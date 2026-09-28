`timescale 1ns/1ps

module fc1_mac_lane (
    input  wire        clk,
    input  wire        rst,

    input  wire        enable,
    input  wire        load_bias,

    input  wire [7:0]  input_value,
    input  wire signed [7:0] weight_value,
    input  wire signed [25:0] bias_value,

    output reg signed [25:0] accumulator
);

    // Convert unsigned 8-bit input into a positive signed value.
    wire signed [8:0] input_signed;
    assign input_signed = {1'b0, input_value};

    // Signed product.
    wire signed [16:0] product;
    assign product = input_signed * weight_value;

    always @(posedge clk) begin
        if (rst) begin
            accumulator <= 26'sd0;
        end
        else if (load_bias) begin
            accumulator <= bias_value;
        end
        else if (enable) begin
            // Sign-extend 17-bit product to 26 bits
            // before adding to the accumulator.
            accumulator <= accumulator + {{9{product[16]}}, product};
        end
    end

endmodule
