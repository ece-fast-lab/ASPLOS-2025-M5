#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <thread>
#include <vector>
#include <fcntl.h>
#include <sys/mman.h>

#include "util.h"
#include "csr.h"
#include "worker.h"


int init(int* pci_fd, uint32_t** hapb_buf_vaddr, uint64_t** pci_vaddr, uint64_t* buf_paddr) {
    int         kmod_fd;
    int         init_ok;
    ssize_t     bytes_read;
    uint64_t*   pci_vaddr_ptr;
    /* Initialize CSR access */
    init_ok = init_csr(pci_fd, &(*pci_vaddr));
    if (init_ok) {
        LOG_ERROR(" Failed with init csr.\n");
        goto FAILED;
    }
    pci_vaddr_ptr = *pci_vaddr;
    pci_vaddr_ptr[CSR_HAPB_HEAD] = 0;
    /* Get the physical address of buffer */
    LOG_INFO("Opening /proc/hapb_test ...\n");
    kmod_fd = open("/proc/hapb_test", O_RDWR); // FIXED: we can't open the file in read-only mode if we want to map it for both read and write
    if (kmod_fd == -1) {
        LOG_ERROR(" Failed with open kmod hapb\n");
        goto FAILED;
    }

    if ((bytes_read = read(kmod_fd, buf_paddr, sizeof(uint64_t))) < 0) {
        LOG_ERROR(" Read buf_paddr from proc file failed. Remember to use sudo. \n");
        goto FAILED;
    }

    pci_vaddr_ptr[CSR_HAPB_HEAD] = (*buf_paddr);
    LOG_INFO(" buf_paddr read from the proc is 0x%lx (size=%ld)\n", *buf_paddr, bytes_read);
    LOG_INFO(" pci_vaddr_ptr[CSR_HAPB_HEAD] = 0x%lx\n", pci_vaddr_ptr[CSR_HAPB_HEAD]);
    /* Map the contiguous buffer to user's memory space */
    *hapb_buf_vaddr = (uint32_t*)mmap(NULL, HAPB_BUF_SIZE, PROT_READ | PROT_WRITE, MAP_SHARED, kmod_fd, 0); 
    if(*hapb_buf_vaddr == (void *) -1){
        LOG_ERROR(" HAPB buffer mmap not successful. Found -1. buf size: %ld\n", HAPB_BUF_SIZE);
        goto FAILED;
    }
    if(*hapb_buf_vaddr == (void *) 0){
        LOG_ERROR(" HAPB buffer mmap not successful. Found 0.\n");
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
    cfg.do_dump = false;            // uses eac, turn off
    cfg.parsing_mode = false;
    cfg.base_freq = PFN_BASE_FREQ;
    cfg.eac_m5 = true;
    cfg.no_mig = false;
    cfg.ratio_power = 3;
    cfg.hwt_only = false;
    cfg.no_algo = false;
    cfg.hapb = false;
    cfg.is_traffic_rate = -1;
}


int main(int argc, char **argv){
    uint64_t* pci_vaddr;
    uint32_t* hapb_buf_vaddr;
    uint64_t buf_paddr;

    int ret, pci_fd;
    cfg_t cfg;

    // arg parse?
    set_default_cfg(cfg);
    ret = parse_arg(argc, argv, cfg);
    IF_FAIL_THEN_EXIT

    // init csr
    ret = init(&pci_fd, &hapb_buf_vaddr, &pci_vaddr, &buf_paddr);
    IF_FAIL_THEN_EXIT

    LOG_INFO("A: 0x%lx\n", hapb_buf_vaddr);
    LOG_INFO("B: 0x%lx\n", hapb_buf_vaddr + HAPB_BUF_SIZE);
    sleep(4);
    // main thread logging
    // worker thread init 
    start_threads(cfg.thread_cnt, pci_vaddr, cfg, &hapb_buf_vaddr, buf_paddr); 

    // clean up
    clean_csr(pci_fd, pci_vaddr);
    LOG_INFO("Done.\n");
    return ret;
FAILED:
    LOG_ERROR(" Failure detected in main(), existing ... \n");
    return -1;
}
