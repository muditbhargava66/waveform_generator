`timescale 1ns / 1ps

//////////////////////////////////////////////////////////////////////////////
// Module: DAC_Controller
//
// SPI controller for a dual-channel DAC (e.g., MCP4922 or similar).
// Sends 16-bit commands to DAC channels A and B, then pulses LDAC
// to simultaneously update both outputs.
//
// SPI timing: 100 MHz / 25 = 4 MHz base, SPI clock = 2 MHz
//
// Protocol (per transfer):
//   [15:12] = command/channel select (0011=ch_a w/ gain, 1011=ch_b w/ gain)
//   [11:0]  = DAC data
//
// State machine sequence:
//   IDLE -> LOAD_A -> SHIFT_A -> PAUSE_A -> LOAD_B -> SHIFT_B -> LDAC -> IDLE
//////////////////////////////////////////////////////////////////////////////

module DAC_Controller (
    input  logic [11:0] r1,      // Channel A DAC data
    input  logic [11:0] r2,      // Channel B DAC data
    input  logic        clk100,  // 100 MHz system clock
    output logic        cs,      // SPI chip select (active low)
    output logic        sclk,    // SPI clock
    output logic        sdi,     // SPI data in (MOSI)
    output logic        ldac     // Load DAC (active low pulse)
);

    // ====================================================================
    // Clock divider: 100 MHz / 25 = 4 MHz pulse
    // ====================================================================
    logic four_mega;
    DivideByN #(.N(25), .M(5)) divide_by_25 (
        .clk(clk100),
        .pulse(four_mega)
    );

    // ====================================================================
    // SPI clock generation (2 MHz from 4 MHz toggle)
    // ====================================================================
    logic sck = 1'b0;
    always_ff @(posedge clk100) begin
        if (four_mega)
            sck <= !sck;
    end

    // ====================================================================
    // State machine
    // ====================================================================
    typedef enum logic [2:0] {
        IDLE     = 3'd0,
        SHIFT_A  = 3'd1,
        PAUSE_A  = 3'd2,
        SHIFT_B  = 3'd3,
        LDAC_LOW = 3'd4,
        LDAC_HI  = 3'd5
    } state_t;

    state_t state = IDLE;
    logic [3:0] counter = 4'd0;

    // Registered DAC words - capture inputs at start of transfer
    logic [15:0] reg1, reg2;

    // ====================================================================
    // State machine transitions (on SPI clock falling edge)
    // ====================================================================
    always_ff @(posedge clk100) begin
        if (four_mega && sck) begin  // Falling edge of SPI clock
            case (state)
                IDLE: begin
                    // Capture DAC words with command prefix
                    reg1 <= {4'b0011, r1};  // Channel A, gain=1x, active
                    reg2 <= {4'b1011, r2};  // Channel B, gain=1x, active
                    counter <= 4'd15;
                    state <= SHIFT_A;
                end
                SHIFT_A: begin
                    if (counter == 4'd0)
                        state <= PAUSE_A;
                    else
                        counter <= counter - 1;
                end
                PAUSE_A: begin
                    counter <= 4'd15;
                    state <= SHIFT_B;
                end
                SHIFT_B: begin
                    if (counter == 4'd0)
                        state <= LDAC_LOW;
                    else
                        counter <= counter - 1;
                end
                LDAC_LOW: begin
                    state <= LDAC_HI;
                end
                LDAC_HI: begin
                    state <= IDLE;
                end
                default: begin
                    state <= IDLE;
                end
            endcase
        end
    end

    // ====================================================================
    // Output combinational logic
    // ====================================================================
    always_comb begin
        case (state)
            IDLE: begin
                cs   = 1'b1;
                ldac = 1'b1;
                sdi  = 1'b0;
            end
            SHIFT_A: begin
                cs   = 1'b0;
                ldac = 1'b1;
                sdi  = reg1[counter];
            end
            PAUSE_A: begin
                cs   = 1'b1;
                ldac = 1'b1;
                sdi  = 1'b0;
            end
            SHIFT_B: begin
                cs   = 1'b0;
                ldac = 1'b1;
                sdi  = reg2[counter];
            end
            LDAC_LOW: begin
                cs   = 1'b1;
                ldac = 1'b0;
                sdi  = 1'b0;
            end
            LDAC_HI: begin
                cs   = 1'b1;
                ldac = 1'b1;
                sdi  = 1'b0;
            end
            default: begin
                cs   = 1'b1;
                ldac = 1'b1;
                sdi  = 1'b0;
            end
        endcase
    end

    assign sclk = sck;

endmodule