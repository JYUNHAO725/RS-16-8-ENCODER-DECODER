`timescale 1ns/1ps
//
// Testbench for RS(16,8) decoder
// - Generate 8 info symbols (0..7)
// - Encode to 16 symbols, optionally inject up to 4 errors
// - Decode and verify the first 8 symbols match
//
module tb_rs_decoder_16_8;

    // Configuration
    localparam integer ERR_NUM = 3; // 0..4
    reg [7:0] ERR_POS [0:3]; // 1-based positions, unused set to 0
    reg [7:0] ERR_VAL [0:3]; // xor values
    initial begin
        ERR_POS[0] = 8'd3;  ERR_VAL[0] = 8'h11;
        ERR_POS[1] = 8'd9;  ERR_VAL[1] = 8'h22;
        ERR_POS[2] = 8'd14; ERR_VAL[2] = 8'h33;
        ERR_POS[3] = 8'd0;  ERR_VAL[3] = 8'h00;
    end

    // Clock / reset
    reg clk = 1'b0;
    reg rst_n = 1'b0;
    always #5 clk = ~clk;

    // Encoder interface
    reg        enc_din_val = 1'b0;
    reg        enc_din_sop = 1'b0;
    reg  [7:0] enc_din     = 8'h00;
    wire       enc_dout_val;
    wire       enc_dout_sop;
    wire       enc_dout_eop;
    wire [7:0] enc_dout;

    rs_encoder_16_8 u_enc (
        .clk      (clk),
        .rst_n    (rst_n),
        .din_val  (enc_din_val),
        .din_sop  (enc_din_sop),
        .din      (enc_din),
        .dout_val (enc_dout_val),
        .dout_sop (enc_dout_sop),
        .dout_eop (enc_dout_eop),
        .dout     (enc_dout)
    );

    // Decoder interface
    reg        dec_din_val = 1'b0;
    reg        dec_din_sop = 1'b0;
    reg        dec_din_eop = 1'b0;
    reg  [7:0] dec_din     = 8'h00;
    wire [7:0] symb_out_cnt;
    wire       symb_out_val;
    wire [7:0] symb_corrected;

    rs_decoder_16_8 u_dec (
        .clk            (clk),
        .rst_n          (rst_n),
        .din_val        (dec_din_val),
        .din_sop        (dec_din_sop),
        .din_eop        (dec_din_eop),
        .din            (dec_din),
        .symb_out_cnt   (symb_out_cnt),
        .symb_out_val   (symb_out_val),
        .symb_corrected (symb_corrected)
    );

    reg [7:0] codeword [0:15];
    reg [7:0] codeword_orig [0:15];
    reg [7:0] decoded [0:15];
    integer i;
    integer cw_idx;
    integer idle_cycles;
    integer err_cnt;

    initial begin
        $dumpfile("tb_rs_decoder_16_8.vcd");
        $dumpvars(0, tb_rs_decoder_16_8);

        #(20);
        rst_n = 1'b1;

        // Encode one frame and capture 16 symbols
        cw_idx = 0;
        idle_cycles = 0;
        fork
            begin : ENC_DRIVE
                @(negedge clk);
                enc_din_sop = 1'b1;
                enc_din_val = 1'b1;
                enc_din     = 8'd0;
                for (i = 0; i < 8; i = i + 1) begin
                    @(negedge clk);
                    enc_din_sop = 1'b0;
                    enc_din     = i[7:0];
                end
                @(negedge clk);
                enc_din_val = 1'b0;
                enc_din     = 8'h00;
            end
            begin : ENC_CAPTURE
                while (!enc_dout_val && idle_cycles < 2000) begin
                    @(posedge clk);
                    idle_cycles = idle_cycles + 1;
                end
                if (enc_dout_val) begin
                    #1;
                    codeword[cw_idx] = enc_dout;
                    cw_idx = cw_idx + 1;
                    idle_cycles = 0;
                    while ((cw_idx < 16) && (idle_cycles < 2000)) begin
                        @(posedge clk);
                        if (enc_dout_val) begin
                            #1;
                            codeword[cw_idx] = enc_dout;
                            cw_idx = cw_idx + 1;
                            idle_cycles = 0;
                        end else begin
                            idle_cycles = idle_cycles + 1;
                        end
                    end
                end
            end
        join

        if (cw_idx != 16) begin
            $display("Encoder capture timeout: got %0d of 16", cw_idx);
        end else begin
            $display("Encoder captured %0d symbols", cw_idx);
            for (i = 0; i < 8; i = i + 1)
                $display("  p%0d=0x%02x", i, codeword[8+i]);
        end

        for (i = 0; i < 16; i = i + 1)
            codeword_orig[i] = codeword[i];

        // Inject errors
        $display("Inject %0d errors:", ERR_NUM);
        for (i = 0; i < ERR_NUM; i = i + 1) begin
            if (ERR_POS[i] > 0 && ERR_POS[i] <= 16) begin
                $display("  pos=%0d xor=0x%02x before=0x%02x -> after=0x%02x",
                         ERR_POS[i], ERR_VAL[i],
                         codeword[ERR_POS[i]-1],
                         codeword[ERR_POS[i]-1] ^ ERR_VAL[i]);
                codeword[ERR_POS[i]-1] = codeword[ERR_POS[i]-1] ^ ERR_VAL[i];
            end
        end

        // Feed decoder
        @(negedge clk);
        dec_din_sop = 1'b1;
        dec_din_val = 1'b1;
        dec_din     = codeword[0];
        for (i = 1; i < 16; i = i + 1) begin
            @(negedge clk);
            dec_din_sop = 1'b0;
            dec_din     = codeword[i];
            dec_din_eop = (i == 15);
        end
        @(negedge clk);
        dec_din_val = 1'b0;
        dec_din_eop = 1'b0;
        dec_din     = 8'h00;

        // Capture decoder output
        i = 0;
        idle_cycles = 0;
        while ((i < 16) && (idle_cycles < 20000)) begin
            @(posedge clk);
            if (symb_out_val) begin
                decoded[i] = symb_corrected;
                i = i + 1;
                idle_cycles = 0;
            end else begin
                idle_cycles = idle_cycles + 1;
            end
        end
        if (i != 16)
            $display("FAIL: decode output timeout (got %0d of 16)", i);

        // Check info symbols
        err_cnt = 0;
        for (i = 0; i < 8; i = i + 1) begin
            if (decoded[i] !== i[7:0]) begin
                err_cnt = err_cnt + 1;
                $display("Mismatch at info symbol %0d: expected %0d got %0d", i, i[7:0], decoded[i]);
            end
        end
        if (err_cnt == 0)
            $display("PASS: info symbols all match (errors injected: %0d)", ERR_NUM);
        else
            $display("FAIL: %0d mismatches", err_cnt);

        #50;
        $finish;
    end

    initial begin
        #1000000;
        $display("GLOBAL TIMEOUT reached, forcing finish");
        $finish;
    end

endmodule
