`timescale 1ns/1ps

// Asynchronous assertion, synchronous deassertion reset conditioner.
// A raw pushbutton is allowed to assert reset immediately, but reset is
// released only after two clocked synchronizer stages.

module reset_sync (
    input  wire clk,
    input  wire async_reset,
    output wire sync_reset
);

    reg [1:0] reset_pipe;

    always @(posedge clk or posedge async_reset) begin
        if (async_reset)
            reset_pipe <= 2'b11;
        else
            reset_pipe <= {reset_pipe[0], 1'b0};
    end

    assign sync_reset = reset_pipe[1];

endmodule
