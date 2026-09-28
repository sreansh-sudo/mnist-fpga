`timescale 1ns/1ps

module fc1_bias_mem (
    input wire [1:0] group,

    output wire signed [25:0] bias0,
    output wire signed [25:0] bias1,
    output wire signed [25:0] bias2,
    output wire signed [25:0] bias3,
    output wire signed [25:0] bias4,
    output wire signed [25:0] bias5,
    output wire signed [25:0] bias6,
    output wire signed [25:0] bias7
);

    // 32 quantized FC1 biases
    //
    // Bias scale = 8192
    // Hardware datapath = signed 26-bit
    //
    // The .mem file contains 7 hexadecimal digits.
    // Use a 28-bit load buffer so Gowin's $readmemh
    // width matches the file, then expose only the
    // lower 26 bits to the FC1 datapath.

    reg [27:0] memory [0:31];

    initial begin
        $readmemh("data/fc1_bias.mem", memory);
    end

    assign bias0 = memory[(group * 8) + 0][25:0];
    assign bias1 = memory[(group * 8) + 1][25:0];
    assign bias2 = memory[(group * 8) + 2][25:0];
    assign bias3 = memory[(group * 8) + 3][25:0];
    assign bias4 = memory[(group * 8) + 4][25:0];
    assign bias5 = memory[(group * 8) + 5][25:0];
    assign bias6 = memory[(group * 8) + 6][25:0];
    assign bias7 = memory[(group * 8) + 7][25:0];

endmodule
