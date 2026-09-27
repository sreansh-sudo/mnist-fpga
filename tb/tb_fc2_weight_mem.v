`timescale 1ns/1ps

module tb_fc2_weight_mem;

    reg [4:0] addr;

    wire signed [7:0] weight0;
    wire signed [7:0] weight1;
    wire signed [7:0] weight2;
    wire signed [7:0] weight3;
    wire signed [7:0] weight4;
    wire signed [7:0] weight5;
    wire signed [7:0] weight6;
    wire signed [7:0] weight7;
    wire signed [7:0] weight8;
    wire signed [7:0] weight9;

    fc2_weight_mem dut (
        .addr(addr),

        .weight0(weight0),
        .weight1(weight1),
        .weight2(weight2),
        .weight3(weight3),
        .weight4(weight4),
        .weight5(weight5),
        .weight6(weight6),
        .weight7(weight7),
        .weight8(weight8),
        .weight9(weight9)
    );

    // ------------------------------------------------------------
    // Check one complete address
    // ------------------------------------------------------------

    task check_address;

        input [4:0] address;

        input signed [7:0] expected0;
        input signed [7:0] expected1;
        input signed [7:0] expected2;
        input signed [7:0] expected3;
        input signed [7:0] expected4;
        input signed [7:0] expected5;
        input signed [7:0] expected6;
        input signed [7:0] expected7;
        input signed [7:0] expected8;
        input signed [7:0] expected9;

        begin

            addr = address;

            #1;

            if (weight0 !== expected0) begin
                $display(
                    "FAIL: addr %0d bank0 expected %0d got %0d",
                    address, expected0, weight0
                );
                $finish;
            end

            if (weight1 !== expected1) begin
                $display(
                    "FAIL: addr %0d bank1 expected %0d got %0d",
                    address, expected1, weight1
                );
                $finish;
            end

            if (weight2 !== expected2) begin
                $display(
                    "FAIL: addr %0d bank2 expected %0d got %0d",
                    address, expected2, weight2
                );
                $finish;
            end

            if (weight3 !== expected3) begin
                $display(
                    "FAIL: addr %0d bank3 expected %0d got %0d",
                    address, expected3, weight3
                );
                $finish;
            end

            if (weight4 !== expected4) begin
                $display(
                    "FAIL: addr %0d bank4 expected %0d got %0d",
                    address, expected4, weight4
                );
                $finish;
            end

            if (weight5 !== expected5) begin
                $display(
                    "FAIL: addr %0d bank5 expected %0d got %0d",
                    address, expected5, weight5
                );
                $finish;
            end

            if (weight6 !== expected6) begin
                $display(
                    "FAIL: addr %0d bank6 expected %0d got %0d",
                    address, expected6, weight6
                );
                $finish;
            end

            if (weight7 !== expected7) begin
                $display(
                    "FAIL: addr %0d bank7 expected %0d got %0d",
                    address, expected7, weight7
                );
                $finish;
            end

            if (weight8 !== expected8) begin
                $display(
                    "FAIL: addr %0d bank8 expected %0d got %0d",
                    address, expected8, weight8
                );
                $finish;
            end

            if (weight9 !== expected9) begin
                $display(
                    "FAIL: addr %0d bank9 expected %0d got %0d",
                    address, expected9, weight9
                );
                $finish;
            end

            $display(
    "PASS: address %0d -> weights = [%0d, %0d, %0d, %0d, %0d, %0d, %0d, %0d, %0d, %0d]",
    address,
    weight0,
    weight1,
    weight2,
    weight3,
    weight4,
    weight5,
    weight6,
    weight7,
    weight8,
    weight9
);

        end

    endtask

    // ------------------------------------------------------------
    // Test
    // ------------------------------------------------------------

    initial begin

        addr = 5'd0;

        // Give $readmemh time to initialize.
        #1;

        // --------------------------------------------------------
        // Address 0
        //
        // From generated FC2 memory:
        //
        // bank0 = -24
        // bank1 =  24
        // bank2 =  -6
        // bank3 =   2
        // bank4 = -17
        // bank5 =  -2
        // bank6 =  10
        // bank7 = -15
        // bank8 =  13
        // bank9 = -29
        // --------------------------------------------------------

        check_address(
            5'd0,
            -8'sd24,
             8'sd24,
            -8'sd6,
             8'sd2,
            -8'sd17,
            -8'sd2,
             8'sd10,
            -8'sd15,
             8'sd13,
            -8'sd29
        );

        // --------------------------------------------------------
        // Address 1
        // --------------------------------------------------------

        check_address(
            5'd1,
             8'sd10,
            -8'sd19,
             8'sd19,
             8'sd11,
             8'sd19,
            -8'sd21,
             8'sd3,
            -8'sd23,
             8'sd9,
             8'sd6
        );

        // --------------------------------------------------------
        // Address 2
        // --------------------------------------------------------

        check_address(
            5'd2,
             8'sd11,
             8'sd4,
             8'sd33,
             8'sd17,
            -8'sd29,
             8'sd2,
            -8'sd43,
            -8'sd3,
            -8'sd11,
            -8'sd16
        );

        // --------------------------------------------------------
        // Address 31
        // --------------------------------------------------------

        check_address(
            5'd31,
             8'sd9,
            -8'sd25,
             8'sd8,
            -8'sd13,
            -8'sd4,
             8'sd0,
             8'sd20,
            -8'sd18,
             8'sd7,
            -8'sd9
        );

        $display("========================================");
        $display("FC2 WEIGHT MEMORY TEST: PASS");
        $display("========================================");

        $finish;

    end

endmodule
