`timescale 1ns / 1ps

module fane_conv_chip_zcu104_wrapper #(
    parameter KERN_SZ = 3,
    parameter IMG_W = 4,
    parameter IMG_D = 6,
    parameter A_W = 14,
    parameter M_W = 18,
    parameter D_W = 48,
    parameter URAM_D_W = 72,
    parameter URAM_A_W = 23,
    parameter Y = 16
)
(
    input clk,
    input rst,
    input ce
);

    // --- 内部信号定义：对应原模块的所有数组接口 ---
    wire [URAM_A_W-1:0] uram1_wr_addr [Y];
    wire [URAM_D_W-1:0] uram1_wr_data [Y];
    wire uram1_wr_en [Y];
    
    wire [URAM_A_W-1:0] uram2_rd_addr_external [Y];
    wire read_en_external [Y];
    wire [URAM_D_W-1:0] uram2_rd_data [Y];
    
    wire ld_new_kernel [Y];
    wire [A_W-1:0] krnl_bram1_wraddr [Y];
    wire [M_W-1:0] krnl_bram1_wrdata [Y];
    wire krnl_bram1_wren [Y];
    
    wire [22:0] addr_chain [Y];
    wire [8:0]  bwe_chain [Y];
    wire [0:0]  dbiterr_chain [Y];
    wire [71:0] din_chain [Y];
    wire [71:0] dout_chain [Y];
    wire [0:0]  en_chain [Y];
    wire [0:0]  rdacess_chain [Y];
    wire [0:0]  rdb_wr_chain [Y];
    wire [0:0]  sbiterr_chain [Y];

    // --- 实例化底层模块 fane_conv_chip ---
    fane_conv_chip #(
        .KERN_SZ(KERN_SZ),
        .IMG_W(IMG_W),
        .IMG_D(IMG_D),
        .A_W(A_W),
        .M_W(M_W),
        .D_W(D_W),
        .URAM_D_W(URAM_D_W),
        .URAM_A_W(URAM_A_W),
        .Y(Y)
    ) i_fane_conv_chip (
        .clk(clk),
        .rst(rst),
        .ce(ce),
        .uram1_wr_addr(uram1_wr_addr),
        .uram1_wr_data(uram1_wr_data),
        .uram1_wr_en(uram1_wr_en),
        .uram2_rd_addr_external(uram2_rd_addr_external),
        .read_en_external(read_en_external),
        .uram2_rd_data(uram2_rd_data),
        .ld_new_kernel(ld_new_kernel),
        .krnl_bram1_wraddr(krnl_bram1_wraddr),
        .krnl_bram1_wrdata(krnl_bram1_wrdata),
        .krnl_bram1_wren(krnl_bram1_wren),
        .addr_chain(addr_chain),
        .bwe_chain(bwe_chain),
        .dbiterr_chain(dbiterr_chain),
        .din_chain(din_chain),
        .dout_chain(dout_chain),
        .en_chain(en_chain),
        .rdacess_chain(rdacess_chain),
        .rdb_wr_chain(rdb_wr_chain),
        .sbiterr_chain(sbiterr_chain)
    );

endmodule