`timescale 1ns/1ps

module tb_fc1_mac8;

    reg clk;
    reg rst;

    reg enable;
    reg load_bias;

    reg [7:0] input_value;

    reg signed [7:0] weight0;
    reg signed [7:0] weight1;
    reg signed [7:0] weight2;
    reg signed [7:0] weight3;
    reg signed [7:0] weight4;
    reg signed [7:0] weight5;
    reg signed [7:0] weight6;
    reg signed [7:0] weight7;

    reg signed [25:0] bias0;
    reg signed [25:0] bias1;
    reg signed [25:0] bias2;
    reg signed [25:0] bias3;
    reg signed [25:0] bias4;
    reg signed [25:0] bias5;
    reg signed [25:0] bias6;
    reg signed [25:0] bias7;

    wire signed [25:0] accumulator0;
    wire signed [25:0] accumulator1;
    wire signed [25:0] accumulator2;
    wire signed [25:0] accumulator3;
    wire signed [25:0] accumulator4;
    wire signed [25:0] accumulator5;
    wire signed [25:0] accumulator6;
    wire signed [25:0] accumulator7;

    fc1_mac8 dut (
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

    // 100 MHz clock
    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    initial begin

        // -------------------------
        // Reset
        // -------------------------

        rst = 1'b1;
        enable = 1'b0;
        load_bias = 1'b0;
        input_value = 8'd0;

        weight0 = 0;
        weight1 = 0;
        weight2 = 0;
        weight3 = 0;
        weight4 = 0;
        weight5 = 0;
        weight6 = 0;
        weight7 = 0;

        bias0 = 0;
        bias1 = 0;
        bias2 = 0;
        bias3 = 0;
        bias4 = 0;
        bias5 = 0;
        bias6 = 0;
        bias7 = 0;

        #20;
        rst = 1'b0;


        // -------------------------
        // Load different biases
        // -------------------------

        bias0 = 26'sd10;
        bias1 = 26'sd20;
        bias2 = 26'sd30;
        bias3 = 26'sd40;
        bias4 = 26'sd50;
        bias5 = 26'sd60;
        bias6 = 26'sd70;
        bias7 = 26'sd80;

        load_bias = 1'b1;

        @(posedge clk);
        #1;

        load_bias = 1'b0;


        // -------------------------
        // Same input to all lanes
        // -------------------------

        input_value = 8'd10;

        // Different weights
        weight0 = 8'sd1;
        weight1 = 8'sd2;
        weight2 = 8'sd3;
        weight3 = 8'sd4;
        weight4 = 8'sd5;
        weight5 = 8'sd6;
        weight6 = 8'sd7;
        weight7 = 8'sd8;

        enable = 1'b1;

        @(posedge clk);
        #1;

        enable = 1'b0;


        // -------------------------
        // Expected:
        //
        // lane0 = 10 + 10×1 = 20
        // lane1 = 20 + 10×2 = 40
        // lane2 = 30 + 10×3 = 60
        // lane3 = 40 + 10×4 = 80
        // lane4 = 50 + 10×5 = 100
        // lane5 = 60 + 10×6 = 120
        // lane6 = 70 + 10×7 = 140
        // lane7 = 80 + 10×8 = 160
        // -------------------------

        if (accumulator0 !== 26'sd20)
            $display("FAIL lane0: expected 20, got %0d", accumulator0);
        else
            $display("PASS lane0: %0d", accumulator0);

        if (accumulator1 !== 26'sd40)
            $display("FAIL lane1: expected 40, got %0d", accumulator1);
        else
            $display("PASS lane1: %0d", accumulator1);

        if (accumulator2 !== 26'sd60)
            $display("FAIL lane2: expected 60, got %0d", accumulator2);
        else
            $display("PASS lane2: %0d", accumulator2);

        if (accumulator3 !== 26'sd80)
            $display("FAIL lane3: expected 80, got %0d", accumulator3);
        else
            $display("PASS lane3: %0d", accumulator3);

        if (accumulator4 !== 26'sd100)
            $display("FAIL lane4: expected 100, got %0d", accumulator4);
        else
            $display("PASS lane4: %0d", accumulator4);

        if (accumulator5 !== 26'sd120)
            $display("FAIL lane5: expected 120, got %0d", accumulator5);
        else
            $display("PASS lane5: %0d", accumulator5);

        if (accumulator6 !== 26'sd140)
            $display("FAIL lane6: expected 140, got %0d", accumulator6);
        else
            $display("PASS lane6: %0d", accumulator6);

        if (accumulator7 !== 26'sd160)
            $display("FAIL lane7: expected 160, got %0d", accumulator7);
        else
            $display("PASS lane7: %0d", accumulator7);


        // -------------------------
        // Second test:
        // negative weights
        // -------------------------

        input_value = 8'd10;

        weight0 = -8'sd1;
        weight1 = -8'sd2;
        weight2 = -8'sd3;
        weight3 = -8'sd4;
        weight4 = -8'sd5;
        weight5 = -8'sd6;
        weight6 = -8'sd7;
        weight7 = -8'sd8;

        enable = 1'b1;

        @(posedge clk);
        #1;

        enable = 1'b0;

        // Expected after second MAC:
        //
        // lane0 = 20  - 10 = 10
        // lane1 = 40  - 20 = 20
        // lane2 = 60  - 30 = 30
        // ...
        // lane7 = 160 - 80 = 80

        if (accumulator0 !== 26'sd10)
            $display("FAIL negative lane0: expected 10, got %0d", accumulator0);
        else
            $display("PASS negative lane0: %0d", accumulator0);

        if (accumulator1 !== 26'sd20)
            $display("FAIL negative lane1: expected 20, got %0d", accumulator1);
        else
            $display("PASS negative lane1: %0d", accumulator1);

        if (accumulator2 !== 26'sd30)
            $display("FAIL negative lane2: expected 30, got %0d", accumulator2);
        else
            $display("PASS negative lane2: %0d", accumulator2);

        if (accumulator3 !== 26'sd40)
            $display("FAIL negative lane3: expected 40, got %0d", accumulator3);
        else
            $display("PASS negative lane3: %0d", accumulator3);

        if (accumulator4 !== 26'sd50)
            $display("FAIL negative lane4: expected 50, got %0d", accumulator4);
        else
            $display("PASS negative lane4: %0d", accumulator4);

        if (accumulator5 !== 26'sd60)
            $display("FAIL negative lane5: expected 60, got %0d", accumulator5);
        else
            $display("PASS negative lane5: %0d", accumulator5);

        if (accumulator6 !== 26'sd70)
            $display("FAIL negative lane6: expected 70, got %0d", accumulator6);
        else
            $display("PASS negative lane6: %0d", accumulator6);

        if (accumulator7 !== 26'sd80)
            $display("FAIL negative lane7: expected 80, got %0d", accumulator7);
        else
            $display("PASS negative lane7: %0d", accumulator7);


        $display("\n======================================");
        $display("FC1 8-LANE MAC TEST COMPLETE");
        $display("======================================\n");

        $finish;
    end

endmodule
