`timescale 1ns/1ps

module tb_fc1_mac_lane;

    reg clk;
    reg rst;

    reg enable;
    reg load_bias;

    reg [7:0] input_value;
    reg signed [7:0] weight_value;
    reg signed [25:0] bias_value;

    wire signed [25:0] accumulator;

    // DUT: Device Under Test
    fc1_mac_lane dut (
        .clk(clk),
        .rst(rst),
        .enable(enable),
        .load_bias(load_bias),
        .input_value(input_value),
        .weight_value(weight_value),
        .bias_value(bias_value),
        .accumulator(accumulator)
    );

    // 100 MHz clock
    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    // Test sequence
    initial begin

        // -----------------------------
        // Initial values
        // -----------------------------
        rst          = 1'b1;
        enable       = 1'b0;
        load_bias    = 1'b0;
        input_value  = 8'd0;
        weight_value = 8'sd0;
        bias_value   = 26'sd0;

        // Hold reset for two clock cycles
        #20;

        rst = 1'b0;

        // =====================================================
        // TEST 1
        // 10 × 5 + 100 = 150
        // =====================================================

        $display("\nTEST 1: positive × positive");

        bias_value = 26'sd100;
        load_bias  = 1'b1;

        @(posedge clk);
        #1;

        load_bias = 1'b0;

        input_value  = 8'd10;
        weight_value = 8'sd5;
        enable       = 1'b1;

        @(posedge clk);
        #1;

        enable = 1'b0;

        if (accumulator !== 26'sd150)
            $display("FAIL: Expected 150, got %0d", accumulator);
        else
            $display("PASS: accumulator = %0d", accumulator);


        // =====================================================
        // TEST 2
        // 10 × (-5) + 100 = 50
        // =====================================================

        $display("\nTEST 2: positive × negative");

        // Reload bias
        bias_value = 26'sd100;
        load_bias  = 1'b1;

        @(posedge clk);
        #1;

        load_bias = 1'b0;

        input_value  = 8'd10;
        weight_value = -8'sd5;
        enable       = 1'b1;

        @(posedge clk);
        #1;

        enable = 1'b0;

        if (accumulator !== 26'sd50)
            $display("FAIL: Expected 50, got %0d", accumulator);
        else
            $display("PASS: accumulator = %0d", accumulator);


        // =====================================================
        // TEST 3
        // 255 × 127 = 32385
        // =====================================================

        $display("\nTEST 3: maximum positive values");

        bias_value = 26'sd0;
        load_bias  = 1'b1;

        @(posedge clk);
        #1;

        load_bias = 1'b0;

        input_value  = 8'd255;
        weight_value = 8'sd127;
        enable       = 1'b1;

        @(posedge clk);
        #1;

        enable = 1'b0;

        if (accumulator !== 26'sd32385)
            $display("FAIL: Expected 32385, got %0d", accumulator);
        else
            $display("PASS: accumulator = %0d", accumulator);


        // =====================================================
        // TEST 4
        // 255 × (-128) = -32640
        // =====================================================

        $display("\nTEST 4: maximum input × minimum weight");

        bias_value = 26'sd0;
        load_bias  = 1'b1;

        @(posedge clk);
        #1;

        load_bias = 1'b0;

        input_value  = 8'd255;
        weight_value = -8'sd128;
        enable       = 1'b1;

        @(posedge clk);
        #1;

        enable = 1'b0;

        if (accumulator !== -26'sd32640)
            $display("FAIL: Expected -32640, got %0d", accumulator);
        else
            $display("PASS: accumulator = %0d", accumulator);


        // =====================================================
        // TEST 5
        // Multiple MAC operations
        //
        // bias = 10
        // 2×3 + 4×(-2) + 5×6
        //
        // = 10 + 6 - 8 + 30
        // = 38
        // =====================================================

        $display("\nTEST 5: multiple MAC operations");

        bias_value = 26'sd10;
        load_bias  = 1'b1;

        @(posedge clk);
        #1;

        load_bias = 1'b0;

        // 2 × 3 = 6
        input_value  = 8'd2;
        weight_value = 8'sd3;
        enable       = 1'b1;

        @(posedge clk);
        #1;

        // 4 × (-2) = -8
        input_value  = 8'd4;
        weight_value = -8'sd2;

        @(posedge clk);
        #1;

        // 5 × 6 = 30
        input_value  = 8'd5;
        weight_value = 8'sd6;

        @(posedge clk);
        #1;

        enable = 1'b0;

        if (accumulator !== 26'sd38)
            $display("FAIL: Expected 38, got %0d", accumulator);
        else
            $display("PASS: accumulator = %0d", accumulator);


        // =====================================================
        // End simulation
        // =====================================================

        $display("\n======================================");
        $display("FC1 MAC LANE TESTBENCH COMPLETE");
        $display("======================================\n");

        $finish;
    end

endmodule
