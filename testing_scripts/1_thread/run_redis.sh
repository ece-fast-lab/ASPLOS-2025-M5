#!/bin/bash
# arg1: workload
# arg2: config
REDIS_SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)

set -e
source ../../setup/env.sh || true
source ./func_redis_ycsb.sh
M5_BIN="$M5_PATH/m5_manager"
PAC_BIN="$PAC_PATH/m5_manager"
M5_LAT_OPT_BIN="$M5_LAT_OPT_PATH/m5_manager"
M5_CORE=0

sudo bash $SCRIPT_DIR/core_pqos/set_1t_llc.sh || true

if [ -n $1 ]; then
	WORKLOAD=$1
else
	WORKLOAD=rssu
fi

if [ -n $2 ]; then
	config=$2
else
	config=$time_tag
fi

if [ -n $3 ]; then
	iter=$3
else
	iter=0
fi

echo "testing with $config"

sleep_kill() {
	echo "sleeping, wait for $1"
	sleep $1
	echo "kill m5"
	sudo pkill -f m5_manager
}

CONFIG_STR="${config}_${iter}_${WORKLOAD}"
RESULT_PATH="$PATH_TO_RESULT/redis/$CONFIG_STR"
mkdir -p $RESULT_PATH
sudo chown -R yans3 $RESULT_PATH
LOG_DIR=$PATH_TO_RESULT/redis/
mkdir -p $LOG_DIR

kill_redis

start_redis_cgroup

# set mem to node 2
set_cgroup_cfg "2" 100G

load_redis $WORKLOAD

if [[ "${config}" == "y" ]]; then
	# ===============================
	#           HPT only
	# ===============================
	set_cgroup_cfg "0,2" 100G
	sudo numactl -C $M5_CORE --membind=0 $M5_LAT_OPT_BIN -s 500 -l 5 -P -f 1 -x 2 -r &

elif [[ "${config}" == "w" ]]; then
	# ===============================
	#           HWT only
	# ===============================
	set_cgroup_cfg "0,2" 100G
	sudo numactl -C $M5_CORE --membind=0 $M5_LAT_OPT_BIN -s 500 -l 5 -P -f 1 -x 2 -r &

elif [[ "${config}" == "pw" ]]; then
	# ===============================
	#           HPT + HWT
	# ===============================
	set_cgroup_cfg "0,2" 100G
	sudo numactl -C $M5_CORE --membind=0 $M5_LAT_OPT_BIN -s 500 -l 5 -P -f 1 -x 2 -r &

elif [[ ${config} == "d" ]]; then
	cd /storage/damon/damo_latest/
	sudo ./damo start p2_0_d0_2.json
	cd -

elif [[ ${config} == "pac_m5_ofw" ]]; then
	sudo numactl -C 20 --membind=0 $PAC_BIN -s 10 -l 5 -f 0.02 -n -d "${PATH_TO_RESULT}/pac_${1}_${config}" -n &

elif [[ ${config} == "pac_anb_ofw" ]]; then
	sudo numactl -C 20 --membind=0 $PAC_BIN -s 10 -l 5 -f 0.02 -d "${PATH_TO_RESULT}/pac_${1}_${config}" &

elif [[ ${config} == "pac_damon_ofw" ]]; then
	sudo numactl -C 20 --membind=0 $PAC_BIN -s 10 -l 5 -f 0.02 -d "${PATH_TO_RESULT}/pac_${1}_${config}" &

elif [[ ${config} == "static" ]]; then
	echo "do nothing"
else
	set_cgroup_cfg "0,2" 100G
fi

sleep 5

query_redis $WORKLOAD
sudo pkill -f m5_manager
sudo pkill -f pcm-memory
sudo pkill -f redis-server

if [[ "${TEST_M5}" == "d" ]]; then
	cd $DAMO_PATH
	sudo ./damo stop
	cd -
fi
