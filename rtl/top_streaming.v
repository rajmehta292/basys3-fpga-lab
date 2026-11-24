`timescale 1ns/1ps

// Basys 3 top level for the internal streaming validation system.
//
// Board controls:
//   BTN_RST   synchronous-system reset request through reset_sync
//   BTN_START starts the counter source
//   BTN_STOP  stops new production after the current handshake completes
//   SW_FAULT  XOR-corrupts accepted words with bit zero
//
// LED0 running, LED1 any word error, LED2 FIFO full, LED3 completed/nonempty
// test. UART_TX carries a coherent status line after stop.

module top_streaming (
    input  wire       CLK100MHZ,
    input  wire       BTN_RST,
    input  wire       BTN_START,
    input  wire       BTN_STOP,
    input  wire       SW_FAULT,
    output wire       UART_TX,
    output wire [3:0] LED
);

    localparam DATA_WIDTH = 128;
    localparam ADDR_WIDTH = 8;

    wire rst;
    reset_sync reset_conditioner (
        .clk         (CLK100MHZ),
        .async_reset (BTN_RST),
        .sync_reset  (rst)
    );

    wire start_level;
    wire start_pulse;
    wire stop_level;
    wire stop_pulse;
    wire fault_level;

    button_conditioner start_conditioner (
        .clk        (CLK100MHZ),
        .rst        (rst),
        .async_in   (BTN_START),
        .level_out  (start_level),
        .rise_pulse (start_pulse),
        .fall_pulse ()
    );

    button_conditioner stop_conditioner (
        .clk        (CLK100MHZ),
        .rst        (rst),
        .async_in   (BTN_STOP),
        .level_out  (stop_level),
        .rise_pulse (stop_pulse),
        .fall_pulse ()
    );

    button_conditioner fault_conditioner (
        .clk        (CLK100MHZ),
        .rst        (rst),
        .async_in   (SW_FAULT),
        .level_out  (fault_level),
        .rise_pulse (),
        .fall_pulse ()
    );

    reg running;
    reg measurement_active;
    reg snapshot_request;

    always @(posedge CLK100MHZ) begin
        if (rst) begin
            running            <= 1'b0;
            measurement_active <= 1'b0;
            snapshot_request   <= 1'b0;
        end
        else begin
            snapshot_request <= 1'b0;

            if (stop_pulse) begin
                running <= 1'b0;
            end
            else if (start_pulse) begin
                running <= 1'b1;
                measurement_active <= 1'b1;
            end

            // Keep the measurement window open while the FIFO drains after
            // stop. Snapshot only after the final queued word is accepted.
            if (measurement_active && !running && fifo_empty) begin
                measurement_active <= 1'b0;
                snapshot_request   <= 1'b1;
            end
        end
    end

    wire                  generator_valid;
    wire                  generator_ready;
    wire [DATA_WIDTH-1:0] generator_data;

    stream_counter_generator_controlled #(
        .DATA_WIDTH(DATA_WIDTH)
    ) generator (
        .clk       (CLK100MHZ),
        .rst       (rst),
        .enable    (running),
        .out_ready (generator_ready),
        .out_valid (generator_valid),
        .out_data  (generator_data)
    );

    wire                  injected_valid;
    wire                  injected_ready;
    wire [DATA_WIDTH-1:0] injected_data;
    wire                  fault_applied;

    fault_injector #(
        .DATA_WIDTH(DATA_WIDTH)
    ) injector (
        .clk          (CLK100MHZ),
        .rst          (rst),
        .fault_enable (fault_level),
        .fault_mask   ({{(DATA_WIDTH-1){1'b0}}, 1'b1}),
        .in_valid     (generator_valid),
        .in_ready     (generator_ready),
        .in_data      (generator_data),
        .out_valid    (injected_valid),
        .out_ready    (injected_ready),
        .out_data     (injected_data),
        .fault_applied(fault_applied)
    );

    wire                  fifo_in_ready;
    wire                  fifo_out_valid;
    wire                  fifo_out_ready;
    wire [DATA_WIDTH-1:0] fifo_out_data;
    wire                  fifo_full;
    wire                  fifo_empty;
    wire [ADDR_WIDTH:0]   fifo_occupancy;
    wire                  fifo_write_accept;
    wire                  fifo_read_accept;
    wire [63:0]           fifo_overflow_attempts;
    wire [63:0]           fifo_underflow_attempts;

    assign injected_ready = fifo_in_ready;

    stream_fifo #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) fifo (
        .clk               (CLK100MHZ),
        .rst               (rst),
        .in_valid          (injected_valid),
        .in_ready          (fifo_in_ready),
        .in_data           (injected_data),
        .out_valid         (fifo_out_valid),
        .out_ready         (fifo_out_ready),
        .out_data          (fifo_out_data),
        .full              (fifo_full),
        .empty             (fifo_empty),
        .occupancy         (fifo_occupancy),
        .write_accept      (fifo_write_accept),
        .read_accept       (fifo_read_accept),
        .overflow_attempts (fifo_overflow_attempts),
        .underflow_attempts (fifo_underflow_attempts)
    );

    wire                  checker_ready;
    wire [63:0]           checker_words;
    wire [63:0]           checker_errors;
    wire [DATA_WIDTH-1:0] checker_expected;
    wire                  checker_error_pulse;

    assign fifo_out_ready = checker_ready;

    stream_sequence_checker #(
        .DATA_WIDTH(DATA_WIDTH)
    ) checker (
        .clk            (CLK100MHZ),
        .rst            (rst),
        .in_valid       (fifo_out_valid),
        .in_data        (fifo_out_data),
        .in_ready       (checker_ready),
        .words_checked  (checker_words),
        .word_errors    (checker_errors),
        .expected_value (checker_expected),
        .error_pulse    (checker_error_pulse)
    );

    wire [63:0] elapsed_cycles;
    wire [63:0] accepted_writes;
    wire [63:0] accepted_reads;
    wire [63:0] words_checked;
    wire [63:0] word_errors;
    wire [63:0] bit_errors;
    wire [63:0] fifo_full_cycles;
    wire [63:0] fifo_empty_cycles;
    wire [63:0] producer_stall_cycles;
    wire [63:0] consumer_stall_cycles;
    wire [ADDR_WIDTH:0] fifo_high_water;

    performance_counters #(
        .DATA_WIDTH(DATA_WIDTH),
        .OCCUPANCY_WIDTH(ADDR_WIDTH+1)
    ) counters (
        .clk                  (CLK100MHZ),
        .rst                  (rst),
        .run_enable           (measurement_active),
        .write_accept         (fifo_write_accept),
        .read_accept          (fifo_read_accept),
        .check_accept         (fifo_out_valid && checker_ready),
        .word_error           (checker_error_pulse),
        .bit_error_count      (32'd0),
        .fifo_full            (fifo_full),
        .fifo_empty           (fifo_empty),
        .producer_stall       (generator_valid && !generator_ready),
        .consumer_stall       (fifo_out_valid && !fifo_out_ready),
        .fifo_occupancy       (fifo_occupancy),
        .elapsed_cycles       (elapsed_cycles),
        .accepted_writes      (accepted_writes),
        .accepted_reads       (accepted_reads),
        .words_checked        (words_checked),
        .word_errors          (word_errors),
        .bit_errors           (bit_errors),
        .fifo_full_cycles     (fifo_full_cycles),
        .fifo_empty_cycles    (fifo_empty_cycles),
        .producer_stall_cycles(producer_stall_cycles),
        .consumer_stall_cycles(consumer_stall_cycles),
        .fifo_high_water      (fifo_high_water)
    );

    wire       uart_start;
    wire [7:0] uart_data;
    wire       uart_busy;
    wire       telemetry_busy;

    telemetry_controller telemetry (
        .clk              (CLK100MHZ),
        .rst              (rst),
        .snapshot_request (snapshot_request),
        .run_active       (running),
        .words_checked    (words_checked),
        .word_errors      (word_errors),
        .elapsed_cycles   (elapsed_cycles),
        .bit_errors       (bit_errors),
        .fifo_high_water  (fifo_high_water),
        .fifo_full_cycles (fifo_full_cycles),
        .fifo_empty_cycles(fifo_empty_cycles),
        .accepted_writes  (accepted_writes),
        .accepted_reads   (accepted_reads),
        .producer_stall_cycles(producer_stall_cycles),
        .consumer_stall_cycles(consumer_stall_cycles),
        .overflow_attempts(fifo_overflow_attempts),
        .underflow_attempts(fifo_underflow_attempts),
        .uart_busy        (uart_busy),
        .uart_start       (uart_start),
        .uart_data        (uart_data),
        .busy             (telemetry_busy)
    );

    uart_tx #(
        .CLOCK_HZ  (100000000),
        .BAUD_RATE (115200)
    ) uart (
        .clk   (CLK100MHZ),
        .rst   (rst),
        .start (uart_start),
        .data  (uart_data),
        .tx    (UART_TX),
        .busy  (uart_busy)
    );

    assign LED[0] = running;
    assign LED[1] = (word_errors != 0);
    assign LED[2] = fifo_full;
    assign LED[3] = (!measurement_active && (words_checked != 0));

endmodule
