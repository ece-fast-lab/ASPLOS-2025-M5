#!/bin/bash

set -e
SKIP_DUMMY_COPY=1
QUARTUS_SIM_LIB_DIR="/home/janux/intelFPGA_pro/23.1/quartus/eda/sim_lib"
REMOTE_SERVER="janux@janux-a0.csl.illinois.edu"
DUMMY_QUARTUS_DIR="/home/zeduoyu2/quartus_23.1_sim_lib"
LOCAL_SIM_LIB_DIR="$DUMMY_QUARTUS_DIR/eda/sim_lib"
LIB_FILES=(
    "220model.v"
    "sgate.v"
    "altera_primitives.v"
    "altera_mf.v"
    "altera_lnsim.sv"
    "tennm_atoms.sv"
    "synopsys/tennm_atoms_ncrypt.sv"
    "fmica_atoms_ncrypt.sv"
    "tennm_hssi_atoms.sv"
    "tennm_hssi_atoms_ncrypt.sv"
    "ctfb_hssi_atoms.sv"
    "synopsys/ctfb_hssi_atoms_ncrypt.sv"
    "synopsys/ctfb_hssi_atoms2_ncrypt.sv"
    "ctr_hssi_atoms.sv"
    "ctr_hssi_atoms_ncrypt.sv"
    "ctrb_hssi_atoms_ncrypt.sv"
    "simsf_dpi.cpp"
)

if [ ! $SKIP_DUMMY_COPY ]; then

    echo "Checking the simulation libraries..."

    if [ ! -e /home/zeduoyu2/quartus_23.1_sim_lib/eda/sim_lib/synopsys ]; then
        mkdir -p /home/zeduoyu2/quartus_23.1_sim_lib/eda/sim_lib/synopsys
    fi

    for file in "${LIB_FILES[@]}"; do

        if [ -e "$LOCAL_SIM_LIB_DIR/$file" ]; then
            echo "File $file exists."
        else
            echo "File $file does not exist. Trying to download..."
            scp $REMOTE_SERVER:$QUARTUS_SIM_LIB_DIR/$file $LOCAL_SIM_LIB_DIR/$file
        fi
    done
fi

# TOP_LEVEL_NAME is used in the Quartus-generated IP simulation script to
# set the top-level simulation or testbench module/entity name.
#
# QSYS_SIMDIR is used in the Quartus-generated IP simulation script to
# construct paths to the files required to simulate the IP in your Quartus
# project. By default, the IP script assumes that you are launching the
# simulator from the IP script location. If launching from another
# location, set QSYS_SIMDIR to the output directory you specified when you
# generated the IP script, relative to the directory from which you launch
# the simulator.
#
# Source the Quartus-generated IP simulation script and do the following:
# - Compile the Quartus EDA simulation library and IP simulation files.
# - Specify TOP_LEVEL_NAME and QSYS_SIMDIR.
# - Compile the design and top-level simulation module/entity using
#   information specified in "filelist.f".
# - Insert "filelist.f" either before IPs using $USER_DEFINED_ELAB_OPTIONS
#   or after IPs using $USER_DEFINED_ELAB_OPTIONS_APPEND.
# - Override the default USER_DEFINED_SIM_OPTIONS. For example, to run
#   until $finish(), set to an empty string: USER_DEFINED_SIM_OPTIONS="".
# - Run the simulation.
#

if [ $SKIP_DUMMY_COPY ]; then
    QUARTUS_DIR="/research/v23.3/quartus"
else
    QUARTUS_DIR=$DUMMY_QUARTUS_DIR
fi

source ../../buf_512w_65536d/sim/synopsys/vcs/vcs_setup.sh \
    TOP_LEVEL_NAME=pac_top_tb \
    QSYS_SIMDIR=../../buf_512w_65536d/sim \
    USER_DEFINED_ELAB_OPTIONS="\"-f ./vcs_filelists/top_filelist -full64 -timescale=1ns/10ps -debug_access+all\"" \
    USER_DEFINED_SIM_OPTIONS="" \
    SKIP_SIM=1 \
    QUARTUS_INSTALL_DIR=$QUARTUS_DIR

# vcs -sverilog -debug_access+all -timescale=1ns/10ps -full64 -f vcs_filelists/top_filelist
# echo "=================="
# echo "Simulation starts."
# echo "=================="
# ./simv
