`timescale 1ns / 1ps

module fane_mac #(
    parameter EXP_WIDTH  = 4,
    parameter MANT_WIDTH = 3
) (
    input clk,
    input rst_n,
    input valid_in,
    input [7:0] mul_a,
    input [7:0] mul_b,
    input [7:0] cascade_sum_in,
    output [7:0] acc_out,
    output [7:0] cascade_mula_out,
    output [7:0] cascade_mulb_out,
    output valid_out
);

reg [7:0] mul_a_r;
reg [7:0] mul_b_r;
reg [7:0] mul_a_r1;
reg [7:0] mul_a_r2;
reg [7:0] mul_a_r3;
reg [7:0] mul_a_r4;
reg [7:0] mul_b_r1;
reg [7:0] mul_b_r2;
reg [7:0] mul_b_r3;
reg [7:0] mul_b_r4;
reg [7:0] sum_r0;
reg [7:0] sum_r1;
reg [7:0] sum_r2;
reg [7:0] fp8_product_r;
reg [7:0] acc_out_r;
reg valid_r0;
reg valid_r1;
reg valid_r2;
reg valid_r3;
reg valid_r4;

wire [7:0] fp8_product;
wire [7:0] sum_result;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        mul_a_r <= 8'd0;
        mul_b_r <= 8'd0;
        mul_a_r1 <= 8'd0;
        mul_a_r2 <= 8'd0;
        mul_a_r3 <= 8'd0;
        mul_a_r4 <= 8'd0;
        mul_b_r1 <= 8'd0;
        mul_b_r2 <= 8'd0;
        mul_b_r3 <= 8'd0;
        mul_b_r4 <= 8'd0;
        sum_r0 <= 8'd0;
        sum_r1 <= 8'd0;
        sum_r2 <= 8'd0;
        fp8_product_r <= 8'd0;
        acc_out_r <= 8'd0;
        valid_r0 <= 1'b0;
        valid_r1 <= 1'b0;
        valid_r2 <= 1'b0;
        valid_r3 <= 1'b0;
        valid_r4 <= 1'b0;
    end else begin
        valid_r0 <= valid_in;
        valid_r1 <= valid_r0;
        valid_r2 <= valid_r1;
        valid_r3 <= valid_r2;
        valid_r4 <= valid_r3;

        if (valid_in) begin
            mul_a_r <= mul_a;
            mul_b_r <= mul_b;
            sum_r0 <= cascade_sum_in;
        end

        if (valid_r0) begin
            mul_a_r1 <= mul_a_r;
            mul_b_r1 <= mul_b_r;
        end

        if (valid_r1) begin
            mul_a_r2 <= mul_a_r1;
            mul_b_r2 <= mul_b_r1;
        end

        if (valid_r2) begin
            mul_a_r3 <= mul_a_r2;
            mul_b_r3 <= mul_b_r2;
        end

        if (valid_r3) begin
            mul_a_r4 <= mul_a_r3;
            mul_b_r4 <= mul_b_r3;
        end

        if (valid_r0) begin
            sum_r1 <= sum_r0;
        end

        if (valid_r1) begin
            sum_r2 <= sum_r1;
            fp8_product_r <= fp8_product;
        end

        if (valid_r3) begin
            acc_out_r <= sum_result;
        end
    end
end

(* dont_touch = "true" *) fp8_addmul #(
    .e(EXP_WIDTH),
    .m(MANT_WIDTH)
) u_fp8_addmul (
    .sys_clk(clk),
    .rst_n(rst_n),
    .w_fp8_x(mul_a_r),
    .w_fp8_y(mul_b_r),
    .product(fp8_product)
);

(* dont_touch = "true" *) fp8_adder #(
    .e(EXP_WIDTH),
    .m(MANT_WIDTH)
) u_fp8_adder (
    .a(sum_r2),
    .b(fp8_product_r),
    .result(sum_result)
);

assign acc_out = acc_out_r;
assign cascade_mula_out = mul_a_r4;
assign cascade_mulb_out = mul_b_r4;
assign valid_out = valid_r4;

endmodule
