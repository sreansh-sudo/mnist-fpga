`timescale 1ns/1ps

module fc1_activation_mem (
    input wire       clk,
    input wire       write_enable,

    input wire [4:0] write_addr,
    input wire [7:0] write_data,

    input wire [4:0] read_addr,
    output wire [7:0] read_data
);

    // 32 activations × 8 bits
    reg [7:0] memory [0:31];


    // --------------------------------------------------------
    // Write
    // --------------------------------------------------------

    always @(posedge clk) begin

        if (write_enable) begin
            memory[write_addr] <= write_data;
        end

    end


    // --------------------------------------------------------
    // Asynchronous read
    // --------------------------------------------------------

    assign read_data = memory[read_addr];

endmodule
