#include <linux/init.h>
#include <linux/module.h>
#include <linux/kernel.h>
#include <linux/fs.h>
#include <linux/device.h>
#include <linux/cdev.h>
#include <linux/uaccess.h>
#include <linux/io.h>
#include <linux/slab.h>
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

/*
 * IOCTL handler with proper copy_from_user/copy_to_user
 * for kernel safety. All userspace pointers are validated
 * before dereferencing.
 */
static long wavegen_ioctl(struct file *file, unsigned int cmd, unsigned long arg)
{
    int ret = 0;

    switch (cmd) {
        case WAVEGEN_IOCTL_SET_MODE: {
            struct wavegen_mode data;
            if (copy_from_user(&data, (void __user *)arg, sizeof(data)))
                return -EFAULT;
            wavegen_ip_set_mode(wavegen_base, &data);
            break;
        }
        case WAVEGEN_IOCTL_SET_FREQUENCY: {
            struct wavegen_frequency data;
            if (copy_from_user(&data, (void __user *)arg, sizeof(data)))
                return -EFAULT;
            wavegen_ip_set_frequency(wavegen_base, &data);
            break;
        }
        case WAVEGEN_IOCTL_SET_AMPLITUDE: {
            struct wavegen_amplitude data;
            if (copy_from_user(&data, (void __user *)arg, sizeof(data)))
                return -EFAULT;
            wavegen_ip_set_amplitude(wavegen_base, &data);
            break;
        }
        case WAVEGEN_IOCTL_SET_OFFSET: {
            struct wavegen_offset data;
            if (copy_from_user(&data, (void __user *)arg, sizeof(data)))
                return -EFAULT;
            wavegen_ip_set_offset(wavegen_base, &data);
            break;
        }
        case WAVEGEN_IOCTL_SET_DUTY_CYCLE: {
            struct wavegen_duty_cycle data;
            if (copy_from_user(&data, (void __user *)arg, sizeof(data)))
                return -EFAULT;
            wavegen_ip_set_duty_cycle(wavegen_base, &data);
            break;
        }
        case WAVEGEN_IOCTL_SET_PHASE_OFFSET: {
            struct wavegen_phase_offset data;
            if (copy_from_user(&data, (void __user *)arg, sizeof(data)))
                return -EFAULT;
            wavegen_ip_set_phase_offset(wavegen_base, &data);
            break;
        }
        case WAVEGEN_IOCTL_SET_CYCLES: {
            struct wavegen_cycles data;
            if (copy_from_user(&data, (void __user *)arg, sizeof(data)))
                return -EFAULT;
            wavegen_ip_set_cycles(wavegen_base, &data);
            break;
        }
        case WAVEGEN_IOCTL_ENABLE: {
            struct wavegen_enable data;
            if (copy_from_user(&data, (void __user *)arg, sizeof(data)))
                return -EFAULT;
            wavegen_ip_enable(wavegen_base, &data);
            break;
        }
        case WAVEGEN_IOCTL_SET_ARB_DEPTH: {
            struct wavegen_arb_waveform_depth data;
            if (copy_from_user(&data, (void __user *)arg, sizeof(data)))
                return -EFAULT;
            wavegen_ip_set_arb_depth(wavegen_base, &data);
            break;
        }
        case WAVEGEN_IOCTL_SET_ARB_DATA: {
            struct wavegen_arb_waveform_data data;
            if (copy_from_user(&data, (void __user *)arg, sizeof(data)))
                return -EFAULT;
            wavegen_ip_set_arb_data(wavegen_base, &data);
            break;
        }
        case WAVEGEN_IOCTL_SET_ARB_BULK: {
            struct wavegen_arb_waveform_bulk bulk;
            unsigned int *kbuf;
            unsigned int i;
            struct wavegen_arb_waveform_data single;

            if (copy_from_user(&bulk, (void __user *)arg, sizeof(bulk)))
                return -EFAULT;

            if (bulk.count == 0 || bulk.count > 4096)
                return -EINVAL;

            kbuf = kmalloc_array(bulk.count, sizeof(unsigned int), GFP_KERNEL);
            if (!kbuf)
                return -ENOMEM;

            if (copy_from_user(kbuf, (void __user *)bulk.data,
                               bulk.count * sizeof(unsigned int))) {
                kfree(kbuf);
                return -EFAULT;
            }

            for (i = 0; i < bulk.count; i++) {
                single.offset = bulk.start_offset + i;
                single.value = kbuf[i];
                wavegen_ip_set_arb_data(wavegen_base, &single);
            }

            kfree(kbuf);
            break;
        }
        case WAVEGEN_IOCTL_TRIGGER: {
            struct wavegen_trigger data;
            if (copy_from_user(&data, (void __user *)arg, sizeof(data)))
                return -EFAULT;
            wavegen_ip_trigger(wavegen_base, &data);
            break;
        }
        case WAVEGEN_IOCTL_RECONFIG: {
            wavegen_ip_reconfig(wavegen_base);
            break;
        }
        case WAVEGEN_IOCTL_GET_STATUS: {
            struct wavegen_status data;
            wavegen_ip_get_status(wavegen_base, &data);
            if (copy_to_user((void __user *)arg, &data, sizeof(data)))
                return -EFAULT;
            break;
        }
        case WAVEGEN_IOCTL_SOFT_RESET: {
            struct wavegen_trigger data;
            if (copy_from_user(&data, (void __user *)arg, sizeof(data)))
                return -EFAULT;
            wavegen_ip_soft_reset(wavegen_base, &data);
            break;
        }
        default:
            return -EINVAL;
    }
    return ret;
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
        pr_err("wavegen: Failed to allocate character device region\n");
        return ret;
    }

    wavegen_class = class_create(THIS_MODULE, DEVICE_NAME);
    if (IS_ERR(wavegen_class)) {
        pr_err("wavegen: Failed to create device class\n");
        ret = PTR_ERR(wavegen_class);
        goto unregister_chrdev;
    }

    if (IS_ERR(device_create(wavegen_class, NULL, wavegen_dev, NULL, DEVICE_NAME))) {
        pr_err("wavegen: Failed to create device\n");
        ret = -ENODEV;
        goto destroy_class;
    }

    cdev_init(&wavegen_cdev, &wavegen_fops);
    ret = cdev_add(&wavegen_cdev, wavegen_dev, 1);
    if (ret < 0) {
        pr_err("wavegen: Failed to add character device\n");
        goto destroy_device;
    }

    wavegen_base = ioremap(WAVEGEN_BASE_ADDR, WAVEGEN_ADDR_RANGE);
    if (!wavegen_base) {
        pr_err("wavegen: Failed to map IP registers\n");
        ret = -ENOMEM;
        goto remove_cdev;
    }

    pr_info("wavegen: Driver initialized (base=0x%08X)\n", WAVEGEN_BASE_ADDR);
    return 0;

remove_cdev:
    cdev_del(&wavegen_cdev);
destroy_device:
    device_destroy(wavegen_class, wavegen_dev);
destroy_class:
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
    pr_info("wavegen: Driver exited\n");
}

module_init(wavegen_init);
module_exit(wavegen_exit);

MODULE_LICENSE("GPL");
MODULE_AUTHOR("Mudit B.");
MODULE_DESCRIPTION("Waveform Generator IP driver");
MODULE_VERSION("2.0");