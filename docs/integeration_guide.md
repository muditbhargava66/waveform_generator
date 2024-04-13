# Waveform Generator Integration Guide

## Introduction
This guide provides instructions on how to integrate the Waveform Generator IP core into your system and utilize its functionality.

## Hardware Integration
1. Instantiate the `wavegen_v1_0` module in your top-level design file.
2. Connect the clock and reset signals to the appropriate system clock and reset sources.
3. Connect the `out_a` and `out_b` signals to the desired output ports or internal signals.
4. Map the AXI4-Lite interface signals (`s00_axi_*`) to the corresponding signals in your system's AXI4-Lite interconnect.
5. Ensure that the `SAMPLING_FREQUENCY` parameter is set correctly based on your system's requirements.

## Software Integration
1. Include the `wavegen_ip.h` header file in your software application.
2. Open the `/dev/wavegen` device file using the `open` system call.
3. Use the IOCTL commands defined in `wavegen_ip.h` to configure and control the Waveform Generator.
   - Use `WAVEGEN_IOCTL_SET_MODE` to set the waveform mode for each channel.
   - Use `WAVEGEN_IOCTL_SET_FREQUENCY` to set the frequency for a specific channel.
   - Use `WAVEGEN_IOCTL_SET_AMPLITUDE` to set the amplitude for a specific channel.
   - Use `WAVEGEN_IOCTL_SET_OFFSET` to set the DC offset for a specific channel.
   - Use `WAVEGEN_IOCTL_SET_DUTY_CYCLE` to set the duty cycle for a specific channel (applicable for square wave mode).
   - Use `WAVEGEN_IOCTL_SET_PHASE_OFFSET` to set the phase offset for a specific channel.
   - Use `WAVEGEN_IOCTL_SET_CYCLES` to set the number of cycles for a specific channel (0 for continuous operation).
   - Use `WAVEGEN_IOCTL_ENABLE` to enable or disable waveform generation for each channel.
4. Close the device file using the `close` system call when done.

## Driver Integration
1. Copy the `wavegen_driver.c`, `wavegen_ip.c`, `wavegen_ip.h`, and `wavegen_regs.h` files to your driver directory.
2. Modify the `Makefile` to include the Waveform Generator driver files and specify the appropriate build targets.
3. Build the driver using the `make` command.
4. Load the driver module using the `insmod` command.
5. Create a device node for the Waveform Generator using `mknod` or `udev` rules.

## Configuring the Sine LUT
The Waveform Generator utilizes a look-up table (LUT) for efficient sine wave generation. To configure the sine LUT:
1. Modify the `scripts/coe.py` file to adjust the `lut_width`, `num_divisions`, and `stop_point` parameters as needed.
2. Run the `coe.py` script to generate the `sin_LUT.coe` file.
3. Update the FPGA bitstream with the generated COE file.

## Updating the FPGA Bitstream
1. Open the Vivado project for the FPGA design.
2. Import the generated `sin_LUT.coe` file into the project.
3. Regenerate the FPGA bitstream.
4. Program the FPGA with the updated bitstream.

## Calibrating the Output Voltages
The Waveform Generator includes voltage-to-DAC word calibration modules (`voltsToDACWords`) to ensure accurate output voltages. To calibrate the outputs:
1. Measure the output voltages for a known set of input values (e.g., 0 V and 2.5 V).
2. Update the `DAC_TWOPOINTFIVE` and `DAC_ZERO` parameters in the `voltsToDACWords` modules according to the measured values.
3. Rebuild the FPGA bitstream with the updated calibration values.

## Troubleshooting
- If the Waveform Generator is not functioning as expected:
  - Verify that the FPGA is programmed with the correct bitstream.
  - Check the connections between the FPGA and the DAC.
  - Ensure that the driver is loaded correctly and the device node is accessible.
  - Verify that the software application is using the correct IOCTL commands and parameters.
- If the output voltages are incorrect:
  - Verify that the calibration values in the `voltsToDACWords` modules are accurate for your setup.
  - Ensure that the DAC is powered and configured correctly.

## Conclusion
By following this integration guide, you should be able to successfully integrate the Waveform Generator IP core into your system and utilize its functionality through the provided driver and software API.

For more detailed information on the API functions and data structures, please refer to the API reference documentation.