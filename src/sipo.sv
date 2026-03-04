module sipo 
    #(parameter width_p = 6
    )
    (input wire clk_i
    ,input wire reset_i
    ,input wire en_i
    ,input wire [width_p-1:0] serial_real
    ,input wire [width_p-1:0] serial_imag
    ,output logic valid_o
    ,output logic [width_p-1:0] buf_real [0:3]
    ,output logic [width_p-1:0] buf_imag [0:3]
);
    logic [1:0] wr_addr_q;
    logic valid_q, valid_q1;

    // Counter only advances on en_i
    always_ff @(posedge clk_i) begin
        if (reset_i) begin
            wr_addr_q <= 2'd0;
            valid_q   <= 1'b0;
        end else if (en_i) begin
            if (wr_addr_q == 2'd3) begin
                wr_addr_q <= 2'd0;
                valid_q   <= 1'b1;
            end else begin
                wr_addr_q <= wr_addr_q + 1;
                valid_q   <= 1'b0;
            end
        end else begin
            valid_q <= 1'b0;
        end
    end

    // Buffer write
    always_ff @(posedge clk_i) begin
        if (reset_i) begin
            buf_real[0] <= '0; buf_real[1] <= '0;
            buf_real[2] <= '0; buf_real[3] <= '0;
            buf_imag[0] <= '0; buf_imag[1] <= '0;
            buf_imag[2] <= '0; buf_imag[3] <= '0;
        end else if (en_i) begin
            buf_real[wr_addr_q] <= serial_real;
            buf_imag[wr_addr_q] <= serial_imag;
        end
    end

    // One-cycle delay: valid fires after buf[3] is committed
    always_ff @(posedge clk_i) begin
        if (reset_i) valid_q1 <= 1'b0;
        else         valid_q1 <= valid_q;
    end

    assign valid_o = valid_q1;

endmodule