`timescale 1ns/1ps

module tb_fc1_bram4;

    reg clk;
    reg rst;
    reg start;

    reg        input_write_enable;
    reg [9:0]  input_write_addr;
    reg [7:0]  input_write_data;

    wire done;

    // fc1_bram4 has a 5-bit activation address: 0..31
    reg  [4:0] activation_read_addr;
    wire [7:0] activation_read_data;

    integer i;
    integer errors;
    integer cycle_count;

    reg [7:0] expected [0:31];

    fc1_bram4 dut (
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

    always #5 clk = ~clk;

    initial begin
        clk = 0;
        rst = 1;
        start = 0;

        input_write_enable = 0;
        input_write_addr = 0;
        input_write_data = 0;
        activation_read_addr = 0;

        errors = 0;

        // Expected FC1 activations for MNIST image #0
        expected[0]  = 8'd0;
        expected[1]  = 8'd33;
        expected[2]  = 8'd21;
        expected[3]  = 8'd0;
        expected[4]  = 8'd0;
        expected[5]  = 8'd41;
        expected[6]  = 8'd37;
        expected[7]  = 8'd46;
        expected[8]  = 8'd40;
        expected[9]  = 8'd40;
        expected[10] = 8'd14;
        expected[11] = 8'd0;
        expected[12] = 8'd42;
        expected[13] = 8'd21;
        expected[14] = 8'd27;
        expected[15] = 8'd7;
        expected[16] = 8'd34;
        expected[17] = 8'd39;
        expected[18] = 8'd0;
        expected[19] = 8'd34;
        expected[20] = 8'd31;
        expected[21] = 8'd17;
        expected[22] = 8'd5;
        expected[23] = 8'd0;
        expected[24] = 8'd2;
        expected[25] = 8'd1;
        expected[26] = 8'd25;
        expected[27] = 8'd0;
        expected[28] = 8'd24;
        expected[29] = 8'd0;
        expected[30] = 8'd0;
        expected[31] = 8'd3;

        // Reset
        repeat (5) @(posedge clk);
        rst = 0;

        // Load the known test image into the DUT input memory.
        $readmemh("data/test_input.mem", dut.input_memory.memory);

        // Start FC1
@(posedge clk);
start = 1;
cycle_count = 0;

@(posedge clk);
start = 0;

// Count FC1 cycles until completion
while (!done) begin
    @(posedge clk);
    cycle_count = cycle_count + 1;
end

$display("FC1 4-LANE LATENCY = %0d cycles", cycle_count);
$display("FC1 4-LANE LATENCY @ 100 MHz = %0.2f us",
         cycle_count * 0.01);

        $display("");
        $display("========================================");
        $display("FC1 4-LANE FUNCTIONAL TEST");
        $display("========================================");

        // Check all 32 activation outputs.
        for (i = 0; i < 32; i = i + 1) begin
            activation_read_addr = i[4:0];

            // Activation memory is synchronous, so allow a clock.
            @(posedge clk);
            #1;

            if (activation_read_data !== expected[i]) begin
                $display(
                    "FAIL activation[%0d]: expected %0d, got %0d",
                    i,
                    expected[i],
                    activation_read_data
                );
                errors = errors + 1;
            end
            else begin
                $display(
                    "PASS activation[%0d] = %0d",
                    i,
                    activation_read_data
                );
            end
        end

        $display("");
        $display("========================================");

        if (errors == 0)
            $display("FC1 4-LANE TEST PASS");
        else
            $display("FC1 4-LANE TEST FAIL: %0d errors", errors);

        $display("========================================");

        #20;
        $finish;
    end

endmodule
