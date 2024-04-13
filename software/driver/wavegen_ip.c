#include <linux/io.h>
#include "wavegen_ip.h"

extern void __iomem *wavegen_base;

void wavegen_set_mode(struct wavegen_mode *mode)
{
    iowrite32(((mode->channel_b & 0x7) << 3) | (mode->channel_a & 0x7),
              wavegen_base + WAVEGEN_MODE_OFFSET);
}

void wavegen_set_frequency(struct wavegen_frequency *frequency)
{
    if (frequency->channel == WAVEGEN_CHANNEL_A) {
        iowrite32(frequency->value, wavegen_base + WAVEGEN_FREQ_A_OFFSET);
    } else if (frequency->channel == WAVEGEN_CHANNEL_B) {
        iowrite32(frequency->value, wavegen_base + WAVEGEN_FREQ_B_OFFSET);
    }
}

void wavegen_set_amplitude(struct wavegen_amplitude *amplitude)
{
    if (amplitude->channel == WAVEGEN_CHANNEL_A) {
        iowrite32(amplitude->value, wavegen_base + WAVEGEN_AMPL_A_OFFSET);
    } else if (amplitude->channel == WAVEGEN_CHANNEL_B) {
        iowrite32(amplitude->value, wavegen_base + WAVEGEN_AMPL_B_OFFSET);
    }
}

void wavegen_set_offset(struct wavegen_offset *offset)
{
    if (offset->channel == WAVEGEN_CHANNEL_A) {
        iowrite32(offset->value, wavegen_base + WAVEGEN_OFFSET_A_OFFSET);
    } else if (offset->channel == WAVEGEN_CHANNEL_B) {
        iowrite32(offset->value, wavegen_base + WAVEGEN_OFFSET_B_OFFSET);
    }
}

void wavegen_set_duty_cycle(struct wavegen_duty_cycle *duty_cycle)
{
    if (duty_cycle->channel == WAVEGEN_CHANNEL_A) {
        iowrite32(duty_cycle->value, wavegen_base + WAVEGEN_DCYCLE_A_OFFSET);
    } else if (duty_cycle->channel == WAVEGEN_CHANNEL_B) {
        iowrite32(duty_cycle->value, wavegen_base + WAVEGEN_DCYCLE_B_OFFSET);
    }
}

void wavegen_set_phase_offset(struct wavegen_phase_offset *phase_offset)
{
    if (phase_offset->channel == WAVEGEN_CHANNEL_A) {
        iowrite32(phase_offset->value, wavegen_base + WAVEGEN_POFFSET_A_OFFSET);
    } else if (phase_offset->channel == WAVEGEN_CHANNEL_B) {
        iowrite32(phase_offset->value, wavegen_base + WAVEGEN_POFFSET_B_OFFSET);
    }
}

void wavegen_set_cycles(struct wavegen_cycles *cycles)
{
    if (cycles->channel == WAVEGEN_CHANNEL_A) {
        iowrite32(cycles->value, wavegen_base + WAVEGEN_CYCLES_A_OFFSET);
    } else if (cycles->channel == WAVEGEN_CHANNEL_B) {
        iowrite32(cycles->value, wavegen_base + WAVEGEN_CYCLES_B_OFFSET);
    }
}

void wavegen_enable(struct wavegen_enable *enable)
{
    iowrite32(((enable->channel_b & 0x1) << 1) | (enable->channel_a & 0x1),
              wavegen_base + WAVEGEN_ENABLE_OFFSET);
}