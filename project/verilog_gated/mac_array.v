// Created by prof. Mingu Kang @VVIP Lab in UCSD ECE department
// Please do not spread this code without permission 
module mac_array (clk, reset, out_s, in_w, in_n, inst_w, valid, o_weight_zero_rows);

  parameter bw = 4;
  parameter psum_bw = 16;
  parameter col = 8;
  parameter row = 8;
  parameter channels_per_pe = 1;

  input  clk, reset;
  output [psum_bw*col-1:0] out_s;
  input  [row*channels_per_pe*bw-1:0] in_w; // inst[1]:execute, inst[0]: kernel loading
  input  [1:0] inst_w;
  input  [psum_bw*col-1:0] in_n;
  output [col-1:0] valid;

  reg [2*row-1:0] inst_w_temp;
  wire [psum_bw*col*(row+1)-1:0] temp;
  wire [row*col-1:0] valid_temp;

  assign out_s = temp[psum_bw*col*9-1:psum_bw*col*8];
  assign temp[psum_bw*col*1-1:psum_bw*col*0] = in_n;
  assign valid = valid_temp[row*col-1:(row-1)*col];

  output [row-1:0] o_weight_zero_rows;
  wire [row-1:0]gate_clk;

  genvar i;
  generate
  for (i=1; i < row+1 ; i=i+1) begin : row_num
	assign gate_clk[i-1] = (~o_weight_zero_rows[i-1] ) & clk;
      mac_row #(.bw(bw), .psum_bw(psum_bw), .channels_per_pe(channels_per_pe)) mac_row_instance (
      .gate_clk(gate_clk[i-1]),
      //.gate_clk(clk),
      .no_gate_clk(clk),
      .reset(reset),
      .in_w(in_w[channels_per_pe*bw*i-1:channels_per_pe*bw*(i-1)]),
      .inst_w(inst_w_temp[2*i-1:2*(i-1)]),
      .in_n(temp[psum_bw*col*i-1:psum_bw*col*(i-1)]),
      .valid(valid_temp[i*col-1:(i-1)*col]),
      .out_s(temp[psum_bw*col*(i+1)-1:psum_bw*col*i]),

      .all_weight_zero(o_weight_zero_rows[i-1])
      );
  end
  endgenerate

  always @ (posedge clk) begin
   // inst_w flows to row0 to row7
      inst_w_temp[1:0] <= inst_w;
      inst_w_temp[3:2] <= inst_w_temp[1:0];
      inst_w_temp[5:4] <= inst_w_temp[3:2];
      inst_w_temp[7:6] <= inst_w_temp[5:4];
      inst_w_temp[9:8] <= inst_w_temp[7:6];
      inst_w_temp[11:10] <= inst_w_temp[9:8];
      inst_w_temp[13:12] <= inst_w_temp[11:10];
      inst_w_temp[15:14] <= inst_w_temp[13:12];
  end



endmodule
