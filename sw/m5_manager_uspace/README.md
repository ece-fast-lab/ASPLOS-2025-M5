# M5 manager

## Arguments

| Argument | Brief description | Default | Valid inputs | Note |
| -------- | ----------------- | ------- | ------------ | ---- |
| t | Thread cnt | 1 | 1 | Number of migrating threads. This only supports 1 for now | 
| f | Base frequency | PFN_BASE_FREQ | floating point values | The starting frequency of tracker output.|
| l | look_back_hist | 10 | < 64 | This corresponds to how the m5_manager filter out some hot page. Depending on the algorithm in algo.cpp, hist have different meaning. For example, in the case of HWT, it sets the `bit_min` which indicates the minimum number of hot cacheline that a page should have, to be considered for page promotion | 
| s | Wait ms | 1000 | 1 - 2^31 | This is the period of m5_manager fetching the hot list from the FPGA |
| c | Cacheline to page ratio | 0 | 1 - 2^31 | The c2p\_ratio decides how many times the cacheline list should be fetched, for every time the page list is fetched. For example, in the `fetch_migrate_list`, the page list is always fetched once, while the cacheline list is fetched `c2p_ratio` times. This will make use of both HPT and HWT and align the two in `migration_pfn`. (The ` migration_pfn[current_pfn] <<= 2;` simply gives a hot cacehline more weight when being considered for hot page promotion.) | 
| x | Ratio power | 3 | 1 - 2^31 | The dram / cxl density ratio is raised to the power of this value. The higher the value, the more “penalty” that we apply to page migration, `threshold_policy_v2`, frequency factor = c_ratio / d_ratio. The larger the value is raised to, the less page we migrate when the d_ratio is large, (1/2)^1 < (1/2)^3, and lower freq = higher period = less migration. | 
| T | Test | / | / | If set, the migration will not happen, but instead, the hot address will be written to a file. | 
| R | Traffic based tracking | false | / | cfg.is_traffic – Use traffic-based tracker output period. The tracker will output based on number of read requests (instead of clock cycle).|
| L | Print migration list | false | / | If set, the migrating address will be printed to the console.|
| C | Print counters | false | / | If set, the statistics will be printed. |
| p | Parsing mode | false | / | Write the migration statistic values to the console, in csv style. |
| d | PAC dump path | / | / | cfg.do_dump – Using this argument will require the PAC bitstreams. The purpose of this argument is to set the path for dumping the PAC values. |
| n | PAC M5 | false | / | Use together as `do_dump`. This will log the migrating address to a file in the case of PAC + M5. This will log the migrating address for AutoNUMA balancing with dmesg (with a modified kernel). |
| m | No migration | false | / | Do not issue page migration. |
| w | HWT only | false | / | When set, the hot page array is ignored, and migraiton is only based on hot cachelines. |
| A | No algo | false | / | When set, the filtering algorithm is not applied. This is useful for debugging and testing the migration logic. The migration will be done directly based on the fetched hot pages from the FPGA. |

