`timescale 1ns / 1ps
/**
 * 
 * READ THIS DESCRIPTION:
 *
 * This is the Wrapper module that will serve as the header file combining your processor, 
 * RegFile and Memory elements together.
 *
 * This file will be used to generate the bitstream to upload to the FPGA.
 * We have provided a sibling file, Wrapper_tb.v so that you can test your processor's functionality.
 * 
 * We will be using our own separate Wrapper_tb.v to test your code. You are allowed to make changes to the Wrapper files 
 * for your own individual testing, but we expect your final processor.v and memory modules to work with the 
 * provided Wrapper interface.
 * 
 * Refer to Lab 5 documents for detailed instructions on how to interface 
 * with the memory elements. Each imem and dmem modules will take 12-bit 
 * addresses and will allow for storing of 32-bit values at each address. 
 * Each memory module should receive a single clock. At which edges, is 
 * purely a design choice (and thereby up to you). 
 * 
 * You must change line 36 to add the memory file of the test you created using the assembler
 * For example, you would add sample inside of the quotes on line 38 after assembling sample.s
 *
 **/

module Wrapper (clk_100mhz, reset, JD, hSync, vSync, VGA_R, VGA_G, VGA_B);
    input clk_100mhz, reset;
    input [10:1] JD; // Controller input
    output hSync, vSync; // VGA sync signals
    output [3:0] VGA_R, VGA_G, VGA_B; // VGA RGB signals
	
	wire clock;
	assign clock = clk_25mhz;
	   
	wire clock_25mhz;
	wire locked;
	clk_wiz_0 pll (
      // Clock out ports
      .clk_out1(clk_25mhz),
      // Status and control signals
      .reset(reset),
      .locked(locked),
     // Clock in ports
      .clk_in1(clk_100mhz)
    );
    
	wire rwe, mwe;
	wire[4:0] rd, rs1, rs2;
	wire[31:0] instAddr, instData, 
		rData, regA, regB,
		memAddr, memDataIn, memDataOut;

	// MMIO Signals
    wire [31:0] mmioDataOut;
    wire mmioAccess = (memAddr[31:16] == 16'hFFFF) && (memAddr[15:8] == 8'h00); // Detect MMIO range

    // RAM Signals
    wire [31:0] ramDataOut;
    wire ramAccess = (memAddr[31:12] == 0); // RAM is accessed when address is within 0x00000000 to 0x00000FFF

	// BulletRAM Signals
    wire [31:0] bulletRamDataOut;
    wire bulletRamAccess = (memAddr[31:16] == 16'h4000); // BulletRAM range: 0x4000_0000 - 0x4000_00FF
    wire [31:0] bulletRamDataIn = memDataIn;
    wire bulletRamWriteEnable = mwe && bulletRamAccess;
    wire bulletRamReadEnable = ~mwe && bulletRamAccess;
    wire [5:0] bulletRamAddress = memAddr[7:2]; // Use bits [7:2] for 64 entries
    wire [2047:0] allBulletContents;

	// ADD YOUR MEMORY FILE HERE
	localparam INSTR_FILE = "C:/Users/hah50/Downloads/ece-350-tank-shooter/CPU/Test Files/Memory Files/project_test";
	
	// Main Processing Unit
	processor CPU(.clock(clock), .reset(reset), 
								
		// ROM
		.address_imem(instAddr), .q_imem(instData),
									
		// Regfile
		.ctrl_writeEnable(rwe),     .ctrl_writeReg(rd),
		.ctrl_readRegA(rs1),     .ctrl_readRegB(rs2), 
		.data_writeReg(rData), .data_readRegA(regA), .data_readRegB(regB),
									
		// RAM
		.wren(mwe), 
		.address_dmem(memAddr), 
		.data(memDataIn), 
		.q_dmem(mmioAccess ? mmioDataOut : 
                (bulletRamAccess ? bulletRamDataOut : ramDataOut)) // Select data from MMIO, BulletRAM, or RAM
    );
	
	// Instruction Memory (ROM)
	ROM #(.MEMFILE({INSTR_FILE, ".mem"}))
	InstMem(.clk(clock), 
		.addr(instAddr[11:0]), 
		.dataOut(instData));
		
	
	// Register File
	regfile RegisterFile(.clock(clock), 
		.ctrl_writeEnable(rwe), .ctrl_reset(reset), 
		.ctrl_writeReg(rd),
		.ctrl_readRegA(rs1), .ctrl_readRegB(rs2), 
		.data_writeReg(rData), .data_readRegA(regA), .data_readRegB(regB));
						
	// Processor Memory (RAM)
	RAM ProcMem (
        .clk(clock), 
        .wEn(mwe && ramAccess), // Write enable for RAM
        .addr(memAddr[11:0]), 
        .dataIn(memDataIn), 
        .dataOut(ramDataOut)
    );

	// MMIO Module
    MMIO mmio_unit (
        .clk(clock),
        .reset(reset),
        .address(memAddr),        // Full 32-bit address from the processor
        .readEn(~mwe && mmioAccess), // MMIO read enable
        .readData(mmioDataOut),   // Data read from MMIO
        .JD(JD)                   // Controller input
    );

	// BulletRAM Module
    BulletRAM #(
        .DATA_WIDTH(32),
        .ADDRESS_WIDTH(6),
        .DEPTH(64)
    ) BulletRAMInstance (
        .clk(clock),
        .wEn(bulletRamWriteEnable), // Write enable for BulletRAM
        .readEn(bulletRamReadEnable), // Read enable for BulletRAM
        .addr(bulletRamAddress),    // Address for BulletRAM
        .dataIn(bulletRamDataIn),   // Data to write into BulletRAM
        .dataOut(bulletRamDataOut),  // Data read from BulletRAM
        .allContents(allBulletContents)    // 2048-bit output with all contents
    );

	// VGA Controller
    VGAController VGAControllerInstance (
        .clk(clk_100mhz),
        .reset(reset),
        .hSync(hSync),
        .vSync(vSync),
        .VGA_R(VGA_R),
        .VGA_G(VGA_G),
        .VGA_B(VGA_B),
        .ps2_clk(),   // Leave unconnected for now
        .ps2_data(),  // Leave unconnected for now
        .CPU_RESETN(),// Leave unconnected for now
        .BTNC(),      // Leave unconnected for now
        .BTNU(),      // Leave unconnected for now
        .BTNL(),      // Leave unconnected for now
        .BTNR(),      // Leave unconnected for now
        .BTND(),      // Leave unconnected for now
        .JD(JD),       // Pass controller input to VGA Controller
		.allBulletContents(allBulletContents) // Pass all bullet contents to VGA Controller
    );



endmodule
