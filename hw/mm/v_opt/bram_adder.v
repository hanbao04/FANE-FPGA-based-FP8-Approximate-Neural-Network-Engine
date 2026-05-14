`timescale 1ns / 1ps

// Pipelined FP8 adder: splits combinational path between exp_diff and shifter.
// Stage 1 (1 cycle): unpack → exp_compare → exp_diff(CARRY8)   ~4 logic levels
// Stage 2 (1 cycle): shifter(CARRY8) → pack                    ~6 logic levels
// Total latency: 2 cycles. Use in place of fpadder where timing is critical.
module bram_adder #(
    parameter e = 4,
    parameter m = 3
)(
    input              clk,
    input       [7:0]  a,
    input       [7:0]  b,
    output      [7:0]  result
);

    // ---- Stage 1: unpack → exp_compare → exp_diff (combinational) ----

    wire s_signed_a, s_signed_b, s_signed_xor;
    wire [e-1:0] s_exp_a, s_exp_b;
    wire [e-1:0] s_exp_common_c, s_exp_diff_c;
    wire [m-1:0] s_frac_a, s_frac_b;
    wire s_exp_a_notzero, s_exp_b_notzero, s_exp_a_larger;

    unpack #(.E(e), .M(m)) u_unpack (
        .a          (a              ),
        .b          (b              ),
        .signed_a   (s_signed_a     ),
        .signed_b   (s_signed_b     ),
        .exp_a      (s_exp_a        ),
        .exp_b      (s_exp_b        ),
        .frac_a     (s_frac_a       ),
        .frac_b     (s_frac_b       )
    );

    exp_compare #(.E(e), .M(m)) u_exp_compare (
        .exp_a        (s_exp_a        ),
        .exp_b        (s_exp_b        ),
        .exp_a_notzero(s_exp_a_notzero),
        .exp_b_notzero(s_exp_b_notzero),
        .exp_a_larger (s_exp_a_larger )
    );

    exp_diff #(.E(e), .M(m)) u_exp_diff (
        .exp_a       (s_exp_a        ),
        .exp_b       (s_exp_b        ),
        .exp_common  (s_exp_common_c ),
        .exp_diff    (s_exp_diff_c   ),
        .exp_a_larger(s_exp_a_larger )
    );

    signed_xor #(.E(e), .M(m)) u_signed_xor (
        .signed_a  (s_signed_a  ),
        .signed_b  (s_signed_b  ),
        .signed_xor(s_signed_xor)
    );

    // ---- Pipeline register (between exp_diff and shifter) ----
    reg [e-1:0] exp_diff_r;
    reg [e-1:0] exp_common_r;
    reg         signed_a_r, signed_b_r, signed_xor_r;
    reg         exp_a_notzero_r, exp_b_notzero_r, exp_a_larger_r;
    reg [m-1:0] frac_a_r, frac_b_r;

    always @(posedge clk) begin
        exp_diff_r      <= s_exp_diff_c;
        exp_common_r    <= s_exp_common_c;
        signed_a_r      <= s_signed_a;
        signed_b_r      <= s_signed_b;
        signed_xor_r    <= s_signed_xor;
        exp_a_notzero_r <= s_exp_a_notzero;
        exp_b_notzero_r <= s_exp_b_notzero;
        exp_a_larger_r  <= s_exp_a_larger;
        frac_a_r        <= s_frac_a;
        frac_b_r        <= s_frac_b;
    end

    // ---- Stage 2: shifter → pack (combinational) ----
    wire s_res_sign;
    wire [m+1:0] s_frac_out;

    shifter #(.E(e), .M(m)) u_shifter (
        .exp_diff     (exp_diff_r     ),
        .signed_a     (signed_a_r     ),
        .signed_b     (signed_b_r     ),
        .signed_xor   (signed_xor_r   ),
        .exp_a_notzero(exp_a_notzero_r),
        .exp_b_notzero(exp_b_notzero_r),
        .exp_a_larger (exp_a_larger_r ),
        .frac_a       (frac_a_r       ),
        .frac_b       (frac_b_r       ),
        .res_sign     (s_res_sign     ),
        .frac_out     (s_frac_out     )
    );

    pack #(.E(e), .M(m)) u_pack (
        .mant_res  (s_frac_out  ),
        .res_sign  (s_res_sign  ),
        .exp_common(exp_common_r),
        .result    (result      )
    );

endmodule