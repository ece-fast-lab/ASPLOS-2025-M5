import time
import os, sys
import numpy as np

TOTAL_LEVEL = 6
NUM_ENTRY = (2 ** TOTAL_LEVEL) - 1
ADDR_RANGE = 10000
CNT_RANGE = 1000
TRACE_SIZE = 100
#TRACE_SIZE = 65 # for simple_trace.txt

if __name__ == '__main__':

    file1 = open("answer.txt", "r")
    file2 = open("result.txt", "r")
    
    lines1 = file1.readlines()
    lines2 = file2.readlines()
    #print(f"file1 : {len(lines1)}, file2 : {len(lines2)}")
    
    wc = 0
    
    f = open(f'compare.txt', 'w')
    for idx in range(len(lines1)):
        wc += 1
        #print(f'{wc} lines')
        line1 = lines1[idx].replace("\n", "")
        if idx >= len(lines2):
            print(f'{wc}) {line1} ||| [blank]')
            f.write(f'{wc}) {line1} ||| [blank]\n')
        else: 
            line2 = lines2[idx].replace("\n", "")
            if line1 != line2:
                print(f'{wc}) {line1} ||| {line2}')
                f.write(f'{wc}) {line1} ||| {line2}\n')
    
    if len(lines1) < len(lines2):
        for idx in range(len(lines1), len(lines2)):
            wc += 1
            line2 = lines2[idx].replace("\n", "")
            print(f'{wc}) [blank] ||| {line2}')
            f.write(f'{wc}) [blank] ||| {line2}\n')
    f.close()
            
                
                    
        
        
    
    
        
    
    
    
