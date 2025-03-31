# Total ways = 15, 0x7FFF
# Core / socket = 32

set -x
CURR_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
python3 $CURR_DIR/cpu-offlining.py -s 8 -e 31
python3 $CURR_DIR/cpu-offlining.py -s 32 -e 63
python3 $CURR_DIR/cpu-onlining.py -s 0 -e 7
#python3 $CURR_DIR/cpu-onlining.py -s 20 -e 20

sudo pqos -R
sudo pqos -e "llc@0:1=0x7800"
sudo pqos -a "llc:1=0-7"

sudo pqos -e "llc@0:2=0x07FF"
sudo pqos -a "llc:2=20"

CPU_POWER_PATH="cpupower"
sudo $CPU_POWER_PATH --cpu all frequency-set --freq 2100MHz
sudo $CPU_POWER_PATH --cpu all frequency-info | grep "current CPU frequency"
