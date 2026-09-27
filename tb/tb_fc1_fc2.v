`timescale 1ns/1ps

module tb_fc1_fc2;

    // ============================================================
    // Clock / Reset / Start
    // ============================================================

    reg clk;
    reg rst;
    reg start;

    // ============================================================
    // FC1 activation memory write interface
    // ============================================================

    reg        mem_write_enable;
    reg [4:0]  mem_write_addr;
    reg [7:0]  mem_write_data;

    // ============================================================
    // FC1 activation memory read interface
    // ============================================================

    reg  [4:0] mem_read_addr_tb;
    wire [4:0] mem_read_addr;
    wire [7:0] activation_mem_data;

    // Controls who owns the activation-memory read address
    // 0 = testbench
    // 1 = FC2
    reg fc2_active;

    // ============================================================
    // FC2 activation interface
    // ============================================================

    wire [4:0] activation_addr;
    wire [7:0] activation_data;

    // ============================================================
    // FC2 outputs
    // ============================================================

    wire [3:0] predicted_digit;
    wire       done;

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

    // ============================================================
    // Expected FC1 activation vector
    //
    // MNIST test image #0
    // Expected label = 7
    // ============================================================

    reg [7:0] expected_activation [0:31];

    integer i;
    integer errors;

    initial begin

        expected_activation[0]  = 8'd0;
        expected_activation[1]  = 8'd33;
        expected_activation[2]  = 8'd21;
        expected_activation[3]  = 8'd0;
        expected_activation[4]  = 8'd0;
        expected_activation[5]  = 8'd41;
        expected_activation[6]  = 8'd37;
        expected_activation[7]  = 8'd46;

        expected_activation[8]  = 8'd40;
        expected_activation[9]  = 8'd40;
        expected_activation[10] = 8'd14;
        expected_activation[11] = 8'd0;
        expected_activation[12] = 8'd42;
        expected_activation[13] = 8'd21;
        expected_activation[14] = 8'd27;
        expected_activation[15] = 8'd7;

        expected_activation[16] = 8'd34;
        expected_activation[17] = 8'd39;
        expected_activation[18] = 8'd0;
        expected_activation[19] = 8'd34;
        expected_activation[20] = 8'd31;
        expected_activation[21] = 8'd17;
        expected_activation[22] = 8'd5;
        expected_activation[23] = 8'd0;

        expected_activation[24] = 8'd2;
        expected_activation[25] = 8'd1;
        expected_activation[26] = 8'd25;
        expected_activation[27] = 8'd0;
        expected_activation[28] = 8'd24;
        expected_activation[29] = 8'd0;
        expected_activation[30] = 8'd0;
        expected_activation[31] = 8'd3;

    end

    // ============================================================
    // Activation-memory read-address ownership
    //
    // Before FC2:
    //     testbench controls read address
    //
    // During FC2:
    //     FC2 controller controls read address
    // ============================================================

    assign mem_read_addr = fc2_active
                         ? activation_addr
                         : mem_read_addr_tb;

    // ============================================================
    // FC1 Activation Memory
    // ============================================================

    fc1_activation_mem activation_memory (
        .clk(clk),

        .write_enable(mem_write_enable),
        .write_addr(mem_write_addr),
        .write_data(mem_write_data),

        .read_addr(mem_read_addr),
        .read_data(activation_mem_data)
    );

    // ============================================================
    // FC2 receives activation memory data
    // ============================================================

    assign activation_data = activation_mem_data;

    // ============================================================
    // FC2
    // ============================================================

    fc2 dut (
        .clk(clk),
        .rst(rst),
        .start(start),

        .activation_addr(activation_addr),
        .activation_data(activation_data),

        .predicted_digit(predicted_digit),
        .done(done),

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

    // ============================================================
    // Clock generation
    // 10 ns period
    // ============================================================

    initial begin
        clk = 1'b0;

        forever #5 clk = ~clk;
    end

    // ============================================================
    // Main test
    // ============================================================

    initial begin

        errors = 0;

        // --------------------------------------------------------
        // Initial conditions
        // --------------------------------------------------------

        rst = 1'b1;
        start = 1'b0;

        mem_write_enable = 1'b0;
        mem_write_addr = 5'd0;
        mem_write_data = 8'd0;

        mem_read_addr_tb = 5'd0;

        fc2_active = 1'b0;

        // --------------------------------------------------------
        // Reset
        // --------------------------------------------------------

        #12;

        rst = 1'b0;

        // --------------------------------------------------------
        // Load FC1 activation memory
        // --------------------------------------------------------

        $display("");
        $display("========================================");
        $display("LOADING FC1 ACTIVATION MEMORY");
        $display("========================================");

        for (i = 0; i < 32; i = i + 1) begin

            @(negedge clk);

            mem_write_enable = 1'b1;
            mem_write_addr = i[4:0];
            mem_write_data = expected_activation[i];

            @(posedge clk);

            #1;

            mem_write_enable = 1'b0;

            $display(
                "activation[%0d] = %0d",
                i,
                expected_activation[i]
            );

        end

        // --------------------------------------------------------
        // Disable writes
        // --------------------------------------------------------

        @(negedge clk);

        mem_write_enable = 1'b0;
        mem_write_addr = 5'd0;
        mem_write_data = 8'd0;

        // --------------------------------------------------------
        // Verify activation memory
        // --------------------------------------------------------

        $display("");
        $display("========================================");
        $display("VERIFYING FC1 ACTIVATION MEMORY");
        $display("========================================");

        for (i = 0; i < 32; i = i + 1) begin

            @(negedge clk);

            mem_read_addr_tb = i[4:0];

            #1;

            if (activation_mem_data !== expected_activation[i]) begin

                $display(
                    "FAIL: activation[%0d] = %0d, expected %0d",
                    i,
                    activation_mem_data,
                    expected_activation[i]
                );

                errors = errors + 1;

            end
            else begin

                $display(
                    "PASS: activation[%0d] = %0d",
                    i,
                    activation_mem_data
                );

            end

        end

        // --------------------------------------------------------
        // Activation-memory result
        // --------------------------------------------------------

        if (errors == 0) begin

            $display("");
            $display("FC1 ACTIVATION MEMORY TEST: PASS");

        end
        else begin

            $display("");
            $display(
                "FC1 ACTIVATION MEMORY TEST: FAIL (%0d errors)",
                errors
            );

            $finish;

        end

        // --------------------------------------------------------
        // Start FC2
        // --------------------------------------------------------

        $display("");
        $display("========================================");
        $display("STARTING FC2");
        $display("========================================");

        @(negedge clk);

        // Give FC2 permanent ownership of read address
        fc2_active = 1'b1;

        // Start FC2
        start = 1'b1;

        @(negedge clk);

        start = 1'b0;

        // --------------------------------------------------------
        // Wait for FC2 completion
        // --------------------------------------------------------

        wait (done == 1'b1);

        #1;

        // FC2 no longer needs the activation memory
        fc2_active = 1'b0;

        // --------------------------------------------------------
        // Display FC2 logits
        // --------------------------------------------------------

        $display("");
        $display("========================================");
        $display("FC2 FINAL LOGITS");
        $display("========================================");

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

        // --------------------------------------------------------
        // Prediction
        // --------------------------------------------------------

        $display("");
        $display("Predicted digit = %0d", predicted_digit);
        $display("Expected digit  = 7");

        $display("========================================");

        // --------------------------------------------------------
        // Final result
        // --------------------------------------------------------

        if (predicted_digit !== 4'd7) begin

            $display("FC1 -> FC2 TEST: FAIL");

        end
        else begin

            $display("FC1 -> FC2 TEST: PASS");

        end

        $display("========================================");

        $finish;

    end

endmodule
