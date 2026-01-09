`timescale 1ns/1ps
//
// RS(16,8) decoder top-level (GF(256), t=4)
//
module rs_decoder_16_8 (
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

    // Syndrome
    wire syndrome_val;
    wire [8*8-1:0] syndrome;

    wire kes_done;
    wire chien_done;
    wire forney_done;
    wire [8*5-1:0] lamda;
    wire [8*4-1:0] omega;
    wire [8*4-1:0] err_loc;
    wire [8*4-1:0] err_val;
    wire [8*4-1:0] err_loc_out;

    syndrome_16_8 u_synd (
        .clk         (clk),
        .rst_n       (rst_n),
        .din_val     (din_val),
        .din_sop     (din_sop),
        .din_eop     (din_eop),
        .din         (din),
        .syndrome_val(syndrome_val),
        .syndrome    (syndrome)
    );

    // 对齐 start 脉冲，避免同一拍采集未稳定的数据
    reg syndrome_val_q, syndrome_val_d;
    reg kes_done_q, kes_done_d;
    reg chien_done_q, chien_done_d;
    reg forney_done_q, forney_done_d;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            syndrome_val_q <= 1'b0;
            syndrome_val_d <= 1'b0;
            kes_done_q     <= 1'b0;
            kes_done_d     <= 1'b0;
            chien_done_q   <= 1'b0;
            chien_done_d   <= 1'b0;
            forney_done_q  <= 1'b0;
            forney_done_d  <= 1'b0;
        end else begin
            syndrome_val_q <= syndrome_val;
            syndrome_val_d <= syndrome_val_q;
            kes_done_q     <= kes_done;
            kes_done_d     <= kes_done_q;
            chien_done_q   <= chien_done;
            chien_done_d   <= chien_done_q;
            forney_done_q  <= forney_done;
            forney_done_d  <= forney_done_q;
        end
    end

    // KES
    kes_16_8 #(
        .SYM_BW(8),
        .N_NUM (16),
        .R_NUM (8)
    ) u_kes (
        .clk      (clk),
        .rst_n    (rst_n),
        .start    (syndrome_val_d),
        .syndrome (syndrome),
        .lamda    (lamda),
        .omega    (omega),
        .done     (kes_done)
    );

    // Chien

    err_locate_16_8 #(
        .SYM_BW(8),
        .N_NUM (16),
        .R_NUM (8)
    ) u_chien (
        .clk     (clk),
        .rst_n   (rst_n),
        .start   (kes_done_d),
        .lamda   (lamda),
        .err_loc (err_loc),
        .done    (chien_done)
    );

    // Forney

    err_value_16_8 #(
        .SYM_BW(8),
        .N_NUM (16),
        .R_NUM (8)
    ) u_forn (
        .clk     (clk),
        .rst_n   (rst_n),
        .start   (chien_done_d),
        .lamda   (lamda),
        .omega   (omega),
        .err_loc (err_loc),
        .err_val (err_val),
        .err_loc_out(err_loc_out),
        .done    (forney_done)
    );

    // FIFO for input symbols
    wire fifo_rd;
    wire [7:0] fifo_dout;
    fifo_buffer #(
        .WIDTH(8),
        .DEPTH(16)
    ) u_fifo (
        .clk     (clk),
        .rst     (~rst_n),
        .rd      (fifo_rd),
        .wr      (din_val),
        .datain  (din),
        .dataout (fifo_dout),
        .empty   ( ),
        .full    ( )
    );

    // Control to drain FIFO
    wire [7:0] symb_cnt_int;
    wire [7:0] symb_with_err;
    dec_ctrl_16_8 u_ctrl (
        .clk        (clk),
        .rst_n      (rst_n),
        .start      (forney_done_d), // err 值就绪后再开始读 FIFO
        .fifo_rd    (fifo_rd),
        .fifo_out   (fifo_dout),
        .symbol_cnt (symb_cnt_int),
        .symbol_out (symb_with_err),
        .running_o  ( )
    );

    // Error correction
    err_correct_16_8 #(
        .SYM_BW(8),
        .N_NUM (16),
        .R_NUM (8)
    ) u_corr (
        .clk            (clk),
        .rst_n          (rst_n),
        .start          (forney_done_d),
        .symb_cnt       (symb_cnt_int),
        .symb_with_err  (symb_with_err),
        .err_val        (err_val),
        .err_loc        (err_loc_out),
        .symb_out_cnt   (symb_out_cnt),
        .symb_out_val   (symb_out_val),
        .symb_corrected (symb_corrected)
    );

endmodule
