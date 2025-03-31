# Pipelined Max heap

## Repository File Structure

```
.
+-- sim/                                    # Cadence Xcelium simulator

+-- src/                       

+-- header/                       

+-- ip/                       

+-- README.md                               # This file
```

## Simulation Guide

### Prerequisites:
- Red Hat Enterprise Linux release 8.2 (Ootpa)
- Cadence Xcelium Version 19.03
- FPGA boards: Xilinx Alveo U280, Altera AGIB027R29A1E2VR3
- If you want to make IP files:
  - AMD Xilinx Vivado 2020.2 for Alveo U280
  - Intel Quartus Prime for Agilex 7 I-series, AGIB027R29A1E2VR3

### How to simulate:
```
$ cd sim/verify
$ ./run.sh
```
The simulation works in the following order.
> (1) Generate a random trace file (cnt_trace.txt, addr_trace.txt) and a correct result file (answer.txt).
> (2) Run the testbench with the Xcelium simulator and log is written in result.txt.
> (3) Compare result.txt with answer.txt.
  
## Contact 
- Eojin Na
