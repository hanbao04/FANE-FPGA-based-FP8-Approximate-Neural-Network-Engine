module dsp_conv_top #(
        parameter KERN_SZ = 3,
        parameter IMG_W = 4,
        parameter IMG_D = 6,
	parameter A_W = 14,
	parameter M_W = 18,
	parameter D_W = 48,
        parameter CASCADE_ORDER_A_RDURAM = "NONE",
        parameter CASCADE_ORDER_A_WRURAM = "NONE",
        parameter NUMBER_OF_REG = 1,
        parameter ADD_PIPE = 2,

        parameter WB_PIPE = 2,
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
input [URAM_A_W-1:0] uram2_rd_addr_external,
input read_en_external,
output [URAM_D_W-1:0] uram2_rd_data,
input ld_new_kernel,
input [A_W-1:0] krnl_bram1_wraddr,
input [M_W-1:0] krnl_bram1_wrdata,
input krnl_bram1_wren,
input [A_W-1:0] krnl_bram2_wraddr,
input [M_W-1:0] krnl_bram2_wrdata,
input krnl_bram2_wren,

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

localparam NO_ITR_W = IMG_W - KERN_SZ + 1; // number of iterations for width
localparam NO_ITR_D = IMG_D - KERN_SZ + 1; // one active FP8 value per 16-bit slot
//state machine for controlling clock enable image reading
localparam RST_s       = 6'b000001;
localparam HIGH1_s     = 6'b000010;
localparam HIGH2_s     = 6'b000100;
localparam HIGH3_s     = 6'b001000;
localparam DONE_s      = 6'b010000;
localparam INIT_DONE_s = 6'b100000;

//state machine for controlling clock enable kernel reading
localparam k_RST_s   = 10'b0000000001;
localparam k_HIGH1_s = 10'b0000000010;
localparam k_HIGH2_s = 10'b0000000100;
localparam k_HIGH3_s = 10'b0000001000;
localparam k_HIGH4_s = 10'b0000010000;
localparam k_HIGH5_s = 10'b0000100000;
localparam k_HIGH6_s = 10'b0001000000;
localparam k_HIGH7_s = 10'b0010000000;
localparam k_HIGH8_s = 10'b0100000000;
localparam k_HIGH9_s = 10'b1000000000;

reg [5:0]                p_state;
reg [5:0]                n_state;
reg [9:0]                k_state;
reg                      read_en_from_ce_state_machine;
reg [$clog2(NO_ITR_W):0] rem_img_sz_w;
reg [$clog2(NO_ITR_D):0] rem_img_sz_d;
reg [URAM_D_W-1:0]       uram_rd_data_r; 
reg [URAM_D_W-1:0]       uram_rd_data_r1; 
reg [URAM_D_W-1:0]       uram_rd_data_r2; 
reg                      ce_dsp;
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
reg                      pc_o_valid_tmp_r16;
reg                      pc_o_valid_tmp_r17;
reg                      pc_o_valid_tmp_r18;
reg                      pc_o_valid_tmp_r19;
reg                      pc_o_valid_tmp_r20;
reg                      pc_o_valid_tmp_r21;
reg [A_W-1:0]            rdaddr_b;
reg                      uram2_wr_en;
reg                      data_valid;
reg                      data_valid_tog;
reg  [URAM_D_W-1:0]      uram2_wr_data;
reg                      ce_b_tmp;
reg  [URAM_A_W-1:0]      uram2_rd_addr; 
reg  [URAM_A_W-1:0]      rd_addr_temp; 
wire [31:0]             writeback_new_fp8;
wire [31:0]             writeback_sum_fp8;
wire [63:0]             writeback_packed;
reg [URAM_A_W-1:0]      write_addr_r2;
reg [URAM_D_W-1:0]      uram2_rd_data_r;
 

wire [URAM_A_W-1:0]      uram1_rd_addr;
wire [A_W-1:0]           b1_wr_addr;
wire                     b1_wr_en;
wire [A_W-1:0]           b2_wr_addr;
wire                     b2_wr_en;
wire [A_W-1:0]           b3_wr_addr;
wire                     b3_wr_en;
wire [A_W-1:0]           b1_rd_addr;
wire [A_W-1:0]           b2_rd_addr;
wire [A_W-1:0]           b3_rd_addr;
wire                     init_done;
wire [URAM_D_W-1:0]      uram_rd_data;
wire [URAM_D_W-1:0]      uram_rd_data_linebuf;
wire [15:0]              data_out_conv1; 
wire [15:0]              data_out_conv2;
wire [URAM_D_W-1:0]      uram2_rd_data_tmp;
wire	[22:0]	CAS_OUT_ADDR_LOCAL;
wire	[8:0]	CAS_OUT_BWE_LOCAL;		
wire	[0:0]	CAS_OUT_DBITERR_LOCAL;
wire	[71:0]	CAS_OUT_DIN_LOCAL;
wire	[71:0]	CAS_OUT_DOUT_LOCAL;		
wire	[0:0]	CAS_OUT_EN_LOCAL;		
wire	[0:0]	CAS_OUT_RDACCESS_LOCAL;
wire	[0:0]	CAS_OUT_RDB_WR_LOCAL;
wire	[0:0]	CAS_OUT_SBITERR_LOCAL;	

addr_gen #(
         .IMG_W        (IMG_W)
        ,.IMG_D        (IMG_D)
	,.URAM_A_W     (URAM_A_W)
	,.BRAM_A_W     (A_W)
        ,.NUMBER_OF_REG (NUMBER_OF_REG)
) addr_gen_inst (
         .clk          (clk)
        ,.rst          (rst)
        ,.ce           (ce)
        ,.read_en_from_ce_state_machine (read_en_from_ce_state_machine)
        ,.uram_rd_addr (uram1_rd_addr)
        ,.b1_wr_addr   (b1_wr_addr)
        ,.b1_wr_en     (b1_wr_en)
        ,.b2_wr_addr   (b2_wr_addr)
        ,.b2_wr_en     (b2_wr_en)
        ,.b3_wr_addr   (b3_wr_addr)
        ,.b3_wr_en     (b3_wr_en)
        ,.b1_rd_addr   (b1_rd_addr)
        ,.b2_rd_addr   (b2_rd_addr)
        ,.b3_rd_addr   (b3_rd_addr)
        ,.init_done    (init_done)
);

//state machine reading
always@(posedge clk) begin
  if (rst) p_state <= RST_s;
  else     p_state <= n_state;
end

always@(*) begin
  case (p_state)
    RST_s : begin 
              if (init_done) n_state <= HIGH1_s;
              else n_state <= RST_s;
            end
    HIGH1_s : n_state <= HIGH2_s;
    HIGH2_s : n_state <= HIGH3_s;
    HIGH3_s : begin
                if (rem_img_sz_w == 0 && rem_img_sz_d == 1)
                  n_state <= DONE_s;
                else if (rem_img_sz_w != 0)
                  n_state <= HIGH3_s;
                else
                  n_state <= HIGH1_s;
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
  if (rst) rem_img_sz_w <= 'b0;
  else begin
    if (p_state[1]) rem_img_sz_w <= NO_ITR_W;
    else if (p_state[2] && n_state[3]) rem_img_sz_w <= rem_img_sz_w - 1;
    else if (p_state[3] && n_state[3]) rem_img_sz_w <= rem_img_sz_w - 1;
  end
end

 always@(posedge clk) begin
  if (rst) rem_img_sz_d <= 'b0;
  else begin
    if (p_state[0]) rem_img_sz_d <= NO_ITR_D;
    else if (p_state[3] && rem_img_sz_w == 0) rem_img_sz_d <= rem_img_sz_d - 1;
  end
end 

always@(posedge clk) begin
    read_en_from_ce_state_machine <= (n_state[1] || n_state[2] || n_state[3]);
end

always@(posedge clk) begin
  if (p_state[1] || p_state[2] || p_state[3])
    ce_dsp <= 1'b1;
  else
    ce_dsp <= 1'b0;
end


///////////////////////////////// optinal register /////////////////
generate if (NUMBER_OF_REG == 1) begin : option_1
  always@(posedge clk) begin
    uram_rd_data_r <= uram_rd_data;
  end
end endgenerate

generate if (NUMBER_OF_REG == 2) begin : option_2
  always@(posedge clk) begin
    uram_rd_data_r1 <= uram_rd_data;
    uram_rd_data_r  <= uram_rd_data_r1;
  end
end endgenerate

generate if (NUMBER_OF_REG == 3) begin : option_3
  always@(posedge clk) begin
    uram_rd_data_r1 <= uram_rd_data;
    uram_rd_data_r2 <= uram_rd_data_r1;
    uram_rd_data_r  <= uram_rd_data_r2;
  end
end endgenerate
////////////////////////////////////////////////////////////////////
// With the chip wrapper's NUMBER_OF_REG=3 setting, the BRAM write address
// path is one cycle shorter than uram_rd_data_r. Select r2 so input[n] is
// written to address[n] instead of duplicating input[0] and dropping input[11].
// Preserve the original selection for the other supported pipeline depths.
assign uram_rd_data_linebuf = (NUMBER_OF_REG == 3) ? uram_rd_data_r2
                                                   : uram_rd_data_r;

//URAM instantiation RD
// image ram

	(* dont_touch = "true" *)	URAM288 #(.IREG_PRE_A("TRUE"),.IREG_PRE_B("TRUE"),.OREG_A("TRUE"),.OREG_B("TRUE"),
			.CASCADE_ORDER_A(CASCADE_ORDER_A_RDURAM), .CASCADE_ORDER_B("NONE"), .REG_CAS_A("TRUE"), .SELF_MASK_A(11'h7fe), .SELF_MASK_B(11'h7ff), .SELF_ADDR_A(11'h0))

		//uram_inst_rd(
		uram_inst_wr(
			// dataflow
			.RDB_WR_B(1'b0),
			.BWE_B({9{1'b1}}),
			.ADDR_B(uram1_rd_addr),
			.DOUT_B(uram_rd_data),
			.RDB_WR_A(uram1_wr_en),
			.BWE_A({9{1'b1}}),
			.ADDR_A(uram1_wr_addr),
			.DIN_A(uram1_wr_data),
			.DOUT_A(),

	                .CAS_OUT_ADDR_A	   (CAS_OUT_ADDR_LOCAL),    		
                        .CAS_OUT_BWE_A	   (CAS_OUT_BWE_LOCAL),       
                        .CAS_OUT_DBITERR_A (CAS_OUT_DBITERR_LOCAL),
                        .CAS_OUT_DIN_A	   (CAS_OUT_DIN_LOCAL),       
                        .CAS_OUT_DOUT_A	   (CAS_OUT_DOUT_LOCAL),       
                        .CAS_OUT_EN_A	   (CAS_OUT_EN_LOCAL),       
                        .CAS_OUT_RDACCESS_A(CAS_OUT_RDACCESS_LOCAL),
                        .CAS_OUT_RDB_WR_A  (CAS_OUT_RDB_WR_LOCAL),
                        .CAS_OUT_SBITERR_A (CAS_OUT_SBITERR_LOCAL),
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

//URAM instantiation WR
// image ram
	(* dont_touch = "true" *)	URAM288 #(.IREG_PRE_A("TRUE"),.IREG_PRE_B("TRUE"),.OREG_A("TRUE"),.OREG_B("TRUE"),
			.CASCADE_ORDER_A(CASCADE_ORDER_A_WRURAM), .CASCADE_ORDER_B("NONE"), .REG_CAS_A("TRUE"), .SELF_MASK_A(11'h7fe), .SELF_MASK_B(11'h7ff), .SELF_ADDR_A(11'h1))
		//uram_inst_wr(
		uram_inst_rd(
			// dataflow
			.RDB_WR_B(uram2_wr_en),
			.BWE_B({9{1'b1}}),
			.ADDR_B(uram2_rd_addr),
                        .DIN_B(uram2_wr_data),
			.DOUT_B(uram2_rd_data_tmp),
			
	                .CAS_OUT_ADDR_A	   (CAS_OUT_ADDR),    		
                        .CAS_OUT_BWE_A	   (CAS_OUT_BWE),       
                        .CAS_OUT_DBITERR_A (CAS_OUT_DBITERR),
                        .CAS_OUT_DIN_A	   (CAS_OUT_DIN),       
                        .CAS_OUT_DOUT_A	   (CAS_OUT_DOUT),       
                        .CAS_OUT_EN_A	   (CAS_OUT_EN),       
                        .CAS_OUT_RDACCESS_A(CAS_OUT_RDACCESS),
                        .CAS_OUT_RDB_WR_A  (CAS_OUT_RDB_WR),
                        .CAS_OUT_SBITERR_A (CAS_OUT_SBITERR),
                        .CAS_IN_ADDR_A	   (CAS_OUT_ADDR_LOCAL),       
                        .CAS_IN_BWE_A	   (CAS_OUT_BWE_LOCAL),       
                        .CAS_IN_DBITERR_A  (CAS_OUT_DBITERR_LOCAL),
                        .CAS_IN_DIN_A	   (CAS_OUT_DIN_LOCAL),       
                        .CAS_IN_DOUT_A	   (CAS_OUT_DOUT_LOCAL),       
                        .CAS_IN_EN_A	   (CAS_OUT_EN_LOCAL), 
                        .CAS_IN_RDACCESS_A (CAS_OUT_RDACCESS_LOCAL),
                        .CAS_IN_RDB_WR_A   (CAS_OUT_RDB_WR_LOCAL),       	
	                .CAS_IN_SBITERR_A  (CAS_OUT_SBITERR_LOCAL),

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

// Each MAC stage now takes ADD_PIPE extra cycles, so the 3x3 window sum
// (fp_acc[9] -> data_out) appears 9*ADD_PIPE cycles later than in the
// single-cycle design. data_valid, the column counters and the writeback FIFO
// are all driven from this valid chain, so delaying its input retimes them.
localparam integer CHAIN_EXTRA = 9*ADD_PIPE;
wire p_state3_aligned;
generate if (CHAIN_EXTRA == 0) begin : vdly_none
  assign p_state3_aligned = p_state[3];
end else begin : vdly_sr
  reg [CHAIN_EXTRA-1:0] vdly;
  always@(posedge clk) begin
    if (rst) vdly <= {CHAIN_EXTRA{1'b0}};
    else     vdly <= {vdly[CHAIN_EXTRA-2:0], p_state[3]};
  end
  assign p_state3_aligned = vdly[CHAIN_EXTRA-1];
end endgenerate

//pc_o_valid
always@(posedge clk) begin
  if (rst) begin
    pc_o_valid_tmp     <= 'b0;
    pc_o_valid_tmp_r   <= 'b0;
    pc_o_valid_tmp_r2  <= 'b0;
    pc_o_valid_tmp_r3  <= 'b0;
    pc_o_valid_tmp_r4  <= 'b0;
    pc_o_valid_tmp_r5  <= 'b0;
    pc_o_valid_tmp_r6  <= 'b0;
    pc_o_valid_tmp_r7  <= 'b0;
    pc_o_valid_tmp_r8  <= 'b0;
    pc_o_valid_tmp_r9  <= 'b0;
    pc_o_valid_tmp_r10 <= 'b0;
    pc_o_valid_tmp_r11 <= 'b0;
    pc_o_valid_tmp_r12 <= 'b0;
    pc_o_valid_tmp_r13 <= 'b0;
    pc_o_valid_tmp_r14 <= 'b0;
    pc_o_valid_tmp_r15 <= 'b0;
    pc_o_valid_tmp_r16 <= 'b0;
  end else begin
    pc_o_valid_tmp     <= p_state3_aligned;
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
    pc_o_valid_tmp_r13 <= pc_o_valid_tmp_r12;
    pc_o_valid_tmp_r14 <= pc_o_valid_tmp_r13;
    pc_o_valid_tmp_r15 <= pc_o_valid_tmp_r14;
    pc_o_valid_tmp_r16 <= pc_o_valid_tmp_r15;
  end
end

generate if (NUMBER_OF_REG == 1) begin : wr_en1
  always@(posedge clk) begin
    if (rst) begin
      data_valid <= 1'b0;
    end else begin
      data_valid <= pc_o_valid_tmp_r16;
    end
  end
end endgenerate

generate if (NUMBER_OF_REG == 2) begin : wr_en2
  always@(posedge clk) begin
    if (rst) begin
      pc_o_valid_tmp_r17 <= 1'b0;
      pc_o_valid_tmp_r18 <= 1'b0;
      data_valid        <= 1'b0;
    end else begin
      pc_o_valid_tmp_r17 <= pc_o_valid_tmp_r16;
      pc_o_valid_tmp_r18 <= pc_o_valid_tmp_r17;
      data_valid        <= pc_o_valid_tmp_r18;
    end
  end
end endgenerate

generate if (NUMBER_OF_REG == 3) begin : wr_en3
  always@(posedge clk) begin
    if (rst) begin
      pc_o_valid_tmp_r17 <= 1'b0;
      pc_o_valid_tmp_r18 <= 1'b0;
      pc_o_valid_tmp_r19 <= 1'b0;
      pc_o_valid_tmp_r20 <= 1'b0;
      data_valid        <= 1'b0;
    end else begin
      pc_o_valid_tmp_r17 <= pc_o_valid_tmp_r16;
      pc_o_valid_tmp_r18 <= pc_o_valid_tmp_r17;
      pc_o_valid_tmp_r19 <= pc_o_valid_tmp_r18;
      pc_o_valid_tmp_r20 <= pc_o_valid_tmp_r19;
      // The NUMBER_OF_REG=3 MAC result is valid three cycles earlier than the
      // original r20 tap. r17 aligns data_valid with the complete 3x3 window.
      data_valid        <= pc_o_valid_tmp_r17;
    end
  end
end endgenerate

// Queue complete adjacent-column words, then carry data and address tags
// through the URAM read/FP8-add/write pipeline. A small queue absorbs changes
// in row packing phase without coupling old-result reads to MAC valid pulses.
localparam integer OUTPUT_COLUMNS = IMG_W - KERN_SZ + 1;
localparam integer WRITEBACK_FIFO_DEPTH = 4;
reg [31:0] writeback_fifo [0:WRITEBACK_FIFO_DEPTH-1];
reg [1:0] fifo_write_ptr;
reg [1:0] fifo_read_ptr;
reg [2:0] writeback_fifo_count;
reg [15:0] first_column_fp8;
// The decoded end-of-row condition belongs in the counter's D logic. A
// binary-counter transition can briefly glitch that decode between clocks.
(* extract_reset = "no" *) reg [$clog2(OUTPUT_COLUMNS):0] output_column;
wire [15:0] current_column_fp8 = {data_out_conv2[7:0], data_out_conv1[7:0]};
wire last_output_column = output_column == OUTPUT_COLUMNS-1;
wire packet_valid = data_valid && (data_valid_tog || last_output_column);
wire [31:0] packet_fp8 = data_valid_tog ?
    {first_column_fp8, current_column_fp8} : {current_column_fp8, 16'd0};
wire read_issue = !rst && ce && !read_en_external && !uram2_wr_en &&
                  writeback_fifo_count != 0;
wire fifo_space = writeback_fifo_count < WRITEBACK_FIFO_DEPTH || read_issue;
wire fifo_push = packet_valid && fifo_space;

reg [2:0] read_valid_pipe;
reg [31:0] read_data_r0, read_data_r1, read_data_r2;
reg [URAM_A_W-1:0] read_addr_r0, read_addr_r1, read_addr_r2;
reg sum_valid;
wire               wb_valid;
wire [URAM_A_W-1:0] wb_addr;
reg [URAM_D_W-1:0] sum_data;
reg [URAM_A_W-1:0] sum_addr;

always @(posedge clk) begin
  if (rst) begin
    data_valid_tog <= 1'b0;
    first_column_fp8 <= 16'd0;
    output_column <= 0;
  end else if (data_valid) begin
    if (last_output_column) output_column <= 0;
    else output_column <= output_column + 1'b1;
    if (data_valid_tog || last_output_column) begin
      data_valid_tog <= 1'b0;
    end else begin
      first_column_fp8 <= current_column_fp8;
      data_valid_tog <= 1'b1;
    end
  end
end

always @(posedge clk) begin
  if (rst) begin
    fifo_write_ptr <= 0;
    fifo_read_ptr <= 0;
    writeback_fifo_count <= 0;
    rd_addr_temp <= 0;
  end else begin
    case ({fifo_push, read_issue})
      2'b10: writeback_fifo_count <= writeback_fifo_count + 1'b1;
      2'b01: writeback_fifo_count <= writeback_fifo_count - 1'b1;
      default: writeback_fifo_count <= writeback_fifo_count;
    endcase
    if (fifo_push) begin
      writeback_fifo[fifo_write_ptr] <= packet_fp8;
      fifo_write_ptr <= fifo_write_ptr + 1'b1;
    end
    if (read_issue) begin
      fifo_read_ptr <= fifo_read_ptr + 1'b1;
      rd_addr_temp <= rd_addr_temp + 'd16;
    end
  end
end

// IREG_PRE_B + the memory stage + OREG_B: consume a read response three
// clocks after its request. The FP8 operands and word address take the same
// three stages. A further write stage keeps read/write requests interleaved.
always @(posedge clk) begin
  if (rst) begin
    read_valid_pipe <= 3'b000;
    sum_valid <= 1'b0;
    uram2_wr_en <= 1'b0;
    write_addr_r2 <= 0;
    sum_addr <= 0;
    sum_data <= 0;
    uram2_wr_data <= 0;
  end else begin
    read_valid_pipe <= {read_valid_pipe[1:0], read_issue};
    if (read_issue) begin
      read_data_r0 <= writeback_fifo[fifo_read_ptr];
      read_addr_r0 <= rd_addr_temp;
    end
    read_data_r1 <= read_data_r0;
    read_data_r2 <= read_data_r1;
    read_addr_r1 <= read_addr_r0;
    read_addr_r2 <= read_addr_r1;
    sum_valid <= wb_valid;
    if (wb_valid) begin
      sum_data <= {8'd0, writeback_packed};
      sum_addr <= wb_addr;
    end
    uram2_wr_en <= sum_valid;
    uram2_wr_data <= sum_data;
    write_addr_r2 <= sum_addr;
  end
end

always @(*) begin
  if (uram2_wr_en) uram2_rd_addr = write_addr_r2;
  else if (read_en_external) uram2_rd_addr = uram2_rd_addr_external;
  else uram2_rd_addr = rd_addr_temp;
end

// Valid/address tags travel alongside the WB_PIPE register ranks inside the
// pipelined adders, so they reach sum_data in the same cycle as the sum.
generate if (WB_PIPE == 0) begin : wb_tag_none
  assign wb_valid = read_valid_pipe[2];
  assign wb_addr  = read_addr_r2;
end else begin : wb_tag_sr
  reg [WB_PIPE-1:0]  wb_v_sr;
  reg [URAM_A_W-1:0] wb_a_sr [0:WB_PIPE-1];
  integer wbk;
  always @(posedge clk) begin
    if (rst) wb_v_sr <= {WB_PIPE{1'b0}};
    else     wb_v_sr <= {wb_v_sr[WB_PIPE-1:0], read_valid_pipe[2]};
    wb_a_sr[0] <= read_addr_r2;
    for (wbk = 1; wbk < WB_PIPE; wbk = wbk + 1) wb_a_sr[wbk] <= wb_a_sr[wbk-1];
  end
  assign wb_valid = wb_v_sr[WB_PIPE-1];
  assign wb_addr  = wb_a_sr[WB_PIPE-1];
end endgenerate

assign writeback_new_fp8 = read_data_r2;
genvar writeback_lane;
generate
  for (writeback_lane = 0; writeback_lane < 4; writeback_lane = writeback_lane + 1) begin : fp8_writeback
    fp8_adder_pipe #(.e(4), .m(3), .PIPE(WB_PIPE)) u_adder (
      .clk(clk),
      .en(1'b1),
      .a(uram2_rd_data_tmp[16*writeback_lane +: 8]),
      .b(writeback_new_fp8[8*writeback_lane +: 8]),
      .result(writeback_sum_fp8[8*writeback_lane +: 8])
    );
    assign writeback_packed[16*writeback_lane +: 16] =
      {8'd0, writeback_sum_fp8[8*writeback_lane +: 8]};
  end
endgenerate

always @(posedge clk) uram2_rd_data_r <= uram2_rd_data_tmp;
assign uram2_rd_data = uram2_rd_data_r;

`ifndef SYNTHESIS
always @(posedge clk) begin
  if (!rst && packet_valid && !fifo_space)
    $fatal(1, "Conv writeback FIFO overflow");
end
`endif

//kernel clock enable and addressing
always@(posedge clk) begin
  if (rst) begin
    k_state <= k_RST_s;
  end else begin
    case (k_state)
      k_RST_s : if (ld_new_kernel) k_state <= k_HIGH1_s;
      k_HIGH1_s : k_state <= k_HIGH2_s;
      k_HIGH2_s : k_state <= k_HIGH3_s;
      k_HIGH3_s : k_state <= k_HIGH4_s;
      k_HIGH4_s : k_state <= k_HIGH5_s;
      k_HIGH5_s : k_state <= k_HIGH6_s;
      k_HIGH6_s : k_state <= k_HIGH7_s;
      k_HIGH7_s : k_state <= k_HIGH8_s;
      k_HIGH8_s : k_state <= k_HIGH9_s;
      default : k_state <= k_RST_s;
    endcase
  end
end
//address generator
always@(posedge clk) begin
  if (rst) begin
    rdaddr_b <= 'b0;
  end else begin
    if ((k_state[0] && ld_new_kernel) || k_state[1] || k_state[2] || k_state[3] || k_state[4] || k_state[5] || k_state[6] || k_state[7] || k_state[8])
      rdaddr_b <= rdaddr_b + 'd16;
  end
end

always@(posedge clk) begin
  if (k_state[1] || k_state[2] || k_state[3] || k_state[4] || k_state[5] || k_state[6] || k_state[7] || k_state[8] || k_state[9])
    ce_b_tmp <= 1'b1;
  else
    ce_b_tmp <= 1'b0;
end

 (* dont_touch = "true" *) dsp_conv #(
	 .A_W (A_W)
	,.M_W (M_W)
	,.URAM_D_W (URAM_D_W)
	,.URAM_A_W (URAM_A_W)
        ,.NUMBER_OF_REG (NUMBER_OF_REG)
        ,.ADD_PIPE (ADD_PIPE)
)
conv1 (
    .clk        (clk)
   ,.rst        (rst)
   ,.ce         (ce)
   ,.ce_b_in    (ce_b_tmp)
   ,.ce_dsp     (ce_dsp)
   ,.knl_b_wraddr (krnl_bram1_wraddr)
   ,.knl_b_wrdata (krnl_bram1_wrdata)
   ,.knl_b_wren   (krnl_bram1_wren)
   ,.b1_wr_addr (b1_wr_addr) 
   ,.b1_wr_en   (b1_wr_en)
   ,.b2_wr_addr (b2_wr_addr)
   ,.b2_wr_en   (b2_wr_en)
   ,.b3_wr_addr (b3_wr_addr)
   ,.b3_wr_en   (b3_wr_en)
   ,.b1_rd_addr (b1_rd_addr)
   ,.b2_rd_addr (b2_rd_addr)
   ,.b3_rd_addr (b3_rd_addr)
   ,.rdaddr_b   (rdaddr_b) 
   ,.data_in    (uram_rd_data_linebuf[15:0])
   ,.data_out   (data_out_conv1)
);

//assign data_out_conv2 = 'b0;

 (* dont_touch = "true" *) dsp_conv #(
	 .A_W (A_W)
	,.M_W (M_W)
	,.URAM_D_W (URAM_D_W)
	,.URAM_A_W (URAM_A_W)
        ,.NUMBER_OF_REG (NUMBER_OF_REG)
        ,.ADD_PIPE (ADD_PIPE)
)
conv2 (
    .clk        (clk)
   ,.rst        (rst)
   ,.ce         (ce)
   ,.ce_b_in    (ce_b_tmp)
   ,.ce_dsp     (ce_dsp)
   ,.knl_b_wraddr (krnl_bram2_wraddr)
   ,.knl_b_wrdata (krnl_bram2_wrdata)
   ,.knl_b_wren   (krnl_bram2_wren)
   ,.b1_wr_addr (b1_wr_addr) 
   ,.b1_wr_en   (b1_wr_en)
   ,.b2_wr_addr (b2_wr_addr)
   ,.b2_wr_en   (b2_wr_en)
   ,.b3_wr_addr (b3_wr_addr)
   ,.b3_wr_en   (b3_wr_en)
   ,.b1_rd_addr (b1_rd_addr)
   ,.b2_rd_addr (b2_rd_addr)
   ,.b3_rd_addr (b3_rd_addr)
   ,.rdaddr_b   (rdaddr_b) 
   ,.data_in    (uram_rd_data_linebuf[31:16])
   ,.data_out   (data_out_conv2)
);

endmodule
