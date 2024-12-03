`timescale 1ns / 1ps
module BulletRAM #( 
    parameter DATA_WIDTH = 32,     // Width for a bullet's parameters
    parameter ADDRESS_WIDTH = 8,   // 256 bullets max (2^8)
    parameter DEPTH = 256          // Number of bullets
) (
    input wire                     clk,
    input wire                     wEn,
    input wire                     readEn,
    input wire [ADDRESS_WIDTH-1:0] addr,
    input wire [DATA_WIDTH-1:0]    dataIn,
    output reg [DATA_WIDTH-1:0]    dataOut
);
    // Define the memory array
    reg [DATA_WIDTH-1:0] MemoryArray[0:DEPTH-1];
    
    // Write and read logic
    always @(posedge clk) begin
        if (wEn) begin
            MemoryArray[addr] <= dataIn; // Write data to memory
        end 
        if (readEn) begin
            dataOut <= MemoryArray[addr]; // Read data from memory
        end
    end
endmodule
