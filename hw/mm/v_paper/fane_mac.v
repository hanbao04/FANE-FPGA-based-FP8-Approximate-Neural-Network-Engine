// after 4 cycles to get the final result
module fane_mac#(
    parameter EXP_WIDTH     = 4,
    parameter MANT_WIDTH    = 3
)(
    input               clk,
    input               rst_n,
    input               en,


    input   [7:0]       mul_a,          
    input   [7:0]       mul_b,       
    input   [7:0]       cascade_sum_in,     

    output  [7:0]       acc_out  ,        
    output  [7:0]       cascade_mula_out,
    output  [7:0]       cascade_mulb_out  
);

wire [7:0] fp8_product;
reg [7:0] acin_reg;
reg [7:0] bcin_reg;
reg [7:0] acin_reg_1;
reg [7:0] bcin_reg_1;
reg [7:0] acin_reg_2;
reg [7:0] bcin_reg_2;
reg [7:0] acin_reg_3;
reg [7:0] bcin_reg_3;
reg [7:0] cascade_sum_in_r1;
reg [7:0] cascade_sum_in_r2;
reg [7:0] cascade_sum_in_r3;
reg [7:0] addmul_out_reg;

assign cascade_mula_out = acin_reg_3;
assign cascade_mulb_out = bcin_reg_3;

always @(posedge clk or negedge rst_n) begin
    if(!rst_n)begin
        acin_reg <= 0;
        bcin_reg <= 0;
        acin_reg_1 <= 0;
        bcin_reg_1 <= 0;
        acin_reg_2 <= 0;
        bcin_reg_2 <= 0;
        acin_reg_3 <= 0;
        bcin_reg_3 <= 0;
    end else if (en) begin
        acin_reg <= mul_a;
        bcin_reg <= mul_b;
        acin_reg_1 <= acin_reg;
        bcin_reg_1 <= bcin_reg;
        acin_reg_2 <= acin_reg_1;
        bcin_reg_2 <= bcin_reg_1;
        acin_reg_3 <= acin_reg_2;
        bcin_reg_3 <= bcin_reg_2;
    end
end

// needs 2 cycles
(* dont_touch = "true" *) fp8_addmul #(
    .e       (EXP_WIDTH         ),
    .m       (MANT_WIDTH        )
) U_FP8_ADDMUL(
    .sys_clk (clk               ),
    .rst_n   (rst_n             ),
    .w_fp8_x (acin_reg          ),
    .w_fp8_y (bcin_reg          ),
    .product (fp8_product       )
);


always @(posedge clk or negedge rst_n) begin
    if(!rst_n)begin
        addmul_out_reg <= 8'd0;
    end else if (en) begin
        addmul_out_reg <= fp8_product;
    end
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n)begin
        cascade_sum_in_r1 <= 8'd0;
        cascade_sum_in_r2 <= 8'd0;
        cascade_sum_in_r3 <= 8'd0;
    end else if (en) begin
        cascade_sum_in_r1 <= cascade_sum_in;
        cascade_sum_in_r2 <= cascade_sum_in_r1;
        cascade_sum_in_r3 <= cascade_sum_in_r2;
    end
end

wire [7:0] sum_result;
(* dont_touch = "true" *) fp8_adder#(
    .e      (EXP_WIDTH          ),
    .m      (MANT_WIDTH         )
) U_FP8_ADDER(
    .a      (cascade_sum_in_r3  ),
    .b      (addmul_out_reg     ),
    .result (sum_result         )
);

reg [7: 0] acc_out_reg;
always @(posedge clk or negedge rst_n) begin
    if(!rst_n)begin
        acc_out_reg <= 8'd0;
    end else if (en) begin
        acc_out_reg <= sum_result;
    end
end
assign acc_out =  acc_out_reg;
    
endmodule