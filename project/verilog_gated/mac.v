// Created by prof. Mingu Kang @VVIP Lab in UCSD ECE department
// Please do not spread this code without permission 
module mac (out, a, b, c);

parameter bw = 4;
parameter psum_bw = 16;
parameter channels_per_pe = 2;

output signed [psum_bw-1:0] out;
input signed  [channels_per_pe*bw-1:0] a;  // activation
input signed  [channels_per_pe*bw-1:0] b;  // weight
input signed  [psum_bw-1:0] c;

wire signed [psum_bw-1:0] psum;

wire [channels_per_pe-1:0]in_weight_zero;


wire signed [2*bw:0] product1[channels_per_pe-1:0];
wire signed [bw:0]   a_pad1[channels_per_pe-1:0];
wire signed [bw-1:0] b1[channels_per_pe-1:0];

wire signed [2*bw+1:0] product;

wire signed [bw:0] a_mul[channels_per_pe-1:0];
wire signed [bw-1:0] b_mul[channels_per_pe-1:0];

genvar i;
generate
for(i = 0; i < channels_per_pe; i = i+1) begin : mac_op 
    assign b1[i] = b[i*bw+:bw];
    assign a_pad1[i] = {1'b0, a[i*bw+:bw]}; // force to be unsigned number
    assign in_weight_zero[i] = (b1[i] != 0);
    
    toggle_filter #(.bw(bw)) filter0(
    	.a(a_pad1[i]),
    	.b(b1[i]),
    	.mask(in_weight_zero[i]),
    	.a_out(a_mul[i]),
    	.b_out(b_mul[i])
    	);

    assign product1[i] = a_mul[i] * b_mul[i];
    //assign product1[i] = a_pad1[i] * b1[i];
end
endgenerate

`ifdef TWO_IC_PER_PE
assign product = (product1[0] + product1[1]);
`else
assign product = product1[0];
`endif

/*wire signed [2*bw:0] product1;
wire signed [bw:0]   a_pad1;
wire signed [bw-1:0] b1;

wire signed [2*bw:0] product2;
wire signed [bw:0]   a_pad2;
wire signed [bw-1:0] b2;

wire signed [2*bw+1:0] product;

assign b1 = b[bw-1:0];
assign a_pad1 = {1'b0, a[bw-1:0]}; // force to be unsigned number
assign product1 = a_pad1 * b1;

//assign product2 = 0;
assign b2 = b[2*bw-1:bw];
assign a_pad2 = {1'b0, a[2*bw-1:bw]};
assign product2 = a_pad2 * b2;

assign product = product1 + product2;*/
assign psum = product + c;
assign out = psum;

endmodule

module toggle_filter (a, b, mask, a_out, b_out);

	parameter bw = 4;

	input signed [bw:0] a;
	input signed [bw-1:0] b;
//	input mask /*synthesis keep*/;
//	output signed [bw:0] a_out;
//	//output signed [bw-1:0] b_out /* synthesis dont_retime */;
//	output signed [bw-1:0] b_out /*synthesis keep*/;

	input mask ;
	output signed [bw:0] a_out;
	output signed [bw-1:0] b_out;
	
	assign a_out = a & {(bw+1){mask}};
	assign b_out = b & {bw{mask}};
	//genvar i;
	//generate
	//for(i=0;i<bw;i=i+1) begin : masking
	//	assign b_out[i] = b[i] & mask;
	//end
	//endgenerate

endmodule
