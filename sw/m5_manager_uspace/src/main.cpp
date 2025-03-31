#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <thread>
#include <vector>

#include "util.h"
#include "csr.h"
#include "worker.h"


int init(int* pci_fd, uint64_t** pci_vaddr) {
    int         init_ok;

    /* Initialize CSR access */
    init_ok = init_csr(pci_fd, &(*pci_vaddr));
    if (init_ok) {
        LOG_ERROR(" Failed with init csr.\n");
        goto FAILED;
    }
    return 0;

FAILED:
    return -1;
}

void set_default_cfg(cfg_t& cfg) {
    cfg.thread_cnt = 1;
    cfg.look_back_hist = 10;
    cfg.wait_ms = 1000;
    cfg.is_test = false;
    cfg.print_list = false;
    cfg.print_counter = false;
    cfg.c2p_ratio = 0;
    cfg.is_traffic = false;
    cfg.do_dump = false;
    cfg.parsing_mode = false;
    cfg.base_freq = PFN_BASE_FREQ;
    cfg.eac_m5 = false;
    cfg.no_mig = false;
    cfg.ratio_power = 3;
    cfg.hwt_only = false;
    cfg.no_algo = false;
    cfg.is_traffic_rate = -1;
}


int main(int argc, char **argv){
    uint64_t* pci_vaddr;
    int ret, pci_fd;
    cfg_t cfg;

    // arg parse? 
    set_default_cfg(cfg);
    ret = parse_arg(argc, argv, cfg);
    IF_FAIL_THEN_EXIT

    // init csr
    ret = init(&pci_fd, &pci_vaddr);
    IF_FAIL_THEN_EXIT
    
    // main thread logging
    // worker thread init 
    start_threads(cfg.thread_cnt, pci_vaddr, cfg); 

    // clean up
    clean_csr(pci_fd, pci_vaddr);
    LOG_INFO("Done.\n");
    return ret;
FAILED:
    LOG_ERROR(" Failure detected in main(), existing ... \n");
    return -1;
}
