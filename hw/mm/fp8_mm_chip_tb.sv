`timescale 1ns/1ps

module fp8_mm_chip_tb;

  localparam int IMG_W    = 9;
  localparam int IMG_D    = 1;
  localparam int A_W      = 14;
  localparam int M_W      = 18;
  localparam int D_W      = 48;
  localparam int URAM_D_W = 72;
  localparam int URAM_A_W = 23;
  localparam int Y        = 1;
  localparam int NUM_TESTS = 4;

  logic clk;
  logic rst;
  logic ce;

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
  logic [M_W-1:0] bram1_rd_data [Y];
  logic [A_W-1:0] bram2_rd_addr [Y];
  logic           bram2_rd_en   [Y];
  logic [M_W-1:0] bram2_rd_data [Y];
  logic [A_W-1:0] bram3_rd_addr [Y];
  logic           bram3_rd_en   [Y];
  logic [M_W-1:0] bram3_rd_data [Y];
  logic [A_W-1:0] bram4_rd_addr [Y];
  logic           bram4_rd_en   [Y];
  logic [M_W-1:0] bram4_rd_data [Y];

  logic [A_W-1:0] b1_wr_addr [Y];
  logic [15:0]    b1_wr_data [Y];
  logic           b1_wr_en   [Y];
  logic [A_W-1:0] b2_wr_addr [Y];
  logic [15:0]    b2_wr_data [Y];
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

  byte unsigned uram_vec [4][9];
  byte unsigned weight_vec [9];
  byte unsigned uram_tests [NUM_TESTS][4][9];
  byte unsigned weight_tests [NUM_TESTS][9];
  logic [M_W-1:0] expected [4];

  fane_mm_chip #(
    .IMG_W    (IMG_W),
    .IMG_D    (IMG_D),
    .A_W      (A_W),
    .M_W      (M_W),
    .D_W      (D_W),
    .URAM_D_W (URAM_D_W),
    .URAM_A_W (URAM_A_W),
    .Y        (Y)
  ) dut (
    .clk            (clk),
    .rst            (rst),
    .ce             (ce),
    .uram1_wr_addr  (uram1_wr_addr),
    .uram1_wr_data  (uram1_wr_data),
    .uram1_wr_en    (uram1_wr_en),
    .uram2_wr_addr  (uram2_wr_addr),
    .uram2_wr_data  (uram2_wr_data),
    .uram2_wr_en    (uram2_wr_en),
    .uram3_wr_addr  (uram3_wr_addr),
    .uram3_wr_data  (uram3_wr_data),
    .uram3_wr_en    (uram3_wr_en),
    .uram4_wr_addr  (uram4_wr_addr),
    .uram4_wr_data  (uram4_wr_data),
    .uram4_wr_en    (uram4_wr_en),
    .bram1_rd_addr  (bram1_rd_addr),
    .bram1_rd_en    (bram1_rd_en),
    .bram1_rd_data  (bram1_rd_data),
    .bram2_rd_addr  (bram2_rd_addr),
    .bram2_rd_en    (bram2_rd_en),
    .bram2_rd_data  (bram2_rd_data),
    .bram3_rd_addr  (bram3_rd_addr),
    .bram3_rd_en    (bram3_rd_en),
    .bram3_rd_data  (bram3_rd_data),
    .bram4_rd_addr  (bram4_rd_addr),
    .bram4_rd_en    (bram4_rd_en),
    .bram4_rd_data  (bram4_rd_data),
    .b1_wr_addr     (b1_wr_addr),
    .b1_wr_data     (b1_wr_data),
    .b1_wr_en       (b1_wr_en),
    .b2_wr_addr     (b2_wr_addr),
    .b2_wr_data     (b2_wr_data),
    .b2_wr_en       (b2_wr_en),
    .b3_wr_addr     (b3_wr_addr),
    .b3_wr_en       (b3_wr_en),
    .b4_wr_addr     (b4_wr_addr),
    .b4_wr_en       (b4_wr_en),
    .b5_wr_addr     (b5_wr_addr),
    .b5_wr_en       (b5_wr_en),
    .b6_wr_addr     (b6_wr_addr),
    .b6_wr_en       (b6_wr_en),
    .b7_wr_addr     (b7_wr_addr),
    .b7_wr_en       (b7_wr_en),
    .b8_wr_addr     (b8_wr_addr),
    .b8_wr_en       (b8_wr_en),
    .b9_wr_addr     (b9_wr_addr),
    .b9_wr_en       (b9_wr_en),
    .addr_chain     (addr_chain),
    .bwe_chain      (bwe_chain),
    .dbiterr_chain  (dbiterr_chain),
    .din_chain      (din_chain),
    .dout_chain     (dout_chain),
    .en_chain       (en_chain),
    .rdacess_chain  (rdacess_chain),
    .rdb_wr_chain   (rdb_wr_chain),
    .sbiterr_chain  (sbiterr_chain)
  );

  always #5 clk = ~clk;

  task automatic clear_drivers;
    int i;
    begin
      for (i = 0; i < Y; i++) begin
        uram1_wr_addr[i] = '0;
        uram1_wr_data[i] = '0;
        uram1_wr_en[i]   = 1'b0;
        uram2_wr_addr[i] = '0;
        uram2_wr_data[i] = '0;
        uram2_wr_en[i]   = 1'b0;
        uram3_wr_addr[i] = '0;
        uram3_wr_data[i] = '0;
        uram3_wr_en[i]   = 1'b0;
        uram4_wr_addr[i] = '0;
        uram4_wr_data[i] = '0;
        uram4_wr_en[i]   = 1'b0;

        bram1_rd_addr[i] = '0;
        bram1_rd_en[i]   = 1'b0;
        bram2_rd_addr[i] = '0;
        bram2_rd_en[i]   = 1'b0;
        bram3_rd_addr[i] = '0;
        bram3_rd_en[i]   = 1'b0;
        bram4_rd_addr[i] = '0;
        bram4_rd_en[i]   = 1'b0;

        b1_wr_addr[i] = '0;
        b1_wr_data[i] = '0;
        b1_wr_en[i]   = 1'b0;
        b2_wr_addr[i] = '0;
        b2_wr_data[i] = '0;
        b2_wr_en[i]   = 1'b0;
        b3_wr_addr[i] = '0;
        b3_wr_en[i]   = 1'b0;
        b4_wr_addr[i] = '0;
        b4_wr_en[i]   = 1'b0;
        b5_wr_addr[i] = '0;
        b5_wr_en[i]   = 1'b0;
        b6_wr_addr[i] = '0;
        b6_wr_en[i]   = 1'b0;
        b7_wr_addr[i] = '0;
        b7_wr_en[i]   = 1'b0;
        b8_wr_addr[i] = '0;
        b8_wr_en[i]   = 1'b0;
        b9_wr_addr[i] = '0;
        b9_wr_en[i]   = 1'b0;

        addr_chain[i]    = '0;
        bwe_chain[i]     = '0;
        dbiterr_chain[i] = '0;
        din_chain[i]     = '0;
        dout_chain[i]    = '0;
        en_chain[i]      = '0;
        rdacess_chain[i] = '0;
        rdb_wr_chain[i]  = '0;
        sbiterr_chain[i] = '0;
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

  function automatic [M_W-1:0] calc_expected(input byte unsigned a0);
    int total;
    begin
      total = a0 + weight_vec[0];
      calc_expected = total[7:0];
    end
  endfunction

  task automatic print_vectors(input int test_id);
    int bank;
    int idx;
    begin
      for (bank = 0; bank < 4; bank++) begin
        $write("test[%0d] uram%0d bytes :", test_id, bank + 1);
        for (idx = 0; idx < 9; idx++) begin
          $write(" %02h", uram_vec[bank][idx]);
        end
        $write("\n");
      end

      $write("test[%0d] weight bytes:", test_id);
      for (idx = 0; idx < 9; idx++) begin
        $write(" %02h", weight_vec[idx]);
      end
      $write("\n");

      $display("test[%0d] expected mm1=0x%0h mm2=0x%0h mm3=0x%0h mm4=0x%0h",
        test_id, expected[0], expected[1], expected[2], expected[3]);
    end
  endtask

  task automatic write_uram(input int sel, input [URAM_D_W-1:0] data_word);
    begin
      case (sel)
        1: begin
          uram1_wr_addr[0] <= '0;
          uram1_wr_data[0] <= data_word;
          uram1_wr_en[0]   <= 1'b1;
        end
        2: begin
          uram2_wr_addr[0] <= '0;
          uram2_wr_data[0] <= data_word;
          uram2_wr_en[0]   <= 1'b1;
        end
        3: begin
          uram3_wr_addr[0] <= '0;
          uram3_wr_data[0] <= data_word;
          uram3_wr_en[0]   <= 1'b1;
        end
        4: begin
          uram4_wr_addr[0] <= '0;
          uram4_wr_data[0] <= data_word;
          uram4_wr_en[0]   <= 1'b1;
        end
      endcase
      @(posedge clk);
      uram1_wr_en[0] <= 1'b0;
      uram2_wr_en[0] <= 1'b0;
      uram3_wr_en[0] <= 1'b0;
      uram4_wr_en[0] <= 1'b0;
    end
  endtask

  task automatic write_weight_bram(input int bank, input [15:0] data_word);
    begin
      case (bank)
        1: begin
          b1_wr_addr[0] <= '0;
          b1_wr_data[0] <= data_word;
          b1_wr_en[0]   <= 1'b1;
        end
        2: begin
          b2_wr_addr[0] <= '0;
          b2_wr_data[0] <= data_word;
          b2_wr_en[0]   <= 1'b1;
        end
      endcase
      @(posedge clk);
      b1_wr_en[0] <= 1'b0;
      b2_wr_en[0] <= 1'b0;
    end
  endtask

  task automatic check_result(
    input int test_id,
    input string tag,
    input logic [M_W-1:0] actual,
    input logic [M_W-1:0] exp
  );
    begin
      $display("test[%0d] %s actual=0x%0h expected=0x%0h", test_id, tag, actual, exp);
      if (actual !== exp) begin
        $error("test[%0d] %s mismatch: expected 0x%0h, got 0x%0h", test_id, tag, exp, actual);
      end else begin
        $display("test[%0d] %s OK: 0x%0h", test_id, tag, actual);
      end
    end
  endtask

  initial begin
    int t;

    clk = 1'b0;
    rst = 1'b1;
    ce  = 1'b1;
    clear_drivers();

    uram_tests[0][0] = '{8'h01, 8'h02, 8'h03, 8'h04, 8'h05, 8'h06, 8'h07, 8'h08, 8'h09};
    uram_tests[0][1] = '{8'h10, 8'h11, 8'h12, 8'h13, 8'h14, 8'h15, 8'h16, 8'h17, 8'h18};
    uram_tests[0][2] = '{8'h20, 8'h21, 8'h22, 8'h23, 8'h24, 8'h25, 8'h26, 8'h27, 8'h28};
    uram_tests[0][3] = '{8'h30, 8'h31, 8'h32, 8'h33, 8'h34, 8'h35, 8'h36, 8'h37, 8'h38};
    weight_tests[0]  = '{8'h11, 8'h22, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00};

    uram_tests[1][0] = '{8'h05, 8'h15, 8'h25, 8'h35, 8'h45, 8'h55, 8'h65, 8'h75, 8'h85};
    uram_tests[1][1] = '{8'h06, 8'h16, 8'h26, 8'h36, 8'h46, 8'h56, 8'h66, 8'h76, 8'h86};
    uram_tests[1][2] = '{8'h07, 8'h17, 8'h27, 8'h37, 8'h47, 8'h57, 8'h67, 8'h77, 8'h87};
    uram_tests[1][3] = '{8'h08, 8'h18, 8'h28, 8'h38, 8'h48, 8'h58, 8'h68, 8'h78, 8'h88};
    weight_tests[1]  = '{8'h03, 8'h44, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00};

    uram_tests[2][0] = '{8'hff, 8'h01, 8'h02, 8'h03, 8'h04, 8'h05, 8'h06, 8'h07, 8'h08};
    uram_tests[2][1] = '{8'h0a, 8'h0b, 8'h0c, 8'h0d, 8'h0e, 8'h0f, 8'h10, 8'h11, 8'h12};
    uram_tests[2][2] = '{8'h13, 8'h14, 8'h15, 8'h16, 8'h17, 8'h18, 8'h19, 8'h1a, 8'h1b};
    uram_tests[2][3] = '{8'h1c, 8'h1d, 8'h1e, 8'h1f, 8'h20, 8'h21, 8'h22, 8'h23, 8'h24};
    weight_tests[2]  = '{8'h01, 8'h99, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00};

    uram_tests[3][0] = '{8'h2a, 8'h2b, 8'h2c, 8'h2d, 8'h2e, 8'h2f, 8'h30, 8'h31, 8'h32};
    uram_tests[3][1] = '{8'h3a, 8'h3b, 8'h3c, 8'h3d, 8'h3e, 8'h3f, 8'h40, 8'h41, 8'h42};
    uram_tests[3][2] = '{8'h4a, 8'h4b, 8'h4c, 8'h4d, 8'h4e, 8'h4f, 8'h50, 8'h51, 8'h52};
    uram_tests[3][3] = '{8'h5a, 8'h5b, 8'h5c, 8'h5d, 8'h5e, 8'h5f, 8'h60, 8'h61, 8'h62};
    weight_tests[3]  = '{8'h05, 8'haa, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00};

    $display("========== fp8_mm_chip_tb start ==========");

    for (t = 0; t < NUM_TESTS; t++) begin
      uram_vec   = uram_tests[t];
      weight_vec = weight_tests[t];
      expected[0] = calc_expected(uram_vec[0][0]);
      expected[1] = calc_expected(uram_vec[1][0]);
      expected[2] = calc_expected(uram_vec[2][0]);
      expected[3] = calc_expected(uram_vec[3][0]);

      clear_drivers();
      rst = 1'b1;
      repeat (4) @(posedge clk);
      $display("---------- test[%0d] ----------", t);
      print_vectors(t);

      rst = 1'b0;
      write_weight_bram(1, {8'h00, weight_vec[0]});
      write_weight_bram(2, {8'h00, weight_vec[1]});
      write_uram(1, pack_uram(uram_vec[0]));
      write_uram(2, pack_uram(uram_vec[1]));
      write_uram(3, pack_uram(uram_vec[2]));
      write_uram(4, pack_uram(uram_vec[3]));

      repeat (2) @(posedge clk);
      rst = 1'b1;
      repeat (3) @(posedge clk);
      rst = 1'b0;

      repeat (40) @(posedge clk);

      bram1_rd_addr[0] <= '0;
      bram2_rd_addr[0] <= '0;
      bram3_rd_addr[0] <= '0;
      bram4_rd_addr[0] <= '0;
      bram1_rd_en[0]   <= 1'b1;
      bram2_rd_en[0]   <= 1'b1;
      bram3_rd_en[0]   <= 1'b1;
      bram4_rd_en[0]   <= 1'b1;

      repeat (4) @(posedge clk);

      $display("test[%0d] internal mm1 bram_wr_data: 0x%0h", t, dut.name[0].dut.mm1.bram_wr_data);
      $display("test[%0d] internal mm2 bram_wr_data: 0x%0h", t, dut.name[0].dut.mm2.bram_wr_data);
      $display("test[%0d] internal mm3 bram_wr_data: 0x%0h", t, dut.name[0].dut.mm3.bram_wr_data);
      $display("test[%0d] internal mm4 bram_wr_data: 0x%0h", t, dut.name[0].dut.mm4.bram_wr_data);

      check_result(t, "mm1", bram1_rd_data[0], expected[0]);
      check_result(t, "mm2", bram2_rd_data[0], expected[1]);
      check_result(t, "mm3", bram3_rd_data[0], expected[2]);
      check_result(t, "mm4", bram4_rd_data[0], expected[3]);

      bram1_rd_en[0] <= 1'b0;
      bram2_rd_en[0] <= 1'b0;
      bram3_rd_en[0] <= 1'b0;
      bram4_rd_en[0] <= 1'b0;
    end

    $display("fp8_mm_chip_tb completed");
    $finish;
  end

endmodule

module fane_mac #(
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
  parameter string IREG_PRE_A     = "TRUE",
  parameter string IREG_PRE_B     = "TRUE",
  parameter string OREG_A         = "TRUE",
  parameter string OREG_B         = "TRUE",
  parameter string CASCADE_ORDER_A = "NONE",
  parameter string CASCADE_ORDER_B = "NONE",
  parameter string REG_CAS_A      = "TRUE",
  parameter [10:0] SELF_MASK_A    = 11'h0,
  parameter [10:0] SELF_MASK_B    = 11'h0,
  parameter [10:0] SELF_ADDR_A    = 11'h0
) (
  input  wire       RDB_WR_B,
  input  wire [8:0] BWE_B,
  input  wire [22:0] ADDR_B,
  output reg  [71:0] DOUT_B,
  input  wire       RDB_WR_A,
  input  wire [8:0] BWE_A,
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
  assign CAS_OUT_ADDR_A    = CAS_IN_ADDR_A;
  assign CAS_OUT_BWE_A     = CAS_IN_BWE_A;
  assign CAS_OUT_DBITERR_A = CAS_IN_DBITERR_A;
  assign CAS_OUT_DIN_A     = CAS_IN_DIN_A;
  assign CAS_OUT_DOUT_A    = CAS_IN_DOUT_A;
  assign CAS_OUT_EN_A      = CAS_IN_EN_A;
  assign CAS_OUT_RDACCESS_A = CAS_IN_RDACCESS_A;
  assign CAS_OUT_RDB_WR_A  = CAS_IN_RDB_WR_A;
  assign CAS_OUT_SBITERR_A = CAS_IN_SBITERR_A;

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
      if (EN_B && !RDB_WR_B) begin
        DOUT_B <= mem[ADDR_B[7:0]];
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

  assign wea_active = |WEA;
  assign web_active = |WEBWE;
  assign casdimuxa_sel = (CASDIMUXA === 1'b1);
  assign casdimuxb_sel = (CASDIMUXB === 1'b1);
  assign write_a_data = casdimuxa_sel ? {CASDINPA, CASDINA} : 18'd0;
  assign write_b_data = casdimuxb_sel ? {CASDINPB, CASDINB} : {DINPBDINP, DINBDIN};

  assign CASDOUTA  = read_a_data[15:0];
  assign CASDOUTPA = read_a_data[17:16];
  assign CASDOUTB  = read_b_data[15:0];
  assign CASDOUTPB = read_b_data[17:16];

  initial begin
    read_a_data = 18'd0;
    read_b_data = 18'd0;
    DOUTADOUT   = 16'd0;
    DOUTPADOUTP = 2'd0;
    DOUTBDOUT   = 16'd0;
    for (idx = 0; idx < 256; idx = idx + 1) begin
      mem[idx] = 18'd0;
    end
  end

  always @(posedge CLKARDCLK) begin
    if (RSTRAMARSTRAM || RSTREGARSTREG) begin
      read_a_data  <= 18'd0;
      DOUTADOUT    <= 16'd0;
      DOUTPADOUTP  <= 2'd0;
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
    end else if (ENBWREN && ADDRENB) begin
      if (web_active) begin
        mem[ADDRBWRADDR[7:0]] <= write_b_data;
      end
      read_b_data <= mem[ADDRBWRADDR[7:0]];
      if (REGCEB) begin
        DOUTBDOUT <= mem[ADDRBWRADDR[7:0]][15:0];
      end
    end
  end

endmodule
