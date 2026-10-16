module Conv_Top (
    output [7:0] convolution_out,
    output conv_valid,

    input [13:0] uram_o_rd_addr,
    output [7:0] uram_o_rd_dout,


    input clk,
    input ce,
    input rst_n
);

    reg brow3_wr_en;
    reg [13:0] brow3_wr_addr;
    wire [7:0] brow3_wr_din;

    reg brow2_wr_en;
    reg [13:0] brow2_wr_addr;
    reg [7:0] brow2_wr_din;

    reg brow1_wr_en;
    reg [13:0] brow1_wr_addr;
    reg [7:0] brow1_wr_din;

    reg [13:0] brow3_rd_addr;
    reg [13:0] brow2_rd_addr;
    reg [13:0] brow1_rd_addr;

    reg bkernl_rd_en;
    reg [13:0] bkernl_rd_addr;


    reg [7:0] bweigth_din;
    reg [1:0] bweigth_store;

    

    // 输入矩阵
    wire [7:0] uram_i_rd_dout;
    wire [7:0] uram_i_wr_din;

    wire uram_i_wr_en;
    wire [13:0] uram_i_wr_addr;
    wire [13:0] uram_i_rd_addr;

    // 存储矩阵
    // wire [7:0] uram_o_rd_dout;
    wire [7:0] uram_o_wr_din;

    wire uram_o_wr_en;
    reg [13:0] uram_o_wr_addr;
    // wire [13:0] uram_o_rd_addr;



    

    localparam IDLE     = 4'd1<<0;
    localparam LOAD_KERNL = 4'd1<<1;
    localparam READ_FIRST = 4'd1<<2;
    localparam RUNNING  = 4'd1<<3;


    reg [3:0] state_c;
    reg [3:0] state_n;
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            state_c <= IDLE;
        end
        else begin
            state_c <= state_n;
        end
    end

    always @(*) begin
        case(state_c)
            IDLE: begin
                if(ce == 1) begin
                    state_n = LOAD_KERNL;
                end
                else begin
                    state_n = IDLE;
                end
            end
            LOAD_KERNL: begin
                if(bkernl_rd_addr == 8*(9-1))begin
                    state_n = READ_FIRST;
                end
                else begin
                    state_n = LOAD_KERNL;
                end
            end
            READ_FIRST: begin // rd 1st row
                state_n = RUNNING;
            end
            RUNNING:begin // wrt
                state_n = RUNNING;
            end
            default:begin
                state_n = IDLE;
            end
        endcase
    end

    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            bkernl_rd_en <= 0;
            bkernl_rd_addr <= -14'd8;
        end
        else begin
            if(bkernl_rd_addr == 8*(9-1)) begin
                bkernl_rd_addr <= 0;
                bkernl_rd_en <= 0;
            end
            else begin
                bkernl_rd_addr <= bkernl_rd_addr + 8'd8;
                bkernl_rd_en <= 1;
            end
        end
    end


    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            bweigth_store <= 0;
        end
        else begin
            bweigth_store[0] <= bkernl_rd_en;
            bweigth_store[1] <= bweigth_store[0];
        end
    end




    // 读地址使能
    reg browX_rd_en;
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n)begin
            brow3_rd_addr <= 0;
            brow2_rd_addr <= 0;
            brow1_rd_addr <= 0;
            browX_rd_en <= 0;
        end
        else if(state_c == READ_FIRST) begin
            browX_rd_en <= 1;
            brow3_rd_addr <= 0;
            brow2_rd_addr <= 0;
            brow1_rd_addr <= 0;
        end
        else if(state_c == RUNNING)begin
            browX_rd_en <= 1;
            if(brow1_rd_addr == 8*(8-1))begin
                brow1_rd_addr <= 0;
                brow2_rd_addr <= 0;
                brow3_rd_addr <= 0;
            end
            else begin
                brow1_rd_addr <= brow1_rd_addr + 8'd8;
                brow2_rd_addr <= brow2_rd_addr + 8'd8;
                brow3_rd_addr <= brow3_rd_addr + 8'd8;
            end
        end
    end

    // 矩阵2 1 行写地址使能
    reg brow1_wr_en_r;
    reg brow2_wr_en_r;
    reg [13:0] brow1_wr_addr_r;
    reg [13:0] brow2_wr_addr_r;
    // 寄存器延迟打拍
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            brow1_wr_en <= 0;
            brow2_wr_en <= 0;
            brow1_wr_addr <= 0;
            brow2_wr_addr <= 0;
            brow1_wr_en_r <= 0;
            brow2_wr_en_r <= 0;
            brow1_wr_addr_r <= 0;
            brow2_wr_addr_r <= 0;
        end
        else if(state_c != IDLE) begin
            brow1_wr_en <= browX_rd_en;
            brow2_wr_en <= browX_rd_en;
            brow1_wr_addr <= brow1_rd_addr;
            brow2_wr_addr <= brow2_rd_addr;
            brow1_wr_en_r <= brow1_wr_en;
            brow2_wr_en_r <= brow2_wr_en;
            brow1_wr_addr_r <= brow1_wr_addr;
            brow2_wr_addr_r <= brow2_wr_addr;
        end
    end

    // 矩阵3 行写地址使能
    reg [13:0] write_pixel_addr;
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            brow3_wr_en <= 0;
            brow3_wr_addr <= -14'd8;
            write_pixel_addr <= -8'd8;
        end
        else if(state_c == RUNNING ) begin
            if(brow3_wr_addr == 8*(8-1)) begin
                brow3_wr_en <= 1;
                brow3_wr_addr <= 0;
                write_pixel_addr <= 0;
            end
            else begin
                brow3_wr_en <= 1;
                brow3_wr_addr <= brow3_wr_addr + 8'd8;
                write_pixel_addr <= write_pixel_addr + 8'd8;
            end
        end
    end

    reg [1:0] brow3_wr_en_r;
    reg [13:0] brow3_wr_addr_r [1:0];
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n)begin
            brow3_wr_en_r <= 0;
            brow3_wr_addr_r[0] <= 0;
            brow3_wr_addr_r[1] <= 0;
        end
        else begin
            brow3_wr_en_r <= {brow3_wr_en_r[0],brow3_wr_en};
            brow3_wr_addr_r[0] <= brow3_wr_addr;
            brow3_wr_addr_r[1] <= brow3_wr_addr_r[0];
        end
    end


    assign uram_i_rd_addr = write_pixel_addr;
    assign brow3_wr_din = uram_i_rd_dout;

    // 卷积地址存储逻辑
    assign uram_o_wr_en = conv_valid; // 写入使能
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            uram_o_wr_addr <= 0;
        end else if(conv_valid) begin
            uram_o_wr_addr <= uram_o_wr_addr + 8'd8;
        end
    end


    // 矩阵输入
    RAMB18E2 #(
      .DOA_REG(1),.DOB_REG(1),
      .CASCADE_ORDER_A("NONE"),.CASCADE_ORDER_B("NONE"),
      .CLOCK_DOMAINS("COMMON"),
                     .WRITE_MODE_A("WRITE_FIRST"), .WRITE_MODE_B("WRITE_FIRST"),
      .INIT_FILE("D:\\Project_ALL\\FP8_project\\MyVsrc\\sim\\pixel_3.hex"),
      .WRITE_WIDTH_A(9), .WRITE_WIDTH_B(9),
      .READ_WIDTH_A(9), .READ_WIDTH_B(9)
    )uram_input_inst (  // a端口读取 b端口写入
      .ADDRARDADDR(uram_i_rd_addr),
      .ADDRBWRADDR(uram_i_wr_addr),
      .ADDRENA(1'b1),
      .ADDRENB(1'b1),
      .WEA({2{1'b0}}),
      .WEBWE({4{uram_i_wr_en}}),

      // horizontal links
      .CASDOUTA(    ), 
      .CASDOUTPA(   ), 
      .DINBDIN(uram_i_wr_din), 
      .DINPBDINP(1'b0),
      .CASDIMUXA(1'b0), 
      .CASDIMUXB(1'b0), 
      .DOUTADOUT(uram_i_rd_dout), 
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

    // 卷积结果存储
   RAMB18E2 #(
      .DOA_REG(1),.DOB_REG(1),
      .CASCADE_ORDER_A("NONE"),.CASCADE_ORDER_B("NONE"),
      .CLOCK_DOMAINS("COMMON"),
                     .WRITE_MODE_A("WRITE_FIRST"), .WRITE_MODE_B("WRITE_FIRST"),
    //   .INIT_FILE("D:\\Project_ALL\\FP8_project\\MyVsrc\\sim\\pixel_3.hex"),
      .WRITE_WIDTH_A(9), .WRITE_WIDTH_B(9),
      .READ_WIDTH_A(9), .READ_WIDTH_B(9)
    )uram_store_inst (  // a端口读取 b端口写入
      .ADDRARDADDR(uram_o_rd_addr),
      .ADDRBWRADDR(uram_o_wr_addr),
      .ADDRENA(1'b1),
      .ADDRENB(1'b1),
      .WEA({2{1'b0}}),
      .WEBWE({4{uram_o_wr_en}}),

      // horizontal links
      .CASDOUTA(    ), 
      .CASDOUTPA(   ), 
      .DINBDIN(convolution_out), 
      .DINPBDINP(1'b0),
      .CASDIMUXA(1'b0), 
      .CASDIMUXB(1'b0), 
      .DOUTADOUT(uram_o_rd_dout), 
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



    (* dont_touch = "true" *) convolution u_convolution(
        .brow3_wr_en     (brow3_wr_en_r[1]     ),
        .brow3_wr_addr   (brow3_wr_addr_r[1]   ),
        .brow3_wr_din    (brow3_wr_din    ),

        .brow2_wr_en     (brow2_wr_en_r     ),
        .brow2_wr_addr   (brow2_wr_addr_r   ),

        .brow1_wr_en     (brow1_wr_en_r     ),
        .brow1_wr_addr   (brow1_wr_addr_r   ),

        .browX_rd_en     (browX_rd_en     ),
        .brow3_rd_addr   (brow3_rd_addr   ),
        .brow2_rd_addr   (brow2_rd_addr   ),
        .brow1_rd_addr   (brow1_rd_addr   ),

        .bkernl_rd_en    (bkernl_rd_en    ),
        .bkernl_rd_addr  (bkernl_rd_addr  ),

        // .bweigth_din     (bweigth_din     ),
        .bweigth_store   (bweigth_store[1]    ),

        .convolution_out (convolution_out ),
        .conv_valid      (conv_valid      ),

        .ce              (ce              ),
        .clk             (clk             ),
        .rst_n           (rst_n           )
    );
    


    
endmodule