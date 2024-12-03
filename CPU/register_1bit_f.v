module register_1bit_f (
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
    dffe_ref_negedge dff (Q, D, clock, in_enable, reset);

endmodule
