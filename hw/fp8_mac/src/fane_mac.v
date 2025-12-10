// After 4 cycles, the final MAC result becomes valid
module fane_mac#(
    parameter EXP_WIDTH     = 4,   // Exponent bit-width of FP8
    parameter MANT_WIDTH    = 3    // Mantissa bit-width of FP8
)(
    input               clk,
    input               rst_n,
    input               ce,        // Global clock enable
    input               ce_a_1,    // Clock enable for mul_a register stage
    input               ce_a_2,    // (Unused here but kept for pipeline control)
    input               ce_b_1,    // Clock enable for mul_b register stage
    input               ce_b_2,    // (Unused here but kept for pipeline control)

    // Synchronized data inputs
    input   [7:0]       mul_a,             // Multiplicand
    input   [7:0]       mul_b,             // Multiplier
    input   [7:0]       cascade_sum_in,    // Cascaded partial sum (PCIN)

    // MAC output result
    output  [7:0]       acc_out,           // Final accumulated output (P)
    output  [7:0]       cascade_mula_out,  // Cascaded output of multiplicand
    output  [7:0]       cascade_mulb_out   // Cascaded output of multiplier
);

wire [7:0] fp8_product;             // Result of FP8 multiplication
reg  [7:0] acin_reg;                // Registered multiplicand
reg  [7:0] bcin_reg;                // Registered multiplier
reg  [7:0] cascade_sum_in_r1;       // Pipeline stage 1 for sum input
reg  [7:0] cascade_sum_in_r2;       // Pipeline stage 2 for sum input
reg  [7:0] cascade_mula_out_reg;    // Registered cascade output for mul_a
reg  [7:0] cascade_mulb_out_reg;    // Registered cascade output for mul_b
reg  [7:0] cascade_sum_in_reg;      // Registered initial sum input
wire [7:0] sum_result;              // Adder result
reg  [7:0] acc_out_reg;             // Registered accumulator output

// Register cascade_sum_in (stage 0)
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        cascade_sum_in_reg <= 8'd0;
    end else if (ce) begin
        cascade_sum_in_reg <= cascade_sum_in;
    end
end

// Register mul_a (multiplicand)
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        acin_reg <= 8'd0;
    end else if (ce_a_1) begin
        acin_reg <= mul_a;
    end
end

// Register mul_b (multiplier)
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        bcin_reg <= 8'd0;
    end else if (ce_b_1) begin
        bcin_reg <= mul_b;
    end
end

// Pipeline cascade outputs of a and b
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        cascade_mula_out_reg <= 8'd0;
        cascade_mulb_out_reg <= 8'd0;
    end else if (ce) begin
        cascade_mula_out_reg <= mul_a;
        cascade_mulb_out_reg <= mul_b;
    end
end

assign cascade_mula_out = cascade_mula_out_reg;
assign cascade_mulb_out = cascade_mulb_out_reg;

// FP8 multiply unit (2-cycle latency)
(* dont_touch = "true" *) fp8_addmul #(
    .e       (EXP_WIDTH  ),
    .m       (MANT_WIDTH )
) U_FP8_ADDMUL(
    .sys_clk (clk        ),
    .rst_n   (rst_n      ),
    .w_fp8_x (acin_reg   ),
    .w_fp8_y (bcin_reg   ),
    .product (fp8_product)
);

// Pipeline the cascade sum input (2 cycles)
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        cascade_sum_in_r1 <= 8'd0;
        cascade_sum_in_r2 <= 8'd0;
    end else if (ce) begin
        cascade_sum_in_r1 <= cascade_sum_in_reg;
        cascade_sum_in_r2 <= cascade_sum_in_r1;
    end
end

// FP8 adder for accumulation
(* dont_touch = "true" *) fp8_adder#(
    .e      (EXP_WIDTH ),
    .m      (MANT_WIDTH)
) U_FP8_ADDER(
    .a      (cascade_sum_in_r2),
    .b      (fp8_product      ),
    .result (sum_result       )
);

// Register final accumulated result
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        acc_out_reg <= 8'd0;
    end else if (ce) begin
        acc_out_reg <= sum_result;
    end
end

assign acc_out = acc_out_reg;

endmodule
