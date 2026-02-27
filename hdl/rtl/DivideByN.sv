`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/13/2024 10:52:32 PM
// Design Name: 
// Module Name: DivideByN
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module DivideByN #(
  parameter N = 100,
  parameter M = 7
)(
  input logic clk,
  output logic pulse
);

  logic [M-1:0] counter = 0;

  always_ff @(posedge clk) begin
    if (counter == N-1) begin
      counter <= 0;
      pulse <= 1'b1;
    end else begin
      counter <= counter + 1;
      pulse <= 1'b0;
    end
  end

endmodule