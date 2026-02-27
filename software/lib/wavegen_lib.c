#include <fcntl.h>
#include <unistd.h>
#include <string.h>
#include <sys/ioctl.h>
#include <stdlib.h>
#include "wavegen_lib.h"
#include "../driver/wavegen_ip.h"

/* ============================================================
 * Internal state
 * ============================================================ */
static int fd = -1;
static wavegen_mode_t current_mode_a = WAVEGEN_MODE_DC;
static wavegen_mode_t current_mode_b = WAVEGEN_MODE_DC;

/* ============================================================
 * Core API
 * ============================================================ */

wavegen_error_t wavegen_init(void)
{
    fd = open("/dev/wavegen", O_RDWR);
    if (fd < 0)
        return WAVEGEN_ERR_INIT;
    current_mode_a = WAVEGEN_MODE_DC;
    current_mode_b = WAVEGEN_MODE_DC;
    return WAVEGEN_OK;
}

void wavegen_close(void)
{
    if (fd >= 0) {
        close(fd);
        fd = -1;
    }
}

/* ============================================================
 * Parameter Configuration 
 * ============================================================ */

wavegen_error_t wavegen_set_mode(wavegen_channel_t channel, wavegen_mode_t mode)
{
    struct wavegen_mode config;

    if (fd < 0) return WAVEGEN_ERR_NOT_INIT;
    if (mode > WAVEGEN_MODE_ARB) return WAVEGEN_ERR_PARAM;

    /* Read-modify-write: preserve the other channel's mode */
    if (channel == WAVEGEN_CH_A) {
        current_mode_a = mode;
        config.channel_a = current_mode_a;
        config.channel_b = current_mode_b;
    } else if (channel == WAVEGEN_CH_B) {
        current_mode_b = mode;
        config.channel_a = current_mode_a;
        config.channel_b = current_mode_b;
    } else if (channel == WAVEGEN_CH_BOTH) {
        current_mode_a = mode;
        current_mode_b = mode;
        config.channel_a = mode;
        config.channel_b = mode;
    } else {
        return WAVEGEN_ERR_PARAM;
    }

    if (ioctl(fd, WAVEGEN_IOCTL_SET_MODE, &config) < 0)
        return WAVEGEN_ERR_IOCTL;

    return WAVEGEN_OK;
}

wavegen_error_t wavegen_set_frequency(wavegen_channel_t channel, uint32_t frequency)
{
    struct wavegen_frequency config;
    if (fd < 0) return WAVEGEN_ERR_NOT_INIT;

    if (channel == WAVEGEN_CH_BOTH) {
        wavegen_error_t ret;
        ret = wavegen_set_frequency(WAVEGEN_CH_A, frequency);
        if (ret != WAVEGEN_OK) return ret;
        return wavegen_set_frequency(WAVEGEN_CH_B, frequency);
    }

    config.channel = (channel == WAVEGEN_CH_A) ? 0 : 1;
    config.value = frequency;

    if (ioctl(fd, WAVEGEN_IOCTL_SET_FREQUENCY, &config) < 0)
        return WAVEGEN_ERR_IOCTL;

    return WAVEGEN_OK;
}

wavegen_error_t wavegen_set_amplitude(wavegen_channel_t channel, uint16_t amplitude)
{
    struct wavegen_amplitude config;
    if (fd < 0) return WAVEGEN_ERR_NOT_INIT;

    if (channel == WAVEGEN_CH_BOTH) {
        wavegen_error_t ret;
        ret = wavegen_set_amplitude(WAVEGEN_CH_A, amplitude);
        if (ret != WAVEGEN_OK) return ret;
        return wavegen_set_amplitude(WAVEGEN_CH_B, amplitude);
    }

    config.channel = (channel == WAVEGEN_CH_A) ? 0 : 1;
    config.value = amplitude;

    if (ioctl(fd, WAVEGEN_IOCTL_SET_AMPLITUDE, &config) < 0)
        return WAVEGEN_ERR_IOCTL;

    return WAVEGEN_OK;
}

wavegen_error_t wavegen_set_offset(wavegen_channel_t channel, int16_t offset)
{
    struct wavegen_offset config;
    if (fd < 0) return WAVEGEN_ERR_NOT_INIT;

    if (channel == WAVEGEN_CH_BOTH) {
        wavegen_error_t ret;
        ret = wavegen_set_offset(WAVEGEN_CH_A, offset);
        if (ret != WAVEGEN_OK) return ret;
        return wavegen_set_offset(WAVEGEN_CH_B, offset);
    }

    config.channel = (channel == WAVEGEN_CH_A) ? 0 : 1;
    config.value = offset;

    if (ioctl(fd, WAVEGEN_IOCTL_SET_OFFSET, &config) < 0)
        return WAVEGEN_ERR_IOCTL;

    return WAVEGEN_OK;
}

wavegen_error_t wavegen_set_duty_cycle(wavegen_channel_t channel, uint16_t duty_cycle)
{
    struct wavegen_duty_cycle config;
    if (fd < 0) return WAVEGEN_ERR_NOT_INIT;

    if (channel == WAVEGEN_CH_BOTH) {
        wavegen_error_t ret;
        ret = wavegen_set_duty_cycle(WAVEGEN_CH_A, duty_cycle);
        if (ret != WAVEGEN_OK) return ret;
        return wavegen_set_duty_cycle(WAVEGEN_CH_B, duty_cycle);
    }

    config.channel = (channel == WAVEGEN_CH_A) ? 0 : 1;
    config.value = duty_cycle;

    if (ioctl(fd, WAVEGEN_IOCTL_SET_DUTY_CYCLE, &config) < 0)
        return WAVEGEN_ERR_IOCTL;

    return WAVEGEN_OK;
}

wavegen_error_t wavegen_set_phase_offset(wavegen_channel_t channel, int16_t phase_offset)
{
    struct wavegen_phase_offset config;
    if (fd < 0) return WAVEGEN_ERR_NOT_INIT;

    if (phase_offset < -18000 || phase_offset > 18000)
        return WAVEGEN_ERR_PARAM;

    if (channel == WAVEGEN_CH_BOTH) {
        wavegen_error_t ret;
        ret = wavegen_set_phase_offset(WAVEGEN_CH_A, phase_offset);
        if (ret != WAVEGEN_OK) return ret;
        return wavegen_set_phase_offset(WAVEGEN_CH_B, phase_offset);
    }

    config.channel = (channel == WAVEGEN_CH_A) ? 0 : 1;
    config.value = phase_offset;

    if (ioctl(fd, WAVEGEN_IOCTL_SET_PHASE_OFFSET, &config) < 0)
        return WAVEGEN_ERR_IOCTL;

    return WAVEGEN_OK;
}

wavegen_error_t wavegen_set_cycles(wavegen_channel_t channel, uint16_t cycles)
{
    struct wavegen_cycles config;
    if (fd < 0) return WAVEGEN_ERR_NOT_INIT;

    if (channel == WAVEGEN_CH_BOTH) {
        wavegen_error_t ret;
        ret = wavegen_set_cycles(WAVEGEN_CH_A, cycles);
        if (ret != WAVEGEN_OK) return ret;
        return wavegen_set_cycles(WAVEGEN_CH_B, cycles);
    }

    config.channel = (channel == WAVEGEN_CH_A) ? 0 : 1;
    config.value = cycles;

    if (ioctl(fd, WAVEGEN_IOCTL_SET_CYCLES, &config) < 0)
        return WAVEGEN_ERR_IOCTL;

    return WAVEGEN_OK;
}

/* ============================================================
 * Control API
 * ============================================================ */

wavegen_error_t wavegen_enable(wavegen_channel_t channel, int enable)
{
    struct wavegen_enable config;
    if (fd < 0) return WAVEGEN_ERR_NOT_INIT;

    /* Default: don't change either channel */
    config.channel_a = 0;
    config.channel_b = 0;

    if (channel == WAVEGEN_CH_A || channel == WAVEGEN_CH_BOTH)
        config.channel_a = enable ? 1 : 0;
    if (channel == WAVEGEN_CH_B || channel == WAVEGEN_CH_BOTH)
        config.channel_b = enable ? 1 : 0;

    if (ioctl(fd, WAVEGEN_IOCTL_ENABLE, &config) < 0)
        return WAVEGEN_ERR_IOCTL;

    return WAVEGEN_OK;
}

wavegen_error_t wavegen_start(wavegen_channel_t channel)
{
    wavegen_error_t ret;
    ret = wavegen_enable(channel, 1);
    if (ret != WAVEGEN_OK) return ret;
    return wavegen_trigger(channel);
}

wavegen_error_t wavegen_stop(wavegen_channel_t channel)
{
    return wavegen_enable(channel, 0);
}

wavegen_error_t wavegen_apply(void)
{
    if (fd < 0) return WAVEGEN_ERR_NOT_INIT;
    if (ioctl(fd, WAVEGEN_IOCTL_RECONFIG) < 0)
        return WAVEGEN_ERR_IOCTL;
    return WAVEGEN_OK;
}

wavegen_error_t wavegen_trigger(wavegen_channel_t channel)
{
    struct wavegen_trigger trig;
    if (fd < 0) return WAVEGEN_ERR_NOT_INIT;

    trig.channel_a = (channel == WAVEGEN_CH_A || channel == WAVEGEN_CH_BOTH) ? 1 : 0;
    trig.channel_b = (channel == WAVEGEN_CH_B || channel == WAVEGEN_CH_BOTH) ? 1 : 0;

    if (ioctl(fd, WAVEGEN_IOCTL_TRIGGER, &trig) < 0)
        return WAVEGEN_ERR_IOCTL;

    return WAVEGEN_OK;
}

wavegen_error_t wavegen_reset(wavegen_channel_t channel)
{
    struct wavegen_trigger rst;
    if (fd < 0) return WAVEGEN_ERR_NOT_INIT;

    rst.channel_a = (channel == WAVEGEN_CH_A || channel == WAVEGEN_CH_BOTH) ? 1 : 0;
    rst.channel_b = (channel == WAVEGEN_CH_B || channel == WAVEGEN_CH_BOTH) ? 1 : 0;

    if (ioctl(fd, WAVEGEN_IOCTL_SOFT_RESET, &rst) < 0)
        return WAVEGEN_ERR_IOCTL;

    return WAVEGEN_OK;
}

wavegen_error_t wavegen_get_status(wavegen_status_t *status)
{
    struct wavegen_status raw;
    if (fd < 0) return WAVEGEN_ERR_NOT_INIT;
    if (!status) return WAVEGEN_ERR_PARAM;

    if (ioctl(fd, WAVEGEN_IOCTL_GET_STATUS, &raw) < 0)
        return WAVEGEN_ERR_IOCTL;

    status->ready = raw.ready;
    status->reconfig_busy = raw.reconfig_busy;
    status->channel_a_running = raw.channel_a_running;
    status->channel_b_running = raw.channel_b_running;
    return WAVEGEN_OK;
}

/* ============================================================
 * Batch Configuration
 * ============================================================ */

wavegen_error_t wavegen_configure(wavegen_channel_t channel,
                                   const wavegen_config_t *config)
{
    wavegen_error_t ret;
    if (!config) return WAVEGEN_ERR_PARAM;

    ret = wavegen_set_mode(channel, config->mode);
    if (ret != WAVEGEN_OK) return ret;

    ret = wavegen_set_frequency(channel, config->frequency);
    if (ret != WAVEGEN_OK) return ret;

    ret = wavegen_set_amplitude(channel, config->amplitude);
    if (ret != WAVEGEN_OK) return ret;

    ret = wavegen_set_offset(channel, config->offset);
    if (ret != WAVEGEN_OK) return ret;

    ret = wavegen_set_duty_cycle(channel, config->duty_cycle);
    if (ret != WAVEGEN_OK) return ret;

    ret = wavegen_set_phase_offset(channel, config->phase_offset);
    if (ret != WAVEGEN_OK) return ret;

    ret = wavegen_set_cycles(channel, config->cycles);
    if (ret != WAVEGEN_OK) return ret;

    /* Apply changes atomically */
    return wavegen_apply();
}

/* ============================================================
 * Arbitrary Waveform API
 * ============================================================ */

wavegen_error_t wavegen_set_arb_depth(uint32_t depth)
{
    struct wavegen_arb_waveform_depth config;
    if (fd < 0) return WAVEGEN_ERR_NOT_INIT;

    config.depth = depth;
    if (ioctl(fd, WAVEGEN_IOCTL_SET_ARB_DEPTH, &config) < 0)
        return WAVEGEN_ERR_IOCTL;

    return WAVEGEN_OK;
}

wavegen_error_t wavegen_set_arb_sample(uint32_t index, uint16_t value)
{
    struct wavegen_arb_waveform_data config;
    if (fd < 0) return WAVEGEN_ERR_NOT_INIT;

    config.offset = index;
    config.value = value;
    if (ioctl(fd, WAVEGEN_IOCTL_SET_ARB_DATA, &config) < 0)
        return WAVEGEN_ERR_IOCTL;

    return WAVEGEN_OK;
}

wavegen_error_t wavegen_load_arb_waveform(const uint16_t *data, uint32_t count)
{
    struct wavegen_arb_waveform_bulk bulk;
    unsigned int *buf;
    unsigned int i;

    if (fd < 0) return WAVEGEN_ERR_NOT_INIT;
    if (!data || count == 0) return WAVEGEN_ERR_PARAM;

    /* Convert uint16_t array to unsigned int array for ioctl */
    buf = (unsigned int *)malloc(count * sizeof(unsigned int));
    if (!buf) return WAVEGEN_ERR_ALLOC;

    for (i = 0; i < count; i++)
        buf[i] = data[i];

    bulk.start_offset = 0;
    bulk.count = count;
    bulk.data = buf;

    int ret = ioctl(fd, WAVEGEN_IOCTL_SET_ARB_BULK, &bulk);
    free(buf);

    if (ret < 0)
        return WAVEGEN_ERR_IOCTL;

    /* Also set the depth register */
    return wavegen_set_arb_depth(count);
}

/* ============================================================
 * Preset Waveforms
 * ============================================================ */

wavegen_error_t wavegen_preset_1khz_sine(wavegen_channel_t channel)
{
    wavegen_config_t config = {
        .mode = WAVEGEN_MODE_SINE,
        .frequency = 10000000,      /* 1 kHz in 100uHz units */
        .amplitude = 32767,         /* Full amplitude */
        .offset = 0,
        .duty_cycle = 32768,        /* 50% (ignored for sine) */
        .phase_offset = 0,
        .cycles = 0                 /* Continuous */
    };
    return wavegen_configure(channel, &config);
}

wavegen_error_t wavegen_preset_1khz_square(wavegen_channel_t channel)
{
    wavegen_config_t config = {
        .mode = WAVEGEN_MODE_SQUARE,
        .frequency = 10000000,
        .amplitude = 32767,
        .offset = 0,
        .duty_cycle = 32768,        /* 50% duty cycle */
        .phase_offset = 0,
        .cycles = 0
    };
    return wavegen_configure(channel, &config);
}

wavegen_error_t wavegen_preset_1khz_triangle(wavegen_channel_t channel)
{
    wavegen_config_t config = {
        .mode = WAVEGEN_MODE_TRIANGLE,
        .frequency = 10000000,
        .amplitude = 32767,
        .offset = 0,
        .duty_cycle = 32768,
        .phase_offset = 0,
        .cycles = 0
    };
    return wavegen_configure(channel, &config);
}

wavegen_error_t wavegen_preset_1khz_sawtooth(wavegen_channel_t channel)
{
    wavegen_config_t config = {
        .mode = WAVEGEN_MODE_SAWTOOTH,
        .frequency = 10000000,
        .amplitude = 32767,
        .offset = 0,
        .duty_cycle = 32768,
        .phase_offset = 0,
        .cycles = 0
    };
    return wavegen_configure(channel, &config);
}