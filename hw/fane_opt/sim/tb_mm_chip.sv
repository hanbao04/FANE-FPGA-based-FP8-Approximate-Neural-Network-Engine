`timescale 1ns/1ps

module tb_mm_chip #(
    parameter integer MVM_VECTORS = 5,
    parameter real CLK_PERIOD_NS = 10.0
);

localparam integer Y = 1;
localparam integer IMG_W = 9 * MVM_VECTORS;
localparam integer IMG_D = 1;
localparam integer MVM_LANES = 4;
localparam integer MVM_REDUCTION = 9;


localparam integer MAC_ADD_PIPE = 2;
localparam integer FINAL_ADD_PIPE = 2;
localparam integer WEIGHT_SCRATCH_ADDR = MVM_VECTORS * 16;
localparam integer A_W = 14;
localparam integer M_W = 18;
localparam integer URAM_A_W = 23;
localparam integer URAM_D_W = 72;

logic clk = 1'b0;
logic rst = 1'b1;
logic ce = 1'b1;

logic [URAM_A_W-1:0] uram1_wr_addr [Y];
logic [URAM_D_W-1:0] uram1_wr_data [Y];
logic uram1_wr_en [Y];
logic [URAM_A_W-1:0] uram2_wr_addr [Y];
logic [URAM_D_W-1:0] uram2_wr_data [Y];
logic uram2_wr_en [Y];
logic [URAM_A_W-1:0] uram3_wr_addr [Y];
logic [URAM_D_W-1:0] uram3_wr_data [Y];
logic uram3_wr_en [Y];
logic [URAM_A_W-1:0] uram4_wr_addr [Y];
logic [URAM_D_W-1:0] uram4_wr_data [Y];
logic uram4_wr_en [Y];

logic [A_W-1:0] bram1_rd_addr [Y];
logic bram1_rd_en [Y];
wire [M_W-1:0] bram1_rd_data [Y];
logic [A_W-1:0] bram2_rd_addr [Y];
logic bram2_rd_en [Y];
wire [M_W-1:0] bram2_rd_data [Y];
logic [A_W-1:0] bram3_rd_addr [Y];
logic bram3_rd_en [Y];
wire [M_W-1:0] bram3_rd_data [Y];
logic [A_W-1:0] bram4_rd_addr [Y];
logic bram4_rd_en [Y];
wire [M_W-1:0] bram4_rd_data [Y];

logic [A_W-1:0] b1_wr_addr [Y];
logic [15:0] b1_wr_data [Y];
logic b1_wr_en [Y];
logic [A_W-1:0] b2_wr_addr [Y];
logic [15:0] b2_wr_data [Y];
logic b2_wr_en [Y];
logic [A_W-1:0] b3_wr_addr [Y];
logic b3_wr_en [Y];
    logic [A_W-1:0] b4_wr_addr [Y];
    logic b4_wr_en [Y];
    logic [A_W-1:0] b5_wr_addr [Y];
    logic b5_wr_en [Y];
    logic [A_W-1:0] b6_wr_addr [Y];
    logic b6_wr_en [Y];
    logic [A_W-1:0] b7_wr_addr [Y];
    logic b7_wr_en [Y];
    logic [A_W-1:0] b8_wr_addr [Y];
    logic b8_wr_en [Y];
    logic [A_W-1:0] b9_wr_addr [Y];
    logic b9_wr_en [Y];

logic [22:0] addr_chain [Y];
logic [8:0] bwe_chain [Y];
logic [0:0] dbiterr_chain [Y];
logic [71:0] din_chain [Y];
logic [71:0] dout_chain [Y];
logic [0:0] en_chain [Y];
logic [0:0] rdacess_chain [Y];
logic [0:0] rdb_wr_chain [Y];
logic [0:0] sbiterr_chain [Y];

logic [71:0] mm_a_mem [0:MVM_LANES*MVM_VECTORS-1];
logic [7:0] mm_b_mem [0:MVM_VECTORS*MVM_REDUCTION-1];
logic [7:0] mm_golden_mem [0:MVM_LANES*MVM_VECTORS-1];
string vector_dir;
integer errors = 0;
integer lane_index;
integer vector_index;
integer current_pass = 0;
integer trace_lane;
integer result_writes [0:3];
integer trace_errors = 0;
integer total_result_writes = 0;
logic trace_enable = 1'b0;
`ifndef POST_SIM
wire [3:0] write_en = {dut.name[0].dut.mm4.bram_wr_en,
                      dut.name[0].dut.mm3.bram_wr_en,
                      dut.name[0].dut.mm2.bram_wr_en,
                      dut.name[0].dut.mm1.bram_wr_en};
wire [3:0][A_W-1:0] write_addr = {dut.name[0].dut.mm4.bram_wr_addr,
                                dut.name[0].dut.mm3.bram_wr_addr,
                                dut.name[0].dut.mm2.bram_wr_addr,
                                dut.name[0].dut.mm1.bram_wr_addr};
wire [3:0][M_W-1:0] write_data = {dut.name[0].dut.mm4.bram_wr_data,
                                dut.name[0].dut.mm3.bram_wr_data,
                                dut.name[0].dut.mm2.bram_wr_data,
                                dut.name[0].dut.mm1.bram_wr_data};

always @(negedge clk) begin
    if (trace_enable) begin
        if (rst) begin
            for (trace_lane = 0; trace_lane < 4; trace_lane = trace_lane + 1)
                result_writes[trace_lane] = 0;
        end else begin
            for (trace_lane = 0; trace_lane < 4; trace_lane = trace_lane + 1) begin
                if (write_en[trace_lane]) begin
                    if (result_writes[trace_lane] >= MVM_VECTORS) begin
                        $display("TRACE_ERROR MVM extra write pass=%0d lane=%0d", current_pass, trace_lane);
                        trace_errors = trace_errors + 1;
                    end else if (write_addr[trace_lane] !== result_writes[trace_lane]*16 ||
                        write_data[trace_lane] !== {10'd0, mm_golden_mem[trace_lane*MVM_VECTORS+result_writes[trace_lane]]}) begin
                        $display("TRACE_ERROR MVM write pass=%0d lane=%0d index=%0d addr=%0d data=%05h",
                            current_pass, trace_lane, result_writes[trace_lane], write_addr[trace_lane], write_data[trace_lane]);
                        trace_errors = trace_errors + 1;
                    end
                    result_writes[trace_lane] = result_writes[trace_lane] + 1;
                end
            end
        end
    end
end
`endif

always #(CLK_PERIOD_NS/2.0) clk = ~clk;

`ifdef POST_SIM
dsp_mm_chip_post #(
`else
dsp_mm_chip #(
`endif
    .IMG_W(IMG_W),
    .IMG_D(IMG_D),
    .Y(Y)
) dut (
    .clk(clk),
    .rst(rst),
    .ce(ce),
    .uram1_wr_addr(uram1_wr_addr),
    .uram1_wr_data(uram1_wr_data),
    .uram1_wr_en(uram1_wr_en),
    .uram2_wr_addr(uram2_wr_addr),
    .uram2_wr_data(uram2_wr_data),
    .uram2_wr_en(uram2_wr_en),
        .uram3_wr_addr(uram3_wr_addr),
        .uram3_wr_data(uram3_wr_data),
        .uram3_wr_en(uram3_wr_en),
        .uram4_wr_addr(uram4_wr_addr),
        .uram4_wr_data(uram4_wr_data),
        .uram4_wr_en(uram4_wr_en),
        .bram1_rd_addr(bram1_rd_addr),
        .bram1_rd_en(bram1_rd_en),
        .bram1_rd_data(bram1_rd_data),
        .bram2_rd_addr(bram2_rd_addr),
        .bram2_rd_en(bram2_rd_en),
        .bram2_rd_data(bram2_rd_data),
        .bram3_rd_addr(bram3_rd_addr),
        .bram3_rd_en(bram3_rd_en),
        .bram3_rd_data(bram3_rd_data),
        .bram4_rd_addr(bram4_rd_addr),
        .bram4_rd_en(bram4_rd_en),
        .bram4_rd_data(bram4_rd_data),
        .b1_wr_addr(b1_wr_addr),
        .b1_wr_data(b1_wr_data),
        .b1_wr_en(b1_wr_en),
        .b2_wr_addr(b2_wr_addr),
    .b2_wr_data(b2_wr_data),
    .b2_wr_en(b2_wr_en),
    .b3_wr_addr(b3_wr_addr),
    .b3_wr_en(b3_wr_en),
    .b4_wr_addr(b4_wr_addr),
    .b4_wr_en(b4_wr_en),
    .b5_wr_addr(b5_wr_addr),
    .b5_wr_en(b5_wr_en),
    .b6_wr_addr(b6_wr_addr),
    .b6_wr_en(b6_wr_en),
    .b7_wr_addr(b7_wr_addr),
    .b7_wr_en(b7_wr_en),
    .b8_wr_addr(b8_wr_addr),
    .b8_wr_en(b8_wr_en),
    .b9_wr_addr(b9_wr_addr),
    .b9_wr_en(b9_wr_en),
    .addr_chain(addr_chain),
    .bwe_chain(bwe_chain),
    .dbiterr_chain(dbiterr_chain),
    .din_chain(din_chain),
    .dout_chain(dout_chain),
    .en_chain(en_chain),
    .rdacess_chain(rdacess_chain),
    .rdb_wr_chain(rdb_wr_chain),
    .sbiterr_chain(sbiterr_chain)
);

task automatic pulse_cascade_write(
    input integer bram_index,
    input integer write_address
);
begin
    @(negedge clk);
    case (bram_index)
        3: begin b3_wr_addr[0] = write_address; b3_wr_en[0] = 1'b1; end
        4: begin b4_wr_addr[0] = write_address; b4_wr_en[0] = 1'b1; end
        5: begin b5_wr_addr[0] = write_address; b5_wr_en[0] = 1'b1; end
        6: begin b6_wr_addr[0] = write_address; b6_wr_en[0] = 1'b1; end
        7: begin b7_wr_addr[0] = write_address; b7_wr_en[0] = 1'b1; end
        8: begin b8_wr_addr[0] = write_address; b8_wr_en[0] = 1'b1; end
        9: begin b9_wr_addr[0] = write_address; b9_wr_en[0] = 1'b1; end
    endcase
    repeat (2) @(posedge clk);
    #1;
    b3_wr_en[0] = 1'b0;
    b4_wr_en[0] = 1'b0;
    b5_wr_en[0] = 1'b0;
    b6_wr_en[0] = 1'b0;
    b7_wr_en[0] = 1'b0;
    b8_wr_en[0] = 1'b0;
    b9_wr_en[0] = 1'b0;
    // Allow the registered source read/cascade output to settle before the
    // next stage consumes it.
    repeat (4) @(posedge clk);
end
endtask

task automatic write_primary_bram(
    input integer bram_index,
    input integer write_address,
    input logic [7:0] value
);
begin
    @(negedge clk);
    if (bram_index == 1) begin
        b1_wr_addr[0] = write_address;
        b1_wr_data[0] = {8'd0, value};
        b1_wr_en[0] = 1'b1;
    end else begin
        b2_wr_addr[0] = write_address;
        b2_wr_data[0] = {8'd0, value};
        b2_wr_en[0] = 1'b1;
    end
    repeat (2) @(posedge clk);
    #1;
    b1_wr_en[0] = 1'b0;
    b2_wr_en[0] = 1'b0;
    repeat (4) @(posedge clk);
end
endtask

task automatic load_odd_weight(
    input integer destination_bram,
    input integer target_address,
    input logic [7:0] value
);
begin
    write_primary_bram(1, WEIGHT_SCRATCH_ADDR, value);
    pulse_cascade_write(3, destination_bram == 3 ? target_address : WEIGHT_SCRATCH_ADDR);
    if (destination_bram >= 5)
        pulse_cascade_write(5, destination_bram == 5 ? target_address : WEIGHT_SCRATCH_ADDR);
    if (destination_bram >= 7)
        pulse_cascade_write(7, destination_bram == 7 ? target_address : WEIGHT_SCRATCH_ADDR);
    if (destination_bram >= 9)
        pulse_cascade_write(9, target_address);
end
endtask

task automatic load_even_weight(
    input integer destination_bram,
    input integer target_address,
    input logic [7:0] value
);
begin
    write_primary_bram(2, WEIGHT_SCRATCH_ADDR, value);
    pulse_cascade_write(4, destination_bram == 4 ? target_address : WEIGHT_SCRATCH_ADDR);
    if (destination_bram >= 6)
        pulse_cascade_write(6, destination_bram == 6 ? target_address : WEIGHT_SCRATCH_ADDR);
    if (destination_bram >= 8)
        pulse_cascade_write(8, target_address);
end
endtask

task automatic initialize_memories;
begin
    // The Xilinx RAM primitives suppress writes while their reset ports are
    // asserted, so load data with reset released. The controller is reset
    // again after initialization before the checked transaction starts.
    rst = 1'b0;
    ce = 1'b1;
    uram1_wr_addr[0] = '0;
    uram2_wr_addr[0] = '0;
    uram3_wr_addr[0] = '0;
    uram4_wr_addr[0] = '0;
    uram1_wr_data[0] = '0;
    uram2_wr_data[0] = '0;
    uram3_wr_data[0] = '0;
    uram4_wr_data[0] = '0;
    uram1_wr_en[0] = 1'b0;
    uram2_wr_en[0] = 1'b0;
    uram3_wr_en[0] = 1'b0;
    uram4_wr_en[0] = 1'b0;

    // Port A is a four-URAM cascade. A command enters through the FIRST
    // instance and ADDR_A[13:12] selects lane 0..3. Low address bits select
    // five consecutive MVM transactions at addresses 0,16,32,48,64.
    for (lane_index = 0; lane_index < MVM_LANES; lane_index = lane_index + 1) begin
        for (vector_index = 0; vector_index < MVM_VECTORS; vector_index = vector_index + 1) begin
            @(negedge clk);
            uram1_wr_addr[0] = (lane_index << 12) | (vector_index * 16);
            uram1_wr_data[0] = mm_a_mem[lane_index*MVM_VECTORS + vector_index];
            uram1_wr_en[0] = 1'b1;
            repeat (6) @(posedge clk);
        end
    end
    @(negedge clk);
    uram1_wr_en[0] = 1'b0;

    // The controller has completed five reads and now holds all delayed master
    // addresses at the unused scratch address 80. Use only the legal b1/b2
    // data ports and the existing BRAM cascade to load b3..b9.
    repeat (10) @(posedge clk);
`ifndef POST_SIM
    if (dut.name[0].dut.master_rdaddr !== WEIGHT_SCRATCH_ADDR)
        $fatal(1, "MVM weight loader expected master_rdaddr=%0d, got %0d",
            WEIGHT_SCRATCH_ADDR, dut.name[0].dut.master_rdaddr);
`endif

    for (vector_index = 0; vector_index < MVM_VECTORS; vector_index = vector_index + 1) begin
        load_odd_weight(9, vector_index*16, mm_b_mem[vector_index*MVM_REDUCTION + 8]);
        load_odd_weight(7, vector_index*16, mm_b_mem[vector_index*MVM_REDUCTION + 6]);
        load_odd_weight(5, vector_index*16, mm_b_mem[vector_index*MVM_REDUCTION + 4]);
        load_odd_weight(3, vector_index*16, mm_b_mem[vector_index*MVM_REDUCTION + 2]);
        write_primary_bram(1, vector_index*16, mm_b_mem[vector_index*MVM_REDUCTION]);

        load_even_weight(8, vector_index*16, mm_b_mem[vector_index*MVM_REDUCTION + 7]);
        load_even_weight(6, vector_index*16, mm_b_mem[vector_index*MVM_REDUCTION + 5]);
        load_even_weight(4, vector_index*16, mm_b_mem[vector_index*MVM_REDUCTION + 3]);
        write_primary_bram(2, vector_index*16, mm_b_mem[vector_index*MVM_REDUCTION + 1]);
    end

end
endtask

task automatic check_result(
    input integer lane,
    input integer vector,
    input logic [M_W-1:0] actual,
    input logic [7:0] expected
);
begin
    if ($isunknown(actual) || actual !== {10'd0, expected}) begin
        $error("MVM pass %0d output[%0d][%0d] mismatch: actual=%02h expected=%02h",
            current_pass, lane, vector, actual, expected);
        errors = errors + 1;
    end else begin
        $display("MVM pass %0d output[%0d][%0d] PASS: %02h", current_pass, lane, vector, actual);
    end
end
endtask

task automatic run_and_check_pass(input integer pass_index);
begin
    current_pass = pass_index;
    @(negedge clk);
    bram1_rd_en[0] = 1'b0;
    bram2_rd_en[0] = 1'b0;
    bram3_rd_en[0] = 1'b0;
    bram4_rd_en[0] = 1'b0;
    rst = 1'b1;
    trace_enable = 1'b1;
    repeat (4) @(posedge clk);
    @(negedge clk);
    rst = 1'b0;
    repeat (160 + 9*MAC_ADD_PIPE + FINAL_ADD_PIPE) @(posedge clk);

    for (vector_index = 0; vector_index < MVM_VECTORS; vector_index = vector_index + 1) begin
        @(negedge clk);
        bram1_rd_addr[0] = vector_index * 16;
        bram2_rd_addr[0] = vector_index * 16;
        bram3_rd_addr[0] = vector_index * 16;
        bram4_rd_addr[0] = vector_index * 16;
        bram1_rd_en[0] = 1'b1;
        bram2_rd_en[0] = 1'b1;
        bram3_rd_en[0] = 1'b1;
        bram4_rd_en[0] = 1'b1;
        repeat (12) @(posedge clk);
        #1;
        check_result(0, vector_index, bram1_rd_data[0],
            mm_golden_mem[vector_index]);
        check_result(1, vector_index, bram2_rd_data[0],
            mm_golden_mem[MVM_VECTORS + vector_index]);
        check_result(2, vector_index, bram3_rd_data[0],
            mm_golden_mem[2*MVM_VECTORS + vector_index]);
        check_result(3, vector_index, bram4_rd_data[0],
            mm_golden_mem[3*MVM_VECTORS + vector_index]);
    end

`ifndef POST_SIM
    for (lane_index = 0; lane_index < MVM_LANES; lane_index = lane_index + 1) begin
        if (result_writes[lane_index] != MVM_VECTORS)
            $fatal(1, "MVM pass %0d lane %0d wrote %0d/%0d results", pass_index,
                lane_index, result_writes[lane_index], MVM_VECTORS);
        total_result_writes = total_result_writes + result_writes[lane_index];
    end
`endif
end
endtask

initial begin
    if (!$value$plusargs("VECTOR_DIR=%s", vector_dir))
        $fatal(1, "+VECTOR_DIR is required");
    $readmemh({vector_dir, "/mm_a.mem"}, mm_a_mem);
    $readmemh({vector_dir, "/mm_b.mem"}, mm_b_mem);
    $readmemh({vector_dir, "/mm_golden.mem"}, mm_golden_mem);

    uram1_wr_en[0] = 1'b0;
    uram2_wr_en[0] = 1'b0;
    uram3_wr_en[0] = 1'b0;
    uram4_wr_en[0] = 1'b0;
    bram1_rd_addr[0] = '0;
    bram2_rd_addr[0] = '0;
    bram3_rd_addr[0] = '0;
    bram4_rd_addr[0] = '0;
    bram1_rd_en[0] = 1'b0;
    bram2_rd_en[0] = 1'b0;
    bram3_rd_en[0] = 1'b0;
    bram4_rd_en[0] = 1'b0;
    b1_wr_addr[0] = '0;
    b2_wr_addr[0] = '0;
    b3_wr_addr[0] = '0;
    b4_wr_addr[0] = '0;
    b5_wr_addr[0] = '0;
    b6_wr_addr[0] = '0;
    b7_wr_addr[0] = '0;
    b8_wr_addr[0] = '0;
    b9_wr_addr[0] = '0;
    b1_wr_en[0] = 1'b0;
    b2_wr_en[0] = 1'b0;
    b3_wr_en[0] = 1'b0;
    b4_wr_en[0] = 1'b0;
    b5_wr_en[0] = 1'b0;
    b6_wr_en[0] = 1'b0;
    b7_wr_en[0] = 1'b0;
    b8_wr_en[0] = 1'b0;
    b9_wr_en[0] = 1'b0;
    addr_chain[0] = '0;
    bwe_chain[0] = '0;
    dbiterr_chain[0] = '0;
    din_chain[0] = '0;
    dout_chain[0] = '0;
    en_chain[0] = '0;
    rdacess_chain[0] = '0;
    rdb_wr_chain[0] = '0;
    sbiterr_chain[0] = '0;

    // glbl keeps GSR asserted for roughly 100 ns. Wait past it before RAM
    // writes; otherwise the Unisim models silently discard early stimuli.
    #200;
    initialize_memories();

    run_and_check_pass(1);
    trace_enable = 1'b0;
    $readmemh({vector_dir, "/mm_a_second.mem"}, mm_a_mem);
    $readmemh({vector_dir, "/mm_b_second.mem"}, mm_b_mem);
    $readmemh({vector_dir, "/mm_accum_golden.mem"}, mm_golden_mem);
    initialize_memories();
    run_and_check_pass(2);
`ifndef POST_SIM
    $display("TRACE_SUMMARY passes=2 result_writes=%0d trace_errors=%0d",
        total_result_writes, trace_errors);
`else
    $display("POSTSIM_SUMMARY unit=MVM passes=2 expected_comparisons=%0d errors=%0d period_ns=%0.3f",
        2*MVM_LANES*MVM_VECTORS, errors, CLK_PERIOD_NS);
`endif

    if (errors != 0)
        $fatal(1, "MM Y=1 validation failed with %0d mismatch(es)", errors);
    if (trace_errors != 0)
        $fatal(1, "MVM write trace failed with %0d errors", trace_errors);
    $display("MM Y=1 validation PASS");
    $finish;
end

endmodule
