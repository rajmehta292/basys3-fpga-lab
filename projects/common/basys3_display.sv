`timescale 1ns/1ps
`default_nettype none

// Four-digit active-low Basys3 hexadecimal display driver.
module basys3_display #(
    parameter integer SCAN_BITS = 18
) (
    input  logic        clk,
    input  logic        rst,
    input  logic [15:0] value,
    input  logic        dp_enable,
    output logic [6:0]  seg,
    output logic        dp,
    output logic [3:0]  an
);
    logic [SCAN_BITS-1:0] scan;
    logic [1:0] digit;
    logic [3:0] nibble;

    always_ff @(posedge clk) begin
        if (rst)
            scan <= '0;
        else
            scan <= scan + 1'b1;
    end

    always @* begin
        digit = scan[SCAN_BITS-1 -: 2];
        case (digit)
            2'd0: begin an = 4'b1110; nibble = value[3:0];   end
            2'd1: begin an = 4'b1101; nibble = value[7:4];   end
            2'd2: begin an = 4'b1011; nibble = value[11:8];  end
            default: begin an = 4'b0111; nibble = value[15:12]; end
        endcase

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

        dp = dp_enable ? ~scan[SCAN_BITS-2] : 1'b1;
    end
endmodule

`default_nettype wire
