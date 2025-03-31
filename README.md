# M5: Mastering Page Migration and Memory Management for CXL-based Tiered Memory Systems
## Overview 
* List of experiments to reproduce:
  * Performance comparison with ANB (Figure 9)
  * Agilex7-based average access-count ratios of HPT (Figure 8)
  * Distribution of access counts per 4KB page. (Figure 10) 

* Abbreviation
    * ANB -- AutoNUMA balancing
    * CXL -- Compute eXpress Link
    * SPR3 -- Testing machine

* Results
    * The results are divided into 20t (GAPBs and Liblinear), and 8t (SPEC2017), and 1t Redis.

## Testbed Specification

### Hardware
| Hardware | Description |
| -------- | ----------- |
| CPU | 2x Intel Xeon 6430 CPU |
| DRAM | DDR5 4800 MT/s, 4 on each socket|
| FPGA | Intel Agilex 7 I-series FPGA, rev. R1BES |


## Installation
### Hardware
Please refer to the [hardware readme](./hw/README.md) for setting up the FPGA.

## Kernels
* M5 -- Linux kernel v6.5
* ANB -- Linux kernel v5.19
* DAMON -- Linux kernel v6.11

Please refer to the [kernel readme](./kernels/README.md) for setting up the Linux kernels.

### Software
Please refer to the [software readme](./software/README.md) for setting up the software.

### Experiments
Please refer to the [experiments readme](./testing_scripts//README.md) for running the experiments.

# [Publication]()
```
@inproceedings{asplos25-m5,
    author = {Sun, Yan and Kim, Jongyul and Yu, Zeduo and Zhang, Jiyuan and Chai, Siyuan and Kim, Michael Jaemin and Nam, Hwayong and Park, Jaehyun and Na, Eojin and Yuan, Yifan and Wang, Ren and Ahn, Jung Ho and Xu, Tianyin and Kim, Nam Sung},
    title = {M5: Mastering Page Migration and Memory Management for CXL-based Tiered Memory Systems},
    year = {2025},
    booktitle = {Proceedings of the 30th ACM International Conference on Architectural Support for Programming Languages and Operating Systems, Volume 2},
}
```
