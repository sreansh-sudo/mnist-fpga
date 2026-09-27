`timescale 1ns/1ps

module tb_fc2_mac10;

    reg clk;
    reg rst;

    reg load_bias;
    reg mac_enable;

    reg [7:0] activation;

    reg signed [7:0]  weight [0:9];
    reg signed [20:0] bias   [0:9];

    wire signed [20:0] accumulator [0:9];

    integer i;

    // ============================================================
    // DUT
    // ============================================================

    fc2_mac10 dut (
        .clk(clk),
        .rst(rst),

        .load_bias(load_bias),
        .mac_enable(mac_enable),

        .activation(activation),

        .weight(weight),
        .bias(bias),

        .accumulator(accumulator)
    );

    // ============================================================
    // Clock
    // ============================================================

    always #5 clk = ~clk;

    // ============================================================
    // Test
    // ============================================================

    initial begin

        // --------------------------------------------------------
        // Initial values
        // --------------------------------------------------------

        clk        = 1'b0;
        rst        = 1'b1;
        load_bias  = 1'b0;
        mac_enable = 1'b0;
        activation = 8'd0;

        for (i = 0; i < 10; i = i + 1) begin
            weight[i] = 8'sd0;
            bias[i]   = 21'sd0;
        end

        // --------------------------------------------------------
        // TEST 1: RESET
        // --------------------------------------------------------

        @(posedge clk);
        #1;

        for (i = 0; i < 10; i = i + 1) begin
            if (accumulator[i] !== 21'sd0) begin
                $display(
                    "FAIL: lane %0d reset = %0d",
                    i,
                    accumulator[i]
                );
                $finish;
            end
        end

        $display("PASS: all lanes reset to 0");

        rst = 1'b0;

        // --------------------------------------------------------
        // TEST DATA
        //
        // Bias:
        //   lane 0 = 100
        //   lane 1 = 101
        //   ...
        //   lane 9 = 109
        //
        // Weight:
        //   lane 0 = -5
        //   lane 1 = -4
        //   ...
        //   lane 5 =  0
        //   ...
        //   lane 9 = +4
        // --------------------------------------------------------

        bias[0] = 21'sd100;
        bias[1] = 21'sd101;
        bias[2] = 21'sd102;
        bias[3] = 21'sd103;
        bias[4] = 21'sd104;
        bias[5] = 21'sd105;
        bias[6] = 21'sd106;
        bias[7] = 21'sd107;
        bias[8] = 21'sd108;
        bias[9] = 21'sd109;

        weight[0] = -8'sd5;
        weight[1] = -8'sd4;
        weight[2] = -8'sd3;
        weight[3] = -8'sd2;
        weight[4] = -8'sd1;
        weight[5] =  8'sd0;
        weight[6] =  8'sd1;
        weight[7] =  8'sd2;
        weight[8] =  8'sd3;
        weight[9] =  8'sd4;

        // --------------------------------------------------------
        // TEST 2: LOAD BIASES
        // --------------------------------------------------------

        load_bias = 1'b1;

        @(posedge clk);
        #1;

        load_bias = 1'b0;

        // Verify each lane received its own bias

        if (accumulator[0] !== 21'sd100) begin
            $display("FAIL: lane 0 bias = %0d", accumulator[0]);
            $finish;
        end

        if (accumulator[1] !== 21'sd101) begin
            $display("FAIL: lane 1 bias = %0d", accumulator[1]);
            $finish;
        end

        if (accumulator[2] !== 21'sd102) begin
            $display("FAIL: lane 2 bias = %0d", accumulator[2]);
            $finish;
        end

        if (accumulator[3] !== 21'sd103) begin
            $display("FAIL: lane 3 bias = %0d", accumulator[3]);
            $finish;
        end

        if (accumulator[4] !== 21'sd104) begin
            $display("FAIL: lane 4 bias = %0d", accumulator[4]);
            $finish;
        end

        if (accumulator[5] !== 21'sd105) begin
            $display("FAIL: lane 5 bias = %0d", accumulator[5]);
            $finish;
        end

        if (accumulator[6] !== 21'sd106) begin
            $display("FAIL: lane 6 bias = %0d", accumulator[6]);
            $finish;
        end

        if (accumulator[7] !== 21'sd107) begin
            $display("FAIL: lane 7 bias = %0d", accumulator[7]);
            $finish;
        end

        if (accumulator[8] !== 21'sd108) begin
            $display("FAIL: lane 8 bias = %0d", accumulator[8]);
            $finish;
        end

        if (accumulator[9] !== 21'sd109) begin
            $display("FAIL: lane 9 bias = %0d", accumulator[9]);
            $finish;
        end

        $display("PASS: all 10 lanes loaded correct biases");

        // --------------------------------------------------------
        // TEST 3: FIRST MAC
        //
        // activation = 10
        //
        // Expected:
        //
        // lane 0: 100 + (10 * -5) = 50
        // lane 1: 101 + (10 * -4) = 61
        // lane 2: 102 + (10 * -3) = 72
        // lane 3: 103 + (10 * -2) = 83
        // lane 4: 104 + (10 * -1) = 94
        // lane 5: 105 + (10 *  0) = 105
        // lane 6: 106 + (10 *  1) = 116
        // lane 7: 107 + (10 *  2) = 127
        // lane 8: 108 + (10 *  3) = 138
        // lane 9: 109 + (10 *  4) = 149
        // --------------------------------------------------------

        activation = 8'd10;
        mac_enable = 1'b1;

        @(posedge clk);
        #1;

        mac_enable = 1'b0;

        if (accumulator[0] !== 21'sd50) begin
            $display("FAIL: lane 0 first MAC = %0d", accumulator[0]);
            $finish;
        end

        if (accumulator[1] !== 21'sd61) begin
            $display("FAIL: lane 1 first MAC = %0d", accumulator[1]);
            $finish;
        end

        if (accumulator[2] !== 21'sd72) begin
            $display("FAIL: lane 2 first MAC = %0d", accumulator[2]);
            $finish;
        end

        if (accumulator[3] !== 21'sd83) begin
            $display("FAIL: lane 3 first MAC = %0d", accumulator[3]);
            $finish;
        end

        if (accumulator[4] !== 21'sd94) begin
            $display("FAIL: lane 4 first MAC = %0d", accumulator[4]);
            $finish;
        end

        if (accumulator[5] !== 21'sd105) begin
            $display("FAIL: lane 5 first MAC = %0d", accumulator[5]);
            $finish;
        end

        if (accumulator[6] !== 21'sd116) begin
            $display("FAIL: lane 6 first MAC = %0d", accumulator[6]);
            $finish;
        end

        if (accumulator[7] !== 21'sd127) begin
            $display("FAIL: lane 7 first MAC = %0d", accumulator[7]);
            $finish;
        end

        if (accumulator[8] !== 21'sd138) begin
            $display("FAIL: lane 8 first MAC = %0d", accumulator[8]);
            $finish;
        end

        if (accumulator[9] !== 21'sd149) begin
            $display("FAIL: lane 9 first MAC = %0d", accumulator[9]);
            $finish;
        end

        $display("PASS: all 10 lanes produced correct first MAC");

        // --------------------------------------------------------
        // TEST 4: SECOND MAC
        //
        // activation = 2
        //
        // Expected:
        //
        // lane 0: 50  + (2 * -5) = 40
        // lane 1: 61  + (2 * -4) = 53
        // lane 2: 72  + (2 * -3) = 66
        // lane 3: 83  + (2 * -2) = 79
        // lane 4: 94  + (2 * -1) = 92
        // lane 5: 105 + (2 *  0) = 105
        // lane 6: 116 + (2 *  1) = 118
        // lane 7: 127 + (2 *  2) = 131
        // lane 8: 138 + (2 *  3) = 144
        // lane 9: 149 + (2 *  4) = 157
        // --------------------------------------------------------

        activation = 8'd2;
        mac_enable = 1'b1;

        @(posedge clk);
        #1;

        mac_enable = 1'b0;

        if (accumulator[0] !== 21'sd40) begin
            $display("FAIL: lane 0 second MAC = %0d", accumulator[0]);
            $finish;
        end

        if (accumulator[1] !== 21'sd53) begin
            $display("FAIL: lane 1 second MAC = %0d", accumulator[1]);
            $finish;
        end

        if (accumulator[2] !== 21'sd66) begin
            $display("FAIL: lane 2 second MAC = %0d", accumulator[2]);
            $finish;
        end

        if (accumulator[3] !== 21'sd79) begin
            $display("FAIL: lane 3 second MAC = %0d", accumulator[3]);
            $finish;
        end

        if (accumulator[4] !== 21'sd92) begin
            $display("FAIL: lane 4 second MAC = %0d", accumulator[4]);
            $finish;
        end

        if (accumulator[5] !== 21'sd105) begin
            $display("FAIL: lane 5 second MAC = %0d", accumulator[5]);
            $finish;
        end

        if (accumulator[6] !== 21'sd118) begin
            $display("FAIL: lane 6 second MAC = %0d", accumulator[6]);
            $finish;
        end

        if (accumulator[7] !== 21'sd131) begin
            $display("FAIL: lane 7 second MAC = %0d", accumulator[7]);
            $finish;
        end

        if (accumulator[8] !== 21'sd144) begin
            $display("FAIL: lane 8 second MAC = %0d", accumulator[8]);
            $finish;
        end

        if (accumulator[9] !== 21'sd157) begin
            $display("FAIL: lane 9 second MAC = %0d", accumulator[9]);
            $finish;
        end

        $display("PASS: repeated MAC on all 10 lanes");

        // --------------------------------------------------------
        // FINAL RESULT
        // --------------------------------------------------------

        $display("========================================");
        $display("FC2 MAC10 TEST: PASS");
        $display("========================================");

        $finish;

    end

endmodule
