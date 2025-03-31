#include "worker.h"
#include "util.h"
#include "csr.h"
#include "algo.h"
#include <iostream>
#include <cstdio>
#include <array>
#include <unistd.h>
#include <fcntl.h>
#include <sys/select.h>
#include <sys/stat.h>
#include <regex>
#include <fstream>
#include <cmath>

#include <unistd.h>
#include <fcntl.h>
#include <sys/shm.h>
#include <semaphore.h>
#include "pcm-memory-shared.c"


//#define PRINT_PFN_LIST
//#define PRINT_COUNTER

// void init_bandwidth_env(double delay);

#define PCM_MEMORY_PATH "/home/yans3/pcm/build/bin/pcm-memory"
#define PCM_MEMORY_REDUCED_PATH "/home/yans3/gitdoc/cxl-hint-fault-pcm/build/bin/pcm-memory-daemon"
#define PCM_LATENCY_PATH "/home/yans3/pcm/build/bin/pcm-latency"
#define DUMMY_OUTPUT_TXT "/home/yans3/gitdoc/cxlmem_test_software/m5_manager_userspace/build/dummy_mig.txt"

// Each worker should not queue more than 
//  this number of PFN
#define MAX_WORKER_QUEUE_PFN        256

#define RATIO_DELTA_FACTOR          0.05
#define THRESHOLD_PRECENTAGE        1000


// global variable for consumer / producer
std::atomic<bool> stop_flag(false);
std::vector<Worker> workers; 
std::vector<thread> threads_vec;
std::atomic<int> dump_cnt(0);

std::vector<u_int64_t> cycle_count_collector;

uint64_t*   pci_vaddr_stop;

uint64_t move_accu;
uint64_t last_print;

void stop_all() {
    stop_flag = true;
    for (auto& curr_worker : workers) {
        curr_worker.cv->notify_all();
    }
    pci_vaddr_stop[CSR_HAPB_HEAD] = 0;
    for (size_t i = 0; i < cycle_count_collector.size(); i++) {
        LOG_INFO("Cycle count: %lu\n", cycle_count_collector[i]);
    }
}

int init_migration_ndoe(int node, bool is_test) {
    string proc_file_path = PATH_TO_MIGRATION_NODE;
    if (is_test) {
        proc_file_path = DUMMY_OUTPUT_TXT;
    }
    ofstream proc_file(proc_file_path);
    if (!proc_file.is_open()) {
        cerr << "Error: Unable to open node file: " << proc_file_path << endl;
        return 1;
    }
    // Write data to the proc file
    proc_file << node;

    // Check if the write was successful
    if (!proc_file.good()) {
        cerr << "Error: Failed to write to proc file " << proc_file_path << endl;
        proc_file.close();
        return 1;
    }
    // Close the proc file
    proc_file.close();
    cout << "Data successfully written to proc file: " << proc_file_path << endl;
    return 0;
}

void check_path_exist(const char* dump_path) {
    struct stat st = {0};
    if (stat(dump_path, &st) == -1) {
        LOG_INFO("path {%s} does not exist, creating one ...\n", dump_path);
        mkdir(dump_path, 0777);
        //LOG_INFO("after creation, %d\n", stat(dump_path, &st));
    } else {
        LOG_INFO("path {%s} exist!\n", dump_path);
    }
}

int worker_dump_func(char* dump_path) {
    cout << "Worker dumping thread is executing..." << endl;
    volatile int dump_cnt_local = 0;

    string file_path = string(dump_path);
    ofstream proc_file(file_path + "/offset_0/klog.txt");
    if (!proc_file.is_open()) {
        cerr << "[worker dump] Error: Unable to open [fist] dir " << (file_path + "/offset_0/klog.txt") << endl;
        return 1;
    } else {
        LOG_DEBUG("[worker dump] first dir ok\n");
    }

    while (!stop_flag) {
        // new path from eac_func
        if (dump_cnt_local != dump_cnt) {
            dump_cnt_local = dump_cnt;
            proc_file.close();

            std::ostringstream oss;
            oss.str("");
            // legacy naming ...
            oss << "/offset_" << (dump_cnt_local) << "/klog.txt";
            proc_file = ofstream(file_path + oss.str());
            cout << oss.str() << endl;
            if (!proc_file.is_open()) {
                cerr << "[worker dump] Error: Unable to [later] open proc file " << (file_path + oss.str()) << endl;
                return 1;
            }
        }

        Worker& worker_self = workers[0];
        unique_lock<mutex> lock(*(worker_self.mtx));

        // wait until not empty
        worker_self.cv->wait(lock, [&worker_self](){ return !worker_self.buffer.empty() || stop_flag; });

        uint64_t pfn_to_migrate = worker_self.buffer.front();
        worker_self.buffer.pop();

        // Write data to the proc file
        proc_file << std::hex << pfn_to_migrate << endl;

        // Check if the write was successful
        if (!proc_file.good()) {
            LOG_ERROR("Error: Failed to write to proc file %s\n", file_path.c_str());
            proc_file.close();
            return 1;
        } else {
            //LOG_DEBUG("Data successfully written to proc file");
        }

        lock.unlock();
        worker_self.cv->notify_all(); // --> producer, ready to append

    }

    LOG_INFO("Worker dump exit ok\n");
    cout << "stop flag = " << stop_flag << endl;
    proc_file.close();
    return 0;
}

int eac_func(char* dump_path, uint64_t* pci_vaddr, bool eac_m5) {
    int dump_cnt_local, ret;
    cout << "EAC dumping thread is executing..." << endl;
    string file_path = string(dump_path);
    while (!stop_flag) {
        dump_cnt_local = dump_cnt;
        LOG_INFO("eac iter: %d\n", (int)dump_cnt);
        // zero out
        start_zeroout(pci_vaddr);

        // sleep
        std::this_thread::sleep_for(std::chrono::milliseconds(100));

        // dump
        // legacy naming ...
        string name = file_path + "/offset_" + std::to_string(dump_cnt_local) + "/counter_val_0.txt";
        dump_eac_buff(pci_vaddr, name.c_str());

        if (!eac_m5) {
            string cmd = "sudo dmesg -c > " + file_path + "/offset_" + std::to_string(dump_cnt_local) + "/klog.txt";
            ret = system(cmd.c_str());
            if (ret) {
                LOG_ERROR("eac_func dmesg dump failed \n");
            }
        }

        // mkdir
        dump_cnt_local += 1;
        name = file_path + "/offset_" + std::to_string(dump_cnt_local);
        check_path_exist(name.c_str());

        // inc
        dump_cnt += 1;
    }
    return 0;
}


int worker_func(int thread_id, bool is_test) {
    cout << "Worker thread " << thread_id << " is executing..." << endl;
    string proc_file_path = PATH_TO_MIGRATION_PFN;
    if (is_test) {
        proc_file_path = DUMMY_OUTPUT_TXT;
    }
    ofstream proc_file(proc_file_path);

    if (!proc_file.is_open()) {
        cerr << "Error: Unable to open proc file " << proc_file_path << endl;
        return 1;
    }

    while (!stop_flag) {
        Worker& worker_self = workers[thread_id];
        unique_lock<mutex> lock(*(worker_self.mtx));
        // cout << "Worker " << thread_id << " waiting ... " << endl;

        // wait until not empty
        worker_self.cv->wait(lock, [&worker_self](){ return !worker_self.buffer.empty() || stop_flag; });

        uint64_t pfn_to_migrate = worker_self.buffer.front();
        worker_self.buffer.pop();

        // Write data to the proc file
        proc_file << std::hex << pfn_to_migrate << endl;
        //LOG_DEBUG("Worker %d consumed: 0x%lx\n", thread_id, pfn_to_migrate);

        // Check if the write was successful
        if (!proc_file.good()) {
            LOG_ERROR("Error: Failed to write to proc file %s\n", proc_file_path.c_str());
            proc_file.close();
            return 1;
        } else {
            // LOG_DEBUG("Data successfully written to proc file");
        }

        lock.unlock();
        worker_self.cv->notify_all(); // --> producer, ready to append
    }
    LOG_DEBUG("Worker %d exit ok\n", thread_id);
    cout << "stop flag = " << stop_flag << endl;
    proc_file.close();
    return 0;
}

void clean_up_algo_structure() {
    // TODO
    LOG_DEBUG("S4: Producer clean up algo struct [TODO] \n");
}
int threshold_policy_v3(double base_freq, double ratio_power, float fast_util, float slow_util) {
    int ret = (int)((pow(slow_util / (fast_util * base_freq), ratio_power) * (double)THRESHOLD_PRECENTAGE));
    LOG_INFO("threshold v3 = %d, %f\n", ret, 
            (pow(slow_util / (fast_util * base_freq), ratio_power)));
    if (ret < 0 || ret > THRESHOLD_PRECENTAGE) ret = THRESHOLD_PRECENTAGE;
    return THRESHOLD_PRECENTAGE;
}

int threshold_policy_v2(
        uint64_t* pci_vaddr,
        bool is_traffic,
        double base_freq,     
        double ratio_power,
        sys_counters_t& sys_counters_curr, 
        float d_ratio,
        float c_ratio,
        float total_bw,
        uint64_t& pfn_period,
        uint64_t& push_period) {

    int ret = THRESHOLD_PRECENTAGE;
    uint64_t period_pfn, period_cl;
    double freq_factor = (double)c_ratio / (double)d_ratio;
    // higher rate = smaller migration
    //  d-c inc == larger period == less mig 
    LOG_DEBUG("S3: freq_factor before powerd: %f\n", freq_factor);
    //freq_factor = pow(freq_factor, ratio_power) * base_freq;
    freq_factor = c_ratio / pow(d_ratio * base_freq, ratio_power);
    LOG_DEBUG("S3: ratio after powered: %f\n", freq_factor);

    // change in total_bw
    double delta_total_bw = total_bw - sys_counters_curr.prev_total_bw;
    double dram_norm = d_ratio / total_bw;
    double delta_norm = dram_norm - sys_counters_curr.prev_factor;
    if (delta_norm > 0.0) {
        ret = 0; // disable migration
        LOG_DEBUG("S3: set threshold to 0, d_T: %f, d_F: %f\n", delta_total_bw, delta_norm);
    }

    // finaliziing 
    double freq_out = freq_factor;
    sys_counters_curr.freq_out = freq_out;
    period_pfn = (uint64_t)((double)1.0 / freq_out);
    //LOG_DEBUG("S3: set threshold to 0, d_T: %f, d_F: %f\n", delta_total_bw, delta_freq_factor);

    if (period_pfn < 128) { period_pfn = 128; }
    else if (period_pfn > 0xFFFFFF) { period_pfn = 0xFFFFFF; }
    period_cl = period_pfn >> 6;

    if (is_traffic) {
        period_pfn |= 0x80000000;
        period_cl |= 0x80000000;
    }
    //LOG_INFO("S3: rate: %d\n", period_pfn);

    pfn_period = period_pfn;
    push_period = period_cl;
    set_counters(pci_vaddr, pfn_period, push_period);

    sys_counters_curr.dram_ratio = d_ratio;
    sys_counters_curr.cxl_ratio = c_ratio;
    sys_counters_curr.d2c = freq_factor;
    sys_counters_curr.prev_total_bw = total_bw;
    sys_counters_curr.prev_factor = dram_norm;

    return THRESHOLD_PRECENTAGE;
}

void apply_threshold(int curr_threshold, 
        unordered_map<uint64_t, 
        uint64_t>& migration_pfn,
        bool hwt_only) {
    // XXX size() of migration_pfn? or max len
    //int max_valid = ((float)curr_threshold / 100.0) * (float)MIGRATE_LIST_MAX_LEN;    
    int max_valid = 0;
    max_valid = ((float)curr_threshold / (float)(THRESHOLD_PRECENTAGE)) * migration_pfn.size();    
    /*
    if (hwt_only) {
    } else {
        //max_valid = ((float)curr_threshold / (float)(THRESHOLD_PRECENTAGE)) * (float)1024;    
    }*/
    int valid_cnt = 0;
    int skip_cnt = 0;
    for (auto& pair : migration_pfn) { 
        if (pair.second != (uint64_t)-1) {
            valid_cnt++;
        }
        // final filter for PFN
        if (valid_cnt >= max_valid) {
            pair.second = (uint64_t)-1;
            //skip_cnt++;
            break;
        }
    }
    LOG_DEBUG("S3: threshold filter: valid: %d, skip: %d, threshold: %d, max_valid: %d\n",
            valid_cnt, skip_cnt, curr_threshold, max_valid);
}

/**
 * update_algo_structure 
 *   @brief this function is called rateically by the producer thread. 
 *      It takes in 1. counter value from hardware, 2. hot pfn list from hardware, 
 *          3. user defined selection algorithm for the pfn list
 *      The user defined selection algorithm should udpate 2. by 
 *          setting any non-migrating entry to 0
 *   @param counter_curr, the counter value return from the monitoring unit in hardware
 *   @param pfn_to_migrate, the hot pfn list generated by the hardware 
 *   @param algo, the user defined algorithm for selecting pages to migrate, upon insertion 
 */
void update_algo_structure(
        uint64_t* pci_vaddr,
        bool is_traffic,
        bool hwt_only,
        double base_freq,
        double ratio_power,
        fpga_counters_t& counter_curr, 
        sys_counters_t& sys_counters_curr, 
        unordered_map<uint64_t, uint64_t>& migration_pfn, 
        uint64_t& pfn_period,
        uint64_t& push_period,
        Selection& algo) {

    // S2 algo for selection
    LOG_DEBUG("S2: Producer update algo struct\n");
    algo.insert_new_pfn(migration_pfn);

    // S3 algo, should use `counter_curr`
    //  store share variable in local variable,
    //      avoid race condition
    float fast_util = (float)sys_counters_curr.fast_util;
    float slow_util = (float)sys_counters_curr.slow_util;
    float cxl_read = counter_curr.rd_bw;
    float dram_read = (float)sys_counters_curr.rd_bw; 

    int curr_threshold = sys_counters_curr.prev_threshold;
    float d_ratio, c_ratio;

    if (slow_util == 0 || dram_read == 0 || cxl_read == 0 || fast_util == 0) {
        curr_threshold = THRESHOLD_PRECENTAGE; // XXX?
        LOG_DEBUG("S3: avoid div by 0, slow_util: %f, dram_read: %f, cxl_read: %f\n", slow_util, dram_read, cxl_read);
        //curr_threshold = threshold_policy_v3(base_freq, ratio_power, fast_util, slow_util);
        d_ratio = fast_util;
        c_ratio = slow_util;
        curr_threshold = threshold_policy_v2(pci_vaddr, 
                is_traffic, 
                base_freq,
                ratio_power,
                sys_counters_curr, 
                d_ratio, 
                c_ratio, 
                cxl_read + dram_read,
                pfn_period, 
                push_period);
    } else {
        d_ratio = (dram_read / fast_util);
        c_ratio = (cxl_read / slow_util);
        LOG_DEBUG("S3: d, c = %f, %f\n", d_ratio, c_ratio);

        curr_threshold = threshold_policy_v2(pci_vaddr, 
                is_traffic, 
                base_freq,
                ratio_power,
                sys_counters_curr, 
                d_ratio, 
                c_ratio, 
                cxl_read + dram_read,
                pfn_period, 
                push_period);
    }
    apply_threshold(curr_threshold, migration_pfn, hwt_only);
    sys_counters_curr.prev_threshold = curr_threshold;
}


uint64_t issue_migraiton(unordered_map<uint64_t, uint64_t>& migration_pfn) {
    uint64_t valid_cnt = 0;
    int issued_and_queuing_item = 0;
    LOG_DEBUG("S4: Producer start %ld migration\n", migration_pfn.size());


    for (const auto& pair : migration_pfn) {
        if (pair.second == (uint64_t)(-1)) continue; // invalid pfn, denoted with -1 as cnt
        uint64_t pfn = pair.first;
        //LOG_DEBUG("Producer valid: %lx\n", pair.second);

        auto& curr_worker = workers[valid_cnt % workers.size()];

        unique_lock<mutex> lock(*(curr_worker.mtx));
        curr_worker.cv->wait(lock, [&curr_worker](){ return curr_worker.buffer.size() < MAX_WORKER_QUEUE_PFN || stop_flag; });

        if (valid_cnt < workers.size()) {
            issued_and_queuing_item += curr_worker.buffer.size();
        }
        if (stop_flag) return 0;
        valid_cnt++;
        curr_worker.buffer.push(pfn);
        lock.unlock();
        curr_worker.cv->notify_all(); // --> worker, new item arrived

        if (valid_cnt % 1024 == 0) {
            LOG_DEBUG("Producer issued %ld migration\n", valid_cnt);
        }
    }

    if (migration_pfn.size() > 0) {
        LOG_DEBUG("Producer done for batch size: %ld, valid cnt: %ld, accumulated: %lu, queuing: %d\n", 
                migration_pfn.size(), 
                valid_cnt, 
                move_accu, 
                issued_and_queuing_item);
        /*
           move_accu += valid_cnt;
           if (move_accu - last_print > 0xFFFF) {
           last_print = move_accu;
           }*/
    }
    return valid_cnt;
}

bool check_alive_worker() {
    bool ret = true;
    for (uint64_t i = 0; i < threads_vec.size(); i++) {
        if (!threads_vec[i].joinable()) {
            LOG_ERROR("Found dead thread %ld\n", i);
            ret = false;
        }
    }
    return ret;
}

int print_sys_counters(sys_counters_t& counter, uint64_t& pfn_period, uint64_t& push_period, bool parsing_mode) {
    if (parsing_mode) {
        cout << counter.rd_bw << ","; 
        cout << counter.fast_util << ","; 
        cout << counter.slow_util << ","; 
        cout << counter.prev_threshold << ",";
        cout << counter.page_mig_cnt << ",";
        cout << counter.dram_ratio << ",";
        cout << counter.cxl_ratio << ",";
        cout << counter.prev_total_bw << ",";
        cout << counter.d2c << ",";
        cout << pfn_period << ",";
        cout << push_period << endl;
    } else {
        //LOG_INFO("       l1_lats: %f\n", counter.l1_lats);
        LOG_INFO("[print_sys_counters] ===============================\n");
        //LOG_INFO("       dram_lats: %f\n", counter.dram_lats);
        LOG_INFO("       read:  %f\n", counter.rd_bw);
        //LOG_INFO("       write: %f\n", counter.wr_bw);
        LOG_INFO("       fast_util:  %d\n", counter.fast_util);
        LOG_INFO("       slow_util:  %d\n", counter.slow_util);
        LOG_INFO("       threshold:  %d\n", counter.prev_threshold);
        LOG_INFO("       page mig :  %ld\n", counter.page_mig_cnt);
        LOG_INFO("       d_ratio  :  %f\n", counter.dram_ratio);
        LOG_INFO("       c_ratio  :  %f\n", counter.cxl_ratio);
        LOG_INFO("       total_bw :  %f\n", counter.prev_total_bw);
        LOG_INFO("       d2c      :  %.15lf\n", counter.d2c);
        LOG_INFO("       freq_out :  %.15lf\n", counter.freq_out);
        LOG_INFO("       rate PFN :  0x%lx\n", pfn_period);
        LOG_INFO("       rate CL  :  0x%lx\n", push_period);
        LOG_INFO("[print_sys_counters] ===============================\n");

    }
    return 0;
}

// =================================================
//                      Main function 
// =================================================

int producer_func(int thread_id, 
        uint64_t* pci_vaddr, 
        sys_counters_t& sys_counters_curr, 
        cfg_t cfg, 
        bool no_algo, 
        bool no_migration, 
        uint32_t** hapb_buf_vaddr,
        uint64_t hapb_buf_paddr) {
    fpga_counters_t counter_curr, counter_record, counter_prev;
    unordered_map<uint64_t, uint64_t> migration_pfn;
    bool all_worker_alive = true;
    uint64_t pfn_period, push_period;

    set_default_counters(pci_vaddr, cfg.is_traffic);
    if (cfg.is_traffic) {
        if (cfg.is_traffic_rate > 0) {
            pfn_period = (cfg.is_traffic_rate | 0x80000000);
            push_period = cfg.is_traffic_rate >> 6;
            if (push_period < 128) push_period = 128;
            push_period |= 0x80000000;
            set_counters(pci_vaddr, pfn_period, push_period);
        } else {
            pfn_period = PFN_BASE_RATE_TRAFFIC;
            push_period = PUSH_BASE_RATE_TRAFFIC;
        }
    } else {
        pfn_period = PFN_BASE_RATE_CLK;
        push_period = PUSH_BASE_RATE_CLK;
    }
    set_counters(pci_vaddr, pfn_period, push_period);

    // HAPB
    uint64_t hapb_base_addr = hapb_buf_paddr;
    pci_vaddr_stop = pci_vaddr;
    uint64_t hapb_prev_count = 0;
    uint32_t* hapb_buf_vaddr_base = *hapb_buf_vaddr;
    //Repetition algo(cfg.look_back_hist);
    //Repetition algo(cfg.look_back_hist, 0);
    //PID algo(cfg.look_back_hist, 1, 1, 1, 100, PID::SCORE_GLOBAL);
    //PID algo(cfg.look_back_hist, 1, 1, 1, 100, PID::SCORE_LOCAL);
    //Pass algo(cfg.look_back_hist);
    Selection* algo;
    if (cfg.hwt_only) {
        algo = new HWT(cfg.look_back_hist);
    } else if (cfg.c2p_ratio > 0) {
        algo = new Filter(cfg.look_back_hist);
    } else {
        algo = new Pass(cfg.look_back_hist);

    }
    //set_default_counters(pci_vaddr, cfg.is_traffic);

    cout << "Producer thread " << thread_id << " is executing..." << endl;
    while (!stop_flag) {
        all_worker_alive = check_alive_worker();
        if (!all_worker_alive) {
            stop_all();
            break;
        }

        // S0 / S1 - fetch
        if (sys_counters_curr.prev_threshold > 0) {
            migration_pfn.clear();
            fetch_counters(pci_vaddr, 
                    counter_curr, 
                    counter_record, 
                    migration_pfn, 
                    cfg.wait_ms, 
                    cfg.c2p_ratio, 
                    MIGRATE_LIST_MAX_LEN,
                    cfg.hwt_only,
                    cfg.hapb,
                    hapb_base_addr,
                    hapb_buf_vaddr,
                    hapb_buf_vaddr_base,
                    hapb_prev_count);
        } else {
            migration_pfn.clear();
            //std::this_thread::sleep_for(std::chrono::milliseconds(100000));
            //stop_all();
            //goto out;
        }

        if (!no_algo) {
            // S2 / S3 ALGO 
            update_algo_structure(pci_vaddr, 
                    cfg.is_traffic, 
                    cfg.hwt_only,
                    cfg.base_freq,
                    cfg.ratio_power,
                    counter_curr, 
                    sys_counters_curr, 
                    migration_pfn, 
                    pfn_period,
                    push_period,
                    *algo);
        }

        // SHOW
        if (cfg.print_list) print_unordered_map(migration_pfn);
        if (cfg.print_counter) {
            print_counters(pci_vaddr, counter_curr, cfg.parsing_mode);
            print_sys_counters(sys_counters_curr, pfn_period, push_period, cfg.parsing_mode);
        }

        // SET
        // Release migration target to workers
        if (!no_migration) {
            sys_counters_curr.page_mig_cnt = issue_migraiton(migration_pfn);
        }

        // set rate for HPAT, HWAT
        counter_prev = counter_curr;

        if (cfg.c2p_ratio <= 0) {
            std::this_thread::sleep_for(std::chrono::milliseconds(cfg.wait_ms));
        }
    }

out:
    clean_up_algo_structure();
    delete algo;
    return 0;
}


void signal_handler(int signal) {
    if (signal == SIGINT) {
        std::cout << "Ctrl-C received. Stopping all threads..." << std::endl;
        stop_all();
    }
}


int start_worker_threads(int num_threads, cfg_t& cfg, uint64_t* pci_vaddr) {
    int ret;

    if (cfg.do_dump) {
        // first dir
        std::ostringstream oss;
        oss << "/offset_" << 0;
        string proc_file_path = string(cfg.dump_path);
        check_path_exist(cfg.dump_path);
        check_path_exist(proc_file_path.append(oss.str()).c_str());

        threads_vec.emplace_back(eac_func, cfg.dump_path, pci_vaddr, cfg.eac_m5);
        //
        workers.push_back(Worker(0));
        threads_vec.emplace_back(worker_dump_func, cfg.dump_path);

        ret = 0;
    } else {
        // Create and start threads
        ret = init_migration_ndoe(MIGRATION_TARGET_NODE, cfg.is_test);
        if (ret) return ret;
        for (int i = 0; i < num_threads; ++i) {
            workers.push_back(Worker(i));
            threads_vec.emplace_back(worker_func, i, cfg.is_test);
        }
    }
    cout << "All worker threads have [started]" << endl;
    return ret;
}

// Regular expression to match the lines with required values
std::regex socket0Regex(R"(Socket0: (\d+\.\d+))");
std::regex readRegex("System Read Throughput\\(MB/s\\):\\s+(\\d+\\.?\\d*)");
std::regex writeRegex("System Write Throughput\\(MB/s\\):\\s+(\\d+\\.?\\d*)");
void pcm_latency_extract(const std::string& input, sys_counters_t& sys_counters_curr) {
    std::smatch matches;
    std::istringstream stream(input);
    std::string line;
    bool l1CacheContext = false;
    while (std::getline(stream, line)) {
        // Check the context of the line
        if (line.find("L1 Cache Miss Latency") != std::string::npos) {
            l1CacheContext = true;
        } else if (line.find("DDR read Latency") != std::string::npos) {
            l1CacheContext = false;
        }

        // Search for "Socket0: <number>"
        if (std::regex_search(line, matches, socket0Regex) && !matches.empty()) {
            //double value = std::stof(matches[1].str());
            if (l1CacheContext) {
                sys_counters_curr.l1_lats = std::stof(matches[1].str());
            } else {
                sys_counters_curr.dram_lats = std::stod(matches[1].str());
            }
        }
    }
}

void pcm_memory_extract(const std::string& line, sys_counters_t& sys_counters_curr) {
    std::smatch match;
    if (std::regex_search(line, match, readRegex)) {
        sys_counters_curr.rd_bw = std::stof(match[1].str());
    }
    if (std::regex_search(line, match, writeRegex)) {
        sys_counters_curr.wr_bw = std::stof(match[1].str());
    }
}

void readZoneInfo(sys_counters_t* sys_counters_curr) {
    std::ifstream zoneinfoFile("/proc/zoneinfo");
    if (!zoneinfoFile.is_open()) {
        std::cerr << "Failed to open /proc/zoneinfo" << std::endl;
        return;
    }
    std::string line;
    std::regex nodeRegex(R"(Node\s+(\d+),\s+zone\s+Normal)");
    std::regex pagesFreeRegex(R"(\s+nr_zone_active_anon\s+(\d+))");

    int currentNode = -1;
    uint64_t val;
    while (std::getline(zoneinfoFile, line)) {
        std::smatch match;
        if (std::regex_search(line, match, nodeRegex)) {
            currentNode = std::stoi(match[1]);
        } else if (std::regex_search(line, match, pagesFreeRegex)) {
            if (currentNode < 0) continue;

            val = std::stoul(match[1]);
            if (currentNode == MIGRATION_TARGET_NODE) {
                sys_counters_curr->fast_util = (val * 4096) >> 20;
            } else if (currentNode == CXL_NODE) {
                sys_counters_curr->slow_util = (val * 4096) >> 20;
                break;
            }
            //std::cout << "NUMA Node: " << currentNode << ", act_anon: " << val << std::endl;
        }
    }
    zoneinfoFile.close();
}

int vmstat_sampler_thread(sys_counters_t* sys_counters_curr) {
    LOG_INFO("vmstat sampler started\n");
    while (!stop_flag) {
        LOG_DEBUG("Reading /proc/zoneinfo...\n");
        readZoneInfo(sys_counters_curr);
        std::this_thread::sleep_for(std::chrono::seconds(1));
    }
    return 0;
}

int pcm_sampler_thread_shmem(string cmd, sys_counters_t* sys_counters_curr) {
    LOG_INFO("pcm sampler started [shemem]\n");
    FILE* pipe = popen(cmd.c_str(), "r"); 
    if (!pipe) {
        std::cerr << "Failed to open pipe!" << std::endl;
        return 1;
    }

    memdata_t *md = openShmem();
    while (!stop_flag) {
        uint64_t ver = md->extra.Version;
        int stall_cnt = 0;
        while(ver == md->extra.Version && !stop_flag) {
            std::this_thread::sleep_for(std::chrono::milliseconds(10));
            stall_cnt++;
            if (stall_cnt > 10000) {
                cout << "ver stall" << endl;
                break;
            }
        }
        sys_counters_curr->rd_bw = md->iMC_Rd_socket[0];
    }
    cout <<  "shmem ending ... " << endl;
    pclose(pipe);
    cout <<  "shmem ending ok 1" << endl;
    closeShmem(md);
    cout <<  "shmem ending ok 2" << endl;
    return 0;
}

int pcm_sampler_thread(string cmd, sys_counters_t* sys_counters_curr) {
    std::array<char, 256> buffer;
    string result;
    cout << "Starting thead for " << cmd << endl;
    FILE* pipe = popen(cmd.c_str(), "r"); 
    bool is_latency;

    is_latency = cmd.find("memory") != std::string::npos;

    if (!pipe) {
        std::cerr << "Failed to open pipe!" << std::endl;
        return 1;
    }

    // Get the file descriptor from the FILE stream
    int fd = fileno(pipe);

    // Make the file descriptor non-blocking
    fcntl(fd, F_SETFL, O_NONBLOCK);

    // Use select() to wait for data to be available
    fd_set set;
    struct timeval timeout;

    while (!stop_flag) {
        FD_ZERO(&set);  // clear the set
        FD_SET(fd, &set);  // add our file descriptor to the set

        timeout.tv_sec = 5;  // timeout after 5 seconds
        timeout.tv_usec = 0;

        int rv = select(fd + 1, &set, NULL, NULL, &timeout);

        if (rv == -1) {
            perror("select\n");  // an error occured
            cout << "Ending thead for " << cmd << endl;
            break;
        } else if (rv == 0) {
            std::cout << "Timeout occurred! No data within 2 seconds." << std::endl;
        } else {
            if (FD_ISSET(fd, &set)) {
                ssize_t bytes_read = read(fd, buffer.data(), buffer.size() - 1);
                if (bytes_read > 0) {
                    buffer[bytes_read] = '\0';  // null terminate

                    if (is_latency) {
                        pcm_memory_extract(buffer.data(), *sys_counters_curr);
                    } else {
                        pcm_latency_extract(buffer.data(), *sys_counters_curr);
                    }
                }
                //cout << buffer.data() << endl;
            }
        }

        // Check if the command is still running
        if (feof(pipe)) {
            break;
        }
    }

    pclose(pipe);
    return 0;
}

int start_sampler_threads(sys_counters_t& sys_counters_curr) {
    int ret;
    ret = 0 ;
    //string pcm_memory_path = PCM_MEMORY_PATH;
    string pcm_memory_reduced_path = PCM_MEMORY_REDUCED_PATH;
    string pcm_latency_path = PCM_LATENCY_PATH;

    // pcm-latency
    //threads_vec.emplace_back(pcm_sampler_thread, pcm_latency_path, is_test,&sys_counters_curr);
    // wait
    //std::this_thread::sleep_for(std::chrono::milliseconds(3000));
    // pcm-memory
    //threads_vec.emplace_back(pcm_sampler_thread, pcm_memory_path, &sys_counters_curr);

    //threads_vec.emplace_back(pcm_sampler_thread_shmem, pcm_memory_reduced_path, &sys_counters_curr);
    // vmstat
    threads_vec.emplace_back(vmstat_sampler_thread, &sys_counters_curr);

    cout << "All threads have [started]" << endl;
    return ret;
}

void join_threads() {
    // Join threads with the main thread
    for (uint64_t i = 0; i < threads_vec.size(); ++i) {
        cout << "thread joining for " << i << endl;
        threads_vec[i].join();
        cout << "thread joining for [ok] " << i << endl;
    }
    cout << "All threads have [ended]" << endl;
}

int start_threads(int num_threads, uint64_t* pci_vaddr, cfg_t cfg, uint32_t** hapb_buf_vaddr, uint64_t hapb_buf_paddr) {
    int ret;
    bool no_algo = false;
    bool no_migration = false;
    sys_counters_t sys_counters_curr;
    sys_counters_curr = {0};
    sys_counters_curr.prev_threshold = THRESHOLD_PRECENTAGE;
    sys_counters_curr.stable_cnt = 0;
    move_accu = 0;
    last_print = 0;

    // register ctrl-c exit
    std::signal(SIGINT, signal_handler);

    // no_mig
    //      no worker, but do not assume sampler

    // eac_m5
    //      yes worker, yes sampler, no migration
    //      must used with -d

    // start worker
    //      dump + dmesg, yes worker, no sampler
    if (cfg.do_dump && !cfg.eac_m5) {
        LOG_INFO("dump dmesg in eac_func ...\n");
        ret = start_worker_threads(num_threads, cfg, pci_vaddr);
        no_algo = true;
        no_migration = false;

    //      output counter without migration. no worker, yes sampler  
    } else if (cfg.parsing_mode && cfg.no_mig) {
        LOG_INFO("Parsing mode without worker, monitoring only ...\n");
        no_algo = true;
        no_migration = true;

        ret = start_sampler_threads(sys_counters_curr);
        IF_FAIL_THEN_EXIT

    } else if (cfg.no_algo) {
        LOG_INFO("Static rate, do migration ...\n");
        no_algo = true;
        ret = start_worker_threads(num_threads, cfg, pci_vaddr);
        IF_FAIL_THEN_EXIT

        ret = start_sampler_threads(sys_counters_curr);
        IF_FAIL_THEN_EXIT

    //      ALL 
    } else {
        LOG_INFO("normal execution ...\n");
        ret = start_worker_threads(num_threads, cfg, pci_vaddr);
        IF_FAIL_THEN_EXIT

        ret = start_sampler_threads(sys_counters_curr);
        IF_FAIL_THEN_EXIT
    }

    // start producer, single producer for now
    //threads_vec.emplace_back(producer_func, 0, pci_vaddr, look_back_hist, wait_ms);
    producer_func(0, pci_vaddr, sys_counters_curr, cfg, no_algo, no_migration, hapb_buf_vaddr, hapb_buf_paddr);

    // join all
    join_threads();
    LOG_DEBUG("all thread joined, exiting ...");
    return ret;

FAILED:
    return -1;
}


