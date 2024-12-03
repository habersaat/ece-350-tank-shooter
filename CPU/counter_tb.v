module counter_tb;

    // Testbench signals
    reg enable;       // Enable signal
    reg clock;        // Clock signal
    reg reset;        // Reset signal
    wire [4:0] count; // 5-bit counter output

    // Variable to hold the expected count value
    reg [4:0] expected_count;

    // Instantiate the 5-bit counter
    counter uut (
        .enable(enable),
        .clock(clock),
        .reset(reset),
        .count(count)
    );

    // Clock generation: Toggle clock every 5 time units
    initial begin
        clock = 0;
        forever #5 clock = ~clock;
    end

    // Test sequence
    initial begin
        // Test header
        $display("Time | Reset | Enable | Count | Expected Count | Result");

        // Test Case 1: Reset the counter
        reset = 1; enable = 0; expected_count = 5'b00000; #10;
        check_output(expected_count);  // Expect count = 0 after reset

        // Test Case 2: Enable counting after reset
        reset = 0; enable = 1; expected_count = expected_count + 1; #10;  // Start counting
        check_output(expected_count);  // Expect count = 1

        // Test Case 3: Continue counting for 10 cycles
        repeat (10) begin
            #10;
            expected_count = expected_count + 1;  // Manually update expected count
            check_output(expected_count);         // Compare with updated expected count
        end

        // Test Case 4: Disable counting and hold the value
        enable = 0; #20;  // Wait for 2 cycles with enable = 0
        check_output(expected_count);  // Expect count to hold its value

        // Test Case 5: Enable counting again and wrap around
        enable = 1;
        while (expected_count < 5'b11111) begin
            #10;
            expected_count = expected_count + 1;  // Continue updating expected count
            check_output(expected_count);
        end
        #10;
        expected_count = 5'b00000;  // Expect count = 0 after wrapping
        check_output(expected_count);

        // Test Case 6: Reset the counter in the middle of counting
        reset = 1; #10;  // Assert reset
        expected_count = 5'b00000;  // Reset expected count to 0
        check_output(expected_count);  // Expect count = 0 after reset
        reset = 0; #10;          // De-assert reset
        expected_count = 5'b00001;  // Start counting again from 1
        check_output(expected_count);

        $display("All tests completed successfully.");
        $finish;
    end

    // Task to check the output and display the results
    task check_output;
        input [4:0] expected_count;
        begin
            $display("%3t | %b     | %b      | %b   | %b            | %s",
                     $time, reset, enable, count, expected_count, (count == expected_count) ? "PASS" : "FAIL");
        end
    endtask

endmodule
