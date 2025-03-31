sudo rmmod pac_ofw_buf
dmesg -C
dmesg -D
make -j8
dmesg -E
sudo insmod pac_ofw_buf.ko $*
dmesg -D
#make clean
#dmesg -E
#rmmod ioat_map
