# Release Notes

## v1.0.0 (2026-02-27)

Initial stable release of the Waveform Generator IP core.

### HDL Core

- Dual-channel phase-accumulator waveform engine supporting DC, sine, sawtooth, triangle, square, and arbitrary waveform modes.
- Quarter-wave sine synthesis via 512-entry, 16-bit LUT (BRAM-inferred). Full waveform is reconstructed using sign and direction symmetry bits.
- AXI4-Lite register interface with shadow register system for glitch-free atomic parameter updates.
- Software trigger register for synchronized dual-channel start.
- Per-channel soft reset and status readback register.
- Arbitrary waveform support with configurable depth (up to 4096 samples) and a dedicated write interface for loading sample data.
- SPI DAC controller with 12-bit output and voltage-to-DAC word calibration using fixed-point arithmetic (no runtime division).
- All arithmetic uses synthesizable fixed-point multiplication with compile-time reciprocal constants. No division operators are inferred.
- Parameterized design: sampling frequency, ARB waveform depth, and DAC calibration values are all configurable.
- Verified with Vivado 2023.2 (xvlog + xelab, zero errors across all 11 source files).

### Software

- Linux kernel driver with IOCTL interface for all waveform parameters, bulk arbitrary waveform upload, trigger, reconfig, soft reset, and status readback. Proper copy_from_user/copy_to_user for kernel safety.
- Linux userspace library (wavegen_lib) with batch configuration, preset waveforms, error codes, and convenience functions (start, stop, apply, trigger).
- Baremetal/Vitis standalone library (wavegen_lib_baremetal.h), header-only with inline functions using direct MMIO access. Supports Xilinx Xil_Out32/Xil_In32 or generic volatile pointer access.

### LUT Generation

- Python script (coe.py) generates quarter-wave sine LUT with high-precision decimal arithmetic. Outputs hex format (for Verilog readmemh) and Xilinx COE format (for Block RAM IP). Includes SNR and error analysis.
- Measured SNR: approximately 100.7 dB for 512 samples at 16-bit resolution.

### Testbench

- Self-checking testbench with AXI4-Lite write/read tasks. Tests all waveform modes, dynamic reconfiguration, shadow register readback, software trigger, soft reset, and dual-channel operation. Includes timeout watchdog and VCD waveform dump.

### Documentation

- User manual with register map, architecture diagram, shadow register documentation, and frequency calculation.
- API reference covering the Linux library, baremetal library, and kernel IOCTL interface.
- Integration guide with step-by-step instructions for Vivado block design, Vitis baremetal application, Linux driver build, and simulation commands (xvlog/xelab/xsim and Icarus Verilog).

### Known Issues

- The xsim simulation kernel (xsimk.exe) may be missing from some Vivado 2023.2 installations on Windows. This is a Vivado installation issue; syntax checking and elaboration work correctly. Reinstalling Vivado with the simulator component should resolve this.
- The sin_LUT.hex file path in sin_LUT.v uses a relative path (coe/sin_LUT.hex). For Vivado synthesis, either set the file search path in project settings or copy the hex file to the project root.

### Files in This Release

HDL sources (10 files):
- hdl/rtl/WaveGen.sv
- hdl/rtl/DivideByN.sv
- hdl/rtl/sin_LUT.v
- hdl/rtl/waveforms/WaveForms.sv
- hdl/rtl/waveforms/SineWaves.sv
- hdl/rtl/axi_lite/wavegen_v1_0_S00_AXI.v
- hdl/rtl/axi_lite/wavegen_v1_0.v
- hdl/rtl/dac/Calibration.sv
- hdl/rtl/dac/DAC_Controller.sv
- ip/system_wrapper.v

Testbench:
- hdl/tb/wavegen_tb.sv

LUT data:
- coe/sin_LUT.hex
- coe/sin_LUT.coe

Software:
- software/driver/wavegen_driver.c
- software/driver/wavegen_ip.c
- software/driver/wavegen_ip.h
- software/driver/wavegen_regs.h
- software/driver/Makefile
- software/lib/wavegen_lib.h
- software/lib/wavegen_lib.c
- software/lib/wavegen_lib_baremetal.h
- software/scripts/coe.py

Documentation:
- docs/user_manual.md
- docs/api_reference.md
- docs/integration_guide.md
