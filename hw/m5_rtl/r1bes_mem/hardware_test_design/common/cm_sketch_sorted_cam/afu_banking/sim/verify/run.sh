#!/bin/bash

if [ $# -ne 5 ]; then 
    echo "usage: $0 W NUM_HASH NUM_ENTRY NUM_TRACE ADDR_RANGE"  
    exit 1
fi

while true; do
    read -p "W(sketch width) = $1, NUM_HASH = $2, NUM_ENTRY = $3, NUM_TRACE = $4, address range = $5 is right? [y/n] : " yn ;
    case $yn in
        [Yy]* ) 
            break;;
        [Nn]* ) 
            exit 1;;
        * ) 
            echo "please press y or n.";;
    esac
done

rm compare.txt answer.txt result.txt rtrace.txt hash.txt;
python3 rtrace_generator.py $4 $5;
cd ../ ; 
xrun -f xrun_arg -define WAVE -define SIM -define XILINX +define+W=$1 +define+NUM_HASH=$2 +define+NUM_ENTRY=$3 +define+NUM_INPUT=$4;
cd verify ;
python3 tb_afu_top_random.py $1 $2 $3 $4;
python3 compare.py;
python3 test.py;
