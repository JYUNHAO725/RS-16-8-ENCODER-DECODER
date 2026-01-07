`timescale 1ns/1ps
module fifo_buffer #(
    parameter WIDTH = 8,
    parameter DEPTH = 132
)(
    input               clk,
    input               rst,   // active high
    input               rd,
    input               wr,
    input  [WIDTH-1:0]  datain,
    output reg [WIDTH-1:0] dataout,
    output              empty,
    output              full
);

    // 对 132 深度，需要 8bit 地址
    localparam PTR_W = 8;

    reg [WIDTH-1:0] mem [0:DEPTH-1];
    reg [PTR_W:0]   count;
    reg [PTR_W-1:0] rptr, wptr;

    always @(posedge clk) begin
        if (rst) begin
            count  <= 0;
            rptr   <= 0;
            wptr   <= 0;
            dataout<= 0;
        end else begin
            case ({rd, wr})
                2'b01: begin // write
                    mem[wptr] <= datain;
                    wptr      <= (wptr == DEPTH-1) ? 0 : wptr + 1;
                    count     <= count + 1;
                end
                2'b10: begin // read
                    dataout   <= mem[rptr];
                    rptr      <= (rptr == DEPTH-1) ? 0 : rptr + 1;
                    count     <= count - 1;
                end
                2'b11: begin // simultaneous
                    mem[wptr] <= datain;
                    wptr      <= (wptr == DEPTH-1) ? 0 : wptr + 1;
                    dataout   <= mem[rptr];
                    rptr      <= (rptr == DEPTH-1) ? 0 : rptr + 1;
                end
                default: ;
            endcase
        end
    end

    assign empty = (count == 0);
    assign full  = (count == DEPTH);

endmodule
