// Created by prof. Mingu Kang @VVIP Lab in UCSD ECE department
// Please do not spread this code without permission 
module mac_tile (gate_clk, no_gate_clk,  out_s, in_w, out_e, in_n, inst_w, inst_e, reset, o_weight_assigned, o_weight_zero);

parameter bw = 4;
parameter psum_bw = 16;
parameter channels_per_pe = 1;

output [psum_bw-1:0] out_s;
input  [channels_per_pe*bw-1:0] in_w; // inst[1]:execute, inst[0]: kernel loading
output [channels_per_pe*bw-1:0] out_e; 
input  [1:0] inst_w;
output [1:0] inst_e;
input  [psum_bw-1:0] in_n;
//input  clk;
input gate_clk;
input no_gate_clk;
input  reset;

output reg o_weight_assigned;
output reg o_weight_zero;
reg weight_assigned;

reg [1:0] inst_q;
reg [channels_per_pe*bw-1:0] a_q, b_q;
reg [psum_bw-1:0] c_q;
reg load_ready_q;
wire [psum_bw-1:0] mac_out;

mac #(.bw(bw), .psum_bw(psum_bw), .channels_per_pe(channels_per_pe)) mac_instance (
        .a(a_q), 
        .b(b_q),
        .c(c_q),
	.out(mac_out)
); 

assign out_s	= mac_out;
assign out_e	= a_q;
assign inst_e	= inst_q;

//always @ (posedge clk) begin
//	if(reset) begin
//		inst_q <= 0;
//		load_ready_q <= 1;
//		a_q <= 0;
//		b_q <= 0;
//		c_q <= 0;
//	end else begin
//		inst_q[1] <= inst_w[1];
//		c_q <= in_n;
//		if(inst_w[0] || inst_w[1]) begin
//			a_q <= in_w;
//		end
//		if(inst_w[0] && load_ready_q) begin
//			b_q <= in_w;
//			load_ready_q <= 0;
//		end
//		if(!load_ready_q) begin
//			inst_q[0] <= inst_w[0];
//		end
//	end
//end

always @ (posedge gate_clk) begin
	//if(reset) begin
	//	inst_q <= 0;
	//	load_ready_q <= 1;
	//	a_q <= 0;
	//	b_q <= 0;
	//	//c_q <= 0;
	//	o_weight_zero <= 0;
	//	o_weight_assigned <= 1'b0;
	if(reset) begin
		inst_q <= 0;
		load_ready_q <= 1;
		a_q <= 0;
		b_q <= 0;
		//c_q <= 0;
		o_weight_zero <= 0;
		weight_assigned <= 1'b0;
		o_weight_assigned <= 1'b0;
	end
	else begin
	//if(~reset) begin
		inst_q[1] <= inst_w[1];
		//c_q <= in_n;
		if(inst_w[0] || inst_w[1]) begin
			a_q <= in_w;
		end
		if(inst_w[0] && load_ready_q) begin
			b_q <= in_w;
			if(in_w == 0) begin
				o_weight_zero <= 1'b1;
			end
			else begin
				o_weight_zero <= 1'b0;
			end
			weight_assigned <= 1'b1;
			o_weight_assigned <= weight_assigned;
			load_ready_q <= 0;
		end
		if(!load_ready_q) begin
			inst_q[0] <= inst_w[0];
		end
	end
end

//always @(posedge no_gate_clk) begin
//	if(reset) begin
//		inst_q <= 0;
//		load_ready_q <= 1;
//		a_q <= 0;
//		b_q <= 0;
//		//c_q <= 0;
//		o_weight_zero <= 0;
//		weight_assigned <= 1'b0;
//		o_weight_assigned <= 1'b0;
//	end
//end

//always @(posedge no_gate_clk) begin
always @(posedge no_gate_clk) begin
	if(reset) begin
		c_q <= 0;
	end
	else begin
		if(~reset) begin
			c_q <= in_n;
		end
	end
end

endmodule
