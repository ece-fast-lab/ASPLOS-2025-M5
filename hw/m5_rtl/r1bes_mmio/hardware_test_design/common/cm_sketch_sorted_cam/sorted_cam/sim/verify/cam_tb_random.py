import time
import math
import numpy as np
import sys


if __name__ == '__main__':

    if (len(sys.argv) != 3):
        print("Usage : python3 cam_tb_random.py NUM_ENTRY NUM_TRACE")
        exit()

    NUM_ENTRY = int(sys.argv[1])
    NUM_TRACE = int(sys.argv[2])
    ADDR_SIZE = 28
    CNT_SIZE = 32

    addr_trace = np.loadtxt('addr_trace.txt', dtype='int')
    cnt_trace = np.loadtxt('cnt_trace.txt', dtype='int')

    table = []
    num_access = 0
    hit = 0
    hit_index = 0
    insert_index = NUM_ENTRY

    for _ in range(NUM_ENTRY+1):
        table.append([0, 0])

    with open('answer.txt', 'w') as f:
        for i in range(0, NUM_TRACE):
            num_access += 1
            hit = 0
            insert_index = NUM_ENTRY   

            # addr CAM search
            for j in range (0, NUM_ENTRY):
                if (table[j][0] == addr_trace[i]):
                    hit = 1
                    hit_index = j
                    break
            
            # cnt CAM search
            for j in range (0, NUM_ENTRY): 
                if (cnt_trace[i] > table[j][1]):
                    insert_index = j
                    break
            
            # Insert
            if (hit):
                if (insert_index != NUM_ENTRY):
                    if (insert_index < hit_index):
                        for j in range (hit_index, insert_index, -1):
                            table[j][0] = table[j-1][0]
                            table[j][1] = table[j-1][1]
                        table[insert_index][0] = addr_trace[i]
                        table[insert_index][1] = cnt_trace[i]
                    elif (insert_index == hit_index):
                        table[insert_index][0] = addr
                        table[insert_index][1] = min
            else:
                if (insert_index != NUM_ENTRY):
                    for j in range (NUM_ENTRY-1, insert_index, -1):
                        table[j][0] = table[j-1][0]
                        table[j][1] = table[j-1][1]
                    table[insert_index][0] = addr_trace[i]
                    table[insert_index][1] = cnt_trace[i]                    
            
            # print
            f.write("///// Print table ({:>8d}) /////\n".format(num_access))
            for j in range (0, NUM_ENTRY):
                f.write("{:>3d}:  {:>5d}  {:0>7x}\n".format(j, table[j][1], table[j][0]))
            f.write("///////////////////////////////\n\n")
            

    



