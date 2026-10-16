module convolution (

   input brow3_wr_en,
   input [13:0] brow3_wr_addr,
   input [7:0] brow3_wr_din,

   input brow2_wr_en,
   input [13:0] brow2_wr_addr,

   input brow1_wr_en,
   input [13:0] brow1_wr_addr,

   input browX_rd_en,
   input [13:0] brow3_rd_addr,
   input [13:0] brow2_rd_addr,
   input [13:0] brow1_rd_addr,

   input bkernl_rd_en,
   input [13:0] bkernl_rd_addr,


   // input [7:0] bweigth_din,
   input [7:0] bweigth_store,

   output [7:0] convolution_out,
   output conv_valid,



   input ce,
   input clk,
   input rst_n
);


   // 矩阵3
   // wire brow3_wr_en;
   // wire [13:0] brow3_wr_addr;
   // wire [7:0] brow3_wr_din;
   // wire [13:0] brow3_rd_addr; 
   wire [7:0] brow3_rd_dout;
   wire [8:0] brow3_cascade_out;

   // 矩阵2
   // wire brow2_wr_en;
   // wire [13:0] brow2_wr_addr;
   // wire [7:0] brow2_wr_din;
   // wire [13:0] brow2_rd_addr; 
   wire [7:0] brow2_rd_dout;
   wire [8:0] brow2_cascade_out;

   // 矩阵1
   // wire brow1_wr_en;
   // wire [13:0] brow1_wr_addr;
   // wire [7:0] brow1_wr_din;
   // wire [13:0] brow1_rd_addr; 
   wire [7:0] brow1_rd_dout;
   wire [8:0] brow1_cascade_out;

   // 读地址同时读，但是到达DSP却不是同时的


   // 存储第三行待处理数据
   RAMB18E2 #(
      .DOA_REG(1),.DOB_REG(1),
      .CASCADE_ORDER_A("FIRST"),.CASCADE_ORDER_B("NONE"),
      .CLOCK_DOMAINS("COMMON"),
                     .WRITE_MODE_A("WRITE_FIRST"), .WRITE_MODE_B("WRITE_FIRST"),
      .INIT_FILE("D:\\Project_ALL\\FP8_project\\MyVsrc\\sim\\pixel_3.hex"),
      .WRITE_WIDTH_A(9), .WRITE_WIDTH_B(9),
      .READ_WIDTH_A(9), .READ_WIDTH_B(9)
   )bram_row3 (  // a端口读取 b端口写入
      .ADDRARDADDR(brow3_rd_addr),
      .ADDRBWRADDR(brow3_wr_addr),
      .ADDRENA(browX_rd_en),
      .ADDRENB(1'b1),
      .WEA({2{1'b0}}),
      .WEBWE({4{brow3_wr_en}}),

      // horizontal links
      .CASDOUTA(brow3_cascade_out[7:0]), 
      .CASDOUTPA(brow3_cascade_out[8]), 
      .DINBDIN(brow3_wr_din), 
      .DINPBDINP(1'b0),
      .CASDIMUXA(1'b0), 
      .CASDIMUXB(1'b0), 
      .DOUTADOUT(brow3_rd_dout), 
      .DOUTPADOUTP(       ), 

      // clocking, reset, and enable control
      .CLKARDCLK(clk),
      .CLKBWRCLK(clk),

      .ENARDEN(ce),
      .ENBWREN(ce),
      .REGCEAREGCE(ce),
      .REGCEB(ce),

      .RSTRAMARSTRAM(~rst_n),
      .RSTRAMB(~rst_n),
      .RSTREGARSTREG(~rst_n),
      .RSTREGB(~rst_n)
   );



   // 存储第二行待处理数据
   RAMB18E2 #(
      .DOA_REG(1),.DOB_REG(1), //  两个 clk 才可以读出数据
      .CASCADE_ORDER_A("LAST"),.CASCADE_ORDER_B("FIRST"),
      .CLOCK_DOMAINS("COMMON"),
                     .WRITE_MODE_A("WRITE_FIRST"), .WRITE_MODE_B("WRITE_FIRST"), // 保证读出的数据是最新的
      .INIT_FILE("D:\\Project_ALL\\FP8_project\\MyVsrc\\sim\\pixel_2.hex"),
      .WRITE_WIDTH_A(9), .WRITE_WIDTH_B(9),
      .READ_WIDTH_A(9), .READ_WIDTH_B(9)
   )bram_row2 (  // a端口写入 b端口读取
      .ADDRARDADDR(brow2_wr_addr),
      .ADDRBWRADDR(brow2_rd_addr),
      .ADDRENA(1'b1),
      .ADDRENB(browX_rd_en),
      .WEA({2{brow2_wr_en}}),
      .WEBWE({4{1'b0}}),

      // horizontal links
      .CASDOUTB(brow2_cascade_out[7:0]), 
      .CASDOUTPB(brow2_cascade_out[8]), 
      .CASDINA(brow3_cascade_out[7:0]),
      .CASDINPA(brow3_cascade_out[8]),
      .CASDIMUXB(1'b0),
      .CASDIMUXA(1'b1),
      .DOUTBDOUT(brow2_rd_dout), 
      .DOUTPBDOUTP(     ), 

      // clocking, reset, and enable control
      .CLKARDCLK(clk),
      .CLKBWRCLK(clk),

      .ENARDEN(ce),
      .ENBWREN(ce),
      .REGCEAREGCE(ce),
      .REGCEB(ce),

      .RSTRAMARSTRAM(~rst_n),
      .RSTRAMB(~rst_n),
      .RSTREGARSTREG(~rst_n),
      .RSTREGB(~rst_n)
   );

   // 存储第一行待处理数据
   RAMB18E2 #(
      .DOA_REG(1),.DOB_REG(1), //  两个 clk 才可以读出数据
      .CASCADE_ORDER_A("NONE"),.CASCADE_ORDER_B("LAST"), // 交替级联
      .CLOCK_DOMAINS("COMMON"),
                     .WRITE_MODE_A("WRITE_FIRST"), .WRITE_MODE_B("WRITE_FIRST"), // 保证读出的数据是最新的
      .INIT_FILE("D:\\Project_ALL\\FP8_project\\MyVsrc\\sim\\pixel_1.hex"),
      .WRITE_WIDTH_A(9), .WRITE_WIDTH_B(9),
      .READ_WIDTH_A(9), .READ_WIDTH_B(9)
   )bram_row1 (  // a端口读取 b端口写入
      .ADDRARDADDR(brow1_rd_addr),
      .ADDRBWRADDR(brow1_wr_addr),
      .ADDRENA(browX_rd_en),
      .ADDRENB(1'b1),
      .WEA({2{1'b0}}),
      .WEBWE({4{brow1_wr_en}}),

      // horizontal links
      .DOUTADOUT(brow1_rd_dout), 
      .DOUTPADOUTP(     ), 
      .CASDINB(brow2_cascade_out[7:0]),
      .CASDINPB(brow2_cascade_out[8]),
      .DOUTBDOUT(), 
      .DOUTPBDOUTP(),
      .CASDIMUXB(1'b1),
      .CASDIMUXA(1'b0),

      // clocking, reset, and enable control
      .CLKARDCLK(clk),
      .CLKBWRCLK(clk),

      .ENARDEN(ce),
      .ENBWREN(ce),
      .REGCEAREGCE(ce),
      .REGCEB(ce),

      .RSTRAMARSTRAM(~rst_n),
      .RSTRAMB(~rst_n),
      .RSTREGARSTREG(~rst_n),
      .RSTREGB(~rst_n)
   );

   // 卷积核存储器
   // wire bkernl_rd_en;
   // wire [13:0] bkernl_rd_addr;
   wire [7:0] bkernl_rd_dout;
   wire [7:0] bkernl_wr_din;
   wire [13:0] bkernl_wr_addr;
   wire bkernl_wr_en;
   RAMB18E2 #(
      .DOA_REG(1),.DOB_REG(1), //  两个 clk 才可以读出数据
      .CASCADE_ORDER_A("NONE"),.CASCADE_ORDER_B("NONE"), // 交替级联
      .CLOCK_DOMAINS("COMMON"),
                     .WRITE_MODE_A("WRITE_FIRST"), .WRITE_MODE_B("WRITE_FIRST"), // 保证读出的数据是最新的
      .INIT_FILE("D:\\Project_All\\FP8_project\\MyVsrc\\sim\\kernl.hex"),
      .WRITE_WIDTH_A(9), .WRITE_WIDTH_B(9),
      .READ_WIDTH_A(9), .READ_WIDTH_B(9)
   )bram_kernl (  // a端口读取 b端口写入
      .ADDRARDADDR(bkernl_rd_addr),
      .ADDRBWRADDR(bkernl_wr_addr),
      .ADDRENA(bkernl_rd_en),
      .ADDRENB(1'b1),
      .WEA({2{1'b0}}),
      .WEBWE({4{bkernl_wr_en}}),

      // horizontal links
      .DOUTADOUT(bkernl_rd_dout), 
      .DOUTPADOUTP(   ),

      // bram侧的写入
      .DINBDIN(bkernl_wr_din),                 // 16-bit input: Port B data/MSB data
      .DINPBDINP(1'b0),

      .DOUTBDOUT(), 
      .DOUTPBDOUTP(),
      .CASDIMUXB(1'b0),
      .CASDIMUXA(1'b0),

      // clocking, reset, and enable control
      .CLKARDCLK(clk),
      .CLKBWRCLK(clk),

      .ENARDEN(ce),
      .ENBWREN(ce),
      .REGCEAREGCE(ce),
      .REGCEB(ce),

      .RSTRAMARSTRAM(~rst_n),
      .RSTRAMB(~rst_n),
      .RSTREGARSTREG(~rst_n),
      .RSTREGB(~rst_n)
   );

   reg [7:0] brow2_rd_dout_r [2:0]; // 延迟 以求和同步
   always @(posedge clk or negedge rst_n) begin
      if(!rst_n) begin
         brow2_rd_dout_r[0] <= 0;
         brow2_rd_dout_r[1] <= 0;
         brow2_rd_dout_r[2] <= 0;

      end
      else begin
         brow2_rd_dout_r[0] <= brow2_rd_dout;
         brow2_rd_dout_r[1] <= brow2_rd_dout_r[0];
         brow2_rd_dout_r[2] <= brow2_rd_dout_r[1];

      end

   end

   reg [7:0] brow1_rd_dout_r [5:0]; // 延迟 以求和同步
   always @(posedge clk or negedge rst_n) begin
      if(!rst_n) begin
         brow1_rd_dout_r[0] <= 0;
         brow1_rd_dout_r[1] <= 0;
         brow1_rd_dout_r[2] <= 0;
         brow1_rd_dout_r[3] <= 0;   
         brow1_rd_dout_r[4] <= 0;
         brow1_rd_dout_r[5] <= 0;

      end
      else begin
         brow1_rd_dout_r[0] <= brow1_rd_dout;
         brow1_rd_dout_r[1] <= brow1_rd_dout_r[0];
         brow1_rd_dout_r[2] <= brow1_rd_dout_r[1];
         brow1_rd_dout_r[3] <= brow1_rd_dout_r[2];
         brow1_rd_dout_r[4] <= brow1_rd_dout_r[3];
         brow1_rd_dout_r[5] <= brow1_rd_dout_r[4];

      end

   end





   // FP8 卷积阵列 卷积阵列矩阵
   wire [7:0] mul_a [8:0];
   wire [7:0] mul_b [8:0];
   wire [7:0] cascade_mula_out [8:0]; 
   wire [7:0] cascade_mulb_out [8:0]; 
   wire [7:0] acc_out [8:0];


   // 矩阵3处理单元
   genvar i;
   generate
      for(i = 0; i < 3 ; i = i + 1)begin : conv3
         if (i==0) begin
            (* dont_touch = "true" *) mul_acc_FP8 u_mul_acc_FP8_3(
                .mul_a            (brow3_rd_dout            ),
                .mul_b            (bkernl_rd_dout            ), // 从mulb 中进行级联输入
                .mult_b_store     (bweigth_store     ), // 锁存信号使能
                .cascade_sum_in   (8'b0   ),
                .cascade_mula_out (cascade_mula_out[0] ),
                .cascade_mulb_out (cascade_mulb_out[0] ),
                .acc_out          (acc_out[0]          ),
                .clk              (clk              ),
                .rst_n            (rst_n            )
            );
            
         end
         else begin
            (* dont_touch = "true" *) mul_acc_FP8 u_mul_acc_FP8_3(
                .mul_a            (cascade_mula_out[i-1]            ),
                .mul_b            (cascade_mulb_out[i-1]            ),
                .mult_b_store     (bweigth_store     ), // 锁存信号使能
                .cascade_sum_in   (acc_out[i-1]   ),
                .cascade_mula_out (cascade_mula_out[i] ),
                .cascade_mulb_out (cascade_mulb_out[i] ),
                .acc_out          (acc_out[i]          ),
                .clk              (clk              ),
                .rst_n            (rst_n            )
            );

         end
         
      end
   endgenerate


   // 矩阵2处理单元
   genvar j;
   generate
      for(j = 0; j < 3 ; j = j + 1)begin: conv2
         if (j==0) begin
            (* dont_touch = "true" *) mul_acc_FP8 u_mul_acc_FP8_2(
                .mul_a            (brow2_rd_dout_r[2]            ),
                .mul_b            (cascade_mulb_out[j+2]            ),
                .mult_b_store     (bweigth_store     ), // 锁存信号使能
                .cascade_sum_in   (acc_out[j+2]   ),
                .cascade_mula_out (cascade_mula_out[j+3] ),
                .cascade_mulb_out (cascade_mulb_out[j+3] ),
                .acc_out          (acc_out[j+3]          ),
                .clk              (clk              ),
                .rst_n            (rst_n            )
            );
            
         end
         else begin
            (* dont_touch = "true" *) mul_acc_FP8 u_mul_acc_FP8_2(
                .mul_a            (cascade_mula_out[j+2]            ),
                .mul_b            (cascade_mulb_out[j+2]            ),
                .mult_b_store     (bweigth_store     ), // 锁存信号使能
                .cascade_sum_in   (acc_out[j+2]   ),
                .cascade_mula_out (cascade_mula_out[j+3] ),
                .cascade_mulb_out (cascade_mulb_out[j+3] ),
                .acc_out          (acc_out[j+3]          ),
                .clk              (clk              ),
                .rst_n            (rst_n            )
            );

         end
         
      end
   endgenerate


   // 矩阵1处理单元
   genvar k;
   generate
      for(k = 0; k < 3 ; k = k + 1)begin: conv1
         if (k==0) begin
            (* dont_touch = "true" *) mul_acc_FP8 u_mul_acc_FP8_1(
                .mul_a            (brow1_rd_dout_r[5]            ),
                .mul_b            (cascade_mulb_out[k+5]            ),
                .mult_b_store     (bweigth_store     ), // 锁存信号使能
                .cascade_sum_in   (acc_out[k+5]   ),
                .cascade_mula_out (cascade_mula_out[k+6] ),
                .cascade_mulb_out (cascade_mulb_out[k+6] ),
                .acc_out          (acc_out[k+6]          ),
                .clk              (clk              ),
                .rst_n            (rst_n            )
            );
            
         end
         else begin
            (* dont_touch = "true" *) mul_acc_FP8 u_mul_acc_FP8_1(
                .mul_a            (cascade_mula_out[k+5]            ),
                .mul_b            (cascade_mulb_out[k+5]            ),
                .mult_b_store     (bweigth_store     ), // 锁存信号使能
                .cascade_sum_in   (acc_out[k+5]   ),
                .cascade_mula_out (cascade_mula_out[k+6] ),
                .cascade_mulb_out (cascade_mulb_out[k+6] ),
                .acc_out          (acc_out[k+6]          ),
                .clk              (clk              ),
                .rst_n            (rst_n            )
            ); 
         end
         
      end
   endgenerate

   assign convolution_out = acc_out[8]; // 卷积结果输出


   // 同步结果 与 有效标志位
   reg [15:0] browX_rd_en_r;
   always @(posedge clk or negedge rst_n) begin
      if (!rst_n) begin
         browX_rd_en_r <= 0;
      end
      else begin
         browX_rd_en_r[0] <= browX_rd_en;
         browX_rd_en_r[1] <= browX_rd_en_r[0];
         browX_rd_en_r[2] <= browX_rd_en_r[1];
         browX_rd_en_r[3] <= browX_rd_en_r[2];
         browX_rd_en_r[4] <= browX_rd_en_r[3];
         browX_rd_en_r[5] <= browX_rd_en_r[4];
         browX_rd_en_r[6] <= browX_rd_en_r[5];
         browX_rd_en_r[7] <= browX_rd_en_r[6];
         browX_rd_en_r[8] <= browX_rd_en_r[7];
         browX_rd_en_r[9] <= browX_rd_en_r[8];
         browX_rd_en_r[10] <= browX_rd_en_r[9];
         browX_rd_en_r[11] <= browX_rd_en_r[10];
         browX_rd_en_r[12] <= browX_rd_en_r[11];
         browX_rd_en_r[13] <= browX_rd_en_r[12];
         browX_rd_en_r[14] <= browX_rd_en_r[13];
         browX_rd_en_r[15] <= browX_rd_en_r[14];
      end
   end

   assign conv_valid = browX_rd_en_r[15]; // 锁存信号使能
    
endmodule