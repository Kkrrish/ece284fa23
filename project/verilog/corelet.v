`define INST_SFP_RELU   34
`define INST_SFP_ACC    33
`define INST_CEN_PMEM   32
`define INST_WEN_PMEM   31
`define INST_A_PMEM     30:20
`define INST_CEN_XMEM   19
`define INST_WEN_XMEM   18
`define INST_A_XMEM     17:7
`define INST_OFIFO_RD   6
`define INST_L0_RD      3
`define INST_L0_WR      2

module corelet #(
    parameter row = 8,
    parameter col = 8,
    parameter bw = 4,
    parameter psum_bw = 16,
    parameter inst_width = 35
)(
    input                   clk,
    input                   reset,
    input   [inst_width-1:0] inst,
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

assign l0_rd = inst[`INST_L0_RD];
assign l0_wr = inst[`INST_L0_WR];
assign l0_data_in = data_in_w;

l0 #(.row(row), .bw(bw)) l0_inst(
    .clk(clk),
    .wr(l0_wr),
    .rd(l0_rd),
    .reset(1'b0), //@FIXME: Is it okay to never reset L0?
    .in(l0_data_in),
    .out(l0_data_out),
    .o_full(l0_full),
    .o_ready(l0_ready)
);

// MAC Array
wire [bw*row-1:0]       mac_data_in_w;
wire [psum_bw*col-1:0]  mac_data_in_n;
wire [1:0]              mac_inst_w;
wire [psum_bw*col-1:0]  mac_out_s;
wire [col-1:0]          mac_valid;

assign mac_inst_w       = inst[1:0];
assign mac_data_in_w    = l0_data_out;
assign mac_data_in_n    = 0; //@FIXME

mac_array #(.bw(bw), .psum_bw(psum_bw), .col(col), .row(row)) mac_array_inst(
    .clk(clk),
    .reset(reset),
    .in_w(mac_data_in_w),
    .in_n(mac_data_in_n),
    .inst_w(mac_inst_w),
    .out_s(mac_out_s),
    .valid(mac_valid)
);

wire                    ofifo_rd;
wire [col-1:0]          ofifo_wr;
wire [psum_bw*col-1:0]  ofifo_data_in;
wire [psum_bw*col-1:0]  ofifo_data_out;
wire                    ofifo_full;
wire                    ofifo_ready;
wire                    ofifo_valid;

assign ofifo_data_in = mac_out_s;
assign ofifo_wr = mac_valid;
assign ofifo_rd = inst[`INST_OFIFO_RD];
assign data_out = ofifo_data_out;

// OFIFO
ofifo #(.col(col), .bw(psum_bw)) ofifo_inst(
    .clk(clk),
    .reset(1'b0), //@FIXME: Is it okay to never reset OFIFO?
    .rd(ofifo_rd),
    .wr(ofifo_wr),
    .in(ofifo_data_in),
    .out(ofifo_data_out),
    .o_full(ofifo_full),
    .o_ready(ofifo_ready),
    .o_valid(ofifo_valid)
);

// SFP
wire [psum_bw*col-1:0]  sfp_in;
wire [psum_bw-1:0]      sfp_thres;
wire                    sfp_acc;
wire                    sfp_relu;

assign sfp_in = data_in_n;
assign sfp_thres = 1'b0;
assign sfp_acc = inst[`INST_SFP_ACC];
assign sfp_relu = inst[`INST_SFP_RELU];

genvar i;
for(i=1; i<col+1; i=i+1) begin : sfp_num
    sfp #(.bw(psum_bw), .psum_bw(psum_bw)) sfp_inst(
        .clk(clk),
        .reset(reset),
        .acc(sfp_acc),
        .relu(sfp_relu),
        .thres(sfp_thres),
        .in(sfp_in[psum_bw*i-1:psum_bw*(i-1)]),
        .out(sfp_out[psum_bw*i-1:psum_bw*(i-1)])
    );
end

endmodule