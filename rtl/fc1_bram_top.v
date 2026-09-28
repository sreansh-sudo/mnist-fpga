`timescale 1ns/1ps

module fc1_bram_top (
    input wire        clk,
    input wire        rst,
    input wire        start,

    // --------------------------------------------------------
    // Input memory write interface
    // --------------------------------------------------------

    input wire        input_write_enable,
    input wire [9:0]  input_write_addr,
    input wire [7:0]  input_write_data,

    // --------------------------------------------------------
    // FC1 status
    // --------------------------------------------------------

    output wire done,

    // --------------------------------------------------------
    // Activation memory read interface
    // --------------------------------------------------------

    input wire [4:0] activation_read_addr,
    output wire [7:0] activation_read_data,

    // --------------------------------------------------------
    // Synthesis observability
    // --------------------------------------------------------

    output wire [7:0] debug_activation0,
    output wire [7:0] debug_activation1,
    output wire [7:0] debug_activation2,
    output wire [7:0] debug_activation3,
    output wire [7:0] debug_activation4,
    output wire [7:0] debug_activation5,
    output wire [7:0] debug_activation6,
    output wire [7:0] debug_activation7
);

    // --------------------------------------------------------
    // BRAM-based FC1
    // --------------------------------------------------------

    fc1_bram dut (
        .clk(clk),
        .rst(rst),
        .start(start),

        .input_write_enable(input_write_enable),
        .input_write_addr(input_write_addr),
        .input_write_data(input_write_data),

        .done(done),

        .activation_read_addr(activation_read_addr),
        .activation_read_data(activation_read_data),

        .debug_activation0(debug_activation0),
        .debug_activation1(debug_activation1),
        .debug_activation2(debug_activation2),
        .debug_activation3(debug_activation3),
        .debug_activation4(debug_activation4),
        .debug_activation5(debug_activation5),
        .debug_activation6(debug_activation6),
        .debug_activation7(debug_activation7)
    );

endmodule
