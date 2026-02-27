`timescale 1ns / 1ps

//////////////////////////////////////////////////////////////////////////////
// Module: WaveForms
//
// Dual-channel waveform generator with support for DC, sine, sawtooth,
// triangle, square, and arbitrary waveform modes.
//
// Uses fixed-point phase accumulator architecture. The frequency is set by
// computing a phase increment (delta_phase) per sample clock cycle.
// Division operations have been replaced with synthesizable fixed-point
// multiplication using pre-computed reciprocals.
//
// Phase accumulator: 32-bit unsigned
//   [31]    = sign bit (for sine symmetry)
//   [30]    = direction bit (for sine symmetry)
//   [29:21] = LUT address (9-bit, 512 entries)
//   [20:0]  = fractional phase (sub-sample precision)
//
// ARB waveform memory is internal (BRAM-inferred) and loaded via a
// simple write interface (arb_wr_en, arb_wr_addr, arb_wr_data) from
// the AXI register slave.
//////////////////////////////////////////////////////////////////////////////

module WaveForms #(
    parameter int SAMPLING_FREQUENCY = 50000,
    parameter int ARB_WAVEFORM_DEPTH = 1024
)(
    input  logic        clk,
    input  logic        lut_clk,
    input  logic        rst_a,
    input  logic        rst_b,
    input  logic        ena,
    input  logic        enb,
    input  logic        trigger_a,
    input  logic        trigger_b,
    input  logic [3:0]  mode_a,
    input  logic [3:0]  mode_b,
    input  logic [31:0] freq_a,
    input  logic [31:0] freq_b,
    input  logic [15:0] dtcyc_a,
    input  logic [15:0] dtcyc_b,
    input  logic signed [15:0] phase_offs_a,
    input  logic signed [15:0] phase_offs_b,
    input  logic [15:0] cycles_a,
    input  logic [15:0] cycles_b,
    input  logic [31:0] arb_waveform_depth,
    // ARB waveform write interface (from AXI slave)
    input  logic        arb_wr_clk,
    input  logic        arb_wr_en,
    input  logic [$clog2(ARB_WAVEFORM_DEPTH)-1:0] arb_wr_addr,
    input  logic [15:0] arb_wr_data,
    output logic signed [15:0] wave_a,
    output logic signed [15:0] wave_b
);

    // ====================================================================
    // Waveform mode constants
    // ====================================================================
    localparam logic [3:0] DC       = 4'd0;
    localparam logic [3:0] SINE     = 4'd1;
    localparam logic [3:0] SAWTOOTH = 4'd2;
    localparam logic [3:0] TRIANGLE = 4'd3;
    localparam logic [3:0] SQUARE   = 4'd4;
    localparam logic [3:0] ARB      = 4'd5;

    localparam signed [15:0] ONE_VOLT     = 16'sd32767;  // 2^15 - 1
    localparam signed [15:0] NEG_ONE_VOLT = -16'sd32767;

    // ====================================================================
    // Fixed-point reciprocal for frequency-to-phase-delta conversion
    //
    // delta_phase = freq * (2^32 / SAMPLING_FREQUENCY)
    //
    // We pre-compute PHASE_SCALE = 2^32 / SAMPLING_FREQUENCY as a
    // compile-time constant. Since this is a parameter expression, 
    // Vivado evaluates it during elaboration (no runtime divider).
    //
    // For SAMPLING_FREQUENCY = 50000:
    //   PHASE_SCALE = 4294967296 / 50000 = 85899 (truncated)
    //
    // The multiplication freq * PHASE_SCALE produces a 64-bit result;
    // we take the lower 32 bits as the phase increment.
    // ====================================================================
    localparam longint unsigned PHASE_SCALE = 64'h1_0000_0000 / SAMPLING_FREQUENCY;

    // ====================================================================
    // Phase offset normalization
    //
    // phase_offs is in units of 0.01 degrees, range -18000 to +18000.
    // We need to map this to a 32-bit phase value:
    //   normalized = phase_offs * (2^32 / 36000)
    //
    // 2^32 / 36000 = 119304 (approximately)
    // ====================================================================
    localparam longint unsigned PHASE_OFFSET_SCALE = 64'h1_0000_0000 / 36000;

    // ====================================================================
    // ARB waveform memory (internal, BRAM-inferred)
    // ====================================================================
    localparam integer ARB_ADDR_BITS = $clog2(ARB_WAVEFORM_DEPTH);

    (* ram_style = "block" *) logic [15:0] arb_waveform_data [0:ARB_WAVEFORM_DEPTH-1];

    // Write port: driven by AXI slave clock domain
    always_ff @(posedge arb_wr_clk) begin
        if (arb_wr_en) begin
            arb_waveform_data[arb_wr_addr] <= arb_wr_data;
        end
    end

    // ====================================================================
    // Channel A signals
    // ====================================================================
    logic [31:0] phase_a;
    logic [63:0] delta_phase_a_wide;
    logic [31:0] delta_phase_a;
    logic [63:0] phase_offset_a_wide;
    logic signed [31:0] normalized_phase_offset_a;
    logic [31:0] real_phase_a;
    logic [15:0] n_cycles_a;
    logic        phase_a_msb_prev;
    logic        triggered_a;

    // Compute phase delta: freq_a * PHASE_SCALE
    assign delta_phase_a_wide = freq_a * PHASE_SCALE;
    assign delta_phase_a = delta_phase_a_wide[31:0];

    // Compute normalized phase offset
    assign phase_offset_a_wide = $signed(phase_offs_a) * $signed(PHASE_OFFSET_SCALE[31:0]);
    assign normalized_phase_offset_a = phase_offset_a_wide[31:0];

    // Apply phase offset
    assign real_phase_a = phase_a + normalized_phase_offset_a;

    // ====================================================================
    // Channel B signals
    // ====================================================================
    logic [31:0] phase_b;
    logic [63:0] delta_phase_b_wide;
    logic [31:0] delta_phase_b;
    logic [63:0] phase_offset_b_wide;
    logic signed [31:0] normalized_phase_offset_b;
    logic [31:0] real_phase_b;
    logic [15:0] n_cycles_b;
    logic        phase_b_msb_prev;
    logic        triggered_b;

    assign delta_phase_b_wide = freq_b * PHASE_SCALE;
    assign delta_phase_b = delta_phase_b_wide[31:0];

    assign phase_offset_b_wide = $signed(phase_offs_b) * $signed(PHASE_OFFSET_SCALE[31:0]);
    assign normalized_phase_offset_b = phase_offset_b_wide[31:0];

    assign real_phase_b = phase_b + normalized_phase_offset_b;

    // ====================================================================
    // Sine wave generation (shared dual-port LUT)
    // ====================================================================
    logic signed [15:0] sine_a, sine_b;

    SineWaves sine_waves (
        .clk(clk),
        .lut_clk(lut_clk),
        .en(1'b1),
        .phase_a(real_phase_a),
        .phase_b(real_phase_b),
        .out_a(sine_a),
        .out_b(sine_b)
    );

    // ====================================================================
    // Duty cycle thresholds (scaled to 32-bit phase range)
    // ====================================================================
    logic [31:0] dtcyca;
    logic [31:0] dtcycb;
    assign dtcyca = {dtcyc_a, 16'b0};
    assign dtcycb = {dtcyc_b, 16'b0};

    // ====================================================================
    // ARB waveform index computation
    // ====================================================================
    logic [ARB_ADDR_BITS-1:0] arb_index_a, arb_index_b;
    assign arb_index_a = phase_a[31 -: ARB_ADDR_BITS];
    assign arb_index_b = phase_b[31 -: ARB_ADDR_BITS];

    // ====================================================================
    // Channel A: Phase accumulator and waveform generation
    // ====================================================================
    always_ff @(posedge clk) begin
        if (rst_a || !ena) begin
            phase_a        <= 32'b0;
            wave_a         <= 16'sb0;
            n_cycles_a     <= 16'b0;
            phase_a_msb_prev <= 1'b0;
            triggered_a    <= 1'b0;
        end else begin
            // Detect trigger
            if (trigger_a)
                triggered_a <= 1'b1;

            // Cycle counting: detect negative edge of phase MSB (one full cycle)
            phase_a_msb_prev <= phase_a[31];
            if (phase_a_msb_prev && !phase_a[31]) begin
                if (cycles_a != 16'b0 && n_cycles_a < cycles_a)
                    n_cycles_a <= n_cycles_a + 1;
            end

            // Generate waveform if continuous (cycles=0) or cycle count not reached
            if (cycles_a == 16'b0 || n_cycles_a < cycles_a) begin
                case (mode_a)
                    DC: wave_a <= 16'sb0;
                    SINE: wave_a <= sine_a;
                    SAWTOOTH: begin
                        // Linear ramp from ~-16384 to ~+16383
                        wave_a <= $signed({1'b0, real_phase_a[31:17]}) - 16'sd16384;
                    end
                    TRIANGLE: begin
                        if (!real_phase_a[31]) begin
                            wave_a <= $signed({1'b0, real_phase_a[30:16]}) - 16'sd16384;
                        end else begin
                            wave_a <= 16'sd16383 - $signed({1'b0, real_phase_a[30:16]});
                        end
                    end
                    SQUARE: begin
                        if (real_phase_a < dtcyca)
                            wave_a <= ONE_VOLT;
                        else
                            wave_a <= NEG_ONE_VOLT;
                    end
                    ARB: begin
                        wave_a <= $signed(arb_waveform_data[arb_index_a]);
                    end
                    default: wave_a <= 16'sb0;
                endcase
                phase_a <= phase_a + delta_phase_a;
            end else begin
                wave_a <= 16'sb0;
            end
        end
    end

    // ====================================================================
    // Channel B: Phase accumulator and waveform generation
    // ====================================================================
    always_ff @(posedge clk) begin
        if (rst_b || !enb) begin
            phase_b        <= 32'b0;
            wave_b         <= 16'sb0;
            n_cycles_b     <= 16'b0;
            phase_b_msb_prev <= 1'b0;
            triggered_b    <= 1'b0;
        end else begin
            if (trigger_b)
                triggered_b <= 1'b1;

            phase_b_msb_prev <= phase_b[31];
            if (phase_b_msb_prev && !phase_b[31]) begin
                if (cycles_b != 16'b0 && n_cycles_b < cycles_b)
                    n_cycles_b <= n_cycles_b + 1;
            end

            if (cycles_b == 16'b0 || n_cycles_b < cycles_b) begin
                case (mode_b)
                    DC: wave_b <= 16'sb0;
                    SINE: wave_b <= sine_b;
                    SAWTOOTH: begin
                        wave_b <= $signed({1'b0, real_phase_b[31:17]}) - 16'sd16384;
                    end
                    TRIANGLE: begin
                        if (!real_phase_b[31]) begin
                            wave_b <= $signed({1'b0, real_phase_b[30:16]}) - 16'sd16384;
                        end else begin
                            wave_b <= 16'sd16383 - $signed({1'b0, real_phase_b[30:16]});
                        end
                    end
                    SQUARE: begin
                        if (real_phase_b < dtcycb)
                            wave_b <= ONE_VOLT;
                        else
                            wave_b <= NEG_ONE_VOLT;
                    end
                    ARB: begin
                        wave_b <= $signed(arb_waveform_data[arb_index_b]);
                    end
                    default: wave_b <= 16'sb0;
                endcase
                phase_b <= phase_b + delta_phase_b;
            end else begin
                wave_b <= 16'sb0;
            end
        end
    end
            
endmodule