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
    output reg [DATA_WIDTH-1:0]    dataOut
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
endmodule
