`timescale 1ns/1ps

module fc2_mac10 (
    input  wire                  clk,
    input  wire                  rst,

    input  wire                  load_bias,
    input  wire                  mac_enable,

    input  wire [7:0]            activation,

    input  wire signed [7:0]     weight [0:9],
    input  wire signed [20:0]    bias [0:9],

    output wire signed [20:0]    accumulator [0:9]
);

    genvar i;

    generate
        for (i = 0; i < 10; i = i + 1) begin : GEN_MAC_LANES

            fc2_mac_lane lane (
                .clk(clk),
                .rst(rst),

                .load_bias(load_bias),
                .mac_enable(mac_enable),

                .activation(activation),
                .weight(weight[i]),
                .bias(bias[i]),

                .accumulator(accumulator[i])
            );

        end
    endgenerate

endmodule
