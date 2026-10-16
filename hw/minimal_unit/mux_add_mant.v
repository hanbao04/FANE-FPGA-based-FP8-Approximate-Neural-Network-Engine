module mux_add_mant#(
    parameter WIDTH = 4
)(
    input [ WIDTH-1:0 ] add1,
    input [ WIDTH-1:0 ] add2,
    input add_flag, // 1 为减法， 0 为加法
    input add1_greater, // 输出结果取负
    output [ WIDTH : 0 ] add_out
);

    wire [4:0] S0;
    wire [4:0] op_b_inv; 

    assign S0[4] = add_flag;
    assign op_b_inv[4] = add_flag;

    genvar i;
    generate 
        for (i = 0; i<  4 ; i = i + 1) begin
            LUT6_2 #(
                .INIT(64'h0000_9696_0000_5A3A) // Specify LUT Contents
            ) LUT6_2_inst (
                .O5(op_b_inv[i]), // 1-bit LUT6 output
                .O6(S0[i]), // 1-bit lower LUT5 output
                .I0(add2[i]), // 1-bit LUT input
                .I1(add1[i]), // 1-bit LUT input
                .I2(add_flag), // 1-bit LUT input
                .I3(add1_greater), // 1-bit LUT input
                .I4(1'b0), // 1-bit LUT input
                .I5(1'b1)  // 1-bit LUT input (fast MUX select only available to O6 output)
            );
        end

    endgenerate

    wire [7:0] CO;
    wire [7:0] O;

    // 提高复用性
    CARRY8 #(
        .CARRY_TYPE("SINGLE_CY8") // 8-bit or dual 4-bit carry (DUAL_CY4, SINGLE_CY8)
    )
    CARRY8_inst (
        .CO(CO), // 8-bit output: Carry-out
        .O(O), // 8-bit output: Carry chain XOR data out
        .CI(add_flag), // 1-bit input: Lower Carry-In
        .CI_TOP(1'b0), // 1-bit input: Upper Carry-In
        .DI(op_b_inv), // 8-bit input: Carry-MUX data in
        .S(S0) // 8-bit input: Carry-MUX selectmux select
    );

    assign add_out = O[4:0];


endmodule