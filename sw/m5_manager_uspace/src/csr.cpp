#include <stdio.h>
#include <sys/mman.h>
#include <fcntl.h>
#include <unistd.h>
#include <stdarg.h>
#include "util.h"
#include "csr.h"
#include <math.h>

// --- if defined, we will fetch the real 
//  h_pfn list from FPGA
#define FETCH_REAL_LIST

/**
 * init_csr
 *   @brief Open the PCIe file and map to virtual memory
 *   @param pci_fd the pointer to the variable that will take the return value of fd
 *   @param pci_vaddr the pointer to the variable that will take the return value of mapped virtual address
 *   @return 0 means succedded, -1 means failed
 */
int init_csr(int *pci_fd, uint64_t **pci_vaddr) {

    uint64_t *ptr;
    int fd;

    fd = open(CXL_PCIE_BAR_PATH, O_RDWR | O_SYNC);
    if(fd == -1){
        LOG_ERROR(" Open BAR2 failed.\n");
        return -1;
    }
    LOG_INFO(" PCIe File opened.\n");

    ptr = (uint64_t*)mmap(0, (1 << 21), PROT_READ | PROT_WRITE, MAP_SHARED, fd, 0);
    if(ptr == (void *) -1){
        LOG_ERROR(" PCIe Device mmap not successful. Found -1.\n");
        close(fd);
        return -1;
    }
    if(ptr == (void *) 0){
        LOG_ERROR(" PCIe Device mmap not successful. Found 0.\n");
        close(fd);
        return -1;
    }

    LOG_INFO(" PCIe Device mmap succeeded.\n");
    LOG_INFO(" PCIe Memory mapped to address 0x%016lx.\n", (unsigned long) ptr);

    *pci_fd = fd;
    *pci_vaddr = ptr;

    return 0;
}

uint64_t access_cnt_to_MB(uint64_t cnt, uint64_t clk_tick, uint64_t clk_rate) {
    uint64_t ret;
    if (clk_tick == 0) return 0;
    ret = (cnt * 64 * clk_rate / clk_tick / 10000) >> 20;
    return ret; 
}

int fetch_counters(uint64_t* pci_vaddr, 
        fpga_counters_t& counter_curr, 
        fpga_counters_t& counter_record, 
        unordered_map<uint64_t, uint64_t>& migration_pfn, 
        int wait_ms,
        int c2p_ratio, 
        int list_max_len,
        bool hwt_only) {
    if (pci_vaddr == 0) { LOG_ERROR("[fetch_counters] void CSR addr\n"); return -1; }

    uint64_t clk, read_cnt, write_cnt, push_cnt, pfn_cnt;
    int num_valid_pfn;

    clk = pci_vaddr[CSR_CLOCK];
    read_cnt = pci_vaddr[CSR_READ_CNT];
    write_cnt = pci_vaddr[CSR_WRITE_CNT];
    push_cnt = pci_vaddr[CSR_PUSH_CNT];
    pfn_cnt = pci_vaddr[CSR_PFN_CNT];


    // calculate delta for these counters
    counter_curr.clock = clk - counter_record.clock;
    counter_curr.read = read_cnt - counter_record.read; 
    counter_curr.write = write_cnt - counter_record.write;
    counter_curr.push_cnt = push_cnt - counter_record.push_cnt;
    counter_curr.pfn_cnt = pfn_cnt - counter_record.pfn_cnt;

    counter_curr.rd_bw = access_cnt_to_MB(counter_curr.read, 
                                                counter_curr.clock,
                                                CSR_MHZ);
    counter_curr.wr_bw = access_cnt_to_MB(counter_curr.write, 
                                                counter_curr.clock,
                                                CSR_MHZ);

    // done with delta, prepare for the next delta
    counter_record.clock = clk;
    counter_record.read = read_cnt; 
    counter_record.write = write_cnt;
    counter_record.push_cnt = push_cnt;
    counter_record.pfn_cnt = pfn_cnt;

    // get migration list info, set len / head immediately after
    counter_curr.queue_len = (pci_vaddr[CSR_QUEUE_LEN] >> 32) & 0x3FF;
    if (hwt_only){ 
        num_valid_pfn = fetch_migrate_list_cl_only(counter_curr, pci_vaddr, migration_pfn, wait_ms, c2p_ratio, list_max_len);
    } else {
        num_valid_pfn = fetch_migrate_list(counter_curr, pci_vaddr, migration_pfn, wait_ms, c2p_ratio, list_max_len);
    }
    return num_valid_pfn;
}

int print_counters(uint64_t* pci_vaddr, fpga_counters_t& counter_curr, bool parsing_mode) {
    if (pci_vaddr == 0) { LOG_ERROR("[print_counters] void CSR addr\n"); return -1; }
    if (parsing_mode) {
        cout << counter_curr.clock << ",";
        cout << counter_curr.rd_bw << ",";
        cout << counter_curr.wr_bw << ",";
        cout << counter_curr.queue_len << ","; // assuming sys counter do enld;
    } else {
        LOG_INFO("[print_counters] ===============================\n");
        LOG_INFO("       clock: 0x%lx\n", counter_curr.clock);
        LOG_INFO("       read:  %ld, %ld MB/s\n", counter_curr.read, counter_curr.rd_bw);
        LOG_INFO("       write: %ld, %ld MB/s\n", counter_curr.write, counter_curr.wr_bw);
        LOG_INFO("       q_len: %ld, after fetch: %ld\n", counter_curr.queue_len, (pci_vaddr[CSR_QUEUE_LEN] >> 32) & 0x3FF);
        LOG_INFO("       pfn_cnt : %ld, total: %ld\n", counter_curr.pfn_cnt, pci_vaddr[CSR_PFN_CNT]);
        LOG_INFO("       push_cnt: %ld, total: %ld\n", counter_curr.push_cnt, pci_vaddr[CSR_PUSH_CNT]);
        LOG_INFO("[print_counters] ===============================\n");
    }
    return 0;
}


int set_default_counters(uint64_t* pci_vaddr, bool is_traffic) {
    if (pci_vaddr == 0) { LOG_ERROR("[set_default_counters] void CSR addr\n"); return -1; }
    if (is_traffic) {
        pci_vaddr[CSR_PFN_RATE] = PFN_BASE_RATE_TRAFFIC;
        pci_vaddr[CSR_PUSH_RATE] = PFN_BASE_RATE_TRAFFIC;
    } else {
        pci_vaddr[CSR_PFN_RATE] = PFN_BASE_RATE_CLK;
        pci_vaddr[CSR_PUSH_RATE] = PUSH_BASE_RATE_CLK;
    }
    return 0;
}

int rate_array_idx = 5;
#define RATE_ARR_LEN 11
// 200MB - 20MB
uint64_t pfn_rate_arr[RATE_ARR_LEN] = {
    39063, 43403,
    48828, 55804,
    65104, 78125,
    97656, 130208,
    195313, 390625, 0
};
uint64_t push_rate_arr[RATE_ARR_LEN] = {
    2441, 2713,
    3052, 3488,
    4069, 4883,
    6104, 8138,
    12207, 24414, 0
};

int set_counters(uint64_t* pci_vaddr, uint64_t& pfn_rate, uint64_t& push_rate) {
    if (pci_vaddr == 0) { LOG_ERROR("[set_counters] void CSR addr\n"); return -1; }
    pci_vaddr[CSR_PFN_RATE] = pfn_rate;
    pci_vaddr[CSR_PUSH_RATE] = push_rate;

    // TODO
    return 0;
}

/**
 * clean_csr
 *   @brief Close the PCIe file and unmap the virtual memory
 *   @param pci_fd  the opened PCIe file
 *   @param pci_vaddr the mapped virtual address
 *   @return 0 means succedded, -1 means failed
 */
int clean_csr(int pci_fd, uint64_t *pci_vaddr) {

    int ret;
    LOG_DEBUG("clear csr\n");
    
    ret = munmap(pci_vaddr, 4096); 
    if (ret < 0) {
        LOG_ERROR(" mummap not successful.\n");
        return -1;
    }
    close(pci_fd);
    
    return 0;
}

#ifndef FETCH_REAL_LIST
int prev_fetch_offset = 0;
#endif

int fetch_migrate_list_cl_only(fpga_counters_t& counter_curr, 
        uint64_t* pci_vaddr,
        unordered_map<uint64_t, uint64_t>& migration_pfn, 
        int wait_ms,
        int c2p_ratio,
        int list_max_len) {

    std::chrono::microseconds sleep_us(1000);
    if (c2p_ratio > 0) {
        sleep_us = std::chrono::microseconds(wait_ms * 1000 / c2p_ratio); 
    }
    uint64_t current_pfn, current_cl, cl_mask;
    uint64_t cl_queue_len;
    uint64_t valid_cnt = 0;
    // fetch hot cacheline for hot pfn 
    for (int j = 0; j < c2p_ratio; j++) {
        cl_queue_len = pci_vaddr[CSR_QUEUE_LEN] & 0x1FFF;
        if (valid_cnt < 2048) {
            for (uint64_t i = 0; i < cl_queue_len; i++) {
                current_cl = (pci_vaddr[CSR_CL_QUEUE_OFFSET + i]);
                current_pfn = current_cl >> 12;

                if (migration_pfn.find(current_pfn) == migration_pfn.end()) {
                    migration_pfn[current_pfn] = 0;
                    valid_cnt++;
                }
                // Extract cl position in a page
                current_cl >>= 6;
                current_cl &= 0x3F; // 64 CL per page
                cl_mask = (1 << current_cl);
                migration_pfn[current_pfn] |= cl_mask;
            }
            LOG_DEBUG("S2: CL queue_len =  %ld\n", cl_queue_len);
        }
        pci_vaddr[CSR_CL_QUEUE_RESET] = 1;
        std::this_thread::sleep_for(sleep_us);
    }
    LOG_DEBUG("S2: CL only, size =  %ld\n", migration_pfn.size());

    // another filter for bit mask bit count threshold?
    return migration_pfn.size();
}

int fetch_migrate_list(fpga_counters_t& counter_curr, 
        uint64_t* pci_vaddr,
        unordered_map<uint64_t, uint64_t>& migration_pfn, 
        int wait_ms,
        int c2p_ratio,
        int list_max_len) {

    std::chrono::microseconds sleep_us(1000);
    if (c2p_ratio > 0) {
        sleep_us = std::chrono::microseconds(wait_ms * 1000 / c2p_ratio); 
    }
#ifdef FETCH_REAL_LIST
    uint64_t current_pfn, current_cl, cl_mask;
    // fetching the pfn list
    for (int i = 0; i < list_max_len && i < counter_curr.queue_len; i++) {
        current_pfn = (pci_vaddr[CSR_PFN_QUEUE_OFFSET + i] & 0xFFFFFFFF);
        if (current_pfn != 0) {
            migration_pfn[current_pfn] = 1;
        }
    }
    pci_vaddr[CSR_PFN_QUEUE_RESET] = 1;
    LOG_DEBUG("S2: done fetch pfn, queue len: %ld\n", counter_curr.queue_len);

    // align cacheline with the hot pfn 
    int hit_cnt = 0;
    int unique_hit = 0;
    uint64_t cl_queue_len;
    for (int j = 0; j < c2p_ratio; j++) {
        cl_queue_len = pci_vaddr[CSR_QUEUE_LEN] & 0x1FFF;
        for (uint64_t i = 0; i < cl_queue_len; i++) {
            current_cl = (pci_vaddr[CSR_CL_QUEUE_OFFSET + i]);
            current_pfn = current_cl >> 12;

            if (migration_pfn.find(current_pfn) != migration_pfn.end()) {
                if (migration_pfn[current_pfn] == 0) unique_hit++;
                /*
                // Extract cl position in a page
                current_cl >>= 6;
                current_cl &= 0x3F; // 64 CL per page
                cl_mask = (1 << current_cl);
                migration_pfn[current_pfn] |= cl_mask;
                */
                migration_pfn[current_pfn] <<= 2;
                hit_cnt++;
            } else {
                migration_pfn[current_pfn] = 1;
            }
        }
        //LOG_DEBUG("cl queue len: %ld\n", cl_queue_len);
        pci_vaddr[CSR_CL_QUEUE_RESET] = 1;
        std::this_thread::sleep_for(sleep_us);
    }
    //if (c2p_ratio > 0) LOG_DEBUG("S2: c2p hit count: %d, sleep us: %ld\n", hit_cnt, sleep_us.count());
    if (c2p_ratio > 0) LOG_DEBUG("S2: c2p hit count: %d, unique hit: %d\n", hit_cnt, unique_hit);
#else
    // if fetching list to debug, ignore c2p_ratio for now
    if (prev_fetch_offset > CXL_MEM_NUM_PFN) prev_fetch_offset = 0;
    for (int i = 0; i < list_max_len; i++) {
        migration_pfn[CXL_MEM_PFN_BEGIN + (++prev_fetch_offset)] = 0;
    }
    
#endif //FETCH_REAL_LIST
    return migration_pfn.size();
}

int dump_eac_buff(uint64_t* pci_vaddr, const char* out_path) {

    FILE*       out_fd;
    int         non_zero_cnt = 0;
    uint64_t    val_pack;
    int         val;

    /* Open the output file */
    if (out_path == NULL) {
        return -1;
    } 
    out_fd = fopen(out_path, "w");
    
    if (out_fd == NULL) {
        LOG_ERROR("[ERROR] Can't open output file %s.\n", out_path);
        return -1;
    }

    /* Read out the counter values */
    for (uint64_t csr_region = 0; csr_region < 2; csr_region++){ // loop through the 4MB counter buffer (2MB for 8bit counter), 1MB each time

        LOG_INFO("[INFO] Set CSR writeback region to %ld\n", csr_region);
        *(pci_vaddr + CSR_EAC_BUFF_OFFSET) = csr_region;

        for (int i = 0; i < EAC_BUFFER_SIZE / 8; i++) { // loop through each 64-bit in the CSR address space (1MB)

            val_pack = *(pci_vaddr + CSR_EAC_BUFF_READ_OFFSET + i);

            for (int k = 0; k < 64/EAC_COUNTER_WIDTH; k++){ // counter is 4-bit wide

                val = (val_pack >> (EAC_COUNTER_WIDTH*k)) & ((1 << EAC_COUNTER_WIDTH) - 1);
                if (val > 0) {
                    non_zero_cnt++;
                    fprintf(out_fd, "%lx %x\n", csr_region * (EAC_BUFFER_SIZE*8/EAC_COUNTER_WIDTH) + i * (64/EAC_COUNTER_WIDTH) + k, val);
                }
            }
        }
    }
    fclose(out_fd);
    LOG_INFO("[INFO] Dumping finished. Non-zero count: %d\n", non_zero_cnt);
    return 0;
}

/**
 * start_zeroout
 *   @brief Start to zero out the contents inside counter buffer. Currently you 
 *          need to wait for 1 sec to make sure this process completes.
 *   @param pci_vaddr the mapped virtual address
 *   @return 0 means succedded, -1 means failed
 */
int start_zeroout(uint64_t* pci_vaddr) {
    if (pci_vaddr == NULL) return -1;
    *(pci_vaddr + CSR_EAC_ZERO_OUT) = 1;
    LOG_DEBUG("zero-out ok\n");
    return 0;
}
