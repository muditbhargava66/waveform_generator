`timescale 1ns / 1ps

module wavegen_v1_0 #(
    parameter integer C_S00_AXI_DATA_WIDTH = 32,
    parameter integer C_S00_AXI_ADDR_WIDTH = 14,
    parameter integer SAMPLING_FREQUENCY = 50000,
    parameter integer ARB_WAVEFORM_DEPTH = 1024
)(
    // Users to add ports here
    input wire clk,
    input wire en,
    output wire signed [15:0] out_a,
    output wire signed [15:0] out_b,
    // User ports ends
    // Do not modify the ports beyond this line

    // Ports of Axi Slave Bus Interface S00_AXI
    input wire s00_axi_aclk,
    input wire s00_axi_aresetn,
    input wire [C_S00_AXI_ADDR_WIDTH-1:0] s00_axi_awaddr,
    input wire [2:0] s00_axi_awprot,
    input wire s00_axi_awvalid,
    output wire s00_axi_awready,
    input wire [C_S00_AXI_DATA_WIDTH-1:0] s00_axi_wdata,
    input wire [(C_S00_AXI_DATA_WIDTH/8)-1:0] s00_axi_wstrb,
    input wire s00_axi_wvalid,
    output wire s00_axi_wready,
    output wire [1:0] s00_axi_bresp,
    output wire s00_axi_bvalid,
    input wire s00_axi_bready,
    input wire [C_S00_AXI_ADDR_WIDTH-1:0] s00_axi_araddr,
    input wire [2:0] s00_axi_arprot,
    input wire s00_axi_arvalid,
    output wire s00_axi_arready,
    output wire [C_S00_AXI_DATA_WIDTH-1:0] s00_axi_rdata,
    output wire [1:0] s00_axi_rresp,
    output wire s00_axi_rvalid,
    input wire s00_axi_rready
);

    // Instantiation of Axi Bus Interface S00_AXI
    wavegen_v1_0_S00_AXI #(
        .C_S_AXI_ADDR_WIDTH(C_S00_AXI_ADDR_WIDTH),
        .SAMPLING_FREQUENCY(SAMPLING_FREQUENCY),
        .ARB_WAVEFORM_DEPTH(ARB_WAVEFORM_DEPTH)
    ) wavegen_v1_0_S00_AXI_inst (
        .s_axi_aclk(s00_axi_aclk),
        .s_axi_aresetn(s00_axi_aresetn),
        .s_axi_awaddr(s00_axi_awaddr),
        .s_axi_awprot(s00_axi_awprot),
        .s_axi_awvalid(s00_axi_awvalid),
        .s_axi_awready(s00_axi_awready),
        .s_axi_wdata(s00_axi_wdata),
        .s_axi_wstrb(s00_axi_wstrb),
        .s_axi_wvalid(s00_axi_wvalid),
        .s_axi_wready(s00_axi_wready),
        .s_axi_bresp(s00_axi_bresp),
        .s_axi_bvalid(s00_axi_bvalid),
        .s_axi_bready(s00_axi_bready),
        .s_axi_araddr(s00_axi_araddr),
        .s_axi_arprot(s00_axi_arprot),
        .s_axi_arvalid(s00_axi_arvalid),
        .s_axi_arready(s00_axi_arready),
        .s_axi_rdata(s00_axi_rdata),
        .s_axi_rresp(s00_axi_rresp),
        .s_axi_rvalid(s00_axi_rvalid),
        .s_axi_rready(s00_axi_rready),
        .sample_clk(en),
        .lut_clk(clk),
        .out_a(out_a),
        .out_b(out_b)
    );

endmodule