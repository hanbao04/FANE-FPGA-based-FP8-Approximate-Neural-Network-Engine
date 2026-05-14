module dsp_conv #(
	parameter A_W = 14,
	parameter M_W = 18,
        parameter NUMBER_OF_REG = 1,
	parameter URAM_D_W = 48,
	parameter URAM_A_W = 14
)
(
input clk,
input rst,
input ce,
input ce_dsp,
input ce_b_in,
input [A_W-1:0] b1_wr_addr,
input           b1_wr_en,
input [A_W-1:0] b2_wr_addr,
input           b2_wr_en,
input [A_W-1:0] b3_wr_addr,
input           b3_wr_en,
input [A_W-1:0] b1_rd_addr,
input [A_W-1:0] b2_rd_addr,
input [A_W-1:0] b3_rd_addr,
input [A_W-1:0] rdaddr_b,
input [15:0]    data_in,
input [A_W-1:0] knl_b_wraddr,
input [M_W-1:0] knl_b_wrdata,
input knl_b_wren,

output reg [15:0] data_out
);

reg                      ce_b;
reg                      ce_b_1;
reg                      ce_b_2;
reg [M_W-1:0]            rd_data_b2_r1;
reg [M_W-1:0]            rd_data_b2_r2;
reg [M_W-1:0]            rd_data_b2_r3;
reg [M_W-1:0]            rd_data_b2_r4;
reg [M_W-1:0]            rd_data_b2_r5;
reg [M_W-1:0]            rd_data_b3_r1;
reg [M_W-1:0]            rd_data_b3_r2;
reg [M_W-1:0]            rd_data_b3_r3;
reg [M_W-1:0]            rd_data_b3_r4;
reg [M_W-1:0]            rd_data_b3_r5;
reg [M_W-1:0]            rd_data_b3_r6;
reg [M_W-1:0]            rd_data_b3_r7;
reg [M_W-1:0]            rd_data_b3_r8;
reg signed [47:0]        final_accumulation;
reg                      ce_dsp_1;
reg                      ce_dsp_2;
reg [2:0]                ce_tmp_r1;
reg [2:0]                ce_tmp_r2;
reg [2:0]                ce_tmp_r3;
reg [2:0]                ce_tmp_r4;
reg [2:0]                ce_tmp_r5;
reg [2:0]                ce_a0;
reg [2:0]                ce_a0_r1;
reg [2:0]                ce_a0_r2;
reg [2:0]                ce_a1;
reg [2:0]                ce_a1_r1;
reg [2:0]                ce_a1_r2;
reg [2:0]                ce_a2;
reg                      acin0_reg [0:2];
reg                      acin01_r1;
reg                      acin02_r1;
reg                      acin1_reg [0:2];
reg                      acin10_r1;
reg                      acin11_r1;
reg                      acin12_r1;
reg                      acin2_reg [0:2];
reg                      acin20_r1;
reg                      acin21_r1;
reg                      acin22_r1;
reg [7:0]                bcin0_reg [0:2];
reg [7:0]                bcin1_reg [0:2];
reg [7:0]                bcin2_reg [0:2];
reg  [M_W-1:0]           dsp_a1;
reg  [M_W-1:0]           dsp_a2;
reg [M_W-1:0]           dsp_a0_r;
reg [M_W-1:0]           dsp_k0_r;
reg [M_W-1:0]           dsp_a0_1;
reg [M_W-1:0]           dsp_k0_1;
reg [M_W-1:0]           dsp_a0_2;
reg [M_W-1:0]           dsp_k0_2;

wire [M_W-1:0]           casc_data_b1;
wire [M_W-1:0]           casc_data_b2;
wire [M_W-1:0]           casc_data_b3;
wire [M_W-1:0]           rd_data_b2;
wire [M_W-1:0]           rd_data_b3;
wire [29:0]              acin0 [0:3];
wire [29:0]              acin1 [0:3];
wire [29:0]              acin2 [0:3];
wire [17:0]              bcin0 [0:8];
wire [M_W-1:0]           dsp_a0;
wire [M_W-1:0]           dsp_k0;
wire [2:0]               ce_tmp;
//////////////////////// optional register /////////////////
generate if (NUMBER_OF_REG == 1) begin : a0k0_1
  always@(posedge clk) begin
    dsp_a0_r <= dsp_a0;
    dsp_k0_r <= dsp_k0;
    ce_b     <= ce_b_in;
    dsp_a1    <= rd_data_b2_r3;
    dsp_a2    <= rd_data_b3_r6;
    ce_tmp_r1 <= ce_tmp;
  end
end endgenerate

generate if (NUMBER_OF_REG == 2) begin : a0k0_2
  always@(posedge clk) begin
    dsp_a0_1 <= dsp_a0;
    dsp_k0_1 <= dsp_k0;
    dsp_a0_r <= dsp_a0_1;
    dsp_k0_r <= dsp_k0_1;
    ce_b_1   <= ce_b_in;
    ce_b     <= ce_b_1;
    rd_data_b2_r4  <= rd_data_b2_r3;
    dsp_a1    <= rd_data_b2_r4;
    rd_data_b3_r7 <= rd_data_b3_r6;
    dsp_a2        <= rd_data_b3_r7;
    ce_tmp_r3 <= ce_tmp;
    ce_tmp_r2 <= ce_tmp_r3;
    ce_tmp_r1 <= ce_tmp_r2;
  end
end endgenerate

generate if (NUMBER_OF_REG == 3) begin : a0k0_3
  always@(posedge clk) begin
    dsp_a0_1 <= dsp_a0;
    dsp_k0_1 <= dsp_k0;
    dsp_a0_2 <= dsp_a0_1;
    dsp_k0_2 <= dsp_k0_1;
    dsp_a0_r <= dsp_a0_2;
    dsp_k0_r <= dsp_k0_2;
    ce_b_1   <= ce_b_in;
    ce_b_2   <= ce_b_1;
    ce_b     <= ce_b_2;
    rd_data_b2_r4  <= rd_data_b2_r3;
    rd_data_b2_r5  <= rd_data_b2_r4;
    dsp_a1    <= rd_data_b2_r5;
    rd_data_b3_r7 <= rd_data_b3_r6;
    rd_data_b3_r8 <= rd_data_b3_r7;
    dsp_a2  <= rd_data_b3_r8;
    ce_tmp_r5 <= ce_tmp;
    ce_tmp_r4 <= ce_tmp_r5;
    ce_tmp_r3 <= ce_tmp_r4;
    ce_tmp_r2 <= ce_tmp_r3;
    ce_tmp_r1 <= ce_tmp_r2;
  end
end endgenerate
//////////////////////////////////////////////////////////
always@(posedge clk) begin
end


		RAMB18E2 #(
			.DOA_REG(1),.DOB_REG(1),
			.CASCADE_ORDER_A("FIRST"),.CASCADE_ORDER_B("NONE"),
			.CLOCK_DOMAINS("COMMON"),
                        .WRITE_MODE_A("WRITE_FIRST"), .WRITE_MODE_B("WRITE_FIRST"),

			.WRITE_WIDTH_A(18), .WRITE_WIDTH_B(18),
			.READ_WIDTH_A(18), .READ_WIDTH_B(18))
        	bram_inst_rdc1 (
	                .ADDRARDADDR(b1_rd_addr),
        	        .ADDRBWRADDR(b1_wr_addr),
	                .ADDRENA(1'b1),
	                .ADDRENB(1'b1),
	                .WEA({2{1'b0}}),
	                .WEBWE({4{b1_wr_en}}),
	
	                // horizontal links
	                .CASDOUTA(casc_data_b1[15:0]), 
	                .CASDOUTPA(casc_data_b1[17:16]), 
	                .DINBDIN(data_in[15:0]), 
	                .DINPBDINP(2'b00),
                        .CASDIMUXA(1'b0), 
                        .CASDIMUXB(1'b0), 
	                .DOUTADOUT(dsp_a0[15:0]), 
	                .DOUTPADOUTP(dsp_a0[17:16]), 
	
	                // clocking, reset, and enable control
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


		RAMB18E2 #(
			.DOA_REG(1),.DOB_REG(1),
			.CASCADE_ORDER_A("LAST"),.CASCADE_ORDER_B("FIRST"),
			.CLOCK_DOMAINS("COMMON"),

                        .WRITE_MODE_A("WRITE_FIRST"), .WRITE_MODE_B("WRITE_FIRST"),
			.WRITE_WIDTH_A(18), .WRITE_WIDTH_B(18),
			.READ_WIDTH_A(18), .READ_WIDTH_B(18))
        	bram_inst_rdc2 (
	                .ADDRARDADDR(b2_wr_addr),
        	        .ADDRBWRADDR(b2_rd_addr),
	                .ADDRENA(1'b1),
	                .ADDRENB(1'b1),
	                .WEA({2{b2_wr_en}}),
	                .WEBWE({4{1'b0}}),
	
	                // horizontal links
	                .CASDOUTB(casc_data_b2[15:0]), 
	                .CASDOUTPB(casc_data_b2[17:16]), 
                        .CASDINA(casc_data_b1[15:0]),
                        .CASDINPA(casc_data_b1[17:16]),
                        .CASDIMUXB(1'b0),
                        .CASDIMUXA(1'b1),
	                .DOUTBDOUT(rd_data_b2[15:0]), 
	                .DOUTPBDOUTP(rd_data_b2[17:16]), 
	
	                // clocking, reset, and enable control
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

		RAMB18E2 #(
			.DOA_REG(1),.DOB_REG(1),
			.CASCADE_ORDER_A("NONE"),.CASCADE_ORDER_B("LAST"),
			.CLOCK_DOMAINS("COMMON"),

                        .WRITE_MODE_A("WRITE_FIRST"), .WRITE_MODE_B("WRITE_FIRST"),
			.WRITE_WIDTH_A(18), .WRITE_WIDTH_B(18),
			.READ_WIDTH_A(18), .READ_WIDTH_B(18))
        	bram_inst_rdc3 (
	                .ADDRARDADDR(b3_rd_addr),
        	        .ADDRBWRADDR(b3_wr_addr),
	                .ADDRENA(1'b1),
	                .ADDRENB(1'b1),
	                .WEA({2{1'b0}}),
	                .WEBWE({4{b3_wr_en}}),
	
	                // horizontal links
	                .DOUTADOUT(rd_data_b3[15:0]), 
	                .DOUTPADOUTP(rd_data_b3[17:16]), 
                        .CASDINB(casc_data_b2[15:0]),
                        .CASDINPB(casc_data_b2[17:16]),
	                .DOUTBDOUT(), 
	                .DOUTPBDOUTP(),
                        .CASDIMUXB(1'b1),
                        .CASDIMUXA(1'b0),
	
	                // clocking, reset, and enable control
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

///////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////


always@(posedge clk) begin
  if (rst) acin0_reg[0] <= 'b0;
  else if (ce_a0[0]) acin0_reg[0] <= acin0[0][26];
  
  if (rst) begin
    acin01_r1 <= 'b0;
    acin0_reg[1] <= 'b0;
  end else if (ce_a0[1]) begin
    acin01_r1 <= acin0_reg[0];
    acin0_reg[1] <= acin01_r1;
  end

  if (rst) begin
    acin02_r1 <= 'b0;
    acin0_reg[2] <= 'b0;
  end else if (ce_a0[2]) begin
    acin02_r1 <= acin0_reg[1];
    acin0_reg[2] <= acin02_r1;
  end
////
  if (rst) acin1_reg[0] <= 'b0;
  else if (ce_a1[0]) acin1_reg[0] <= acin1[0][26];
  
  if (rst) begin
    acin11_r1 <= 'b0;
    acin1_reg[1] <= 'b0;
  end else if (ce_a1[1]) begin
    acin11_r1 <= acin1_reg[0];
    acin1_reg[1] <= acin11_r1;
  end

  if (rst) begin
    acin12_r1 <= 'b0;
    acin1_reg[2] <= 'b0;
  end else if (ce_a1[2]) begin
    acin12_r1 <= acin1_reg[1];
    acin1_reg[2] <= acin12_r1;
  end
////
  if (rst) acin2_reg[0] <= 'b0;
  else if (ce_a2[0]) acin2_reg[0] <= acin2[0][26];
  
  if (rst) begin
    acin21_r1 <= 'b0;
    acin2_reg[1] <= 'b0;
  end else if (ce_a2[1]) begin
    acin21_r1 <= acin2_reg[0];
    acin2_reg[1] <= acin21_r1;
  end

  if (rst) begin
    acin22_r1 <= 'b0;
    acin2_reg[2] <= 'b0;
  end else if (ce_a2[2]) begin
    acin22_r1 <= acin2_reg[1];
    acin2_reg[2] <= acin22_r1;
  end
end

always@(posedge clk) begin
  if (rst) begin
    bcin0_reg[0] <= 'b0;
    bcin0_reg[1] <= 'b0;
    bcin0_reg[2] <= 'b0;
    bcin1_reg[0] <= 'b0;
    bcin1_reg[1] <= 'b0;
    bcin1_reg[2] <= 'b0;
    bcin2_reg[0] <= 'b0;
    bcin2_reg[1] <= 'b0;
    bcin2_reg[2] <= 'b0;
  end else if (ce_b) begin
    bcin0_reg[0] <= bcin0[0][7:0];
    bcin0_reg[1] <= bcin0_reg[0];
    bcin0_reg[2] <= bcin0_reg[1];
    bcin1_reg[0] <= bcin0_reg[2];
    bcin1_reg[1] <= bcin1_reg[0];
    bcin1_reg[2] <= bcin1_reg[1];
    bcin2_reg[0] <= bcin1_reg[2];
    bcin2_reg[1] <= bcin2_reg[0];
    bcin2_reg[2] <= bcin2_reg[1];
  end
end

always@(posedge clk) begin
    ce_dsp_1 <= ce_dsp;
    ce_dsp_2 <= ce_dsp_1;
end

assign ce_tmp = {ce_dsp_2, ce_dsp_1, ce_dsp};

//registering ce_a for 11 clock cycle
always@(posedge clk) begin
  ce_a0     <= ce_tmp_r1;
  
  ce_a0_r1 <= ce_a0;
  ce_a0_r2 <= ce_a0_r1;
  ce_a1    <= ce_a0_r2;

  ce_a1_r1 <= ce_a1;
  ce_a1_r2 <= ce_a1_r1;
  ce_a2    <= ce_a1_r2;
end

assign acin0[0] = {{3{1'b0}},dsp_a0_r[15:8],{11{1'b0}},dsp_a0_r[7:0]};
assign bcin0[0] = {{10{dsp_k0_r[7]}},dsp_k0_r[7:0]};
assign acin1[0] = {{3{1'b0}},dsp_a1[15:8],{11{1'b0}},dsp_a1[7:0]};
assign acin2[0] = {{3{1'b0}},dsp_a2[15:8],{11{1'b0}},dsp_a2[7:0]};

always@(posedge clk) begin
  rd_data_b2_r1 <= rd_data_b2;
  rd_data_b2_r2 <= rd_data_b2_r1;
  rd_data_b2_r3 <= rd_data_b2_r2;
  rd_data_b3_r1 <= rd_data_b3;
  rd_data_b3_r2 <= rd_data_b3_r1;
  rd_data_b3_r3 <= rd_data_b3_r2;
  rd_data_b3_r4 <= rd_data_b3_r3;
  rd_data_b3_r5 <= rd_data_b3_r4;
  rd_data_b3_r6 <= rd_data_b3_r5;
end

//////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////// FPMAC /////////////////////////////////////////

//kernel ram

		RAMB18E2 #(
			.DOA_REG(1),.DOB_REG(1),
			.CASCADE_ORDER_A("NONE"),.CASCADE_ORDER_B("NONE"),
			.CLOCK_DOMAINS("COMMON"),

			//.INIT_FILE("k_pixels_3.hex"),
			.WRITE_WIDTH_A(18), .WRITE_WIDTH_B(18),
			.READ_WIDTH_A(18), .READ_WIDTH_B(18))
        	bram_inst_rdc4 (
	                .ADDRARDADDR(rdaddr_b),
        	        .ADDRBWRADDR(knl_b_wraddr),
	                .ADDRENA(1'b1),
	                .ADDRENB(1'b1),
	                .WEA({2{1'b0}}),
	                .WEBWE({4{knl_b_wren}}),
	
	                // horizontal links
	                .DOUTADOUT(dsp_k0[15:0]), 
	                .DOUTPADOUTP(dsp_k0[17:16]), 
	                .DINBDIN(knl_b_wrdata[15:0]), 
	                .DINPBDINP(knl_b_wrdata[17:16]), 
	
	                // clocking, reset, and enable control
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

wire [7:0] fp_acc [0:9];
wire [7:0] fp_a   [0:8];
wire [7:0] fp_b   [0:8];

assign fp_acc[0] = 8'd0;

assign fp_a[0] = dsp_a0_r[7:0];
assign fp_a[1] = dsp_a0_r[7:0];
assign fp_a[2] = dsp_a0_r[7:0];
assign fp_a[3] = dsp_a1[7:0];
assign fp_a[4] = dsp_a1[7:0];
assign fp_a[5] = dsp_a1[7:0];
assign fp_a[6] = dsp_a2[7:0];
assign fp_a[7] = dsp_a2[7:0];
assign fp_a[8] = dsp_a2[7:0];

assign fp_b[0] = bcin0_reg[0];
assign fp_b[1] = bcin0_reg[1];
assign fp_b[2] = bcin0_reg[2];
assign fp_b[3] = bcin1_reg[0];
assign fp_b[4] = bcin1_reg[1];
assign fp_b[5] = bcin1_reg[2];
assign fp_b[6] = bcin2_reg[0];
assign fp_b[7] = bcin2_reg[1];
assign fp_b[8] = bcin2_reg[2];

genvar fp_i;
generate
for (fp_i=0; fp_i<9; fp_i=fp_i+1) begin : fpmac_chain
  (* dont_touch = "true" *) fpmac_conv #(
    .NUM_INREG(NUMBER_OF_REG)
  ) fpmac_inst (
    .clk     (clk),
    .rst_n   (~rst),
    .en      (ce),
    .en_1    (ce),
    .en_2    (ce),
    .mul_a   (fp_a[fp_i]),
    .mul_b   (fp_b[fp_i]),
    .sum_in  (fp_acc[fp_i]),
    .acc_out (),
    .PCOUT   (fp_acc[fp_i+1])
  );
end
endgenerate


always@(posedge clk) begin
  if (rst) begin
    data_out <= 16'd0;
  end else if (ce) begin
    data_out <= {8'd0, fp_acc[9]};
  end
end
endmodule
