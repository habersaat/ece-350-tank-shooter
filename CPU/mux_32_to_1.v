module mux_32(out, select, in0, in1, in2, in3, in4, in5, in6, in7, in8, in9, in10, in11, in12, in13, in14, in15, in16, in17, in18, in19, in20, in21, in22, in23, in24, in25, in26, in27, in28, in29, in30, in31, in32);
    input [4:0] select;
    input [31:0] in0, in1, in2, in3, in4, in5, in6, in7, in8, in9, in10, in11, in12, in13, in14, in15, in16, in17, in18, in19, in20, in21, in22, in23, in24, in25, in26, in27, in28, in29, in30, in31, in32;
    output [31:0] out;
    wire [31:0] w1, w2, w3, w4;
    
    mux_8 first_mux(w1, select[2:0], in0, in1, in2, in3, in4, in5, in6, in7);
    mux_8 second_mux(w2, select[2:0], in8, in9, in10, in11, in12, in13, in14, in15);
    mux_8 third_mux(w3, select[2:0], in16, in17, in18, in19, in20, in21, in22, in23);
    mux_8 fourth_mux(w4, select[2:0], in24, in25, in26, in27, in28, in29, in30, in31);
    
    mux_4 final_mux(out, select[4:3], w1, w2, w3, w4);
endmodule
