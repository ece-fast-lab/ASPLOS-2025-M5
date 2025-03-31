set -x

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)

# PATHS
M5_PATH="$SCRIPT_DIR/../sw/m5_manager_uspace/build"
M5_LAT_OPT_PATH="$SCRIPT_DIR/../sw/m5_lat_opt_uspace/build"
PAC_PATH="$SCRIPT_DIR/../sw/pac_ofw_uspace/build"
DAMO_PATH="$SCRIPT_DIR/../sw/damo/"
PATH_TO_KMOD=""
PATH_TO_PCIMEM=""
PATH_TO_RESULT="$SCRIPT_DIR/../results/"

YCSB_PATH="/storage/yans3/AE_root/ycsb_redis"
SPEC_PATH="/storage/yans3/AE_root/spec/spec2017"
GAPBS_PATH="/storage/memtis/memtis/memtis-userspace/bench_dir/gapbs/"
LIBLINEAR_PATH="/storage/memtis/memtis/memtis-userspace/bench_dir/liblinear-multicore-2.47/"

#CPU_POWER_PATH="/home/yans3/linux_tpp/tools/power/cpupower/cpupower"
CPU_POWER_PATH="cpupower"

# Setting  things
sudo $SCRIPT_DIR/turbo-boost.sh disable
sudo $CPU_POWER_PATH --cpu all frequency-set --freq 2100MHz
sudo $CPU_POWER_PATH --cpu all frequency-info | grep "current CPU frequency"

# lock uncore
sudo wrmsr -a 0x620 0x1919

# drop file cache
sudo sh -c "echo 3 > /proc/sys/vm/drop_caches"

time_tag=$(date '+%d-%m-%Y-%H-%M-%S')
