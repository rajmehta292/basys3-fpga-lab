`timescale 1ns/1ps

// Milestone 1: checker for the counter sequence 0, 1, 2, ...
//
// This first checker is an always-ready consumer.  A later FIFO/consumer
// module will provide backpressure to the source.  The checker still uses
// the same accepted-transfer definition: in_valid && in_ready.

module stream_sequence_checker #(
    parameter DATA_WIDTH = 128
) (
    input  wire                  clk,
    input  wire                  rst,
    input  wire                  in_valid,
    input  wire  [DATA_WIDTH-1:0] in_data,
    output wire                  in_ready,
    output reg   [63:0]           words_checked,
    output reg   [63:0]           word_errors,
    output reg   [DATA_WIDTH-1:0] expected_value,
    output reg                    error_pulse
);

    // There is no internal queue in this checker, so it can accept one word
    // on every clock.  The transfer condition is still explicit and is used
    // by the sequential logic below.
    assign in_ready = 1'b1;

    wire transfer_accepted;
    assign transfer_accepted = in_valid && in_ready;

    always @(posedge clk) begin
        if (rst) begin
            words_checked <= 64'd0;
            word_errors   <= 64'd0;
            expected_value <= {DATA_WIDTH{1'b0}};
            error_pulse   <= 1'b0;
        end
        else begin
            // error_pulse is a one-clock event indicator.
            error_pulse <= 1'b0;

            if (transfer_accepted) begin
                if (in_data != expected_value) begin
                    word_errors <= word_errors + 1'b1;
                    error_pulse <= 1'b1;
                end

                words_checked  <= words_checked + 1'b1;
                expected_value <= expected_value + 1'b1;
            end
        end
    end

endmodule
