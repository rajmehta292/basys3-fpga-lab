`timescale 1ns/1ps
`default_nettype none

// Converts the mechanical center button into a synchronous reset level.
// The two flip-flops reduce the probability that metastability reaches the
// rest of the design. This is a synchronous reset: downstream logic observes
// rst only on a rising clock edge.
module basys3_reset_sync (
    input  logic clk,
    input  logic btn_c,
    output logic rst
);
    logic meta;

    always_ff @(posedge clk) begin
        meta <= btn_c;
        rst  <= meta;
    end
endmodule

`default_nettype wire
