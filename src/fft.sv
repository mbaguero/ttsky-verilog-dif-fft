module fft
    #(parameter width_p = 8
    )
    (input signed [width_p - 1:0] in_real_0
    ,input signed [width_p - 1:0] in_real_1
    ,input signed [width_p - 1:0] in_real_2
    ,input signed [width_p - 1:0] in_real_3
    ,input signed [width_p - 1:0] in_img_0
    ,input signed [width_p - 1:0] in_img_1
    ,input signed [width_p - 1:0] in_img_2
    ,input signed [width_p - 1:0] in_img_3
    ,output signed [width_p -1:0] out_real_0
    ,output signed [width_p -1:0] out_real_1
    ,output signed [width_p -1:0] out_real_2
    ,output signed [width_p -1:0] out_real_3
    ,output signed [width_p -1:0] out_img_0
    ,output signed [width_p -1:0] out_img_1
    ,output signed [width_p -1:0] out_img_2
    ,output signed [width_p -1:0] out_img_3
    );


    wire signed [width_p-1:0] A_r, B_r, C_r, D_r;
    wire signed [width_p-1:0] A_i, B_i, C_i, D_i;

    assign A_r = (in_real_0 + in_real_2) >>> 1;
    assign B_r = (in_real_1 + in_real_3) >>> 1;
    assign C_r = (in_real_0 - in_real_2) >>> 1;
    assign D_r = (in_img_1 - in_img_3) >>> 1;

    assign A_i = (in_img_0 + in_img_2) >>> 1;
    assign B_i = (in_img_1 + in_img_3) >>> 1;
    assign C_i = (in_img_0 - in_img_2) >>> 1;
    assign D_i = (-(in_real_1 - in_real_3)) >>> 1;


    assign out_real_0 = (A_r + B_r) >>> 1;
    assign out_real_1 = (A_r - B_r) >>> 1;
    assign out_real_2 = (C_r + D_r) >>> 1;
    assign out_real_3 = (C_r - D_r) >>> 1;
    assign out_img_0  = (A_i + B_i) >>> 1;
    assign out_img_1  = (A_i - B_i) >>> 1;
    assign out_img_2  = (C_i + D_i) >>> 1;
    assign out_img_3  = (C_i - D_i) >>> 1;

endmodule