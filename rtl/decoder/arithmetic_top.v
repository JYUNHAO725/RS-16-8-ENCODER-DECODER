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
//   Arithmetic Top wrapper for RS(132,120) decoder.
//   This module provides a simple top-level interface for synthesis/analysis
//   flows by instantiating rs_decoder_132_120 with a clean, flat port list.
//
// Dependencies:
//   rs_decoder_132_120.v
//   syndrome_132_120.v
//   kes_132_120.v
//   err_locate_132_120.v
//   err_value_132_120.v
//   err_correct_132_120.v
//   dec_ctrl_132_120.v
//   fifo_buffer.v
//   gf256mul_dec.v
//   gf256mul.v
//   gf256_tables.v
//
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//   - Intended for DC area/power evaluation (no testbench required).
//   - Ports mirror the decoder streaming interface and corrected output.
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
    rs_decoder_132_120 u_decoder (
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
