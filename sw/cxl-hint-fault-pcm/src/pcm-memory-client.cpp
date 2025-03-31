#include <iostream>

#include <unistd.h>
#include <fcntl.h>
#include <sys/shm.h>
#include <semaphore.h>

using namespace std;

class ServerUncoreCounterState
{
public:
    enum {
        maxControllers = 32,
        maxChannels = 32,
        maxCXLPorts = 6,
    };
    enum FreeRunningCounterID
    {
        ImcReads,
        ImcWrites,
        PMMReads,
        PMMWrites
    };
};

enum ServerUncoreMemoryMetrics
{
    PartialWrites,
    Pmem,
    PmemMemoryMode,
    PmemMixedMode
};

#include "pcm-memory-shared.c"

int main(int argc, char * argv[])
{
    (void) argc;
    (void) argv;

    memdata_t *md = openShmem();

    for (;;) {
        uint64_t ver = md->extra.Version;

        while(ver == md->extra.Version)
            asm volatile("pause");

        cout << md->iMC_Rd_socket[0] << endl;
    }

    closeShmem(md);

    return 0;
}
