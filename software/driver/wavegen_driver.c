#include <linux/init.h>
#include <linux/module.h>
#include <linux/kernel.h>
#include <linux/fs.h>
#include <linux/device.h>
#include <linux/cdev.h>
#include <linux/uaccess.h>
#include <linux/io.h>
#include "wavegen_ip.h"
#include "wavegen_regs.h"

#define DRIVER_NAME "wavegen"
#define DEVICE_NAME "wavegen"

static struct class *wavegen_class;
static struct cdev wavegen_cdev;
static dev_t wavegen_dev;

static void __iomem *wavegen_base;

static int wavegen_open(struct inode *inode, struct file *file)
{
    return 0;
}

static int wavegen_release(struct inode *inode, struct file *file)
{
    return 0;
}

static long wavegen_ioctl(struct file *file, unsigned int cmd, unsigned long arg)
{
    switch (cmd) {
        case WAVEGEN_IOCTL_SET_MODE:
            wavegen_set_mode((struct wavegen_mode *)arg);
            break;
        case WAVEGEN_IOCTL_SET_FREQUENCY:
            wavegen_set_frequency((struct wavegen_frequency *)arg);
            break;
        case WAVEGEN_IOCTL_SET_AMPLITUDE:
            wavegen_set_amplitude((struct wavegen_amplitude *)arg);
            break;
        case WAVEGEN_IOCTL_SET_OFFSET:
            wavegen_set_offset((struct wavegen_offset *)arg);
            break;
        case WAVEGEN_IOCTL_SET_DUTY_CYCLE:
            wavegen_set_duty_cycle((struct wavegen_duty_cycle *)arg);
            break;
        case WAVEGEN_IOCTL_SET_PHASE_OFFSET:
            wavegen_set_phase_offset((struct wavegen_phase_offset *)arg);
            break;
        case WAVEGEN_IOCTL_SET_CYCLES:
            wavegen_set_cycles((struct wavegen_cycles *)arg);
            break;
        case WAVEGEN_IOCTL_ENABLE:
            wavegen_enable((struct wavegen_enable *)arg);
            break;
        case WAVEGEN_IOCTL_SET_ARB_WAVEFORM_DEPTH:
            wavegen_set_arb_waveform_depth((struct wavegen_arb_waveform_depth *)arg);
            break;
        case WAVEGEN_IOCTL_SET_ARB_WAVEFORM_DATA:
            wavegen_set_arb_waveform_data((struct wavegen_arb_waveform_data *)arg);
            break;
        default:
            return -EINVAL;
    }
    return 0;
}

static struct file_operations wavegen_fops = {
    .owner          = THIS_MODULE,
    .open           = wavegen_open,
    .release        = wavegen_release,
    .unlocked_ioctl = wavegen_ioctl,
};

static int __init wavegen_init(void)
{
    int ret;

    ret = alloc_chrdev_region(&wavegen_dev, 0, 1, DEVICE_NAME);
    if (ret < 0) {
        pr_err("Failed to allocate character device region\n");
        return ret;
    }

    wavegen_class = class_create(THIS_MODULE, DEVICE_NAME);
    if (IS_ERR(wavegen_class)) {
        pr_err("Failed to create device class\n");
        ret = PTR_ERR(wavegen_class);
        goto unregister_chrdev;
    }

    device_create(wavegen_class, NULL, wavegen_dev, NULL, DEVICE_NAME);

    cdev_init(&wavegen_cdev, &wavegen_fops);
    ret = cdev_add(&wavegen_cdev, wavegen_dev, 1);
    if (ret < 0) {
        pr_err("Failed to add character device\n");
        goto destroy_device;
    }

    wavegen_base = ioremap(WAVEGEN_BASE_ADDR, WAVEGEN_ADDR_RANGE);
    if (!wavegen_base) {
        pr_err("Failed to map wavegen IP registers\n");
        ret = -ENOMEM;
        goto remove_cdev;
    }

    pr_info("Wavegen driver initialized\n");
    return 0;

remove_cdev:
    cdev_del(&wavegen_cdev);
destroy_device:
    device_destroy(wavegen_class, wavegen_dev);
    class_destroy(wavegen_class);
unregister_chrdev:
    unregister_chrdev_region(wavegen_dev, 1);
    return ret;
}

static void __exit wavegen_exit(void)
{
    iounmap(wavegen_base);
    cdev_del(&wavegen_cdev);
    device_destroy(wavegen_class, wavegen_dev);
    class_destroy(wavegen_class);
    unregister_chrdev_region(wavegen_dev, 1);
    pr_info("Wavegen driver exited\n");
}

module_init(wavegen_init);
module_exit(wavegen_exit);

MODULE_LICENSE("GPL");
MODULE_AUTHOR("Mudit B.");
MODULE_DESCRIPTION("Wavegen driver");
MODULE_VERSION("1.0");

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

void wavegen_set_arb_waveform_depth(struct wavegen_arb_waveform_depth *depth)
{
    iowrite32(depth->depth, wavegen_base + WAVEGEN_ARB_DEPTH_OFFSET);
}

void wavegen_set_arb_waveform_data(struct wavegen_arb_waveform_data *data)
{
    iowrite32(data->value, wavegen_base + WAVEGEN_ARB_DATA_OFFSET + data->offset * 4);
}