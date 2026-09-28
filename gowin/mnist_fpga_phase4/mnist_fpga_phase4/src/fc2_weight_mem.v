`timescale 1ns/1ps

module fc2_weight_mem (
    input  wire [4:0] addr,

    output wire signed [7:0] weight0,
    output wire signed [7:0] weight1,
    output wire signed [7:0] weight2,
    output wire signed [7:0] weight3,
    output wire signed [7:0] weight4,
    output wire signed [7:0] weight5,
    output wire signed [7:0] weight6,
    output wire signed [7:0] weight7,
    output wire signed [7:0] weight8,
    output wire signed [7:0] weight9
);

    reg signed [7:0] bank0 [0:31];
    reg signed [7:0] bank1 [0:31];
    reg signed [7:0] bank2 [0:31];
    reg signed [7:0] bank3 [0:31];
    reg signed [7:0] bank4 [0:31];
    reg signed [7:0] bank5 [0:31];
    reg signed [7:0] bank6 [0:31];
    reg signed [7:0] bank7 [0:31];
    reg signed [7:0] bank8 [0:31];
    reg signed [7:0] bank9 [0:31];

    initial begin
        $readmemh("data/fc2_bank0.mem", bank0);
        $readmemh("data/fc2_bank1.mem", bank1);
        $readmemh("data/fc2_bank2.mem", bank2);
        $readmemh("data/fc2_bank3.mem", bank3);
        $readmemh("data/fc2_bank4.mem", bank4);
        $readmemh("data/fc2_bank5.mem", bank5);
        $readmemh("data/fc2_bank6.mem", bank6);
        $readmemh("data/fc2_bank7.mem", bank7);
        $readmemh("data/fc2_bank8.mem", bank8);
        $readmemh("data/fc2_bank9.mem", bank9);
    end

    assign weight0 = bank0[addr];
    assign weight1 = bank1[addr];
    assign weight2 = bank2[addr];
    assign weight3 = bank3[addr];
    assign weight4 = bank4[addr];
    assign weight5 = bank5[addr];
    assign weight6 = bank6[addr];
    assign weight7 = bank7[addr];
    assign weight8 = bank8[addr];
    assign weight9 = bank9[addr];

endmodule
