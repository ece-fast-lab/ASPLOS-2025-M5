#/bin/bash
set -x
sudo setpci -s 27:00.1 COMMAND=0x02
sudo /home/yans3/gitdoc/pcimem/pcimem /sys/devices/pci0000\:27/0000\:27\:00.1/resource2 96 d 1
