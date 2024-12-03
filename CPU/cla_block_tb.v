`timescale 1ns/1ps

module cla_block_tb;
    // Inputs to the CLA block
    reg [7:0] X;
    reg [7:0] Y;
    reg Cin;

    // Outputs from the CLA block
    wire [7:0] S;
    wire G_0, P_0;

    // Expected outputs for comparison
    reg [7:0] expected_S;
    reg expected_G_0, expected_P_0;

    // Instantiate the CLA block
    cla_block UUT (
        .X(X),
        .Y(Y),
        .Cin(Cin),
        .S(S),
        .G(G_0),     // Group generate
        .P(P_0)      // Group propagate
    );

    integer i, j, k;  // Loop variables for exhaustively testing inputs

    // Variables to store intermediate propagate and generate values
    reg p0, p1, p2, p3, p4, p5, p6, p7;
    reg g0, g1, g2, g3, g4, g5, g6, g7;

    initial begin
        // Loop through all combinations of X, Y, and Cin
        for (i = 0; i < 256; i = i + 1) begin
            for (j = 0; j < 256; j = j + 1) begin
                for (k = 0; k < 2; k = k + 1) begin
                    X = i;        // Assign a new value to X
                    Y = j;        // Assign a new value to Y
                    Cin = k;      // Assign a new value to Cin (0 or 1)

                    // Calculate individual propagate and generate signals
                    p0 = X[0] | Y[0];
                    p1 = X[1] | Y[1];
                    p2 = X[2] | Y[2];
                    p3 = X[3] | Y[3];
                    p4 = X[4] | Y[4];
                    p5 = X[5] | Y[5];
                    p6 = X[6] | Y[6];
                    p7 = X[7] | Y[7];

                    g0 = X[0] & Y[0];
                    g1 = X[1] & Y[1];
                    g2 = X[2] & Y[2];
                    g3 = X[3] & Y[3];
                    g4 = X[4] & Y[4];
                    g5 = X[5] & Y[5];
                    g6 = X[6] & Y[6];
                    g7 = X[7] & Y[7];

                    // Calculate the expected Group Propagate (P_0)
                    expected_P_0 = p7 & p6 & p5 & p4 & p3 & p2 & p1 & p0;

                    // Calculate the expected Group Generate (G_0)
                    expected_G_0 = g7 |
                                   (p7 & g6) |
                                   (p7 & p6 & g5) |
                                   (p7 & p6 & p5 & g4) |
                                   (p7 & p6 & p5 & p4 & g3) |
                                   (p7 & p6 & p5 & p4 & p3 & g2) |
                                   (p7 & p6 & p5 & p4 & p3 & p2 & g1) |
                                   (p7 & p6 & p5 & p4 & p3 & p2 & p1 & g0);

                    #10;  // Wait for propagation delay

                    // Calculate the expected sum (X + Y + Cin)
                    expected_S = X + Y + Cin;  // Expected sum and carry-out (group generate)

                    // Check if the actual outputs match the expected ones
                    if (S !== expected_S || G_0 !== expected_G_0 || P_0 !== expected_P_0) begin
                        $display("Mismatch for X: %b, Y: %b, Cin: %b", X, Y, Cin);
                        $display("Expected S: %b, G_0: %b, P_0: %b", expected_S, expected_G_0, expected_P_0);
                        $display("Actual   S: %b, G_0: %b, P_0: %b\n", S, G_0, P_0);
                    end
                end
            end
        end

        $finish;  // End the testbench
    end
endmodule
