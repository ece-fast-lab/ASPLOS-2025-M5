# (C) 2001-2023 Intel Corporation. All rights reserved.
# Your use of Intel Corporation's design tools, logic functions and other 
# software and tools, and its AMPP partner logic functions, and any output 
# files from any of the foregoing (including device programming or simulation 
# files), and any associated documentation or information are expressly subject 
# to the terms and conditions of the Intel Program License Subscription 
# Agreement, Intel FPGA IP License Agreement, or other applicable 
# license agreement, including, without limitation, that your use is for the 
# sole purpose of programming logic devices manufactured by Intel and sold by 
# Intel or its authorized distributors.  Please refer to the applicable 
# agreement for further details.


    # Analysis & Synthesis Assignments
    # ================================
    set_global_assignment -name VERILOG_INPUT_VERSION SYSTEMVERILOG_2009
    set_global_assignment -name REMOVE_DUPLICATE_LOGIC ON
    set_global_assignment -name SYNTH_GATED_CLOCK_CONVERSION ON
    set_global_assignment -name REMOVE_DUPLICATE_REGISTERS OFF

    # Compiler Assignments
    # ====================
    set_global_assignment -name OPTIMIZATION_MODE "SUPERIOR PERFORMANCE WITH MAXIMUM PLACEMENT EFFORT"
    set_global_assignment -name ALLOW_REGISTER_RETIMING ON
    set_global_assignment -name ALLOW_RAM_RETIMING ON
    set_global_assignment -name ALLOW_DSP_RETIMING ON
    set_global_assignment -name STATE_MACHINE_PROCESSING "ONE-HOT"

    # Fitter Assignments
    # ==================
    set_global_assignment -name FINAL_PLACEMENT_OPTIMIZATION ALWAYS
    set_global_assignment -name ALM_REGISTER_PACKING_EFFORT LOW
    set_global_assignment -name QII_AUTO_PACKED_REGISTERS "NORMAL"

    set_global_assignment -name OPTIMIZATION_TECHNIQUE SPEED
    set_global_assignment -name ROUTER_TIMING_OPTIMIZATION_LEVEL MAXIMUM
    set_global_assignment -name MUX_RESTRUCTURE OFF
    set_global_assignment -name FLOW_ENABLE_HYPER_RETIMER_FAST_FORWARD ON
    set_global_assignment -name ADV_NETLIST_OPT_SYNTH_WYSIWYG_REMAP ON
  	set_global_assignment -name MAX_FANOUT 100
  	set_global_assignment -name SYNCHRONIZATION_REGISTER_CHAIN_LENGTH 2

    set_global_assignment -name SYNTH_TIMING_DRIVEN_SYNTHESIS ON
    set_global_assignment -name OPTIMIZE_POWER_DURING_SYNTHESIS OFF
    set_global_assignment -name OPTIMIZE_POWER_DURING_FITTING OFF
    set_global_assignment -name FITTER_EFFORT "STANDARD FIT"
    set_global_assignment -name PHYSICAL_SYNTHESIS ON
    set_global_assignment -name FITTER_AGGRESSIVE_ROUTABILITY_OPTIMIZATION ALWAYS
    

    # Classic Timing Assignments
    # ==========================
    set_global_assignment -name TAO_FILE myresults.tao
    set_global_assignment -name ENABLE_CLOCK_LATENCY ON
    set_global_assignment -name MIN_CORE_JUNCTION_TEMP 0
    set_global_assignment -name MAX_CORE_JUNCTION_TEMP 100
    set_global_assignment -name TIMING_ANALYZER_DO_REPORT_TIMING ON
    set_global_assignment -name TIMING_ANALYZER_MULTICORNER_ANALYSIS ON

    # Global Clock assignments
    # ========================

	
