#!/bin/bash
set -x
sudo swapoff -a
sudo sh -c "echo 1 > /sys/kernel/mm/numa/demotion_enabled"
sudo cat /sys/kernel/mm/numa/demotion_enabled

# We don't need to enable numa balancing.
sudo sh -c "echo 2 > /proc/sys/kernel/numa_balancing" # 2 = NUMA_BALANCING_MEMORY_TIERING
