#!/bin/bash

set -x
instance=$1
bench=$2
mem_cfg=$3
TEST_M5=$4
core_cnt=0

PWD=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)

source $PWD/../../setup/env.sh
M5_BIN="$M5_PATH/m5_manager"
PAC_BIN="$PAC_PATH/m5_manager"
M5_CORE=0

echo $mem_cfg
mem_cfg_underscore=${mem_cfg// /_}
RESULT_PATH="./${bench}_${mem_cfg_underscore}_${instance}"
mkdir -p $RESULT_PATH
CGROUP_PATH=/sys/fs/cgroup/app

sudo cgconfigparser -l /etc/cgconfig.conf

MAX_CORE_CNT=$((core_cnt + instance - 1))
CORE_BASE_CNT=$core_cnt
PERF_LOG_DIR=$PATH_TO_RESULT/perf/${bench}
PERF_LOG_TEMP_DIR=$PATH_TO_RESULT/perf
mkdir -p $PERF_LOG_DIR
echo "$PERF_LOG_DIR"

# arg0: mem_node
# arg1: mem_size
set_cgroup_cfg() {
	echo "Setting cgroup to node:$1, size:$2"
	sudo sh -c "echo $CORE_BASE_CNT-$MAX_CORE_CNT > ${CGROUP_PATH}/cpuset.cpus"
	sudo sh -c "echo $1 > ${CGROUP_PATH}/cpuset.mems"
	sudo sh -c "echo max > ${CGROUP_PATH}/memory.high"
	sudo sh -c "echo $2 > ${CGROUP_PATH}/memory.max"
	cat ${CGROUP_PATH}/cpuset.cpus
	cat ${CGROUP_PATH}/cpuset.mems
	cat ${CGROUP_PATH}/cpuset.mems.effective
	cat ${CGROUP_PATH}/memory.high
	cat ${CGROUP_PATH}/memory.max
}

set_cgroup_cfg 2 "100G"
sudo bash $SCRIPT_DIR/core_pqos/set_8t_llc.sh

sudo cat /proc/vmstat >vmstat_begin.txt
cgexec -g cpuset,memory:app runcpu \
	--iterations 1 \
	--size ref \
	--tune=base \
	--action onlyrun \
	--config myprogram-gcc-linux-x86.cfg \
	--copies=$instance \
	--noreportable ${bench} >${RESULT_PATH}/result_${bench}.txt &
PID_TO_CHECK=$!

echo "wait for 180 sec, next = enable promotion"
sleep 180
if [[ "${TEST_M5}" == "y" ]]; then
	set_cgroup_cfg "0,2" "100G"
	sudo numactl -C $M5_CORE --membind=0 $M5_BIN -t 1 -s 10 -l 5 -f 0.0001 >/dev/null &
elif [[ "${TEST_M5}" == "w" ]]; then
	set_cgroup_cfg "0,2" "100G"
	sudo numactl -C $M5_CORE --membind=0 $M5_BIN -s 100 -f 0.00005 -x 3.5 -w -c 2 -r >/dev/null &
elif [[ "${TEST_M5}" == "pw" ]]; then
	set_cgroup_cfg "0,2" "100G"
	sudo numactl -C $M5_CORE --membind=0 $M5_BIN -s 100 -f 0.00001 -x 3 -c 2 -l 4 >/dev/null &
elif [[ "${TEST_M5}" == "s" ]]; then
	set_cgroup_cfg "$MAIN_MEM_NODE,2" "100G"
	sudo numactl -C $M5_CORE --membind=0 $M5_BIN -s 25 -A -R 5000 &
elif [[ "${TEST_M5}" == "d" ]]; then
	set_cgroup_cfg "0,2" "100G"
	cd /storage/damon/damo_latest/
	sudo ./damo start p2_0_d0_2.json
	cd -
elif [[ ${TEST_M5} == "pac_m5_ofw" ]]; then
	sudo numactl -C 20 --membind=0 $PAC_BIN -s 10 -l 5 -f 0.02 -n -d "${PATH_TO_RESULT}/pac_${bench}_${TEST_M5}" &

elif [[ ${TEST_M5} == "pac_other_ofw" ]]; then
	sudo numactl -C 20 --membind=0 $PAC_BIN -s 10 -l 5 -f 0.02 -d "${PATH_TO_RESULT}/pac_${bench}_${TEST_M5}" &

elif [[ ${TEST_M5} == "static" ]]; then
	echo "do nothing"
else
	set_cgroup_cfg "0,2" "100G"
fi

sudo cat /proc/vmstat >vmstat_end.txt

if [[ ${TEST_M5} == "pac_m5_ofw" || ${TEST_M5} == "pac_other_ofw" ]]; then
	DURATION=8000
	INTERVAL=1
	elapsed_time=0

	while [ $elapsed_time -lt $DURATION ]; do
		if ps -p $PID_TO_CHECK >/dev/null 2>&1; then
			echo "PID $PID_TO_CHECK is alive"
		else
			echo "PID $PID_TO_CHECK is not alive"
			break
		fi

		# Sleep for the interval duration
		sleep $INTERVAL

		# Increment the elapsed time
		elapsed_time=$((elapsed_time + INTERVAL))
	done
	sudo pkill -f run_base
	sudo pkill -f m5_manager
	sudo pkill -f pcm
	echo "wait for 10 sec, finished, cooling down"
	sleep 10
else
	SPEC_JOBS=$(pgrep -f "$bench")
	t=0
	for job in $SPEC_JOBS; do
		echo $job
		wait $job || let "FAIL+=1"
		echo "waiting for $t second"
		sleep 0.2
		((t++))
	done

	echo "wait for 10 sec, finished, cooling down"
	sleep 10
fi
