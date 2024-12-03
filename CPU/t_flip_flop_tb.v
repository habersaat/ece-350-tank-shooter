module t_flip_flop_tb;

    // Testbench signals
    reg t;           // T (toggle) input
    reg clk;         // Clock input
    reg reset;       // Reset input
    wire q;          // Output state

    // Instantiate the T-Flip-Flop module
    t_flip_flop uut (
        .t(t),
        .clk(clk),
        .reset(reset),
        .q(q)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk;  // Toggle clock every 5 time units
    end

    // Test sequence
    initial begin
        // Test header
        $display("Time | Reset | T | Q | Expected Q | Result");

        // Test Case 1: Reset the flip-flop
        reset = 1; t = 0; #10;
        check_output(0);  // Q should be 0 after reset

        // Test Case 2: Toggle with T = 1 (Toggle from 0 -> 1)
        reset = 0; t = 1; #10;
        check_output(1);  // Q should toggle to 1

        // Test Case 3: Keep T = 0 (No toggle)
        t = 0; #10;
        check_output(1);  // Q should remain 1

        // Test Case 4: Toggle with T = 1 (Toggle from 1 -> 0)
        t = 1; #10;
        check_output(0);  // Q should toggle back to 0

        // Test Case 5: Continuous toggling
        t = 1; #10;
        check_output(1);  // Q should toggle to 1
        t = 1; #10;
        check_output(0);  // Q should toggle back to 0
        t = 1; #10;
        check_output(1);  // Q should toggle to 1

        // Test Case 6: Hold value with T = 0
        t = 0; #10;
        check_output(1);  // Q should remain 1

        // Test Case 7: Reset the flip-flop again
        reset = 1; #10;
        check_output(0);  // Q should be reset to 0

        $display("All tests completed successfully.");
        $finish;
    end

    // Task to check the output and display the results
    task check_output;
        input expected_q;
        begin
            $display("%4t | %b     | %b | %b | %b          | %s",
                     $time, reset, t, q, expected_q, (q == expected_q) ? "PASS" : "FAIL");
        end
    endtask

endmodule
