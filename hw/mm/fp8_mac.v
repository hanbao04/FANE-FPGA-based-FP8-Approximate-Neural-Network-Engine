module md_in(
	input wire sys_clk,
	input wire rst_n,
	input wire en,
	input wire [7:0] w_fp8_x,
	input wire [7:0] w_fp8_y,
	output reg [7:0] fp8_x,
	output reg [7:0] fp8_y,
	output wire zero		//fp8_x or fp8_y == 0,is 1
);

always @(posedge sys_clk or negedge rst_n) begin
    if(!rst_n) begin
        fp8_x <= 8'd0;
        fp8_y <= 8'd0;
    end
    else begin
		if (en) begin
        fp8_x <= w_fp8_x[7:0];
        fp8_y <= w_fp8_y[7:0]; 
		end
    end
end

wire y_ho;
// LUT3: 3-Bit Look-Up Table
// UltraScale
// Xilinx HDL Language Template, version 2024.1
LUT3 #(
 .INIT(8'h01) // Logic function
)
yzero_LUT3(
 .O(y_ho), // 1-bit output: LUT
 .I0(fp8_y[4]), // 1-bit input: LUT
 .I1(fp8_y[5]), // 1-bit input: LUT
 .I2(fp8_y[6]) // 1-bit input: LUT
);
// End of LUT3_inst instantiation

wire y_lo;
// LUT4: 4-Bit Look-Up Table
// UltraScale
// Xilinx HDL Language Template, version 2024.1
LUT4 #(
 .INIT(16'h0001) // Logic function
)
yzero_LUT4(
 .O(y_lo), // 1-bit output: LUT
 .I0(fp8_y[0]), // 1-bit input: LUT
 .I1(fp8_y[1]), // 1-bit input: LUT
 .I2(fp8_y[2]), // 1-bit input: LUT
 .I3(fp8_y[3]) // 1-bit input: LUT
);
// End of LUT4_inst instantiation

wire x_lo;
// LUT4: 4-Bit Look-Up Table
// UltraScale
// Xilinx HDL Language Template, version 2024.1
LUT4 #(
 .INIT(16'h0001) // Logic function
)
xzero_LUT4(
 .O(x_lo), // 1-bit output: LUT
 .I0(fp8_x[0]), // 1-bit input: LUT
 .I1(fp8_x[1]), // 1-bit input: LUT
 .I2(fp8_x[2]), // 1-bit input: LUT
 .I3(fp8_x[3]) // 1-bit input: LUT
);
// End of LUT4_inst instantiation

// LUT6: 6-Bit Look-Up Table
// UltraScale
// Xilinx HDL Language Template, version 2024.1
LUT6 #(
 .INIT(64'hFFFF010001000100) // Logic function
)
xzero_LUT6(
 .O(zero), // 1-bit output: LUT
 .I0(fp8_x[4]), // 1-bit input: LUT
 .I1(fp8_x[5]), // 1-bit input: LUT
 .I2(fp8_x[6]), // 1-bit input: LUT
 .I3(x_lo), // 1-bit input: LUT
 .I4(y_lo), // 1-bit input: LUT
 .I5(y_ho) // 1-bit input: LUT
);
// End of LUT6_inst instantiation


endmodule

module carry8_adder
#(
	parameter w = 3'd7
)
(
	input wire CI,
	input wire [w:0] x,
	input wire [w:0] y,
	output wire [7:0] O,
	output wire [7:0] CO
);

//wire [w:0] w_S;
wire [7:0] S;
wire [7:0] x_whole;
//assign S = w_S;
assign S = (CI == 1'b0) ? x^y:x^(~y);
assign x_whole = x;

// LUT3: 3-Bit Look-Up Table
// UltraScale
// Xilinx HDL Language Template, version 2024.1
//genvar i;
//generate
//    for( i = 0; i < w+1 ; i = i + 1 ) begin : width_parallel
//        LUT3 #(
//         .INIT(8'h96) // Logic function
//        )
//        LUT3_inst (
//         .O(w_S[i]), // 1-bit output: LUT
//         .I0(y[i]), // 1-bit input: LUT
//         .I1(x[i]), // 1-bit input: LUT
//         .I2(CI) // 1-bit input: LUT
//        );
//    end
//endgenerate
// End of LUT3_inst instantiation

// CARRY8: Fast Carry Logic with Look Ahead
// UltraScale
// Xilinx HDL Language Template, version 2024.1
CARRY8#(
 .CARRY_TYPE("SINGLE_CY8") // 8-bit or dual 4-bit carry (DUAL_CY4, SINGLE_CY8)
)  
CARRY8_inst (
 .CO(CO), // 8-bit output: Carry-out
 .O(O), // 8-bit output: Carry chain XOR data out
 .CI(CI), // 1-bit input: Lower Carry-In
 .CI_TOP(1'b0), // 1-bit input: Upper Carry-In
 .DI(x_whole), // 8-bit input: Carry-MUX data in
 .S(S) // 8-bit input: Carry-mux select
);
// End of CARRY8_inst instantiation
endmodule

module md_out(
	input wire sys_clk,
	input wire rst_n,
	input wire en,
	input wire [7:0] xyaddbias_out,
	input wire fp8_x_sign,
	input wire fp8_y_sign,
	input wire zero,
	output reg [8:0] product
);

wire sign;
wire [7:0] exp_man;

always @(posedge sys_clk or negedge rst_n) begin
	if(!rst_n) begin
		product <= 9'd0;
	end
	else begin
		if (en) begin
		product <= {sign,exp_man};
	
		end
		end
end

// LUT2: 2-Bit Look-Up Table
// UltraScale
// Xilinx HDL Language Template, version 2024.1
genvar i;
generate
    for( i = 0; i < 8 ; i = i + 1 ) begin : exp_man_bits
		LUT3 #(
			.INIT(8'h10)  // Logic function
		)
		LUT3_inst (
			.O (exp_man[i]		),  // 1-bit output: LUT
			.I0(xyaddbias_out[7]), 	// 1-bit input: LUT
			.I1(zero			), 	// 1-bit input: LUT
			.I2(xyaddbias_out[i])  	// 1-bit input: LUT
		);
	end
endgenerate

//sign bit
LUT2 #(
		.INIT(4'h6) // Logic function
		)
		sign_bits_LUT2(
		.O(sign), // 1-bit output: LUT
		.I0(fp8_x_sign), // 1-bit input: LUT
		.I1(fp8_y_sign) // 1-bit input: LUT
		);
// End of LUT2_inst instantiation

endmodule

module addmul
#(
    parameter e = 3'd4,
    parameter m = 3'd3
)
(
	input wire sys_clk,
	input wire rst_n,
	input wire en,
	input wire [7:0] w_fp8_x,
	input wire [7:0] w_fp8_y,
	output wire [7:0] product
);

wire [7:0] fp8_x;
wire [7:0] fp8_y;

wire [7:0] xyadd_out;
wire [7:0] xyaddbias_out;

localparam [7:0] bias = (m == 3'd1) ? (8'd31 << m) :
                        (m == 3'd2) ? (8'd15 << m) :
                        (m == 3'd3) ? (8'd7  << m) :
                        (m == 3'd4) ? (8'd3  << m) :
                        (m == 3'd5) ? (8'd1  << m) :
                        (m == 3'd6) ? 8'd0 :
                        8'd0;

wire zero;
md_in U_GEN_MD_IN(
	.sys_clk	(sys_clk),
	.rst_n		(rst_n	),
	.en(en),
	.w_fp8_x	(w_fp8_x),
	.w_fp8_y	(w_fp8_y),
	.fp8_x	(fp8_x),
	.fp8_y	(fp8_y),
	.zero	(zero)		//fp8_x or fp8_y == 0,is 1
);
wire [8:0] product_tmp;
assign product = {product_tmp[8],product_tmp[6:0]};
md_out U_GEN_MD_OUT(
	.sys_clk	(sys_clk),
	.rst_n		(rst_n	),
	.en(en),
	.xyaddbias_out		(xyaddbias_out),
	.fp8_x_sign		(fp8_x[7]),
	.fp8_y_sign		(fp8_y[7]),
	.zero			(zero),
	.product	 (product_tmp)
);

carry8_adder
#(
	.w(3'd6)
)
U_GEN_CA0(
	.CI	( 1'b0 ),	//CI == 1'b0 is add
	.x	( fp8_x[6:0] ),
	.y	( fp8_y[6:0] ),
	.O	( xyadd_out ),
	.CO	(  )
);

carry8_adder
#(
	.w(3'd7)
)
U_GEN_CA1(
	.CI	( 1'b1 ),	//CI == 1'b0 is add
	.x	( xyadd_out[7:0] ),
	.y	( bias ),
	.O	( xyaddbias_out ),
	.CO	(  )
);

endmodule

module fpadder #(
    parameter e = 4,
    parameter m = 3
)(
    input  wire       clk,
    input  wire       rst_n,
    input  wire       en,
    input  wire [7:0] a,
    input  wire [7:0] b,
    output wire [7:0] result
);

    wire         sign_a = a[7];
    wire         sign_b = b[7];
    wire [e-1:0] exp_a  = a[6 -: e];
    wire [e-1:0] exp_b  = b[6 -: e];
    wire [m-1:0] frac_a = a[m-1:0];
    wire [m-1:0] frac_b = b[m-1:0];

    wire a_mag_ge_b = (exp_a > exp_b) || ((exp_a == exp_b) && (frac_a >= frac_b));

    wire         base_sign  = a_mag_ge_b ? sign_a : sign_b;
    wire         small_sign = a_mag_ge_b ? sign_b : sign_a;
    wire [e-1:0] base_exp   = a_mag_ge_b ? exp_a  : exp_b;
    wire [e-1:0] small_exp  = a_mag_ge_b ? exp_b  : exp_a;
    wire [m-1:0] base_frac  = a_mag_ge_b ? frac_a : frac_b;
    wire [m-1:0] small_frac = a_mag_ge_b ? frac_b : frac_a;

    wire [e-1:0] exp_diff = base_exp - small_exp;
    wire [1:0] diff_bucket = exp_diff[1:0];

    wire [m:0] base_mant = {1'b1, base_frac};
    wire [m:0] small_mant = {1'b1, small_frac};

    reg [m:0] small_mant_shifted;
    always @(*) begin
        case (diff_bucket)
            2'd0: small_mant_shifted = small_mant;
            2'd1: small_mant_shifted = small_mant >> 1;
            2'd2: small_mant_shifted = small_mant >> 2;
            default: small_mant_shifted = small_mant >> 2;
        endcase
    end

    wire same_sign = (base_sign == small_sign);
    wire [m+1:0] mant_add = {1'b0, base_mant} + {1'b0, small_mant_shifted};
    wire [m+1:0] mant_sub = {1'b0, base_mant} - {1'b0, small_mant_shifted};
    wire [e-1:0] exp_inc = base_exp + {{(e-1){1'b0}}, 1'b1};
    wire [e-1:0] exp_dec = base_exp - {{(e-1){1'b0}}, 1'b1};

    reg [7:0] approx_result;
    always @(*) begin
        if (same_sign) begin
            if (mant_add[m+1]) begin
                approx_result = {base_sign, exp_inc, mant_add[m:1]};
            end else begin
                approx_result = {base_sign, base_exp, mant_add[m-1:0]};
            end
        end else begin
            if (mant_sub[m:0] == {(m+1){1'b0}}) begin
                approx_result = 8'd0;
            end else if (mant_sub[m]) begin
                approx_result = {base_sign, base_exp, mant_sub[m-1:0]};
            end else if (mant_sub[m-1]) begin
                approx_result = {base_sign, exp_dec, mant_sub[m-2:0], 1'b0};
            end else begin
                approx_result = {base_sign, exp_dec, {m{1'b0}}};
            end
        end
    end

    assign result = approx_result;

endmodule

`timescale 1ns / 1ps

module fpmac#(
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
    if (NUM_INREG == 1) begin : signle_inreg
        (* dont_touch = "true" *) addmul  #(
            .e      (EXP_WIDTH      ),
            .m      (MANT_WIDTH     )
        ) U_FP8_ADDMUL (
            .sys_clk (clk        ),
            .rst_n   (rst_n      ),
            .en      (en_2       ),
            .w_fp8_x (mul_a      ),
            .w_fp8_y (mul_b      ),
            .product (prod_out   )
        );

        (* dont_touch = "true" *)fpadder #(
            .e      (EXP_WIDTH      ),
            .m      (MANT_WIDTH     )
        ) U_FP8_ADDER (
            .clk    (clk            ),
            .rst_n  (rst_n          ),
            .en     (en             ),
            .a      (sum_r1         ),
            .b      (prod_out       ),
            .result (acc_res        )
        );
    end else if (NUM_INREG == 2) begin : dou_inreg
         (* dont_touch = "true" *) addmul  #(
            .e      (EXP_WIDTH      ),
            .m      (MANT_WIDTH     )
        ) U_FP8_ADDMUL (
            .sys_clk (clk        ),
            .rst_n   (rst_n      ),
            .en      (en_2       ),
            .w_fp8_x (ain_r0     ),
            .w_fp8_y (bin_r0     ),
            .product (prod_out   )
        );

        (* dont_touch = "true" *) fpadder #(
            .e      (EXP_WIDTH      ),
            .m      (MANT_WIDTH     )
        ) U_FP8_ADDER (
            .clk    (clk            ),
            .rst_n  (rst_n          ),
            .en     (en             ),
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
