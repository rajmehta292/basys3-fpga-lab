`timescale 1ns/1ps
`default_nettype none

module tb_pwm_breathing;
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

    pwm_breathing #(.BREATH_STEP_DIV(2)) dut (.*);

    initial begin
        btnC = 1'b1;
        repeat (4) @(posedge clk);
        btnC = 1'b0;
        repeat (40) @(posedge clk);
        if (dut.brightness == 0 || dut.brightness == 8'hFF)
            $fatal(1, "brightness envelope did not advance");

        sw = 16'h0001;
        repeat (10) @(posedge clk);
        if (led[15:1] !== 15'h0000)
            $fatal(1, "switch mask leaked into unselected LEDs");

        $display("PWM BREATHING PASS");
        $finish;
    end
endmodule

`default_nettype wire
