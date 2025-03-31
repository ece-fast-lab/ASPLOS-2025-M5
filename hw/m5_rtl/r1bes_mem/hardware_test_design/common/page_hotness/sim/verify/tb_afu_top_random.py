import time
import numpy as np

NUM_ENTRY = 100
NUM_ROW = 500
TRACE_SIZE = 1300
TOP_K_CACHE = 2
TOP_K_PAGE = 5
MIG_TH = 200

if __name__ == '__main__':

    # np.random.seed(777)
    np.random.seed(int(time.time()))

    trace = np.random.randint(1, NUM_ROW + 1, size=TRACE_SIZE)
    
    np.savetxt('rtrace.txt', trace, fmt='%d')

    trace = np.loadtxt('rtrace.txt', dtype='int')

    table_cache = []
    top_k_table_cache = []
    table_page = []
    top_k_table_page = []

    for _ in range(NUM_ENTRY):
        table_cache.append([0, 0])
        table_page.append([0, 0])
    
    for _ in range(TOP_K_CACHE):
        top_k_table_cache.append([0, 0])

    for _ in range(TOP_K_PAGE):    
        top_k_table_page.append([0, 0])
    
    req_cnt = 0
    
    minptr_cache = 0
    minptr_page = 0

    hit_rank_cache = 0
    new_rank_cache = 0
    hit_rank_page = 0
    new_rank_page = 0
    
    num_access = 0
    num_query = 0

    with open('answer.txt', 'w') as f:
        '''
        f.write("///// Print Tracker Table ({:>8d}) /////\n".format(num_access))
        for i in range (0, NUM_ENTRY):
            f.write("{:>3d}:  {:0>7x}  {:>5d} | {:0>7x}  {:>5d}\n".format(i, table_cache[i][0], table_cache[i][1], table_page[i][0], table_page[i][1]))
        f.write("///////////////////////////////\n\n")
        '''
        for req_addr in trace:
            req_cnt += 1
            num_access += 1
            f.write("///// Print Tracker Table ({:>8d}) /////\n".format(num_access))
        
            cache_req_addr = req_addr
            page_req_addr = (req_addr // 64) << 6

            exist_cache = False
            exist_page = False

            # cache table hit
            for i in range (0, NUM_ENTRY): 
                if (table_cache[i][0] == cache_req_addr):
                    hit_rank_cache = i
                    table_cache[i][1] += 1
                    # addr, count sort
                    if (hit_rank_cache == minptr_cache):
                        minptr_cache += 1 # no sort, just increase minptr_cache 1
                    elif (i > 0): # sort
                        if (table_cache[i][1] == table_cache[i-1][1]):
                            pass
                        elif (table_cache[i][1] > table_cache[i-1][1]):
                            for j in range (0, NUM_ENTRY):
                                if (table_cache[i][1] > table_cache[j][1]):
                                    new_rank_cache = j
                                    break
                            temp_addr = table_cache[hit_rank_cache][0]
                            temp_cnt = table_cache[hit_rank_cache][1]
                            for k in range (new_rank_cache, hit_rank_cache):
                                table_cache[hit_rank_cache+new_rank_cache-k][0] = table_cache[hit_rank_cache+new_rank_cache-k-1][0]
                                table_cache[hit_rank_cache+new_rank_cache-k][1] = table_cache[hit_rank_cache+new_rank_cache-k-1][1]
                            table_cache[new_rank_cache][0] = temp_addr
                            table_cache[new_rank_cache][1] = temp_cnt
                            # minptr_cache update
                            if (new_rank_cache == minptr_cache):
                                minptr_cache += 1
                    exist_cache = True
                    break

            # page table hit
            for i in range (0, NUM_ENTRY): 
                if table_page[i][0] == page_req_addr:
                    hit_rank_page = i
                    table_page[i][1] += 1
                    # addr, count sort
                    if (hit_rank_page == minptr_page):
                        minptr_page += 1 # no sort, just increase minptr_page 1
                    elif (i > 0): # sort
                        if (table_page[i][1] == table_page[i-1][1]):
                            pass
                        elif (table_page[i][1] > table_page[i-1][1]):
                            for j in range (0, NUM_ENTRY):
                                if (table_page[i][1] > table_page[j][1]):
                                    new_rank_page = j
                                    break
                            temp_addr = table_page[hit_rank_page][0]
                            temp_cnt = table_page[hit_rank_page][1]
                            for k in range (new_rank_page, hit_rank_page):
                                table_page[hit_rank_page+new_rank_page-k][0] = table_page[hit_rank_page+new_rank_page-k-1][0]
                                table_page[hit_rank_page+new_rank_page-k][1] = table_page[hit_rank_page+new_rank_page-k-1][1]
                            table_page[new_rank_page][0] = temp_addr
                            table_page[new_rank_page][1] = temp_cnt
                            # minptr_page update
                            if (new_rank_page == minptr_page):
                                minptr_page += 1
                    exist_page = True
                    break
                    
            # cache table miss
            if not exist_cache: 
                table_cache[minptr_cache][0] = cache_req_addr
                table_cache[minptr_cache][1] += 1
                if (minptr_cache == NUM_ENTRY-1): # minptr_cache sort
                    for j in range (0, NUM_ENTRY):
                        if (table_cache[j][1] == table_cache[NUM_ENTRY-1][1]):
                            minptr_cache = j
                            break
                else:
                    minptr_cache += 1

            # page table miss
            if not exist_page: 
                table_page[minptr_page][0] = page_req_addr
                table_page[minptr_page][1] += 1
                if (minptr_page == NUM_ENTRY-1): # minptr_page sort
                    for j in range (0, NUM_ENTRY):
                        if (table_page[j][1] == table_page[NUM_ENTRY-1][1]):
                            minptr_page = j
                            break
                else:
                    minptr_page += 1

            for i in range (0, NUM_ENTRY):
                f.write("{:>3d}:  {:0>7x}  {:>5d} | {:0>7x}  {:>5d}\n".format(i, table_cache[i][0], table_cache[i][1], table_page[i][0], table_page[i][1]))
            f.write("///////////////////////////////\n\n")

            ############################################################################################################################################
            ############################################################################################################################################
            
            # Migration
            #if (req_cnt  % MIG_TH == MIG_TH -1):
            if (req_cnt  % MIG_TH == 0) and (req_cnt > 0):
                minptr_cache_cnt = table_cache[minptr_cache][1]
                minptr_page_cnt = table_page[minptr_page][1]
                
                num_query += 1
                f.write("///// Print Tracker Table (Query {:>8d}) /////\n".format(num_query))
                
                # Query_cache
                for i in range(0, NUM_ENTRY):
                    if (i < NUM_ENTRY - TOP_K_CACHE):
                        table_cache[i][0] = table_cache[i+TOP_K_CACHE][0]  
                        table_cache[i][1] = table_cache[i+TOP_K_CACHE][1] - minptr_cache_cnt                              
                    else:
                        table_cache[i][0] = 0
                        table_cache[i][1] = 0

                if (table_cache[minptr_cache][1] == 0):
                    for i in range(minptr_cache-TOP_K_CACHE, NUM_ENTRY):
                        table_cache[i][0] = 0
                        table_cache[i][1] = 0
                    
                if (minptr_cache < TOP_K_CACHE):
                    minptr_cache = 0
                else:
                    minptr_cache -= TOP_K_CACHE

                # Query_page
                for i in range(0, NUM_ENTRY):
                    if (i < NUM_ENTRY - TOP_K_PAGE):
                        table_page[i][0] = table_page[i+TOP_K_PAGE][0]  
                        table_page[i][1] = table_page[i+TOP_K_PAGE][1] - minptr_page_cnt                              
                    else:
                        table_page[i][0] = 0
                        table_page[i][1] = 0

                if (table_page[minptr_page][1] == 0):
                    for i in range(minptr_page-TOP_K_PAGE, NUM_ENTRY):
                        table_page[i][0] = 0
                        table_page[i][1] = 0
                    
                if (minptr_page < TOP_K_PAGE):
                    minptr_page = 0
                else:
                    minptr_page -= TOP_K_PAGE
                

                for i in range (0, NUM_ENTRY):
                    f.write("{:>3d}:  {:0>7x}  {:>5d} | {:0>7x}  {:>5d}\n".format(i, table_cache[i][0], table_cache[i][1], table_page[i][0], table_page[i][1]))
                f.write("///////////////////////////////\n\n")
