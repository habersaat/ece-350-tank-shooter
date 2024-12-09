`timescale 1ns / 1ps
module VRAM #( parameter DATA_WIDTH = 8, ADDRESS_WIDTH = 8, DEPTH = 256, MEMFILE = "") (
    input wire                     clk,
    input wire [ADDRESS_WIDTH-1:0] addr,
    output reg [DATA_WIDTH-1:0]    dataOut);
    
    reg[DATA_WIDTH-1:0] MemoryArray[0:DEPTH-1];
    
    initial begin
        if(MEMFILE > 0) begin
            $readmemh(MEMFILE, MemoryArray);
        end
    end
    
    always @(posedge clk) begin
        dataOut <= MemoryArray[addr];
    end
endmodule
