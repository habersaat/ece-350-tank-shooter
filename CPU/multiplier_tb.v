module multiplier_tb;

    // Testbench signals
    reg [31:0] multiplicand;    // 32-bit multiplicand input
    reg [31:0] multiplier;      // 32-bit multiplier input
    reg clock;                  // Clock signal
    reg reset;                  // Reset signal
    wire [31:0] product;        // 32-bit final product output
    wire resultRDY;             // Result ready signal
    wire overflow;              // Overflow signal

    // Internal wires to capture submodule signals
    wire [3:0] state_count;              // State counter output
    wire [31:0] upper_product_bits;      // Upper 32 bits of the product
    wire [31:0] new_product;             // Next product state
    wire add_m, sub_m, shift_l;          // Control signals from the Booth encoder
    wire Q2_debug, Q1_debug, Q0_debug;   // Booth Encoder inputs

    // Instantiate the multiplier module with internal wire connections
    multiplier uut (
        .multiplicand(multiplicand),
        .multiplier(multiplier),
        .clock(clock),
        .reset(reset),
        .product(product),
        .resultRDY(resultRDY),
        .overflow(overflow),
        .state_count(state_count),
        .current_product(upper_product_bits),  // Debugging signal for upper product bits
        .new_product(new_product),
        .add_m(add_m),
        .sub_m(sub_m),
        .shift_l(shift_l),
        .Q2_debug(Q2_debug),
        .Q1_debug(Q1_debug),
        .Q0_debug(Q0_debug),
        .upper_product_bits_debug(upper_product_bits)  // Use upper product bits debug output
    );

    // Clock generation
    initial begin
        clock = 0;
        forever #20 clock = ~clock;  // Clock period is 40 time units
    end

    // Display internal signals at each clock cycle
    always @(posedge clock) begin
        // Display all relevant signals at each step
        $display("Time: %4t | Count: %2d | Q2: %b | Q1: %b | Q0: %b | add_m: %b | sub_m: %b | shift_l: %b | Upper Prod Bits: %h | New Prod: %h | Product: %h | Overflow: %b | ResultRDY: %b",
                 $time, state_count, Q2_debug, Q1_debug, Q0_debug, add_m, sub_m, shift_l, upper_product_bits, new_product, product, overflow, resultRDY);
    end

    // Test sequence
    initial begin
        // Monitor key signals
        $monitor("Time: %4t | Reset: %b | Multiplicand: %d | Multiplier: %d | Product: %d | Overflow: %b | resultRDY: %b",
                 $time, reset, multiplicand, multiplier, product, overflow, resultRDY);

        // Test header
        $display("Start of Multiplier Testing...");
        $display("-------------------------------------------------------------------------------------------------------------------------------------------------");
        $display("Time: %4t | Count: %2d | Q2: %b | Q1: %b | Q0: %b | add_m: %b | sub_m: %b | shift_l: %b | Upper Prod Bits: %h | New Prod: %h | Product: %h | Overflow: %b | ResultRDY: %b",
                 $time, 5'd0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 32'h00000000, 32'h00000000, 32'h00000000, 1'b0, 1'b0);
        $display("-------------------------------------------------------------------------------------------------------------------------------------------------");

        // Test Case 1: Simple multiplication of positive numbers (4 * 8)
        multiplicand = 32'd2; multiplier = 32'd7; reset = 1; #40;
        reset = 0; #640;

        // // Uncomment the following test cases as needed

        // // Test Case 2: Multiplying a negative and a positive (-5 * 3)
        // multiplicand = -32'd5; multiplier = 32'd3; reset = 1; #0;
        // reset = 0; #200;

        // // Test Case 3: Multiplying two negative numbers (-355 * -711)
        // multiplicand = -32'd355; multiplier = -32'd711; reset = 1; #20;
        // reset = 0; #200;

        // // Test Case 4: Multiplying with zero (12345 * 0)
        // multiplicand = 32'd12345; multiplier = 32'd0; reset = 1; #20;
        // reset = 0; #200;

        // // Test Case 5: Multiplying a large positive and a small negative number (2147483647 * -1)
        // multiplicand = 32'd2147483647; multiplier = -32'd1; reset = 1; #0;
        // reset = 0; #200;

        // // Test Case 6: Multiplying the maximum negative and maximum positive
        // multiplicand = -32'd2147483648; multiplier = 32'd1; reset = 1; #20;
        // reset = 0; #200;

        // // Test Case 7: Multiplying two large positive numbers (65536 * 65536)
        // multiplicand = 32'd65536; multiplier = 32'd65536; reset = 1; #0;
        // reset = 0; #200;

        $display("End of Multiplier Testing.");
        $finish;
    end

endmodule
