module fane_mm_top #(
        parameter IMG_W = 9,
        parameter IMG_D = 2,
	parameter A_W = 14,
	parameter M_W = 18,
	parameter D_W = 48,
        parameter NUMBER_OF_REG = 3,
	parameter URAM_D_W = 72,
	parameter URAM_A_W = 23
)
(
input clk,
input rst,
input ce,
input [URAM_A_W-1:0] uram1_wr_addr,
input [URAM_D_W-1:0] uram1_wr_data,
input uram1_wr_en,
input [URAM_A_W-1:0] uram2_wr_addr,
input [URAM_D_W-1:0] uram2_wr_data,
input uram2_wr_en,
input [URAM_A_W-1:0] uram3_wr_addr,
input [URAM_D_W-1:0] uram3_wr_data,
input uram3_wr_en,
input [URAM_A_W-1:0] uram4_wr_addr,
input [URAM_D_W-1:0] uram4_wr_data,
input uram4_wr_en,
input [A_W-1:0]      bram1_rd_addr,
input                bram1_rd_en,
output [M_W-1:0]     bram1_rd_data,
input [A_W-1:0]      bram2_rd_addr,
input                bram2_rd_en,
output [M_W-1:0]     bram2_rd_data,
input [A_W-1:0]      bram3_rd_addr,
input                bram3_rd_en,
output [M_W-1:0]     bram3_rd_data,
input [A_W-1:0]      bram4_rd_addr,
input                bram4_rd_en,
output [M_W-1:0]     bram4_rd_data,
input [A_W-1:0]      b1_wr_addr,
input [15:0]         b1_wr_data,
input b1_wr_en,
input [A_W-1:0]      b2_wr_addr,
input [15:0]         b2_wr_data,
input b2_wr_en,
input [A_W-1:0]      b3_wr_addr,
input b3_wr_en,
input [A_W-1:0]      b4_wr_addr,
input b4_wr_en,
input [A_W-1:0]      b5_wr_addr,
input b5_wr_en,
input [A_W-1:0]      b6_wr_addr,
input b6_wr_en,
input [A_W-1:0]      b7_wr_addr,
input b7_wr_en,
input [A_W-1:0]      b8_wr_addr,
input b8_wr_en,
input [A_W-1:0]      b9_wr_addr,
input b9_wr_en,
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

localparam NO_ITR_W = IMG_W/9;
localparam NO_ITR_D = IMG_D;

localparam RST_s   = 3'b001;
localparam READ_s  = 3'b010;
localparam DONE_s  = 3'b100;

reg [2:0]                         p_state;
reg [2:0]                         n_state;
reg [$clog2(NO_ITR_W*NO_ITR_D):0] rem_img_sz;
reg                               ce_dsp, ce_dsp_r, ce_dsp_2r, ce_dsp_1, ce_dsp_2;
reg                               ce_dsp_opr1;
reg                               ce_dsp_opr2;
reg [13:0]                        master_rdaddr;
reg [13:0]                        master_rdaddr_r;
reg [13:0]                        master_rdaddr_2r;
reg [13:0]                        master_rdaddr_3r;
reg [13:0]                        master_rdaddr_4r;
reg [13:0]                        master_rdaddr_5r;
reg [13:0]                        master_rdaddr_6r;
reg [13:0]                        master_rdaddr_7r;
reg [15:0]                        rd_data1_r1;
reg [15:0]                        rd_data2_r1;
reg [15:0]                        rd_data3_r1;
reg [15:0]                        rd_data4_r1;
reg [15:0]                        rd_data5_r1;
reg [15:0]                        rd_data6_r1;
reg [15:0]                        rd_data7_r1;
reg [15:0]                        rd_data8_r1;
reg [15:0]                        rd_data9_r1;
reg [15:0]                        rd_data1_r2;
reg [15:0]                        rd_data2_r2;
reg [15:0]                        rd_data3_r2;
reg [15:0]                        rd_data4_r2;
reg [15:0]                        rd_data5_r2;
reg [15:0]                        rd_data6_r2;
reg [15:0]                        rd_data7_r2;
reg [15:0]                        rd_data8_r2;
reg [15:0]                        rd_data9_r2;

wire [2:0]                        ce_tmp;
wire [15:0]                       rd_data1;
wire [15:0]                       rd_data2;
wire [15:0]                       rd_data3;
wire [15:0]                       rd_data4;
wire [15:0]                       rd_data5;
wire [15:0]                       rd_data6;
wire [15:0]                       rd_data7;
wire [15:0]                       rd_data8;
wire [15:0]                       rd_data9;
wire [15:0]                       rd_data1_tmp;
wire [15:0]                       rd_data2_tmp;
wire [15:0]                       rd_data3_tmp;
wire [15:0]                       rd_data4_tmp;
wire [15:0]                       rd_data5_tmp;
wire [15:0]                       rd_data6_tmp;
wire [15:0]                       rd_data7_tmp;
wire [15:0]                       rd_data8_tmp;
wire [15:0]                       rd_data9_tmp;
wire [M_W-1:0]                    casc_data_b1;
wire [M_W-1:0]                    casc_data_b2;
wire [M_W-1:0]                    casc_data_b3;
wire [M_W-1:0]                    casc_data_b4;
wire [M_W-1:0]                    casc_data_b5;
wire [M_W-1:0]                    casc_data_b6;
wire [M_W-1:0]                    casc_data_b7;

wire	[22:0]	CAS_OUT_ADDR_LOCAL1;
wire	[8:0]	CAS_OUT_BWE_LOCAL1;
wire	[0:0]	CAS_OUT_DBITERR_LOCAL1;
wire	[71:0]	CAS_OUT_DIN_LOCAL1;
wire	[71:0]	CAS_OUT_DOUT_LOCAL1;
wire	[0:0]	CAS_OUT_EN_LOCAL1;
wire	[0:0]	CAS_OUT_RDACCESS_LOCAL1;
wire	[0:0]	CAS_OUT_RDB_WR_LOCAL1;
wire	[0:0]	CAS_OUT_SBITERR_LOCAL1;

wire	[22:0]	CAS_OUT_ADDR_LOCAL2;
wire	[8:0]	CAS_OUT_BWE_LOCAL2;
wire	[0:0]	CAS_OUT_DBITERR_LOCAL2;
wire	[71:0]	CAS_OUT_DIN_LOCAL2;
wire	[71:0]	CAS_OUT_DOUT_LOCAL2;
wire	[0:0]	CAS_OUT_EN_LOCAL2;
wire	[0:0]	CAS_OUT_RDACCESS_LOCAL2;
wire	[0:0]	CAS_OUT_RDB_WR_LOCAL2;
wire	[0:0]	CAS_OUT_SBITERR_LOCAL2;

wire	[22:0]	CAS_OUT_ADDR_LOCAL3;
wire	[8:0]	CAS_OUT_BWE_LOCAL3;
wire	[0:0]	CAS_OUT_DBITERR_LOCAL3;
wire	[71:0]	CAS_OUT_DIN_LOCAL3;
wire	[71:0]	CAS_OUT_DOUT_LOCAL3;
wire	[0:0]	CAS_OUT_EN_LOCAL3;
wire	[0:0]	CAS_OUT_RDACCESS_LOCAL3;
wire	[0:0]	CAS_OUT_RDB_WR_LOCAL3;
wire	[0:0]	CAS_OUT_SBITERR_LOCAL3;

always@(posedge clk) begin
  if (rst) p_state <= RST_s;
  else     p_state <= n_state;
end

always@(*) begin
  case (p_state)
    RST_s : n_state <= READ_s;
    READ_s : begin
                if (rem_img_sz == 1)
                  n_state <= DONE_s;
                else
                  n_state <= READ_s;
              end
    DONE_s : begin
               if (rst)
                 n_state <= RST_s;
               else
                 n_state <= DONE_s;
             end
    default: n_state <= RST_s;
  endcase
end

always@(posedge clk) begin
  if (rst) rem_img_sz <= 'b0;
  else begin
    if (p_state[0]) rem_img_sz <= NO_ITR_W*NO_ITR_D;
    else if (p_state[1]) rem_img_sz <= rem_img_sz - 1;
  end
end

generate if (NUMBER_OF_REG == 1) begin : wr_en1
  always@(posedge clk) begin
    if (rst) begin
      ce_dsp <= 1'b0;
    end else begin
      ce_dsp <= p_state[1];
    end
  end

  assign rd_data1_tmp = rd_data1;
  assign rd_data2_tmp = rd_data2;
  assign rd_data3_tmp = rd_data3;
  assign rd_data4_tmp = rd_data4;
  assign rd_data5_tmp = rd_data5;
  assign rd_data6_tmp = rd_data6;
  assign rd_data7_tmp = rd_data7;
  assign rd_data8_tmp = rd_data8;
  assign rd_data9_tmp = rd_data9;
end endgenerate

generate if (NUMBER_OF_REG == 2) begin : wr_en2
  always@(posedge clk) begin
    if (rst) begin
      ce_dsp_opr1 <= 1'b0;
      ce_dsp <= 1'b0;
    end else begin
      ce_dsp_opr1 <= p_state[1];
      ce_dsp <= ce_dsp_opr1;
    end
  end
  assign rd_data1_tmp = rd_data1_r1;
  assign rd_data2_tmp = rd_data2_r1;
  assign rd_data3_tmp = rd_data3_r1;
  assign rd_data4_tmp = rd_data4_r1;
  assign rd_data5_tmp = rd_data5_r1;
  assign rd_data6_tmp = rd_data6_r1;
  assign rd_data7_tmp = rd_data7_r1;
  assign rd_data8_tmp = rd_data8_r1;
  assign rd_data9_tmp = rd_data9_r1;
end endgenerate

generate if (NUMBER_OF_REG == 3) begin : wr_en3
  always@(posedge clk) begin
    if (rst) begin
      ce_dsp_opr2 <= 1'b0;
      ce_dsp_opr1 <= 1'b0;
      ce_dsp <= 1'b0;
    end else begin
      ce_dsp_opr2 <= p_state[1];
      ce_dsp_opr1 <= ce_dsp_opr2;
      ce_dsp <= ce_dsp_opr1;
    end
  end
  assign rd_data1_tmp = rd_data1_r2;
  assign rd_data2_tmp = rd_data2_r2;
  assign rd_data3_tmp = rd_data3_r2;
  assign rd_data4_tmp = rd_data4_r2;
  assign rd_data5_tmp = rd_data5_r2;
  assign rd_data6_tmp = rd_data6_r2;
  assign rd_data7_tmp = rd_data7_r2;
  assign rd_data8_tmp = rd_data8_r2;
  assign rd_data9_tmp = rd_data9_r2;
end endgenerate

always@(posedge clk) begin
  rd_data1_r1 <= rd_data1;
  rd_data2_r1 <= rd_data2;
  rd_data3_r1 <= rd_data3;
  rd_data4_r1 <= rd_data4;
  rd_data5_r1 <= rd_data5;
  rd_data6_r1 <= rd_data6;
  rd_data7_r1 <= rd_data7;
  rd_data8_r1 <= rd_data8;
  rd_data9_r1 <= rd_data9;
  rd_data1_r2 <= rd_data1_r1;
  rd_data2_r2 <= rd_data2_r1;
  rd_data3_r2 <= rd_data3_r1;
  rd_data4_r2 <= rd_data4_r1;
  rd_data5_r2 <= rd_data5_r1;
  rd_data6_r2 <= rd_data6_r1;
  rd_data7_r2 <= rd_data7_r1;
  rd_data8_r2 <= rd_data8_r1;
  rd_data9_r2 <= rd_data9_r1;
end

always@(posedge clk) begin
  if (rst) begin
    ce_dsp_r  <= 1'b0;
    ce_dsp_2r <= 1'b0;
  end else begin
    ce_dsp_r  <= ce_dsp;
    ce_dsp_2r <= ce_dsp_r;
  end
end

always@(*) begin
  ce_dsp_1 <= ce_dsp_2r || ce_dsp_r;
end

always@(posedge clk) begin
  if (rst) ce_dsp_2 <= 1'b0;
  else ce_dsp_2     <= ce_dsp_1;
end

assign ce_tmp = {ce_dsp_2, ce_dsp_1, ce_dsp_r};

always@(posedge clk) begin
  if (rst) begin
    master_rdaddr <= 14'd0;
  end else if (p_state[1]) begin
    master_rdaddr <= master_rdaddr + 14'd16;
  end
end

always@(posedge clk) begin
  if (rst) begin
    master_rdaddr_r  <= 14'd0;
    master_rdaddr_2r <= 14'd0;
    master_rdaddr_3r <= 14'd0;
    master_rdaddr_4r <= 14'd0;
    master_rdaddr_5r <= 14'd0;
    master_rdaddr_6r <= 14'd0;
    master_rdaddr_7r <= 14'd0;
  end else begin
    master_rdaddr_r  <= master_rdaddr;
    master_rdaddr_2r <= master_rdaddr_r;
    master_rdaddr_3r <= master_rdaddr_2r;
    master_rdaddr_4r <= master_rdaddr_3r;
    master_rdaddr_5r <= master_rdaddr_4r;
    master_rdaddr_6r <= master_rdaddr_5r;
    master_rdaddr_7r <= master_rdaddr_6r;
  end
end

		RAMB18E2 #(
			.DOA_REG(1),.DOB_REG(1),
			.CASCADE_ORDER_A("FIRST"),.CASCADE_ORDER_B("NONE"),
			.CLOCK_DOMAINS("COMMON"),
                        .WRITE_MODE_A("WRITE_FIRST"), .WRITE_MODE_B("WRITE_FIRST"),
			.WRITE_WIDTH_A(18), .WRITE_WIDTH_B(18),
			.READ_WIDTH_A(18), .READ_WIDTH_B(18))
        	bram1 (
	                .ADDRARDADDR(master_rdaddr),
        	        .ADDRBWRADDR(b1_wr_addr),
	                .ADDRENA(1'b1),
	                .ADDRENB(1'b1),
	                .WEA({2{1'b0}}),
	                .WEBWE({4{b1_wr_en}}),
	                .CASDOUTA(casc_data_b1[15:0]),
	                .CASDOUTPA(casc_data_b1[17:16]),
	                .DINBDIN(b1_wr_data[15:0]),
	                .DINPBDINP(2'd0),
                        .CASDIMUXA('b0),
                        .CASDIMUXB('b0),
	                .DOUTADOUT(rd_data1),
	                .CLKARDCLK(clk),
	                .CLKBWRCLK(clk),
	                .ENARDEN(ce),
	                .ENBWREN(ce),
	                .REGCEAREGCE(ce),
	                .REGCEB(ce),
	                .RSTRAMARSTRAM(rst),
	                .RSTRAMB(rst),
	                .RSTREGARSTREG(rst),
	                .RSTREGB(rst) );

		RAMB18E2 #(
			.DOA_REG(1),.DOB_REG(1),
			.CASCADE_ORDER_A("FIRST"),.CASCADE_ORDER_B("NONE"),
			.CLOCK_DOMAINS("COMMON"),
                        .WRITE_MODE_A("WRITE_FIRST"), .WRITE_MODE_B("WRITE_FIRST"),
			.WRITE_WIDTH_A(18), .WRITE_WIDTH_B(18),
			.READ_WIDTH_A(18), .READ_WIDTH_B(18))
        	bram2 (
	                .ADDRARDADDR(master_rdaddr),
        	        .ADDRBWRADDR(b2_wr_addr),
	                .ADDRENA(1'b1),
	                .ADDRENB(1'b1),
	                .WEA({2{1'b0}}),
	                .WEBWE({4{b2_wr_en}}),
	                .CASDOUTA(casc_data_b2[15:0]),
	                .CASDOUTPA(casc_data_b2[17:16]),
	                .DINBDIN(b2_wr_data[15:0]),
	                .DINPBDINP(2'd0),
                        .CASDIMUXA('b0),
                        .CASDIMUXB('b0),
	                .DOUTADOUT(rd_data2),
	                .CLKARDCLK(clk),
	                .CLKBWRCLK(clk),
	                .ENARDEN(ce),
	                .ENBWREN(ce),
	                .REGCEAREGCE(ce),
	                .REGCEB(ce),
	                .RSTRAMARSTRAM(rst),
	                .RSTRAMB(rst),
	                .RSTREGARSTREG(rst),
	                .RSTREGB(rst) );

		RAMB18E2 #(
			.DOA_REG(1),.DOB_REG(1),
			.CASCADE_ORDER_A("LAST"),.CASCADE_ORDER_B("FIRST"),
			.CLOCK_DOMAINS("COMMON"),
                        .WRITE_MODE_A("WRITE_FIRST"), .WRITE_MODE_B("WRITE_FIRST"),
			.WRITE_WIDTH_A(18), .WRITE_WIDTH_B(18),
			.READ_WIDTH_A(18), .READ_WIDTH_B(18))
        	bram3 (
	                .ADDRARDADDR(b3_wr_addr),
        	        .ADDRBWRADDR(master_rdaddr_r),
	                .ADDRENA(1'b1),
	                .ADDRENB(1'b1),
	                .WEA({2{b3_wr_en}}),
	                .WEBWE({4{1'b0}}),
	                .CASDOUTB(casc_data_b3[15:0]),
	                .CASDOUTPB(casc_data_b3[17:16]),
                        .CASDINA(casc_data_b1[15:0]),
                        .CASDINPA(casc_data_b1[17:16]),
                        .CASDIMUXB(1'b0),
                        .CASDIMUXA(1'b1),
	                .DOUTBDOUT(rd_data3),
	                .CLKARDCLK(clk),
	                .CLKBWRCLK(clk),
	                .ENARDEN(ce),
	                .ENBWREN(ce),
	                .REGCEAREGCE(ce),
	                .REGCEB(ce),
	                .RSTRAMARSTRAM(rst),
	                .RSTRAMB(rst),
	                .RSTREGARSTREG(rst),
	                .RSTREGB(rst) );

		RAMB18E2 #(
			.DOA_REG(1),.DOB_REG(1),
			.CASCADE_ORDER_A("LAST"),.CASCADE_ORDER_B("FIRST"),
			.CLOCK_DOMAINS("COMMON"),
                        .WRITE_MODE_A("WRITE_FIRST"), .WRITE_MODE_B("WRITE_FIRST"),
			.WRITE_WIDTH_A(18), .WRITE_WIDTH_B(18),
			.READ_WIDTH_A(18), .READ_WIDTH_B(18))
        	bram4 (
	                .ADDRARDADDR(b4_wr_addr),
        	        .ADDRBWRADDR(master_rdaddr_3r),
	                .ADDRENA(1'b1),
	                .ADDRENB(1'b1),
	                .WEA({2{b4_wr_en}}),
	                .WEBWE({4{1'b0}}),
	                .CASDOUTB(casc_data_b4[15:0]),
	                .CASDOUTPB(casc_data_b4[17:16]),
                        .CASDINA(casc_data_b2[15:0]),
                        .CASDINPA(casc_data_b2[17:16]),
                        .CASDIMUXB(1'b0),
                        .CASDIMUXA(1'b1),
	                .DOUTBDOUT(rd_data4),
	                .CLKARDCLK(clk),
	                .CLKBWRCLK(clk),
	                .ENARDEN(ce),
	                .ENBWREN(ce),
	                .REGCEAREGCE(ce),
	                .REGCEB(ce),
	                .RSTRAMARSTRAM(rst),
	                .RSTRAMB(rst),
	                .RSTREGARSTREG(rst),
	                .RSTREGB(rst) );

		RAMB18E2 #(
			.DOA_REG(1),.DOB_REG(1),
			.CASCADE_ORDER_A("FIRST"),.CASCADE_ORDER_B("LAST"),
			.CLOCK_DOMAINS("COMMON"),
                        .WRITE_MODE_A("WRITE_FIRST"), .WRITE_MODE_B("WRITE_FIRST"),
			.WRITE_WIDTH_A(18), .WRITE_WIDTH_B(18),
			.READ_WIDTH_A(18), .READ_WIDTH_B(18))
        	bram5 (
	                .ADDRARDADDR(master_rdaddr_3r),
        	        .ADDRBWRADDR(b5_wr_addr),
	                .ADDRENA(1'b1),
	                .ADDRENB(1'b1),
	                .WEA({2{1'b0}}),
	                .WEBWE({4{b5_wr_en}}),
	                .CASDOUTA(casc_data_b5[15:0]),
	                .CASDOUTPA(casc_data_b5[17:16]),
                        .CASDINB(casc_data_b3[15:0]),
                        .CASDINPB(casc_data_b3[17:16]),
                        .CASDIMUXB(1'b1),
                        .CASDIMUXA(1'b0),
	                .DOUTADOUT(rd_data5),
	                .CLKARDCLK(clk),
	                .CLKBWRCLK(clk),
	                .ENARDEN(ce),
	                .ENBWREN(ce),
	                .REGCEAREGCE(ce),
	                .REGCEB(ce),
	                .RSTRAMARSTRAM(rst),
	                .RSTRAMB(rst),
	                .RSTREGARSTREG(rst),
	                .RSTREGB(rst) );

		RAMB18E2 #(
			.DOA_REG(1),.DOB_REG(1),
			.CASCADE_ORDER_A("FIRST"),.CASCADE_ORDER_B("LAST"),
			.CLOCK_DOMAINS("COMMON"),
                        .WRITE_MODE_A("WRITE_FIRST"), .WRITE_MODE_B("WRITE_FIRST"),
			.WRITE_WIDTH_A(18), .WRITE_WIDTH_B(18),
			.READ_WIDTH_A(18), .READ_WIDTH_B(18))
        	bram6 (
	                .ADDRARDADDR(master_rdaddr_4r),
        	        .ADDRBWRADDR(b6_wr_addr),
	                .ADDRENA(1'b1),
	                .ADDRENB(1'b1),
	                .WEA({2{1'b0}}),
	                .WEBWE({4{b6_wr_en}}),
	                .CASDOUTA(casc_data_b6[15:0]),
	                .CASDOUTPA(casc_data_b6[17:16]),
                        .CASDINB(casc_data_b4[15:0]),
                        .CASDINPB(casc_data_b4[17:16]),
                        .CASDIMUXB(1'b1),
                        .CASDIMUXA(1'b0),
	                .DOUTADOUT(rd_data6),
	                .CLKARDCLK(clk),
	                .CLKBWRCLK(clk),
	                .ENARDEN(ce),
	                .ENBWREN(ce),
	                .REGCEAREGCE(ce),
	                .REGCEB(ce),
	                .RSTRAMARSTRAM(rst),
	                .RSTRAMB(rst),
	                .RSTREGARSTREG(rst),
	                .RSTREGB(rst) );

		RAMB18E2 #(
			.DOA_REG(1),.DOB_REG(1),
			.CASCADE_ORDER_A("LAST"),.CASCADE_ORDER_B("FIRST"),
			.CLOCK_DOMAINS("COMMON"),
                        .WRITE_MODE_A("WRITE_FIRST"), .WRITE_MODE_B("WRITE_FIRST"),
			.WRITE_WIDTH_A(18), .WRITE_WIDTH_B(18),
			.READ_WIDTH_A(18), .READ_WIDTH_B(18))
        	bram7 (
	                .ADDRARDADDR(b7_wr_addr),
        	        .ADDRBWRADDR(master_rdaddr_6r),
	                .ADDRENA(1'b1),
	                .ADDRENB(1'b1),
	                .WEA({2{b7_wr_en}}),
	                .WEBWE({4{1'b0}}),
	                .CASDOUTB(casc_data_b7[15:0]),
	                .CASDOUTPB(casc_data_b7[17:16]),
                        .CASDINA(casc_data_b5[15:0]),
                        .CASDINPA(casc_data_b5[17:16]),
                        .CASDIMUXB(1'b0),
                        .CASDIMUXA(1'b1),
	                .DOUTBDOUT(rd_data7),
	                .CLKARDCLK(clk),
	                .CLKBWRCLK(clk),
	                .ENARDEN(ce),
	                .ENBWREN(ce),
	                .REGCEAREGCE(ce),
	                .REGCEB(ce),
	                .RSTRAMARSTRAM(rst),
	                .RSTRAMB(rst),
	                .RSTREGARSTREG(rst),
	                .RSTREGB(rst) );

		RAMB18E2 #(
			.DOA_REG(1),.DOB_REG(1),
			.CASCADE_ORDER_A("LAST"),.CASCADE_ORDER_B("NONE"),
			.CLOCK_DOMAINS("COMMON"),
                        .WRITE_MODE_A("WRITE_FIRST"), .WRITE_MODE_B("WRITE_FIRST"),
			.WRITE_WIDTH_A(18), .WRITE_WIDTH_B(18),
			.READ_WIDTH_A(18), .READ_WIDTH_B(18))
        	bram8 (
	                .ADDRARDADDR(b8_wr_addr),
        	        .ADDRBWRADDR(master_rdaddr_6r),
	                .ADDRENA(1'b1),
	                .ADDRENB(1'b1),
	                .WEA({2{b8_wr_en}}),
	                .WEBWE({4{1'b0}}),
                        .CASDINA(casc_data_b6[15:0]),
                        .CASDINPA(casc_data_b6[17:16]),
                        .CASDIMUXB(1'b0),
                        .CASDIMUXA(1'b1),
	                .DOUTBDOUT(rd_data8),
	                .CLKARDCLK(clk),
	                .CLKBWRCLK(clk),
	                .ENARDEN(ce),
	                .ENBWREN(ce),
	                .REGCEAREGCE(ce),
	                .REGCEB(ce),
	                .RSTRAMARSTRAM(rst),
	                .RSTRAMB(rst),
	                .RSTREGARSTREG(rst),
	                .RSTREGB(rst) );

		RAMB18E2 #(
			.DOA_REG(1),.DOB_REG(1),
			.CASCADE_ORDER_A("NONE"),.CASCADE_ORDER_B("LAST"),
			.CLOCK_DOMAINS("COMMON"),
                        .WRITE_MODE_A("WRITE_FIRST"), .WRITE_MODE_B("WRITE_FIRST"),
			.WRITE_WIDTH_A(18), .WRITE_WIDTH_B(18),
			.READ_WIDTH_A(18), .READ_WIDTH_B(18))
        	bram9 (
	                .ADDRARDADDR(master_rdaddr_7r),
        	        .ADDRBWRADDR(b9_wr_addr),
	                .ADDRENA(1'b1),
	                .ADDRENB(1'b1),
	                .WEA({2{1'b0}}),
	                .WEBWE({4{b9_wr_en}}),
                        .CASDINB(casc_data_b7[15:0]),
                        .CASDINPB(casc_data_b7[17:16]),
                        .CASDIMUXB(1'b1),
                        .CASDIMUXA(1'b0),
	                .DOUTADOUT(rd_data9),
	                .CLKARDCLK(clk),
	                .CLKBWRCLK(clk),
	                .ENARDEN(ce),
	                .ENBWREN(ce),
	                .REGCEAREGCE(ce),
	                .REGCEB(ce),
	                .RSTRAMARSTRAM(rst),
	                .RSTRAMB(rst),
	                .RSTREGARSTREG(rst),
	                .RSTREGB(rst) );

(* dont_touch = "true" *) fane_mm #(
	 .A_W (A_W)
	,.M_W (M_W)
	,.D_W (D_W)
	,.URAM_D_W (URAM_D_W)
	,.URAM_A_W (URAM_A_W)
        ,.NUMBER_OF_REG (NUMBER_OF_REG)
        ,.CASCADE_ORDER_A ("FIRST")
        ,.SELF_ADDR_A (11'h0)
)
mm1 (
         .clk           (clk)
        ,.rst           (rst)
        ,.ce            (ce)
        ,.ce_tmp        (ce_tmp)
        ,.bram_data1    (rd_data1_tmp[7:0])
        ,.bram_data2    (rd_data2_tmp[7:0])
        ,.bram_data3    (rd_data3_tmp[7:0])
        ,.bram_data4    (rd_data4_tmp[7:0])
        ,.bram_data5    (rd_data5_tmp[7:0])
        ,.bram_data6    (rd_data6_tmp[7:0])
        ,.bram_data7    (rd_data7_tmp[7:0])
        ,.bram_data8    (rd_data8_tmp[7:0])
        ,.bram_data9    (rd_data9_tmp[7:0])
        ,.uram_rd_addr  (master_rdaddr)
        ,.uram_wr_addr  (uram1_wr_addr)
        ,.uram_wr_data  (uram1_wr_data)
        ,.uram_wr_en    (uram1_wr_en)
        ,.bram_rd_addr_external (bram1_rd_addr)
        ,.bram_rd_en_external (bram1_rd_en)
        ,.bram_rd_data  (bram1_rd_data)
        ,.CAS_OUT_ADDR    (CAS_OUT_ADDR_LOCAL1)
        ,.CAS_OUT_BWE	    (CAS_OUT_BWE_LOCAL1)
        ,.CAS_OUT_DBITERR (CAS_OUT_DBITERR_LOCAL1)
        ,.CAS_OUT_DIN	    (CAS_OUT_DIN_LOCAL1)
        ,.CAS_OUT_DOUT   (CAS_OUT_DOUT_LOCAL1)
        ,.CAS_OUT_EN	   (CAS_OUT_EN_LOCAL1)
        ,.CAS_OUT_RDACCESS (CAS_OUT_RDACCESS_LOCAL1)
        ,.CAS_OUT_RDB_WR   (CAS_OUT_RDB_WR_LOCAL1)
        ,.CAS_OUT_SBITERR  (CAS_OUT_SBITERR_LOCAL1)
        ,.CAS_IN_ADDR	   (CAS_IN_ADDR)
        ,.CAS_IN_BWE	   (CAS_IN_BWE)
        ,.CAS_IN_DBITERR  (CAS_IN_DBITERR)
        ,.CAS_IN_DIN	   (CAS_IN_DIN)
        ,.CAS_IN_DOUT	   (CAS_IN_DOUT)
        ,.CAS_IN_EN	   (CAS_IN_EN)
        ,.CAS_IN_RDACCESS (CAS_IN_RDACCESS)
        ,.CAS_IN_RDB_WR   (CAS_IN_RDB_WR)
        ,.CAS_IN_SBITERR  (CAS_IN_SBITERR)
);

(* dont_touch = "true" *) fane_mm #(
	 .A_W (A_W)
	,.M_W (M_W)
	,.D_W (D_W)
	,.URAM_D_W (URAM_D_W)
	,.URAM_A_W (URAM_A_W)
        ,.NUMBER_OF_REG (NUMBER_OF_REG)
        ,.CASCADE_ORDER_A ("MIDDLE")
        ,.SELF_ADDR_A (11'h1)
)
mm2 (
         .clk           (clk)
        ,.rst           (rst)
        ,.ce            (ce)
        ,.ce_tmp        (ce_tmp)
        ,.bram_data1    (rd_data1_tmp[7:0])
        ,.bram_data2    (rd_data2_tmp[7:0])
        ,.bram_data3    (rd_data3_tmp[7:0])
        ,.bram_data4    (rd_data4_tmp[7:0])
        ,.bram_data5    (rd_data5_tmp[7:0])
        ,.bram_data6    (rd_data6_tmp[7:0])
        ,.bram_data7    (rd_data7_tmp[7:0])
        ,.bram_data8    (rd_data8_tmp[7:0])
        ,.bram_data9    (rd_data9_tmp[7:0])
        ,.uram_rd_addr  (master_rdaddr)
        ,.uram_wr_addr  (uram2_wr_addr)
        ,.uram_wr_data  (uram2_wr_data)
        ,.uram_wr_en    (uram2_wr_en)
        ,.bram_rd_addr_external (bram2_rd_addr)
        ,.bram_rd_en_external (bram2_rd_en)
        ,.bram_rd_data  (bram2_rd_data)
        ,.CAS_OUT_ADDR    (CAS_OUT_ADDR_LOCAL2)
        ,.CAS_OUT_BWE	    (CAS_OUT_BWE_LOCAL2)
        ,.CAS_OUT_DBITERR (CAS_OUT_DBITERR_LOCAL2)
        ,.CAS_OUT_DIN	    (CAS_OUT_DIN_LOCAL2)
        ,.CAS_OUT_DOUT   (CAS_OUT_DOUT_LOCAL2)
        ,.CAS_OUT_EN	   (CAS_OUT_EN_LOCAL2)
        ,.CAS_OUT_RDACCESS (CAS_OUT_RDACCESS_LOCAL2)
        ,.CAS_OUT_RDB_WR   (CAS_OUT_RDB_WR_LOCAL2)
        ,.CAS_OUT_SBITERR  (CAS_OUT_SBITERR_LOCAL2)
        ,.CAS_IN_ADDR	   (CAS_OUT_ADDR_LOCAL1)
        ,.CAS_IN_BWE	   (CAS_OUT_BWE_LOCAL1)
        ,.CAS_IN_DBITERR  (CAS_OUT_DBITERR_LOCAL1)
        ,.CAS_IN_DIN	   (CAS_OUT_DIN_LOCAL1)
        ,.CAS_IN_DOUT	   (CAS_OUT_DOUT_LOCAL1)
        ,.CAS_IN_EN	   (CAS_OUT_EN_LOCAL1)
        ,.CAS_IN_RDACCESS (CAS_OUT_RDACCESS_LOCAL1)
        ,.CAS_IN_RDB_WR   (CAS_OUT_RDB_WR_LOCAL1)
        ,.CAS_IN_SBITERR  (CAS_OUT_SBITERR_LOCAL1)
);

(* dont_touch = "true" *) fane_mm #(
	 .A_W (A_W)
	,.M_W (M_W)
	,.D_W (D_W)
	,.URAM_D_W (URAM_D_W)
	,.URAM_A_W (URAM_A_W)
        ,.NUMBER_OF_REG (NUMBER_OF_REG)
        ,.CASCADE_ORDER_A ("MIDDLE")
        ,.SELF_ADDR_A (11'h2)
)
mm3 (
         .clk           (clk)
        ,.rst           (rst)
        ,.ce            (ce)
        ,.ce_tmp        (ce_tmp)
        ,.bram_data1    (rd_data1_tmp[7:0])
        ,.bram_data2    (rd_data2_tmp[7:0])
        ,.bram_data3    (rd_data3_tmp[7:0])
        ,.bram_data4    (rd_data4_tmp[7:0])
        ,.bram_data5    (rd_data5_tmp[7:0])
        ,.bram_data6    (rd_data6_tmp[7:0])
        ,.bram_data7    (rd_data7_tmp[7:0])
        ,.bram_data8    (rd_data8_tmp[7:0])
        ,.bram_data9    (rd_data9_tmp[7:0])
        ,.uram_rd_addr  (master_rdaddr)
        ,.uram_wr_addr  (uram3_wr_addr)
        ,.uram_wr_data  (uram3_wr_data)
        ,.uram_wr_en    (uram3_wr_en)
        ,.bram_rd_addr_external (bram3_rd_addr)
        ,.bram_rd_en_external (bram3_rd_en)
        ,.bram_rd_data  (bram3_rd_data)
        ,.CAS_OUT_ADDR    (CAS_OUT_ADDR_LOCAL3)
        ,.CAS_OUT_BWE	    (CAS_OUT_BWE_LOCAL3)
        ,.CAS_OUT_DBITERR (CAS_OUT_DBITERR_LOCAL3)
        ,.CAS_OUT_DIN	    (CAS_OUT_DIN_LOCAL3)
        ,.CAS_OUT_DOUT   (CAS_OUT_DOUT_LOCAL3)
        ,.CAS_OUT_EN	   (CAS_OUT_EN_LOCAL3)
        ,.CAS_OUT_RDACCESS (CAS_OUT_RDACCESS_LOCAL3)
        ,.CAS_OUT_RDB_WR   (CAS_OUT_RDB_WR_LOCAL3)
        ,.CAS_OUT_SBITERR  (CAS_OUT_SBITERR_LOCAL3)
        ,.CAS_IN_ADDR	   (CAS_OUT_ADDR_LOCAL2)
        ,.CAS_IN_BWE	   (CAS_OUT_BWE_LOCAL2)
        ,.CAS_IN_DBITERR  (CAS_OUT_DBITERR_LOCAL2)
        ,.CAS_IN_DIN	   (CAS_OUT_DIN_LOCAL2)
        ,.CAS_IN_DOUT	   (CAS_OUT_DOUT_LOCAL2)
        ,.CAS_IN_EN	   (CAS_OUT_EN_LOCAL2)
        ,.CAS_IN_RDACCESS (CAS_OUT_RDACCESS_LOCAL2)
        ,.CAS_IN_RDB_WR   (CAS_OUT_RDB_WR_LOCAL2)
        ,.CAS_IN_SBITERR  (CAS_OUT_SBITERR_LOCAL2)
);

(* dont_touch = "true" *) fane_mm #(
	 .A_W (A_W)
	,.M_W (M_W)
	,.D_W (D_W)
	,.URAM_D_W (URAM_D_W)
	,.URAM_A_W (URAM_A_W)
        ,.NUMBER_OF_REG (NUMBER_OF_REG)
        ,.CASCADE_ORDER_A ("LAST")
        ,.SELF_ADDR_A (11'h3)
)
mm4 (
         .clk           (clk)
        ,.rst           (rst)
        ,.ce            (ce)
        ,.ce_tmp        (ce_tmp)
        ,.bram_data1    (rd_data1_tmp[7:0])
        ,.bram_data2    (rd_data2_tmp[7:0])
        ,.bram_data3    (rd_data3_tmp[7:0])
        ,.bram_data4    (rd_data4_tmp[7:0])
        ,.bram_data5    (rd_data5_tmp[7:0])
        ,.bram_data6    (rd_data6_tmp[7:0])
        ,.bram_data7    (rd_data7_tmp[7:0])
        ,.bram_data8    (rd_data8_tmp[7:0])
        ,.bram_data9    (rd_data9_tmp[7:0])
        ,.uram_rd_addr  (master_rdaddr)
        ,.uram_wr_addr  (uram4_wr_addr)
        ,.uram_wr_data  (uram4_wr_data)
        ,.uram_wr_en    (uram4_wr_en)
        ,.bram_rd_addr_external (bram4_rd_addr)
        ,.bram_rd_en_external (bram4_rd_en)
        ,.bram_rd_data  (bram4_rd_data)
        ,.CAS_OUT_ADDR    (CAS_OUT_ADDR)
        ,.CAS_OUT_BWE	    (CAS_OUT_BWE)
        ,.CAS_OUT_DBITERR (CAS_OUT_DBITERR)
        ,.CAS_OUT_DIN	    (CAS_OUT_DIN)
        ,.CAS_OUT_DOUT   (CAS_OUT_DOUT)
        ,.CAS_OUT_EN	   (CAS_OUT_EN)
        ,.CAS_OUT_RDACCESS (CAS_OUT_RDACCESS)
        ,.CAS_OUT_RDB_WR   (CAS_OUT_RDB_WR)
        ,.CAS_OUT_SBITERR  (CAS_OUT_SBITERR)
        ,.CAS_IN_ADDR	   (CAS_OUT_ADDR_LOCAL3)
        ,.CAS_IN_BWE	   (CAS_OUT_BWE_LOCAL3)
        ,.CAS_IN_DBITERR  (CAS_OUT_DBITERR_LOCAL3)
        ,.CAS_IN_DIN	   (CAS_OUT_DIN_LOCAL3)
        ,.CAS_IN_DOUT	   (CAS_OUT_DOUT_LOCAL3)
        ,.CAS_IN_EN	   (CAS_OUT_EN_LOCAL3)
        ,.CAS_IN_RDACCESS (CAS_OUT_RDACCESS_LOCAL3)
        ,.CAS_IN_RDB_WR   (CAS_OUT_RDB_WR_LOCAL3)
        ,.CAS_IN_SBITERR  (CAS_OUT_SBITERR_LOCAL3)
);

endmodule
