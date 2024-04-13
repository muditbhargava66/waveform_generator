# Waveform Generator

The Waveform Generator is a digital system that generates various waveforms, including sine, sawtooth, triangle, and square waves. It is controlled through an AXI4-Lite interface and supports two output channels (A and B) with configurable parameters.

## Features
- Generates sine, sawtooth, triangle, and square waves
- Two independent output channels (A and B)
- Configurable waveform parameters:
  - Mode (DC, Sine, Sawtooth, Triangle, Square)
  - Frequency
  - Amplitude
  - Offset
  - Duty cycle (for square wave)
  - Phase offset
  - Number of cycles
- AXI4-Lite interface for configuration and control
- Look-up table (LUT) for efficient sine wave generation
- Voltage-to-DAC word calibration for accurate output voltages

## Directory Structure
```
waveform_generator/
├── hdl/
│   ├── rtl/
│   │   ├── waveforms/
│   │   │   ├── WaveForms.sv
│   │   │   ├── SineWaves.sv
│   │   │   └── s2ui.sv
│   │   ├── axi_lite/
│   │   │   ├── wavegen_v1_0_S00_AXI.v
│   │   │   └── wavegen_v1_0.v
│   │   ├── dac/
│   │   │   ├── Calibration.sv
│   │   │   └── DAC_Controller.sv
│   │   └── WaveGen.sv
│   └── tb/
│       └── wavegen_tb.sv
├── software/
│   ├── driver/
│   │   ├── wavegen_driver.c
│   │   ├── wavegen_ip.c
│   │   ├── wavegen_ip.h
│   │   ├── wavegen_regs.h
│   │   └── Makefile
│   └── scripts/
│       └── coe.py
|── docs/
|    ├── user_manual.md
|    ├── api_reference.md
|    ├── integration_guide.md
└── README.md
```

## Getting Started
1. Clone the repository:
   ```
   git clone https://github.com/your-username/waveform-generator.git
   ```
2. Set up the hardware:
   - Connect the FPGA board to your system
   - Ensure the DAC is properly connected and powered
3. Build the FPGA bitstream:
   - Open the Vivado project in the `hdl` directory
   - Generate the bitstream
   - Program the FPGA with the generated bitstream
4. Build and load the driver:
   - Navigate to the `software/driver` directory
   - Run `make` to build the driver
   - Load the driver using `insmod wavegen_driver.ko`
5. Configure and control the Waveform Generator:
   - Use the provided API functions and data structures to configure the waveform parameters
   - Refer to the API reference and integration guide for detailed instructions

## Documentation
- [User Manual](docs/user_manual.md)
- [API Reference](docs/api_reference.md)
- [Integration Guide](docs/integration_guide.md)

## Future Updates
- [ ] Add support for arbitrary waveform generation
- [ ] Implement dynamic reconfiguration of waveform parameters
- [ ] Enhance the driver with real-time waveform updates and triggers
- [ ] Improve the sine LUT generation script for better accuracy
- [ ] Develop a high-level software library for easier integration
- [ ] Optimize the HDL code for resource utilization and performance

## Contributing
Contributions are welcome! If you find any issues or have suggestions for improvements, please open an issue or submit a pull request.

## License
This project is licensed under the [MIT License](LICENSE).