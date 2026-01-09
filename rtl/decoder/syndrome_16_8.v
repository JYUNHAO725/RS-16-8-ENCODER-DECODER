`timescale 1ns/1ps
module syndrome_16_8 (
    input        clk,
    input        rst_n,
    input        din_val,
    input        din_sop,
    input        din_eop,
    input  [7:0] din,
    output reg   syndrome_val,
    output reg [8*8-1:0] syndrome // S0..S7 打包输出，低位是 S0
);

    localparam integer R_NUM = 8;
    // α^(1..8) 固定表（GF(256), primitive 0x11d）
    wire [7:0] ALPHA [0:R_NUM-1];
    wire [7:0] ALPHA_OFF [0:R_NUM-1];

    assign ALPHA[0]=8'h02; assign ALPHA[1]=8'h04; assign ALPHA[2]=8'h08; assign ALPHA[3]=8'h10;
    assign ALPHA[4]=8'h20; assign ALPHA[5]=8'h40; assign ALPHA[6]=8'h80; assign ALPHA[7]=8'h1d;

    assign ALPHA_OFF[0]=8'h16; assign ALPHA_OFF[1]=8'h09; assign ALPHA_OFF[2]=8'hA6; assign ALPHA_OFF[3]=8'h41;
    assign ALPHA_OFF[4]=8'hFF; assign ALPHA_OFF[5]=8'h73; assign ALPHA_OFF[6]=8'h54; assign ALPHA_OFF[7]=8'hCC;
// S0..S7 寄存器
    reg [7:0] s [0:R_NUM-1];
    // 本拍输入后的 s 值（组合预计算，便于在 din_eop 时直接使用）
    reg [7:0] s_next [0:R_NUM-1];
    integer i;
    integer dbg_update;

    // 预计算 s[i]*alpha(i+1)
    wire [7:0] mult [0:R_NUM-1];
    // 输出补偿：s[i]*alpha_off(i+1)
    wire [7:0] mult_off [0:R_NUM-1];
    // 以“下一拍值”计算的补偿，用于帧尾锁存 syndrome
    wire [7:0] mult_off_next [0:R_NUM-1];
    genvar gi;
    generate
        for (gi = 0; gi < R_NUM; gi = gi + 1) begin : GEN_MUL
            gf256mul_dec u_mul (
                .a(s[gi]),
                .b(ALPHA[gi]),
                .z(mult[gi])
            );
            gf256mul_dec u_mul_off (
                .a(s[gi]),
                .b(ALPHA_OFF[gi]),
                .z(mult_off[gi])
            );
            gf256mul_dec u_mul_off_next (
                .a(s_next[gi]),
                .b(ALPHA_OFF[gi]),
                .z(mult_off_next[gi])
            );
        end
    endgenerate

    // 组合：当前输入后的 s 值
    integer si;
    always @* begin
        for (si = 0; si < R_NUM; si = si + 1) begin
            if (din_val) begin
                if (din_sop)
                    s_next[si] = din;
                else
                    s_next[si] = mult[si] ^ din;
            end else begin
                s_next[si] = s[si];
            end
        end
    end

    // 在输入流期间累积 syndrome
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // 复位：清零所有综合
            for (i = 0; i < R_NUM; i = i + 1) s[i] <= 8'h00;
            dbg_update <= 0;
        end else if (din_val) begin
            for (i = 0; i < R_NUM; i = i + 1)
                s[i] <= s_next[i];
            if (dbg_update < 4) begin
                dbg_update <= dbg_update + 1;
                                $display("SYND step%0d din=%02x s=%02x %02x %02x %02x %02x %02x %02x %02x",
                         dbg_update, din, s_next[0], s_next[1], s_next[2], s_next[3],
                         s_next[4], s_next[5], s_next[6], s_next[7]);
            end
        end else if (din_sop) begin
            // 若无 din_val 但收到 sop，清零（防御性处理）
            for (i = 0; i < R_NUM; i = i + 1) s[i] <= 8'h00;
        end
    end

    // 打包输出 syndrome：低位放 S0，在帧尾锁存便于后级使用
    integer k;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (k = 0; k < R_NUM; k = k + 1) syndrome[k*8 +: 8] <= 8'h00;
        end else if (din_eop) begin
            // 用“含最后一个符号”的 s_next 计算综合
            for (k = 0; k < R_NUM; k = k + 1) syndrome[k*8 +: 8] <= mult_off_next[k];
        end
    end

    // 完成脉冲：帧尾 din_eop
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) syndrome_val <= 1'b0;
        else begin
            syndrome_val <= din_eop;
            if (din_eop) begin
                                $display("SYND debug s=%02x %02x %02x %02x %02x %02x %02x %02x off=%02x %02x %02x %02x %02x %02x %02x %02x",
                         s[0], s[1], s[2], s[3], s[4], s[5], s[6], s[7],
                         mult_off[0], mult_off[1], mult_off[2], mult_off[3],
                         mult_off[4], mult_off[5], mult_off[6], mult_off[7]);
            end
        end
    end

endmodule
