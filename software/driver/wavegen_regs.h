#ifndef WAVEGEN_REGS_H
#define WAVEGEN_REGS_H

/*
 * Waveform Generator IP - Register Map
 *
 * Base address: 0x43C00000 (Zynq GP0 AXI base)
 *
 * All registers are 32-bit, word-aligned.
 * Multi-channel registers pack channel A in [15:0], channel B in [31:16].
 */

#define WAVEGEN_BASE_ADDR       0x43C00000
#define WAVEGEN_ADDR_RANGE      0x10000

/* Control registers (word offset * 4) */
#define WAVEGEN_MODE_OFFSET     0x00    /* [6:4]=mode_b, [2:0]=mode_a */
#define WAVEGEN_RUN_OFFSET      0x04    /* [1]=enable_b, [0]=enable_a */
#define WAVEGEN_FREQ_A_OFFSET   0x08    /* [31:0]=freq_a (100uHz units) */
#define WAVEGEN_FREQ_B_OFFSET   0x0C    /* [31:0]=freq_b (100uHz units) */
#define WAVEGEN_OFFSET_OFFSET   0x10    /* [31:16]=offset_b, [15:0]=offset_a */
#define WAVEGEN_AMPLTD_OFFSET   0x14    /* [31:16]=amp_b, [15:0]=amp_a */
#define WAVEGEN_DTCYC_OFFSET    0x18    /* [31:16]=dtcyc_b, [15:0]=dtcyc_a */
#define WAVEGEN_CYCLES_OFFSET   0x1C    /* [31:16]=cycles_b, [15:0]=cycles_a */
#define WAVEGEN_PHASE_OFFSET    0x20    /* [31:16]=phase_b, [15:0]=phase_a */
#define WAVEGEN_ARB_DEPTH_OFFSET 0x24   /* [31:0]=arb waveform depth */
#define WAVEGEN_ARB_DATA_OFFSET  0x28   /* [15:0]=arb sample data */
#define WAVEGEN_RECONFIG_OFFSET  0x2C   /* Write any value to apply shadows */
#define WAVEGEN_STATUS_OFFSET    0x30   /* [RO] status register */
#define WAVEGEN_TRIGGER_OFFSET   0x34   /* [1]=trigger_b, [0]=trigger_a */
#define WAVEGEN_SOFT_RST_OFFSET  0x38   /* [1]=reset_b, [0]=reset_a */

/* Status register bit definitions */
#define WAVEGEN_STATUS_READY        (1 << 0)
#define WAVEGEN_STATUS_RECONFIG     (1 << 1)
#define WAVEGEN_STATUS_CHA_RUNNING  (1 << 2)
#define WAVEGEN_STATUS_CHB_RUNNING  (1 << 3)

/* Waveform mode constants */
#define WAVEGEN_MODE_DC         0
#define WAVEGEN_MODE_SINE       1
#define WAVEGEN_MODE_SAWTOOTH   2
#define WAVEGEN_MODE_TRIANGLE   3
#define WAVEGEN_MODE_SQUARE     4
#define WAVEGEN_MODE_ARB        5

/* Channel constants */
#define WAVEGEN_CHANNEL_A       0
#define WAVEGEN_CHANNEL_B       1

#endif /* WAVEGEN_REGS_H */