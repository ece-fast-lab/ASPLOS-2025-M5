set -x
source env.sh
sudo sh -c "echo 0 > /sys/kernel/mm/numa/demotion_enabled"
cd $SCRIPT_DIR/..//oom_hack
sudo numactl --membind=0 ./a.out
cd $SCRIPT_DIR
bash enable_demote.sh
cd $SCRIPT_DIR/../sw/kmod_pgmigrate/
sudo bash compile_install.sh
cd $SCRIPT_DIR/../sw/kmod_pac_ofw_buf/
sudo bash compile_install.sh

cd $SCRIPT_DIR/../sw/pcimem
bash set_all_init.sh
sudo swapon -a
sudo cpupower --cpu all frequency-set --freq 2100MHz
sudo $CPU_POWER_PATH --cpu all frequency-set --freq 2100MHz
sudo cpupower --cpu all frequency-info | grep "current"

sudo wrmsr -a 0x620 0x1919
