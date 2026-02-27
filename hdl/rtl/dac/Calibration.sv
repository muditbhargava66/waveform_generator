`timescale 1ns / 1ps

//////////////////////////////////////////////////////////////////////////////
// Module: voltsToDACWords
//
// Calibrates a signed 16-bit voltage value to a 12-bit DAC word using
// a linear mapping between two calibration points:
//   - DAC_ZERO:        DAC code that produces 0V
//   - DAC_TWOPOINTFIVE: DAC code that produces 2.5V
//
// The formula:
//   calibrated = (DAC_TWOPOINTFIVE - DAC_ZERO) * in / 25000 + DAC_ZERO
//
// To avoid runtime division, we pre-compute the reciprocal at elaboration:
//   scale = (DAC_TWOPOINTFIVE - DAC_ZERO) * 2^16 / 25000
//   calibrated = (scale * in) >>> 16 + DAC_ZERO
//
// This uses a single DSP multiply + shift instead of a divider.
//////////////////////////////////////////////////////////////////////////////

module voltsToDACWords #(
    parameter int DAC_TWOPOINTFIVE = 1,
    parameter int DAC_ZERO = 2048,
    parameter int N = 16,
    parameter int M = 12
)(
    input  logic signed [N-1:0] in,
    output logic [M-1:0] calibrated
);

    // Pre-computed scale factor (elaboration-time constant)
    // scale = (DAC_TWOPOINTFIVE - DAC_ZERO) * 65536 / 25000
    // For default values: (1 - 2048) * 65536 / 25000 = -5368 (approx)
    localparam int SCALE_NUMER = (DAC_TWOPOINTFIVE - DAC_ZERO) * 65536;
    localparam int SCALE = SCALE_NUMER / 25000;

    wire signed [31:0] product = SCALE * in;
    wire signed [31:0] shifted = product >>> 16;
    wire signed [31:0] result  = shifted + DAC_ZERO;

    // Clamp to valid DAC range [0, 2^M-1]
    assign calibrated = (result < 0) ? {M{1'b0}} :
                         (result >= (1 << M)) ? {M{1'b1}} :
                         result[M-1:0];

endmodule