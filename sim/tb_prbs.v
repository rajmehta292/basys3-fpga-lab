`timescale 1ns/1ps

module tb_prbs;

    localparam DATA_WIDTH = 128;

    reg clk;
    reg rst;
    wire gen_valid;
    wire gen_ready;
    wire [DATA_WIDTH-1:0] gen_data;
    wire [63:0] words_checked;
    wire [63:0] word_errors;
    wire [63:0] bit_errors;
    wire error_pulse;
    wire [31:0] bit_error_pulse_count;
    integer failures;
    integer i;
    reg inject_error;

    assign gen_ready = 1'b1;

    prbs_generator #(
        .DATA_WIDTH(DATA_WIDTH),
        .SEED(31'h7fffffff)
    ) generator (
        .clk       (clk),
        .rst       (rst),
        .out_ready (gen_ready),
        .out_valid (gen_valid),
        .out_data  (gen_data)
    );

    prbs_checker #(
        .DATA_WIDTH(DATA_WIDTH),
        .SEED(31'h7fffffff)
    ) checker (
        .clk                  (clk),
        .rst                  (rst),
        .in_valid             (gen_valid),
        .in_data              (gen_data ^ (inject_error ? 128'h1 : 128'd0)),
        .in_ready             (),
        .words_checked        (words_checked),
        .word_errors          (word_errors),
        .bit_errors           (bit_errors),
        .error_pulse          (error_pulse),
        .bit_error_pulse_count(bit_error_pulse_count)
    );

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    initial begin
        failures = 0;
        inject_error = 1'b0;
        rst = 1'b1;
        repeat (3) @(posedge clk);
        @(negedge clk);
        rst = 1'b0;

        // Thirty-two clean words.
        repeat (33) @(posedge clk);
        @(negedge clk);
        if (word_errors !== 0)
            begin failures = failures + 1; $display("PRBS FAIL: clean words produced errors"); end
        if (words_checked !== 32)
            begin failures = failures + 1; $display("PRBS FAIL: wrong clean word count"); end

        // One-bit corruption on the next accepted word.
        inject_error = 1'b1;
        @(posedge clk);
        @(negedge clk);
        inject_error = 1'b0;
        if (word_errors !== 1)
            begin failures = failures + 1; $display("PRBS FAIL: one corrupted word was not counted"); end
        if (bit_errors !== 1)
            begin failures = failures + 1; $display("PRBS FAIL: one-bit corruption was not counted as one bit"); end
        if (bit_error_pulse_count !== 1)
            begin failures = failures + 1; $display("PRBS FAIL: bit error pulse count was not one"); end

        if (failures == 0)
            $display("PRBS PASS: parallel PRBS-31 sequence and one-bit fault detection passed");
        else
            $display("PRBS FAIL: %0d checks failed", failures);
        $finish;
    end

endmodule
