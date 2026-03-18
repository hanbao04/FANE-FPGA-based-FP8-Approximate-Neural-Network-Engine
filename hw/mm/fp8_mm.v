module fane_mm #(
	parameter A_W = 14,
	parameter M_W = 18,
	parameter D_W = 48,
        parameter NUMBER_OF_REG = 1,
        parameter CASCADE_ORDER_A = "NONE",
        parameter SELF_ADDR_A = 11'h0,
	parameter URAM_D_W = 72,
	parameter URAM_A_W = 23
)
(
input clk,
input rst,
input ce,
input [2:0] ce_tmp,
input [7:0] bram_data1,
input [7:0] bram_data2,
input [7:0] bram_data3,
input [7:0] bram_data4,
input [7:0] bram_data5,
input [7:0] bram_data6,
input [7:0] bram_data7,
input [7:0] bram_data8,
input [7:0] bram_data9,
input [URAM_A_W-1:0] uram_rd_addr,
input [URAM_A_W-1:0] uram_wr_addr,
input [URAM_D_W-1:0] uram_wr_data,
input uram_wr_en,
input [A_W-1:0] bram_rd_addr_external,
input bram_rd_en_external,
output [M_W-1:0] bram_rd_data,

output	[22:0]	CAS_OUT_ADDR,
output	[8:0]	CAS_OUT_BWE,
output	[0:0]	CAS_OUT_DBITERR,
output	[71:0]	CAS_OUT_DIN,
output	[71:0]	CAS_OUT_DOUT,
output	[0:0]	CAS_OUT_EN,
output	[0:0]	CAS_OUT_RDACCESS,
output	[0:0]	CAS_OUT_RDB_WR,
output	[0:0]	CAS_OUT_SBITERR,
input   [22:0]	CAS_IN_ADDR,
input   [8:0]	CAS_IN_BWE,
input   [0:0]	CAS_IN_DBITERR,
input   [71:0]	CAS_IN_DIN,
input   [71:0]	CAS_IN_DOUT,
input   [0:0]	CAS_IN_EN,
input   [0:0]	CAS_IN_RDACCESS,
input   [0:0]	CAS_IN_RDB_WR,
input   [0:0]	CAS_IN_SBITERR
);

reg [7:0]                bram_data1r;
reg [7:0]                bram_data2r;
reg [7:0]                bram_data3r;
reg [7:0]                bram_data4r;
reg [7:0]                bram_data5r;
reg [7:0]                bram_data6r;
reg [7:0]                bram_data7r;
reg [7:0]                bram_data8r;
reg [7:0]                bram_data9r;
reg [A_W-1:0]            bram_rd_addr_internal;
reg [A_W-1:0]            bram_rd_addr;
reg [M_W-1:0]            bram_rd_data_r;
reg [A_W-1:0]            bram_wr_addr;
reg [M_W-1:0]            bram_wr_data;
reg [71:0]               uram_rd_data_r;
reg [71:0]               uram_rd_data_r1;
reg [71:0]               uram_rd_data_r2;
reg                      bram_wr_en;
reg [A_W-1:0]            bram_wr_addr_counter;

wire [7:0]               Ain [0:8];
wire [7:0]               Bin [0:8];
wire [7:0]               mac_sum [0:8];
wire [7:0]               cascade_a_unused [0:8];
wire [7:0]               cascade_b_unused [0:8];
wire                     mac_valid [0:8];
wire [URAM_D_W-1:0]      uram_rd_data;
wire [M_W-1:0]           bram_rd_data_tmp;
wire                     start_valid;

always@(posedge clk) begin
  bram_data1r <= bram_data1;
  bram_data2r <= bram_data2;
  bram_data3r <= bram_data3;
  bram_data4r <= bram_data4;
  bram_data5r <= bram_data5;
  bram_data6r <= bram_data6;
  bram_data7r <= bram_data7;
  bram_data8r <= bram_data8;
  bram_data9r <= bram_data9;
end

generate if (NUMBER_OF_REG == 1) begin : urd_1
  always@(posedge clk) begin
    uram_rd_data_r <= uram_rd_data;
  end
end endgenerate

generate if (NUMBER_OF_REG == 2) begin : urd_2
  always@(posedge clk) begin
    uram_rd_data_r1 <= uram_rd_data;
    uram_rd_data_r <= uram_rd_data_r1;
  end
end endgenerate

generate if (NUMBER_OF_REG == 3) begin : urd_3
  always@(posedge clk) begin
    uram_rd_data_r1 <= uram_rd_data;
    uram_rd_data_r2 <= uram_rd_data_r1;
    uram_rd_data_r  <= uram_rd_data_r2;
  end
end endgenerate

always@(posedge clk) begin
  if (rst) begin
    bram_rd_addr_internal <= {A_W{1'b0}};
  end else if (mac_valid[8]) begin
    bram_rd_addr_internal <= bram_rd_addr_internal + 14'd16;
  end
end

always@(posedge clk) begin
  if (rst) bram_rd_addr <= {A_W{1'b0}};
  else begin
    if (bram_rd_en_external)  bram_rd_addr <= bram_rd_addr_external;
    else bram_rd_addr <= bram_rd_addr_internal;
  end
end

always@(posedge clk) begin
  bram_rd_data_r <= bram_rd_data_tmp;
end

always@(posedge clk) begin
  if (rst) begin
    bram_wr_en <= 1'b0;
    bram_wr_addr <= {A_W{1'b0}};
    bram_wr_addr_counter <= {A_W{1'b0}};
    bram_wr_data <= {M_W{1'b0}};
  end else begin
    bram_wr_en <= mac_valid[8];
    if (mac_valid[8]) begin
      bram_wr_addr <= bram_wr_addr_counter;
      bram_wr_addr_counter <= bram_wr_addr_counter + 14'd16;
      bram_wr_data <= {{(M_W-8){1'b0}}, mac_sum[8]};
    end
  end
end

assign bram_rd_data = bram_rd_data_r;
assign start_valid = ce_tmp[0];

assign Ain[0] = uram_rd_data_r[7:0];
assign Ain[1] = uram_rd_data_r[15:8];
assign Ain[2] = uram_rd_data_r[23:16];
assign Ain[3] = uram_rd_data_r[31:24];
assign Ain[4] = uram_rd_data_r[39:32];
assign Ain[5] = uram_rd_data_r[47:40];
assign Ain[6] = uram_rd_data_r[55:48];
assign Ain[7] = uram_rd_data_r[63:56];
assign Ain[8] = uram_rd_data_r[71:64];

assign Bin[0] = bram_data1r;
assign Bin[1] = bram_data2r;
assign Bin[2] = bram_data3r;
assign Bin[3] = bram_data4r;
assign Bin[4] = bram_data5r;
assign Bin[5] = bram_data6r;
assign Bin[6] = bram_data7r;
assign Bin[7] = bram_data8r;
assign Bin[8] = bram_data9r;

(* dont_touch = "true" *)	URAM288 #(.IREG_PRE_A("TRUE"),.IREG_PRE_B("TRUE"),.OREG_A("TRUE"),.OREG_B("TRUE"),
			.CASCADE_ORDER_A(CASCADE_ORDER_A), .CASCADE_ORDER_B("NONE"), .REG_CAS_A("TRUE"), .SELF_MASK_A(11'h7fc), .SELF_MASK_B(11'h7ff), .SELF_ADDR_A(SELF_ADDR_A))
		uram_inst_rd(
			.RDB_WR_B(1'b0),
			.BWE_B({9{1'b1}}),
			.ADDR_B(uram_rd_addr),
			.DOUT_B(uram_rd_data),
			.RDB_WR_A(uram_wr_en),
			.BWE_A({9{1'b1}}),
			.ADDR_A(uram_wr_addr),
			.DIN_A(uram_wr_data),
			.DOUT_A(),
	                .CAS_OUT_ADDR_A	   (CAS_OUT_ADDR),
                        .CAS_OUT_BWE_A	   (CAS_OUT_BWE),
                        .CAS_OUT_DBITERR_A (CAS_OUT_DBITERR),
                        .CAS_OUT_DIN_A	   (CAS_OUT_DIN),
                        .CAS_OUT_DOUT_A	   (CAS_OUT_DOUT),
                        .CAS_OUT_EN_A	   (CAS_OUT_EN),
                        .CAS_OUT_RDACCESS_A(CAS_OUT_RDACCESS),
                        .CAS_OUT_RDB_WR_A  (CAS_OUT_RDB_WR),
                        .CAS_OUT_SBITERR_A (CAS_OUT_SBITERR),
                        .CAS_IN_ADDR_A	   (CAS_IN_ADDR),
                        .CAS_IN_BWE_A	   (CAS_IN_BWE),
                        .CAS_IN_DBITERR_A  (CAS_IN_DBITERR),
                        .CAS_IN_DIN_A	   (CAS_IN_DIN),
                        .CAS_IN_DOUT_A	   (CAS_IN_DOUT),
                        .CAS_IN_EN_A	   (CAS_IN_EN),
                        .CAS_IN_RDACCESS_A (CAS_IN_RDACCESS),
                        .CAS_IN_RDB_WR_A   (CAS_IN_RDB_WR),
	                .CAS_IN_SBITERR_A  (CAS_IN_SBITERR),
			.CLK(clk),
			.EN_A(ce),
			.EN_B(ce),
			.OREG_CE_B(1'b1),
			.OREG_ECC_CE_B(1'b0),
			.RST_A(rst),
			.RST_B(rst),
			.SLEEP(1'b0)
		);

		RAMB18E2 #(
			.DOA_REG(1),.DOB_REG(1),
			.CASCADE_ORDER_A("NONE"),.CASCADE_ORDER_B("NONE"),
			.CLOCK_DOMAINS("COMMON"),
			.WRITE_WIDTH_A(18), .WRITE_WIDTH_B(18),
			.READ_WIDTH_A(18), .READ_WIDTH_B(18))
        	bram_inst_wr (
	                .ADDRARDADDR(bram_rd_addr),
        	        .ADDRBWRADDR(bram_wr_addr),
	                .ADDRENA(1'b1),
	                .ADDRENB(1'b1),
	                .WEA({2{1'b0}}),
	                .WEBWE({4{bram_wr_en}}),
	                .DOUTADOUT(bram_rd_data_tmp[15:0]),
	                .DOUTPADOUTP(bram_rd_data_tmp[17:16]),
	                .DINBDIN(bram_wr_data[15:0]),
	                .DINPBDINP(bram_wr_data[17:16]),
	                .CLKARDCLK(clk),
	                .CLKBWRCLK(clk),
	                .ENARDEN(ce),
	                .ENBWREN(ce),
	                .REGCEAREGCE(ce),
	                .REGCEB(ce),
	                .RSTRAMARSTRAM(rst),
	                .RSTRAMB(rst),
	                .RSTREGARSTREG(rst),
	                .RSTREGB(rst)
	        );

(* dont_touch = "true" *) fane_mac #(.INPUT_DELAY(0)) mac1 (
    .clk(clk), .rst_n(~rst), 
    .valid_in(start_valid), 
    .mul_a(Ain[0]), 
    .mul_b(Bin[0]), 
    .cascade_sum_in(8'd0),
    .acc_out(mac_sum[0]), 
    .cascade_mula_out(cascade_a_unused[0]), 
    .cascade_mulb_out(cascade_b_unused[0]), 
    .valid_out(mac_valid[0])
);

(* dont_touch = "true" *) fane_mac #(.INPUT_DELAY(4)) mac2 (
    .clk(clk), .rst_n(~rst), 
    .valid_in(mac_valid[0]), 
    .mul_a(Ain[1]), 
    .mul_b(Bin[1]), 
    .cascade_sum_in(mac_sum[0]),
    .acc_out(mac_sum[1]),
     .cascade_mula_out(cascade_a_unused[1]), 
     .cascade_mulb_out(cascade_b_unused[1]), 
     .valid_out(mac_valid[1])
);

(* dont_touch = "true" *) fane_mac #(.INPUT_DELAY(9)) mac3 (
    .clk(clk), .rst_n(~rst), 
    .valid_in(mac_valid[1]), 
    .mul_a(Ain[2]), 
    .mul_b(Bin[2]), 
    .cascade_sum_in(mac_sum[1]),
    .acc_out(mac_sum[2]), 
    .cascade_mula_out(cascade_a_unused[2]), 
    .cascade_mulb_out(cascade_b_unused[2]), 
    .valid_out(mac_valid[2])
);

(* dont_touch = "true" *) fane_mac #(.INPUT_DELAY(14)) mac4 (
    .clk(clk), .rst_n(~rst), 
    .valid_in(mac_valid[2]), 
    .mul_a(Ain[3]),
     .mul_b(Bin[3]),
      .cascade_sum_in(mac_sum[2]),
    .acc_out(mac_sum[3]), 
    .cascade_mula_out(cascade_a_unused[3]), 
    .cascade_mulb_out(cascade_b_unused[3]), 
    .valid_out(mac_valid[3])
);

(* dont_touch = "true" *) fane_mac #(.INPUT_DELAY(19)) mac5 (
    .clk(clk), .rst_n(~rst), 
    .valid_in(mac_valid[3]), 
    .mul_a(Ain[4]), 
    .mul_b(Bin[4]), 
    .cascade_sum_in(mac_sum[3]),
    .acc_out(mac_sum[4]), 
    .cascade_mula_out(cascade_a_unused[4]), 
    .cascade_mulb_out(cascade_b_unused[4]), 
    .valid_out(mac_valid[4])
);

(* dont_touch = "true" *) fane_mac #(.INPUT_DELAY(24)) mac6 (
    .clk(clk), 
    .rst_n(~rst), 
    .valid_in(mac_valid[4]), 
    .mul_a(Ain[5]), 
    .mul_b(Bin[5]), 
    .cascade_sum_in(mac_sum[4]),
    .acc_out(mac_sum[5]), 
    .cascade_mula_out(cascade_a_unused[5]), 
    .cascade_mulb_out(cascade_b_unused[5]), 
    .valid_out(mac_valid[5])
);

(* dont_touch = "true" *) fane_mac #(.INPUT_DELAY(29)) mac7 (
    .clk(clk), .rst_n(~rst), 
    .valid_in(mac_valid[5]),
     .mul_a(Ain[6]), 
     .mul_b(Bin[6]), 
     .cascade_sum_in(mac_sum[5]),
    .acc_out(mac_sum[6]), 
    .cascade_mula_out(cascade_a_unused[6]), 
    .cascade_mulb_out(cascade_b_unused[6]), 
    .valid_out(mac_valid[6])
);

(* dont_touch = "true" *) fane_mac #(.INPUT_DELAY(34)) mac8 (
    .clk(clk), 
    .rst_n(~rst), 
    .valid_in(mac_valid[6]), 
    .mul_a(Ain[7]), 
    .mul_b(Bin[7]), 
    .cascade_sum_in(mac_sum[6]),
    .acc_out(mac_sum[7]), 
    .cascade_mula_out(cascade_a_unused[7]), 
    .cascade_mulb_out(cascade_b_unused[7]), 
    .valid_out(mac_valid[7])
);

(* dont_touch = "true" *) fane_mac #(.INPUT_DELAY(39)) mac9 (
    .clk(clk), .rst_n(~rst), 
    .valid_in(mac_valid[7]), 
    .mul_a(Ain[8]),
     .mul_b(Bin[8]), 
     .cascade_sum_in(mac_sum[7]),
    .acc_out(mac_sum[8]), 
    .cascade_mula_out(cascade_a_unused[8]), 
    .cascade_mulb_out(cascade_b_unused[8]), 
    .valid_out(mac_valid[8])
);

endmodule
