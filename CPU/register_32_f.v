module register_32_f(
    input clock,
    input reset,
    input in_enable,
    input [31:0] D,
    output [31:0] Q
);
    genvar i;
    generate
        for (i = 0; i < 32; i = i + 1) begin : reg_loop
            dffe_ref_negedge dff (Q[i], D[i], clock, in_enable, reset);
        end
    endgenerate
endmodule
