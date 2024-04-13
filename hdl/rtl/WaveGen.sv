`timescale 1ns / 1ps

module WaveGen(
    input wire clk100,
    output wire [9:0] led,
    output wire [2:0] rgb0,
    output wire [2:0] rgb1,
    output wire [3:0] ss_anode,
    output wire [7:0] ss_cathode,
    input wire [11:0] sw,
    input wire [3:0] pb,
    inout wire [23:0] gpio,
    output wire [3:0] servo,
    output wire pdm_speaker,
    input wire pdm_mic_data,
    output wire pdm_mic_clk,
    output wire esp32_uart1_txd,
    input wire esp32_uart1_rxd,
    output wire imu_sclk,
    output wire imu_sdi,
    input wire imu_sdo_ag,
    input wire imu_sdo_m,
    output wire imu_cs_ag,
    output wire imu_cs_m,
    input wire imu_drdy_m,
    input wire imu_int1_ag,
    input wire imu_int_m,
    output wire imu_den_ag,
    inout wire [14:0] ddr_addr,
    inout wire [2:0] ddr_ba,
    inout wire ddr_cas_n,
    inout wire ddr_ck_n,
    inout wire ddr_ck_p,
    inout wire ddr_cke,
    inout wire ddr_cs_n,
    inout wire [3:0] ddr_dm,
    inout wire [31:0] ddr_dq,
    inout wire [3:0] ddr_dqs_n,
    inout wire [3:0] ddr_dqs_p,
    inout wire ddr_odt,
    inout wire ddr_ras_n,
    inout wire ddr_reset_n,
    inout wire ddr_we_n,
    inout wire fixed_io_ddr_vrn,
    inout wire fixed_io_ddr_vrp,
    inout wire [53:0] fixed_io_mio,
    inout wire fixed_io_ps_clk,
    inout wire fixed_io_ps_porb,
    inout wire fixed_io_ps_srstb
);
    // Terminate all of the unused outputs or i/o's
    assign led = 10'b0000000000;
    assign rgb0 = 3'b000;
    assign rgb1 = 3'b000;
    assign ss_anode = 4'b0000;
    assign ss_cathode = 8'b11111111;
    assign servo = 4'b0000;
    assign pdm_speaker = 1'b0;
    assign pdm_mic_clk = 1'b0;
    assign esp32_uart1_txd = 1'b0;
    assign imu_sclk = 1'b0;
    assign imu_sdi = 1'b0;
    assign imu_cs_ag = 1'b1;
    assign imu_cs_m = 1'b1;
    assign imu_den_ag = 1'b0;
    
    wire signed [15:0] out_a, out_b;

    wire [11:0] dac_a_out, dac_b_out;
    wire sdi, cs, ldac, sck;
    assign gpio = {4'b0, ldac, sdi, sck, cs, 16'b0};
    
    // Instantiate DACs
    voltsToDACWords #(
        .DAC_TWOPOINTFIVE(135),
        .DAC_ZERO(2079)
    ) dac_a (
        .in(out_a),
        .calibrated(dac_a_out)
    );
    
    voltsToDACWords #(
        .DAC_TWOPOINTFIVE(134),
        .DAC_ZERO(2071)
    ) dac_b (
        .in(out_b),
        .calibrated(dac_b_out)
    );
    
    DAC_Controller controller(
        .r1(dac_a_out),
        .r2(dac_b_out),
        .clk100(clk100),
        .cs(cs),
        .sclk(sck),
        .sdi(sdi),
        .ldac(ldac)
    );  
    
    system_wrapper system_wrapper_i (
        .DDR_addr(ddr_addr),
        .DDR_ba(ddr_ba),
        .DDR_cas_n(ddr_cas_n),
        .DDR_ck_n(ddr_ck_n),
        .DDR_ck_p(ddr_ck_p),
        .DDR_cke(ddr_cke),
        .DDR_cs_n(ddr_cs_n),
        .DDR_dm(ddr_dm),
        .DDR_dq(ddr_dq),
        .DDR_dqs_n(ddr_dqs_n),
        .DDR_dqs_p(ddr_dqs_p),
        .DDR_odt(ddr_odt),
        .DDR_ras_n(ddr_ras_n),
        .DDR_reset_n(ddr_reset_n),
        .DDR_we_n(ddr_we_n),
        .EN_0(ldac == 1'b0),
        .FIXED_IO_ddr_vrn(fixed_io_ddr_vrn),
        .FIXED_IO_ddr_vrp(fixed_io_ddr_vrp),
        .FIXED_IO_mio(fixed_io_mio),
        .FIXED_IO_ps_clk(fixed_io_ps_clk),
        .FIXED_IO_ps_porb(fixed_io_ps_porb),
        .FIXED_IO_ps_srstb(fixed_io_ps_srstb),
        .OUT_A_0(out_a),
        .OUT_B_0(out_b)
    );
endmodule