`timescale 1ns/1ps
module syndrome_16_8 (
    input        clk,
    input        rst_n,
    input        din_val,
    input        din_sop,
    input        din_eop,
    input  [7:0] din,
    output reg   syndrome_val,
    output reg [8*8-1:0] syndrome // S0..S7 鎵撳寘杈撳嚭锛屼綆浣嶆槸 S0
);

    localparam integer R_NUM = 8;
    // 伪^(1..8) 鍥哄畾琛紙GF(256), primitive 0x11d锛?
    reg [7:0] ALPHA [0:R_NUM-1];
    // 缂╃煭鐮佸亸绉伙細n=16 鐩稿綋浜庡湪 RS(255,247) 鍓嶈ˉ 239 涓?0锛岃ˉ鍋垮洜瀛?伪^{(i+1)*239}
    reg [7:0] ALPHA_OFF [0:R_NUM-1];
    integer ai;    initial begin
        ALPHA[0]=8'h02; ALPHA[1]=8'h04; ALPHA[2]=8'h08; ALPHA[3]=8'h10;
        ALPHA[4]=8'h20; ALPHA[5]=8'h40; ALPHA[6]=8'h80; ALPHA[7]=8'h1d;

        ALPHA_OFF[0]=8'h16; ALPHA_OFF[1]=8'h09; ALPHA_OFF[2]=8'hA6; ALPHA_OFF[3]=8'h41;
        ALPHA_OFF[4]=8'hFF; ALPHA_OFF[5]=8'h73; ALPHA_OFF[6]=8'h54; ALPHA_OFF[7]=8'hCC;
    end// S0..S7 瀵勫瓨鍣?
    reg [7:0] s [0:R_NUM-1];
    // 鏈媿杈撳叆鍚庣殑 s 鍊硷紙缁勫悎棰勮绠楋紝渚夸簬鍦?din_eop 鏃剁洿鎺ヤ娇鐢級
    reg [7:0] s_next [0:R_NUM-1];
    integer i;
    integer dbg_update;

    // 棰勮绠?s[i]*alpha(i+1)
    wire [7:0] mult [0:R_NUM-1];
    // 杈撳嚭琛ュ伩锛歴[i]*alpha_off(i+1)
    wire [7:0] mult_off [0:R_NUM-1];
    // 浠モ€滀笅涓€鎷嶅€尖€濊绠楃殑琛ュ伩锛岀敤浜庡抚灏鹃攣瀛?syndrome
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

    // 缁勫悎锛氬綋鍓嶈緭鍏ュ悗鐨?s 鍊?
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

    // 鍦ㄨ緭鍏ユ祦鏈熼棿绱Н syndrome
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // 澶嶄綅锛氭竻闆舵墍鏈夌患鍚?
            for (i = 0; i < R_NUM; i = i + 1) s[i] <= 8'h00;
            dbg_update <= 0;
        end else if (din_val) begin
            for (i = 0; i < R_NUM; i = i + 1)
                s[i] <= s_next[i];
            if (dbg_update < 4) begin
                dbg_update <= dbg_update + 1;
                end
        end else if (din_sop) begin
            // 鑻ユ棤 din_val 浣嗘敹鍒?sop锛屾竻闆讹紙闃插尽鎬у鐞嗭級
            for (i = 0; i < R_NUM; i = i + 1) s[i] <= 8'h00;
        end
    end

    // 鎵撳寘杈撳嚭 syndrome锛氫綆浣嶆斁 S0锛屽湪甯у熬閿佸瓨渚夸簬鍚庣骇浣跨敤
    integer k;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (k = 0; k < R_NUM; k = k + 1) syndrome[k*8 +: 8] <= 8'h00;
        end else if (din_eop) begin
            // 鐢ㄢ€滃惈鏈€鍚庝竴涓鍙封€濈殑 s_next 璁＄畻缁煎悎
            for (k = 0; k < R_NUM; k = k + 1) syndrome[k*8 +: 8] <= mult_off_next[k];
        end
    end

    // 瀹屾垚鑴夊啿锛氬抚灏?din_eop
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) syndrome_val <= 1'b0;
        else begin
            syndrome_val <= din_eop;
            if (din_eop) begin
                end
        end
    end

endmodule

