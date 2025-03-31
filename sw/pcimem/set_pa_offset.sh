set -x
sudo setpci -s 27:00.1 COMMAND=0x02
sudo /home/yans3/gitdoc/pcimem/pcimem /sys/devices/pci0000\:27/0000\:27\:00.1/resource2 80 d 0x2080000000
#sudo /home/yans3/gitdoc/pcimem/pcimem /sys/devices/pci0000\:27/0000\:27\:00.1/resource2 112 d 0
sudo /home/yans3/gitdoc/pcimem/pcimem /sys/devices/pci0000\:27/0000\:27\:00.1/resource2 112 d 0x180000000
