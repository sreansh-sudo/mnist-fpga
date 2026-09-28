`timescale 1ns/1ps

module fc1_controller_bram (
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
                //
                // Important for synchronous BRAM:
                //
                // current_input = 0
                // weight_addr = group * 784 + 0
                //
                // At this clock edge the BRAM loads weight 0.
                // At the same edge the MAC loads its bias.
                //
                // The first MAC operation happens on the
                // following clock edge.
                // ------------------------------------------------

                STATE_INIT: begin

                    current_input <= 10'd0;
                    store_index   <= 3'd0;

                    state <= STATE_MAC;

                end


                // ------------------------------------------------
                // MAC
                //
                // The BRAM has one-cycle read latency.
                //
                // Therefore:
                //
                // MAC uses weight[current_input]
                //
                // while BRAM is simultaneously loading:
                //
                // weight[current_input + 1]
                //
                // for the next MAC cycle.
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

        input_addr = current_input;

        bias_group = current_group;


        // ----------------------------------------------------
        // Synchronous BRAM address pipeline
        //
        // INIT:
        //     request current weight
        //
        // MAC:
        //     request NEXT weight
        //
        // Therefore the registered BRAM output corresponds
        // to the current MAC input.
        // ----------------------------------------------------

        if ((state == STATE_MAC) &&
            (current_input != 10'd783)) begin

            weight_addr =
                (current_group * 12'd784) +
                {2'b00, current_input + 10'd1};

        end

        else begin

            weight_addr =
                (current_group * 12'd784) +
                {2'b00, current_input};

        end


        // ----------------------------------------------------
        // Default controls
        // ----------------------------------------------------

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
