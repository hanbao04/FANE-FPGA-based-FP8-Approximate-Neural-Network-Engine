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