# Waveform Generator API Reference

## Introduction
This document provides a reference for the API functions and data structures used to interact with the Waveform Generator IP core.

## IOCTL Commands
The following IOCTL commands are available for configuring and controlling the Waveform Generator:

| Command                      | Description                                        |
|------------------------------|----------------------------------------------------|
| `WAVEGEN_IOCTL_SET_MODE`     | Set the waveform mode for each channel             |
| `WAVEGEN_IOCTL_SET_FREQUENCY`| Set the frequency for a specific channel           |
| `WAVEGEN_IOCTL_SET_AMPLITUDE`| Set the amplitude for a specific channel           |
| `WAVEGEN_IOCTL_SET_OFFSET`   | Set the DC offset for a specific channel           |
| `WAVEGEN_IOCTL_SET_DUTY_CYCLE`| Set the duty cycle for a specific channel         |
| `WAVEGEN_IOCTL_SET_PHASE_OFFSET`| Set the phase offset for a specific channel     |
| `WAVEGEN_IOCTL_SET_CYCLES`   | Set the number of cycles for a specific channel    |
| `WAVEGEN_IOCTL_ENABLE`       | Enable or disable waveform generation for each channel |

## Data Structures
The following data structures are used for configuring the Waveform Generator:

### `struct wavegen_mode`
```c
struct wavegen_mode {
    unsigned int channel_a;
    unsigned int channel_b;
};
```
- `channel_a`: Waveform mode for channel A (0-7)
- `channel_b`: Waveform mode for channel B (0-7)

### `struct wavegen_frequency`
```c
struct wavegen_frequency {
    unsigned int channel;
    unsigned int value;
};
```
- `channel`: Channel to set the frequency for (0: Channel A, 1: Channel B)
- `value`: Frequency value in units of 100 μHz

### `struct wavegen_amplitude`
```c
struct wavegen_amplitude {
    unsigned int channel;
    unsigned int value;
};
```
- `channel`: Channel to set the amplitude for (0: Channel A, 1: Channel B)
- `value`: Amplitude value in units of 100 μV

### `struct wavegen_offset`
```c
struct wavegen_offset {
    unsigned int channel;
    unsigned int value;
};
```
- `channel`: Channel to set the DC offset for (0: Channel A, 1: Channel B)
- `value`: DC offset value in units of 100 μV

### `struct wavegen_duty_cycle`
```c
struct wavegen_duty_cycle {
    unsigned int channel;
    unsigned int value;
};
```
- `channel`: Channel to set the duty cycle for (0: Channel A, 1: Channel B)
- `value`: Duty cycle value in units of 100%/2^16

### `struct wavegen_phase_offset`
```c
struct wavegen_phase_offset {
    unsigned int channel;
    unsigned int value;
};
```
- `channel`: Channel to set the phase offset for (0: Channel A, 1: Channel B)
- `value`: Phase offset value in units of 0.01 degrees (-180 to 180)

### `struct wavegen_cycles`
```c
struct wavegen_cycles {
    unsigned int channel;
    unsigned int value;
};
```
- `channel`: Channel to set the number of cycles for (0: Channel A, 1: Channel B)
- `value`: Number of cycles (0 for continuous operation)

### `struct wavegen_enable`
```c
struct wavegen_enable {
    unsigned int channel_a;
    unsigned int channel_b;
};
```
- `channel_a`: Enable (1) or disable (0) waveform generation for channel A
- `channel_b`: Enable (1) or disable (0) waveform generation for channel B

## Waveform Modes
The following waveform modes are available:

| Mode Value | Waveform Type |
|------------|---------------|
| 0          | DC            |
| 1          | Sine          |
| 2          | Sawtooth      |
| 3          | Triangle      |
| 4          | Square        |

## Example Usage
Here's an example of how to use the IOCTL commands to configure and control the Waveform Generator:

```c
#include <stdio.h>
#include <fcntl.h>
#include <sys/ioctl.h>
#include "wavegen_ip.h"

int main() {
    int fd = open("/dev/wavegen", O_RDWR);
    if (fd < 0) {
        perror("Failed to open wavegen device");
        return 1;
    }

    struct wavegen_mode mode = {1, 2}; // Sine wave on channel A, Sawtooth wave on channel B
    ioctl(fd, WAVEGEN_IOCTL_SET_MODE, &mode);

    struct wavegen_frequency freq = {WAVEGEN_CHANNEL_A, 10000}; // 1 kHz on channel A
    ioctl(fd, WAVEGEN_IOCTL_SET_FREQUENCY, &freq);

    struct wavegen_amplitude amp = {WAVEGEN_CHANNEL_A, 5000}; // 0.5 V amplitude on channel A
    ioctl(fd, WAVEGEN_IOCTL_SET_AMPLITUDE, &amp);

    struct wavegen_enable enable = {1, 0}; // Enable channel A, disable channel B
    ioctl(fd, WAVEGEN_IOCTL_ENABLE, &enable);

    // ...

    close(fd);
    return 0;
}
```

In this example, the `/dev/wavegen` device is opened, and IOCTL commands are used to set the waveform mode, frequency, amplitude, and enable/disable channels. The device is then closed after the configuration is complete.

For more detailed information on the Waveform Generator IP core and its integration, please refer to the integration guide.