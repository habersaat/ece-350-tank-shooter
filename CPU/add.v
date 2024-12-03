module add(data_operandA, data_operandB, Cin, data_result, overflow, carry_out);
        
    // Declare inputs and outputs
    input [31:0] data_operandA, data_operandB;
    input Cin;
    output [31:0] data_result;
    output overflow, carry_out;

    // Declare wires for intermediate G and P, and carry
    wire G0, G1, G2, G3;
    wire P0, P1, P2, P3;
    wire c0, c8, c16, c24;

    // Calculate c0
    assign c0 = Cin;

    // CLA block 0 [7:0]
    cla_block block0(.X(data_operandA[7:0]), .Y(data_operandB[7:0]), .Cin(c0), .S(data_result[7:0]), .G(G0), .P(P0));

    // Calculate c8
    wire P0c0;
    and P0_and_c0(P0c0, P0, c0);
    or carry8(c8, G0, P0c0);
    
    // CLA block 1 [15:8]
    cla_block block1(.X(data_operandA[15:8]), .Y(data_operandB[15:8]), .Cin(c8), .S(data_result[15:8]), .G(G1), .P(P1));

    // Calculate c16
    wire P1G0, P1P0c0;
    and P1_and_G0(P1G0, P1, G0);
    and P1_and_P0_and_c0(P1P0c0, P1, P0, c0);
    or carry16(c16, G1, P1G0, P1P0c0);

    // CLA block 2 [23:16]
    cla_block block2(.X(data_operandA[23:16]), .Y(data_operandB[23:16]), .Cin(c16), .S(data_result[23:16]), .G(G2), .P(P2));

    // Calculate c24
    wire P2G1, P2P1G0, P2P1P0c0;
    and P2_and_G1(P2G1, P2, G1);
    and P2_and_P1_and_G0(P2P1G0, P2, P1, G0);
    and P2_and_P1_and_P0_and_c0(P2P1P0c0, P2, P1, P0, c0);
    or carry24(c24, G2, P2G1, P2P1G0, P2P1P0c0);

    // CLA block 3 [31:24]
    cla_block block3(.X(data_operandA[31:24]), .Y(data_operandB[31:24]), .Cin(c24), .S(data_result[31:24]), .G(G3), .P(P3));

    // Calculate carry_out (used in multiplier)
    wire P3G2, P3P2G1, P3P2P1G0, P3P2P1P0c0;
    and P3_and_G2(P3G2, P3, G2);
    and P3_and_P2_and_G1(P3P2G1, P3, P2, G1);
    and P3_and_P2_and_P1_and_G0(P3P2P1G0, P3, P2, P1, G0);
    and P3_and_P2_and_P1_and_P0_and_c0(P3P2P1P0c0, P3, P2, P1, P0, c0);
    or carry32(carry_out, G3, P3G2, P3P2G1, P3P2P1G0, P3P2P1P0c0);

    // --- Determine Overflow --- \\

    // Declare wires for MSB and inverted signals
    wire msbA, msbB, msbResult;
    wire notA, notB, notResult;
    wire and1, and2;

    // Extract the MSB (most significant bit) from A, B, and result
    assign msbA = data_operandA[31];  // MSB of A
    assign msbB = data_operandB[31];  // MSB of B
    assign msbResult = data_result[31];  // MSB of result

    // Invert the MSBs
    not invertA(notA, msbA);
    not invertB(notB, msbB);
    not invertResult(notResult, msbResult);

    // First condition: A and B negative, result positive
    // Second condition: A and B positive, result negative
    
    and condition1(and1, msbA, msbB, notResult);
    and condition2(and2, notA, notB, msbResult);
    or calculate_overflow(overflow, and1, and2);
    
endmodule