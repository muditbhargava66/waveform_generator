`timescale 1ns / 1ps

//////////////////////////////////////////////////////////////////////////////
// Module: wavegen_tb
//
// Comprehensive testbench for the Waveform Generator IP.
//
// Tests:
//   1. AXI write/read register access
//   2. All waveform modes (DC, Sine, Sawtooth, Triangle, Square, Arbitrary)
//   3. Dynamic reconfiguration (shadow register system)
//   4. Software trigger
//   5. Soft reset
//   6. Dual-channel operation
//
// Self-checking: Verifies register readback matches written values.
// Waveform output can be inspected visually in the waveform viewer.
//////////////////////////////////////////////////////////////////////////////

module wavegen_tb;

    // ====================================================================
    // Clock and reset
    // ====================================================================
    reg clk = 0;
    reg resetn = 0;

    always #5 clk = ~clk;  // 100 MHz

    // ====================================================================
    // AXI signals
    // ====================================================================
    localparam ADDR_WIDTH = 14;

    reg  [ADDR_WIDTH-1:0] axi_awaddr;
    reg  [2:0]            axi_awprot;
    reg                   axi_awvalid;
    wire                  axi_awready;

    reg  [31:0]           axi_wdata;
    reg  [3:0]            axi_wstrb;
    reg                   axi_wvalid;
    wire                  axi_wready;

    wire [1:0]            axi_bresp;
    wire                  axi_bvalid;
    reg                   axi_bready;

    reg  [ADDR_WIDTH-1:0] axi_araddr;
    reg  [2:0]            axi_arprot;
    reg                   axi_arvalid;
    wire                  axi_arready;

    wire [31:0]           axi_rdata;
    wire [1:0]            axi_rresp;
    wire                  axi_rvalid;
    reg                   axi_rready;

    // ====================================================================
    // DUT outputs
    // ====================================================================
    wire signed [15:0] out_a, out_b;
    reg en;

    // ====================================================================
    // DUT instantiation
    // ====================================================================
    wavegen_v1_0 #(
        .C_S00_AXI_DATA_WIDTH(32),
        .C_S00_AXI_ADDR_WIDTH(ADDR_WIDTH),
        .SAMPLING_FREQUENCY(50000),
        .ARB_WAVEFORM_DEPTH(1024)
    ) dut (
        .clk(clk),
        .en(en),
        .out_a(out_a),
        .out_b(out_b),
        .s00_axi_aclk(clk),
        .s00_axi_aresetn(resetn),
        .s00_axi_awaddr(axi_awaddr),
        .s00_axi_awprot(axi_awprot),
        .s00_axi_awvalid(axi_awvalid),
        .s00_axi_awready(axi_awready),
        .s00_axi_wdata(axi_wdata),
        .s00_axi_wstrb(axi_wstrb),
        .s00_axi_wvalid(axi_wvalid),
        .s00_axi_wready(axi_wready),
        .s00_axi_bresp(axi_bresp),
        .s00_axi_bvalid(axi_bvalid),
        .s00_axi_bready(axi_bready),
        .s00_axi_araddr(axi_araddr),
        .s00_axi_arprot(axi_arprot),
        .s00_axi_arvalid(axi_arvalid),
        .s00_axi_arready(axi_arready),
        .s00_axi_rdata(axi_rdata),
        .s00_axi_rresp(axi_rresp),
        .s00_axi_rvalid(axi_rvalid),
        .s00_axi_rready(axi_rready)
    );

    // ====================================================================
    // Test counters
    // ====================================================================
    integer test_pass = 0;
    integer test_fail = 0;
    integer test_num  = 0;

    // ====================================================================
    // AXI Write Task
    // ====================================================================
    task axi_write;
        input [ADDR_WIDTH-1:0] addr;
        input [31:0] data;
        input [3:0] strb;
        begin
            @(posedge clk);
            axi_awaddr  <= addr;
            axi_awprot  <= 3'b0;
            axi_awvalid <= 1'b1;
            axi_wdata   <= data;
            axi_wstrb   <= strb;
            axi_wvalid  <= 1'b1;
            axi_bready  <= 1'b1;

            // Wait for both ready signals
            @(posedge clk);
            while (!(axi_awready && axi_wready))
                @(posedge clk);
            
            axi_awvalid <= 1'b0;
            axi_wvalid  <= 1'b0;

            // Wait for write response
            while (!axi_bvalid)
                @(posedge clk);

            axi_bready <= 1'b0;
            @(posedge clk);
        end
    endtask

    // ====================================================================
    // AXI Write (full word, wrstrb=0xF)
    // ====================================================================
    task axi_write_word;
        input [ADDR_WIDTH-1:0] addr;
        input [31:0] data;
        begin
            axi_write(addr, data, 4'hF);
        end
    endtask

    // ====================================================================
    // AXI Read Task
    // ====================================================================
    task axi_read;
        input  [ADDR_WIDTH-1:0] addr;
        output [31:0]           data;
        begin
            @(posedge clk);
            axi_araddr  <= addr;
            axi_arprot  <= 3'b0;
            axi_arvalid <= 1'b1;
            axi_rready  <= 1'b1;

            // Wait for address ready
            @(posedge clk);
            while (!axi_arready)
                @(posedge clk);
            
            axi_arvalid <= 1'b0;

            // Wait for data valid
            while (!axi_rvalid)
                @(posedge clk);

            data = axi_rdata;
            axi_rready <= 1'b0;
            @(posedge clk);
        end
    endtask

    // ====================================================================
    // Check task: compare expected vs actual
    // ====================================================================
    task check;
        input [31:0] expected;
        input [31:0] actual;
        input [255:0] msg;
        begin
            test_num = test_num + 1;
            if (expected === actual) begin
                test_pass = test_pass + 1;
                $display("  [PASS] Test %0d: %0s (0x%08X)", test_num, msg, actual);
            end else begin
                test_fail = test_fail + 1;
                $display("  [FAIL] Test %0d: %0s - Expected 0x%08X, Got 0x%08X",
                         test_num, msg, expected, actual);
            end
        end
    endtask

    // ====================================================================
    // Main test sequence
    // ====================================================================
    reg [31:0] read_data;

    initial begin
        // VCD dump for waveform viewing
        $dumpfile("wavegen_tb.vcd");
        $dumpvars(0, wavegen_tb);

        // Initialize AXI signals
        axi_awaddr  = 0;
        axi_awprot  = 0;
        axi_awvalid = 0;
        axi_wdata   = 0;
        axi_wstrb   = 0;
        axi_wvalid  = 0;
        axi_bready  = 0;
        axi_araddr  = 0;
        axi_arprot  = 0;
        axi_arvalid = 0;
        axi_rready  = 0;
        en          = 0;

        // ============================================================
        // Reset sequence
        // ============================================================
        $display("\n========================================");
        $display("Waveform Generator Testbench");
        $display("========================================\n");

        resetn = 0;
        repeat (10) @(posedge clk);
        resetn = 1;
        repeat (5) @(posedge clk);

        // ============================================================
        // Test 1: Register write/read verification
        // (shadow registers require RECONFIG before readback)
        // ============================================================
        $display("--- Test Group 1: Register Access ---");

        // Write shadow registers
        axi_write_word(14'h00, 32'h00000012);  // mode_a=2(SAW), mode_b=1(SINE)
        axi_write_word(14'h08, 32'h00989680);  // freq_a = 1 kHz
        axi_write_word(14'h0C, 32'h01312D00);  // freq_b = 2 kHz
        axi_write_word(14'h14, 32'h7FFF7FFF);  // Both channels full amplitude
        axi_write_word(14'h10, 32'h00000000);  // Both channels zero offset
        axi_write_word(14'h18, 32'h80008000);  // 50% duty cycle both

        // Apply shadows to active via RECONFIG
        axi_write_word(14'h2C, 32'h00000001);
        repeat (5) @(posedge clk);

        // Now read back active registers
        axi_read(14'h00, read_data);
        check(32'h00000012, read_data, "MODE register (after reconfig)");

        axi_read(14'h08, read_data);
        check(32'h00989680, read_data, "FREQ_A register (after reconfig)");

        axi_read(14'h0C, read_data);
        check(32'h01312D00, read_data, "FREQ_B register (after reconfig)");

        axi_read(14'h14, read_data);
        check(32'h7FFF7FFF, read_data, "AMPLTD register (packed)");

        axi_read(14'h10, read_data);
        check(32'h00000000, read_data, "OFFSET register (packed)");

        axi_read(14'h18, read_data);
        check(32'h80008000, read_data, "DTCYC register (packed)");

        // Read STATUS register
        axi_read(14'h30, read_data);
        $display("  [INFO] STATUS = 0x%08X (ready=%b)", read_data, read_data[0]);

        // ============================================================
        // Test 2: Dynamic reconfiguration
        // ============================================================
        $display("\n--- Test Group 2: Dynamic Reconfiguration ---");

        // Configure for sine wave on channel A via shadow registers
        axi_write_word(14'h00, 32'h00000001);  // mode_a=1(SINE)
        axi_write_word(14'h08, 32'h00989680);  // freq_a = 1 kHz
        axi_write_word(14'h14, 32'h7FFF7FFF);  // full amplitude both

        // Apply via RECONFIG
        axi_write_word(14'h2C, 32'h00000001);  // Trigger reconfig
        repeat (5) @(posedge clk);

        // Enable and verify
        axi_write_word(14'h04, 32'h00000003);  // Enable both channels
        en = 1;
        $display("  [INFO] Reconfiguration applied, channels enabled");

        // ============================================================
        // Test 3: Sine wave output
        // ============================================================
        $display("\n--- Test Group 3: Sine Wave Output ---");
        repeat (2000) @(posedge clk);
        $display("  [INFO] Sine wave running for 2000 cycles");
        $display("  [INFO] out_a = %0d, out_b = %0d", out_a, out_b);

        // ============================================================
        // Test 4: Mode change to square wave
        // ============================================================
        $display("\n--- Test Group 4: Square Wave ---");
        axi_write_word(14'h00, 32'h00000044);  // mode_a=4(SQUARE), mode_b=4(SQUARE)
        axi_write_word(14'h2C, 32'h00000001);  // Reconfig
        repeat (2000) @(posedge clk);
        $display("  [INFO] Square wave running, out_a = %0d", out_a);

        // ============================================================
        // Test 5: Triangle wave
        // ============================================================
        $display("\n--- Test Group 5: Triangle Wave ---");
        axi_write_word(14'h00, 32'h00000033);  // mode=3(TRIANGLE) both
        axi_write_word(14'h2C, 32'h00000001);
        repeat (2000) @(posedge clk);
        $display("  [INFO] Triangle wave running, out_a = %0d", out_a);

        // ============================================================
        // Test 6: Sawtooth wave
        // ============================================================
        $display("\n--- Test Group 6: Sawtooth Wave ---");
        axi_write_word(14'h00, 32'h00000022);  // mode=2(SAWTOOTH) both
        axi_write_word(14'h2C, 32'h00000001);
        repeat (2000) @(posedge clk);
        $display("  [INFO] Sawtooth wave running, out_a = %0d", out_a);

        // ============================================================
        // Test 7: Software trigger
        // ============================================================
        $display("\n--- Test Group 7: Software Trigger ---");
        axi_write_word(14'h34, 32'h00000003);  // Trigger both channels
        repeat (100) @(posedge clk);
        $display("  [INFO] Trigger sent, channels re-synced");

        // ============================================================
        // Test 8: Soft reset
        // ============================================================
        $display("\n--- Test Group 8: Soft Reset ---");
        axi_write_word(14'h38, 32'h00000003);  // Reset both channels
        repeat (10) @(posedge clk);
        $display("  [INFO] After soft reset: out_a = %0d, out_b = %0d", out_a, out_b);

        // Re-enable after reset
        axi_write_word(14'h04, 32'h00000003);
        repeat (500) @(posedge clk);

        // ============================================================
        // Test 9: Arbitrary waveform
        // ============================================================
        $display("\n--- Test Group 9: Arbitrary Waveform ---");
        axi_write_word(14'h00, 32'h00000055);  // mode=5(ARB) both
        axi_write_word(14'h24, 32'h00000010);  // depth=16 samples
        axi_write_word(14'h2C, 32'h00000001);

        // Load a simple ramp: 0, 2048, 4096, ..., 30720
        begin : arb_load
            integer i;
            for (i = 0; i < 16; i = i + 1) begin
                axi_write_word(14'h28 + i * 4, i * 2048);
            end
        end

        repeat (2000) @(posedge clk);
        $display("  [INFO] Arbitrary waveform running, out_a = %0d", out_a);

        // ============================================================
        // Test 10: Frequency change during operation
        // ============================================================
        $display("\n--- Test Group 10: Dynamic Frequency Change ---");
        axi_write_word(14'h00, 32'h00000011);  // mode=1(SINE) both
        axi_write_word(14'h08, 32'h02FAF080);  // 50,000,000 = 5 kHz
        axi_write_word(14'h2C, 32'h00000001);  // Reconfig
        repeat (2000) @(posedge clk);
        $display("  [INFO] 5 kHz sine wave, out_a = %0d", out_a);

        // ============================================================
        // Summary
        // ============================================================
        $display("\n========================================");
        $display("Test Summary: %0d passed, %0d failed out of %0d",
                 test_pass, test_fail, test_num);
        $display("========================================\n");

        if (test_fail > 0)
            $display("*** SOME TESTS FAILED ***");
        else
            $display("*** ALL TESTS PASSED ***");

        $finish;
    end

    // ====================================================================
    // Timeout watchdog
    // ====================================================================
    initial begin
        #500000;
        $display("\n*** TIMEOUT: Simulation exceeded 500us ***");
        $finish;
    end

endmodule