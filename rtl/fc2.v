`timescale 1ns/1ps

module fc2 (
    input wire clk,
    input wire rst,
    input wire start,

    // Connection to FC1 activation memory
    output wire [4:0] activation_addr,
    input wire [7:0] activation_data,

    // FC2 result
    output wire [3:0] predicted_digit,
    output wire done,

    // Final FC2 logits
    output wire signed [20:0] logit0,
    output wire signed [20:0] logit1,
    output wire signed [20:0] logit2,
    output wire signed [20:0] logit3,
    output wire signed [20:0] logit4,
    output wire signed [20:0] logit5,
    output wire signed [20:0] logit6,
    output wire signed [20:0] logit7,
    output wire signed [20:0] logit8,
    output wire signed [20:0] logit9
);

    // ------------------------------------------------------------
    // Controller
    // ------------------------------------------------------------

    wire load_bias;
    wire mac_enable;

    fc2_controller controller (
        .clk(clk),
        .rst(rst),
        .start(start),
        .load_bias(load_bias),
        .mac_enable(mac_enable),
        .input_addr(activation_addr),
        .done(done)
    );

    // ------------------------------------------------------------
    // FC2 weight memory
    // ------------------------------------------------------------

    wire signed [7:0] weight0;
    wire signed [7:0] weight1;
    wire signed [7:0] weight2;
    wire signed [7:0] weight3;
    wire signed [7:0] weight4;
    wire signed [7:0] weight5;
    wire signed [7:0] weight6;
    wire signed [7:0] weight7;
    wire signed [7:0] weight8;
    wire signed [7:0] weight9;

    fc2_weight_mem weight_memory (
        .addr(activation_addr),
        .weight0(weight0),
        .weight1(weight1),
        .weight2(weight2),
        .weight3(weight3),
        .weight4(weight4),
        .weight5(weight5),
        .weight6(weight6),
        .weight7(weight7),
        .weight8(weight8),
        .weight9(weight9)
    );

    // ------------------------------------------------------------
    // FC2 bias memory
    // ------------------------------------------------------------

    wire signed [20:0] bias0;
    wire signed [20:0] bias1;
    wire signed [20:0] bias2;
    wire signed [20:0] bias3;
    wire signed [20:0] bias4;
    wire signed [20:0] bias5;
    wire signed [20:0] bias6;
    wire signed [20:0] bias7;
    wire signed [20:0] bias8;
    wire signed [20:0] bias9;

    fc2_bias_mem bias_memory (
        .bias0(bias0),
        .bias1(bias1),
        .bias2(bias2),
        .bias3(bias3),
        .bias4(bias4),
        .bias5(bias5),
        .bias6(bias6),
        .bias7(bias7),
        .bias8(bias8),
        .bias9(bias9)
    );

    // ------------------------------------------------------------
    // Convert individual signals to arrays for fc2_mac10
    // ------------------------------------------------------------

    wire signed [7:0] mac_weights [0:9];
    wire signed [20:0] mac_biases [0:9];
    wire signed [20:0] mac_accumulators [0:9];

    assign mac_weights[0] = weight0;
    assign mac_weights[1] = weight1;
    assign mac_weights[2] = weight2;
    assign mac_weights[3] = weight3;
    assign mac_weights[4] = weight4;
    assign mac_weights[5] = weight5;
    assign mac_weights[6] = weight6;
    assign mac_weights[7] = weight7;
    assign mac_weights[8] = weight8;
    assign mac_weights[9] = weight9;

    assign mac_biases[0] = bias0;
    assign mac_biases[1] = bias1;
    assign mac_biases[2] = bias2;
    assign mac_biases[3] = bias3;
    assign mac_biases[4] = bias4;
    assign mac_biases[5] = bias5;
    assign mac_biases[6] = bias6;
    assign mac_biases[7] = bias7;
    assign mac_biases[8] = bias8;
    assign mac_biases[9] = bias9;

    // ------------------------------------------------------------
    // 10 parallel MAC lanes
    // ------------------------------------------------------------

    fc2_mac10 mac_units (
        .clk(clk),
        .rst(rst),
        .load_bias(load_bias),
        .mac_enable(mac_enable),
        .activation(activation_data),
        .weight(mac_weights),
        .bias(mac_biases),
        .accumulator(mac_accumulators)
    );

    // ------------------------------------------------------------
    // Final logits
    // ------------------------------------------------------------

    assign logit0 = mac_accumulators[0];
    assign logit1 = mac_accumulators[1];
    assign logit2 = mac_accumulators[2];
    assign logit3 = mac_accumulators[3];
    assign logit4 = mac_accumulators[4];
    assign logit5 = mac_accumulators[5];
    assign logit6 = mac_accumulators[6];
    assign logit7 = mac_accumulators[7];
    assign logit8 = mac_accumulators[8];
    assign logit9 = mac_accumulators[9];

    // ------------------------------------------------------------
    // Argmax
    // ------------------------------------------------------------

    argmax10 argmax (
        .logit0(logit0),
        .logit1(logit1),
        .logit2(logit2),
        .logit3(logit3),
        .logit4(logit4),
        .logit5(logit5),
        .logit6(logit6),
        .logit7(logit7),
        .logit8(logit8),
        .logit9(logit9),
        .predicted_digit(predicted_digit)
    );

endmodule
