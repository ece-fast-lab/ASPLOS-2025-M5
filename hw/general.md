# General design
This document elaborates on how the design is connected, base on the `r1bes_mmio` version of the hardware.

## Hardware design
The tracker is instantiated in `./m5_rtl/r1bes_mmio/hardware_test_design/common/afu/afu_banking_top.sv`

Trackers:
* CM-Sketch tracker
    * `./m5_rtl/r1bes_mmio/hardware_test_design/common/cm_sketch_sorted_cam/afu_banking/`
* Space-saving tracker
    * `./m5_rtl/r1bes_mmio/hardware_test_design/common/page_hotness/`

## Timing and clocking
* The trackers runs in `afu_clk`, which is 400MHz
* The CSRs runs in 125MHz.
* The CDC happens in the `./m5_rtl/r1bes_mmio/hardware_test_design/ed_top_wrapper_typ2.sv`

## Control status registers (CSRs)
The CSR is instantiated here: `./m5_rtl/r1bes_mmio/hardware_test_design/common/ex_default_csr/ex_default_csr_avmm_slave.sv`

The design example provided by Intel supports up to 2MB of CSR space in the PF1 resource2. The CSR described below uses up to 16384 * 8 byte = 128 KB of CSR space. 

All CSR operates in 64bits granularity.

| Index | Read Write | CSR Name Description |
| ----- | ---------- | -------------------- |
| 0 | R | Clock counter, it is incremented every 10,000 cycle in 125MHz |
| 1 | R | CXL.mem read counter |
| 2 | R | CXL.mem write counter |
| 3 | R | Hot page tracker output count |
| 4 | R | Hot cacheline tracker output count |
| 5 | R | {4'h9, page_mig_addr, 4'h4, cache_mig_addr}, debug |
| 6 | R | {pfn_overflow_cnt, 6'h0, pfn_wr_idx, cache_overflow_cnt, 3'h0, cache_wr_idx}, debug | 
| 7 | / | Not used |
| 8 | RW | Page tracker output rate, when the MSB bit 32 is set, the tracker is outputed base on number of read requests. Please see `./m5_rtl/r1bes_mmio/hardware_test_design/common/cm_sketch_sorted_cam/afu_banking/src/query_ctrl.sv` for more information. |
| 9 | RW | Cacheline tracker output rate | 
| 10 | RW | This is the starting PFN of CXL memory. Please see `sudo cat /proc/zoneinfo`, `start_pfn` for the CXL node.| 
| 11 | W | Reset hot page array | 
| 12 / 13 | / | Not used | 
| 14 | RW | The CXL address offset. For a system with 128 GB DDR memory, the CXL actually starts from 130GB. This would make the address offset `0x180000000`, which shifts the FPGA address by 2GB, please see the `h_pfn_addr_cvtr` for more information |
| 15 / 16 | RW | This limits the range of address tracking. For all expriments, please see the reg 15 to 0 and reg 16 to `0xFFFFFFFFFFFFF`. Please see `sw/pcimem/set_range.sh` for more information. |
| 17 | W | Reset hot cacheline array | 
| 18 - 23 | / | Not used | 
| 24 | W | This is used by PAC only. This will sent the circular buffer that PAC uses for writing the overflowing PAC counter index. |  
| 25 | W | This is used by PAC only. This is a accumulating counter that inform the CPU host of the number of valid index written to the circular buffer. | 
| 4096 - 5120 | R | This is for MMIO version of the M5 (r1bes_mmio). Hot page array. The hot PFN is in the lower 32 bits, and the upper 32 bits are hard-coded to a value for debugging. |
| 8192 - 16384 | R | This is for MMIO version of the M5 (r1bes_mmio). Hot cacheline array. |
