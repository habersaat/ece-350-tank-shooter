module sub(data_operandA, data_operandB, data_result, isNotEqual, isLessThan, overflow);
        
    // Declare inputs and outputs
    input [31:0] data_operandA, data_operandB;
    output [31:0] data_result;
    output isNotEqual, isLessThan, overflow;

    // Negate B
    wire [31:0] negatedB;
    bitwise_not inverseB(.data_operandA(data_operandB), .data_result(negatedB));

    // Add A and -B (with Cin = 1)
    add adder(.data_operandA(data_operandA), .data_operandB(negatedB), .Cin(1'b1), .data_result(data_result), .overflow(overflow));

    // Calculate isNotEqual (A != B) by checking the result
    or neq(isNotEqual, data_result[0], data_result[1], data_result[2], data_result[3], data_result[4], data_result[5], data_result[6], data_result[7],
        data_result[8], data_result[9], data_result[10], data_result[11], data_result[12], data_result[13], data_result[14], data_result[15],
        data_result[16], data_result[17], data_result[18], data_result[19], data_result[20], data_result[21], data_result[22], data_result[23],
        data_result[24], data_result[25], data_result[26], data_result[27], data_result[28], data_result[29], data_result[30], data_result[31]);

    // --- Calculate isLessThan (A < B) --- \\

    // Declare wires for MSB and inverted signals
    wire msbA, msbB, msbResult;
    wire notA, notB, notResult;
    wire and1, and2, and3;

    // Extract the MSB (most significant bit) from A, B, and result
    assign msbA = data_operandA[31];  // MSB of A
    assign msbB = data_operandB[31];  // MSB of B
    assign msbResult = data_result[31];  // MSB of result

    // Invert the MSBs
    not invertA(notA, msbA);
    not invertB(notB, msbB);
    not invertResult(notResult, msbResult);

    // First condition: A and B positive, result negative
    // Second condition: A and B negative, result negative
    // Third condition: A negative, B positive

    and condition1(and1, notA, notB, msbResult);
    and condition2(and2, msbA, msbB, msbResult);
    and condition3(and3, msbA, notB);
    or calculate_isLessThan(isLessThan, and1, and2, and3);

endmodule