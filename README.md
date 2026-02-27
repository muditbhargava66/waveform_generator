# Waveform Generator

A dual-channel, AXI4-Lite controlled waveform generator IP core for Xilinx Zynq-7000 SoC platforms. Generates DC, sine, sawtooth, triangle, square, and arbitrary waveforms with configurable parameters. Interfaces with external DACs via SPI.

## Features
- **Dual independent channels** (A and B) with per-channel configuration
- **6 waveform modes**: DC, Sine, Sawtooth, Triangle, Square, Arbitrary
- **Configurable parameters**: frequency, amplitude, offset, duty cycle, phase offset, number of cycles
- **AXI4-Lite register interface** with shadow registers for glitch-free atomic updates
- **Software trigger** for synchronized dual-channel start
- **Per-channel soft reset** and status readback
- **Quarter-wave sine LUT** (512 entries, 16-bit, ~100 dB SNR)
- **Arbitrary waveform** support with configurable depth (up to 4096 samples)
- **Fixed-point arithmetic** — no runtime division, fully synthesizable
- **Vivado 2023.2 verified** — all files pass `xvlog` and `xelab` with zero errors
- **High-level libraries**: Linux userspace (`wavegen_lib`) and baremetal/Vitis (`wavegen_lib_baremetal`)
- **Linux kernel driver** with IOCTL interface and safe user-space memory access

## Directory Structure
```
waveform_generator/
├── hdl/
│   ├── rtl/
│   │   ├── WaveGen.sv                  # Top-level module (Zynq + DAC)
│   │   ├── DivideByN.sv               # Parameterized clock divider
│   │   ├── sin_LUT.v                   # Dual-port sine LUT (BRAM)
│   │   ├── waveforms/
│   │   │   ├── WaveForms.sv            # Phase-accumulator waveform engine
│   │   │   └── SineWaves.sv            # Quarter-wave sine synthesis
│   │   ├── axi_lite/
│   │   │   ├── wavegen_v1_0_S00_AXI.v  # AXI4-Lite slave (shadow regs)
│   │   │   └── wavegen_v1_0.v          # AXI IP wrapper
│   │   └── dac/
│   │       ├── Calibration.sv          # Voltage-to-DAC calibration
│   │       └── DAC_Controller.sv       # SPI DAC controller
│   └── tb/
│       └── wavegen_tb.sv              # Self-checking testbench
├── ip/
│   └── system_wrapper.v              # Zynq PS block design stub
├── coe/
│   ├── sin_LUT.hex                    # Hex LUT ($readmemh)
│   └── sin_LUT.coe                    # Xilinx COE (Block RAM IP)
├── software/
│   ├── driver/
│   │   ├── wavegen_driver.c           # Linux kernel driver
│   │   ├── wavegen_ip.c               # Register access functions
│   │   ├── wavegen_ip.h               # IOCTL definitions
│   │   ├── wavegen_regs.h             # Register map
│   │   └── Makefile
│   ├── scripts/
│   │   └── coe.py                     # Sine LUT generator
│   └── lib/
│       ├── wavegen_lib.h              # Linux userspace library
│       ├── wavegen_lib.c
│       └── wavegen_lib_baremetal.h     # Baremetal/Vitis library
├── docs/
│   ├── user_manual.md
│   ├── api_reference.md
│   └── integration_guide.md
└── README.md
```

## Quick Start

### 1. Generate the Sine LUT
```bash
cd software/scripts
python coe.py --samples 512 --bits 16 --output-dir ../../coe --format both
```

### 2. Verify HDL with Vivado
```bash
# Syntax check
xvlog --sv hdl/rtl/waveforms/*.sv hdl/rtl/dac/*.sv hdl/rtl/*.sv hdl/rtl/*.v hdl/rtl/axi_lite/*.v ip/*.v

# Elaboration (testbench)
xvlog --sv hdl/tb/wavegen_tb.sv
xelab wavegen_tb -s wavegen_tb_sim --debug off
xsim wavegen_tb_sim -R
```

### 3. Build for Hardware
- Open Vivado, create a block design with Zynq PS
- Add `wavegen_v1_0` as a custom AXI peripheral
- Generate bitstream → program FPGA

### 4. Software Integration

**Baremetal (Vitis)**:
```c
#include "wavegen_lib_baremetal.h"
wavegen_hw_init(XPAR_WAVEGEN_0_S00_AXI_BASEADDR);
wavegen_hw_configure(WAVEGEN_HW_CH_A, WAVEGEN_HW_SINE,
                     10000000, 32767, 0, 32768, 0, 0); // 1 kHz sine
wavegen_hw_enable(WAVEGEN_HW_CH_A, 1);
```

**Linux**:
```c
#include "wavegen_lib.h"
wavegen_init();
wavegen_preset_1khz_sine(WAVEGEN_CH_A);
wavegen_start(WAVEGEN_CH_A);
```

## Documentation
- [User Manual](docs/user_manual.md) — Register map, architecture, usage flow
- [API Reference](docs/api_reference.md) — Library functions, IOCTLs, error codes
- [Integration Guide](docs/integration_guide.md) — Vivado/Vitis setup, simulation, DAC pinout

## Completed Tasks
- [x] Improve the sine LUT generation script for better accuracy
- [x] Add support for arbitrary waveform generation
- [x] Implement dynamic reconfiguration of waveform parameters
- [x] Enhance the driver with real-time waveform updates and triggers
- [x] Develop a high-level software library for easier integration
- [x] Optimize the HDL code for resource utilization and performance

## License
This project is licensed under the [MIT License](LICENSE).