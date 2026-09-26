`timescale 1ns/1ps

module tb_fc1_activation_mem;

    reg clk;
    reg write_enable;

    reg [4:0] write_addr;
    reg [7:0] write_data;

    reg [4:0] read_addr;
    wire [7:0] read_data;


    // --------------------------------------------------------
    // DUT
    // --------------------------------------------------------

    fc1_activation_mem dut (
        .clk(clk),
        .write_enable(write_enable),

        .write_addr(write_addr),
        .write_data(write_data),

        .read_addr(read_addr),
        .read_data(read_data)
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

        write_enable = 1'b0;
        write_addr   = 5'd0;
        write_data   = 8'd0;
        read_addr    = 5'd0;


        // ----------------------------------------------------
        // Write activation 10 to address 0
        // ----------------------------------------------------

        @(negedge clk);

        write_enable = 1'b1;
        write_addr   = 5'd0;
        write_data   = 8'd10;

        @(posedge clk);

        #1;

        write_enable = 1'b0;


        // ----------------------------------------------------
        // Write activation 20 to address 7
        // ----------------------------------------------------

        @(negedge clk);

        write_enable = 1'b1;
        write_addr   = 5'd7;
        write_data   = 8'd20;

        @(posedge clk);

        #1;

        write_enable = 1'b0;


        // ----------------------------------------------------
        // Write activation 100 to address 8
        // ----------------------------------------------------

        @(negedge clk);

        write_enable = 1'b1;
        write_addr   = 5'd8;
        write_data   = 8'd100;

        @(posedge clk);

        #1;

        write_enable = 1'b0;


        // ----------------------------------------------------
        // Write activation 200 to address 15
        // ----------------------------------------------------

        @(negedge clk);

        write_enable = 1'b1;
        write_addr   = 5'd15;
        write_data   = 8'd200;

        @(posedge clk);

        #1;

        write_enable = 1'b0;


        // ----------------------------------------------------
        // Write activation 255 to address 31
        // ----------------------------------------------------

        @(negedge clk);

        write_enable = 1'b1;
        write_addr   = 5'd31;
        write_data   = 8'd255;

        @(posedge clk);

        #1;

        write_enable = 1'b0;


        // ----------------------------------------------------
        // Read address 0
        // ----------------------------------------------------

        read_addr = 5'd0;

        #1;

        $display(
            "Address 0  = %0d",
            read_data
        );

        if (read_data != 8'd10) begin
            $display("ERROR: Address 0 mismatch");
            $finish;
        end


        // ----------------------------------------------------
        // Read address 7
        // ----------------------------------------------------

        read_addr = 5'd7;

        #1;

        $display(
            "Address 7  = %0d",
            read_data
        );

        if (read_data != 8'd20) begin
            $display("ERROR: Address 7 mismatch");
            $finish;
        end


        // ----------------------------------------------------
        // Read address 8
        // ----------------------------------------------------

        read_addr = 5'd8;

        #1;

        $display(
            "Address 8  = %0d",
            read_data
        );

        if (read_data != 8'd100) begin
            $display("ERROR: Address 8 mismatch");
            $finish;
        end


        // ----------------------------------------------------
        // Read address 15
        // ----------------------------------------------------

        read_addr = 5'd15;

        #1;

        $display(
            "Address 15 = %0d",
            read_data
        );

        if (read_data != 8'd200) begin
            $display("ERROR: Address 15 mismatch");
            $finish;
        end


        // ----------------------------------------------------
        // Read address 31
        // ----------------------------------------------------

        read_addr = 5'd31;

        #1;

        $display(
            "Address 31 = %0d",
            read_data
        );

        if (read_data != 8'd255) begin
            $display("ERROR: Address 31 mismatch");
            $finish;
        end


        // ----------------------------------------------------
        // Final result
        // ----------------------------------------------------

        $display("\nFC1 activation memory test: PASS");

        $finish;

    end

endmodule
