`timescale 1ns/1ps

module tb_conv_chip #(
    parameter integer IMG_W = 4,
    parameter integer IMG_D = 6,
    parameter real CLK_PERIOD_NS = 10.0
);

localparam integer Y = 1;
localparam integer KERN_SZ = 3;
localparam integer IMAGE_WORDS = IMG_W * IMG_D;
localparam integer OUTPUT_ROWS = IMG_D - KERN_SZ + 1;
    localparam integer OUTPUT_COLUMNS = IMG_W - KERN_SZ + 1;
    localparam integer WORDS_PER_ROW = (OUTPUT_COLUMNS + 1) / 2;
    localparam integer RESULT_WORDS = OUTPUT_ROWS * WORDS_PER_ROW;
    localparam integer MAC_ADD_PIPE = 2;
    localparam integer WB_ADD_PIPE  = 2;
    localparam integer MAC_DELAY0   = 12 + 9*MAC_ADD_PIPE;
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
logic [URAM_A_W-1:0] uram2_rd_addr_external [Y];
logic read_en_external [Y];
wire [URAM_D_W-1:0] uram2_rd_data [Y];
logic ld_new_kernel [Y];
logic [A_W-1:0] krnl_bram1_wraddr [Y];
logic [M_W-1:0] krnl_bram1_wrdata [Y];
logic krnl_bram1_wren [Y];
logic [A_W-1:0] krnl_bram2_wraddr [Y];
logic [M_W-1:0] krnl_bram2_wrdata [Y];
logic krnl_bram2_wren [Y];
logic [22:0] addr_chain [Y];
logic [8:0] bwe_chain [Y];
logic [0:0] dbiterr_chain [Y];
logic [71:0] din_chain [Y];
logic [71:0] dout_chain [Y];
logic [0:0] en_chain [Y];
logic [0:0] rdacess_chain [Y];
logic [0:0] rdb_wr_chain [Y];
logic [0:0] sbiterr_chain [Y];

logic [71:0] conv_image_mem [0:IMAGE_WORDS-1];
logic [7:0] conv_kernel1_mem [0:8];
logic [7:0] conv_kernel2_mem [0:8];
logic [71:0] conv_golden_word_mem [0:RESULT_WORDS-1];
logic [71:0] conv_accum_golden_word_mem [0:RESULT_WORDS-1];
string vector_dir;
integer errors = 0;
integer index;
integer compare_index;
integer trace_cycle = 0;
integer b1_write_count = 0;
integer b2_write_count = 0;
integer b3_write_count = 0;
integer result_write_count = 0;
integer trace_errors = 0;
integer total_trace_errors = 0;
integer total_result_write_count = 0;
integer lane0_index;
integer lane1_index;
integer kernel_settle_count = 0;
integer mac_stage;
integer mac_delay;
integer scan_row;
integer scan_column;
integer scan_tap;
integer expected_pixel_index;
logic trace_enable = 1'b0;
logic kernel_shift_seen = 1'b0;
logic kernel_checked = 1'b0;
integer active_pass = 0;
integer valid_window_count = 0;
integer check_word;
logic valid_window_found;
logic normal_window_match;
logic flipped_window_match;
logic [7:0] mac_a0_history [0:8][0:MAC_DELAY0];
logic [7:0] mac_a1_history [0:8][0:MAC_DELAY0];
logic [7:0] effective_mac_a0 [0:8];
logic [7:0] effective_mac_a1 [0:8];

always #(CLK_PERIOD_NS/2.0) clk = ~clk;

`ifndef POST_SIM
function automatic integer find_lane0_pixel(input logic [7:0] value);
    integer pixel_index;
begin
    find_lane0_pixel = -1;
    for (pixel_index = 0; pixel_index < IMAGE_WORDS; pixel_index = pixel_index + 1)
        if (value === conv_image_mem[pixel_index][7:0])
            find_lane0_pixel = pixel_index;
end
endfunction

function automatic integer find_lane1_pixel(input logic [7:0] value);
    integer pixel_index;
begin
    find_lane1_pixel = -1;
    for (pixel_index = 0; pixel_index < IMAGE_WORDS; pixel_index = pixel_index + 1)
        if (value === conv_image_mem[pixel_index][23:16])
            find_lane1_pixel = pixel_index;
end
endfunction

task automatic check_kernel_operands;
    integer tap;
    logic [7:0] actual_weight1 [0:8];
    logic [7:0] actual_weight2 [0:8];
begin
    actual_weight1[0] = dut.name[0].dut.conv1.fp_b[0];
    actual_weight1[1] = dut.name[0].dut.conv1.fp_b[1];
    actual_weight1[2] = dut.name[0].dut.conv1.fp_b[2];
    actual_weight1[3] = dut.name[0].dut.conv1.fp_b[3];
    actual_weight1[4] = dut.name[0].dut.conv1.fp_b[4];
    actual_weight1[5] = dut.name[0].dut.conv1.fp_b[5];
    actual_weight1[6] = dut.name[0].dut.conv1.fp_b[6];
    actual_weight1[7] = dut.name[0].dut.conv1.fp_b[7];
    actual_weight1[8] = dut.name[0].dut.conv1.fp_b[8];
    actual_weight2[0] = dut.name[0].dut.conv2.fp_b[0];
    actual_weight2[1] = dut.name[0].dut.conv2.fp_b[1];
    actual_weight2[2] = dut.name[0].dut.conv2.fp_b[2];
    actual_weight2[3] = dut.name[0].dut.conv2.fp_b[3];
    actual_weight2[4] = dut.name[0].dut.conv2.fp_b[4];
    actual_weight2[5] = dut.name[0].dut.conv2.fp_b[5];
    actual_weight2[6] = dut.name[0].dut.conv2.fp_b[6];
    actual_weight2[7] = dut.name[0].dut.conv2.fp_b[7];
    actual_weight2[8] = dut.name[0].dut.conv2.fp_b[8];

    for (tap = 0; tap < 9; tap = tap + 1) begin
        // The generator reverses the load file because the serial kernel
        // shift register presents the original row-major order at fp_b[0:8].
        if (actual_weight1[tap] !== conv_kernel1_mem[8-tap]) begin
            $display(
                "TRACE_ERROR kernel1 tap=%0d actual=%02h expected=%02h",
                tap, actual_weight1[tap], conv_kernel1_mem[8-tap]
            );
            trace_errors = trace_errors + 1;
        end
        if (actual_weight2[tap] !== conv_kernel2_mem[8-tap]) begin
            $display(
                "TRACE_ERROR kernel2 tap=%0d actual=%02h expected=%02h",
                tap, actual_weight2[tap], conv_kernel2_mem[8-tap]
            );
            trace_errors = trace_errors + 1;
        end
    end
    $display(
        "TRACE_KERNEL_CHECK cycle=%0d lane0=%02h_%02h_%02h_%02h_%02h_%02h_%02h_%02h_%02h lane1=%02h_%02h_%02h_%02h_%02h_%02h_%02h_%02h_%02h errors=%0d",
        trace_cycle,
        actual_weight1[0], actual_weight1[1], actual_weight1[2],
        actual_weight1[3], actual_weight1[4], actual_weight1[5],
        actual_weight1[6], actual_weight1[7], actual_weight1[8],
        actual_weight2[0], actual_weight2[1], actual_weight2[2],
        actual_weight2[3], actual_weight2[4], actual_weight2[5],
        actual_weight2[6], actual_weight2[7], actual_weight2[8],
        trace_errors
    );
end
endtask

// Sample at the falling edge. All RTL state and RAM outputs have settled from
// the preceding rising edge, while write-enable/address/data are the values
// that will be consumed by the following rising edge.
always @(negedge clk) begin
    if (trace_enable) begin
        if (rst) begin
            trace_cycle = 0;
            b1_write_count = 0;
            b2_write_count = 0;
            b3_write_count = 0;
            result_write_count = 0;
            valid_window_count = 0;
            kernel_shift_seen = 1'b0;
            kernel_checked = 1'b0;
            kernel_settle_count = 0;
            for (mac_stage = 0; mac_stage < 9; mac_stage = mac_stage + 1)
                for (mac_delay = 0; mac_delay <= MAC_DELAY0; mac_delay = mac_delay + 1) begin
                    mac_a0_history[mac_stage][mac_delay] = 8'd0;
                    mac_a1_history[mac_stage][mac_delay] = 8'd0;
                end
        end else begin
            trace_cycle = trace_cycle + 1;

            if (dut.name[0].dut.k_state != 10'b0000000001)
                kernel_shift_seen = 1'b1;
            if (kernel_shift_seen && !kernel_checked &&
                dut.name[0].dut.k_state == 10'b0000000001) begin
                // k_state returns to idle before the RAM output and serial
                // weight registers have drained. Four extra cycles are
                // required for NUMBER_OF_REG=3 before fp_b[0:8] is stable.
                if (kernel_settle_count == 4) begin
                    check_kernel_operands();
                    kernel_checked = 1'b1;
                end else begin
                    kernel_settle_count = kernel_settle_count + 1;
                end
            end

            // Reconstruct the nine image operands contributing to the current
            // data_out. Each PCOUT stage adds one cycle; the multiplier input
            // path contributes the common remaining delay. Therefore tap i of
            // data_out at cycle T came from ain_r1 at cycle T-(12-i)-9*ADD_PIPE.
            for (mac_stage = 0; mac_stage < 9; mac_stage = mac_stage + 1)
                for (mac_delay = MAC_DELAY0; mac_delay > 0; mac_delay = mac_delay - 1) begin
                    mac_a0_history[mac_stage][mac_delay] =
                        mac_a0_history[mac_stage][mac_delay-1];
                    mac_a1_history[mac_stage][mac_delay] =
                        mac_a1_history[mac_stage][mac_delay-1];
                end
            mac_a0_history[0][0] = dut.name[0].dut.conv1.fpmac_chain[0].fpmac_inst.ain_r1;
            mac_a0_history[1][0] = dut.name[0].dut.conv1.fpmac_chain[1].fpmac_inst.ain_r1;
            mac_a0_history[2][0] = dut.name[0].dut.conv1.fpmac_chain[2].fpmac_inst.ain_r1;
            mac_a0_history[3][0] = dut.name[0].dut.conv1.fpmac_chain[3].fpmac_inst.ain_r1;
            mac_a0_history[4][0] = dut.name[0].dut.conv1.fpmac_chain[4].fpmac_inst.ain_r1;
            mac_a0_history[5][0] = dut.name[0].dut.conv1.fpmac_chain[5].fpmac_inst.ain_r1;
            mac_a0_history[6][0] = dut.name[0].dut.conv1.fpmac_chain[6].fpmac_inst.ain_r1;
            mac_a0_history[7][0] = dut.name[0].dut.conv1.fpmac_chain[7].fpmac_inst.ain_r1;
            mac_a0_history[8][0] = dut.name[0].dut.conv1.fpmac_chain[8].fpmac_inst.ain_r1;
            mac_a1_history[0][0] = dut.name[0].dut.conv2.fpmac_chain[0].fpmac_inst.ain_r1;
            mac_a1_history[1][0] = dut.name[0].dut.conv2.fpmac_chain[1].fpmac_inst.ain_r1;
            mac_a1_history[2][0] = dut.name[0].dut.conv2.fpmac_chain[2].fpmac_inst.ain_r1;
            mac_a1_history[3][0] = dut.name[0].dut.conv2.fpmac_chain[3].fpmac_inst.ain_r1;
            mac_a1_history[4][0] = dut.name[0].dut.conv2.fpmac_chain[4].fpmac_inst.ain_r1;
            mac_a1_history[5][0] = dut.name[0].dut.conv2.fpmac_chain[5].fpmac_inst.ain_r1;
            mac_a1_history[6][0] = dut.name[0].dut.conv2.fpmac_chain[6].fpmac_inst.ain_r1;
            mac_a1_history[7][0] = dut.name[0].dut.conv2.fpmac_chain[7].fpmac_inst.ain_r1;
            mac_a1_history[8][0] = dut.name[0].dut.conv2.fpmac_chain[8].fpmac_inst.ain_r1;
            for (mac_stage = 0; mac_stage < 9; mac_stage = mac_stage + 1) begin
                effective_mac_a0[mac_stage] =
                    mac_a0_history[mac_stage][MAC_DELAY0-mac_stage];
                effective_mac_a1[mac_stage] =
                    mac_a1_history[mac_stage][MAC_DELAY0-mac_stage];
            end

            // Identify complete 3x3 windows independently from their numeric
            // result. Check both normal row order and the bottom-to-top order
            // naturally produced by the three line buffers.
            valid_window_found = 1'b0;
            for (scan_row = 0; scan_row < OUTPUT_ROWS; scan_row = scan_row + 1)
                for (scan_column = 0; scan_column < OUTPUT_COLUMNS; scan_column = scan_column + 1) begin
                    normal_window_match = 1'b1;
                    flipped_window_match = 1'b1;
                    for (scan_tap = 0; scan_tap < 9; scan_tap = scan_tap + 1) begin
                        expected_pixel_index =
                            (scan_row + scan_tap/3) * IMG_W +
                            scan_column + scan_tap%3;
                        if (effective_mac_a0[scan_tap] !==
                                conv_image_mem[expected_pixel_index][7:0] ||
                            effective_mac_a1[scan_tap] !==
                                conv_image_mem[expected_pixel_index][23:16])
                            normal_window_match = 1'b0;
                        expected_pixel_index =
                            (scan_row + 2 - scan_tap/3) * IMG_W +
                            scan_column + scan_tap%3;
                        if (effective_mac_a0[scan_tap] !==
                                conv_image_mem[expected_pixel_index][7:0] ||
                            effective_mac_a1[scan_tap] !==
                                conv_image_mem[expected_pixel_index][23:16])
                            flipped_window_match = 1'b0;
                    end
                    if (normal_window_match)
                        $display(
                            "TRACE_MAC_WINDOW cycle=%0d row=%0d column=%0d order=top_to_bottom output0=%02h output1=%02h data_valid=%b",
                            trace_cycle, scan_row, scan_column,
                            dut.name[0].dut.data_out_conv1[7:0],
                            dut.name[0].dut.data_out_conv2[7:0],
                            dut.name[0].dut.data_valid
                        );
                    if (flipped_window_match && dut.name[0].dut.data_valid) begin
                        valid_window_found = 1'b1;
                        if (scan_row != valid_window_count / OUTPUT_COLUMNS ||
                            scan_column != valid_window_count % OUTPUT_COLUMNS) begin
                            $display("TRACE_ERROR MAC window order row=%0d col=%0d index=%0d", scan_row, scan_column, valid_window_count);
                            trace_errors = trace_errors + 1;
                        end
                    end
                    if (flipped_window_match)
                        $display(
                            "TRACE_MAC_WINDOW cycle=%0d row=%0d column=%0d order=bottom_to_top output0=%02h output1=%02h data_valid=%b",
                            trace_cycle, scan_row, scan_column,
                            dut.name[0].dut.data_out_conv1[7:0],
                            dut.name[0].dut.data_out_conv2[7:0],
                            dut.name[0].dut.data_valid
                        );
                end

            if (dut.name[0].dut.data_valid) begin
                if (!valid_window_found) begin
                    $display("TRACE_ERROR data_valid without a complete MAC window cycle=%0d", trace_cycle);
                    trace_errors = trace_errors + 1;
                end
                valid_window_count = valid_window_count + 1;
            end

            if (dut.name[0].dut.b1_wr_en) begin
                lane0_index = find_lane0_pixel(
                    dut.name[0].dut.uram_rd_data_linebuf[7:0]);
                lane1_index = find_lane1_pixel(
                    dut.name[0].dut.uram_rd_data_linebuf[23:16]);
                if (b1_write_count >= IMAGE_WORDS ||
                    lane0_index != b1_write_count ||
                    lane1_index != b1_write_count ||
                    dut.name[0].dut.b1_wr_addr != (b1_write_count % IMG_W) * 16) begin
                    $display(
                        "TRACE_ERROR B1_WRITE cycle=%0d count=%0d addr=%0d lane0_index=%0d lane1_index=%0d data=%018h",
                        trace_cycle, b1_write_count,
                        dut.name[0].dut.b1_wr_addr,
                        lane0_index, lane1_index,
                        dut.name[0].dut.uram_rd_data_linebuf
                    );
                    trace_errors = trace_errors + 1;
                end
                b1_write_count = b1_write_count + 1;
            end

            if (dut.name[0].dut.b2_wr_en) begin
                lane0_index = find_lane0_pixel(
                    dut.name[0].dut.conv1.casc_data_b1[7:0]);
                lane1_index = find_lane1_pixel(
                    dut.name[0].dut.conv2.casc_data_b1[7:0]);
                if (lane0_index != b2_write_count ||
                    lane1_index != b2_write_count ||
                    dut.name[0].dut.b2_wr_addr != (b2_write_count % IMG_W) * 16) begin
                    $display(
                        "TRACE_ERROR B2_WRITE cycle=%0d count=%0d addr=%0d lane0_index=%0d lane1_index=%0d",
                        trace_cycle, b2_write_count,
                        dut.name[0].dut.b2_wr_addr,
                        lane0_index, lane1_index
                    );
                    trace_errors = trace_errors + 1;
                end
                b2_write_count = b2_write_count + 1;
            end

            if (dut.name[0].dut.b3_wr_en) begin
                lane0_index = find_lane0_pixel(
                    dut.name[0].dut.conv1.casc_data_b2[7:0]);
                lane1_index = find_lane1_pixel(
                    dut.name[0].dut.conv2.casc_data_b2[7:0]);
                if (lane0_index != b3_write_count ||
                    lane1_index != b3_write_count ||
                    dut.name[0].dut.b3_wr_addr != (b3_write_count % IMG_W) * 16) begin
                    $display(
                        "TRACE_ERROR B3_WRITE cycle=%0d count=%0d addr=%0d lane0_index=%0d lane1_index=%0d",
                        trace_cycle, b3_write_count,
                        dut.name[0].dut.b3_wr_addr,
                        lane0_index, lane1_index
                    );
                    trace_errors = trace_errors + 1;
                end
                b3_write_count = b3_write_count + 1;
            end

            if (dut.name[0].dut.uram2_wr_en) begin
                if (result_write_count >= RESULT_WORDS) begin
                    $display("TRACE_ERROR extra Conv result write");
                    trace_errors = trace_errors + 1;
                end else if (dut.name[0].dut.uram2_rd_addr !== result_write_count*16 ||
                    dut.name[0].dut.uram2_wr_data !== (active_pass == 1 ?
                        conv_golden_word_mem[result_write_count] : conv_accum_golden_word_mem[result_write_count])) begin
                    $display("TRACE_ERROR Conv write pass=%0d word=%0d addr=%0d data=%018h", active_pass,
                        result_write_count, dut.name[0].dut.uram2_rd_addr, dut.name[0].dut.uram2_wr_data);
                    trace_errors = trace_errors + 1;
                end
                $display(
                    "TRACE_RESULT_WRITE cycle=%0d write=%0d addr=%0d data=%018h valid=%b tog=%b",
                    trace_cycle, result_write_count,
                    dut.name[0].dut.uram2_rd_addr,
                    dut.name[0].dut.uram2_wr_data,
                    dut.name[0].dut.data_valid,
                    dut.name[0].dut.data_valid_tog
                );
                result_write_count = result_write_count + 1;
            end

        end
    end
end

`endif

`ifdef POST_SIM
dsp_conv_chip_post #(
`else
dsp_conv_chip #(
`endif
    .KERN_SZ(KERN_SZ),
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
    .uram2_rd_addr_external(uram2_rd_addr_external),
    .read_en_external(read_en_external),
    .uram2_rd_data(uram2_rd_data),
    .ld_new_kernel(ld_new_kernel),
    .krnl_bram1_wraddr(krnl_bram1_wraddr),
        .krnl_bram1_wrdata(krnl_bram1_wrdata),
        .krnl_bram1_wren(krnl_bram1_wren),
        .krnl_bram2_wraddr(krnl_bram2_wraddr),
        .krnl_bram2_wrdata(krnl_bram2_wrdata),
        .krnl_bram2_wren(krnl_bram2_wren),
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

task automatic initialize_memories;
begin
    // The Xilinx RAM primitives suppress writes while reset is asserted.
    // Reset the controller again after all image, kernel, and result data has
    // been initialized.
    rst = 1'b0;
    ce = 1'b1;

    // Load IMG_W * IMG_D packed image words through the chip's URAM port.
    for (index = 0; index < IMAGE_WORDS; index = index + 1) begin
        @(negedge clk);
        uram1_wr_addr[0] = index * 16;
        uram1_wr_data[0] = conv_image_mem[index];
        uram1_wr_en[0] = 1'b1;
    end
    @(negedge clk);
    uram1_wr_en[0] = 1'b0;

    // Both 3x3 kernels are loaded at native RAM addresses 0,16,...,128.
    for (index = 0; index < 9; index = index + 1) begin
        @(negedge clk);
        krnl_bram1_wraddr[0] = index * 16;
        krnl_bram2_wraddr[0] = index * 16;
        krnl_bram1_wrdata[0] = {10'd0, conv_kernel1_mem[index]};
        krnl_bram2_wrdata[0] = {10'd0, conv_kernel2_mem[index]};
        krnl_bram1_wren[0] = 1'b1;
        krnl_bram2_wren[0] = 1'b1;
    end
    @(negedge clk);
    krnl_bram1_wren[0] = 1'b0;
    krnl_bram2_wren[0] = 1'b0;

end
endtask

task automatic read_and_check_word(input integer pass_index, input integer word_index);
    logic [71:0] actual;
    logic [71:0] expected;
begin
    expected = pass_index == 1 ? conv_golden_word_mem[word_index] :
        conv_accum_golden_word_mem[word_index];
    @(negedge clk);
    uram2_rd_addr_external[0] = word_index * 16;
    read_en_external[0] = 1'b1;
    repeat (10) @(posedge clk);
    #1;
    actual = uram2_rd_data[0];
    if ($isunknown(actual) || actual !== expected) begin
        $error(
            "Conv pass %0d word %0d mismatch: actual=%018h expected=%018h",
            pass_index,
            word_index,
            actual,
            expected
        );
        errors = errors + 1;
    end else begin
        $display("Conv pass %0d word %0d PASS: %018h", pass_index, word_index, actual);
    end
end
endtask

task automatic run_and_check_pass(input integer pass_index);
begin
    active_pass = pass_index;
    trace_errors = 0;
    $display("TRACE_PASS_BEGIN pass=%0d", pass_index);
    @(negedge clk);
    read_en_external[0] = 1'b0;
    rst = 1'b1;
    trace_enable = 1'b1;
    repeat (4) @(posedge clk);
    @(negedge clk);
    rst = 1'b0;
    ld_new_kernel[0] = 1'b1;
    @(negedge clk);
    ld_new_kernel[0] = 1'b0;

    repeat (250 + 9*MAC_ADD_PIPE + WB_ADD_PIPE) @(posedge clk);
    for (check_word = 0; check_word < RESULT_WORDS; check_word = check_word + 1)
        read_and_check_word(pass_index, check_word);
`ifndef POST_SIM
    if (!kernel_checked || result_write_count != RESULT_WORDS ||
        valid_window_count != OUTPUT_ROWS*OUTPUT_COLUMNS || b1_write_count != IMAGE_WORDS)
        $fatal(1, "Conv pass %0d incomplete: kernel_checked=%b result_writes=%0d",
            pass_index, kernel_checked, result_write_count);
    $display(
        "TRACE_PASS_SUMMARY pass=%0d b1_writes=%0d b2_writes=%0d b3_writes=%0d result_writes=%0d trace_errors=%0d",
        pass_index, b1_write_count, b2_write_count, b3_write_count,
        result_write_count, trace_errors
    );
    total_trace_errors = total_trace_errors + trace_errors;
    total_result_write_count = total_result_write_count + result_write_count;
`endif
end
endtask

initial begin
    if (!$value$plusargs("VECTOR_DIR=%s", vector_dir))
        $fatal(1, "+VECTOR_DIR is required");
    $readmemh({vector_dir, "/conv_image.mem"}, conv_image_mem);
    $readmemh({vector_dir, "/conv_kernel1.mem"}, conv_kernel1_mem);
    $readmemh({vector_dir, "/conv_kernel2.mem"}, conv_kernel2_mem);
    $readmemh({vector_dir, "/conv_golden_word.mem"}, conv_golden_word_mem);
    $readmemh({vector_dir, "/conv_accum_golden_word.mem"}, conv_accum_golden_word_mem);

    // Address-sensitive coverage: repeated image words would allow a broken
    // URAM/line-buffer address path to produce the same numerical result.
    for (index = 0; index < IMAGE_WORDS; index = index + 1) begin
        if ($isunknown(conv_image_mem[index]))
            $fatal(1, "Conv input word %0d contains unknown bits", index);
        if (conv_image_mem[index][71:32] !== 40'd0 ||
            conv_image_mem[index][31:24] !== 8'd0 ||
            conv_image_mem[index][15:8] !== 8'd0)
            $fatal(1, "Conv input word %0d violates {8'h00, fp8_low} packing", index);
        for (compare_index = 0; compare_index < index; compare_index = compare_index + 1)
            if (conv_image_mem[index] === conv_image_mem[compare_index])
                $fatal(1, "Conv input words %0d and %0d are identical",
                    compare_index, index);
    end

    uram1_wr_addr[0] = '0;
    uram1_wr_data[0] = '0;
    uram1_wr_en[0] = 1'b0;
        uram2_rd_addr_external[0] = '0;
        read_en_external[0] = 1'b0;
        ld_new_kernel[0] = 1'b0;
        krnl_bram1_wraddr[0] = '0;
        krnl_bram1_wrdata[0] = '0;
        krnl_bram1_wren[0] = 1'b0;
        krnl_bram2_wraddr[0] = '0;
        krnl_bram2_wrdata[0] = '0;
        krnl_bram2_wren[0] = 1'b0;
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

    // Reset only the controller/MAC state between passes. RAM contents remain
    // intact, so pass 2 exercises FP8 writeback onto nonzero partial sums.
    run_and_check_pass(1);
    trace_enable = 1'b0;
    $readmemh({vector_dir, "/conv_image_second.mem"}, conv_image_mem);
    $readmemh({vector_dir, "/conv_kernel1_second.mem"}, conv_kernel1_mem);
    $readmemh({vector_dir, "/conv_kernel2_second.mem"}, conv_kernel2_mem);
    initialize_memories();
    run_and_check_pass(2);

`ifndef POST_SIM
    $display(
        "TRACE_SUMMARY passes=2 result_writes=%0d trace_errors=%0d",
        total_result_write_count, total_trace_errors
    );
`else
    $display("POSTSIM_SUMMARY unit=CONV passes=2 expected_comparisons=%0d errors=%0d period_ns=%0.3f",
        2*RESULT_WORDS, errors, CLK_PERIOD_NS);
`endif

    if (errors != 0)
        $fatal(1, "Conv Y=1 validation failed with %0d mismatch(es)", errors);
    if (total_trace_errors != 0)
        $fatal(1, "Conv Y=1 trace validation failed with %0d error(s)", total_trace_errors);
    $display("Conv Y=1 FP8 writeback validation PASS");
    $finish;
end

endmodule
