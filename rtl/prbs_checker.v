`timescale 1ns/1ps

// Matching PRBS-31 checker. It reports both word errors and differing bits.

module prbs_checker #(
    parameter DATA_WIDTH = 128,
    parameter [30:0] SEED = 31'h7fffffff
) (
    input  wire                  clk,
    input  wire                  rst,
    input  wire                  in_valid,
    input  wire [DATA_WIDTH-1:0] in_data,
    output wire                  in_ready,
    output reg  [63:0]           words_checked,
    output reg  [63:0]           word_errors,
    output reg  [63:0]           bit_errors,
    output reg                   error_pulse,
    output reg  [31:0]            bit_error_pulse_count
);

    reg [30:0] lfsr_state;
    wire transfer_accepted;

    assign in_ready = 1'b1;
    assign transfer_accepted = in_valid && in_ready;

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

    function [31:0] population_count;
        input [DATA_WIDTH-1:0] value;
        integer k;
        begin
            population_count = 32'd0;
            for (k = 0; k < DATA_WIDTH; k = k + 1)
                population_count = population_count + value[k];
        end
    endfunction

    reg [DATA_WIDTH-1:0] expected_word;
    reg [DATA_WIDTH-1:0] difference;
    reg [31:0] differing_bits;

    always @* begin
        expected_word  = word_from_state(lfsr_state);
        difference     = in_data ^ expected_word;
        differing_bits = population_count(difference);
    end

    always @(posedge clk) begin
        if (rst) begin
            lfsr_state          <= SEED;
            words_checked       <= 64'd0;
            word_errors         <= 64'd0;
            bit_errors          <= 64'd0;
            error_pulse         <= 1'b0;
            bit_error_pulse_count <= 32'd0;
        end
        else begin
            error_pulse           <= 1'b0;
            bit_error_pulse_count <= 32'd0;
            if (transfer_accepted) begin
                if (differing_bits != 0) begin
                    word_errors <= word_errors + 1'b1;
                    error_pulse <= 1'b1;
                end
                words_checked <= words_checked + 1'b1;
                bit_errors <= bit_errors + differing_bits;
                bit_error_pulse_count <= differing_bits;
                lfsr_state <= advance_state(lfsr_state);
            end
        end
    end

endmodule
