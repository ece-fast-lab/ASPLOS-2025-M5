#!/bin/bash

GRAPH_DIR=$GAPBS_PATH/benchmark/graphs

BENCH_RUN="${GAPBS_PATH}/sssp -f ${GRAPH_DIR}/gplus/gplus/imc12/direct_social_structure_3-5G.wel -n200"

export BENCH_RUN
export BENCH_DRAM
