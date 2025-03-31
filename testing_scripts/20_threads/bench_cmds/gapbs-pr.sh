#!/bin/bash

GRAPH_DIR=$GAPBS_PATH/benchmark/graphs

BENCH_RUN="${GAPBS_PATH}/pr -f ${GRAPH_DIR}/twitter_reduced_6G.sg -i1000 -t1e-4 -n20"

export BENCH_RUN
export BENCH_DRAM
