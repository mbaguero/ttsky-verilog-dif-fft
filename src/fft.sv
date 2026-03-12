module fft
    #(parameter width_p = 2)
    (
     input  signed [width_p-1:0] in_real_0
    ,input  signed [width_p-1:0] in_real_1
    ,input  signed [width_p-1:0] in_real_2
    ,input  signed [width_p-1:0] in_real_3
    ,output signed [width_p+1:0] out_real_0  
    ,output signed [width_p+1:0] out_real_1  
    ,output signed [width_p+1:0] out_img_1   
    ,output signed [width_p+1:0] out_real_2
    );

    // Stage 1: widen inputs by 1 bit before adding → 3-bit intermediates
    wire signed [width_p:0] A_r = {{1{in_real_0[width_p-1]}}, in_real_0}
                                + {{1{in_real_2[width_p-1]}}, in_real_2};
    wire signed [width_p:0] B_r = {{1{in_real_1[width_p-1]}}, in_real_1}
                                + {{1{in_real_3[width_p-1]}}, in_real_3};
    wire signed [width_p:0] C_r = {{1{in_real_0[width_p-1]}}, in_real_0}
                                - {{1{in_real_2[width_p-1]}}, in_real_2};
    wire signed [width_p:0] D_r = {{1{in_real_3[width_p-1]}}, in_real_3}
                                - {{1{in_real_1[width_p-1]}}, in_real_1};

    // Stage 2: widen intermediates by 1 bit before adding → 4-bit outputs
    assign out_real_0 = {{1{A_r[width_p]}}, A_r} + {{1{B_r[width_p]}}, B_r};
    assign out_real_2 = {{1{A_r[width_p]}}, A_r} - {{1{B_r[width_p]}}, B_r};
    assign out_real_1 = {{2{C_r[width_p]}}, C_r[width_p-1:0]};  // sign-extend to 4 bits
    assign out_img_1  = {{2{D_r[width_p]}}, D_r[width_p-1:0]};

endmodule