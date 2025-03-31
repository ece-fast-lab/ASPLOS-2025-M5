#ifndef CSR_H
#define CSR_H

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

#define     CSR_MHZ         125000000

/* 
 *  =================================
 *         EAC counters / spec 
 *  =================================
 */
#define EAC_BUFFER_SIZE 1*1024*1024 // 1MB region
#define EAC_COUNTER_WIDTH           8
#define CSR_EAC_ZERO_OUT            34
#define CSR_EAC_BUFF_OFFSET         33
// reading 1MB offset of the CSR buff, in 64bit
#define CSR_EAC_BUFF_READ_OFFSET    131072

/* 
 *  =================================
 *         MMIO for monitoring status
 *  =================================
 */
#define     CSR_CLOCK           0
#define     CSR_READ_CNT        1
#define     CSR_WRITE_CNT       2
#define     CSR_PFN_CNT         3
#define     CSR_PUSH_CNT        4

/* 
 *  =================================
 *         MMIO for setting interval
 *  =================================
 */
#define     CSR_PFN_RATE        8
#define     CSR_PUSH_RATE       9

/* 
 *  =================================
 *         MMIO for fetching PFN
 *  =================================
 */
#define     CSR_PFN_QUEUE_OFFSET    4096
#define     CSR_QUEUE_LEN   6
#define     CSR_PFN_QUEUE_RESET 11

#define     CSR_CL_QUEUE_OFFSET     8192
#define     CSR_QUEUE_LEN   6
#define     CSR_CL_QUEUE_RESET  17

#define     CSR_PUSH_DEBUG_ADDR 12
#define     CSR_PUSH_DEBUG_EN   13

#define     CSR_HAPB_HEAD       24
#define     CSR_HAPB_VALID_CNT  25
/* 
 *  =================================
 *         Interface to migrate 
 *  =================================
 */
// Need to test with 6.5-cxl-mig+ kernel

// unit = Do op after X number of request
// 5 / ?us 
//#define     PFN_BASE_RATE_CLK      5000 
// -- M5 algo base config
//#define     PFN_BASE_RATE_CLK      1000 
//#define     PUSH_BASE_RATE_CLK      (PFN_BASE_RATE_CLK / 64)
// 5 /  ?
//#define     PFN_BASE_RATE_CLK     80000 
// 5 / 250us 
//#define     PFN_BASE_RATE       100000 
// 5 / 500us
//#define     PFN_BASE_RATE       200000 
// 5 / 1ms
//#define     PFN_BASE_RATE       400000 
// 1 / 1ms
//#define     PFN_BASE_RATE       2000000 
// query / 1ms
//#define     PFN_BASE_RATE_CLK     125000 
// query / 10ms
#define     PFN_BASE_RATE_CLK       1250000 
#define     PUSH_BASE_RATE_CLK      (PFN_BASE_RATE_CLK / 64)

// 4096
//#define     PFN_BASE_RATE_TRAFFIC    0x80000FFF
//#define     PUSH_BASE_RATE_TRAFFIC   0x8000003F
//
// 6000
//#define     PFN_BASE_RATE_TRAFFIC    (0x80000000 + 6000)
//#define     PUSH_BASE_RATE_TRAFFIC   (0x80000000 + ((PFN_BASE_RATE_TRAFFIC & 0x7FFFFFFF) >> 6))

// 8192
#define     PFN_BASE_RATE_TRAFFIC    0x80001FFF
#define     PUSH_BASE_RATE_TRAFFIC   0x8000007F

// 16384
//#define     PFN_BASE_RATE_TRAFFIC    0x80003FFF
//#define     PUSH_BASE_RATE_TRAFFIC   0x800000FF

// 65536 
//#define     PFN_BASE_RATE_TRAFFIC    0x8000FFFF
//#define     PUSH_BASE_RATE_TRAFFIC   0x800003FF


// ============== freq hack
#define     PFN_BASE_FREQ               10000 

/* 
 *  =================================
 *         M5 FPGA / device specifics 
 *  =================================
 */
#define CXL_NODE_START_ADDR     0xA000000000 
#define M5_DEVICE_PF_ADDR       0x22feffa00000
#define M5_DEVICE_PF_SIZE       0x400000

#define CXL_NODE                2
#define CXL_MEM_PFN_BEGIN       0xA080000
//#define CXL_MEM_PFN_BEGIN       (0xA080000 + ((4UL << 30) >> 12))
#define CXL_MEM_NUM_PFN         2097152 // 8GB / 4096B

#define MIGRATE_LIST_MAX_LEN    (1 << 11) // 2048, just in case overflow
#define BITS_PER_BYTE           8

#define HAPB_BUF_SIZE           64*1024

// SPR3 socket 1
//#define CXL_PCIE_BAR_PATH  "/sys/devices/pci0000:98/0000:98:00.1/resource2"
// SPR3 socket 0
#define CXL_PCIE_BAR_PATH  "/sys/devices/pci0000:27/0000:27:00.1/resource2"

typedef struct fpga_counters {
    uint64_t clock;
    uint64_t read;
    uint64_t write;    
    uint64_t rd_bw;
    uint64_t wr_bw;
    uint64_t queue_len;
    uint64_t push_cnt;
    uint64_t pfn_cnt;
} fpga_counters_t;

int init_csr(int* pci_fd, uint64_t** pci_vaddr);

int clean_csr(int pci_fd, uint64_t* pci_vaddr);

int fetch_counters(uint64_t* pci_vaddr, 
        fpga_counters_t& counter_curr, 
        fpga_counters_t& counter_record, 
        unordered_map<uint64_t, uint64_t>& migration_pfn, 
        int wait_ms,
        int c2p_ratio, 
        int list_max_len,
        bool hwt_only,
        bool hapb_enabled,
        uint64_t hapb_base_addr,
        uint32_t** hapb_buf_vaddr,
        uint32_t* hapb_buf_vaddr_base,
        uint64_t& hapb_prev_count);

int set_default_counters(uint64_t* pci_vaddr, bool is_traffic);

int set_counters(uint64_t* pci_vaddr, uint64_t& pfn_rate, uint64_t& push_rate);

int print_counters(uint64_t* pci_vaddr, fpga_counters_t& counter_curr, bool parsing_mode);

int fetch_migrate_list_cl_only(fpga_counters_t& counter_curr, 
        uint64_t* pci_vaddr,
        unordered_map<uint64_t, uint64_t>& migration_pfn, 
        int wait_ms,
        int c2p_ratio,
        int list_max_len);

int fetch_migrate_list(fpga_counters_t& counter_curr, 
        uint64_t* pci_vaddr,
        unordered_map<uint64_t, uint64_t>& migration_pfn, 
        int wait_ms,
        int c2p_ratio,
        int list_max_len);

int fetch_migrate_list_hapb(fpga_counters_t& counter_curr, 
        uint64_t* pci_vaddr,
        unordered_map<uint64_t, uint64_t>& migration_pfn, 
        int wait_ms,
        int c2p_ratio,
        int list_max_len,
        uint64_t hapb_base_addr,
        uint32_t** hapb_buf_vaddr,
        uint32_t* hapb_buf_vaddr_base,
        uint64_t& hapb_prev_count);

int dump_eac_buff(uint64_t* pci_vaddr, const char* out_path);

int start_zeroout(uint64_t* pci_vaddr);

static inline uint64_t rdtsc_start(void);
static inline uint64_t rdtsc_end(void);

#endif // CSR_H
