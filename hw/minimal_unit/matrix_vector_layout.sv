module matrix_vector_cross( // 不按其两个读取的方式进行写
    input [8:0] bvector_wr_en,
    input [8:0] [13:0] bvector_wr_addr,
    input [7:0] bvector_wr_din, // 只有一位需要写入，其他都是串行寄存

    input [13:0] bvector_wr_addr_1,
    input [7:0] bvector_wr_din_1, // 只有一位需要写入，其他都是串行寄存


    input [13:0] bvectorM_rd_addr, // 只有第一位需要进行读取，其他都是串行寄存

    input [8:0] [7:0] browX_mulbin, // 72位uram输入
    
    output [7:0] matrix_vector_out,

    input ce,
    input clk,
    input rst_n
);






    reg [8:0] [13:0] bvector_rd_addr;
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n)begin
            bvector_rd_addr <= 0;
        end
        else begin
            bvector_rd_addr[0] <= bvectorM_rd_addr;
            bvector_rd_addr[1] <= bvector_rd_addr[0];
            bvector_rd_addr[2] <= bvector_rd_addr[1];
            bvector_rd_addr[3] <= bvector_rd_addr[2];
            bvector_rd_addr[4] <= bvector_rd_addr[3];
            bvector_rd_addr[5] <= bvector_rd_addr[4];
            bvector_rd_addr[6] <= bvector_rd_addr[5];
            bvector_rd_addr[7] <= bvector_rd_addr[6];
            bvector_rd_addr[8] <= bvector_rd_addr[7];
			// bvector_rd_addr[9] <= bvector_rd_addr[8];
			// bvector_rd_addr[10] <= bvector_rd_addr[9];
			// bvector_rd_addr[11] <= bvector_rd_addr[10];
			// bvector_rd_addr[12] <= bvector_rd_addr[11];
			// bvector_rd_addr[13] <= bvector_rd_addr[12];
			// bvector_rd_addr[14] <= bvector_rd_addr[13];
			// bvector_rd_addr[15] <= bvector_rd_addr[14];
        end
    end

    wire [8:0] [7:0] bvector_rd_out;

    wire [8:0] cascade_out [7:0];

    // 9 branm
	// 奇
    RAMB18E2 #(
			.DOA_REG(1),.DOB_REG(1),
			.CASCADE_ORDER_A("FIRST"),.CASCADE_ORDER_B("NONE"),
			.CLOCK_DOMAINS("COMMON"),
                        .WRITE_MODE_A("WRITE_FIRST"), .WRITE_MODE_B("WRITE_FIRST"),
			.INIT_FILE("D:\\Project_ALL\\FP8_project\\MyVsrc\\sim\\pixel_3.hex"),
			.WRITE_WIDTH_A(9), .WRITE_WIDTH_B(9),
			.READ_WIDTH_A(9), .READ_WIDTH_B(9))
        	bram1 ( // A 读 B 写
	                .ADDRARDADDR(bvector_rd_addr[0]),
        	        .ADDRBWRADDR(bvector_wr_addr[0]),
	                .ADDRENA(1'b1),
	                .ADDRENB(1'b1),
	                .WEA({2{1'b0}}),
	                .WEBWE({4{bvector_wr_en[0]}}),
	                .CASDOUTA(cascade_out[0][7:0]), 
	                .CASDOUTPA(cascade_out[0][8]), 
	                .DINBDIN(bvector_wr_din), 
	                .DINPBDINP(1'd0),
                        .CASDIMUXA(1'b0), 
                        .CASDIMUXB(1'b0), 
	                .DOUTADOUT(bvector_rd_out[0]), 

	                .CLKARDCLK(clk),
	                .CLKBWRCLK(clk),
	                .ENARDEN(ce),
	                .ENBWREN(ce),
	                .REGCEAREGCE(ce),
	                .REGCEB(ce),
	                .RSTRAMARSTRAM(~rst_n),
	                .RSTRAMB(~rst_n),
	                .RSTREGARSTREG(~rst_n),
	                .RSTREGB(~rst_n) );
// 偶
    RAMB18E2 #(
			.DOA_REG(1),.DOB_REG(1),
			.CASCADE_ORDER_A("FIRST"),.CASCADE_ORDER_B("NONE"),
			.CLOCK_DOMAINS("COMMON"),
                        .WRITE_MODE_A("WRITE_FIRST"), .WRITE_MODE_B("WRITE_FIRST"),
			.INIT_FILE("D:\\Project_ALL\\FP8_project\\MyVsrc\\sim\\pixel_3.hex"),
			.WRITE_WIDTH_A(9), .WRITE_WIDTH_B(9),
			.READ_WIDTH_A(9), .READ_WIDTH_B(9))
        	bram2 (  // A 读 B 写
	                .ADDRARDADDR(bvector_rd_addr[1]),
        	        .ADDRBWRADDR(bvector_wr_addr[1]),
	                .ADDRENA(1'b1),
	                .ADDRENB(1'b1),
	                .WEA({2{1'b0}}),
	                .WEBWE({4{bvector_wr_en[1]}}),

	                .CASDOUTA(cascade_out[1][7:0]), 
	                .CASDOUTPA(cascade_out[1][8]), 

	                .DINBDIN(bvector_wr_din_1), 
	                .DINPBDINP(1'd0),
                        // .CASDINA(cascade_out[0][7:0]),
                        // .CASDINPA(cascade_out[0][8]),
                        .CASDIMUXA(1'b0), 
                        .CASDIMUXB(1'b0), 
	                .DOUTADOUT(bvector_rd_out[1]), 

	                .CLKARDCLK(clk),
	                .CLKBWRCLK(clk),
	                .ENARDEN(ce),
	                .ENBWREN(ce),
	                .REGCEAREGCE(ce),
	                .REGCEB(ce),
	                .RSTRAMARSTRAM(~rst_n),
	                .RSTRAMB(~rst_n),
	                .RSTREGARSTREG(~rst_n),
	                .RSTREGB(~rst_n) );

// 奇
    RAMB18E2 #(
			.DOA_REG(1),.DOB_REG(1),
			.CASCADE_ORDER_A("LAST"),.CASCADE_ORDER_B("FIRST"),
			.CLOCK_DOMAINS("COMMON"),
                        .WRITE_MODE_A("WRITE_FIRST"), .WRITE_MODE_B("WRITE_FIRST"),
			.INIT_FILE("D:\\Project_ALL\\FP8_project\\MyVsrc\\sim\\pixel_3.hex"),
			.WRITE_WIDTH_A(9), .WRITE_WIDTH_B(9),
			.READ_WIDTH_A(9), .READ_WIDTH_B(9))
        	bram3 ( // A 写 B 读
	                .ADDRARDADDR(bvector_wr_addr[2]),
        	        .ADDRBWRADDR(bvector_rd_addr[2]),
	                .ADDRENA(1'b1),
	                .ADDRENB(1'b1),
	                .WEA({2{bvector_wr_en[2]}}),
	                .WEBWE({4{1'b0}}),
	                .CASDOUTB(cascade_out[2][7:0]), 
	                .CASDOUTPB(cascade_out[2][8]), 
	                .DINADIN(bvector_wr_din), 
	                .DINPADINP(1'd0),
                        .CASDINA(cascade_out[0][7:0]),
                        .CASDINPA(cascade_out[0][8]),
                        .CASDIMUXA(1'b1), 
                        .CASDIMUXB(1'b0), 
	                .DOUTBDOUT(bvector_rd_out[2]), 

	                .CLKARDCLK(clk),
	                .CLKBWRCLK(clk),
	                .ENARDEN(ce),
	                .ENBWREN(ce),
	                .REGCEAREGCE(ce),
	                .REGCEB(ce),
	                .RSTRAMARSTRAM(~rst_n),
	                .RSTRAMB(~rst_n),
	                .RSTREGARSTREG(~rst_n),
	                .RSTREGB(~rst_n) );
// 偶
    RAMB18E2 #(
			.DOA_REG(1),.DOB_REG(1),
			.CASCADE_ORDER_A("LAST"),.CASCADE_ORDER_B("FIRST"),
			.CLOCK_DOMAINS("COMMON"),
                        .WRITE_MODE_A("WRITE_FIRST"), .WRITE_MODE_B("WRITE_FIRST"),
			.INIT_FILE("D:\\Project_ALL\\FP8_project\\MyVsrc\\sim\\pixel_3.hex"),
			.WRITE_WIDTH_A(9), .WRITE_WIDTH_B(9),
			.READ_WIDTH_A(9), .READ_WIDTH_B(9))
        	bram4 (  // A 写 B 读
	                .ADDRARDADDR(bvector_wr_addr[3]),
        	        .ADDRBWRADDR(bvector_rd_addr[3]),
	                .ADDRENA(1'b1),
	                .ADDRENB(1'b1),
	                .WEA({2{bvector_wr_en[3]}}),
	                .WEBWE({4{1'b0}}),

	                .CASDOUTB(cascade_out[3][7:0]), 
	                .CASDOUTPB(cascade_out[3][8]), 

	                .DINADIN(bvector_wr_din), 
	                .DINPADINP(1'd0),
                        .CASDINA(cascade_out[1][7:0]),
                        .CASDINPA(cascade_out[1][8]),
                        .CASDIMUXA(1'b1), 
                        .CASDIMUXB(1'b0), 
	                .DOUTBDOUT(bvector_rd_out[3]), 

	                .CLKARDCLK(clk),
	                .CLKBWRCLK(clk),
	                .ENARDEN(ce),
	                .ENBWREN(ce),
	                .REGCEAREGCE(ce),
	                .REGCEB(ce),
	                .RSTRAMARSTRAM(~rst_n),
	                .RSTRAMB(~rst_n),
	                .RSTREGARSTREG(~rst_n),
	                .RSTREGB(~rst_n) );

// 奇
    RAMB18E2 #(
			.DOA_REG(1),.DOB_REG(1),
			.CASCADE_ORDER_A("FIRST"),.CASCADE_ORDER_B("LAST"),
			.CLOCK_DOMAINS("COMMON"),
                        .WRITE_MODE_A("WRITE_FIRST"), .WRITE_MODE_B("WRITE_FIRST"),
			.INIT_FILE("D:\\Project_ALL\\FP8_project\\MyVsrc\\sim\\pixel_3.hex"),
			.WRITE_WIDTH_A(9), .WRITE_WIDTH_B(9),
			.READ_WIDTH_A(9), .READ_WIDTH_B(9))
        	bram5 ( // A 读 B 写
	                .ADDRARDADDR(bvector_rd_addr[4]),
        	        .ADDRBWRADDR(bvector_wr_addr[4]),
	                .ADDRENA(1'b1),
	                .ADDRENB(1'b1),
	                .WEA({2{1'b0}}),
	                .WEBWE({4{bvector_wr_en[4]}}),
	                .CASDOUTA(cascade_out[4][7:0]), 
	                .CASDOUTPA(cascade_out[4][8]), 
	                .DINBDIN(bvector_wr_din), 
	                .DINPBDINP(1'd0),
                        .CASDINB(cascade_out[2][7:0]),
                        .CASDINPB(cascade_out[2][8]),
                        .CASDIMUXA(1'b0), 
                        .CASDIMUXB(1'b1), 
	                .DOUTADOUT(bvector_rd_out[4]), 

	                .CLKARDCLK(clk),
	                .CLKBWRCLK(clk),
	                .ENARDEN(ce),
	                .ENBWREN(ce),
	                .REGCEAREGCE(ce),
	                .REGCEB(ce),
	                .RSTRAMARSTRAM(~rst_n),
	                .RSTRAMB(~rst_n),
	                .RSTREGARSTREG(~rst_n),
	                .RSTREGB(~rst_n) );
// 偶数
    RAMB18E2 #(
			.DOA_REG(1),.DOB_REG(1),
			.CASCADE_ORDER_A("FIRST"),.CASCADE_ORDER_B("LAST"),
			.CLOCK_DOMAINS("COMMON"),
                        .WRITE_MODE_A("WRITE_FIRST"), .WRITE_MODE_B("WRITE_FIRST"),
			.INIT_FILE("D:\\Project_ALL\\FP8_project\\MyVsrc\\sim\\pixel_3.hex"),
			.WRITE_WIDTH_A(9), .WRITE_WIDTH_B(9),
			.READ_WIDTH_A(9), .READ_WIDTH_B(9))
        	bram6 (  // A 读 B 写
	                .ADDRARDADDR(bvector_rd_addr[5]),
        	        .ADDRBWRADDR(bvector_wr_addr[5]),
	                .ADDRENA(1'b1),
	                .ADDRENB(1'b1),
	                .WEA({2{1'b0}}),
	                .WEBWE({4{bvector_wr_en[5]}}),

	                .CASDOUTA(cascade_out[5][7:0]), 
	                .CASDOUTPA(cascade_out[5][8]), 

	                .DINADIN(bvector_wr_din), 
	                .DINPADINP(1'd0),
                        .CASDINB(cascade_out[3][7:0]),
                        .CASDINPB(cascade_out[3][8]),
                        .CASDIMUXA(1'b0), 
                        .CASDIMUXB(1'b1), 
	                .DOUTADOUT(bvector_rd_out[5]), 

	                .CLKARDCLK(clk),
	                .CLKBWRCLK(clk),
	                .ENARDEN(ce),
	                .ENBWREN(ce),
	                .REGCEAREGCE(ce),
	                .REGCEB(ce),
	                .RSTRAMARSTRAM(~rst_n),
	                .RSTRAMB(~rst_n),
	                .RSTREGARSTREG(~rst_n),
	                .RSTREGB(~rst_n) );

// 奇数
    RAMB18E2 #(
			.DOA_REG(1),.DOB_REG(1),
			.CASCADE_ORDER_A("LAST"),.CASCADE_ORDER_B("FIRST"),
			.CLOCK_DOMAINS("COMMON"),
                        .WRITE_MODE_A("WRITE_FIRST"), .WRITE_MODE_B("WRITE_FIRST"),
			.INIT_FILE("D:\\Project_ALL\\FP8_project\\MyVsrc\\sim\\pixel_3.hex"),
			.WRITE_WIDTH_A(9), .WRITE_WIDTH_B(9),
			.READ_WIDTH_A(9), .READ_WIDTH_B(9))
        	bram7 ( // A 写 B 读
	                .ADDRARDADDR(bvector_wr_addr[6]),
        	        .ADDRBWRADDR(bvector_rd_addr[6]),
	                .ADDRENA(1'b1),
	                .ADDRENB(1'b1),
	                .WEA({2{bvector_wr_en[6]}}),
	                .WEBWE({4{1'b0}}),
	                .CASDOUTB(cascade_out[6][7:0]), 
	                .CASDOUTPB(cascade_out[6][8]), 
	                .DINADIN(bvector_wr_din), 
	                .DINPADINP(1'd0),
                        .CASDINA(cascade_out[4][7:0]),
                        .CASDINPA(cascade_out[4][8]),
                        .CASDIMUXA(1'b1), 
                        .CASDIMUXB(1'b0), 
	                .DOUTBDOUT(bvector_rd_out[6]), 

	                .CLKARDCLK(clk),
	                .CLKBWRCLK(clk),
	                .ENARDEN(ce),
	                .ENBWREN(ce),
	                .REGCEAREGCE(ce),
	                .REGCEB(ce),
	                .RSTRAMARSTRAM(~rst_n),
	                .RSTRAMB(~rst_n),
	                .RSTREGARSTREG(~rst_n),
	                .RSTREGB(~rst_n) );
// 偶数
    RAMB18E2 #(
			.DOA_REG(1),.DOB_REG(1),
			.CASCADE_ORDER_A("LAST"),.CASCADE_ORDER_B("NONE"),
			.CLOCK_DOMAINS("COMMON"),
                        .WRITE_MODE_A("WRITE_FIRST"), .WRITE_MODE_B("WRITE_FIRST"),
			.INIT_FILE("D:\\Project_ALL\\FP8_project\\MyVsrc\\sim\\pixel_3.hex"),
			.WRITE_WIDTH_A(9), .WRITE_WIDTH_B(9),
			.READ_WIDTH_A(9), .READ_WIDTH_B(9))
        	bram8 (  // A 写 B 读
	                .ADDRARDADDR(bvector_wr_addr[7]),
        	        .ADDRBWRADDR(bvector_rd_addr[7]),
	                .ADDRENA(1'b1),
	                .ADDRENB(1'b1),
	                .WEA({2{bvector_wr_en[7]}}),
	                .WEBWE({4{1'b0}}),

	                // .CASDOUTB(cascade_out[7][7:0]), 
	                // .CASDOUTPB(cascade_out[7][8]), 

	                .DINADIN(bvector_wr_din), 
	                .DINPADINP(1'd0),
                        .CASDINA(cascade_out[5][7:0]),
                        .CASDINPA(cascade_out[5][8]),
                        .CASDIMUXA(1'b1), 
                        .CASDIMUXB(1'b0), 
	                .DOUTBDOUT(bvector_rd_out[7]), 

	                .CLKARDCLK(clk),
	                .CLKBWRCLK(clk),
	                .ENARDEN(ce),
	                .ENBWREN(ce),
	                .REGCEAREGCE(ce),
	                .REGCEB(ce),
	                .RSTRAMARSTRAM(~rst_n),
	                .RSTRAMB(~rst_n),
	                .RSTREGARSTREG(~rst_n),
	                .RSTREGB(~rst_n) );

// 奇数
    RAMB18E2 #(
			.DOA_REG(1),.DOB_REG(1),
			.CASCADE_ORDER_A("NONE"),.CASCADE_ORDER_B("LAST"),
			.CLOCK_DOMAINS("COMMON"),
                        .WRITE_MODE_A("WRITE_FIRST"), .WRITE_MODE_B("WRITE_FIRST"),
			.INIT_FILE("D:\\Project_ALL\\FP8_project\\MyVsrc\\sim\\pixel_3.hex"),
			.WRITE_WIDTH_A(9), .WRITE_WIDTH_B(9),
			.READ_WIDTH_A(9), .READ_WIDTH_B(9))
        	bram9 ( // A 读 B 写
	                .ADDRARDADDR(bvector_rd_addr[8]),
        	        .ADDRBWRADDR(bvector_wr_addr[8]),
	                .ADDRENA(1'b1),
	                .ADDRENB(1'b1),
	                .WEA({2{1'b0}}),
	                .WEBWE({4{bvector_wr_en[8]}}),
	                // .CASDOUTA(cascade_out[8][7:0]), 
	                // .CASDOUTPA(cascade_out[8][8]), 
	                .DINBDIN(bvector_wr_din), 
	                .DINPBDINP(1'd0),
                        .CASDINB(cascade_out[6][7:0]),
                        .CASDINPB(cascade_out[6][8]),
                        .CASDIMUXA(1'b0), 
                        .CASDIMUXB(1'b1), 
	                .DOUTADOUT(bvector_rd_out[8]), 

	                .CLKARDCLK(clk),
	                .CLKBWRCLK(clk),
	                .ENARDEN(ce),
	                .ENBWREN(ce),
	                .REGCEAREGCE(ce),
	                .REGCEB(ce),
	                .RSTRAMARSTRAM(~rst_n),
	                .RSTRAMB(~rst_n),
	                .RSTREGARSTREG(~rst_n),
	                .RSTREGB(~rst_n) );

    wire [8:0] [7:0] acc_out;

	// 仅相隔一个reg

    genvar i;
    generate
        for (i = 0; i < 9; i = i + 1) begin : gen_mul_acc
            if (i == 0) begin
                mul_acc_FP8 u_mul_acc_FP8(
                    .mul_a            (bvector_rd_out[i]            ),
                    .mul_b            (browX_mulbin[0]     ), //  注意数据同步
                    .mult_b_store     (1'b1     ),
                    .cascade_sum_in   (0   ),
                    .cascade_mula_out (  ),
                    .cascade_mulb_out (  ),
                    .acc_out          (acc_out[i]          ),
                    .clk              (clk              ),
                    .rst_n            (rst_n            )
                );
            end
            else begin
                mul_acc_FP8 u_mul_acc_FP8(
                    .mul_a            (bvector_rd_out[i]            ),
                    .mul_b            (browX_mulbin[i]            ),
                    .mult_b_store     (1'b1     ),
                    .cascade_sum_in   (acc_out[i-1]   ),
                    .cascade_mula_out (  ),
                    .cascade_mulb_out (  ),
                    .acc_out          (acc_out[i]          ),
                    .clk              (clk              ),
                    .rst_n            (rst_n            )
                );
            end
            
        end
    endgenerate

    assign matrix_vector_out = acc_out[8];

    


endmodule