`timescale 1ns/1ps

module fc1_mac4 (
    input  wire clk,
    input  wire rst,

    input  wire enable,
    input  wire load_bias,

    // One input is broadcast to all 4 lanes.
    input  wire [7:0] input_value,

    // One weight for each lane.
    input  wire signed [7:0] weight0,
    input  wire signed [7:0] weight1,
    input  wire signed [7:0] weight2,
    input  wire signed [7:0] weight3,

    // One bias for each lane.
    input  wire signed [25:0] bias0,
    input  wire signed [25:0] bias1,
    input  wire signed [25:0] bias2,
    input  wire signed [25:0] bias3,

    // One accumulator per lane.
    output wire signed [25:0] accumulator0,
    output wire signed [25:0] accumulator1,
    output wire signed [25:0] accumulator2,
    output wire signed [25:0] accumulator3
);

    fc1_mac_lane lane0 (
        .clk(clk),
        .rst(rst),
        .enable(enable),
        .load_bias(load_bias),
        .input_value(input_value),
        .weight_value(weight0),
        .bias_value(bias0),
        .accumulator(accumulator0)
    );

    fc1_mac_lane lane1 (
        .clk(clk),
        .rst(rst),
        .enable(enable),
        .load_bias(load_bias),
        .input_value(input_value),
        .weight_value(weight1),
        .bias_value(bias1),
        .accumulator(accumulator1)
    );

    fc1_mac_lane lane2 (
        .clk(clk),
        .rst(rst),
        .enable(enable),
        .load_bias(load_bias),
        .input_value(input_value),
        .weight_value(weight2),
        .bias_value(bias2),
        .accumulator(accumulator2)
    );

    fc1_mac_lane lane3 (
        .clk(clk),
        .rst(rst),
        .enable(enable),
        .load_bias(load_bias),
        .input_value(input_value),
        .weight_value(weight3),
        .bias_value(bias3),
        .accumulator(accumulator3)
    );

endmodule
