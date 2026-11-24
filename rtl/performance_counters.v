`timescale 1ns/1ps

// Measurement counters. All event counters advance only while run_enable is
// asserted. The host can derive throughput from words_checked, DATA_WIDTH,
// CLOCK_HZ, and elapsed_cycles without relying on UART timing.

module performance_counters #(
    parameter DATA_WIDTH = 128,
    parameter OCCUPANCY_WIDTH = 9
) (
    input  wire                       clk,
    input  wire                       rst,
    input  wire                       run_enable,
    input  wire                       write_accept,
    input  wire                       read_accept,
    input  wire                       check_accept,
    input  wire                       word_error,
    input  wire [31:0]                bit_error_count,
    input  wire                       fifo_full,
    input  wire                       fifo_empty,
    input  wire                       producer_stall,
    input  wire                       consumer_stall,
    input  wire [OCCUPANCY_WIDTH-1:0] fifo_occupancy,
    output reg  [63:0]                elapsed_cycles,
    output reg  [63:0]                accepted_writes,
    output reg  [63:0]                accepted_reads,
    output reg  [63:0]                words_checked,
    output reg  [63:0]                word_errors,
    output reg  [63:0]                bit_errors,
    output reg  [63:0]                fifo_full_cycles,
    output reg  [63:0]                fifo_empty_cycles,
    output reg  [63:0]                producer_stall_cycles,
    output reg  [63:0]                consumer_stall_cycles,
    output reg  [OCCUPANCY_WIDTH-1:0] fifo_high_water
);

    always @(posedge clk) begin
        if (rst) begin
            elapsed_cycles       <= 64'd0;
            accepted_writes      <= 64'd0;
            accepted_reads       <= 64'd0;
            words_checked        <= 64'd0;
            word_errors          <= 64'd0;
            bit_errors           <= 64'd0;
            fifo_full_cycles     <= 64'd0;
            fifo_empty_cycles    <= 64'd0;
            producer_stall_cycles <= 64'd0;
            consumer_stall_cycles <= 64'd0;
            fifo_high_water      <= {OCCUPANCY_WIDTH{1'b0}};
        end
        else if (run_enable) begin
            elapsed_cycles <= elapsed_cycles + 1'b1;

            if (write_accept)
                accepted_writes <= accepted_writes + 1'b1;
            if (read_accept)
                accepted_reads <= accepted_reads + 1'b1;
            if (check_accept)
                words_checked <= words_checked + 1'b1;
            if (word_error)
                word_errors <= word_errors + 1'b1;
            if (bit_error_count != 0)
                bit_errors <= bit_errors + bit_error_count;
            if (fifo_full)
                fifo_full_cycles <= fifo_full_cycles + 1'b1;
            if (fifo_empty)
                fifo_empty_cycles <= fifo_empty_cycles + 1'b1;
            if (producer_stall)
                producer_stall_cycles <= producer_stall_cycles + 1'b1;
            if (consumer_stall)
                consumer_stall_cycles <= consumer_stall_cycles + 1'b1;
            if (fifo_occupancy > fifo_high_water)
                fifo_high_water <= fifo_occupancy;
        end
    end

endmodule
