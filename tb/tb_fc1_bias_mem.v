`timescale 1ns/1ps

module tb_fc1_bias_mem;

    reg [1:0] group;

    wire signed [25:0] bias0;
    wire signed [25:0] bias1;
    wire signed [25:0] bias2;
    wire signed [25:0] bias3;
    wire signed [25:0] bias4;
    wire signed [25:0] bias5;
    wire signed [25:0] bias6;
    wire signed [25:0] bias7;


    // --------------------------------------------------------
    // DUT
    // --------------------------------------------------------

    fc1_bias_mem dut (
        .group(group),

        .bias0(bias0),
        .bias1(bias1),
        .bias2(bias2),
        .bias3(bias3),
        .bias4(bias4),
        .bias5(bias5),
        .bias6(bias6),
        .bias7(bias7)
    );


    // --------------------------------------------------------
    // Test
    // --------------------------------------------------------

    initial begin

        // ----------------------------------------------------
        // Group 0
        // Neurons 0..7
        // ----------------------------------------------------

        group = 2'd0;
        #1;

        $display("Group 0:");
        $display("  Biases = %0d %0d %0d %0d %0d %0d %0d %0d",
                 bias0, bias1, bias2, bias3,
                 bias4, bias5, bias6, bias7);


        // ----------------------------------------------------
        // Group 1
        // Neurons 8..15
        // ----------------------------------------------------

        group = 2'd1;
        #1;

        $display("\nGroup 1:");
        $display("  Biases = %0d %0d %0d %0d %0d %0d %0d %0d",
                 bias0, bias1, bias2, bias3,
                 bias4, bias5, bias6, bias7);


        // ----------------------------------------------------
        // Group 2
        // Neurons 16..23
        // ----------------------------------------------------

        group = 2'd2;
        #1;

        $display("\nGroup 2:");
        $display("  Biases = %0d %0d %0d %0d %0d %0d %0d %0d",
                 bias0, bias1, bias2, bias3,
                 bias4, bias5, bias6, bias7);


        // ----------------------------------------------------
        // Group 3
        // Neurons 24..31
        // ----------------------------------------------------

        group = 2'd3;
        #1;

        $display("\nGroup 3:");
        $display("  Biases = %0d %0d %0d %0d %0d %0d %0d %0d",
                 bias0, bias1, bias2, bias3,
                 bias4, bias5, bias6, bias7);


        $display("\nFC1 bias memory test complete.");

        $finish;
    end

endmodule
