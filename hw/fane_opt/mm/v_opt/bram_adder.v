`timescale 1ns / 1ps


module bram_adder #(
    parameter e = 4,
    parameter m = 3,
    parameter PIPE = 2
)(
    input              clk,
    input       [7:0]  a,
    input       [7:0]  b,
    output      [7:0]  result
);

    fpadder_pipe #(.e(e), .m(m), .PIPE(PIPE)) u_add (
        .clk   (clk   ),
        .en    (1'b1  ),
        .a     (a     ),
        .b     (b     ),
        .result(result)
    );

endmodule
