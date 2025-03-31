#ifndef UTIL_H
#define UTIL_H

#include <stdint.h>
#include <stdbool.h>

#include <iostream>
#include <thread>
#include <vector>
#include <fstream>
#include <mutex>
#include <condition_variable>
#include <chrono>
#include <queue>
#include <csignal>
#include <atomic>
#include <chrono>
#include <cstdint>
#include <iomanip>
#include <unordered_map>

using std::vector;
using std::thread;
using std::cout;
using std::endl;
using std::cerr;
using std::string;
using std::ofstream;
using std::unique_lock;
using std::mutex;
using std::shared_ptr;
using std::condition_variable;
using std::unordered_map;

#define DEBUG 1

/* text color */
#define RED   "\x1B[31m"
#define GRN   "\x1B[32m"
#define YEL   "\x1B[33m"
#define BLU   "\x1B[34m"
#define MAG   "\x1B[35m"
#define CYN   "\x1B[36m"
#define WHT   "\x1B[37m"
#define RESET "\x1B[0m"

#define MAX_PATH_LEN    256

#define LOG_INFO(...) ( printf(GRN "[INFO] " RESET), printf(__VA_ARGS__) )
#define LOG_WARN(...) ( printf(YEL "[WARN] " RESET), printf(__VA_ARGS__) )
#if DEBUG == 1
#define LOG_DEBUG(...) ( printf(MAG "[DEBUG] " RESET), printf(__VA_ARGS__) )
#else
#define LOG_DEBUG(...) 
#endif // DEBUG
#define LOG_ERROR(...) ( printf(RED "[ERROR] " RESET), printf(__VA_ARGS__) )

#define debug_print(fmt, ...) \
        do { if (DEBUG) fprintf(stderr, "%s:%d:%s(): " fmt, __FILE__, \
                                __LINE__, __func__, __VA_ARGS__); } while (0)
#define smart_log(...) ( printf(CYN "[%s]: " RESET, __func__ ) , printf(__VA_ARGS__) )

#define DEBUG_LOG(x) do { \
      if (DEBUG) { std::cerr << x << std::endl; } \
} while (0)

#define IF_FAIL_THEN_EXIT       if (ret != 0) goto FAILED;


typedef struct cfg {
    int thread_cnt;
    int look_back_hist;
    int wait_ms;
    bool is_test;
    bool print_counter;
    bool print_list;
    int c2p_ratio;
    bool is_traffic;
    bool do_dump;
    char dump_path[MAX_PATH_LEN];
    bool parsing_mode;
    double base_freq;
    bool eac_m5;
    bool no_mig;
    double ratio_power;
    bool hwt_only;
    bool no_algo;
    int is_traffic_rate;
    bool hapb;
} cfg_t;


int get_node(void* p, uint64_t size);

int node_alloc(uint64_t size, int node, char** alloc_ptr, bool touch_pages);

int node_free (char* ptr, uint64_t size);

int parse_arg(int argc, char** argv, cfg_t& cfg);

void print_arr(uint64_t* arr, int len);

void print_arr_hex(uint64_t* arr, int len);

void print_unordered_map(unordered_map<uint64_t, uint64_t>& map);

void print_map(unordered_map<uint64_t, uint64_t>& map);

extern std::vector<u_int64_t> cycle_count_collector;


/*
typedef enum test_op {
	RD_ONE_PASS,
    RD_ZIPFIAN,
    RD_UNIFORM,
    RD_STRIDE,
    TYPE_LAST
} test_op_t;
*/

#endif
