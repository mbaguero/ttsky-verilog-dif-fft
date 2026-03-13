module sipo
    #(parameter width_p = 6
    )
    (input wire clk_i
    ,input wire reset_i
    ,input wire valid_i 
    ,input wire [width_p-1:0] serial_real
    ,input wire [width_p-1:0] serial_imag
    ,input wire ready_i
    ,output logic valid_o
    ,output logic [width_p-1:0] buf_real_0
    ,output logic [width_p-1:0] buf_real_1
    ,output logic [width_p-1:0] buf_real_2
    ,output logic [width_p-1:0] buf_real_3
    ,output logic [width_p-1:0] buf_imag_0
    ,output logic [width_p-1:0] buf_imag_1
    ,output logic [width_p-1:0] buf_imag_2
    ,output logic [width_p-1:0] buf_imag_3
);
    logic [1:0] wr_addr_d, wr_addr_q, wr_addr_q2;
    logic valid_d;
    logic [width_p-1:0] buf_real [0:3];
    logic [width_p-1:0] buf_imag [0:3];
    logic probe;

    always_ff @(posedge clk_i) begin
        if (reset_i) begin
            wr_addr_q <= 2'b0;
            wr_addr_q2 <= 2'b0;
            valid_o   <= 1'b0;
            //valid_q <= 1'b0;
        end else begin
            valid_o   <= valid_d;
            //valid_o <= valid_q;
            wr_addr_q <= wr_addr_d;
            wr_addr_q2 <= wr_addr_q;
        end
    end



    always_comb begin
        wr_addr_d = wr_addr_q;
        valid_d   = valid_o;
        if (valid_o && ready_i) begin
            // downstream consumed frame — clear valid, reset address
            valid_d   = 1'b0;
            wr_addr_d = 2'b0;
        end else if (!valid_o && valid_i) begin
            // only advance when a real sample is presented
            if (wr_addr_q == 2'd3) begin
                valid_d   = 1'b1;
                wr_addr_d = 2'b0;
                probe = 1'b0;
            end else begin
                wr_addr_d = wr_addr_q + 1'b1;
                valid_d   = 1'b0;
            end
        end
        // else: hold state
    end

    always_ff @(posedge clk_i) begin
        if (reset_i) begin
            buf_real[0] <= '0; buf_real[1] <= '0;
            buf_real[2] <= '0; buf_real[3] <= '0;
            buf_imag[0] <= '0; buf_imag[1] <= '0;
            buf_imag[2] <= '0; buf_imag[3] <= '0;
        end else if (!valid_o && valid_i) begin
            buf_real[wr_addr_q2] <= serial_real;
            buf_imag[wr_addr_q2] <= serial_imag;
        end
    end

    assign buf_real_0 = buf_real[0]; assign buf_real_1 = buf_real[1];
    assign buf_real_2 = buf_real[2]; assign buf_real_3 = buf_real[3];
    assign buf_imag_0 = buf_imag[0]; assign buf_imag_1 = buf_imag[1];
    assign buf_imag_2 = buf_imag[2]; assign buf_imag_3 = buf_imag[3];

endmodule