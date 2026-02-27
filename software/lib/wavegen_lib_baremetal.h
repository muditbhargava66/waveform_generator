#ifndef WAVEGEN_LIB_BAREMETAL_H
#define WAVEGEN_LIB_BAREMETAL_H

/*
 * Waveform Generator Baremetal Library
 *
 * Standalone library for use in Xilinx Vitis / SDK applications
 * without a Linux kernel. Uses direct MMIO register access
 * (Xil_Out32/Xil_In32 on Zynq, or generic volatile pointer access).
 *
 * Usage:
 *   #include "wavegen_lib_baremetal.h"
 *
 *   // In your main():
 *   wavegen_hw_init(XPAR_WAVEGEN_0_BASEADDR);  // From xparameters.h
 *   wavegen_hw_set_mode(WAVEGEN_HW_CH_A, WAVEGEN_HW_SINE);
 *   wavegen_hw_set_frequency(WAVEGEN_HW_CH_A, 10000000);  // 1 kHz
 *   wavegen_hw_set_amplitude(WAVEGEN_HW_CH_A, 32767);
 *   wavegen_hw_enable(WAVEGEN_HW_CH_A, 1);
 *   wavegen_hw_reconfig();
 */

#include <stdint.h>

/* ============================================================
 * Platform abstraction for register I/O
 * ============================================================ */
#ifdef __XILINX__
  #include "xil_io.h"
  #define WAVEGEN_WRITE32(addr, val) Xil_Out32((addr), (val))
  #define WAVEGEN_READ32(addr)       Xil_In32((addr))
#else
  /* Generic volatile pointer access */
  #define WAVEGEN_WRITE32(addr, val) (*(volatile uint32_t *)(addr) = (val))
  #define WAVEGEN_READ32(addr)       (*(volatile uint32_t *)(addr))
#endif

/* ============================================================
 * Register offsets (must match wavegen_v1_0_S00_AXI.v)
 * ============================================================ */
#define WAVEGEN_HW_MODE_OFF      0x00
#define WAVEGEN_HW_RUN_OFF       0x04
#define WAVEGEN_HW_FREQ_A_OFF    0x08
#define WAVEGEN_HW_FREQ_B_OFF    0x0C
#define WAVEGEN_HW_OFFSET_OFF    0x10
#define WAVEGEN_HW_AMPLTD_OFF    0x14
#define WAVEGEN_HW_DTCYC_OFF     0x18
#define WAVEGEN_HW_CYCLES_OFF    0x1C
#define WAVEGEN_HW_PHASE_OFF     0x20
#define WAVEGEN_HW_ARB_DEPTH_OFF 0x24
#define WAVEGEN_HW_ARB_DATA_OFF  0x28
#define WAVEGEN_HW_RECONFIG_OFF  0x2C
#define WAVEGEN_HW_STATUS_OFF    0x30
#define WAVEGEN_HW_TRIGGER_OFF   0x34
#define WAVEGEN_HW_SOFT_RST_OFF  0x38

/* ============================================================
 * Constants
 * ============================================================ */
typedef enum {
    WAVEGEN_HW_DC        = 0,
    WAVEGEN_HW_SINE      = 1,
    WAVEGEN_HW_SAWTOOTH  = 2,
    WAVEGEN_HW_TRIANGLE  = 3,
    WAVEGEN_HW_SQUARE    = 4,
    WAVEGEN_HW_ARB       = 5
} wavegen_hw_mode_t;

typedef enum {
    WAVEGEN_HW_CH_A = 0,
    WAVEGEN_HW_CH_B = 1
} wavegen_hw_channel_t;

/* ============================================================
 * API functions (all inline for baremetal use)
 * ============================================================ */

static uintptr_t _wavegen_base = 0;

static inline void wavegen_hw_init(uintptr_t base_addr) {
    _wavegen_base = base_addr;
}

static inline void wavegen_hw_set_mode(wavegen_hw_channel_t ch, wavegen_hw_mode_t mode) {
    uint32_t reg = WAVEGEN_READ32(_wavegen_base + WAVEGEN_HW_MODE_OFF);
    if (ch == WAVEGEN_HW_CH_A)
        reg = (reg & 0xFFFFFFF0) | (mode & 0x0F);
    else
        reg = (reg & 0xFFFFFF0F) | ((mode & 0x0F) << 4);
    WAVEGEN_WRITE32(_wavegen_base + WAVEGEN_HW_MODE_OFF, reg);
}

static inline void wavegen_hw_set_frequency(wavegen_hw_channel_t ch, uint32_t freq) {
    uintptr_t off = (ch == WAVEGEN_HW_CH_A) ? WAVEGEN_HW_FREQ_A_OFF : WAVEGEN_HW_FREQ_B_OFF;
    WAVEGEN_WRITE32(_wavegen_base + off, freq);
}

static inline void wavegen_hw_set_amplitude(wavegen_hw_channel_t ch, uint16_t amp) {
    uint32_t reg = WAVEGEN_READ32(_wavegen_base + WAVEGEN_HW_AMPLTD_OFF);
    if (ch == WAVEGEN_HW_CH_A)
        reg = (reg & 0xFFFF0000) | amp;
    else
        reg = (reg & 0x0000FFFF) | ((uint32_t)amp << 16);
    WAVEGEN_WRITE32(_wavegen_base + WAVEGEN_HW_AMPLTD_OFF, reg);
}

static inline void wavegen_hw_set_offset(wavegen_hw_channel_t ch, int16_t offset) {
    uint32_t reg = WAVEGEN_READ32(_wavegen_base + WAVEGEN_HW_OFFSET_OFF);
    if (ch == WAVEGEN_HW_CH_A)
        reg = (reg & 0xFFFF0000) | (uint16_t)offset;
    else
        reg = (reg & 0x0000FFFF) | ((uint32_t)(uint16_t)offset << 16);
    WAVEGEN_WRITE32(_wavegen_base + WAVEGEN_HW_OFFSET_OFF, reg);
}

static inline void wavegen_hw_set_duty_cycle(wavegen_hw_channel_t ch, uint16_t dc) {
    uint32_t reg = WAVEGEN_READ32(_wavegen_base + WAVEGEN_HW_DTCYC_OFF);
    if (ch == WAVEGEN_HW_CH_A)
        reg = (reg & 0xFFFF0000) | dc;
    else
        reg = (reg & 0x0000FFFF) | ((uint32_t)dc << 16);
    WAVEGEN_WRITE32(_wavegen_base + WAVEGEN_HW_DTCYC_OFF, reg);
}

static inline void wavegen_hw_set_phase_offset(wavegen_hw_channel_t ch, int16_t po) {
    uint32_t reg = WAVEGEN_READ32(_wavegen_base + WAVEGEN_HW_PHASE_OFF);
    if (ch == WAVEGEN_HW_CH_A)
        reg = (reg & 0xFFFF0000) | (uint16_t)po;
    else
        reg = (reg & 0x0000FFFF) | ((uint32_t)(uint16_t)po << 16);
    WAVEGEN_WRITE32(_wavegen_base + WAVEGEN_HW_PHASE_OFF, reg);
}

static inline void wavegen_hw_set_cycles(wavegen_hw_channel_t ch, uint16_t cycles) {
    uint32_t reg = WAVEGEN_READ32(_wavegen_base + WAVEGEN_HW_CYCLES_OFF);
    if (ch == WAVEGEN_HW_CH_A)
        reg = (reg & 0xFFFF0000) | cycles;
    else
        reg = (reg & 0x0000FFFF) | ((uint32_t)cycles << 16);
    WAVEGEN_WRITE32(_wavegen_base + WAVEGEN_HW_CYCLES_OFF, reg);
}

static inline void wavegen_hw_enable(wavegen_hw_channel_t ch, int enable) {
    uint32_t reg = WAVEGEN_READ32(_wavegen_base + WAVEGEN_HW_RUN_OFF);
    if (ch == WAVEGEN_HW_CH_A)
        reg = (reg & ~1u) | (enable ? 1 : 0);
    else
        reg = (reg & ~2u) | (enable ? 2 : 0);
    WAVEGEN_WRITE32(_wavegen_base + WAVEGEN_HW_RUN_OFF, reg);
}

static inline void wavegen_hw_set_arb_depth(uint32_t depth) {
    WAVEGEN_WRITE32(_wavegen_base + WAVEGEN_HW_ARB_DEPTH_OFF, depth);
}

static inline void wavegen_hw_set_arb_sample(uint32_t index, uint16_t value) {
    WAVEGEN_WRITE32(_wavegen_base + WAVEGEN_HW_ARB_DATA_OFF + index * 4, value);
}

static inline void wavegen_hw_reconfig(void) {
    WAVEGEN_WRITE32(_wavegen_base + WAVEGEN_HW_RECONFIG_OFF, 1);
}

static inline void wavegen_hw_trigger(wavegen_hw_channel_t ch) {
    uint32_t val = (ch == WAVEGEN_HW_CH_A) ? 1 : 2;
    WAVEGEN_WRITE32(_wavegen_base + WAVEGEN_HW_TRIGGER_OFF, val);
}

static inline void wavegen_hw_trigger_both(void) {
    WAVEGEN_WRITE32(_wavegen_base + WAVEGEN_HW_TRIGGER_OFF, 3);
}

static inline uint32_t wavegen_hw_get_status(void) {
    return WAVEGEN_READ32(_wavegen_base + WAVEGEN_HW_STATUS_OFF);
}

static inline void wavegen_hw_soft_reset(wavegen_hw_channel_t ch) {
    uint32_t val = (ch == WAVEGEN_HW_CH_A) ? 1 : 2;
    WAVEGEN_WRITE32(_wavegen_base + WAVEGEN_HW_SOFT_RST_OFF, val);
}

/* ============================================================
 * Convenience: Configure a channel in one call
 * ============================================================ */
static inline void wavegen_hw_configure(
    wavegen_hw_channel_t ch,
    wavegen_hw_mode_t mode,
    uint32_t freq,
    uint16_t amp,
    int16_t offset,
    uint16_t duty_cycle,
    int16_t phase_offset,
    uint16_t cycles)
{
    wavegen_hw_set_mode(ch, mode);
    wavegen_hw_set_frequency(ch, freq);
    wavegen_hw_set_amplitude(ch, amp);
    wavegen_hw_set_offset(ch, offset);
    wavegen_hw_set_duty_cycle(ch, duty_cycle);
    wavegen_hw_set_phase_offset(ch, phase_offset);
    wavegen_hw_set_cycles(ch, cycles);
    wavegen_hw_reconfig();
}

#endif /* WAVEGEN_LIB_BAREMETAL_H */
