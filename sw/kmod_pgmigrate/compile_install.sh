rmmod page_migrate.ko
dmesg -C
dmesg -D
make -j8
dmesg -E
insmod page_migrate.ko $*
dmesg -D
#make clean
#dmesg -E
#rmmod ioat_map
