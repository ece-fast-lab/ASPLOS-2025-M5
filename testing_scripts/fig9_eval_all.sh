#!/bin/bash

set -x
source ../setup/env.sh

PWD=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)

ITERATION=5
spec_benchs=("507.cactuBSSN_r" "505.mcf_r" "554.roms_r" "549.fotonik3d_r")
gapbs_benchs=("cc" "bc" "sssp" "bfs" "tc" "pr")

run_all_20t() {
	cd 20_threads
	mkdir -p cr_results/$1

	for bench in "${gapbs_benchs[@]}"; do
		bash ./run_gapbs_${bench}.sh $1 >cr_results/${1}/${bench}_${2}.txt
		sleep 10
	done

	bash ./run_liblinear.sh $1 >cr_results/${1}/liblinear_${2}.txt
	#cd $PWD
	cd ..
}

# arg1: TEST_M5
# arg2: mem_cfg denote
run_all_8t() {
	cd 8_threads
	for bench in "${spec_benchs[@]}"; do
		sudo pkill -f run_base
		bash ./run_spec_cgrp.sh 8 $bench "${1}_${2}" "${1}"
		bash ${PATH_TO_RESULT}/clear_log.sh
		sleep 10
	done

	sudo pkill -f run_base
	#cd $PWD
	cd ..
}

run_all_1t() {
	cd 1_thread
	bash ./run_redis.sh rsu $1 $2
	#cd $PWD
	sleep 10
	cd ..
}

sudo sh -c "echo 0 > /proc/sys/kernel/numa_balancing"
for ((i = 0; i < $ITERATION; i++)); do
	if [[ ${1} == "anb" ]]; then
		sudo sh -c "echo 1 > /proc/sys/kernel/numa_balancing"
		run_all_20t "n" "${i}"
		run_all_8t "n" "${i}"
		run_all_1t "n" "${i}"

	elif [[ ${1} == "static" ]]; then
		run_all_20t "static" "${i}"
		run_all_8t "static" "${i}"
		run_all_1t "static" "${i}"

	elif [[ ${1} == "damon" ]]; then
		run_all_20t "d" "${i}"
		run_all_8t "d" "${i}"
		run_all_1t "d" "${i}"

	elif [[ ${1} == "hpt" ]]; then
		run_all_20t "y" "${i}"
		run_all_8t "y" "${i}"
		run_all_1t "y" "${i}"

	elif [[ ${1} == "hwt" ]]; then
		run_all_20t "w" "${i}"
		run_all_8t "w" "${i}"
		run_all_1t "w" "${i}"

	elif [[ ${1} == "hpwt" ]]; then
		run_all_20t "pw" "${i}"
		run_all_8t "pw" "${i}"
		run_all_1t "pw" "${i}"

	else
		echo "unk ${1}"
	fi
done
