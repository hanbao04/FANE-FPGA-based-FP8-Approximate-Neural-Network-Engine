`timescale 1ns / 1ps

module fane_conv #(
    parameter A_W = 14,
    parameter M_W = 18,
    parameter NUMBER_OF_REG = 1,
    parameter URAM_D_W = 48,
    parameter URAM_A_W = 14
) (
    input clk,
    input rst,
    input ce,
    input ce_dsp,
    input ce_b_in,
    input [A_W-1:0] b1_wr_addr,
    input b1_wr_en,
    input [A_W-1:0] b2_wr_addr,
    input b2_wr_en,
    input [A_W-1:0] b3_wr_addr,
    input b3_wr_en,
    input [A_W-1:0] b1_rd_addr,
    input [A_W-1:0] b2_rd_addr,
    input [A_W-1:0] b3_rd_addr,
    input [A_W-1:0] rdaddr_b,
    input [15:0] data_in,
    input [A_W-1:0] knl_b_wraddr,
    input [M_W-1:0] knl_b_wrdata,
    input knl_b_wren,
    output reg [15:0] data_out
);

localparam MAC_STAGES = 9;

integer idx;

reg ce_b;
reg ce_b_1;
reg ce_b_2;
reg [M_W-1:0] rd_data_b2_r1;
reg [M_W-1:0] rd_data_b2_r2;
reg [M_W-1:0] rd_data_b2_r3;
reg [M_W-1:0] rd_data_b2_r4;
reg [M_W-1:0] rd_data_b2_r5;
reg [M_W-1:0] rd_data_b3_r1;
reg [M_W-1:0] rd_data_b3_r2;
reg [M_W-1:0] rd_data_b3_r3;
reg [M_W-1:0] rd_data_b3_r4;
reg [M_W-1:0] rd_data_b3_r5;
reg [M_W-1:0] rd_data_b3_r6;
reg [M_W-1:0] rd_data_b3_r7;
reg [M_W-1:0] rd_data_b3_r8;
reg [M_W-1:0] dsp_a1;
reg [M_W-1:0] dsp_a2;
reg [M_W-1:0] dsp_a0_r;
reg [M_W-1:0] dsp_k0_r;
reg [M_W-1:0] dsp_a0_1;
reg [M_W-1:0] dsp_k0_1;
reg [M_W-1:0] dsp_a0_2;
reg [M_W-1:0] dsp_k0_2;
reg ce_dsp_1;
reg ce_dsp_2;
reg start_valid;
reg [7:0] kernel_reg [0:8];

wire [M_W-1:0] casc_data_b1;
wire [M_W-1:0] casc_data_b2;
wire [M_W-1:0] rd_data_b2;
wire [M_W-1:0] rd_data_b3;
wire [M_W-1:0] dsp_a0;
wire [M_W-1:0] dsp_k0;
wire [7:0] mac_sum [0:MAC_STAGES-1];
wire [7:0] mac_a_cascade [0:MAC_STAGES-1];
wire [7:0] mac_b_cascade [0:MAC_STAGES-1];
wire mac_valid [0:MAC_STAGES-1];

generate
if (NUMBER_OF_REG == 1) begin : a0k0_1
    always @(posedge clk) begin
        dsp_a0_r <= dsp_a0;
        dsp_k0_r <= dsp_k0;
        ce_b <= ce_b_in;
        dsp_a1 <= rd_data_b2_r3;
        dsp_a2 <= rd_data_b3_r6;
    end
end
endgenerate

generate
if (NUMBER_OF_REG == 2) begin : a0k0_2
    always @(posedge clk) begin
        dsp_a0_1 <= dsp_a0;
        dsp_k0_1 <= dsp_k0;
        dsp_a0_r <= dsp_a0_1;
        dsp_k0_r <= dsp_k0_1;
        ce_b_1 <= ce_b_in;
        ce_b <= ce_b_1;
        rd_data_b2_r4 <= rd_data_b2_r3;
        dsp_a1 <= rd_data_b2_r4;
        rd_data_b3_r7 <= rd_data_b3_r6;
        dsp_a2 <= rd_data_b3_r7;
    end
end
endgenerate

generate
if (NUMBER_OF_REG == 3) begin : a0k0_3
    always @(posedge clk) begin
        dsp_a0_1 <= dsp_a0;
        dsp_k0_1 <= dsp_k0;
        dsp_a0_2 <= dsp_a0_1;
        dsp_k0_2 <= dsp_k0_1;
        dsp_a0_r <= dsp_a0_2;
        dsp_k0_r <= dsp_k0_2;
        ce_b_1 <= ce_b_in;
        ce_b_2 <= ce_b_1;
        ce_b <= ce_b_2;
        rd_data_b2_r4 <= rd_data_b2_r3;
        rd_data_b2_r5 <= rd_data_b2_r4;
        dsp_a1 <= rd_data_b2_r5;
        rd_data_b3_r7 <= rd_data_b3_r6;
        rd_data_b3_r8 <= rd_data_b3_r7;
        dsp_a2 <= rd_data_b3_r8;
    end
end
endgenerate

always @(posedge clk) begin
    if (rst) begin
        rd_data_b2_r1 <= {M_W{1'b0}};
        rd_data_b2_r2 <= {M_W{1'b0}};
        rd_data_b2_r3 <= {M_W{1'b0}};
        rd_data_b2_r4 <= {M_W{1'b0}};
        rd_data_b2_r5 <= {M_W{1'b0}};
        rd_data_b3_r1 <= {M_W{1'b0}};
        rd_data_b3_r2 <= {M_W{1'b0}};
        rd_data_b3_r3 <= {M_W{1'b0}};
        rd_data_b3_r4 <= {M_W{1'b0}};
        rd_data_b3_r5 <= {M_W{1'b0}};
        rd_data_b3_r6 <= {M_W{1'b0}};
        rd_data_b3_r7 <= {M_W{1'b0}};
        rd_data_b3_r8 <= {M_W{1'b0}};
        ce_dsp_1 <= 1'b0;
        ce_dsp_2 <= 1'b0;
        start_valid <= 1'b0;
        data_out <= 16'd0;
        for (idx = 0; idx < MAC_STAGES; idx = idx + 1) begin
            kernel_reg[idx] <= 8'd0;
        end
    end else begin
        rd_data_b2_r1 <= rd_data_b2;
        rd_data_b2_r2 <= rd_data_b2_r1;
        rd_data_b2_r3 <= rd_data_b2_r2;
        rd_data_b3_r1 <= rd_data_b3;
        rd_data_b3_r2 <= rd_data_b3_r1;
        rd_data_b3_r3 <= rd_data_b3_r2;
        rd_data_b3_r4 <= rd_data_b3_r3;
        rd_data_b3_r5 <= rd_data_b3_r4;
        rd_data_b3_r6 <= rd_data_b3_r5;

        ce_dsp_1 <= ce_dsp;
        ce_dsp_2 <= ce_dsp_1;
        start_valid <= ce_dsp_2;

        if (ce_b) begin
            kernel_reg[0] <= dsp_k0_r[7:0];
            for (idx = 1; idx < MAC_STAGES; idx = idx + 1) begin
                kernel_reg[idx] <= kernel_reg[idx-1];
            end
        end

        if (mac_valid[MAC_STAGES-1]) begin
            data_out <= {8'd0, mac_sum[MAC_STAGES-1]};
        end
    end
end

(* dont_touch = "true" *) RAMB18E2 #(
    .DOA_REG(1), .DOB_REG(1),
    .CASCADE_ORDER_A("FIRST"), .CASCADE_ORDER_B("NONE"),
    .CLOCK_DOMAINS("COMMON"),
    .WRITE_MODE_A("WRITE_FIRST"), .WRITE_MODE_B("WRITE_FIRST"),
    .WRITE_WIDTH_A(18), .WRITE_WIDTH_B(18),
    .READ_WIDTH_A(18), .READ_WIDTH_B(18)
) bram_inst_rdc1 (
    .ADDRARDADDR(b1_rd_addr),
    .ADDRBWRADDR(b1_wr_addr),
    .ADDRENA(1'b1),
    .ADDRENB(1'b1),
    .WEA({2{1'b0}}),
    .WEBWE({4{b1_wr_en}}),
    .CASDOUTA(casc_data_b1[15:0]),
    .CASDOUTPA(casc_data_b1[17:16]),
    .DINBDIN(data_in[15:0]),
    .DINPBDINP(2'b00),
    .CASDIMUXA(1'b0),
    .CASDIMUXB(1'b0),
    .DOUTADOUT(dsp_a0[15:0]),
    .DOUTPADOUTP(dsp_a0[17:16]),
    .CLKARDCLK(clk),
    .CLKBWRCLK(clk),
    .ENARDEN(ce),
    .ENBWREN(ce),
    .REGCEAREGCE(ce),
    .REGCEB(ce),
    .RSTRAMARSTRAM(rst),
    .RSTRAMB(rst),
    .RSTREGARSTREG(rst),
    .RSTREGB(rst)
);

(* dont_touch = "true" *) RAMB18E2 #(
    .DOA_REG(1), .DOB_REG(1),
    .CASCADE_ORDER_A("LAST"), .CASCADE_ORDER_B("FIRST"),
    .CLOCK_DOMAINS("COMMON"),
    .WRITE_MODE_A("WRITE_FIRST"), .WRITE_MODE_B("WRITE_FIRST"),
    .WRITE_WIDTH_A(18), .WRITE_WIDTH_B(18),
    .READ_WIDTH_A(18), .READ_WIDTH_B(18)
) bram_inst_rdc2 (
    .ADDRARDADDR(b2_wr_addr),
    .ADDRBWRADDR(b2_rd_addr),
    .ADDRENA(1'b1),
    .ADDRENB(1'b1),
    .WEA({2{b2_wr_en}}),
    .WEBWE({4{1'b0}}),
    .CASDOUTB(casc_data_b2[15:0]),
    .CASDOUTPB(casc_data_b2[17:16]),
    .CASDINA(casc_data_b1[15:0]),
    .CASDINPA(casc_data_b1[17:16]),
    .CASDIMUXB(1'b0),
    .CASDIMUXA(1'b1),
    .DOUTBDOUT(rd_data_b2[15:0]),
    .DOUTPBDOUTP(rd_data_b2[17:16]),
    .CLKARDCLK(clk),
    .CLKBWRCLK(clk),
    .ENARDEN(ce),
    .ENBWREN(ce),
    .REGCEAREGCE(ce),
    .REGCEB(ce),
    .RSTRAMARSTRAM(rst),
    .RSTRAMB(rst),
    .RSTREGARSTREG(rst),
    .RSTREGB(rst)
);

(* dont_touch = "true" *) RAMB18E2 #(
    .DOA_REG(1), .DOB_REG(1),
    .CASCADE_ORDER_A("NONE"), .CASCADE_ORDER_B("LAST"),
    .CLOCK_DOMAINS("COMMON"),
    .WRITE_MODE_A("WRITE_FIRST"), .WRITE_MODE_B("WRITE_FIRST"),
    .WRITE_WIDTH_A(18), .WRITE_WIDTH_B(18),
    .READ_WIDTH_A(18), .READ_WIDTH_B(18)
) bram_inst_rdc3 (
    .ADDRARDADDR(b3_rd_addr),
    .ADDRBWRADDR(b3_wr_addr),
    .ADDRENA(1'b1),
    .ADDRENB(1'b1),
    .WEA({2{1'b0}}),
    .WEBWE({4{b3_wr_en}}),
    .DOUTADOUT(rd_data_b3[15:0]),
    .DOUTPADOUTP(rd_data_b3[17:16]),
    .CASDINB(casc_data_b2[15:0]),
    .CASDINPB(casc_data_b2[17:16]),
    .DOUTBDOUT(),
    .DOUTPBDOUTP(),
    .CASDIMUXB(1'b1),
    .CASDIMUXA(1'b0),
    .CLKARDCLK(clk),
    .CLKBWRCLK(clk),
    .ENARDEN(ce),
    .ENBWREN(ce),
    .REGCEAREGCE(ce),
    .REGCEB(ce),
    .RSTRAMARSTRAM(rst),
    .RSTRAMB(rst),
    .RSTREGARSTREG(rst),
    .RSTREGB(rst)
);

(* dont_touch = "true" *) RAMB18E2 #(
    .DOA_REG(1), .DOB_REG(1),
    .CASCADE_ORDER_A("NONE"), .CASCADE_ORDER_B("NONE"),
    .CLOCK_DOMAINS("COMMON"),
    .WRITE_WIDTH_A(18), .WRITE_WIDTH_B(18),
    .READ_WIDTH_A(18), .READ_WIDTH_B(18)
) bram_inst_rdc4 (
    .ADDRARDADDR(rdaddr_b),
    .ADDRBWRADDR(knl_b_wraddr),
    .ADDRENA(1'b1),
    .ADDRENB(1'b1),
    .WEA({2{1'b0}}),
    .WEBWE({4{knl_b_wren}}),
    .DOUTADOUT(dsp_k0[15:0]),
    .DOUTPADOUTP(dsp_k0[17:16]),
    .DINBDIN(knl_b_wrdata[15:0]),
    .DINPBDINP(knl_b_wrdata[17:16]),
    .CLKARDCLK(clk),
    .CLKBWRCLK(clk),
    .ENARDEN(ce),
    .ENBWREN(ce),
    .REGCEAREGCE(ce),
    .REGCEB(ce),
    .RSTRAMARSTRAM(rst),
    .RSTRAMB(rst),
    .RSTREGARSTREG(rst),
    .RSTREGB(rst)
);

(* dont_touch = "true" *) fane_mac mac0 (
    .clk(clk),
    .rst_n(~rst),
    .valid_in(start_valid),
    .mul_a(dsp_a0_r[7:0]),
    .mul_b(kernel_reg[0]),
    .cascade_sum_in(8'd0),
    .acc_out(mac_sum[0]),
    .cascade_mula_out(mac_a_cascade[0]),
    .cascade_mulb_out(mac_b_cascade[0]),
    .valid_out(mac_valid[0])
);

(* dont_touch = "true" *) fane_mac mac1 (
    .clk(clk),
    .rst_n(~rst),
    .valid_in(mac_valid[0]),
    .mul_a(mac_a_cascade[0]),
    .mul_b(kernel_reg[1]),
    .cascade_sum_in(mac_sum[0]),
    .acc_out(mac_sum[1]),
    .cascade_mula_out(mac_a_cascade[1]),
    .cascade_mulb_out(mac_b_cascade[1]),
    .valid_out(mac_valid[1])
);

(* dont_touch = "true" *) fane_mac mac2 (
    .clk(clk),
    .rst_n(~rst),
    .valid_in(mac_valid[1]),
    .mul_a(mac_a_cascade[1]),
    .mul_b(kernel_reg[2]),
    .cascade_sum_in(mac_sum[1]),
    .acc_out(mac_sum[2]),
    .cascade_mula_out(mac_a_cascade[2]),
    .cascade_mulb_out(mac_b_cascade[2]),
    .valid_out(mac_valid[2])
);

(* dont_touch = "true" *) fane_mac mac3 (
    .clk(clk),
    .rst_n(~rst),
    .valid_in(mac_valid[2]),
    .mul_a(dsp_a1[7:0]),
    .mul_b(kernel_reg[3]),
    .cascade_sum_in(mac_sum[2]),
    .acc_out(mac_sum[3]),
    .cascade_mula_out(mac_a_cascade[3]),
    .cascade_mulb_out(mac_b_cascade[3]),
    .valid_out(mac_valid[3])
);

(* dont_touch = "true" *) fane_mac mac4 (
    .clk(clk),
    .rst_n(~rst),
    .valid_in(mac_valid[3]),
    .mul_a(mac_a_cascade[3]),
    .mul_b(kernel_reg[4]),
    .cascade_sum_in(mac_sum[3]),
    .acc_out(mac_sum[4]),
    .cascade_mula_out(mac_a_cascade[4]),
    .cascade_mulb_out(mac_b_cascade[4]),
    .valid_out(mac_valid[4])
);

(* dont_touch = "true" *) fane_mac mac5 (
    .clk(clk),
    .rst_n(~rst),
    .valid_in(mac_valid[4]),
    .mul_a(mac_a_cascade[4]),
    .mul_b(kernel_reg[5]),
    .cascade_sum_in(mac_sum[4]),
    .acc_out(mac_sum[5]),
    .cascade_mula_out(mac_a_cascade[5]),
    .cascade_mulb_out(mac_b_cascade[5]),
    .valid_out(mac_valid[5])
);

(* dont_touch = "true" *) fane_mac mac6 (
    .clk(clk),
    .rst_n(~rst),
    .valid_in(mac_valid[5]),
    .mul_a(dsp_a2[7:0]),
    .mul_b(kernel_reg[6]),
    .cascade_sum_in(mac_sum[5]),
    .acc_out(mac_sum[6]),
    .cascade_mula_out(mac_a_cascade[6]),
    .cascade_mulb_out(mac_b_cascade[6]),
    .valid_out(mac_valid[6])
);

(* dont_touch = "true" *) fane_mac mac7 (
    .clk(clk),
    .rst_n(~rst),
    .valid_in(mac_valid[6]),
    .mul_a(mac_a_cascade[6]),
    .mul_b(kernel_reg[7]),
    .cascade_sum_in(mac_sum[6]),
    .acc_out(mac_sum[7]),
    .cascade_mula_out(mac_a_cascade[7]),
    .cascade_mulb_out(mac_b_cascade[7]),
    .valid_out(mac_valid[7])
);

(* dont_touch = "true" *) fane_mac mac8 (
    .clk(clk),
    .rst_n(~rst),
    .valid_in(mac_valid[7]),
    .mul_a(mac_a_cascade[7]),
    .mul_b(kernel_reg[8]),
    .cascade_sum_in(mac_sum[7]),
    .acc_out(mac_sum[8]),
    .cascade_mula_out(mac_a_cascade[8]),
    .cascade_mulb_out(mac_b_cascade[8]),
    .valid_out(mac_valid[8])
);

endmodule
