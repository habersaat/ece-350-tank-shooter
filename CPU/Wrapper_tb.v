`timescale 1ns / 1ps
/**
 * 
 * READ THIS DESCRIPTION:
 *
 * This is the Wrapper module that will serve as the header file combining your processor, 
 * RegFile and Memory elements together.
 *
 * This file will be used to test your processor for functionality.
 * We have provided a sibling file, Wrapper_tb.v so that you can test your processor's functionality.
 * 
 * We will be using our own separate Wrapper_tb.v to test your code. 
 * You are allowed to make changes to the Wrapper files 
 * for your own individual testing, but we expect your final processor.v 
 * and memory modules to work with the Wrapper interface as provided.
 * 
 * Refer to Lab 5 documents for detailed instructions on how to interface 
 * with the memory elements. Each imem and dmem modules will take 12-bit 
 * addresses and will allow for storing of 32-bit values at each address. 
 * Each memory module should receive a single clock. At which edges, is 
 * purely a design choice (and thereby up to you). 
 * 
 * You must set the parameter when compiling to use the memory file of 
 * the test you created using the assembler and load the appropriate 
 * verification file.
 *
 * For example, you would add sample as your parameter after assembling sample.s
 * using the command
 *
 * 	 iverilog -o proc -c FileList.txt -s Wrapper_tb -PWrapper_tb.FILE=\"sample\"
 *
 * Note the backslashes (\) preceding the quotes. These are required.
 *
 **/

module Wrapper_tb #(parameter FILE = "bullet_test_advanced");

    // FileData
    localparam DIR = "Test Files/";
    localparam MEM_DIR = "Memory Files/";
    localparam OUT_DIR = "Output Files/";
    localparam VERIF_DIR = "Verification Files/";
    localparam DEFAULT_CYCLES = 255;

    // Inputs to the processor
    reg clock = 0, reset = 0;

    // I/O for the processor
    wire rwe, mwe;
    wire [4:0] rd, rs1, rs2;
    wire [31:0] instAddr, instData, 
                rData, regA, regB,
                memAddr, memDataIn, memDataOut;

    // Debug signals from the processor
    wire [31:0] pc_counter_debug, pc_instruction_debug;
    wire branch_taken_debug;
    wire [31:0] branch_target_debug;
	wire [31:0] opA_debug;

    // Wires for Test Harness
    wire [4:0] rs1_test, rs1_in;
    reg testMode = 0; 
    reg [16:0] num_cycles = DEFAULT_CYCLES;
    reg [15*8:0] exp_text;
    reg null;

    // Connect the reg to test to the for loop
    assign rs1_test = reg_to_test;

    // Hijack the RS1 value for testing
    assign rs1_in = testMode ? rs1_test : rs1;

    // Expected Value from File
    reg signed [31:0] exp_result;

    // Where to store file error codes
    integer expFile, diffFile, actFile, expScan; 

    // Do Verification
    reg verify = 1;

    // Metadata
    integer errors = 0,
            cycles = 0,
            reg_to_test = 0;

    // Main Processing Unit
    processor CPU(
        .clock(clock),
        .reset(reset),
                                
        // ROM
        .address_imem(instAddr), .q_imem(instData),
                                    
        // Regfile
        .ctrl_writeEnable(rwe), .ctrl_writeReg(rd),
        .ctrl_readRegA(rs1), .ctrl_readRegB(rs2), 
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
                ramDataOut), // Select data from MMIO, BulletRAM, SpriteRAM, HealthRAM, ArenaRAM, or RAM
                
        // Debug ports connected
        .pc_counter_debug(pc_counter_debug),
        .pc_instruction_debug(pc_instruction_debug),
        .branch_taken_debug(branch_taken_debug),
        .branch_target_debug(branch_target_debug),
		.opA_debug(opA_debug)
    ); 

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
    
    // Instruction Memory (ROM)
    ROM #(.MEMFILE({DIR, MEM_DIR, FILE, ".mem"}))
    InstMem(.clk(clock), 
        .addr(instAddr[11:0]), 
        .dataOut(instData));
    
    // Register File
    regfile RegisterFile(.clock(clock), 
        .ctrl_writeEnable(rwe), .ctrl_reset(reset), 
        .ctrl_writeReg(rd),
        .ctrl_readRegA(rs1_in), .ctrl_readRegB(rs2), 
        .data_writeReg(rData), .data_readRegA(regA), .data_readRegB(regB));
                        
    // Processor Memory (RAM)
	RAM ProcMem (
        .clk(clock), 
        .wEn(mwe && ramAccess), // Write enable for RAM
        .addr(memAddr[11:0]), 
        .dataIn(memDataIn), 
        .dataOut(ramDataOut)
    );

    wire [9:0] JD = 10'd0; // Default value for JD

    // MMIO Module
    MMIO mmio_unit (
        .clk(clock),
        .reset(reset),
        .address(memAddr),        // Full 32-bit address from the processor
        .readEn(~mwe && mmioAccess), // MMIO read enable
        .readData(mmioDataOut),   // Data read from MMIO
        .JD(JD)                   // Controller input
    );

    wire [2047:0] allBulletContents;

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
        .DEPTH(1024)
    ) ArenaRAMInstance (
        .clk(clock),
        .wEn(arenaRamWriteEnable),    // Write enable for ArenaRAM
        .readEn(arenaRamReadEnable),  // Read enable for ArenaRAM
        .addr(arenaRamAddress),       // Address for ArenaRAM
        .dataIn(arenaRamDataIn),      // Data to write into ArenaRAM
        .dataOut(arenaRamDataOut)     // Data read from ArenaRAM
    );

    // VGA Controller
    VGAController VGAControllerInstance (
        .clk(clock),
        .reset(reset),
        .hSync(),
        .vSync(),
        .VGA_R(),
        .VGA_G(),
        .VGA_B(),
        .ps2_clk(),   // Leave unconnected for now
        .ps2_data(),  // Leave unconnected for now
        .CPU_RESETN(),// Leave unconnected for now
        .BTNC(),      // Leave unconnected for now
        .BTNU(),      // Leave unconnected for now
        .BTNL(),      // Leave unconnected for now
        .BTNR(),      // Leave unconnected for now
        .BTND(),      // Leave unconnected for now
        .JD(JD),       // Pass controller input to VGA Controller
        .allBulletContents(allBulletContents), // Pass all bullet contents to VGA Controller
        .allSpriteContents(allSpriteContents),  // Pass all sprite contents to VGA Controller
        .allHealthContents(allHealthContents)   // Pass all health contents to VGA Controller
    );



    // Create the clock
    always
        #10 clock = ~clock; 

    //////////////////
    // Test Harness //
    //////////////////

    initial begin
        // Check if the parameter exists
        if(FILE == 0) begin
            $display("Please specify the test");
            $finish;
        end

        $display({"Loading ", FILE, ".mem\n"});

        // Read the expected file
        expFile = $fopen({DIR, VERIF_DIR, FILE, "_exp.txt"}, "r");

        // Check for any errors in opening the file
        if(!expFile) begin
            $display("Couldn't read the expected file.",
                "\nMake sure there is a %0s_exp.txt file in the \"%0s\" directory.", FILE, {DIR ,VERIF_DIR});
            $display("Continuing for %0d cycles without checking for correctness,\n", DEFAULT_CYCLES);
            verify = 0;
        end

        // Output file name
        $dumpfile({DIR, OUT_DIR, FILE, ".vcd"});
        // Module to capture and what level, 0 means all wires
        $dumpvars(0, Wrapper_tb);

        $display();

        // Create the files to store the output
        actFile = $fopen({DIR, OUT_DIR, FILE, "_actual.txt"},   "w");

        if (verify) begin
            diffFile = $fopen({DIR, OUT_DIR, FILE, "_diff.txt"},  "w");

            // Get the number of cycles from the file
            expScan = $fscanf(expFile, "num cycles:%d", num_cycles);

            // Check that the number of cycles was read
            if(expScan != 1) begin
                $display("Error reading the %0s file.", {FILE, "_exp.txt"});
                $display("Make sure that file starts with \n\tnum cycles:NUM_CYCLES");
                $display("Where NUM_CYCLES is a positive integer\n");
            end
        end

        // Clear the Processor at the beginning
        reset = 1;
        #1
        reset = 0;

        // Run for the number of cycles specified 
        for (cycles = 0; cycles < num_cycles; cycles = cycles + 1) begin
            // Every rising edge, write to the actual file and display debug info
            @(posedge clock);
            $display("Cycle %d: PC = %d, Instruction = %b, Branch Taken = %b, Branch Target = %d, OperandA = %d",
                     cycles, pc_counter_debug, pc_instruction_debug, branch_taken_debug, branch_target_debug, opA_debug);
                     $display("BulletRAM Contents: %h", allBulletContents);
            if (rwe && rd != 0) begin
                $fdisplay(actFile, "Cycle %3d: Wrote %0d into register %0d", cycles, rData, rd);
            end
        end

        $fdisplay(actFile, "============== Testing Mode ==============");

		if (verify)
			$display("\t================== Checking Registers ==================");

		// Activate the test harness
		testMode = 1;

		// Check the values in the regfile
		for (reg_to_test = 0; reg_to_test < 32; reg_to_test = reg_to_test + 1) begin
			
			if (verify) begin
				// Obtain the register value
				expScan =  $fscanf(expFile, "%s", exp_text);
				expScan = $sscanf(exp_text, "r%d=%d", null, exp_result);

				// Check for errors when reading
				if (expScan != 2) begin
					$display("Error reading value for register %0d.", reg_to_test);
					$display("Please make sure the value is in the format");
					$display("\tr%0d=EXPECTED_VALUE", reg_to_test);

					// Close the Files
					$fclose(expFile);
					$fclose(actFile);
					$fclose(diffFile);

					#100;
					$finish;
				end
			end 
			
			// Allow the regfile output value to stabilize
			#1;

			// Write the register value to the actual file
			$fdisplay(actFile, "Reg %2d: %11d", rs1_test, regA);
			
			// Compare the Values 
			if (verify) begin
				if (exp_result !== regA) begin
					$fdisplay(diffFile, "Reg: %2d Expected: %11d Actual: %11d",
						rs1_test, $signed(exp_result), $signed(regA));
					$display("\tFAILED Reg: %2d Expected: %11d Actual: %11d",
						rs1_test, $signed(exp_result), $signed(regA));
					errors = errors + 1;
				end else begin
					$display("\tPASSED Reg: %2d", rs1_test);
				end
			end
		end

		// Close the Files
		$fclose(expFile);
		$fclose(actFile);

		if (verify)
			$fclose(diffFile);

		// Display the tests and errors
		if (verify)
			$display("\nFinished %0d cycle%c with %0d error%c", cycles, "s"*(cycles != 1), errors, "s"*(errors != 1));
		else 
			$display("Finished %0d cycle%c", cycles, "s"*(cycles != 1));

		#100;
		$finish;
	end
endmodule


// `timescale 1ns / 1ps
// module Wrapper_tb #(parameter FILE = "nop");

//     // FileData
//     localparam DIR = "Test Files/";
//     localparam MEM_DIR = "Memory Files/";
//     localparam OUT_DIR = "Output Files/";
//     localparam VERIF_DIR = "Verification Files/";
//     localparam DEFAULT_CYCLES = 210;

//     // Inputs to the processor
//     reg clock = 0, reset = 0;

//     // I/O for the processor
//     wire rwe, mwe;
//     wire [4:0] rd, rs1, rs2;
//     wire [31:0] instAddr, instData, 
//                 rData, regA, regB,
//                 memAddr, memDataIn, memDataOut;

//     // Debug signals from the processor
//     wire [31:0] program_counter, instruction;
//     wire is_data_hazard, branch_taken_dbg;
//     wire [31:0] operandA_dbg, operandB_dbg;
// 	wire bypass_dbg;

//     // Wires for Test Harness
//     wire [4:0] rs1_test, rs1_in;
//     reg testMode = 0; 
//     reg [9:0] num_cycles = DEFAULT_CYCLES;
//     reg [15*8:0] exp_text;
//     reg null;

//     // Connect the reg to test to the for loop
//     assign rs1_test = reg_to_test;

//     // Hijack the RS1 value for testing
//     assign rs1_in = testMode ? rs1_test : rs1;

//     // Expected Value from File
//     reg signed [31:0] exp_result;

//     // Where to store file error codes
//     integer expFile, diffFile, actFile, expScan; 

//     // Do Verification
//     reg verify = 1;

//     // Metadata
//     integer errors = 0,
//             cycles = 0,
//             reg_to_test = 0;

//     // Main Processing Unit
//     processor CPU(.clock(clock), .reset(reset), 
                                
//         // ROM
//         .address_imem(instAddr), .q_imem(instData),
                                    
//         // Regfile
//         .ctrl_writeEnable(rwe), .ctrl_writeReg(rd),
//         .ctrl_readRegA(rs1), .ctrl_readRegB(rs2), 
//         .data_writeReg(rData), .data_readRegA(regA), .data_readRegB(regB),
                                    
//         // RAM
//         .wren(mwe), .address_dmem(memAddr), 
//         .data(memDataIn), .q_dmem(memDataOut),

//         // Debug ports connected
//         .program_counter(program_counter),
//         .instruction(instruction),
//         .is_data_hazard(is_data_hazard),
//         .branch_taken_dbg(branch_taken_dbg),
//         .operandA_dbg(operandA_dbg),
//         .operandB_dbg(operandB_dbg),
// 		.bypass_dbg(bypass_dbg)
//     ); 
    
//     // Instruction Memory (ROM)
//     ROM #(.MEMFILE({DIR, MEM_DIR, FILE, ".mem"}))
//     InstMem(.clk(clock), 
//         .addr(instAddr[11:0]), 
//         .dataOut(instData));
    
//     // Register File
//     regfile RegisterFile(.clock(clock), 
//         .ctrl_writeEnable(rwe), .ctrl_reset(reset), 
//         .ctrl_writeReg(rd),
//         .ctrl_readRegA(rs1_in), .ctrl_readRegB(rs2), 
//         .data_writeReg(rData), .data_readRegA(regA), .data_readRegB(regB));
                        
//     // Processor Memory (RAM)
//     RAM ProcMem(.clk(clock), 
//         .wEn(mwe), 
//         .addr(memAddr[11:0]), 
//         .dataIn(memDataIn), 
//         .dataOut(memDataOut));

//     // Create the clock
//     always
//         #10 clock = ~clock; 

//     //////////////////
//     // Test Harness //
//     //////////////////

//     initial begin
//         // Check if the parameter exists
//         if(FILE == 0) begin
//             $display("Please specify the test");
//             $finish;
//         end

//         $display({"Loading ", FILE, ".mem\n"});

//         // Read the expected file
//         expFile = $fopen({DIR, VERIF_DIR, FILE, "_exp.txt"}, "r");

//         // Check for any errors in opening the file
//         if(!expFile) begin
//             $display("Couldn't read the expected file.",
//                 "\nMake sure there is a %0s_exp.txt file in the \"%0s\" directory.", FILE, {DIR ,VERIF_DIR});
//             $display("Continuing for %0d cycles without checking for correctness,\n", DEFAULT_CYCLES);
//             verify = 0;
//         end

//         // Output file name
//         $dumpfile({DIR, OUT_DIR, FILE, ".vcd"});
//         // Module to capture and what level, 0 means all wires
//         $dumpvars(0, Wrapper_tb);

//         $display();

//         // Create the files to store the output
//         actFile = $fopen({DIR, OUT_DIR, FILE, "_actual.txt"},   "w");

//         if (verify) begin
//             diffFile = $fopen({DIR, OUT_DIR, FILE, "_diff.txt"},  "w");

//             // Get the number of cycles from the file
//             expScan = $fscanf(expFile, "num cycles:%d", num_cycles);

//             // Check that the number of cycles was read
//             if(expScan != 1) begin
//                 $display("Error reading the %0s file.", {FILE, "_exp.txt"});
//                 $display("Make sure that file starts with \n\tnum cycles:NUM_CYCLES");
//                 $display("Where NUM_CYCLES is a positive integer\n");
//             end
//         end

//         // Clear the Processor at the beginning
//         reset = 1;
//         #1
//         reset = 0;

//         // Run for the number of cycles specified 
//         for (cycles = 0; cycles < num_cycles; cycles = cycles + 1) begin
//             // Every rising edge, write to the actual file and display debug info
//             @(posedge clock);
//             $display("Cycle %d: PC = %d, Instruction = %h, Data Hazard = %b, Branch Taken = %b, OperandA = %d, OperandB = %d, BypassMXa = %d",
//                 cycles, program_counter, instruction, is_data_hazard, branch_taken_dbg, operandA_dbg, operandB_dbg, bypass_dbg);
//             if (rwe && rd != 0) begin
//                 $fdisplay(actFile, "Cycle %3d: Wrote %0d into register %0d", cycles, rData, rd);
//                 $display("Cycle %3d: Wrote %0d into register %0d", cycles, rData, rd);
//             end
//         end

//         $fdisplay(actFile, "============== Testing Mode ==============");

//         if (verify)
//             $display("\t================== Checking Registers ==================");

//         // Activate the test harness
//         testMode = 1;

//         // Check the values in the regfile
//         for (reg_to_test = 0; reg_to_test < 32; reg_to_test = reg_to_test + 1) begin
            
//             if (verify) begin
//                 // Obtain the register value
//                 expScan =  $fscanf(expFile, "%s", exp_text);
//                 expScan = $sscanf(exp_text, "r%d=%d", null, exp_result);

//                 // Check for errors when reading
//                 if (expScan != 2) begin
//                     $display("Error reading value for register %0d.", reg_to_test);
//                     $display("Please make sure the value is in the format");
//                     $display("\tr%0d=EXPECTED_VALUE", reg_to_test);

//                     // Close the Files
//                     $fclose(expFile);
//                     $fclose(actFile);
//                     $fclose(diffFile);

//                     #100;
//                     $finish;
//                 end
//             end 
            
//             // Allow the regfile output value to stabilize
//             #1;

//             // Write the register value to the actual file
//             $fdisplay(actFile, "Reg %2d: %11d", rs1_test, regA);
            
//             // Compare the Values 
//             if (verify) begin
//                 if (exp_result !== regA) begin
//                     $fdisplay(diffFile, "Reg: %2d Expected: %11d Actual: %11d",
//                         rs1_test, $signed(exp_result), $signed(regA));
//                     $display("\tFAILED Reg: %2d Expected: %11d Actual: %11d",
//                         rs1_test, $signed(exp_result), $signed(regA));
//                     errors = errors + 1;
//                 end else begin
//                     $display("\tPASSED Reg: %2d", rs1_test);
//                 end
//             end
//         end

//         // Close the Files
//         $fclose(expFile);
//         $fclose(actFile);

//         if (verify)
//             $fclose(diffFile);

//         // Display the tests and errors
//         if (verify)
//             $display("\nFinished %0d cycle%c with %0d error%c", cycles, "s"*(cycles != 1), errors, "s"*(errors != 1));
//         else 
//             $display("Finished %0d cycle%c", cycles, "s"*(cycles != 1));

//         #100;
//         $finish;
//     end
// endmodule
