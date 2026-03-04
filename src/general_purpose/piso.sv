module piso
    #(parameter width_p = 6
    )
    (input wire clk_i
    ,input wire reset_i

    ,input valid_i
    ,output logic ready_o

    ,input logic [width_p -1:0] buf_real [0:3]
    ,input logic [width_p -1:0] buf_imag [0:3]

    ,output logic [width_p -1:0] serial_real
    ,output logic [width_p -1:0] serial_imag
);

    logic [1:0] rd_addr_d, rd_addr_q;
    wire valid_d;

    always_ff @(posedge clk_i) begin
        if (reset_i) begin
            rd_addr_q <= 2'b0;
            valid_o <= 1'b0;
        end else begin
            rd_addr_q <= rd_addr_d;
            valid_o <= valid_d;
        end
    end

    always_comb begin
        rd_addr_d = rd_addr_q;
        valid_d = valid_o;
        if (ready_i) begin
            if (rd_addr_q < 2'd3) begin
                rd_addr_d = rd_addr_q + 1;
                valid_d = 1'b1;
            end else if (rd_addr_q == 2'd3) begin
                valid_d = 1'b1;
                rd_addr_d = 2'b0;
            end else begin
                rd_addr_d = rd_addr_q;
                valid_d = valid_o;
            end
        end else begin
            valid_d = 1'b0;
        end
    end

    always_ff @(posedge clk_i) begin
        if (reset_i) begin
            ;
        end else begin
            serial_real <= buf_real[rd_addr_q];
            serial_imag <= buf_imag[rd_addr_q];
        end
    end


endmodule