`timescale 1ns/1ps

module tb_fc2_mac_lane;

    reg clk;
    reg rst;

    reg load_bias;
    reg mac_enable;

    reg [7:0] activation;
    reg signed [7:0] weight;
    reg signed [20:0] bias;

    wire signed [20:0] accumulator;

    fc2_mac_lane dut (
        .clk(clk),
        .rst(rst),
        .load_bias(load_bias),
        .mac_enable(mac_enable),
        .activation(activation),
        .weight(weight),
        .bias(bias),
        .accumulator(accumulator)
    );

    always #5 clk = ~clk;

    task check_accumulator;
        input signed [20:0] expected;
        begin
            if (accumulator !== expected) begin
                $display("FAIL: expected %0d, got %0d",
                         expected, accumulator);
                $finish;
            end
            else begin
                $display("PASS: accumulator = %0d", accumulator);
            end
        end
    endtask

    initial begin

        clk = 0;
        rst = 1;
        load_bias = 0;
        mac_enable = 0;
        activation = 0;
        weight = 0;
        bias = 0;

        // Reset
        @(posedge clk);
        #1;
        check_accumulator(0);

        rst = 0;

        // ------------------------------------------------
        // Test 1: 10 * 5 + 100 = 150
        // ------------------------------------------------
        bias = 100;
        load_bias = 1;

        @(posedge clk);
        #1;

        load_bias = 0;
        activation = 10;
        weight = 5;
        mac_enable = 1;

        @(posedge clk);
        #1;

        mac_enable = 0;

        check_accumulator(150);

        // ------------------------------------------------
        // Test 2: 10 * (-5) + 100 = 50
        // ------------------------------------------------
        rst = 1;

        @(posedge clk);
        #1;

        rst = 0;

        bias = 100;
        load_bias = 1;

        @(posedge clk);
        #1;

        load_bias = 0;
        activation = 10;
        weight = -5;
        mac_enable = 1;

        @(posedge clk);
        #1;

        mac_enable = 0;

        check_accumulator(50);

        // ------------------------------------------------
        // Test 3: 255 * 127 = 32385
        // ------------------------------------------------
        rst = 1;

        @(posedge clk);
        #1;

        rst = 0;

        bias = 0;
        load_bias = 1;

        @(posedge clk);
        #1;

        load_bias = 0;
        activation = 255;
        weight = 127;
        mac_enable = 1;

        @(posedge clk);
        #1;

        mac_enable = 0;

        check_accumulator(32385);

        // ------------------------------------------------
        // Test 4: 255 * (-128) = -32640
        // ------------------------------------------------
        rst = 1;

        @(posedge clk);
        #1;

        rst = 0;

        bias = 0;
        load_bias = 1;

        @(posedge clk);
        #1;

        load_bias = 0;
        activation = 255;
        weight = -128;
        mac_enable = 1;

        @(posedge clk);
        #1;

        mac_enable = 0;

        check_accumulator(-32640);

        // ------------------------------------------------
        // Test 5: repeated MAC
        //
        // 100 + (10*5) + (4*-3) + (7*2)
        // = 152
        // ------------------------------------------------
        rst = 1;

        @(posedge clk);
        #1;

        rst = 0;

        bias = 100;
        load_bias = 1;

        @(posedge clk);
        #1;

        load_bias = 0;

        activation = 10;
        weight = 5;
        mac_enable = 1;

        @(posedge clk);
        #1;

        activation = 4;
        weight = -3;

        @(posedge clk);
        #1;

        activation = 7;
        weight = 2;

        @(posedge clk);
        #1;

        mac_enable = 0;

        check_accumulator(152);

        $display("========================================");
        $display("FC2 MAC LANE TEST: PASS");
        $display("========================================");

        $finish;
    end

endmodule
