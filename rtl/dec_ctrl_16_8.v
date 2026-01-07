`timescale 1ns/1ps
module dec_ctrl_16_8 (
    input        clk,
    input        rst_n,
    input        start,          // 脉冲，错误值就绪后开始读 FIFO
    output reg   fifo_rd,
    input  [7:0] fifo_out,
    output reg [7:0] symbol_cnt,
    output reg [7:0] symbol_out,
    output reg       running_o
);

    localparam integer N_NUM = 16;

    reg [7:0] cnt;       // 当前输出的符号计数（1..132）
    reg       running;   // 读出进行中
    reg       start_latched; // 捕获 start 脉冲
    integer dbg_cnt;
    // 延迟 1 拍采样 FIFO 输出，避免与同步读写在同一拍出现旧数据
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
            fifo_rd <= 1'b0; // 默认不读
            // latch start 脉冲，直到读完 132 个符号
            if (start)
                start_latched <= 1'b1;
            else if (running && cnt == N_NUM)
                start_latched <= 1'b0;

            if (start) begin
                running <= 1'b1;    // 启动读出
                cnt     <= 8'd1;    // 从符号 1 开始
                fifo_rd <= 1'b1;    // 立刻发出读信号
            end else if (running || start_latched) begin
                running <= 1'b1;
                fifo_rd <= 1'b1;    // 读下一个符号
                if (cnt == N_NUM) begin
                    running <= 1'b0; // 读满 132 个后停止
                    start_latched <= 1'b0;
                end else begin
                    cnt <= cnt + 1'b1;
                end
            end
            // 记录本拍的 rd，下一拍输出对应数据与计数
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
