#!/bin/bash
#set -xve
set -x

BENCH=$1
MAIN_MEM_NODE=$2
SLEEP_TIME=$3
M5_CORE=0
TEST_M5=$4
sudo dmesg -c

source ../../setup/env.sh

M5_BIN="$M5_PATH/m5_manager"
PAC_BIN="$PAC_PATH/m5_manager"
PWD=$(pwd)
CGROUP_PATH=/sys/fs/cgroup/app
sudo cgconfigparser -l /etc/cgconfig.conf

# arg0: mem_node
# arg1: mem_size
set_cgroup_cfg() {
	echo "Setting cgroup to node:$1, size:$2"
	sudo sh -c "echo '0-19' > ${CGROUP_PATH}/cpuset.cpus"
	sudo sh -c "echo $1 > ${CGROUP_PATH}/cpuset.mems"
	sudo sh -c "echo max > ${CGROUP_PATH}/memory.high"
	sudo sh -c "echo $2 > ${CGROUP_PATH}/memory.max"
	cat ${CGROUP_PATH}/cpuset.cpus
	cat ${CGROUP_PATH}/cpuset.mems
	cat ${CGROUP_PATH}/cpuset.mems.effective
	cat ${CGROUP_PATH}/memory.high
	cat ${CGROUP_PATH}/memory.max
}

countdown() {
	secs=$1
	while [ $secs -gt 0 ]; do
		echo -ne "Countdown: $secs seconds"
		sleep 1
		: $((secs--))
	done
	echo "Countdown complete!"
}

sleep_and_migrate() {
	echo "sleeping ${SLEEP_TIME}, waiting for load"
	sleep $SLEEP_TIME
	echo "re-enable migration"
	if [[ "${TEST_M5}" == "y" ]]; then
		# ===============================
		#           HPT only
		# ===============================
		set_cgroup_cfg "$MAIN_MEM_NODE,2" "18000M"
		if [[ "${1}" == "gapbs-pr" ]]; then
			sudo numactl -C $M5_CORE --membind=0 $M5_BIN -s 1 -l 5 -f 0.001 >/dev/null &
		elif [[ "${1}" == "gapbs-tc" ]]; then
			sudo numactl -C $M5_CORE --membind=0 $M5_BIN -s 25 -l 5 -f 0.0005 -x 1.5 >/dev/null &
		elif [[ "${1}" == "gapbs-bc" ]]; then
			sudo numactl -C $M5_CORE --membind=0 $M5_BIN -s 20 -l 5 -f 0.001 -x 1 >/dev/null &
		elif [[ "${1}" == "liblinear" ]]; then
			sudo numactl -C $M5_CORE --membind=0 $M5_BIN -s 1 -f 0.00005 -x 1 &
		else
			sudo numactl -C $M5_CORE --membind=0 $M5_BIN -s 1 -l 5 -f 0.001 >/dev/null &
		fi

	elif [[ "${TEST_M5}" == "w" ]]; then
		# ===============================
		#           HWT only
		# ===============================
		set_cgroup_cfg "$MAIN_MEM_NODE,2" "18000M"
		if [[ "${1}" == "liblinear" ]]; then
			sudo numactl -C $M5_CORE --membind=0 $M5_BIN -s 10 -f 0.001 -x 1 -w -c 2 -l 0 &
		elif [[ "${1}" == "gapbs-tc" ]]; then
			sudo numactl -C $M5_CORE --membind=0 $M5_BIN -s 10 -f 0.0005 -x 3 -w -c 2 -l 0 >/dev/null &
		else
			sudo numactl -C $M5_CORE --membind=0 $M5_BIN -s 1 -f 0.01 -x 6 -w -c 2 -l 0 &
		fi

	elif [[ "${TEST_M5}" == "pw" ]]; then
		# ===============================
		#           HPT + HWT
		# ===============================
		set_cgroup_cfg "$MAIN_MEM_NODE,2" "18000M"
		if [[ "${1}" == "liblinear" ]]; then
			sudo numactl -C $M5_CORE --membind=0 $M5_BIN -s 25 -f 0.0001 -x 1 -c 2 -l 0 &
		elif [[ "${1}" == "gapbs-tc" ]]; then
			sudo numactl -C $M5_CORE --membind=0 $M5_BIN -s 25 -f 0.0005 -x 2 -c 2 >/dev/null &
		else
			sudo numactl -C $M5_CORE --membind=0 $M5_BIN -s 25 -f 0.01 -x 5.4 -c 2 &
		fi

	elif [[ "${TEST_M5}" == "d" ]]; then
		# ===============================
		#           damon hmdk
		# ===============================
		set_cgroup_cfg "$MAIN_MEM_NODE,2" "18000M"
		cd $DAMO_PATH
		sudo ./damo start p2_0_d0_2.json
		cd -

	elif [[ ${TEST_M5} == "pac_m5_ofw" ]]; then
		sudo numactl -C 20 --membind=0 $PAC_BIN -s 10 -l 5 -f 0.02 -d "${PATH_TO_RESULT}/pac_${1}_${TEST_M5}" -n &

	elif [[ ${TEST_M5} == "pac_anb_ofw" ]]; then
		sudo numactl -C 20 --membind=0 $PAC_BIN -s 10 -l 5 -f 0.1 -d "${PATH_TO_RESULT}/pac_${1}_${TEST_M5}" &

	elif [[ ${TEST_M5} == "pac_damon_ofw" ]]; then
		sudo numactl -C 20 --membind=0 $PAC_BIN -s 10 -l 5 -f 0.1 -d "${PATH_TO_RESULT}/pac_${1}_${TEST_M5}" &

	elif [[ ${TEST_M5} == "static" ]]; then
		echo "do nothing"
	else
		set_cgroup_cfg "$MAIN_MEM_NODE,2" "18000M"
		# default to have NUMA balancing on
	fi
}

sudo bash $SCRIPT_DIR/core_pqos/set_20t_llc.sh

if [[ -e ./bench_cmds/${BENCH}.sh ]]; then
	source ./bench_cmds/${BENCH}.sh
else
	echo "ERROR: ${BENCH}.sh does not exist."
	continue
fi

LOG_DIR=$PATH_TO_RESULT/${BENCH}/${TEST_M5}
mkdir -p $LOG_DIR

# drop file cache
free
sync
sudo sh -c "/usr/bin/echo 3 > /proc/sys/vm/drop_caches"
free

# lock memory to node2
set_cgroup_cfg "2" "18000M"

# then gradually migrate to node 0
sleep_and_migrate $BENCH $LOG_DIR &

# run!
/usr/bin/time -f "execution time %e (s)" \
	sudo cgexec -g cpuset,memory:app ${BENCH_RUN} 2>&1 |
	tee ${LOG_DIR}/output.log

# post-work
if [[ "${TEST_M5}" == "y" ]]; then
	sudo pkill -f m5_manager
elif [[ "${TEST_M5}" == "d" ]]; then
	cd $DAMO_PATH
	sudo ./damo stop
	cd -
elif [[ "${TEST_M5}" == "nd" ]]; then
	cd $DAMO_PATH
	sudo ./damo stop
	cd -
elif [[ ${TEST_M5} == "pac_m5_ofw" ]]; then
	sudo pkill -f m5_manager
elif [[ ${TEST_M5} == "pac_other_ofw" ]]; then
	sudo pkill -f m5_manager
elif [[ ${TEST_M5} == "perf-overhead" ]]; then
	# TODO
	# stop perf
	sudo pkill -INT perf
	echo "Stop recording with perf."
elif [[ ${TEST_M5} == "perf-damon" ]]; then
	# TODO
	# stop perf
	sudo pkill -INT perf
	echo "Stop recording with perf."

	# Stop DAMON
	cd $DAMO_PATH
	sudo ./damo stop
	cd -
fi
