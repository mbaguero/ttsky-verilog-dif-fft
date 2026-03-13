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
    
    // SIPO to FFT signals
    wire valid_lo, ready_li;
    wire [width_p-1:0] sipo_real_0, sipo_real_1, sipo_real_2, sipo_real_3;
    wire [width_p-1:0] sipo_imag_0, sipo_imag_1, sipo_imag_2, sipo_imag_3;
    
    // FFT to PISO signals
    wire [width_p-1:0] fft_real_0,  fft_real_1,  fft_real_2,  fft_real_3;
    wire [width_p-1:0] fft_imag_0,  fft_imag_1,  fft_imag_2,  fft_imag_3;
    
    // Control signals
    wire serial_valid;
    wire [5:0] serial_imag_combined;
    

    wire [3:0] uio_in_upper_unused;
    assign uio_in_upper_unused = uio_in[7:4];
    

    assign serial_valid = !valid_lo;
    assign serial_imag_combined = {uio_in[3:0], ui_in[7:6]};
    assign uio_oe = 8'b11110000;
    

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
    
    wire _unused = &{ena, uio_in_upper_unused, 1'b0, uio_out[3:0]};

endmodule


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

    reg [1:0] count_q, count_d;
    reg [width_p-1:0] stage0_real_q, stage0_real_d;
    reg [width_p-1:0] stage1_real_q, stage1_real_d;
    reg [width_p-1:0] stage2_real_q, stage2_real_d;
    reg [width_p-1:0] stage3_real_q, stage3_real_d;
    reg [width_p-1:0] stage0_imag_q, stage0_imag_d;
    reg [width_p-1:0] stage1_imag_q, stage1_imag_d;
    reg [width_p-1:0] stage2_imag_q, stage2_imag_d;
    reg [width_p-1:0] stage3_imag_q, stage3_imag_d;
    reg valid_q, valid_d;
    

    always @(posedge clk_i) begin
        if (reset_i) begin
            count_q <= 2'b0;
            stage0_real_q <= {width_p{1'b0}};
            stage1_real_q <= {width_p{1'b0}};
            stage2_real_q <= {width_p{1'b0}};
            stage3_real_q <= {width_p{1'b0}};
            stage0_imag_q <= {width_p{1'b0}};
            stage1_imag_q <= {width_p{1'b0}};
            stage2_imag_q <= {width_p{1'b0}};
            stage3_imag_q <= {width_p{1'b0}};
            valid_q <= 1'b0;
        end else begin
            count_q <= count_d;
            stage0_real_q <= stage0_real_d;
            stage1_real_q <= stage1_real_d;
            stage2_real_q <= stage2_real_d;
            stage3_real_q <= stage3_real_d;
            stage0_imag_q <= stage0_imag_d;
            stage1_imag_q <= stage1_imag_d;
            stage2_imag_q <= stage2_imag_d;
            stage3_imag_q <= stage3_imag_d;
            valid_q <= valid_d;
        end
    end
    

    always_comb begin
        count_d = count_q;
        stage0_real_d = stage0_real_q;
        stage1_real_d = stage1_real_q;
        stage2_real_d = stage2_real_q;
        stage3_real_d = stage3_real_q;
        stage0_imag_d = stage0_imag_q;
        stage1_imag_d = stage1_imag_q;
        stage2_imag_d = stage2_imag_q;
        stage3_imag_d = stage3_imag_q;
        valid_d = valid_q;
        
        if (valid_i && ready_i) begin
            stage3_real_d = stage2_real_q;
            stage2_real_d = stage1_real_q;
            stage1_real_d = stage0_real_q;
            stage0_real_d = serial_real;
            
            stage3_imag_d = stage2_imag_q;
            stage2_imag_d = stage1_imag_q;
            stage1_imag_d = stage0_imag_q;
            stage0_imag_d = serial_imag;
            
            count_d = count_q + 1;
            
            if (count_q == 2'b11) begin
                valid_d = 1'b1;
            end
        end
        
        if (valid_q && ready_i) begin
            valid_d = 1'b0;
            count_d = 2'b0;
        end
    end
    

    assign buf_real_0 = stage0_real_q;
    assign buf_real_1 = stage1_real_q;
    assign buf_real_2 = stage2_real_q;
    assign buf_real_3 = stage3_real_q;
    assign buf_imag_0 = stage0_imag_q;
    assign buf_imag_1 = stage1_imag_q;
    assign buf_imag_2 = stage2_imag_q;
    assign buf_imag_3 = stage3_imag_q;
    assign valid_o = valid_q;

endmodule

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

//============================================================================
// PISO Module: Parallel In Serial Out (4-stage to serial)
//============================================================================
module piso #(
    parameter width_p = 6
) (
    input  wire                     clk_i,
    input  wire                     reset_i,
    input  wire                     valid_i,
    output wire                     ready_o,
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
  
    reg [1:0] count_q, count_d;
    reg [width_p-1:0] buffer_real_q[0:3];
    reg [width_p-1:0] buffer_imag_q[0:3];
    reg busy_q, busy_d;
    reg [width_p-1:0] buffer_real_next[0:3];
    reg [width_p-1:0] buffer_imag_next[0:3];
    

    always @(posedge clk_i) begin
        integer j;
        if (reset_i) begin
            count_q <= 2'b0;
            busy_q <= 1'b0;
            for (j = 0; j < 4; j = j + 1) begin
                buffer_real_q[j] <= {width_p{1'b0}};
                buffer_imag_q[j] <= {width_p{1'b0}};
            end
        end else begin
            count_q <= count_d;
            busy_q <= busy_d;
            for (j = 0; j < 4; j = j + 1) begin
                buffer_real_q[j] <= buffer_real_next[j];
                buffer_imag_q[j] <= buffer_imag_next[j];
            end
        end
    end
    

    always_comb begin
        integer k;
        
        count_d = count_q;
        busy_d = busy_q;
        for (k = 0; k < 4; k = k + 1) begin
            buffer_real_next[k] = buffer_real_q[k];
            buffer_imag_next[k] = buffer_imag_q[k];
        end
        
  
        serial_real = {width_p{1'b0}};
        serial_imag = {width_p{1'b0}};
        
        if (valid_i && !busy_q) begin

            buffer_real_next[0] = buf_real_0;
            buffer_real_next[1] = buf_real_1;
            buffer_real_next[2] = buf_real_2;
            buffer_real_next[3] = buf_real_3;
            buffer_imag_next[0] = buf_imag_0;
            buffer_imag_next[1] = buf_imag_1;
            buffer_imag_next[2] = buf_imag_2;
            buffer_imag_next[3] = buf_imag_3;
            busy_d = 1'b1;
            count_d = 2'b0;
            

            serial_real = buf_real_0;
            serial_imag = buf_imag_0;
        end else if (busy_q) begin
            case (count_q)
                2'b00: begin
                    serial_real = buffer_real_q[0];
                    serial_imag = buffer_imag_q[0];
                end
                2'b01: begin
                    serial_real = buffer_real_q[1];
                    serial_imag = buffer_imag_q[1];
                end
                2'b10: begin
                    serial_real = buffer_real_q[2];
                    serial_imag = buffer_imag_q[2];
                end
                2'b11: begin
                    serial_real = buffer_real_q[3];
                    serial_imag = buffer_imag_q[3];
                end
            endcase
            
  
            count_d = count_q + 1;

            if (count_q == 2'b11) begin
                busy_d = 1'b0;
            end
        end
    end
    

    assign ready_o = !busy_q;

endmodule