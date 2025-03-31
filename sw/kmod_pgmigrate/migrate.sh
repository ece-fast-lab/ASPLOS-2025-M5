sudo dmesg -c
sudo sh -c "echo ${1} > /proc/cxl_migrate_pfn"
#sleep 0.5
sudo dmesg -c
