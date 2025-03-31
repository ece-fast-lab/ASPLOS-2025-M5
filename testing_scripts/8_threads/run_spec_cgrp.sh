#!/bin/bash
#bench="549.fotonik3d_r"
#bench="654.roms_s"
instance=$1
bench=$2
mem_cfg=$3
TEST_M5=$4
CURR_SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
set -x

sudo -s <<EOF
pushd /storage/yans3/AE_root/spec/spec2017 
source shrc
bash $CURR_SCRIPT_DIR/loop_base_cgrp_copies.sh $instance $bench "$mem_cfg" "$TEST_M5"
EOF
sudo pkill -f pcm-memory-daem
