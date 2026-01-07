`timescale 1ns/1ps
//
// RS(16,8) 缂栫爜鍣ㄦ牳蹇?LFSR锛堢郴缁熷紡缂栫爜锛?
// - 鍙傛暟锛歮=8, n=16, k=8, r=8, t=4
// - 鐢熸垚澶氶」寮?g(x)=鈭廮{i=1..8}(x-伪^i)锛屛?0x02 (poly 0x11d)
// - 绯绘暟 g1..g8 (hex)锛?E3, 2C, B2, 47, AC, 08, E0, 25
//
// 宸ヤ綔鍘熺悊锛堟瘡鎷嶅鐞?1 绗﹀彿锛夛細
//   feedback f = din ^ parity_last;
//   parity_next[0] = f * g1;
//   parity_next[i] = f * g(i+1) ^ parity[i-1]  (i=1..11)
// 杈撳嚭锛氫俊鎭鐩撮€氳緭鍏ワ紝鏍￠獙娈佃緭鍑烘棫鐨?parity_last銆?
//
module rs_lfsr_16_8 (
    input         clk,
    input         rst_n,
    input         din_val,
    input         din_sop,
    input  [7:0]  din,
    output        dout_val,
    output        dout_sop,
    output        dout_eop,
    output [7:0]  dout
);

    localparam integer N_NUM = 16;
    localparam integer K_NUM = 8;
    localparam integer R_NUM = 8;

    // g1..g8 coefficients for RS(16,8)
    reg [7:0] GEN [0:R_NUM-1];
    initial begin
        GEN[0] = 8'hE3; // g1
        GEN[1] = 8'h2C; // g2
        GEN[2] = 8'hB2; // g3
        GEN[3] = 8'h47; // g4
        GEN[4] = 8'hAC; // g5
        GEN[5] = 8'h08; // g6
        GEN[6] = 8'hE0; // g7
        GEN[7] = 8'h25; // g8
    end

    // Parity registers (remainder of m(x)*x^R_NUM / g(x))
    reg [7:0] parity[0:R_NUM-1];
    reg [7:0] parity_shift[0:R_NUM-1]; // 涓茶杈撳嚭鐢ㄧ殑绉讳綅瀵勫瓨

    // Symbol counter: 0 = idle, 1..N_NUM active
    reg [7:0] sym_cnt;            // 0=绌洪棽锛?..132 涓烘椿璺?
    wire      busy = (sym_cnt != 0);

    // Phase flags
    wire data_phase   = busy && (sym_cnt <= K_NUM);
    wire parity_phase = busy && (sym_cnt >  K_NUM) && (sym_cnt <= N_NUM);
    wire new_frame    = din_sop && din_val; // start of a new frame

    // 璁＄畻 data 绗﹀彿鐨勪綑寮忔洿鏂帮細鍏佽 new_frame 鏃朵娇鐢ㄥ叏闆朵綑寮忎綔涓鸿捣鐐?
    reg [7:0] parity_base[0:R_NUM-1];
    integer pb;
    always @* begin
        for (pb = 0; pb < R_NUM; pb = pb + 1)
            parity_base[pb] = (new_frame ? 8'h00 : parity[pb]);
    end

    // 鍙嶉浣跨敤鈥滃綋鍓嶈緭鍏ュ紓鎴栨渶浣庨樁浣欏紡鈥?
    wire [7:0] feedback = (data_phase && din_val) ? (din ^ parity_base[0]) : 8'h00;

    // GF multiplications with generator coefficients
    wire [7:0] mult [0:R_NUM-1];
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
        for (pj = 0; pj < R_NUM-1; pj = pj + 1)
            parity_next[pj] = parity_base[pj+1] ^ mult[pj];
        parity_next[R_NUM-1] = mult[R_NUM-1];
    end

    // Parity update / shift control
    wire data_update = new_frame || (busy && data_phase && din_val);
    integer pk;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (pk = 0; pk < R_NUM; pk = pk + 1) begin
                parity[pk]      <= 8'h00;
                parity_shift[pk] <= 8'h00;
            end
        end else if (busy) begin
            if (data_update) begin
                // 鍚告敹涓€涓暟鎹鍙凤紙new_frame 瑙嗕负鍦ㄩ浂浣欏紡涓婂鐞嗛绗﹀彿锛?
                for (pk = 0; pk < R_NUM; pk = pk + 1)
                    parity[pk] <= parity_next[pk];
                if (sym_cnt < 5) begin
                    $display("ENC data step sym_cnt=%0d din=0x%02x fb=0x%02x next0-3=%02x %02x %02x %02x",
                             sym_cnt, din, feedback,
                             parity_next[0], parity_next[1], parity_next[2], parity_next[3]);
                end
                // 褰撳鐞嗘渶鍚庝竴涓暟鎹鍙锋椂锛屾洿鏂板悗鐨勪綑寮忛渶瑕佽杞藉埌 parity_shift
                if ((sym_cnt == K_NUM) || (K_NUM == 1 && new_frame)) begin
                    for (pk = 0; pk < R_NUM; pk = pk + 1)
                        parity_shift[pk] <= parity_next[pk];
                    end
            end else if (parity_phase) begin
                // 涓茶杈撳嚭鏍￠獙锛氱Щ浣?
                for (pk = 0; pk < R_NUM-1; pk = pk + 1)
                    parity_shift[pk] <= parity_shift[pk+1];
                parity_shift[R_NUM-1] <= 8'h00;
            end
        end
    end

    // Symbol counter
    // 绗﹀彿璁℃暟锛歜usy 鏃舵瘡鎷嶈嚜澧烇紝鏁板埌 N_NUM 娓呴浂閫€鍑?
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sym_cnt <= 8'd0;
        end else if (new_frame) begin
            sym_cnt <= 8'd1;
        end else if (busy) begin
            if (sym_cnt == N_NUM)
                sym_cnt <= 8'd0;
            else
                sym_cnt <= sym_cnt + 8'd1;
        end
    end

    // Output logic
    wire [7:0] parity_out = parity_shift[0]; // 渚濇杈撳嚭浣欏紡楂橀樁鍒颁綆闃?
    reg  [7:0] dout_r;
    reg        dout_val_r, dout_sop_r, dout_eop_r;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            dout_r      <= 8'h00;
            dout_val_r  <= 1'b0;
            dout_sop_r  <= 1'b0;
            dout_eop_r  <= 1'b0;
        end else begin
            dout_val_r <= (new_frame) ||
                          (busy && parity_phase) ||
                          (busy && data_phase && din_val);
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

