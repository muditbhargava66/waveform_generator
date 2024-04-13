`timescale 1ns / 1ps

module wavegen_tb;

    reg clk;
    reg en;
    wire signed [15:0] out_a;
    wire signed [15:0] out_b;

    wavegen_v1_0 #(
        .C_S00_AXI_DATA_WIDTH(32),
        .C_S00_AXI_ADDR_WIDTH(6),
        .SAMPLING_FREQUENCY(50000)
    ) dut (
        .clk(clk),
        .en(en),
        .out_a(out_a),
        .out_b(out_b),
        .s00_axi_aclk(clk),
        .s00_axi_aresetn(1'b1),
        .s00_axi_awaddr(6'b0),
        .s00_axi_awprot(3'b0),
        .s00_axi_awvalid(1'b0),
        .s00_axi_wdata(32'b0),
        .s00_axi_wstrb(4'b0),
        .s00_axi_wvalid(1'b0),
        .s00_axi_bready(1'b0),
        .s00_axi_araddr(6'b0),
        .s00_axi_arprot(3'b0),
        .s00_axi_arvalid(1'b0),
        .s00_axi_rready(1'b0)
    );

    initial begin
        clk = 0;
        en = 0;
        #10;
        en = 1;
        #1000;
        $finish;
    end

    always #5 clk = ~clk;

endmodule