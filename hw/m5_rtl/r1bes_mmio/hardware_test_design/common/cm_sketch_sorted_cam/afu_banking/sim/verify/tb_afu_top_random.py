import time
import math
import numpy as np
import sys


if __name__ == '__main__':

    if (len(sys.argv) != 5):
        print("Usage : python3 tb_afu_top_random.py W NUM_HASH NUM_ENTRY NUM_TRACE")
        exit()

    W = int(sys.argv[1])
    NUM_HASH = int(sys.argv[2])
    NUM_ENTRY = int(sys.argv[3])
    NUM_TRACE = int(sys.argv[4])

    ADDR_SIZE = 28
    CNT_SIZE = 32

    trace = np.loadtxt('rtrace.txt', dtype='int')
    hash = np.loadtxt("hash.txt", dtype='str', delimiter=" ")

    np.savetxt('rtrace_hex.txt', trace, fmt='%x')

    # CM-sketch initialize
    sketch = [[0] * W for _ in range(NUM_HASH)]
    hash_value = [0] * NUM_HASH
    
    # CAM initialize
    table = []
    hit = 0
    hit_index = 0
    insert_index = NUM_ENTRY

    for _ in range(NUM_ENTRY+1):
        table.append([0, 0])

    num_access = 0

    with open('answer.txt', 'w') as f:
        for i in range(0, NUM_TRACE):
            num_access += 1

            ###################################################################
            #################          CM-sketch          #####################
            ###################################################################
            addr = trace[i] >> 12
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
            
            ###################################################################
            ####################          CAM          ########################
            ###################################################################
            hit = 0
            insert_index = NUM_ENTRY 

            # addr CAM search
            for j in range (0, NUM_ENTRY):
                if (table[j][0] == addr):
                    hit = 1
                    hit_index = j
                    break
            
            # cnt CAM search
            for j in range (0, NUM_ENTRY): 
                if (min > table[j][1]):
                    insert_index = j
                    break
            
            # Insert
            if (hit):
                if (insert_index != NUM_ENTRY):
                    if (insert_index < hit_index):
                        for j in range (hit_index, insert_index, -1):
                            table[j][0] = table[j-1][0]
                            table[j][1] = table[j-1][1]
                        table[insert_index][0] = addr
                        table[insert_index][1] = min
                    elif (insert_index == hit_index):
                        table[insert_index][0] = addr
                        table[insert_index][1] = min
            else:
                if (insert_index != NUM_ENTRY):
                    for j in range (NUM_ENTRY-1, insert_index, -1):
                        table[j][0] = table[j-1][0]
                        table[j][1] = table[j-1][1]
                    table[insert_index][0] = addr
                    table[insert_index][1] = min                   
            
            # print
            f.write("///// Print Tracker table ({:>8d}) /////\n".format(num_access))
            for j in range (0, NUM_ENTRY):
                f.write("{:>3d}:  {:>5d}  {:0>7x}\n".format(j, table[j][1], table[j][0]))
            f.write("///////////////////////////////\n\n")