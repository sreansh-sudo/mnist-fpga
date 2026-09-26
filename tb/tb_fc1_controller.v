`timescale 1ns/1ps

module tb_fc1_controller;

    reg clk;
    reg rst;
    reg start;

    wire [9:0] input_addr;
    wire [11:0] weight_addr;
    wire [1:0] bias_group;

    wire load_bias;
    wire mac_enable;
    wire requant_enable;
    wire store_enable;
    wire [2:0] store_index;
    wire done;

    wire [1:0] current_group;
    wire [9:0] current_input;


    // --------------------------------------------------------
    // DUT
    // --------------------------------------------------------

    fc1_controller dut (
        .clk(clk),
        .rst(rst),
        .start(start),

        .input_addr(input_addr),
        .weight_addr(weight_addr),

        .bias_group(bias_group),

        .load_bias(load_bias),
        .mac_enable(mac_enable),

        .requant_enable(requant_enable),
        .store_enable(store_enable),
        .store_index(store_index),

        .done(done),

        .current_group(current_group),
        .current_input(current_input)
    );


    // --------------------------------------------------------
    // Clock
    // --------------------------------------------------------

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end


    // --------------------------------------------------------
    // Test
    // --------------------------------------------------------

    initial begin

        rst   = 1'b1;
        start = 1'b0;

        #12;

        rst = 1'b0;


        // ----------------------------------------------------
        // Start FC1
        // ----------------------------------------------------

        @(posedge clk);
        start = 1'b1;

        @(posedge clk);
        start = 1'b0;


        // ----------------------------------------------------
        // Monitor controller
        // ----------------------------------------------------

        forever begin

            @(posedge clk);


            // ------------------------------------------------
            // Bias initialization
            // ------------------------------------------------

            if (load_bias) begin

                $display(
                    "INIT:    group=%0d input=%0d weight_addr=%0d",
                    current_group,
                    current_input,
                    weight_addr
                );

            end


            // ------------------------------------------------
            // MAC
            // ------------------------------------------------

            if (mac_enable) begin

                if ((current_input == 10'd0) ||
                    (current_input == 10'd1) ||
                    (current_input == 10'd782) ||
                    (current_input == 10'd783)) begin

                    $display(
                        "MAC:     group=%0d input=%0d input_addr=%0d weight_addr=%0d",
                        current_group,
                        current_input,
                        input_addr,
                        weight_addr
                    );

                end

            end


            // ------------------------------------------------
            // Requantization
            // ------------------------------------------------

            if (requant_enable) begin

                $display(
                    "REQUANT: group=%0d",
                    current_group
                );

            end


            // ------------------------------------------------
            // Store
            // ------------------------------------------------

            if (store_enable) begin

                $display(
                    "STORE:   group=%0d store_index=%0d",
                    current_group,
                    store_index
                );

            end


            // ------------------------------------------------
            // Done
            // ------------------------------------------------

            if (done) begin

                $display(
                    "DONE:    group=%0d input=%0d",
                    current_group,
                    current_input
                );

                break;

            end

        end


        $display("\nFC1 controller test complete.");

        $finish;

    end

endmodule
