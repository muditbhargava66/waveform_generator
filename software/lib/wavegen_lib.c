#include <fcntl.h>
#include <unistd.h>
#include <sys/ioctl.h>
#include "wavegen_lib.h"
#include "wavegen_ip.h"

static int fd;

int wavegen_init() {
    fd = open("/dev/wavegen", O_RDWR);
    if (fd < 0) {
        return -1;
    }
    return 0;
}

void wavegen_close() {
    close(fd);
}

int wavegen_set_mode(wavegen_channel_t channel, wavegen_mode_t mode) {
    struct wavegen_mode config;
    config.channel_a = (channel == WAVEGEN_CHANNEL_A) ? mode : 0;
    config.channel_b = (channel == WAVEGEN_CHANNEL_B) ? mode : 0;
    return ioctl(fd, WAVEGEN_IOCTL_SET_MODE, &config);
}

int wavegen_set_frequency(wavegen_channel_t channel, uint32_t frequency) {
    struct wavegen_frequency config;
    config.channel = channel;
    config.value = frequency;
    return ioctl(fd, WAVEGEN_IOCTL_SET_FREQUENCY, &config);
}

int wavegen_set_amplitude(wavegen_channel_t channel, uint16_t amplitude) {
    struct wavegen_amplitude config;
    config.channel = channel;
    config.value = amplitude;
    return ioctl(fd, WAVEGEN_IOCTL_SET_AMPLITUDE, &config);
}

int wavegen_set_offset(wavegen_channel_t channel, int16_t offset) {
    struct wavegen_offset config;
    config.channel = channel;
    config.value = offset;
    return ioctl(fd, WAVEGEN_IOCTL_SET_OFFSET, &config);
}

int wavegen_set_duty_cycle(wavegen_channel_t channel, uint16_t duty_cycle) {
    struct wavegen_duty_cycle config;
    config.channel = channel;
    config.value = duty_cycle;
    return ioctl(fd, WAVEGEN_IOCTL_SET_DUTY_CYCLE, &config);
}

int wavegen_set_phase_offset(wavegen_channel_t channel, int16_t phase_offset) {
    struct wavegen_phase_offset config;
    config.channel = channel;
    config.value = phase_offset;
    return ioctl(fd, WAVEGEN_IOCTL_SET_PHASE_OFFSET, &config);
}

int wavegen_set_cycles(wavegen_channel_t channel, uint16_t cycles) {
    struct wavegen_cycles config;
    config.channel = channel;
    config.value = cycles;
    return ioctl(fd, WAVEGEN_IOCTL_SET_CYCLES, &config);
}

int wavegen_enable(wavegen_channel_t channel, uint8_t enable) {
    struct wavegen_enable config;
    config.channel_a = (channel == WAVEGEN_CHANNEL_A) ? enable : 0;
    config.channel_b = (channel == WAVEGEN_CHANNEL_B) ? enable : 0;
    return ioctl(fd, WAVEGEN_IOCTL_ENABLE, &config);
}

int wavegen_set_arb_waveform_depth(uint32_t depth) {
    struct wavegen_arb_waveform_depth config;
    config.depth = depth;
    return ioctl(fd, WAVEGEN_IOCTL_SET_ARB_WAVEFORM_DEPTH, &config);
}

int wavegen_set_arb_waveform_data(uint32_t offset, uint16_t value) {
    struct wavegen_arb_waveform_data config;
    config.offset = offset;
    config.value = value;
    return ioctl(fd, WAVEGEN_IOCTL_SET_ARB_WAVEFORM_DATA, &config);
}