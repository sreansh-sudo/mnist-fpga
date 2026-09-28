`timescale 1ns/1ps

module fc1_controller (
    input wire clk,
    input wire rst,
    input wire start,

    // Input memory
    output reg [9:0] input_addr,

    // Weight memory
    output reg [11:0] weight_addr,

    // Bias memory
    output reg [1:0] bias_group,

    // MAC control
    output reg load_bias,
    output reg mac_enable,

    // Requantization / storage control
    output reg requant_enable,
    output reg store_enable,

    // Activation memory write index
    output reg [2:0] store_index,

    // Status
    output reg done,

    // Debug / current operation
    output reg [1:0] current_group,
    output reg [9:0] current_input
);


    // --------------------------------------------------------
    // FSM states
    // --------------------------------------------------------

    localparam STATE_IDLE    = 3'd0;
    localparam STATE_INIT    = 3'd1;
    localparam STATE_MAC     = 3'd2;
    localparam STATE_DRAIN   = 3'd3;
    localparam STATE_REQUANT = 3'd4;
    localparam STATE_STORE   = 3'd5;
    localparam STATE_NEXT    = 3'd6;
    localparam STATE_DONE    = 3'd7;


    reg [2:0] state;


    // --------------------------------------------------------
    // Sequential logic
    // --------------------------------------------------------

    always @(posedge clk) begin

        if (rst) begin

            state         <= STATE_IDLE;

            current_group <= 2'd0;
            current_input <= 10'd0;

            store_index   <= 3'd0;

        end

        else begin

            case (state)

                // ------------------------------------------------
                // IDLE
                // ------------------------------------------------

                STATE_IDLE: begin

                    if (start) begin

                        current_group <= 2'd0;
                        current_input <= 10'd0;
                        store_index   <= 3'd0;

                        state <= STATE_INIT;

                    end

                end


                // ------------------------------------------------
                // INIT
                // ------------------------------------------------

                STATE_INIT: begin

                    current_input <= 10'd0;
                    store_index   <= 3'd0;

                    state <= STATE_MAC;

                end


                // ------------------------------------------------
                // MAC
                // ------------------------------------------------

                STATE_MAC: begin

                    if (current_input == 10'd783) begin

                        state <= STATE_DRAIN;

                    end

                    else begin

                        current_input <= current_input + 10'd1;

                    end

                end


                // ------------------------------------------------
                // DRAIN
                // ------------------------------------------------

                STATE_DRAIN: begin

                    state <= STATE_REQUANT;

                end


                // ------------------------------------------------
                // REQUANT
                // ------------------------------------------------

                STATE_REQUANT: begin

                    state <= STATE_STORE;

                    store_index <= 3'd0;

                end


                // ------------------------------------------------
                // STORE
                //
                // One activation per clock.
                // ------------------------------------------------

                STATE_STORE: begin

                    if (store_index == 3'd7) begin

                        state <= STATE_NEXT;

                    end

                    else begin

                        store_index <= store_index + 3'd1;

                    end

                end


                // ------------------------------------------------
                // NEXT GROUP
                // ------------------------------------------------

                STATE_NEXT: begin

                    if (current_group == 2'd3) begin

                        state <= STATE_DONE;

                    end

                    else begin

                        current_group <= current_group + 2'd1;
                        current_input <= 10'd0;
                        store_index   <= 3'd0;

                        state <= STATE_INIT;

                    end

                end


                // ------------------------------------------------
                // DONE
                // ------------------------------------------------

                STATE_DONE: begin

                    if (!start) begin
                        state <= STATE_IDLE;
                    end

                end


                default: begin

                    state <= STATE_IDLE;

                end

            endcase

        end

    end


    // --------------------------------------------------------
    // Combinational outputs
    // --------------------------------------------------------

    always @(*) begin

        // Address outputs

        input_addr = current_input;

        bias_group = current_group;

        weight_addr =
            (current_group * 12'd784) +
            {2'b00, current_input};


        // Default controls

        load_bias      = 1'b0;
        mac_enable     = 1'b0;
        requant_enable = 1'b0;
        store_enable   = 1'b0;
        done           = 1'b0;


        case (state)

            STATE_INIT: begin

                load_bias = 1'b1;

            end


            STATE_MAC: begin

                mac_enable = 1'b1;

            end


            STATE_REQUANT: begin

                requant_enable = 1'b1;

            end


            STATE_STORE: begin

                store_enable = 1'b1;

            end


            STATE_DONE: begin

                done = 1'b1;

            end


            default: begin

            end

        endcase

    end

endmodule
