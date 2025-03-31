# Hot tracker code
This is an module tracking hot page and hot cache in CXL Type 2 IP. Hot tracker currently supports the AMD Xilinx Alveo U280 and Intel Altera Agilex 7 I-series, AGIB027R29A1E2VR3. 

## Repository File Structure

```
.
+-- sim/                                    # Cadence Xcelium simulator
|       +-- tb_afu_top_random.sv            # Testbench. A result log is generated in ./verify/result.txt
|       +-- xrun_arg                        # Xcelium arguments
|       +-- filelist                        # verilog files and IP files
|       +-- sim.sh                          # simulation script
|       +-- verify
        |     +-- tb_afu_top_random.py      # Verification code. Generate random trace (./rtrace.txt) 
                                              and give the correct answer (./answer.txt)
        |     +-- compare.py                # Compare answer.txt and result.txt
        |     +-- run.sh                    
+-- src/                       
|       +-- afu_top.sv                      
|         +-- hot_tracker_top.sv            
|           +-- hot_tracker.sv              
|             +-- addr_cam.sv               # Address CAM 
|             +-- cnt_cam.sv                # Count CAM
|             +-- cam_components.sv         # CAM's logic 
|       +-- axis_data_fifo                  # Axis FIFO wrapper
+-- header/                       
|       +-- afu_axi_if_pkg.sv               # Intel CXL IP package
|       +-- clst_pkg.sv                     # Intel CXL IP package
|       +-- mc_axi_if_pkg.sv                # Intel CXL IP package
|       +-- cxlip_top_pkg.sv                # Intel CXL IP package
|       +-- cxl_ed_defines.svh.iv           # Intel CXL IP systemverilog header files
|       +-- cxl_type2_defines.svh.iv        # Intel CXL IP systemverilog header files
+-- ip/                       
|       +-- axis_data_fifo                  # AMD XILINX axi-stream FIFO IP
|       +-- fifo                            # Intel FIFO IP 
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
> (1) Generate a random trace file (rtrace.txt) and a correct result file (answer.txt).
> (2) Run the testbench with the Xcelium simulator and log is written in result.txt.
> (3) Compare result.txt with answer.
  
## Contact 
- Hwayong Nam
- Eojin Na
- Jaehyun Park
