`timescale 1ns / 1ps

module s2ui (
    input logic signed [11:0] signed_in,
    output logic [11:0] unsigned_out
);
    assign unsigned_out = -1 * signed_in + 2048;
endmodule