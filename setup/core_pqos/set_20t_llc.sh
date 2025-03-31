# Total ways = 15, 0x7FFF
# Core / socket = 32

set -x
CURR_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
python3 $CURR_DIR/cpu-offlining.py -s 20 -e 31
python3 $CURR_DIR/cpu-offlining.py -s 32 -e 63
python3 $CURR_DIR/cpu-onlining.py -s 0 -e 19
#python3 $CURR_DIR/cpu-onlining.py -s 20 -e 20

# set 0-19 to use 20 / 32 * 15 ~= 10 way
sudo pqos -R
sudo pqos -e "llc@0:1=0x7FC0"
sudo pqos -a "llc:1=0-19"

# set 20 to use the rest of LLC
sudo pqos -e "llc@0:2=0x003F"
sudo pqos -a "llc:2=20"

CPU_POWER_PATH="cpupower"
sudo $CPU_POWER_PATH --cpu all frequency-set --freq 2100MHz
sudo $CPU_POWER_PATH --cpu all frequency-info | grep "current CPU frequency"
