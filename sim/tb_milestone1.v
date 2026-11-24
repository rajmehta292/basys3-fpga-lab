`timescale 1ns/1ps

// Self-checking Milestone 1 testbench.
//
// It verifies:
//   1. Synchronous reset initializes the generator and checker.
//   2. The generator holds valid and data during backpressure.
//   3. Accepted generator transfers produce 0, 1, 2, ... in order.
//   4. The integrated generator/checker path has no errors.
//   5. Invalid cycles do not advance the checker.
//   6. A deliberately corrupted word is counted exactly once when it is the
//      final word in the test.  A missing word would cause a cascade in this
//      simple non-resynchronizing checker; that behavior is documented.

module tb_milestone1;

    localparam DATA_WIDTH = 128;

    reg clk;
    reg rst;
    integer failures;
    integer i;

    // A 100 MHz simulation clock: 10 ns period.
    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    // ---------------------------------------------------------------------
    // Generator under explicit backpressure.
    // ---------------------------------------------------------------------
    reg stall_ready;
    wire stall_valid;
    wire [DATA_WIDTH-1:0] stall_data;

    stream_counter_generator #(
        .DATA_WIDTH(DATA_WIDTH)
    ) generator_under_test (
        .clk       (clk),
        .rst       (rst),
        .out_ready (stall_ready),
        .out_valid (stall_valid),
        .out_data  (stall_data)
    );

    // ---------------------------------------------------------------------
    // Always-ready integrated generator/checker path.
    // ---------------------------------------------------------------------
    wire integrated_valid;
    wire [DATA_WIDTH-1:0] integrated_data;
    wire integrated_ready;
    wire [63:0] integrated_words;
    wire [63:0] integrated_errors;
    wire [DATA_WIDTH-1:0] integrated_expected;
    wire integrated_error_pulse;

    stream_counter_generator #(
        .DATA_WIDTH(DATA_WIDTH)
    ) integrated_generator (
        .clk       (clk),
        .rst       (rst),
        .out_ready (integrated_ready),
        .out_valid (integrated_valid),
        .out_data  (integrated_data)
    );

    stream_sequence_checker #(
        .DATA_WIDTH(DATA_WIDTH)
    ) integrated_checker (
        .clk            (clk),
        .rst            (rst),
        .in_valid       (integrated_valid),
        .in_data        (integrated_data),
        .in_ready       (integrated_ready),
        .words_checked  (integrated_words),
        .word_errors    (integrated_errors),
        .expected_value (integrated_expected),
        .error_pulse    (integrated_error_pulse)
    );

    // ---------------------------------------------------------------------
    // Direct checker stimulus for invalid-cycle and fault tests.
    // ---------------------------------------------------------------------
    reg manual_rst;
    reg manual_valid;
    reg [DATA_WIDTH-1:0] manual_data;
    wire manual_ready;
    wire [63:0] manual_words;
    wire [63:0] manual_errors;
    wire [DATA_WIDTH-1:0] manual_expected;
    wire manual_error_pulse;

    stream_sequence_checker #(
        .DATA_WIDTH(DATA_WIDTH)
    ) manual_checker (
        .clk            (clk),
        .rst            (manual_rst),
        .in_valid       (manual_valid),
        .in_data        (manual_data),
        .in_ready       (manual_ready),
        .words_checked  (manual_words),
        .word_errors    (manual_errors),
        .expected_value (manual_expected),
        .error_pulse    (manual_error_pulse)
    );

    task report_failure;
        input [1023:0] message;
        begin
            failures = failures + 1;
            $display("FAIL: %0s", message);
        end
    endtask

    initial begin
        failures     = 0;
        rst          = 1'b1;
        manual_rst   = 1'b1;
        stall_ready  = 1'b0;
        manual_valid = 1'b0;
        manual_data  = {DATA_WIDTH{1'b0}};

        // Hold reset for three rising edges.  Reset is synchronous, so the
        // DUTs only observe it at these edges.
        repeat (3) @(posedge clk);
        @(negedge clk);
        rst = 1'b0;

        // --------------------------
        // Test 1: generator stalls.
        // --------------------------
        // The first active cycle presents word zero.  With ready low, it
        // must remain stable for all four observations.
        for (i = 0; i < 4; i = i + 1) begin
            @(negedge clk);
            if (stall_valid !== 1'b1)
                report_failure("generator did not assert valid after reset");
            if (stall_data !== {DATA_WIDTH{1'b0}})
                report_failure("generator changed data while stalled");
        end

        // Accept sixteen words and verify that the registered output advances
        // exactly once per accepted edge.
        @(negedge clk);
        stall_ready = 1'b1;
        for (i = 0; i < 16; i = i + 1) begin
            @(posedge clk);
            @(negedge clk);
            if (stall_valid !== 1'b1)
                report_failure("generator dropped valid during accepted traffic");
            if (stall_data !== (i + 1))
                report_failure("generator sequence advanced incorrectly");
        end

        // --------------------------
        // Test 2: clean integrated path.
        // --------------------------
        // Reset both integrated modules, then wait for exactly 32 accepted
        // words.  One extra edge is needed because valid is asserted one
        // cycle after reset is released.
        @(negedge clk);
        rst = 1'b1;
        repeat (2) @(posedge clk);
        @(negedge clk);
        rst = 1'b0;
        repeat (33) @(posedge clk);
        @(negedge clk);

        if (integrated_words !== 64'd32)
            report_failure("integrated checker counted the wrong number of words");
        if (integrated_errors !== 64'd0)
            report_failure("integrated clean path reported an error");
        if (integrated_expected !== 32)
            report_failure("integrated checker expected value is incorrect");

        // --------------------------
        // Test 3: invalid cycles and one final corrupted word.
        // --------------------------
        @(negedge clk);
        manual_rst   = 1'b0;
        manual_valid = 1'b0;

        // Four valid words, each separated by an invalid cycle.
        for (i = 0; i < 4; i = i + 1) begin
            @(negedge clk);
            manual_data  = i;
            manual_valid = 1'b1;
            @(posedge clk);
            @(negedge clk);
            manual_valid = 1'b0;
            @(posedge clk);
        end

        // The checker expects four here.  Word 99 is deliberately corrupt.
        @(negedge clk);
        manual_data  = 128'd99;
        manual_valid = 1'b1;
        @(posedge clk);
        @(negedge clk);
        manual_valid = 1'b0;
        @(posedge clk);
        @(negedge clk);

        if (manual_ready !== 1'b1)
            report_failure("checker unexpectedly backpressured the testbench");
        if (manual_words !== 64'd5)
            report_failure("checker advanced on an invalid cycle or missed a transfer");
        if (manual_errors !== 64'd1)
            report_failure("checker did not count the deliberately corrupted word");
        if (manual_expected !== 5)
            report_failure("checker expected value did not advance after the error");

        if (failures == 0) begin
            $display("MILESTONE1 PASS: generator, handshake hold, checker, and fault test passed");
        end
        else begin
            $display("MILESTONE1 FAIL: %0d checks failed", failures);
        end

        $finish;
    end

endmodule
