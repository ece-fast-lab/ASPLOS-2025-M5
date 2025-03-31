#!/bin/bash

GRAPH_DIR=$GAPBS_PATH/benchmark/graphs

BENCH_RUN="${GAPBS_PATH}/bc -f ${GRAPH_DIR}/gplus/gplus/imc12/direct_social_structure.wel -n100"

export BENCH_RUN
export BENCH_DRAM
