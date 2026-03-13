/*
 * Copyright (c) 2024 Michael Aguero
 * SPDX-License-Identifier: Apache-2.0
 */
`default_nettype none

//============================================================================
// Top Module: tt_um_dif_fft_core
//============================================================================
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
    //------------------------------------------------------------------------
    // Parameters
    //------------------------------------------------------------------------
    localparam width_p = 6;
    
    //------------------------------------------------------------------------
    // Internal Signals
    //------------------------------------------------------------------------
    wire reset = ~rst_n;
    
    // SIPO to FFT signals
    wire valid_lo, ready_li;
    wire [width_p-1:0] sipo_real_0, sipo_real_1, sipo_real_2, sipo_real_3;
    wire [width_p-1:0] sipo_imag_0, sipo_imag_1, sipo_imag_2, sipo_imag_3;
    
    // FFT to PISO signals
    wire [width_p-1:0] fft_real_0,  fft_real_1,  fft_real_2,  fft_real_3;
    wire [width_p-1:0] fft_imag_0,  fft_imag_1,  fft_imag_2,  fft_imag_3;
    
    // Control signals
    wire serial_valid;
    wire [7:0] serial_imag_combined;
    
    //------------------------------------------------------------------------
    // Fix for UNUSEDSIGNAL - use the upper bits of uio_in
    //------------------------------------------------------------------------
    wire [3:0] uio_in_upper_unused;
    assign uio_in_upper_unused = uio_in[7:4];
    
    //------------------------------------------------------------------------
    // Control Logic
    //------------------------------------------------------------------------
    assign serial_valid = !valid_lo;
    assign serial_imag_combined = {uio_in[3:0], ui_in[7:6]};
    assign uio_oe = 8'b11110000;
    
    //------------------------------------------------------------------------
    // SIPO Module Instantiation
    //------------------------------------------------------------------------
    sipo #(.width_p(width_p)) sipo_inst (
        .clk_i       (clk),
        .reset_i     (reset),
        .valid_i     (serial_valid),
        .serial_real (ui_in[5:0]),
        .serial_imag (serial_imag_combined[5:0]),
        .ready_i     (ready_li),
        .valid_o     (valid_lo),
        .buf_real_0  (sipo_real_0), 
        .buf_real_1  (sipo_real_1),
        .buf_real_2  (sipo_real_2), 
        .buf_real_3  (sipo_real_3),
        .buf_imag_0  (sipo_imag_0), 
        .buf_imag_1  (sipo_imag_1),
        .buf_imag_2  (sipo_imag_2), 
        .buf_imag_3  (sipo_imag_3)
    );
    
    //------------------------------------------------------------------------
    // FFT Module Instantiation
    //------------------------------------------------------------------------
    fft #(.width_p(width_p)) fft_inst (
        .in_real_0  (sipo_real_0), 
        .in_real_1  (sipo_real_1),
        .in_real_2  (sipo_real_2), 
        .in_real_3  (sipo_real_3),
        .in_img_0   (sipo_imag_0), 
        .in_img_1   (sipo_imag_1),
        .in_img_2   (sipo_imag_2), 
        .in_img_3   (sipo_imag_3),
        .out_real_0 (fft_real_0),  
        .out_real_1 (fft_real_1),
        .out_real_2 (fft_real_2),  
        .out_real_3 (fft_real_3),
        .out_img_0  (fft_imag_0),  
        .out_img_1  (fft_imag_1),
        .out_img_2  (fft_imag_2),  
        .out_img_3  (fft_imag_3)
    );
    
    //------------------------------------------------------------------------
    // PISO Module Instantiation
    //------------------------------------------------------------------------
    piso #(.width_p(width_p)) piso_inst (
        .clk_i       (clk),
        .reset_i     (reset),
        .valid_i     (valid_lo),
        .ready_o     (ready_li),
        .buf_real_0  (fft_real_0), 
        .buf_real_1  (fft_real_1),
        .buf_real_2  (fft_real_2), 
        .buf_real_3  (fft_real_3),
        .buf_imag_0  (fft_imag_0), 
        .buf_imag_1  (fft_imag_1),
        .buf_imag_2  (fft_imag_2), 
        .buf_imag_3  (fft_imag_3),
        .serial_real (uo_out[5:0]),
        .serial_imag ({uio_out[7:4], uo_out[7:6]})
    );
    
    //------------------------------------------------------------------------
    // Unused Signals
    //------------------------------------------------------------------------
    wire _unused = &{ena, uio_in_upper_unused, 1'b0};

endmodule

//============================================================================
// SIPO Module - Serial In Parallel Out
//============================================================================
module sipo #(
    parameter width_p = 6
) (
    input  wire                     clk_i,
    input  wire                     reset_i,
    input  wire                     valid_i,
    input  wire [width_p-1:0]       serial_real,
    input  wire [width_p-1:0]       serial_imag,
    input  wire                     ready_i,
    output reg                      valid_o,
    output reg  [width_p-1:0]       buf_real_0,
    output reg  [width_p-1:0]       buf_real_1,
    output reg  [width_p-1:0]       buf_real_2,
    output reg  [width_p-1:0]       buf_real_3,
    output reg  [width_p-1:0]       buf_imag_0,
    output reg  [width_p-1:0]       buf_imag_1,
    output reg  [width_p-1:0]       buf_imag_2,
    output reg  [width_p-1:0]       buf_imag_3
);
    //------------------------------------------------------------------------
    // Internal Signals
    //------------------------------------------------------------------------
    reg [1:0] count;
    reg [width_p-1:0] stage0_real, stage1_real, stage2_real, stage3_real;
    reg [width_p-1:0] stage0_imag, stage1_imag, stage2_imag, stage3_imag;
    
    //------------------------------------------------------------------------
    // Sequential Logic
    //------------------------------------------------------------------------
    always @(posedge clk_i) begin
        if (reset_i) begin
            count <= 2'b0;
            stage0_real <= {width_p{1'b0}};
            stage1_real <= {width_p{1'b0}};
            stage2_real <= {width_p{1'b0}};
            stage3_real <= {width_p{1'b0}};
            stage0_imag <= {width_p{1'b0}};
            stage1_imag <= {width_p{1'b0}};
            stage2_imag <= {width_p{1'b0}};
            stage3_imag <= {width_p{1'b0}};
            valid_o <= 1'b0;
        end else begin
            if (valid_i && ready_i) begin
                // Shift pipeline and load new data
                stage3_real <= stage2_real;
                stage2_real <= stage1_real;
                stage1_real <= stage0_real;
                stage0_real <= serial_real;
                
                stage3_imag <= stage2_imag;
                stage2_imag <= stage1_imag;
                stage1_imag <= stage0_imag;
                stage0_imag <= serial_imag;
                
                count <= count + 1;
                
                // When we've collected 4 samples, assert valid
                if (count == 2'b11) begin
                    valid_o <= 1'b1;
                end
            end
            
            // Clear valid when downstream is ready
            if (valid_o && ready_i) begin
                valid_o <= 1'b0;
                count <= 2'b0;
            end
        end
    end
    
    //------------------------------------------------------------------------
    // Output Assignments
    //------------------------------------------------------------------------
    always @* begin
        buf_real_0 = stage0_real;
        buf_real_1 = stage1_real;
        buf_real_2 = stage2_real;
        buf_real_3 = stage3_real;
        buf_imag_0 = stage0_imag;
        buf_imag_1 = stage1_imag;
        buf_imag_2 = stage2_imag;
        buf_imag_3 = stage3_imag;
    end

endmodule

//============================================================================
// FFT Module: 4-point DIF FFT (Combinational)
//============================================================================
module fft #(
    parameter width_p = 8
) (
    input  signed [width_p-1:0] in_real_0,
    input  signed [width_p-1:0] in_real_1,
    input  signed [width_p-1:0] in_real_2,
    input  signed [width_p-1:0] in_real_3,
    input  signed [width_p-1:0] in_img_0,
    input  signed [width_p-1:0] in_img_1,
    input  signed [width_p-1:0] in_img_2,
    input  signed [width_p-1:0] in_img_3,
    output signed [width_p-1:0] out_real_0,
    output signed [width_p-1:0] out_real_1,
    output signed [width_p-1:0] out_real_2,
    output signed [width_p-1:0] out_real_3,
    output signed [width_p-1:0] out_img_0,
    output signed [width_p-1:0] out_img_1,
    output signed [width_p-1:0] out_img_2,
    output signed [width_p-1:0] out_img_3
);
    // Stage 1 intermediate signals
    wire signed [width_p-1:0] A_r, B_r, C_r, D_r;
    wire signed [width_p-1:0] A_i, B_i, C_i, D_i;

    // Stage 1 computations
    assign A_r = (in_real_0 + in_real_2) >>> 1;
    assign B_r = (in_real_1 + in_real_3) >>> 1;
    assign C_r = (in_real_0 - in_real_2) >>> 1;
    assign D_r = (in_img_1 - in_img_3) >>> 1;

    assign A_i = (in_img_0 + in_img_2) >>> 1;
    assign B_i = (in_img_1 + in_img_3) >>> 1;
    assign C_i = (in_img_0 - in_img_2) >>> 1;
    assign D_i = (-(in_real_1 - in_real_3)) >>> 1;

    // Stage 2 computations (final output)
    assign out_real_0 = (A_r + B_r) >>> 1;
    assign out_real_1 = (A_r - B_r) >>> 1;
    assign out_real_2 = (C_r + D_r) >>> 1;
    assign out_real_3 = (C_r - D_r) >>> 1;
    assign out_img_0  = (A_i + B_i) >>> 1;
    assign out_img_1  = (A_i - B_i) >>> 1;
    assign out_img_2  = (C_i + D_i) >>> 1;
    assign out_img_3  = (C_i - D_i) >>> 1;

endmodule

//============================================================================
// PISO Module - Parallel In Serial Out
//============================================================================
module piso #(
    parameter width_p = 6
) (
    input  wire                     clk_i,
    input  wire                     reset_i,
    input  wire                     valid_i,
    output reg                      ready_o,
    input  wire [width_p-1:0]       buf_real_0,
    input  wire [width_p-1:0]       buf_real_1,
    input  wire [width_p-1:0]       buf_real_2,
    input  wire [width_p-1:0]       buf_real_3,
    input  wire [width_p-1:0]       buf_imag_0,
    input  wire [width_p-1:0]       buf_imag_1,
    input  wire [width_p-1:0]       buf_imag_2,
    input  wire [width_p-1:0]       buf_imag_3,
    output reg  [width_p-1:0]       serial_real,
    output reg  [width_p-1:0]       serial_imag
);
    //------------------------------------------------------------------------
    // Internal Signals
    //------------------------------------------------------------------------
    reg [1:0] count;
    reg [width_p-1:0] buffer_real[0:3];
    reg [width_p-1:0] buffer_imag[0:3];
    reg busy;
    
    //------------------------------------------------------------------------
    // Sequential Logic
    //------------------------------------------------------------------------
    always @(posedge clk_i) begin
        integer j;
        
        if (reset_i) begin
            count <= 2'b0;
            busy <= 1'b0;
            ready_o <= 1'b1;
            serial_real <= {width_p{1'b0}};
            serial_imag <= {width_p{1'b0}};
            for (j = 0; j < 4; j = j + 1) begin
                buffer_real[j] <= {width_p{1'b0}};
                buffer_imag[j] <= {width_p{1'b0}};
            end
        end else begin
            // Default ready flag
            ready_o <= !busy;
            
            if (valid_i && !busy) begin
                // Load new data
                buffer_real[0] <= buf_real_0;
                buffer_real[1] <= buf_real_1;
                buffer_real[2] <= buf_real_2;
                buffer_real[3] <= buf_real_3;
                buffer_imag[0] <= buf_imag_0;
                buffer_imag[1] <= buf_imag_1;
                buffer_imag[2] <= buf_imag_2;
                buffer_imag[3] <= buf_imag_3;
                busy <= 1'b1;
                count <= 2'b0;
                
                // Output first sample immediately
                serial_real <= buf_real_0;
                serial_imag <= buf_imag_0;
            end else if (busy) begin
                // Output current sample based on count
                case (count)
                    2'b00: begin
                        serial_real <= buffer_real[0];
                        serial_imag <= buffer_imag[0];
                    end
                    2'b01: begin
                        serial_real <= buffer_real[1];
                        serial_imag <= buffer_imag[1];
                    end
                    2'b10: begin
                        serial_real <= buffer_real[2];
                        serial_imag <= buffer_imag[2];
                    end
                    2'b11: begin
                        serial_real <= buffer_real[3];
                        serial_imag <= buffer_imag[3];
                    end
                endcase
                
                // Increment counter
                count <= count + 1;
                
                // After outputting all 4 samples, clear busy
                if (count == 2'b11) begin
                    busy <= 1'b0;
                end
            end
        end
    end

endmodule