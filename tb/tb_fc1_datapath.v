`timescale 1ns/1ps

module tb_fc1_datapath;

    reg clk;
    reg rst;

    // Input memory signals
    reg        input_write_enable;
    reg [9:0]  input_write_addr;
    reg [7:0]  input_write_data;
    reg [9:0]  input_read_addr;
    wire [7:0] input_value;

    // Weight memory
    reg [11:0] weight_addr;

    wire signed [7:0] weight0;
    wire signed [7:0] weight1;
    wire signed [7:0] weight2;
    wire signed [7:0] weight3;
    wire signed [7:0] weight4;
    wire signed [7:0] weight5;
    wire signed [7:0] weight6;
    wire signed [7:0] weight7;

    // MAC control
    reg load_bias;
    reg enable;

    // MAC outputs
    wire signed [25:0] accumulator0;
    wire signed [25:0] accumulator1;
    wire signed [25:0] accumulator2;
    wire signed [25:0] accumulator3;
    wire signed [25:0] accumulator4;
    wire signed [25:0] accumulator5;
    wire signed [25:0] accumulator6;
    wire signed [25:0] accumulator7;


    // --------------------------------------------------------
    // Clock
    // --------------------------------------------------------

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end


    // --------------------------------------------------------
    // Input memory
    // --------------------------------------------------------

    fc1_input_mem input_memory (
        .clk(clk),
        .write_enable(input_write_enable),

        .write_addr(input_write_addr),
        .write_data(input_write_data),

        .read_addr(input_read_addr),
        .read_data(input_value)
    );


    // --------------------------------------------------------
    // Weight memory
    // --------------------------------------------------------

    fc1_weight_mem weight_memory (
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


    // --------------------------------------------------------
    // 8 parallel MAC lanes
    // --------------------------------------------------------

    fc1_mac8 mac8 (
        .clk(clk),
        .rst(rst),

        .enable(enable),
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

        .bias0(26'sd0),
        .bias1(26'sd0),
        .bias2(26'sd0),
        .bias3(26'sd0),
        .bias4(26'sd0),
        .bias5(26'sd0),
        .bias6(26'sd0),
        .bias7(26'sd0),

        .accumulator0(accumulator0),
        .accumulator1(accumulator1),
        .accumulator2(accumulator2),
        .accumulator3(accumulator3),
        .accumulator4(accumulator4),
        .accumulator5(accumulator5),
        .accumulator6(accumulator6),
        .accumulator7(accumulator7)
    );


    // --------------------------------------------------------
    // Test
    // --------------------------------------------------------

    initial begin

        rst = 1'b1;

        input_write_enable = 1'b0;
        input_write_addr = 10'd0;
        input_write_data = 8'd0;

        input_read_addr = 10'd0;
        weight_addr = 12'd0;

        load_bias = 1'b0;
        enable = 1'b0;


        // ----------------------------------------------------
        // Release reset
        // ----------------------------------------------------

        #12;
        rst = 1'b0;


        // ----------------------------------------------------
        // Load two input pixels
        //
        // input[0] = 10
        // input[1] = 20
        // ----------------------------------------------------

        input_write_enable = 1'b1;

        @(posedge clk);
        input_write_addr = 10'd0;
        input_write_data = 8'd10;

        @(posedge clk);
        input_write_addr = 10'd1;
        input_write_data = 8'd20;

        @(posedge clk);
        input_write_enable = 1'b0;


        // ----------------------------------------------------
        // Initialize accumulators to zero
        // ----------------------------------------------------

        load_bias = 1'b1;

        @(posedge clk);
        #1;

        load_bias = 1'b0;


        // ----------------------------------------------------
        // Test input[0] with Group 0 weights
        //
        // Address = 0
        //
        // Input = 10
        //
        // Weights:
        //   2, -1, 0, 1, 1, -1, 1, -1
        // ----------------------------------------------------

        input_read_addr = 10'd0;
        weight_addr = 12'd0;

        #1;

        $display("\nInput[0] = %0d", input_value);

        $display("Weights = %0d %0d %0d %0d %0d %0d %0d %0d",
                 weight0, weight1, weight2, weight3,
                 weight4, weight5, weight6, weight7);

        enable = 1'b1;

        @(posedge clk);
        #1;

        enable = 1'b0;

        $display("After input[0]:");
        $display("Accumulators = %0d %0d %0d %0d %0d %0d %0d %0d",
                 accumulator0, accumulator1, accumulator2,
                 accumulator3, accumulator4, accumulator5,
                 accumulator6, accumulator7);


        // ----------------------------------------------------
        // Test input[1] with Group 0 weights
        //
        // Input = 20
        //
        // Expected cumulative result:
        //
        // lane 0: 10*2 + 20*2 = 60
        // lane 1: 10*-1 + 20*2 = 30
        // lane 2: 10*0 + 20*(-1) = -20
        // lane 3: 10*1 + 20*2 = 50
        // lane 4: 10*1 + 20*(-1) = -10
        // lane 5: 10*-1 + 20*2 = 30
        // lane 6: 10*1 + 20*(-1) = -10
        // lane 7: 10*-1 + 20*2 = 30
        // ----------------------------------------------------

        input_read_addr = 10'd1;
        weight_addr = 12'd1;

        #1;

        $display("\nInput[1] = %0d", input_value);

        $display("Weights = %0d %0d %0d %0d %0d %0d %0d %0d",
                 weight0, weight1, weight2, weight3,
                 weight4, weight5, weight6, weight7);

        enable = 1'b1;

        @(posedge clk);
        #1;

        enable = 1'b0;

        $display("After input[1]:");
        $display("Accumulators = %0d %0d %0d %0d %0d %0d %0d %0d",
                 accumulator0, accumulator1, accumulator2,
                 accumulator3, accumulator4, accumulator5,
                 accumulator6, accumulator7);


        $display("\nFC1 complete datapath test finished.");

        $finish;

    end

endmodule
