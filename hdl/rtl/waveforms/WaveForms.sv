`timescale 1ns / 1ps

module WaveForms #(
    parameter int SAMPLING_FREQUENCY = 50000,
    parameter int ARB_WAVEFORM_DEPTH = 1024
)(
    input logic clk,
    input logic lut_clk,
    input logic ena,
    input logic enb,
    input logic [3:0] mode_a,
    input logic [3:0] mode_b,
    input logic [31:0] freq_a,
    input logic [31:0] freq_b,
    input logic [15:0] dtcyc_a,
    input logic [15:0] dtcyc_b,
    input logic signed [15:0] phase_offs_a,
    input logic signed [15:0] phase_offs_b,
    input logic [15:0] cycles_a,
    input logic [15:0] cycles_b,
    input logic [15:0] arb_waveform_data[0:ARB_WAVEFORM_DEPTH-1],
    output logic signed [15:0] wave_a,
    output logic signed [15:0] wave_b
);
    localparam DC = 4'd0, SINE = 4'd1, SAWTOOTH = 4'd2, TRIANGLE = 4'd3, SQUARE = 4'd4, ARB = 4'd5;
    localparam ONE_VOLT = 2**15 - 1;
    
    logic [31:0] phase_a = 0;
    logic [31:0] delta_phase_a = ({freq_a, 32'b0}) / SAMPLING_FREQUENCY;
    
    logic signed [31:0] normalized_phase_offset_a = ({phase_offs_a, 30'b0}) / 9000; // phase offset is from -180 degrees to 180 degrees
    logic [31:0] real_phase_a = phase_a + normalized_phase_offset_a; 
         
    logic [31:0] phase_b = 0;
    logic [31:0] delta_phase_b = ({freq_b, 32'b0}) / SAMPLING_FREQUENCY;
      
    logic signed [31:0] normalized_phase_offset_b = ({phase_offs_b, 30'b0}) / 9000; // phase offset is from -180 degrees to 180 degrees
    logic [31:0] real_phase_b = phase_b + normalized_phase_offset_b;
    
    logic signed [15:0] sine_a, sine_b;
    SineWaves sine_waves(
        .clk(clk),
        .lut_clk(lut_clk),
        .en(1'b1),
        .phase_a(real_phase_a),
        .phase_b(real_phase_b),
        .out_a(sine_a),
        .out_b(sine_b)
    );
    
    logic [31:0] dtcyca = {dtcyc_a, 16'b0}; 
    logic [31:0] dtcycb = {dtcyc_b, 16'b0}; 
      
    logic [15:0] n_cycles_a = 0;
    always_ff @(negedge phase_a[31] or negedge ena) begin
        if (ena == 1'b0) begin
            n_cycles_a <= 0;
        end else if (n_cycles_a != cycles_a) begin
            n_cycles_a <= n_cycles_a + 1;
        end
    end
  
    always_ff @(posedge clk) begin
        if (ena == 1'b0) begin
            phase_a <= 32'b0;
            wave_a <= 16'b0;
        end else if (cycles_a == 0 || n_cycles_a != cycles_a) begin     
            case (mode_a)
                DC: wave_a <= 0;
                SINE: wave_a <= sine_a;
                SAWTOOTH:
                    if (real_phase_a >= 0 && real_phase_a < 2**31)
                        wave_a <= real_phase_a / 2**16; // 2x
                    else
                        wave_a <= real_phase_a / 2**16 - (2**16 - 1); // 2x - 2                 
                TRIANGLE: begin                
                    if (real_phase_a >= 0 && real_phase_a < 2**30)
                        wave_a <= real_phase_a / 2**15; // 4x
                    else if (real_phase_a >= (2**30) && real_phase_a < 3 * (2**30))
                        wave_a <= (2**16 - 1) - real_phase_a / 2**15; // 2 - 4x
                    else // real_phase >= 3 * (2**30)
                        wave_a <= real_phase_a / 2**15 - (2**17 - 2); // 4x - 4
                end
                SQUARE:
                    if (real_phase_a >= dtcyca)
                        wave_a <= -ONE_VOLT;
                    else 
                        wave_a <= ONE_VOLT;
                ARB: wave_a <= arb_waveform_data[phase_a[31:20]]; // Use top 12 bits of phase as address
            endcase
            phase_a <= phase_a + delta_phase_a;
        end else begin
            wave_a <= 16'b0;
        end
    end

    logic [15:0] n_cycles_b = 0;        
    always_ff @(negedge phase_b[31]) begin
        if (enb == 1'b0) begin
            n_cycles_b <= 0;
        end else if (n_cycles_b != cycles_b) begin
            n_cycles_b <= n_cycles_b + 1;
        end          
    end

    always_ff @(posedge clk) begin
        if (enb == 1'b0) begin
            phase_b <= 32'b0;
            wave_b <= 16'b0;
        end else if (cycles_b == 0 || n_cycles_b != cycles_b) begin     
            case (mode_b)
                DC: wave_b <= 0;
                SINE: wave_b <= sine_b;
                SAWTOOTH:
                    if (real_phase_b >= 0 && real_phase_b < 2**31)
                        wave_b <= real_phase_b / 2**16; // 2x
                    else
                        wave_b <= real_phase_b / 2**16 - (2**16 - 1); // 2x - 2                 
                TRIANGLE: begin                
                    if (real_phase_b >= 0 && real_phase_b < 2**30)
                        wave_b <= real_phase_b / 2**15; // 4x
                    else if (real_phase_b >= (2**30) && real_phase_b < 3 * (2**30))
                        wave_b <= (2**16 - 1) - real_phase_b / 2**15; // 2 - 4x
                    else // real_phase >= 3 * (2**30)
                        wave_b <= real_phase_b / 2**15 - (2**17 - 2); // 4x - 4
                end
                SQUARE:
                    if (real_phase_b >= dtcycb)
                        wave_b <= -ONE_VOLT;
                    else 
                        wave_b <= ONE_VOLT;
                ARB: wave_b <= arb_waveform_data[phase_b[31:20]]; // Use top 12 bits of phase as address
            endcase
            phase_b <= phase_b + delta_phase_b;
        end else begin
            wave_b <= 16'b0;
        end
    end
            
endmodule