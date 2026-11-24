`timescale 1ns/1ps

// Self-checking FIFO testbench. The reference model records every accepted
// write and compares every accepted read against the oldest stored word.

module tb_stream_fifo;

    localparam DATA_WIDTH = 128;
    localparam ADDR_WIDTH = 8;

    reg clk;
    reg rst;
    reg in_valid;
    reg [DATA_WIDTH-1:0] in_data;
    reg out_ready;

    wire in_ready;
    wire out_valid;
    wire [DATA_WIDTH-1:0] out_data;
    wire full;
    wire empty;
    wire [ADDR_WIDTH:0] occupancy;
    wire write_accept;
    wire read_accept;
    wire [63:0] overflow_attempts;
    wire [63:0] underflow_attempts;

    reg [DATA_WIDTH-1:0] reference [0:2047];
    integer reference_head;
    integer reference_tail;
    integer reference_count;
    integer failures;
    integer i;
    integer last_write;
    integer last_read;
    integer full_seen;

    stream_fifo #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) dut (
        .clk               (clk),
        .rst               (rst),
        .in_valid          (in_valid),
        .in_ready          (in_ready),
        .in_data           (in_data),
        .out_valid         (out_valid),
        .out_ready         (out_ready),
        .out_data          (out_data),
        .full              (full),
        .empty             (empty),
        .occupancy         (occupancy),
        .write_accept      (write_accept),
        .read_accept       (read_accept),
        .overflow_attempts (overflow_attempts),
        .underflow_attempts (underflow_attempts)
    );

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    task fail;
        input [1023:0] message;
        begin
            failures = failures + 1;
            $display("FIFO FAIL: %0s", message);
        end
    endtask

    // Score signals before the active edge. The FIFO samples the same stable
    // values on that edge; its nonblocking updates happen afterward.
    task one_cycle;
        begin
            @(negedge clk);
            last_write = in_valid && in_ready;
            last_read  = out_valid && out_ready;

            if (last_read) begin
                if (reference_count == 0)
                    fail("FIFO produced a read with an empty reference model");
                else if (out_data !== reference[reference_head])
                    fail("FIFO output did not match the oldest reference word");
                else begin
                    reference_head = reference_head + 1;
                    reference_count = reference_count - 1;
                end
            end

            if (last_write) begin
                reference[reference_tail] = in_data;
                reference_tail = reference_tail + 1;
                reference_count = reference_count + 1;
            end

            if (full)
                full_seen = 1;

            @(posedge clk);
        end
    endtask

    initial begin
        failures        = 0;
        reference_head  = 0;
        reference_tail  = 0;
        reference_count = 0;
        full_seen       = 0;
        in_valid        = 1'b0;
        in_data         = 128'd0;
        out_ready       = 1'b0;
        rst             = 1'b1;

        repeat (3) @(posedge clk);
        @(negedge clk);
        rst = 1'b0;

        // Empty read attempts must not fabricate data.
        out_ready = 1'b1;
        one_cycle;
        one_cycle;
        out_ready = 1'b0;

        // Fill beyond capacity with no reads. The producer must hold the
        // current data while full and overflow attempts must be recorded.
        in_valid = 1'b1;
        in_data  = 128'd0;
        for (i = 0; i < 300; i = i + 1) begin
            one_cycle;
            if (last_write)
                in_data = in_data + 1'b1;
        end
        in_valid = 1'b0;

        if (!full_seen)
            fail("FIFO never reached full during the overfill test");
        if (overflow_attempts == 0)
            fail("FIFO did not count rejected writes while full");
        if (reference_count != 256)
            fail("reference model did not contain the expected 256 words");
        if (occupancy !== 256)
            fail("FIFO occupancy did not reach 256");

        // Drain the FIFO completely. This exercises the registered output
        // latency and the transition from full to empty.
        out_ready = 1'b1;
        for (i = 0; i < 320; i = i + 1)
            one_cycle;

        if (reference_count != 0)
            fail("FIFO did not drain to the empty reference state");
        if (!empty)
            fail("FIFO empty flag was not asserted after draining");
        if (underflow_attempts == 0)
            fail("FIFO did not count an empty read attempt");

        // Randomized deterministic traffic with simultaneous reads/writes and
        // backpressure. The source only advances its word after acceptance.
        in_valid = 1'b1;
        in_data  = 128'h1000;
        for (i = 0; i < 1000; i = i + 1) begin
            out_ready = ((i % 7) != 0);
            one_cycle;
            if (last_write)
                in_data = in_data + 1'b1;
        end
        in_valid  = 1'b0;
        out_ready = 1'b1;
        for (i = 0; i < 1200; i = i + 1)
            one_cycle;

        if (reference_count != 0)
            fail("randomized traffic left words in the reference model");
        if (!empty)
            fail("randomized traffic did not end empty");

        if (failures == 0)
            $display("FIFO PASS: full, empty, registered output, stalls, and randomized traffic passed");
        else
            $display("FIFO FAIL: %0d checks failed", failures);

        $finish;
    end

endmodule
