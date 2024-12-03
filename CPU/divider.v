module divider(
    input [31:0] dividend, divisor,
    input clock, reset,
    output [31:0] quotient,
    output resultRDY, exception
);

    // ----- 1. State Control -----
    wire [5:0] count;               // 6-bit State counter to track division steps
    wire is_max_index, is_zero_index; // State indicator flags for division control

    // State counter to keep track of the current step in division
    counter state_counter (
        .enable(1'b1),     // Always enabled for counting steps
        .clock(clock),
        .reset(reset),
        .count(count)
    );

    // State indicator logic
    assign is_max_index = count[5] & ~|count[4:0];  // True when count is 5'b10000 (final index)
    assign is_zero_index = ~|count;                 // True when count is 5'b00000 (initial index)

    wire [31:0] inverted_divisor, inverted_dividend;

    // Generate Inverted Divisor
    inverter invert_divisor(
        .data(divisor),
        .data_inv(inverted_divisor)
    );

    // Generate Inverted Dividend
    inverter invert_dividend(
        .data(dividend),
        .data_inv(inverted_dividend)
    );

    // Switch operands to positive values
    wire [31:0] abs_dividend, abs_divisor;
    wire flip_sign;
    assign abs_dividend = dividend[31] ? inverted_dividend : dividend;
    assign abs_divisor = divisor[31] ? inverted_divisor : divisor;
    assign flip_sign = dividend[31] ^ divisor[31];

    // ----- 2. Operand Registers -----
    wire [63:0] shifted_quotient;  // 64-bit value for dividend register
    wire [63:0] working_register_out;  // 64-bit value for working register
    wire [31:0] upper_reg_bits, lower_reg_bits;
    wire [31:0] working_remainder, working_quotient;  // Remainder and lower 32 bits of the quotient
    wire [31:0] addsub_result;  // Result of the addition or subtraction
    wire [63:0] working_register_in;  // 64-bit value for working register input
    
    // Select lower reg bits based on the state
    assign lower_reg_bits = is_zero_index ? abs_dividend : working_register_out[31:0];
    assign upper_reg_bits = is_zero_index ? 32'b0 : working_register_out[63:32];
    
    // Left shift the quotient by 1 bit
    assign shifted_quotient = is_max_index ? {upper_reg_bits, lower_reg_bits} : {upper_reg_bits[30:0], lower_reg_bits, 1'b0};

    assign working_remainder = shifted_quotient[63:32];
    assign working_quotient = shifted_quotient[31:0];

    
    // ----- 3. Division Logic -----
    wire [31:0] signed_divisor;
    wire sub;
    
    // Check the MSB of the remainder. If it's 0, subtract the divisor from the remainder. If it's 1, add the divisor.
    assign sub = ~working_remainder[31];

    // If we are subtracting, negate the divisor    
    assign signed_divisor = sub ? ~abs_divisor : abs_divisor;

    // Perform the subtraction or addition
    add sub_adder(
        .data_operandA(working_remainder),
        .data_operandB(signed_divisor),
        .Cin(sub),
        .data_result(addsub_result),
        .overflow(),
        .carry_out()
    );

    // Set Q[0] to 1 if MSB of the remainder is 1, 0 otherwise
    assign working_register_in = {addsub_result, working_quotient[31:1], ~addsub_result[31]};


    // Store current state (Remainder, Quotient) in 64-bit register
    register_64 working_register(
        .clock(clock),
        .reset(reset),
        .in_enable(1'b1),  // Always enabled for updating
        .D(working_register_in),
        .Q(working_register_out)
    );


    // ----- 5. Result Ready and Exception Handling -----
    wire ready_flag, division_exception;

    // Exception: Set if the divisor is zero
    assign division_exception = ~|divisor;

    // Result ready when the maximum index is reached
    assign ready_flag = is_max_index;

    // ----- 6. Output Assignment -----
    wire [31:0] inverted_quotient;

    inverter invert_quotient(
        .data(working_quotient),
        .data_inv(inverted_quotient)
    );

    assign quotient = division_exception ? 32'b0 : (flip_sign ? inverted_quotient : working_quotient); // Flip bits if the sign is negative
    assign resultRDY = ready_flag;
    assign exception = division_exception;

endmodule
