// ========================= UNPACK MODULE =========================
// Extract sign, exponent, and fraction fields from FP8 inputs
module unpack#(
    parameter E = 3,   // Exponent width
    parameter M = 4    // Mantissa width (fraction bits)
)(
    input [7:0] a,
    input [7:0] b,

    output signed_a,       // Sign bit of a
    output signed_b,       // Sign bit of b

    output [E-1:0] exp_a,  // Exponent of a
    output [E-1:0] exp_b,  // Exponent of b

    output [M-1:0] frac_a, // Fraction (mantissa) of a
    output [M-1:0] frac_b  // Fraction (mantissa) of b
);

    // Sign bit: MSB
    assign signed_a = a[7];
    assign signed_b = b[7];

    // Exponent field
    assign exp_a = a[6 -: E];
    assign exp_b = b[6 -: E];

    // Fraction field (mantissa)
    assign frac_a = a[M-1:0];
    assign frac_b = b[M-1:0];

endmodule


// ========================= EXPONENT COMPARE MODULE =========================
// Compare exponent fields and detect whether they are zero
module exp_compare#(
    parameter E = 3,
    parameter M = 4
)(
    input [E-1:0] exp_a,
    input [E-1:0] exp_b,

    output exp_a_notzero,  // Exponent of a is non-zero
    output exp_b_notzero,  // Exponent of b is non-zero
    output exp_a_larger    // exp(a) > exp(b)
);

    assign exp_a_notzero = |exp_a;   // Detect denormal
    assign exp_b_notzero = |exp_b;

    assign exp_a_larger = (exp_a > exp_b);

endmodule


// ========================= EXPONENT DIFFERENCE MODULE =========================
// Compute delta exponent and the common exponent for alignment
module exp_diff#(
    parameter E = 3,
    parameter M = 4
)(
    input [E-1:0] exp_a,
    input [E-1:0] exp_b,

    output [E-1:0] exp_common, // Larger exponent (final exponent before normalization)
    output [E-1:0] exp_diff,   // Exponent difference
    input exp_a_larger         // a has larger exponent
);

    // Use mux-add module to compute |exp_a - exp_b|
    mux_add_exp #(
        .WIDTH(E)
    )u_mux_add_exp(
        .add1         (exp_a        ),
        .add2         (exp_b        ),
        .add1_greater (exp_a_larger ),
        .add_out      (exp_diff     )
    );

    // Select the larger exponent as the shared exponent
    assign exp_common = exp_a_larger ? exp_a : exp_b;

endmodule


// ========================= MANTISSA ALIGNMENT & ADDITION MODULE =========================
// Align mantissas based on exponent difference, compute sign, and perform add/sub
module shifter#(
    parameter E = 3,
    parameter M = 4
)(
    input [E-1:0] exp_diff,

    input signed_a,
    input signed_b,

    input signed_xor,       // Indicates addition or subtraction

    input exp_a_notzero,
    input exp_b_notzero,

    input exp_a_larger,

    input [M-1:0] frac_a,
    input [M-1:0] frac_b,

    output res_sign,          // Sign of result
    output [M + 1: 0] frac_out // Unnormalized mantissa output
);

    // Build mantissas with implicit leading 1 for normalized values
    wire [M:0] mant_a = {exp_a_notzero, frac_a};
    wire [M:0] mant_b = {exp_b_notzero, frac_b};

    // Right-shift mantissas according to exponent difference
    reg [M:0] mant_a_shift_bydiff;
    reg [M:0] mant_b_shift_bydiff;

    // Shift table for mant_a
    always @(*) begin
        case (exp_diff)
            4'd0: mant_a_shift_bydiff = mant_a;
            4'd1: mant_a_shift_bydiff = mant_a >> 1;
            4'd2: mant_a_shift_bydiff = mant_a >> 2;
            4'd3: mant_a_shift_bydiff = mant_a >> 3;
            4'd4: mant_a_shift_bydiff = mant_a >> 4;
            default: mant_a_shift_bydiff = 4'd0;
        endcase
    end

    // Shift table for mant_b
    always @(*) begin
        case (exp_diff)
            4'd0: mant_b_shift_bydiff = mant_b;
            4'd1: mant_b_shift_bydiff = mant_b >> 1;
            4'd2: mant_b_shift_bydiff = mant_b >> 2;
            4'd3: mant_b_shift_bydiff = mant_b >> 3;
            4'd4: mant_b_shift_bydiff = mant_b >> 4;
            default: mant_b_shift_bydiff = 4'd0;
        endcase
    end

    // Select which mantissa gets shifted
    wire [M:0] mant_a_shifted = exp_a_larger ? mant_a : mant_a_shift_bydiff;
    wire [M:0] mant_b_shifted = exp_a_larger ? mant_b_shift_bydiff : mant_b;

    // Determine which mantissa is larger after alignment
    wire mant_a_greater = mant_a_shifted > mant_b_shifted;

    // Result sign
    assign res_sign = mant_a_greater ? signed_a : signed_b;

    // Perform mantissa add/sub using muxed LUT + carry chain
    mux_add_mant #(
        .WIDTH(M+1)
    )u_mux_add_mant(
        .add1         (mant_a_shifted ),
        .add2         (mant_b_shifted ),
        .add_flag     (signed_xor     ),
        .add1_greater (mant_a_greater ),
        .add_out      (frac_out       )
    );

endmodule


// ========================= SIGN XOR MODULE =========================
// Determines whether addition or subtraction is needed
module signed_xor#(
    parameter E = 3,
    parameter M = 4
)(
    input signed_a,
    input signed_b,

    output signed_xor
);

    assign signed_xor = signed_a ^ signed_b;

endmodule


// ========================= PACK MODULE =========================
// Reconstruct FP8 number from normalized mantissa, exponent, and sign
module pack#(
    parameter E = 3,
    parameter M = 4
)(
    input [M + 1:0] mant_res, // Unnormalized mantissa
    input res_sign,
    input [E-1:0] exp_common,

    output [7:0] result
);

    // Normalization logic
    reg [M:0] norm_mant;
    reg [E-1:0] norm_exp;
    wire norm_sign = res_sign;

    // Priority-based normalization
    always @(*) begin
        if (mant_res[M+1]) begin
            norm_mant = mant_res[M+1:1];  // Overflow → shift right
            norm_exp  = exp_common + 1;
        end else if (mant_res[M]) begin
            norm_mant = mant_res[M:0];    // Normal case
            norm_exp  = exp_common;
        end else if (mant_res[M-1]) begin
            norm_mant = mant_res[M-1:0] << 1;
            norm_exp  = exp_common - 1;
        end else if (mant_res[M-2]) begin
            norm_mant = mant_res[M-2:0] << 2;
            norm_exp  = exp_common - 2;
        end else begin
            norm_mant = 0;
            norm_exp  = 0;
        end
    end

    // Output FP8 number
    assign result = (mant_res == 0) ? {1'b0, {E{1'b0}}, {M{1'b0}}} :
                    {norm_sign, norm_exp, norm_mant[M-1:0]};

endmodule



// ========================= MUX-BASED EXPONENT ADDER =========================
// Implement addition/subtraction using LUT6_2 + CARRY8 fast carry chain
module mux_add_exp#(
    parameter WIDTH = 4
)(
    input   [WIDTH - 1:0] add1,
    input   [WIDTH - 1:0] add2,
    input                 add1_greater, // Select subtract direction
    output  [WIDTH: 0]    add_out
);

    wire    [WIDTH: 0] S0;
    wire    [WIDTH: 0] op_b_inv;

    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin
            LUT6_2 #(
                .INIT(64'h0000_0099_0000_0053)
            ) LUT6_2_inst (
                .O5(op_b_inv[i]),
                .O6(S0[i]),
                .I0(add2[i]),
                .I1(add1[i]),
                .I2(add1_greater),
                .I3(1'b0),
                .I4(1'b0),
                .I5(1'b1)
            );
        end
    endgenerate

    wire [7:0] CO;
    wire [7:0] O;

    CARRY8 #(
        .CARRY_TYPE("SINGLE_CY8")
    ) CARRY8_inst (
        .CO(CO),
        .O(O),
        .CI(1'b1),
        .CI_TOP(1'b0),
        .DI(op_b_inv),
        .S(S0)
    );

    assign add_out = O[WIDTH:0];

endmodule



// ========================= MUX-BASED MANTISSA ADD/SUB =========================
// Supports both addition and subtraction of mantissas
module mux_add_mant#(
    parameter WIDTH = 4
)(
    input   [WIDTH - 1:0] add1,
    input   [WIDTH - 1:0] add2,
    input                 add_flag,       // 1: subtract, 0: add
    input                 add1_greater,   // Result negation flag
    output  [WIDTH: 0]    add_out
);

    wire [WIDTH: 0] S0;
    wire [WIDTH: 0] op_b_inv;

    assign S0[WIDTH]       = add_flag;
    assign op_b_inv[WIDTH] = add_flag;

    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin
            LUT6_2 #(
                .INIT(64'h0000_9696_0000_5A3A)
            ) LUT6_2_inst (
                .O5(op_b_inv[i]),
                .O6(S0[i]),
                .I0(add2[i]),
                .I1(add1[i]),
                .I2(add_flag),
                .I3(add1_greater),
                .I4(1'b0),
                .I5(1'b1)
            );
        end
    endgenerate

    wire [7:0] CO;
    wire [7:0] O;

    CARRY8 #(
        .CARRY_TYPE("SINGLE_CY8")
    ) CARRY8_inst (
        .CO(CO),
        .O(O),
        .CI(add_flag),
        .CI_TOP(1'b0),
        .DI(op_b_inv),
        .S(S0)
    );

    assign add_out = O[WIDTH:0];

endmodule



// ========================= TOP FP8 ADDER =========================
// Full FP8 addition pipeline: unpack → compare → align → add → normalize → pack
module fpadder#(
    parameter e = 3,
    parameter m = 4
)(
    input [7:0] a,
    input [7:0] b,

    output [7:0] result
);

    wire signed_a, signed_b;
    wire signed_xor;
    wire res_sign;

    wire [e-1:0] exp_common;
    wire [e-1:0] exp_a, exp_b;
    wire [e-1:0] exp_diff;

    wire [m-1:0] frac_a, frac_b;
    wire [m+1:0] frac_out;

    wire exp_a_notzero, exp_b_notzero;
    wire exp_a_larger;

    // Unpack fields
    unpack #(
        .E(e), .M(m)
    ) u_unpack (
        .a(a),
        .b(b),
        .signed_a(signed_a),
        .signed_b(signed_b),
        .exp_a(exp_a),
        .exp_b(exp_b),
        .frac_a(frac_a),
        .frac_b(frac_b)
    );

    // Compare exponents
    exp_compare #(
        .E(e), .M(m)
    ) u_exp_compare(
        .exp_a(exp_a),
        .exp_b(exp_b),
        .exp_a_notzero(exp_a_notzero),
        .exp_b_notzero(exp_b_notzero),
        .exp_a_larger(exp_a_larger)
    );

    // Compute exponent difference
    exp_diff #(
        .E(e), .M(m)
    ) u_exp_diff(
        .exp_a(exp_a),
        .exp_b(exp_b),
        .exp_common(exp_common),
        .exp_diff(exp_diff),
        .exp_a_larger(exp_a_larger)
    );

    // Determine add or subtract
    signed_xor #(
        .E(e), .M(m)
    ) u_signed_xor (
        .signed_a(signed_a),
        .signed_b(signed_b),
        .signed_xor(signed_xor)
    );

    // Align fractions and perform mantissa operation
    shifter #(
        .E(e), .M(m)
    ) u_shifter (
        .exp_diff(exp_diff),
        .signed_a(signed_a),
        .signed_b(signed_b),
        .signed_xor(signed_xor),
        .exp_a_notzero(exp_a_notzero),
        .exp_b_notzero(exp_b_notzero),
        .exp_a_larger(exp_a_larger),
        .frac_a(frac_a),
        .frac_b(frac_b),
        .res_sign(res_sign),
        .frac_out(frac_out)
    );

    // Pack final result
    pack #(
        .E(e), .M(m)
    ) u_pack (
        .mant_res(frac_out),
        .res_sign(res_sign),
        .exp_common(exp_common),
        .result(result)
    );

endmodule


// ========================= SHIFTER, SPLIT IN TWO =========================
// shifter_align + shifter_add together are bit-identical to `shifter` above;
// the split only exposes the point (aligned mantissas + magnitude compare)
// where fpadder_pipe places a pipeline register.
module shifter_align#(
    parameter E = 3,
    parameter M = 4
)(
    input [E-1:0] exp_diff,
    input exp_a_notzero,
    input exp_b_notzero,
    input exp_a_larger,
    input [M-1:0] frac_a,
    input [M-1:0] frac_b,

    output [M:0] mant_a_shifted,
    output [M:0] mant_b_shifted
);

    wire [M:0] mant_a = {exp_a_notzero, frac_a};
    wire [M:0] mant_b = {exp_b_notzero, frac_b};

    reg [M:0] mant_a_shift_bydiff;
    reg [M:0] mant_b_shift_bydiff;

    always @(*) begin
        case (exp_diff)
            4'd0: mant_a_shift_bydiff = mant_a;
            4'd1: mant_a_shift_bydiff = mant_a >> 1;
            4'd2: mant_a_shift_bydiff = mant_a >> 2;
            4'd3: mant_a_shift_bydiff = mant_a >> 3;
            4'd4: mant_a_shift_bydiff = mant_a >> 4;
            default: mant_a_shift_bydiff = 4'd0;
        endcase
    end

    always @(*) begin
        case (exp_diff)
            4'd0: mant_b_shift_bydiff = mant_b;
            4'd1: mant_b_shift_bydiff = mant_b >> 1;
            4'd2: mant_b_shift_bydiff = mant_b >> 2;
            4'd3: mant_b_shift_bydiff = mant_b >> 3;
            4'd4: mant_b_shift_bydiff = mant_b >> 4;
            default: mant_b_shift_bydiff = 4'd0;
        endcase
    end

    assign mant_a_shifted = exp_a_larger ? mant_a : mant_a_shift_bydiff;
    assign mant_b_shifted = exp_a_larger ? mant_b_shift_bydiff : mant_b;

endmodule


module shifter_add#(
    parameter E = 3,
    parameter M = 4
)(
    input signed_a,
    input signed_b,
    input signed_xor,
    input [M:0] mant_a_shifted,
    input [M:0] mant_b_shifted,
    input mant_a_greater,

    output res_sign,
    output [M + 1: 0] frac_out
);

    assign res_sign = mant_a_greater ? signed_a : signed_b;

    mux_add_mant #(
        .WIDTH(M+1)
    )u_mux_add_mant(
        .add1         (mant_a_shifted ),
        .add2         (mant_b_shifted ),
        .add_flag     (signed_xor     ),
        .add1_greater (mant_a_greater ),
        .add_out      (frac_out       )
    );

endmodule


// ========================= PIPELINED FP8 ADDER =========================
// Same arithmetic as `fpadder` (built from the very same sub-modules), cut into
//   S1: unpack, exponent compare, exponent difference (CARRY8), sign xor
//   S2: mantissa alignment + magnitude compare
//   S3: mantissa add/sub (LUT6_2+CARRY8), normalise/pack
// PIPE = number of register ranks inside the adder (latency of `result`):
//   0 : purely combinational (identical to fpadder)
//   1 : one rank, between S2 and S3
//   2 : ranks between S1|S2 and S2|S3   (3 balanced stages, recommended)
// `en` is a clock enable for the internal ranks. The ranks have no reset: the
// pipeline is feed-forward, so it flushes itself within PIPE cycles.
module fpadder_pipe#(
    parameter e = 3,
    parameter m = 4,
    parameter PIPE = 2
)(
    input clk,
    input en,
    input [7:0] a,
    input [7:0] b,

    output [7:0] result
);

    // ---------------- S1 ----------------
    wire signed_a, signed_b, signed_xor;
    wire [e-1:0] exp_a, exp_b, exp_common, exp_diff;
    wire [m-1:0] frac_a, frac_b;
    wire exp_a_notzero, exp_b_notzero, exp_a_larger;

    unpack #(.E(e), .M(m)) u_unpack (
        .a(a), .b(b),
        .signed_a(signed_a), .signed_b(signed_b),
        .exp_a(exp_a), .exp_b(exp_b),
        .frac_a(frac_a), .frac_b(frac_b)
    );

    exp_compare #(.E(e), .M(m)) u_exp_compare(
        .exp_a(exp_a), .exp_b(exp_b),
        .exp_a_notzero(exp_a_notzero),
        .exp_b_notzero(exp_b_notzero),
        .exp_a_larger(exp_a_larger)
    );

    exp_diff #(.E(e), .M(m)) u_exp_diff(
        .exp_a(exp_a), .exp_b(exp_b),
        .exp_common(exp_common),
        .exp_diff(exp_diff),
        .exp_a_larger(exp_a_larger)
    );

    signed_xor #(.E(e), .M(m)) u_signed_xor (
        .signed_a(signed_a), .signed_b(signed_b), .signed_xor(signed_xor)
    );

    // ---------------- rank R1 (S1 | S2) ----------------
    wire [e-1:0] s2_exp_diff, s2_exp_common;
    wire         s2_signed_a, s2_signed_b, s2_signed_xor;
    wire         s2_nza, s2_nzb, s2_larger;
    wire [m-1:0] s2_frac_a, s2_frac_b;

    generate if (PIPE >= 2) begin : g_r1
        reg [e-1:0] exp_diff_r, exp_common_r;
        reg         signed_a_r, signed_b_r, signed_xor_r;
        reg         nza_r, nzb_r, larger_r;
        reg [m-1:0] frac_a_r, frac_b_r;
        always @(posedge clk) if (en) begin
            exp_diff_r   <= exp_diff;
            exp_common_r <= exp_common;
            signed_a_r   <= signed_a;
            signed_b_r   <= signed_b;
            signed_xor_r <= signed_xor;
            nza_r        <= exp_a_notzero;
            nzb_r        <= exp_b_notzero;
            larger_r     <= exp_a_larger;
            frac_a_r     <= frac_a;
            frac_b_r     <= frac_b;
        end
        assign s2_exp_diff   = exp_diff_r;
        assign s2_exp_common = exp_common_r;
        assign s2_signed_a   = signed_a_r;
        assign s2_signed_b   = signed_b_r;
        assign s2_signed_xor = signed_xor_r;
        assign s2_nza        = nza_r;
        assign s2_nzb        = nzb_r;
        assign s2_larger     = larger_r;
        assign s2_frac_a     = frac_a_r;
        assign s2_frac_b     = frac_b_r;
    end else begin : g_r1_bypass
        assign s2_exp_diff   = exp_diff;
        assign s2_exp_common = exp_common;
        assign s2_signed_a   = signed_a;
        assign s2_signed_b   = signed_b;
        assign s2_signed_xor = signed_xor;
        assign s2_nza        = exp_a_notzero;
        assign s2_nzb        = exp_b_notzero;
        assign s2_larger     = exp_a_larger;
        assign s2_frac_a     = frac_a;
        assign s2_frac_b     = frac_b;
    end endgenerate

    // ---------------- S2 ----------------
    wire [m:0] mant_a_shifted, mant_b_shifted;

    shifter_align #(.E(e), .M(m)) u_align (
        .exp_diff      (s2_exp_diff   ),
        .exp_a_notzero (s2_nza        ),
        .exp_b_notzero (s2_nzb        ),
        .exp_a_larger  (s2_larger     ),
        .frac_a        (s2_frac_a     ),
        .frac_b        (s2_frac_b     ),
        .mant_a_shifted(mant_a_shifted),
        .mant_b_shifted(mant_b_shifted)
    );

    wire mant_a_greater = mant_a_shifted > mant_b_shifted;

    // ---------------- rank R2 (S2 | S3) ----------------
    wire [e-1:0] s3_exp_common;
    wire         s3_signed_a, s3_signed_b, s3_signed_xor, s3_greater;
    wire [m:0]   s3_mant_a, s3_mant_b;

    generate if (PIPE >= 1) begin : g_r2
        reg [e-1:0] exp_common_r;
        reg         signed_a_r, signed_b_r, signed_xor_r, greater_r;
        reg [m:0]   mant_a_r, mant_b_r;
        always @(posedge clk) if (en) begin
            exp_common_r <= s2_exp_common;
            signed_a_r   <= s2_signed_a;
            signed_b_r   <= s2_signed_b;
            signed_xor_r <= s2_signed_xor;
            greater_r    <= mant_a_greater;
            mant_a_r     <= mant_a_shifted;
            mant_b_r     <= mant_b_shifted;
        end
        assign s3_exp_common = exp_common_r;
        assign s3_signed_a   = signed_a_r;
        assign s3_signed_b   = signed_b_r;
        assign s3_signed_xor = signed_xor_r;
        assign s3_greater    = greater_r;
        assign s3_mant_a     = mant_a_r;
        assign s3_mant_b     = mant_b_r;
    end else begin : g_r2_bypass
        assign s3_exp_common = s2_exp_common;
        assign s3_signed_a   = s2_signed_a;
        assign s3_signed_b   = s2_signed_b;
        assign s3_signed_xor = s2_signed_xor;
        assign s3_greater    = mant_a_greater;
        assign s3_mant_a     = mant_a_shifted;
        assign s3_mant_b     = mant_b_shifted;
    end endgenerate

    // ---------------- S3 ----------------
    wire res_sign;
    wire [m+1:0] frac_out;

    shifter_add #(.E(e), .M(m)) u_add (
        .signed_a      (s3_signed_a  ),
        .signed_b      (s3_signed_b  ),
        .signed_xor    (s3_signed_xor),
        .mant_a_shifted(s3_mant_a    ),
        .mant_b_shifted(s3_mant_b    ),
        .mant_a_greater(s3_greater   ),
        .res_sign      (res_sign     ),
        .frac_out      (frac_out     )
    );

    pack #(.E(e), .M(m)) u_pack (
        .mant_res  (frac_out     ),
        .res_sign  (res_sign     ),
        .exp_common(s3_exp_common),
        .result    (result       )
    );

endmodule
