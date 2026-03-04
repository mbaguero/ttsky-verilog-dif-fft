module sipo 
    #(parameter width_p = 6
    )
    (input wire clk_i
    ,input wire reset_i
    ,input wire [width_p -1:0] serial_real
    ,input wire [width_p -1:0] serial_imag

    ,input  ready_i
    ,output valid_o

    ,output logic [width_p -1:0] buf_real [0:2]
    ,output logic [width_p -1:0] buf_imag [0:2]
);

    logic [1:0] wr_addr_d, wr_addr_q;
    wire valid_d;

    always_ff @(posedge clk_i) begin
        if (reset_i) begin
            wr_addr_q <= 2'b0;
            valid_o <= 1'b0;
        end else begin
            wr_addr_q <= wr_addr_d;
            valid_o <= valid_d;
        end
    end

    always_comb begin
        wr_addr_d = wr_addr_q;
        valid_d = valid_o;
        if (ready_i) begin
            if (wr_addr_q < 2'd3) begin
                wr_addr_d = wr_addr_q + 1;
            end else if (wr_addr_q == 2'd3) begin
                valid_d = 1'b1;
                wr_addr_d = 2'b0;
            end else begin
                wr_addr_d = wr_addr_q;
                valid_d = valid_o;
            end
        end
    end

    always_ff @(posedge clk_i) begin
        if (reset_i) begin
            ;
        end else if begin
            buf_real[wr_addr_q] <= serial_real;
            buf_imag[wr_addr_q] <= serial_imag;
        end
    end

endmodule