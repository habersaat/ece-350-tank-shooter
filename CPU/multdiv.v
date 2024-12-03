module multdiv(
	data_operandA, data_operandB, 
	ctrl_MULT, ctrl_DIV, 
	clock, 
	data_result, data_exception, data_resultRDY,
    op_in_progress
    );

    // Inputs
    input [31:0] data_operandA, data_operandB;
    input ctrl_MULT, ctrl_DIV, clock;

    // Outputs
    output [31:0] data_result;
    output data_exception, data_resultRDY;
    output op_in_progress;

    // Internal signals for multiplication
    wire mult_done, mult_overflow;
    wire [31:0] mult_result;

    // Internal signals for division
    wire div_done, div_exception;
    wire [31:0] div_result;

    // Wires for storing operands and results
    wire [31:0] operandA_reg, operandB_reg, product_reg, division_reg;
    wire ready_flag, exception_flag;

    // Wires for register enable signals
    wire load_operands, reset_state, latch_op;

    // Enable signals
    assign load_operands = ctrl_MULT | ctrl_DIV; // Latch new operands when a new operation starts
    assign reset_state = load_operands;  // Reset state whenever a new operation starts

    // Operand registers to hold `data_operandA` and `data_operandB`
    register operandA_reg_inst(
        .clock(clock),
        .reset(1'b0),
        .in_enable(load_operands),
        .D(data_operandA),
        .Q(operandA_reg)
    );

    register operandB_reg_inst(
        .clock(clock),
        .reset(1'b0),
        .in_enable(load_operands),
        .D(data_operandB),
        .Q(operandB_reg)
    );

    // Register to hold 0 for multiplication or 1 for division
    register_1bit ctrl_MULT_DIV_reg(
        .clock(clock),
        .reset(1'b0),
        .in_enable(load_operands),
        .D(ctrl_DIV),
        .Q(latch_op)
    );

    // Product register to store the multiplication result
    register product_result_inst(
        .clock(clock),
        .reset(reset_state),
        .in_enable(mult_done),
        .D(mult_result),
        .Q(product_reg)
    );

    // Division register to store the division result
    register division_result_inst(
        .clock(clock),
        .reset(reset_state),
        .in_enable(div_done),
        .D(div_result),
        .Q(division_reg)
    );

    // Ready flag register: Indicates the result is ready for one cycle
    register_1bit ready_flag_reg(
        .clock(clock),
        .reset(reset_state),
        .in_enable((~latch_op & mult_done) | (latch_op & div_done)),
        .D(1'b1),
        .Q(ready_flag)
    );

    // Exception flag register: Set if there's an overflow
    register_1bit exception_flag_reg(
        .clock(clock),
        .reset(reset_state),
        .in_enable((~latch_op & mult_done) | (latch_op & div_done)),
        .D(latch_op ? div_exception : mult_overflow), // Set exception flag based on operation
        .Q(exception_flag)
    );

    // Connect the internal ready flag and exception flag to the output signals
    assign data_resultRDY = ready_flag;
    assign data_exception = exception_flag;

    // Connect the product result to the data_result output
    assign data_result = latch_op ? division_reg : product_reg;

    // Multiplier instance
    multiplier mult_unit (
        .multiplicand(operandA_reg), 
        .multiplier(operandB_reg), 
        .clock(clock), 
        .reset(reset_state),  // Reset the multiplier when a new operation starts
        .product(mult_result), 
        .resultRDY(mult_done), 
        .overflow(mult_overflow)
    );

    // Divider instance
    divider div_unit (
        .dividend(operandA_reg), 
        .divisor(operandB_reg), 
        .clock(clock), 
        .reset(reset_state),  // Reset the divider when a new operation starts
        .quotient(div_result), 
        .resultRDY(div_done), 
        .exception(div_exception)
    );

    // 1 bit register to latch that an operation is in progress
    register_1bit op_in_progress_reg(
        .clock(clock),
        .reset(data_resultRDY),  // Reset the register when the result is ready and the operation is not in progress
        .in_enable(load_operands),
        .D(1'b1),
        .Q(op_in_progress)
    );




endmodule