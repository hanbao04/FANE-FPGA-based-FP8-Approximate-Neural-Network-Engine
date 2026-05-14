`timescale 1ns / 1ps

module conv_wrapper    #(
    parameter IMG_W    = 4,
    parameter IMG_D    = 6,
    parameter EXP_WIDTH = 4,
    parameter MANT_WIDTH = 3,
    parameter A_W      = 14,
    parameter M_W      = 18,
    parameter D_W      = 48,
    parameter URAM_D_W = 72,
    parameter URAM_A_W = 23,
    parameter Y        = 6
)(
    input clk,
    input rst,
    input ce
);

    logic [URAM_A_W-1:0] uram1_wr_addr [Y];
    logic [URAM_D_W-1:0] uram1_wr_data [Y];
    logic                uram1_wr_en   [Y];

    logic [URAM_A_W-1:0] uram2_wr_addr [Y];
    logic [URAM_D_W-1:0] uram2_wr_data [Y];
    logic                uram2_wr_en   [Y];

    logic [URAM_A_W-1:0] uram3_wr_addr [Y];
    logic [URAM_D_W-1:0] uram3_wr_data [Y];
    logic                uram3_wr_en   [Y];

    logic [URAM_A_W-1:0] uram4_wr_addr [Y];
    logic [URAM_D_W-1:0] uram4_wr_data [Y];
    logic                uram4_wr_en   [Y];

    logic [A_W-1:0] bram1_rd_addr [Y];
    logic           bram1_rd_en   [Y];
    wire  [M_W-1:0] bram1_rd_data [Y];

    logic [A_W-1:0] bram2_rd_addr [Y];
    logic           bram2_rd_en   [Y];
    wire  [M_W-1:0] bram2_rd_data [Y];

    logic [A_W-1:0] bram3_rd_addr [Y];
    logic           bram3_rd_en   [Y];
    wire  [M_W-1:0] bram3_rd_data [Y];

    logic [A_W-1:0] bram4_rd_addr [Y];
    logic           bram4_rd_en   [Y];
    wire  [M_W-1:0] bram4_rd_data [Y];

    logic [A_W-1:0] b1_wr_addr [Y];
    logic [7:0]     b1_wr_data [Y];
    logic           b1_wr_en   [Y];

    logic [A_W-1:0] b2_wr_addr [Y];
    logic [7:0]     b2_wr_data [Y];
    logic           b2_wr_en   [Y];

    logic [A_W-1:0] b3_wr_addr [Y];
    logic           b3_wr_en   [Y];

    logic [A_W-1:0] b4_wr_addr [Y];
    logic           b4_wr_en   [Y];

    logic [A_W-1:0] b5_wr_addr [Y];
    logic           b5_wr_en   [Y];

    logic [A_W-1:0] b6_wr_addr [Y];
    logic           b6_wr_en   [Y];

    logic [A_W-1:0] b7_wr_addr [Y];
    logic           b7_wr_en   [Y];

    logic [A_W-1:0] b8_wr_addr [Y];
    logic           b8_wr_en   [Y];

    logic [A_W-1:0] b9_wr_addr [Y];
    logic           b9_wr_en   [Y];

    logic [22:0] addr_chain     [Y];
    logic [8:0]  bwe_chain      [Y];
    logic [0:0]  dbiterr_chain  [Y];
    logic [71:0] din_chain      [Y];
    logic [71:0] dout_chain     [Y];
    logic [0:0]  en_chain       [Y];
    logic [0:0]  rdacess_chain  [Y];
    logic [0:0]  rdb_wr_chain   [Y];
    logic [0:0]  sbiterr_chain  [Y];

    conv_chip #(
        .IMG_W     (IMG_W),
        .IMG_D     (IMG_D),
        .EXP_WIDTH (EXP_WIDTH),
        .MANT_WIDTH(MANT_WIDTH),
        .A_W       (A_W),
        .M_W       (M_W),
        .D_W       (D_W),
        .URAM_D_W  (URAM_D_W),
        .URAM_A_W  (URAM_A_W),
        .Y         (Y)
    ) u_conv_chip (
        .clk(clk),
        .rst(rst),
        .ce (ce),

        .uram1_wr_addr(uram1_wr_addr),
        .uram1_wr_data(uram1_wr_data),
        .uram1_wr_en  (uram1_wr_en),

        .uram2_wr_addr(uram2_wr_addr),
        .uram2_wr_data(uram2_wr_data),
        .uram2_wr_en  (uram2_wr_en),

        .uram3_wr_addr(uram3_wr_addr),
        .uram3_wr_data(uram3_wr_data),
        .uram3_wr_en  (uram3_wr_en),

        .uram4_wr_addr(uram4_wr_addr),
        .uram4_wr_data(uram4_wr_data),
        .uram4_wr_en  (uram4_wr_en),

        .bram1_rd_addr(bram1_rd_addr),
        .bram1_rd_en  (bram1_rd_en),
        .bram1_rd_data(bram1_rd_data),

        .bram2_rd_addr(bram2_rd_addr),
        .bram2_rd_en  (bram2_rd_en),
        .bram2_rd_data(bram2_rd_data),

        .bram3_rd_addr(bram3_rd_addr),
        .bram3_rd_en  (bram3_rd_en),
        .bram3_rd_data(bram3_rd_data),

        .bram4_rd_addr(bram4_rd_addr),
        .bram4_rd_en  (bram4_rd_en),
        .bram4_rd_data(bram4_rd_data),

        .b1_wr_addr(b1_wr_addr),
        .b1_wr_data(b1_wr_data),
        .b1_wr_en  (b1_wr_en),

        .b2_wr_addr(b2_wr_addr),
        .b2_wr_data(b2_wr_data),
        .b2_wr_en  (b2_wr_en),

        .b3_wr_addr(b3_wr_addr),
        .b3_wr_en  (b3_wr_en),

        .b4_wr_addr(b4_wr_addr),
        .b4_wr_en  (b4_wr_en),

        .b5_wr_addr(b5_wr_addr),
        .b5_wr_en  (b5_wr_en),

        .b6_wr_addr(b6_wr_addr),
        .b6_wr_en  (b6_wr_en),

        .b7_wr_addr(b7_wr_addr),
        .b7_wr_en  (b7_wr_en),

        .b8_wr_addr(b8_wr_addr),
        .b8_wr_en  (b8_wr_en),

        .b9_wr_addr(b9_wr_addr),
        .b9_wr_en  (b9_wr_en),

        .addr_chain    (addr_chain),
        .bwe_chain     (bwe_chain),
        .dbiterr_chain (dbiterr_chain),
        .din_chain     (din_chain),
        .dout_chain    (dout_chain),
        .en_chain      (en_chain),
        .rdacess_chain (rdacess_chain),
        .rdb_wr_chain  (rdb_wr_chain),
        .sbiterr_chain (sbiterr_chain)
    );

endmodule
