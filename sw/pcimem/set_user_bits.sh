#/bin/bash
set -x
sudo setpci -s 27:00.1 COMMAND=0x02
#awuser 0x22 -- 10 0010 -- HDM, host-bias, nc-p // hot addr, hot page (bot host)
#aruser 0x22 -- 10 0010 -- HDM, host-bais, cache-own read // hot page read (hard coded), read src addr ()
sudo /home/yans3/gitdoc/pcimem/pcimem /sys/devices/pci0000\:27/0000\:27\:00.1/resource2 104 d 0x0200000002

#awuser 0x21 -- 10 0001 -- HDM, host-bias, cache-own write
#aruser 0x22 -- 10 0010 -- HDM, host-bais, cache-own read
#sudo /home/yans3/gitdoc/pcimem/pcimem /sys/devices/pci0000\:27/0000\:27\:00.1/resource2 104 d 0x2100000022
