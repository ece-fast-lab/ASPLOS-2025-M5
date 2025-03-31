# Page Table Scanner

Tested on Linux 5.15, not sure if works on Linux 6.5.

1. Compile and install the module

2. Set the dump target `echo "U<pid>" > /proc/page_tables`, e.g. `echo "U1" > /proc/page_tables`

3. Dump page table (and clear access bits): `cat /proc/page_tables > dump.txt`

4. Dump page table again (and see who is re-accessed, as well as clear access bits again): `cat /proc/page_tables > dump.txt`

Example output with comments (from `example.txt`):

```
# PID of the target process
               1

# column header
VA,PGD_ACC,P4D_ACC,PUD_ACC,PMD_ACC,PTE_ACC,PA,ENT_TYPE

# column contents
000055fbd7a0f000,1,1,1,1,0,42fafd,PTE
000055fbd7a10000,1,1,1,1,0,42c07e,PTE
000055fbd7a11000,1,1,1,1,0,115424,PTE
000055fbd7a12000,1,1,1,1,0,1155e9,PTE
000055fbd7a13000,1,1,1,1,0,119c4b,PTE
000055fbd7a14000,1,1,1,1,0,11b539,PTE
000055fbd7a15000,1,1,1,1,0,119f2a,PTE
000055fbd7a16000,1,1,1,1,0,114f1b,PTE
000055fbd7a17000,1,1,1,1,0,114f11,PTE
```
