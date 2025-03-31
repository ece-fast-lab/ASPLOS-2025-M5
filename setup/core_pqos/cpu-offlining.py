import os
import sys
import string
import argparse
import re
from subprocess import Popen, PIPE
import numa



def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("-s", "--start", help = \
            "start cpu id.", default="7")
    parser.add_argument("-e", "--end", help = \
            "end cpu id.", default="0")
    args = parser.parse_args()

    start = int(args.start)
    end = int(args.end)+1
    # Offline as much as possible
    for cpuid in range(start, end):
        print("Offlining cpu" + str(cpuid))
        os.system("sudo sh -c 'echo 0 > /sys/devices/system/cpu/cpu" + str(cpuid) + "/online'")
        print("Done!")


    # Results
    print("===============================\n")
    print("Online CPUs")
    os.system("sudo sh -c 'cat /sys/devices/system/cpu/online'")
    print("Offline CPUs")
    os.system("sudo sh -c 'cat /sys/devices/system/cpu/offline'")



if __name__=="__main__":
    main()
