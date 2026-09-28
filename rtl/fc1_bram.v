`timescale 1ns/1ps

module fc1_bram (
    input wire clk,
    input wire rst,
    input wire start,

    // --------------------------------------------------------
    // Input loading interface
    // --------------------------------------------------------

    input wire        input_write_enable,
    input wire [9:0]  input_write_addr,
    input wire [7:0]  input_write_data,

    // --------------------------------------------------------
    // Status
    // --------------------------------------------------------

    output wire done,

    // --------------------------------------------------------
    // Activation read interface
    // --------------------------------------------------------

    input wire [4:0] activation_read_addr,
    output wire [7:0] activation_read_data,

    // --------------------------------------------------------
    // Synthesis observability
    // --------------------------------------------------------

    output wire [7:0] debug_activation0,
    output wire [7:0] debug_activation1,
    output wire [7:0] debug_activation2,
    output wire [7:0] debug_activation3,
    output wire [7:0] debug_activation4,
    output wire [7:0] debug_activation5,
    output wire [7:0] debug_activation6,
    output wire [7:0] debug_activation7
);

    // ========================================================
    // Controller signals
    // ========================================================

    wire [9:0]  input_addr;
    wire [11:0] weight_addr;
    wire [1:0]  bias_group;

    wire load_bias;
    wire mac_enable;

    wire requant_enable;
    wire store_enable;

    wire [2:0] store_index;

    wire [1:0] current_group;
    wire [9:0] current_input;


    // ========================================================
    // Input memory
    // ========================================================

    wire [7:0] input_value;

    fc1_input_mem input_memory (
        .clk(clk),
        .write_enable(input_write_enable),

        .write_addr(input_write_addr),
        .write_data(input_write_data),

        .read_addr(input_addr),
        .read_data(input_value)
    );


    // ========================================================
    // BRAM-based weight memory
    // ========================================================

    wire signed [7:0] weight0;
    wire signed [7:0] weight1;
    wire signed [7:0] weight2;
    wire signed [7:0] weight3;
    wire signed [7:0] weight4;
    wire signed [7:0] weight5;
    wire signed [7:0] weight6;
    wire signed [7:0] weight7;

    fc1_weight_mem_bram weight_memory (
        .clk(clk),
        .addr(weight_addr),

        .weight0(weight0),
        .weight1(weight1),
        .weight2(weight2),
        .weight3(weight3),
        .weight4(weight4),
        .weight5(weight5),
        .weight6(weight6),
        .weight7(weight7)
    );


    // ========================================================
    // Bias memory
    // ========================================================

    wire signed [25:0] bias0;
    wire signed [25:0] bias1;
    wire signed [25:0] bias2;
    wire signed [25:0] bias3;
    wire signed [25:0] bias4;
    wire signed [25:0] bias5;
    wire signed [25:0] bias6;
    wire signed [25:0] bias7;

    fc1_bias_mem bias_memory (
        .group(bias_group),

        .bias0(bias0),
        .bias1(bias1),
        .bias2(bias2),
        .bias3(bias3),
        .bias4(bias4),
        .bias5(bias5),
        .bias6(bias6),
        .bias7(bias7)
    );


    // ========================================================
    // MAC8
    // ========================================================

    wire signed [25:0] accumulator0;
    wire signed [25:0] accumulator1;
    wire signed [25:0] accumulator2;
    wire signed [25:0] accumulator3;
    wire signed [25:0] accumulator4;
    wire signed [25:0] accumulator5;
    wire signed [25:0] accumulator6;
    wire signed [25:0] accumulator7;

    fc1_mac8 mac8 (
        .clk(clk),
        .rst(rst),

        .enable(mac_enable),
        .load_bias(load_bias),

        .input_value(input_value),

        .weight0(weight0),
        .weight1(weight1),
        .weight2(weight2),
        .weight3(weight3),
        .weight4(weight4),
        .weight5(weight5),
        .weight6(weight6),
        .weight7(weight7),

        .bias0(bias0),
        .bias1(bias1),
        .bias2(bias2),
        .bias3(bias3),
        .bias4(bias4),
        .bias5(bias5),
        .bias6(bias6),
        .bias7(bias7),

        .accumulator0(accumulator0),
        .accumulator1(accumulator1),
        .accumulator2(accumulator2),
        .accumulator3(accumulator3),
        .accumulator4(accumulator4),
        .accumulator5(accumulator5),
        .accumulator6(accumulator6),
        .accumulator7(accumulator7)
    );


    // ========================================================
    // Requantization + ReLU
    // ========================================================

    wire [7:0] activation0;
    wire [7:0] activation1;
    wire [7:0] activation2;
    wire [7:0] activation3;
    wire [7:0] activation4;
    wire [7:0] activation5;
    wire [7:0] activation6;
    wire [7:0] activation7;


    // --------------------------------------------------------
    // Synthesis observability
    //
    // These are the actual FC1 post-ReLU activations.
    // No additional computation is introduced.
    // --------------------------------------------------------

    assign debug_activation0 = activation0;
    assign debug_activation1 = activation1;
    assign debug_activation2 = activation2;
    assign debug_activation3 = activation3;
    assign debug_activation4 = activation4;
    assign debug_activation5 = activation5;
    assign debug_activation6 = activation6;
    assign debug_activation7 = activation7;


    fc1_requant_relu requant0 (
        .accumulator(accumulator0),
        .activation(activation0)
    );

    fc1_requant_relu requant1 (
        .accumulator(accumulator1),
        .activation(activation1)
    );

    fc1_requant_relu requant2 (
        .accumulator(accumulator2),
        .activation(activation2)
    );

    fc1_requant_relu requant3 (
        .accumulator(accumulator3),
        .activation(activation3)
    );

    fc1_requant_relu requant4 (
        .accumulator(accumulator4),
        .activation(activation4)
    );

    fc1_requant_relu requant5 (
        .accumulator(accumulator5),
        .activation(activation5)
    );

    fc1_requant_relu requant6 (
        .accumulator(accumulator6),
        .activation(activation6)
    );

    fc1_requant_relu requant7 (
        .accumulator(accumulator7),
        .activation(activation7)
    );


    // ========================================================
    // Activation memory
    // ========================================================

    reg        activation_write_enable;
    reg [4:0]  activation_write_addr;
    reg [7:0]  activation_write_data;

    fc1_activation_mem activation_memory (
        .clk(clk),

        .write_enable(activation_write_enable),

        .write_addr(activation_write_addr),
        .write_data(activation_write_data),

        .read_addr(activation_read_addr),
        .read_data(activation_read_data)
    );


    // ========================================================
    // BRAM-aware controller
    // ========================================================

    fc1_controller_bram controller (
        .clk(clk),
        .rst(rst),
        .start(start),

        .input_addr(input_addr),
        .weight_addr(weight_addr),

        .bias_group(bias_group),

        .load_bias(load_bias),
        .mac_enable(mac_enable),

        .requant_enable(requant_enable),
        .store_enable(store_enable),
        .store_index(store_index),

        .done(done),

        .current_group(current_group),
        .current_input(current_input)
    );


    // ========================================================
    // Activation storage control
    // ========================================================

    always @(*) begin

        activation_write_enable = 1'b0;

        activation_write_addr = 5'd0;

        activation_write_data = 8'd0;


        if (store_enable) begin

            activation_write_enable = 1'b1;

            activation_write_addr =
                {current_group, 3'b000} +
                {2'b00, store_index};


            case (store_index)

                3'd0:
                    activation_write_data = activation0;

                3'd1:
                    activation_write_data = activation1;

                3'd2:
                    activation_write_data = activation2;

                3'd3:
                    activation_write_data = activation3;

                3'd4:
                    activation_write_data = activation4;

                3'd5:
                    activation_write_data = activation5;

                3'd6:
                    activation_write_data = activation6;

                3'd7:
                    activation_write_data = activation7;

                default:
                    activation_write_data = 8'd0;

            endcase

        end

    end

endmodule
