`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/25/2025 02:13:36 PM
// Design Name: FP8 MAC Testbench
// Module Name: fane_mac_tb
// Description: 
//   Testbench for the FP8 MAC unit (fane_mac). This file instantiates 
//   four MAC units with different FP8 formats (E2M5, E3M4, E4M3, E5M2)
//   and applies a set of test inputs to verify the accumulation behavior.
//
// Additional Comments:
//   - Only E2M5 test vectors are enabled by default.
//   - Other formats (E3M4 / E4M3 / E5M2) test cases are commented out.
// 
//////////////////////////////////////////////////////////////////////////////////

module fane_mac_tb;

  // ============================
  // Clock and control signals
  // ============================
  reg clk;
  reg rst_n;
  reg ce;
  reg ce_a_1;
  reg ce_a_2;
  reg ce_b_1;
  reg ce_b_2;

  // ============================
  // Common FP8 inputs
  // ============================
  reg [7:0] mul_a;            // MAC multiplicand
  reg [7:0] mul_b;            // MAC multiplier
  reg [7:0] cascade_sum_in;   // Input partial sum (PCIN)

  // ============================
  // Outputs from four FP8 formats
  // ============================
  wire [7:0] acc_out_e2m5;    // Result for FP8 format E2M5
  wire [7:0] acc_out_e3m4;    // Result for FP8 format E3M4
  wire [7:0] acc_out_e4m3;    // Result for FP8 format E4M3
  wire [7:0] acc_out_e5m2;    // Result for FP8 format E5M2

  // ============================
  // Instantiate DUT — FP8 Format E2M5
  // ============================
  fane_mac #(
      .EXP_WIDTH(2), 
      .MANT_WIDTH(5), 
      .AREG(2), 
      .BREG(2)
  ) dut_e2m5 (
    .clk(clk), 
    .rst_n(rst_n), 
    .ce(ce),
    .ce_a_1(ce_a_1), 
    .ce_a_2(ce_a_2),
    .ce_b_1(ce_b_1), 
    .ce_b_2(ce_b_2),
    .mul_a(mul_a), 
    .mul_b(mul_b),
    .cascade_sum_in(cascade_sum_in),
    .acc_out(acc_out_e2m5)
  );

  // ============================
  // Instantiate DUT — FP8 Format E3M4
  // Note: original design uses 'en', but 'en' is not defined here.
  // ============================
  fane_mac #(.EXP_WIDTH(3), .MANT_WIDTH(4)) dut_e3m4 (
    .clk(clk), 
    .rst_n(rst_n), 
    .en(en),  // ← User-defined enable (not initialized in TB)
    .mul_a(mul_a), 
    .mul_b(mul_b),
    .cascade_sum_in(cascade_sum_in),
    .acc_out(acc_out_e3m4)
  );

  // ============================
  // Instantiate DUT — FP8 Format E4M3
  // ============================
  fane_mac #(.EXP_WIDTH(4), .MANT_WIDTH(3)) dut_e4m3 (
    .clk(clk), 
    .rst_n(rst_n), 
    .en(en),
    .mul_a(mul_a), 
    .mul_b(mul_b),
    .cascade_sum_in(cascade_sum_in),
    .acc_out(acc_out_e4m3)
  );

  // ============================
  // Instantiate DUT — FP8 Format E5M2
  // ============================
  fane_mac #(.EXP_WIDTH(5), .MANT_WIDTH(2)) dut_e5m2 (
    .clk(clk), 
    .rst_n(rst_n), 
    .en(en),
    .mul_a(mul_a), 
    .mul_b(mul_b),
    .cascade_sum_in(cascade_sum_in),
    .acc_out(acc_out_e5m2)
  );

  // ============================
  // Clock Generation
  // 10 ns clock period (100 MHz)
  // ============================
  initial clk = 0;
  always #5 clk = ~clk;

  // ============================
  // Main Test Process
  // ============================
  initial begin
    // Dump waveforms for GTKWave or Vivado
    $dumpfile("wave_fane_mac.vcd");
    $dumpvars(0, tb_fane_mac);

    // Initialize inputs
    rst_n = 0;
    ce = 0;
    ce_a_1 = 0;
    ce_a_2 = 0;
    ce_b_1 = 0;
    ce_b_2 = 0;

    mul_a = 0;
    mul_b = 0;
    cascade_sum_in = 0;

    // Hold reset for 20ns
    #20;
    rst_n = 1;

    // Enable control signals
    ce = 1;
    ce_a_1 = 1;
    ce_a_2 = 1;
    ce_b_1 = 1;
    ce_b_2 = 1;

    $display("[%0t] Reset released.", $time);

    // ============================
    // Test Set 1: FP8 Format E2M5
    // ============================
    $display("\n=== Testing Format: E2M5 ===");

    #20;
    mul_a=8'b00100000; mul_b=8'b00100000; cascade_sum_in=8'b00100000; #50;
    $display("a=%b, b=%b, c=%b -> acc_out(E2M5)=%b",
               mul_a,mul_b,cascade_sum_in,acc_out_e2m5);

    #20;
    mul_a=8'b00101000; mul_b=8'b00101000; cascade_sum_in=8'b00100000; #50;
    $display("a=%b, b=%b, c=%b -> acc_out(E2M5)=%b",
               mul_a,mul_b,cascade_sum_in,acc_out_e2m5);

    #20;
    mul_a=8'b01000000; mul_b=8'b00100000; cascade_sum_in=8'b00100000; #50;
    $display("a=%b, b=%b, c=%b -> acc_out(E2M5)=%b",
               mul_a,mul_b,cascade_sum_in,acc_out_e2m5);

    #20;
    mul_a=8'b01001000; mul_b=8'b01001000; cascade_sum_in=8'b00100000; #50;
    $display("a=%b, b=%b, c=%b -> acc_out(E2M5)=%b",
               mul_a,mul_b,cascade_sum_in,acc_out_e2m5);

    #20;
    mul_a=8'b10100000; mul_b=8'b10100000; cascade_sum_in=8'b00100000; #50;
    $display("a=%b, b=%b, c=%b -> acc_out(E2M5)=%b",
               mul_a,mul_b,cascade_sum_in,acc_out_e2m5);

    // Other formats (E3M4, E4M3, E5M2) commented out but available.

    // ============================
    // End Simulation
    // ============================
    #50;
    $display("\n[%0t] === All FP8 MAC tests completed ===", $time);
    $stop;
  end

endmodule
