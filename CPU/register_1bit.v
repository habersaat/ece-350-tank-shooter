module register_1bit (
    clock,
    reset,
    in_enable,
    D,
    Q
);

    input clock, reset, in_enable;
    input D;
    output Q;

    // Instantiate a single DFF for 1-bit storage
    dffe_ref dff (Q, D, clock, in_enable, reset);

endmodule
