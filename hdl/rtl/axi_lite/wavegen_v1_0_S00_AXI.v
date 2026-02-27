`timescale 1ns / 1ps

////////////////////////////////////
// Module: wavegen_v1_0_S00_AXI
// 
// AXI4-Lite slave interface for the waveform generator IP.
// Features:
//   - Shadow register system for atomic parameter updates
//   - Software trigger for synchronized channel start
//   - Status readback register
//   - Arbitrary waveform data loading via extended address space
//   - Dynamic reconfiguration with glitch-free parameter updates
//
// Register Map (active registers, 32-bit aligned):
//   0x00  MODE        [7:4]=mode_b, [3:0]=mode_a
//   0x04  RUN         [1]=enable_b, [0]=enable_a
//   0x08  FREQ_A      [31:0]=frequency channel A (100uHz units)
//   0x0C  FREQ_B      [31:0]=frequency channel B (100uHz units)
//   0x10  OFFSET      [31:16]=offset_b, [15:0]=offset_a
//   0x14  AMPLTD      [31:16]=amp_b, [15:0]=amp_a
//   0x18  DTCYC       [31:16]=dtcyc_b, [15:0]=dtcyc_a
//   0x1C  CYCLES      [31:16]=cycles_b, [15:0]=cycles_a
//   0x20  PHASE_OFF   [31:16]=phase_off_b, [15:0]=phase_off_a
//   0x24  ARB_DEPTH   [31:0]=arb waveform depth (samples)
//   0x28  ARB_DATA    [15:0]=arb sample (addr via write offset)
//   0x2C  RECONFIG    Write any value to apply shadow registers
//   0x30  STATUS      [RO] [3]=ch_b_running, [2]=ch_a_running,
//                           [1]=reconfig_busy, [0]=ready
//   0x34  TRIGGER     Write: [1]=trigger_b, [0]=trigger_a
//   0x38  SOFT_RESET  Write: [1]=reset_b, [0]=reset_a
////////////////////////////////////

module wavegen_v1_0_S00_AXI #(
    parameter integer C_S_AXI_ADDR_WIDTH = 14,
    parameter integer SAMPLING_FREQUENCY = 50000,
    parameter integer ARB_WAVEFORM_DEPTH = 1024
)(
    // Ports to top level module (what makes this the Wavegen IP module)
    input sample_clk,
    input lut_clk,
    output signed [15:0] out_a,
    output signed [15:0] out_b,
    
    // AXI clock and reset        
    input wire s_axi_aclk,
    input wire s_axi_aresetn,

    // AXI write channel
    input wire [C_S_AXI_ADDR_WIDTH-1:0] s_axi_awaddr,
    input wire [2:0] s_axi_awprot,
    input wire s_axi_awvalid,
    output wire s_axi_awready,
    
    input wire [31:0] s_axi_wdata,
    input wire [3:0] s_axi_wstrb,
    input wire s_axi_wvalid,
    output wire s_axi_wready,
    
    output wire [1:0] s_axi_bresp,
    output wire s_axi_bvalid,
    input wire s_axi_bready,
    
    // AXI read channel
    input wire [C_S_AXI_ADDR_WIDTH-1:0] s_axi_araddr,
    input wire [2:0] s_axi_arprot,
    input wire s_axi_arvalid,
    output wire s_axi_arready,
    
    output wire [31:0] s_axi_rdata,
    output wire [1:0] s_axi_rresp,
    output wire s_axi_rvalid,
    input wire s_axi_rready
);

    // ========================================================================
    // Register number definitions (address bits [5:2])
    // ========================================================================
    localparam integer MODE_REG       = 4'b0000; // 0x00
    localparam integer RUN_REG        = 4'b0001; // 0x04
    localparam integer FREQ_A_REG     = 4'b0010; // 0x08
    localparam integer FREQ_B_REG     = 4'b0011; // 0x0C
    localparam integer OFFSET_REG     = 4'b0100; // 0x10
    localparam integer AMPLTD_REG     = 4'b0101; // 0x14
    localparam integer DTCYC_REG      = 4'b0110; // 0x18
    localparam integer CYCLES_REG     = 4'b0111; // 0x1C
    localparam integer PHASE_OFF_REG  = 4'b1000; // 0x20
    localparam integer ARB_DEPTH_REG  = 4'b1001; // 0x24
    localparam integer ARB_DATA_REG   = 4'b1010; // 0x28
    localparam integer RECONFIG_REG   = 4'b1011; // 0x2C
    localparam integer STATUS_REG     = 4'b1100; // 0x30
    localparam integer TRIGGER_REG    = 4'b1101; // 0x34
    localparam integer SOFT_RESET_REG = 4'b1110; // 0x38

    // ========================================================================
    // Active registers (directly drive the waveform generator)
    // ========================================================================
    reg [3:0] mode_a, mode_b;
    reg enable_a, enable_b;
    reg [31:0] freq_a, freq_b;
    reg signed [15:0] offset_a, offset_b;
    reg [15:0] amp_a, amp_b;
    reg [15:0] dtcyc_a, dtcyc_b;
    reg [15:0] cycles_a, cycles_b;
    reg signed [15:0] phase_off_a, phase_off_b;
    reg [31:0] arb_waveform_depth;

    // ARB waveform write interface (memory is inside WaveForms module)
    reg arb_wr_en;
    reg [$clog2(ARB_WAVEFORM_DEPTH)-1:0] arb_wr_addr;
    reg [15:0] arb_wr_data;

    // ========================================================================
    // Shadow registers (written by AXI, applied on RECONFIG)
    // ========================================================================
    reg [3:0] shadow_mode_a, shadow_mode_b;
    reg shadow_enable_a, shadow_enable_b;
    reg [31:0] shadow_freq_a, shadow_freq_b;
    reg signed [15:0] shadow_offset_a, shadow_offset_b;
    reg [15:0] shadow_amp_a, shadow_amp_b;
    reg [15:0] shadow_dtcyc_a, shadow_dtcyc_b;
    reg [15:0] shadow_cycles_a, shadow_cycles_b;
    reg signed [15:0] shadow_phase_off_a, shadow_phase_off_b;
    reg [31:0] shadow_arb_waveform_depth;

    // ========================================================================
    // Control signals
    // ========================================================================
    reg reconfig_pending;
    reg trigger_a, trigger_b;
    reg soft_reset_a, soft_reset_b;

    // ========================================================================
    // AXI4-Lite interface signals
    // (declared here, before WaveForms instantiation which uses axi_clk)
    // ========================================================================
    reg axi_awready;
    reg axi_wready;
    reg [1:0] axi_bresp;
    reg axi_bvalid;
    reg axi_arready;
    reg [31:0] axi_rdata;
    reg [1:0] axi_rresp;
    reg axi_rvalid;
    
    wire axi_clk     = s_axi_aclk;
    wire axi_resetn  = s_axi_aresetn;
    wire [31:0] axi_awaddr  = {{(32-C_S_AXI_ADDR_WIDTH){1'b0}}, s_axi_awaddr};
    wire axi_awvalid = s_axi_awvalid;
    wire axi_wvalid  = s_axi_wvalid;
    wire [3:0] axi_wstrb = s_axi_wstrb;
    wire axi_bready  = s_axi_bready;
    wire [31:0] axi_araddr  = {{(32-C_S_AXI_ADDR_WIDTH){1'b0}}, s_axi_araddr};
    wire axi_arvalid = s_axi_arvalid;
    wire axi_rready  = s_axi_rready;
    
    assign s_axi_awready = axi_awready;
    assign s_axi_wready  = axi_wready;
    assign s_axi_bresp   = axi_bresp;
    assign s_axi_bvalid  = axi_bvalid;
    assign s_axi_arready = axi_arready;
    assign s_axi_rdata   = axi_rdata;
    assign s_axi_rresp   = axi_rresp;
    assign s_axi_rvalid  = axi_rvalid;

    // ========================================================================
    // Waveform output logic
    // ========================================================================
    wire signed [15:0] wave_a_value;
    wire signed [15:0] wave_b_value;
    
    wire signed [31:0] temp_a = $signed(amp_a) * wave_a_value;
    wire signed [31:0] temp_b = $signed(amp_b) * wave_b_value;
    
    assign out_a = enable_a ? ((temp_a >>> 15) + offset_a) : 16'sd0;
    assign out_b = enable_b ? ((temp_b >>> 15) + offset_b) : 16'sd0;

    // ========================================================================
    // WaveForms instantiation
    // ========================================================================
    WaveForms #(
        .SAMPLING_FREQUENCY(SAMPLING_FREQUENCY),
        .ARB_WAVEFORM_DEPTH(ARB_WAVEFORM_DEPTH)
    ) waves (
        .clk(sample_clk),
        .lut_clk(lut_clk),
        .rst_a(soft_reset_a),
        .rst_b(soft_reset_b),
        .ena(enable_a),
        .enb(enable_b),
        .trigger_a(trigger_a),
        .trigger_b(trigger_b),
        .mode_a(mode_a),
        .mode_b(mode_b),
        .freq_a(freq_a),
        .freq_b(freq_b),
        .dtcyc_a(dtcyc_a),
        .dtcyc_b(dtcyc_b),
        .phase_offs_a(phase_off_a),
        .phase_offs_b(phase_off_b),
        .cycles_a(cycles_a),
        .cycles_b(cycles_b),
        .arb_waveform_depth(arb_waveform_depth),
        .arb_wr_clk(axi_clk),
        .arb_wr_en(arb_wr_en),
        .arb_wr_addr(arb_wr_addr),
        .arb_wr_data(arb_wr_data),
        .wave_a(wave_a_value),
        .wave_b(wave_b_value)
    );

    // ========================================================================
    // AXI write address ready handshake
    // ========================================================================
    wire wr_add_data_valid = axi_awvalid && axi_wvalid;
    reg aw_en;
    
    always @(posedge axi_clk) begin
        if (axi_resetn == 1'b0) begin
            axi_awready <= 1'b0;
            aw_en <= 1'b1;
        end else begin
            if (wr_add_data_valid && ~axi_awready && aw_en) begin
                axi_awready <= 1'b1;
                aw_en <= 1'b0;
            end else if (axi_bready && axi_bvalid) begin
                aw_en <= 1'b1;
                axi_awready <= 1'b0;
            end else begin           
                axi_awready <= 1'b0;
            end
        end 
    end

    // ========================================================================
    // Capture write address
    // ========================================================================
    reg [C_S_AXI_ADDR_WIDTH-1:0] waddr;
    always @(posedge axi_clk) begin
        if (axi_resetn == 1'b0) begin
            waddr <= 0;
        end else if (wr_add_data_valid && ~axi_awready && aw_en) begin
            waddr <= s_axi_awaddr;
        end
    end

    // ========================================================================
    // Write data ready handshake
    // ========================================================================
    always @(posedge axi_clk) begin
        if (axi_resetn == 1'b0) begin
            axi_wready <= 1'b0;
        end else begin
            axi_wready <= (wr_add_data_valid && ~axi_wready && aw_en);
        end
    end       

    // ========================================================================
    // Write to shadow registers (+ direct arb data, reconfig, trigger)
    // ========================================================================
    wire wr = wr_add_data_valid && axi_awready && axi_wready;
    integer byte_index;
    integer arb_idx;
    
    always @(posedge axi_clk) begin
        if (axi_resetn == 1'b0) begin
            // Reset shadow registers
            shadow_mode_a <= 4'b0;
            shadow_mode_b <= 4'b0;
            shadow_enable_a <= 1'b0;
            shadow_enable_b <= 1'b0;
            shadow_freq_a <= 32'b0;
            shadow_freq_b <= 32'b0;
            shadow_offset_a <= 16'sb0;
            shadow_offset_b <= 16'sb0;
            shadow_amp_a <= 16'h7FFF;  // Default full amplitude
            shadow_amp_b <= 16'h7FFF;
            shadow_dtcyc_a <= 16'h8000; // Default 50% duty cycle
            shadow_dtcyc_b <= 16'h8000;
            shadow_cycles_a <= 16'b0;   // 0 = continuous
            shadow_cycles_b <= 16'b0;
            shadow_phase_off_a <= 16'sb0;
            shadow_phase_off_b <= 16'sb0;
            shadow_arb_waveform_depth <= 32'd1024;
            
            // Reset active registers
            mode_a <= 4'b0;
            mode_b <= 4'b0;
            enable_a <= 1'b0;
            enable_b <= 1'b0;
            freq_a <= 32'b0;
            freq_b <= 32'b0;
            offset_a <= 16'sb0;
            offset_b <= 16'sb0;
            amp_a <= 16'h7FFF;
            amp_b <= 16'h7FFF;
            dtcyc_a <= 16'h8000;
            dtcyc_b <= 16'h8000;
            cycles_a <= 16'b0;
            cycles_b <= 16'b0;
            phase_off_a <= 16'sb0;
            phase_off_b <= 16'sb0;
            arb_waveform_depth <= 32'd1024;
            
            // Reset control signals
            reconfig_pending <= 1'b0;
            trigger_a <= 1'b0;
            trigger_b <= 1'b0;
            soft_reset_a <= 1'b0;
            soft_reset_b <= 1'b0;
            arb_wr_en <= 1'b0;
            arb_wr_addr <= 0;
            arb_wr_data <= 16'b0;
        end else begin
            // Auto-clear single-cycle pulse signals
            trigger_a <= 1'b0;
            trigger_b <= 1'b0;
            soft_reset_a <= 1'b0;
            soft_reset_b <= 1'b0;
            arb_wr_en <= 1'b0;  // Default: no write
            
            // Apply shadow registers to active on reconfig
            if (reconfig_pending) begin
                mode_a <= shadow_mode_a;
                mode_b <= shadow_mode_b;
                enable_a <= shadow_enable_a;
                enable_b <= shadow_enable_b;
                freq_a <= shadow_freq_a;
                freq_b <= shadow_freq_b;
                offset_a <= shadow_offset_a;
                offset_b <= shadow_offset_b;
                amp_a <= shadow_amp_a;
                amp_b <= shadow_amp_b;
                dtcyc_a <= shadow_dtcyc_a;
                dtcyc_b <= shadow_dtcyc_b;
                cycles_a <= shadow_cycles_a;
                cycles_b <= shadow_cycles_b;
                phase_off_a <= shadow_phase_off_a;
                phase_off_b <= shadow_phase_off_b;
                arb_waveform_depth <= shadow_arb_waveform_depth;
                reconfig_pending <= 1'b0;
            end
            
            if (wr) begin
                case (waddr[5:2])
                    MODE_REG:
                        if (axi_wstrb[0] == 1) begin
                            shadow_mode_a <= s_axi_wdata[3:0];
                            shadow_mode_b <= s_axi_wdata[7:4];
                        end
                    RUN_REG:
                       if (axi_wstrb[0] == 1) begin
                            // RUN register is applied immediately (no shadow)
                            {enable_b, enable_a} <= s_axi_wdata[1:0];
                            {shadow_enable_b, shadow_enable_a} <= s_axi_wdata[1:0];
                       end
                    FREQ_A_REG: 
                        for (byte_index = 0; byte_index <= 3; byte_index = byte_index + 1)
                            if (axi_wstrb[byte_index] == 1)
                                shadow_freq_a[(byte_index * 8) +: 8] <= s_axi_wdata[(byte_index * 8) +: 8];
                    FREQ_B_REG:
                        for (byte_index = 0; byte_index <= 3; byte_index = byte_index + 1)
                            if (axi_wstrb[byte_index] == 1)
                                shadow_freq_b[(byte_index * 8) +: 8] <= s_axi_wdata[(byte_index * 8) +: 8];
                    OFFSET_REG:
                    begin
                        for (byte_index = 0; byte_index <= 1; byte_index = byte_index + 1)
                            if (axi_wstrb[byte_index] == 1) 
                                shadow_offset_a[(byte_index * 8) +: 8] <= s_axi_wdata[(byte_index * 8) +: 8];
                                
                        for (byte_index = 2; byte_index <= 3; byte_index = byte_index + 1)
                            if (axi_wstrb[byte_index] == 1)
                                shadow_offset_b[((byte_index - 2) * 8) +: 8] <= s_axi_wdata[(byte_index * 8) +: 8];
                    end
                    AMPLTD_REG:
                    begin
                        for (byte_index = 0; byte_index <= 1; byte_index = byte_index + 1)
                            if (axi_wstrb[byte_index] == 1) 
                                shadow_amp_a[(byte_index * 8) +: 8] <= s_axi_wdata[(byte_index * 8) +: 8];
                                
                        for (byte_index = 2; byte_index <= 3; byte_index = byte_index + 1)
                            if (axi_wstrb[byte_index] == 1)
                                shadow_amp_b[((byte_index - 2) * 8) +: 8] <= s_axi_wdata[(byte_index * 8) +: 8];
                    end
                    DTCYC_REG:
                    begin
                        for (byte_index = 0; byte_index <= 1; byte_index = byte_index + 1)
                            if (axi_wstrb[byte_index] == 1) 
                                shadow_dtcyc_a[(byte_index * 8) +: 8] <= s_axi_wdata[(byte_index * 8) +: 8];
                                
                        for (byte_index = 2; byte_index <= 3; byte_index = byte_index + 1)
                            if (axi_wstrb[byte_index] == 1)
                                shadow_dtcyc_b[((byte_index - 2) * 8) +: 8] <= s_axi_wdata[(byte_index * 8) +: 8];
                    end 
                    CYCLES_REG:
                    begin
                        for (byte_index = 0; byte_index <= 1; byte_index = byte_index + 1)
                            if (axi_wstrb[byte_index] == 1)
                                shadow_cycles_a[(byte_index * 8) +: 8] <= s_axi_wdata[(byte_index * 8) +: 8];
                        
                        for (byte_index = 2; byte_index <= 3; byte_index = byte_index + 1)
                            if (axi_wstrb[byte_index] == 1)
                                shadow_cycles_b[((byte_index - 2) * 8) +: 8] <= s_axi_wdata[(byte_index * 8) +: 8];
                    end                    
                    PHASE_OFF_REG:
                    begin
                        for (byte_index = 0; byte_index <= 1; byte_index = byte_index + 1)
                            if (axi_wstrb[byte_index] == 1) 
                                shadow_phase_off_a[(byte_index * 8) +: 8] <= s_axi_wdata[(byte_index * 8) +: 8];
                                
                        for (byte_index = 2; byte_index <= 3; byte_index = byte_index + 1)
                            if (axi_wstrb[byte_index] == 1)
                                shadow_phase_off_b[((byte_index - 2) * 8) +: 8] <= s_axi_wdata[(byte_index * 8) +: 8];
                    end
                    ARB_DEPTH_REG:
                        for (byte_index = 0; byte_index <= 3; byte_index = byte_index + 1)
                            if (axi_wstrb[byte_index] == 1)
                                shadow_arb_waveform_depth[(byte_index * 8) +: 8] <= s_axi_wdata[(byte_index * 8) +: 8];
                    ARB_DATA_REG: begin
                        // ARB data: drive write interface to WaveForms module
                        arb_wr_en   <= 1'b1;
                        arb_wr_addr <= waddr[$clog2(ARB_WAVEFORM_DEPTH)+1:2];
                        arb_wr_data <= s_axi_wdata[15:0];
                    end
                    RECONFIG_REG:
                        reconfig_pending <= 1'b1;
                    TRIGGER_REG: begin
                        trigger_a <= s_axi_wdata[0];
                        trigger_b <= s_axi_wdata[1];
                    end
                    SOFT_RESET_REG: begin
                        soft_reset_a <= s_axi_wdata[0];
                        soft_reset_b <= s_axi_wdata[1];
                    end
                endcase
            end
        end
    end    

    // ========================================================================
    // Write response
    // ========================================================================
    wire wr_add_data_ready = axi_awready && axi_wready;
    always @(posedge axi_clk) begin
        if (axi_resetn == 1'b0) begin
            axi_bvalid  <= 0;
            axi_bresp   <= 2'b0;
        end else begin
            if (wr_add_data_valid && wr_add_data_ready && ~axi_bvalid) begin
                axi_bvalid <= 1'b1;
                axi_bresp  <= 2'b0;
            end else if (s_axi_bready && axi_bvalid) begin 
                axi_bvalid <= 1'b0; 
            end
        end
    end   

    // ========================================================================
    // Read address capture
    // ========================================================================
    reg [C_S_AXI_ADDR_WIDTH-1:0] raddr;
    always @(posedge axi_clk) begin
        if (axi_resetn == 1'b0) begin
            axi_arready <= 1'b0;
            raddr <= {C_S_AXI_ADDR_WIDTH{1'b0}};
        end else begin    
            if (axi_arvalid && ~axi_arready) begin
                axi_arready <= 1'b1;
                raddr  <= s_axi_araddr;
            end else begin
                axi_arready <= 1'b0;
            end
        end 
    end       
        
    // ========================================================================
    // Read data output
    // ========================================================================
    wire rd = axi_arvalid && axi_arready && ~axi_rvalid;
    always @(posedge axi_clk) begin
        if (axi_resetn == 1'b0) begin
            axi_rdata <= 32'b0;
        end else begin    
            if (rd) begin
                case (raddr[5:2])
                    MODE_REG: 
                        axi_rdata <= {24'b0, mode_b, mode_a};
                    RUN_REG:
                        axi_rdata <= {30'b0, enable_b, enable_a};
                    FREQ_A_REG: 
                        axi_rdata <= freq_a;
                    FREQ_B_REG: 
                        axi_rdata <= freq_b;
                    OFFSET_REG:
                        axi_rdata <= {offset_b, offset_a};
                    AMPLTD_REG:
                        axi_rdata <= {amp_b, amp_a};
                    DTCYC_REG:
                        axi_rdata <= {dtcyc_b, dtcyc_a};
                    CYCLES_REG:
                        axi_rdata <= {cycles_b, cycles_a};
                    PHASE_OFF_REG:
                        axi_rdata <= {phase_off_b, phase_off_a};
                    ARB_DEPTH_REG:
                        axi_rdata <= arb_waveform_depth;
                    ARB_DATA_REG:
                        axi_rdata <= 32'b0;  // ARB data is write-only (memory inside WaveForms)
                    STATUS_REG:
                        axi_rdata <= {28'b0, enable_b, enable_a, reconfig_pending, 1'b1};
                    default:
                        axi_rdata <= 32'b0;
                endcase
            end   
        end
    end    

    // ========================================================================
    // Read valid handshake
    // ========================================================================
    always @(posedge axi_clk) begin
        if (axi_resetn == 1'b0) begin
            axi_rvalid <= 1'b0;
            axi_rresp  <= 2'b0;
        end else begin
            if (axi_arvalid && axi_arready && ~axi_rvalid) begin
                axi_rvalid <= 1'b1;
                axi_rresp <= 2'b0;
            end else if (axi_rvalid && axi_rready) begin
                axi_rvalid <= 1'b0;
            end
        end
    end

endmodule