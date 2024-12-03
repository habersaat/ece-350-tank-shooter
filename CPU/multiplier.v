module multiplier(
    input [31:0] multiplicand, multiplier,
    input clock, reset,
    output [31:0] product,
    output resultRDY, overflow
);

    // ----- 1. State Control and Initial Booth Multiplier Setup -----
    wire [3:0] count;                // State counter
    wire is_max_index, is_zero_index; // State indicator flags
    wire [32:0] initial_booth_multiplier;  // Initial 33-bit Booth multiplier value
    wire [1:0] high_count_bits;             // High bit of the count

    // State counter to keep track of current step in Booth's algorithm
    counter state_counter (
        .enable(1'b1),   // Always enabled for counting
        .clock(clock), 
        .reset(reset), 
        .count({high_count_bits, count})
    );

    // State indicator logic
    assign is_max_index = &count;       // True when count is 4'b1111 (index 15)
    assign is_zero_index = ~|count;     // True when count is 4'b0000 (index 0)

    // Booth multiplier register initialization
    assign initial_booth_multiplier = {multiplier, 1'b0};  // 33-bit value: {multiplier, 0}


    // ----- 2. Booth Encoding Logic -----
    wire Q2_wire, Q1_wire, Q0_wire;   // Booth encoding control bits
    wire [32:0] booth_multiplicand;  // Booth encoded multiplicand value
    wire [32:0] sign_extended_multiplicand; // Sign-extended multiplicand (bc modified booths)

    // Sign extend the multiplicand by 1 bit
    assign sign_extended_multiplicand = {multiplicand[31], multiplicand};

    // Calculate Booth control bits based on current state and product
    assign Q2_wire = is_zero_index ? initial_booth_multiplier[2] : product_66_bit[2];
    assign Q1_wire = is_zero_index ? initial_booth_multiplier[1] : product_66_bit[1];
    assign Q0_wire = is_zero_index ? initial_booth_multiplier[0] : product_66_bit[0];

    // Booth encoding based on Q2, Q1, Q0
    mux_8_33bit booth_mux(
        .out(booth_multiplicand),
        .select({Q2_wire, Q1_wire, Q0_wire}),
        .in0(33'b0),                                // 000
        .in1(sign_extended_multiplicand),           // 001
        .in2(sign_extended_multiplicand),           // 010
        .in3(sign_extended_multiplicand << 1),      // 011
        .in4(~(sign_extended_multiplicand << 1)),   // 100
        .in5(~sign_extended_multiplicand),          // 101
        .in6(~sign_extended_multiplicand),          // 110
        .in7(33'b0)                                 // 111
    );

    // Generate subtraction control signal for the adder
    wire sub = Q2_wire & (~Q0_wire | ~Q1_wire);

    
    // ----- 3. Accumulation Logic -----
    wire [31:0] upper_bits;           // Result of the addition (upper 32 bits)
    wire sign_extension;              // Sign extension bit for the adder
    wire adder_carry_out;             // Carry out from the adder

    // Generate sign extension bit for the adder
    assign sign_extension = booth_multiplicand[32];

    // Add the Booth encoded multiplicand to the higher bits of the current product
    add adder(
        .data_operandA(product_66_bit[64:33]),      // Upper 32 bits of the product (not including bonus bit)
        .data_operandB(booth_multiplicand[31:0]),
        .Cin(sub), // +1 if subtraction is needed
        .data_result(upper_bits),
        .overflow(),
        .carry_out(adder_carry_out) // Carry out from the adder (for bonus bit calculation)
    );

    // Calculate the bonus bit for sign extension after shift
    wire bonus_bit = sign_extension ^ adder_carry_out ^ product_66_bit[65];


    // ----- 4. Product Register and Shifting Logic -----
    wire [65:0] product_66_bit;        // 66-bit product register
    wire [65:0] shifted_product;       // 66-bit shifted product
    wire [32:0] lower_product_bits;    // Lower 33 bits of the product

    // Select lower product bits based on the state
    assign lower_product_bits = is_zero_index ? initial_booth_multiplier : product_66_bit[32:0];

    // Perform a 2-bit right shift on the entire 66-bit product
    assign shifted_product = {{3{bonus_bit}}, upper_bits[31:0], lower_product_bits[32:2]}; // Shift right by 2 bits

    // Store the current product using a 66-bit register
    register_66 product_reg(
        .clock(clock), 
        .reset(reset), 
        .in_enable(1'b1), 
        .D(shifted_product), 
        .Q(product_66_bit)
    );


    // ----- 5. Output and Overflow Detection -----
    wire [31:0] upper_product_bits = shifted_product[64:33];

    // Output the final product and result ready signal
    assign product = shifted_product[32:1];            // Lower 32 bits
    assign resultRDY = is_max_index;                   // Result ready when max index is reached

    // Overflow detection: XOR upper bits with sign extension from the lower product bits
    assign overflow = resultRDY & |(upper_product_bits ^ {32{product[31]}});

endmodule
