`define INST_CEN_XMEM 19
`define INST_WEN_XMEM 18
`define INST_A_XMEM 17:7

module core #(
    parameter row = 8,
    parameter col = 8,
    parameter bw = 4,
    parameter psum_bw = 16
)(
    input                   clk,
    input                   reset,
    input   [33:0]          inst,
    input   [bw*row-1:0]    D_xmem,
    output                  ofifo_valid,
    output  [psum_bw*col-1:0] sfp_out
);

wire xmem_chip_en;
wire xmem_wr_en;
wire [31:0] xmem_data_in;
wire [10:0] xmem_addr_in;
wire [31:0] xmem_data_out;

assign xmem_chip_en = inst[`INST_CEN_XMEM];
assign xmem_wr_en   = inst[`INST_WEN_XMEM];
assign xmem_addr_in = inst[`INST_A_XMEM];
assign xmem_data_in = D_xmem;

sram_32b_w2048 #(.num(2048)) xmem_inst(
    .CLK(clk),
    .D(xmem_data_in),
    .Q(xmem_data_out),
    .CEN(xmem_chip_en),
    .WEN(xmem_wr_en),
    .A(xmem_addr_in)
);

endmodule