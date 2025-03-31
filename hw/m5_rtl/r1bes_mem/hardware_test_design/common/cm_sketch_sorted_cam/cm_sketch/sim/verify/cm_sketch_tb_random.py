import time
import math
import numpy as np
import sys


if __name__ == '__main__':

    if (len(sys.argv) != 4):
        print("Usage : python3 cm_sketch_tb_random.py NUM_HASH W NUM_TRACE")
        exit()

    NUM_HASH = int(sys.argv[1])
    W = int(sys.argv[2])
    NUM_TRACE = int(sys.argv[3])
    #ADDR_RANGE = int(sys.argv[4])
    ADDR_SIZE = 28
    CNT_SIZE = 32

    trace = np.loadtxt('rtrace.txt', dtype='int')
    hash = np.loadtxt("hash.txt", dtype='str', delimiter=" ")

    #for i in range(len(hash)):
    #    for j in range(len(hash[i])):
    #        hash[i][j] = hex(int(hash[i][j], 16))

    sketch = [[0] * W for _ in range(NUM_HASH)]
    hash_value = [0] * NUM_HASH
    num_access = 0

    with open('answer.txt', 'w') as f:
        for i in range(0, NUM_TRACE):
            num_access += 1
            addr = trace[i]
            for j in range(0, NUM_HASH):
                if (addr & 0x0001):
                    hash_value[j] = int(hash[j][0], 16)
                else:
                    hash_value[j] = 0                
                for k in range(1, 32):
                    if((addr >> k) & 0x0001):
                        hash_value[j] = hash_value[j] ^ int(hash[j][k], 16)
                    else:
                        hash_value[j] = hash_value[j] ^ 0x0000

            for j in range (0, NUM_HASH):
                sketch[j][hash_value[j]] += 1

            min = sketch[0][hash_value[0]]
            for j in range (1, NUM_HASH):
                if (sketch[j][hash_value[j]] < min):
                    min = sketch[j][hash_value[j]]
            
            # print
            #f.write("Hash value of addr {:>5d} is: ".format(addr))

            #for j in range (0, NUM_HASH):
            #    f.write("{:>5d},".format(hash_value[j]))
            #f.write("\n")
            #f.write("///// Hash table ({:>8d}) /////\n".format(num_access))
            #for j in range (0, NUM_HASH):
            #    for k in range (0, W):
            #        f.write("{:>5d},".format(sketch[j][k]))
            #    f.write("\n")
        
            f.write("count of addr {:>5d} is: {:>5d}\n".format(addr, min))
            #f.write("\n")
                
            

    



