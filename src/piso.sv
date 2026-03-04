module piso
    #(parameter width_p = 6
    )
    (input wire clk_i
    ,input wire reset_i
    ,input logic signed [width_p-1:0] buf_real [0:3]
    ,input logic signed [width_p-1:0] buf_imag [0:3]
    ,input logic valid_i
    ,output logic active_o              // NEW: tells top/SIPO we are busy
    ,output logic [width_p-1:0] serial_real
    ,output logic [width_p-1:0] serial_imag
);
    logic [1:0] rd_addr_d, rd_addr_q;
    logic active_d, active_q;
    logic [width_p-1:0] serial_real_d, serial_imag_d;

    always_comb begin
        rd_addr_d     = rd_addr_q;
        active_d      = active_q;
        serial_real_d = '0;
        serial_imag_d = '0;

        if (valid_i && !active_q) begin
            active_d      = 1'b1;
            rd_addr_d     = 2'd1;       // buf[0] is pre-loaded, skip ahead
            serial_real_d = buf_real[0];
            serial_imag_d = buf_imag[0];
        end else if (active_q) begin
            serial_real_d = buf_real[rd_addr_q];
            serial_imag_d = buf_imag[rd_addr_q];
            if (rd_addr_q == 2'd3) begin
                active_d  = 1'b0;
                rd_addr_d = 2'b0;
            end else begin
                rd_addr_d = rd_addr_q + 1;
            end
        end
    end

    always_ff @(posedge clk_i) begin
        if (reset_i) begin
            rd_addr_q   <= 2'b0;
            active_q    <= 1'b0;
            serial_real <= '0;
            serial_imag <= '0;
        end else begin
            active_q    <= active_d;
            rd_addr_q   <= rd_addr_d;
            serial_real <= serial_real_d;
            serial_imag <= serial_imag_d;
        end
    end

    assign active_o = active_q;

endmodule