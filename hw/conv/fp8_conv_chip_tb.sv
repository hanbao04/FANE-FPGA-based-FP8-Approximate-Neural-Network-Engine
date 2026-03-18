`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/18/2026 03:19:53 PM
// Design Name: 
// Module Name: fp8_conv_tb
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// !!!!!!! PLEASE RUN AT LEAST 3000ns
//////////////////////////////////////////////////////////////////////////////////


`timescale 1ns/1ps

module fane_conv_chip_tb;

  localparam int KERN_SZ  = 3;
  localparam int IMG_W    = 4;
  localparam int IMG_D    = 4;
  localparam int A_W      = 14;
  localparam int M_W      = 18;
  localparam int D_W      = 48;
  localparam int URAM_D_W = 72;
  localparam int URAM_A_W = 23;
  localparam int Y        = 1;

  logic clk;
  logic rst;
  logic ce;

  logic [URAM_A_W-1:0] uram1_wr_addr          [Y];
  logic [URAM_D_W-1:0] uram1_wr_data          [Y];
  logic                uram1_wr_en            [Y];
  logic [URAM_A_W-1:0] uram2_rd_addr_external [Y];
  logic                read_en_external       [Y];
  logic [URAM_D_W-1:0] uram2_rd_data          [Y];
  logic                ld_new_kernel          [Y];
  logic [A_W-1:0]      krnl_bram1_wraddr      [Y];
  logic [M_W-1:0]      krnl_bram1_wrdata      [Y];
  logic                krnl_bram1_wren        [Y];

  logic [22:0] addr_chain    [Y];
  logic [8:0]  bwe_chain     [Y];
  logic [0:0]  dbiterr_chain [Y];
  logic [71:0] din_chain     [Y];
  logic [71:0] dout_chain    [Y];
  logic [0:0]  en_chain      [Y];
  logic [0:0]  rdacess_chain [Y];
  logic [0:0]  rdb_wr_chain  [Y];
  logic [0:0]  sbiterr_chain [Y];

  byte unsigned img_vec [9];
  byte unsigned kernel_vec [9];
  logic [URAM_D_W-1:0] expected_word;

  fane_conv_chip #(
    .KERN_SZ  (KERN_SZ),
    .IMG_W    (IMG_W),
    .IMG_D    (IMG_D),
    .A_W      (A_W),
    .M_W      (M_W),
    .D_W      (D_W),
    .URAM_D_W (URAM_D_W),
    .URAM_A_W (URAM_A_W),
    .Y        (Y)
  ) dut (
    .clk                   (clk),
    .rst                   (rst),
    .ce                    (ce),
    .uram1_wr_addr         (uram1_wr_addr),
    .uram1_wr_data         (uram1_wr_data),
    .uram1_wr_en           (uram1_wr_en),
    .uram2_rd_addr_external(uram2_rd_addr_external),
    .read_en_external      (read_en_external),
    .uram2_rd_data         (uram2_rd_data),
    .ld_new_kernel         (ld_new_kernel),
    .krnl_bram1_wraddr     (krnl_bram1_wraddr),
    .krnl_bram1_wrdata     (krnl_bram1_wrdata),
    .krnl_bram1_wren       (krnl_bram1_wren),
    .addr_chain            (addr_chain),
    .bwe_chain             (bwe_chain),
    .dbiterr_chain         (dbiterr_chain),
    .din_chain             (din_chain),
    .dout_chain            (dout_chain),
    .en_chain              (en_chain),
    .rdacess_chain         (rdacess_chain),
    .rdb_wr_chain          (rdb_wr_chain),
    .sbiterr_chain         (sbiterr_chain)
  );

  always #5 clk = ~clk;

  task automatic clear_drivers;
    int i;
    begin
      for (i = 0; i < Y; i++) begin
        uram1_wr_addr[i]          = '0;
        uram1_wr_data[i]          = '0;
        uram1_wr_en[i]            = 1'b0;
        uram2_rd_addr_external[i] = '0;
        read_en_external[i]       = 1'b0;
        ld_new_kernel[i]          = 1'b0;
        krnl_bram1_wraddr[i]      = '0;
        krnl_bram1_wrdata[i]      = '0;
        krnl_bram1_wren[i]        = 1'b0;
        addr_chain[i]             = '0;
        bwe_chain[i]              = '0;
        dbiterr_chain[i]          = '0;
        din_chain[i]              = '0;
        dout_chain[i]             = '0;
        en_chain[i]               = '0;
        rdacess_chain[i]          = '0;
        rdb_wr_chain[i]           = '0;
        sbiterr_chain[i]          = '0;
      end
    end
  endtask

  function automatic [URAM_D_W-1:0] pack_uram(input byte unsigned vec [9]);
    int i;
    begin
      pack_uram = '0;
      for (i = 0; i < 9; i++) begin
        pack_uram[i*8 +: 8] = vec[i];
      end
    end
  endfunction

  task automatic write_image_word(input [URAM_A_W-1:0] addr, input [URAM_D_W-1:0] data_word);
    begin
      uram1_wr_addr[0] <= addr;
      uram1_wr_data[0] <= data_word;
      uram1_wr_en[0]   <= 1'b1;
      @(posedge clk);
      uram1_wr_en[0]   <= 1'b0;
    end
  endtask

  task automatic write_kernel_word(input int idx, input [M_W-1:0] data_word);
    begin
      krnl_bram1_wraddr[0] <= idx * 16;
      krnl_bram1_wrdata[0] <= data_word;
      krnl_bram1_wren[0]   <= 1'b1;
      @(posedge clk);
      krnl_bram1_wren[0]   <= 1'b0;
    end
  endtask

  task automatic pulse_ld_new_kernel;
    begin
      ld_new_kernel[0] <= 1'b1;
      @(posedge clk);
      ld_new_kernel[0] <= 1'b0;
    end
  endtask

  task automatic check_result(
    input logic [URAM_D_W-1:0] actual,
    input logic [URAM_D_W-1:0] exp
  );
    int i;
    begin
      $display("conv actual=0x%0h expected=0x%0h", actual, exp);
      $write("conv actual bytes   :");
      for (i = 0; i < 9; i++) begin
        $write(" %02h", actual[i*8 +: 8]);
      end
      $write("\n");
      $write("conv expected bytes :");
      for (i = 0; i < 9; i++) begin
        $write(" %02h", exp[i*8 +: 8]);
      end
      $write("\n");
      if (actual !== exp) begin
        $error("conv mismatch: expected 0x%0h, got 0x%0h", exp, actual);
      end else begin
        $display("conv OK: 0x%0h", actual);
      end
    end
  endtask

  task automatic print_vectors;
    int i;
    begin
      $write("image bytes         :");
      for (i = 0; i < 9; i++) begin
        $write(" %02h", img_vec[i]);
      end
      $write("\n");

      $write("kernel bytes        :");
      for (i = 0; i < 9; i++) begin
        $write(" %02h", kernel_vec[i]);
      end
      $write("\n");

      $display("packed image word   : 0x%0h", pack_uram(img_vec));
      $display("expected uram word  : 0x%0h", expected_word);
    end
  endtask

  initial begin
    int i;

    clk = 1'b0;
    rst = 1'b1;
    ce  = 1'b1;
    clear_drivers();

    img_vec    = '{8'h01, 8'h02, 8'h03, 8'h04, 8'h05, 8'h06, 8'h07, 8'h08, 8'h09};
    kernel_vec = '{8'h11, 8'h12, 8'h13, 8'h14, 8'h15, 8'h16, 8'h17, 8'h18, 8'h19};
    expected_word = 72'h000000001200000012;

    $display("========== fane_conv_chip_tb start ==========");
    print_vectors();

    repeat (4) @(posedge clk);
    rst = 1'b0;

    $display("write image to uram1 addr=0");
    write_image_word('0, pack_uram(img_vec));
    for (i = 0; i < 9; i++) begin
      $display("write kernel[%0d] addr=%0d data=0x%0h", i, i*16, {10'd0, kernel_vec[i]});
      write_kernel_word(i, {10'd0, kernel_vec[i]});
    end
    $display("pulse ld_new_kernel");
    pulse_ld_new_kernel();

    repeat (2) @(posedge clk);
    $display("re-assert reset to restart datapath after preload");
    rst = 1'b1;
    repeat (3) @(posedge clk);
    rst = 1'b0;

    repeat (140) @(posedge clk);

    $display("read uram2 external addr=0");
    uram2_rd_addr_external[0] <= '0;
    read_en_external[0]       <= 1'b1;

    repeat (4) @(posedge clk);

    $display("internal uram2_wr_en  : %0b", dut.name[0].dut.uram2_wr_en);
    $display("internal uram2_wr_data: 0x%0h", dut.name[0].dut.uram2_wr_data);
    $display("internal data_valid   : %0b", dut.name[0].dut.data_valid);
    $display("internal rd_addr_temp : 0x%0h", dut.name[0].dut.rd_addr_temp);
    $display("internal wr_addr_temp : 0x%0h", dut.name[0].dut.wr_addr_temp);

    check_result(uram2_rd_data[0], expected_word);

    $display("fane_conv_chip_tb completed");
    $finish;
  end

endmodule

module fane_mac #(
  parameter integer EXP_WIDTH  = 4,
  parameter integer MANT_WIDTH = 3,
  parameter integer INPUT_DELAY = 0
) (
  input  wire       clk,
  input  wire       rst_n,
  input  wire       valid_in,
  input  wire [7:0] mul_a,
  input  wire [7:0] mul_b,
  input  wire [7:0] cascade_sum_in,
  output reg  [7:0] acc_out,
  output wire [7:0] cascade_mula_out,
  output wire [7:0] cascade_mulb_out,
  output reg        valid_out
);

  assign cascade_mula_out = mul_a;
  assign cascade_mulb_out = mul_b;

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      acc_out   <= 8'd0;
      valid_out <= 1'b0;
    end else begin
      valid_out <= valid_in;
      if (valid_in) begin
        acc_out <= cascade_sum_in + mul_a + mul_b;
      end
    end
  end

endmodule

module URAM288 #(
  parameter string IREG_PRE_A      = "TRUE",
  parameter string IREG_PRE_B      = "TRUE",
  parameter string OREG_A          = "TRUE",
  parameter string OREG_B          = "TRUE",
  parameter string CASCADE_ORDER_A = "NONE",
  parameter string CASCADE_ORDER_B = "NONE",
  parameter string REG_CAS_A       = "TRUE",
  parameter [10:0] SELF_MASK_A     = 11'h0,
  parameter [10:0] SELF_MASK_B     = 11'h0,
  parameter [10:0] SELF_ADDR_A     = 11'h0
) (
  input  wire        RDB_WR_B,
  input  wire [8:0]  BWE_B,
  input  wire [22:0] ADDR_B,
  input  wire [71:0] DIN_B,
  output reg  [71:0] DOUT_B,
  input  wire        RDB_WR_A,
  input  wire [8:0]  BWE_A,
  input  wire [22:0] ADDR_A,
  input  wire [71:0] DIN_A,
  output wire [71:0] DOUT_A,
  output wire [22:0] CAS_OUT_ADDR_A,
  output wire [8:0]  CAS_OUT_BWE_A,
  output wire [0:0]  CAS_OUT_DBITERR_A,
  output wire [71:0] CAS_OUT_DIN_A,
  output wire [71:0] CAS_OUT_DOUT_A,
  output wire [0:0]  CAS_OUT_EN_A,
  output wire [0:0]  CAS_OUT_RDACCESS_A,
  output wire [0:0]  CAS_OUT_RDB_WR_A,
  output wire [0:0]  CAS_OUT_SBITERR_A,
  input  wire [22:0] CAS_IN_ADDR_A,
  input  wire [8:0]  CAS_IN_BWE_A,
  input  wire [0:0]  CAS_IN_DBITERR_A,
  input  wire [71:0] CAS_IN_DIN_A,
  input  wire [71:0] CAS_IN_DOUT_A,
  input  wire [0:0]  CAS_IN_EN_A,
  input  wire [0:0]  CAS_IN_RDACCESS_A,
  input  wire [0:0]  CAS_IN_RDB_WR_A,
  input  wire [0:0]  CAS_IN_SBITERR_A,
  input  wire        CLK,
  input  wire        EN_A,
  input  wire        EN_B,
  input  wire        OREG_CE_B,
  input  wire        OREG_ECC_CE_B,
  input  wire        RST_A,
  input  wire        RST_B,
  input  wire        SLEEP
);

  reg [71:0] mem [0:255];
  integer idx;

  assign DOUT_A = 72'd0;
  assign CAS_OUT_ADDR_A     = CAS_IN_ADDR_A;
  assign CAS_OUT_BWE_A      = CAS_IN_BWE_A;
  assign CAS_OUT_DBITERR_A  = CAS_IN_DBITERR_A;
  assign CAS_OUT_DIN_A      = CAS_IN_DIN_A;
  assign CAS_OUT_DOUT_A     = CAS_IN_DOUT_A;
  assign CAS_OUT_EN_A       = CAS_IN_EN_A;
  assign CAS_OUT_RDACCESS_A = CAS_IN_RDACCESS_A;
  assign CAS_OUT_RDB_WR_A   = CAS_IN_RDB_WR_A;
  assign CAS_OUT_SBITERR_A  = CAS_IN_SBITERR_A;

  initial begin
    DOUT_B = 72'd0;
    for (idx = 0; idx < 256; idx = idx + 1) begin
      mem[idx] = 72'd0;
    end
  end

  always @(posedge CLK) begin
    if (RST_B) begin
      DOUT_B <= 72'd0;
    end else begin
      if (EN_A && RDB_WR_A) begin
        mem[ADDR_A[7:0]] <= DIN_A;
      end
      if (EN_B) begin
        if (RDB_WR_B) begin
          mem[ADDR_B[7:0]] <= DIN_B;
        end else begin
          DOUT_B <= mem[ADDR_B[7:0]];
        end
      end
    end
  end

endmodule

module RAMB18E2 #(
  parameter integer DOA_REG = 1,
  parameter integer DOB_REG = 1,
  parameter string CASCADE_ORDER_A = "NONE",
  parameter string CASCADE_ORDER_B = "NONE",
  parameter string CLOCK_DOMAINS = "COMMON",
  parameter string WRITE_MODE_A = "WRITE_FIRST",
  parameter string WRITE_MODE_B = "WRITE_FIRST",
  parameter integer WRITE_WIDTH_A = 18,
  parameter integer WRITE_WIDTH_B = 18,
  parameter integer READ_WIDTH_A = 18,
  parameter integer READ_WIDTH_B = 18
) (
  input  wire [13:0] ADDRARDADDR,
  input  wire [13:0] ADDRBWRADDR,
  input  wire        ADDRENA,
  input  wire        ADDRENB,
  input  wire [1:0]  WEA,
  input  wire [3:0]  WEBWE,
  output wire [15:0] CASDOUTA,
  output wire [1:0]  CASDOUTPA,
  output wire [15:0] CASDOUTB,
  output wire [1:0]  CASDOUTPB,
  input  wire [15:0] CASDINA,
  input  wire [1:0]  CASDINPA,
  input  wire [15:0] CASDINB,
  input  wire [1:0]  CASDINPB,
  input  wire        CASDIMUXA,
  input  wire        CASDIMUXB,
  output reg  [15:0] DOUTADOUT,
  output reg  [1:0]  DOUTPADOUTP,
  output reg  [15:0] DOUTBDOUT,
  output reg  [1:0]  DOUTPBDOUTP,
  input  wire [15:0] DINBDIN,
  input  wire [1:0]  DINPBDINP,
  input  wire        CLKARDCLK,
  input  wire        CLKBWRCLK,
  input  wire        ENARDEN,
  input  wire        ENBWREN,
  input  wire        REGCEAREGCE,
  input  wire        REGCEB,
  input  wire        RSTRAMARSTRAM,
  input  wire        RSTRAMB,
  input  wire        RSTREGARSTREG,
  input  wire        RSTREGB
);

  reg [17:0] mem [0:255];
  reg [17:0] read_a_data;
  reg [17:0] read_b_data;
  wire [17:0] write_a_data;
  wire [17:0] write_b_data;
  wire        wea_active;
  wire        web_active;
  wire        casdimuxa_sel;
  wire        casdimuxb_sel;
  integer idx;

  assign wea_active   = |WEA;
  assign web_active   = |WEBWE;
  assign casdimuxa_sel = (CASDIMUXA === 1'b1);
  assign casdimuxb_sel = (CASDIMUXB === 1'b1);
  assign write_a_data = casdimuxa_sel ? {CASDINPA, CASDINA} : 18'd0;
  assign write_b_data = casdimuxb_sel ? {CASDINPB, CASDINB} : {DINPBDINP, DINBDIN};

  assign CASDOUTA  = read_a_data[15:0];
  assign CASDOUTPA = read_a_data[17:16];
  assign CASDOUTB  = read_b_data[15:0];
  assign CASDOUTPB = read_b_data[17:16];

  initial begin
    read_a_data  = 18'd0;
    read_b_data  = 18'd0;
    DOUTADOUT    = 16'd0;
    DOUTPADOUTP  = 2'd0;
    DOUTBDOUT    = 16'd0;
    DOUTPBDOUTP  = 2'd0;
    for (idx = 0; idx < 256; idx = idx + 1) begin
      mem[idx] = 18'd0;
    end
  end

  always @(posedge CLKARDCLK) begin
    if (RSTRAMARSTRAM || RSTREGARSTREG) begin
      read_a_data <= 18'd0;
      DOUTADOUT   <= 16'd0;
      DOUTPADOUTP <= 2'd0;
    end else if (ENARDEN && ADDRENA) begin
      if (wea_active) begin
        mem[ADDRARDADDR[7:0]] <= write_a_data;
      end
      read_a_data <= mem[ADDRARDADDR[7:0]];
      if (REGCEAREGCE) begin
        DOUTADOUT   <= mem[ADDRARDADDR[7:0]][15:0];
        DOUTPADOUTP <= mem[ADDRARDADDR[7:0]][17:16];
      end
    end
  end

  always @(posedge CLKBWRCLK) begin
    if (RSTRAMB || RSTREGB) begin
      read_b_data <= 18'd0;
      DOUTBDOUT   <= 16'd0;
      DOUTPBDOUTP <= 2'd0;
    end else if (ENBWREN && ADDRENB) begin
      if (web_active) begin
        mem[ADDRBWRADDR[7:0]] <= write_b_data;
      end
      read_b_data <= mem[ADDRBWRADDR[7:0]];
      if (REGCEB) begin
        DOUTBDOUT   <= mem[ADDRBWRADDR[7:0]][15:0];
        DOUTPBDOUTP <= mem[ADDRBWRADDR[7:0]][17:16];
      end
    end
  end

endmodule
