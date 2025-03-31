#!/bin/bash

if [ $# -ne 4 ]; then 
    echo "usage: $0 NUM_ENTRY NUM_TRACE ADDR_RANGE CNT_RANGE" 
    exit 1
fi

while true; do
    read -p "NUM_ENTRY = $1, NUM_TRACE = $2, address range = $3, count range = $4 is right? [y/n] : " yn ;
    case $yn in
        [Yy]* ) 
            break;;
        [Nn]* ) 
            exit 1;;
        * ) 
            echo "please press y or n.";;
    esac
done

rm compare.txt answer.txt result.txt addr_trace.txt cnt_tract.txt;
python3 rtrace_generator.py $2 $3 $4;
cd ../ ; 
xrun -f xrun_arg -define WAVE -define SIM -define XILINX +define+NUM_ENTRY=$1;
cd verify ;
python3 cam_tb_random.py $1 $2;
python3 compare.py;
python3 test.py;
