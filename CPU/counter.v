module counter(enable, clock, reset, count);

    // Inputs and outputs
    input enable, clock, reset;
    output [5:0] count;  // Updated to 6 bits for the counter output

    // Internal wires for each flip-flop's output
    wire q0, q1, q2, q3, q4, q5; // Added q5 for the 6th bit
    wire t1, t2, t3, t4, t5;     // Added t5 for enable logic of the 6th T flip-flop

    // And gates for the T flip-flops to generate enable signals
    and and1(t1, enable, q0);     // Enable for the 2nd T flip-flop
    and and2(t2, t1, q1);         // Enable for the 3rd T flip-flop
    and and3(t3, t2, q2);         // Enable for the 4th T flip-flop
    and and4(t4, t3, q3);         // Enable for the 5th T flip-flop
    and and5(t5, t4, q4);         // Enable for the 6th T flip-flop

    // Instantiate the T flip-flops
    t_flip_flop tff0(enable, clock, reset, q0);   // 1st bit (LSB)
    t_flip_flop tff1(t1, clock, reset, q1);       // 2nd bit
    t_flip_flop tff2(t2, clock, reset, q2);       // 3rd bit
    t_flip_flop tff3(t3, clock, reset, q3);       // 4th bit
    t_flip_flop tff4(t4, clock, reset, q4);       // 5th bit
    t_flip_flop tff5(t5, clock, reset, q5);       // 6th bit (MSB)

    // Output assignment
    assign count = {q5, q4, q3, q2, q1, q0};  // Concatenate flip-flop outputs to form the 6-bit counter value

endmodule
