`timescale 1ns/1ps

module mnist_top (
    input wire clk,
    input wire rst,
    input wire start,

    // --------------------------------------------------------
    // MNIST input loading interface
    // --------------------------------------------------------

    input wire       input_write_enable,
    input wire [9:0] input_write_addr,
    input wire [7:0] input_write_data,

    // --------------------------------------------------------
    // Final result
    // --------------------------------------------------------

    output wire       done,
    output wire [3:0] predicted_digit,

    // --------------------------------------------------------
    // Final FC2 logits
    // --------------------------------------------------------

    output wire signed [20:0] logit0,
    output wire signed [20:0] logit1,
    output wire signed [20:0] logit2,
    output wire signed [20:0] logit3,
    output wire signed [20:0] logit4,
    output wire signed [20:0] logit5,
    output wire signed [20:0] logit6,
    output wire signed [20:0] logit7,
    output wire signed [20:0] logit8,
    output wire signed [20:0] logit9
);

    // ========================================================
    // Top-level FSM
    // ========================================================

    localparam STATE_IDLE = 2'd0;
    localparam STATE_FC1  = 2'd1;
    localparam STATE_FC2  = 2'd2;
    localparam STATE_DONE = 2'd3;

    reg [1:0] state;

    // One-cycle start pulses for FC1 and FC2
    reg fc1_start;
    reg fc2_start;

    wire fc1_done;
    wire fc2_done;

    // ========================================================
    // FC1 activation-memory read interface
    // ========================================================

    wire [4:0] fc1_activation_read_addr;
    wire [7:0] fc1_activation_read_data;

    // ========================================================
    // FC2 activation interface
    // ========================================================

    wire [4:0] fc2_activation_addr;
    wire [7:0] fc2_activation_data;

    // FC2 result
    wire [3:0] fc2_predicted_digit;

    // ========================================================
    // Connect FC2 activation address to FC1 activation memory
    // ========================================================

    assign fc1_activation_read_addr = fc2_activation_addr;
    assign fc2_activation_data      = fc1_activation_read_data;

    // ========================================================
    // Top-level outputs
    // ========================================================

    assign predicted_digit = fc2_predicted_digit;

    assign done = (state == STATE_DONE);

    // ========================================================
    // FC1
    // ========================================================

    fc1 fc1_inst (
        .clk(clk),
        .rst(rst),
        .start(fc1_start),

        .input_write_enable(input_write_enable),
        .input_write_addr(input_write_addr),
        .input_write_data(input_write_data),

        .done(fc1_done),

        .activation_read_addr(fc1_activation_read_addr),
        .activation_read_data(fc1_activation_read_data)
    );

    // ========================================================
    // FC2
    // ========================================================

    fc2 fc2_inst (
        .clk(clk),
        .rst(rst),
        .start(fc2_start),

        .activation_addr(fc2_activation_addr),
        .activation_data(fc2_activation_data),

        .predicted_digit(fc2_predicted_digit),
        .done(fc2_done),

        .logit0(logit0),
        .logit1(logit1),
        .logit2(logit2),
        .logit3(logit3),
        .logit4(logit4),
        .logit5(logit5),
        .logit6(logit6),
        .logit7(logit7),
        .logit8(logit8),
        .logit9(logit9)
    );

    // ========================================================
    // Top-level control FSM
    // ========================================================

    always @(posedge clk) begin

        if (rst) begin
            state    <= STATE_IDLE;
            fc1_start <= 1'b0;
            fc2_start <= 1'b0;
        end

        else begin

            // Start pulses are one clock wide.
            fc1_start <= 1'b0;
            fc2_start <= 1'b0;

            case (state)

                // ------------------------------------------------
                // Wait for external start request
                // ------------------------------------------------

                STATE_IDLE: begin

                    if (start) begin
                        fc1_start <= 1'b1;
                        state <= STATE_FC1;
                    end

                end

                // ------------------------------------------------
                // FC1 running
                // ------------------------------------------------

                STATE_FC1: begin

                    if (fc1_done) begin
                        fc2_start <= 1'b1;
                        state <= STATE_FC2;
                    end

                end

                // ------------------------------------------------
                // FC2 running
                // ------------------------------------------------

                STATE_FC2: begin

                    if (fc2_done) begin
                        state <= STATE_DONE;
                    end

                end

                // ------------------------------------------------
                // Complete
                // ------------------------------------------------

                STATE_DONE: begin

                    // Wait for start to be released before
                    // allowing another inference.
                    if (!start)
                        state <= STATE_IDLE;

                end

                default: begin
                    state <= STATE_IDLE;
                end

            endcase

        end
    end

endmodule
