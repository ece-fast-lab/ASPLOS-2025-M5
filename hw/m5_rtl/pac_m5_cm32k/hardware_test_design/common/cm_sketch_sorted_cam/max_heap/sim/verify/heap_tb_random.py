import time
import math
import numpy as np

TOTAL_LEVEL = 6

NUM_ENTRY = (2 ** TOTAL_LEVEL) - 1
ADDR_RANGE = 10000
CNT_RANGE = 1000
TRACE_SIZE = 100
#TRACE_SIZE = 65 # for simple_trace.txt

TOP_K = 50

if __name__ == '__main__':

    # Create random trace
    # np.random.seed(777)
    np.random.seed(int(time.time()))

    addr_trace = np.random.randint(1, ADDR_RANGE + 1, size = TRACE_SIZE)
    cnt_trace = np.random.randint(1, CNT_RANGE + 1, size = TRACE_SIZE)

    np.savetxt('addr_trace.txt', addr_trace, fmt='%d')
    np.savetxt('cnt_trace.txt', cnt_trace, fmt='%d')

    addr_trace = np.loadtxt('addr_trace.txt', dtype='int')
    cnt_trace = np.loadtxt('cnt_trace.txt', dtype='int')
    #cnt_trace = np.loadtxt('simple_trace.txt', dtype='int')

    # initialize
    heap = []
    wcnt = []
    waddr = []
    for _ in range(NUM_ENTRY+1):
        heap.append([0, 0])

    for _ in range(TOTAL_LEVEL+1):
        wcnt.append(0)
        waddr.append(0)

    num_access = 0
    heap_element_cnt = 0

    with open('answer.txt', 'w') as f:
        for i in range(0, TRACE_SIZE):
            num_access += 1

            insert_path = heap_element_cnt + 1 - (2 ** math.floor(math.log2(heap_element_cnt + 1)))
            if (heap_element_cnt == NUM_ENTRY):
                insert_path = NUM_ENTRY

            #if (num_access == TRACE_SIZE):
            f.write("///// Print heap ({:>8d}) /////\n".format(num_access))

            if (heap_element_cnt == 0):
                heap[1][0] = cnt_trace[i]
                heap[1][1] = addr_trace[i]
            else:
                wcnt[0] = cnt_trace[i]
                waddr[0] = addr_trace[i]
                index = 1
                for j in range(1, math.ceil(math.log2(heap_element_cnt + 2)) + 1): # j is currnet stage's level
                    if (j > TOTAL_LEVEL):
                        break
                    
                    if (wcnt[j-1] > heap[index][0]):
                        if(j != math.ceil(math.log2(heap_element_cnt + 2))):
                            wcnt[j] = heap[index][0]
                            waddr[j] = heap[index][1]
                        else:
                            wcnt[j] = 0
                            waddr[j] = 0
                        heap[index][0] = wcnt[j-1]
                        heap[index][1] = waddr[j-1]
                    else:
                        if(j != math.ceil(math.log2(heap_element_cnt + 2))):
                            wcnt[j] = wcnt[j-1]
                            waddr[j] = waddr[j-1]
                        else:
                            wcnt[j] = 0
                            waddr[j] = 0
                    if (j == math.ceil(math.log2(heap_element_cnt + 2))):
                        break
                    if (((insert_path >> math.ceil(math.log2(heap_element_cnt+2)) - j - 1) & 1) == 0): # left child
                        index = index * 2
                    else: # right child
                        index = (index * 2) + 1

            
            # increase element count
            if (heap_element_cnt < NUM_ENTRY):
                heap_element_cnt += 1

            #if (num_access == TRACE_SIZE):
            for k in range (1, NUM_ENTRY+1):
                f.write("{:>3d}:  {:>5d}  {:0>7x}\n".format(k, heap[k][0], heap[k][1]))
            f.write("///////////////////////////////\n\n")
