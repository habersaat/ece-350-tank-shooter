`timescale 1ns / 1ps

module divider_tb();

    // Inputs to the divider
    reg [31:0] dividend, divisor;
    reg clock, reset;

    // Outputs from the divider
    wire [31:0] quotient;
    wire resultRDY, exception;

    // Debug Ports
    wire [5:0] debug_count;          // Current iteration index
    wire [31:0] debug_remainder;     // Current working remainder
    wire [31:0] debug_quotient;      // Current working quotient
    wire [31:0] debug_addsub_result; // Result of the addition or subtraction
    wire debug_sub;                  // Indicates if subtraction is being performed

    // Instantiate the divider module with debug ports
    divider uut (
        .dividend(dividend),
        .divisor(divisor),
        .clock(clock),
        .reset(reset),
        .quotient(quotient),
        .resultRDY(resultRDY),
        .exception(exception),
        // Debug Ports
        .debug_count(debug_count),
        .debug_remainder(debug_remainder),
        .debug_quotient(debug_quotient),
        .debug_addsub_result(debug_addsub_result),
        .debug_sub(debug_sub)
    );

    // Clock generation
    initial begin
        clock = 0;
        forever #5 clock = ~clock;  // Generate a clock with a period of 10 time units
    end

    // Test process
    initial begin
        // Initialize signals
        reset = 1;
        dividend = 0;
        divisor = 0;

        // Display initial message
        $display("Starting divider test...\n");

        // Apply reset
        #10 reset = 0;

        // Test Case 1: 100 / 10
        $display("Test Case 1: 6480321 / 746");
        dividend = 6480321;
        divisor = 746;
        reset = 1;     // Assert reset for initialization
        #10 reset = 0; // De-assert reset to start division

        // Wait for the division to complete
        wait(resultRDY == 1);

        // Display the result for the first test case
        $display("  Final Quotient: %d", quotient);
        $display("  Final Remainder: %d", debug_remainder);
        $display("  Exception: %b", exception);
        $display("  Iteration Count: %d\n", debug_count);
        
        // Test Case 2: 500 / 3
        $display("Test Case 2: 500 / 3");
        dividend = 500;
        divisor = 3;
        reset = 1;
        #10 reset = 0;

        wait(resultRDY == 1);
        $display("  Final Quotient: %d", quotient);
        $display("  Final Remainder: %d", debug_remainder);
        $display("  Exception: %b", exception);
        $display("  Iteration Count: %d\n", debug_count);

        // Test Case 3: 32 / 8
        $display("Test Case 3: 32 / 8");
        dividend = 32;
        divisor = 8;
        reset = 1;
        #10 reset = 0;

        wait(resultRDY == 1);
        $display("  Final Quotient: %d", quotient);
        $display("  Final Remainder: %d", debug_remainder);
        $display("  Exception: %b", exception);
        $display("  Iteration Count: %d\n", debug_count);

        // Test Case 4: 15 / 4
        $display("Test Case 4: 15 / 4");
        dividend = 15;
        divisor = 4;
        reset = 1;
        #10 reset = 0;

        wait(resultRDY == 1);
        $display("  Final Quotient: %d", quotient);
        $display("  Final Remainder: %d", debug_remainder);
        $display("  Exception: %b", exception);
        $display("  Iteration Count: %d\n", debug_count);

        // Test Case 5: Division by Zero (50 / 0)
        $display("Test Case 5: 50 / 0 (Division by Zero)");
        dividend = 50;
        divisor = 0;
        reset = 1;
        #10 reset = 0;

        wait(resultRDY == 1);
        $display("  Final Quotient: %d", quotient);
        $display("  Final Remainder: %d", debug_remainder);
        $display("  Exception: %b", exception);
        $display("  Iteration Count: %d\n", debug_count);

        // Complete the test
        $display("Divider test completed.");
        $finish;
    end

    // Monitor debug signals on each clock cycle for detailed tracking
    initial begin
        $monitor("Time = %0t | Count = %d | Remainder = %d | Quotient = %d | Add/Sub Result = %d | Sub = %b",
                 $time, debug_count, debug_remainder, debug_quotient, debug_addsub_result, debug_sub);
    end

endmodule
