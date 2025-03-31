# Hardware
## Compilation
The design was compiled in Quartus v23.3, using Intel Quartus CXL-Type2 license. 

The design targets Intel Agilex 7 I-series, rev. `R1BES`. 

Please note that bitstream for `R1BES` and `RBES` FPGA are not compatible.

Loading the wrong bitstream will result in FPGA malfunction and requires a factory reset. 

## Pre-compiled designs
A few pre-compiled bitstreams are placed [here](https://drive.google.com/drive/folders/1LT51dHFtwyn8Gi2jxa-DLJqJT_W0--O8?usp=sharing):
- Any design named **without `rbes` is for `r1bes`**
- `cm` for Count-Min sketch, `w32k` for 32k counters
- `ss` for Space-saving
- `pac` page access counter


To compile the design:
```
cd m5_rtl/hardware_test_design
# update compile.sh for the quartus path
bash compile.sh 
# takes about 4hrs
# the generated bitstream is under m5_rtl/hardware_test_design/output_files/output_files/cxltyp2_ed.sof
```
## General setup
The [design doc](./general.md) provides a general understanding of the following components: 
1. Timing and clocking
2. Hardware interconnects
3. Control status registers (CSR)

## Individual designs
This folder offers several variants of the design. 

Depending of the test case, the user should load the proper bitstream for their test.

### M5 CM32k (MMIO)
This folder holds the design for the M5 CM sketch, with W=32k, and hot address fetch with MMIO interface. This will be used for HPT, HWT, and HPT + HWT.

The user may configure the design in `./m5_rtl/r1bes_mmio/hardware_test_design/common/afu/afu_banking_top.sv`, to toggle the `W` value.

### M5 CM32k (MEM)
This folder holds the design for the M5 CM sketch, with W=32k, and hot PFN fetch with memory (HPT only).

In the case of hot word fetch (HWT) , the design top level must be updated to do CXL Type2 write for the hot words.

In the case of hot word + hot page (HPT + HWT), the design top level must be updated to multiplex CXL Type2 write for both hot pages and hot words.

### PAC M5 CM32k
This folder holds the design for PAC, where the CXL Type2 is responsible for writing the overflowing index to a pre-allocated memory space.  

The corresponding software is under `../sw/pac_ofw_uspace/`, and `../sw/kmod_pac_ofw_buf/`.

The tracker in this case is using the CM32k tracker.

The hot address / words are exposed in MMIO.

### PAC M5 SS
Same as PAC M5 CM32k, except the tracker is using the space-saving tracker.


## Programming
Please follow the Intel Agilex documents to
1. Converting the `cxltyp2_ed.sof` to `.pof` file
    * The steps are listed in the Agilex dev kit documnet.
2. Programming the `.pof` file to the FPGA
    * Update the `.cdf` file to point to the desired `.pof` file.
    * Program with the `.cdf` file.

A [script](./program_fpga.sh) is provided here. Please update the quartus path and the USB blaster path then run the following command. The system may also require setting up the USB-blaster rules.

```
# for cm32k
bash program_fpga.sh ./bitstreams/m5_cm_banking.cdf
```

## USB blaster rules
These are necessary driver rules on Linux, to allow the USB blaster to communicate with the FPGA.

Please use `sudo` to edit these files  and restart the system after editing the rules.

### /etc/udev/rules.d/92-usbblaster.rules
```
# USB-Blaster
SUBSYSTEM=="usb", ATTRS{idVendor}=="09fb", ATTRS{idProduct}=="6001", MODE="0666"
SUBSYSTEM=="usb", ATTRS{idVendor}=="09fb", ATTRS{idProduct}=="6002", MODE="0666"
SUBSYSTEM=="usb", ATTRS{idVendor}=="09fb", ATTRS{idProduct}=="6003", MODE="0666"

# USB-Blaster II
SUBSYSTEM=="usb", ATTRS{idVendor}=="09fb", ATTRS{idProduct}=="6010", MODE="0666"
SUBSYSTEM=="usb", ATTRS{idVendor}=="09fb", ATTRS{idProduct}=="6810", MODE="0666"
```

### /etc/udev/rules.d/51-usbblaster.rules
```
# Intel FPGA Download Cable
SUBSYSTEM=="usb", ATTR{idVendor}=="09fb", ATTR{idProduct}=="6001", MODE="0666"
SUBSYSTEM=="usb", ATTR{idVendor}=="09fb", ATTR{idProduct}=="6002", MODE="0666"
SUBSYSTEM=="usb", ATTR{idVendor}=="09fb", ATTR{idProduct}=="6003", MODE="0666"


# Intel FPGA Download Cable II
SUBSYSTEM=="usb", ATTR{idVendor}=="09fb", ATTR{idProduct}=="6010", MODE="0666"
SUBSYSTEM=="usb", ATTR{idVendor}=="09fb", ATTR{idProduct}=="6810", MODE="0666"
```
