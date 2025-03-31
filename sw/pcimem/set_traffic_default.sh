#/bin/bash
set -x
sudo setpci -s 27:00.1 COMMAND=0x02
#sudo /home/yans3/gitdoc/pcimem/pcimem /sys/devices/pci0000\:27/0000\:27\:00.1/resource2 64 d 400000
#sudo /home/yans3/gitdoc/pcimem/pcimem /sys/devices/pci0000\:27/0000\:27\:00.1/resource2 64 d 0x800000FF
sudo /home/yans3/gitdoc/pcimem/pcimem /sys/devices/pci0000\:27/0000\:27\:00.1/resource2 64 d 0x800FFFFF
sudo /home/yans3/gitdoc/pcimem/pcimem /sys/devices/pci0000\:27/0000\:27\:00.1/resource2 72 d 0x80000FFF
#sudo /home/yans3/gitdoc/pcimem/pcimem /sys/devices/pci0000\:27/0000\:27\:00.1/resource2 72 d 1000000
#sudo /home/yans3/gitdoc/pcimem/pcimem /sys/devices/pci0000\:27/0000\:27\:00.1/resource2 72 d 2000
#sudo /home/yans3/gitdoc/pcimem/pcimem /sys/devices/pci0000\:27/0000\:27\:00.1/resource2 72 d 4000
