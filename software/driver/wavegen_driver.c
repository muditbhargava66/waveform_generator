#include <linux/init.h>
#include <linux/module.h>
#include <linux/kernel.h>
#include <linux/fs.h>
#include <linux/device.h>
#include <linux/cdev.h>
#include <linux/uaccess.h>
#include <linux/io.h>
#include "wavegen_ip.h"

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
MODULE_AUTHOR("Your Name");
MODULE_DESCRIPTION("Wavegen driver");
MODULE_VERSION("1.0");