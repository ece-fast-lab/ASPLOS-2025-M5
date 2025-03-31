import time
import math
import numpy as np
import sys


if __name__ == '__main__':

    if (len(sys.argv) != 4):
        print("Usage : python3 rtrace_generator.py NUM_TRACE ADDR_RANGE CNT_RANGE")
        exit()

    NUM_TRACE = int(sys.argv[1])
    ADDR_RANGE = int(sys.argv[2])
    CNT_RANGE = int(sys.argv[3])

    # Create random trace
    # np.random.seed(777)
    np.random.seed(int(time.time()))

    addr_trace = np.random.randint(1, ADDR_RANGE + 1, size = NUM_TRACE)
    cnt_trace = np.random.randint(1, CNT_RANGE + 1, size = NUM_TRACE)
    np.savetxt('addr_trace.txt', addr_trace, fmt='%d')
    np.savetxt('cnt_trace.txt', cnt_trace, fmt='%d')