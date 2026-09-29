`timescale 1ns/1ps

module tb_fc1_mac4_pipe;

    reg clk;
    reg rst;

    reg enable;
    reg load_bias;

    reg [7:0] input_value;

    reg signed [7:0] weight0;
    reg signed [7:0] weight1;
    reg signed [7:0] weight2;
    reg signed [7:0] weight3;

    reg signed [25:0] bias0;
    reg signed [25:0] bias1;
    reg signed [25:0] bias2;
    reg signed [25:0] bias3;

    wire signed [25:0] pipe_acc0;
    wire signed [25:0] pipe_acc1;
    wire signed [25:0] pipe_acc2;
    wire signed [25:0] pipe_acc3;

    wire signed [25:0] ref_acc0;
    wire signed [25:0] ref_acc1;
    wire signed [25:0] ref_acc2;
    wire signed [25:0] ref_acc3;

    fc1_mac4_pipe dut_pipe (
        .clk(clk),
        .rst(rst),
        .enable(enable),
        .load_bias(load_bias),
        .input_value(input_value),
        .weight0(weight0),
        .weight1(weight1),
        .weight2(weight2),
        .weight3(weight3),
        .bias0(bias0),
        .bias1(bias1),
        .bias2(bias2),
        .bias3(bias3),
        .accumulator0(pipe_acc0),
        .accumulator1(pipe_acc1),
        .accumulator2(pipe_acc2),
        .accumulator3(pipe_acc3)
    );

    fc1_mac4 dut_ref (
        .clk(clk),
        .rst(rst),
        .enable(enable),
        .load_bias(load_bias),
        .input_value(input_value),
        .weight0(weight0),
        .weight1(weight1),
        .weight2(weight2),
        .weight3(weight3),
        .bias0(bias0),
        .bias1(bias1),
        .bias2(bias2),
        .bias3(bias3),
        .accumulator0(ref_acc0),
        .accumulator1(ref_acc1),
        .accumulator2(ref_acc2),
        .accumulator3(ref_acc3)
    );

    always #5 clk = ~clk;

    integer errors;

    initial begin
        clk = 0;
        rst = 1;

        enable = 0;
        load_bias = 0;

        input_value = 0;

        weight0 = 0;
        weight1 = 0;
        weight2 = 0;
        weight3 = 0;

        bias0 = 26'sd100;
        bias1 = -26'sd200;
        bias2 = 26'sd300;
        bias3 = -26'sd400;

        errors = 0;

        repeat (2) @(posedge clk);
        rst = 0;

        // ----------------------------------------------------
        // Load bias.
        // ----------------------------------------------------

        load_bias = 1;

        @(posedge clk);

        load_bias = 0;

        // ----------------------------------------------------
        // Apply three products.
        //
        // Each lane uses a different weight so that alignment
        // errors are easy to detect.
        // ----------------------------------------------------

        enable = 1;

        input_value = 8'd2;
        weight0 = 8'sd3;
        weight1 = -8'sd4;
        weight2 = 8'sd5;
        weight3 = -8'sd6;

        @(posedge clk);

        input_value = 8'd4;
        weight0 = 8'sd7;
        weight1 = -8'sd8;
        weight2 = 8'sd9;
        weight3 = -8'sd10;

        @(posedge clk);

        input_value = 8'd6;
        weight0 = 8'sd11;
        weight1 = -8'sd12;
        weight2 = 8'sd13;
        weight3 = -8'sd14;

        @(posedge clk);

        enable = 0;

        // Allow the pipelined MAC to consume the final operands.
        @(posedge clk);
        @(posedge clk);

        #1;

        $display("PIPE ACC0 = %0d", pipe_acc0);
        $display("PIPE ACC1 = %0d", pipe_acc1);
        $display("PIPE ACC2 = %0d", pipe_acc2);
        $display("PIPE ACC3 = %0d", pipe_acc3);

        $display("REF  ACC0 = %0d", ref_acc0);
        $display("REF  ACC1 = %0d", ref_acc1);
        $display("REF  ACC2 = %0d", ref_acc2);
        $display("REF  ACC3 = %0d", ref_acc3);

        // Reference:
        // lane0 = 100 + 2*3 + 4*7 + 6*11 = 192
        // lane1 = -200 + 2*(-4) + 4*(-8) + 6*(-12) = -304
        // lane2 = 300 + 2*5 + 4*9 + 6*13 = 424
        // lane3 = -400 + 2*(-6) + 4*(-10) + 6*(-14) = -544

        if (pipe_acc0 !== 26'sd200) errors = errors + 1;
        if (pipe_acc1 !== -26'sd312) errors = errors + 1;
        if (pipe_acc2 !== 26'sd424) errors = errors + 1;
        if (pipe_acc3 !== -26'sd536) errors = errors + 1;

        if (errors == 0)
            $display("FC1 MAC4 PIPE TEST PASS");
        else
            $display("FC1 MAC4 PIPE TEST FAIL: %0d errors", errors);

        $finish;
    end

endmodule
