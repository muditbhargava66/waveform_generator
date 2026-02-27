# User Manual — Waveform Generator IP

## Overview

The Waveform Generator is a dual-channel, AXI4-Lite controlled IP core for generating standard waveforms including DC, sine, sawtooth, triangle, square, and arbitrary waveforms. It targets Xilinx Zynq-7000 SoC platforms and interfaces with external DACs via SPI.

## Architecture

```
  Zynq PS ──► AXI4-Lite ──► wavegen_v1_0_S00_AXI (shadow + active registers)
                                    │
                                    ▼
                              WaveForms (phase accumulator engine)
                              ├── SineWaves (quarter-wave LUT synthesis)
                              └── arb_waveform_data (BRAM)
                                    │
                                    ▼
                        voltsToDACWords (calibration, fixed-point)
                                    │
                                    ▼
                          DAC_Controller (SPI master)
                                    │
                                    ▼
                            External DAC (e.g., MCP4922)
```

## Waveform Modes

| Mode ID | Name     | Description                                |
| ------- | -------- | ------------------------------------------ |
| 0       | DC       | Constant zero output                       |
| 1       | Sine     | Sine wave via quarter-wave LUT             |
| 2       | Sawtooth | Linear ramp from -32767 to +32767          |
| 3       | Triangle | Symmetric triangle wave                    |
| 4       | Square   | Square wave with configurable duty cycle   |
| 5       | ARB      | Arbitrary waveform from user-loaded memory |

## Register Map

All registers are 32-bit, word-aligned at the IP base address.

| Offset | Name      | Access | Description                                                 |
| ------ | --------- | ------ | ----------------------------------------------------------- |
| 0x00   | MODE      | R/W    | `[6:4]`=mode_b, `[2:0]`=mode_a                              |
| 0x04   | RUN       | R/W    | `[1]`=enable_b, `[0]`=enable_a (immediate)                  |
| 0x08   | FREQ_A    | R/W    | Channel A frequency (100μHz units)                          |
| 0x0C   | FREQ_B    | R/W    | Channel B frequency (100μHz units)                          |
| 0x10   | OFFSET    | R/W    | `[31:16]`=offset_b, `[15:0]`=offset_a                       |
| 0x14   | AMPLTD    | R/W    | `[31:16]`=amp_b, `[15:0]`=amp_a                             |
| 0x18   | DTCYC     | R/W    | `[31:16]`=duty_b, `[15:0]`=duty_a                           |
| 0x1C   | CYCLES    | R/W    | `[31:16]`=cycles_b, `[15:0]`=cycles_a                       |
| 0x20   | PHASE_OFF | R/W    | `[31:16]`=phase_b, `[15:0]`=phase_a                         |
| 0x24   | ARB_DEPTH | R/W    | Arbitrary waveform sample count                             |
| 0x28+n | ARB_DATA  | R/W    | Arbitrary waveform sample `n`                               |
| 0x2C   | RECONFIG  | W      | Write any value → apply shadow registers                    |
| 0x30   | STATUS    | R      | `[3]`=ch_b_run, `[2]`=ch_a_run, `[1]`=reconfig, `[0]`=ready |
| 0x34   | TRIGGER   | W      | `[1]`=trigger_b, `[0]`=trigger_a                            |
| 0x38   | SOFT_RST  | W      | `[1]`=reset_b, `[0]`=reset_a                                |

## Shadow Register System

Most registers are **shadow registers**: writes go to a shadow copy that is NOT immediately applied to the waveform engine. To apply all pending changes atomically (glitch-free), write any value to the **RECONFIG** register (0x2C).

**Exception**: The RUN register (0x04) is applied immediately for fast enable/disable.

## Frequency Calculation

Frequency is specified in units of 100μHz (0.0001 Hz).

| Desired Frequency | Register Value |
| ----------------- | -------------- |
| 1 Hz              | 10,000         |
| 100 Hz            | 1,000,000      |
| 1 kHz             | 10,000,000     |
| 10 kHz            | 100,000,000    |

## Typical Usage Flow

1. **Reset**: Assert AXI reset, then deassert
2. **Configure**: Write MODE, FREQ, AMPLTD, etc. (writes to shadow registers)
3. **Apply**: Write to RECONFIG register (0x2C) to transfer shadow → active
4. **Enable**: Write to RUN register (0x04) to enable channels
5. **Trigger** (optional): Write to TRIGGER (0x34) for synchronized start
6. **Update**: Modify shadow registers, write RECONFIG again for glitch-free update

## Arbitrary Waveform Loading

1. Write the number of samples to ARB_DEPTH (0x24)
2. Write each sample to ARB_DATA (0x28 + sample_index × 4)
3. Set MODE to ARB (5) and apply via RECONFIG
4. Enable the channel

Samples are 16-bit unsigned values (0 to 65535).

## DAC Calibration

The `voltsToDACWords` module maps the signed 16-bit waveform output to 12-bit DAC codes using per-channel calibration parameters:
- `DAC_ZERO`: DAC code that produces 0V output
- `DAC_TWOPOINTFIVE`: DAC code that produces 2.5V output

These are set as Verilog parameters in `WaveGen.sv`.