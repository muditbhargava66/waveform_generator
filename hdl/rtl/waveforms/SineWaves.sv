`timescale 1ns / 1ps

//////////////////////////////////////////////////////////////////////////////
// Module: SineWaves
//
// Quarter-wave sine synthesis using a shared dual-port LUT.
//
// The 32-bit phase input is decomposed as:
//   [31]    = sign     : if 1, negate the output (handles 3rd & 4th quadrants)
//   [30]    = direction: if 1, mirror the LUT index (handles 2nd quadrant)
//   [29:21] = 9-bit LUT address (512 entries for first quadrant)
//
// This approach stores only one quarter of the sine wave (0 to pi/2),
// reducing memory by 4x while maintaining full 16-bit precision.
//////////////////////////////////////////////////////////////////////////////

module SineWaves (
    input  logic        clk,
    input  logic        lut_clk,
    input  logic        en,
    input  logic [31:0] phase_a,
    input  logic [31:0] phase_b,
    output logic signed [15:0] out_a,
    output logic signed [15:0] out_b
);
    localparam LUT_ADDR_WIDTH = 9;
    
    // Phase decomposition - registered for proper timing
    logic sign_a_r, dir_a_r;
    logic sign_b_r, dir_b_r;
    logic [LUT_ADDR_WIDTH-1:0] lut_index_a, lut_index_b;

    // LUT address and output
    logic [LUT_ADDR_WIDTH-1:0] lut_addr_a;
    logic [LUT_ADDR_WIDTH-1:0] lut_addr_b;
    logic [15:0] lut_value_a, lut_value_b;
    
    // Pipeline stage: delayed sign for output negation
    // (accounts for 1-cycle LUT read latency)
    logic sign_a_d1, sign_b_d1;

    // Dual-port sine LUT
    sin_LUT lut (
        .clka(lut_clk),
        .addra(lut_addr_a),
        .douta(lut_value_a),
        .clkb(lut_clk),
        .addrb(lut_addr_b),
        .doutb(lut_value_b)
    );

    always_ff @(posedge lut_clk) begin
        if (clk == 1'b1) begin
            // Stage 1: Decompose phase and compute LUT address
            sign_a_r  <= phase_a[31];
            dir_a_r   <= phase_a[30];
            lut_index_a <= phase_a[29 -: LUT_ADDR_WIDTH];
            
            sign_b_r  <= phase_b[31];
            dir_b_r   <= phase_b[30];
            lut_index_b <= phase_b[29 -: LUT_ADDR_WIDTH];

            // Apply direction mirroring
            lut_addr_a <= dir_a_r ? ~lut_index_a : lut_index_a;
            lut_addr_b <= dir_b_r ? ~lut_index_b : lut_index_b;

            // Pipeline delay for sign bit (matches LUT read latency)
            sign_a_d1 <= sign_a_r;
            sign_b_d1 <= sign_b_r;

            // Stage 2: Apply sign (negate for quadrants 3 & 4)
            out_a <= sign_a_d1 ? -$signed({1'b0, lut_value_a[14:0]}) : $signed({1'b0, lut_value_a[14:0]});
            out_b <= sign_b_d1 ? -$signed({1'b0, lut_value_b[14:0]}) : $signed({1'b0, lut_value_b[14:0]});
        end
    end

endmodule