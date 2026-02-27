# API Reference — Waveform Generator

## Linux Userspace Library (`wavegen_lib.h`)

### Initialization

```c
wavegen_error_t wavegen_init(void);
```
Opens `/dev/wavegen` device. Returns `WAVEGEN_OK` on success.

```c
void wavegen_close(void);
```
Closes the device file descriptor.

### Parameter Configuration

All parameter functions write to shadow registers. Call `wavegen_apply()` to commit changes.

```c
wavegen_error_t wavegen_set_mode(wavegen_channel_t channel, wavegen_mode_t mode);
```
Set waveform mode. Uses read-modify-write to preserve the other channel's mode.

| Mode      | Constant                |
| --------- | ----------------------- |
| DC        | `WAVEGEN_MODE_DC`       |
| Sine      | `WAVEGEN_MODE_SINE`     |
| Sawtooth  | `WAVEGEN_MODE_SAWTOOTH` |
| Triangle  | `WAVEGEN_MODE_TRIANGLE` |
| Square    | `WAVEGEN_MODE_SQUARE`   |
| Arbitrary | `WAVEGEN_MODE_ARB`      |

```c
wavegen_error_t wavegen_set_frequency(wavegen_channel_t channel, uint32_t frequency);
```
Set frequency in 100μHz units. Example: `10000000` = 1 kHz.

```c
wavegen_error_t wavegen_set_amplitude(wavegen_channel_t channel, uint16_t amplitude);
```
Set amplitude (0 to 32767). Full scale = 32767.

```c
wavegen_error_t wavegen_set_offset(wavegen_channel_t channel, int16_t offset);
```
Set DC offset (signed 16-bit).

```c
wavegen_error_t wavegen_set_duty_cycle(wavegen_channel_t channel, uint16_t duty_cycle);
```
Set duty cycle (0 to 65535). 32768 = 50%. Only affects square wave mode.

```c
wavegen_error_t wavegen_set_phase_offset(wavegen_channel_t channel, int16_t phase_offset);
```
Set phase offset in 0.01° units. Range: -18000 to +18000 (-180° to +180°).

```c
wavegen_error_t wavegen_set_cycles(wavegen_channel_t channel, uint16_t cycles);
```
Set number of output cycles. 0 = continuous.

### Control

```c
wavegen_error_t wavegen_enable(wavegen_channel_t channel, int enable);
```
Enable (1) or disable (0) a channel. Takes effect immediately.

```c
wavegen_error_t wavegen_apply(void);
```
Atomically transfer all shadow register values to active registers.

```c
wavegen_error_t wavegen_trigger(wavegen_channel_t channel);
```
Software trigger for synchronized start.

```c
wavegen_error_t wavegen_start(wavegen_channel_t channel);
```
Convenience: enable + trigger.

```c
wavegen_error_t wavegen_stop(wavegen_channel_t channel);
```
Convenience: disable channel.

```c
wavegen_error_t wavegen_reset(wavegen_channel_t channel);
```
Soft reset: clears phase accumulator and cycle count.

```c
wavegen_error_t wavegen_get_status(wavegen_status_t *status);
```
Read current status (ready, reconfig_busy, channel running flags).

### Batch Configuration

```c
wavegen_error_t wavegen_configure(wavegen_channel_t channel, const wavegen_config_t *config);
```
Configure all parameters at once and apply atomically.

```c
typedef struct {
    wavegen_mode_t mode;
    uint32_t frequency;
    uint16_t amplitude;
    int16_t  offset;
    uint16_t duty_cycle;
    int16_t  phase_offset;
    uint16_t cycles;
} wavegen_config_t;
```

### Arbitrary Waveform

```c
wavegen_error_t wavegen_set_arb_depth(uint32_t depth);
wavegen_error_t wavegen_set_arb_sample(uint32_t index, uint16_t value);
wavegen_error_t wavegen_load_arb_waveform(const uint16_t *data, uint32_t count);
```

### Preset Waveforms

```c
wavegen_error_t wavegen_preset_1khz_sine(wavegen_channel_t channel);
wavegen_error_t wavegen_preset_1khz_square(wavegen_channel_t channel);
wavegen_error_t wavegen_preset_1khz_triangle(wavegen_channel_t channel);
wavegen_error_t wavegen_preset_1khz_sawtooth(wavegen_channel_t channel);
```

### Channel Constants

| Constant          | Value | Description    |
| ----------------- | ----- | -------------- |
| `WAVEGEN_CH_A`    | 0     | Channel A only |
| `WAVEGEN_CH_B`    | 1     | Channel B only |
| `WAVEGEN_CH_BOTH` | 2     | Both channels  |

### Error Codes

| Code | Constant               | Description              |
| ---- | ---------------------- | ------------------------ |
| 0    | `WAVEGEN_OK`           | Success                  |
| -1   | `WAVEGEN_ERR_INIT`     | Failed to open device    |
| -2   | `WAVEGEN_ERR_NOT_INIT` | Library not initialized  |
| -3   | `WAVEGEN_ERR_IOCTL`    | IOCTL call failed        |
| -4   | `WAVEGEN_ERR_PARAM`    | Invalid parameter        |
| -5   | `WAVEGEN_ERR_ALLOC`    | Memory allocation failed |

---

## Baremetal Library (`wavegen_lib_baremetal.h`)

Header-only library for Xilinx Vitis standalone applications. All functions are `static inline`.

### Initialization

```c
wavegen_hw_init(XPAR_WAVEGEN_0_BASEADDR);
```

### Configuration

```c
wavegen_hw_set_mode(WAVEGEN_HW_CH_A, WAVEGEN_HW_SINE);
wavegen_hw_set_frequency(WAVEGEN_HW_CH_A, 10000000);  // 1 kHz
wavegen_hw_set_amplitude(WAVEGEN_HW_CH_A, 32767);
wavegen_hw_set_offset(WAVEGEN_HW_CH_A, 0);
wavegen_hw_set_duty_cycle(WAVEGEN_HW_CH_A, 32768);
wavegen_hw_set_phase_offset(WAVEGEN_HW_CH_A, 0);
wavegen_hw_set_cycles(WAVEGEN_HW_CH_A, 0);
```

### Control

```c
wavegen_hw_enable(WAVEGEN_HW_CH_A, 1);
wavegen_hw_reconfig();
wavegen_hw_trigger(WAVEGEN_HW_CH_A);
wavegen_hw_trigger_both();
wavegen_hw_soft_reset(WAVEGEN_HW_CH_A);
uint32_t status = wavegen_hw_get_status();
```

### One-Line Configure

```c
wavegen_hw_configure(WAVEGEN_HW_CH_A, WAVEGEN_HW_SINE,
                     10000000, 32767, 0, 32768, 0, 0);
```

---

## Kernel IOCTL Interface (`wavegen_ip.h`)

For direct driver interaction (advanced use). See `wavegen_ip.h` for complete struct/ioctl definitions.

| IOCTL                            | Direction | Description             |
| -------------------------------- | --------- | ----------------------- |
| `WAVEGEN_IOCTL_SET_MODE`         | W         | Set waveform modes      |
| `WAVEGEN_IOCTL_SET_FREQUENCY`    | W         | Set frequency           |
| `WAVEGEN_IOCTL_SET_AMPLITUDE`    | W         | Set amplitude           |
| `WAVEGEN_IOCTL_SET_OFFSET`       | W         | Set DC offset           |
| `WAVEGEN_IOCTL_SET_DUTY_CYCLE`   | W         | Set duty cycle          |
| `WAVEGEN_IOCTL_SET_PHASE_OFFSET` | W         | Set phase offset        |
| `WAVEGEN_IOCTL_SET_CYCLES`       | W         | Set cycle count         |
| `WAVEGEN_IOCTL_ENABLE`           | W         | Enable/disable channels |
| `WAVEGEN_IOCTL_SET_ARB_DEPTH`    | W         | Set arb waveform depth  |
| `WAVEGEN_IOCTL_SET_ARB_DATA`     | W         | Write arb sample        |
| `WAVEGEN_IOCTL_SET_ARB_BULK`     | W         | Bulk write arb samples  |
| `WAVEGEN_IOCTL_TRIGGER`          | W         | Software trigger        |
| `WAVEGEN_IOCTL_RECONFIG`         | -         | Apply shadow registers  |
| `WAVEGEN_IOCTL_GET_STATUS`       | R         | Read status             |
| `WAVEGEN_IOCTL_SOFT_RESET`       | W         | Per-channel soft reset  |