`timescale 1ns/1ps

// End-to-end counter -> fault injector -> FIFO -> checker test.
// The consumer is deliberately stalled in a deterministic pattern so the
// generator must stop advancing while the FIFO absorbs the burst.

module tb_stream_pipeline;

    localparam DATA_WIDTH = 128;
    localparam ADDR_WIDTH = 8;

    reg clk;
    reg rst;
    reg consumer_ready;
    reg fault_enable;
    integer failures;
    integer i;
    integer fault_started;
    integer saw_full;

    wire generator_valid;
    wire generator_ready;
    wire [DATA_WIDTH-1:0] generator_data;
    wire injected_valid;
    wire injected_ready;
    wire [DATA_WIDTH-1:0] injected_data;
    wire fault_applied;

    wire fifo_out_valid;
    wire fifo_out_ready;
    wire [DATA_WIDTH-1:0] fifo_out_data;
    wire fifo_in_ready;
    wire fifo_full;
    wire fifo_empty;
    wire [ADDR_WIDTH:0] fifo_occupancy;
    wire fifo_write_accept;
    wire fifo_read_accept;
    wire [63:0] fifo_overflow_attempts;
    wire [63:0] fifo_underflow_attempts;

    wire checker_in_valid;
    wire checker_ready;
    wire [63:0] checker_words;
    wire [63:0] checker_errors;
    wire [DATA_WIDTH-1:0] checker_expected;
    wire checker_error_pulse;

    wire [63:0] elapsed_cycles;
    wire [63:0] accepted_writes;
    wire [63:0] accepted_reads;
    wire [63:0] words_checked;
    wire [63:0] word_errors;
    wire [63:0] bit_errors;
    wire [63:0] fifo_full_cycles;
    wire [63:0] fifo_empty_cycles;
    wire [63:0] producer_stall_cycles;
    wire [63:0] consumer_stall_cycles;
    wire [ADDR_WIDTH:0] fifo_high_water;

    stream_counter_generator #(
        .DATA_WIDTH(DATA_WIDTH)
    ) generator (
        .clk       (clk),
        .rst       (rst),
        .out_ready (generator_ready),
        .out_valid (generator_valid),
        .out_data  (generator_data)
    );

    fault_injector #(
        .DATA_WIDTH(DATA_WIDTH)
    ) injector (
        .clk          (clk),
        .rst          (rst),
        .fault_enable (fault_enable),
        .fault_mask   (128'h1),
        .in_valid     (generator_valid),
        .in_ready     (generator_ready),
        .in_data      (generator_data),
        .out_valid    (injected_valid),
        .out_ready    (injected_ready),
        .out_data     (injected_data),
        .fault_applied(fault_applied)
    );

    assign injected_ready = fifo_in_ready;

    stream_fifo #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) fifo (
        .clk                (clk),
        .rst                (rst),
        .in_valid           (injected_valid),
        .in_ready           (fifo_in_ready),
        .in_data            (injected_data),
        .out_valid          (fifo_out_valid),
        .out_ready          (fifo_out_ready),
        .out_data           (fifo_out_data),
        .full               (fifo_full),
        .empty              (fifo_empty),
        .occupancy          (fifo_occupancy),
        .write_accept       (fifo_write_accept),
        .read_accept        (fifo_read_accept),
        .overflow_attempts  (fifo_overflow_attempts),
        .underflow_attempts (fifo_underflow_attempts)
    );

    assign fifo_out_ready = consumer_ready && checker_ready;
    assign checker_in_valid = fifo_out_valid && consumer_ready;

    stream_sequence_checker #(
        .DATA_WIDTH(DATA_WIDTH)
    ) checker (
        .clk            (clk),
        .rst            (rst),
        .in_valid       (checker_in_valid),
        .in_data        (fifo_out_data),
        .in_ready       (checker_ready),
        .words_checked  (checker_words),
        .word_errors    (checker_errors),
        .expected_value (checker_expected),
        .error_pulse    (checker_error_pulse)
    );

    performance_counters #(
        .DATA_WIDTH(DATA_WIDTH),
        .OCCUPANCY_WIDTH(ADDR_WIDTH+1)
    ) counters (
        .clk                   (clk),
        .rst                   (rst),
        .run_enable            (1'b1),
        .write_accept          (fifo_write_accept),
        .read_accept           (fifo_read_accept),
        .check_accept          (checker_in_valid && checker_ready),
        .word_error            (checker_error_pulse),
        .bit_error_count       (32'd0),
        .fifo_full             (fifo_full),
        .fifo_empty            (fifo_empty),
        .producer_stall        (generator_valid && !generator_ready),
        .consumer_stall        (fifo_out_valid && !fifo_out_ready),
        .fifo_occupancy        (fifo_occupancy),
        .elapsed_cycles        (elapsed_cycles),
        .accepted_writes       (accepted_writes),
        .accepted_reads        (accepted_reads),
        .words_checked         (words_checked),
        .word_errors           (word_errors),
        .bit_errors            (bit_errors),
        .fifo_full_cycles      (fifo_full_cycles),
        .fifo_empty_cycles     (fifo_empty_cycles),
        .producer_stall_cycles (producer_stall_cycles),
        .consumer_stall_cycles (consumer_stall_cycles),
        .fifo_high_water       (fifo_high_water)
    );

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    initial begin
        failures = 0;
        fault_started = 0;
        saw_full = 0;
        rst = 1'b1;
        consumer_ready = 1'b1;
        fault_enable = 1'b0;

        repeat (3) @(posedge clk);
        @(negedge clk);
        rst = 1'b0;

        for (i = 0; i < 2600; i = i + 1) begin
            @(negedge clk);

            // Three unavailable cycles out of every eleven create sustained
            // backpressure while preserving long accepted runs.
            consumer_ready = ((i % 11) >= 3);

            if (!fault_started && checker_words >= 64'd200) begin
                fault_enable = 1'b1;
                fault_started = 1;
            end
            else if (fault_started == 1) begin
                fault_enable = 1'b0;
                fault_started = 2;
            end

            if (fifo_full)
                saw_full = 1;

            @(posedge clk);
        end

        // Stop adding backpressure and drain any queued data.
        @(negedge clk);
        consumer_ready = 1'b1;
        fault_enable = 1'b0;
        repeat (600) @(posedge clk);
        @(negedge clk);

        if (checker_words < 64'd300)
            begin failures = failures + 1; $display("PIPELINE FAIL: too few words checked"); end
        if (checker_errors !== 64'd1)
            begin failures = failures + 1; $display("PIPELINE FAIL: expected exactly one injected word error"); end
        if (!saw_full)
            begin failures = failures + 1; $display("PIPELINE FAIL: FIFO never reached full under backpressure"); end
        if (producer_stall_cycles == 0)
            begin failures = failures + 1; $display("PIPELINE FAIL: producer never observed backpressure"); end
        if (fifo_high_water !== 256)
            begin failures = failures + 1; $display("PIPELINE FAIL: high-water mark was not 256"); end
        if (accepted_reads !== words_checked)
            begin failures = failures + 1; $display("PIPELINE FAIL: read/check counters disagree"); end

        // Reset while the source is active, then prove the complete pipeline
        // restarts from a clean zero sequence without inherited state.
        @(negedge clk);
        rst = 1'b1;
        consumer_ready = 1'b1;
        fault_enable = 1'b0;
        repeat (3) @(posedge clk);
        @(negedge clk);
        rst = 1'b0;
        repeat (140) @(posedge clk);
        @(negedge clk);
        if (checker_words < 64'd100)
            begin failures = failures + 1; $display("PIPELINE FAIL: reset restart did not produce fresh traffic"); end
        if (checker_errors !== 64'd0)
            begin failures = failures + 1; $display("PIPELINE FAIL: reset restart inherited sequence errors"); end

        if (failures == 0)
            $display("PIPELINE PASS: generator, fault injection, FIFO backpressure, checker, and counters passed");
        else
            $display("PIPELINE FAIL: %0d checks failed", failures);
        $finish;
    end

endmodule
