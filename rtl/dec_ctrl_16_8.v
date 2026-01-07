`timescale 1ns/1ps
module dec_ctrl_16_8 (
    input        clk,
    input        rst_n,
    input        start,          // 鑴夊啿锛岄敊璇€煎氨缁悗寮€濮嬭 FIFO
    output reg   fifo_rd,
    input  [7:0] fifo_out,
    output reg [7:0] symbol_cnt,
    output reg [7:0] symbol_out,
    output reg       running_o
);

    localparam integer N_NUM = 16;

    reg [7:0] cnt;       // 褰撳墠杈撳嚭鐨勭鍙疯鏁帮紙1..132锛?
    reg       running;   // 璇诲嚭杩涜涓?
    reg       start_latched; // 鎹曡幏 start 鑴夊啿
    integer dbg_cnt;
    // 寤惰繜 1 鎷嶉噰鏍?FIFO 杈撳嚭锛岄伩鍏嶄笌鍚屾璇诲啓鍦ㄥ悓涓€鎷嶅嚭鐜版棫鏁版嵁
    reg       fifo_rd_d;
    reg [7:0] cnt_d;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cnt      <= 0;
            running  <= 0;
            start_latched <= 1'b0;
            fifo_rd  <= 0;
            symbol_cnt <= 0;
            symbol_out <= 0;
            running_o <= 1'b0;
            dbg_cnt  <= 0;
            fifo_rd_d <= 1'b0;
            cnt_d     <= 8'd0;
        end else begin
            fifo_rd <= 1'b0; // 榛樿涓嶈
            // latch start 鑴夊啿锛岀洿鍒拌瀹?132 涓鍙?
            if (start)
                start_latched <= 1'b1;
            else if (running && cnt == N_NUM)
                start_latched <= 1'b0;

            if (start) begin
                running <= 1'b1;    // 鍚姩璇诲嚭
                cnt     <= 8'd1;    // 浠庣鍙?1 寮€濮?
                fifo_rd <= 1'b1;    // 绔嬪埢鍙戝嚭璇讳俊鍙?
            end else if (running || start_latched) begin
                running <= 1'b1;
                fifo_rd <= 1'b1;    // 璇讳笅涓€涓鍙?
                if (cnt == N_NUM) begin
                    running <= 1'b0; // 璇绘弧 132 涓悗鍋滄
                    start_latched <= 1'b0;
                end else begin
                    cnt <= cnt + 1'b1;
                end
            end
            // 璁板綍鏈媿鐨?rd锛屼笅涓€鎷嶈緭鍑哄搴旀暟鎹笌璁℃暟
            fifo_rd_d <= fifo_rd;
            cnt_d     <= cnt;
            if (fifo_rd_d) begin
                symbol_out <= fifo_out;
                symbol_cnt <= cnt_d;
            end else begin
                symbol_out <= symbol_out;
                symbol_cnt <= running ? symbol_cnt : 8'd0;
            end
            running_o <= running;

            if ((start || running) && dbg_cnt < 20) begin
                $display("dec_ctrl dbg: start=%b start_lat=%b running=%b fifo_rd=%b cnt=%0d symbol_cnt=%0d fifo_out=0x%02x t=%0t",
                         start, start_latched, running, fifo_rd, cnt, symbol_cnt, fifo_out, $time);
                dbg_cnt <= dbg_cnt + 1;
            end
        end
    end

endmodule

