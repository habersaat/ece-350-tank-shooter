/**
 * READ THIS DESCRIPTION!
 *
 * This is your processor module that will contain the bulk of your code submission. You are to implement
 * a 5-stage pipelined processor in this module, accounting for hazards and implementing bypasses as
 * necessary.
 *
 * Ultimately, your processor will be tested by a master skeleton, so the
 * testbench can see which controls signal you active when. Therefore, there needs to be a way to
 * "inject" imem, dmem, and regfile interfaces from some external controller module. The skeleton
 * file, Wrapper.v, acts as a small wrapper around your processor for this purpose. Refer to Wrapper.v
 * for more details.
 *
 * As a result, this module will NOT contain the RegFile nor the memory modules. Study the inputs 
 * very carefully - the RegFile-related I/Os are merely signals to be sent to the RegFile instantiated
 * in your Wrapper module. This is the same for your memory elements. 
 *
 *
 */
module processor(
    // Control signals
    clock,                          // I: The master clock
    reset,                          // I: A reset signal

    // Imem
    address_imem,                   // O: The address of the data to get from imem
    q_imem,                         // I: The data from imem

    // Dmem
    address_dmem,                   // O: The address of the data to get or put from/to dmem
    data,                           // O: The data to write to dmem
    wren,                           // O: Write enable for dmem
    q_dmem,                         // I: The data from dmem

    // Regfile
    ctrl_writeEnable,               // O: Write enable for RegFile
    ctrl_writeReg,                  // O: Register to write to in RegFile
    ctrl_readRegA,                  // O: Register to read from port A of RegFile
    ctrl_readRegB,                  // O: Register to read from port B of RegFile
    data_writeReg,                  // O: Data to write to for RegFile
    data_readRegA,                  // I: Data from port A of RegFile
    data_readRegB,                   // I: Data from port B of RegFile

    // Debug
    pc_counter_debug,
    pc_instruction_debug,
    branch_taken_debug,
    branch_target_debug,
    opA_debug,
	);

	// Control signals
	input clock, reset;
	
	// Imem
    output [31:0] address_imem;
	input [31:0] q_imem;

	// Dmem
	output [31:0] address_dmem, data;
	output wren;
	input [31:0] q_dmem;

	// Regfile
	output ctrl_writeEnable;
	output [4:0] ctrl_writeReg, ctrl_readRegA, ctrl_readRegB;
	output [31:0] data_writeReg;
	input [31:0] data_readRegA, data_readRegB;

    // ------------ OPCODES ------------ //

    // Standard Opcodes
    parameter OPCODE_R_TYPE = 5'b00000; parameter OPCODE_ADDI = 5'b00101; parameter OPCODE_SW   = 5'b00111; parameter OPCODE_LW = 5'b01000; 
    parameter OPCODE_J      = 5'b00001; parameter OPCODE_BNE  = 5'b00010; parameter OPCODE_JAL  = 5'b00011; parameter OPCODE_JR = 5'b00100; 
    parameter OPCODE_BLT    = 5'b00110; parameter OPCODE_BEX  = 5'b10110; parameter OPCODE_SETX = 5'b10101;

    // ALU Operations (for R-type instructions with opcode 00000)
    parameter ALU_OP_ADD  = 5'b00000; parameter ALU_OP_SUB  = 5'b00001; parameter ALU_OP_AND  = 5'b00010; parameter ALU_OP_OR   = 5'b00011;
    parameter ALU_OP_SLL  = 5'b00100; parameter ALU_OP_SRA  = 5'b00101; parameter ALU_OP_MUL  = 5'b00110; parameter ALU_OP_DIV  = 5'b00111;

    // Debug
    output [31:0] pc_counter_debug, pc_instruction_debug;
    output branch_taken_debug;
    output [31:0] branch_target_debug;
    output [31:0] opA_debug;

    assign pc_counter_debug = fd_pc_out;
    assign pc_instruction_debug = fd_inst_out;
    assign branch_taken_debug = branch_taken;
    assign branch_target_debug = branch_target;
    assign opA_debug = bypass_from_wx_exception;
    



    // ------------ FETCH ------------ //

    // Set PC_reg_in to current instruction
    assign PC_reg_in = branch_mux_out;

    // Program Counter (disable on data hazard UNLESS branch is taken). If branch is taken we don't care about disabling reg_in
    wire [31:0] PC_reg_in, PC_reg_out;
    register_32 PC_reg (.clock(clock), .reset(reset), .in_enable(branch_taken || (~stall_pipeline && ~data_hazard)), .D(PC_reg_in), .Q(PC_reg_out));

    // Calculate the next PC
    wire [31:0] next_PC, incremented_PC;
    add pc_adder (.data_operandA(PC_reg_out), .data_operandB(32'b1), .Cin(1'b0), .data_result(incremented_PC), .overflow(), .carry_out());
    assign next_PC = reset ? 32'b0 : incremented_PC;

    // Assign address_imem
    assign address_imem = PC_reg_out;

    // Branch Mux
    wire [31:0] branch_mux_out;
    assign branch_mux_out = branch_taken ? branch_target : next_PC;

    // Check if the current instruction in the F/D, D/X, or X/M stage is valid (not a NOP)
    wire ex_valid = (ex_inst_out != 32'b0);
    wire xm_valid = (xm_inst_out != 32'b0);
    wire mw_valid = (mw_inst_out != 32'b0);

    // Check if current instruction is J1 type (no RD or other hazards)
    wire fetch_j1_safe = (fd_inst_out[31:27] == OPCODE_J) || (fd_inst_out[31:27] == OPCODE_JAL) || (fd_inst_out[31:27] == OPCODE_SETX);
    wire fetch_J2_type = (fd_inst_out[31:27] == OPCODE_JR);
    wire fetch_br_edge_cases = (fd_inst_out[31:27] == OPCODE_BLT) || (fd_inst_out[31:27] == OPCODE_BNE); // blt and bne
    wire fetch_sw = (fd_inst_out[31:27] == OPCODE_SW);
    wire fetch_bex = (fd_inst_out[31:27] == OPCODE_BEX);

    // Data Hazard Detection
    wire data_hazard;

    wire [4:0] fd_rs1 = fd_inst_out[21:17];
    wire [4:0] fd_rs2 = fd_inst_out[16:12];
    wire [4:0] fd_rd = fd_inst_out[26:22];

    wire [4:0] ex_rd = ex_inst_out[26:22];
    wire [4:0] xm_rd = xm_inst_out[26:22];

    wire true_data_hazard_1 = (ex_inst_out[31:27] == OPCODE_LW) && fd_rs1 == ex_rd && ex_valid; // lw data hazard
    wire true_data_hazard_2 = (ex_inst_out[31:27] == OPCODE_LW) && fd_rs2 == ex_rd && ex_valid && ~fetch_sw; // lw data hazard
    wire true_data_hazard_3 = (ex_inst_out[31:27] == OPCODE_LW) && fd_rd == ex_rd && ex_valid && (fetch_J2_type || fetch_br_edge_cases); // jr/bne/blt data hazard
    wire exceptions_data_hazard = (fetch_bex && (ex_inst_out[31:27] == OPCODE_SETX || xm_inst_out[31:27] == OPCODE_SETX));      // setx/bex data hazard

    assign data_hazard = ~fetch_j1_safe && (
                            true_data_hazard_1 || 
                            true_data_hazard_2 ||
                            true_data_hazard_3 ||
                            exceptions_data_hazard
                        );





    // ------------ DECODE ------------ //

    wire [31:0] fd_pc_out, fd_inst_out;

    /// Inject NOP if branch is taken
    wire [31:0] fd_inst_in;
    assign fd_inst_in = branch_taken ? 32'b0 : q_imem; // Inject NOP if branch is taken

    // F/D Register (stall on data hazard). Again branch_taken is more important because in that case we want to take the nop
    register_64_f F_D_reg (.clock(clock), .reset(reset), .in_enable(branch_taken || (~stall_pipeline && ~data_hazard)), .D({PC_reg_out, fd_inst_in}), .Q({fd_pc_out, fd_inst_out}));

    // Decode Opcode
    wire [4:0] opcode;
    assign opcode = fd_inst_out[31:27];

    // Assign potential operands
    wire [4:0] rd, rs, rt, shamt, ALU_op;
    wire [16:0] short_immediate;
    wire [31:0] immediate;
    wire [26:0] target;

    // 5-bit operands
    assign rd = fd_inst_out[26:22];
    assign rs = fd_inst_out[21:17];
    assign rt = fd_inst_out[16:12];
    assign shamt = fd_inst_out[11:7];
    assign ALU_op = fd_inst_out[6:2];
    
    // Longer operands
    assign short_immediate = fd_inst_out[16:0];
    assign immediate = { {15{fd_inst_out[16]}}, short_immediate }; // Sign extend immediate
    assign target = fd_inst_out[26:0];

    // Determine instruction type
    wire R_type, I_type, J1_type, J2_type;

    assign R_type = (opcode == OPCODE_R_TYPE);
    assign I_type = (opcode == OPCODE_ADDI) || (opcode == OPCODE_SW) || (opcode == OPCODE_LW) || (opcode == OPCODE_BNE) || (opcode == OPCODE_BLT);
    assign J1_type = (opcode == OPCODE_J) || (opcode == OPCODE_JAL) || (opcode == OPCODE_BEX) || (opcode == OPCODE_SETX);
    assign J2_type = (opcode ==OPCODE_JR);

    // Regfile control signals
    assign ctrl_writeEnable = mw_we;

    assign ctrl_readRegA = ((opcode == OPCODE_BNE) || (opcode == OPCODE_BLT) || (opcode ==OPCODE_JR)) ? rd : // For branches (and jr), read from rd
                           (opcode == OPCODE_BEX) ? 5'b11110 : // For bex, read from register 30
                           rs; // For all other instructions, read from
    assign ctrl_readRegB = ((opcode == OPCODE_BNE) || (opcode == OPCODE_BLT)) ? rs : // For branches, read from rs
                           R_type ? rt : // For R-type, read froxm rt
                           rd; // read from rd for all other instructions

    assign ctrl_writeReg = mw_ctrl_writeReg;
    assign data_writeReg = mw_write_data;
    



    // ------------ EXECUTE ------------ //

    wire [31:0] ex_pc_out, ex_inst_out, ex_a_out, ex_b_out;

    // Inject NOP if branch is taken
    wire [31:0] ex_inst_in;
    assign ex_inst_in = (branch_taken || data_hazard) ? 32'b0 : fd_inst_out; // Inject NOP if branch is taken OR data hazard

    // D/X Register
    register_128_f D_X_reg (.clock(clock), .reset(reset), .in_enable(~stall_pipeline), .D({fd_pc_out, data_readRegA, data_readRegB, ex_inst_in}), .Q({ex_pc_out, ex_a_out, ex_b_out, ex_inst_out}));

    // ALU
    wire [31:0] ALU_out;
    wire ALU_neq, ALU_lt, ALU_ovf;

    // Determine instruction type (now for execute stage)
    wire [4:0] ex_opcode = ex_inst_out[31:27];
    wire ex_R_type, ex_I_type, ex_J1_type, ex_J2_type;

    assign ex_R_type = (ex_opcode == OPCODE_R_TYPE);
    assign ex_I_type = (ex_opcode == OPCODE_ADDI) || (ex_opcode == OPCODE_SW) || (ex_opcode == OPCODE_LW) || (ex_opcode == OPCODE_BNE) || (ex_opcode == OPCODE_BLT);
    assign ex_J1_type = (ex_opcode == OPCODE_J) || (ex_opcode == OPCODE_JAL) || (ex_opcode == OPCODE_BEX) || (ex_opcode == OPCODE_SETX);
    assign ex_J2_type = (ex_opcode ==OPCODE_JR);

    // Set ex_ALU_op, ex_shamt, ex_immediate, ex_target
    wire [31:0] ex_immediate = { {15{ex_inst_out[16]}}, ex_inst_out[16:0] }; // Sign extend immediate
    wire [26:0] ex_target = ex_inst_out[26:0];
    wire [4:0] ex_shamt = ex_inst_out[11:7];
    wire [4:0] ex_ALU_op = ex_inst_out[6:2];
    // wire [4:0] ex_rd = ex_inst_out[26:22]; already done
    wire [4:0] ex_rs = ex_inst_out[21:17];
    wire [4:0] ex_rt = ex_inst_out[16:12];

    // Bypass mux for operand A
    wire [31:0] bypassed_a_out = bypass_from_mw_blt_A ? xm_o_out : // Bypass from M/W blt
                                 bypass_from_wx_blt_A ? mw_write_data : // Bypass from W/X blt
                                 bypass_from_mw_A ? xm_o_out : // Bypass from M/W
                                 bypass_from_wx_A ? mw_write_data : // Bypass from W/X
                                 bypass_from_mw_exception_A ? xm_o_out : // Bypass from M/W exception
                                 ex_a_out;

    // Operand A
    wire [31:0] operandA;
    assign operandA = (ex_opcode == OPCODE_JAL) ? ex_pc_out : // JAL (put PC in operand A)
                      bypassed_a_out;

    // Bypass mux for operand B
    wire [31:0] bypassed_b_out = bypass_from_mw_blt_B ? xm_o_out : // Bypass from M/W blt
                                 bypass_from_wx_blt_B ? mw_write_data : // Bypass from W/X blt
                                 bypass_from_mw_B ? xm_o_out : // Bypass from M/W
                                 bypass_from_wx_B ? mw_write_data : // Bypass from W/X
                                 bypass_from_mw_exception_B ? xm_o_out : // Bypass from M/W exception
                                 ex_b_out;

    // Operand B
    wire [31:0] operandB;
    assign operandB = ex_R_type || ((ex_opcode == OPCODE_BNE) || (ex_opcode == OPCODE_BLT)) ? bypassed_b_out :
                      (ex_opcode == OPCODE_JAL) ? OPCODE_R_TYPE : // JAL (add 0 to operand A)
                      ex_I_type ? ex_immediate :
                      ex_target;

    // Determine ALU operation (ALU_opcode for R-type, or add for others)
    wire [4:0] ALU_opcode;
    assign ALU_opcode = ex_R_type ? ex_ALU_op : 
                        ((ex_opcode == OPCODE_BNE) || (ex_opcode == OPCODE_BLT)) ? ALU_OP_SUB : // Subtract for branches
                        ALU_OP_ADD;

    // Determine shift amount (shamt for R-type, or 0 for others)
    wire [4:0] shiftamt;
    assign shiftamt = ex_R_type ? ex_shamt : OPCODE_R_TYPE;

    // Assign ALU output
    alu alu_unit (
        .data_operandA(operandA),
        .data_operandB(operandB),
        .ctrl_ALUopcode(ALU_opcode),
        .ctrl_shiftamt(shiftamt),
        .data_result(ALU_out), 
        .isNotEqual(ALU_neq),
        .isLessThan(ALU_lt),
        .overflow(ALU_ovf)
    );

    // Multdiv Wires
    wire [31:0] multdiv_result;
    wire multdiv_exception, multdiv_resultRDY;
    wire op_in_progress;

    // Determine if instruction is mult or div
    wire is_mult = (ex_R_type && ex_ALU_op == ALU_OP_MUL);
    wire is_div = (ex_R_type && ex_ALU_op == ALU_OP_DIV);

    // Control signals for mult/div
    wire ctrl_MULT = (is_mult && ~prev_stall);
    wire ctrl_DIV = (is_div && ~prev_stall);

    // Multdiv Unit
    multdiv multdiv_unit(
        .data_operandA(operandA),
        .data_operandB(operandB),
        .ctrl_MULT(ctrl_MULT),
        .ctrl_DIV(ctrl_DIV),
        .clock(clock),
        .data_result(multdiv_result),
        .data_exception(multdiv_exception),
        .data_resultRDY(multdiv_resultRDY),
        .op_in_progress(op_in_progress)
    );


   

    // Pipeline stall logic
    wire stall_pipeline = op_in_progress || ctrl_MULT || ctrl_DIV;

    // 1 bit prev_stall register
    wire prev_stall;
    register_1bit prev_stall_reg (.clock(clock), .reset(reset), .in_enable(1'b1), .D(stall_pipeline), .Q(prev_stall));


    // Branch control signals
    wire [31:0] branch_target, branch_addition;
    
    // Calculate branch target as PC + 1 + immediate
    alu branch_alu (
        .data_operandA(ex_pc_out),
        .data_operandB(ex_immediate),
        .ctrl_ALUopcode(ALU_OP_ADD), // Add
        .ctrl_shiftamt(5'b0), // No shift
        .data_result(branch_addition),
        .isNotEqual(),
        .isLessThan(),
        .overflow()
    );

    assign branch_target = (ex_opcode == OPCODE_BEX || ex_opcode == OPCODE_J || ex_opcode == OPCODE_JAL) ? ex_target : // BEX, J, JAL
                           (ex_opcode == OPCODE_JR) ? operandA : // JR
                           (ex_opcode == OPCODE_BNE || ex_opcode == OPCODE_BLT) ? branch_addition : // BNE, BLT
                            32'b0; // All other instructions

    // Determine if branch is taken
    wire branch_taken = (ex_opcode == OPCODE_BNE) ? ALU_neq : // BNE
                        (ex_opcode == OPCODE_BLT) ? ALU_lt : // BLT
                        (ex_opcode == OPCODE_BEX) ? operandA != 0 : // BEX
                        (ex_opcode == OPCODE_J || ex_opcode == OPCODE_JR) ? 1'b1 : // J, JR
                        (ex_opcode == OPCODE_JAL) ? 1'b1 : // JAL
                        1'b0;

    // Set exception for overflow
    wire [31:0] exception;
    assign exception = (ex_R_type && ex_ALU_op == ALU_OP_ADD && ALU_ovf) ? 32'd1 : // add - overflow exception
                       (ex_opcode == OPCODE_ADDI && ALU_ovf) ? 32'd2 : // addi - overflow exception
                       (ex_R_type && ex_ALU_op == ALU_OP_SUB && ALU_ovf) ? 32'd3 : // sub - overflow exception
                       (ex_R_type && ex_ALU_op == ALU_OP_MUL && multdiv_exception) ? 32'd4 : // mult - mult/div exception
                       (ex_R_type && ex_ALU_op == ALU_OP_DIV && multdiv_exception) ? 32'd5 : // div - mult/div exception
                       32'd0;

    // Set ex_output to ALU output, multdiv output, or exception
    wire [31:0] ex_output;
    wire is_exception;

    assign is_exception = (exception != 32'd0) ? 1'b1 : 1'b0;
    assign ex_output = is_exception ? exception :
                       ((ex_R_type || ex_I_type) && ex_rd == 5'b00000) ? 32'd0 : // $zero is always 0
                       ((ex_R_type && ex_ALU_op == ALU_OP_MUL) | (ex_R_type && ex_ALU_op == ALU_OP_DIV)) ? multdiv_result :
                       ALU_out;


    // BYPASSING LOGIC

    // Determine if we need to bypass from M/W
    wire bypass_from_mw_A = ~(ex_opcode == OPCODE_BLT || ex_opcode == OPCODE_BNE || ex_opcode ==OPCODE_JR) && ((ex_R_type || ex_I_type) && ex_rs == xm_rd) && (xm_R_type || (xm_opcode == OPCODE_ADDI) || (xm_opcode == OPCODE_LW) || (xm_opcode == OPCODE_SETX) || (xm_opcode == OPCODE_JAL)) && xm_valid; // xm_me -- will be written to regfile
    wire bypass_from_mw_B = ~(ex_opcode == OPCODE_BLT || ex_opcode == OPCODE_BNE || ex_opcode ==OPCODE_JR) && (ex_R_type && ex_rt == xm_rd) && (xm_R_type || (xm_opcode == OPCODE_ADDI) || (xm_opcode == OPCODE_LW) || (xm_opcode == OPCODE_SETX) || (xm_opcode == OPCODE_JAL)) && xm_valid; // xm_me -- will be written to regfile
    
    wire bypass_from_mw_exception_A = ((ex_R_type || ex_I_type) && ex_rs == 5'b11110) && xm_exception && xm_valid; // Exception
    wire bypass_from_mw_exception_B = (ex_R_type && ex_rt == 5'b11110) && xm_exception && xm_valid; // Exception

    wire bypass_from_mw_blt_A = (ex_opcode == OPCODE_BLT || ex_opcode == OPCODE_BNE || ex_opcode == OPCODE_JR) && (ex_rd == xm_rd) && xm_valid && ~(xm_opcode == OPCODE_SW || xm_opcode == OPCODE_BNE || xm_opcode == OPCODE_BLT); // branch data hazard -- only if writes to rd
    wire bypass_from_mw_blt_B = (ex_opcode == OPCODE_BLT || ex_opcode == OPCODE_BNE || ex_opcode == OPCODE_JR) && (ex_rs == xm_rd) && xm_valid && ~(xm_opcode == OPCODE_SW || xm_opcode == OPCODE_BNE || xm_opcode == OPCODE_BLT); // blt data hazard -- only if writes to rd

    // Determine if we need to bypass from W/X
    wire bypass_from_wx_A = ~(ex_opcode == OPCODE_BLT || ex_opcode == OPCODE_BNE || ex_opcode ==OPCODE_JR) && ((ex_R_type || ex_I_type) && ex_rs == mw_ctrl_writeReg) && (mw_R_type || mw_inst_out[31:27] == OPCODE_ADDI || mw_inst_out[31:27] == OPCODE_LW || mw_inst_out[31:27] == OPCODE_SETX || mw_inst_out[31:27] == OPCODE_JAL) && mw_valid; // mw_we -- will be written to regfile
    wire bypass_from_wx_B = ~(ex_opcode == OPCODE_BLT || ex_opcode == OPCODE_BNE || ex_opcode ==OPCODE_JR) && (ex_R_type && ex_rt == mw_ctrl_writeReg) && (mw_R_type || mw_inst_out[31:27] == OPCODE_ADDI || mw_inst_out[31:27] == OPCODE_LW || mw_inst_out[31:27] == OPCODE_SETX || mw_inst_out[31:27] == OPCODE_JAL) && mw_valid; // mw_we -- will be written to regfile

    wire bypass_from_wx_blt_A = (ex_opcode == OPCODE_BLT || ex_opcode == OPCODE_BNE || ex_opcode ==OPCODE_JR) && (ex_rd == mw_ctrl_writeReg) && mw_valid && ~(mw_opcode == OPCODE_SW || mw_opcode == OPCODE_BNE || mw_opcode == OPCODE_BLT); // branch data hazard -- only if writes to rd
    wire bypass_from_wx_blt_B = (ex_opcode == OPCODE_BLT || ex_opcode == OPCODE_BNE || ex_opcode ==OPCODE_JR) && (ex_rs == mw_ctrl_writeReg) && mw_valid && ~(mw_opcode == OPCODE_SW || mw_opcode == OPCODE_BNE || mw_opcode == OPCODE_BLT); // blt data hazard -- only if writes to rd
    
    wire bypass_from_wx_exception = (ex_opcode == OPCODE_SW) && (ex_rd == mw_ctrl_writeReg) && mw_valid && ~(mw_opcode == OPCODE_SW || mw_opcode == OPCODE_LW || mw_opcode == OPCODE_BNE || mw_opcode == OPCODE_BLT);

    // SW edge case where we want to calculate immediate + N but also want to store a bypassed b_out in the X/M stage
    wire [31:0] wx_bypass_ex_out = bypass_from_wx_exception ? mw_write_data : ex_b_out;




    // ------------ MEMORY ------------ //

    wire [31:0] xm_o_out, xm_b_out, xm_inst_out;
    wire xm_exception;

    // X/M Register
    register_96_f X_M_reg (.clock(clock), .reset(reset), .in_enable(~stall_pipeline), .D({ex_output, wx_bypass_ex_out, ex_inst_out}), .Q({xm_o_out, xm_b_out, xm_inst_out}));

    // 1 bit register for exception
    register_1bit_f xm_exception_reg (.clock(clock), .reset(reset), .in_enable(~stall_pipeline), .D(is_exception), .Q(xm_exception));
    
    // WM Bypass Logic
    wire wm_bypass = (xm_rd == mw_ctrl_writeReg) && mw_we && mw_valid; // R-type or ADDI in next stage

    // WM Bypass Mux
    wire [31:0] bypassed_b_out_xm = wm_bypass ? mw_write_data : 
                                    xm_b_out;


    // Data memory control signals
    assign address_dmem = xm_o_out;
    assign data = bypassed_b_out_xm;
    assign wren = (xm_inst_out[31:27] == OPCODE_SW) ? 1'b1 : 1'b0; // Enable on sw instruction

    // Set opcode and rd FOR BYPASS LOGIC
    wire [4:0] xm_opcode = xm_inst_out[31:27];
    wire xm_R_type = (xm_opcode == OPCODE_R_TYPE);
    // wire [4:0] xm_rd = xm_inst_out[26:22]; already done



    // ------------ WRITEBACK ------------ //

    wire [31:0] mw_o_out, mw_d_out, mw_inst_out;
    wire mw_exception;

    // M/W Register
    register_96_f M_W_reg (.clock(clock), .reset(reset), .in_enable(~stall_pipeline), .D({xm_o_out, q_dmem, xm_inst_out}), .Q({mw_o_out, mw_d_out, mw_inst_out}));

    // 1 bit register for exception
    register_1bit_f mw_exception_reg (.clock(clock), .reset(reset), .in_enable(~stall_pipeline), .D(xm_exception), .Q(mw_exception));


    // Set opcode and rd
    wire [4:0] mw_opcode = mw_inst_out[31:27];
    wire [4:0] mw_rd = mw_inst_out[26:22];

    // Determine if instruction is R-type
    wire mw_R_type = (mw_opcode == OPCODE_R_TYPE);

    // prepend 0s to target which is 27 bits
    wire [31:0] mw_target = { {5{1'b0}}, mw_inst_out[26:0] };


    // Regfile data write
    wire [31:0] mw_write_data;
    wire [4:0] mw_ctrl_writeReg;
    wire mw_we;

    assign mw_write_data = (mw_opcode == OPCODE_LW) ? mw_d_out : // Write data from memory if lw instruction
                           (mw_opcode == OPCODE_SETX) ? mw_target : // setx writes target
                           (mw_opcode == OPCODE_JAL) ? mw_o_out : // jal writes PC + 1 (stored in o_out)
                            mw_o_out; // otherwise write data from ALU
    assign mw_ctrl_writeReg = mw_exception ? 5'b11110 : // exception writes to register 30
                              (mw_opcode == OPCODE_SETX) ? 5'b11110 : // setx writes to register 30
                              (mw_opcode == OPCODE_JAL) ? 5'b11111 : // jal writes to register 31
                               mw_rd; // For all other instructions, write to rd
    assign mw_we = (mw_ctrl_writeReg == 5'b00000) ? 1'b0 : // $zero is not writable
                    mw_R_type ? 1'b1 : 
                   (mw_inst_out[31:27] == OPCODE_ADDI) ? 1'b1 : // ADDI
                   (mw_inst_out[31:27] == OPCODE_LW) ? 1'b1 : // LW
                   (mw_inst_out[31:27] == OPCODE_SETX) ? 1'b1 : // SETX
                   (mw_inst_out[31:27] == OPCODE_JAL) ? 1'b1 : // JAL
                   1'b0; // All other instructions do not write to regfile

endmodule
