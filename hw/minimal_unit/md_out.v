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