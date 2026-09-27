`timescale 1ns/1ps

module fc2_bias_mem (
    output wire signed [20:0] bias0,
    output wire signed [20:0] bias1,
    output wire signed [20:0] bias2,
    output wire signed [20:0] bias3,
    output wire signed [20:0] bias4,
    output wire signed [20:0] bias5,
    output wire signed [20:0] bias6,
    output wire signed [20:0] bias7,
    output wire signed [20:0] bias8,
    output wire signed [20:0] bias9
);

    reg signed [20:0] memory [0:9];

    initial begin
        $readmemh("data/fc2_bias.mem", memory);
    end

    assign bias0 = memory[0];
    assign bias1 = memory[1];
    assign bias2 = memory[2];
    assign bias3 = memory[3];
    assign bias4 = memory[4];
    assign bias5 = memory[5];
    assign bias6 = memory[6];
    assign bias7 = memory[7];
    assign bias8 = memory[8];
    assign bias9 = memory[9];

endmodule
