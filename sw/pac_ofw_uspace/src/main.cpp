#include <stdio.h>
#include <stdlib.h>
#include <sys/types.h>
#include <unistd.h>
#include <thread>
#include <vector>
#include <fcntl.h>
#include <sys/mman.h>
#include <cstring> // Required for memset

#include "util.h"
#include "csr.h"
#include "worker.h"

#define SLEEP_SEC 1

int init(int* pci_fd, uint64_t** pci_vaddr, 
            uint32_t** pac_ofw_buf_vaddr, uint64_t* pac_ofw_buf_paddr) {

    int         kmod_fd_dst, kmod_fd_src;
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

    if (RESET_HEAD) {
        pci_vaddr_ptr[CSR_PAC_OFW_BUF_HEAD] = 0;
    }
    // pac_ofw_buf
    /* Get the physical address of buffer */
    LOG_INFO("Opening /proc/pac_ofw_buf ...\n");
    kmod_fd_dst = open("/proc/pac_ofw_buf", O_RDWR); // FIXED: we can't open the file in read-only mode if we want to map it for both read and write
    if (kmod_fd_dst == -1) {
        LOG_ERROR(" Failed with open kmod pac_ofw_buf\n");
        goto FAILED;
    }
    if ((bytes_read = read(kmod_fd_dst, pac_ofw_buf_paddr, sizeof(uint64_t))) < 0) {
        LOG_ERROR(" Read pac_ofw_buf_paddr from proc file failed. Remember to use sudo. \n");
        goto FAILED;
    }
    // TODO READ DATA HERE FIRST


    LOG_INFO(" pac_ofw_buf_paddr read from the proc is 0x%lx (size=%ld)\n", *pac_ofw_buf_paddr, bytes_read);
    LOG_INFO(" pci_vaddr_ptr[CSR_PAC_OFW_BUF_HEAD] = 0x%lx\n", pci_vaddr_ptr[CSR_PAC_OFW_BUF_HEAD]);
    /* Map the contiguous buffer to user's memory space */
    *pac_ofw_buf_vaddr = (uint32_t*)mmap(NULL, BUF_SIZE_BYTE/*32*16/8*/, PROT_READ | PROT_WRITE, MAP_SHARED, kmod_fd_dst, 0); 
    if(*pac_ofw_buf_vaddr == (void *) -1){
        LOG_ERROR(" PAC_OFW buffer mmap not successful. Found -1. buf size: %d\n", BUF_SIZE_BYTE/*32*16/8*/);
        goto FAILED;
    }
    if(*pac_ofw_buf_vaddr == (void *) 0){
        LOG_ERROR(" PAC_OFW buffer mmap not successful. Found 0.\n");
        goto FAILED;
    }
    pci_vaddr_ptr[CSR_PAC_OFW_BUF_MAX] = BUF_SIZE_BYTE / 64; // 4 * 64 = 256
    memset(*pac_ofw_buf_vaddr, 0, BUF_SIZE_BYTE);

// Reset all src/dst addresses
    for (int i = 0; i < BUF_SIZE_BYTE / sizeof(uint32_t); i++) {
        (*pac_ofw_buf_vaddr)[i] = 0;
    }
    if (RESET_HEAD) {
        pci_vaddr_ptr[CSR_PAC_OFW_BUF_HEAD] = (*pac_ofw_buf_paddr);
    }
    LOG_INFO(" pci_vaddr_ptr[CSR_PAC_OFW_BUF_HEAD] = 0x%lx\n", pci_vaddr_ptr[CSR_PAC_OFW_BUF_HEAD]);

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
    cfg.eac_m5 = false;
    cfg.no_mig = false;
    cfg.ratio_power = 3;
    cfg.hwt_only = false;
    cfg.no_algo = false;
    cfg.hapb = false;
    cfg.is_traffic_rate = -1;
}

int main(int argc, char **argv){
    uint64_t* pci_vaddr;
    uint64_t pac_ofw_buf_paddr;
    uint32_t* pac_ofw_buf_vaddr;

    int ret, pci_fd;
    cfg_t cfg;

    // arg parse?
    set_default_cfg(cfg);
    ret = parse_arg(argc, argv, cfg);
    IF_FAIL_THEN_EXIT

    // init csr
    ret = init(&pci_fd, &pci_vaddr, &pac_ofw_buf_vaddr, &pac_ofw_buf_paddr);
    IF_FAIL_THEN_EXIT

    // main thread logging
    // worker thread init 
    start_threads(cfg.thread_cnt, pci_vaddr, cfg, pac_ofw_buf_paddr, pac_ofw_buf_vaddr); 

    // clean up
    clean_csr(pci_fd, pci_vaddr);
    LOG_INFO("Done.\n");
    return ret;
// FAILED:
    LOG_ERROR(" Failure detected in main(), existing ... \n");
    return -1;
}
