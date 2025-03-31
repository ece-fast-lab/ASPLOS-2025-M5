#ifndef WORKER_H
#define WORKER_H

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
#include "util.h"


#define PATH_TO_MIGRATION_PFN   "/proc/cxl_migrate_pfn"
#define PATH_TO_MIGRATION_NODE  "/proc/cxl_migrate_node"

// TODO, make this arg?
#define MIGRATION_TARGET_NODE   0

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

int start_threads(int num_threads, uint64_t* pci_vaddr, cfg_t cfg, uint32_t** hapb_buf_vaddr, uint64_t hapb_buf_paddr); 
class Worker {
    public:
        //mutex mtx;
        std::queue<uint64_t> buffer;
        shared_ptr<condition_variable> cv;
        shared_ptr<mutex> mtx; 
        int id;

        Worker(int id) : 
            id(id), 
            cv(std::make_shared<condition_variable>()), 
            mtx(std::make_shared<mutex>()) {}
};

typedef struct sys_counters {
    // use by different threads, no sync
    float rd_bw;
    float wr_bw;
    float l1_lats;
    float dram_lats;
    int fast_util; 
    int slow_util;

    // used by same thread
    int prev_threshold;
    float prev_total_bw;
    float prev_factor;
    int stable_cnt;
    uint64_t page_mig_cnt;
    float dram_ratio;
    float cxl_ratio;
    double d2c;
    double freq_out;
} sys_counters_t;

#endif 
