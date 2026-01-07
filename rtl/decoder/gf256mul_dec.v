`timescale 1ns/1ps
// Combinational GF(256) multiplier (primitive poly 0x11d)
module gf256mul_dec(
    input [7:0] a,
    input [7:0] b,
    output [7:0] z
);
    function [7:0] gf_mul;
        input [7:0] aa;
        input [7:0] bb;
        integer i;
        reg [7:0] p;
        reg [7:0] a_tmp;
        reg [7:0] b_tmp;
    begin
        p = 8'h00;
        a_tmp = aa;
        b_tmp = bb;
        for (i = 0; i < 8; i = i + 1) begin
            if (b_tmp[0]) begin
                p = p ^ a_tmp;
            end
            if (a_tmp[7]) begin
                a_tmp = (a_tmp << 1) ^ 8'h1d;
            end else begin
                a_tmp = a_tmp << 1;
            end
            b_tmp = b_tmp >> 1;
        end
        gf_mul = p;
    end
    endfunction

    assign z = gf_mul(a, b);
endmodule
