`timescale 1ns/1ps

module tb_uart_tx;

    reg clk;
    reg rst;
    reg start;
    reg [7:0] data;
    wire tx;
    wire busy;
    integer failures;
    integer i;
    reg [9:0] expected_frame;

    // 100 Hz clock and 10 baud make each UART bit ten simulation clocks.
    uart_tx #(
        .CLOCK_HZ(100),
        .BAUD_RATE(10)
    ) dut (
        .clk  (clk),
        .rst  (rst),
        .start(start),
        .data (data),
        .tx   (tx),
        .busy (busy)
    );

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    initial begin
        failures = 0;
        start = 1'b0;
        data = 8'hA5;
        rst = 1'b1;
        repeat (2) @(posedge clk);
        @(negedge clk);
        rst = 1'b0;
        start = 1'b1;
        @(posedge clk);
        @(negedge clk);
        start = 1'b0;

        expected_frame = {1'b1, 8'hA5, 1'b0};
        if (!busy) begin failures = failures + 1; $display("UART FAIL: transmitter did not become busy"); end

        // The start bit is already present after the launch edge. Sample each
        // bit in the middle of its ten-clock interval.
        for (i = 0; i < 10; i = i + 1) begin
            repeat (5) @(posedge clk);
            if (tx !== expected_frame[i]) begin
                failures = failures + 1;
                $display("UART FAIL: bit %0d expected %b got %b", i, expected_frame[i], tx);
            end
            repeat (5) @(posedge clk);
        end

        // Allow the stop-bit interval to complete and the transmitter to
        // return to idle after the final sampled midpoint.
        repeat (2) @(posedge clk);
        if (busy) begin failures = failures + 1; $display("UART FAIL: transmitter remained busy after stop bit"); end
        if (failures == 0)
            $display("UART PASS: 8-N-1 frame timing passed");
        else
            $display("UART FAIL: %0d checks failed", failures);
        $finish;
    end

endmodule
