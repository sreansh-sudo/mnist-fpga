`timescale 1ns/1ps

module tb_fc1;

    reg clk;
    reg rst;
    reg start;

    // Input loading interface
    reg        input_write_enable;
    reg [9:0]  input_write_addr;
    reg [7:0]  input_write_data;

    // FC1 completion
    wire done;

    // Activation read interface
    reg  [4:0] activation_read_addr;
    wire [7:0] activation_read_data;

    // ----------------------------------------------------
    // DUT
    // ----------------------------------------------------

    fc1 dut (
        .clk(clk),
        .rst(rst),
        .start(start),

        .input_write_enable(input_write_enable),
        .input_write_addr(input_write_addr),
        .input_write_data(input_write_data),

        .done(done),

        .activation_read_addr(activation_read_addr),
        .activation_read_data(activation_read_data)
    );

    // ----------------------------------------------------
    // Clock
    // ----------------------------------------------------

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    // ----------------------------------------------------
    // Test data
    // ----------------------------------------------------

    reg [7:0] expected_activation [0:31];

    // ----------------------------------------------------
    // Variables
    // ----------------------------------------------------

    integer i;
    integer pass_count;
    integer fail_count;
    integer cycle_count;

    // ----------------------------------------------------
    // Main test
    // ----------------------------------------------------

    initial begin

        // Initial values
        rst = 1'b1;
        start = 1'b0;

        input_write_enable = 1'b0;
        input_write_addr = 10'd0;
        input_write_data = 8'd0;

        activation_read_addr = 5'd0;

        pass_count = 0;
        fail_count = 0;
        cycle_count = 0;

        // Load expected FC1 activations
        $readmemh(
            "data/fc1_expected_activation.mem",
            expected_activation
        );

        // ------------------------------------------------
        // Reset
        // ------------------------------------------------

        #12;

        rst = 1'b0;

        // ------------------------------------------------
        // Load 784 quantized MNIST pixels into input memory
        // ------------------------------------------------

        $display("");
        $display("========================================");
        $display("LOADING MNIST INPUT");
        $display("========================================");

        for (i = 0; i < 784; i = i + 1) begin

            input_write_addr   = i[9:0];
            input_write_data   = 8'd0;
            input_write_enable = 1'b1;

            // Read the actual generated memory file
            // directly into the write data for this test.
            //
            // This temporary array is declared below.
            input_write_data = test_input[i];

            @(posedge clk);

        end

        input_write_enable = 1'b0;

        $display("Loaded 784 input pixels.");

        // ------------------------------------------------
        // Start FC1
        // ------------------------------------------------

        @(posedge clk);

        start = 1'b1;

        @(posedge clk);

        start = 1'b0;

        $display("");
        $display("========================================");
        $display("STARTING FC1");
        $display("========================================");

        // ------------------------------------------------
        // Wait for FC1 to finish
        // ------------------------------------------------

        while (!done) begin

            @(posedge clk);

            cycle_count = cycle_count + 1;

        end

        $display("FC1 DONE.");
        $display("Measured FC1 cycles: %0d", cycle_count);

        // ------------------------------------------------
        // Check all 32 activations
        // ------------------------------------------------

        $display("");
        $display("========================================");
        $display("CHECKING FC1 ACTIVATIONS");
        $display("========================================");

        for (i = 0; i < 32; i = i + 1) begin

            activation_read_addr = i[4:0];

            // Allow combinational read to settle
            #1;

            if (activation_read_data === expected_activation[i]) begin

                $display(
                    "Activation %2d: RTL=%3d EXPECTED=%3d PASS",
                    i,
                    activation_read_data,
                    expected_activation[i]
                );

                pass_count = pass_count + 1;

            end
            else begin

                $display(
                    "Activation %2d: RTL=%3d EXPECTED=%3d FAIL",
                    i,
                    activation_read_data,
                    expected_activation[i]
                );

                fail_count = fail_count + 1;

            end

        end

        // ------------------------------------------------
        // Final result
        // ------------------------------------------------

        $display("");
        $display("========================================");
        $display("FC1 END-TO-END RESULT");
        $display("========================================");

        $display("Passed: %0d / 32", pass_count);
        $display("Failed: %0d / 32", fail_count);
        $display("Cycles: %0d", cycle_count);

        if (fail_count == 0) begin
            $display("");
            $display("FC1 END-TO-END TEST: PASS");
        end
        else begin
            $display("");
            $display("FC1 END-TO-END TEST: FAIL");
        end

        $display("");

        $finish;

    end

    // ----------------------------------------------------
    // Test input memory
    // ----------------------------------------------------

    reg [7:0] test_input [0:783];

    initial begin
        $readmemh(
            "data/test_input.mem",
            test_input
        );
    end

endmodule
