# Waveform Generator User Manual

## Introduction
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
- Arbitrary waveform generation with customizable depth and data

## Hardware Requirements
- FPGA board with sufficient resources (e.g., Xilinx Zynq)
- DAC chip compatible with the DAC controller interface
- Appropriate power supplies and connections

## Software Requirements
- Vivado Design Suite for FPGA development
- Xilinx SDK for software development
- Python 3.x for running the COE file generation script

## Getting Started
1. Clone the waveform generator repository from GitHub.
2. Open the Vivado project and build the FPGA bitstream.
3. Export the hardware design to Xilinx SDK.
4. Develop the software application to configure and control the waveform generator using the provided driver and APIs.
5. Program the FPGA with the bitstream and run the software application.

## Configuring the Waveform Generator
The waveform generator is configured through the AXI4-Lite interface. The following registers are available for configuration:

- Mode (0x00): Select the waveform mode for each channel (A and B)
- Run (0x04): Enable/disable waveform generation for each channel
- Frequency (0x08, 0x0C): Set the frequency for each channel (in units of 100 μHz)
- Offset (0x10): Set the DC offset for each channel (in units of 100 μV)
- Amplitude (0x14): Set the amplitude for each channel (in units of 100 μV)
- Duty Cycle (0x18): Set the duty cycle for square wave (in units of 100%/2^16)
- Cycles (0x1C): Set the number of cycles for each channel
- Phase Offset (0x20): Set the phase offset for each channel (in units of 0.01 degrees, range: -180 to 180)

### Arbitrary Waveform Generation
The Waveform Generator supports arbitrary waveform generation, allowing you to generate custom waveforms by providing the waveform depth and data.

To configure arbitrary waveform generation:
1. Set the arbitrary waveform depth using the `WAVEGEN_IOCTL_SET_ARB_WAVEFORM_DEPTH` IOCTL command.
2. Load the arbitrary waveform data using the `WAVEGEN_IOCTL_SET_ARB_WAVEFORM_DATA` IOCTL command. You need to provide the offset and value for each data point.
3. Set the waveform mode to `ARB` using the `WAVEGEN_IOCTL_SET_MODE` IOCTL command.
4. Enable the waveform generation using the `WAVEGEN_IOCTL_ENABLE` IOCTL command.

Refer to the API reference documentation for more details on how to access and modify these registers.

## Generating the Sine LUT
The waveform generator uses a look-up table (LUT) to store pre-calculated sine values for efficient sine wave generation. To generate the LUT:

1. Open the `scripts/coe.py` file.
2. Modify the `lut_width`, `num_divisions`, and `stop_point` variables as needed.
3. Run the script to generate the `sin_LUT.coe` file.
4. Update the FPGA project with the generated COE file.

## Calibrating the Output Voltages
The waveform generator includes voltage-to-DAC word calibration modules (`voltsToDACWords`) to ensure accurate output voltages. To calibrate the outputs:

1. Measure the output voltages for a known set of input values (e.g., 0V and 2.5V).
2. Update the `DAC_TWOPOINTFIVE` and `DAC_ZERO` parameters in the `voltsToDACWords` modules according to the measured values.
3. Rebuild the FPGA bitstream with the updated calibration values.

## Troubleshooting
- If the waveform generator is not functioning as expected, verify the following:
  - The FPGA is programmed with the correct bitstream.
  - The DAC chip is properly connected and powered.
  - The AXI4-Lite interface is correctly configured and accessed.
  - The calibration values are accurate for your specific setup.
- If you encounter any issues or have questions, please refer to the troubleshooting guide or contact our support team.

## Conclusion
The Waveform Generator is a versatile and configurable system for generating various waveforms. With its AXI4-Lite interface, look-up table-based sine wave generation, and voltage calibration, it provides an efficient and accurate solution for waveform generation applications.

For more detailed information, please refer to the API reference documentation and the source code repository.