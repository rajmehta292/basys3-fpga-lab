`timescale 1ns/1ps

// Sends a coherent hexadecimal status line through uart_tx.
// Format:
//   STAT W=<16 hex> E=<16 hex> C=<16 hex> B=<16 hex> H=<4 hex>
//        F=<16 hex> M=<16 hex> R=<1 hex> I=<16 hex> O=<16 hex>
//        P=<16 hex> Q=<16 hex> X=<16 hex> Y=<16 hex>\r\n
// W words checked, E word errors, C elapsed cycles, B bit errors,
// H FIFO high-water mark, F full cycles, M empty cycles, R running,
// I accepted writes, O accepted reads, P producer stalls, Q consumer stalls,
// X overflow attempts, Y underflow attempts.

module telemetry_controller (
    input  wire       clk,
    input  wire       rst,
    input  wire       snapshot_request,
    input  wire       run_active,
    input  wire [63:0] words_checked,
    input  wire [63:0] word_errors,
    input  wire [63:0] elapsed_cycles,
    input  wire [63:0] bit_errors,
    input  wire [8:0]  fifo_high_water,
    input  wire [63:0] fifo_full_cycles,
    input  wire [63:0] fifo_empty_cycles,
    input  wire [63:0] accepted_writes,
    input  wire [63:0] accepted_reads,
    input  wire [63:0] producer_stall_cycles,
    input  wire [63:0] consumer_stall_cycles,
    input  wire [63:0] overflow_attempts,
    input  wire [63:0] underflow_attempts,
    input  wire        uart_busy,
    output reg         uart_start,
    output reg  [7:0]  uart_data,
    output reg         busy
);

    localparam integer MESSAGE_LENGTH = 245;

    reg [63:0] snap_words;
    reg [63:0] snap_errors;
    reg [63:0] snap_cycles;
    reg [63:0] snap_bits;
    reg [8:0]  snap_high_water;
    reg [63:0] snap_full_cycles;
    reg [63:0] snap_empty_cycles;
    reg [63:0] snap_accepted_writes;
    reg [63:0] snap_accepted_reads;
    reg [63:0] snap_producer_stalls;
    reg [63:0] snap_consumer_stalls;
    reg [63:0] snap_overflow_attempts;
    reg [63:0] snap_underflow_attempts;
    reg        snap_running;
    reg [7:0]  character_index;

    function [7:0] hex_ascii;
        input [3:0] nibble;
        begin
            if (nibble < 10)
                hex_ascii = "0" + nibble;
            else
                hex_ascii = "A" + (nibble - 10);
        end
    endfunction

    function [7:0] fixed_character;
        input integer index;
        begin
            fixed_character = 8'h20;
            case (index)
                0: fixed_character = "S";
                1: fixed_character = "T";
                2: fixed_character = "A";
                3: fixed_character = "T";
                4: fixed_character = " ";
                5: fixed_character = "W";
                6: fixed_character = "=";
                23: fixed_character = " ";
                24: fixed_character = "E";
                25: fixed_character = "=";
                42: fixed_character = " ";
                43: fixed_character = "C";
                44: fixed_character = "=";
                61: fixed_character = " ";
                62: fixed_character = "B";
                63: fixed_character = "=";
                80: fixed_character = " ";
                81: fixed_character = "H";
                82: fixed_character = "=";
                87: fixed_character = " ";
                88: fixed_character = "F";
                89: fixed_character = "=";
                106: fixed_character = " ";
                107: fixed_character = "M";
                108: fixed_character = "=";
                125: fixed_character = " ";
                126: fixed_character = "R";
                127: fixed_character = "=";
                129: fixed_character = " ";
                130: fixed_character = "I";
                131: fixed_character = "=";
                148: fixed_character = " ";
                149: fixed_character = "O";
                150: fixed_character = "=";
                167: fixed_character = " ";
                168: fixed_character = "P";
                169: fixed_character = "=";
                186: fixed_character = " ";
                187: fixed_character = "Q";
                188: fixed_character = "=";
                205: fixed_character = " ";
                206: fixed_character = "X";
                207: fixed_character = "=";
                224: fixed_character = " ";
                225: fixed_character = "Y";
                226: fixed_character = "=";
                243: fixed_character = 8'h0d;
                244: fixed_character = 8'h0a;
                default: fixed_character = 8'h20;
            endcase
        end
    endfunction

    function [7:0] message_character;
        input integer index;
        reg [63:0] value;
        integer digit;
        begin
            value = 64'd0;
            digit = 0;
            message_character = 8'h20;

            if (index <= 6 || (index >= 23 && index <= 25) ||
                (index >= 42 && index <= 44) || (index >= 61 && index <= 63) ||
                (index >= 80 && index <= 82) || (index >= 87 && index <= 89) ||
                (index >= 106 && index <= 108) || (index >= 125 && index <= 127) ||
                (index >= 129 && index <= 131) || (index >= 148 && index <= 150) ||
                (index >= 167 && index <= 169) || (index >= 186 && index <= 188) ||
                (index >= 205 && index <= 207) || (index >= 224 && index <= 226) ||
                index >= 243) begin
                message_character = fixed_character(index);
            end
            else if (index >= 7 && index <= 22) begin
                value = snap_words;
                digit = index - 7;
                message_character = hex_ascii((value >> ((15 - digit) * 4)) & 4'hf);
            end
            else if (index >= 26 && index <= 41) begin
                value = snap_errors;
                digit = index - 26;
                message_character = hex_ascii((value >> ((15 - digit) * 4)) & 4'hf);
            end
            else if (index >= 45 && index <= 60) begin
                value = snap_cycles;
                digit = index - 45;
                message_character = hex_ascii((value >> ((15 - digit) * 4)) & 4'hf);
            end
            else if (index >= 64 && index <= 79) begin
                value = snap_bits;
                digit = index - 64;
                message_character = hex_ascii((value >> ((15 - digit) * 4)) & 4'hf);
            end
            else if (index >= 83 && index <= 86) begin
                value = snap_high_water;
                digit = index - 83 + 12;
                message_character = hex_ascii((value >> ((15 - digit) * 4)) & 4'hf);
            end
            else if (index >= 90 && index <= 105) begin
                value = snap_full_cycles;
                digit = index - 90;
                message_character = hex_ascii((value >> ((15 - digit) * 4)) & 4'hf);
            end
            else if (index >= 109 && index <= 124) begin
                value = snap_empty_cycles;
                digit = index - 109;
                message_character = hex_ascii((value >> ((15 - digit) * 4)) & 4'hf);
            end
            else if (index == 128) begin
                message_character = snap_running ? "1" : "0";
            end
            else if (index >= 132 && index <= 147) begin
                value = snap_accepted_writes;
                digit = index - 132;
                message_character = hex_ascii((value >> ((15 - digit) * 4)) & 4'hf);
            end
            else if (index >= 151 && index <= 166) begin
                value = snap_accepted_reads;
                digit = index - 151;
                message_character = hex_ascii((value >> ((15 - digit) * 4)) & 4'hf);
            end
            else if (index >= 170 && index <= 185) begin
                value = snap_producer_stalls;
                digit = index - 170;
                message_character = hex_ascii((value >> ((15 - digit) * 4)) & 4'hf);
            end
            else if (index >= 189 && index <= 204) begin
                value = snap_consumer_stalls;
                digit = index - 189;
                message_character = hex_ascii((value >> ((15 - digit) * 4)) & 4'hf);
            end
            else if (index >= 208 && index <= 223) begin
                value = snap_overflow_attempts;
                digit = index - 208;
                message_character = hex_ascii((value >> ((15 - digit) * 4)) & 4'hf);
            end
            else if (index >= 227 && index <= 242) begin
                value = snap_underflow_attempts;
                digit = index - 227;
                message_character = hex_ascii((value >> ((15 - digit) * 4)) & 4'hf);
            end
        end
    endfunction

    always @(posedge clk) begin
        if (rst) begin
            snap_words       <= 64'd0;
            snap_errors      <= 64'd0;
            snap_cycles      <= 64'd0;
            snap_bits        <= 64'd0;
            snap_high_water  <= 9'd0;
            snap_full_cycles <= 64'd0;
            snap_empty_cycles <= 64'd0;
            snap_accepted_writes <= 64'd0;
            snap_accepted_reads <= 64'd0;
            snap_producer_stalls <= 64'd0;
            snap_consumer_stalls <= 64'd0;
            snap_overflow_attempts <= 64'd0;
            snap_underflow_attempts <= 64'd0;
            snap_running     <= 1'b0;
            character_index <= 8'd0;
            uart_start      <= 1'b0;
            uart_data       <= 8'd0;
            busy            <= 1'b0;
        end
        else begin
            uart_start <= 1'b0;

            if (snapshot_request && !busy) begin
                snap_words        <= words_checked;
                snap_errors       <= word_errors;
                snap_cycles       <= elapsed_cycles;
                snap_bits         <= bit_errors;
                snap_high_water   <= fifo_high_water;
                snap_full_cycles <= fifo_full_cycles;
                snap_empty_cycles <= fifo_empty_cycles;
                snap_accepted_writes <= accepted_writes;
                snap_accepted_reads <= accepted_reads;
                snap_producer_stalls <= producer_stall_cycles;
                snap_consumer_stalls <= consumer_stall_cycles;
                snap_overflow_attempts <= overflow_attempts;
                snap_underflow_attempts <= underflow_attempts;
                snap_running      <= run_active;
                character_index  <= 8'd0;
                busy             <= 1'b1;
            end
            else if (busy && !uart_busy) begin
                if (character_index < MESSAGE_LENGTH) begin
                    uart_data       <= message_character(character_index);
                    uart_start      <= 1'b1;
                    character_index <= character_index + 1'b1;
                end
                else begin
                    busy <= 1'b0;
                end
            end
        end
    end

endmodule
