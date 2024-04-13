`timescale 1ns / 1ps

module voltsToDACWords #(
    parameter int DAC_TWOPOINTFIVE = 1,
    parameter int DAC_ZERO = 2048,
    parameter int N = 16,
    parameter int M = 12
)(
    input logic signed [N-1:0] in,
    output logic [M-1:0] calibrated
);
    assign calibrated = ($signed(DAC_TWOPOINTFIVE - DAC_ZERO) * in + 12500) / 25000 + DAC_ZERO;
endmodule