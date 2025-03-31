#/bin/bash
sudo setpci -s 27:00.1 COMMAND=0x02
sudo watch -n 1 ./pcimem /sys/devices/pci0000\:27/0000\:27\:00.1/resource2 32768 w*128
#sudo watch -n 1 ./pcimem /sys/devices/pci0000\:27/0000\:27\:00.1/resource2 32768 w*16
#sudo watch -n 1 ./pcimem /sys/devices/pci0000\:27/0000\:27\:00.1/resource2 32776 w*4
