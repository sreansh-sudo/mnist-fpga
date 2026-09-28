`timescale 1ns/1ps

module fc1_weight_mem_bram_top (
    input  wire        clk,
    input  wire [11:0] addr,

    output wire signed [7:0] weight0,
    output wire signed [7:0] weight1,
    output wire signed [7:0] weight2,
    output wire signed [7:0] weight3,
    output wire signed [7:0] weight4,
    output wire signed [7:0] weight5,
    output wire signed [7:0] weight6,
    output wire signed [7:0] weight7
);

    fc1_weight_mem_bram mem (
        .clk(clk),
        .addr(addr),

        .weight0(weight0),
        .weight1(weight1),
        .weight2(weight2),
        .weight3(weight3),
        .weight4(weight4),
        .weight5(weight5),
        .weight6(weight6),
        .weight7(weight7)
    );

endmodule
