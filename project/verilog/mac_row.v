// Created by prof. Mingu Kang @VVIP Lab in UCSD ECE department
// Please do not spread this code without permission 
module mac_row (clk, out_s, in_w, in_n, valid, inst_w, reset);

  parameter bw = 4;
  parameter psum_bw = 16;
  parameter col = 8;
  parameter channels_per_pe = 1;

  input  clk, reset;
  output [psum_bw*col-1:0] out_s;
  output [col-1:0] valid;
  input  [channels_per_pe*bw-1:0] in_w; // inst[1]:execute, inst[0]: kernel loading
  input  [1:0] inst_w;
  input  [psum_bw*col-1:0] in_n;

  wire  [(col+1)*channels_per_pe*bw-1:0] temp;
  wire  [(col+1)*2-1:0] temp_inst;

  assign temp[channels_per_pe*bw-1:0]   = in_w;
  assign temp_inst[1:0]	= inst_w;

  genvar i;
  generate
  for (i=1; i < col+1 ; i=i+1) begin : col_num
      mac_tile #(.bw(bw), .psum_bw(psum_bw), .channels_per_pe(channels_per_pe)) mac_tile_instance (
         .clk(clk),
         .reset(reset),
	 .in_w( temp[channels_per_pe*bw*i-1:channels_per_pe*bw*(i-1)]),
	 .out_e(temp[channels_per_pe*bw*(i+1)-1:channels_per_pe*bw*i]),
	 .inst_w(temp_inst[2*i-1:2*(i-1)]),
	 .inst_e(temp_inst[2*(i+1)-1:2*i]),
	 .in_n(in_n[psum_bw*i-1:psum_bw*(i-1)]),
	 .out_s(out_s[psum_bw*i-1:psum_bw*(i-1)]));
      
      assign valid[i-1] = temp_inst[2*(i+1)-1];
  end
  endgenerate

endmodule
