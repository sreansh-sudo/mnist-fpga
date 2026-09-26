`timescale 1ns/1ps

module fc1_input_mem (
    input  wire        clk,
    input  wire        write_enable,

    input  wire [9:0]  write_addr,
    input  wire [7:0]  write_data,

    input  wire [9:0]  read_addr,
    output wire [7:0]  read_data
);

    // --------------------------------------------------------
    // MNIST input buffer
    //
    // 784 pixels
    // 8 bits per pixel
    //
    // Address:
    //   0   -> pixel 0
    //   783 -> pixel 783
    // --------------------------------------------------------

    reg [7:0] memory [0:783];


    // --------------------------------------------------------
    // Write port
    // --------------------------------------------------------

    always @(posedge clk) begin
        if (write_enable) begin
            memory[write_addr] <= write_data;
        end
    end


    // --------------------------------------------------------
    // Read port
    //
    // Combinational read:
    // read_data immediately reflects memory[read_addr]
    // --------------------------------------------------------

    assign read_data = memory[read_addr];

endmodule
