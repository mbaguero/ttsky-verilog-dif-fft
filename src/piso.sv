module piso
    #(parameter width_p = 6
    )
    (input  wire                     clk_i
    ,input  wire                     reset_i
    ,input  wire                     valid_i
    ,output wire                     ready_o
    ,input  wire [width_p-1:0]       buf_real_0
    ,input  wire [width_p-1:0]       buf_real_1
    ,input  wire [width_p-1:0]       buf_real_2
    ,input  wire [width_p-1:0]       buf_real_3
    ,input  wire [width_p-1:0]       buf_imag_0
    ,input  wire [width_p-1:0]       buf_imag_1
    ,input  wire [width_p-1:0]       buf_imag_2
    ,input  wire [width_p-1:0]       buf_imag_3
    ,output reg  [width_p-1:0]       serial_real
    ,output reg  [width_p-1:0]       serial_imag
    );


    reg [1:0] count_q, count_d;
    reg [width_p-1:0] buffer_real_q[0:3];
    reg [width_p-1:0] buffer_imag_q[0:3];
    reg [width_p-1:0] buffer_real_d[0:3];
    reg [width_p-1:0] buffer_imag_d[0:3];
    reg busy_q, busy_d;
    

    integer i;
    
    always @(posedge clk_i) begin
        if (reset_i) begin
            count_q <= 2'b0;
            busy_q <= 1'b0;
            for (i = 0; i < 4; i = i + 1) begin
                buffer_real_q[i] <= {width_p{1'b0}};
                buffer_imag_q[i] <= {width_p{1'b0}};
            end
        end else begin
            count_q <= count_d;
            busy_q <= busy_d;
            for (i = 0; i < 4; i = i + 1) begin
                buffer_real_q[i] <= buffer_real_d[i];
                buffer_imag_q[i] <= buffer_imag_d[i];
            end
        end
    end
    

    always_comb begin
        count_d = count_q;
        busy_d = busy_q;
        for (i = 0; i < 4; i = i + 1) begin
            buffer_real_d[i] = buffer_real_q[i];
            buffer_imag_d[i] = buffer_imag_q[i];
        end
        
        serial_real = {width_p{1'b0}};
        serial_imag = {width_p{1'b0}};
        
        if (valid_i && !busy_q) begin
            buffer_real_d[0] = buf_real_0;
            buffer_real_d[1] = buf_real_1;
            buffer_real_d[2] = buf_real_2;
            buffer_real_d[3] = buf_real_3;
            buffer_imag_d[0] = buf_imag_0;
            buffer_imag_d[1] = buf_imag_1;
            buffer_imag_d[2] = buf_imag_2;
            buffer_imag_d[3] = buf_imag_3;
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