module core #(
    parameter row = 8,
    parameter col = 8,
    parameter bw = 4,
    parameter psum_bw = 16,
    parameter inst_width = 35,
    parameter channels_per_pe = 1
)(
    input                   clk,
    input                   reset,
    input   [inst_width-1:0] inst,
    input   [channels_per_pe*bw*row-1:0]    D_xmem,
    output                  ofifo_valid,
    output  [psum_bw*col-1:0] sfp_out
);

// Activation/Kernel Memory
wire xmem_chip_en;
wire xmem_wr_en;
wire [32*channels_per_pe-1:0] xmem_data_in;
wire [10:0] xmem_addr_in;
wire [32*channels_per_pe-1:0] xmem_data_out;

assign xmem_chip_en = inst[`INST_CEN_XMEM];
assign xmem_wr_en   = inst[`INST_WEN_XMEM];
assign xmem_addr_in = inst[`INST_A_XMEM];
assign xmem_data_in = D_xmem;

sram_32b_w2048 #(.num(2048), .width(32*channels_per_pe)) xmem_inst(
    .CLK(clk),
    .D(xmem_data_in),
    .Q(xmem_data_out),
    .CEN(xmem_chip_en),
    .WEN(xmem_wr_en),
    .A(xmem_addr_in)
);

// PSUM Memory
wire pmem_chip_en;
wire pmem_wr_en;
wire [psum_bw*col-1:0] pmem_data_in;
wire [10:0] pmem_addr_in;
wire [psum_bw*col-1:0] pmem_data_out;

assign pmem_chip_en = inst[`INST_CEN_PMEM];
assign pmem_wr_en   = inst[`INST_WEN_PMEM];
assign pmem_addr_in = inst[`INST_A_PMEM];
assign pmem_data_in = inst[`INST_OFIFO_RD] ? corelet_inst.ofifo_data_out : corelet_sfp_out;

sram_32b_w2048 #(.num(2048), .width(128)) pmem_inst(
    .CLK(clk),
    .D(pmem_data_in),
    .Q(pmem_data_out),
    .CEN(pmem_chip_en),
    .WEN(pmem_wr_en),
    .A(pmem_addr_in)
);

// Corelet - contains L0, MAC Array, OFIFIO and SFP
wire [channels_per_pe*bw*row-1:0]       corelet_data_in_w;
wire [psum_bw*col-1:0]  corelet_data_in_n;
wire [psum_bw*col-1:0]  corelet_data_out;
wire [psum_bw*col-1:0]  corelet_sfp_out;

//@FIXME: Assign corelet inputs
assign corelet_data_in_w = xmem_data_out;
assign corelet_data_in_n = pmem_data_out;
assign sfp_out = corelet_sfp_out;

corelet #(.row(row), .col(col), .bw(bw), .psum_bw(psum_bw), .channels_per_pe(channels_per_pe)) corelet_inst(
    .clk(clk),
    .reset(reset),
    .inst(inst),
    .data_in_w(corelet_data_in_w),
    .data_in_n(corelet_data_in_n),
    .data_out(corelet_data_out),
    .sfp_out(corelet_sfp_out)
);

endmodule