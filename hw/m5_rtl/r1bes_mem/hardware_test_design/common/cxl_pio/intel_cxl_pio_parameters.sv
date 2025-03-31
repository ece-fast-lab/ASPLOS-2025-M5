// (C) 2001-2023 Intel Corporation. All rights reserved.
// Your use of Intel Corporation's design tools, logic functions and other 
// software and tools, and its AMPP partner logic functions, and any output 
// files from any of the foregoing (including device programming or simulation 
// files), and any associated documentation or information are expressly subject 
// to the terms and conditions of the Intel Program License Subscription 
// Agreement, Intel FPGA IP License Agreement, or other applicable 
// license agreement, including, without limitation, that your use is for the 
// sole purpose of programming logic devices manufactured by Intel and sold by 
// Intel or its authorized distributors.  Please refer to the applicable 
// agreement for further details.


package intel_cxl_pio_parameters;
    parameter ENABLE_ONLY_DEFAULT_CONFIG= 0;
    parameter ENABLE_ONLY_PIO           = 0;
    parameter ENABLE_BOTH_DEFAULT_CONFIG_PIO = 1;
    parameter PFNUM_WIDTH               = 3;
    parameter VFNUM_WIDTH               = 12;
    parameter DATA_WIDTH                = 1024;
    parameter BAM_DATAWIDTH             = DATA_WIDTH;
    parameter DEVICE_FAMILY             = "Agilex";
    //parameter CXL_IO_DWIDTH = 256; // Data width for each channel
    //parameter CXL_IO_PWIDTH = 32;  // Prefix Width
    //parameter CXL_IO_CHWIDTH = 1;  // Prefix Width

endpackage
