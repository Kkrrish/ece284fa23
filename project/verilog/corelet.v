`define INST_CEN_XMEM   19
`define INST_WEN_XMEM   18
`define INST_A_XMEM     17:7
`define INST_L0_RD      3
`define INST_L0_WR      2

module corelet #(
    parameter row = 8,
    parameter col = 8,
    parameter bw = 4,
    parameter psum_bw = 16
)(
    input                   clk,
    input                   reset,
    input   [33:0]          inst,
    input   [bw*row-1:0]    data_in_w,
    input   [psum_bw*col-1:0]   data_in_n,
    output  [psum_bw*col-1:0]   data_out,
    output  [psum_bw*col-1:0]   sfp_out
);

// L0
wire                    l0_wr;
wire                    l0_rd;
wire    [row*bw-1:0]    l0_data_in;
wire    [row*bw-1:0]    l0_data_out;
wire                    l0_full;
wire                    l0_ready;

//@FIXME: Assign inputs
assign l0_rd = inst[`INST_L0_RD];
assign l0_wr = inst[`INST_L0_WR];
assign l0_data_in = data_in_w;

l0 #(.row(row), .bw(bw)) l0_inst(
    .clk(clk),
    .wr(l0_wr),
    .rd(l0_rd),
    .reset(reset),
    .in(l0_data_in),
    .out(l0_data_out),
    .o_full(l0_full),
    .o_ready(l0_ready)
);

// MAC Array

// OFIFIO

// SFP

endmodule