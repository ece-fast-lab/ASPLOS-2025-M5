#!/bin/bash

GRAPH_DIR=$GAPBS_PATH/benchmark/graphs

BENCH_RUN="${GAPBS_PATH}/tc -f ${GRAPH_DIR}/twitter_reduced_690M_u.sg -n1"

export BENCH_RUN
export BENCH_DRAM
