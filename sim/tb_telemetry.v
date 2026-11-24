`timescale 1ns/1ps

module tb_telemetry;

    reg clk;
    reg rst;
    reg snapshot_request;
    reg run_active;
    reg [63:0] words_checked;
    reg [63:0] word_errors;
    reg [63:0] elapsed_cycles;
    reg [63:0] bit_errors;
    reg [8:0] fifo_high_water;
    reg [63:0] fifo_full_cycles;
    reg [63:0] fifo_empty_cycles;
    reg [63:0] accepted_writes;
    reg [63:0] accepted_reads;
    reg [63:0] producer_stall_cycles;
    reg [63:0] consumer_stall_cycles;
    reg [63:0] overflow_attempts;
    reg [63:0] underflow_attempts;
    wire uart_start;
    wire [7:0] uart_data;
    wire uart_busy;
    wire telemetry_busy;
    reg [7:0] captured [0:255];
    integer captured_count;
    integer failures;
    integer i;

    // A one-cycle fake UART acceptance interval. This checks telemetry's
    // handshake without simulating the baud divider again.
    assign uart_busy = uart_start;

    telemetry_controller dut (
        .clk              (clk),
        .rst              (rst),
        .snapshot_request (snapshot_request),
        .run_active       (run_active),
        .words_checked    (words_checked),
        .word_errors      (word_errors),
        .elapsed_cycles   (elapsed_cycles),
        .bit_errors       (bit_errors),
        .fifo_high_water  (fifo_high_water),
        .fifo_full_cycles (fifo_full_cycles),
        .fifo_empty_cycles(fifo_empty_cycles),
        .accepted_writes  (accepted_writes),
        .accepted_reads   (accepted_reads),
        .producer_stall_cycles(producer_stall_cycles),
        .consumer_stall_cycles(consumer_stall_cycles),
        .overflow_attempts(overflow_attempts),
        .underflow_attempts(underflow_attempts),
        .uart_busy        (uart_busy),
        .uart_start       (uart_start),
        .uart_data        (uart_data),
        .busy             (telemetry_busy)
    );

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    always @(posedge clk) begin
        if (uart_start) begin
            captured[captured_count] = uart_data;
            captured_count = captured_count + 1;
        end
    end

    initial begin
        failures = 0;
        captured_count = 0;
        rst = 1'b1;
        snapshot_request = 1'b0;
        run_active = 1'b1;
        words_checked = 64'h123;
        word_errors = 64'h2;
        elapsed_cycles = 64'h456;
        bit_errors = 64'h5;
        fifo_high_water = 9'h12;
        fifo_full_cycles = 64'h7;
        fifo_empty_cycles = 64'h9;
        accepted_writes = 64'hA;
        accepted_reads = 64'hB;
        producer_stall_cycles = 64'hC;
        consumer_stall_cycles = 64'hD;
        overflow_attempts = 64'hE;
        underflow_attempts = 64'hF;

        repeat (3) @(posedge clk);
        @(negedge clk);
        rst = 1'b0;
        snapshot_request = 1'b1;
        @(posedge clk);
        @(negedge clk);
        snapshot_request = 1'b0;

        repeat (2000) @(posedge clk);

        if (captured_count !== 245) begin
            failures = failures + 1;
            $display("TELEMETRY FAIL: expected 245 bytes, got %0d", captured_count);
        end
        if (captured[0] !== "S" || captured[1] !== "T" || captured[2] !== "A" ||
            captured[3] !== "T" || captured[4] !== " " || captured[5] !== "W" ||
            captured[6] !== "=") begin
            failures = failures + 1;
            $display("TELEMETRY FAIL: STAT W header is malformed");
        end
        if (captured[22] !== "3" || captured[41] !== "2" ||
            captured[60] !== "6" || captured[79] !== "5") begin
            failures = failures + 1;
            $display("TELEMETRY FAIL: hexadecimal counter fields are malformed");
        end
        if (captured[86] !== "2" || captured[105] !== "7" ||
            captured[124] !== "9" || captured[128] !== "1" ||
            captured[147] !== "A" || captured[166] !== "B" ||
            captured[185] !== "C" || captured[204] !== "D" ||
            captured[223] !== "E" || captured[242] !== "F") begin
            failures = failures + 1;
            $display("TELEMETRY FAIL: high-water, status, or transfer fields are malformed");
        end
        if (captured[243] !== 8'h0d || captured[244] !== 8'h0a)
            begin failures = failures + 1; $display("TELEMETRY FAIL: missing CRLF terminator"); end

        if (failures == 0)
            $display("TELEMETRY PASS: coherent structured status frame passed");
        else
            $display("TELEMETRY FAIL: %0d checks failed", failures);
        $finish;
    end

endmodule
