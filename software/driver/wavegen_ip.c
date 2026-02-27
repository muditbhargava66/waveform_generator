#include <linux/io.h>
#include "wavegen_ip.h"
#include "wavegen_regs.h"

/*
 * Low-level IP register access functions.
 *
 * These functions implement the packed register layout where
 * channel A occupies bits [15:0] and channel B occupies bits [31:16]
 * for parameters like offset, amplitude, duty cycle, etc.
 *
 * Read-modify-write pattern is used for packed registers to avoid
 * inadvertently clobbering the other channel's settings.
 */

void wavegen_ip_set_mode(void __iomem *base, struct wavegen_mode *mode)
{
    u32 val = ((mode->channel_b & 0xF) << 4) | (mode->channel_a & 0xF);
    iowrite32(val, base + WAVEGEN_MODE_OFFSET);
}

void wavegen_ip_set_frequency(void __iomem *base, struct wavegen_frequency *freq)
{
    if (freq->channel == WAVEGEN_CHANNEL_A)
        iowrite32(freq->value, base + WAVEGEN_FREQ_A_OFFSET);
    else if (freq->channel == WAVEGEN_CHANNEL_B)
        iowrite32(freq->value, base + WAVEGEN_FREQ_B_OFFSET);
}

void wavegen_ip_set_amplitude(void __iomem *base, struct wavegen_amplitude *amp)
{
    u32 reg = ioread32(base + WAVEGEN_AMPLTD_OFFSET);
    if (amp->channel == WAVEGEN_CHANNEL_A) {
        reg = (reg & 0xFFFF0000) | (amp->value & 0xFFFF);
    } else if (amp->channel == WAVEGEN_CHANNEL_B) {
        reg = (reg & 0x0000FFFF) | ((amp->value & 0xFFFF) << 16);
    }
    iowrite32(reg, base + WAVEGEN_AMPLTD_OFFSET);
}

void wavegen_ip_set_offset(void __iomem *base, struct wavegen_offset *offset)
{
    u32 reg = ioread32(base + WAVEGEN_OFFSET_OFFSET);
    if (offset->channel == WAVEGEN_CHANNEL_A) {
        reg = (reg & 0xFFFF0000) | (offset->value & 0xFFFF);
    } else if (offset->channel == WAVEGEN_CHANNEL_B) {
        reg = (reg & 0x0000FFFF) | ((offset->value & 0xFFFF) << 16);
    }
    iowrite32(reg, base + WAVEGEN_OFFSET_OFFSET);
}

void wavegen_ip_set_duty_cycle(void __iomem *base, struct wavegen_duty_cycle *dc)
{
    u32 reg = ioread32(base + WAVEGEN_DTCYC_OFFSET);
    if (dc->channel == WAVEGEN_CHANNEL_A) {
        reg = (reg & 0xFFFF0000) | (dc->value & 0xFFFF);
    } else if (dc->channel == WAVEGEN_CHANNEL_B) {
        reg = (reg & 0x0000FFFF) | ((dc->value & 0xFFFF) << 16);
    }
    iowrite32(reg, base + WAVEGEN_DTCYC_OFFSET);
}

void wavegen_ip_set_phase_offset(void __iomem *base, struct wavegen_phase_offset *po)
{
    u32 reg = ioread32(base + WAVEGEN_PHASE_OFFSET);
    if (po->channel == WAVEGEN_CHANNEL_A) {
        reg = (reg & 0xFFFF0000) | (po->value & 0xFFFF);
    } else if (po->channel == WAVEGEN_CHANNEL_B) {
        reg = (reg & 0x0000FFFF) | ((po->value & 0xFFFF) << 16);
    }
    iowrite32(reg, base + WAVEGEN_PHASE_OFFSET);
}

void wavegen_ip_set_cycles(void __iomem *base, struct wavegen_cycles *cyc)
{
    u32 reg = ioread32(base + WAVEGEN_CYCLES_OFFSET);
    if (cyc->channel == WAVEGEN_CHANNEL_A) {
        reg = (reg & 0xFFFF0000) | (cyc->value & 0xFFFF);
    } else if (cyc->channel == WAVEGEN_CHANNEL_B) {
        reg = (reg & 0x0000FFFF) | ((cyc->value & 0xFFFF) << 16);
    }
    iowrite32(reg, base + WAVEGEN_CYCLES_OFFSET);
}

void wavegen_ip_enable(void __iomem *base, struct wavegen_enable *en)
{
    u32 val = ((en->channel_b & 0x1) << 1) | (en->channel_a & 0x1);
    iowrite32(val, base + WAVEGEN_RUN_OFFSET);
}

void wavegen_ip_set_arb_depth(void __iomem *base, struct wavegen_arb_waveform_depth *d)
{
    iowrite32(d->depth, base + WAVEGEN_ARB_DEPTH_OFFSET);
}

void wavegen_ip_set_arb_data(void __iomem *base, struct wavegen_arb_waveform_data *d)
{
    iowrite32(d->value & 0xFFFF, base + WAVEGEN_ARB_DATA_OFFSET + d->offset * 4);
}

void wavegen_ip_trigger(void __iomem *base, struct wavegen_trigger *trig)
{
    u32 val = ((trig->channel_b & 0x1) << 1) | (trig->channel_a & 0x1);
    iowrite32(val, base + WAVEGEN_TRIGGER_OFFSET);
}

void wavegen_ip_reconfig(void __iomem *base)
{
    iowrite32(1, base + WAVEGEN_RECONFIG_OFFSET);
}

void wavegen_ip_get_status(void __iomem *base, struct wavegen_status *st)
{
    u32 raw = ioread32(base + WAVEGEN_STATUS_OFFSET);
    st->raw = raw;
    st->ready = (raw >> 0) & 1;
    st->reconfig_busy = (raw >> 1) & 1;
    st->channel_a_running = (raw >> 2) & 1;
    st->channel_b_running = (raw >> 3) & 1;
}

void wavegen_ip_soft_reset(void __iomem *base, struct wavegen_trigger *rst)
{
    u32 val = ((rst->channel_b & 0x1) << 1) | (rst->channel_a & 0x1);
    iowrite32(val, base + WAVEGEN_SOFT_RST_OFFSET);
}