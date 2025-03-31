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


// Copyright 2023 Intel Corporation.
//
// THIS SOFTWARE MAY CONTAIN PREPRODUCTION CODE AND IS PROVIDED BY THE
// COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED
// WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
// MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
// DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
// LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
// CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
// SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR
// BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
// WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
// OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE,
// EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//
///////////////////////////////////////////////////////////////////////

`ifndef CAFU_CSR0_CFG_PKG_VH
`define CAFU_CSR0_CFG_PKG_VH

`include "cafu_csr0_reg_macros.vh.iv"
`include "rtlgen_include_v12.vh.iv"

package cafu_csr0_cfg_pkg;

import rtlgen_pkg_v12::*;

typedef cfg_req_64bit_t cafu_csr0_cfg_cr_req_t;
typedef cfg_ack_64bit_t cafu_csr0_cfg_cr_ack_t;
typedef struct packed {
   logic treg_trdy; 
   logic treg_cerr;   
   logic [63:0] treg_rdata;
} cafu_csr0_cfg_sb_ack_t;

// Comments were moved out of macro, due to collage failure
// treg_data 
//    Assumption1: (treg_trdy == 0 | treg_cerr == 0) => treg_rdata   
//    Assumption2: non relevant fields & reserved are also set to 0  
// treg_trdy
//    Regular case: All banks should return same treg_trdy value.    
//    Special case: Multi cycle read/write from handcoded memory.    
//               One bank hold ack until result is ready          
//    For this case all acks are AND                               
// treg_cerr
//    Assumption: treg_trdy=0 => treg_cerr=0                         
//    Regular case: return error when all banks return error         
//    Spacial case: when bank with multi cycle request, hold the     
//                request, its ack treg_trdy=0 && treg_cerr=0     
//               when bank with multi cycle ready, all banks      
//            return ack, since the request is hold for all banks 

`ifndef RTLGEN_MERGE_SB_ACK_LIST
`define RTLGEN_MERGE_SB_ACK_LIST(sb_ack_list,merged_sb_ack)         \
  always_comb begin                                                 \
     merged_sb_ack.treg_rdata = '0;                                 \
     for (int i=0; i<$size(sb_ack_list); i++) begin                 \
        merged_sb_ack.treg_rdata |= sb_ack_list[i].treg_rdata;      \
     end                                                            \
  end                                                               \
                                                                    \
  always_comb begin                                                 \
     merged_sb_ack.treg_trdy = '1;                                  \
     for (int i=0; i<$size(sb_ack_list); i = i + 1) begin           \
        merged_sb_ack.treg_trdy &= sb_ack_list[i].treg_trdy;        \
     end                                                            \
  end                                                               \
                                                                    \
  always_comb begin                                                 \
     merged_sb_ack.treg_cerr = '0;                                  \
     for (int i=0; i<$size(sb_ack_list); i = i + 1) begin           \
        merged_sb_ack.treg_cerr |= sb_ack_list[i].treg_cerr;        \
     end                                                            \
  end                                                               
`endif // RTLGEN_MERGE_SB_ACK_LIST                                  

// sai_successfull - acknowledge with zero value must have valid=1 and miss=0
// read/write valid - all acknowledges should have the same valid
// read/write miss - return miss when all banks return miss
`ifndef RTLGEN_MERGE_CR_ACK_LIST
`define RTLGEN_MERGE_CR_ACK_LIST(cr_ack_list,merged_cr_ack)       \
   always_comb begin                                              \
      merged_cr_ack.data = '0;                                    \
      for (int i=0; i<$size(cr_ack_list); i++) begin              \
         merged_cr_ack.data |= cr_ack_list[i].data;               \
      end                                                         \
   end                                                            \
   always_comb begin                                              \
      merged_cr_ack.read_valid = '1;                              \
      for (int i=0; i<$size(cr_ack_list); i = i + 1) begin        \
         merged_cr_ack.read_valid &= cr_ack_list[i].read_valid;   \
      end                                                         \
   end                                                            \
   always_comb begin                                              \
      merged_cr_ack.write_valid = '1;                             \
      for (int i=0; i<$size(cr_ack_list); i = i + 1) begin        \
         merged_cr_ack.write_valid &= cr_ack_list[i].write_valid; \
      end                                                         \
   end                                                            \
   always_comb begin                                                      \
      merged_cr_ack.sai_successfull = '1;                                 \
      for (int i=0; i<$size(cr_ack_list); i = i + 1) begin                \
         merged_cr_ack.sai_successfull &= cr_ack_list[i].sai_successfull; \
      end                                                                 \
   end                                                                    \
   always_comb begin                                            \
      merged_cr_ack.read_miss = '1;                             \
      for (int i=0; i<$size(cr_ack_list); i = i + 1) begin      \
         merged_cr_ack.read_miss &= cr_ack_list[i].read_miss;   \
      end                                                       \
   end                                                          \
   always_comb begin                                            \
      merged_cr_ack.write_miss = '1;                            \
      for (int i=0; i<$size(cr_ack_list); i = i + 1) begin      \
         merged_cr_ack.write_miss &= cr_ack_list[i].write_miss; \
      end                                                       \
   end                                                          
`endif // RTLGEN_MERGE_CR_ACK_LIST                         

// ===================================================
// register structs

typedef struct packed {
    logic [11:0] next_cap_offset;  // RO
    logic  [3:0] dvsec_cap_version;  // RO
    logic [15:0] dvsec_cap_id;  // RO
} DVSEC_DEV_t;

localparam DVSEC_DEV_REG_STRIDE = 12'h4;
localparam DVSEC_DEV_REG_ENTRIES = 1;
localparam [11:0] DVSEC_DEV_CR_ADDR = 12'hF00;
localparam DVSEC_DEV_SIZE = 32;
localparam DVSEC_DEV_NEXT_CAP_OFFSET_LO = 20;
localparam DVSEC_DEV_NEXT_CAP_OFFSET_HI = 31;
localparam DVSEC_DEV_NEXT_CAP_OFFSET_RESET = 12'hF40;
localparam DVSEC_DEV_DVSEC_CAP_VERSION_LO = 16;
localparam DVSEC_DEV_DVSEC_CAP_VERSION_HI = 19;
localparam DVSEC_DEV_DVSEC_CAP_VERSION_RESET = 4'h1;
localparam DVSEC_DEV_DVSEC_CAP_ID_LO = 0;
localparam DVSEC_DEV_DVSEC_CAP_ID_HI = 15;
localparam DVSEC_DEV_DVSEC_CAP_ID_RESET = 16'h23;
localparam DVSEC_DEV_USEMASK = 32'hFFFFFFFF;
localparam DVSEC_DEV_RO_MASK = 32'hFFFFFFFF;
localparam DVSEC_DEV_WO_MASK = 32'h0;
localparam DVSEC_DEV_RESET = 32'hF4010023;

typedef struct packed {
    logic [11:0] dvsec_length;  // RO
    logic  [3:0] dvsec_revision;  // RO
    logic [15:0] dvsec_vendor_id;  // RO
} DVSEC_HDR1_t;

localparam DVSEC_HDR1_REG_STRIDE = 12'h4;
localparam DVSEC_HDR1_REG_ENTRIES = 1;
localparam [11:0] DVSEC_HDR1_CR_ADDR = 12'hF04;
localparam DVSEC_HDR1_SIZE = 32;
localparam DVSEC_HDR1_DVSEC_LENGTH_LO = 20;
localparam DVSEC_HDR1_DVSEC_LENGTH_HI = 31;
localparam DVSEC_HDR1_DVSEC_LENGTH_RESET = 12'h38;
localparam DVSEC_HDR1_DVSEC_REVISION_LO = 16;
localparam DVSEC_HDR1_DVSEC_REVISION_HI = 19;
localparam DVSEC_HDR1_DVSEC_REVISION_RESET = 4'h1;
localparam DVSEC_HDR1_DVSEC_VENDOR_ID_LO = 0;
localparam DVSEC_HDR1_DVSEC_VENDOR_ID_HI = 15;
localparam DVSEC_HDR1_DVSEC_VENDOR_ID_RESET = 16'h1E98;
localparam DVSEC_HDR1_USEMASK = 32'hFFFFFFFF;
localparam DVSEC_HDR1_RO_MASK = 32'hFFFFFFFF;
localparam DVSEC_HDR1_WO_MASK = 32'h0;
localparam DVSEC_HDR1_RESET = 32'h3811E98;

typedef struct packed {
    logic  [0:0] pm_init_comp_capable;  // RO
    logic  [0:0] viral_capable;  // RO
    logic  [0:0] mld;  // RO
    logic  [0:0] reserved0;  // RSVD
    logic  [0:0] cxl_reset_mem_clr_capable;  // RO
    logic  [2:0] cxl_reset_timeout;  // RO
    logic  [0:0] cxl_reset_capable;  // RO
    logic  [0:0] cache_wb_and_inv_capable;  // RO
    logic  [1:0] hdm_count;  // RO
    logic  [0:0] mem_hwInit_mode;  // RO
    logic  [0:0] mem_capable;  // RO
    logic  [0:0] io_capable;  // RO
    logic  [0:0] cache_capable;  // RO
    logic [15:0] dvsec_id;  // RO
} DVSEC_FBCAP_HDR2_t;

localparam DVSEC_FBCAP_HDR2_REG_STRIDE = 12'h4;
localparam DVSEC_FBCAP_HDR2_REG_ENTRIES = 1;
localparam [11:0] DVSEC_FBCAP_HDR2_CR_ADDR = 12'hF08;
localparam DVSEC_FBCAP_HDR2_SIZE = 32;
localparam DVSEC_FBCAP_HDR2_PM_INIT_COMP_CAPABLE_LO = 31;
localparam DVSEC_FBCAP_HDR2_PM_INIT_COMP_CAPABLE_HI = 31;
localparam DVSEC_FBCAP_HDR2_PM_INIT_COMP_CAPABLE_RESET = 1'b1;
localparam DVSEC_FBCAP_HDR2_VIRAL_CAPABLE_LO = 30;
localparam DVSEC_FBCAP_HDR2_VIRAL_CAPABLE_HI = 30;
localparam DVSEC_FBCAP_HDR2_VIRAL_CAPABLE_RESET = 1'b1;
localparam DVSEC_FBCAP_HDR2_MLD_LO = 29;
localparam DVSEC_FBCAP_HDR2_MLD_HI = 29;
localparam DVSEC_FBCAP_HDR2_MLD_RESET = 1'b0;
localparam DVSEC_FBCAP_HDR2_CXL_RESET_MEM_CLR_CAPABLE_LO = 27;
localparam DVSEC_FBCAP_HDR2_CXL_RESET_MEM_CLR_CAPABLE_HI = 27;
localparam DVSEC_FBCAP_HDR2_CXL_RESET_MEM_CLR_CAPABLE_RESET = 1'b0;
localparam DVSEC_FBCAP_HDR2_CXL_RESET_TIMEOUT_LO = 24;
localparam DVSEC_FBCAP_HDR2_CXL_RESET_TIMEOUT_HI = 26;
localparam DVSEC_FBCAP_HDR2_CXL_RESET_TIMEOUT_RESET = 3'b10;
localparam DVSEC_FBCAP_HDR2_CXL_RESET_CAPABLE_LO = 23;
localparam DVSEC_FBCAP_HDR2_CXL_RESET_CAPABLE_HI = 23;
localparam DVSEC_FBCAP_HDR2_CXL_RESET_CAPABLE_RESET = 1'b1;
localparam DVSEC_FBCAP_HDR2_CACHE_WB_AND_INV_CAPABLE_LO = 22;
localparam DVSEC_FBCAP_HDR2_CACHE_WB_AND_INV_CAPABLE_HI = 22;
localparam DVSEC_FBCAP_HDR2_CACHE_WB_AND_INV_CAPABLE_RESET = 1'b1;
localparam DVSEC_FBCAP_HDR2_HDM_COUNT_LO = 20;
localparam DVSEC_FBCAP_HDR2_HDM_COUNT_HI = 21;
localparam DVSEC_FBCAP_HDR2_HDM_COUNT_RESET = 2'b1;
localparam DVSEC_FBCAP_HDR2_MEM_HWINIT_MODE_LO = 19;
localparam DVSEC_FBCAP_HDR2_MEM_HWINIT_MODE_HI = 19;
localparam DVSEC_FBCAP_HDR2_MEM_HWINIT_MODE_RESET = 1'b1;
localparam DVSEC_FBCAP_HDR2_MEM_CAPABLE_LO = 18;
localparam DVSEC_FBCAP_HDR2_MEM_CAPABLE_HI = 18;
localparam DVSEC_FBCAP_HDR2_MEM_CAPABLE_RESET = 1'b1;
localparam DVSEC_FBCAP_HDR2_IO_CAPABLE_LO = 17;
localparam DVSEC_FBCAP_HDR2_IO_CAPABLE_HI = 17;
localparam DVSEC_FBCAP_HDR2_IO_CAPABLE_RESET = 1'b1;
localparam DVSEC_FBCAP_HDR2_CACHE_CAPABLE_LO = 16;
localparam DVSEC_FBCAP_HDR2_CACHE_CAPABLE_HI = 16;
localparam DVSEC_FBCAP_HDR2_CACHE_CAPABLE_RESET = 1'b1;
localparam DVSEC_FBCAP_HDR2_DVSEC_ID_LO = 0;
localparam DVSEC_FBCAP_HDR2_DVSEC_ID_HI = 15;
localparam DVSEC_FBCAP_HDR2_DVSEC_ID_RESET = 16'h0;
localparam DVSEC_FBCAP_HDR2_USEMASK = 32'hEFFFFFFF;
localparam DVSEC_FBCAP_HDR2_RO_MASK = 32'hEFFFFFFF;
localparam DVSEC_FBCAP_HDR2_WO_MASK = 32'h0;
localparam DVSEC_FBCAP_HDR2_RESET = 32'hC2DF0000;

typedef struct packed {
    logic  [0:0] reserved0;  // RSVD
    logic  [0:0] viral_status;  // RW/1C/V/P
    logic [14:0] reserved1;  // RSVD
    logic  [0:0] viral_enable;  // RW/L
    logic  [1:0] reserved2;  // RSVD
    logic  [0:0] cache_clean_eviction;  // RW/L
    logic  [2:0] cache_sf_granularity;  // RW/L
    logic  [4:0] cache_sf_coverage;  // RW/L
    logic  [0:0] mem_enable;  // RW/L
    logic  [0:0] io_enable;  // RO
    logic  [0:0] cache_enable;  // RW/L
} DVSEC_FBCTRL_STATUS_t;

localparam DVSEC_FBCTRL_STATUS_REG_STRIDE = 12'h4;
localparam DVSEC_FBCTRL_STATUS_REG_ENTRIES = 1;
localparam [11:0] DVSEC_FBCTRL_STATUS_CR_ADDR = 12'hF0C;
localparam DVSEC_FBCTRL_STATUS_SIZE = 32;
localparam DVSEC_FBCTRL_STATUS_VIRAL_STATUS_LO = 30;
localparam DVSEC_FBCTRL_STATUS_VIRAL_STATUS_HI = 30;
localparam DVSEC_FBCTRL_STATUS_VIRAL_STATUS_RESET = 1'b0;
localparam DVSEC_FBCTRL_STATUS_VIRAL_ENABLE_LO = 14;
localparam DVSEC_FBCTRL_STATUS_VIRAL_ENABLE_HI = 14;
localparam DVSEC_FBCTRL_STATUS_VIRAL_ENABLE_RESET = 1'b0;
localparam DVSEC_FBCTRL_STATUS_CACHE_CLEAN_EVICTION_LO = 11;
localparam DVSEC_FBCTRL_STATUS_CACHE_CLEAN_EVICTION_HI = 11;
localparam DVSEC_FBCTRL_STATUS_CACHE_CLEAN_EVICTION_RESET = 1'b0;
localparam DVSEC_FBCTRL_STATUS_CACHE_SF_GRANULARITY_LO = 8;
localparam DVSEC_FBCTRL_STATUS_CACHE_SF_GRANULARITY_HI = 10;
localparam DVSEC_FBCTRL_STATUS_CACHE_SF_GRANULARITY_RESET = 3'b0;
localparam DVSEC_FBCTRL_STATUS_CACHE_SF_COVERAGE_LO = 3;
localparam DVSEC_FBCTRL_STATUS_CACHE_SF_COVERAGE_HI = 7;
localparam DVSEC_FBCTRL_STATUS_CACHE_SF_COVERAGE_RESET = 5'b0;
localparam DVSEC_FBCTRL_STATUS_MEM_ENABLE_LO = 2;
localparam DVSEC_FBCTRL_STATUS_MEM_ENABLE_HI = 2;
localparam DVSEC_FBCTRL_STATUS_MEM_ENABLE_RESET = 1'b0;
localparam DVSEC_FBCTRL_STATUS_IO_ENABLE_LO = 1;
localparam DVSEC_FBCTRL_STATUS_IO_ENABLE_HI = 1;
localparam DVSEC_FBCTRL_STATUS_IO_ENABLE_RESET = 1'b1;
localparam DVSEC_FBCTRL_STATUS_CACHE_ENABLE_LO = 0;
localparam DVSEC_FBCTRL_STATUS_CACHE_ENABLE_HI = 0;
localparam DVSEC_FBCTRL_STATUS_CACHE_ENABLE_RESET = 1'b0;
localparam DVSEC_FBCTRL_STATUS_USEMASK = 32'h40004FFF;
localparam DVSEC_FBCTRL_STATUS_RO_MASK = 32'h2;
localparam DVSEC_FBCTRL_STATUS_WO_MASK = 32'h0;
localparam DVSEC_FBCTRL_STATUS_RESET = 32'h2;

typedef struct packed {
    logic  [0:0] power_mgt_init_complete;  // RO/V
    logic [11:0] reserved0;  // RSVD
    logic  [0:0] cxl_reset_error;  // RO/V
    logic  [0:0] cxl_reset_complete;  // RO/V
    logic  [0:0] cache_invalid;  // RO/V
    logic [11:0] reserved1;  // RSVD
    logic  [0:0] cxl_reset_mem_clr_enable;  // RW
    logic  [0:0] initiate_cxl_reset;  // RW/1S/V
    logic  [0:0] initiate_cache_wb_and_inv;  // RW/1S/V
    logic  [0:0] disable_caching;  // RW
} DVSEC_FBCTRL2_STATUS2_t;

localparam DVSEC_FBCTRL2_STATUS2_REG_STRIDE = 12'h4;
localparam DVSEC_FBCTRL2_STATUS2_REG_ENTRIES = 1;
localparam [11:0] DVSEC_FBCTRL2_STATUS2_CR_ADDR = 12'hF10;
localparam DVSEC_FBCTRL2_STATUS2_SIZE = 32;
localparam DVSEC_FBCTRL2_STATUS2_POWER_MGT_INIT_COMPLETE_LO = 31;
localparam DVSEC_FBCTRL2_STATUS2_POWER_MGT_INIT_COMPLETE_HI = 31;
localparam DVSEC_FBCTRL2_STATUS2_POWER_MGT_INIT_COMPLETE_RESET = 1'b0;
localparam DVSEC_FBCTRL2_STATUS2_CXL_RESET_ERROR_LO = 18;
localparam DVSEC_FBCTRL2_STATUS2_CXL_RESET_ERROR_HI = 18;
localparam DVSEC_FBCTRL2_STATUS2_CXL_RESET_ERROR_RESET = 1'b0;
localparam DVSEC_FBCTRL2_STATUS2_CXL_RESET_COMPLETE_LO = 17;
localparam DVSEC_FBCTRL2_STATUS2_CXL_RESET_COMPLETE_HI = 17;
localparam DVSEC_FBCTRL2_STATUS2_CXL_RESET_COMPLETE_RESET = 1'b0;
localparam DVSEC_FBCTRL2_STATUS2_CACHE_INVALID_LO = 16;
localparam DVSEC_FBCTRL2_STATUS2_CACHE_INVALID_HI = 16;
localparam DVSEC_FBCTRL2_STATUS2_CACHE_INVALID_RESET = 1'b0;
localparam DVSEC_FBCTRL2_STATUS2_CXL_RESET_MEM_CLR_ENABLE_LO = 3;
localparam DVSEC_FBCTRL2_STATUS2_CXL_RESET_MEM_CLR_ENABLE_HI = 3;
localparam DVSEC_FBCTRL2_STATUS2_CXL_RESET_MEM_CLR_ENABLE_RESET = 1'b0;
localparam DVSEC_FBCTRL2_STATUS2_INITIATE_CXL_RESET_LO = 2;
localparam DVSEC_FBCTRL2_STATUS2_INITIATE_CXL_RESET_HI = 2;
localparam DVSEC_FBCTRL2_STATUS2_INITIATE_CXL_RESET_RESET = 1'b0;
localparam DVSEC_FBCTRL2_STATUS2_INITIATE_CACHE_WB_AND_INV_LO = 1;
localparam DVSEC_FBCTRL2_STATUS2_INITIATE_CACHE_WB_AND_INV_HI = 1;
localparam DVSEC_FBCTRL2_STATUS2_INITIATE_CACHE_WB_AND_INV_RESET = 1'b0;
localparam DVSEC_FBCTRL2_STATUS2_DISABLE_CACHING_LO = 0;
localparam DVSEC_FBCTRL2_STATUS2_DISABLE_CACHING_HI = 0;
localparam DVSEC_FBCTRL2_STATUS2_DISABLE_CACHING_RESET = 1'b0;
localparam DVSEC_FBCTRL2_STATUS2_USEMASK = 32'h8007000F;
localparam DVSEC_FBCTRL2_STATUS2_RO_MASK = 32'h80070000;
localparam DVSEC_FBCTRL2_STATUS2_WO_MASK = 32'h0;
localparam DVSEC_FBCTRL2_STATUS2_RESET = 32'h0;

typedef struct packed {
    logic  [7:0] cache_size;  // RO
    logic  [3:0] reserved0;  // RSVD
    logic  [3:0] cache_size_unit;  // RO
    logic [14:0] reserved1;  // RSVD
    logic  [0:0] config_lock;  // RW/L
} DVSEC_FBLOCK_t;

localparam DVSEC_FBLOCK_REG_STRIDE = 12'h4;
localparam DVSEC_FBLOCK_REG_ENTRIES = 1;
localparam [11:0] DVSEC_FBLOCK_CR_ADDR = 12'hF14;
localparam DVSEC_FBLOCK_SIZE = 32;
localparam DVSEC_FBLOCK_CACHE_SIZE_LO = 24;
localparam DVSEC_FBLOCK_CACHE_SIZE_HI = 31;
localparam DVSEC_FBLOCK_CACHE_SIZE_RESET = 8'b10;
localparam DVSEC_FBLOCK_CACHE_SIZE_UNIT_LO = 16;
localparam DVSEC_FBLOCK_CACHE_SIZE_UNIT_HI = 19;
localparam DVSEC_FBLOCK_CACHE_SIZE_UNIT_RESET = 4'b1;
localparam DVSEC_FBLOCK_CONFIG_LOCK_LO = 0;
localparam DVSEC_FBLOCK_CONFIG_LOCK_HI = 0;
localparam DVSEC_FBLOCK_CONFIG_LOCK_RESET = 1'b0;
localparam DVSEC_FBLOCK_USEMASK = 32'hFF0F0001;
localparam DVSEC_FBLOCK_RO_MASK = 32'hFF0F0000;
localparam DVSEC_FBLOCK_WO_MASK = 32'h0;
localparam DVSEC_FBLOCK_RESET = 32'h2010000;

typedef struct packed {
    logic [31:0] memory_size;  // RO
} DVSEC_FBRANGE1SZHIGH_t;

localparam DVSEC_FBRANGE1SZHIGH_REG_STRIDE = 12'h4;
localparam DVSEC_FBRANGE1SZHIGH_REG_ENTRIES = 1;
localparam [11:0] DVSEC_FBRANGE1SZHIGH_CR_ADDR = 12'hF18;
localparam DVSEC_FBRANGE1SZHIGH_SIZE = 32;
localparam DVSEC_FBRANGE1SZHIGH_MEMORY_SIZE_LO = 0;
localparam DVSEC_FBRANGE1SZHIGH_MEMORY_SIZE_HI = 31;
localparam DVSEC_FBRANGE1SZHIGH_MEMORY_SIZE_RESET = 32'h1;
localparam DVSEC_FBRANGE1SZHIGH_USEMASK = 32'hFFFFFFFF;
localparam DVSEC_FBRANGE1SZHIGH_RO_MASK = 32'hFFFFFFFF;
localparam DVSEC_FBRANGE1SZHIGH_WO_MASK = 32'h0;
localparam DVSEC_FBRANGE1SZHIGH_RESET = 32'h1;

typedef struct packed {
    logic  [3:0] memory_size_low;  // RO
    logic [11:0] reserved0;  // RSVD
    logic  [2:0] memory_active_timeout;  // RO
    logic  [1:0] reserved1;  // RSVD
    logic  [2:0] desired_interleave;  // RO
    logic  [2:0] memory_class;  // RO
    logic  [2:0] media_type;  // RO
    logic  [0:0] mem_active;  // RO
    logic  [0:0] mem_valid;  // RO
} DVSEC_FBRANGE1SZLOW_t;

localparam DVSEC_FBRANGE1SZLOW_REG_STRIDE = 12'h4;
localparam DVSEC_FBRANGE1SZLOW_REG_ENTRIES = 1;
localparam [11:0] DVSEC_FBRANGE1SZLOW_CR_ADDR = 12'hF1C;
localparam DVSEC_FBRANGE1SZLOW_SIZE = 32;
localparam DVSEC_FBRANGE1SZLOW_MEMORY_SIZE_LOW_LO = 28;
localparam DVSEC_FBRANGE1SZLOW_MEMORY_SIZE_LOW_HI = 31;
localparam DVSEC_FBRANGE1SZLOW_MEMORY_SIZE_LOW_RESET = 4'h0;
localparam DVSEC_FBRANGE1SZLOW_MEMORY_ACTIVE_TIMEOUT_LO = 13;
localparam DVSEC_FBRANGE1SZLOW_MEMORY_ACTIVE_TIMEOUT_HI = 15;
localparam DVSEC_FBRANGE1SZLOW_MEMORY_ACTIVE_TIMEOUT_RESET = 3'b1;
localparam DVSEC_FBRANGE1SZLOW_DESIRED_INTERLEAVE_LO = 8;
localparam DVSEC_FBRANGE1SZLOW_DESIRED_INTERLEAVE_HI = 10;
localparam DVSEC_FBRANGE1SZLOW_DESIRED_INTERLEAVE_RESET = 3'b0;
localparam DVSEC_FBRANGE1SZLOW_MEMORY_CLASS_LO = 5;
localparam DVSEC_FBRANGE1SZLOW_MEMORY_CLASS_HI = 7;
localparam DVSEC_FBRANGE1SZLOW_MEMORY_CLASS_RESET = 3'b10;
localparam DVSEC_FBRANGE1SZLOW_MEDIA_TYPE_LO = 2;
localparam DVSEC_FBRANGE1SZLOW_MEDIA_TYPE_HI = 4;
localparam DVSEC_FBRANGE1SZLOW_MEDIA_TYPE_RESET = 3'b10;
localparam DVSEC_FBRANGE1SZLOW_MEM_ACTIVE_LO = 1;
localparam DVSEC_FBRANGE1SZLOW_MEM_ACTIVE_HI = 1;
localparam DVSEC_FBRANGE1SZLOW_MEM_ACTIVE_RESET = 1'b1;
localparam DVSEC_FBRANGE1SZLOW_MEM_VALID_LO = 0;
localparam DVSEC_FBRANGE1SZLOW_MEM_VALID_HI = 0;
localparam DVSEC_FBRANGE1SZLOW_MEM_VALID_RESET = 1'b1;
localparam DVSEC_FBRANGE1SZLOW_USEMASK = 32'hF000E7FF;
localparam DVSEC_FBRANGE1SZLOW_RO_MASK = 32'hF000E7FF;
localparam DVSEC_FBRANGE1SZLOW_WO_MASK = 32'h0;
localparam DVSEC_FBRANGE1SZLOW_RESET = 32'h204B;

typedef struct packed {
    logic [31:0] memory_base_high;  // RW/L
} DVSEC_FBRANGE1HIGH_t;

localparam DVSEC_FBRANGE1HIGH_REG_STRIDE = 12'h4;
localparam DVSEC_FBRANGE1HIGH_REG_ENTRIES = 1;
localparam [11:0] DVSEC_FBRANGE1HIGH_CR_ADDR = 12'hF20;
localparam DVSEC_FBRANGE1HIGH_SIZE = 32;
localparam DVSEC_FBRANGE1HIGH_MEMORY_BASE_HIGH_LO = 0;
localparam DVSEC_FBRANGE1HIGH_MEMORY_BASE_HIGH_HI = 31;
localparam DVSEC_FBRANGE1HIGH_MEMORY_BASE_HIGH_RESET = 32'h0;
localparam DVSEC_FBRANGE1HIGH_USEMASK = 32'hFFFFFFFF;
localparam DVSEC_FBRANGE1HIGH_RO_MASK = 32'h0;
localparam DVSEC_FBRANGE1HIGH_WO_MASK = 32'h0;
localparam DVSEC_FBRANGE1HIGH_RESET = 32'h0;

typedef struct packed {
    logic  [3:0] memory_base_low;  // RW/L
    logic [27:0] reserved0;  // RSVD
} DVSEC_FBRANGE1LOW_t;

localparam DVSEC_FBRANGE1LOW_REG_STRIDE = 12'h4;
localparam DVSEC_FBRANGE1LOW_REG_ENTRIES = 1;
localparam [11:0] DVSEC_FBRANGE1LOW_CR_ADDR = 12'hF24;
localparam DVSEC_FBRANGE1LOW_SIZE = 32;
localparam DVSEC_FBRANGE1LOW_MEMORY_BASE_LOW_LO = 28;
localparam DVSEC_FBRANGE1LOW_MEMORY_BASE_LOW_HI = 31;
localparam DVSEC_FBRANGE1LOW_MEMORY_BASE_LOW_RESET = 4'h0;
localparam DVSEC_FBRANGE1LOW_USEMASK = 32'hF0000000;
localparam DVSEC_FBRANGE1LOW_RO_MASK = 32'h0;
localparam DVSEC_FBRANGE1LOW_WO_MASK = 32'h0;
localparam DVSEC_FBRANGE1LOW_RESET = 32'h0;

typedef struct packed {
    logic [31:0] memory_size;  // RO
} DVSEC_FBRANGE2SZHIGH_t;

localparam DVSEC_FBRANGE2SZHIGH_REG_STRIDE = 12'h4;
localparam DVSEC_FBRANGE2SZHIGH_REG_ENTRIES = 1;
localparam [11:0] DVSEC_FBRANGE2SZHIGH_CR_ADDR = 12'hF28;
localparam DVSEC_FBRANGE2SZHIGH_SIZE = 32;
localparam DVSEC_FBRANGE2SZHIGH_MEMORY_SIZE_LO = 0;
localparam DVSEC_FBRANGE2SZHIGH_MEMORY_SIZE_HI = 31;
localparam DVSEC_FBRANGE2SZHIGH_MEMORY_SIZE_RESET = 32'h0;
localparam DVSEC_FBRANGE2SZHIGH_USEMASK = 32'hFFFFFFFF;
localparam DVSEC_FBRANGE2SZHIGH_RO_MASK = 32'hFFFFFFFF;
localparam DVSEC_FBRANGE2SZHIGH_WO_MASK = 32'h0;
localparam DVSEC_FBRANGE2SZHIGH_RESET = 32'h0;

typedef struct packed {
    logic  [3:0] memory_size_low;  // RO
    logic [11:0] reserved0;  // RSVD
    logic  [2:0] memory_active_timeout;  // RO
    logic  [1:0] reserved1;  // RSVD
    logic  [2:0] desired_interleave;  // RO
    logic  [2:0] memory_class;  // RO
    logic  [2:0] media_type;  // RO
    logic  [0:0] mem_active;  // RO
    logic  [0:0] mem_valid;  // RO
} DVSEC_FBRANGE2SZLOW_t;

localparam DVSEC_FBRANGE2SZLOW_REG_STRIDE = 12'h4;
localparam DVSEC_FBRANGE2SZLOW_REG_ENTRIES = 1;
localparam [11:0] DVSEC_FBRANGE2SZLOW_CR_ADDR = 12'hF2C;
localparam DVSEC_FBRANGE2SZLOW_SIZE = 32;
localparam DVSEC_FBRANGE2SZLOW_MEMORY_SIZE_LOW_LO = 28;
localparam DVSEC_FBRANGE2SZLOW_MEMORY_SIZE_LOW_HI = 31;
localparam DVSEC_FBRANGE2SZLOW_MEMORY_SIZE_LOW_RESET = 4'h0;
localparam DVSEC_FBRANGE2SZLOW_MEMORY_ACTIVE_TIMEOUT_LO = 13;
localparam DVSEC_FBRANGE2SZLOW_MEMORY_ACTIVE_TIMEOUT_HI = 15;
localparam DVSEC_FBRANGE2SZLOW_MEMORY_ACTIVE_TIMEOUT_RESET = 3'b0;
localparam DVSEC_FBRANGE2SZLOW_DESIRED_INTERLEAVE_LO = 8;
localparam DVSEC_FBRANGE2SZLOW_DESIRED_INTERLEAVE_HI = 10;
localparam DVSEC_FBRANGE2SZLOW_DESIRED_INTERLEAVE_RESET = 3'b0;
localparam DVSEC_FBRANGE2SZLOW_MEMORY_CLASS_LO = 5;
localparam DVSEC_FBRANGE2SZLOW_MEMORY_CLASS_HI = 7;
localparam DVSEC_FBRANGE2SZLOW_MEMORY_CLASS_RESET = 3'b0;
localparam DVSEC_FBRANGE2SZLOW_MEDIA_TYPE_LO = 2;
localparam DVSEC_FBRANGE2SZLOW_MEDIA_TYPE_HI = 4;
localparam DVSEC_FBRANGE2SZLOW_MEDIA_TYPE_RESET = 3'b0;
localparam DVSEC_FBRANGE2SZLOW_MEM_ACTIVE_LO = 1;
localparam DVSEC_FBRANGE2SZLOW_MEM_ACTIVE_HI = 1;
localparam DVSEC_FBRANGE2SZLOW_MEM_ACTIVE_RESET = 1'b0;
localparam DVSEC_FBRANGE2SZLOW_MEM_VALID_LO = 0;
localparam DVSEC_FBRANGE2SZLOW_MEM_VALID_HI = 0;
localparam DVSEC_FBRANGE2SZLOW_MEM_VALID_RESET = 1'b0;
localparam DVSEC_FBRANGE2SZLOW_USEMASK = 32'hF000E7FF;
localparam DVSEC_FBRANGE2SZLOW_RO_MASK = 32'hF000E7FF;
localparam DVSEC_FBRANGE2SZLOW_WO_MASK = 32'h0;
localparam DVSEC_FBRANGE2SZLOW_RESET = 32'h0;

typedef struct packed {
    logic [31:0] memory_base_high;  // RW/L
} DVSEC_FBRANGE2HIGH_t;

localparam DVSEC_FBRANGE2HIGH_REG_STRIDE = 12'h4;
localparam DVSEC_FBRANGE2HIGH_REG_ENTRIES = 1;
localparam [11:0] DVSEC_FBRANGE2HIGH_CR_ADDR = 12'hF30;
localparam DVSEC_FBRANGE2HIGH_SIZE = 32;
localparam DVSEC_FBRANGE2HIGH_MEMORY_BASE_HIGH_LO = 0;
localparam DVSEC_FBRANGE2HIGH_MEMORY_BASE_HIGH_HI = 31;
localparam DVSEC_FBRANGE2HIGH_MEMORY_BASE_HIGH_RESET = 32'h0;
localparam DVSEC_FBRANGE2HIGH_USEMASK = 32'hFFFFFFFF;
localparam DVSEC_FBRANGE2HIGH_RO_MASK = 32'h0;
localparam DVSEC_FBRANGE2HIGH_WO_MASK = 32'h0;
localparam DVSEC_FBRANGE2HIGH_RESET = 32'h0;

typedef struct packed {
    logic  [3:0] memory_base_low;  // RW/L
    logic [27:0] reserved0;  // RSVD
} DVSEC_FBRANGE2LOW_t;

localparam DVSEC_FBRANGE2LOW_REG_STRIDE = 12'h4;
localparam DVSEC_FBRANGE2LOW_REG_ENTRIES = 1;
localparam [11:0] DVSEC_FBRANGE2LOW_CR_ADDR = 12'hF34;
localparam DVSEC_FBRANGE2LOW_SIZE = 32;
localparam DVSEC_FBRANGE2LOW_MEMORY_BASE_LOW_LO = 28;
localparam DVSEC_FBRANGE2LOW_MEMORY_BASE_LOW_HI = 31;
localparam DVSEC_FBRANGE2LOW_MEMORY_BASE_LOW_RESET = 4'h0;
localparam DVSEC_FBRANGE2LOW_USEMASK = 32'hF0000000;
localparam DVSEC_FBRANGE2LOW_RO_MASK = 32'h0;
localparam DVSEC_FBRANGE2LOW_WO_MASK = 32'h0;
localparam DVSEC_FBRANGE2LOW_RESET = 32'h0;

typedef struct packed {
    logic [11:0] next_cap_offset;  // RO
    logic  [3:0] dvsec_cap_version;  // RO
    logic [15:0] dvsec_cap_id;  // RO
} DVSEC_DOE_t;

localparam DVSEC_DOE_REG_STRIDE = 12'h4;
localparam DVSEC_DOE_REG_ENTRIES = 1;
localparam [11:0] DVSEC_DOE_CR_ADDR = 12'hF40;
localparam DVSEC_DOE_SIZE = 32;
localparam DVSEC_DOE_NEXT_CAP_OFFSET_LO = 20;
localparam DVSEC_DOE_NEXT_CAP_OFFSET_HI = 31;
localparam DVSEC_DOE_NEXT_CAP_OFFSET_RESET = 12'hF60;
localparam DVSEC_DOE_DVSEC_CAP_VERSION_LO = 16;
localparam DVSEC_DOE_DVSEC_CAP_VERSION_HI = 19;
localparam DVSEC_DOE_DVSEC_CAP_VERSION_RESET = 4'h1;
localparam DVSEC_DOE_DVSEC_CAP_ID_LO = 0;
localparam DVSEC_DOE_DVSEC_CAP_ID_HI = 15;
localparam DVSEC_DOE_DVSEC_CAP_ID_RESET = 16'h2E;
localparam DVSEC_DOE_USEMASK = 32'hFFFFFFFF;
localparam DVSEC_DOE_RO_MASK = 32'hFFFFFFFF;
localparam DVSEC_DOE_WO_MASK = 32'h0;
localparam DVSEC_DOE_RESET = 32'hF601002E;

typedef struct packed {
    logic [19:0] reserved0;  // RSVD
    logic [10:0] doe_int_msg;  // RO
    logic  [0:0] doe_int_support;  // RO
} DOE_CAPREG_t;

localparam DOE_CAPREG_REG_STRIDE = 12'h4;
localparam DOE_CAPREG_REG_ENTRIES = 1;
localparam [11:0] DOE_CAPREG_CR_ADDR = 12'hF44;
localparam DOE_CAPREG_SIZE = 32;
localparam DOE_CAPREG_DOE_INT_MSG_LO = 1;
localparam DOE_CAPREG_DOE_INT_MSG_HI = 11;
localparam DOE_CAPREG_DOE_INT_MSG_RESET = 11'h0;
localparam DOE_CAPREG_DOE_INT_SUPPORT_LO = 0;
localparam DOE_CAPREG_DOE_INT_SUPPORT_HI = 0;
localparam DOE_CAPREG_DOE_INT_SUPPORT_RESET = 1'b0;
localparam DOE_CAPREG_USEMASK = 32'hFFF;
localparam DOE_CAPREG_RO_MASK = 32'hFFF;
localparam DOE_CAPREG_WO_MASK = 32'h0;
localparam DOE_CAPREG_RESET = 32'h0;

typedef struct packed {
    logic  [0:0] doe_go;  // RW/V
    logic [28:0] reserved0;  // RSVD
    logic  [0:0] doe_int_enb;  // RW
    logic  [0:0] doe_abort;  // RW/V
} DOE_CTLREG_t;

localparam DOE_CTLREG_REG_STRIDE = 12'h4;
localparam DOE_CTLREG_REG_ENTRIES = 1;
localparam [11:0] DOE_CTLREG_CR_ADDR = 12'hF48;
localparam DOE_CTLREG_SIZE = 32;
localparam DOE_CTLREG_DOE_GO_LO = 31;
localparam DOE_CTLREG_DOE_GO_HI = 31;
localparam DOE_CTLREG_DOE_GO_RESET = 1'b0;
localparam DOE_CTLREG_DOE_INT_ENB_LO = 1;
localparam DOE_CTLREG_DOE_INT_ENB_HI = 1;
localparam DOE_CTLREG_DOE_INT_ENB_RESET = 1'b0;
localparam DOE_CTLREG_DOE_ABORT_LO = 0;
localparam DOE_CTLREG_DOE_ABORT_HI = 0;
localparam DOE_CTLREG_DOE_ABORT_RESET = 1'b0;
localparam DOE_CTLREG_USEMASK = 32'h80000003;
localparam DOE_CTLREG_RO_MASK = 32'h0;
localparam DOE_CTLREG_WO_MASK = 32'h0;
localparam DOE_CTLREG_RESET = 32'h0;

typedef struct packed {
    logic  [0:0] data_object_ready;  // RO/V
    logic [27:0] reserved0;  // RSVD
    logic  [0:0] doe_error;  // RO/V
    logic  [0:0] doe_int_status;  // RW/1C/V
    logic  [0:0] doe_busy;  // RO/V
} DOE_STSREG_t;

localparam DOE_STSREG_REG_STRIDE = 12'h4;
localparam DOE_STSREG_REG_ENTRIES = 1;
localparam [11:0] DOE_STSREG_CR_ADDR = 12'hF4C;
localparam DOE_STSREG_SIZE = 32;
localparam DOE_STSREG_DATA_OBJECT_READY_LO = 31;
localparam DOE_STSREG_DATA_OBJECT_READY_HI = 31;
localparam DOE_STSREG_DATA_OBJECT_READY_RESET = 1'b0;
localparam DOE_STSREG_DOE_ERROR_LO = 2;
localparam DOE_STSREG_DOE_ERROR_HI = 2;
localparam DOE_STSREG_DOE_ERROR_RESET = 1'b0;
localparam DOE_STSREG_DOE_INT_STATUS_LO = 1;
localparam DOE_STSREG_DOE_INT_STATUS_HI = 1;
localparam DOE_STSREG_DOE_INT_STATUS_RESET = 1'b0;
localparam DOE_STSREG_DOE_BUSY_LO = 0;
localparam DOE_STSREG_DOE_BUSY_HI = 0;
localparam DOE_STSREG_DOE_BUSY_RESET = 1'b0;
localparam DOE_STSREG_USEMASK = 32'h80000007;
localparam DOE_STSREG_RO_MASK = 32'h80000005;
localparam DOE_STSREG_WO_MASK = 32'h0;
localparam DOE_STSREG_RESET = 32'h0;

typedef struct packed {
    logic [31:0] doe_wr_data_mailbox;  // RW/V
} DOE_WRMAILREG_t;

localparam DOE_WRMAILREG_REG_STRIDE = 12'h4;
localparam DOE_WRMAILREG_REG_ENTRIES = 1;
localparam [11:0] DOE_WRMAILREG_CR_ADDR = 12'hF50;
localparam DOE_WRMAILREG_SIZE = 32;
localparam DOE_WRMAILREG_DOE_WR_DATA_MAILBOX_LO = 0;
localparam DOE_WRMAILREG_DOE_WR_DATA_MAILBOX_HI = 31;
localparam DOE_WRMAILREG_DOE_WR_DATA_MAILBOX_RESET = 32'h0;
localparam DOE_WRMAILREG_USEMASK = 32'hFFFFFFFF;
localparam DOE_WRMAILREG_RO_MASK = 32'h0;
localparam DOE_WRMAILREG_WO_MASK = 32'h0;
localparam DOE_WRMAILREG_RESET = 32'h0;

typedef struct packed {
    logic [31:0] doe_rd_data_mailbox;  // RW/V
} DOE_RDMAILREG_t;

localparam DOE_RDMAILREG_REG_STRIDE = 12'h4;
localparam DOE_RDMAILREG_REG_ENTRIES = 1;
localparam [11:0] DOE_RDMAILREG_CR_ADDR = 12'hF54;
localparam DOE_RDMAILREG_SIZE = 32;
localparam DOE_RDMAILREG_DOE_RD_DATA_MAILBOX_LO = 0;
localparam DOE_RDMAILREG_DOE_RD_DATA_MAILBOX_HI = 31;
localparam DOE_RDMAILREG_DOE_RD_DATA_MAILBOX_RESET = 32'h0;
localparam DOE_RDMAILREG_USEMASK = 32'hFFFFFFFF;
localparam DOE_RDMAILREG_RO_MASK = 32'h0;
localparam DOE_RDMAILREG_WO_MASK = 32'h0;
localparam DOE_RDMAILREG_RESET = 32'h0;

typedef struct packed {
    logic [11:0] next_cap_offset;  // RO
    logic  [3:0] test_cap_version;  // RO
    logic [15:0] test_cap_id;  // RO
} DVSEC_TEST_CAP_t;

localparam DVSEC_TEST_CAP_REG_STRIDE = 12'h4;
localparam DVSEC_TEST_CAP_REG_ENTRIES = 1;
localparam [11:0] DVSEC_TEST_CAP_CR_ADDR = 12'hF60;
localparam DVSEC_TEST_CAP_SIZE = 32;
localparam DVSEC_TEST_CAP_NEXT_CAP_OFFSET_LO = 20;
localparam DVSEC_TEST_CAP_NEXT_CAP_OFFSET_HI = 31;
localparam DVSEC_TEST_CAP_NEXT_CAP_OFFSET_RESET = 12'h0;
localparam DVSEC_TEST_CAP_TEST_CAP_VERSION_LO = 16;
localparam DVSEC_TEST_CAP_TEST_CAP_VERSION_HI = 19;
localparam DVSEC_TEST_CAP_TEST_CAP_VERSION_RESET = 4'h1;
localparam DVSEC_TEST_CAP_TEST_CAP_ID_LO = 0;
localparam DVSEC_TEST_CAP_TEST_CAP_ID_HI = 15;
localparam DVSEC_TEST_CAP_TEST_CAP_ID_RESET = 16'h23;
localparam DVSEC_TEST_CAP_USEMASK = 32'hFFFFFFFF;
localparam DVSEC_TEST_CAP_RO_MASK = 32'hFFFFFFFF;
localparam DVSEC_TEST_CAP_WO_MASK = 32'h0;
localparam DVSEC_TEST_CAP_RESET = 32'h10023;

typedef struct packed {
    logic [11:0] dvsec_length;  // RO
    logic  [3:0] dvsec_revision;  // RO
    logic [15:0] dvsec_vend_id;  // RO
} CXL_DVSEC_HEADER_1_t;

localparam CXL_DVSEC_HEADER_1_REG_STRIDE = 12'h4;
localparam CXL_DVSEC_HEADER_1_REG_ENTRIES = 1;
localparam [11:0] CXL_DVSEC_HEADER_1_CR_ADDR = 12'hF64;
localparam CXL_DVSEC_HEADER_1_SIZE = 32;
localparam CXL_DVSEC_HEADER_1_DVSEC_LENGTH_LO = 20;
localparam CXL_DVSEC_HEADER_1_DVSEC_LENGTH_HI = 31;
localparam CXL_DVSEC_HEADER_1_DVSEC_LENGTH_RESET = 12'h22;
localparam CXL_DVSEC_HEADER_1_DVSEC_REVISION_LO = 16;
localparam CXL_DVSEC_HEADER_1_DVSEC_REVISION_HI = 19;
localparam CXL_DVSEC_HEADER_1_DVSEC_REVISION_RESET = 4'h0;
localparam CXL_DVSEC_HEADER_1_DVSEC_VEND_ID_LO = 0;
localparam CXL_DVSEC_HEADER_1_DVSEC_VEND_ID_HI = 15;
localparam CXL_DVSEC_HEADER_1_DVSEC_VEND_ID_RESET = 16'h1E98;
localparam CXL_DVSEC_HEADER_1_USEMASK = 32'hFFFFFFFF;
localparam CXL_DVSEC_HEADER_1_RO_MASK = 32'hFFFFFFFF;
localparam CXL_DVSEC_HEADER_1_WO_MASK = 32'h0;
localparam CXL_DVSEC_HEADER_1_RESET = 32'h2201E98;

typedef struct packed {
    logic [15:0] dvsec_id;  // RO
} CXL_DVSEC_HEADER_2_t;

localparam CXL_DVSEC_HEADER_2_REG_STRIDE = 12'h2;
localparam CXL_DVSEC_HEADER_2_REG_ENTRIES = 1;
localparam [11:0] CXL_DVSEC_HEADER_2_CR_ADDR = 12'hF68;
localparam CXL_DVSEC_HEADER_2_SIZE = 16;
localparam CXL_DVSEC_HEADER_2_DVSEC_ID_LO = 0;
localparam CXL_DVSEC_HEADER_2_DVSEC_ID_HI = 15;
localparam CXL_DVSEC_HEADER_2_DVSEC_ID_RESET = 16'hA;
localparam CXL_DVSEC_HEADER_2_USEMASK = 16'hFFFF;
localparam CXL_DVSEC_HEADER_2_RO_MASK = 16'hFFFF;
localparam CXL_DVSEC_HEADER_2_WO_MASK = 16'h0;
localparam CXL_DVSEC_HEADER_2_RESET = 16'hA;

typedef struct packed {
    logic [14:0] reserved0;  // RSVD
    logic  [0:0] test_config_lock;  // RW/L
} CXL_DVSEC_TEST_LOCK_t;

localparam CXL_DVSEC_TEST_LOCK_REG_STRIDE = 12'h2;
localparam CXL_DVSEC_TEST_LOCK_REG_ENTRIES = 1;
localparam [11:0] CXL_DVSEC_TEST_LOCK_CR_ADDR = 12'hF6A;
localparam CXL_DVSEC_TEST_LOCK_SIZE = 16;
localparam CXL_DVSEC_TEST_LOCK_TEST_CONFIG_LOCK_LO = 0;
localparam CXL_DVSEC_TEST_LOCK_TEST_CONFIG_LOCK_HI = 0;
localparam CXL_DVSEC_TEST_LOCK_TEST_CONFIG_LOCK_RESET = 1'b0;
localparam CXL_DVSEC_TEST_LOCK_USEMASK = 16'h1;
localparam CXL_DVSEC_TEST_LOCK_RO_MASK = 16'h0;
localparam CXL_DVSEC_TEST_LOCK_WO_MASK = 16'h0;
localparam CXL_DVSEC_TEST_LOCK_RESET = 16'h0;

typedef struct packed {
    logic  [7:0] test_config_size;  // RO
    logic  [2:0] reserved0;  // RSVD
    logic  [0:0] cmplte_timeout_injection;  // RO
    logic  [0:0] unexpect_cmpletion;  // RO
    logic  [0:0] cache_flushed;  // RO
    logic  [0:0] cache_wr_inv;  // RO
    logic  [0:0] cache_wow_invf;  // RO
    logic  [0:0] cache_wow_inv;  // RO
    logic  [0:0] cache_clean_evict_nodata;  // RO
    logic  [0:0] cache_dirty_evict;  // RO
    logic  [0:0] cache_clean_evict;  // RO
    logic  [0:0] cache_cl_flush;  // RO
    logic  [0:0] cache_mem_wr;  // RO
    logic  [0:0] cache_itom_wr;  // RO
    logic  [0:0] cache_rdown_nodata;  // RO
    logic  [0:0] cache_rdany;  // RO
    logic  [0:0] cache_rdshared;  // RO
    logic  [0:0] cache_rdown;  // RO
    logic  [0:0] cache_rdcurrent;  // RO
    logic  [0:0] algotype_2;  // RO
    logic  [0:0] algotype_1b;  // RO
    logic  [0:0] algotype_1a;  // RO
    logic  [0:0] algo_selfcheck_enb;  // RO
} CXL_DVSEC_TEST_CAP1_t;

localparam CXL_DVSEC_TEST_CAP1_REG_STRIDE = 12'h4;
localparam CXL_DVSEC_TEST_CAP1_REG_ENTRIES = 1;
localparam [11:0] CXL_DVSEC_TEST_CAP1_CR_ADDR = 12'hF6C;
localparam CXL_DVSEC_TEST_CAP1_SIZE = 32;
localparam CXL_DVSEC_TEST_CAP1_TEST_CONFIG_SIZE_LO = 24;
localparam CXL_DVSEC_TEST_CAP1_TEST_CONFIG_SIZE_HI = 31;
localparam CXL_DVSEC_TEST_CAP1_TEST_CONFIG_SIZE_RESET = 8'h0;
localparam CXL_DVSEC_TEST_CAP1_CMPLTE_TIMEOUT_INJECTION_LO = 20;
localparam CXL_DVSEC_TEST_CAP1_CMPLTE_TIMEOUT_INJECTION_HI = 20;
localparam CXL_DVSEC_TEST_CAP1_CMPLTE_TIMEOUT_INJECTION_RESET = 1'b0;
localparam CXL_DVSEC_TEST_CAP1_UNEXPECT_CMPLETION_LO = 19;
localparam CXL_DVSEC_TEST_CAP1_UNEXPECT_CMPLETION_HI = 19;
localparam CXL_DVSEC_TEST_CAP1_UNEXPECT_CMPLETION_RESET = 1'b0;
localparam CXL_DVSEC_TEST_CAP1_CACHE_FLUSHED_LO = 18;
localparam CXL_DVSEC_TEST_CAP1_CACHE_FLUSHED_HI = 18;
localparam CXL_DVSEC_TEST_CAP1_CACHE_FLUSHED_RESET = 1'b0;
localparam CXL_DVSEC_TEST_CAP1_CACHE_WR_INV_LO = 17;
localparam CXL_DVSEC_TEST_CAP1_CACHE_WR_INV_HI = 17;
localparam CXL_DVSEC_TEST_CAP1_CACHE_WR_INV_RESET = 1'b0;
localparam CXL_DVSEC_TEST_CAP1_CACHE_WOW_INVF_LO = 16;
localparam CXL_DVSEC_TEST_CAP1_CACHE_WOW_INVF_HI = 16;
localparam CXL_DVSEC_TEST_CAP1_CACHE_WOW_INVF_RESET = 1'b1;
localparam CXL_DVSEC_TEST_CAP1_CACHE_WOW_INV_LO = 15;
localparam CXL_DVSEC_TEST_CAP1_CACHE_WOW_INV_HI = 15;
localparam CXL_DVSEC_TEST_CAP1_CACHE_WOW_INV_RESET = 1'b1;
localparam CXL_DVSEC_TEST_CAP1_CACHE_CLEAN_EVICT_NODATA_LO = 14;
localparam CXL_DVSEC_TEST_CAP1_CACHE_CLEAN_EVICT_NODATA_HI = 14;
localparam CXL_DVSEC_TEST_CAP1_CACHE_CLEAN_EVICT_NODATA_RESET = 1'b0;
localparam CXL_DVSEC_TEST_CAP1_CACHE_DIRTY_EVICT_LO = 13;
localparam CXL_DVSEC_TEST_CAP1_CACHE_DIRTY_EVICT_HI = 13;
localparam CXL_DVSEC_TEST_CAP1_CACHE_DIRTY_EVICT_RESET = 1'b1;
localparam CXL_DVSEC_TEST_CAP1_CACHE_CLEAN_EVICT_LO = 12;
localparam CXL_DVSEC_TEST_CAP1_CACHE_CLEAN_EVICT_HI = 12;
localparam CXL_DVSEC_TEST_CAP1_CACHE_CLEAN_EVICT_RESET = 1'b0;
localparam CXL_DVSEC_TEST_CAP1_CACHE_CL_FLUSH_LO = 11;
localparam CXL_DVSEC_TEST_CAP1_CACHE_CL_FLUSH_HI = 11;
localparam CXL_DVSEC_TEST_CAP1_CACHE_CL_FLUSH_RESET = 1'b0;
localparam CXL_DVSEC_TEST_CAP1_CACHE_MEM_WR_LO = 10;
localparam CXL_DVSEC_TEST_CAP1_CACHE_MEM_WR_HI = 10;
localparam CXL_DVSEC_TEST_CAP1_CACHE_MEM_WR_RESET = 1'b0;
localparam CXL_DVSEC_TEST_CAP1_CACHE_ITOM_WR_LO = 9;
localparam CXL_DVSEC_TEST_CAP1_CACHE_ITOM_WR_HI = 9;
localparam CXL_DVSEC_TEST_CAP1_CACHE_ITOM_WR_RESET = 1'b1;
localparam CXL_DVSEC_TEST_CAP1_CACHE_RDOWN_NODATA_LO = 8;
localparam CXL_DVSEC_TEST_CAP1_CACHE_RDOWN_NODATA_HI = 8;
localparam CXL_DVSEC_TEST_CAP1_CACHE_RDOWN_NODATA_RESET = 1'b0;
localparam CXL_DVSEC_TEST_CAP1_CACHE_RDANY_LO = 7;
localparam CXL_DVSEC_TEST_CAP1_CACHE_RDANY_HI = 7;
localparam CXL_DVSEC_TEST_CAP1_CACHE_RDANY_RESET = 1'b0;
localparam CXL_DVSEC_TEST_CAP1_CACHE_RDSHARED_LO = 6;
localparam CXL_DVSEC_TEST_CAP1_CACHE_RDSHARED_HI = 6;
localparam CXL_DVSEC_TEST_CAP1_CACHE_RDSHARED_RESET = 1'b1;
localparam CXL_DVSEC_TEST_CAP1_CACHE_RDOWN_LO = 5;
localparam CXL_DVSEC_TEST_CAP1_CACHE_RDOWN_HI = 5;
localparam CXL_DVSEC_TEST_CAP1_CACHE_RDOWN_RESET = 1'b1;
localparam CXL_DVSEC_TEST_CAP1_CACHE_RDCURRENT_LO = 4;
localparam CXL_DVSEC_TEST_CAP1_CACHE_RDCURRENT_HI = 4;
localparam CXL_DVSEC_TEST_CAP1_CACHE_RDCURRENT_RESET = 1'b1;
localparam CXL_DVSEC_TEST_CAP1_ALGOTYPE_2_LO = 3;
localparam CXL_DVSEC_TEST_CAP1_ALGOTYPE_2_HI = 3;
localparam CXL_DVSEC_TEST_CAP1_ALGOTYPE_2_RESET = 1'b0;
localparam CXL_DVSEC_TEST_CAP1_ALGOTYPE_1B_LO = 2;
localparam CXL_DVSEC_TEST_CAP1_ALGOTYPE_1B_HI = 2;
localparam CXL_DVSEC_TEST_CAP1_ALGOTYPE_1B_RESET = 1'b0;
localparam CXL_DVSEC_TEST_CAP1_ALGOTYPE_1A_LO = 1;
localparam CXL_DVSEC_TEST_CAP1_ALGOTYPE_1A_HI = 1;
localparam CXL_DVSEC_TEST_CAP1_ALGOTYPE_1A_RESET = 1'b1;
localparam CXL_DVSEC_TEST_CAP1_ALGO_SELFCHECK_ENB_LO = 0;
localparam CXL_DVSEC_TEST_CAP1_ALGO_SELFCHECK_ENB_HI = 0;
localparam CXL_DVSEC_TEST_CAP1_ALGO_SELFCHECK_ENB_RESET = 1'b1;
localparam CXL_DVSEC_TEST_CAP1_USEMASK = 32'hFF1FFFFF;
localparam CXL_DVSEC_TEST_CAP1_RO_MASK = 32'hFF1FFFFF;
localparam CXL_DVSEC_TEST_CAP1_WO_MASK = 32'h0;
localparam CXL_DVSEC_TEST_CAP1_RESET = 32'h1A273;

typedef struct packed {
    logic  [1:0] cache_size_unit;  // RO
    logic [13:0] cache_size_device;  // RO
} CXL_DVSEC_TEST_CAP2_t;

localparam CXL_DVSEC_TEST_CAP2_REG_STRIDE = 12'h2;
localparam CXL_DVSEC_TEST_CAP2_REG_ENTRIES = 1;
localparam [11:0] CXL_DVSEC_TEST_CAP2_CR_ADDR = 12'hF70;
localparam CXL_DVSEC_TEST_CAP2_SIZE = 16;
localparam CXL_DVSEC_TEST_CAP2_CACHE_SIZE_UNIT_LO = 14;
localparam CXL_DVSEC_TEST_CAP2_CACHE_SIZE_UNIT_HI = 15;
localparam CXL_DVSEC_TEST_CAP2_CACHE_SIZE_UNIT_RESET = 2'b1;
localparam CXL_DVSEC_TEST_CAP2_CACHE_SIZE_DEVICE_LO = 0;
localparam CXL_DVSEC_TEST_CAP2_CACHE_SIZE_DEVICE_HI = 13;
localparam CXL_DVSEC_TEST_CAP2_CACHE_SIZE_DEVICE_RESET = 14'h147;
localparam CXL_DVSEC_TEST_CAP2_USEMASK = 16'hFFFF;
localparam CXL_DVSEC_TEST_CAP2_RO_MASK = 16'hFFFF;
localparam CXL_DVSEC_TEST_CAP2_WO_MASK = 16'h0;
localparam CXL_DVSEC_TEST_CAP2_RESET = 16'h4147;

typedef struct packed {
    logic [27:0] test_config_base_low;  // RO/V
    logic  [0:0] reserved0;  // RSVD
    logic  [1:0] base_reg_type;  // RO
    logic  [0:0] mem_space_indicator;  // RO
} CXL_DVSEC_TEST_CNF_BASE_LOW_t;

localparam CXL_DVSEC_TEST_CNF_BASE_LOW_REG_STRIDE = 12'h4;
localparam CXL_DVSEC_TEST_CNF_BASE_LOW_REG_ENTRIES = 1;
localparam [11:0] CXL_DVSEC_TEST_CNF_BASE_LOW_CR_ADDR = 12'hF74;
localparam CXL_DVSEC_TEST_CNF_BASE_LOW_SIZE = 32;
localparam CXL_DVSEC_TEST_CNF_BASE_LOW_TEST_CONFIG_BASE_LOW_LO = 4;
localparam CXL_DVSEC_TEST_CNF_BASE_LOW_TEST_CONFIG_BASE_LOW_HI = 31;
localparam CXL_DVSEC_TEST_CNF_BASE_LOW_TEST_CONFIG_BASE_LOW_RESET = 'h0;
localparam CXL_DVSEC_TEST_CNF_BASE_LOW_BASE_REG_TYPE_LO = 1;
localparam CXL_DVSEC_TEST_CNF_BASE_LOW_BASE_REG_TYPE_HI = 2;
localparam CXL_DVSEC_TEST_CNF_BASE_LOW_BASE_REG_TYPE_RESET = 2'b0;
localparam CXL_DVSEC_TEST_CNF_BASE_LOW_MEM_SPACE_INDICATOR_LO = 0;
localparam CXL_DVSEC_TEST_CNF_BASE_LOW_MEM_SPACE_INDICATOR_HI = 0;
localparam CXL_DVSEC_TEST_CNF_BASE_LOW_MEM_SPACE_INDICATOR_RESET = 1'b0;
localparam CXL_DVSEC_TEST_CNF_BASE_LOW_USEMASK = 32'hFFFFFFF7;
localparam CXL_DVSEC_TEST_CNF_BASE_LOW_RO_MASK = 32'hFFFFFFF7;
localparam CXL_DVSEC_TEST_CNF_BASE_LOW_WO_MASK = 32'h0;
localparam CXL_DVSEC_TEST_CNF_BASE_LOW_RESET = 32'h0;

typedef struct packed {
    logic [31:0] test_config_base_high;  // RO/V
} CXL_DVSEC_TEST_CNF_BASE_HIGH_t;

localparam CXL_DVSEC_TEST_CNF_BASE_HIGH_REG_STRIDE = 12'h4;
localparam CXL_DVSEC_TEST_CNF_BASE_HIGH_REG_ENTRIES = 1;
localparam [11:0] CXL_DVSEC_TEST_CNF_BASE_HIGH_CR_ADDR = 12'hF78;
localparam CXL_DVSEC_TEST_CNF_BASE_HIGH_SIZE = 32;
localparam CXL_DVSEC_TEST_CNF_BASE_HIGH_TEST_CONFIG_BASE_HIGH_LO = 0;
localparam CXL_DVSEC_TEST_CNF_BASE_HIGH_TEST_CONFIG_BASE_HIGH_HI = 31;
localparam CXL_DVSEC_TEST_CNF_BASE_HIGH_TEST_CONFIG_BASE_HIGH_RESET = 32'h0;
localparam CXL_DVSEC_TEST_CNF_BASE_HIGH_USEMASK = 32'hFFFFFFFF;
localparam CXL_DVSEC_TEST_CNF_BASE_HIGH_RO_MASK = 32'hFFFFFFFF;
localparam CXL_DVSEC_TEST_CNF_BASE_HIGH_WO_MASK = 32'h0;
localparam CXL_DVSEC_TEST_CNF_BASE_HIGH_RESET = 32'h0;

typedef struct packed {
    logic  [7:0] reserved0;  // RSVD
    logic  [7:0] version;  // RO
    logic [15:0] cap_id;  // RO
} CXL_DEV_CAP_ARRAY_0_t;

localparam CXL_DEV_CAP_ARRAY_0_REG_STRIDE = 48'h4;
localparam CXL_DEV_CAP_ARRAY_0_REG_ENTRIES = 1;
localparam [47:0] CXL_DEV_CAP_ARRAY_0_CR_ADDR = 48'h180000;
localparam CXL_DEV_CAP_ARRAY_0_SIZE = 32;
localparam CXL_DEV_CAP_ARRAY_0_VERSION_LO = 16;
localparam CXL_DEV_CAP_ARRAY_0_VERSION_HI = 23;
localparam CXL_DEV_CAP_ARRAY_0_VERSION_RESET = 8'h1;
localparam CXL_DEV_CAP_ARRAY_0_CAP_ID_LO = 0;
localparam CXL_DEV_CAP_ARRAY_0_CAP_ID_HI = 15;
localparam CXL_DEV_CAP_ARRAY_0_CAP_ID_RESET = 16'h0;
localparam CXL_DEV_CAP_ARRAY_0_USEMASK = 32'hFFFFFF;
localparam CXL_DEV_CAP_ARRAY_0_RO_MASK = 32'hFFFFFF;
localparam CXL_DEV_CAP_ARRAY_0_WO_MASK = 32'h0;
localparam CXL_DEV_CAP_ARRAY_0_RESET = 32'h10000;

typedef struct packed {
    logic [15:0] reserved0;  // RSVD
    logic [15:0] cap_cnt;  // RO
} CXL_DEV_CAP_ARRAY_1_t;

localparam CXL_DEV_CAP_ARRAY_1_REG_STRIDE = 48'h4;
localparam CXL_DEV_CAP_ARRAY_1_REG_ENTRIES = 1;
localparam [47:0] CXL_DEV_CAP_ARRAY_1_CR_ADDR = 48'h180004;
localparam CXL_DEV_CAP_ARRAY_1_SIZE = 32;
localparam CXL_DEV_CAP_ARRAY_1_CAP_CNT_LO = 0;
localparam CXL_DEV_CAP_ARRAY_1_CAP_CNT_HI = 15;
localparam CXL_DEV_CAP_ARRAY_1_CAP_CNT_RESET = 16'h3;
localparam CXL_DEV_CAP_ARRAY_1_USEMASK = 32'hFFFF;
localparam CXL_DEV_CAP_ARRAY_1_RO_MASK = 32'hFFFF;
localparam CXL_DEV_CAP_ARRAY_1_WO_MASK = 32'h0;
localparam CXL_DEV_CAP_ARRAY_1_RESET = 32'h3;

typedef struct packed {
    logic  [7:0] reserved0;  // RSVD
    logic  [7:0] version;  // RO
    logic [15:0] cap_id;  // RO
} CXL_DEV_CAP_HDR1_0_t;

localparam CXL_DEV_CAP_HDR1_0_REG_STRIDE = 48'h4;
localparam CXL_DEV_CAP_HDR1_0_REG_ENTRIES = 1;
localparam [47:0] CXL_DEV_CAP_HDR1_0_CR_ADDR = 48'h180010;
localparam CXL_DEV_CAP_HDR1_0_SIZE = 32;
localparam CXL_DEV_CAP_HDR1_0_VERSION_LO = 16;
localparam CXL_DEV_CAP_HDR1_0_VERSION_HI = 23;
localparam CXL_DEV_CAP_HDR1_0_VERSION_RESET = 8'h1;
localparam CXL_DEV_CAP_HDR1_0_CAP_ID_LO = 0;
localparam CXL_DEV_CAP_HDR1_0_CAP_ID_HI = 15;
localparam CXL_DEV_CAP_HDR1_0_CAP_ID_RESET = 16'h1;
localparam CXL_DEV_CAP_HDR1_0_USEMASK = 32'hFFFFFF;
localparam CXL_DEV_CAP_HDR1_0_RO_MASK = 32'hFFFFFF;
localparam CXL_DEV_CAP_HDR1_0_WO_MASK = 32'h0;
localparam CXL_DEV_CAP_HDR1_0_RESET = 32'h10001;

typedef struct packed {
    logic [31:0] offset;  // RO
} CXL_DEV_CAP_HDR1_1_t;

localparam CXL_DEV_CAP_HDR1_1_REG_STRIDE = 48'h4;
localparam CXL_DEV_CAP_HDR1_1_REG_ENTRIES = 1;
localparam [47:0] CXL_DEV_CAP_HDR1_1_CR_ADDR = 48'h180014;
localparam CXL_DEV_CAP_HDR1_1_SIZE = 32;
localparam CXL_DEV_CAP_HDR1_1_OFFSET_LO = 0;
localparam CXL_DEV_CAP_HDR1_1_OFFSET_HI = 31;
localparam CXL_DEV_CAP_HDR1_1_OFFSET_RESET = 32'h50;
localparam CXL_DEV_CAP_HDR1_1_USEMASK = 32'hFFFFFFFF;
localparam CXL_DEV_CAP_HDR1_1_RO_MASK = 32'hFFFFFFFF;
localparam CXL_DEV_CAP_HDR1_1_WO_MASK = 32'h0;
localparam CXL_DEV_CAP_HDR1_1_RESET = 32'h50;

typedef struct packed {
    logic [31:0] length;  // RO
} CXL_DEV_CAP_HDR1_2_t;

localparam CXL_DEV_CAP_HDR1_2_REG_STRIDE = 48'h4;
localparam CXL_DEV_CAP_HDR1_2_REG_ENTRIES = 1;
localparam [47:0] CXL_DEV_CAP_HDR1_2_CR_ADDR = 48'h180018;
localparam CXL_DEV_CAP_HDR1_2_SIZE = 32;
localparam CXL_DEV_CAP_HDR1_2_LENGTH_LO = 0;
localparam CXL_DEV_CAP_HDR1_2_LENGTH_HI = 31;
localparam CXL_DEV_CAP_HDR1_2_LENGTH_RESET = 32'h8;
localparam CXL_DEV_CAP_HDR1_2_USEMASK = 32'hFFFFFFFF;
localparam CXL_DEV_CAP_HDR1_2_RO_MASK = 32'hFFFFFFFF;
localparam CXL_DEV_CAP_HDR1_2_WO_MASK = 32'h0;
localparam CXL_DEV_CAP_HDR1_2_RESET = 32'h8;

typedef struct packed {
    logic  [7:0] reserved0;  // RSVD
    logic  [7:0] version;  // RO
    logic [15:0] cap_id;  // RO
} CXL_DEV_CAP_HDR2_0_t;

localparam CXL_DEV_CAP_HDR2_0_REG_STRIDE = 48'h4;
localparam CXL_DEV_CAP_HDR2_0_REG_ENTRIES = 1;
localparam [47:0] CXL_DEV_CAP_HDR2_0_CR_ADDR = 48'h180020;
localparam CXL_DEV_CAP_HDR2_0_SIZE = 32;
localparam CXL_DEV_CAP_HDR2_0_VERSION_LO = 16;
localparam CXL_DEV_CAP_HDR2_0_VERSION_HI = 23;
localparam CXL_DEV_CAP_HDR2_0_VERSION_RESET = 8'h1;
localparam CXL_DEV_CAP_HDR2_0_CAP_ID_LO = 0;
localparam CXL_DEV_CAP_HDR2_0_CAP_ID_HI = 15;
localparam CXL_DEV_CAP_HDR2_0_CAP_ID_RESET = 16'h4000;
localparam CXL_DEV_CAP_HDR2_0_USEMASK = 32'hFFFFFF;
localparam CXL_DEV_CAP_HDR2_0_RO_MASK = 32'hFFFFFF;
localparam CXL_DEV_CAP_HDR2_0_WO_MASK = 32'h0;
localparam CXL_DEV_CAP_HDR2_0_RESET = 32'h14000;

typedef struct packed {
    logic [31:0] offset;  // RO
} CXL_DEV_CAP_HDR2_1_t;

localparam CXL_DEV_CAP_HDR2_1_REG_STRIDE = 48'h4;
localparam CXL_DEV_CAP_HDR2_1_REG_ENTRIES = 1;
localparam [47:0] CXL_DEV_CAP_HDR2_1_CR_ADDR = 48'h180024;
localparam CXL_DEV_CAP_HDR2_1_SIZE = 32;
localparam CXL_DEV_CAP_HDR2_1_OFFSET_LO = 0;
localparam CXL_DEV_CAP_HDR2_1_OFFSET_HI = 31;
localparam CXL_DEV_CAP_HDR2_1_OFFSET_RESET = 32'h58;
localparam CXL_DEV_CAP_HDR2_1_USEMASK = 32'hFFFFFFFF;
localparam CXL_DEV_CAP_HDR2_1_RO_MASK = 32'hFFFFFFFF;
localparam CXL_DEV_CAP_HDR2_1_WO_MASK = 32'h0;
localparam CXL_DEV_CAP_HDR2_1_RESET = 32'h58;

typedef struct packed {
    logic [31:0] length;  // RO
} CXL_DEV_CAP_HDR2_2_t;

localparam CXL_DEV_CAP_HDR2_2_REG_STRIDE = 48'h4;
localparam CXL_DEV_CAP_HDR2_2_REG_ENTRIES = 1;
localparam [47:0] CXL_DEV_CAP_HDR2_2_CR_ADDR = 48'h180028;
localparam CXL_DEV_CAP_HDR2_2_SIZE = 32;
localparam CXL_DEV_CAP_HDR2_2_LENGTH_LO = 0;
localparam CXL_DEV_CAP_HDR2_2_LENGTH_HI = 31;
localparam CXL_DEV_CAP_HDR2_2_LENGTH_RESET = 32'h8;
localparam CXL_DEV_CAP_HDR2_2_USEMASK = 32'hFFFFFFFF;
localparam CXL_DEV_CAP_HDR2_2_RO_MASK = 32'hFFFFFFFF;
localparam CXL_DEV_CAP_HDR2_2_WO_MASK = 32'h0;
localparam CXL_DEV_CAP_HDR2_2_RESET = 32'h8;

typedef struct packed {
    logic  [7:0] reserved0;  // RSVD
    logic  [7:0] version;  // RO
    logic [15:0] cap_id;  // RO
} CXL_DEV_CAP_HDR3_0_t;

localparam CXL_DEV_CAP_HDR3_0_REG_STRIDE = 48'h4;
localparam CXL_DEV_CAP_HDR3_0_REG_ENTRIES = 1;
localparam [47:0] CXL_DEV_CAP_HDR3_0_CR_ADDR = 48'h180030;
localparam CXL_DEV_CAP_HDR3_0_SIZE = 32;
localparam CXL_DEV_CAP_HDR3_0_VERSION_LO = 16;
localparam CXL_DEV_CAP_HDR3_0_VERSION_HI = 23;
localparam CXL_DEV_CAP_HDR3_0_VERSION_RESET = 8'h1;
localparam CXL_DEV_CAP_HDR3_0_CAP_ID_LO = 0;
localparam CXL_DEV_CAP_HDR3_0_CAP_ID_HI = 15;
localparam CXL_DEV_CAP_HDR3_0_CAP_ID_RESET = 16'h2;
localparam CXL_DEV_CAP_HDR3_0_USEMASK = 32'hFFFFFF;
localparam CXL_DEV_CAP_HDR3_0_RO_MASK = 32'hFFFFFF;
localparam CXL_DEV_CAP_HDR3_0_WO_MASK = 32'h0;
localparam CXL_DEV_CAP_HDR3_0_RESET = 32'h10002;

typedef struct packed {
    logic [31:0] offset;  // RO
} CXL_DEV_CAP_HDR3_1_t;

localparam CXL_DEV_CAP_HDR3_1_REG_STRIDE = 48'h4;
localparam CXL_DEV_CAP_HDR3_1_REG_ENTRIES = 1;
localparam [47:0] CXL_DEV_CAP_HDR3_1_CR_ADDR = 48'h180034;
localparam CXL_DEV_CAP_HDR3_1_SIZE = 32;
localparam CXL_DEV_CAP_HDR3_1_OFFSET_LO = 0;
localparam CXL_DEV_CAP_HDR3_1_OFFSET_HI = 31;
localparam CXL_DEV_CAP_HDR3_1_OFFSET_RESET = 32'h60;
localparam CXL_DEV_CAP_HDR3_1_USEMASK = 32'hFFFFFFFF;
localparam CXL_DEV_CAP_HDR3_1_RO_MASK = 32'hFFFFFFFF;
localparam CXL_DEV_CAP_HDR3_1_WO_MASK = 32'h0;
localparam CXL_DEV_CAP_HDR3_1_RESET = 32'h60;

typedef struct packed {
    logic [31:0] length;  // RO
} CXL_DEV_CAP_HDR3_2_t;

localparam CXL_DEV_CAP_HDR3_2_REG_STRIDE = 48'h4;
localparam CXL_DEV_CAP_HDR3_2_REG_ENTRIES = 1;
localparam [47:0] CXL_DEV_CAP_HDR3_2_CR_ADDR = 48'h180038;
localparam CXL_DEV_CAP_HDR3_2_SIZE = 32;
localparam CXL_DEV_CAP_HDR3_2_LENGTH_LO = 0;
localparam CXL_DEV_CAP_HDR3_2_LENGTH_HI = 31;
localparam CXL_DEV_CAP_HDR3_2_LENGTH_RESET = 32'h820;
localparam CXL_DEV_CAP_HDR3_2_USEMASK = 32'hFFFFFFFF;
localparam CXL_DEV_CAP_HDR3_2_RO_MASK = 32'hFFFFFFFF;
localparam CXL_DEV_CAP_HDR3_2_WO_MASK = 32'h0;
localparam CXL_DEV_CAP_HDR3_2_RESET = 32'h820;

typedef struct packed {
    logic [27:0] reserved0;  // RSVD
    logic  [0:0] fatal_event_log;  // RO/V
    logic  [0:0] failure_event_log;  // RO/V
    logic  [0:0] warning_event_log;  // RO/V
    logic  [0:0] info_event_log;  // RO/V
} CXL_DEV_CAP_EVENT_STATUS_t;

localparam CXL_DEV_CAP_EVENT_STATUS_REG_STRIDE = 48'h4;
localparam CXL_DEV_CAP_EVENT_STATUS_REG_ENTRIES = 1;
localparam [47:0] CXL_DEV_CAP_EVENT_STATUS_CR_ADDR = 48'h180050;
localparam CXL_DEV_CAP_EVENT_STATUS_SIZE = 32;
localparam CXL_DEV_CAP_EVENT_STATUS_FATAL_EVENT_LOG_LO = 3;
localparam CXL_DEV_CAP_EVENT_STATUS_FATAL_EVENT_LOG_HI = 3;
localparam CXL_DEV_CAP_EVENT_STATUS_FATAL_EVENT_LOG_RESET = 1'b0;
localparam CXL_DEV_CAP_EVENT_STATUS_FAILURE_EVENT_LOG_LO = 2;
localparam CXL_DEV_CAP_EVENT_STATUS_FAILURE_EVENT_LOG_HI = 2;
localparam CXL_DEV_CAP_EVENT_STATUS_FAILURE_EVENT_LOG_RESET = 1'b0;
localparam CXL_DEV_CAP_EVENT_STATUS_WARNING_EVENT_LOG_LO = 1;
localparam CXL_DEV_CAP_EVENT_STATUS_WARNING_EVENT_LOG_HI = 1;
localparam CXL_DEV_CAP_EVENT_STATUS_WARNING_EVENT_LOG_RESET = 1'b0;
localparam CXL_DEV_CAP_EVENT_STATUS_INFO_EVENT_LOG_LO = 0;
localparam CXL_DEV_CAP_EVENT_STATUS_INFO_EVENT_LOG_HI = 0;
localparam CXL_DEV_CAP_EVENT_STATUS_INFO_EVENT_LOG_RESET = 1'b0;
localparam CXL_DEV_CAP_EVENT_STATUS_USEMASK = 32'hF;
localparam CXL_DEV_CAP_EVENT_STATUS_RO_MASK = 32'hF;
localparam CXL_DEV_CAP_EVENT_STATUS_WO_MASK = 32'h0;
localparam CXL_DEV_CAP_EVENT_STATUS_RESET = 32'h0;

typedef struct packed {
    logic [23:0] reserved0;  // RSVD
    logic  [2:0] reset_needed;  // RO/V
    logic  [0:0] mailbox_if_ready;  // RO/V
    logic  [1:0] media_status;  // RO/V
    logic  [0:0] fw_halt;  // RO/V
    logic  [0:0] device_fatal;  // RO/V
} CXL_MEM_DEV_STATUS_t;

localparam CXL_MEM_DEV_STATUS_REG_STRIDE = 48'h4;
localparam CXL_MEM_DEV_STATUS_REG_ENTRIES = 1;
localparam [47:0] CXL_MEM_DEV_STATUS_CR_ADDR = 48'h180058;
localparam CXL_MEM_DEV_STATUS_SIZE = 32;
localparam CXL_MEM_DEV_STATUS_RESET_NEEDED_LO = 5;
localparam CXL_MEM_DEV_STATUS_RESET_NEEDED_HI = 7;
localparam CXL_MEM_DEV_STATUS_RESET_NEEDED_RESET = 3'b0;
localparam CXL_MEM_DEV_STATUS_MAILBOX_IF_READY_LO = 4;
localparam CXL_MEM_DEV_STATUS_MAILBOX_IF_READY_HI = 4;
localparam CXL_MEM_DEV_STATUS_MAILBOX_IF_READY_RESET = 1'b1;
localparam CXL_MEM_DEV_STATUS_MEDIA_STATUS_LO = 2;
localparam CXL_MEM_DEV_STATUS_MEDIA_STATUS_HI = 3;
localparam CXL_MEM_DEV_STATUS_MEDIA_STATUS_RESET = 2'b1;
localparam CXL_MEM_DEV_STATUS_FW_HALT_LO = 1;
localparam CXL_MEM_DEV_STATUS_FW_HALT_HI = 1;
localparam CXL_MEM_DEV_STATUS_FW_HALT_RESET = 1'b0;
localparam CXL_MEM_DEV_STATUS_DEVICE_FATAL_LO = 0;
localparam CXL_MEM_DEV_STATUS_DEVICE_FATAL_HI = 0;
localparam CXL_MEM_DEV_STATUS_DEVICE_FATAL_RESET = 1'b0;
localparam CXL_MEM_DEV_STATUS_USEMASK = 32'hFF;
localparam CXL_MEM_DEV_STATUS_RO_MASK = 32'hFF;
localparam CXL_MEM_DEV_STATUS_WO_MASK = 32'h0;
localparam CXL_MEM_DEV_STATUS_RESET = 32'h14;

typedef struct packed {
    logic [20:0] reserved0;  // RSVD
    logic  [3:0] int_msg_num;  // RO
    logic  [0:0] bk_cmd_comp_int_cap;  // RO
    logic  [0:0] mb_doorbell_int_cap;  // RO
    logic  [4:0] payload_size;  // RO
} CXL_MB_CAP_t;

localparam CXL_MB_CAP_REG_STRIDE = 48'h4;
localparam CXL_MB_CAP_REG_ENTRIES = 1;
localparam [47:0] CXL_MB_CAP_CR_ADDR = 48'h180060;
localparam CXL_MB_CAP_SIZE = 32;
localparam CXL_MB_CAP_INT_MSG_NUM_LO = 7;
localparam CXL_MB_CAP_INT_MSG_NUM_HI = 10;
localparam CXL_MB_CAP_INT_MSG_NUM_RESET = 4'b0;
localparam CXL_MB_CAP_BK_CMD_COMP_INT_CAP_LO = 6;
localparam CXL_MB_CAP_BK_CMD_COMP_INT_CAP_HI = 6;
localparam CXL_MB_CAP_BK_CMD_COMP_INT_CAP_RESET = 1'b0;
localparam CXL_MB_CAP_MB_DOORBELL_INT_CAP_LO = 5;
localparam CXL_MB_CAP_MB_DOORBELL_INT_CAP_HI = 5;
localparam CXL_MB_CAP_MB_DOORBELL_INT_CAP_RESET = 1'b0;
localparam CXL_MB_CAP_PAYLOAD_SIZE_LO = 0;
localparam CXL_MB_CAP_PAYLOAD_SIZE_HI = 4;
localparam CXL_MB_CAP_PAYLOAD_SIZE_RESET = 5'b1011;
localparam CXL_MB_CAP_USEMASK = 32'h7FF;
localparam CXL_MB_CAP_RO_MASK = 32'h7FF;
localparam CXL_MB_CAP_WO_MASK = 32'h0;
localparam CXL_MB_CAP_RESET = 32'hB;

typedef struct packed {
    logic [28:0] reserved0;  // RSVD
    logic  [0:0] bk_cmd_comp_int;  // RW
    logic  [0:0] mb_doorbell_int;  // RW
    logic  [0:0] doorbell;  // RW/V
} CXL_MB_CTRL_t;

localparam CXL_MB_CTRL_REG_STRIDE = 48'h4;
localparam CXL_MB_CTRL_REG_ENTRIES = 1;
localparam [47:0] CXL_MB_CTRL_CR_ADDR = 48'h180064;
localparam CXL_MB_CTRL_SIZE = 32;
localparam CXL_MB_CTRL_BK_CMD_COMP_INT_LO = 2;
localparam CXL_MB_CTRL_BK_CMD_COMP_INT_HI = 2;
localparam CXL_MB_CTRL_BK_CMD_COMP_INT_RESET = 1'b0;
localparam CXL_MB_CTRL_MB_DOORBELL_INT_LO = 1;
localparam CXL_MB_CTRL_MB_DOORBELL_INT_HI = 1;
localparam CXL_MB_CTRL_MB_DOORBELL_INT_RESET = 1'b0;
localparam CXL_MB_CTRL_DOORBELL_LO = 0;
localparam CXL_MB_CTRL_DOORBELL_HI = 0;
localparam CXL_MB_CTRL_DOORBELL_RESET = 1'b0;
localparam CXL_MB_CTRL_USEMASK = 32'h7;
localparam CXL_MB_CTRL_RO_MASK = 32'h0;
localparam CXL_MB_CTRL_WO_MASK = 32'h0;
localparam CXL_MB_CTRL_RESET = 32'h0;

typedef struct packed {
    logic [26:0] reserved0;  // RSVD
    logic [20:0] payload_len;  // RW/V
    logic [15:0] command_op;  // RW
} CXL_MB_CMD_t;

localparam CXL_MB_CMD_REG_STRIDE = 48'h8;
localparam CXL_MB_CMD_REG_ENTRIES = 1;
localparam [47:0] CXL_MB_CMD_CR_ADDR = 48'h180068;
localparam CXL_MB_CMD_SIZE = 64;
localparam CXL_MB_CMD_PAYLOAD_LEN_LO = 16;
localparam CXL_MB_CMD_PAYLOAD_LEN_HI = 36;
localparam CXL_MB_CMD_PAYLOAD_LEN_RESET = 21'b0;
localparam CXL_MB_CMD_COMMAND_OP_LO = 0;
localparam CXL_MB_CMD_COMMAND_OP_HI = 15;
localparam CXL_MB_CMD_COMMAND_OP_RESET = 16'b0;
localparam CXL_MB_CMD_USEMASK = 64'h1FFFFFFFFF;
localparam CXL_MB_CMD_RO_MASK = 64'h0;
localparam CXL_MB_CMD_WO_MASK = 64'h0;
localparam CXL_MB_CMD_RESET = 64'h0;

typedef struct packed {
    logic [15:0] vendor_specfic_ext_status;  // RO/V
    logic [15:0] return_code;  // RO/V
    logic [30:0] reserved0;  // RSVD
    logic  [0:0] bk_operation;  // RO/V
} CXL_MB_STATUS_t;

localparam CXL_MB_STATUS_REG_STRIDE = 48'h8;
localparam CXL_MB_STATUS_REG_ENTRIES = 1;
localparam [47:0] CXL_MB_STATUS_CR_ADDR = 48'h180070;
localparam CXL_MB_STATUS_SIZE = 64;
localparam CXL_MB_STATUS_VENDOR_SPECFIC_EXT_STATUS_LO = 48;
localparam CXL_MB_STATUS_VENDOR_SPECFIC_EXT_STATUS_HI = 63;
localparam CXL_MB_STATUS_VENDOR_SPECFIC_EXT_STATUS_RESET = 16'b0;
localparam CXL_MB_STATUS_RETURN_CODE_LO = 32;
localparam CXL_MB_STATUS_RETURN_CODE_HI = 47;
localparam CXL_MB_STATUS_RETURN_CODE_RESET = 16'b0;
localparam CXL_MB_STATUS_BK_OPERATION_LO = 0;
localparam CXL_MB_STATUS_BK_OPERATION_HI = 0;
localparam CXL_MB_STATUS_BK_OPERATION_RESET = 1'b0;
localparam CXL_MB_STATUS_USEMASK = 64'hFFFFFFFF00000001;
localparam CXL_MB_STATUS_RO_MASK = 64'hFFFFFFFF00000001;
localparam CXL_MB_STATUS_WO_MASK = 64'h0;
localparam CXL_MB_STATUS_RESET = 64'h0;

typedef struct packed {
    logic [15:0] vendor_specfic_ext_status;  // RO/V
    logic [15:0] return_code;  // RO/V
    logic  [8:0] reserved0;  // RSVD
    logic  [6:0] percentage_comp;  // RO/V
    logic [15:0] cmd_opcode;  // RO/V
} CXL_MB_BK_CMD_STATUS_t;

localparam CXL_MB_BK_CMD_STATUS_REG_STRIDE = 48'h8;
localparam CXL_MB_BK_CMD_STATUS_REG_ENTRIES = 1;
localparam [47:0] CXL_MB_BK_CMD_STATUS_CR_ADDR = 48'h180078;
localparam CXL_MB_BK_CMD_STATUS_SIZE = 64;
localparam CXL_MB_BK_CMD_STATUS_VENDOR_SPECFIC_EXT_STATUS_LO = 48;
localparam CXL_MB_BK_CMD_STATUS_VENDOR_SPECFIC_EXT_STATUS_HI = 63;
localparam CXL_MB_BK_CMD_STATUS_VENDOR_SPECFIC_EXT_STATUS_RESET = 16'b0;
localparam CXL_MB_BK_CMD_STATUS_RETURN_CODE_LO = 32;
localparam CXL_MB_BK_CMD_STATUS_RETURN_CODE_HI = 47;
localparam CXL_MB_BK_CMD_STATUS_RETURN_CODE_RESET = 16'b0;
localparam CXL_MB_BK_CMD_STATUS_PERCENTAGE_COMP_LO = 16;
localparam CXL_MB_BK_CMD_STATUS_PERCENTAGE_COMP_HI = 22;
localparam CXL_MB_BK_CMD_STATUS_PERCENTAGE_COMP_RESET = 7'b0;
localparam CXL_MB_BK_CMD_STATUS_CMD_OPCODE_LO = 0;
localparam CXL_MB_BK_CMD_STATUS_CMD_OPCODE_HI = 15;
localparam CXL_MB_BK_CMD_STATUS_CMD_OPCODE_RESET = 16'b0;
localparam CXL_MB_BK_CMD_STATUS_USEMASK = 64'hFFFFFFFF007FFFFF;
localparam CXL_MB_BK_CMD_STATUS_RO_MASK = 64'hFFFFFFFF007FFFFF;
localparam CXL_MB_BK_CMD_STATUS_WO_MASK = 64'h0;
localparam CXL_MB_BK_CMD_STATUS_RESET = 64'h0;

typedef struct packed {
    logic [31:0] mailbox_payload_start;  // RW
} CXL_MB_PAY_START_t;

localparam CXL_MB_PAY_START_REG_STRIDE = 48'h4;
localparam CXL_MB_PAY_START_REG_ENTRIES = 1;
localparam [47:0] CXL_MB_PAY_START_CR_ADDR = 48'h180080;
localparam CXL_MB_PAY_START_SIZE = 32;
localparam CXL_MB_PAY_START_MAILBOX_PAYLOAD_START_LO = 0;
localparam CXL_MB_PAY_START_MAILBOX_PAYLOAD_START_HI = 31;
localparam CXL_MB_PAY_START_MAILBOX_PAYLOAD_START_RESET = 32'h0;
localparam CXL_MB_PAY_START_USEMASK = 32'hFFFFFFFF;
localparam CXL_MB_PAY_START_RO_MASK = 32'h0;
localparam CXL_MB_PAY_START_WO_MASK = 32'h0;
localparam CXL_MB_PAY_START_RESET = 32'h0;

typedef struct packed {
    logic [31:0] mailbox_payload_end;  // RW
} CXL_MB_PAY_END_t;

localparam CXL_MB_PAY_END_REG_STRIDE = 48'h4;
localparam CXL_MB_PAY_END_REG_ENTRIES = 1;
localparam [47:0] CXL_MB_PAY_END_CR_ADDR = 48'h18087C;
localparam CXL_MB_PAY_END_SIZE = 32;
localparam CXL_MB_PAY_END_MAILBOX_PAYLOAD_END_LO = 0;
localparam CXL_MB_PAY_END_MAILBOX_PAYLOAD_END_HI = 31;
localparam CXL_MB_PAY_END_MAILBOX_PAYLOAD_END_RESET = 32'h0;
localparam CXL_MB_PAY_END_USEMASK = 32'hFFFFFFFF;
localparam CXL_MB_PAY_END_RO_MASK = 32'h0;
localparam CXL_MB_PAY_END_WO_MASK = 32'h0;
localparam CXL_MB_PAY_END_RESET = 32'h0;

typedef struct packed {
    logic [18:0] reserved0;  // RSVD
    logic  [0:0] support_16_way;  // RO
    logic  [0:0] support_3_6_12_way;  // RO
    logic  [0:0] poison_on_err;  // RO
    logic  [0:0] addr14_12;  // RO
    logic  [0:0] addr11_8;  // RO
    logic  [3:0] tgt_cnt;  // RO
    logic  [3:0] dec_cnt;  // RO
} HDM_DEC_CAP_t;

localparam HDM_DEC_CAP_REG_STRIDE = 48'h4;
localparam HDM_DEC_CAP_REG_ENTRIES = 1;
localparam [47:0] HDM_DEC_CAP_CR_ADDR = 48'h181000;
localparam HDM_DEC_CAP_SIZE = 32;
localparam HDM_DEC_CAP_SUPPORT_16_WAY_LO = 12;
localparam HDM_DEC_CAP_SUPPORT_16_WAY_HI = 12;
localparam HDM_DEC_CAP_SUPPORT_16_WAY_RESET = 1'b0;
localparam HDM_DEC_CAP_SUPPORT_3_6_12_WAY_LO = 11;
localparam HDM_DEC_CAP_SUPPORT_3_6_12_WAY_HI = 11;
localparam HDM_DEC_CAP_SUPPORT_3_6_12_WAY_RESET = 1'b0;
localparam HDM_DEC_CAP_POISON_ON_ERR_LO = 10;
localparam HDM_DEC_CAP_POISON_ON_ERR_HI = 10;
localparam HDM_DEC_CAP_POISON_ON_ERR_RESET = 1'b0;
localparam HDM_DEC_CAP_ADDR14_12_LO = 9;
localparam HDM_DEC_CAP_ADDR14_12_HI = 9;
localparam HDM_DEC_CAP_ADDR14_12_RESET = 1'b0;
localparam HDM_DEC_CAP_ADDR11_8_LO = 8;
localparam HDM_DEC_CAP_ADDR11_8_HI = 8;
localparam HDM_DEC_CAP_ADDR11_8_RESET = 1'b0;
localparam HDM_DEC_CAP_TGT_CNT_LO = 4;
localparam HDM_DEC_CAP_TGT_CNT_HI = 7;
localparam HDM_DEC_CAP_TGT_CNT_RESET = 4'h0;
localparam HDM_DEC_CAP_DEC_CNT_LO = 0;
localparam HDM_DEC_CAP_DEC_CNT_HI = 3;
localparam HDM_DEC_CAP_DEC_CNT_RESET = 4'h0;
localparam HDM_DEC_CAP_USEMASK = 32'h1FFF;
localparam HDM_DEC_CAP_RO_MASK = 32'h1FFF;
localparam HDM_DEC_CAP_WO_MASK = 32'h0;
localparam HDM_DEC_CAP_RESET = 32'h0;

typedef struct packed {
    logic [29:0] reserved0;  // RSVD
    logic  [0:0] dec_enable;  // RW
    logic  [0:0] poison_on_err_enable;  // RO
} HDM_DEC_GBL_CTRL_t;

localparam HDM_DEC_GBL_CTRL_REG_STRIDE = 48'h4;
localparam HDM_DEC_GBL_CTRL_REG_ENTRIES = 1;
localparam [47:0] HDM_DEC_GBL_CTRL_CR_ADDR = 48'h181004;
localparam HDM_DEC_GBL_CTRL_SIZE = 32;
localparam HDM_DEC_GBL_CTRL_DEC_ENABLE_LO = 1;
localparam HDM_DEC_GBL_CTRL_DEC_ENABLE_HI = 1;
localparam HDM_DEC_GBL_CTRL_DEC_ENABLE_RESET = 1'b0;
localparam HDM_DEC_GBL_CTRL_POISON_ON_ERR_ENABLE_LO = 0;
localparam HDM_DEC_GBL_CTRL_POISON_ON_ERR_ENABLE_HI = 0;
localparam HDM_DEC_GBL_CTRL_POISON_ON_ERR_ENABLE_RESET = 1'b0;
localparam HDM_DEC_GBL_CTRL_USEMASK = 32'h3;
localparam HDM_DEC_GBL_CTRL_RO_MASK = 32'h1;
localparam HDM_DEC_GBL_CTRL_WO_MASK = 32'h0;
localparam HDM_DEC_GBL_CTRL_RESET = 32'h0;

typedef struct packed {
    logic  [3:0] mem_base_low;  // RW/L
    logic [27:0] reserved0;  // RSVD
} HDM_DEC_BASELOW_t;

localparam HDM_DEC_BASELOW_REG_STRIDE = 48'h4;
localparam HDM_DEC_BASELOW_REG_ENTRIES = 1;
localparam [47:0] HDM_DEC_BASELOW_CR_ADDR = 48'h181010;
localparam HDM_DEC_BASELOW_SIZE = 32;
localparam HDM_DEC_BASELOW_MEM_BASE_LOW_LO = 28;
localparam HDM_DEC_BASELOW_MEM_BASE_LOW_HI = 31;
localparam HDM_DEC_BASELOW_MEM_BASE_LOW_RESET = 4'h0;
localparam HDM_DEC_BASELOW_USEMASK = 32'hF0000000;
localparam HDM_DEC_BASELOW_RO_MASK = 32'h0;
localparam HDM_DEC_BASELOW_WO_MASK = 32'h0;
localparam HDM_DEC_BASELOW_RESET = 32'h0;

typedef struct packed {
    logic [31:0] mem_base_high;  // RW/L
} HDM_DEC_BASEHIGH_t;

localparam HDM_DEC_BASEHIGH_REG_STRIDE = 48'h4;
localparam HDM_DEC_BASEHIGH_REG_ENTRIES = 1;
localparam [47:0] HDM_DEC_BASEHIGH_CR_ADDR = 48'h181014;
localparam HDM_DEC_BASEHIGH_SIZE = 32;
localparam HDM_DEC_BASEHIGH_MEM_BASE_HIGH_LO = 0;
localparam HDM_DEC_BASEHIGH_MEM_BASE_HIGH_HI = 31;
localparam HDM_DEC_BASEHIGH_MEM_BASE_HIGH_RESET = 32'h0;
localparam HDM_DEC_BASEHIGH_USEMASK = 32'hFFFFFFFF;
localparam HDM_DEC_BASEHIGH_RO_MASK = 32'h0;
localparam HDM_DEC_BASEHIGH_WO_MASK = 32'h0;
localparam HDM_DEC_BASEHIGH_RESET = 32'h0;

typedef struct packed {
    logic  [3:0] mem_size_low;  // RW/L
    logic [27:0] reserved0;  // RSVD
} HDM_DEC_SIZELOW_t;

localparam HDM_DEC_SIZELOW_REG_STRIDE = 48'h4;
localparam HDM_DEC_SIZELOW_REG_ENTRIES = 1;
localparam [47:0] HDM_DEC_SIZELOW_CR_ADDR = 48'h181018;
localparam HDM_DEC_SIZELOW_SIZE = 32;
localparam HDM_DEC_SIZELOW_MEM_SIZE_LOW_LO = 28;
localparam HDM_DEC_SIZELOW_MEM_SIZE_LOW_HI = 31;
localparam HDM_DEC_SIZELOW_MEM_SIZE_LOW_RESET = 4'h0;
localparam HDM_DEC_SIZELOW_USEMASK = 32'hF0000000;
localparam HDM_DEC_SIZELOW_RO_MASK = 32'h0;
localparam HDM_DEC_SIZELOW_WO_MASK = 32'h0;
localparam HDM_DEC_SIZELOW_RESET = 32'h0;

typedef struct packed {
    logic [31:0] mem_size_high;  // RW/L
} HDM_DEC_SIZEHIGH_t;

localparam HDM_DEC_SIZEHIGH_REG_STRIDE = 48'h4;
localparam HDM_DEC_SIZEHIGH_REG_ENTRIES = 1;
localparam [47:0] HDM_DEC_SIZEHIGH_CR_ADDR = 48'h18101C;
localparam HDM_DEC_SIZEHIGH_SIZE = 32;
localparam HDM_DEC_SIZEHIGH_MEM_SIZE_HIGH_LO = 0;
localparam HDM_DEC_SIZEHIGH_MEM_SIZE_HIGH_HI = 31;
localparam HDM_DEC_SIZEHIGH_MEM_SIZE_HIGH_RESET = 32'h0;
localparam HDM_DEC_SIZEHIGH_USEMASK = 32'hFFFFFFFF;
localparam HDM_DEC_SIZEHIGH_RO_MASK = 32'h0;
localparam HDM_DEC_SIZEHIGH_WO_MASK = 32'h0;
localparam HDM_DEC_SIZEHIGH_RESET = 32'h0;

typedef struct packed {
    logic [18:0] reserved0;  // RSVD
    logic  [0:0] target_dev_type;  // RW/L
    logic  [0:0] err_not_committed;  // RO
    logic  [0:0] committed;  // RO/V
    logic  [0:0] commit;  // RW/L
    logic  [0:0] lock_on_commit;  // RW/L
    logic  [3:0] interleave_ways;  // RW/L
    logic  [3:0] interleave_granularity;  // RW/L
} HDM_DEC_CTRL_t;

localparam HDM_DEC_CTRL_REG_STRIDE = 48'h4;
localparam HDM_DEC_CTRL_REG_ENTRIES = 1;
localparam [47:0] HDM_DEC_CTRL_CR_ADDR = 48'h181020;
localparam HDM_DEC_CTRL_SIZE = 32;
localparam HDM_DEC_CTRL_TARGET_DEV_TYPE_LO = 12;
localparam HDM_DEC_CTRL_TARGET_DEV_TYPE_HI = 12;
localparam HDM_DEC_CTRL_TARGET_DEV_TYPE_RESET = 1'b0;
localparam HDM_DEC_CTRL_ERR_NOT_COMMITTED_LO = 11;
localparam HDM_DEC_CTRL_ERR_NOT_COMMITTED_HI = 11;
localparam HDM_DEC_CTRL_ERR_NOT_COMMITTED_RESET = 1'b0;
localparam HDM_DEC_CTRL_COMMITTED_LO = 10;
localparam HDM_DEC_CTRL_COMMITTED_HI = 10;
localparam HDM_DEC_CTRL_COMMITTED_RESET = 1'b0;
localparam HDM_DEC_CTRL_COMMIT_LO = 9;
localparam HDM_DEC_CTRL_COMMIT_HI = 9;
localparam HDM_DEC_CTRL_COMMIT_RESET = 1'b0;
localparam HDM_DEC_CTRL_LOCK_ON_COMMIT_LO = 8;
localparam HDM_DEC_CTRL_LOCK_ON_COMMIT_HI = 8;
localparam HDM_DEC_CTRL_LOCK_ON_COMMIT_RESET = 1'b0;
localparam HDM_DEC_CTRL_INTERLEAVE_WAYS_LO = 4;
localparam HDM_DEC_CTRL_INTERLEAVE_WAYS_HI = 7;
localparam HDM_DEC_CTRL_INTERLEAVE_WAYS_RESET = 4'b0;
localparam HDM_DEC_CTRL_INTERLEAVE_GRANULARITY_LO = 0;
localparam HDM_DEC_CTRL_INTERLEAVE_GRANULARITY_HI = 3;
localparam HDM_DEC_CTRL_INTERLEAVE_GRANULARITY_RESET = 4'b0;
localparam HDM_DEC_CTRL_USEMASK = 32'h1FFF;
localparam HDM_DEC_CTRL_RO_MASK = 32'hC00;
localparam HDM_DEC_CTRL_WO_MASK = 32'h0;
localparam HDM_DEC_CTRL_RESET = 32'h0;

typedef struct packed {
    logic  [3:0] dpa_skip_low;  // RW/L
    logic [27:0] reserved0;  // RSVD
} HDM_DEC_DPALOW_t;

localparam HDM_DEC_DPALOW_REG_STRIDE = 48'h4;
localparam HDM_DEC_DPALOW_REG_ENTRIES = 1;
localparam [47:0] HDM_DEC_DPALOW_CR_ADDR = 48'h181024;
localparam HDM_DEC_DPALOW_SIZE = 32;
localparam HDM_DEC_DPALOW_DPA_SKIP_LOW_LO = 28;
localparam HDM_DEC_DPALOW_DPA_SKIP_LOW_HI = 31;
localparam HDM_DEC_DPALOW_DPA_SKIP_LOW_RESET = 4'h0;
localparam HDM_DEC_DPALOW_USEMASK = 32'hF0000000;
localparam HDM_DEC_DPALOW_RO_MASK = 32'h0;
localparam HDM_DEC_DPALOW_WO_MASK = 32'h0;
localparam HDM_DEC_DPALOW_RESET = 32'h0;

typedef struct packed {
    logic [31:0] dpa_skip_high;  // RW/L
} HDM_DEC_DPAHIGH_t;

localparam HDM_DEC_DPAHIGH_REG_STRIDE = 48'h4;
localparam HDM_DEC_DPAHIGH_REG_ENTRIES = 1;
localparam [47:0] HDM_DEC_DPAHIGH_CR_ADDR = 48'h181028;
localparam HDM_DEC_DPAHIGH_SIZE = 32;
localparam HDM_DEC_DPAHIGH_DPA_SKIP_HIGH_LO = 0;
localparam HDM_DEC_DPAHIGH_DPA_SKIP_HIGH_HI = 31;
localparam HDM_DEC_DPAHIGH_DPA_SKIP_HIGH_RESET = 32'h0;
localparam HDM_DEC_DPAHIGH_USEMASK = 32'hFFFFFFFF;
localparam HDM_DEC_DPAHIGH_RO_MASK = 32'h0;
localparam HDM_DEC_DPAHIGH_WO_MASK = 32'h0;
localparam HDM_DEC_DPAHIGH_RESET = 32'h0;

typedef struct packed {
    logic [11:0] reserved0;  // RSVD
    logic [51:0] config_test_start_addr;  // RW
} CONFIG_TEST_START_ADDR_t;

localparam CONFIG_TEST_START_ADDR_REG_STRIDE = 48'h8;
localparam CONFIG_TEST_START_ADDR_REG_ENTRIES = 1;
localparam [47:0] CONFIG_TEST_START_ADDR_CR_ADDR = 48'h181400;
localparam CONFIG_TEST_START_ADDR_SIZE = 64;
localparam CONFIG_TEST_START_ADDR_CONFIG_TEST_START_ADDR_LO = 0;
localparam CONFIG_TEST_START_ADDR_CONFIG_TEST_START_ADDR_HI = 51;
localparam CONFIG_TEST_START_ADDR_CONFIG_TEST_START_ADDR_RESET = 64'h0;
localparam CONFIG_TEST_START_ADDR_USEMASK = 64'hFFFFFFFFFFFFF;
localparam CONFIG_TEST_START_ADDR_RO_MASK = 64'h0;
localparam CONFIG_TEST_START_ADDR_WO_MASK = 64'h0;
localparam CONFIG_TEST_START_ADDR_RESET = 64'h0;

typedef struct packed {
    logic [11:0] reserved0;  // RSVD
    logic [51:0] config_test_wrback_addr;  // RW
} CONFIG_TEST_WR_BACK_ADDR_t;

localparam CONFIG_TEST_WR_BACK_ADDR_REG_STRIDE = 48'h8;
localparam CONFIG_TEST_WR_BACK_ADDR_REG_ENTRIES = 1;
localparam [47:0] CONFIG_TEST_WR_BACK_ADDR_CR_ADDR = 48'h181408;
localparam CONFIG_TEST_WR_BACK_ADDR_SIZE = 64;
localparam CONFIG_TEST_WR_BACK_ADDR_CONFIG_TEST_WRBACK_ADDR_LO = 0;
localparam CONFIG_TEST_WR_BACK_ADDR_CONFIG_TEST_WRBACK_ADDR_HI = 51;
localparam CONFIG_TEST_WR_BACK_ADDR_CONFIG_TEST_WRBACK_ADDR_RESET = 64'h0;
localparam CONFIG_TEST_WR_BACK_ADDR_USEMASK = 64'hFFFFFFFFFFFFF;
localparam CONFIG_TEST_WR_BACK_ADDR_RO_MASK = 64'h0;
localparam CONFIG_TEST_WR_BACK_ADDR_WO_MASK = 64'h0;
localparam CONFIG_TEST_WR_BACK_ADDR_RESET = 64'h0;

typedef struct packed {
    logic [31:0] config_test_addr_setoffset;  // RW
    logic [31:0] config_test_addr_incre;  // RW
} CONFIG_TEST_ADDR_INCRE_t;

localparam CONFIG_TEST_ADDR_INCRE_REG_STRIDE = 48'h8;
localparam CONFIG_TEST_ADDR_INCRE_REG_ENTRIES = 1;
localparam [47:0] CONFIG_TEST_ADDR_INCRE_CR_ADDR = 48'h181410;
localparam CONFIG_TEST_ADDR_INCRE_SIZE = 64;
localparam CONFIG_TEST_ADDR_INCRE_CONFIG_TEST_ADDR_SETOFFSET_LO = 32;
localparam CONFIG_TEST_ADDR_INCRE_CONFIG_TEST_ADDR_SETOFFSET_HI = 63;
localparam CONFIG_TEST_ADDR_INCRE_CONFIG_TEST_ADDR_SETOFFSET_RESET = 32'h0;
localparam CONFIG_TEST_ADDR_INCRE_CONFIG_TEST_ADDR_INCRE_LO = 0;
localparam CONFIG_TEST_ADDR_INCRE_CONFIG_TEST_ADDR_INCRE_HI = 31;
localparam CONFIG_TEST_ADDR_INCRE_CONFIG_TEST_ADDR_INCRE_RESET = 32'h0;
localparam CONFIG_TEST_ADDR_INCRE_USEMASK = 64'hFFFFFFFFFFFFFFFF;
localparam CONFIG_TEST_ADDR_INCRE_RO_MASK = 64'h0;
localparam CONFIG_TEST_ADDR_INCRE_WO_MASK = 64'h0;
localparam CONFIG_TEST_ADDR_INCRE_RESET = 64'h0;

typedef struct packed {
    logic [31:0] algorithm_pattern2;  // RW
    logic [31:0] algorithm_pattern1;  // RW
} CONFIG_TEST_PATTERN_t;

localparam CONFIG_TEST_PATTERN_REG_STRIDE = 48'h8;
localparam CONFIG_TEST_PATTERN_REG_ENTRIES = 1;
localparam [47:0] CONFIG_TEST_PATTERN_CR_ADDR = 48'h181418;
localparam CONFIG_TEST_PATTERN_SIZE = 64;
localparam CONFIG_TEST_PATTERN_ALGORITHM_PATTERN2_LO = 32;
localparam CONFIG_TEST_PATTERN_ALGORITHM_PATTERN2_HI = 63;
localparam CONFIG_TEST_PATTERN_ALGORITHM_PATTERN2_RESET = 32'h0;
localparam CONFIG_TEST_PATTERN_ALGORITHM_PATTERN1_LO = 0;
localparam CONFIG_TEST_PATTERN_ALGORITHM_PATTERN1_HI = 31;
localparam CONFIG_TEST_PATTERN_ALGORITHM_PATTERN1_RESET = 32'h0;
localparam CONFIG_TEST_PATTERN_USEMASK = 64'hFFFFFFFFFFFFFFFF;
localparam CONFIG_TEST_PATTERN_RO_MASK = 64'h0;
localparam CONFIG_TEST_PATTERN_WO_MASK = 64'h0;
localparam CONFIG_TEST_PATTERN_RESET = 64'h0;

typedef struct packed {
    logic [63:0] cacheline_bytemask;  // RW
} CONFIG_TEST_BYTEMASK_t;

localparam CONFIG_TEST_BYTEMASK_REG_STRIDE = 48'h8;
localparam CONFIG_TEST_BYTEMASK_REG_ENTRIES = 1;
localparam [47:0] CONFIG_TEST_BYTEMASK_CR_ADDR = 48'h181420;
localparam CONFIG_TEST_BYTEMASK_SIZE = 64;
localparam CONFIG_TEST_BYTEMASK_CACHELINE_BYTEMASK_LO = 0;
localparam CONFIG_TEST_BYTEMASK_CACHELINE_BYTEMASK_HI = 63;
localparam CONFIG_TEST_BYTEMASK_CACHELINE_BYTEMASK_RESET = 64'h0;
localparam CONFIG_TEST_BYTEMASK_USEMASK = 64'hFFFFFFFFFFFFFFFF;
localparam CONFIG_TEST_BYTEMASK_RO_MASK = 64'h0;
localparam CONFIG_TEST_BYTEMASK_WO_MASK = 64'h0;
localparam CONFIG_TEST_BYTEMASK_RESET = 64'h0;

typedef struct packed {
    logic [59:0] reserved0;  // RSVD
    logic  [0:0] pattern_parameter;  // RW
    logic  [2:0] pattern_size;  // RW
} CONFIG_TEST_PATTERN_PARAM_t;

localparam CONFIG_TEST_PATTERN_PARAM_REG_STRIDE = 48'h8;
localparam CONFIG_TEST_PATTERN_PARAM_REG_ENTRIES = 1;
localparam [47:0] CONFIG_TEST_PATTERN_PARAM_CR_ADDR = 48'h181428;
localparam CONFIG_TEST_PATTERN_PARAM_SIZE = 64;
localparam CONFIG_TEST_PATTERN_PARAM_PATTERN_PARAMETER_LO = 3;
localparam CONFIG_TEST_PATTERN_PARAM_PATTERN_PARAMETER_HI = 3;
localparam CONFIG_TEST_PATTERN_PARAM_PATTERN_PARAMETER_RESET = 1'b0;
localparam CONFIG_TEST_PATTERN_PARAM_PATTERN_SIZE_LO = 0;
localparam CONFIG_TEST_PATTERN_PARAM_PATTERN_SIZE_HI = 2;
localparam CONFIG_TEST_PATTERN_PARAM_PATTERN_SIZE_RESET = 3'b0;
localparam CONFIG_TEST_PATTERN_PARAM_USEMASK = 64'hF;
localparam CONFIG_TEST_PATTERN_PARAM_RO_MASK = 64'h0;
localparam CONFIG_TEST_PATTERN_PARAM_WO_MASK = 64'h0;
localparam CONFIG_TEST_PATTERN_PARAM_RESET = 64'h0;

typedef struct packed {
    logic [16:0] reserved0;  // RSVD
    logic  [2:0] verify_semantics_cache;  // RW
    logic  [2:0] execute_read_semantics;  // RW
    logic  [0:0] flush_cache;  // RW/L
    logic  [3:0] write_semantics_cache;  // RW
    logic  [2:0] interface_protocol_type;  // RW
    logic  [0:0] address_is_virtual;  // RW
    logic  [7:0] num_of_loops;  // RW
    logic  [7:0] num_of_sets;  // RW
    logic  [7:0] num_of_increments;  // RW
    logic  [3:0] reserved1;  // RSVD
    logic  [0:0] device_selfchecking;  // RW
    logic  [2:0] test_algorithm_type;  // RW/L
} CONFIG_ALGO_SETTING_t;

localparam CONFIG_ALGO_SETTING_REG_STRIDE = 48'h8;
localparam CONFIG_ALGO_SETTING_REG_ENTRIES = 1;
localparam [47:0] CONFIG_ALGO_SETTING_CR_ADDR = 48'h181430;
localparam CONFIG_ALGO_SETTING_SIZE = 64;
localparam CONFIG_ALGO_SETTING_VERIFY_SEMANTICS_CACHE_LO = 44;
localparam CONFIG_ALGO_SETTING_VERIFY_SEMANTICS_CACHE_HI = 46;
localparam CONFIG_ALGO_SETTING_VERIFY_SEMANTICS_CACHE_RESET = 3'b0;
localparam CONFIG_ALGO_SETTING_EXECUTE_READ_SEMANTICS_LO = 41;
localparam CONFIG_ALGO_SETTING_EXECUTE_READ_SEMANTICS_HI = 43;
localparam CONFIG_ALGO_SETTING_EXECUTE_READ_SEMANTICS_RESET = 3'b0;
localparam CONFIG_ALGO_SETTING_FLUSH_CACHE_LO = 40;
localparam CONFIG_ALGO_SETTING_FLUSH_CACHE_HI = 40;
localparam CONFIG_ALGO_SETTING_FLUSH_CACHE_RESET = 1'b0;
localparam CONFIG_ALGO_SETTING_WRITE_SEMANTICS_CACHE_LO = 36;
localparam CONFIG_ALGO_SETTING_WRITE_SEMANTICS_CACHE_HI = 39;
localparam CONFIG_ALGO_SETTING_WRITE_SEMANTICS_CACHE_RESET = 4'h0;
localparam CONFIG_ALGO_SETTING_INTERFACE_PROTOCOL_TYPE_LO = 33;
localparam CONFIG_ALGO_SETTING_INTERFACE_PROTOCOL_TYPE_HI = 35;
localparam CONFIG_ALGO_SETTING_INTERFACE_PROTOCOL_TYPE_RESET = 3'b0;
localparam CONFIG_ALGO_SETTING_ADDRESS_IS_VIRTUAL_LO = 32;
localparam CONFIG_ALGO_SETTING_ADDRESS_IS_VIRTUAL_HI = 32;
localparam CONFIG_ALGO_SETTING_ADDRESS_IS_VIRTUAL_RESET = 1'b0;
localparam CONFIG_ALGO_SETTING_NUM_OF_LOOPS_LO = 24;
localparam CONFIG_ALGO_SETTING_NUM_OF_LOOPS_HI = 31;
localparam CONFIG_ALGO_SETTING_NUM_OF_LOOPS_RESET = 8'h0;
localparam CONFIG_ALGO_SETTING_NUM_OF_SETS_LO = 16;
localparam CONFIG_ALGO_SETTING_NUM_OF_SETS_HI = 23;
localparam CONFIG_ALGO_SETTING_NUM_OF_SETS_RESET = 8'h0;
localparam CONFIG_ALGO_SETTING_NUM_OF_INCREMENTS_LO = 8;
localparam CONFIG_ALGO_SETTING_NUM_OF_INCREMENTS_HI = 15;
localparam CONFIG_ALGO_SETTING_NUM_OF_INCREMENTS_RESET = 8'h0;
localparam CONFIG_ALGO_SETTING_DEVICE_SELFCHECKING_LO = 3;
localparam CONFIG_ALGO_SETTING_DEVICE_SELFCHECKING_HI = 3;
localparam CONFIG_ALGO_SETTING_DEVICE_SELFCHECKING_RESET = 1'b0;
localparam CONFIG_ALGO_SETTING_TEST_ALGORITHM_TYPE_LO = 0;
localparam CONFIG_ALGO_SETTING_TEST_ALGORITHM_TYPE_HI = 2;
localparam CONFIG_ALGO_SETTING_TEST_ALGORITHM_TYPE_RESET = 3'b0;
localparam CONFIG_ALGO_SETTING_USEMASK = 64'h7FFFFFFFFF0F;
localparam CONFIG_ALGO_SETTING_RO_MASK = 64'h0;
localparam CONFIG_ALGO_SETTING_WO_MASK = 64'h0;
localparam CONFIG_ALGO_SETTING_RESET = 64'h0;

typedef struct packed {
    logic [27:0] reserved0;  // RSVD
    logic  [0:0] completer_timeout_inj_busy;  // RO/V
    logic  [0:0] completer_timeout;  // RW/L
    logic  [0:0] unexp_compl_inject_busy;  // RO/V
    logic  [0:0] unexp_compl_inject;  // RW/L
} CONFIG_DEVICE_INJECTION_t;

localparam CONFIG_DEVICE_INJECTION_REG_STRIDE = 48'h4;
localparam CONFIG_DEVICE_INJECTION_REG_ENTRIES = 1;
localparam [47:0] CONFIG_DEVICE_INJECTION_CR_ADDR = 48'h181438;
localparam CONFIG_DEVICE_INJECTION_SIZE = 32;
localparam CONFIG_DEVICE_INJECTION_COMPLETER_TIMEOUT_INJ_BUSY_LO = 3;
localparam CONFIG_DEVICE_INJECTION_COMPLETER_TIMEOUT_INJ_BUSY_HI = 3;
localparam CONFIG_DEVICE_INJECTION_COMPLETER_TIMEOUT_INJ_BUSY_RESET = 1'b0;
localparam CONFIG_DEVICE_INJECTION_COMPLETER_TIMEOUT_LO = 2;
localparam CONFIG_DEVICE_INJECTION_COMPLETER_TIMEOUT_HI = 2;
localparam CONFIG_DEVICE_INJECTION_COMPLETER_TIMEOUT_RESET = 1'b0;
localparam CONFIG_DEVICE_INJECTION_UNEXP_COMPL_INJECT_BUSY_LO = 1;
localparam CONFIG_DEVICE_INJECTION_UNEXP_COMPL_INJECT_BUSY_HI = 1;
localparam CONFIG_DEVICE_INJECTION_UNEXP_COMPL_INJECT_BUSY_RESET = 1'b0;
localparam CONFIG_DEVICE_INJECTION_UNEXP_COMPL_INJECT_LO = 0;
localparam CONFIG_DEVICE_INJECTION_UNEXP_COMPL_INJECT_HI = 0;
localparam CONFIG_DEVICE_INJECTION_UNEXP_COMPL_INJECT_RESET = 1'b0;
localparam CONFIG_DEVICE_INJECTION_USEMASK = 32'hF;
localparam CONFIG_DEVICE_INJECTION_RO_MASK = 32'hA;
localparam CONFIG_DEVICE_INJECTION_WO_MASK = 32'h0;
localparam CONFIG_DEVICE_INJECTION_RESET = 32'h0;

typedef struct packed {
    logic [31:0] observed_pattern1;  // RO/V
    logic [31:0] expected_pattern1;  // RO/V
} DEVICE_ERROR_LOG1_t;

localparam DEVICE_ERROR_LOG1_REG_STRIDE = 48'h8;
localparam DEVICE_ERROR_LOG1_REG_ENTRIES = 1;
localparam [47:0] DEVICE_ERROR_LOG1_CR_ADDR = 48'h181440;
localparam DEVICE_ERROR_LOG1_SIZE = 64;
localparam DEVICE_ERROR_LOG1_OBSERVED_PATTERN1_LO = 32;
localparam DEVICE_ERROR_LOG1_OBSERVED_PATTERN1_HI = 63;
localparam DEVICE_ERROR_LOG1_OBSERVED_PATTERN1_RESET = 'h0;
localparam DEVICE_ERROR_LOG1_EXPECTED_PATTERN1_LO = 0;
localparam DEVICE_ERROR_LOG1_EXPECTED_PATTERN1_HI = 31;
localparam DEVICE_ERROR_LOG1_EXPECTED_PATTERN1_RESET = 'h0;
localparam DEVICE_ERROR_LOG1_USEMASK = 64'hFFFFFFFFFFFFFFFF;
localparam DEVICE_ERROR_LOG1_RO_MASK = 64'hFFFFFFFFFFFFFFFF;
localparam DEVICE_ERROR_LOG1_WO_MASK = 64'h0;
localparam DEVICE_ERROR_LOG1_RESET = 64'h0;

typedef struct packed {
    logic [31:0] observed_pattern2;  // RO/V
    logic [31:0] expected_pattern2;  // RO/V
} DEVICE_ERROR_LOG2_t;

localparam DEVICE_ERROR_LOG2_REG_STRIDE = 48'h8;
localparam DEVICE_ERROR_LOG2_REG_ENTRIES = 1;
localparam [47:0] DEVICE_ERROR_LOG2_CR_ADDR = 48'h181448;
localparam DEVICE_ERROR_LOG2_SIZE = 64;
localparam DEVICE_ERROR_LOG2_OBSERVED_PATTERN2_LO = 32;
localparam DEVICE_ERROR_LOG2_OBSERVED_PATTERN2_HI = 63;
localparam DEVICE_ERROR_LOG2_OBSERVED_PATTERN2_RESET = 'h0;
localparam DEVICE_ERROR_LOG2_EXPECTED_PATTERN2_LO = 0;
localparam DEVICE_ERROR_LOG2_EXPECTED_PATTERN2_HI = 31;
localparam DEVICE_ERROR_LOG2_EXPECTED_PATTERN2_RESET = 'h0;
localparam DEVICE_ERROR_LOG2_USEMASK = 64'hFFFFFFFFFFFFFFFF;
localparam DEVICE_ERROR_LOG2_RO_MASK = 64'hFFFFFFFFFFFFFFFF;
localparam DEVICE_ERROR_LOG2_WO_MASK = 64'h0;
localparam DEVICE_ERROR_LOG2_RESET = 64'h0;

typedef struct packed {
    logic [46:0] reserved0;  // RSVD
    logic  [0:0] error_status;  // RW/1C/V
    logic  [7:0] loop_numb;  // RO/V
    logic  [7:0] byte_offset;  // RO/V
} DEVICE_ERROR_LOG3_t;

localparam DEVICE_ERROR_LOG3_REG_STRIDE = 48'h8;
localparam DEVICE_ERROR_LOG3_REG_ENTRIES = 1;
localparam [47:0] DEVICE_ERROR_LOG3_CR_ADDR = 48'h181450;
localparam DEVICE_ERROR_LOG3_SIZE = 64;
localparam DEVICE_ERROR_LOG3_ERROR_STATUS_LO = 16;
localparam DEVICE_ERROR_LOG3_ERROR_STATUS_HI = 16;
localparam DEVICE_ERROR_LOG3_ERROR_STATUS_RESET = 1'h0;
localparam DEVICE_ERROR_LOG3_LOOP_NUMB_LO = 8;
localparam DEVICE_ERROR_LOG3_LOOP_NUMB_HI = 15;
localparam DEVICE_ERROR_LOG3_LOOP_NUMB_RESET = 'h0;
localparam DEVICE_ERROR_LOG3_BYTE_OFFSET_LO = 0;
localparam DEVICE_ERROR_LOG3_BYTE_OFFSET_HI = 7;
localparam DEVICE_ERROR_LOG3_BYTE_OFFSET_RESET = 'h0;
localparam DEVICE_ERROR_LOG3_USEMASK = 64'h1FFFF;
localparam DEVICE_ERROR_LOG3_RO_MASK = 64'hFFFF;
localparam DEVICE_ERROR_LOG3_WO_MASK = 64'h0;
localparam DEVICE_ERROR_LOG3_RESET = 64'h0;

typedef struct packed {
    logic [44:0] reserved0;  // RSVD
    logic  [0:0] event_edge_detect;  // RW
    logic  [0:0] event_counter_reset;  // RW
    logic  [0:0] reserved1;  // RSVD
    logic  [7:0] sub_event_select;  // RW
    logic  [7:0] available_event_select;  // RW
} DEVICE_EVENT_CTRL_t;

localparam DEVICE_EVENT_CTRL_REG_STRIDE = 48'h8;
localparam DEVICE_EVENT_CTRL_REG_ENTRIES = 1;
localparam [47:0] DEVICE_EVENT_CTRL_CR_ADDR = 48'h181460;
localparam DEVICE_EVENT_CTRL_SIZE = 64;
localparam DEVICE_EVENT_CTRL_EVENT_EDGE_DETECT_LO = 18;
localparam DEVICE_EVENT_CTRL_EVENT_EDGE_DETECT_HI = 18;
localparam DEVICE_EVENT_CTRL_EVENT_EDGE_DETECT_RESET = 1'b0;
localparam DEVICE_EVENT_CTRL_EVENT_COUNTER_RESET_LO = 17;
localparam DEVICE_EVENT_CTRL_EVENT_COUNTER_RESET_HI = 17;
localparam DEVICE_EVENT_CTRL_EVENT_COUNTER_RESET_RESET = 1'h0;
localparam DEVICE_EVENT_CTRL_SUB_EVENT_SELECT_LO = 8;
localparam DEVICE_EVENT_CTRL_SUB_EVENT_SELECT_HI = 15;
localparam DEVICE_EVENT_CTRL_SUB_EVENT_SELECT_RESET = 8'h0;
localparam DEVICE_EVENT_CTRL_AVAILABLE_EVENT_SELECT_LO = 0;
localparam DEVICE_EVENT_CTRL_AVAILABLE_EVENT_SELECT_HI = 7;
localparam DEVICE_EVENT_CTRL_AVAILABLE_EVENT_SELECT_RESET = 8'h0;
localparam DEVICE_EVENT_CTRL_USEMASK = 64'h6FFFF;
localparam DEVICE_EVENT_CTRL_RO_MASK = 64'h0;
localparam DEVICE_EVENT_CTRL_WO_MASK = 64'h0;
localparam DEVICE_EVENT_CTRL_RESET = 64'h0;

typedef struct packed {
    logic [63:0] event_count;  // RW/V
} DEVICE_EVENT_COUNT_t;

localparam DEVICE_EVENT_COUNT_REG_STRIDE = 48'h8;
localparam DEVICE_EVENT_COUNT_REG_ENTRIES = 1;
localparam [47:0] DEVICE_EVENT_COUNT_CR_ADDR = 48'h181468;
localparam DEVICE_EVENT_COUNT_SIZE = 64;
localparam DEVICE_EVENT_COUNT_EVENT_COUNT_LO = 0;
localparam DEVICE_EVENT_COUNT_EVENT_COUNT_HI = 63;
localparam DEVICE_EVENT_COUNT_EVENT_COUNT_RESET = 'h0;
localparam DEVICE_EVENT_COUNT_USEMASK = 64'hFFFFFFFFFFFFFFFF;
localparam DEVICE_EVENT_COUNT_RO_MASK = 64'h0;
localparam DEVICE_EVENT_COUNT_WO_MASK = 64'h0;
localparam DEVICE_EVENT_COUNT_RESET = 64'h0;

typedef struct packed {
    logic [52:0] reserved0;  // RSVD
    logic  [0:0] CacheMemCRCInjectionBusy;  // RO
    logic  [1:0] CacheMemCRCInjectionCount;  // RO
    logic  [1:0] CacheMemCRCInjection;  // RO
    logic  [0:0] IOPoisonInjectionBusy;  // RO
    logic  [0:0] IOPoisonInjectionStart;  // RO
    logic  [0:0] MemPoisonInjectionBusy;  // RO
    logic  [0:0] MemPoisonInjectionStart;  // RW/L
    logic  [0:0] CachePoisonInjectionBusy;  // RO/V
    logic  [0:0] CachePoisonInjectionStart;  // RW/L
} DEVICE_ERROR_INJECTION_t;

localparam DEVICE_ERROR_INJECTION_REG_STRIDE = 48'h8;
localparam DEVICE_ERROR_INJECTION_REG_ENTRIES = 1;
localparam [47:0] DEVICE_ERROR_INJECTION_CR_ADDR = 48'h181470;
localparam DEVICE_ERROR_INJECTION_SIZE = 64;
localparam DEVICE_ERROR_INJECTION_CACHEMEMCRCINJECTIONBUSY_LO = 10;
localparam DEVICE_ERROR_INJECTION_CACHEMEMCRCINJECTIONBUSY_HI = 10;
localparam DEVICE_ERROR_INJECTION_CACHEMEMCRCINJECTIONBUSY_RESET = 1'b0;
localparam DEVICE_ERROR_INJECTION_CACHEMEMCRCINJECTIONCOUNT_LO = 8;
localparam DEVICE_ERROR_INJECTION_CACHEMEMCRCINJECTIONCOUNT_HI = 9;
localparam DEVICE_ERROR_INJECTION_CACHEMEMCRCINJECTIONCOUNT_RESET = 2'b0;
localparam DEVICE_ERROR_INJECTION_CACHEMEMCRCINJECTION_LO = 6;
localparam DEVICE_ERROR_INJECTION_CACHEMEMCRCINJECTION_HI = 7;
localparam DEVICE_ERROR_INJECTION_CACHEMEMCRCINJECTION_RESET = 2'b0;
localparam DEVICE_ERROR_INJECTION_IOPOISONINJECTIONBUSY_LO = 5;
localparam DEVICE_ERROR_INJECTION_IOPOISONINJECTIONBUSY_HI = 5;
localparam DEVICE_ERROR_INJECTION_IOPOISONINJECTIONBUSY_RESET = 1'b0;
localparam DEVICE_ERROR_INJECTION_IOPOISONINJECTIONSTART_LO = 4;
localparam DEVICE_ERROR_INJECTION_IOPOISONINJECTIONSTART_HI = 4;
localparam DEVICE_ERROR_INJECTION_IOPOISONINJECTIONSTART_RESET = 1'b0;
localparam DEVICE_ERROR_INJECTION_MEMPOISONINJECTIONBUSY_LO = 3;
localparam DEVICE_ERROR_INJECTION_MEMPOISONINJECTIONBUSY_HI = 3;
localparam DEVICE_ERROR_INJECTION_MEMPOISONINJECTIONBUSY_RESET = 1'b0;
localparam DEVICE_ERROR_INJECTION_MEMPOISONINJECTIONSTART_LO = 2;
localparam DEVICE_ERROR_INJECTION_MEMPOISONINJECTIONSTART_HI = 2;
localparam DEVICE_ERROR_INJECTION_MEMPOISONINJECTIONSTART_RESET = 1'b0;
localparam DEVICE_ERROR_INJECTION_CACHEPOISONINJECTIONBUSY_LO = 1;
localparam DEVICE_ERROR_INJECTION_CACHEPOISONINJECTIONBUSY_HI = 1;
localparam DEVICE_ERROR_INJECTION_CACHEPOISONINJECTIONBUSY_RESET = 1'b0;
localparam DEVICE_ERROR_INJECTION_CACHEPOISONINJECTIONSTART_LO = 0;
localparam DEVICE_ERROR_INJECTION_CACHEPOISONINJECTIONSTART_HI = 0;
localparam DEVICE_ERROR_INJECTION_CACHEPOISONINJECTIONSTART_RESET = 1'b0;
localparam DEVICE_ERROR_INJECTION_USEMASK = 64'h7FF;
localparam DEVICE_ERROR_INJECTION_RO_MASK = 64'h7FA;
localparam DEVICE_ERROR_INJECTION_WO_MASK = 64'h0;
localparam DEVICE_ERROR_INJECTION_RESET = 64'h0;

typedef struct packed {
    logic [62:0] reserved0;  // RSVD
    logic  [0:0] forcefully_disable_afu;  // RW
} DEVICE_FORCE_DISABLE_t;

localparam DEVICE_FORCE_DISABLE_REG_STRIDE = 48'h8;
localparam DEVICE_FORCE_DISABLE_REG_ENTRIES = 1;
localparam [47:0] DEVICE_FORCE_DISABLE_CR_ADDR = 48'h181478;
localparam DEVICE_FORCE_DISABLE_SIZE = 64;
localparam DEVICE_FORCE_DISABLE_FORCEFULLY_DISABLE_AFU_LO = 0;
localparam DEVICE_FORCE_DISABLE_FORCEFULLY_DISABLE_AFU_HI = 0;
localparam DEVICE_FORCE_DISABLE_FORCEFULLY_DISABLE_AFU_RESET = 1'b0;
localparam DEVICE_FORCE_DISABLE_USEMASK = 64'h1;
localparam DEVICE_FORCE_DISABLE_RO_MASK = 64'h0;
localparam DEVICE_FORCE_DISABLE_WO_MASK = 64'h0;
localparam DEVICE_FORCE_DISABLE_RESET = 64'h0;

typedef struct packed {
    logic [51:0] reserved0;  // RSVD
    logic  [3:0] set_number;  // RO/V
    logic  [7:0] address_increment;  // RO/V
} DEVICE_ERROR_LOG4_t;

localparam DEVICE_ERROR_LOG4_REG_STRIDE = 48'h8;
localparam DEVICE_ERROR_LOG4_REG_ENTRIES = 1;
localparam [47:0] DEVICE_ERROR_LOG4_CR_ADDR = 48'h181480;
localparam DEVICE_ERROR_LOG4_SIZE = 64;
localparam DEVICE_ERROR_LOG4_SET_NUMBER_LO = 8;
localparam DEVICE_ERROR_LOG4_SET_NUMBER_HI = 11;
localparam DEVICE_ERROR_LOG4_SET_NUMBER_RESET = 4'h0;
localparam DEVICE_ERROR_LOG4_ADDRESS_INCREMENT_LO = 0;
localparam DEVICE_ERROR_LOG4_ADDRESS_INCREMENT_HI = 7;
localparam DEVICE_ERROR_LOG4_ADDRESS_INCREMENT_RESET = 8'h0;
localparam DEVICE_ERROR_LOG4_USEMASK = 64'hFFF;
localparam DEVICE_ERROR_LOG4_RO_MASK = 64'hFFF;
localparam DEVICE_ERROR_LOG4_WO_MASK = 64'h0;
localparam DEVICE_ERROR_LOG4_RESET = 64'h0;

typedef struct packed {
    logic [11:0] reserved0;  // RSVD
    logic [51:0] address_of_first_error;  // RO/V
} DEVICE_ERROR_LOG5_t;

localparam DEVICE_ERROR_LOG5_REG_STRIDE = 48'h8;
localparam DEVICE_ERROR_LOG5_REG_ENTRIES = 1;
localparam [47:0] DEVICE_ERROR_LOG5_CR_ADDR = 48'h181488;
localparam DEVICE_ERROR_LOG5_SIZE = 64;
localparam DEVICE_ERROR_LOG5_ADDRESS_OF_FIRST_ERROR_LO = 0;
localparam DEVICE_ERROR_LOG5_ADDRESS_OF_FIRST_ERROR_HI = 51;
localparam DEVICE_ERROR_LOG5_ADDRESS_OF_FIRST_ERROR_RESET = 'h0;
localparam DEVICE_ERROR_LOG5_USEMASK = 64'hFFFFFFFFFFFFF;
localparam DEVICE_ERROR_LOG5_RO_MASK = 64'hFFFFFFFFFFFFF;
localparam DEVICE_ERROR_LOG5_WO_MASK = 64'h0;
localparam DEVICE_ERROR_LOG5_RESET = 64'h0;

typedef struct packed {
    logic [53:0] reserved0;  // RSVD
    logic  [0:0] slverr_on_write_response;  // RO/V
    logic  [0:0] slverr_on_read_response;  // RO/V
    logic  [0:0] poison_on_read_response;  // RO/V
    logic  [0:0] illegal_cache_flush_call;  // RO/V
    logic  [0:0] illegal_base_address;  // RO/V
    logic  [0:0] illegal_pattern_size;  // RO/V
    logic  [0:0] illegal_verify_read_semantics;  // RO/V
    logic  [0:0] illegal_execute_read_semantics;  // RO/V
    logic  [0:0] illegal_write_semantics;  // RO/V
    logic  [0:0] illegal_protocol;  // RO/V
} CONFIG_CXL_ERRORS_t;

localparam CONFIG_CXL_ERRORS_REG_STRIDE = 48'h8;
localparam CONFIG_CXL_ERRORS_REG_ENTRIES = 1;
localparam [47:0] CONFIG_CXL_ERRORS_CR_ADDR = 48'h181490;
localparam CONFIG_CXL_ERRORS_SIZE = 64;
localparam CONFIG_CXL_ERRORS_SLVERR_ON_WRITE_RESPONSE_LO = 9;
localparam CONFIG_CXL_ERRORS_SLVERR_ON_WRITE_RESPONSE_HI = 9;
localparam CONFIG_CXL_ERRORS_SLVERR_ON_WRITE_RESPONSE_RESET = 1'b0;
localparam CONFIG_CXL_ERRORS_SLVERR_ON_READ_RESPONSE_LO = 8;
localparam CONFIG_CXL_ERRORS_SLVERR_ON_READ_RESPONSE_HI = 8;
localparam CONFIG_CXL_ERRORS_SLVERR_ON_READ_RESPONSE_RESET = 1'b0;
localparam CONFIG_CXL_ERRORS_POISON_ON_READ_RESPONSE_LO = 7;
localparam CONFIG_CXL_ERRORS_POISON_ON_READ_RESPONSE_HI = 7;
localparam CONFIG_CXL_ERRORS_POISON_ON_READ_RESPONSE_RESET = 1'b0;
localparam CONFIG_CXL_ERRORS_ILLEGAL_CACHE_FLUSH_CALL_LO = 6;
localparam CONFIG_CXL_ERRORS_ILLEGAL_CACHE_FLUSH_CALL_HI = 6;
localparam CONFIG_CXL_ERRORS_ILLEGAL_CACHE_FLUSH_CALL_RESET = 1'b0;
localparam CONFIG_CXL_ERRORS_ILLEGAL_BASE_ADDRESS_LO = 5;
localparam CONFIG_CXL_ERRORS_ILLEGAL_BASE_ADDRESS_HI = 5;
localparam CONFIG_CXL_ERRORS_ILLEGAL_BASE_ADDRESS_RESET = 1'b0;
localparam CONFIG_CXL_ERRORS_ILLEGAL_PATTERN_SIZE_LO = 4;
localparam CONFIG_CXL_ERRORS_ILLEGAL_PATTERN_SIZE_HI = 4;
localparam CONFIG_CXL_ERRORS_ILLEGAL_PATTERN_SIZE_RESET = 1'b0;
localparam CONFIG_CXL_ERRORS_ILLEGAL_VERIFY_READ_SEMANTICS_LO = 3;
localparam CONFIG_CXL_ERRORS_ILLEGAL_VERIFY_READ_SEMANTICS_HI = 3;
localparam CONFIG_CXL_ERRORS_ILLEGAL_VERIFY_READ_SEMANTICS_RESET = 1'b0;
localparam CONFIG_CXL_ERRORS_ILLEGAL_EXECUTE_READ_SEMANTICS_LO = 2;
localparam CONFIG_CXL_ERRORS_ILLEGAL_EXECUTE_READ_SEMANTICS_HI = 2;
localparam CONFIG_CXL_ERRORS_ILLEGAL_EXECUTE_READ_SEMANTICS_RESET = 1'b0;
localparam CONFIG_CXL_ERRORS_ILLEGAL_WRITE_SEMANTICS_LO = 1;
localparam CONFIG_CXL_ERRORS_ILLEGAL_WRITE_SEMANTICS_HI = 1;
localparam CONFIG_CXL_ERRORS_ILLEGAL_WRITE_SEMANTICS_RESET = 1'b0;
localparam CONFIG_CXL_ERRORS_ILLEGAL_PROTOCOL_LO = 0;
localparam CONFIG_CXL_ERRORS_ILLEGAL_PROTOCOL_HI = 0;
localparam CONFIG_CXL_ERRORS_ILLEGAL_PROTOCOL_RESET = 1'b0;
localparam CONFIG_CXL_ERRORS_USEMASK = 64'h3FF;
localparam CONFIG_CXL_ERRORS_RO_MASK = 64'h3FF;
localparam CONFIG_CXL_ERRORS_WO_MASK = 64'h0;
localparam CONFIG_CXL_ERRORS_RESET = 64'h0;

typedef struct packed {
    logic [31:0] current_base_pattern;  // RO/V
    logic  [3:0] set_number;  // RO/V
    logic  [7:0] loop_number;  // RO/V
    logic [15:0] reserved0;  // RSVD
    logic  [0:0] alg_verify_sc_busy;  // RO/V
    logic  [0:0] alg_verify_nsc_busy;  // RO/V
    logic  [0:0] alg_execute_busy;  // RO/V
    logic  [0:0] afu_busy;  // RO/V
} DEVICE_AFU_STATUS1_t;

localparam DEVICE_AFU_STATUS1_REG_STRIDE = 48'h8;
localparam DEVICE_AFU_STATUS1_REG_ENTRIES = 1;
localparam [47:0] DEVICE_AFU_STATUS1_CR_ADDR = 48'h181498;
localparam DEVICE_AFU_STATUS1_SIZE = 64;
localparam DEVICE_AFU_STATUS1_CURRENT_BASE_PATTERN_LO = 32;
localparam DEVICE_AFU_STATUS1_CURRENT_BASE_PATTERN_HI = 63;
localparam DEVICE_AFU_STATUS1_CURRENT_BASE_PATTERN_RESET = 1'b0;
localparam DEVICE_AFU_STATUS1_SET_NUMBER_LO = 28;
localparam DEVICE_AFU_STATUS1_SET_NUMBER_HI = 31;
localparam DEVICE_AFU_STATUS1_SET_NUMBER_RESET = 1'b0;
localparam DEVICE_AFU_STATUS1_LOOP_NUMBER_LO = 20;
localparam DEVICE_AFU_STATUS1_LOOP_NUMBER_HI = 27;
localparam DEVICE_AFU_STATUS1_LOOP_NUMBER_RESET = 1'b0;
localparam DEVICE_AFU_STATUS1_ALG_VERIFY_SC_BUSY_LO = 3;
localparam DEVICE_AFU_STATUS1_ALG_VERIFY_SC_BUSY_HI = 3;
localparam DEVICE_AFU_STATUS1_ALG_VERIFY_SC_BUSY_RESET = 1'b0;
localparam DEVICE_AFU_STATUS1_ALG_VERIFY_NSC_BUSY_LO = 2;
localparam DEVICE_AFU_STATUS1_ALG_VERIFY_NSC_BUSY_HI = 2;
localparam DEVICE_AFU_STATUS1_ALG_VERIFY_NSC_BUSY_RESET = 1'b0;
localparam DEVICE_AFU_STATUS1_ALG_EXECUTE_BUSY_LO = 1;
localparam DEVICE_AFU_STATUS1_ALG_EXECUTE_BUSY_HI = 1;
localparam DEVICE_AFU_STATUS1_ALG_EXECUTE_BUSY_RESET = 1'b0;
localparam DEVICE_AFU_STATUS1_AFU_BUSY_LO = 0;
localparam DEVICE_AFU_STATUS1_AFU_BUSY_HI = 0;
localparam DEVICE_AFU_STATUS1_AFU_BUSY_RESET = 1'b0;
localparam DEVICE_AFU_STATUS1_USEMASK = 64'hFFFFFFFFFFF0000F;
localparam DEVICE_AFU_STATUS1_RO_MASK = 64'hFFFFFFFFFFF0000F;
localparam DEVICE_AFU_STATUS1_WO_MASK = 64'h0;
localparam DEVICE_AFU_STATUS1_RESET = 64'h0;

typedef struct packed {
    logic [11:0] reserved0;  // RSVD
    logic [51:0] current_base_address;  // RO/V
} DEVICE_AFU_STATUS2_t;

localparam DEVICE_AFU_STATUS2_REG_STRIDE = 48'h8;
localparam DEVICE_AFU_STATUS2_REG_ENTRIES = 1;
localparam [47:0] DEVICE_AFU_STATUS2_CR_ADDR = 48'h1814A0;
localparam DEVICE_AFU_STATUS2_SIZE = 64;
localparam DEVICE_AFU_STATUS2_CURRENT_BASE_ADDRESS_LO = 0;
localparam DEVICE_AFU_STATUS2_CURRENT_BASE_ADDRESS_HI = 51;
localparam DEVICE_AFU_STATUS2_CURRENT_BASE_ADDRESS_RESET = 1'b0;
localparam DEVICE_AFU_STATUS2_USEMASK = 64'hFFFFFFFFFFFFF;
localparam DEVICE_AFU_STATUS2_RO_MASK = 64'hFFFFFFFFFFFFF;
localparam DEVICE_AFU_STATUS2_WO_MASK = 64'h0;
localparam DEVICE_AFU_STATUS2_RESET = 64'h0;

typedef struct packed {
    logic  [3:0] read_aruser_opcode;  // RO/V
    logic [11:0] read_arid;  // RO/V
    logic  [0:0] read_opcode_error_status;  // RO/V
    logic  [0:0] reserved0;  // RSVD
    logic  [3:0] write_awuser_opcode;  // RO/V
    logic [11:0] write_awid;  // RO/V
    logic  [0:0] write_opcode_error_status;  // RO/V
    logic  [0:0] reserved1;  // RSVD
    logic  [2:0] cafu_csr0_read_semantic;  // RO/V
    logic  [3:0] cafu_csr0_write_semantic;  // RO/V
    logic  [0:0] config_error_status;  // RO/V
    logic [17:0] reserved2;  // RSVD
    logic  [0:0] axi2cpi_busy;  // RO/V
    logic  [0:0] clear;  // RW
} DEVICE_AXI2CPI_STATUS_1_t;

localparam DEVICE_AXI2CPI_STATUS_1_REG_STRIDE = 48'h8;
localparam DEVICE_AXI2CPI_STATUS_1_REG_ENTRIES = 1;
localparam [47:0] DEVICE_AXI2CPI_STATUS_1_CR_ADDR = 48'h1814A8;
localparam DEVICE_AXI2CPI_STATUS_1_SIZE = 64;
localparam DEVICE_AXI2CPI_STATUS_1_READ_ARUSER_OPCODE_LO = 60;
localparam DEVICE_AXI2CPI_STATUS_1_READ_ARUSER_OPCODE_HI = 63;
localparam DEVICE_AXI2CPI_STATUS_1_READ_ARUSER_OPCODE_RESET = 'h0;
localparam DEVICE_AXI2CPI_STATUS_1_READ_ARID_LO = 48;
localparam DEVICE_AXI2CPI_STATUS_1_READ_ARID_HI = 59;
localparam DEVICE_AXI2CPI_STATUS_1_READ_ARID_RESET = 'h0;
localparam DEVICE_AXI2CPI_STATUS_1_READ_OPCODE_ERROR_STATUS_LO = 47;
localparam DEVICE_AXI2CPI_STATUS_1_READ_OPCODE_ERROR_STATUS_HI = 47;
localparam DEVICE_AXI2CPI_STATUS_1_READ_OPCODE_ERROR_STATUS_RESET = 1'b0;
localparam DEVICE_AXI2CPI_STATUS_1_WRITE_AWUSER_OPCODE_LO = 42;
localparam DEVICE_AXI2CPI_STATUS_1_WRITE_AWUSER_OPCODE_HI = 45;
localparam DEVICE_AXI2CPI_STATUS_1_WRITE_AWUSER_OPCODE_RESET = 'h0;
localparam DEVICE_AXI2CPI_STATUS_1_WRITE_AWID_LO = 30;
localparam DEVICE_AXI2CPI_STATUS_1_WRITE_AWID_HI = 41;
localparam DEVICE_AXI2CPI_STATUS_1_WRITE_AWID_RESET = 'h0;
localparam DEVICE_AXI2CPI_STATUS_1_WRITE_OPCODE_ERROR_STATUS_LO = 29;
localparam DEVICE_AXI2CPI_STATUS_1_WRITE_OPCODE_ERROR_STATUS_HI = 29;
localparam DEVICE_AXI2CPI_STATUS_1_WRITE_OPCODE_ERROR_STATUS_RESET = 1'b0;
localparam DEVICE_AXI2CPI_STATUS_1_CAFU_CSR0_READ_SEMANTIC_LO = 25;
localparam DEVICE_AXI2CPI_STATUS_1_CAFU_CSR0_READ_SEMANTIC_HI = 27;
localparam DEVICE_AXI2CPI_STATUS_1_CAFU_CSR0_READ_SEMANTIC_RESET = 'h0;
localparam DEVICE_AXI2CPI_STATUS_1_CAFU_CSR0_WRITE_SEMANTIC_LO = 21;
localparam DEVICE_AXI2CPI_STATUS_1_CAFU_CSR0_WRITE_SEMANTIC_HI = 24;
localparam DEVICE_AXI2CPI_STATUS_1_CAFU_CSR0_WRITE_SEMANTIC_RESET = 'h0;
localparam DEVICE_AXI2CPI_STATUS_1_CONFIG_ERROR_STATUS_LO = 20;
localparam DEVICE_AXI2CPI_STATUS_1_CONFIG_ERROR_STATUS_HI = 20;
localparam DEVICE_AXI2CPI_STATUS_1_CONFIG_ERROR_STATUS_RESET = 1'b0;
localparam DEVICE_AXI2CPI_STATUS_1_AXI2CPI_BUSY_LO = 1;
localparam DEVICE_AXI2CPI_STATUS_1_AXI2CPI_BUSY_HI = 1;
localparam DEVICE_AXI2CPI_STATUS_1_AXI2CPI_BUSY_RESET = 1'b0;
localparam DEVICE_AXI2CPI_STATUS_1_CLEAR_LO = 0;
localparam DEVICE_AXI2CPI_STATUS_1_CLEAR_HI = 0;
localparam DEVICE_AXI2CPI_STATUS_1_CLEAR_RESET = 1'b0;
localparam DEVICE_AXI2CPI_STATUS_1_USEMASK = 64'hFFFFBFFFEFF00003;
localparam DEVICE_AXI2CPI_STATUS_1_RO_MASK = 64'hFFFFBFFFEFF00002;
localparam DEVICE_AXI2CPI_STATUS_1_WO_MASK = 64'h0;
localparam DEVICE_AXI2CPI_STATUS_1_RESET = 64'h0;

typedef struct packed {
    logic [46:0] address;  // RO/V
    logic [12:0] ccv_afu_arid;  // RO/V
    logic  [0:0] data_parity_error_status;  // RO/V
    logic  [0:0] header_parity_error_status;  // RO/V
    logic  [0:0] reserved0;  // RSVD
    logic  [0:0] clear;  // RW
} DEVICE_AXI2CPI_STATUS_2_t;

localparam DEVICE_AXI2CPI_STATUS_2_REG_STRIDE = 48'h8;
localparam DEVICE_AXI2CPI_STATUS_2_REG_ENTRIES = 1;
localparam [47:0] DEVICE_AXI2CPI_STATUS_2_CR_ADDR = 48'h1814B0;
localparam DEVICE_AXI2CPI_STATUS_2_SIZE = 64;
localparam DEVICE_AXI2CPI_STATUS_2_ADDRESS_LO = 17;
localparam DEVICE_AXI2CPI_STATUS_2_ADDRESS_HI = 63;
localparam DEVICE_AXI2CPI_STATUS_2_ADDRESS_RESET = 'h0;
localparam DEVICE_AXI2CPI_STATUS_2_CCV_AFU_ARID_LO = 4;
localparam DEVICE_AXI2CPI_STATUS_2_CCV_AFU_ARID_HI = 16;
localparam DEVICE_AXI2CPI_STATUS_2_CCV_AFU_ARID_RESET = 'h0;
localparam DEVICE_AXI2CPI_STATUS_2_DATA_PARITY_ERROR_STATUS_LO = 3;
localparam DEVICE_AXI2CPI_STATUS_2_DATA_PARITY_ERROR_STATUS_HI = 3;
localparam DEVICE_AXI2CPI_STATUS_2_DATA_PARITY_ERROR_STATUS_RESET = 1'b0;
localparam DEVICE_AXI2CPI_STATUS_2_HEADER_PARITY_ERROR_STATUS_LO = 2;
localparam DEVICE_AXI2CPI_STATUS_2_HEADER_PARITY_ERROR_STATUS_HI = 2;
localparam DEVICE_AXI2CPI_STATUS_2_HEADER_PARITY_ERROR_STATUS_RESET = 1'b0;
localparam DEVICE_AXI2CPI_STATUS_2_CLEAR_LO = 0;
localparam DEVICE_AXI2CPI_STATUS_2_CLEAR_HI = 0;
localparam DEVICE_AXI2CPI_STATUS_2_CLEAR_RESET = 1'b0;
localparam DEVICE_AXI2CPI_STATUS_2_USEMASK = 64'hFFFFFFFFFFFFFFFD;
localparam DEVICE_AXI2CPI_STATUS_2_RO_MASK = 64'hFFFFFFFFFFFFFFFC;
localparam DEVICE_AXI2CPI_STATUS_2_WO_MASK = 64'h0;
localparam DEVICE_AXI2CPI_STATUS_2_RESET = 64'h0;

typedef struct packed {
    logic [31:0] cdat_0;  // RW/V
} CDAT_0_t;

localparam CDAT_0_REG_STRIDE = 48'h4;
localparam CDAT_0_REG_ENTRIES = 1;
localparam [47:0] CDAT_0_CR_ADDR = 48'h181500;
localparam CDAT_0_SIZE = 32;
localparam CDAT_0_CDAT_0_LO = 0;
localparam CDAT_0_CDAT_0_HI = 31;
localparam CDAT_0_CDAT_0_RESET = 32'h60;
localparam CDAT_0_USEMASK = 32'hFFFFFFFF;
localparam CDAT_0_RO_MASK = 32'h0;
localparam CDAT_0_WO_MASK = 32'h0;
localparam CDAT_0_RESET = 32'h60;

typedef struct packed {
    logic [31:0] cdat_1;  // RW/V
} CDAT_1_t;

localparam CDAT_1_REG_STRIDE = 48'h4;
localparam CDAT_1_REG_ENTRIES = 1;
localparam [47:0] CDAT_1_CR_ADDR = 48'h181504;
localparam CDAT_1_SIZE = 32;
localparam CDAT_1_CDAT_1_LO = 0;
localparam CDAT_1_CDAT_1_HI = 31;
localparam CDAT_1_CDAT_1_RESET = 32'h4401;
localparam CDAT_1_USEMASK = 32'hFFFFFFFF;
localparam CDAT_1_RO_MASK = 32'h0;
localparam CDAT_1_WO_MASK = 32'h0;
localparam CDAT_1_RESET = 32'h4401;

typedef struct packed {
    logic [31:0] cdat_2;  // RW
} CDAT_2_t;

localparam CDAT_2_REG_STRIDE = 48'h4;
localparam CDAT_2_REG_ENTRIES = 1;
localparam [47:0] CDAT_2_CR_ADDR = 48'h181508;
localparam CDAT_2_SIZE = 32;
localparam CDAT_2_CDAT_2_LO = 0;
localparam CDAT_2_CDAT_2_HI = 31;
localparam CDAT_2_CDAT_2_RESET = 32'h0;
localparam CDAT_2_USEMASK = 32'hFFFFFFFF;
localparam CDAT_2_RO_MASK = 32'h0;
localparam CDAT_2_WO_MASK = 32'h0;
localparam CDAT_2_RESET = 32'h0;

typedef struct packed {
    logic [31:0] cdat_3;  // RW
} CDAT_3_t;

localparam CDAT_3_REG_STRIDE = 48'h4;
localparam CDAT_3_REG_ENTRIES = 1;
localparam [47:0] CDAT_3_CR_ADDR = 48'h18150C;
localparam CDAT_3_SIZE = 32;
localparam CDAT_3_CDAT_3_LO = 0;
localparam CDAT_3_CDAT_3_HI = 31;
localparam CDAT_3_CDAT_3_RESET = 32'h0;
localparam CDAT_3_USEMASK = 32'hFFFFFFFF;
localparam CDAT_3_RO_MASK = 32'h0;
localparam CDAT_3_WO_MASK = 32'h0;
localparam CDAT_3_RESET = 32'h0;

typedef struct packed {
    logic [31:0] dsmas_0;  // RW
} DSMAS_0_t;

localparam DSMAS_0_REG_STRIDE = 48'h4;
localparam DSMAS_0_REG_ENTRIES = 1;
localparam [47:0] DSMAS_0_CR_ADDR = 48'h181510;
localparam DSMAS_0_SIZE = 32;
localparam DSMAS_0_DSMAS_0_LO = 0;
localparam DSMAS_0_DSMAS_0_HI = 31;
localparam DSMAS_0_DSMAS_0_RESET = 32'h180000;
localparam DSMAS_0_USEMASK = 32'hFFFFFFFF;
localparam DSMAS_0_RO_MASK = 32'h0;
localparam DSMAS_0_WO_MASK = 32'h0;
localparam DSMAS_0_RESET = 32'h180000;

typedef struct packed {
    logic [31:0] dsmas_1;  // RW
} DSMAS_1_t;

localparam DSMAS_1_REG_STRIDE = 48'h4;
localparam DSMAS_1_REG_ENTRIES = 1;
localparam [47:0] DSMAS_1_CR_ADDR = 48'h181514;
localparam DSMAS_1_SIZE = 32;
localparam DSMAS_1_DSMAS_1_LO = 0;
localparam DSMAS_1_DSMAS_1_HI = 31;
localparam DSMAS_1_DSMAS_1_RESET = 32'h0;
localparam DSMAS_1_USEMASK = 32'hFFFFFFFF;
localparam DSMAS_1_RO_MASK = 32'h0;
localparam DSMAS_1_WO_MASK = 32'h0;
localparam DSMAS_1_RESET = 32'h0;

typedef struct packed {
    logic [31:0] dsmas_2;  // RW
} DSMAS_2_t;

localparam DSMAS_2_REG_STRIDE = 48'h4;
localparam DSMAS_2_REG_ENTRIES = 1;
localparam [47:0] DSMAS_2_CR_ADDR = 48'h181518;
localparam DSMAS_2_SIZE = 32;
localparam DSMAS_2_DSMAS_2_LO = 0;
localparam DSMAS_2_DSMAS_2_HI = 31;
localparam DSMAS_2_DSMAS_2_RESET = 32'h0;
localparam DSMAS_2_USEMASK = 32'hFFFFFFFF;
localparam DSMAS_2_RO_MASK = 32'h0;
localparam DSMAS_2_WO_MASK = 32'h0;
localparam DSMAS_2_RESET = 32'h0;

typedef struct packed {
    logic [31:0] dsmas_3;  // RW
} DSMAS_3_t;

localparam DSMAS_3_REG_STRIDE = 48'h4;
localparam DSMAS_3_REG_ENTRIES = 1;
localparam [47:0] DSMAS_3_CR_ADDR = 48'h18151C;
localparam DSMAS_3_SIZE = 32;
localparam DSMAS_3_DSMAS_3_LO = 0;
localparam DSMAS_3_DSMAS_3_HI = 31;
localparam DSMAS_3_DSMAS_3_RESET = 32'h0;
localparam DSMAS_3_USEMASK = 32'hFFFFFFFF;
localparam DSMAS_3_RO_MASK = 32'h0;
localparam DSMAS_3_WO_MASK = 32'h0;
localparam DSMAS_3_RESET = 32'h0;

typedef struct packed {
    logic [31:0] dsmas_4;  // RW
} DSMAS_4_t;

localparam DSMAS_4_REG_STRIDE = 48'h4;
localparam DSMAS_4_REG_ENTRIES = 1;
localparam [47:0] DSMAS_4_CR_ADDR = 48'h181520;
localparam DSMAS_4_SIZE = 32;
localparam DSMAS_4_DSMAS_4_LO = 0;
localparam DSMAS_4_DSMAS_4_HI = 31;
localparam DSMAS_4_DSMAS_4_RESET = 32'h0;
localparam DSMAS_4_USEMASK = 32'hFFFFFFFF;
localparam DSMAS_4_RO_MASK = 32'h0;
localparam DSMAS_4_WO_MASK = 32'h0;
localparam DSMAS_4_RESET = 32'h0;

typedef struct packed {
    logic [31:0] dsmas_5;  // RW
} DSMAS_5_t;

localparam DSMAS_5_REG_STRIDE = 48'h4;
localparam DSMAS_5_REG_ENTRIES = 1;
localparam [47:0] DSMAS_5_CR_ADDR = 48'h181524;
localparam DSMAS_5_SIZE = 32;
localparam DSMAS_5_DSMAS_5_LO = 0;
localparam DSMAS_5_DSMAS_5_HI = 31;
localparam DSMAS_5_DSMAS_5_RESET = 32'h1;
localparam DSMAS_5_USEMASK = 32'hFFFFFFFF;
localparam DSMAS_5_RO_MASK = 32'h0;
localparam DSMAS_5_WO_MASK = 32'h0;
localparam DSMAS_5_RESET = 32'h1;

typedef struct packed {
    logic [31:0] dsis_0;  // RW
} DSIS_0_t;

localparam DSIS_0_REG_STRIDE = 48'h4;
localparam DSIS_0_REG_ENTRIES = 1;
localparam [47:0] DSIS_0_CR_ADDR = 48'h181528;
localparam DSIS_0_SIZE = 32;
localparam DSIS_0_DSIS_0_LO = 0;
localparam DSIS_0_DSIS_0_HI = 31;
localparam DSIS_0_DSIS_0_RESET = 32'h80003;
localparam DSIS_0_USEMASK = 32'hFFFFFFFF;
localparam DSIS_0_RO_MASK = 32'h0;
localparam DSIS_0_WO_MASK = 32'h0;
localparam DSIS_0_RESET = 32'h80003;

typedef struct packed {
    logic [31:0] dsis_1;  // RW
} DSIS_1_t;

localparam DSIS_1_REG_STRIDE = 48'h4;
localparam DSIS_1_REG_ENTRIES = 1;
localparam [47:0] DSIS_1_CR_ADDR = 48'h18152C;
localparam DSIS_1_SIZE = 32;
localparam DSIS_1_DSIS_1_LO = 0;
localparam DSIS_1_DSIS_1_HI = 31;
localparam DSIS_1_DSIS_1_RESET = 32'h1;
localparam DSIS_1_USEMASK = 32'hFFFFFFFF;
localparam DSIS_1_RO_MASK = 32'h0;
localparam DSIS_1_WO_MASK = 32'h0;
localparam DSIS_1_RESET = 32'h1;

typedef struct packed {
    logic [31:0] dslbis_0;  // RW
} DSLBIS_0_t;

localparam DSLBIS_0_REG_STRIDE = 48'h4;
localparam DSLBIS_0_REG_ENTRIES = 1;
localparam [47:0] DSLBIS_0_CR_ADDR = 48'h181530;
localparam DSLBIS_0_SIZE = 32;
localparam DSLBIS_0_DSLBIS_0_LO = 0;
localparam DSLBIS_0_DSLBIS_0_HI = 31;
localparam DSLBIS_0_DSLBIS_0_RESET = 32'h180001;
localparam DSLBIS_0_USEMASK = 32'hFFFFFFFF;
localparam DSLBIS_0_RO_MASK = 32'h0;
localparam DSLBIS_0_WO_MASK = 32'h0;
localparam DSLBIS_0_RESET = 32'h180001;

typedef struct packed {
    logic [31:0] dslbis_1;  // RW
} DSLBIS_1_t;

localparam DSLBIS_1_REG_STRIDE = 48'h4;
localparam DSLBIS_1_REG_ENTRIES = 1;
localparam [47:0] DSLBIS_1_CR_ADDR = 48'h181534;
localparam DSLBIS_1_SIZE = 32;
localparam DSLBIS_1_DSLBIS_1_LO = 0;
localparam DSLBIS_1_DSLBIS_1_HI = 31;
localparam DSLBIS_1_DSLBIS_1_RESET = 32'h0;
localparam DSLBIS_1_USEMASK = 32'hFFFFFFFF;
localparam DSLBIS_1_RO_MASK = 32'h0;
localparam DSLBIS_1_WO_MASK = 32'h0;
localparam DSLBIS_1_RESET = 32'h0;

typedef struct packed {
    logic [31:0] dslbis_2;  // RW
} DSLBIS_2_t;

localparam DSLBIS_2_REG_STRIDE = 48'h4;
localparam DSLBIS_2_REG_ENTRIES = 1;
localparam [47:0] DSLBIS_2_CR_ADDR = 48'h181538;
localparam DSLBIS_2_SIZE = 32;
localparam DSLBIS_2_DSLBIS_2_LO = 0;
localparam DSLBIS_2_DSLBIS_2_HI = 31;
localparam DSLBIS_2_DSLBIS_2_RESET = 32'h0;
localparam DSLBIS_2_USEMASK = 32'hFFFFFFFF;
localparam DSLBIS_2_RO_MASK = 32'h0;
localparam DSLBIS_2_WO_MASK = 32'h0;
localparam DSLBIS_2_RESET = 32'h0;

typedef struct packed {
    logic [31:0] dslbis_3;  // RW
} DSLBIS_3_t;

localparam DSLBIS_3_REG_STRIDE = 48'h4;
localparam DSLBIS_3_REG_ENTRIES = 1;
localparam [47:0] DSLBIS_3_CR_ADDR = 48'h18153C;
localparam DSLBIS_3_SIZE = 32;
localparam DSLBIS_3_DSLBIS_3_LO = 0;
localparam DSLBIS_3_DSLBIS_3_HI = 31;
localparam DSLBIS_3_DSLBIS_3_RESET = 32'h0;
localparam DSLBIS_3_USEMASK = 32'hFFFFFFFF;
localparam DSLBIS_3_RO_MASK = 32'h0;
localparam DSLBIS_3_WO_MASK = 32'h0;
localparam DSLBIS_3_RESET = 32'h0;

typedef struct packed {
    logic [31:0] dslbis_4;  // RW
} DSLBIS_4_t;

localparam DSLBIS_4_REG_STRIDE = 48'h4;
localparam DSLBIS_4_REG_ENTRIES = 1;
localparam [47:0] DSLBIS_4_CR_ADDR = 48'h181540;
localparam DSLBIS_4_SIZE = 32;
localparam DSLBIS_4_DSLBIS_4_LO = 0;
localparam DSLBIS_4_DSLBIS_4_HI = 31;
localparam DSLBIS_4_DSLBIS_4_RESET = 32'h0;
localparam DSLBIS_4_USEMASK = 32'hFFFFFFFF;
localparam DSLBIS_4_RO_MASK = 32'h0;
localparam DSLBIS_4_WO_MASK = 32'h0;
localparam DSLBIS_4_RESET = 32'h0;

typedef struct packed {
    logic [31:0] dslbis_5;  // RW
} DSLBIS_5_t;

localparam DSLBIS_5_REG_STRIDE = 48'h4;
localparam DSLBIS_5_REG_ENTRIES = 1;
localparam [47:0] DSLBIS_5_CR_ADDR = 48'h181544;
localparam DSLBIS_5_SIZE = 32;
localparam DSLBIS_5_DSLBIS_5_LO = 0;
localparam DSLBIS_5_DSLBIS_5_HI = 31;
localparam DSLBIS_5_DSLBIS_5_RESET = 32'h0;
localparam DSLBIS_5_USEMASK = 32'hFFFFFFFF;
localparam DSLBIS_5_RO_MASK = 32'h0;
localparam DSLBIS_5_WO_MASK = 32'h0;
localparam DSLBIS_5_RESET = 32'h0;

typedef struct packed {
    logic [31:0] dsemts_0;  // RW
} DSEMTS_0_t;

localparam DSEMTS_0_REG_STRIDE = 48'h4;
localparam DSEMTS_0_REG_ENTRIES = 1;
localparam [47:0] DSEMTS_0_CR_ADDR = 48'h181548;
localparam DSEMTS_0_SIZE = 32;
localparam DSEMTS_0_DSEMTS_0_LO = 0;
localparam DSEMTS_0_DSEMTS_0_HI = 31;
localparam DSEMTS_0_DSEMTS_0_RESET = 32'h180004;
localparam DSEMTS_0_USEMASK = 32'hFFFFFFFF;
localparam DSEMTS_0_RO_MASK = 32'h0;
localparam DSEMTS_0_WO_MASK = 32'h0;
localparam DSEMTS_0_RESET = 32'h180004;

typedef struct packed {
    logic [31:0] dsemts_1;  // RW
} DSEMTS_1_t;

localparam DSEMTS_1_REG_STRIDE = 48'h4;
localparam DSEMTS_1_REG_ENTRIES = 1;
localparam [47:0] DSEMTS_1_CR_ADDR = 48'h18154C;
localparam DSEMTS_1_SIZE = 32;
localparam DSEMTS_1_DSEMTS_1_LO = 0;
localparam DSEMTS_1_DSEMTS_1_HI = 31;
localparam DSEMTS_1_DSEMTS_1_RESET = 32'h100;
localparam DSEMTS_1_USEMASK = 32'hFFFFFFFF;
localparam DSEMTS_1_RO_MASK = 32'h0;
localparam DSEMTS_1_WO_MASK = 32'h0;
localparam DSEMTS_1_RESET = 32'h100;

typedef struct packed {
    logic [31:0] dsemts_2;  // RW
} DSEMTS_2_t;

localparam DSEMTS_2_REG_STRIDE = 48'h4;
localparam DSEMTS_2_REG_ENTRIES = 1;
localparam [47:0] DSEMTS_2_CR_ADDR = 48'h181550;
localparam DSEMTS_2_SIZE = 32;
localparam DSEMTS_2_DSEMTS_2_LO = 0;
localparam DSEMTS_2_DSEMTS_2_HI = 31;
localparam DSEMTS_2_DSEMTS_2_RESET = 32'h0;
localparam DSEMTS_2_USEMASK = 32'hFFFFFFFF;
localparam DSEMTS_2_RO_MASK = 32'h0;
localparam DSEMTS_2_WO_MASK = 32'h0;
localparam DSEMTS_2_RESET = 32'h0;

typedef struct packed {
    logic [31:0] dsemts_3;  // RW
} DSEMTS_3_t;

localparam DSEMTS_3_REG_STRIDE = 48'h4;
localparam DSEMTS_3_REG_ENTRIES = 1;
localparam [47:0] DSEMTS_3_CR_ADDR = 48'h181554;
localparam DSEMTS_3_SIZE = 32;
localparam DSEMTS_3_DSEMTS_3_LO = 0;
localparam DSEMTS_3_DSEMTS_3_HI = 31;
localparam DSEMTS_3_DSEMTS_3_RESET = 32'h0;
localparam DSEMTS_3_USEMASK = 32'hFFFFFFFF;
localparam DSEMTS_3_RO_MASK = 32'h0;
localparam DSEMTS_3_WO_MASK = 32'h0;
localparam DSEMTS_3_RESET = 32'h0;

typedef struct packed {
    logic [31:0] dsemts_4;  // RW
} DSEMTS_4_t;

localparam DSEMTS_4_REG_STRIDE = 48'h4;
localparam DSEMTS_4_REG_ENTRIES = 1;
localparam [47:0] DSEMTS_4_CR_ADDR = 48'h181558;
localparam DSEMTS_4_SIZE = 32;
localparam DSEMTS_4_DSEMTS_4_LO = 0;
localparam DSEMTS_4_DSEMTS_4_HI = 31;
localparam DSEMTS_4_DSEMTS_4_RESET = 32'h0;
localparam DSEMTS_4_USEMASK = 32'hFFFFFFFF;
localparam DSEMTS_4_RO_MASK = 32'h0;
localparam DSEMTS_4_WO_MASK = 32'h0;
localparam DSEMTS_4_RESET = 32'h0;

typedef struct packed {
    logic [31:0] dsemts_5;  // RW
} DSEMTS_5_t;

localparam DSEMTS_5_REG_STRIDE = 48'h4;
localparam DSEMTS_5_REG_ENTRIES = 1;
localparam [47:0] DSEMTS_5_CR_ADDR = 48'h18155C;
localparam DSEMTS_5_SIZE = 32;
localparam DSEMTS_5_DSEMTS_5_LO = 0;
localparam DSEMTS_5_DSEMTS_5_HI = 31;
localparam DSEMTS_5_DSEMTS_5_RESET = 32'h0;
localparam DSEMTS_5_USEMASK = 32'hFFFFFFFF;
localparam DSEMTS_5_RO_MASK = 32'h0;
localparam DSEMTS_5_WO_MASK = 32'h0;
localparam DSEMTS_5_RESET = 32'h0;

typedef struct packed {
    logic [15:0] mc1_status;  // RO/V
    logic [15:0] mc0_status;  // RO/V
} MC_STATUS_t;

localparam MC_STATUS_REG_STRIDE = 48'h4;
localparam MC_STATUS_REG_ENTRIES = 1;
localparam [47:0] MC_STATUS_CR_ADDR = 48'h181560;
localparam MC_STATUS_SIZE = 32;
localparam MC_STATUS_MC1_STATUS_LO = 16;
localparam MC_STATUS_MC1_STATUS_HI = 31;
localparam MC_STATUS_MC1_STATUS_RESET = 16'b0;
localparam MC_STATUS_MC0_STATUS_LO = 0;
localparam MC_STATUS_MC0_STATUS_HI = 15;
localparam MC_STATUS_MC0_STATUS_RESET = 16'b0;
localparam MC_STATUS_USEMASK = 32'hFFFFFFFF;
localparam MC_STATUS_RO_MASK = 32'hFFFFFFFF;
localparam MC_STATUS_WO_MASK = 32'h0;
localparam MC_STATUS_RESET = 32'h0;

typedef struct packed {
    logic [31:0] chan1_cnt;  // RO/V
    logic [31:0] chan0_cnt;  // RO/V
} DEVMEM_SBECNT_t;

localparam DEVMEM_SBECNT_REG_STRIDE = 48'h8;
localparam DEVMEM_SBECNT_REG_ENTRIES = 1;
localparam [47:0] DEVMEM_SBECNT_CR_ADDR = 48'h181568;
localparam DEVMEM_SBECNT_SIZE = 64;
localparam DEVMEM_SBECNT_CHAN1_CNT_LO = 32;
localparam DEVMEM_SBECNT_CHAN1_CNT_HI = 63;
localparam DEVMEM_SBECNT_CHAN1_CNT_RESET = 32'b0;
localparam DEVMEM_SBECNT_CHAN0_CNT_LO = 0;
localparam DEVMEM_SBECNT_CHAN0_CNT_HI = 31;
localparam DEVMEM_SBECNT_CHAN0_CNT_RESET = 32'b0;
localparam DEVMEM_SBECNT_USEMASK = 64'hFFFFFFFFFFFFFFFF;
localparam DEVMEM_SBECNT_RO_MASK = 64'hFFFFFFFFFFFFFFFF;
localparam DEVMEM_SBECNT_WO_MASK = 64'h0;
localparam DEVMEM_SBECNT_RESET = 64'h0;

typedef struct packed {
    logic [31:0] chan1_cnt;  // RO/V
    logic [31:0] chan0_cnt;  // RO/V
} DEVMEM_DBECNT_t;

localparam DEVMEM_DBECNT_REG_STRIDE = 48'h8;
localparam DEVMEM_DBECNT_REG_ENTRIES = 1;
localparam [47:0] DEVMEM_DBECNT_CR_ADDR = 48'h181570;
localparam DEVMEM_DBECNT_SIZE = 64;
localparam DEVMEM_DBECNT_CHAN1_CNT_LO = 32;
localparam DEVMEM_DBECNT_CHAN1_CNT_HI = 63;
localparam DEVMEM_DBECNT_CHAN1_CNT_RESET = 32'b0;
localparam DEVMEM_DBECNT_CHAN0_CNT_LO = 0;
localparam DEVMEM_DBECNT_CHAN0_CNT_HI = 31;
localparam DEVMEM_DBECNT_CHAN0_CNT_RESET = 32'b0;
localparam DEVMEM_DBECNT_USEMASK = 64'hFFFFFFFFFFFFFFFF;
localparam DEVMEM_DBECNT_RO_MASK = 64'hFFFFFFFFFFFFFFFF;
localparam DEVMEM_DBECNT_WO_MASK = 64'h0;
localparam DEVMEM_DBECNT_RESET = 64'h0;

typedef struct packed {
    logic [31:0] chan1_cnt;  // RO/V
    logic [31:0] chan0_cnt;  // RO/V
} DEVMEM_POISONCNT_t;

localparam DEVMEM_POISONCNT_REG_STRIDE = 48'h8;
localparam DEVMEM_POISONCNT_REG_ENTRIES = 1;
localparam [47:0] DEVMEM_POISONCNT_CR_ADDR = 48'h181578;
localparam DEVMEM_POISONCNT_SIZE = 64;
localparam DEVMEM_POISONCNT_CHAN1_CNT_LO = 32;
localparam DEVMEM_POISONCNT_CHAN1_CNT_HI = 63;
localparam DEVMEM_POISONCNT_CHAN1_CNT_RESET = 32'b0;
localparam DEVMEM_POISONCNT_CHAN0_CNT_LO = 0;
localparam DEVMEM_POISONCNT_CHAN0_CNT_HI = 31;
localparam DEVMEM_POISONCNT_CHAN0_CNT_RESET = 32'b0;
localparam DEVMEM_POISONCNT_USEMASK = 64'hFFFFFFFFFFFFFFFF;
localparam DEVMEM_POISONCNT_RO_MASK = 64'hFFFFFFFFFFFFFFFF;
localparam DEVMEM_POISONCNT_WO_MASK = 64'h0;
localparam DEVMEM_POISONCNT_RESET = 64'h0;

typedef struct packed {
    logic [27:0] reserved;  // RW
    logic  [0:0] event_record;  // RW
    logic  [1:0] event_severity;  // RW
    logic  [0:0] event_trigger;  // RW
} MBOX_EVENTINJ_t;

localparam MBOX_EVENTINJ_REG_STRIDE = 48'h4;
localparam MBOX_EVENTINJ_REG_ENTRIES = 1;
localparam [47:0] MBOX_EVENTINJ_CR_ADDR = 48'h181580;
localparam MBOX_EVENTINJ_SIZE = 32;
localparam MBOX_EVENTINJ_RESERVED_LO = 4;
localparam MBOX_EVENTINJ_RESERVED_HI = 31;
localparam MBOX_EVENTINJ_RESERVED_RESET = 28'b0;
localparam MBOX_EVENTINJ_EVENT_RECORD_LO = 3;
localparam MBOX_EVENTINJ_EVENT_RECORD_HI = 3;
localparam MBOX_EVENTINJ_EVENT_RECORD_RESET = 1'b0;
localparam MBOX_EVENTINJ_EVENT_SEVERITY_LO = 1;
localparam MBOX_EVENTINJ_EVENT_SEVERITY_HI = 2;
localparam MBOX_EVENTINJ_EVENT_SEVERITY_RESET = 2'b0;
localparam MBOX_EVENTINJ_EVENT_TRIGGER_LO = 0;
localparam MBOX_EVENTINJ_EVENT_TRIGGER_HI = 0;
localparam MBOX_EVENTINJ_EVENT_TRIGGER_RESET = 1'b0;
localparam MBOX_EVENTINJ_USEMASK = 32'hFFFFFFFF;
localparam MBOX_EVENTINJ_RO_MASK = 32'h0;
localparam MBOX_EVENTINJ_WO_MASK = 32'h0;
localparam MBOX_EVENTINJ_RESET = 32'h0;

typedef struct packed {
    logic  [0:0] clear_number_loops;  // RW
    logic [19:0] total_number_loops;  // RO/V
    logic [39:0] reserved0;  // RSVD
    logic  [0:0] reads_only_mode_enable;  // RW
    logic  [0:0] writes_only_mode_enable;  // RW
    logic  [0:0] latency_mode_enable;  // RW
} DEVICE_AFU_LATENCY_MODE_t;

localparam DEVICE_AFU_LATENCY_MODE_REG_STRIDE = 48'h8;
localparam DEVICE_AFU_LATENCY_MODE_REG_ENTRIES = 1;
localparam [47:0] DEVICE_AFU_LATENCY_MODE_CR_ADDR = 48'h181588;
localparam DEVICE_AFU_LATENCY_MODE_SIZE = 64;
localparam DEVICE_AFU_LATENCY_MODE_CLEAR_NUMBER_LOOPS_LO = 63;
localparam DEVICE_AFU_LATENCY_MODE_CLEAR_NUMBER_LOOPS_HI = 63;
localparam DEVICE_AFU_LATENCY_MODE_CLEAR_NUMBER_LOOPS_RESET = 1'b0;
localparam DEVICE_AFU_LATENCY_MODE_TOTAL_NUMBER_LOOPS_LO = 43;
localparam DEVICE_AFU_LATENCY_MODE_TOTAL_NUMBER_LOOPS_HI = 62;
localparam DEVICE_AFU_LATENCY_MODE_TOTAL_NUMBER_LOOPS_RESET = 'h0;
localparam DEVICE_AFU_LATENCY_MODE_READS_ONLY_MODE_ENABLE_LO = 2;
localparam DEVICE_AFU_LATENCY_MODE_READS_ONLY_MODE_ENABLE_HI = 2;
localparam DEVICE_AFU_LATENCY_MODE_READS_ONLY_MODE_ENABLE_RESET = 1'b0;
localparam DEVICE_AFU_LATENCY_MODE_WRITES_ONLY_MODE_ENABLE_LO = 1;
localparam DEVICE_AFU_LATENCY_MODE_WRITES_ONLY_MODE_ENABLE_HI = 1;
localparam DEVICE_AFU_LATENCY_MODE_WRITES_ONLY_MODE_ENABLE_RESET = 1'b0;
localparam DEVICE_AFU_LATENCY_MODE_LATENCY_MODE_ENABLE_LO = 0;
localparam DEVICE_AFU_LATENCY_MODE_LATENCY_MODE_ENABLE_HI = 0;
localparam DEVICE_AFU_LATENCY_MODE_LATENCY_MODE_ENABLE_RESET = 1'b0;
localparam DEVICE_AFU_LATENCY_MODE_USEMASK = 64'hFFFFF80000000007;
localparam DEVICE_AFU_LATENCY_MODE_RO_MASK = 64'h7FFFF80000000000;
localparam DEVICE_AFU_LATENCY_MODE_WO_MASK = 64'h0;
localparam DEVICE_AFU_LATENCY_MODE_RESET = 64'h0;

typedef struct packed {
    DVSEC_DEV_t  DVSEC_DEV;
    DVSEC_HDR1_t  DVSEC_HDR1;
    DVSEC_FBCAP_HDR2_t  DVSEC_FBCAP_HDR2;
    DVSEC_FBCTRL_STATUS_t  DVSEC_FBCTRL_STATUS;
    DVSEC_FBCTRL2_STATUS2_t  DVSEC_FBCTRL2_STATUS2;
    DVSEC_FBLOCK_t  DVSEC_FBLOCK;
    DVSEC_FBRANGE1SZHIGH_t  DVSEC_FBRANGE1SZHIGH;
    DVSEC_FBRANGE1SZLOW_t  DVSEC_FBRANGE1SZLOW;
    DVSEC_FBRANGE1HIGH_t  DVSEC_FBRANGE1HIGH;
    DVSEC_FBRANGE1LOW_t  DVSEC_FBRANGE1LOW;
    DVSEC_FBRANGE2SZHIGH_t  DVSEC_FBRANGE2SZHIGH;
    DVSEC_FBRANGE2SZLOW_t  DVSEC_FBRANGE2SZLOW;
    DVSEC_FBRANGE2HIGH_t  DVSEC_FBRANGE2HIGH;
    DVSEC_FBRANGE2LOW_t  DVSEC_FBRANGE2LOW;
    DVSEC_DOE_t  DVSEC_DOE;
    DOE_CAPREG_t  DOE_CAPREG;
    DOE_CTLREG_t  DOE_CTLREG;
    DOE_STSREG_t  DOE_STSREG;
    DOE_WRMAILREG_t  DOE_WRMAILREG;
    DOE_RDMAILREG_t  DOE_RDMAILREG;
    DVSEC_TEST_CAP_t  DVSEC_TEST_CAP;
    CXL_DVSEC_HEADER_1_t  CXL_DVSEC_HEADER_1;
    CXL_DVSEC_HEADER_2_t  CXL_DVSEC_HEADER_2;
    CXL_DVSEC_TEST_LOCK_t  CXL_DVSEC_TEST_LOCK;
    CXL_DVSEC_TEST_CAP1_t  CXL_DVSEC_TEST_CAP1;
    CXL_DVSEC_TEST_CAP2_t  CXL_DVSEC_TEST_CAP2;
    CXL_DVSEC_TEST_CNF_BASE_LOW_t  CXL_DVSEC_TEST_CNF_BASE_LOW;
    CXL_DVSEC_TEST_CNF_BASE_HIGH_t  CXL_DVSEC_TEST_CNF_BASE_HIGH;
    CXL_DEV_CAP_ARRAY_0_t  CXL_DEV_CAP_ARRAY_0;
    CXL_DEV_CAP_ARRAY_1_t  CXL_DEV_CAP_ARRAY_1;
    CXL_DEV_CAP_HDR1_0_t  CXL_DEV_CAP_HDR1_0;
    CXL_DEV_CAP_HDR1_1_t  CXL_DEV_CAP_HDR1_1;
    CXL_DEV_CAP_HDR1_2_t  CXL_DEV_CAP_HDR1_2;
    CXL_DEV_CAP_HDR2_0_t  CXL_DEV_CAP_HDR2_0;
    CXL_DEV_CAP_HDR2_1_t  CXL_DEV_CAP_HDR2_1;
    CXL_DEV_CAP_HDR2_2_t  CXL_DEV_CAP_HDR2_2;
    CXL_DEV_CAP_HDR3_0_t  CXL_DEV_CAP_HDR3_0;
    CXL_DEV_CAP_HDR3_1_t  CXL_DEV_CAP_HDR3_1;
    CXL_DEV_CAP_HDR3_2_t  CXL_DEV_CAP_HDR3_2;
    CXL_DEV_CAP_EVENT_STATUS_t  CXL_DEV_CAP_EVENT_STATUS;
    CXL_MEM_DEV_STATUS_t  CXL_MEM_DEV_STATUS;
    CXL_MB_CAP_t  CXL_MB_CAP;
    CXL_MB_CTRL_t  CXL_MB_CTRL;
    CXL_MB_CMD_t  CXL_MB_CMD;
    CXL_MB_STATUS_t  CXL_MB_STATUS;
    CXL_MB_BK_CMD_STATUS_t  CXL_MB_BK_CMD_STATUS;
    CXL_MB_PAY_START_t  CXL_MB_PAY_START;
    CXL_MB_PAY_END_t  CXL_MB_PAY_END;
    HDM_DEC_CAP_t  HDM_DEC_CAP;
    HDM_DEC_GBL_CTRL_t  HDM_DEC_GBL_CTRL;
    HDM_DEC_BASELOW_t  HDM_DEC_BASELOW;
    HDM_DEC_BASEHIGH_t  HDM_DEC_BASEHIGH;
    HDM_DEC_SIZELOW_t  HDM_DEC_SIZELOW;
    HDM_DEC_SIZEHIGH_t  HDM_DEC_SIZEHIGH;
    HDM_DEC_CTRL_t  HDM_DEC_CTRL;
    HDM_DEC_DPALOW_t  HDM_DEC_DPALOW;
    HDM_DEC_DPAHIGH_t  HDM_DEC_DPAHIGH;
    CONFIG_TEST_START_ADDR_t  CONFIG_TEST_START_ADDR;
    CONFIG_TEST_WR_BACK_ADDR_t  CONFIG_TEST_WR_BACK_ADDR;
    CONFIG_TEST_ADDR_INCRE_t  CONFIG_TEST_ADDR_INCRE;
    CONFIG_TEST_PATTERN_t  CONFIG_TEST_PATTERN;
    CONFIG_TEST_BYTEMASK_t  CONFIG_TEST_BYTEMASK;
    CONFIG_TEST_PATTERN_PARAM_t  CONFIG_TEST_PATTERN_PARAM;
    CONFIG_ALGO_SETTING_t  CONFIG_ALGO_SETTING;
    CONFIG_DEVICE_INJECTION_t  CONFIG_DEVICE_INJECTION;
    DEVICE_ERROR_LOG1_t  DEVICE_ERROR_LOG1;
    DEVICE_ERROR_LOG2_t  DEVICE_ERROR_LOG2;
    DEVICE_ERROR_LOG3_t  DEVICE_ERROR_LOG3;
    DEVICE_EVENT_CTRL_t  DEVICE_EVENT_CTRL;
    DEVICE_EVENT_COUNT_t  DEVICE_EVENT_COUNT;
    DEVICE_ERROR_INJECTION_t  DEVICE_ERROR_INJECTION;
    DEVICE_FORCE_DISABLE_t  DEVICE_FORCE_DISABLE;
    DEVICE_ERROR_LOG4_t  DEVICE_ERROR_LOG4;
    DEVICE_ERROR_LOG5_t  DEVICE_ERROR_LOG5;
    CONFIG_CXL_ERRORS_t  CONFIG_CXL_ERRORS;
    DEVICE_AFU_STATUS1_t  DEVICE_AFU_STATUS1;
    DEVICE_AFU_STATUS2_t  DEVICE_AFU_STATUS2;
    DEVICE_AXI2CPI_STATUS_1_t  DEVICE_AXI2CPI_STATUS_1;
    DEVICE_AXI2CPI_STATUS_2_t  DEVICE_AXI2CPI_STATUS_2;
    CDAT_0_t  CDAT_0;
    CDAT_1_t  CDAT_1;
    CDAT_2_t  CDAT_2;
    CDAT_3_t  CDAT_3;
    DSMAS_0_t  DSMAS_0;
    DSMAS_1_t  DSMAS_1;
    DSMAS_2_t  DSMAS_2;
    DSMAS_3_t  DSMAS_3;
    DSMAS_4_t  DSMAS_4;
    DSMAS_5_t  DSMAS_5;
    DSIS_0_t  DSIS_0;
    DSIS_1_t  DSIS_1;
    DSLBIS_0_t  DSLBIS_0;
    DSLBIS_1_t  DSLBIS_1;
    DSLBIS_2_t  DSLBIS_2;
    DSLBIS_3_t  DSLBIS_3;
    DSLBIS_4_t  DSLBIS_4;
    DSLBIS_5_t  DSLBIS_5;
    DSEMTS_0_t  DSEMTS_0;
    DSEMTS_1_t  DSEMTS_1;
    DSEMTS_2_t  DSEMTS_2;
    DSEMTS_3_t  DSEMTS_3;
    DSEMTS_4_t  DSEMTS_4;
    DSEMTS_5_t  DSEMTS_5;
    MC_STATUS_t  MC_STATUS;
    DEVMEM_SBECNT_t  DEVMEM_SBECNT;
    DEVMEM_DBECNT_t  DEVMEM_DBECNT;
    DEVMEM_POISONCNT_t  DEVMEM_POISONCNT;
    MBOX_EVENTINJ_t  MBOX_EVENTINJ;
    DEVICE_AFU_LATENCY_MODE_t  DEVICE_AFU_LATENCY_MODE;
} cafu_csr0_cfg_registers_t;

// ===================================================
// load

typedef struct packed {
    logic  [0:0] viral_status;  // RW/1C/V/P
} load_DVSEC_FBCTRL_STATUS_t;

typedef struct packed {
    logic  [0:0] initiate_cxl_reset;  // RW/1S/V
    logic  [0:0] initiate_cache_wb_and_inv;  // RW/1S/V
} load_DVSEC_FBCTRL2_STATUS2_t;

typedef struct packed {
    logic  [0:0] doe_go;  // RW/V
    logic  [0:0] doe_abort;  // RW/V
} load_DOE_CTLREG_t;

typedef struct packed {
    logic  [0:0] doe_int_status;  // RW/1C/V
} load_DOE_STSREG_t;

typedef struct packed {
    logic  [0:0] doe_wr_data_mailbox;  // RW/V
} load_DOE_WRMAILREG_t;

typedef struct packed {
    logic  [0:0] doe_rd_data_mailbox;  // RW/V
} load_DOE_RDMAILREG_t;

typedef struct packed {
    logic  [0:0] doorbell;  // RW/V
} load_CXL_MB_CTRL_t;

typedef struct packed {
    logic  [0:0] payload_len;  // RW/V
} load_CXL_MB_CMD_t;

typedef struct packed {
    logic  [0:0] error_status;  // RW/1C/V
} load_DEVICE_ERROR_LOG3_t;

typedef struct packed {
    logic  [0:0] event_count;  // RW/V
} load_DEVICE_EVENT_COUNT_t;

typedef struct packed {
    logic  [0:0] cdat_0;  // RW/V
} load_CDAT_0_t;

typedef struct packed {
    logic  [0:0] cdat_1;  // RW/V
} load_CDAT_1_t;

typedef struct packed {
    load_DVSEC_FBCTRL_STATUS_t  DVSEC_FBCTRL_STATUS;
    load_DVSEC_FBCTRL2_STATUS2_t  DVSEC_FBCTRL2_STATUS2;
    load_DOE_CTLREG_t  DOE_CTLREG;
    load_DOE_STSREG_t  DOE_STSREG;
    load_DOE_WRMAILREG_t  DOE_WRMAILREG;
    load_DOE_RDMAILREG_t  DOE_RDMAILREG;
    load_CXL_MB_CTRL_t  CXL_MB_CTRL;
    load_CXL_MB_CMD_t  CXL_MB_CMD;
    load_DEVICE_ERROR_LOG3_t  DEVICE_ERROR_LOG3;
    load_DEVICE_EVENT_COUNT_t  DEVICE_EVENT_COUNT;
    load_CDAT_0_t  CDAT_0;
    load_CDAT_1_t  CDAT_1;
} cafu_csr0_cfg_load_t;

// ===================================================
// lock

typedef struct packed {
    logic  [0:0] mem_base_low;  // RW/L
} lock_HDM_DEC_BASELOW_t;

typedef struct packed {
    logic  [0:0] mem_base_high;  // RW/L
} lock_HDM_DEC_BASEHIGH_t;

typedef struct packed {
    logic  [0:0] mem_size_low;  // RW/L
} lock_HDM_DEC_SIZELOW_t;

typedef struct packed {
    logic  [0:0] mem_size_high;  // RW/L
} lock_HDM_DEC_SIZEHIGH_t;

typedef struct packed {
    logic  [0:0] target_dev_type;  // RW/L
    logic  [0:0] commit;  // RW/L
    logic  [0:0] lock_on_commit;  // RW/L
    logic  [0:0] interleave_ways;  // RW/L
    logic  [0:0] interleave_granularity;  // RW/L
} lock_HDM_DEC_CTRL_t;

typedef struct packed {
    logic  [0:0] dpa_skip_low;  // RW/L
} lock_HDM_DEC_DPALOW_t;

typedef struct packed {
    logic  [0:0] dpa_skip_high;  // RW/L
} lock_HDM_DEC_DPAHIGH_t;

typedef struct packed {
    lock_HDM_DEC_BASELOW_t  HDM_DEC_BASELOW;
    lock_HDM_DEC_BASEHIGH_t  HDM_DEC_BASEHIGH;
    lock_HDM_DEC_SIZELOW_t  HDM_DEC_SIZELOW;
    lock_HDM_DEC_SIZEHIGH_t  HDM_DEC_SIZEHIGH;
    lock_HDM_DEC_CTRL_t  HDM_DEC_CTRL;
    lock_HDM_DEC_DPALOW_t  HDM_DEC_DPALOW;
    lock_HDM_DEC_DPAHIGH_t  HDM_DEC_DPAHIGH;
} cafu_csr0_cfg_lock_t;

// ===================================================
// valid (so far used by WO registers)

// ===================================================
// new

typedef struct packed {
    logic  [0:0] viral_status;  // RW/1C/V/P
} new_DVSEC_FBCTRL_STATUS_t;

typedef struct packed {
    logic  [0:0] power_mgt_init_complete;  // RO/V
    logic  [0:0] cxl_reset_error;  // RO/V
    logic  [0:0] cxl_reset_complete;  // RO/V
    logic  [0:0] cache_invalid;  // RO/V
    logic  [0:0] initiate_cxl_reset;  // RW/1S/V
    logic  [0:0] initiate_cache_wb_and_inv;  // RW/1S/V
} new_DVSEC_FBCTRL2_STATUS2_t;

typedef struct packed {
    logic  [0:0] doe_go;  // RW/V
    logic  [0:0] doe_abort;  // RW/V
} new_DOE_CTLREG_t;

typedef struct packed {
    logic  [0:0] data_object_ready;  // RO/V
    logic  [0:0] doe_error;  // RO/V
    logic  [0:0] doe_int_status;  // RW/1C/V
    logic  [0:0] doe_busy;  // RO/V
} new_DOE_STSREG_t;

typedef struct packed {
    logic [31:0] doe_wr_data_mailbox;  // RW/V
} new_DOE_WRMAILREG_t;

typedef struct packed {
    logic [31:0] doe_rd_data_mailbox;  // RW/V
} new_DOE_RDMAILREG_t;

typedef struct packed {
    logic [27:0] test_config_base_low;  // RO/V
} new_CXL_DVSEC_TEST_CNF_BASE_LOW_t;

typedef struct packed {
    logic [31:0] test_config_base_high;  // RO/V
} new_CXL_DVSEC_TEST_CNF_BASE_HIGH_t;

typedef struct packed {
    logic  [0:0] fatal_event_log;  // RO/V
    logic  [0:0] failure_event_log;  // RO/V
    logic  [0:0] warning_event_log;  // RO/V
    logic  [0:0] info_event_log;  // RO/V
} new_CXL_DEV_CAP_EVENT_STATUS_t;

typedef struct packed {
    logic  [2:0] reset_needed;  // RO/V
    logic  [0:0] mailbox_if_ready;  // RO/V
    logic  [1:0] media_status;  // RO/V
    logic  [0:0] fw_halt;  // RO/V
    logic  [0:0] device_fatal;  // RO/V
} new_CXL_MEM_DEV_STATUS_t;

typedef struct packed {
    logic  [0:0] doorbell;  // RW/V
} new_CXL_MB_CTRL_t;

typedef struct packed {
    logic [20:0] payload_len;  // RW/V
} new_CXL_MB_CMD_t;

typedef struct packed {
    logic [15:0] vendor_specfic_ext_status;  // RO/V
    logic [15:0] return_code;  // RO/V
    logic  [0:0] bk_operation;  // RO/V
} new_CXL_MB_STATUS_t;

typedef struct packed {
    logic [15:0] vendor_specfic_ext_status;  // RO/V
    logic [15:0] return_code;  // RO/V
    logic  [6:0] percentage_comp;  // RO/V
    logic [15:0] cmd_opcode;  // RO/V
} new_CXL_MB_BK_CMD_STATUS_t;

typedef struct packed {
    logic  [0:0] committed;  // RO/V
} new_HDM_DEC_CTRL_t;

typedef struct packed {
    logic  [0:0] completer_timeout_inj_busy;  // RO/V
    logic  [0:0] unexp_compl_inject_busy;  // RO/V
} new_CONFIG_DEVICE_INJECTION_t;

typedef struct packed {
    logic [31:0] observed_pattern1;  // RO/V
    logic [31:0] expected_pattern1;  // RO/V
} new_DEVICE_ERROR_LOG1_t;

typedef struct packed {
    logic [31:0] observed_pattern2;  // RO/V
    logic [31:0] expected_pattern2;  // RO/V
} new_DEVICE_ERROR_LOG2_t;

typedef struct packed {
    logic  [0:0] error_status;  // RW/1C/V
    logic  [7:0] loop_numb;  // RO/V
    logic  [7:0] byte_offset;  // RO/V
} new_DEVICE_ERROR_LOG3_t;

typedef struct packed {
    logic [63:0] event_count;  // RW/V
} new_DEVICE_EVENT_COUNT_t;

typedef struct packed {
    logic  [0:0] CachePoisonInjectionBusy;  // RO/V
} new_DEVICE_ERROR_INJECTION_t;

typedef struct packed {
    logic  [3:0] set_number;  // RO/V
    logic  [7:0] address_increment;  // RO/V
} new_DEVICE_ERROR_LOG4_t;

typedef struct packed {
    logic [51:0] address_of_first_error;  // RO/V
} new_DEVICE_ERROR_LOG5_t;

typedef struct packed {
    logic  [0:0] slverr_on_write_response;  // RO/V
    logic  [0:0] slverr_on_read_response;  // RO/V
    logic  [0:0] poison_on_read_response;  // RO/V
    logic  [0:0] illegal_cache_flush_call;  // RO/V
    logic  [0:0] illegal_base_address;  // RO/V
    logic  [0:0] illegal_pattern_size;  // RO/V
    logic  [0:0] illegal_verify_read_semantics;  // RO/V
    logic  [0:0] illegal_execute_read_semantics;  // RO/V
    logic  [0:0] illegal_write_semantics;  // RO/V
    logic  [0:0] illegal_protocol;  // RO/V
} new_CONFIG_CXL_ERRORS_t;

typedef struct packed {
    logic [31:0] current_base_pattern;  // RO/V
    logic  [3:0] set_number;  // RO/V
    logic  [7:0] loop_number;  // RO/V
    logic  [0:0] alg_verify_sc_busy;  // RO/V
    logic  [0:0] alg_verify_nsc_busy;  // RO/V
    logic  [0:0] alg_execute_busy;  // RO/V
    logic  [0:0] afu_busy;  // RO/V
} new_DEVICE_AFU_STATUS1_t;

typedef struct packed {
    logic [51:0] current_base_address;  // RO/V
} new_DEVICE_AFU_STATUS2_t;

typedef struct packed {
    logic  [3:0] read_aruser_opcode;  // RO/V
    logic [11:0] read_arid;  // RO/V
    logic  [0:0] read_opcode_error_status;  // RO/V
    logic  [3:0] write_awuser_opcode;  // RO/V
    logic [11:0] write_awid;  // RO/V
    logic  [0:0] write_opcode_error_status;  // RO/V
    logic  [2:0] cafu_csr0_read_semantic;  // RO/V
    logic  [3:0] cafu_csr0_write_semantic;  // RO/V
    logic  [0:0] config_error_status;  // RO/V
    logic  [0:0] axi2cpi_busy;  // RO/V
} new_DEVICE_AXI2CPI_STATUS_1_t;

typedef struct packed {
    logic [46:0] address;  // RO/V
    logic [12:0] ccv_afu_arid;  // RO/V
    logic  [0:0] data_parity_error_status;  // RO/V
    logic  [0:0] header_parity_error_status;  // RO/V
} new_DEVICE_AXI2CPI_STATUS_2_t;

typedef struct packed {
    logic [31:0] cdat_0;  // RW/V
} new_CDAT_0_t;

typedef struct packed {
    logic [31:0] cdat_1;  // RW/V
} new_CDAT_1_t;

typedef struct packed {
    logic [15:0] mc1_status;  // RO/V
    logic [15:0] mc0_status;  // RO/V
} new_MC_STATUS_t;

typedef struct packed {
    logic [31:0] chan1_cnt;  // RO/V
    logic [31:0] chan0_cnt;  // RO/V
} new_DEVMEM_SBECNT_t;

typedef struct packed {
    logic [31:0] chan1_cnt;  // RO/V
    logic [31:0] chan0_cnt;  // RO/V
} new_DEVMEM_DBECNT_t;

typedef struct packed {
    logic [31:0] chan1_cnt;  // RO/V
    logic [31:0] chan0_cnt;  // RO/V
} new_DEVMEM_POISONCNT_t;

typedef struct packed {
    logic [19:0] total_number_loops;  // RO/V
} new_DEVICE_AFU_LATENCY_MODE_t;

typedef struct packed {
    new_DVSEC_FBCTRL_STATUS_t  DVSEC_FBCTRL_STATUS;
    new_DVSEC_FBCTRL2_STATUS2_t  DVSEC_FBCTRL2_STATUS2;
    new_DOE_CTLREG_t  DOE_CTLREG;
    new_DOE_STSREG_t  DOE_STSREG;
    new_DOE_WRMAILREG_t  DOE_WRMAILREG;
    new_DOE_RDMAILREG_t  DOE_RDMAILREG;
    new_CXL_DVSEC_TEST_CNF_BASE_LOW_t  CXL_DVSEC_TEST_CNF_BASE_LOW;
    new_CXL_DVSEC_TEST_CNF_BASE_HIGH_t  CXL_DVSEC_TEST_CNF_BASE_HIGH;
    new_CXL_DEV_CAP_EVENT_STATUS_t  CXL_DEV_CAP_EVENT_STATUS;
    new_CXL_MEM_DEV_STATUS_t  CXL_MEM_DEV_STATUS;
    new_CXL_MB_CTRL_t  CXL_MB_CTRL;
    new_CXL_MB_CMD_t  CXL_MB_CMD;
    new_CXL_MB_STATUS_t  CXL_MB_STATUS;
    new_CXL_MB_BK_CMD_STATUS_t  CXL_MB_BK_CMD_STATUS;
    new_HDM_DEC_CTRL_t  HDM_DEC_CTRL;
    new_CONFIG_DEVICE_INJECTION_t  CONFIG_DEVICE_INJECTION;
    new_DEVICE_ERROR_LOG1_t  DEVICE_ERROR_LOG1;
    new_DEVICE_ERROR_LOG2_t  DEVICE_ERROR_LOG2;
    new_DEVICE_ERROR_LOG3_t  DEVICE_ERROR_LOG3;
    new_DEVICE_EVENT_COUNT_t  DEVICE_EVENT_COUNT;
    new_DEVICE_ERROR_INJECTION_t  DEVICE_ERROR_INJECTION;
    new_DEVICE_ERROR_LOG4_t  DEVICE_ERROR_LOG4;
    new_DEVICE_ERROR_LOG5_t  DEVICE_ERROR_LOG5;
    new_CONFIG_CXL_ERRORS_t  CONFIG_CXL_ERRORS;
    new_DEVICE_AFU_STATUS1_t  DEVICE_AFU_STATUS1;
    new_DEVICE_AFU_STATUS2_t  DEVICE_AFU_STATUS2;
    new_DEVICE_AXI2CPI_STATUS_1_t  DEVICE_AXI2CPI_STATUS_1;
    new_DEVICE_AXI2CPI_STATUS_2_t  DEVICE_AXI2CPI_STATUS_2;
    new_CDAT_0_t  CDAT_0;
    new_CDAT_1_t  CDAT_1;
    new_MC_STATUS_t  MC_STATUS;
    new_DEVMEM_SBECNT_t  DEVMEM_SBECNT;
    new_DEVMEM_DBECNT_t  DEVMEM_DBECNT;
    new_DEVMEM_POISONCNT_t  DEVMEM_POISONCNT;
    new_DEVICE_AFU_LATENCY_MODE_t  DEVICE_AFU_LATENCY_MODE;
} cafu_csr0_cfg_new_t;

// ===================================================
// HandCoded Control structure
//   (used by project HandCoded specified registers)

// ===================================================
// HandCoded Read/Write Structure
//    (used by project HandCoded specified registers)

// ===================================================
// HandCoded Read/Write Structure
//    (used by project HandCoded specified registers)

// ===================================================
// RW/V2 Structure

// ===================================================
// Parity Bit Structure

// ===================================================
// Watch Signals Structure


endpackage: cafu_csr0_cfg_pkg

`endif // CAFU_CSR0_CFG_PKG_VH
