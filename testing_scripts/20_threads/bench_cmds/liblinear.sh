#!/bin/bash

BENCH_RUN="${LIBLINEAR_PATH}/train -s 6 -m 20 ${LIBLINEAR_PATH}/datasets/kdd12-1-1-1"

export BENCH_RUN
export BENCH_DRAM
