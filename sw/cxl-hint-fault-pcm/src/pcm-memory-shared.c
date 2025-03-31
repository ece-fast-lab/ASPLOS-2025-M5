// #include <unistd.h>
// #include <fcntl.h>
// #include <sys/shm.h>
// #include <semaphore.h>

#define FILENAME "/tmp/cxl-hint-fault-pcm"

constexpr uint32_t max_sockets = 256;
uint32_t max_imc_channels = ServerUncoreCounterState::maxChannels;
const uint32_t max_edc_channels = ServerUncoreCounterState::maxChannels;
const uint32_t max_imc_controllers = ServerUncoreCounterState::maxControllers;
bool SPR_CXL = false; // use SPR CXL monitoring implementation

typedef struct memdata {
    volatile double iMC_Rd_socket_chan[max_sockets][ServerUncoreCounterState::maxChannels]{};
    volatile double iMC_Wr_socket_chan[max_sockets][ServerUncoreCounterState::maxChannels]{};
    volatile double iMC_PMM_Rd_socket_chan[max_sockets][ServerUncoreCounterState::maxChannels]{};
    volatile double iMC_PMM_Wr_socket_chan[max_sockets][ServerUncoreCounterState::maxChannels]{};
    volatile double MemoryMode_Miss_socket_chan[max_sockets][ServerUncoreCounterState::maxChannels]{};
    volatile double iMC_Rd_socket[max_sockets]{};
    volatile double iMC_Wr_socket[max_sockets]{};
    volatile double iMC_PMM_Rd_socket[max_sockets]{};
    volatile double iMC_PMM_Wr_socket[max_sockets]{};
    volatile double CXLMEM_Rd_socket_port[max_sockets][ServerUncoreCounterState::maxCXLPorts]{};
    volatile double CXLMEM_Wr_socket_port[max_sockets][ServerUncoreCounterState::maxCXLPorts]{};
    volatile double CXLCACHE_Rd_socket_port[max_sockets][ServerUncoreCounterState::maxCXLPorts]{};
    volatile double CXLCACHE_Wr_socket_port[max_sockets][ServerUncoreCounterState::maxCXLPorts]{};
    volatile double MemoryMode_Miss_socket[max_sockets]{};
    volatile bool NM_hit_rate_supported{};
    volatile bool BHS_NM{};
    volatile bool BHS{};
    volatile double MemoryMode_Hit_socket[max_sockets]{};
    volatile bool M2M_NM_read_hit_rate_supported{};
    volatile double NM_hit_rate[max_sockets]{};
    volatile double M2M_NM_read_hit_rate[max_sockets][max_imc_controllers]{};
    volatile double EDC_Rd_socket_chan[max_sockets][max_edc_channels]{};
    volatile double EDC_Wr_socket_chan[max_sockets][max_edc_channels]{};
    volatile double EDC_Rd_socket[max_sockets]{};
    volatile double EDC_Wr_socket[max_sockets]{};
    volatile uint64_t partial_write[max_sockets]{};
    volatile ServerUncoreMemoryMetrics metrics{};

    volatile struct {
        double CXL_Read_BW;
        uint64_t Version;
    } extra{};
} memdata_t;

// Leader is the process that starts first
memdata_t *openShmem(void)
{
    int fd = creat(FILENAME, 0644);
    if (fd == -1) {
        cerr << "Unable to creat shmem file " << FILENAME << " with errno " << errno << "\n";
        return NULL;
    }
    close(fd);

    key_t key = ftok(FILENAME, 1);
    if (key == -1) {
        cerr << "Unable to ftok shmem file " << FILENAME << " with errno " << errno << "\n";
        return NULL;
    }
 
    int shmid = shmget(key, sizeof(memdata_t), 0666 | IPC_CREAT);
    if (shmid == -1) {
        cerr << "Unable to shmget shmem file " << FILENAME << " with errno " << errno << "\n";
        return NULL;
    }

    memdata_t *md = (memdata_t *) shmat(shmid, NULL, 0);
    if (md == (void *) -1) {
        cerr << "Unable to shmat shmem file " << FILENAME << " with errno " << errno << "\n";
        return NULL;
    }

    return md;
}

void closeShmem(memdata_t *md)
{
    if (shmdt(md)) {
        cerr << "Unable to shmdt shmem file " << FILENAME << " with errno " << errno << "\n";
    }
}
