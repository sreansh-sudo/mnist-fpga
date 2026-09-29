`timescale 1ns/1ps

module fc1_mac4_pipe (
    input wire clk,
    input wire rst,

    input wire enable,
    input wire load_bias,

    input wire [7:0] input_value,

    input wire signed [7:0] weight0,
    input wire signed [7:0] weight1,
    input wire signed [7:0] weight2,
    input wire signed [7:0] weight3,

    input wire signed [25:0] bias0,
    input wire signed [25:0] bias1,
    input wire signed [25:0] bias2,
    input wire signed [25:0] bias3,

    output wire signed [25:0] accumulator0,
    output wire signed [25:0] accumulator1,
    output wire signed [25:0] accumulator2,
    output wire signed [25:0] accumulator3
);

    // --------------------------------------------------------
    // One-cycle pipeline for the MAC operands/control.
    //
    // Weight and input are delayed together so that the
    // synchronous weight BRAM remains aligned with the
    // combinational input memory.
    // --------------------------------------------------------

    reg [7:0] input_value_r;

    reg signed [7:0] weight0_r;
    reg signed [7:0] weight1_r;
    reg signed [7:0] weight2_r;
    reg signed [7:0] weight3_r;

    reg enable_r;

    always @(posedge clk) begin
        if (rst) begin
            input_value_r <= 8'd0;

            weight0_r <= 8'sd0;
            weight1_r <= 8'sd0;
            weight2_r <= 8'sd0;
            weight3_r <= 8'sd0;

            enable_r <= 1'b0;
        end
        else begin
            input_value_r <= input_value;

            weight0_r <= weight0;
            weight1_r <= weight1;
            weight2_r <= weight2;
            weight3_r <= weight3;

            enable_r <= enable;
        end
    end

    // --------------------------------------------------------
    // Bias loading remains direct.
    //
    // The controller loads the bias before MAC begins, so
    // delaying load_bias would incorrectly shift initialization.
    // --------------------------------------------------------

    fc1_mac_lane lane0 (
        .clk(clk),
        .rst(rst),
        .enable(enable_r),
        .load_bias(load_bias),
        .input_value(input_value_r),
        .weight_value(weight0_r),
        .bias_value(bias0),
        .accumulator(accumulator0)
    );

    fc1_mac_lane lane1 (
        .clk(clk),
        .rst(rst),
        .enable(enable_r),
        .load_bias(load_bias),
        .input_value(input_value_r),
        .weight_value(weight1_r),
        .bias_value(bias1),
        .accumulator(accumulator1)
    );

    fc1_mac_lane lane2 (
        .clk(clk),
        .rst(rst),
        .enable(enable_r),
        .load_bias(load_bias),
        .input_value(input_value_r),
        .weight_value(weight2_r),
        .bias_value(bias2),
        .accumulator(accumulator2)
    );

    fc1_mac_lane lane3 (
        .clk(clk),
        .rst(rst),
        .enable(enable_r),
        .load_bias(load_bias),
        .input_value(input_value_r),
        .weight_value(weight3_r),
        .bias_value(bias3),
        .accumulator(accumulator3)
    );

endmodule
