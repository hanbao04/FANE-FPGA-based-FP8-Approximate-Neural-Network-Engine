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