`timescale 1ns/1ps

// Parallel PRBS-31 generator.
// Polynomial: x^31 + x^28 + 1.
// For each output word, DATA_WIDTH successive PRBS bits are emitted in
// ascending bit positions and the LFSR advances by DATA_WIDTH steps.

module prbs_generator #(
    parameter DATA_WIDTH = 128,
    parameter [30:0] SEED = 31'h7fffffff
) (
    input  wire                  clk,
    input  wire                  rst,
    input  wire                  out_ready,
    output reg                   out_valid,
    output reg  [DATA_WIDTH-1:0] out_data
);

    reg [30:0] lfsr_state;

    function [DATA_WIDTH-1:0] word_from_state;
        input [30:0] state_in;
        reg [30:0] state;
        integer k;
        begin
            state = state_in;
            word_from_state = {DATA_WIDTH{1'b0}};
            for (k = 0; k < DATA_WIDTH; k = k + 1) begin
                word_from_state[k] = state[0];
                state = {state[29:0], state[30] ^ state[27]};
            end
        end
    endfunction

    function [30:0] advance_state;
        input [30:0] state_in;
        reg [30:0] state;
        integer k;
        begin
            state = state_in;
            for (k = 0; k < DATA_WIDTH; k = k + 1)
                state = {state[29:0], state[30] ^ state[27]};
            advance_state = state;
        end
    endfunction

    always @(posedge clk) begin
        if (rst) begin
            out_valid  <= 1'b0;
            out_data   <= word_from_state(SEED);
            lfsr_state <= advance_state(SEED);
        end
        else if (!out_valid) begin
            out_valid <= 1'b1;
        end
        else if (out_ready) begin
            out_data   <= word_from_state(lfsr_state);
            lfsr_state <= advance_state(lfsr_state);
        end
    end

endmodule
