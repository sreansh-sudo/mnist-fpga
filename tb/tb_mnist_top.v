`timescale 1ns/1ps

module tb_mnist_top;

    // ========================================================
    // Clock / reset
    // ========================================================

    reg clk;
    reg rst;
    reg start;

    // ========================================================
    // Input loading interface
    // ========================================================

    reg        input_write_enable;
    reg [9:0]  input_write_addr;
    reg [7:0]  input_write_data;

    // ========================================================
    // Outputs
    // ========================================================

    wire       done;
    wire [3:0] predicted_digit;

    wire signed [20:0] logit0;
    wire signed [20:0] logit1;
    wire signed [20:0] logit2;
    wire signed [20:0] logit3;
    wire signed [20:0] logit4;
    wire signed [20:0] logit5;
    wire signed [20:0] logit6;
    wire signed [20:0] logit7;
    wire signed [20:0] logit8;
    wire signed [20:0] logit9;

    // ========================================================
    // Test input memory
    // ========================================================

    reg [7:0] test_input [0:783];

    // ========================================================
    // 64-bit simulation timestamps
    // ========================================================

    reg [63:0] start_time;
    reg [63:0] done_time;

    // ========================================================
    // DUT
    // ========================================================

    mnist_top dut (
        .clk(clk),
        .rst(rst),
        .start(start),

        .input_write_enable(input_write_enable),
        .input_write_addr(input_write_addr),
        .input_write_data(input_write_data),

        .done(done),
        .predicted_digit(predicted_digit),

        .logit0(logit0),
        .logit1(logit1),
        .logit2(logit2),
        .logit3(logit3),
        .logit4(logit4),
        .logit5(logit5),
        .logit6(logit6),
        .logit7(logit7),
        .logit8(logit8),
        .logit9(logit9)
    );

    // ========================================================
    // Clock generation
    //
    // 10 ns clock period
    // ========================================================

    initial begin
        clk = 1'b0;

        forever #5 clk = ~clk;
    end

    // ========================================================
    // Main test
    // ========================================================

    integer i;

    initial begin

        // ----------------------------------------------------
        // Load MNIST test image
        // ----------------------------------------------------

        $readmemh("data/test_input.mem", test_input);

        // ----------------------------------------------------
        // Initial conditions
        // ----------------------------------------------------

        rst = 1'b1;
        start = 1'b0;

        input_write_enable = 1'b0;
        input_write_addr = 10'd0;
        input_write_data = 8'd0;

        start_time = 64'd0;
        done_time = 64'd0;

        // ----------------------------------------------------
        // Reset DUT
        // ----------------------------------------------------

        repeat (2) @(posedge clk);

        rst = 1'b0;

        @(posedge clk);

        // ----------------------------------------------------
        // Load all 784 quantized pixels into FC1
        // input memory
        // ----------------------------------------------------

        for (i = 0; i < 784; i = i + 1) begin

            @(posedge clk);

            input_write_enable = 1'b1;
            input_write_addr = i[9:0];
            input_write_data = test_input[i];

        end

        // Finish final write cleanly
        @(posedge clk);

        input_write_enable = 1'b0;
        input_write_addr = 10'd0;
        input_write_data = 8'd0;

        // ----------------------------------------------------
        // Start complete MNIST inference
        // ----------------------------------------------------

        @(posedge clk);

        start = 1'b1;
        start_time = $time;

        @(posedge clk);

        start = 1'b0;

        // ----------------------------------------------------
        // Wait for complete inference
        // ----------------------------------------------------

        wait (done == 1'b1);

        done_time = $time;

        // ----------------------------------------------------
        // Display final results
        // ----------------------------------------------------

        $display("");
        $display("========================================");
        $display("       MNIST FULL NETWORK TEST");
        $display("========================================");

        $display("");
        $display("FINAL FC2 LOGITS");

        $display("logit0 = %0d", logit0);
        $display("logit1 = %0d", logit1);
        $display("logit2 = %0d", logit2);
        $display("logit3 = %0d", logit3);
        $display("logit4 = %0d", logit4);
        $display("logit5 = %0d", logit5);
        $display("logit6 = %0d", logit6);
        $display("logit7 = %0d", logit7);
        $display("logit8 = %0d", logit8);
        $display("logit9 = %0d", logit9);

        $display("");
        $display("Predicted digit = %0d", predicted_digit);
        $display("Expected digit  = 7");

        $display("");
        $display("Inference simulation time = %0d ns",
                 done_time - start_time);

        // ----------------------------------------------------
        // Check prediction
        // ----------------------------------------------------

        if (predicted_digit == 4'd7) begin

            $display("");
            $display("========================================");
            $display("MNIST FULL NETWORK TEST: PASS");
            $display("========================================");

        end

        else begin

            $display("");
            $display("========================================");
            $display("MNIST FULL NETWORK TEST: FAIL");
            $display("========================================");

        end

        $finish;

    end

endmodule
