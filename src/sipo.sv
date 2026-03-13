module sipo #(
    parameter width_p = 6
)(
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
            // Shift pipeline and load new data
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