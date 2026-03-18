module fp8_mm #(
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
output [7:0] bram_rd_data,

//rd uram cascade signals
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


reg [2:0]                ce_a0;
reg [2:0]                ce_a0_r1;
reg [2:0]                ce_a0_r2;
reg [2:0]                ce_a1;
reg [2:0]                ce_a1_r1;
reg [2:0]                ce_a1_r2;
reg [2:0]                ce_a2;
reg                      pc_o_valid_tmp;
reg                      pc_o_valid_tmp_r;
reg                      pc_o_valid_tmp_r2;
reg                      pc_o_valid_tmp_r3;
reg                      pc_o_valid_tmp_r4;
reg                      pc_o_valid_tmp_r5;
reg                      pc_o_valid_tmp_r6;
reg                      pc_o_valid_tmp_r7;
reg                      pc_o_valid_tmp_r8;
reg                      pc_o_valid_tmp_r9;
reg                      pc_o_valid_tmp_r10;
reg                      pc_o_valid_tmp_r11;
reg                      pc_o_valid_tmp_r12;
reg                      pc_o_valid_tmp_r13;
reg                      pc_o_valid_tmp_r14;
reg                      pc_o_valid_tmp_r15;
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
reg [7:0]                bram_rd_data_r;
reg [7:0]                bram_rd_data_r1;
reg [7:0]                bram_rd_data_r2;
reg [7:0]                bram_rd_data_r3;

reg  [A_W-1:0]           bram_wr_addr;
reg  [M_W-1:0]           bram_wr_data;
reg  [71:0]              uram_rd_data_r;
reg  [71:0]              uram_rd_data_r1;
reg  [71:0]              uram_rd_data_r2;
reg                      bram_wr_en;
reg [7:0]                pout_reg;
reg [7:0]                pout_reg1;
reg [7:0]                pout_reg2;
reg [7:0]                pout_reg3;

wire [8:0]               ce_shift;
wire [7:0]               Ain [8:0];
wire [7:0]               Bin [8:0];
wire [7:0]               p [0:9];
wire [7:0]               pout [0:8];
wire [7:0]               cascade_mula [0:8];
wire [7:0]               cascade_mulb [0:8];
wire [URAM_D_W-1:0]      uram_rd_data;
wire                     rd_en_internal;
wire [17:0]              bram_rd_data_tmp_raw;
wire [7:0]               bram_rd_data_tmp;


reg [7:0] rd_data3r;
reg [7:0] rd_data5r_t1, rd_data5r_t2, rd_data5r;
reg [7:0] rd_data6r;
reg [7:0] rd_data9r;
reg [7:0] uram_rd_data_r_reg_3;
reg [7:0] uram_rd_data_r_reg_4_t1;
reg [7:0] uram_rd_data_r_reg_4_t2;
reg [7:0] uram_rd_data_r_reg_4;
reg [7:0] uram_rd_data_r_reg_5_t1;
reg [7:0] uram_rd_data_r_reg_5_t2;
reg [7:0] uram_rd_data_r_reg_5;
reg [7:0] uram_rd_data_r_reg_6_t1;
reg [7:0] uram_rd_data_r_reg_6_t2;
reg [7:0] uram_rd_data_r_reg_6_t3;
reg [7:0] uram_rd_data_r_reg_6;
reg [7:0] uram_rd_data_r_reg_7_t1;
reg [7:0] uram_rd_data_r_reg_7_t2;
reg [7:0] uram_rd_data_r_reg_7_t3;
reg [7:0] uram_rd_data_r_reg_7_t4;
reg [7:0] uram_rd_data_r_reg_7_t5;
reg [7:0] uram_rd_data_r_reg_7;
reg [7:0] uram_rd_data_r_reg_8_t1;
reg [7:0] uram_rd_data_r_reg_8_t2;
reg [7:0] uram_rd_data_r_reg_8_t3;
reg [7:0] uram_rd_data_r_reg_8_t4;
reg [7:0] uram_rd_data_r_reg_8_t5;
reg [7:0] uram_rd_data_r_reg_8;
reg [7:0] uram_rd_data_r_reg_9_t1;
reg [7:0] uram_rd_data_r_reg_9_t2;
reg [7:0] uram_rd_data_r_reg_9_t3;
reg [7:0] uram_rd_data_r_reg_9_t4;
reg [7:0] uram_rd_data_r_reg_9_t5;
reg [7:0] uram_rd_data_r_reg_9_t6;
reg [7:0] uram_rd_data_r_reg_9;

always@(posedge clk) begin
  bram_data1r             <= bram_data1;
  bram_data2r             <= bram_data2;
  bram_data3r             <= bram_data3;
  bram_data4r             <= bram_data4;
  bram_data5r             <= bram_data5;
  bram_data6r             <= bram_data6;
  bram_data7r             <= bram_data7;
  bram_data8r             <= bram_data8;
  bram_data9r             <= bram_data9;
  uram_rd_data_r_reg_3    <= uram_rd_data_r[23:16];
  uram_rd_data_r_reg_4_t1 <= uram_rd_data_r[31:24];
  uram_rd_data_r_reg_4_t2 <= uram_rd_data_r_reg_4_t1;
  uram_rd_data_r_reg_4    <= uram_rd_data_r_reg_4_t2;
  uram_rd_data_r_reg_5_t1 <= uram_rd_data_r[39:32];
  uram_rd_data_r_reg_5_t2 <= uram_rd_data_r_reg_5_t1;
  uram_rd_data_r_reg_5    <= uram_rd_data_r_reg_5_t2;
  uram_rd_data_r_reg_6_t1 <= uram_rd_data_r[47:40];
  uram_rd_data_r_reg_6_t2 <= uram_rd_data_r_reg_6_t1;
  uram_rd_data_r_reg_6_t3 <= uram_rd_data_r_reg_6_t2;
  uram_rd_data_r_reg_6    <= uram_rd_data_r_reg_6_t3;
  uram_rd_data_r_reg_7_t1 <= uram_rd_data_r[55:48];
  uram_rd_data_r_reg_7_t2 <= uram_rd_data_r_reg_7_t1;
  uram_rd_data_r_reg_7_t3 <= uram_rd_data_r_reg_7_t2;
  uram_rd_data_r_reg_7_t4 <= uram_rd_data_r_reg_7_t3;
  uram_rd_data_r_reg_7_t5 <= uram_rd_data_r_reg_7_t4;
  uram_rd_data_r_reg_7    <= uram_rd_data_r_reg_7_t5;
  uram_rd_data_r_reg_8_t1 <= uram_rd_data_r[63:56];
  uram_rd_data_r_reg_8_t2 <= uram_rd_data_r_reg_8_t1;
  uram_rd_data_r_reg_8_t3 <= uram_rd_data_r_reg_8_t2;
  uram_rd_data_r_reg_8_t4 <= uram_rd_data_r_reg_8_t3;
  uram_rd_data_r_reg_8_t5 <= uram_rd_data_r_reg_8_t4;
  uram_rd_data_r_reg_8    <= uram_rd_data_r_reg_8_t5;
  uram_rd_data_r_reg_9_t1 <= uram_rd_data_r[71:64];
  uram_rd_data_r_reg_9_t2 <= uram_rd_data_r_reg_9_t1;
  uram_rd_data_r_reg_9_t3 <= uram_rd_data_r_reg_9_t2;
  uram_rd_data_r_reg_9_t4 <= uram_rd_data_r_reg_9_t3;
  uram_rd_data_r_reg_9_t5 <= uram_rd_data_r_reg_9_t4;
  uram_rd_data_r_reg_9_t6 <= uram_rd_data_r_reg_9_t5;
  uram_rd_data_r_reg_9    <= uram_rd_data_r_reg_9_t6;
end

//////////////////////// optional register /////////////////
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
//////////////////////////////////////////////////////////



//delay ce_tmp twice to align with the BRAM/URAM reading
always@(posedge clk) begin
  if (rst) begin
    ce_a0     <= 3'b000;
    ce_a0_r1  <= 3'b000;
    ce_a0_r2  <= 3'b000;
    ce_a1     <= 3'b000;
    ce_a1_r1  <= 3'b000;
    ce_a1_r2  <= 3'b000;
    ce_a2     <= 3'b000;
  end else begin
    ce_a0    <= ce_tmp;
    ce_a0_r1 <= ce_a0;
    ce_a0_r2 <= ce_a0_r1;
    ce_a1    <= ce_a0_r2;
    ce_a1_r1 <= ce_a1;
    ce_a1_r2 <= ce_a1_r1;
    ce_a2    <= ce_a1_r2;
  end
end


//URAM instantiation RD
(* dont_touch = "true" *)	URAM288 #(.IREG_PRE_A("TRUE"),.IREG_PRE_B("TRUE"),.OREG_A("TRUE"),.OREG_B("TRUE"),
			.CASCADE_ORDER_A(CASCADE_ORDER_A), .CASCADE_ORDER_B("NONE"), .REG_CAS_A("TRUE"), .SELF_MASK_A(11'h7fc), .SELF_MASK_B(11'h7ff), .SELF_ADDR_A(SELF_ADDR_A))
		uram_inst_rd(
			// dataflow
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

			// clocking and control
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
	                // horizontal links
	                .DOUTADOUT(bram_rd_data_tmp_raw[15:0]), 
	                .DOUTPADOUTP(bram_rd_data_tmp_raw[17:16]), 
	                .DINBDIN(bram_wr_data[15:0]), 
	                .DINPBDINP(bram_wr_data[17:16]), 
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

//pc_o_valid
always@(posedge clk) begin
  if (rst) begin
    pc_o_valid_tmp     <= 1'b0;
    pc_o_valid_tmp_r   <= 1'b0;
    pc_o_valid_tmp_r2  <= 1'b0;
    pc_o_valid_tmp_r3  <= 1'b0;
    pc_o_valid_tmp_r4  <= 1'b0;
    pc_o_valid_tmp_r5  <= 1'b0;
    pc_o_valid_tmp_r6  <= 1'b0;
    pc_o_valid_tmp_r7  <= 1'b0;
    pc_o_valid_tmp_r8  <= 1'b0;
    pc_o_valid_tmp_r9  <= 1'b0;
    pc_o_valid_tmp_r10 <= 1'b0;
    pc_o_valid_tmp_r11 <= 1'b0;
    pc_o_valid_tmp_r12 <= 1'b0;
  end else begin
    pc_o_valid_tmp     <= ce_tmp[0];
    pc_o_valid_tmp_r   <= pc_o_valid_tmp;
    pc_o_valid_tmp_r2  <= pc_o_valid_tmp_r;
    pc_o_valid_tmp_r3  <= pc_o_valid_tmp_r2;
    pc_o_valid_tmp_r4  <= pc_o_valid_tmp_r3;
    pc_o_valid_tmp_r5  <= pc_o_valid_tmp_r4;
    pc_o_valid_tmp_r6  <= pc_o_valid_tmp_r5;
    pc_o_valid_tmp_r7  <= pc_o_valid_tmp_r6;
    pc_o_valid_tmp_r8  <= pc_o_valid_tmp_r7;
    pc_o_valid_tmp_r9  <= pc_o_valid_tmp_r8;
    pc_o_valid_tmp_r10 <= pc_o_valid_tmp_r9;
    pc_o_valid_tmp_r11 <= pc_o_valid_tmp_r10;
    pc_o_valid_tmp_r12 <= pc_o_valid_tmp_r11;
  end
end
//optional register
  assign rd_en_internal = pc_o_valid_tmp_r8;
generate if (NUMBER_OF_REG == 1) begin : wr_en1

  always@(posedge clk) begin
    if (rst) begin
      pc_o_valid_tmp_r13 <= 1'b0;
      bram_wr_en        <= 1'b0;
    end else begin
      pc_o_valid_tmp_r13 <= pc_o_valid_tmp_r12;
      bram_wr_en         <= pc_o_valid_tmp_r13;
    end
  end

  always@(posedge clk) begin
    pout_reg1 <= pout[8];
    pout_reg  <= pout_reg1;
    bram_rd_data_r1 <= bram_rd_data_tmp;
    bram_rd_data_r <= bram_rd_data_r1;
  end
end endgenerate

generate if (NUMBER_OF_REG == 2) begin : wr_en2
  always@(posedge clk) begin
    if (rst) begin
      pc_o_valid_tmp_r13 <= 1'b0;
      pc_o_valid_tmp_r14 <= 1'b0;
      bram_wr_en         <= 1'b0;
    end else begin
      pc_o_valid_tmp_r13 <= pc_o_valid_tmp_r12;
      pc_o_valid_tmp_r14 <= pc_o_valid_tmp_r13;
      bram_wr_en         <= pc_o_valid_tmp_r14;
    end
  end

  always@(posedge clk) begin
    pout_reg1 <= pout[8];
    pout_reg2 <= pout_reg1;
    pout_reg  <= pout_reg2;
    bram_rd_data_r1 <= bram_rd_data_tmp;
    bram_rd_data_r2 <= bram_rd_data_r1;
    bram_rd_data_r <= bram_rd_data_r2;
  end
end endgenerate

generate if (NUMBER_OF_REG == 3) begin : wr_en3
  always@(posedge clk) begin
    if (rst) begin
      pc_o_valid_tmp_r13 <= 1'b0;
      pc_o_valid_tmp_r14 <= 1'b0;
      pc_o_valid_tmp_r15 <= 1'b0;
      bram_wr_en         <= 1'b0;
    end else begin
      pc_o_valid_tmp_r13 <= pc_o_valid_tmp_r12;
      pc_o_valid_tmp_r14 <= pc_o_valid_tmp_r13;
      pc_o_valid_tmp_r15 <= pc_o_valid_tmp_r14;
      bram_wr_en         <= pc_o_valid_tmp_r15;
    end
  end

  always@(posedge clk) begin
    pout_reg1 <= pout[8];
    pout_reg2 <= pout_reg1;
    pout_reg3 <= pout_reg2;
    pout_reg  <= pout_reg3;
    bram_rd_data_r1 <= bram_rd_data_tmp;
    bram_rd_data_r2 <= bram_rd_data_r1;
    bram_rd_data_r3 <= bram_rd_data_r2;
    bram_rd_data_r  <= bram_rd_data_r3;
  end
end endgenerate

////////////////////////////////////////////////////////
//internal rden and rdaddr

always@(posedge clk) begin
  if (rst) begin
    bram_rd_addr_internal <= {A_W{1'b0}};
  end else begin
    if (rd_en_internal) begin
      bram_rd_addr_internal <= bram_rd_addr_internal + 14'd16;  
    end
  end
end

// actual bram rd addr
always@(posedge clk) begin
  if (rst) bram_rd_addr <= {A_W{1'b0}};
  else begin
    if (bram_rd_en_external)  bram_rd_addr <= bram_rd_addr_external;
    else bram_rd_addr <= bram_rd_addr_internal;
  end
end

always@(posedge clk) begin
  bram_wr_data <= {10'd0, (bram_rd_data_r[7:0] + pout_reg[7:0])};
end

always@(posedge clk) begin
  if (rst) begin
    bram_wr_addr <= {A_W{1'b0}};
  end else begin
    if (bram_wr_en) begin
      bram_wr_addr <= bram_wr_addr + 14'd16;  
    end
  end
end

assign bram_rd_data_tmp = bram_rd_data_tmp_raw[7:0];
assign bram_rd_data = bram_rd_data_r;


assign p[0] = 8'd0;
assign ce_shift = {ce_a2,ce_a1,ce_a0};
assign Ain[0] = uram_rd_data_r[7:0];
assign Ain[1] = uram_rd_data_r[15:8];
assign Ain[2] = uram_rd_data_r_reg_3;
assign Ain[3] = uram_rd_data_r_reg_4;
assign Ain[4] = uram_rd_data_r_reg_5;
assign Ain[5] = uram_rd_data_r_reg_6;
assign Ain[6] = uram_rd_data_r_reg_7;
assign Ain[7] = uram_rd_data_r_reg_8;
assign Ain[8] = uram_rd_data_r_reg_9;
assign Bin[0] = bram_data1r;
assign Bin[1] = bram_data2r;
assign Bin[2] = bram_data3r;
assign Bin[3] = bram_data4r;
assign Bin[4] = bram_data5r;
assign Bin[5] = bram_data6r;
assign Bin[6] = bram_data7r;
assign Bin[7] = bram_data8r;
assign Bin[8] = bram_data9r;
genvar i;
generate
for (i=0; i<=8; i=i+1) begin : dsp_chain
    fane_mac #(
        .EXP_WIDTH(4),
        .MANT_WIDTH(3)
    ) dsp_inst (
        .clk              (clk),
        .rst_n            (~rst),
        .ce               (ce),
        .ce_a_1           (ce_shift[i]),
        .ce_a_2           (ce_shift[i]),
        .ce_b_1           (ce_shift[i]),
        .ce_b_2           (ce_shift[i]),
        .mul_a            (Ain[i]),
        .mul_b            (Bin[i]),
        .cascade_sum_in   (p[i]),
        .acc_out          (pout[i]),
        .cascade_mula_out (cascade_mula[i]),
        .cascade_mulb_out (cascade_mulb[i])
    );
    assign p[i+1] = pout[i];
end
endgenerate

endmodule
