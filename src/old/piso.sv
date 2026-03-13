module piso
    #(parameter width_p = 6
    )
    (input wire clk_i
    ,input wire reset_i
    ,input wire valid_i
    ,output logic ready_o
    ,input wire [width_p-1:0] buf_real_0
    ,input wire [width_p-1:0] buf_real_1
    ,input wire [width_p-1:0] buf_real_2
    ,input wire [width_p-1:0] buf_real_3
    ,input wire [width_p-1:0] buf_imag_0
    ,input wire [width_p-1:0] buf_imag_1
    ,input wire [width_p-1:0] buf_imag_2
    ,input wire [width_p-1:0] buf_imag_3
    ,output logic [width_p-1:0] serial_real
    ,output logic [width_p-1:0] serial_imag
);
    logic [1:0] rd_addr_d, rd_addr_q;
    logic active_d, active_q;
    logic ready_d;
    logic [width_p-1:0] serial_real_d, serial_imag_d;

    // Reassemble into local array for indexed access
    wire [width_p-1:0] buf_real [0:3];
    wire [width_p-1:0] buf_imag [0:3];
    
    assign buf_real[0] = buf_real_0; assign buf_real[1] = buf_real_1;
    assign buf_real[2] = buf_real_2; assign buf_real[3] = buf_real_3;
    assign buf_imag[0] = buf_imag_0; assign buf_imag[1] = buf_imag_1;
    assign buf_imag[2] = buf_imag_2; assign buf_imag[3] = buf_imag_3;

    always_ff @(posedge clk_i) begin
        if (reset_i) begin
            rd_addr_q   <= 2'b0;
            ready_o     <= 1'b0;
            active_q    <= 1'b0;
            serial_real <= '0;
            serial_imag <= '0;
        end else begin
            rd_addr_q   <= rd_addr_d;
            ready_o     <= ready_d;
            active_q    <= active_d;
            serial_real <= serial_real_d;
            serial_imag <= serial_imag_d;
        end
    end

    always_comb begin
        active_d      = active_q;
        ready_d       = 1'b0;
        rd_addr_d     = rd_addr_q;
        serial_real_d = serial_real;
        serial_imag_d = serial_imag;
        if (!active_q) begin
            if (valid_i) begin
                active_d      = 1'b1;
                ready_d       = 1'b1;
                rd_addr_d     = 2'b0;
                serial_real_d = buf_real[0];
                serial_imag_d = buf_imag[0];
            end
        end else begin
            if (rd_addr_q == 2'd3) begin
                active_d  = 1'b0;
                ready_d   = 1'b0;
                rd_addr_d = 2'b0;
            end else begin
                ready_d       = 1'b1;
                rd_addr_d     = rd_addr_q + 1'b1;
                serial_real_d = buf_real[rd_addr_q + 1'b1];
                serial_imag_d = buf_imag[rd_addr_q + 1'b1];
            end
        end
    end

endmodule