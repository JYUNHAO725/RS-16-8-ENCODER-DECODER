`timescale 1ns/1ps
//
// RS(16,8) 缂栫爜鍣ㄩ《灞傦紙GF(256), r=8, t=4锛?
// - 浠呭疄渚嬪寲 LFSR 鏍稿績锛屾帴鍙ｄ负娴佸紡鎻℃墜
// - 杈撳叆锛歞in_val/din_sop/din
// - 杈撳嚭锛歞out_val/dout_sop/dout_eop/dout
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


