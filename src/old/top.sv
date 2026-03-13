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

    assign uio_oe = 8'b11110000;

    wire valid_lo, ready_li;

    // Scalar wires replacing unpacked arrays (Icarus doesn't propagate
    // unpacked arrays across module port boundaries)
    wire [width_p-1:0] sipo_real_0, sipo_real_1, sipo_real_2, sipo_real_3;
    wire [width_p-1:0] sipo_imag_0, sipo_imag_1, sipo_imag_2, sipo_imag_3;
    wire [width_p-1:0] fft_real_0,  fft_real_1,  fft_real_2,  fft_real_3;
    wire [width_p-1:0] fft_imag_0,  fft_imag_1,  fft_imag_2,  fft_imag_3;

    // serial_valid: high whenever ui_in/uio_in carry a real sample.
    // Use ready_o from PISO inverted — when PISO is NOT outputting,
    // we are in receive mode. Or simply: always accept when !valid_lo.
    wire serial_valid = !valid_lo;

    sipo #(.width_p(width_p)) sipo_inst (
        .clk_i       (clk),
        .reset_i     (reset),
        .valid_i     (serial_valid),
        .serial_real (ui_in[5:0]),
        .serial_imag ({uio_in[3:0], ui_in[7:6]}),
        .ready_i     (ready_li),
        .valid_o     (valid_lo),
        .buf_real_0  (sipo_real_0), .buf_real_1 (sipo_real_1),
        .buf_real_2  (sipo_real_2), .buf_real_3 (sipo_real_3),
        .buf_imag_0  (sipo_imag_0), .buf_imag_1 (sipo_imag_1),
        .buf_imag_2  (sipo_imag_2), .buf_imag_3 (sipo_imag_3)
    );

    fft #(.width_p(width_p)) fft_inst (
        .in_real_0  (sipo_real_0), .in_real_1 (sipo_real_1),
        .in_real_2  (sipo_real_2), .in_real_3 (sipo_real_3),
        .in_img_0   (sipo_imag_0), .in_img_1  (sipo_imag_1),
        .in_img_2   (sipo_imag_2), .in_img_3  (sipo_imag_3),
        .out_real_0 (fft_real_0),  .out_real_1 (fft_real_1),
        .out_real_2 (fft_real_2),  .out_real_3 (fft_real_3),
        .out_img_0  (fft_imag_0),  .out_img_1  (fft_imag_1),
        .out_img_2  (fft_imag_2),  .out_img_3  (fft_imag_3)
    );

    piso #(.width_p(width_p)) piso_inst (
        .clk_i       (clk),
        .reset_i     (reset),
        .valid_i     (valid_lo),
        .ready_o     (ready_li),
        .buf_real_0  (fft_real_0), .buf_real_1 (fft_real_1),
        .buf_real_2  (fft_real_2), .buf_real_3 (fft_real_3),
        .buf_imag_0  (fft_imag_0), .buf_imag_1 (fft_imag_1),
        .buf_imag_2  (fft_imag_2), .buf_imag_3 (fft_imag_3),
        .serial_real (uo_out[5:0]),
        .serial_imag ({uio_out[7:4], uo_out[7:6]})
    );

    wire _unused = &{ena, 1'b0};

endmodule