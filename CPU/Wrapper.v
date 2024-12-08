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

module Wrapper (clk_100mhz, reset, JD, JC, hSync, vSync, VGA_R, VGA_G, VGA_B);
    input clk_100mhz, reset;
    input [10:1] JD; // Controller input
    input [10:1] JC; 
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

    // SpriteRAM Signals
    wire [31:0] spriteRamDataOut;
    wire spriteRamAccess = (memAddr[31:16] == 16'h5000); // SpriteRAM range: 0x5000_0000 - 0x5000_00FF
    wire [31:0] spriteRamDataIn = memDataIn;
    wire spriteRamWriteEnable = mwe && spriteRamAccess;
    wire spriteRamReadEnable = ~mwe && spriteRamAccess;
    wire [1:0] spriteRamAddress = memAddr[3:2]; // Use bits [3:2] for 4 entries
    wire [127:0] allSpriteContents;

    // HealthRAM Signals
    wire [31:0] healthRamDataOut;
    wire healthRamAccess = (memAddr[31:16] == 16'h6000); // HealthRAM range: 0x6000_0000 - 0x6000_00FF
    wire [31:0] healthRamDataIn = memDataIn;
    wire healthRamWriteEnable = mwe && healthRamAccess;
    wire healthRamReadEnable = ~mwe && healthRamAccess;
    wire [0:0] healthRamAddress = memAddr[2]; // Use bit [2] for 2 entries
    wire [63:0] allHealthContents;

    // ArenaRAM Signals
    wire [31:0] arenaRamDataOut;
    wire arenaRamAccess = (memAddr[31:16] == 16'h7000); // ArenaRAM range: 0x7000_0000 - 0x7000_03FF
    wire [31:0] arenaRamDataIn = memDataIn;
    wire arenaRamWriteEnable = mwe && arenaRamAccess;
    wire arenaRamReadEnable = ~mwe && arenaRamAccess;
    wire [9:0] arenaRamAddress = memAddr[11:2]; // Use bits [11:2] for 1024 entries


	// ADD YOUR MEMORY FILE HERE
	localparam INSTR_FILE = "C:/Users/hah50/Downloads/ece-350-tank-shooter/CPU/Test Files/Memory Files/tank_shooter";
	
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
            bulletRamAccess ? bulletRamDataOut : 
            spriteRamAccess ? spriteRamDataOut :
            healthRamAccess ? healthRamDataOut :
            arenaRamAccess ? arenaRamDataOut :
            ramDataOut) // Select data from MMIO, BulletRAM, SpriteRAM, HealthRAM, ArenaRAM, or RAM
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
        .address(memAddr),              // Full 32-bit address from the processor
        .readEn(~mwe && mmioAccess),    // MMIO read enable
        .readData(mmioDataOut),         // Data read from MMIO
        .JD(JD),                        // Controller input JD
        .JC(JC)                         // Controller input JC
    );

    // SpriteRAM Module
    SpriteRAM #(
        .DATA_WIDTH(32),
        .ADDRESS_WIDTH(2),
        .DEPTH(4)
    ) SpriteRAMInstance (
        .clk(clock),
        .wEn(spriteRamWriteEnable), // Write enable for SpriteRAM
        .readEn(spriteRamReadEnable), // Read enable for SpriteRAM
        .addr(spriteRamAddress),    // Address for SpriteRAM
        .dataIn(spriteRamDataIn),   // Data to write into SpriteRAM
        .dataOut(spriteRamDataOut), // Data read from SpriteRAM
        .allContents(allSpriteContents) // 128-bit output with all contents
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

    // HealthRAM Module
    HealthRAM #(
        .DATA_WIDTH(32),
        .ADDRESS_WIDTH(1),
        .DEPTH(2)
    ) HealthRAMInstance (
        .clk(clock),
        .wEn(healthRamWriteEnable), // Write enable for HealthRAM
        .readEn(healthRamReadEnable), // Read enable for HealthRAM
        .addr(healthRamAddress),    // Address for HealthRAM
        .dataIn(healthRamDataIn),   // Data to write into HealthRAM
        .dataOut(healthRamDataOut), // Data read from HealthRAM
        .allContents(allHealthContents) // 64-bit output with all contents
    );

    // ArenaRAM Module
    ArenaRAM #(
        .DATA_WIDTH(32),
        .ADDRESS_WIDTH(10),
        .DEPTH(1024),
        .MEMFILE("arena_ram_init.mem")
    ) ArenaRAMInstance (
        .clk(clock),
        .wEn(arenaRamWriteEnable),  // Write enable for ArenaRAM
        .readEn(arenaRamReadEnable), // Read enable for ArenaRAM
        .addr(arenaRamAddress),     // Address for ArenaRAM
        .dataIn(arenaRamDataIn),    // Data to write into ArenaRAM
        .dataOut(arenaRamDataOut)   // Data read from ArenaRAM
    );

	// VGA Controller
    VGAController VGAControllerInstance (
        .clk(clk_25mhz),
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
        .JC(JC),
		.allBulletContents(allBulletContents), // Pass all bullet contents to VGA Controller
        .allSpriteContents(allSpriteContents),  // Pass all sprite contents to VGA Controller
        .allHealthContents(allHealthContents)   // Pass all health contents to VGA Controller
    );



endmodule
