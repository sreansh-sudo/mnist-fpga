`timescale 1ns/1ps

module fc2_controller (
    input  wire       clk,
    input  wire       rst,
    input  wire       start,

    output reg        load_bias,
    output reg        mac_enable,
    output reg [4:0]  input_addr,
    output reg        done
);

    localparam STATE_IDLE = 2'd0;
    localparam STATE_INIT = 2'd1;
    localparam STATE_MAC  = 2'd2;
    localparam STATE_DONE = 2'd3;

    reg [1:0] state;

    always @(posedge clk) begin

        if (rst) begin

            state      <= STATE_IDLE;
            input_addr <= 5'd0;

        end else begin

            case (state)

                // ------------------------------------------------
                // IDLE
                // ------------------------------------------------
                STATE_IDLE: begin

                    input_addr <= 5'd0;

                    if (start)
                        state <= STATE_INIT;

                end


                // ------------------------------------------------
                // INIT
                //
                // Biases are loaded into all 10 accumulators.
                // ------------------------------------------------
                STATE_INIT: begin

                    input_addr <= 5'd0;
                    state      <= STATE_MAC;

                end


                // ------------------------------------------------
                // MAC
                //
                // One activation/weight index per cycle.
                // Indices 0 through 31.
                // ------------------------------------------------
                STATE_MAC: begin

                    if (input_addr == 5'd31) begin

                        state <= STATE_DONE;

                    end else begin

                        input_addr <= input_addr + 5'd1;

                    end

                end


                // ------------------------------------------------
                // DONE
                // ------------------------------------------------
                STATE_DONE: begin

                    state <= STATE_IDLE;

                end


                default: begin

                    state      <= STATE_IDLE;
                    input_addr <= 5'd0;

                end

            endcase

        end

    end


    // ------------------------------------------------------------
    // Combinational control outputs
    // ------------------------------------------------------------

    always @(*) begin

        load_bias  = 1'b0;
        mac_enable = 1'b0;
        done       = 1'b0;

        case (state)

            STATE_INIT: begin
                load_bias = 1'b1;
            end

            STATE_MAC: begin
                mac_enable = 1'b1;
            end

            STATE_DONE: begin
                done = 1'b1;
            end

            default: begin
                // IDLE
            end

        endcase

    end

endmodule
