// after 4 cycles to get the final result
module fane_mac#(
    parameter EXP_WIDTH     = 3,
    parameter MANT_WIDTH    = 4
)(
    input               clk,
    input               rst_n,
    input               en,


    input   [7:0]       mul_a,         
    input   [7:0]       mul_b,     
    input   [7:0]       cascade_sum_in,     // pcin


    output  [7:0]       acc_out  ,        // P
    output  [7:0]       cascade_mula_out, 
    output  [7:0]       cascade_mulb_out  
);

wire [7:0] fp8_product;
reg [7:0] acin_reg;
reg [7:0] bcin_reg;
reg [7:0] cascade_sum_in_r1;
reg [7:0] cascade_sum_in_r2;
reg [7:0] cascade_sum_in_r3;
reg [7:0] addmul_out_reg;

assign cascade_mula_out = acin_reg;
assign cascade_mulb_out = bcin_reg;

always @(posedge clk or negedge rst_n) begin
    if(!rst_n)begin
        acin_reg <= 0;
        bcin_reg <= 0;
    end else if (en) begin
        acin_reg <= mul_a;
        bcin_reg <= mul_b;
    end
end

// needs 2 cycles
(* dont_touch = "true" *) fp8_addmul #(
    .e       (EXP_WIDTH         ),
    .m       (MANT_WIDTH        )
) u_fp8_lopt(
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
) u_FP8_add_Top(
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