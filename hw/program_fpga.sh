#!/bin/bash
set -x
echo "cdf path = ${1}"
cat ${1}
# quartus_pgm --auto will show the port name:
#USB_PORT="AGI FPGA Development Kit [1-5]"
USB_PORT="USB-BlasterII [1-7]"
QUARTUS_PATH="/storage/intelFPGA_pro/23.2/quartus/bin"

$QUARTUS_PATH/quartus_pgm $PORT -c $1
