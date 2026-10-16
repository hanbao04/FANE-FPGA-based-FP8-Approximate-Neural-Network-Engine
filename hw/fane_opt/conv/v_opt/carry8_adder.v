module carry8_adder #(
    parameter w = 3'd7
)(
    input  wire         CI,
    input  wire [w:0]   x,
    input  wire [w:0]   y,
    output wire [7:0]   O,
    output wire [7:0]   CO
);

wire [7:0] S;
wire [7:0] x_whole;

assign S = (CI == 1'b0) ? x ^ y : x ^ (~y);
assign x_whole = x;

CARRY8 #(
    .CARRY_TYPE("SINGLE_CY8")
) CARRY8_inst (
    .CO     (CO      ),
    .O      (O       ),
    .CI     (CI      ),
    .CI_TOP (1'b0    ),
    .DI     (x_whole ),
    .S      (S       )
);

endmodule
