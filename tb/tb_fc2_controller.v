`timescale 1ns/1ps

module tb_fc2_controller;

    reg clk;
    reg rst;
    reg start;

    wire load_bias;
    wire mac_enable;
    wire [4:0] input_addr;
    wire done;

    integer mac_count;
    integer expected_addr;

    fc2_controller dut (
        .clk(clk),
        .rst(rst),
        .start(start),
        .load_bias(load_bias),
        .mac_enable(mac_enable),
        .input_addr(input_addr),
        .done(done)
    );


    // ------------------------------------------------------------
    // Clock
    // ------------------------------------------------------------

    initial begin
        clk = 1'b0;

        forever #5 clk = ~clk;
    end


    // ------------------------------------------------------------
    // Monitor / verification
    // ------------------------------------------------------------

    always @(posedge clk) begin

        #1;

        if (load_bias) begin

            $display(
                "INIT: load_bias = 1, input_addr = %0d",
                input_addr
            );

            if (input_addr !== 5'd0) begin
                $display("FAIL: INIT input_addr should be 0");
                $finish;
            end

        end


        if (mac_enable) begin

            $display(
                "MAC: input_addr = %0d",
                input_addr
            );

            if (input_addr !== expected_addr[4:0]) begin

                $display(
                    "FAIL: expected MAC address %0d, got %0d",
                    expected_addr,
                    input_addr
                );

                $finish;

            end

            mac_count = mac_count + 1;
            expected_addr = expected_addr + 1;

        end


        if (done) begin

            $display(
                "DONE: mac_count = %0d",
                mac_count
            );

            if (mac_count != 32) begin

                $display(
                    "FAIL: expected 32 MAC cycles, got %0d",
                    mac_count
                );

                $finish;

            end

            if (expected_addr != 32) begin

                $display(
                    "FAIL: expected final address count 32, got %0d",
                    expected_addr
                );

                $finish;

            end

            $display("========================================");
            $display("FC2 CONTROLLER TEST: PASS");
            $display("========================================");

            $finish;

        end

    end


    // ------------------------------------------------------------
    // Stimulus
    // ------------------------------------------------------------

    initial begin

        rst = 1'b1;
        start = 1'b0;

        mac_count = 0;
        expected_addr = 0;

        // Reset
        #12;

        rst = 1'b0;

        // Wait one cycle, then start FC2
        #8;

        start = 1'b1;

        #10;

        start = 1'b0;

    end

endmodule
