`timescale 1ns / 1ps
module HealthRAM #( 
    parameter DATA_WIDTH = 32,     // Width for each health value
    parameter ADDRESS_WIDTH = 1,   // 2 entries max (2^1)
    parameter DEPTH = 2,           // Number of entries (player1_health, player2_health)
    parameter MEMFILE = ""
) (
    input wire                     clk,
    input wire                     wEn,
    input wire                     readEn,
    input wire [ADDRESS_WIDTH-1:0] addr,
    input wire [DATA_WIDTH-1:0]    dataIn,
    output reg [DATA_WIDTH-1:0]    dataOut,
    output wire [DATA_WIDTH*DEPTH-1:0] allContents // 64-bit output (32 * 2)
);
    // Define the memory array
    reg [DATA_WIDTH-1:0] MemoryArray[0:DEPTH-1];
    
    // Initialize the memory array
    initial begin
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

    // Concatenate all contents of the memory array into a single wire
    generate
        genvar i;
        for (i = 0; i < DEPTH; i = i + 1) begin
            assign allContents[(i+1)*DATA_WIDTH-1:i*DATA_WIDTH] = MemoryArray[i];
        end
    endgenerate
endmodule
