/*
 * Copyright (c) 2024 Your Name
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

module tt_um_dif_fft_core (
    input  wire [7:0] ui_in,    // Dedicated inputs
    output wire [7:0] uo_out,   // Dedicated outputs
    input  wire [7:0] uio_in,   // IOs: Input path
    output wire [7:0] uio_out,  // IOs: Output path
    output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
    input  wire       ena,      // always 1 when the design is powered, so you can ignore it
    input  wire       clk,      // clock
    input  wire       rst_n     // reset_n - low to reset
);


    localparam width_p = 8;

    wire reset = ~rst_n;


    // SIPO
    logic sipo_valid;
    logic [width_p-1:0] sipo_real [0:3];
    logic [width_p-1:0] sipo_imag [0:3];

    sipo #(.width_p(width_p)) sipo_inst (
        .clk_i(clk),
        .reset_i(reset),
        .serial_real(ui_in),
        .serial_imag(uio_in),
        .valid_o(sipo_valid),
        .buf_real(sipo_real),
        .buf_imag(sipo_imag)
    );

    // FFT
    logic fft_valid_o;
    wire fft_ready_o;
    wire fft_ready_i = 1'b1;  // always ready downstream

    logic signed [width_p-1:0] fft_out_real [0:3];
    logic signed [width_p-1:0] fft_out_imag [0:3];

    fft #(.width_p(width_p)) fft_inst (
        .clk_i(clk),
        .reset_i(reset),

        .valid_i(sipo_valid),
        .ready_o(), /*TODO*/

        .in_real_0(sipo_real[0]),
        .in_real_1(sipo_real[1]),
        .in_real_2(sipo_real[2]),
        .in_real_3(sipo_real[3]),

        .in_img_0(sipo_imag[0]),
        .in_img_1(sipo_imag[1]),
        .in_img_2(sipo_imag[2]),
        .in_img_3(sipo_imag[3]),

        .valid_o(fft_valid_o),
        .ready_i(fft_ready_i),

        .out_real_0(fft_out_real[0]),
        .out_real_1(fft_out_real[1]),
        .out_real_2(fft_out_real[2]),
        .out_real_3(fft_out_real[3]),

        .out_img_0(fft_out_imag[0]),
        .out_img_1(fft_out_imag[1]),
        .out_img_2(fft_out_imag[2]),
        .out_img_3(fft_out_imag[3])
    );

    // PISO
    logic piso_valid;
    logic [width_p-1:0] serial_real_out;
    logic [width_p-1:0] serial_imag_out;

    piso #(.width_p(width_p)) piso_inst (
        .clk_i(clk),
        .reset_i(reset),
        .ready_i(1'b1),   // always shifting
        .buf_real(fft_out_real),
        .buf_imag(fft_out_imag),
        .valid_o(piso_valid),
        .serial_real(serial_real_out),
        .serial_imag(serial_imag_out)
    );


    assign uo_out  = serial_real_out;
    assign uio_out = serial_imag_out;

    // drive uio as output
    assign uio_oe  = 8'hFF;

    // unused
    wire _unused = &{ena, 1'b0};

endmodule