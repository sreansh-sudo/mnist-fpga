`timescale 1ns/1ps

module argmax10 (
    input wire signed [20:0] logit0,
    input wire signed [20:0] logit1,
    input wire signed [20:0] logit2,
    input wire signed [20:0] logit3,
    input wire signed [20:0] logit4,
    input wire signed [20:0] logit5,
    input wire signed [20:0] logit6,
    input wire signed [20:0] logit7,
    input wire signed [20:0] logit8,
    input wire signed [20:0] logit9,

    output reg [3:0] predicted_digit
);

    reg signed [20:0] max_value;
    reg [3:0] max_index;

    always @(*) begin

        // Start with neuron 0.
        max_value = logit0;
        max_index = 4'd0;

        if (logit1 > max_value) begin
            max_value = logit1;
            max_index = 4'd1;
        end

        if (logit2 > max_value) begin
            max_value = logit2;
            max_index = 4'd2;
        end

        if (logit3 > max_value) begin
            max_value = logit3;
            max_index = 4'd3;
        end

        if (logit4 > max_value) begin
            max_value = logit4;
            max_index = 4'd4;
        end

        if (logit5 > max_value) begin
            max_value = logit5;
            max_index = 4'd5;
        end

        if (logit6 > max_value) begin
            max_value = logit6;
            max_index = 4'd6;
        end

        if (logit7 > max_value) begin
            max_value = logit7;
            max_index = 4'd7;
        end

        if (logit8 > max_value) begin
            max_value = logit8;
            max_index = 4'd8;
        end

        if (logit9 > max_value) begin
            max_value = logit9;
            max_index = 4'd9;
        end

        predicted_digit = max_index;

    end

endmodule
