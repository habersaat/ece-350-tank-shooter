module register (
	clock,
	reset,
    in_enable,
    D,
    Q
);

	input clock, reset, in_enable;
	input [31:0] D;
	output [31:0] Q;

    // Define the 32 DFFs
    genvar i; 
    generate
        for (i = 0; i < 32; i = i + 1) begin : reg_loop
            dffe_ref dff (Q[i], D[i], clock, in_enable, reset);
        end
    endgenerate

endmodule
