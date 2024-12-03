module cla_block(X, Y, Cin, S, G, P);
        
    // Declare inputs and outputs
    input [7:0] X, Y;
    input Cin;
    output [7:0] S;
    output G, P;

    // Declare wires for generation, propagation, and carry signals
    wire g0, g1, g2, g3, g4, g5, g6, g7;
    wire p0, p1, p2, p3, p4, p5, p6, p7;
    wire c0, c1, c2, c3, c4, c5, c6, c7;

    // Declare AND intermediate for carry equations
    wire p0c0;                                                                                // c1
    wire p1g0, p1p0c0;                                                                        // c2
    wire p2g1, p2p1g0, p2p1p0c0;                                                              // c3
    wire p3g2, p3p2g1, p3p2p1g0, p3p2p1p0c0;                                                  // c4
    wire p4g3, p4p3g2, p4p3p2g1, p4p3p2p1g0, p4p3p2p1p0c0;                                    // c5
    wire p5g4, p5p4g3, p5p4p3g2, p5p4p3p2g1, p5p4p3p2p1g0, p5p4p3p2p1p0c0;                    // c6
    wire p6g5, p6p5g4, p6p5p4g3, p6p5p4p3g2, p6p5p4p3p2g1, p6p5p4p3p2p1g0, p6p5p4p3p2p1p0c0;  // c7

    // Declare intermediate signals for G signal
    wire p7g6, p7p6g5, p7p6p5g4, p7p6p5p4g3, p7p6p5p4p3g2, p7p6p5p4p3p2g1, p7p6p5p4p3p2p1g0;
    wire g7_p7g6, p7p6g5_p7p6p5g4, g7_p7g6_p7p6g5_p7p6p5g4, p7p6p5p4g3_p7p6p5p4p3g2, p7p6p5p4p3p2g1_p7p6p5p4p3p2p1g0, p7p6p5p4g3_p7p6p5p4p3g2_p7p6p5p4p3p2g1_p7p6p5p4p3p2p1g0, g7_p7g6_p7p6g5_p7p6p5g4_p7p6p5p4g3_p7p6p5p4p3g2_p7p6p5p4p3p2g1_p7p6p5p4p3p2p1g0;

    // Generate signals
    and g0_gate(g0, X[0], Y[0]);
    and g1_gate(g1, X[1], Y[1]);
    and g2_gate(g2, X[2], Y[2]);
    and g3_gate(g3, X[3], Y[3]);
    and g4_gate(g4, X[4], Y[4]);
    and g5_gate(g5, X[5], Y[5]);
    and g6_gate(g6, X[6], Y[6]);
    and g7_gate(g7, X[7], Y[7]);

    // Propegate signals
    or p0_gate(p0, X[0], Y[0]);
    or p1_gate(p1, X[1], Y[1]);
    or p2_gate(p2, X[2], Y[2]);
    or p3_gate(p3, X[3], Y[3]);
    or p4_gate(p4, X[4], Y[4]);
    or p5_gate(p5, X[5], Y[5]);
    or p6_gate(p6, X[6], Y[6]);
    or p7_gate(p7, X[7], Y[7]);

    // c0
    assign c0 = Cin;

    // c1
    and p0_and_c0(p0c0, p0, c0);
    or (c1, g0, p0c0);

    // c2
    and p1_and_g0(p1g0, p1, g0);
    and p1_and_p0c0(p1p0c0, p1, p0c0);
    or (c2, g1, p1g0, p1p0c0);

    // c3
    and p2_and_g1(p2g1, p2, g1);
    and p2_and_p1g0(p2p1g0, p2, p1g0);
    and p2_and_p1p0c0(p2p1p0c0, p2, p1p0c0);
    or (c3, g2, p2g1, p2p1g0, p2p1p0c0);

    // c4
    and p3_and_g2(p3g2, p3, g2);
    and p3_and_p2g1(p3p2g1, p3, p2g1);
    and p3_and_p2p1g0(p3p2p1g0, p3, p2p1g0);
    and p3_and_p2p1p0c0(p3p2p1p0c0, p3, p2p1p0c0);
    or (c4, g3, p3g2, p3p2g1, p3p2p1g0, p3p2p1p0c0);

    // c5
    and p4_and_g3(p4g3, p4, g3);
    and p4_and_p3g2(p4p3g2, p4, p3g2);
    and p4_and_p3p2g1(p4p3p2g1, p4, p3p2g1);
    and p4_and_p3p2p1g0(p4p3p2p1g0, p4, p3p2p1g0);
    and p4_and_p3p2p1p0c0(p4p3p2p1p0c0, p4, p3p2p1p0c0);
    or (c5, g4, p4g3, p4p3g2, p4p3p2g1, p4p3p2p1g0, p4p3p2p1p0c0);

    // c6
    and p5_and_g4(p5g4, p5, g4);
    and p5_and_p4g3(p5p4g3, p5, p4g3);
    and p5_and_p4p3g2(p5p4p3g2, p5, p4p3g2);
    and p5_and_p4p3p2g1(p5p4p3p2g1, p5, p4p3p2g1);
    and p5_and_p4p3p2p1g0(p5p4p3p2p1g0, p5, p4p3p2p1g0);
    and p5_and_p4p3p2p1p0c0(p5p4p3p2p1p0c0, p5, p4p3p2p1p0c0);
    or (c6, g5, p5g4, p5p4g3, p5p4p3g2, p5p4p3p2g1, p5p4p3p2p1g0, p5p4p3p2p1p0c0);

    // c7
    and p6_and_g5(p6g5, p6, g5);
    and p6_and_p5g4(p6p5g4, p6, p5g4);
    and p6_and_p5p4g3(p6p5p4g3, p6, p5p4g3);
    and p6_and_p5p4p3g2(p6p5p4p3g2, p6, p5p4p3g2);
    and p6_and_p5p4p3p2g1(p6p5p4p3p2g1, p6, p5p4p3p2g1);
    and p6_and_p5p4p3p2p1g0(p6p5p4p3p2p1g0, p6, p5p4p3p2p1g0);
    and p6_and_p5p4p3p2p1p0c0(p6p5p4p3p2p1p0c0, p6, p5p4p3p2p1p0c0);
    or (c7, g6, p6g5, p6p5g4, p6p5p4g3, p6p5p4p3g2, p6p5p4p3p2g1, p6p5p4p3p2p1g0, p6p5p4p3p2p1p0c0);

    // Calculate sum bits
    xor (S[0], X[0], Y[0], Cin); 
    xor (S[1], X[1], Y[1], c1);  
    xor (S[2], X[2], Y[2], c2);
    xor (S[3], X[3], Y[3], c3); 
    xor (S[4], X[4], Y[4], c4);
    xor (S[5], X[5], Y[5], c5); 
    xor (S[6], X[6], Y[6], c6); 
    xor (S[7], X[7], Y[7], c7);
    
    // P Signal
    and (P, p7, p6, p5, p4, p3, p2, p1, p0);

    // G Signal
    and (p7g6, p7, g6);                                     // p7 * g6
    and (p7p6g5, p7, p6, g5);                               // p7 * p6 * g5
    and (p7p6p5g4, p7, p6, p5, g4);                         // p7 * p6 * p5 * g4
    and (p7p6p5p4g3, p7, p6, p5, p4, g3);                   // p7 * p6 * p5 * p4 * g3
    and (p7p6p5p4p3g2, p7, p6, p5, p4, p3, g2);             // p7 * p6 * p5 * p4 * p3 * g2
    and (p7p6p5p4p3p2g1, p7, p6, p5, p4, p3, p2, g1);       // p7 * p6 * p5 * p4 * p3 * p2 * g1
    and (p7p6p5p4p3p2p1g0, p7, p6, p5, p4, p3, p2, p1, g0); // p7 * p6 * p5 * p4 * p3 * p2 * p1 * g0

    // Final OR gate to combine the terms for Group Generate
    or (G, g7, p7g6, p7p6g5, p7p6p5g4, p7p6p5p4g3, p7p6p5p4p3g2, p7p6p5p4p3p2g1, p7p6p5p4p3p2p1g0);

endmodule