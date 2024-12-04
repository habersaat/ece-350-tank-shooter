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
    output reg [DATA_WIDTH-1:0]    dataOut,
    output wire [DATA_WIDTH*DEPTH-1:0] allContents // 2048-bit output
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

    // Concatenate all contents of the memory array into a single wire
    generate
        genvar i;
        for (i = 0; i < DEPTH; i = i + 1) begin
            assign allContents[(i+1)*DATA_WIDTH-1:i*DATA_WIDTH] = MemoryArray[i];
        end
    endgenerate
endmodule
