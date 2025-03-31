#/bin/bash
sudo setpci -s 27:00.1 COMMAND=0x02
#sudo watch -n 1 ./pcimem /sys/devices/pci0000\:27/0000\:27\:00.1/resource2 32768 d*100
sudo watch -n 1 ./pcimem /sys/devices/pci0000\:27/0000\:27\:00.1/resource2 65536 d*64
#sudo watch -n 1 ./pcimem /sys/devices/pci0000\:27/0000\:27\:00.1/resource2 65560 d*1
