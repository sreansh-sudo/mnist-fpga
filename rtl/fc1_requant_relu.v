`timescale 1ns/1ps

module fc1_requant_relu (
    input  wire signed [25:0] accumulator,

    output reg [7:0] activation
);

    reg signed [26:0] rounded_value;

    always @(*) begin

        // ----------------------------------------------------
        // Default output
        // ----------------------------------------------------

        activation = 8'd0;
        rounded_value = 27'sd0;


        // ----------------------------------------------------
        // ReLU
        //
        // Any negative accumulator becomes zero.
        // ----------------------------------------------------

        if (accumulator < 0) begin

            activation = 8'd0;

        end


        // ----------------------------------------------------
        // Positive accumulator
        //
        // Accumulator scale = 8192
        // Activation scale  = 8
        //
        // 8192 / 8 = 1024 = 2^10
        //
        // Add 512 before shifting for round-to-nearest.
        // ----------------------------------------------------

        else begin

            rounded_value =
                (accumulator + 26'sd512) >>> 10;


            // ------------------------------------------------
            // INT8 saturation
            // ------------------------------------------------

            if (rounded_value > 27'sd255)
                activation = 8'd255;
            else
                activation = rounded_value[7:0];

        end

    end

endmodule
