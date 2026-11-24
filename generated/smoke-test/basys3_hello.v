module basys3_hello(
    input  wire       clk,
    input  wire [15:0] sw,
    output wire [15:0] led
);
    reg [25:0] heartbeat;

    always @(posedge clk) begin
        heartbeat <= heartbeat + 1'b1;
    end

    // The slow heartbeat makes the physical cause/effect visible.
    assign led = sw ^ {16{heartbeat[25]}};
endmodule
