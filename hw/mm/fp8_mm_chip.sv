module fane_mm_chip #(
        parameter IMG_W = 4,
        parameter IMG_D = 6,
	parameter A_W = 14,
	parameter M_W = 18,
	parameter D_W = 48,
	parameter URAM_D_W = 72,
	parameter URAM_A_W = 23,
        parameter Y = 240
)
(
input clk,
input rst,
input ce,
input [URAM_A_W-1:0] uram1_wr_addr [Y],
input [URAM_D_W-1:0] uram1_wr_data [Y],
input uram1_wr_en [Y],
input [URAM_A_W-1:0] uram2_wr_addr [Y],
input [URAM_D_W-1:0] uram2_wr_data [Y],
input uram2_wr_en [Y],
input [URAM_A_W-1:0] uram3_wr_addr [Y],
input [URAM_D_W-1:0] uram3_wr_data [Y],
input uram3_wr_en [Y],
input [URAM_A_W-1:0] uram4_wr_addr [Y],
input [URAM_D_W-1:0] uram4_wr_data [Y],
input uram4_wr_en [Y],
input [A_W-1:0]      bram1_rd_addr [Y],
input bram1_rd_en [Y],
output [M_W-1:0]      bram1_rd_data [Y],
input [A_W-1:0]      bram2_rd_addr [Y],
input bram2_rd_en [Y],
output [M_W-1:0]      bram2_rd_data [Y],
input [A_W-1:0]      bram3_rd_addr [Y],
input bram3_rd_en [Y],
output [M_W-1:0]      bram3_rd_data [Y],
input [A_W-1:0]      bram4_rd_addr [Y],
input bram4_rd_en [Y],
output [M_W-1:0]      bram4_rd_data [Y],
input [A_W-1:0]      b1_wr_addr [Y],
input [15:0]         b1_wr_data [Y],
input b1_wr_en [Y],
input [A_W-1:0]      b2_wr_addr [Y],
input [15:0]         b2_wr_data [Y],
input b2_wr_en [Y],
input [A_W-1:0]      b3_wr_addr [Y],
input b3_wr_en [Y],
input [A_W-1:0]      b4_wr_addr [Y],
input b4_wr_en [Y],
input [A_W-1:0]      b5_wr_addr [Y],
input b5_wr_en [Y],
input [A_W-1:0]      b6_wr_addr [Y],
input b6_wr_en [Y],
input [A_W-1:0]      b7_wr_addr [Y],
input b7_wr_en [Y],
input [A_W-1:0]      b8_wr_addr [Y],
input b8_wr_en [Y],
input [A_W-1:0]      b9_wr_addr [Y],
input b9_wr_en [Y],
input	[22:0]	addr_chain [Y],
input	[8:0]	bwe_chain  [Y],
input	[0:0]	dbiterr_chain [Y],
input	[71:0]	din_chain [Y],
input	[71:0]	dout_chain [Y],
input	[0:0]	en_chain [Y],
input	[0:0]	rdacess_chain [Y],
input	[0:0]	rdb_wr_chain [Y],
input	[0:0]	sbiterr_chain [Y]

);

genvar y;

generate for (y = 0; y < Y; y = y + 1) begin : name
 (* dont_touch = "true" *)  fane_mm_top #(
         .IMG_W    (IMG_W)
        ,.IMG_D    (IMG_D)
	,.A_W      (A_W)
	,.M_W      (M_W)
	,.D_W      (D_W)
	,.URAM_D_W (URAM_D_W)
	,.URAM_A_W (URAM_A_W)
        ,.NUMBER_OF_REG (3)
  )
  dut (
         .clk                   (clk)
        ,.rst                   (rst)
        ,.ce                    (ce)
        ,.uram1_wr_addr         (uram1_wr_addr[y])
        ,.uram1_wr_data         (uram1_wr_data[y])
        ,.uram1_wr_en           (uram1_wr_en[y])
        ,.uram2_wr_addr         (uram2_wr_addr[y])
        ,.uram2_wr_data         (uram2_wr_data[y])
        ,.uram2_wr_en           (uram2_wr_en[y])
        ,.uram3_wr_addr         (uram3_wr_addr[y])
        ,.uram3_wr_data         (uram3_wr_data[y])
        ,.uram3_wr_en           (uram3_wr_en[y])
        ,.uram4_wr_addr         (uram4_wr_addr[y])
        ,.uram4_wr_data         (uram4_wr_data[y])
        ,.uram4_wr_en           (uram4_wr_en[y])
        ,.bram1_rd_addr         (bram1_rd_addr[y])
        ,.bram1_rd_data         (bram1_rd_data[y])
        ,.bram1_rd_en           (bram1_rd_en[y])
        ,.bram2_rd_addr         (bram2_rd_addr[y])
        ,.bram2_rd_en           (bram2_rd_en[y])
        ,.bram2_rd_data         (bram2_rd_data[y])
        ,.bram3_rd_addr         (bram3_rd_addr[y])
        ,.bram3_rd_en           (bram3_rd_en[y])
        ,.bram3_rd_data         (bram3_rd_data[y])
        ,.bram4_rd_addr         (bram4_rd_addr[y])
        ,.bram4_rd_en           (bram4_rd_en[y])
        ,.bram4_rd_data         (bram4_rd_data[y])
        ,.b1_wr_addr            (b1_wr_addr [y])
        ,.b1_wr_data            (b1_wr_data [y])
        ,.b1_wr_en              (b1_wr_en[y])
        ,.b2_wr_addr            (b2_wr_addr [y])
        ,.b2_wr_data            (b2_wr_data [y])
        ,.b2_wr_en              (b2_wr_en[y])
        ,.b3_wr_addr            (b3_wr_addr [y])
        ,.b3_wr_en              (b3_wr_en[y])
        ,.b4_wr_addr            (b4_wr_addr [y])
        ,.b4_wr_en              (b4_wr_en[y])
        ,.b5_wr_addr            (b5_wr_addr [y])
        ,.b5_wr_en              (b5_wr_en[y])
        ,.b6_wr_addr            (b6_wr_addr [y])
        ,.b6_wr_en              (b6_wr_en[y])
        ,.b7_wr_addr            (b7_wr_addr [y])
        ,.b7_wr_en              (b7_wr_en[y])
        ,.b8_wr_addr            (b8_wr_addr [y])
        ,.b8_wr_en              (b8_wr_en[y])
        ,.b9_wr_addr            (b9_wr_addr [y])
        ,.b9_wr_en              (b9_wr_en[y])
        ,.CAS_IN_ADDR           (addr_chain[y])
        ,.CAS_IN_BWE            (bwe_chain[y])
        ,.CAS_IN_DBITERR        (dbiterr_chain[y])
        ,.CAS_IN_DIN            (din_chain[y])
        ,.CAS_IN_DOUT           (dout_chain[y])
        ,.CAS_IN_EN             (en_chain[y])
        ,.CAS_IN_RDACCESS       (rdacess_chain[y])
        ,.CAS_IN_RDB_WR         (rdb_wr_chain[y])
        ,.CAS_IN_SBITERR        (sbiterr_chain[y])

  );
end
endgenerate


endmodule
