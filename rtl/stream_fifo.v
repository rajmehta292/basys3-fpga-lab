`timescale 1ns/1ps

// Single-clock streaming FIFO with a registered output.
//
// DATA_WIDTH=128 and ADDR_WIDTH=8 produce a 256-word, 32,768-bit FIFO.
// The memory read is clocked, so the first word may take one cycle to appear
// at out_valid. Once primed, the FIFO can accept and emit one word per cycle.
// The output register is counted as occupied storage; this makes full/empty
// behavior and simultaneous read/write behavior explicit.

module stream_fifo #(
    parameter DATA_WIDTH = 128,
    parameter ADDR_WIDTH = 8
) (
    input  wire                    clk,
    input  wire                    rst,
    input  wire                    in_valid,
    output wire                    in_ready,
    input  wire [DATA_WIDTH-1:0]    in_data,
    output reg                     out_valid,
    input  wire                    out_ready,
    output reg  [DATA_WIDTH-1:0]    out_data,
    output wire                    full,
    output wire                    empty,
    output wire [ADDR_WIDTH:0]      occupancy,
    output wire                    write_accept,
    output wire                    read_accept,
    output reg  [63:0]              overflow_attempts,
    output reg  [63:0]              underflow_attempts
);

    localparam FIFO_DEPTH = (1 << ADDR_WIDTH);

    reg [DATA_WIDTH-1:0] memory [0:FIFO_DEPTH-1];
    reg [ADDR_WIDTH-1:0] write_pointer;
    reg [ADDR_WIDTH-1:0] read_pointer;
    reg [ADDR_WIDTH:0]   memory_count;

    wire [ADDR_WIDTH:0] occupancy_int;
    wire full_int;
    wire empty_int;
    wire load_memory_to_output;
    wire bypass_write_to_output;
    wire memory_write;

    assign occupancy_int = memory_count + out_valid;
    assign full_int      = (occupancy_int >= FIFO_DEPTH);
    assign empty_int     = (occupancy_int == 0);

    // A full FIFO can still accept a word if its current output is consumed
    // on the same edge.
    assign in_ready     = !full_int || (out_valid && out_ready);
    assign write_accept = in_valid && in_ready;
    assign read_accept  = out_valid && out_ready;

    // Load the registered output whenever it is empty and memory has data, or
    // replace a consumed output from memory on the same edge.
    assign load_memory_to_output = (!out_valid && (memory_count != 0)) ||
                                   (out_valid && out_ready && (memory_count != 0));

    // If the output is consumed and the memory is empty, bypass a simultaneous
    // write directly into the output register to sustain one word per cycle.
    assign bypass_write_to_output = out_valid && out_ready &&
                                    (memory_count == 0) && write_accept;
    assign memory_write = write_accept && !bypass_write_to_output;

    assign full       = full_int;
    assign empty      = empty_int;
    assign occupancy  = occupancy_int;

    always @(posedge clk) begin
        if (rst) begin
            write_pointer     <= {ADDR_WIDTH{1'b0}};
            read_pointer      <= {ADDR_WIDTH{1'b0}};
            memory_count      <= {(ADDR_WIDTH+1){1'b0}};
            out_valid         <= 1'b0;
            out_data          <= {DATA_WIDTH{1'b0}};
            overflow_attempts <= 64'd0;
            underflow_attempts <= 64'd0;
        end
        else begin
            if (memory_write) begin
                memory[write_pointer] <= in_data;
                write_pointer <= write_pointer + 1'b1;
            end

            if (load_memory_to_output) begin
                out_data     <= memory[read_pointer];
                read_pointer <= read_pointer + 1'b1;
                out_valid    <= 1'b1;
            end
            else if (bypass_write_to_output) begin
                out_data  <= in_data;
                out_valid <= 1'b1;
            end
            else if (read_accept) begin
                out_valid <= 1'b0;
            end

            case ({memory_write, load_memory_to_output})
                2'b10: memory_count <= memory_count + 1'b1;
                2'b01: memory_count <= memory_count - 1'b1;
                default: memory_count <= memory_count;
            endcase

            if (in_valid && !in_ready)
                overflow_attempts <= overflow_attempts + 1'b1;
            if (out_ready && empty_int)
                underflow_attempts <= underflow_attempts + 1'b1;
        end
    end

endmodule
