#!/bin/bash

set -x
source ../setup/env.sh

spec_benchs=("507.cactuBSSN_r" "505.mcf_r" "549.fotonik3d_r" "554.roms_r")
gapbs_benchs=("bc" "cc" "sssp" "bfs" "tc" "pr")
PWD=$(pwd)

run_all_20t() {
	cd 20_threads
	mkdir -p ${PATH_TO_RESULT}/pac_out/$1

	for bench in "${gapbs_benchs[@]}"; do
		bash ./run_gapbs_${bench}.sh "${1}" >${PATH_TO_RESULT}/pac_out/${1}/${bench}_${2}.txt
		bash ${PATH_TO_RESULT}/clear_log.sh
	done

	bash ./run_liblinear.sh $1 >${PATH_TO_RESULT}/pac_out/${1}/liblinear_${2}.txt
	bash ${PATH_TO_RESULT}/clear_log.sh
	cd ..
}

# arg1: TEST_M5
# arg2: mem_cfg denote
run_all_8t() {
	cd 8_threads
	for bench in "${spec_benchs[@]}"; do
		bash ./run_spec_cgrp.sh 8 $bench "${1}_${2}" "${1}"
		bash ${PATH_TO_RESULT}/clear_log.sh
	done
	cd ..
}
run_all_1t() {
	cd 1_thread
	bash run_redis.sh rsu $1
	bash ${PATH_TO_RESULT}/clear_log.sh
	cd ..
}

# arg1: iter
run_m5() {
	run_all_20t "pac_m5" "${1}"
	run_all_8t "pac_m5" "${1}"
	run_all_1t "pac_m5"
}

run_m5_sampling() {
	run_all_20t "pac_m5_sampling" "${1}"
	run_all_8t "pac_m5_sampling" "${1}"
	run_all_1t "pac_m5_sampling" "${1}"
}

run_other() {
	run_all_20t "pac_other" "${1}"
	run_all_8t "pac_other" "${1}"
	run_all_1t "pac_other"
}

run_damon() {
	cd $DAMO_PATH
	sudo ./damo start p2_0_d0_2.json
	cd -
	run_other $1

	cd $DAMO_PATH
	sudo ./damo stop
	cd -

}

# disable ANB by default
sudo sh -c "echo 0 > /proc/sys/kernel/numa_balancing"
if [[ ${1} == "pac-m5-ofw" ]]; then
	run_all_20t "pac_m5_ofw" "${i}"
	run_all_8t "pac_m5_ofw" "${i}"
	run_all_1t "pac_m5_ofw" "${i}"
elif [[ ${1} == "pac-damon-ofw" ]]; then
	# 6.11 kernel, disable migration, log migration
	cd $DAMO_PATH
	cd -
	run_all_20t "pac_damon_ofw" "${i}"
	run_all_8t "pac_damon_ofw" "${i}"
	run_all_1t "pac_damon_ofw" "${i}"
	cd $DAMO_PATH
	sudo ./damo stop
elif [[ ${1} == "pac-anb-ofw" ]]; then
	# 5.19 kernel, disable migration, log migraiton
	sudo sh -c "echo 1 > /proc/sys/kernel/numa_balancing"
	run_all_20t "pac_anb_ofw" "${i}"
	run_all_8t "pac_anb_ofw" "${i}"
	run_all_1t "pac_anb_ofw" "${i}"
else
	echo "Invalid argument"
fi
