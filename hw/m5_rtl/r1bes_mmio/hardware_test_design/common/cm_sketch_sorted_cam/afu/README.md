# Count-Min sketch
This is implementation of Count-Min sketch. When address comes in, it exports a probabilistic estimate of how many times it has been accessed.

## Repository File Structure
todo

## Simulation Guide

$ cd sim/verify

$ ./run.sh [NUM_HASH] [W] [NUM_TRACE] [ADDR_RANGE]


 - NUM_HASH : Number of Hash function (height of sketch structure)
 - W : Width of Sketch
 - NUM_TRACE : Number of Request
 - ADDR_RANGE : Range of input address


The simulation works in the following order.

 (1) Generate a random trace file (rtrace.txt).

 (2) Run the .sv testbench with the Xcelium simulator and log is written in result.txt, and random generated hash values are written in hash.txt.

 (3) cm_sketch_tb_random.py read rtrace.txt, hash.txt and generate answer file (answer.txt)

 (4) Compare result.txt with answer.txt.


## Contact 
- Eojin Na
