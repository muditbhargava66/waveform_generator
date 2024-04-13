`timescale 1ns / 1ps

////////////////////////////////////
// Desscription : 
// This code implements an AXI4-Lite slave interface for the waveform generator. It handles the read and write transactions from the AXI4-Lite master and provides access to the internal registers of the waveform generator.
// The module instantiates the `WaveForms` module to generate the actual waveforms based on the configuration parameters stored in the internal registers. The generated waveforms are then scaled and offset based on the amplitude and offset settings before being output through `out_a` and `out_b`.
// The AXI4-Lite interface follows the standard protocol, with separate read and write channels. The module asserts the appropriate handshake signals (`awready`, `wready`, `bvalid`, `arready`, `rvalid`) to communicate with the AXI4-Lite master.
// When a write transaction occurs, the module captures the write address and data, and updates the corresponding internal registers based on the address and byte enables. When a read transaction occurs, the module provides the requested data from the internal registers based on the read address.
// The module also includes a reset signal (`axi_resetn`) to reset the internal registers and AXI4-Lite interface signals to their default values.
// Please note that this code assumes the presence of the `WaveForms` module, which should be defined separately.
////////////////////////////////////

module wavegen_v1_0_S00_AXI #(
    parameter integer C_S_AXI_ADDR_WIDTH = 6,
    parameter integer SAMPLING_FREQUENCY = 50000
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
    // Internal registers
    reg [2:0] mode_a, mode_b;
    reg enable_a, enable_b;
    reg [31:0] freq_a, freq_b;
    reg [15:0] offset_a, offset_b;
    reg [15:0] amp_a, amp_b;
    reg [15:0] dtcyc_a, dtcyc_b;
    reg [15:0] cycles_a, cycles_b;
    reg [15:0] phase_off_a, phase_off_b;
    
    wire signed [15:0] wave_a_value;
    wire signed [15:0] wave_b_value;
    
    wire signed [31:0] temp_a = $signed(amp_a) * wave_a_value;
    wire signed [31:0] temp_b = $signed(amp_b) * wave_b_value;
    
    assign out_a = enable_a ? ((temp_a >>> 15) + offset_a) : 16'd0;
    assign out_b = enable_b ? ((temp_b >>> 15) + offset_b) : 16'd0;
    
    // Wave instantiations  
    WaveForms #(
        .SAMPLING_FREQUENCY(SAMPLING_FREQUENCY)
    ) waves (
        .clk(sample_clk),
        .lut_clk(lut_clk),
        .ena(enable_a),
        .enb(enable_b),
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
        .wave_a(wave_a_value),
        .wave_b(wave_b_value)
    );
    
    // Register map
    // ofs  fn
    //   0  mode (r/w)   -
    //   4  run (r/w)    -
    //   8  freqA (r/w) units of 100uHz
    //  12  freqB (r/w) units of 100uHz
    //  16  offset (r/w) units of 100uV
    //  20  ampltd (r/w) units of 100uV
    //  24  dtcyc (r/w) units of 100%/2**16
    //  28  cycles (r/w) units of 1 cycle
    //  32  phase_off (r/w) units of 0.01 degrees (-180 to 180)
    
    // Register numbers
    localparam integer MODE_REG       = 4'b0000;
    localparam integer RUN_REG        = 4'b0001;
    localparam integer FREQ_A_REG     = 4'b0010;
    localparam integer FREQ_B_REG     = 4'b0011;
    localparam integer OFFSET_REG     = 4'b0100;
    localparam integer AMPLTD_REG     = 4'b0101;
    localparam integer DTCYC_REG      = 4'b0110;
    localparam integer CYCLES_REG     = 4'b0111;
    localparam integer PHASE_OFF_REG  = 4'b1000;
    
    // AXI4-lite signals
    reg axi_awready;
    reg axi_wready;
    reg [1:0] axi_bresp;
    reg axi_bvalid;
    reg axi_arready;
    reg [31:0] axi_rdata;
    reg [1:0] axi_rresp;
    reg axi_rvalid;
    
    // Friendly clock, reset, and bus signals from master
    wire axi_clk = s_axi_aclk;
    wire axi_resetn = s_axi_aresetn;
    wire [31:0] axi_awaddr = s_axi_awaddr;
    wire axi_awvalid = s_axi_awvalid;
    wire axi_wvalid = s_axi_wvalid;
    wire [3:0] axi_wstrb = s_axi_wstrb;
    wire axi_bready = s_axi_bready;
    wire [31:0] axi_araddr = s_axi_araddr;
    wire axi_arvalid = s_axi_arvalid;
    wire axi_rready = s_axi_rready;    
    
    // Assign bus signals to master to internal reg names
    assign s_axi_awready = axi_awready;
    assign s_axi_wready = axi_wready;
    assign s_axi_bresp = axi_bresp;
    assign s_axi_bvalid = axi_bvalid;
    assign s_axi_arready = axi_arready;
    assign s_axi_rdata = axi_rdata;
    assign s_axi_rresp = axi_rresp;
    assign s_axi_rvalid = axi_rvalid;
  
    // Assert address ready handshake (axi_awready) 
    // - after address is valid (axi_awvalid)
    // - after data is valid (axi_wvalid)
    // - while configured to receive a write (aw_en)
    // De-assert ready (axi_awready)
    // - after write response channel ready handshake received (axi_bready)
    // - after this module sends write response channel valid (axi_bvalid) 
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

    // Capture the write address (axi_awaddr) in the first clock (~axi_awready)
    // - after write address is valid (axi_awvalid)
    // - after write data is valid (axi_wvalid)
    // - while configured to receive a write (aw_en)
    reg [C_S_AXI_ADDR_WIDTH-1:0] waddr;
    always @(posedge axi_clk) begin
        if (axi_resetn == 1'b0) begin
            waddr <= 0;
        end else if (wr_add_data_valid && ~axi_awready && aw_en) begin
            waddr <= axi_awaddr;
        end
    end

    // Output write data ready handshake (axi_wready) generation for one clock
    // - after address is valid (axi_awvalid)
    // - after data is valid (axi_wvalid)
    // - while configured to receive a write (aw_en)
    always @(posedge axi_clk) begin
        if (axi_resetn == 1'b0) begin
            axi_wready <= 1'b0;
        end else begin
            axi_wready <= (wr_add_data_valid && ~axi_wready && aw_en);
        end
    end       

    // Write data to internal registers
    // - after address is valid (axi_awvalid)
    // - after write data is valid (axi_wvalid)
    // - after this module asserts ready for address handshake (axi_awready)
    // - after this module asserts ready for data handshake (axi_wready)
    // Write correct bytes in 32-bit word based on byte enables (axi_wstrb)
    wire wr = wr_add_data_valid && axi_awready && axi_wready;
    integer byte_index;
    always @(posedge axi_clk) begin
        if (axi_resetn == 1'b0) begin
            mode_a <= 3'b0;
            mode_b <= 3'b0;
            enable_a <= 1'b1;
            enable_b <= 1'b1;
            freq_a <= 32'b0;
            freq_b <= 32'b0;
            offset_a <= 16'b0;
            offset_b <= 16'b0;
            amp_a <= 16'b0;
            amp_b <= 16'b0;
            dtcyc_a <= 16'b0;
            dtcyc_b <= 16'b0;
            cycles_a <= 16'b0;
            cycles_b <= 16'b0;
            phase_off_a <= 16'b0;
            phase_off_b <= 16'b0;
        end else begin
            if (wr) begin
                case (waddr[5:2])
                    MODE_REG:
                        if (axi_wstrb[0] == 1)
                            {mode_b, mode_a} <= s_axi_wdata[5:0];
                    RUN_REG:
                       if (axi_wstrb[0] == 1)
                            {enable_b, enable_a} <= s_axi_wdata[1:0];
                    FREQ_A_REG: 
                        for (byte_index = 0; byte_index <= 3; byte_index = byte_index + 1)
                            if (axi_wstrb[byte_index] == 1)
                                freq_a[(byte_index * 8) +: 8] <= s_axi_wdata[(byte_index * 8) +: 8];
                    FREQ_B_REG:
                        for (byte_index = 0; byte_index <= 3; byte_index = byte_index + 1)
                            if (axi_wstrb[byte_index] == 1)
                                freq_b[(byte_index * 8) +: 8] <= s_axi_wdata[(byte_index * 8) +: 8];
                    OFFSET_REG:
                    begin
                        for (byte_index = 0; byte_index <= 1; byte_index = byte_index + 1)
                            if (axi_wstrb[byte_index] == 1) 
                                offset_a[(byte_index * 8) +: 8] <= s_axi_wdata[(byte_index * 8) +: 8];
                                
                        for (byte_index = 2; byte_index <= 3; byte_index = byte_index + 1)
                            if (axi_wstrb[byte_index] == 1)
                                offset_b[((byte_index - 2) * 8) +: 8] <= s_axi_wdata[(byte_index * 8) +: 8];
                    end
                    AMPLTD_REG:
                    begin
                        for (byte_index = 0; byte_index <= 1; byte_index = byte_index + 1)
                            if (axi_wstrb[byte_index] == 1) 
                                amp_a[(byte_index * 8) +: 8] <= s_axi_wdata[(byte_index * 8) +: 8];
                                
                        for (byte_index = 2; byte_index <= 3; byte_index = byte_index + 1)
                            if (axi_wstrb[byte_index] == 1)
                                amp_b[((byte_index - 2) * 8) +: 8] <= s_axi_wdata[(byte_index * 8) +: 8];
                    end
                    DTCYC_REG:
                    begin
                        for (byte_index = 0; byte_index <= 1; byte_index = byte_index + 1)
                            if (axi_wstrb[byte_index] == 1) 
                                dtcyc_a[(byte_index * 8) +: 8] <= s_axi_wdata[(byte_index * 8) +: 8];
                                
                        for (byte_index = 2; byte_index <= 3; byte_index = byte_index + 1)
                            if (axi_wstrb[byte_index] == 1)
                                dtcyc_b[((byte_index - 2) * 8) +: 8] <= s_axi_wdata[(byte_index * 8) +: 8];
                    end
                    CYCLES_REG:
                    begin
                        for (byte_index = 0; byte_index <= 1; byte_index = byte_index + 1)
                            if (axi_wstrb[byte_index] == 1) 
                                cycles_a[(byte_index * 8) +: 8] <= s_axi_wdata[(byte_index * 8) +: 8];
                                
                        for (byte_index = 2; byte_index <= 3; byte_index = byte_index + 1)
                            if (axi_wstrb[byte_index] == 1)
                                cycles_b[((byte_index - 2) * 8) +: 8] <= s_axi_wdata[(byte_index * 8) +: 8];
                    end
                    PHASE_OFF_REG:
                    begin
                        for (byte_index = 0; byte_index <= 1; byte_index = byte_index + 1)
                            if (axi_wstrb[byte_index] == 1)
                                phase_off_a[(byte_index * 8) +: 8] <= s_axi_wdata[(byte_index * 8) +: 8];

                        for (byte_index = 2; byte_index <= 3; byte_index = byte_index + 1)
                            if (axi_wstrb[byte_index] == 1)
                                phase_off_b[((byte_index - 2) * 8) +: 8] <= s_axi_wdata[(byte_index * 8) +: 8];
                    end
                endcase
            end
        end
    end    

    // Send write response (axi_bvalid, axi_bresp)
    // - after address is valid (axi_awvalid)
    // - after write data is valid (axi_wvalid)
    // - after this module asserts ready for address handshake (axi_awready)
    // - after this module asserts ready for data handshake (axi_wready)
    // Clear write response valid (axi_bvalid) after one clock
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

    // In the first clock (~axi_arready) that the read address is valid
    // - capture the address (axi_araddr)
    // - output ready (axi_arready) for one clock
    reg [C_S_AXI_ADDR_WIDTH-1:0] raddr;
    always @(posedge axi_clk) begin
        if (axi_resetn == 1'b0) begin
            axi_arready <= 1'b0;
            raddr <= 32'b0;
        end else begin    
            // if valid, pulse ready (axi_rready) for one clock and save address
            if (axi_arvalid && ~axi_arready) begin
                axi_arready <= 1'b1;
                raddr  <= axi_araddr;
            end else begin
                axi_arready <= 1'b0;
            end
        end 
    end       
        
    // Update register read data
    // - after this module receives a valid address (axi_arvalid)
    // - after this module asserts ready for address handshake (axi_arready)
    // - before the module asserts the data is valid (~axi_rvalid)
    //   (don't change the data while asserting read data is valid)
    wire rd = axi_arvalid && axi_arready && ~axi_rvalid;
    always @(posedge axi_clk) begin
        if (axi_resetn == 1'b0) begin
            axi_rdata <= 32'b0;
        end else begin    
            if (rd) begin
                // Address decoding for reading registers
                case (raddr[5:2])
                    MODE_REG: 
                        axi_rdata <= {26'b0, mode_b, mode_a};
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
                endcase
            end   
        end
    end    

    // Assert data is valid for reading (axi_rvalid)
    // - after address is valid (axi_arvalid)
    // - after this module asserts ready for address handshake (axi_arready)
    // De-assert data valid (axi_rvalid) 
    // - after master ready handshake is received (axi_rready)
    always @(posedge axi_clk) begin
        if (axi_resetn == 1'b0) begin
            axi_rvalid <= 1'b0;
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