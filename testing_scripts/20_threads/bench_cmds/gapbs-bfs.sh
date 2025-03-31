#!/bin/bash

GRAPH_DIR=$GAPBS_PATH/benchmark/graphs

BENCH_RUN="${GAPBS_PATH}/bfs -f ${GRAPH_DIR}/twitter_reduced_6G.sg -n200"

export BENCH_RUN
export BENCH_DRAM
