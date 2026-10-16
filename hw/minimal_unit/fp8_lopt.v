module fp8_lopt
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

// reg [7:0] bias;

// always @(*) begin
// 	case(m)
// 		3'b001: bias = 8'd31<<m;
// 		3'b010: bias = 8'd15<<m;
// 		3'b011: bias = 8'd7<<m;
// 		3'b100: bias = 8'd3<<m;
// 		3'b101: bias = 8'd1<<m;
// 		3'b110: bias = 8'd0;
// 		default: bias = 8'd0;
// 	endcase
// end

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