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

wire signed [2*bw:0] product1[channels_per_pe-1:0];
wire signed [bw:0]   a_pad1[channels_per_pe-1:0];
wire signed [bw-1:0] b1[channels_per_pe-1:0];

wire signed [2*bw+1:0] product;

genvar i;
for(i = 0; i < channels_per_pe; i = i+1) begin
    assign b1[i] = b[i*bw+:bw];
    assign a_pad1[i] = {1'b0, a[i*bw+:bw]}; // force to be unsigned number
    assign product1[i] = a_pad1[i] * b1[i];
end

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
