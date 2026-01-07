`timescale 1ns/1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date:
// Design Name:
// Module Name:    arithmetic_top
// Project Name:
// Target Devices:
// Tool Versions:
// Description:
//   Arithmetic Top wrapper for RS(16,8) encoder.
//   This module provides a simple top-level interface for synthesis/analysis
//   flows by instantiating rs_encoder_16_8 with a clean, flat port list.
//
// Dependencies:
//   rs_encoder_16_8.v
//   rs_lfsr_16_8.v
//   gf256mul_dec.v
//
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//   - Intended for DC area/power evaluation (no testbench required).
//   - Ports mirror the encoder streaming interface.
//////////////////////////////////////////////////////////////////////////////////

module arithmetic_top (
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
    rs_encoder_16_8 u_encoder (
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