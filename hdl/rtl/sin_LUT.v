`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module Name: sin_LUT
// Description: Dual-port synchronous ROM for quarter-wave sine lookup table.
//              Stores 512 entries of 16-bit unsigned sine values for the
//              first quadrant (0 to pi/2). The SineWaves module reconstructs
//              the full waveform using sign and direction symmetry bits.
//
// Port A and Port B provide independent read access for channels A and B.
// Data is loaded from sin_LUT.hex via $readmemh at elaboration time.
//////////////////////////////////////////////////////////////////////////////////

module sin_LUT (
  input  wire        clka,
  input  wire [8:0]  addra,
  output reg  [15:0] douta,
  input  wire        clkb,
  input  wire [8:0]  addrb,
  output reg  [15:0] doutb
);

  // Quarter-wave sine LUT: 512 entries x 16-bit
  (* rom_style = "block" *) reg [15:0] lut_memory [0:511];

  // Load LUT data from hex file (one hex value per line)
  initial begin
    $readmemh("coe/sin_LUT.hex", lut_memory);
  end

  // Synchronous read - Port A
  always @(posedge clka) begin
    douta <= lut_memory[addra];
  end

  // Synchronous read - Port B
  always @(posedge clkb) begin
    doutb <= lut_memory[addrb];
  end

endmodule