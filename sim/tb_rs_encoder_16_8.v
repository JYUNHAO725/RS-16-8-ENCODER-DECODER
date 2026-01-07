`timescale 1ns/1ps
//
// Testbench for RS(16,8) encoder (GF(256))
// - Feeds one frame of 8 symbols (incrementing 0..7)
// - Observes 16 output symbols: first 8 should match inputs, last 8 are parity
// - Generates VCD for waveform viewing
//
module tb_rs_encoder_16_8;

    // Clock / reset
    reg clk   = 1'b0;
    reg rst_n = 1'b0;
    always #5 clk = ~clk; // 100 MHz

    // DUT interface
    reg        din_val = 1'b0;
    reg        din_sop = 1'b0;
    reg [7:0]  din     = 8'h00;
    wire       dout_val;
    wire       dout_sop;
    wire       dout_eop;
    wire [7:0] dout;

    // Instantiate DUT
    rs_encoder_16_8 dut (
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

    integer i;

    initial begin
        $dumpfile("tb_rs_encoder_16_8.vcd");
        $dumpvars(0, tb_rs_encoder_16_8);

        // Reset
        #(20);
        rst_n = 1'b1;

        // 椹卞姩涓庢崟鑾峰苟琛岃繘琛岋紝閬垮厤涓㈠け杈撳嚭
        fork
            // 椹卞姩杈撳叆甯э紙鎭板ソ 8 涓鍙凤級
            begin : DRIVE
                @(negedge clk);
                din_val = 1'b1;
                for (i = 0; i < 8; i = i + 1) begin
                    @(negedge clk);
                    din_sop = (i == 0);
                    din     = i[7:0];
                end
                @(negedge clk);
                din_val = 1'b0;
                din_sop = 1'b0;
                din     = 8'h00;
            end

            // 鎹曡幏 16 涓緭鍑猴紝甯﹁秴鏃朵繚鎶?
            begin : CAPTURE
                reg [7:0] codeword [0:15];
                integer idx;
                integer err_cnt;
                integer idle_cycles;
                idx = 0;
                err_cnt = 0;
                idle_cycles = 0;

                // 绛夊緟棣栦釜鏈夋晥杈撳嚭锛坉out_sop锛夛紝骞跺厛璁板綍绗?1 涓鍙?
                while (!dout_val) @(posedge clk);
                codeword[idx] = dout;
                idx = idx + 1;
                $display("Capturing encoder outputs...");

                // 缁х画鏀堕泦鍓╀綑绗﹀彿锛岃秴杩?2000 鎷嶆湭鎷垮埌鍒欒秴鏃?
                while ((idx < 16) && (idle_cycles < 2000)) begin
                    @(posedge clk);
                    if (dout_val) begin
                        codeword[idx] = dout;
                        idx = idx + 1;
                        idle_cycles = 0;
                    end else begin
                        idle_cycles = idle_cycles + 1;
                    end
                end

                if (idx != 16) begin
                    $display("FAIL: timed out capturing outputs (got %0d of 16)", idx);
                end else begin
                    for (idx = 0; idx < 8; idx = idx + 1) begin
                        if (codeword[idx] !== idx[7:0]) begin
                            $display("Mismatch at symbol %0d: expected %0d got %0d", idx, idx[7:0], codeword[idx]);
                            err_cnt = err_cnt + 1;
                        end
                    end
                    if (err_cnt == 0)
                        $display("PASS: info symbols match (0..7). Parity captured in codeword[8..15].");
                    else
                        $display("FAIL: %0d mismatches in info symbols.", err_cnt);
                end
            end
        join

        $finish;
    end

endmodule

