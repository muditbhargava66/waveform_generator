obj-m += wavegen_driver.o
wavegen_driver-objs := wavegen_driver.o wavegen_ip.o

KDIR := /lib/modules/$(shell uname -r)/build
PWD := $(shell pwd)

default:
    $(MAKE) -C $(KDIR) M=$(PWD) modules

clean:
    $(MAKE) -C $(KDIR) M=$(PWD) clean