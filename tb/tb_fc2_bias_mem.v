`timescale 1ns/1ps

module tb_fc2_bias_mem;

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

    fc2_bias_mem dut (
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

    initial begin

        #1;

        if (bias0 !== -21'sd79) begin
            $display("FAIL: bias0 expected -79, got %0d", bias0);
            $finish;
        end

        if (bias1 !== 21'sd134) begin
            $display("FAIL: bias1 expected 134, got %0d", bias1);
            $finish;
        end

        if (bias2 !== 21'sd12) begin
            $display("FAIL: bias2 expected 12, got %0d", bias2);
            $finish;
        end

        if (bias3 !== -21'sd181) begin
            $display("FAIL: bias3 expected -181, got %0d", bias3);
            $finish;
        end

        if (bias4 !== 21'sd50) begin
            $display("FAIL: bias4 expected 50, got %0d", bias4);
            $finish;
        end

        if (bias5 !== 21'sd118) begin
            $display("FAIL: bias5 expected 118, got %0d", bias5);
            $finish;
        end

        if (bias6 !== -21'sd15) begin
            $display("FAIL: bias6 expected -15, got %0d", bias6);
            $finish;
        end

        if (bias7 !== -21'sd33) begin
            $display("FAIL: bias7 expected -33, got %0d", bias7);
            $finish;
        end

        if (bias8 !== -21'sd96) begin
            $display("FAIL: bias8 expected -96, got %0d", bias8);
            $finish;
        end

        if (bias9 !== 21'sd61) begin
            $display("FAIL: bias9 expected 61, got %0d", bias9);
            $finish;
        end

        $display("PASS: bias0 = %0d", bias0);
        $display("PASS: bias1 = %0d", bias1);
        $display("PASS: bias2 = %0d", bias2);
        $display("PASS: bias3 = %0d", bias3);
        $display("PASS: bias4 = %0d", bias4);
        $display("PASS: bias5 = %0d", bias5);
        $display("PASS: bias6 = %0d", bias6);
        $display("PASS: bias7 = %0d", bias7);
        $display("PASS: bias8 = %0d", bias8);
        $display("PASS: bias9 = %0d", bias9);

        $display("========================================");
        $display("FC2 BIAS MEMORY TEST: PASS");
        $display("========================================");

        $finish;

    end

endmodule
