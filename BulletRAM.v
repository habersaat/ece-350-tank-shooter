`timescale 1ns / 1ps
module BulletRAM #( 
    parameter DATA_WIDTH = 32,     // Width for a bullet's parameters
    parameter ADDRESS_WIDTH = 6,   // 64 bullets max (2^6)
    parameter DEPTH = 64,          // Number of bullets
    parameter MEMFILE = ""
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
    
    // Initialize the memory array
    initial begin
        if(MEMFILE > 0) begin
            $readmemh(MEMFILE, MemoryArray);
        end
    end

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
