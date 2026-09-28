`timescale 1ns/1ps

module fc2_mac_lane (
    input  wire              clk,
    input  wire              rst,

    input  wire              load_bias,
    input  wire              mac_enable,

    input  wire [7:0]        activation,
    input  wire signed [7:0] weight,
    input  wire signed [20:0] bias,

    output reg signed [20:0] accumulator
);

    // FC1 activation is unsigned INT8.
    // Zero-extend to 9-bit signed so values 128..255
    // are not interpreted as negative numbers.
    wire signed [8:0] activation_ext;
    assign activation_ext = {1'b0, activation};

    // 9-bit signed activation × 8-bit signed weight
    // gives a signed 16-bit product for the required range.
    wire signed [15:0] product;
    assign product = activation_ext * weight;

    // Sign-extend the product to the 21-bit accumulator width.
    wire signed [20:0] product_ext;
    assign product_ext = {{5{product[15]}}, product};

    always @(posedge clk) begin
        if (rst) begin
            accumulator <= 21'sd0;
        end
        else if (load_bias) begin
            accumulator <= bias;
        end
        else if (mac_enable) begin
            accumulator <= accumulator + product_ext;
        end
    end

endmodule
