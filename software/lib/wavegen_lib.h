#ifndef WAVEGEN_LIB_H
#define WAVEGEN_LIB_H

#include <stdint.h>

/*
 * High-Level Waveform Generator Library
 *
 * Provides a user-friendly API for configuring and controlling the
 * waveform generator hardware via the Linux kernel driver.
 *
 * Usage:
 *   1. Call wavegen_init() to open the device
 *   2. Configure parameters using wavegen_set_* functions
 *   3. Call wavegen_apply() to atomically apply all parameter changes
 *   4. Call wavegen_start() to begin waveform generation
 *   5. Call wavegen_close() when done
 */

/* ============================================================
 * Waveform modes
 * ============================================================ */
typedef enum {
    WAVEGEN_MODE_DC        = 0,
    WAVEGEN_MODE_SINE      = 1,
    WAVEGEN_MODE_SAWTOOTH  = 2,
    WAVEGEN_MODE_TRIANGLE  = 3,
    WAVEGEN_MODE_SQUARE    = 4,
    WAVEGEN_MODE_ARB       = 5
} wavegen_mode_t;

/* ============================================================
 * Channel selection
 * ============================================================ */
typedef enum {
    WAVEGEN_CH_A = 0,
    WAVEGEN_CH_B = 1,
    WAVEGEN_CH_BOTH = 2
} wavegen_channel_t;

/* ============================================================
 * Error codes
 * ============================================================ */
typedef enum {
    WAVEGEN_OK             = 0,
    WAVEGEN_ERR_INIT       = -1,
    WAVEGEN_ERR_NOT_INIT   = -2,
    WAVEGEN_ERR_IOCTL      = -3,
    WAVEGEN_ERR_PARAM      = -4,
    WAVEGEN_ERR_ALLOC      = -5
} wavegen_error_t;

/* ============================================================
 * Status structure
 * ============================================================ */
typedef struct {
    int ready;
    int reconfig_busy;
    int channel_a_running;
    int channel_b_running;
} wavegen_status_t;

/* ============================================================
 * Batch configuration structure
 * ============================================================ */
typedef struct {
    wavegen_mode_t mode;
    uint32_t frequency;         /* In 100uHz units (e.g., 10000000 = 1 kHz) */
    uint16_t amplitude;         /* 0 to 32767 */
    int16_t  offset;            /* Signed offset */
    uint16_t duty_cycle;        /* 0 to 65535 (maps to 0-100%) */
    int16_t  phase_offset;      /* In 0.01 degree units (-18000 to 18000) */
    uint16_t cycles;            /* 0 = continuous */
} wavegen_config_t;

/* ============================================================
 * Core API
 * ============================================================ */

/* Initialize the library and open the device driver */
wavegen_error_t wavegen_init(void);

/* Close the device and clean up */
void wavegen_close(void);

/* ============================================================
 * Parameter Configuration (writes to shadow registers)
 * ============================================================ */

/* Set waveform mode for a channel */
wavegen_error_t wavegen_set_mode(wavegen_channel_t channel, wavegen_mode_t mode);

/* Set frequency in 100uHz units (e.g., 10000000 = 1 kHz) */
wavegen_error_t wavegen_set_frequency(wavegen_channel_t channel, uint32_t frequency);

/* Set amplitude (0 to 32767) */
wavegen_error_t wavegen_set_amplitude(wavegen_channel_t channel, uint16_t amplitude);

/* Set offset (signed 16-bit) */
wavegen_error_t wavegen_set_offset(wavegen_channel_t channel, int16_t offset);

/* Set duty cycle (0 to 65535 for 0% to 100%) */
wavegen_error_t wavegen_set_duty_cycle(wavegen_channel_t channel, uint16_t duty_cycle);

/* Set phase offset in 0.01 degree units (-18000 to +18000) */
wavegen_error_t wavegen_set_phase_offset(wavegen_channel_t channel, int16_t phase_offset);

/* Set number of cycles (0 = continuous) */
wavegen_error_t wavegen_set_cycles(wavegen_channel_t channel, uint16_t cycles);

/* ============================================================
 * Control API
 * ============================================================ */

/* Enable/disable channel output */
wavegen_error_t wavegen_enable(wavegen_channel_t channel, int enable);

/* Convenience: start a channel (enable + trigger) */
wavegen_error_t wavegen_start(wavegen_channel_t channel);

/* Convenience: stop a channel (disable) */
wavegen_error_t wavegen_stop(wavegen_channel_t channel);

/* Apply all shadow register changes atomically */
wavegen_error_t wavegen_apply(void);

/* Software trigger (synchronized start) */
wavegen_error_t wavegen_trigger(wavegen_channel_t channel);

/* Soft reset a channel (clears phase, cycle count) */
wavegen_error_t wavegen_reset(wavegen_channel_t channel);

/* Get current status */
wavegen_error_t wavegen_get_status(wavegen_status_t *status);

/* ============================================================
 * Batch Configuration API
 * ============================================================ */

/* Configure a channel with all parameters at once */
wavegen_error_t wavegen_configure(wavegen_channel_t channel,
                                   const wavegen_config_t *config);

/* ============================================================
 * Arbitrary Waveform API
 * ============================================================ */

/* Set arbitrary waveform depth */
wavegen_error_t wavegen_set_arb_depth(uint32_t depth);

/* Load a single arbitrary waveform sample */
wavegen_error_t wavegen_set_arb_sample(uint32_t index, uint16_t value);

/* Load arbitrary waveform data in bulk */
wavegen_error_t wavegen_load_arb_waveform(const uint16_t *data, uint32_t count);

/* ============================================================
 * Preset Waveforms (convenience functions)
 * ============================================================ */

/* Generate a standard 1 kHz sine wave on a channel */
wavegen_error_t wavegen_preset_1khz_sine(wavegen_channel_t channel);

/* Generate a 1 kHz square wave (50% duty cycle) */
wavegen_error_t wavegen_preset_1khz_square(wavegen_channel_t channel);

/* Generate a 1 kHz triangle wave */
wavegen_error_t wavegen_preset_1khz_triangle(wavegen_channel_t channel);

/* Generate a 1 kHz sawtooth wave */
wavegen_error_t wavegen_preset_1khz_sawtooth(wavegen_channel_t channel);

#endif /* WAVEGEN_LIB_H */