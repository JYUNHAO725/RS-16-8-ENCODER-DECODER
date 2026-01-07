`timescale 1ns / 1ps
//
// RS(16,8) 编码器核心 LFSR（系统式编码）
// - 参数：m=8, n=16, k=8, r=8, t=4
// - 生成多项式 g(x)=∏_{i=1..8}(x-α^i)，α=0x02 (poly 0x11d)
// - 系数 g1..g8 (hex)：E3, 2C, B2, 47, AC, 08, E0, 25
//
// 工作原理（每拍处理 1 符号）：
//   feedback f = din ^ parity_last;
//   parity_next[0] = f * g1;
//   parity_next[i] = f * g(i+1) ^ parity[i-1]  (i=1..7)
// 输出：信息段直通输入，校验段输出旧的 parity_last
//
module rs_lfsr_16_8 (
    input        clk,
    input        rst_n,
    input        din_val,
    input        din_sop,
    input  [7:0] din,
    output       dout_val,
    output       dout_sop,
    output       dout_eop,
    output [7:0] dout
);

  localparam integer N_NUM = 16;
  localparam integer K_NUM = 8;
  localparam integer R_NUM = 8;

  // g1..g8 coefficients for RS(16,8)
  wire [7:0] GEN[0:R_NUM-1];
  assign GEN[0] = 8'hE3;  // g1
  assign GEN[1] = 8'h2C;  // g2
  assign GEN[2] = 8'hB2;  // g3
  assign GEN[3] = 8'h47;  // g4
  assign GEN[4] = 8'hAC;  // g5
  assign GEN[5] = 8'h08;  // g6
  assign GEN[6] = 8'hE0;  // g7
  assign GEN[7] = 8'h25;  // g8

  // Parity registers (remainder of m(x)*x^R_NUM / g(x))
  reg     [7:0] parity                                                         [0:R_NUM-1];
  reg     [7:0] parity_shift                                                   [0:R_NUM-1];

  // Symbol counter: 0 = idle, 1..N_NUM active
  reg     [7:0] sym_cnt;
  wire          busy = (sym_cnt != 0);

  // Phase flags
  wire          data_phase = busy && (sym_cnt <= K_NUM);
  wire          parity_phase = busy && (sym_cnt > K_NUM) && (sym_cnt <= N_NUM);
  wire          new_frame = din_sop && din_val;

  // 计算 data 符号的余式更新：允许 new_frame 时使用全零余式作为起点
  reg     [7:0] parity_base                                                    [0:R_NUM-1];
  integer       pb;
  always @* begin
    for (pb = 0; pb < R_NUM; pb = pb + 1) parity_base[pb] = (new_frame ? 8'h00 : parity[pb]);
  end

  // 反馈使用“当前输入异或最低阶余式”
  wire [7:0] feedback = (data_phase && din_val) ? (din ^ parity_base[0]) : 8'h00;

  // GF multiplications with generator coefficients
  wire [7:0] mult[0:R_NUM-1];
  genvar gi;
  generate
    for (gi = 0; gi < R_NUM; gi = gi + 1) begin : gen_mul
      gf256mul_dec u_mul (
          .a(feedback),
          .b(GEN[gi]),
          .z(mult[gi])
      );
    end
  endgenerate

  // Next remainder when absorbing a data symbol
  reg [7:0] parity_next[0:R_NUM-1];
  integer pj;
  always @* begin
    // parity_next[i] = parity_base[i+1] ^ feedback * g_{i+1}
    for (pj = 0; pj < R_NUM - 1; pj = pj + 1) parity_next[pj] = parity_base[pj+1] ^ mult[pj];
    parity_next[R_NUM-1] = mult[R_NUM-1];
  end

  // Parity update / shift control
  wire data_update = new_frame || (busy && data_phase && din_val);
  integer pk;
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      for (pk = 0; pk < R_NUM; pk = pk + 1) begin
        parity[pk]       <= 8'h00;
        parity_shift[pk] <= 8'h00;
      end
    end else if (busy) begin
      if (data_update) begin
        // 吸收一个数据符号（new_frame 视为在零余式上处理首符号）
        for (pk = 0; pk < R_NUM; pk = pk + 1) parity[pk] <= parity_next[pk];
        // 当处理最后一个数据符号时，更新后的余式需要装载到 parity_shift
        if ((sym_cnt == K_NUM) || (K_NUM == 1 && new_frame)) begin
          for (pk = 0; pk < R_NUM; pk = pk + 1) parity_shift[pk] <= parity_next[pk];
        end
      end else if (parity_phase) begin
        // 串行输出校验：移位
        for (pk = 0; pk < R_NUM - 1; pk = pk + 1) parity_shift[pk] <= parity_shift[pk+1];
        parity_shift[R_NUM-1] <= 8'h00;
      end
    end
  end

  // Symbol counter
  // 符号计数：busy 时每拍自增，数到 N_NUM 清零退出
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      sym_cnt <= 8'd0;
    end else if (new_frame) begin
      sym_cnt <= 8'd1;
    end else if (busy) begin
      if (sym_cnt == N_NUM) sym_cnt <= 8'd0;
      else sym_cnt <= sym_cnt + 8'd1;
    end
  end

  // Output logic
  wire [7:0] parity_out = parity_shift[0];
  reg  [7:0] dout_r;
  reg dout_val_r, dout_sop_r, dout_eop_r;

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      dout_r     <= 8'h00;
      dout_val_r <= 1'b0;
      dout_sop_r <= 1'b0;
      dout_eop_r <= 1'b0;
    end else begin
      dout_val_r <= (new_frame) || (busy && parity_phase) || (busy && data_phase && din_val);
      dout_sop_r <= new_frame;
      dout_eop_r <= busy && (sym_cnt == N_NUM);

      if (new_frame || (busy && data_phase && din_val)) begin
        dout_r <= din;
      end else if (busy && parity_phase) begin
        dout_r <= parity_out;
      end else begin
        dout_r <= 8'h00;
      end
    end
  end

  assign dout     = dout_r;
  assign dout_val = dout_val_r;
  assign dout_sop = dout_sop_r;
  assign dout_eop = dout_eop_r;

endmodule
