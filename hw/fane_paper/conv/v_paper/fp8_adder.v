
// 解包模块
module unpack#(
    parameter E = 3,
    parameter M = 4
)(
    input [7:0] a,
    input [7:0] b,

    output signed_a,
    output signed_b,

    output [E-1:0] exp_a,
    output [E-1:0] exp_b,

    output [M-1:0] frac_a,
    output [M-1:0] frac_b

);


    assign signed_a = a[7];
    assign signed_b = b[7];

    assign exp_a = a[6 -: E];
    assign exp_b = b[6 -: E];

    assign frac_a = a[M-1:0];
    assign frac_b = b[M-1:0];

endmodule

// 比较模块
module exp_compare#(
    parameter E = 3,
    parameter M = 4
)(

    input [E-1:0] exp_a,
    input [E-1:0] exp_b,

    output exp_a_notzero, // 阶码是否为0
    output exp_b_notzero,
    output exp_a_larger // a 是否大于 b

);

    assign exp_a_notzero = |exp_a;
    assign exp_b_notzero = |exp_b;
    assign exp_a_larger = (exp_a > exp_b);

endmodule

// 计算阶码差值
module exp_diff#(
    parameter E = 3,
    parameter M = 4
)(
    input [E-1:0] exp_a,
    input [E-1:0] exp_b,

    output [E-1:0] exp_common,

    output [E-1:0] exp_diff,
    input exp_a_larger // a 是否大于 b

);

    mux_add_exp #(
        .WIDTH(E)       
    )u_mux_add_exp(
        .add1         (exp_a         ),
        .add2         (exp_b         ),
        .add1_greater (exp_a_larger ),
        .add_out      (exp_diff      )
    );

    assign exp_common = exp_a_larger ? exp_a : exp_b;

endmodule


module shifter#(
    parameter E = 3,
    parameter M = 4
)(
    input [E-1:0] exp_diff,

    input signed_a,
    input signed_b,

    input signed_xor,

    input exp_a_notzero,
    input exp_b_notzero,

    input exp_a_larger,

    input [M-1:0] frac_a,
    input [M-1:0] frac_b,


    output res_sign,
    output [M + 1: 0] frac_out // 结果输出

);

    wire [M:0] mant_a = {exp_a_notzero, frac_a};
    wire [M:0] mant_b = {exp_b_notzero, frac_b};


    reg [M:0] mant_a_shift_bydiff;
    reg [M:0] mant_b_shift_bydiff;

    always @(*) begin
        case (exp_diff)
            4'd0: begin
                mant_a_shift_bydiff = mant_a;
            end
            4'd1: begin
                mant_a_shift_bydiff = mant_a >> 1;
            end
            4'd2: begin
                mant_a_shift_bydiff = mant_a >> 2;
            end
            4'd3: begin
                mant_a_shift_bydiff = mant_a >> 3;
            end
            4'd4: begin
                mant_a_shift_bydiff = mant_a >> 4;
            end
            default: mant_a_shift_bydiff = 4'd0;
        endcase
    end

    always @(*) begin
        case (exp_diff)
            4'd0: begin
                mant_b_shift_bydiff = mant_b;
            end
            4'd1: begin
                mant_b_shift_bydiff = mant_b >> 1;
            end
            4'd2: begin
                mant_b_shift_bydiff = mant_b >> 2;
            end
            4'd3: begin
                mant_b_shift_bydiff = mant_b >> 3;
            end
            4'd4: begin
                mant_b_shift_bydiff = mant_b >> 4;
            end
            default: mant_b_shift_bydiff = 4'd0;
        endcase
    end

    wire [M:0] mant_a_shifted = exp_a_larger ? mant_a : mant_a_shift_bydiff;
    wire [M:0] mant_b_shifted = exp_a_larger ? mant_b_shift_bydiff : mant_b;

    // 这个路径较长
    wire mant_a_greater = mant_a_shifted > mant_b_shifted;

    assign res_sign = mant_a_greater ? signed_a : signed_b;

    mux_add_mant #(
        .WIDTH(M+1)       
    )u_mux_add_mant(
        .add1         (mant_a_shifted         ),
        .add2         (mant_b_shifted         ),
        .add_flag     ( signed_xor     ),
        .add1_greater (mant_a_greater ),
        .add_out      (frac_out      )
    );


endmodule

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

module pack#(
    parameter E = 3,
    parameter M = 4
)(
    input [M + 1:0] mant_res,

    input res_sign,
    
    input [E-1:0] exp_common,

    output [7:0] result
);


// 规格化处理
    reg [M:0] norm_mant;
    reg [E-1:0] norm_exp;
    wire        norm_sign;
    assign norm_sign = res_sign;

    // 需要进行优化

    // for 循环 将其按并行展开
    // 规格化处理（基于 MSB 位置的 priority encoder）
    always @(*) begin
        if (mant_res[M+1]) begin
            norm_mant = mant_res[M+1:1];  // 溢出，右移 1
            norm_exp  = exp_common + 1;
        end else if (mant_res[M]) begin
            norm_mant = mant_res[M:0];   // 正常
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

    assign result = (mant_res == 0) ? {1'b0, {E{1'b0}}, {M{1'b0}}} :
                    {norm_sign, norm_exp, norm_mant[M-1:0]};



endmodule



module fp8_adder#(
    parameter e = 3,
    parameter m = 4
)(
    input [7:0] a,
    input [7:0] b,

    output [7:0] result
);
    wire signed_a;
    wire signed_b;

    wire signed_xor;

    wire res_sign;

    wire [e-1:0] exp_common;

    wire [e-1:0] exp_a;
    wire [e-1:0] exp_b;

    wire [e-1:0] exp_diff;

    wire [m-1:0] frac_a;
    wire [m-1:0] frac_b;

    wire [m + 1:0] frac_out;

    wire exp_a_notzero;
    wire exp_b_notzero;

    wire exp_a_larger;

    (* dont_touch = "true" *)unpack #(
        .E(e),
        .M(m)
    )u_unpack(
        .a        (a        ),
        .b        (b        ),
        .signed_a (signed_a ),
        .signed_b (signed_b ),
        .exp_a    (exp_a    ),
        .exp_b    (exp_b    ),
        .frac_a   (frac_a   ),
        .frac_b   (frac_b   )
    );

    (* dont_touch = "true" *)exp_compare#(
        .E(e),
        .M(m)
    ) u_exp_compare(
        .exp_a         (exp_a         ),
        .exp_b         (exp_b         ),
        .exp_a_notzero (exp_a_notzero ),
        .exp_b_notzero (exp_b_notzero ),
        .exp_a_larger  (exp_a_larger  )
    );

    (* dont_touch = "true" *)exp_diff#(
        .E(e),
        .M(m)
    ) u_exp_diff(
        .exp_a        (exp_a        ),
        .exp_b        (exp_b        ),
        .exp_common   (exp_common   ),
        .exp_diff     (exp_diff     ),
        .exp_a_larger (exp_a_larger )
    );

    (* dont_touch = "true" *)signed_xor #(
        .E(e),
        .M(m)
    )u_signed_xor(
        .signed_a   (signed_a   ),
        .signed_b   (signed_b   ),
        .signed_xor (signed_xor )
    );
    

    (* dont_touch = "true" *)shifter #(
        .E(e),
        .M(m)
    )u_shifter(
        .exp_diff      (exp_diff      ),
        .signed_a      (signed_a      ),
        .signed_b      (signed_b      ),
        .signed_xor    (signed_xor    ),
        .exp_a_notzero (exp_a_notzero ),
        .exp_b_notzero (exp_b_notzero ),
        .exp_a_larger  (exp_a_larger  ),
        .frac_a        (frac_a        ),
        .frac_b        (frac_b        ),
        .res_sign      (res_sign      ),
        .frac_out      (frac_out      )
    );

    wire [7:0] result_tmp;
    (* dont_touch = "true" *)pack #(
        .E(e),
        .M(m)
    )u_pack(
        .mant_res   (frac_out   ),
        .res_sign   (res_sign   ),
        .exp_common (exp_common ),
        .result     (result )
    );
    


endmodule