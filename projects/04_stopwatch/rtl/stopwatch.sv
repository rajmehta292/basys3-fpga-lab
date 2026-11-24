`timescale 1ns/1ps
`default_nettype none

// Four-digit decimal stopwatch. UP toggles run/pause, DOWN clears while
// paused, and CENTER resets unconditionally. Display format is M:SSt where
// the rightmost digit is tenths of a second.
module stopwatch #(
    parameter integer CLK_HZ = 100_000_000,
    parameter integer TICK_HZ = 10,
    parameter integer BUTTON_FILTER_CYCLES = 1_000_000
) (
    input  logic        clk,
    input  logic        btnC,
    input  logic        btnU,
    input  logic        btnD,
    input  logic [15:0] sw,
    output logic [15:0] led,
    output logic [6:0]  seg,
    output logic        dp,
    output logic [3:0]  an
);
    localparam integer TICK_DIV = CLK_HZ / TICK_HZ;
    logic rst;
    logic [26:0] tick_count;
    logic tenth_tick;
    logic up_press;
    logic down_press;
    logic running;
    logic [3:0] tenths;
    logic [3:0] seconds_ones;
    logic [3:0] seconds_tens;
    logic [3:0] minutes;
    logic [15:0] display_value;

    basys3_reset_sync reset_i (.clk(clk), .btn_c(btnC), .rst(rst));
    button_onepulse #(.FILTER_CYCLES(BUTTON_FILTER_CYCLES)) up_i (
        .clk(clk), .rst(rst), .button(btnU), .press(up_press), .level()
    );
    button_onepulse #(.FILTER_CYCLES(BUTTON_FILTER_CYCLES)) down_i (
        .clk(clk), .rst(rst), .button(btnD), .press(down_press), .level()
    );

    assign tenth_tick = (tick_count == TICK_DIV-1);

    always_ff @(posedge clk) begin
        if (rst) begin
            tick_count    <= '0;
            running       <= 1'b0;
            tenths        <= '0;
            seconds_ones  <= '0;
            seconds_tens  <= '0;
            minutes       <= '0;
        end else begin
            if (tenth_tick)
                tick_count <= '0;
            else
                tick_count <= tick_count + 1'b1;

            if (up_press)
                running <= ~running;
            else if (down_press && !running) begin
                tenths       <= '0;
                seconds_ones <= '0;
                seconds_tens <= '0;
                minutes       <= '0;
            end else if (tenth_tick && running) begin
                if (tenths == 9) begin
                    tenths <= 0;
                    if (seconds_ones == 9) begin
                        seconds_ones <= 0;
                        if (seconds_tens == 5) begin
                            seconds_tens <= 0;
                            if (minutes == 9)
                                minutes <= 0;
                            else
                                minutes <= minutes + 1'b1;
                        end else begin
                            seconds_tens <= seconds_tens + 1'b1;
                        end
                    end else begin
                        seconds_ones <= seconds_ones + 1'b1;
                    end
                end else begin
                    tenths <= tenths + 1'b1;
                end
            end
        end
    end

    always @* begin
        display_value = {minutes, seconds_tens, seconds_ones, tenths};
        led           = {sw[15:1], running};
    end

    basys3_display display_i (
        .clk(clk), .rst(rst), .value(display_value), .dp_enable(running),
        .seg(seg), .dp(dp), .an(an)
    );
endmodule

`default_nettype wire
