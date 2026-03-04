module elastic
  #(parameter [31:0] width_p = 8
   )
  (input [0:0] clk_i
  ,input [0:0] reset_i

  ,input valid_i
  ,output logic ready_o

  ,input [width_p-1: 0] data0_i
  ,input [width_p-1: 0] data1_i
  ,input [width_p-1: 0] data2_i
  ,input [width_p-1: 0] data3_i
  ,input [width_p-1: 0] data4_i
  ,input [width_p-1: 0] data5_i
  ,input [width_p-1: 0] data6_i
  ,input [width_p-1: 0] data7_i

  ,output valid_o
  ,input ready_i

  ,output [width_p-1: 0] data0_o
  ,output [width_p-1: 0] data1_o
  ,output [width_p-1: 0] data2_o
  ,output [width_p-1: 0] data3_o
  ,output [width_p-1: 0] data4_o
  ,output [width_p-1: 0] data5_o
  ,output [width_p-1: 0] data6_o
  ,output [width_p-1: 0] data7_o
  );

  logic [width_p-1:0] d0, d1, d2, d3, d4, d5, d6, d7;
  logic [width_p-1:0] q0, q1, q2, q3, q4, q5, q6, q7;
  wire en;
  assign en = valid_i & ready_o;
  logic valid_r;

  always_ff @(posedge clk_i) begin
    if (reset_i) begin
      q0 <= '0;
      q1 <= '0;
      q2 <= '0;
      q3 <= '0;
      q4 <= '0;
      q5 <= '0;
      q6 <= '0;
      q7 <= '0;
    end else begin
      q0 <= d0;
      q1 <= d1;
      q2 <= d2;
      q3 <= d3;
      q4 <= d4;
      q5 <= d5;
      q6 <= d6;
      q7 <= d7;
    end
  end

  always_comb begin
    d0 = q0; 
    d1 = q1; 
    d2 = q2; 
    d3 = q3; 
    d4 = q4; 
    d5 = q5; 
    d6 = q6; 
    d7 = q7; 
    if (en) begin
        d0 = data0_i; 
        d1 = data1_i; 
        d2 = data2_i; 
        d3 = data3_i; 
        d4 = data4_i; 
        d5 = data5_i; 
        d6 = data6_i; 
        d7 = data7_i; 
    end
  end

  always_ff @(posedge clk_i) begin
    if (reset_i) begin
      valid_r <= '0;
    end else if (ready_o) begin
      valid_r <= valid_i;
    end
  end

  assign ready_o = !valid_o | (valid_o & ready_i);
  assign valid_o = valid_r;

  assign data0_o = q0; 
  assign data1_o = q1; 
  assign data2_o = q2; 
  assign data3_o = q3; 
  assign data4_o = q4; 
  assign data5_o = q5; 
  assign data6_o = q6; 
  assign data7_o = q7; 


endmodule