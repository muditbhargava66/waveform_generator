#ifndef WAVEGEN_LIB_H
#define WAVEGEN_LIB_H

#include <stdint.h>

// Waveform modes
typedef enum {
    WAVEGEN_MODE_DC,
    WAVEGEN_MODE_SINE,
    WAVEGEN_MODE_SAWTOOTH,
    WAVEGEN_MODE_TRIANGLE,
    WAVEGEN_MODE_SQUARE,
    WAVEGEN_MODE_ARB
} wavegen_mode_t;

// Channel selection
typedef enum {
    WAVEGEN_CHANNEL_A,
    WAVEGEN_CHANNEL_B
} wavegen_channel_t;

// Function prototypes
int wavegen_init();
void wavegen_close();
int wavegen_set_mode(wavegen_channel_t channel, wavegen_mode_t mode);
int wavegen_set_frequency(wavegen_channel_t channel, uint32_t frequency);
int wavegen_set_amplitude(wavegen_channel_t channel, uint16_t amplitude);
int wavegen_set_offset(wavegen_channel_t channel, int16_t offset);
int wavegen_set_duty_cycle(wavegen_channel_t channel, uint16_t duty_cycle);
int wavegen_set_phase_offset(wavegen_channel_t channel, int16_t phase_offset);
int wavegen_set_cycles(wavegen_channel_t channel, uint16_t cycles);
int wavegen_enable(wavegen_channel_t channel, uint8_t enable);
int wavegen_set_arb_waveform_depth(uint32_t depth);
int wavegen_set_arb_waveform_data(uint32_t offset, uint16_t value);

#endif /* WAVEGEN_LIB_H */