INSTANCE=1
THREADS=10
#TARGET=500000
TARGET=40000
REDIS_PORT_START=15000

#RESULT_PATH="${YCSB_PATH}/redis_eac/${NODE_CONFIG}"
CGROUP_PATH=/sys/fs/cgroup/app

sudo cgconfigparser -l /etc/cgconfig.conf

# arg0: mem_node
# arg1: mem_size
set_cgroup_cfg() {
	echo "Setting cgroup to node:$1, size:$2"
	sudo sh -c "echo 0 > ${CGROUP_PATH}/cpuset.cpus"
	sudo sh -c "echo $1 > ${CGROUP_PATH}/cpuset.mems"
	sudo sh -c "echo max > ${CGROUP_PATH}/memory.high"
	sudo sh -c "echo $2 > ${CGROUP_PATH}/memory.max"
	cat ${CGROUP_PATH}/cpuset.cpus
	cat ${CGROUP_PATH}/cpuset.mems
	cat ${CGROUP_PATH}/cpuset.mems.effective
	cat ${CGROUP_PATH}/memory.high
	cat ${CGROUP_PATH}/memory.max
}

# arg1: memory node
start_redis() {
	echo 'start redis'
	for ((i = 0; i < $INSTANCE; i++)); do
		port=$(($i + $REDIS_PORT_START))
		echo "starting redis at port ${port}"
		#sudo numactl --interleave=${SNC_LOCAL_NODE},${CXL_MEM_NODE} redis-server --daemonize yes --port $port
		sudo numactl --membind=1 redis-server --daemonize yes --port $port
		sleep 1
	done
	sleep 10
}

# arg1: memory node
start_redis_mem_pref() {
	echo 'start redis mem pref'
	for ((i = 0; i < $INSTANCE; i++)); do
		port=$(($i + $REDIS_PORT_START))
		echo "starting redis at port ${port}"
		#sudo numactl --interleave=${SNC_LOCAL_NODE},${CXL_MEM_NODE} redis-server --daemonize yes --port $port
		sudo numactl --preferred=1 redis-server --daemonize yes --port $port
		sleep 1
	done
	sleep 10
}

# arg1: memory node
start_redis_mem_itlv() {
	echo 'start redis mem pref'
	for ((i = 0; i < $INSTANCE; i++)); do
		port=$(($i + $REDIS_PORT_START))
		echo "starting redis at port ${port}"
		sudo numactl --interleave=0,2 -C 12 redis-server --daemonize yes --port $port
		sleep 1
	done
	sleep 10
}

start_redis_cgroup() {
	echo 'start redis with cgroup'
	for ((i = 0; i < $INSTANCE; i++)); do
		port=$(($i + $REDIS_PORT_START))
		echo "starting redis at port ${port}"
		sudo cgexec -g cpuset,memory:app redis-server --daemonize yes --port $port
		sleep 1
	done
	sleep 10
}

kill_redis() {
	echo 'kill redis'
	sudo pkill -f redis-server
	sleep 5
}

# arg1: workload
load_redis() {
	echo "run load"
	cd ${YCSB_PATH}
	mkdir -p $RESULT_PATH
	WORKLOAD=$1

	for ((j = 0; j < $INSTANCE; j++)); do
		port=$(($REDIS_PORT_START + $j))
		echo "loading redis at port ${port}"
		echo "$RESULT_PATH"
		taskset -c 32-43 ./bin/ycsb.sh load redis -s -P workloads/workload$WORKLOAD -p "redis.host=127.0.0.1" -p "redis.port=${port}" \
			-threads $THREADS >$RESULT_PATH/workload${WORKLOAD}_qps${TARGET}_Load_${j}.log &
		sleep 2
	done
	YCSB_JOBS=$(jobs -p)
	for job in $YCSB_JOBS; do
		echo $job
		wait $job || let "FAIL+=1"
		sleep 1
	done
	sleep 10
}

# arg1: workload
query_redis() {
	echo "run run"
	cd ${YCSB_PATH}
	WORKLOAD=$1

	for ((j = 0; j < $INSTANCE; j++)); do
		port=$(($REDIS_PORT_START + $j))
		echo "running redis at port ${port}"
		echo "$RESULT_PATH"
		mkdir -p $RESULT_PATH
		# run
		taskset -c 32-43 ./bin/ycsb.sh run redis -s -P workloads/workload$WORKLOAD \
			-p "redis.host=127.0.0.1" -p "redis.port=${port}" \
			-threads $THREADS -target $TARGET >$RESULT_PATH/workload${WORKLOAD}_qps${TARGET}_Run_${j}.log &
		#sleep 2
		echo "[DEBUG] Redis pid is $!"
	done
	# YCSB_JOBS=`jobs -p`
	YCSB_JOBS=$(pgrep -f "ycsb")

	for job in $YCSB_JOBS; do
		echo $job
		wait $job || let "FAIL+=1"
		sleep 1
	done
	sudo numastat -c redis-server >>$RESULT_PATH/workload${WORKLOAD}_qps${TARGET}_Run_0.log
	sleep 5
}

query_redis_port() {
	echo "run run"
	cd ${YCSB_PATH}
	WORKLOAD=$1

	port=$2
	echo "running redis at port ${port}"
	echo "$RESULT_PATH"
	mkdir -p $RESULT_PATH
	# run
	taskset -c 32-43 ./bin/ycsb.sh run redis -s -P workloads/workload$WORKLOAD \
		-p "redis.host=127.0.0.1" -p "redis.port=${port}" \
		-threads $THREADS -target $TARGET >$RESULT_PATH/workload${WORKLOAD}_qps${TARGET}_Run_${port}.log &
	#sleep 2
	echo "[DEBUG] Redis pid is $!"

	# YCSB_JOBS=`jobs -p`
	YCSB_JOBS=$(pgrep -f "ycsb")

	for job in $YCSB_JOBS; do
		echo $job
		wait $job || let "FAIL+=1"
		sleep 1
	done
	sudo numastat -c redis-server >>$RESULT_PATH/workload${WORKLOAD}_qps${TARGET}_Run_0.log
	sleep 5
}
