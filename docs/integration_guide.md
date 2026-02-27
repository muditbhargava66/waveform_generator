# Integration Guide — Waveform Generator

## Vivado Integration

### Creating the Block Design

1. **Create a new Vivado project** targeting your Zynq-7000 device (e.g., xc7z020clg400-1 for PYNQ-Z1)

2. **Add RTL sources**: Add all files from `hdl/rtl/` to the project
   ```
   hdl/rtl/WaveGen.sv
   hdl/rtl/DivideByN.sv
   hdl/rtl/sin_LUT.v
   hdl/rtl/waveforms/WaveForms.sv
   hdl/rtl/waveforms/SineWaves.sv
   hdl/rtl/waveforms/s2ui.sv
   hdl/rtl/dac/Calibration.sv
   hdl/rtl/dac/DAC_Controller.sv
   hdl/rtl/axi_lite/wavegen_v1_0.v
   hdl/rtl/axi_lite/wavegen_v1_0_S00_AXI.v
   ```

3. **Add the sine LUT hex file**: Copy `coe/sin_LUT.hex` to your Vivado project's simulation directory so `$readmemh` can find it. For synthesis, the file should be in the project root or set the path via simulation settings.

4. **Package as IP** (recommended):
   - Tools → Create and Package New IP → Package your current project
   - Set `wavegen_v1_0` as the top module
   - Configure the AXI4-Lite interface
   - Package the IP

5. **Create Block Design**:
   - Create a new block design
   - Add Zynq PS (ZYNQ7 Processing System)
   - Add your packaged `wavegen_v1_0` IP
   - Run Connection Automation to connect via AXI Interconnect
   - Make `out_a`, `out_b`, and `en` external

6. **Generate and Build**:
   - Generate block design
   - Create HDL wrapper (let Vivado auto-create)
   - Set `WaveGen.sv` as the top module (it wraps the block design)
   - Run Synthesis → Implementation → Generate Bitstream

### Standalone Synthesis (Without Zynq PS)

For simulation or testing without the Zynq PS:

1. Use `ip/system_wrapper.v` as a stub (AXI ports are tied off)
2. Set `WaveGen.sv` as the top module
3. Run synthesis — the design will synthesize with default register values

## Vitis Integration

### Baremetal Application

1. **Export hardware** from Vivado (File → Export → Export Hardware, include bitstream)
2. **Create Vitis workspace** and import the hardware platform
3. **Create a standalone application** project
4. **Add library files**: Copy `software/lib/wavegen_lib_baremetal.h` to your source directory

```c
#include "xparameters.h"
#include "wavegen_lib_baremetal.h"

int main(void)
{
    // Initialize with base address from xparameters.h
    wavegen_hw_init(XPAR_WAVEGEN_0_S00_AXI_BASEADDR);

    // Configure a 1 kHz sine wave on channel A
    wavegen_hw_configure(
        WAVEGEN_HW_CH_A,
        WAVEGEN_HW_SINE,
        10000000,   // 1 kHz
        32767,      // Full amplitude
        0,          // No offset
        32768,      // 50% duty (ignored for sine)
        0,          // No phase offset
        0           // Continuous
    );

    // Enable and start
    wavegen_hw_enable(WAVEGEN_HW_CH_A, 1);

    // Optionally trigger both channels simultaneously
    wavegen_hw_trigger_both();

    while (1) {
        // Application loop
    }

    return 0;
}
```

### Linux Application

1. **Build the kernel driver**:
   ```bash
   cd software/driver
   make
   sudo insmod wavegen.ko
   ```

2. **Use the library**:
   ```c
   #include "wavegen_lib.h"

   int main(void)
   {
       if (wavegen_init() != WAVEGEN_OK) {
           printf("Failed to initialize wavegen\n");
           return 1;
       }

       // Use a preset...
       wavegen_preset_1khz_sine(WAVEGEN_CH_A);
       wavegen_start(WAVEGEN_CH_A);

       // ...or configure manually
       wavegen_config_t config = {
           .mode = WAVEGEN_MODE_SQUARE,
           .frequency = 50000000,      // 5 kHz
           .amplitude = 16384,         // Half amplitude
           .offset = 0,
           .duty_cycle = 16384,        // 25% duty cycle
           .phase_offset = 9000,       // 90 degrees
           .cycles = 100               // 100 cycles then stop
       };
       wavegen_configure(WAVEGEN_CH_B, &config);
       wavegen_start(WAVEGEN_CH_B);

       // Wait, then clean up
       sleep(5);
       wavegen_stop(WAVEGEN_CH_BOTH);
       wavegen_close();
       return 0;
   }
   ```

   Compile:
   ```bash
   gcc -o wavegen_app main.c software/lib/wavegen_lib.c -I software/driver -I software/lib
   ```

## Simulation

### Using Vivado Simulator (xsim)

```bash
cd hdl/tb
xvlog --sv \
  ../rtl/axi_lite/wavegen_v1_0.v \
  ../rtl/axi_lite/wavegen_v1_0_S00_AXI.v \
  ../rtl/waveforms/WaveForms.sv \
  ../rtl/waveforms/SineWaves.sv \
  ../rtl/waveforms/s2ui.sv \
  ../rtl/sin_LUT.v \
  ../rtl/dac/Calibration.sv \
  ../rtl/dac/DAC_Controller.sv \
  ../rtl/DivideByN.sv \
  wavegen_tb.sv
xelab wavegen_tb -s wavegen_tb_sim
xsim wavegen_tb_sim -R
```

### Using Icarus Verilog

```bash
cd hdl/tb
iverilog -g2012 -o wavegen_tb.vvp \
  ../rtl/axi_lite/wavegen_v1_0.v \
  ../rtl/axi_lite/wavegen_v1_0_S00_AXI.v \
  ../rtl/waveforms/WaveForms.sv \
  ../rtl/waveforms/SineWaves.sv \
  ../rtl/waveforms/s2ui.sv \
  ../rtl/sin_LUT.v \
  ../rtl/dac/Calibration.sv \
  ../rtl/dac/DAC_Controller.sv \
  ../rtl/DivideByN.sv \
  wavegen_tb.sv
vvp wavegen_tb.vvp
```

## DAC Hardware Connection

The DAC controller outputs SPI signals on the GPIO bus:
- `gpio[16]` = CS (Chip Select, active low)
- `gpio[17]` = SCK (SPI Clock)
- `gpio[18]` = SDI (SPI Data In / MOSI)
- `gpio[19]` = LDAC (Load DAC, active low pulse)

Connect to a dual-channel SPI DAC (e.g., MCP4922, AD5628) with appropriate pin mapping in your XDC constraints file.

## Generating the Sine LUT

```bash
cd software/scripts
python coe.py --samples 512 --bits 16 --output-dir ../../coe --format all
```

Options:
- `--samples N`: Number of quarter-wave samples (default: 512)
- `--bits B`: Bit width per sample (default: 16)
- `--format {hex,coe,mem,both,all}`: Output format(s)
