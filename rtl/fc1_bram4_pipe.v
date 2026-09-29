`timescale 1ns/1ps

module fc1_bram4_pipe (
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
    output wire [7:0] activation_read_data
);

    // ========================================================
    // Controller signals
    // ========================================================

    wire [9:0]  input_addr;
    wire [11:0] weight_addr;
    wire [1:0]  bias_group;
    wire        phase;

    wire load_bias;
    wire mac_enable;
    wire requant_enable_unused;

    wire store_enable;

    wire [1:0] store_index;

    wire [1:0] current_group;
    wire [9:0] current_input_unused;


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
    // Existing packed 64-bit weight BRAM
    //
    // Each word contains eight weights:
    //   weight0..weight3 = phase 0
    //   weight4..weight7 = phase 1
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
    // Existing bias memory
    //
    // Each group contains eight biases:
    //
    // phase 0 → bias0..bias3
    // phase 1 → bias4..bias7
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
    // Selected four weights
    // ========================================================

    wire signed [7:0] selected_weight0;
    wire signed [7:0] selected_weight1;
    wire signed [7:0] selected_weight2;
    wire signed [7:0] selected_weight3;

    assign selected_weight0 =
        phase ? weight4 : weight0;

    assign selected_weight1 =
        phase ? weight5 : weight1;

    assign selected_weight2 =
        phase ? weight6 : weight2;

    assign selected_weight3 =
        phase ? weight7 : weight3;


    // ========================================================
    // Selected four biases
    // ========================================================

    wire signed [25:0] selected_bias0;
    wire signed [25:0] selected_bias1;
    wire signed [25:0] selected_bias2;
    wire signed [25:0] selected_bias3;

    assign selected_bias0 =
        phase ? bias4 : bias0;

    assign selected_bias1 =
        phase ? bias5 : bias1;

    assign selected_bias2 =
        phase ? bias6 : bias2;

    assign selected_bias3 =
        phase ? bias7 : bias3;


    // ========================================================
    // Four-lane MAC
    // ========================================================

    wire signed [25:0] accumulator0;
    wire signed [25:0] accumulator1;
    wire signed [25:0] accumulator2;
    wire signed [25:0] accumulator3;

    fc1_mac4_pipe mac4 (
        .clk(clk),
        .rst(rst),

        .enable(mac_enable),
        .load_bias(load_bias),

        .input_value(input_value),

        .weight0(selected_weight0),
        .weight1(selected_weight1),
        .weight2(selected_weight2),
        .weight3(selected_weight3),

        .bias0(selected_bias0),
        .bias1(selected_bias1),
        .bias2(selected_bias2),
        .bias3(selected_bias3),

        .accumulator0(accumulator0),
        .accumulator1(accumulator1),
        .accumulator2(accumulator2),
        .accumulator3(accumulator3)
    );


    // ========================================================
    // Requantization + ReLU
    // ========================================================

    wire [7:0] activation0;
    wire [7:0] activation1;
    wire [7:0] activation2;
    wire [7:0] activation3;

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
    // Four-lane controller
    // ========================================================

    fc1_controller_bram4_pipe controller (
        .clk(clk),
        .rst(rst),
        .start(start),

        .input_addr(input_addr),
        .weight_addr(weight_addr),

        .bias_group(bias_group),
        .phase(phase),

        .load_bias(load_bias),
        .mac_enable(mac_enable),

        .requant_enable(requant_enable_unused),
        .store_enable(store_enable),
        .store_index(store_index),

        .done(done),

        .current_group(current_group),
        .current_input(current_input_unused)
    );


    // ========================================================
    // Activation storage control
    // ========================================================
    //
    // Each phase stores four consecutive neurons.
    //
    // group 0:
    //   phase 0 → addresses 0..3
    //   phase 1 → addresses 4..7
    //
    // group 1:
    //   phase 0 → addresses 8..11
    //   phase 1 → addresses 12..15
    //
    // etc.
    // ========================================================

    always @(*) begin

        activation_write_enable = 1'b0;
        activation_write_addr   = 5'd0;
        activation_write_data   = 8'd0;

        if (store_enable) begin

            activation_write_enable = 1'b1;

            activation_write_addr =
                ({3'b000, current_group} << 3) +
                ({4'b0000, phase} << 2) +
                {3'b000, store_index};


            case (store_index)

                2'd0:
                    activation_write_data = activation0;

                2'd1:
                    activation_write_data = activation1;

                2'd2:
                    activation_write_data = activation2;

                2'd3:
                    activation_write_data = activation3;

                default:
                    activation_write_data = 8'd0;

            endcase

        end

    end

endmodule
