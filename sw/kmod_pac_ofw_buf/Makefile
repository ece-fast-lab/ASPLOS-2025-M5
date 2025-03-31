KDIR = /lib/modules/$(shell uname -r)/build
obj-m += pac_ofw_buf.o
PWD := $(CURDIR)

all:
	make -C $(KDIR) M=$(PWD) modules

clean:
	make -C $(KDIR) M=$(PWD) clean
