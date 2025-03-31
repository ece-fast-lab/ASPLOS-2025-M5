#!/bin/bash

set -x
source ../setup/env.sh
CURR_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)

ITERATION=1
spec_benchs=("507.cactuBSSN_r" "505.mcf_r" "549.fotonik3d_r" "554.roms_r")
#gapbs_benchs=("bc" "cc" "sssp" "bfs" "tc" "pr")
#gapbs_benchs=("pr")
#gapbs_benchs=("bc" "cc" "sssp" "bfs" "tc")
gapbs_benchs=()

# arg1: test name
start_pac() {
	cd $CURR_DIR/pac_tests
	bash ./test_4KB.sh $1 &
	cd -
}

run_all_20t() {
	cd 20_threads
	mkdir -p ${PATH_TO_RESULT}/pac_results/$1

	for bench in "${gapbs_benchs[@]}"; do
		start_pac "${bench}"
		bash ./run_gapbs_${bench}.sh $1 >${PATH_TO_RESULT}/pac_results/${1}/${bench}_${2}.txt
		sudo pkill -f test_4KB
	done

	start_pac "liblinear"
	bash ./run_liblinear.sh $1 >${PATH_TO_RESULT}/pac_results/${1}/liblinear_${2}.txt
	sudo pkill -f test_4KB
	cd ..
}

# arg1: TEST_M5
# arg2: mem_cfg denote
run_all_8t() {
	cd 8_threads
	for bench in "${spec_benchs[@]}"; do
		start_pac "${bench}"
		bash ./run_spec_cgrp.sh 8 $bench "${1}_${2}" "${1}"
		sudo pkill -f test_4KB
	done
	cd ..
}

run_all_1t() {
	cd 1_thread
	bash ./run_redis.sh "rsu" $1
	sudo pkill -f test_4KB
	cd ..
}

for ((i = 0; i < $ITERATION; i++)); do
	#run_all_20t "n" "${i}"
	#run_all_8t "pac_full" "${i}"
	run_all_1t "pac_full" "${i}"
	echo "done"
done
