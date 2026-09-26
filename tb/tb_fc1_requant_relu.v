`timescale 1ns/1ps

module tb_fc1_requant_relu;

    reg signed [25:0] accumulator;
    wire [7:0] activation;


    // --------------------------------------------------------
    // DUT
    // --------------------------------------------------------

    fc1_requant_relu dut (
        .accumulator(accumulator),
        .activation(activation)
    );


    // --------------------------------------------------------
    // Test
    // --------------------------------------------------------

    initial begin

        // ----------------------------------------------------
        // Zero
        // ----------------------------------------------------

        accumulator = 26'sd0;
        #1;

        $display("Accumulator = %0d, Activation = %0d",
                 accumulator, activation);

        if (activation != 8'd0)
            $display("FAIL: zero");


        // ----------------------------------------------------
        // Small positive value
        //
        // 1024 / 1024 = 1
        // ----------------------------------------------------

        accumulator = 26'sd1024;
        #1;

        $display("Accumulator = %0d, Activation = %0d",
                 accumulator, activation);

        if (activation != 8'd1)
            $display("FAIL: 1024");


        // ----------------------------------------------------
        // 2048 / 1024 = 2
        // ----------------------------------------------------

        accumulator = 26'sd2048;
        #1;

        $display("Accumulator = %0d, Activation = %0d",
                 accumulator, activation);

        if (activation != 8'd2)
            $display("FAIL: 2048");


        // ----------------------------------------------------
        // Rounding test
        //
        // 1024 + 512 = 1536
        // 1536 / 1024 -> 2 after rounding
        // ----------------------------------------------------

        accumulator = 26'sd1536;
        #1;

        $display("Accumulator = %0d, Activation = %0d",
                 accumulator, activation);

        if (activation != 8'd2)
            $display("FAIL: rounding");


        // ----------------------------------------------------
        // Negative value
        //
        // ReLU -> 0
        // ----------------------------------------------------

        accumulator = -26'sd5000;
        #1;

        $display("Accumulator = %0d, Activation = %0d",
                 accumulator, activation);

        if (activation != 8'd0)
            $display("FAIL: negative/ReLU");


        // ----------------------------------------------------
        // Maximum representable activation
        //
        // 255 * 1024 = 261120
        // ----------------------------------------------------

        accumulator = 26'sd261120;
        #1;

        $display("Accumulator = %0d, Activation = %0d",
                 accumulator, activation);

        if (activation != 8'd255)
            $display("FAIL: 255");


        // ----------------------------------------------------
        // Saturation
        //
        // Anything above 255 must become 255.
        // ----------------------------------------------------

        accumulator = 26'sd500000;
        #1;

        $display("Accumulator = %0d, Activation = %0d",
                 accumulator, activation);

        if (activation != 8'd255)
            $display("FAIL: saturation");


        $display("\nFC1 requantization + ReLU test complete.");

        $finish;

    end

endmodule
