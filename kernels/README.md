
# Tested Kernels
## M5 kernel (v6.5 based)
We made a customized Linux kernel to enable page migration with simply
1. A physical address 
2. A NUMA node number as the target node

To compile the kernel:
```
cd ./m5_kernel_v6.5/ 
make menuconfig
bash compile.sh
```

We made a kernel module to interacts with the migration interface.
To compile the kernel module:

```
cd ../sw/kmod_pgmigrate
sudo bash compile_install.sh
```
This will expose `/proc/cxl_migrate_pfn` and `/proc/cxl_migrate_node` for page migration.


## ANB (v5.19 based)
We chose v5.19 as it has the most stable performance in terms of migrating pages. In the 6.x kernels, we sometimes see ANB do not migrate any pages in the benchmarks.  

Any generic kernel at v5.19 will be sufficient.

### ANB-PAC
The `mm/migrate.c` file is changed to:
1. Disable page migration
2. Log the migrating PFN

The file is attached in the `./5.19_changes/`.

## DAMON (v6.11 based)
Starting from v6.11, DAMON with hot and cold page migration is integrated into the Linux kernel. The [hmsdk](https://github.com/skhynix/hmsdk/blob/main/tools/gen_migpol.py) provides a script to generate the necessary DAMON policy for issuing the page promotion and demotion. 

Please be sure to follow the instruction in [here](https://damonitor.github.io/posts/damon/) for setting up your kernel to enable DAMON tracking.

### DAMON-PAC
The `mm/damon/paddr.c` file is changed to:
1. Disable page migration
2. Log the migrating PFN

The file is attached in the `./6.11_changes/`.
