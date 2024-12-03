module alu(data_operandA, data_operandB, ctrl_ALUopcode, ctrl_shiftamt, data_result, isNotEqual, isLessThan, overflow);
        
    // Declare inputs and outputs
    input [31:0] data_operandA, data_operandB;
    input [4:0] ctrl_ALUopcode, ctrl_shiftamt;

    // Declare outputs
    output [31:0] data_result;
    output isNotEqual, isLessThan, overflow;

    // Declare wires for the results of each operation
    wire [31:0] and_result, or_result, add_result, sub_result, sll_result, sra_result;  // Wires for the results of each operation
    wire [31:0] default_result = 32'b0; // Default value when no operation is selected
    wire add_overflow, sub_overflow; // Wires for the overflow of ADD and SUB operations
    wire default_overflow = 1'b0; // Default value for overflow

    // Instantiate operation modules
    bitwise_and and_gate(.data_operandA(data_operandA), .data_operandB(data_operandB), .data_result(and_result)); // Bitwise AND
    bitwise_or or_gate(.data_operandA(data_operandA), .data_operandB(data_operandB), .data_result(or_result)); // Bitwise OR
    sll shift_logical_left(.data_operandA(data_operandA), .ctrl_shiftamt(ctrl_shiftamt), .data_result(sll_result)); // SLL
    sra shift_right_arithmetic(.data_operandA(data_operandA), .ctrl_shiftamt(ctrl_shiftamt), .data_result(sra_result)); // SRA
    add adder(.data_operandA(data_operandA), .data_operandB(data_operandB), .Cin(1'b0), .data_result(add_result), .overflow(add_overflow)); // ADD
    sub subtract(.data_operandA(data_operandA), .data_operandB(data_operandB), .data_result(sub_result), .isNotEqual(isNotEqual), .isLessThan(isLessThan), .overflow(sub_overflow)); // SUB

    mux_8 opcode_selection(
        data_result, 
        ctrl_ALUopcode[2:0], 
        add_result,                 // 00000 - ADD
        sub_result,                 // 00001 - SUB
        and_result,                 // 00010 - AND
        or_result,                  // 00011 - OR
        sll_result,                 // 00100 - SLL
        sra_result,                 // 00101 - SRA
        default_result,             // Default
        default_result              // Default
    );

    mux_4_single overflow_selection(
        overflow,
        ctrl_ALUopcode[1:0],
        add_overflow,               // 00 - ADD
        sub_overflow,               // 01 - SUB
        default_overflow,           // Default
        default_overflow            // Default
    );

endmodule