# Total ways = 15, 0x7FFF
# Core / socket = 32

set -x
python3 cpu-offlining.py -s 4 -e 31
python3 cpu-onlining.py -s 20 -e 20
python3 cpu-onlining.py -s 32 -e 63

sudo pqos -R
sudo pqos -e "llc@0:2=0x1FFE"
sudo pqos -a "llc:2=20"

sudo pqos -e "llc@0:3=0x6000"
sudo pqos -a "llc:3=0-3"

sudo pqos -e "llc@0:1=0x0001"
sudo pqos -a "llc:1=31"

# spec = ? instances?

# Liblinear = 20 cores?
