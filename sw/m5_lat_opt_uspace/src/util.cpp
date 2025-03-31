#include "util.h"
#include <stdio.h>
#include <numa.h>
#include <numaif.h>
#include <stdlib.h>
#include <unistd.h>
#include <errno.h>
#include <fcntl.h>

void print_arr(uint64_t* arr, int len) {
    for (int i = 0; i < len; i++) {
        cout << i << " " << arr[i] << "   ";
        if (len % 16 == 0 && len != 0) {
            cout << endl;
        }
    }
    cout << endl;
}

void print_unordered_map(unordered_map<uint64_t, uint64_t>& map) {
    int i = 0;
    for (const auto& pair : map) { 
        if (pair.second <= 1) continue;
        //if (pair.second == 0) continue;
        if (i % 8 == 0) cout << i << " "; 
        cout << "{" << std::hex << pair.first << ":" <<  std::dec << pair.second << "}   ";
        if (i % 8 == 7) cout << endl;
        i++;
    }
}

void print_arr_hex(uint64_t* arr, int len) {
    for (int i = 0; i < len; i++) {
        if (i % 8 == 0) cout << i << " "; 
        cout << std::hex << arr[i] <<  std::dec << "   ";
        if (i % 8 == 7) cout << endl;
    }
    cout << endl;
}

void print_map(unordered_map<uint64_t, uint64_t>& map) {
    int i = 0;
    for (auto it = map.cbegin(); it != map.cend(); ++it) {
        cout << std::hex << it->first <<  std::dec << " " << it->second << endl;
        i++;
        if (i > 256) break;
    }
}

// This function returns the NUMA node that a pointer address resides on.
int get_node(void *p, uint64_t size)
{
	int* status;
	void** page_arr;
	unsigned long page_size;
	unsigned long page_cnt;
	int ret;
	char* start_addr;
	
	page_size = (unsigned long)getpagesize();
	page_cnt = (size / page_size);
	status = (int*)malloc(page_cnt * sizeof(int));
	page_arr = (void**)malloc(page_cnt * sizeof(char*));
	start_addr = (char*)p;

	fprintf(stdout, "[get_node] buf: %lx, page_size: %ld, page_cnt: %ld\n", (uint64_t)(p), page_size, page_cnt);

	for (unsigned long i = 0; i < page_cnt; i++) {
		page_arr[i] = start_addr;
		if (i < page_cnt) {
			start_addr = &(start_addr[page_size]);
		}
	}

	
	ret = move_pages(0, page_cnt, page_arr, NULL, status, 0); 
	if (ret != 0) {
		fprintf(stderr, "Problem in %s line %d calling move_pages(), ret = %d\n", __FILE__,__LINE__, ret);
		printf("%s\n", strerror(errno));
	}

	ret = status[0];
	for (uint64_t i = 0; i < page_cnt; i++) {
		if (ret != status[i]) {
			fprintf(stderr, "found page: %lu on node: %d, different from node: %d\n", i, status[i], ret);
			ret = status[i];
			break;
		}
	}

	if (ret == status[0]) {
		fprintf(stdout, "all pages: %lx, %lx ... are on node: %d\n", (uint64_t)(page_arr[0]), (uint64_t)(page_arr[1]), ret);
	}
	
	free(page_arr);
	free(status);
	return ret;
}

/**
 * node_alloc
 *   @brief Allocate a memory buffer on the specified node.
 *   @param size in unit of bytes
 *   @param node integer to indicate the node where to allocate.
 *   @param alloc_ptr used for returning the pointer to the buffer.
 *   @return 0 if successful. Else error.
 */
int node_alloc(uint64_t size, int node, char** alloc_ptr, bool touch_pages) {
    char *ptr;
    int ret;
    unsigned long page_size;
    uint64_t page_cnt;
    uint64_t idx;

    if ((ptr = (char *)numa_alloc_onnode(size, node)) == NULL) {
        fprintf(stderr,"Problem in %s line %d allocating memory\n",__FILE__,__LINE__);
        return -1;
    }

    if (touch_pages) {
        printf("[INFO] done alloc. Next, touch all pages\n");

        // alloc is only ready when accessed
        page_size = (unsigned long)getpagesize();
        page_cnt = (size / page_size);
        idx = 0;
        for (uint64_t i = 0; i < page_cnt; i++) {
            ptr[idx] = 0;	
            idx += page_size;
        }
        printf("[INFO] done touching pages. Next, validate on node X\n");

        ret = get_node(ptr, size);
        if (ret != node) {
            printf("ptr is on node %d, but expect node %d\n", ret, node);
            return -2;
        }
        printf("ptr is on node %d\n", ret);

    } else {
        smart_log("Allocated mem, but pages are not touched\n");
    }

    printf("allocated: %luMB\n", (size >> 20));
    *alloc_ptr = ptr;
    
    return 0;
}


int node_free (char* ptr, uint64_t size) {
	numa_free(ptr, size);
	return 0;
}

int parse_arg(int argc, char** argv, cfg_t& cfg) {
    /* parse the arguments */
    char opt;
    int ret = 0;
    while ((opt = getopt(argc, argv, "t:l:c:s:d:R:x:f:TLCprmnwAhP")) != -1) {
        LOG_DEBUG("opt: %c\n", opt);
        switch (opt) {
            case 't':
                cfg.thread_cnt = atoi(optarg);
                break;
            case 'f':
                cfg.base_freq = strtod(optarg, NULL);
                break;
            case 'l':
                cfg.look_back_hist = atoi(optarg);
                break;
            case 's':
                cfg.wait_ms = atoi(optarg);
                break;
            case 'c':
                cfg.c2p_ratio = atoi(optarg);
                break;
            case 'x':
                cfg.ratio_power = strtod(optarg, NULL);
                break;
            case 'R':
                cfg.is_traffic = true;
                cfg.is_traffic_rate = atoi(optarg);
                break;
            case 'T':
                cfg.is_test = true;
                break;
            case 'L':
                cfg.print_list = true;
                break;
            case 'C':
                cfg.print_counter = true;
                break;
            case 'p':
                cfg.parsing_mode = true;
                cfg.print_counter = true;
                break;
            case 'r':
                cfg.is_traffic = true;
                break;
            case 'n':
                cfg.eac_m5 = true;
                break;
            case 'w':
                cfg.hwt_only = true;
                break;
            case 'A':
                cfg.no_algo = true;
                break;
            case 'd':
                cfg.do_dump = true;
                cfg.is_test = true;
                if (strlen(optarg) < MAX_PATH_LEN) {
                    strcpy(cfg.dump_path, optarg);
                    LOG_INFO("hi, %s\n", cfg.dump_path);
                } else {
                    LOG_ERROR("file path <%s> is too long, please limited it to %d characters\n", optarg, MAX_PATH_LEN);
                    ret = -1;
                }
                break;
            case 'm':
                cfg.no_mig = true;
                break;
            case 'P':
                cfg.hapb = true;
                break;
            case 'h':
                printf("Usage: sudo ./m5_manager <args>\n");
                printf( 
                        " ----------------------------- help ----- <with arg>\n"\
                        "   -t  migrator thread count [default = 1]\n"\
                        "   -f  default frequency, used for scaling the tracker output frequency[default = 1]\n"\
                        "   -l  number of history to look back for the algorithm [default = 10]\n"\
                        "   -c  number of cacheline list fetch per pfn fetch [default = 0, no cacheline fetch]\n"\
                        "   -s  sleep ms for each iteration [default = 1000]\n"\
                        "   -d  dump log / eac to path <input> [default = no dumpping], if enabled, migration is not triggered (-m is implied)\n"\
                        "   -x  ratio power, rasise the c2d ratio to the power of X [default = 3]\n"\
                        "   -R  traffic based query, changing the default rate [see include for default]\n"\
                        " ----------------------------- help ----- <w/o arg>\n"\
                        "   -T  worker write to file, instead of migratino proc fs [default = false]\n"\
                        "   -L  print migration list [default = false]\n"\
                        "   -C  print counter values [default = false]\n"\
                        "   -p  print counter values in parsing mode [default = false], if true, then -C is implied\n"\
                        "   -r  use traffic based query [default = clk based]\n"\
                        "   -m  disable migration [default = false == enable m5 migration ]\n"\
                        "   -n  do eac_m5, must use with -d [default = false]. Without -d -n, dmesg will be output to klog.txt\n"\
                        "   -w  hwt_only. fetch page list from cl list. [default = false]\n"\
                        "   -A  no algo. disable tuning for rate and have static rate instead\n"\
                        "   -h  print this message\n"
                        "   -P  use hapb buffer for migration\n"
                );
                return -1;
            default:
                LOG_ERROR("Unknown arg %c\n", opt);
                ret = -1;
                break;
        }
        if (ret < 0) break;
    }
    cout << "cfg.do_dump" << cfg.do_dump << endl;
    cout << "cfg.is_test" << cfg.is_test << endl;
    return ret;
}
