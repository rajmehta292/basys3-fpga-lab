`timescale 1ns/1ps

// Counter source with a safe run/stop control.
// If enable is removed while stalled, the current word remains valid and
// stable until it is accepted. If enable is removed on an accepting edge, the
// accepted word is consumed and the source becomes idle without repeating it.

module stream_counter_generator_controlled #(
    parameter DATA_WIDTH = 128
) (
    input  wire                  clk,
    input  wire                  rst,
    input  wire                  enable,
    input  wire                  out_ready,
    output reg                   out_valid,
    output reg  [DATA_WIDTH-1:0] out_data
);

    always @(posedge clk) begin
        if (rst) begin
            out_valid <= 1'b0;
            out_data  <= {DATA_WIDTH{1'b0}};
        end
        else if (!enable) begin
            if (out_valid && out_ready) begin
                out_data  <= out_data + 1'b1;
                out_valid <= 1'b0;
            end
            else if (!out_valid) begin
                out_valid <= 1'b0;
            end
            // When valid is high and ready is low, deliberately hold both.
        end
        else if (!out_valid) begin
            out_valid <= 1'b1;
        end
        else if (out_ready) begin
            out_data <= out_data + 1'b1;
        end
    end

endmodule
