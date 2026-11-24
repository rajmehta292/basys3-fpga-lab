`timescale 1ns/1ps
`default_nettype none

module tb_stopwatch;
    logic clk = 1'b0;
    logic btnC = 1'b0;
    logic btnU = 1'b0;
    logic btnD = 1'b0;
    logic [15:0] sw = 16'hA5A5;
    logic [15:0] led;
    logic [6:0] seg;
    logic dp;
    logic [3:0] an;

    always #5 clk = ~clk;

    stopwatch #(
        .CLK_HZ(100), .TICK_HZ(10), .BUTTON_FILTER_CYCLES(1)
    ) dut (.*);

    task automatic pulse_up;
        begin
            btnU = 1'b1;
            repeat (4) @(posedge clk);
            btnU = 1'b0;
            repeat (5) @(posedge clk);
        end
    endtask

    task automatic pulse_down;
        begin
            btnD = 1'b1;
            repeat (4) @(posedge clk);
            btnD = 1'b0;
            repeat (5) @(posedge clk);
        end
    endtask

    initial begin
        btnC = 1'b1;
        repeat (5) @(posedge clk);
        btnC = 1'b0;
        repeat (5) @(posedge clk);

        pulse_up();
        repeat (45) @(posedge clk);
        if (!dut.running || dut.tenths == 0)
            $fatal(1, "stopwatch did not advance while running");

        pulse_up();
        if (dut.running) $fatal(1, "stopwatch did not pause");
        pulse_down();
        if (dut.tenths !== 0 || dut.seconds_ones !== 0 ||
            dut.seconds_tens !== 0 || dut.minutes !== 0)
            $fatal(1, "stopwatch did not clear while paused");

        $display("STOPWATCH PASS");
        $finish;
    end
endmodule

`default_nettype wire
