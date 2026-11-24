`timescale 1ns/1ps

// 8-N-1 UART transmitter. One byte is accepted when start is pulsed while
// busy is low. UART is deliberately isolated from the high-speed datapath.

module uart_tx #(
    parameter CLOCK_HZ = 100000000,
    parameter BAUD_RATE = 115200
) (
    input  wire       clk,
    input  wire       rst,
    input  wire       start,
    input  wire [7:0] data,
    output reg        tx,
    output reg        busy
);

    localparam integer CLKS_PER_BIT = CLOCK_HZ / BAUD_RATE;

    reg [9:0]  shift_register;
    reg [31:0] baud_count;
    reg [3:0]  bit_index;

    always @(posedge clk) begin
        if (rst) begin
            tx              <= 1'b1;
            busy            <= 1'b0;
            shift_register  <= 10'b1111111111;
            baud_count      <= 32'd0;
            bit_index       <= 4'd0;
        end
        else if (!busy) begin
            if (start) begin
                // Bit 0 is the start bit, bits 1..8 are data LSB first,
                // and bit 9 is the stop bit.
                shift_register <= {1'b1, data, 1'b0};
                tx             <= 1'b0;
                busy           <= 1'b1;
                baud_count     <= 32'd0;
                bit_index      <= 4'd0;
            end
        end
        else if (baud_count >= CLKS_PER_BIT - 1) begin
            baud_count <= 32'd0;
            if (bit_index == 4'd9) begin
                tx   <= 1'b1;
                busy <= 1'b0;
            end
            else begin
                shift_register <= {1'b1, shift_register[9:1]};
                tx             <= shift_register[1];
                bit_index      <= bit_index + 1'b1;
            end
        end
        else begin
            baud_count <= baud_count + 1'b1;
        end
    end

endmodule
