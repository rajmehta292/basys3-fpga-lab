`timescale 1ns/1ps

// Synchronizes and debounces an active-high mechanical input.
// STABLE_CYCLES is deliberately a parameter so simulation can use a small
// value while hardware can use approximately 10 ms at 100 MHz.

module button_conditioner #(
    parameter STABLE_CYCLES = 1000000
) (
    input  wire clk,
    input  wire rst,
    input  wire async_in,
    output reg  level_out,
    output reg  rise_pulse,
    output reg  fall_pulse
);

    reg sync_meta;
    reg sync_level;
    reg [31:0] stable_count;

    always @(posedge clk) begin
        if (rst) begin
            sync_meta   <= 1'b0;
            sync_level  <= 1'b0;
            stable_count <= 32'd0;
            level_out   <= 1'b0;
            rise_pulse  <= 1'b0;
            fall_pulse  <= 1'b0;
        end
        else begin
            sync_meta  <= async_in;
            sync_level <= sync_meta;
            rise_pulse <= 1'b0;
            fall_pulse <= 1'b0;

            if (sync_level == level_out) begin
                stable_count <= 32'd0;
            end
            else if (STABLE_CYCLES <= 1 || stable_count >= STABLE_CYCLES - 1) begin
                if (sync_level)
                    rise_pulse <= 1'b1;
                else
                    fall_pulse <= 1'b1;
                level_out    <= sync_level;
                stable_count <= 32'd0;
            end
            else begin
                stable_count <= stable_count + 1'b1;
            end
        end
    end

endmodule
