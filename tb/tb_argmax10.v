`timescale 1ns/1ps

module tb_argmax10;

    reg signed [20:0] logit0;
    reg signed [20:0] logit1;
    reg signed [20:0] logit2;
    reg signed [20:0] logit3;
    reg signed [20:0] logit4;
    reg signed [20:0] logit5;
    reg signed [20:0] logit6;
    reg signed [20:0] logit7;
    reg signed [20:0] logit8;
    reg signed [20:0] logit9;

    wire [3:0] predicted_digit;

    argmax10 dut (
        .logit0(logit0),
        .logit1(logit1),
        .logit2(logit2),
        .logit3(logit3),
        .logit4(logit4),
        .logit5(logit5),
        .logit6(logit6),
        .logit7(logit7),
        .logit8(logit8),
        .logit9(logit9),
        .predicted_digit(predicted_digit)
    );


    task check_prediction;

        input [3:0] expected;
        input [255:0] test_name;

        begin

            #1;

            if (predicted_digit !== expected) begin

                $display(
                    "FAIL: %0s | expected digit %0d, got %0d",
                    test_name,
                    expected,
                    predicted_digit
                );

                $finish;

            end

            $display(
                "PASS: %0s | predicted digit = %0d",
                test_name,
                predicted_digit
            );

        end

    endtask


    initial begin

        // --------------------------------------------------------
        // Test 1: digit 0 wins
        // --------------------------------------------------------

        logit0 = 21'sd100;
        logit1 = 21'sd20;
        logit2 = -21'sd50;
        logit3 = 21'sd30;
        logit4 = 21'sd10;
        logit5 = -21'sd10;
        logit6 = 21'sd40;
        logit7 = 21'sd5;
        logit8 = 21'sd60;
        logit9 = 21'sd80;

        check_prediction(4'd0, "digit 0 maximum");


        // --------------------------------------------------------
        // Test 2: digit 7 wins
        // --------------------------------------------------------

        logit0 = -21'sd100;
        logit1 = 21'sd20;
        logit2 = 21'sd30;
        logit3 = 21'sd40;
        logit4 = 21'sd50;
        logit5 = 21'sd60;
        logit6 = 21'sd70;
        logit7 = 21'sd900;
        logit8 = 21'sd80;
        logit9 = 21'sd90;

        check_prediction(4'd7, "digit 7 maximum");


        // --------------------------------------------------------
        // Test 3: negative logits
        // --------------------------------------------------------

        logit0 = -21'sd100;
        logit1 = -21'sd200;
        logit2 = -21'sd50;
        logit3 = -21'sd300;
        logit4 = -21'sd150;
        logit5 = -21'sd75;
        logit6 = -21'sd500;
        logit7 = -21'sd80;
        logit8 = -21'sd90;
        logit9 = -21'sd120;

        check_prediction(4'd2, "negative logits");


        // --------------------------------------------------------
        // Test 4: tie
        //
        // Digit 2 and digit 5 both equal 500.
        // Lower index must win.
        // --------------------------------------------------------

        logit0 = 21'sd10;
        logit1 = 21'sd20;
        logit2 = 21'sd500;
        logit3 = 21'sd100;
        logit4 = 21'sd200;
        logit5 = 21'sd500;
        logit6 = 21'sd50;
        logit7 = 21'sd300;
        logit8 = 21'sd400;
        logit9 = 21'sd250;

        check_prediction(4'd2, "tie chooses lower index");


        // --------------------------------------------------------
        // Test 5: digit 9 wins
        // --------------------------------------------------------

        logit0 = 21'sd1;
        logit1 = 21'sd2;
        logit2 = 21'sd3;
        logit3 = 21'sd4;
        logit4 = 21'sd5;
        logit5 = 21'sd6;
        logit6 = 21'sd7;
        logit7 = 21'sd8;
        logit8 = 21'sd9;
        logit9 = 21'sd1000;

        check_prediction(4'd9, "digit 9 maximum");


        $display("========================================");
        $display("ARGMAX10 TEST: PASS");
        $display("========================================");

        $finish;

    end

endmodule
