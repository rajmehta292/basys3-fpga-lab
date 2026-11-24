`timescale 1ns/1ps

// Milestone 1: deterministic counter-based streaming source.
//
// Interface contract:
//   A transfer occurs on a rising clock edge when out_valid && out_ready.
//   While out_valid is high and out_ready is low, both out_valid and out_data
//   remain unchanged.  This is the essential valid/ready backpressure rule.

module stream_counter_generator #(
    parameter DATA_WIDTH = 128
) (
    input  wire                  clk,
    input  wire                  rst,
    input  wire                  out_ready,
    output reg                   out_valid,
    output reg  [DATA_WIDTH-1:0] out_data
);

    always @(posedge clk) begin
        if (rst) begin
            out_valid <= 1'b0;
            out_data  <= {DATA_WIDTH{1'b0}};
        end
        else begin
            // Present the first word after reset.  It is zero and remains
            // zero until the receiver accepts it.
            if (!out_valid) begin
                out_valid <= 1'b1;
            end
            else if (out_ready) begin
                // The current word was accepted at this edge.  The next
                // word is therefore the current word plus one.
                out_data <= out_data + 1'b1;
            end
        end
    end

endmodule
