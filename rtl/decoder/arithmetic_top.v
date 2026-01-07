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
//   Arithmetic Top wrapper for RS(16,8) decoder.
//   This module provides a simple top-level interface for synthesis/analysis
//   flows by instantiating rs_decoder_16_8 with a clean, flat port list.
//
// Dependencies:
//   rs_decoder_16_8.v
//   syndrome_16_8.v
//   kes_16_8.v
//   err_locate_16_8.v
//   err_value_16_8.v
//   err_correct_16_8.v
//   dec_ctrl_16_8.v
//
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//   - Intended for DC area/power evaluation (no testbench required).
//   - Ports mirror the decoder streaming interface.
//////////////////////////////////////////////////////////////////////////////////

module arithmetic_top (
    input        clk,
    input        rst_n,
    input        din_val,
    input        din_sop,
    input        din_eop,
    input  [7:0] din,
    output [7:0] symb_out_cnt,
    output       symb_out_val,
    output [7:0] symb_corrected
);
    rs_decoder_16_8 u_decoder (
        .clk            (clk),
        .rst_n          (rst_n),
        .din_val        (din_val),
        .din_sop        (din_sop),
        .din_eop        (din_eop),
        .din            (din),
        .symb_out_cnt   (symb_out_cnt),
        .symb_out_val   (symb_out_val),
        .symb_corrected (symb_corrected)
    );
endmodule
