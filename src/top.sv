/*
 * Copyright (c) 2024 Michael Aguero
 * SPDX-License-Identifier: Apache-2.0
 */
`default_nettype none
module tt_um_dif_fft_core (
    input  wire [7:0] ui_in,
    output wire [7:0] uo_out,
    input  wire [7:0] uio_in,
    output wire [7:0] uio_out,
    output wire [7:0] uio_oe,
    input  wire       ena,
    input  wire       clk,
    input  wire       rst_n
);
    localparam width_p = 2;
    wire reset = ~rst_n;

    // uio[7:0] = outputs
    assign uio_oe = 8'b11111111;


    fft #(.width_p(width_p)) fft_inst (
        .in_real_0(ui_in[1:0]),
        .in_real_1(ui_in[3:2]),
        .in_real_2(ui_in[5:4]),
        .in_real_3(ui_in[7:6]),

        .out_real_0(uo_out[3:0]),    // X[0] DC
        .out_real_2(uo_out[7:4]),    // X[2] Nyquist  
        .out_real_1(uio_out[3:0]),   // X[1] real     
        .out_img_1 (uio_out[7:4])  
    );


    wire _unused = &{ena, clk, rst_n, uio_in, 1'b0};
    
endmodule