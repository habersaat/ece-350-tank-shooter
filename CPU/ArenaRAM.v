`timescale 1ns / 1ps
module ArenaRAM #( 
    parameter DATA_WIDTH = 32,      // Width for each border pixel location
    parameter ADDRESS_WIDTH = 10,   // 1024 locations max (2^10)
    parameter DEPTH = 1024,         // Number of border pixel locations
    parameter MEMFILE = ""
) (
    input wire                     clk,
    input wire                     wEn,
    input wire                     readEn,
    input wire [ADDRESS_WIDTH-1:0] addr,
    input wire [DATA_WIDTH-1:0]    dataIn,
    output reg [DATA_WIDTH-1:0]    dataOut,
    output wire [DATA_WIDTH*DEPTH-1:0] allContents // Wire for all memory contents
);
    // Define the memory array
    reg [DATA_WIDTH-1:0] MemoryArray[0:DEPTH-1];
    
    // Initialize the memory array
    initial begin : MEMORY_INIT
        if (MEMFILE > 0) begin
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

    // Concatenate all memory contents into the allContents wire
    generate
        genvar i;
        for (i = 0; i < DEPTH; i = i + 1) begin
            assign allContents[(i+1)*DATA_WIDTH-1:i*DATA_WIDTH] = MemoryArray[i];
        end
    endgenerate
endmodule
