module md_in(
	input wire sys_clk,
	input wire rst_n,
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
        fp8_x <= w_fp8_x[7:0];
        fp8_y <= w_fp8_y[7:0]; 
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
		product <= {sign,exp_man};
	end
end

// LUT2: 2-Bit Look-Up Table
// UltraScale
// Xilinx HDL Language Template, version 2024.1
genvar i;
generate
    for( i = 0; i < 8 ; i = i + 1 ) begin : exp_man_bits
		LUT2 #(
		.INIT(4'h2) // Logic function
		)
		exp_bits_LUT2(
		.O(exp_man[i]), // 1-bit output: LUT
		.I0(xyaddbias_out[i]), // 1-bit input: LUT
		.I1(zero) // 1-bit input: LUT
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

module fp8_addmul
#(
    parameter e = 3'd4,
    parameter m = 3'd3
)
(
	input wire sys_clk,
	input wire rst_n,
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