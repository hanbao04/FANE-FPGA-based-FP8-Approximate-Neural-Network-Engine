// 替代 DSP48 模块 4周期完成运算 数据输入时刻 结果输出时刻 4级寄存器
module mul_acc_FP8(

    // 数据 同步 输入
    input [7:0] mul_a,// 被乘数
    input [7:0] mul_b,//  乘数

    input mult_b_store,

    // 级联信号
    input [7:0] cascade_sum_in,
    output [7:0] cascade_mula_out,
    output [7:0] cascade_mulb_out,

    // 乘累加结果输出
    output [7:0] acc_out,

    input clk,
    input rst_n
);

    // 被乘数寄存器输入  反推脉动
    reg [7:0] mul_a_reg;
    reg [7:0] mul_a_reg_r1; 
    assign cascade_mula_out = mul_a_reg_r1;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            mul_a_reg <= 0;
            mul_a_reg_r1 <= 0;
        end 
        else begin
            mul_a_reg <= mul_a;
            mul_a_reg_r1 <= mul_a_reg;
        end
    end

    // 乘数的级联输出 做FP8的乘数输入端
    reg [7:0] cascade_b_out_reg;
    assign cascade_mulb_out = cascade_b_out_reg;
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n)begin
            cascade_b_out_reg <= 0;
        end
        else if (mult_b_store) begin
            cascade_b_out_reg <= mul_b;
        end
    end

    // 3周期完成输出
    wire [7:0] fp8_product;
    (* dont_touch = "true" *) fp8_lopt#(
        .e (3'd4),
        .m (3'd3)
    ) u_fp8_lopt(
        .sys_clk (clk ),
        .rst_n   (rst_n   ),
        .w_fp8_x (mul_a_reg ),
        .w_fp8_y (cascade_b_out_reg ),
        .product (fp8_product )
    );

    wire [7:0] sum_result;
    // 采用优化手段

    (* dont_touch = "true" *) FP8_add_Top u_FP8_add_Top(
        .a      (cascade_sum_in      ),
        .b      (fp8_product      ),
        .result (sum_result )
    );
    
    // (* dont_touch = "true" *) fp_add_opt u_fp_add(
    //     .clk      (clk      ),
    //     .rst_n    (rst_n    ),
    //     .a      (cascade_sum_in      ),
    //     .b      (fp8_product      ),
    //     .result (sum_result )
    // );

    reg [7:0] sum_out;
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n)begin
            sum_out <= 0;
        end
        else begin
            sum_out <= sum_result;
        end
    end

    assign acc_out = sum_out;
    

endmodule