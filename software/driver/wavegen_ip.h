#ifndef WAVEGEN_IP_H
#define WAVEGEN_IP_H

#include <linux/ioctl.h>

#define WAVEGEN_IOC_MAGIC 'w'

/* ============================================================
 * Data structures for ioctl commands
 * ============================================================ */

struct wavegen_mode {
    unsigned int channel_a;     /* Mode for channel A (0-5) */
    unsigned int channel_b;     /* Mode for channel B (0-5) */
};

struct wavegen_frequency {
    unsigned int channel;       /* WAVEGEN_CHANNEL_A or _B */
    unsigned int value;         /* Frequency in 100uHz units */
};

struct wavegen_amplitude {
    unsigned int channel;
    unsigned int value;         /* Amplitude (0-32767) */
};

struct wavegen_offset {
    unsigned int channel;
    int value;                  /* Signed offset */
};

struct wavegen_duty_cycle {
    unsigned int channel;
    unsigned int value;         /* Duty cycle (0-65535, maps to 0-100%) */
};

struct wavegen_phase_offset {
    unsigned int channel;
    int value;                  /* Phase offset in 0.01 degree units (-18000 to 18000) */
};

struct wavegen_cycles {
    unsigned int channel;
    unsigned int value;         /* Number of cycles (0 = continuous) */
};

struct wavegen_enable {
    unsigned int channel_a;     /* 1 = enable, 0 = disable */
    unsigned int channel_b;
};

struct wavegen_arb_waveform_depth {
    unsigned int depth;         /* Number of samples in arb waveform */
};

struct wavegen_arb_waveform_data {
    unsigned int offset;        /* Sample index */
    unsigned int value;         /* Sample value (16-bit) */
};

struct wavegen_arb_waveform_bulk {
    unsigned int start_offset;  /* Starting sample index */
    unsigned int count;         /* Number of samples */
    unsigned int *data;         /* Pointer to sample array (userspace) */
};

struct wavegen_trigger {
    unsigned int channel_a;     /* 1 = trigger */
    unsigned int channel_b;     /* 1 = trigger */
};

struct wavegen_status {
    unsigned int ready;
    unsigned int reconfig_busy;
    unsigned int channel_a_running;
    unsigned int channel_b_running;
    unsigned int raw;           /* Raw status register value */
};

/* ============================================================
 * IOCTL command definitions
 * ============================================================ */

#define WAVEGEN_IOCTL_SET_MODE              _IOW(WAVEGEN_IOC_MAGIC, 1, struct wavegen_mode)
#define WAVEGEN_IOCTL_SET_FREQUENCY         _IOW(WAVEGEN_IOC_MAGIC, 2, struct wavegen_frequency)
#define WAVEGEN_IOCTL_SET_AMPLITUDE         _IOW(WAVEGEN_IOC_MAGIC, 3, struct wavegen_amplitude)
#define WAVEGEN_IOCTL_SET_OFFSET            _IOW(WAVEGEN_IOC_MAGIC, 4, struct wavegen_offset)
#define WAVEGEN_IOCTL_SET_DUTY_CYCLE        _IOW(WAVEGEN_IOC_MAGIC, 5, struct wavegen_duty_cycle)
#define WAVEGEN_IOCTL_SET_PHASE_OFFSET      _IOW(WAVEGEN_IOC_MAGIC, 6, struct wavegen_phase_offset)
#define WAVEGEN_IOCTL_SET_CYCLES            _IOW(WAVEGEN_IOC_MAGIC, 7, struct wavegen_cycles)
#define WAVEGEN_IOCTL_ENABLE                _IOW(WAVEGEN_IOC_MAGIC, 8, struct wavegen_enable)
#define WAVEGEN_IOCTL_SET_ARB_DEPTH         _IOW(WAVEGEN_IOC_MAGIC, 9, struct wavegen_arb_waveform_depth)
#define WAVEGEN_IOCTL_SET_ARB_DATA          _IOW(WAVEGEN_IOC_MAGIC, 10, struct wavegen_arb_waveform_data)
#define WAVEGEN_IOCTL_SET_ARB_BULK          _IOW(WAVEGEN_IOC_MAGIC, 11, struct wavegen_arb_waveform_bulk)
#define WAVEGEN_IOCTL_TRIGGER               _IOW(WAVEGEN_IOC_MAGIC, 12, struct wavegen_trigger)
#define WAVEGEN_IOCTL_RECONFIG              _IO(WAVEGEN_IOC_MAGIC, 13)
#define WAVEGEN_IOCTL_GET_STATUS            _IOR(WAVEGEN_IOC_MAGIC, 14, struct wavegen_status)
#define WAVEGEN_IOCTL_SOFT_RESET            _IOW(WAVEGEN_IOC_MAGIC, 15, struct wavegen_trigger)

/* ============================================================
 * Function prototypes (implemented in wavegen_ip.c)
 * ============================================================ */

void wavegen_ip_set_mode(void __iomem *base, struct wavegen_mode *mode);
void wavegen_ip_set_frequency(void __iomem *base, struct wavegen_frequency *freq);
void wavegen_ip_set_amplitude(void __iomem *base, struct wavegen_amplitude *amp);
void wavegen_ip_set_offset(void __iomem *base, struct wavegen_offset *offset);
void wavegen_ip_set_duty_cycle(void __iomem *base, struct wavegen_duty_cycle *dc);
void wavegen_ip_set_phase_offset(void __iomem *base, struct wavegen_phase_offset *po);
void wavegen_ip_set_cycles(void __iomem *base, struct wavegen_cycles *cyc);
void wavegen_ip_enable(void __iomem *base, struct wavegen_enable *en);
void wavegen_ip_set_arb_depth(void __iomem *base, struct wavegen_arb_waveform_depth *d);
void wavegen_ip_set_arb_data(void __iomem *base, struct wavegen_arb_waveform_data *d);
void wavegen_ip_trigger(void __iomem *base, struct wavegen_trigger *trig);
void wavegen_ip_reconfig(void __iomem *base);
void wavegen_ip_get_status(void __iomem *base, struct wavegen_status *st);
void wavegen_ip_soft_reset(void __iomem *base, struct wavegen_trigger *rst);

#endif /* WAVEGEN_IP_H */