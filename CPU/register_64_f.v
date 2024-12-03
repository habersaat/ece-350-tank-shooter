module register_64_f(
    input clock,
    input reset,
    input in_enable,
    input [63:0] D,
    output [63:0] Q
);
    genvar i;
    generate
        for (i = 0; i < 64; i = i + 1) begin : reg_loop
            dffe_ref_negedge dff (Q[i], D[i], clock, in_enable, reset);
        end
    endgenerate
endmodule
