`timescale 1ns / 1ps

module fpmac_conv#(
    parameter EXP_WIDTH     = 4,
    parameter MANT_WIDTH    = 3,
    parameter NUM_INREG     = 1,
    parameter ADD_PIPE      = 2,
    parameter PROD_DELAY    = 0
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
reg     [7:0]   sum_r3      ;
reg     [7:0]   ain_r0      ;
reg     [7:0]   ain_r1      ;
reg     [7:0]   bin_r0      ;
reg     [7:0]   bin_r1      ;
wire    [7:0]   acc_res     ;

generate
    if (NUM_INREG == 1) begin : single_inreg
        (* dont_touch = "true" *) fp8_addmul U_FP8_ADDMUL(
            .sys_clk (clk        ),
            .rst_n   (rst_n      ),
            .en      (en_2       ),
            .w_fp8_x (mul_a      ),
            .w_fp8_y (mul_b      ),
            .product (prod_out   )
        );

    end else if (NUM_INREG == 2) begin : double_inreg
        (* dont_touch = "true" *) fp8_addmul U_FP8_ADDMUL(
            .sys_clk (clk        ),
            .rst_n   (rst_n      ),
            .en      (en_2       ),
            .w_fp8_x (ain_r0     ),
            .w_fp8_y (bin_r0     ),
            .product (prod_out   )
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
    end else if (NUM_INREG == 3) begin : triple_inreg
        (* dont_touch = "true" *) fp8_addmul U_FP8_ADDMUL(
            .sys_clk (clk        ),
            .rst_n   (rst_n      ),
            .en      (en_2       ),
            .w_fp8_x (ain_r1     ),
            .w_fp8_y (bin_r1     ),
            .product (prod_out   )
        );

        always @(posedge clk or negedge rst_n) begin
            if(!rst_n) begin
                sum_r2 <= 8'd0;
                sum_r3 <= 8'd0;
                ain_r0 <= 8'b0;
                ain_r1 <= 8'b0;
                bin_r0 <= 8'b0;
                bin_r1 <= 8'b0;
            end else begin
                if (en_1) begin
                    sum_r2 <= sum_r1;
                    sum_r3 <= sum_r2;
                    ain_r0 <= mul_a ;
                    ain_r1 <= ain_r0;
                    bin_r0 <= mul_b ;
                    bin_r1 <= bin_r0;
                end
            end
        end
    end
endgenerate

// Product delay line (free running, no reset: pure time shift of prod_out).
wire [7:0] prod_dl;
generate
    if (PROD_DELAY == 0) begin : no_prod_dl
        assign prod_dl = prod_out;
    end else begin : prod_dl_sr
        fpmac_conv_delay #(.W(8), .N(PROD_DELAY)) u_prod_dl (
            .clk(clk), .en(en), .d(prod_out), .q(prod_dl)
        );
    end
endgenerate

(* dont_touch = "true" *) fp8_adder_pipe#(
    .e      (EXP_WIDTH      ),
    .m      (MANT_WIDTH     ),
    .PIPE   (ADD_PIPE       )
) U_FP8_ADDER(
    .clk    (clk            ),
    .en     (en             ),
    .a      (sum_in         ),
    .b      (prod_dl        ),
    .result (acc_res        )
);

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


// N-cycle delay line, clock-enabled, no reset (Vivado maps it to SRLs).
module fpmac_conv_delay #(
    parameter W = 8,
    parameter N = 1
)(
    input  wire         clk,
    input  wire         en,
    input  wire [W-1:0] d,
    output wire [W-1:0] q
);
    reg [W-1:0] sr [0:N-1];
    integer k;
    always @(posedge clk) if (en) begin
        sr[0] <= d;
        for (k = 1; k < N; k = k + 1) sr[k] <= sr[k-1];
    end
    assign q = sr[N-1];
endmodule
