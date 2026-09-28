`timescale 1ns/1ps

module fc2_mac10 (
    input  wire                  clk,
    input  wire                  rst,

    input  wire                  load_bias,
    input  wire                  mac_enable,

    input  wire [7:0]            activation,

    input  wire signed [7:0]     weight0,
    input  wire signed [7:0]     weight1,
    input  wire signed [7:0]     weight2,
    input  wire signed [7:0]     weight3,
    input  wire signed [7:0]     weight4,
    input  wire signed [7:0]     weight5,
    input  wire signed [7:0]     weight6,
    input  wire signed [7:0]     weight7,
    input  wire signed [7:0]     weight8,
    input  wire signed [7:0]     weight9,

    input  wire signed [20:0]    bias0,
    input  wire signed [20:0]    bias1,
    input  wire signed [20:0]    bias2,
    input  wire signed [20:0]    bias3,
    input  wire signed [20:0]    bias4,
    input  wire signed [20:0]    bias5,
    input  wire signed [20:0]    bias6,
    input  wire signed [20:0]    bias7,
    input  wire signed [20:0]    bias8,
    input  wire signed [20:0]    bias9,

    output wire signed [20:0]    accumulator0,
    output wire signed [20:0]    accumulator1,
    output wire signed [20:0]    accumulator2,
    output wire signed [20:0]    accumulator3,
    output wire signed [20:0]    accumulator4,
    output wire signed [20:0]    accumulator5,
    output wire signed [20:0]    accumulator6,
    output wire signed [20:0]    accumulator7,
    output wire signed [20:0]    accumulator8,
    output wire signed [20:0]    accumulator9
);

    // ------------------------------------------------------------
    // MAC Lane 0
    // ------------------------------------------------------------

    fc2_mac_lane lane0 (
        .clk(clk),
        .rst(rst),
        .load_bias(load_bias),
        .mac_enable(mac_enable),
        .activation(activation),
        .weight(weight0),
        .bias(bias0),
        .accumulator(accumulator0)
    );

    // ------------------------------------------------------------
    // MAC Lane 1
    // ------------------------------------------------------------

    fc2_mac_lane lane1 (
        .clk(clk),
        .rst(rst),
        .load_bias(load_bias),
        .mac_enable(mac_enable),
        .activation(activation),
        .weight(weight1),
        .bias(bias1),
        .accumulator(accumulator1)
    );

    // ------------------------------------------------------------
    // MAC Lane 2
    // ------------------------------------------------------------

    fc2_mac_lane lane2 (
        .clk(clk),
        .rst(rst),
        .load_bias(load_bias),
        .mac_enable(mac_enable),
        .activation(activation),
        .weight(weight2),
        .bias(bias2),
        .accumulator(accumulator2)
    );

    // ------------------------------------------------------------
    // MAC Lane 3
    // ------------------------------------------------------------

    fc2_mac_lane lane3 (
        .clk(clk),
        .rst(rst),
        .load_bias(load_bias),
        .mac_enable(mac_enable),
        .activation(activation),
        .weight(weight3),
        .bias(bias3),
        .accumulator(accumulator3)
    );

    // ------------------------------------------------------------
    // MAC Lane 4
    // ------------------------------------------------------------

    fc2_mac_lane lane4 (
        .clk(clk),
        .rst(rst),
        .load_bias(load_bias),
        .mac_enable(mac_enable),
        .activation(activation),
        .weight(weight4),
        .bias(bias4),
        .accumulator(accumulator4)
    );

    // ------------------------------------------------------------
    // MAC Lane 5
    // ------------------------------------------------------------

    fc2_mac_lane lane5 (
        .clk(clk),
        .rst(rst),
        .load_bias(load_bias),
        .mac_enable(mac_enable),
        .activation(activation),
        .weight(weight5),
        .bias(bias5),
        .accumulator(accumulator5)
    );

    // ------------------------------------------------------------
    // MAC Lane 6
    // ------------------------------------------------------------

    fc2_mac_lane lane6 (
        .clk(clk),
        .rst(rst),
        .load_bias(load_bias),
        .mac_enable(mac_enable),
        .activation(activation),
        .weight(weight6),
        .bias(bias6),
        .accumulator(accumulator6)
    );

    // ------------------------------------------------------------
    // MAC Lane 7
    // ------------------------------------------------------------

    fc2_mac_lane lane7 (
        .clk(clk),
        .rst(rst),
        .load_bias(load_bias),
        .mac_enable(mac_enable),
        .activation(activation),
        .weight(weight7),
        .bias(bias7),
        .accumulator(accumulator7)
    );

    // ------------------------------------------------------------
    // MAC Lane 8
    // ------------------------------------------------------------

    fc2_mac_lane lane8 (
        .clk(clk),
        .rst(rst),
        .load_bias(load_bias),
        .mac_enable(mac_enable),
        .activation(activation),
        .weight(weight8),
        .bias(bias8),
        .accumulator(accumulator8)
    );

    // ------------------------------------------------------------
    // MAC Lane 9
    // ------------------------------------------------------------

    fc2_mac_lane lane9 (
        .clk(clk),
        .rst(rst),
        .load_bias(load_bias),
        .mac_enable(mac_enable),
        .activation(activation),
        .weight(weight9),
        .bias(bias9),
        .accumulator(accumulator9)
    );

endmodule
