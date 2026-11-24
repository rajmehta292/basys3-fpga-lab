`timescale 1ns/1ps
`default_nettype none

// Reaction timer game using only Basys3 buttons, LEDs, and seven-segment
// display. Press UP to start a random wait. Press DOWN only after GO appears.
// The result is displayed as hexadecimal tenths of a second.
module reaction_timer #(
    parameter integer CLK_HZ = 100_000_000,
    parameter integer TICK_HZ = 10,
    parameter integer BUTTON_FILTER_CYCLES = 1_000_000
) (
    input  logic        clk,
    input  logic        btnC,
    input  logic        btnU,
    input  logic        btnD,
    input  logic [15:0] sw,
    output logic [15:0] led,
    output logic [6:0]  seg,
    output logic        dp,
    output logic [3:0]  an
);
    localparam integer TICK_DIV = CLK_HZ / TICK_HZ;

    logic rst;
    logic [26:0] tick_count;
    logic tenth_tick;
    logic up_press;
    logic down_press;
    logic [15:0] display_value;
    logic dp_enable;

    typedef enum logic [1:0] {IDLE, WAITING, GO, RESULT} state_t;
    state_t state;
    logic [7:0] delay_ticks;
    logic [15:0] reaction_ticks;
    logic early;
    logic [7:0] lfsr;

    basys3_reset_sync reset_i (.clk(clk), .btn_c(btnC), .rst(rst));
    button_onepulse #(.FILTER_CYCLES(BUTTON_FILTER_CYCLES)) up_i (
        .clk(clk), .rst(rst), .button(btnU), .press(up_press), .level()
    );
    button_onepulse #(.FILTER_CYCLES(BUTTON_FILTER_CYCLES)) down_i (
        .clk(clk), .rst(rst), .button(btnD), .press(down_press), .level()
    );

    assign tenth_tick = (tick_count == TICK_DIV-1);

    always_ff @(posedge clk) begin
        if (rst)
            tick_count <= '0;
        else if (tenth_tick)
            tick_count <= '0;
        else
            tick_count <= tick_count + 1'b1;
    end

    always_ff @(posedge clk) begin
        if (rst) begin
            state          <= IDLE;
            delay_ticks    <= '0;
            reaction_ticks <= '0;
            early          <= 1'b0;
            lfsr           <= 8'hA7;
        end else begin
            if (tenth_tick)
                lfsr <= {lfsr[6:0], lfsr[7] ^ lfsr[5] ^ lfsr[4] ^ lfsr[3]};

            if (up_press && (state == IDLE || state == RESULT)) begin
                state          <= WAITING;
                delay_ticks    <= 8'd10 + lfsr[4:0];
                reaction_ticks <= '0;
                early          <= 1'b0;
            end else if (down_press && state == WAITING) begin
                state <= RESULT;
                early <= 1'b1;
            end else if (down_press && state == GO) begin
                state <= RESULT;
            end else if (tenth_tick) begin
                case (state)
                    WAITING: begin
                        if (delay_ticks <= 1) begin
                            state          <= GO;
                            reaction_ticks <= '0;
                        end else begin
                            delay_ticks <= delay_ticks - 1'b1;
                        end
                    end
                    GO: begin
                        if (reaction_ticks != 16'hFFFF)
                            reaction_ticks <= reaction_ticks + 1'b1;
                    end
                    default: begin end
                endcase
            end
        end
    end

    always @* begin
        case (state)
            IDLE: begin
                led           = 16'h0001;
                display_value = 16'h0000;
            end
            WAITING: begin
                led           = 16'h00F0;
                display_value = 16'hCAFE;
            end
            GO: begin
                led           = 16'hFFFF;
                display_value = 16'h600D;
            end
            default: begin
                led           = early ? 16'hF000 : 16'h0F00;
                display_value = early ? 16'hE001 : reaction_ticks;
            end
        endcase
        led[15:8] = led[15:8] ^ sw[15:8];
        dp_enable = 1'b1;
    end

    basys3_display display_i (
        .clk(clk), .rst(rst), .value(display_value), .dp_enable(dp_enable),
        .seg(seg), .dp(dp), .an(an)
    );
endmodule

`default_nettype wire
