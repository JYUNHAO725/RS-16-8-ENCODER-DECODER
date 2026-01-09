`timescale 1ns/1ps
// Berlekamp-Massey for RS(16,8), GF(256), t=4
// S0..S7, LSB is S0
module kes_16_8 #(
    parameter SYM_BW = 8,
    parameter N_NUM  = 16,
    parameter R_NUM  = 8
) (
    input                     clk,
    input                     rst_n,
    input                     start,        // pulse when syndrome ready
    input  [SYM_BW*8-1:0]    syndrome,     // S0..S7, LSB is S0
    output reg [SYM_BW*5-1:0] lamda,        // lambda0..lambda4
    output reg [SYM_BW*4-1:0] omega,        // omega0..omega3
    output reg                done
);
    localparam integer T = 4; // 纠错能力

    // GF helpers (EXP/LOG table + gf_mul/gf_inv/gf_pow) inlined to avoid external include
    function automatic [SYM_BW-1:0] gf_exp;
        input [7:0] idx;
        begin
            case (idx)
                8'h00: gf_exp = 8'h01;
                8'h01: gf_exp = 8'h02;
                8'h02: gf_exp = 8'h04;
                8'h03: gf_exp = 8'h08;
                8'h04: gf_exp = 8'h10;
                8'h05: gf_exp = 8'h20;
                8'h06: gf_exp = 8'h40;
                8'h07: gf_exp = 8'h80;
                8'h08: gf_exp = 8'h1d;
                8'h09: gf_exp = 8'h3a;
                8'h0a: gf_exp = 8'h74;
                8'h0b: gf_exp = 8'he8;
                8'h0c: gf_exp = 8'hcd;
                8'h0d: gf_exp = 8'h87;
                8'h0e: gf_exp = 8'h13;
                8'h0f: gf_exp = 8'h26;
                8'h10: gf_exp = 8'h4c;
                8'h11: gf_exp = 8'h98;
                8'h12: gf_exp = 8'h2d;
                8'h13: gf_exp = 8'h5a;
                8'h14: gf_exp = 8'hb4;
                8'h15: gf_exp = 8'h75;
                8'h16: gf_exp = 8'hea;
                8'h17: gf_exp = 8'hc9;
                8'h18: gf_exp = 8'h8f;
                8'h19: gf_exp = 8'h03;
                8'h1a: gf_exp = 8'h06;
                8'h1b: gf_exp = 8'h0c;
                8'h1c: gf_exp = 8'h18;
                8'h1d: gf_exp = 8'h30;
                8'h1e: gf_exp = 8'h60;
                8'h1f: gf_exp = 8'hc0;
                8'h20: gf_exp = 8'h9d;
                8'h21: gf_exp = 8'h27;
                8'h22: gf_exp = 8'h4e;
                8'h23: gf_exp = 8'h9c;
                8'h24: gf_exp = 8'h25;
                8'h25: gf_exp = 8'h4a;
                8'h26: gf_exp = 8'h94;
                8'h27: gf_exp = 8'h35;
                8'h28: gf_exp = 8'h6a;
                8'h29: gf_exp = 8'hd4;
                8'h2a: gf_exp = 8'hb5;
                8'h2b: gf_exp = 8'h77;
                8'h2c: gf_exp = 8'hee;
                8'h2d: gf_exp = 8'hc1;
                8'h2e: gf_exp = 8'h9f;
                8'h2f: gf_exp = 8'h23;
                8'h30: gf_exp = 8'h46;
                8'h31: gf_exp = 8'h8c;
                8'h32: gf_exp = 8'h05;
                8'h33: gf_exp = 8'h0a;
                8'h34: gf_exp = 8'h14;
                8'h35: gf_exp = 8'h28;
                8'h36: gf_exp = 8'h50;
                8'h37: gf_exp = 8'ha0;
                8'h38: gf_exp = 8'h5d;
                8'h39: gf_exp = 8'hba;
                8'h3a: gf_exp = 8'h69;
                8'h3b: gf_exp = 8'hd2;
                8'h3c: gf_exp = 8'hb9;
                8'h3d: gf_exp = 8'h6f;
                8'h3e: gf_exp = 8'hde;
                8'h3f: gf_exp = 8'ha1;
                8'h40: gf_exp = 8'h5f;
                8'h41: gf_exp = 8'hbe;
                8'h42: gf_exp = 8'h61;
                8'h43: gf_exp = 8'hc2;
                8'h44: gf_exp = 8'h99;
                8'h45: gf_exp = 8'h2f;
                8'h46: gf_exp = 8'h5e;
                8'h47: gf_exp = 8'hbc;
                8'h48: gf_exp = 8'h65;
                8'h49: gf_exp = 8'hca;
                8'h4a: gf_exp = 8'h89;
                8'h4b: gf_exp = 8'h0f;
                8'h4c: gf_exp = 8'h1e;
                8'h4d: gf_exp = 8'h3c;
                8'h4e: gf_exp = 8'h78;
                8'h4f: gf_exp = 8'hf0;
                8'h50: gf_exp = 8'hfd;
                8'h51: gf_exp = 8'he7;
                8'h52: gf_exp = 8'hd3;
                8'h53: gf_exp = 8'hbb;
                8'h54: gf_exp = 8'h6b;
                8'h55: gf_exp = 8'hd6;
                8'h56: gf_exp = 8'hb1;
                8'h57: gf_exp = 8'h7f;
                8'h58: gf_exp = 8'hfe;
                8'h59: gf_exp = 8'he1;
                8'h5a: gf_exp = 8'hdf;
                8'h5b: gf_exp = 8'ha3;
                8'h5c: gf_exp = 8'h5b;
                8'h5d: gf_exp = 8'hb6;
                8'h5e: gf_exp = 8'h71;
                8'h5f: gf_exp = 8'he2;
                8'h60: gf_exp = 8'hd9;
                8'h61: gf_exp = 8'haf;
                8'h62: gf_exp = 8'h43;
                8'h63: gf_exp = 8'h86;
                8'h64: gf_exp = 8'h11;
                8'h65: gf_exp = 8'h22;
                8'h66: gf_exp = 8'h44;
                8'h67: gf_exp = 8'h88;
                8'h68: gf_exp = 8'h0d;
                8'h69: gf_exp = 8'h1a;
                8'h6a: gf_exp = 8'h34;
                8'h6b: gf_exp = 8'h68;
                8'h6c: gf_exp = 8'hd0;
                8'h6d: gf_exp = 8'hbd;
                8'h6e: gf_exp = 8'h67;
                8'h6f: gf_exp = 8'hce;
                8'h70: gf_exp = 8'h81;
                8'h71: gf_exp = 8'h1f;
                8'h72: gf_exp = 8'h3e;
                8'h73: gf_exp = 8'h7c;
                8'h74: gf_exp = 8'hf8;
                8'h75: gf_exp = 8'hed;
                8'h76: gf_exp = 8'hc7;
                8'h77: gf_exp = 8'h93;
                8'h78: gf_exp = 8'h3b;
                8'h79: gf_exp = 8'h76;
                8'h7a: gf_exp = 8'hec;
                8'h7b: gf_exp = 8'hc5;
                8'h7c: gf_exp = 8'h97;
                8'h7d: gf_exp = 8'h33;
                8'h7e: gf_exp = 8'h66;
                8'h7f: gf_exp = 8'hcc;
                8'h80: gf_exp = 8'h85;
                8'h81: gf_exp = 8'h17;
                8'h82: gf_exp = 8'h2e;
                8'h83: gf_exp = 8'h5c;
                8'h84: gf_exp = 8'hb8;
                8'h85: gf_exp = 8'h6d;
                8'h86: gf_exp = 8'hda;
                8'h87: gf_exp = 8'ha9;
                8'h88: gf_exp = 8'h4f;
                8'h89: gf_exp = 8'h9e;
                8'h8a: gf_exp = 8'h21;
                8'h8b: gf_exp = 8'h42;
                8'h8c: gf_exp = 8'h84;
                8'h8d: gf_exp = 8'h15;
                8'h8e: gf_exp = 8'h2a;
                8'h8f: gf_exp = 8'h54;
                8'h90: gf_exp = 8'ha8;
                8'h91: gf_exp = 8'h4d;
                8'h92: gf_exp = 8'h9a;
                8'h93: gf_exp = 8'h29;
                8'h94: gf_exp = 8'h52;
                8'h95: gf_exp = 8'ha4;
                8'h96: gf_exp = 8'h55;
                8'h97: gf_exp = 8'haa;
                8'h98: gf_exp = 8'h49;
                8'h99: gf_exp = 8'h92;
                8'h9a: gf_exp = 8'h39;
                8'h9b: gf_exp = 8'h72;
                8'h9c: gf_exp = 8'he4;
                8'h9d: gf_exp = 8'hd5;
                8'h9e: gf_exp = 8'hb7;
                8'h9f: gf_exp = 8'h73;
                8'ha0: gf_exp = 8'he6;
                8'ha1: gf_exp = 8'hd1;
                8'ha2: gf_exp = 8'hbf;
                8'ha3: gf_exp = 8'h63;
                8'ha4: gf_exp = 8'hc6;
                8'ha5: gf_exp = 8'h91;
                8'ha6: gf_exp = 8'h3f;
                8'ha7: gf_exp = 8'h7e;
                8'ha8: gf_exp = 8'hfc;
                8'ha9: gf_exp = 8'he5;
                8'haa: gf_exp = 8'hd7;
                8'hab: gf_exp = 8'hb3;
                8'hac: gf_exp = 8'h7b;
                8'had: gf_exp = 8'hf6;
                8'hae: gf_exp = 8'hf1;
                8'haf: gf_exp = 8'hff;
                8'hb0: gf_exp = 8'he3;
                8'hb1: gf_exp = 8'hdb;
                8'hb2: gf_exp = 8'hab;
                8'hb3: gf_exp = 8'h4b;
                8'hb4: gf_exp = 8'h96;
                8'hb5: gf_exp = 8'h31;
                8'hb6: gf_exp = 8'h62;
                8'hb7: gf_exp = 8'hc4;
                8'hb8: gf_exp = 8'h95;
                8'hb9: gf_exp = 8'h37;
                8'hba: gf_exp = 8'h6e;
                8'hbb: gf_exp = 8'hdc;
                8'hbc: gf_exp = 8'ha5;
                8'hbd: gf_exp = 8'h57;
                8'hbe: gf_exp = 8'hae;
                8'hbf: gf_exp = 8'h41;
                8'hc0: gf_exp = 8'h82;
                8'hc1: gf_exp = 8'h19;
                8'hc2: gf_exp = 8'h32;
                8'hc3: gf_exp = 8'h64;
                8'hc4: gf_exp = 8'hc8;
                8'hc5: gf_exp = 8'h8d;
                8'hc6: gf_exp = 8'h07;
                8'hc7: gf_exp = 8'h0e;
                8'hc8: gf_exp = 8'h1c;
                8'hc9: gf_exp = 8'h38;
                8'hca: gf_exp = 8'h70;
                8'hcb: gf_exp = 8'he0;
                8'hcc: gf_exp = 8'hdd;
                8'hcd: gf_exp = 8'ha7;
                8'hce: gf_exp = 8'h53;
                8'hcf: gf_exp = 8'ha6;
                8'hd0: gf_exp = 8'h51;
                8'hd1: gf_exp = 8'ha2;
                8'hd2: gf_exp = 8'h59;
                8'hd3: gf_exp = 8'hb2;
                8'hd4: gf_exp = 8'h79;
                8'hd5: gf_exp = 8'hf2;
                8'hd6: gf_exp = 8'hf9;
                8'hd7: gf_exp = 8'hef;
                8'hd8: gf_exp = 8'hc3;
                8'hd9: gf_exp = 8'h9b;
                8'hda: gf_exp = 8'h2b;
                8'hdb: gf_exp = 8'h56;
                8'hdc: gf_exp = 8'hac;
                8'hdd: gf_exp = 8'h45;
                8'hde: gf_exp = 8'h8a;
                8'hdf: gf_exp = 8'h09;
                8'he0: gf_exp = 8'h12;
                8'he1: gf_exp = 8'h24;
                8'he2: gf_exp = 8'h48;
                8'he3: gf_exp = 8'h90;
                8'he4: gf_exp = 8'h3d;
                8'he5: gf_exp = 8'h7a;
                8'he6: gf_exp = 8'hf4;
                8'he7: gf_exp = 8'hf5;
                8'he8: gf_exp = 8'hf7;
                8'he9: gf_exp = 8'hf3;
                8'hea: gf_exp = 8'hfb;
                8'heb: gf_exp = 8'heb;
                8'hec: gf_exp = 8'hcb;
                8'hed: gf_exp = 8'h8b;
                8'hee: gf_exp = 8'h0b;
                8'hef: gf_exp = 8'h16;
                8'hf0: gf_exp = 8'h2c;
                8'hf1: gf_exp = 8'h58;
                8'hf2: gf_exp = 8'hb0;
                8'hf3: gf_exp = 8'h7d;
                8'hf4: gf_exp = 8'hfa;
                8'hf5: gf_exp = 8'he9;
                8'hf6: gf_exp = 8'hcf;
                8'hf7: gf_exp = 8'h83;
                8'hf8: gf_exp = 8'h1b;
                8'hf9: gf_exp = 8'h36;
                8'hfa: gf_exp = 8'h6c;
                8'hfb: gf_exp = 8'hd8;
                8'hfc: gf_exp = 8'had;
                8'hfd: gf_exp = 8'h47;
                8'hfe: gf_exp = 8'h8e;
                8'hff: gf_exp = 8'h01;
                default: gf_exp = 8'h00;
            endcase
        end
    endfunction

    function automatic [SYM_BW-1:0] gf_log;
        input [7:0] val;
        begin
            case (val)
                8'h00: gf_log = 8'h00;
                8'h01: gf_log = 8'h00;
                8'h02: gf_log = 8'h01;
                8'h03: gf_log = 8'h19;
                8'h04: gf_log = 8'h02;
                8'h05: gf_log = 8'h32;
                8'h06: gf_log = 8'h1a;
                8'h07: gf_log = 8'hc6;
                8'h08: gf_log = 8'h03;
                8'h09: gf_log = 8'hdf;
                8'h0a: gf_log = 8'h33;
                8'h0b: gf_log = 8'hee;
                8'h0c: gf_log = 8'h1b;
                8'h0d: gf_log = 8'h68;
                8'h0e: gf_log = 8'hc7;
                8'h0f: gf_log = 8'h4b;
                8'h10: gf_log = 8'h04;
                8'h11: gf_log = 8'h64;
                8'h12: gf_log = 8'he0;
                8'h13: gf_log = 8'h0e;
                8'h14: gf_log = 8'h34;
                8'h15: gf_log = 8'h8d;
                8'h16: gf_log = 8'hef;
                8'h17: gf_log = 8'h81;
                8'h18: gf_log = 8'h1c;
                8'h19: gf_log = 8'hc1;
                8'h1a: gf_log = 8'h69;
                8'h1b: gf_log = 8'hf8;
                8'h1c: gf_log = 8'hc8;
                8'h1d: gf_log = 8'h08;
                8'h1e: gf_log = 8'h4c;
                8'h1f: gf_log = 8'h71;
                8'h20: gf_log = 8'h05;
                8'h21: gf_log = 8'h8a;
                8'h22: gf_log = 8'h65;
                8'h23: gf_log = 8'h2f;
                8'h24: gf_log = 8'he1;
                8'h25: gf_log = 8'h24;
                8'h26: gf_log = 8'h0f;
                8'h27: gf_log = 8'h21;
                8'h28: gf_log = 8'h35;
                8'h29: gf_log = 8'h93;
                8'h2a: gf_log = 8'h8e;
                8'h2b: gf_log = 8'hda;
                8'h2c: gf_log = 8'hf0;
                8'h2d: gf_log = 8'h12;
                8'h2e: gf_log = 8'h82;
                8'h2f: gf_log = 8'h45;
                8'h30: gf_log = 8'h1d;
                8'h31: gf_log = 8'hb5;
                8'h32: gf_log = 8'hc2;
                8'h33: gf_log = 8'h7d;
                8'h34: gf_log = 8'h6a;
                8'h35: gf_log = 8'h27;
                8'h36: gf_log = 8'hf9;
                8'h37: gf_log = 8'hb9;
                8'h38: gf_log = 8'hc9;
                8'h39: gf_log = 8'h9a;
                8'h3a: gf_log = 8'h09;
                8'h3b: gf_log = 8'h78;
                8'h3c: gf_log = 8'h4d;
                8'h3d: gf_log = 8'he4;
                8'h3e: gf_log = 8'h72;
                8'h3f: gf_log = 8'ha6;
                8'h40: gf_log = 8'h06;
                8'h41: gf_log = 8'hbf;
                8'h42: gf_log = 8'h8b;
                8'h43: gf_log = 8'h62;
                8'h44: gf_log = 8'h66;
                8'h45: gf_log = 8'hdd;
                8'h46: gf_log = 8'h30;
                8'h47: gf_log = 8'hfd;
                8'h48: gf_log = 8'he2;
                8'h49: gf_log = 8'h98;
                8'h4a: gf_log = 8'h25;
                8'h4b: gf_log = 8'hb3;
                8'h4c: gf_log = 8'h10;
                8'h4d: gf_log = 8'h91;
                8'h4e: gf_log = 8'h22;
                8'h4f: gf_log = 8'h88;
                8'h50: gf_log = 8'h36;
                8'h51: gf_log = 8'hd0;
                8'h52: gf_log = 8'h94;
                8'h53: gf_log = 8'hce;
                8'h54: gf_log = 8'h8f;
                8'h55: gf_log = 8'h96;
                8'h56: gf_log = 8'hdb;
                8'h57: gf_log = 8'hbd;
                8'h58: gf_log = 8'hf1;
                8'h59: gf_log = 8'hd2;
                8'h5a: gf_log = 8'h13;
                8'h5b: gf_log = 8'h5c;
                8'h5c: gf_log = 8'h83;
                8'h5d: gf_log = 8'h38;
                8'h5e: gf_log = 8'h46;
                8'h5f: gf_log = 8'h40;
                8'h60: gf_log = 8'h1e;
                8'h61: gf_log = 8'h42;
                8'h62: gf_log = 8'hb6;
                8'h63: gf_log = 8'ha3;
                8'h64: gf_log = 8'hc3;
                8'h65: gf_log = 8'h48;
                8'h66: gf_log = 8'h7e;
                8'h67: gf_log = 8'h6e;
                8'h68: gf_log = 8'h6b;
                8'h69: gf_log = 8'h3a;
                8'h6a: gf_log = 8'h28;
                8'h6b: gf_log = 8'h54;
                8'h6c: gf_log = 8'hfa;
                8'h6d: gf_log = 8'h85;
                8'h6e: gf_log = 8'hba;
                8'h6f: gf_log = 8'h3d;
                8'h70: gf_log = 8'hca;
                8'h71: gf_log = 8'h5e;
                8'h72: gf_log = 8'h9b;
                8'h73: gf_log = 8'h9f;
                8'h74: gf_log = 8'h0a;
                8'h75: gf_log = 8'h15;
                8'h76: gf_log = 8'h79;
                8'h77: gf_log = 8'h2b;
                8'h78: gf_log = 8'h4e;
                8'h79: gf_log = 8'hd4;
                8'h7a: gf_log = 8'he5;
                8'h7b: gf_log = 8'hac;
                8'h7c: gf_log = 8'h73;
                8'h7d: gf_log = 8'hf3;
                8'h7e: gf_log = 8'ha7;
                8'h7f: gf_log = 8'h57;
                8'h80: gf_log = 8'h07;
                8'h81: gf_log = 8'h70;
                8'h82: gf_log = 8'hc0;
                8'h83: gf_log = 8'hf7;
                8'h84: gf_log = 8'h8c;
                8'h85: gf_log = 8'h80;
                8'h86: gf_log = 8'h63;
                8'h87: gf_log = 8'h0d;
                8'h88: gf_log = 8'h67;
                8'h89: gf_log = 8'h4a;
                8'h8a: gf_log = 8'hde;
                8'h8b: gf_log = 8'hed;
                8'h8c: gf_log = 8'h31;
                8'h8d: gf_log = 8'hc5;
                8'h8e: gf_log = 8'hfe;
                8'h8f: gf_log = 8'h18;
                8'h90: gf_log = 8'he3;
                8'h91: gf_log = 8'ha5;
                8'h92: gf_log = 8'h99;
                8'h93: gf_log = 8'h77;
                8'h94: gf_log = 8'h26;
                8'h95: gf_log = 8'hb8;
                8'h96: gf_log = 8'hb4;
                8'h97: gf_log = 8'h7c;
                8'h98: gf_log = 8'h11;
                8'h99: gf_log = 8'h44;
                8'h9a: gf_log = 8'h92;
                8'h9b: gf_log = 8'hd9;
                8'h9c: gf_log = 8'h23;
                8'h9d: gf_log = 8'h20;
                8'h9e: gf_log = 8'h89;
                8'h9f: gf_log = 8'h2e;
                8'ha0: gf_log = 8'h37;
                8'ha1: gf_log = 8'h3f;
                8'ha2: gf_log = 8'hd1;
                8'ha3: gf_log = 8'h5b;
                8'ha4: gf_log = 8'h95;
                8'ha5: gf_log = 8'hbc;
                8'ha6: gf_log = 8'hcf;
                8'ha7: gf_log = 8'hcd;
                8'ha8: gf_log = 8'h90;
                8'ha9: gf_log = 8'h87;
                8'haa: gf_log = 8'h97;
                8'hab: gf_log = 8'hb2;
                8'hac: gf_log = 8'hdc;
                8'had: gf_log = 8'hfc;
                8'hae: gf_log = 8'hbe;
                8'haf: gf_log = 8'h61;
                8'hb0: gf_log = 8'hf2;
                8'hb1: gf_log = 8'h56;
                8'hb2: gf_log = 8'hd3;
                8'hb3: gf_log = 8'hab;
                8'hb4: gf_log = 8'h14;
                8'hb5: gf_log = 8'h2a;
                8'hb6: gf_log = 8'h5d;
                8'hb7: gf_log = 8'h9e;
                8'hb8: gf_log = 8'h84;
                8'hb9: gf_log = 8'h3c;
                8'hba: gf_log = 8'h39;
                8'hbb: gf_log = 8'h53;
                8'hbc: gf_log = 8'h47;
                8'hbd: gf_log = 8'h6d;
                8'hbe: gf_log = 8'h41;
                8'hbf: gf_log = 8'ha2;
                8'hc0: gf_log = 8'h1f;
                8'hc1: gf_log = 8'h2d;
                8'hc2: gf_log = 8'h43;
                8'hc3: gf_log = 8'hd8;
                8'hc4: gf_log = 8'hb7;
                8'hc5: gf_log = 8'h7b;
                8'hc6: gf_log = 8'ha4;
                8'hc7: gf_log = 8'h76;
                8'hc8: gf_log = 8'hc4;
                8'hc9: gf_log = 8'h17;
                8'hca: gf_log = 8'h49;
                8'hcb: gf_log = 8'hec;
                8'hcc: gf_log = 8'h7f;
                8'hcd: gf_log = 8'h0c;
                8'hce: gf_log = 8'h6f;
                8'hcf: gf_log = 8'hf6;
                8'hd0: gf_log = 8'h6c;
                8'hd1: gf_log = 8'ha1;
                8'hd2: gf_log = 8'h3b;
                8'hd3: gf_log = 8'h52;
                8'hd4: gf_log = 8'h29;
                8'hd5: gf_log = 8'h9d;
                8'hd6: gf_log = 8'h55;
                8'hd7: gf_log = 8'haa;
                8'hd8: gf_log = 8'hfb;
                8'hd9: gf_log = 8'h60;
                8'hda: gf_log = 8'h86;
                8'hdb: gf_log = 8'hb1;
                8'hdc: gf_log = 8'hbb;
                8'hdd: gf_log = 8'hcc;
                8'hde: gf_log = 8'h3e;
                8'hdf: gf_log = 8'h5a;
                8'he0: gf_log = 8'hcb;
                8'he1: gf_log = 8'h59;
                8'he2: gf_log = 8'h5f;
                8'he3: gf_log = 8'hb0;
                8'he4: gf_log = 8'h9c;
                8'he5: gf_log = 8'ha9;
                8'he6: gf_log = 8'ha0;
                8'he7: gf_log = 8'h51;
                8'he8: gf_log = 8'h0b;
                8'he9: gf_log = 8'hf5;
                8'hea: gf_log = 8'h16;
                8'heb: gf_log = 8'heb;
                8'hec: gf_log = 8'h7a;
                8'hed: gf_log = 8'h75;
                8'hee: gf_log = 8'h2c;
                8'hef: gf_log = 8'hd7;
                8'hf0: gf_log = 8'h4f;
                8'hf1: gf_log = 8'hae;
                8'hf2: gf_log = 8'hd5;
                8'hf3: gf_log = 8'he9;
                8'hf4: gf_log = 8'he6;
                8'hf5: gf_log = 8'he7;
                8'hf6: gf_log = 8'had;
                8'hf7: gf_log = 8'he8;
                8'hf8: gf_log = 8'h74;
                8'hf9: gf_log = 8'hd6;
                8'hfa: gf_log = 8'hf4;
                8'hfb: gf_log = 8'hea;
                8'hfc: gf_log = 8'ha8;
                8'hfd: gf_log = 8'h50;
                8'hfe: gf_log = 8'h58;
                8'hff: gf_log = 8'haf;
                default: gf_log = 8'h00;
            endcase
        end
    endfunction

    function automatic [7:0] gf_mul;
        input [7:0] a;
        input [7:0] b;
        reg [8:0] sum;
    begin
        if (a == 0 || b == 0) begin
            gf_mul = 8'h00;
        end else begin
            sum = gf_log(a) + gf_log(b);
            if (sum >= 9'd255)
                sum = sum - 9'd255;
            gf_mul = gf_exp(sum[7:0]);
        end
    end
    endfunction

    function automatic [7:0] gf_inv;
        input [7:0] a;
        reg [8:0] idx;
    begin
        if (a == 0) begin
            gf_inv = 8'h00;
        end else begin
            idx = 9'd255 - gf_log(a);
            if (idx >= 9'd255)
                idx = idx - 9'd255;
            gf_inv = gf_exp(idx[7:0]);
        end
    end
    endfunction

    function automatic [7:0] gf_pow;
        input integer idx;
        integer adj;
    begin
        adj = idx % 255;
        if (adj < 0)
            adj = adj + 255;
        gf_pow = gf_exp(adj[7:0]);
    end
    endfunction

    // Syndrome 寄存
    reg [SYM_BW-1:0] S[0:R_NUM-1];
    integer i;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i = 0; i < R_NUM; i = i + 1) S[i] <= {SYM_BW{1'b0}};
        end else if (start) begin
            for (i = 0; i < R_NUM; i = i + 1)
                S[i] <= syndrome[i*SYM_BW +: SYM_BW];
                        $display("KES load S raw   : %02x %02x %02x %02x %02x %02x %02x %02x",
                     syndrome[0*SYM_BW +: SYM_BW], syndrome[1*SYM_BW +: SYM_BW],
                     syndrome[2*SYM_BW +: SYM_BW], syndrome[3*SYM_BW +: SYM_BW],
                     syndrome[4*SYM_BW +: SYM_BW], syndrome[5*SYM_BW +: SYM_BW],
                     syndrome[6*SYM_BW +: SYM_BW], syndrome[7*SYM_BW +: SYM_BW]);
        end
    end

    // BM 状态变量
    reg [SYM_BW-1:0] Lambda[0:T];
    reg [SYM_BW-1:0] B[0:T];
    reg [3:0] L;
    reg [3:0] m;
    reg [SYM_BW-1:0] b;
    reg [3:0] r;           // 当前处理的 syndrome 序号 0..11
    reg       running;

    // next-state
    reg [SYM_BW-1:0] Lambda_n[0:T];
    reg [SYM_BW-1:0] B_n[0:T];
    reg [3:0] L_n;
    reg [3:0] m_n;
    reg [SYM_BW-1:0] b_n;
    reg [3:0] r_n;
    reg       running_n;
    reg       done_n;
    reg [SYM_BW*5-1:0] lamda_n;
    reg [SYM_BW*4-1:0] omega_n;

    // 临时
    reg [SYM_BW-1:0] d_calc;   // discrepancy
    reg [SYM_BW-1:0] scale;
    reg [SYM_BW-1:0] acc;
    integer j, k;

    // 组合：下一状态与输出计算
    always @* begin
        // 默认保持
        for (j = 0; j <= T; j = j + 1) begin
            Lambda_n[j] = Lambda[j];
            B_n[j]      = B[j];
        end
        L_n       = L;
        m_n       = m;
        b_n       = b;
        r_n       = r;
        running_n = running;
        done_n    = 1'b0;
        lamda_n   = lamda;
        omega_n   = omega;
        d_calc    = {SYM_BW{1'b0}};
        scale     = {SYM_BW{1'b0}};

        if (start) begin
            // 初始化 BM 变量
            for (j = 0; j <= T; j = j + 1) begin
                Lambda_n[j] = (j == 0) ? {{(SYM_BW-1){1'b0}},1'b1} : {SYM_BW{1'b0}};
                B_n[j]      = (j == 0) ? {{(SYM_BW-1){1'b0}},1'b1} : {SYM_BW{1'b0}};
            end
            L_n       = 4'd0;
            m_n       = 4'd1;
            b_n       = {{(SYM_BW-1){1'b0}},1'b1};
            r_n       = 4'd0;
            running_n = 1'b1;
            lamda_n   = {SYM_BW*5{1'b0}};
            omega_n   = {SYM_BW*4{1'b0}};
        end else if (running) begin
            // d = S[r] ⊕ Σ_{i=1..L} λ_i * S[r-i]
            d_calc = S[r];
            for (j = 1; j <= T; j = j + 1) begin
                if ((j <= L) && (r >= j))
                    d_calc = d_calc ^ gf_mul(Lambda[j], S[r-j]);
            end

            if (d_calc != 0) begin
                scale = gf_mul(d_calc, gf_inv(b));
                // Lambda = Lambda ⊕ scale * x^m * B
                for (j = 0; j <= T; j = j + 1) begin
                    if (j >= m && (j - m) <= T)
                        Lambda_n[j] = Lambda[j] ^ gf_mul(scale, B[j-m]);
                end
                if ((L << 1) <= r) begin
                    L_n = r + 1 - L;
                    for (j = 0; j <= T; j = j + 1) B_n[j] = Lambda[j];
                    b_n = d_calc;
                    m_n = 4'd1;
                end else begin
                    m_n = m + 4'd1;
                end
            end else begin
                m_n = m + 4'd1;
            end

            if (r == R_NUM-1) begin
                running_n = 1'b0;
                done_n    = 1'b1;
                // 输出 λ
                for (j = 0; j <= T; j = j + 1)
                    lamda_n[j*SYM_BW +: SYM_BW] = Lambda_n[j];
                // 输出 Ω_k = Σ_{i=0..k} Λ_i * S_{k-i}
                for (k = 0; k < T; k = k + 1) begin
                    acc = {SYM_BW{1'b0}};
                    for (j = 0; j <= k; j = j + 1)
                        acc = acc ^ gf_mul(Lambda_n[j], S[k - j]);
                    omega_n[k*SYM_BW +: SYM_BW] = acc;
                end
            end else begin
                r_n = r + 4'd1;
            end
        end
    end

    // 时序寄存
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i = 0; i <= T; i = i + 1) begin
                Lambda[i] <= (i == 0) ? {{(SYM_BW-1){1'b0}},1'b1} : {SYM_BW{1'b0}};
                B[i]      <= (i == 0) ? {{(SYM_BW-1){1'b0}},1'b1} : {SYM_BW{1'b0}};
            end
            L       <= 4'd0;
            m       <= 4'd1;
            b       <= {{(SYM_BW-1){1'b0}},1'b1};
            r       <= 4'd0;
            running <= 1'b0;
            done    <= 1'b0;
            lamda   <= {SYM_BW*5{1'b0}};
            omega   <= {SYM_BW*4{1'b0}};
        end else begin
            for (i = 0; i <= T; i = i + 1) begin
                Lambda[i] <= Lambda_n[i];
                B[i]      <= B_n[i];
            end
            L       <= L_n;
            m       <= m_n;
            b       <= b_n;
            r       <= r_n;
            running <= running_n;
            done    <= done_n;
            lamda   <= lamda_n;
            omega   <= omega_n;
            if (done_n) begin
                $display("KES debug: lamda=%h omega=%h", lamda_n, omega_n);
            end
        end
    end

endmodule
