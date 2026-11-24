`timescale 1ns/1ps
`default_nettype none

// A self-contained LED breathing controller. With no switches on, all LEDs
// breathe together. Turning on any switch selects those LED channels. The
// seven-segment display shows the current 8-bit brightness in hexadecimal.
module pwm_breathing #(
    parameter integer BREATH_STEP_DIV = 250_000
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
    logic rst;
    logic [7:0] pwm_counter;
    logic [7:0] brightness;
    logic       rising;
    logic [17:0] step_count;
    logic [15:0] mask;
    logic [15:0] display_value;

    basys3_reset_sync reset_i (.clk(clk), .btn_c(btnC), .rst(rst));

    always_ff @(posedge clk) begin
        if (rst) begin
            pwm_counter <= '0;
            brightness  <= 8'd1;
            rising      <= 1'b1;
            step_count  <= '0;
        end else begin
            pwm_counter <= pwm_counter + 1'b1;
            if (step_count == BREATH_STEP_DIV-1) begin
                step_count <= '0;
                if (rising) begin
                    if (brightness == 8'hFF) begin
                        brightness <= 8'hFE;
                        rising     <= 1'b0;
                    end else begin
                        brightness <= brightness + 1'b1;
                    end
                end else if (brightness == 0) begin
                    brightness <= 1;
                    rising     <= 1'b1;
                end else begin
                    brightness <= brightness - 1'b1;
                end
            end else begin
                step_count <= step_count + 1'b1;
            end
        end
    end

    always @* begin
        mask = (sw == 16'h0000) ? 16'hFFFF : sw;
        led  = {16{pwm_counter < brightness}} & mask;
        display_value = {8'h00, brightness};
    end

    basys3_display display_i (
        .clk(clk), .rst(rst), .value(display_value), .dp_enable(1'b1),
        .seg(seg), .dp(dp), .an(an)
    );
endmodule

`default_nettype wire
