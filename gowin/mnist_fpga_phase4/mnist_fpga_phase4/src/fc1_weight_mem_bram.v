`timescale 1ns/1ps

module fc1_weight_mem_bram (
    input wire        clk,
    input wire [11:0] addr,

    output wire signed [7:0] weight0,
    output wire signed [7:0] weight1,
    output wire signed [7:0] weight2,
    output wire signed [7:0] weight3,
    output wire signed [7:0] weight4,
    output wire signed [7:0] weight5,
    output wire signed [7:0] weight6,
    output wire signed [7:0] weight7
);

    // ============================================================
    // 3136 x 64-bit packed FC1 weight memory
    //
    // Each address contains 8 weights:
    //
    // [ 7: 0]  = bank0
    // [15: 8]  = bank1
    // [23:16]  = bank2
    // [31:24]  = bank3
    // [39:32]  = bank4
    // [47:40]  = bank5
    // [55:48]  = bank6
    // [63:56]  = bank7
    // ============================================================

    reg [63:0] memory [0:3135];

    reg [63:0] read_data;

    // ============================================================
    // Initialize memory from packed .mem file
    // ============================================================

    initial begin
        $readmemh("data/fc1_bram.mem", memory);
    end

    // ============================================================
    // Synchronous read
    // ============================================================

    always @(posedge clk) begin
        read_data <= memory[addr];
    end

    // ============================================================
    // Unpack the 64-bit word into 8 signed weights
    // ============================================================

    assign weight0 = read_data[7:0];
    assign weight1 = read_data[15:8];
    assign weight2 = read_data[23:16];
    assign weight3 = read_data[31:24];

    assign weight4 = read_data[39:32];
    assign weight5 = read_data[47:40];
    assign weight6 = read_data[55:48];
    assign weight7 = read_data[63:56];

endmodule
