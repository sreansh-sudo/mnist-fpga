`timescale 1ns/1ps

module tb_fc2;

    reg clk;
    reg rst;
    reg start;

    // ------------------------------------------------------------
    // Activation memory interface
    // ------------------------------------------------------------

    wire [4:0] activation_addr;
    reg  [7:0] activation_data;

    // ------------------------------------------------------------
    // FC2 outputs
    // ------------------------------------------------------------

    wire [3:0] predicted_digit;
    wire done;

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

    // ------------------------------------------------------------
    // Test activation vector
    //
    // Simple deterministic values.
    // ------------------------------------------------------------

    reg [7:0] test_activation [0:31];

    integer i;

    // ------------------------------------------------------------
    // FC2 DUT
    // ------------------------------------------------------------

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

    // ------------------------------------------------------------
    // Clock
    // ------------------------------------------------------------

    initial begin
        clk = 1'b0;

        forever #5 clk = ~clk;
    end

    // ------------------------------------------------------------
    // Combinational activation memory model
    // ------------------------------------------------------------

    always @(*) begin
        activation_data = test_activation[activation_addr];
    end

    // ------------------------------------------------------------
    // Test
    // ------------------------------------------------------------

    initial begin

        // --------------------------------------------------------
        // Deterministic activation vector
        // --------------------------------------------------------

        test_activation[0]  = 8'd0;
        test_activation[1]  = 8'd1;
        test_activation[2]  = 8'd2;
        test_activation[3]  = 8'd3;
        test_activation[4]  = 8'd4;
        test_activation[5]  = 8'd5;
        test_activation[6]  = 8'd6;
        test_activation[7]  = 8'd7;
        test_activation[8]  = 8'd8;
        test_activation[9]  = 8'd9;
        test_activation[10] = 8'd10;
        test_activation[11] = 8'd11;
        test_activation[12] = 8'd12;
        test_activation[13] = 8'd13;
        test_activation[14] = 8'd14;
        test_activation[15] = 8'd15;
        test_activation[16] = 8'd16;
        test_activation[17] = 8'd17;
        test_activation[18] = 8'd18;
        test_activation[19] = 8'd19;
        test_activation[20] = 8'd20;
        test_activation[21] = 8'd21;
        test_activation[22] = 8'd22;
        test_activation[23] = 8'd23;
        test_activation[24] = 8'd24;
        test_activation[25] = 8'd25;
        test_activation[26] = 8'd26;
        test_activation[27] = 8'd27;
        test_activation[28] = 8'd28;
        test_activation[29] = 8'd29;
        test_activation[30] = 8'd30;
        test_activation[31] = 8'd31;

        // --------------------------------------------------------
        // Initial conditions
        // --------------------------------------------------------

        rst = 1'b1;
        start = 1'b0;

        #12;

        rst = 1'b0;

        // --------------------------------------------------------
        // Start FC2
        // --------------------------------------------------------

        #8;

        start = 1'b1;

        #10;

        start = 1'b0;

        // --------------------------------------------------------
        // Wait for completion
        // --------------------------------------------------------

        wait (done == 1'b1);

        #1;

        // --------------------------------------------------------
        // Display final logits
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

        $display("");
        $display("Predicted digit = %0d", predicted_digit);

        $display("========================================");

        $finish;

    end

endmodule
