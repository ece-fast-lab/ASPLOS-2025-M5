# Running experiments
## Data sets
The data sets for the GAPBs and Liblinear test cases are reduced to < 8GB such that it fits in the 8GB CXL memory.

They are available in here: 

And they should be placed under the path specified in the `env.sh`, `GAPBS_PATH` and `LIBLINEAR_PATH`.

## Reproducing the results
### Exp 1. Performance comparison with ANB (Figure 9)
#### 1.1 Running Experiments
1. We will config the kernel ahead of each test case.
2. Input the proper argument`fig9_eval_all.sh` to evaluate the corresponding test case.

| Option | Kernel used | Description |
| -------- | ----------- | ---------- |
| anb | 5.19 | ANB, clean generic kernel |
| static | any kernel | All-CXL |
| damon | 6.11 | DAMON, everything enabled |
| hpt | 6.5-m5 | M5 HPT |
| hwt | 6.5-m5 | M5 HWT |
| hpwt | 6.5-m5 | M5 HPT+HWT |
```
cd ./testing_scripts/
# Switch kernel to 5.19
# For ANB
bash fig9_eval_all.sh "anb"

# Switch kernel to 6.11
# For DAMON 
bash fig9_eval_all.sh "damon"

# Switch kernel to 6.5-m5
# For M5 HPT
bash fig9_eval_all.sh "hpt"

# For M5 HWT
bash fig9_eval_all.sh "hwt"

# For M5 HPT+HWT
bash fig9_eval_all.sh "hpwt"
```

Each of the test case takes about 5 hours.

#### 1.2 Parsing Results
Since the result only consists of time logs, we can simply parse / plot the result on the SPR3 machine.

After running the 5 configurations above, the step below outlines how to parse the results:
```
cd ../results/
bash group_fig9_results.sh
```

#### 1.3 Generating graphics 
```
cd ../results/
python3 plot_fig9.py
# the plot will be in fig9.png
```

### Exp 2. HPT based average access-count ratios of HPT (Figure 8)

#### 2.1 Running Experiments

```
cd ./testing_scripts/
bash fig8_eval_all.sh
```
| Option | Kernel used | Description |
| -------- | ----------- | ---------- |
| pac-m5-ofw | 6.5 M5 kernel | M5 with Count-Min Sketch 2K counter, with PAC on the same bitstream | 
| pac-m5-ofw | 6.5 M5 kernel | M5 with Space-saving 50 counter, with PAC on the same bitstream |
| pac-damon-ofw | 6.11-PAC | 6.11 kernel with DAMON enabled, but page migraiton disabled. See DAMON-PAC in `../kernels`.|
| pac-anb-ofw | 5.19-PAC | ANB but disable migration, log all migrating addresses. See ANB-PAC in `../kernels`.|

Please uncomment the proper test for the corresponding test case in the script.

#### 2.2 Parsing Results
Since the HPT generates a huge amount of data for page access count, we recommand using a machine with ~150GB of storage space. 

If you would like to use another machine to parse the result, the general step is listed below.

Please update the `results/scp_to_a0.sh` with the proper path to the testing machine.

To organize the result and send to another machine for parsing, please use the following procedure:
#### ANB
```
# on the testing machine
cd <repo>/results
mkdir pac_anb_ofw
mv *_pac_anb_ofw pac_anb_ofw
bash fast-compress.sh pac_anb_ofw
bash scp_to_a0.sh pac_anb_ofw

# on the parsing machine
cd <repo>/results
mv <your scp path>/pac_anb_ofw* ./
bash fast_decompress.sh pac_anb_ofw

# parse on the parsing machine
cd <repo>/results
# uncomment the ANB part
bash parse_fig8.sh
```
#### DAMON
```
# on the testing machine
cd <repo>/results
mkdir pac_damon_ofw
mv *_pac_damon_ofw pac_damon_ofw
bash fast-compress.sh pac_damon_ofw
bash scp_to_a0.sh pac_damon_ofw

# on the parsing machine
cd <repo>/results
mv <your scp path>/pac_damon_ofw* ./
bash fast_decompress.sh pac_damon_ofw

# parse on the parsing machine
cd <repo>/results
# uncomment the DAMON part
bash parse_fig8.sh
```

#### M5-SS
```
# on the testing machine
cd results
mkdir pac_m5-ss
mv *_pac_m5_ofw pac_m5-ss
bash fast-compress.sh pac_m5-ss
bash scp_to_a0.sh pac_m5-ss

# on the parsing machine
cd <repo>/results
mv <your scp path>/pac_m5-ss* ./
bash fast_decompress.sh pac_m5-ss

# parse on the parsing machine
cd <repo>/results
# uncomment the M5-SS part
bash parse_fig8.sh
```

#### M5-cm2k
```
# on the testing machine
cd results
mkdir pac_m5-cm2k
mv *_pac_m5_ofw pac_m5-cm2k
bash fast-compress.sh pac_m5-cm2k
bash scp_to_a0.sh pac_m5-cm2k

# on the parsing machine
cd <repo>/results
mv <your scp path>/pac_m5-cm2k* ./
bash fast_decompress.sh pac_m5-cm2k

# parse on the parsing machine
cd <repo>/results 
# uncomment the M5-cm2k part
bash parse_fig8.sh
```

The result needs to be organized into the following structure in `<repo>/results`:
```
└── pac_anb_ofw
    ├── pac_505.mcf_r_pac_anb_ofw
    ├── pac_507.cactuBSSN_r_pac_anb_ofw
    ├── pac_549.fotonik3d_r_pac_anb_ofw
    ├── pac_554.roms_r_pac_anb_ofw
    ├── pac_gapbs-bc_pac_anb_ofw
    ├── pac_gapbs-bfs_pac_anb_ofw
    ├── pac_gapbs-cc_pac_anb_ofw
    ├── pac_gapbs-pr_pac_anb_ofw
    ├── pac_gapbs-sssp_pac_anb_ofw
    ├── pac_gapbs-tc_pac_anb_ofw
    ├── pac_liblinear_pac_anb_ofw
    └── pac_rsu_pac_anb_ofw
└── pac_damon_ofw
    ...
└── pac_m5-ss
    ...
└── pac_m5-cm2k
    ...
```
Both `pac_m5-ss` and `pac_m5-cm2k` are tested as `pac_m5_ofw`, while `pac_anb` is tested as `pac_anb_ofw`. The different between `pac_m5-ss` and `pac_m5-cm2k` is the bitstream that's being used, which will be configured ahead of the evaluation. It is important, however, to name the result correctly after running the two `pac_m5_ofw` experiments.

For each parsing, the python script will randomly sample 10 points in the PAC result, and use 10 threads to parse them 

The `parse_fig8.sh` spawns parsing for all benchmarks in the background. The user may comment out part of the script to reduce the amount of parallel parsing.

#### 2.3 Plotting 
Finally, the `plot_fig8.py` will generate a plot from all `r_max512.csv`
```
cd <repo>/results 
python3 plot_fig8.py
```
The generated plot is under `<repo>/results/fig8.png`

### Exp 3. Distribution of access counts per 4KB page. (Figure 10)
Figure 10 is generated from result extracted from figure 8.

On the machine that stores the `<repo>/results/pac*` with all the counter values.
```
cd ../results
bash plot_fig10.py
```
The generated plot is under `results/fig10.png`

### One step
It's not recommended to use this one step to do everything. 

This assumes all results are tested and parsed on the same machine. 
```
cd ../results/
bash organize_results.sh
bash parse_all_figs.sh
python3 plot_all_figs.py
```

# Acknowledgement
Some part of the testing script is derived from the well written scripts in [Memtis (SOSP'23)](https://dl.acm.org/doi/10.1145/3600006.3613167) and [HMSDK](https://github.com/skhynix/hmsdk/tree/main). We would like to thank the authors for their contribution to the community!
