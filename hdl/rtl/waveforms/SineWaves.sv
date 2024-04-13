`timescale 1ns / 1ps

module SineWaves (
    input logic clk,
    input logic lut_clk,
    input logic en,
    input logic [31:0] phase_a,
    input logic [31:0] phase_b,
    output logic signed [15:0] out_a,
    output logic signed [15:0] out_b
);
    localparam LUT_ADDR_WIDTH = 9;
    
    logic sign_a = phase_a[31];
    logic dir_a = phase_a[30];
    logic [LUT_ADDR_WIDTH-1:0] lut_index_a = phase_a[29 -: LUT_ADDR_WIDTH];
    
    logic sign_b = phase_b[31];
    logic dir_b = phase_b[30];
    logic [LUT_ADDR_WIDTH-1:0] lut_index_b = phase_b[29 -: LUT_ADDR_WIDTH];
    
    logic [LUT_ADDR_WIDTH-1:0] lut_addr_a;
    logic [LUT_ADDR_WIDTH-1:0] lut_addr_b;
    logic [15:0] lut_value_a, lut_value_b;
    
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
            lut_addr_a <= dir_a ? ~lut_index_a : lut_index_a;
            lut_addr_b <= dir_b ? ~lut_index_b : lut_index_b;
            out_a <= sign_a ? -lut_value_a : lut_value_a;
            out_b <= sign_b ? -lut_value_b : lut_value_b;
        end
    end
    
endmodule