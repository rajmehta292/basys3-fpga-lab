`timescale 1ns/1ps
`default_nettype none

// Synchronizes and debounces one active-high Basys3 pushbutton. `press` is a
// one-clock pulse when the debounced state changes from low to high.
module button_onepulse #(
    parameter integer FILTER_CYCLES = 1_000_000
) (
    input  logic clk,
    input  logic rst,
    input  logic button,
    output logic press,
    output logic level
);
    localparam integer COUNT_WIDTH = (FILTER_CYCLES <= 1) ? 1 : $clog2(FILTER_CYCLES);

    logic meta;
    logic sync;
    logic stable;
    logic [COUNT_WIDTH-1:0] count;

    always_ff @(posedge clk) begin
        if (rst) begin
            meta   <= 1'b0;
            sync   <= 1'b0;
            stable <= 1'b0;
            count  <= '0;
            press  <= 1'b0;
        end else begin
            meta  <= button;
            sync  <= meta;
            press <= 1'b0;

            if (sync == stable) begin
                count <= '0;
            end else if (FILTER_CYCLES <= 1) begin
                stable <= sync;
                count  <= '0;
                if (sync)
                    press <= 1'b1;
            end else if (count == FILTER_CYCLES-1) begin
                stable <= sync;
                count  <= '0;
                if (sync)
                    press <= 1'b1;
            end else begin
                count <= count + 1'b1;
            end
        end
    end

    assign level = stable;
endmodule

`default_nettype wire
