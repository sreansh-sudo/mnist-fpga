`timescale 1ns/1ps

module tb_fc1_weight_mem;

    reg [11:0] addr;

    wire signed [7:0] weight0;
    wire signed [7:0] weight1;
    wire signed [7:0] weight2;
    wire signed [7:0] weight3;
    wire signed [7:0] weight4;
    wire signed [7:0] weight5;
    wire signed [7:0] weight6;
    wire signed [7:0] weight7;

    fc1_weight_mem dut (
        .addr(addr),

        .weight0(weight0),
        .weight1(weight1),
        .weight2(weight2),
        .weight3(weight3),
        .weight4(weight4),
        .weight5(weight5),
        .weight6(weight6),
        .weight7(weight7)
    );

    initial begin

        // ----------------------------------------------------
        // Test 1: Group 0, input 0
        // Address = 0
        // Should contain neurons 0..7, input 0
        // ----------------------------------------------------

        addr = 12'd0;
        #1;

        $display("Group 0, input 0:");
        $display("  Bank 0 = %0d", weight0);
        $display("  Bank 1 = %0d", weight1);
        $display("  Bank 2 = %0d", weight2);
        $display("  Bank 3 = %0d", weight3);
        $display("  Bank 4 = %0d", weight4);
        $display("  Bank 5 = %0d", weight5);
        $display("  Bank 6 = %0d", weight6);
        $display("  Bank 7 = %0d", weight7);


        // ----------------------------------------------------
        // Test 2: Group 1, input 0
        // Address = 784
        // Should contain neurons 8..15, input 0
        // ----------------------------------------------------

        addr = 12'd784;
        #1;

        $display("\nGroup 1, input 0:");
        $display("  Bank 0 = %0d", weight0);
        $display("  Bank 1 = %0d", weight1);
        $display("  Bank 2 = %0d", weight2);
        $display("  Bank 3 = %0d", weight3);
        $display("  Bank 4 = %0d", weight4);
        $display("  Bank 5 = %0d", weight5);
        $display("  Bank 6 = %0d", weight6);
        $display("  Bank 7 = %0d", weight7);


        // ----------------------------------------------------
        // Test 3: Group 2, input 0
        // Address = 1568
        // Should contain neurons 16..23, input 0
        // ----------------------------------------------------

        addr = 12'd1568;
        #1;

        $display("\nGroup 2, input 0:");
        $display("  Bank 0 = %0d", weight0);
        $display("  Bank 1 = %0d", weight1);
        $display("  Bank 2 = %0d", weight2);
        $display("  Bank 3 = %0d", weight3);
        $display("  Bank 4 = %0d", weight4);
        $display("  Bank 5 = %0d", weight5);
        $display("  Bank 6 = %0d", weight6);
        $display("  Bank 7 = %0d", weight7);


        // ----------------------------------------------------
        // Test 4: Group 3, input 0
        // Address = 2352
        // Should contain neurons 24..31, input 0
        // ----------------------------------------------------

        addr = 12'd2352;
        #1;

        $display("\nGroup 3, input 0:");
        $display("  Bank 0 = %0d", weight0);
        $display("  Bank 1 = %0d", weight1);
        $display("  Bank 2 = %0d", weight2);
        $display("  Bank 3 = %0d", weight3);
        $display("  Bank 4 = %0d", weight4);
        $display("  Bank 5 = %0d", weight5);
        $display("  Bank 6 = %0d", weight6);
        $display("  Bank 7 = %0d", weight7);


        // ----------------------------------------------------
        // Test 5: Last address
        // Address = 3135
        //
        // This is:
        // group 3 + input 783
        // ----------------------------------------------------

        addr = 12'd3135;
        #1;

        $display("\nGroup 3, input 783 (last address):");
        $display("  Bank 0 = %0d", weight0);
        $display("  Bank 1 = %0d", weight1);
        $display("  Bank 2 = %0d", weight2);
        $display("  Bank 3 = %0d", weight3);
        $display("  Bank 4 = %0d", weight4);
        $display("  Bank 5 = %0d", weight5);
        $display("  Bank 6 = %0d", weight6);
        $display("  Bank 7 = %0d", weight7);


        $display("\nFC1 weight memory test complete.");

        $finish;
    end

endmodule
