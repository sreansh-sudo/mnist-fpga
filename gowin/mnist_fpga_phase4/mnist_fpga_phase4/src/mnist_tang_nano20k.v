module mnist_tang_nano20k (
    input  wire       clk27,
    output wire [5:0] led
);

    // ============================================================
    // 27 MHz -> ~100 MHz PLL
    // ============================================================

    wire clk100;

    Gowin_rPLL u_pll (
        .clkin  (clk27),
        .clkout (clk100)
    );

    // ============================================================
    // Test image ROM
    // 784 bytes = 28x28 MNIST image
    // ============================================================

    reg [7:0] image_mem [0:783];

    initial begin
        $readmemh("data/test_input.mem", image_mem);
    end

    // ============================================================
    // Accelerator interface
    // ============================================================

    reg        input_write_enable;
    reg [9:0]  input_write_addr;
    reg [7:0]  input_write_data;
    reg        start;

    wire       done;
    wire [3:0] predicted_digit;

    // ============================================================
    // Image loading / inference controller
    // ============================================================

    localparam S_LOAD = 2'd0;
    localparam S_START = 2'd1;
    localparam S_RUN = 2'd2;
    localparam S_DONE = 2'd3;

    reg [1:0] state = S_LOAD;
    reg [9:0] load_addr = 10'd0;

    // ============================================================
    // Startup reset
    // ============================================================

    reg [4:0] reset_count = 5'd0;
    reg       rst = 1'b1;

    always @(posedge clk100) begin
        if (reset_count != 5'd16) begin
            reset_count <= reset_count + 5'd1;
            rst         <= 1'b1;
        end
        else begin
            rst         <= 1'b0;

            case (state)

                S_LOAD: begin
                    input_write_enable <= 1'b1;
                    input_write_addr   <= load_addr;
                    input_write_data   <= image_mem[load_addr];
                    start              <= 1'b0;

                    if (load_addr == 10'd783) begin
                        state <= S_START;
                    end
                    else begin
                        load_addr <= load_addr + 10'd1;
                    end
                end

                S_START: begin
                    input_write_enable <= 1'b0;
                    start              <= 1'b1;
                    state              <= S_RUN;
                end

                S_RUN: begin
                    input_write_enable <= 1'b0;
                    start              <= 1'b0;

                    if (done) begin
                        state <= S_DONE;
                    end
                end

                S_DONE: begin
                    input_write_enable <= 1'b0;
                    start              <= 1'b0;
                end

                default: begin
                    state <= S_LOAD;
                end

            endcase
        end
    end

    // ============================================================
    // Accelerator
    // ============================================================

    mnist_top u_mnist (
        .clk               (clk100),
        .rst               (rst),
        .start             (start),

        .input_write_enable(input_write_enable),
        .input_write_addr  (input_write_addr),
        .input_write_data  (input_write_data),

        .done              (done),
        .predicted_digit   (predicted_digit),

        .logit0            (),
        .logit1            (),
        .logit2            (),
        .logit3            (),
        .logit4            (),
        .logit5            (),
        .logit6            (),
        .logit7            (),
        .logit8            (),
        .logit9            ()
    );

    // LEDs are active-low on Tang Nano 20K.
    // Show the predicted digit as a 4-bit binary value.
    assign led[3:0] = ~predicted_digit;

    // Keep unused LEDs off.
    assign led[5:4] = 2'b11;

endmodule
