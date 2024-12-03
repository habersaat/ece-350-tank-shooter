module mux_2_33bit(out, select, in0, in1);
    input select;
    input [32:0] in0, in1;
    output [32:0] out;
    assign out = select ? in1 : in0;
endmodule