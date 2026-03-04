/*
 * Copyright (c) 2024 Your Name
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
    localparam width_p = 6;
    wire reset = ~rst_n;

    // uio[7:4] = outputs, [3:0] = inputs
    assign uio_oe = 8'b11110000;

    // Gate SIPO: stop accepting new samples while PISO is outputting
    wire piso_active;
    wire sipo_en = ~piso_active;

    // SIPO
    wire valid_lo;
    logic [width_p-1:0] sipo_real [0:3];
    logic [width_p-1:0] sipo_imag [0:3];

    sipo #(.width_p(width_p)) sipo_inst (
        .clk_i       (clk),
        .reset_i     (reset),
        .en_i        (sipo_en),          // pauses while PISO reads
        .serial_real (ui_in[5:0]),
        .serial_imag ({uio_in[3:0], ui_in[7:6]}),
        .valid_o     (valid_lo),
        .buf_real    (sipo_real),
        .buf_imag    (sipo_imag)
    );

    // FFT (combinational)
    logic signed [width_p-1:0] fft_out_real [0:3];
    logic signed [width_p-1:0] fft_out_imag [0:3];

    fft #(.width_p(width_p)) fft_inst (
        .in_real_0  (sipo_real[0]), .in_real_1 (sipo_real[1]),
        .in_real_2  (sipo_real[2]), .in_real_3 (sipo_real[3]),
        .in_img_0   (sipo_imag[0]), .in_img_1  (sipo_imag[1]),
        .in_img_2   (sipo_imag[2]), .in_img_3  (sipo_imag[3]),
        .out_real_0 (fft_out_real[0]), .out_real_1 (fft_out_real[1]),
        .out_real_2 (fft_out_real[2]), .out_real_3 (fft_out_real[3]),
        .out_img_0  (fft_out_imag[0]), .out_img_1  (fft_out_imag[1]),
        .out_img_2  (fft_out_imag[2]), .out_img_3  (fft_out_imag[3])
    );

    // PISO
    piso #(.width_p(width_p)) piso_inst (
        .clk_i       (clk),
        .reset_i     (reset),
        .buf_real    (fft_out_real),
        .buf_imag    (fft_out_imag),
        .valid_i     (valid_lo),
        .active_o    (piso_active),      // new output port
        .serial_real ({uo_out[5:0]}),
        .serial_imag ({uio_out[7:4], uo_out[7:6]})
    );

    wire _unused = &{ena, 1'b0};
endmodule