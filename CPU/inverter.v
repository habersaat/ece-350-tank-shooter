module inverter(
    input [31:0] data,
    output [31:0] data_inv
);

    wire [31:0] data_reversed_bits;
    assign data_reversed_bits = ~data;

    add adder(
        .data_operandA(data_reversed_bits), 
        .data_operandB(32'b1), 
        .Cin(1'b0), 
        .data_result(data_inv), 
        .overflow(), 
        .carry_out()
    );

endmodule