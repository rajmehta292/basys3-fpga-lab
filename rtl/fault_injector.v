`timescale 1ns/1ps

// Pass-through stream stage that XORs a selected mask when fault_enable is
// high. The control should remain stable until the transfer completes so the
// output still obeys the valid/data stability rule while stalled.

module fault_injector #(
    parameter DATA_WIDTH = 128
) (
    input  wire                  clk,
    input  wire                  rst,
    input  wire                  fault_enable,
    input  wire [DATA_WIDTH-1:0] fault_mask,
    input  wire                  in_valid,
    output wire                  in_ready,
    input  wire [DATA_WIDTH-1:0] in_data,
    output wire                  out_valid,
    input  wire                  out_ready,
    output wire [DATA_WIDTH-1:0] out_data,
    output wire                  fault_applied
);

    // These ports are intentionally present so the stage can later gain a
    // registered one-shot control without changing the stream interface.
    wire unused_clk = clk;
    wire unused_rst = rst;

    assign in_ready      = out_ready;
    assign out_valid     = in_valid;
    assign out_data      = in_data ^ (fault_enable ? fault_mask : {DATA_WIDTH{1'b0}});
    assign fault_applied = in_valid && out_ready && fault_enable;

endmodule
