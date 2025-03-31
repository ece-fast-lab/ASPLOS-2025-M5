import time
import math
import numpy as np
import sys


if __name__ == '__main__':

    if (len(sys.argv) != 3):
        print("Usage : python3 rtrace_generator.py NUM_TRACE ADDR_RANGE")
        exit()

    NUM_TRACE = int(sys.argv[1])
    ADDR_RANGE = int(sys.argv[2])

    # Create random trace
    # np.random.seed(777)
    np.random.seed(int(time.time()))

    rtrace = np.random.randint(1, ADDR_RANGE + 1, size = NUM_TRACE)
    np.savetxt('rtrace.txt', rtrace, fmt='%d')