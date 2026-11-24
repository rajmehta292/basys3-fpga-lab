`timescale 1ns/1ps
`default_nettype none

// Basys 3 bring-up design.
//
// Expected behavior after programming:
//   * LED[15:0] mirrors SW[15:0].
//   * The four-digit display shows SW[15:0] as four hexadecimal digits.
//   * The decimal point blinks as a heartbeat.
//   * BTN_C synchronously clears the scanner/heartbeat counter.
//
// The seven-segment cathodes and digit anodes are active-low on Basys 3.
module basys3_demo (
    input  logic        clk,
    input  logic        btnC,
    input  logic [15:0] sw,
    output logic [15:0] led,
    output logic [6:0]  seg,
    output logic        dp,
    output logic [3:0]  an
);

    logic [26:0] tick;
    logic [1:0]  digit;
    logic [3:0]  nibble;

    always_ff @(posedge clk) begin
        if (btnC) begin
            tick <= '0;
        end else begin
            tick <= tick + 27'd1;
        end
    end

    // 100 MHz / 2^18 gives a comfortable display scan rate.
    always_comb begin
        digit = tick[19:18];
        case (digit)
            2'd0: begin
                an     = 4'b1110;
                nibble = sw[3:0];
            end
            2'd1: begin
                an     = 4'b1101;
                nibble = sw[7:4];
            end
            2'd2: begin
                an     = 4'b1011;
                nibble = sw[11:8];
            end
            default: begin
                an     = 4'b0111;
                nibble = sw[15:12];
            end
        endcase

        // CA..CG are active-low: {a,b,c,d,e,f,g}.
        case (nibble)
            4'h0: seg = 7'b1000000;
            4'h1: seg = 7'b1111001;
            4'h2: seg = 7'b0100100;
            4'h3: seg = 7'b0110000;
            4'h4: seg = 7'b0011001;
            4'h5: seg = 7'b0010010;
            4'h6: seg = 7'b0000010;
            4'h7: seg = 7'b1111000;
            4'h8: seg = 7'b0000000;
            4'h9: seg = 7'b0010000;
            4'hA: seg = 7'b0001000;
            4'hB: seg = 7'b0000011;
            4'hC: seg = 7'b1000110;
            4'hD: seg = 7'b0100001;
            4'hE: seg = 7'b0000110;
            default: seg = 7'b0001110;
        endcase
    end

    assign led = sw;
    assign dp  = ~tick[26];

endmodule

`default_nettype wire
