`timescale 1ns/1ps

module tb_fc1_input_mem;

    reg clk;
    reg write_enable;

    reg [9:0] write_addr;
    reg [7:0] write_data;

    reg [9:0] read_addr;
    wire [7:0] read_data;


    // --------------------------------------------------------
    // DUT
    // --------------------------------------------------------

    fc1_input_mem dut (
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
        write_addr = 10'd0;
        write_data = 8'd0;
        read_addr = 10'd0;


        write_enable = 1'b1;

@(posedge clk);
write_addr = 10'd0;
write_data = 8'd10;

@(posedge clk);
write_addr = 10'd1;
write_data = 8'd20;

@(posedge clk);
write_addr = 10'd2;
write_data = 8'd30;

@(posedge clk);
write_addr = 10'd783;
write_data = 8'd255;

@(posedge clk);

write_enable = 1'b0;


        // ----------------------------------------------------
        // Read address 0
        // ----------------------------------------------------

        read_addr = 10'd0;
        #1;

        $display("Address 0   = %0d", read_data);


        // ----------------------------------------------------
        // Read address 1
        // ----------------------------------------------------

        read_addr = 10'd1;
        #1;

        $display("Address 1   = %0d", read_data);


        // ----------------------------------------------------
        // Read address 2
        // ----------------------------------------------------

        read_addr = 10'd2;
        #1;

        $display("Address 2   = %0d", read_data);


        // ----------------------------------------------------
        // Read last address
        // ----------------------------------------------------

        read_addr = 10'd783;
        #1;

        $display("Address 783 = %0d", read_data);


        // ----------------------------------------------------
        // Checks
        // ----------------------------------------------------

        if (read_data == 8'd255)
            $display("Last address check: PASS");
        else
            $display("Last address check: FAIL");


        $display("\nFC1 input memory test complete.");

        $finish;
    end

endmodule
