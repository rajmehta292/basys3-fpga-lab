`timescale 1ns/1ps
`default_nettype none

module tb_reaction_timer;
    logic clk = 1'b0;
    logic btnC = 1'b0;
    logic btnU = 1'b0;
    logic btnD = 1'b0;
    logic [15:0] sw = 16'h0000;
    logic [15:0] led;
    logic [6:0] seg;
    logic dp;
    logic [3:0] an;

    always #5 clk = ~clk;

    reaction_timer #(
        .CLK_HZ(100), .TICK_HZ(10), .BUTTON_FILTER_CYCLES(1)
    ) dut (.*);

    task automatic reset_dut;
        begin
            btnC = 1'b1;
            repeat (5) @(posedge clk);
            btnC = 1'b0;
            repeat (5) @(posedge clk);
        end
    endtask

    task automatic press_up;
        begin
            btnU = 1'b1;
            repeat (4) @(posedge clk);
            btnU = 1'b0;
            repeat (5) @(posedge clk);
        end
    endtask

    task automatic press_down;
        begin
            btnD = 1'b1;
            repeat (4) @(posedge clk);
            btnD = 1'b0;
            repeat (5) @(posedge clk);
        end
    endtask

    initial begin
        reset_dut();
        if (dut.state !== dut.IDLE) $fatal(1, "reset did not reach IDLE");

        press_up();
        if (dut.state !== dut.WAITING) $fatal(1, "UP did not start wait");

        repeat (600) @(posedge clk);
        if (dut.state !== dut.GO) $fatal(1, "random wait did not reach GO");
        press_down();
        if (dut.state !== dut.RESULT || dut.early !== 1'b0)
            $fatal(1, "valid reaction was not recorded");

        reset_dut();
        press_up();
        press_down();
        if (dut.state !== dut.RESULT || dut.early !== 1'b1)
            $fatal(1, "early reaction was not detected");

        $display("REACTION TIMER PASS");
        $finish;
    end
endmodule

`default_nettype wire
