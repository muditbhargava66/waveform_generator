#ifndef WAVEGEN_IP_H
#define WAVEGEN_IP_H

#include <linux/ioctl.h>

#define WAVEGEN_IOC_MAGIC 'w'

struct wavegen_mode {
    unsigned int channel_a;
    unsigned int channel_b;
};

struct wavegen_frequency {
    unsigned int channel;
    unsigned int value;
};

struct wavegen_amplitude {
    unsigned int channel;
    unsigned int value;
};

struct wavegen_offset {
    unsigned int channel;
    unsigned int value;
};

struct wavegen_duty_cycle {
    unsigned int channel;
    unsigned int value;
};

struct wavegen_phase_offset {
    unsigned int channel;
    unsigned int value;
};

struct wavegen_cycles {
    unsigned int channel;
    unsigned int value;
};

struct wavegen_enable {
    unsigned int channel_a;
    unsigned int channel_b;
};

struct wavegen_arb_waveform_depth {
    unsigned int depth;
};

struct wavegen_arb_waveform_data {
    unsigned int offset;
    unsigned int value;
};

#define WAVEGEN_IOCTL_SET_MODE          _IOW(WAVEGEN_IOC_MAGIC, 1, struct wavegen_mode)
#define WAVEGEN_IOCTL_SET_FREQUENCY     _IOW(WAVEGEN_IOC_MAGIC, 2, struct wavegen_frequency)
#define WAVEGEN_IOCTL_SET_AMPLITUDE     _IOW(WAVEGEN_IOC_MAGIC, 3, struct wavegen_amplitude)
#define WAVEGEN_IOCTL_SET_OFFSET        _IOW(WAVEGEN_IOC_MAGIC, 4, struct wavegen_offset)
#define WAVEGEN_IOCTL_SET_DUTY_CYCLE    _IOW(WAVEGEN_IOC_MAGIC, 5, struct wavegen_duty_cycle)
#define WAVEGEN_IOCTL_SET_PHASE_OFFSET  _IOW(WAVEGEN_IOC_MAGIC, 6, struct wavegen_phase_offset)
#define WAVEGEN_IOCTL_SET_CYCLES        _IOW(WAVEGEN_IOC_MAGIC, 7, struct wavegen_cycles)
#define WAVEGEN_IOCTL_ENABLE            _IOW(WAVEGEN_IOC_MAGIC, 8, struct wavegen_enable)
#define WAVEGEN_IOCTL_SET_ARB_WAVEFORM_DEPTH _IOW(WAVEGEN_IOC_MAGIC, 9, struct wavegen_arb_waveform_depth)
#define WAVEGEN_IOCTL_SET_ARB_WAVEFORM_DATA  _IOW(WAVEGEN_IOC_MAGIC, 10, struct wavegen_arb_waveform_data)

#define WAVEGEN_CHANNEL_A 0
#define WAVEGEN_CHANNEL_B 1

void wavegen_set_mode(struct wavegen_mode *mode);
void wavegen_set_frequency(struct wavegen_frequency *frequency);
void wavegen_set_amplitude(struct wavegen_amplitude *amplitude);
void wavegen_set_offset(struct wavegen_offset *offset);
void wavegen_set_duty_cycle(struct wavegen_duty_cycle *duty_cycle);
void wavegen_set_phase_offset(struct wavegen_phase_offset *phase_offset);
void wavegen_set_cycles(struct wavegen_cycles *cycles);
void wavegen_enable(struct wavegen_enable *enable);
void wavegen_set_arb_waveform_depth(struct wavegen_arb_waveform_depth *depth);
void wavegen_set_arb_waveform_data(struct wavegen_arb_waveform_data *data);

#endif /* WAVEGEN_IP_H */