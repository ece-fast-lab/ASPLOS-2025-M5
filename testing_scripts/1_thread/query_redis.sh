#!/bin/bash
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

set -e
source ../func_init.sh
cd $SCRIPT_DIR
source ../func_buf_reader.sh
cd $SCRIPT_DIR
source ../func_redis_ycsb.sh
cd $SCRIPT_DIR

source ../env.sh || true

echo "testing with $config"

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

RESULT_PATH="/home/yans3/gitdoc/cxlmem_test_software/results/redis_performance/$config/"

# set mem to node 2
set_cgroup_cfg "0,2" 100G
#set_cgroup_cfg "2" 100G

query_redis $WORKLOAD
