`timescale 1ns / 1ps

module fpmac_conv#(
    parameter EXP_WIDTH     = 4,
    parameter MANT_WIDTH    = 3,
    parameter NUM_INREG     = 1
)(
    input   wire                clk     ,
    input   wire                rst_n   ,
    input   wire                en      ,
    input   wire                en_1    ,
    input   wire                en_2    ,

    input   wire    [7:0]       mul_a   ,
    input   wire    [7:0]       mul_b   ,
    input   wire    [7:0]       sum_in  ,

    output  reg     [7:0]       acc_out ,
    output  wire    [7:0]       PCOUT
);

wire    [7:0]   prod_out    ;
reg     [7:0]   sum_r0      ;
reg     [7:0]   sum_r1      ;
reg     [7:0]   sum_r2      ;
reg     [7:0]   ain_r0      ;
reg     [7:0]   bin_r0      ;
wire    [7:0]   acc_res     ;

generate
    if (NUM_INREG == 1) begin : single_inreg
        (* dont_touch = "true" *) addmul U_FP8_ADDMUL(
            .sys_clk (clk        ),
            .rst_n   (rst_n      ),
            .en      (en_2       ),
            .w_fp8_x (mul_a      ),
            .w_fp8_y (mul_b      ),
            .product (prod_out   )
        );

        (* dont_touch = "true" *) fpadder#(
            .e      (EXP_WIDTH      ),
            .m      (MANT_WIDTH     )
        ) U_FP8_ADDER(
            .a      (sum_r1         ),
            .b      (prod_out       ),
            .result (acc_res        )
        );
    end else if (NUM_INREG == 2) begin : double_inreg
        (* dont_touch = "true" *) addmul U_FP8_ADDMUL(
            .sys_clk (clk        ),
            .rst_n   (rst_n      ),
            .en      (en_2       ),
            .w_fp8_x (ain_r0     ),
            .w_fp8_y (bin_r0     ),
            .product (prod_out   )
        );

        (* dont_touch = "true" *) fpadder#(
            .e      (EXP_WIDTH      ),
            .m      (MANT_WIDTH     )
        ) U_FP8_ADDER(
            .a      (sum_r2         ),
            .b      (prod_out       ),
            .result (acc_res        )
        );
        always @(posedge clk or negedge rst_n) begin
            if(!rst_n) begin
                sum_r2 <= 8'd0;
                ain_r0 <= 8'b0;
                bin_r0 <= 8'b0;
            end else begin
                if (en_1) begin
                    sum_r2 <= sum_r1;
                    ain_r0 <= mul_a ;
                    bin_r0 <= mul_b ;
                end
            end
        end
    end
endgenerate

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        acc_out <= 8'd0;
        sum_r0  <= 8'b0;
        sum_r1  <= 8'b0;
    end else begin
        if (en) begin
            acc_out <= acc_res;
            sum_r0  <= sum_in ;
            sum_r1  <= sum_r0 ;
        end
    end
end

assign PCOUT = acc_out;

endmodule
