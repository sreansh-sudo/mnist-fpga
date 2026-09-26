`timescale 1ns/1ps

module fc1_bias_mem (
    input  wire [1:0] group,

    output wire signed [25:0] bias0,
    output wire signed [25:0] bias1,
    output wire signed [25:0] bias2,
    output wire signed [25:0] bias3,
    output wire signed [25:0] bias4,
    output wire signed [25:0] bias5,
    output wire signed [25:0] bias6,
    output wire signed [25:0] bias7
);

    // --------------------------------------------------------
    // 32 quantized FC1 biases
    //
    // Bias scale = 8192
    // Storage format = signed 26-bit
    //
    // Group 0 -> neurons 0..7
    // Group 1 -> neurons 8..15
    // Group 2 -> neurons 16..23
    // Group 3 -> neurons 24..31
    // --------------------------------------------------------

    reg signed [25:0] memory [0:31];


    // --------------------------------------------------------
    // Load generated bias memory
    // --------------------------------------------------------

    initial begin
        $readmemh("data/fc1_bias.mem", memory);
    end


    // --------------------------------------------------------
    // Select the eight biases for the current group
    //
    // Base address:
    //   group 0 -> 0
    //   group 1 -> 8
    //   group 2 -> 16
    //   group 3 -> 24
    // --------------------------------------------------------

    assign bias0 = memory[(group * 8) + 0];
    assign bias1 = memory[(group * 8) + 1];
    assign bias2 = memory[(group * 8) + 2];
    assign bias3 = memory[(group * 8) + 3];
    assign bias4 = memory[(group * 8) + 4];
    assign bias5 = memory[(group * 8) + 5];
    assign bias6 = memory[(group * 8) + 6];
    assign bias7 = memory[(group * 8) + 7];

endmodule
