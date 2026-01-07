`timescale 1ns/1ps
//
// RS(16,8) 编码器顶层（GF(256), r=8, t=4）
// - 仅实例化 LFSR 核心，接口为流式握手
// - 输入：din_val/din_sop/din
// - 输出：dout_val/dout_sop/dout_eop/dout
//
module rs_encoder_16_8 (
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

    rs_lfsr_16_8 u_lfsr (
        .clk      (clk),
        .rst_n    (rst_n),
        .din_val  (din_val),
        .din_sop  (din_sop),
        .din      (din),
        .dout_val (dout_val),
        .dout_sop (dout_sop),
        .dout_eop (dout_eop),
        .dout     (dout)
    );

endmodule
