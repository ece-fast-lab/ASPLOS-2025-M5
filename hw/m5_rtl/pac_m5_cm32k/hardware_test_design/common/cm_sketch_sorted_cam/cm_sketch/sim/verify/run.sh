#!/bin/bash

if [ $# -ne 4 ]; then 
    echo "usage: $0 NUM_HASH W NUM_TRACE ADDR_RANGE"  
    exit 1
fi

while true; do
    read -p "NUM_HASH = $1, W(sketch width) = $2, NUM_TRACE = $3, address range = $4 is right? [y/n] : " yn ;
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
python3 rtrace_generator.py $3 $4;
cd ../ ; 
xrun -f xrun_arg -define WAVE -define SIM -define XILINX +define+NUM_HASH=$1 +define+W=$2 ;
cd verify ;
python3 cm_sketch_tb_random.py $1 $2 $3;
python3 compare.py;
python3 test.py;
