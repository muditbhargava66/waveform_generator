`timescale 1ns / 1ps

//////////////////////////////////////////////////////////////////////////////
// Module: system_wrapper
//
// Stub wrapper for the Zynq PS + AXI block design.
// In a real Vivado project, this would be auto-generated from the block
// design. This stub provides a synthesizable/simulatable stand-in that
// instantiates the wavegen IP with direct port connections.
//
// For deployment:
//   1. Create a Vivado block design with Zynq PS + AXI Interconnect
//   2. Add wavegen_v1_0 as a custom AXI peripheral
//   3. Generate the block design wrapper to replace this file
//////////////////////////////////////////////////////////////////////////////

module system_wrapper (
    // DDR interface (directly from Zynq PS)
    inout  wire [14:0] DDR_addr,
    inout  wire [2:0]  DDR_ba,
    inout  wire        DDR_cas_n,
    inout  wire        DDR_ck_n,
    inout  wire        DDR_ck_p,
    inout  wire        DDR_cke,
    inout  wire        DDR_cs_n,
    inout  wire [3:0]  DDR_dm,
    inout  wire [31:0] DDR_dq,
    inout  wire [3:0]  DDR_dqs_n,
    inout  wire [3:0]  DDR_dqs_p,
    inout  wire        DDR_odt,
    inout  wire        DDR_ras_n,
    inout  wire        DDR_reset_n,
    inout  wire        DDR_we_n,

    // Fixed IO (Zynq PS)
    inout  wire        FIXED_IO_ddr_vrn,
    inout  wire        FIXED_IO_ddr_vrp,
    inout  wire [53:0] FIXED_IO_mio,
    inout  wire        FIXED_IO_ps_clk,
    inout  wire        FIXED_IO_ps_porb,
    inout  wire        FIXED_IO_ps_srstb,

    // Waveform generator enable
    input  wire        EN_0,

    // Waveform generator outputs
    output wire signed [15:0] OUT_A_0,
    output wire signed [15:0] OUT_B_0
);

    // ====================================================================
    // In the real system, the Zynq PS provides:
    //   - FCLK_CLK0: Fabric clock (e.g., 100 MHz)
    //   - AXI Master port connected to wavegen IP via AXI Interconnect
    //
    // For standalone simulation/synthesis without Zynq PS:
    //   - We use FIXED_IO_ps_clk as the clock source
    //   - AXI ports are tied off (no PS master in stub mode)
    //   - The wavegen IP runs with default register values
    // ====================================================================

    wire axi_clk;
    wire axi_resetn;

    // Use PS clock as AXI clock in stub mode
    assign axi_clk = FIXED_IO_ps_clk;
    assign axi_resetn = FIXED_IO_ps_srstb;

    wavegen_v1_0 #(
        .C_S00_AXI_DATA_WIDTH(32),
        .C_S00_AXI_ADDR_WIDTH(14),
        .SAMPLING_FREQUENCY(50000),
        .ARB_WAVEFORM_DEPTH(1024)
    ) wavegen_inst (
        // User ports
        .clk(axi_clk),
        .en(EN_0),
        .out_a(OUT_A_0),
        .out_b(OUT_B_0),

        // AXI ports - tied off in stub mode (no PS master)
        .s00_axi_aclk(axi_clk),
        .s00_axi_aresetn(axi_resetn),
        .s00_axi_awaddr(14'b0),
        .s00_axi_awprot(3'b0),
        .s00_axi_awvalid(1'b0),
        .s00_axi_awready(),
        .s00_axi_wdata(32'b0),
        .s00_axi_wstrb(4'b0),
        .s00_axi_wvalid(1'b0),
        .s00_axi_wready(),
        .s00_axi_bresp(),
        .s00_axi_bvalid(),
        .s00_axi_bready(1'b0),
        .s00_axi_araddr(14'b0),
        .s00_axi_arprot(3'b0),
        .s00_axi_arvalid(1'b0),
        .s00_axi_arready(),
        .s00_axi_rdata(),
        .s00_axi_rresp(),
        .s00_axi_rvalid(),
        .s00_axi_rready(1'b0)
    );

endmodule
