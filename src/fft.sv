module fft
    #(parameter width_p = 8
    )
    (input [0:0] clk_i
    ,input [0:0] reset_i

    ,input valid_i
    ,output logic ready_o

    ,input signed [width_p - 1:0] in_real_0
    ,input signed [width_p - 1:0] in_real_1
    ,input signed [width_p - 1:0] in_real_2
    ,input signed [width_p - 1:0] in_real_3
    ,input signed [width_p - 1:0] in_img_0
    ,input signed [width_p - 1:0] in_img_1
    ,input signed [width_p - 1:0] in_img_2
    ,input signed [width_p - 1:0] in_img_3

    ,output logic valid_o
    ,input ready_i

    ,output signed [width_p -1:0] out_real_0
    ,output signed [width_p -1:0] out_real_1
    ,output signed [width_p -1:0] out_real_2
    ,output signed [width_p -1:0] out_real_3
    ,output signed [width_p -1:0] out_img_0
    ,output signed [width_p -1:0] out_img_1
    ,output signed [width_p -1:0] out_img_2
    ,output signed [width_p -1:0] out_img_3
    )

    wire ready_lo;
    wire ready_li;
    wire valid_lo;
    wire valid_li;

    // Stage 1

    wire signed [width_p -1:0] A_r, B_r, C_r, D_r;
    wire signed [width_p -1:0] A_i, B_i, C_i, D_i;

    wire signed [width_p -1:0] A_rq, B_rq, C_rq, D_rq;
    wire signed [width_p -1:0] A_iq, B_iq, C_iq, D_iq;

    assign A_r = (in_real_0 + in_real_2) >>> 1;
    assign B_r = (in_real_1 + in_real_3) >>> 1;
    assign C_r = (in_real_0 - in_real_2) >>> 1;
    assign D_r = (in_img_1 - in_img_3) >>> 1;

    assign A_i = (in_img_0 + in_img_2) >>> 1;
    assign B_i = (in_img_1 + in_img_3) >>> 1;
    assign C_i = (in_img_0 - in_img_2) >>> 1;
    assign D_i = (-(in_real_1 - in_real_3)) >>> 1;

    elastic #(
        .width_p(width_p)
    )
    elastic_inst_0 (
        .clk_i(clk_i),
        .reset_i(reset_i),

        .valid_i(valid_i),
        .ready_o(ready_o),

        .data0_i(A_r),
        .data1_i(B_r),
        .data2_i(C_r),
        .data3_i(D_r),
        .data4_i(A_i),
        .data5_i(B_i),
        .data6_i(C_i),
        .data7_i(D_i),

        .valid_o(valid_lo),
        .ready_i(ready_li),

        .data0_o(A_rq),
        .data1_o(B_rq),
        .data2_o(C_rq),
        .data3_o(D_rq),
        .data4_o(A_iq),
        .data5_o(B_iq),
        .data6_o(C_iq),
        .data7_o(D_iq)
    );

    // Stage 2

    wire signed [width_p -1:0] X0_r, X1_r, X0_i, X1_i;
    wire signed [width_p -1:0] X2_r, X3_r, X2_i, X3_i;

    wire signed [width_p -1:0] X0_rq, X1_rq, X0_iq, X1_iq;
    wire signed [width_p -1:0] X2_rq, X3_rq, X2_iq, X3_iq;

    assign X0_r = (A_rq + B_rq) >>> 1;
    assign X1_r = (A_rq - B_rq) >>> 1;
    assign X2_r = (C_rq + D_rq) >>> 1;
    assign X3_r = (C_rq - D_rq) >>> 1;

    assign X0_i = (A_iq + B_iq) >>> 1;
    assign X1_i = (A_iq - B_iq) >>> 1;
    assign X2_i = (C_iq + D_iq) >>> 1;
    assign X3_i = (C_iq - D_iq) >>> 1;


    elastic #(
        .width_p(width_p)
    )
    elastic_inst_1 (
        .clk_i(clk_i),
        .reset_i(reset_i),

        .valid_i(valid_lo),
        .ready_o(ready_li),

        .data0_i(X0_r),
        .data1_i(X1_r),
        .data2_i(X2_r),
        .data3_i(X3_r),
        .data4_i(X0_i),
        .data5_i(X1_i),
        .data6_i(X2_i),
        .data7_i(X3_i),

        .valid_o(valid_o),
        .ready_i(ready_i),

        .data0_o(out_real_0),
        .data1_o(out_real_1),
        .data2_o(out_real_2),
        .data3_o(out_real_3),
        .data4_o(out_img_0),
        .data5_o(out_img_1),
        .data6_o(out_img_2),
        .data7_o(out_img_3)
    );

endmodule