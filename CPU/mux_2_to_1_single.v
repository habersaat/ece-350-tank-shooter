module mux_2_single(out, select, in0, in1);

    input select;
    input in0, in1;
    output out;
    assign out = select ? in1 : in0;
    
endmodule
