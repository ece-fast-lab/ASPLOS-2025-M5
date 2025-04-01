# Software

## M5 manager
The general usage of the M5 manager is linked [here](./m5_manager_uspace/README.md).
To build the M5 manager:
```
cd ./m5_manager_uspace
mkdir build
cd build
cmake ..
make -j
# The binary is `m5_manager`
```
* The corresponding hardware design for the HPT is under `../hw/m5_rtl/r1bes_mmio/`

### Modified Intel PCM
A modified version of Intel PCM is included under `./cxl-hint-fault-pcm/` which has the following features:
1. Reduce monitoring overhead by only monitoring the bandwidth.
2. Using a share-memory to communicate with the M5 manager.

The path `PCM_MEMORY_REDUCED_PATH` in `./m5_manager_uspace/src/worker.cpp` should be updated to the path of this compiled binary.

## M5 manager latency optimized
To further reduce the overhead of M5 manager, some components are further optimized:
1. The pcm-memory is removed, as it incur ~1-2% CPU utilization.
    * In that case, the algorithm relies on the memory size usage for deciding the tracker output rate.
2. Hot address fetching is switched from MMIO to using CXL Type2 to write the hot PFN to a pre-allocated buffer.
    * This circular buffer will have CPU being the consumer and the Type2 device being the producer. 
    * This will reduce the overhead of MMIO read to memory read. 
    * The corresponding hardware design for the HPT is under `../hw/m5_rtl/r1bes_mem/`
        * The HWT / HPT + HWT would require changing the Type2 write addresses to write HWT address / mix of HWT + HPT addresses.
```
cd ./m5_lat_opt_uspace/
mkdir build
cd build
cmake ..
make -j
# The binary is `m5_manager`
```

## kmod\_pgmigrate
We made a kernel module to interacts with the migration interface. This must be used in the M5 v6.5 kernel.

To compile the kernel module:
```
cd ./kmod_pgmigrate/
sudo bash compile_install.sh
```
A new proc file `/proc/cxl_migrate_pfn` and `/proc/cxl_migrate_node` will be created for page migration.

## PAC
The PAC tracks the page access count in FPGA with SRAM. For the SRAM entry that overflows, the CXL Type2 logic will store the index of this page in hardware. When there's enough index to fill a 512 bit cacheline, the Type2 logic will issue a write to a circular buffer, which will be polled periodically by the pac userspace software. The polled indexes are accumulated for their corresponding access count and stored into a file. Finally, when testing with M5, the hot addresses are extracted at the same time from MMIO as the indexes are accumulated. When testing with ANB or DAMON, the hot addresses is logged to `dmesg`, which will also be dumped into a file.

To compile the PAC userspace binary:
```
cd ./pac_ofw_uspace/
mkdir build
cd build
cmake ..
make -j
# The binary is `m5_manager`
```

* The corresponding hardware design for the HPT is under `../hw/m5_rtl/pac_m5_cm32k/`

## damo
DAMON is linked to awslabs/damo

The `gen_migpol.py` comes from [hmsdk](https://github.com/skhynix/hmsdk/tree/main/tools), which is used for generating migration policy for damon.

The `p2_0d0_2.json` is generated for promoting hot pages from node 2 to node 0, and demoting cold pages from node 0 to node 2.

## pcimem
PCImem is used for setting the CSR on the hardware. The forked version includes a set of scripts that pre-configure the CSR for the experiments `set_all_init.sh`.

Before running the `pcimem`, please run the following command to enable the CSRs.
27:00.1 is the PCIe bar address on our machine for the FPGA.
```
sudo setpci -s 27:00.1 COMMAND=0x02
```

Please also update the pcie path in all of the shell scripts.
