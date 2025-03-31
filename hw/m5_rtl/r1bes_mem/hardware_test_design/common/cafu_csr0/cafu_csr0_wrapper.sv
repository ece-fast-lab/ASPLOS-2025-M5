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

`ifdef SINGLE_SLICE_ENV
  `include "ccv_afu_globals.vh.iv"
`else
  `include "ccv_afu_globals.vh.iv"
`endif

import rtlgen_pkg_v12::*;
import ccv_afu_pkg::*;
import afu_axi_if_pkg::*;
import ext_csr_if_pkg::*;
import cxlip_top_pkg::*;
import mc_ecc_pkg::*;

`ifdef ORIGINAL_CCV_AFU_MODE
   import ccv_afu_cfg_pkg::*;
`else
   //import cafu_csr0_cfg_pkg::*;
   import rtlgen_pkg_v12::*;
   import tmp_cafu_csr0_cfg_pkg::*;
`endif



module cafu_csr0_wrapper   // ccv_afu_wrapper
`ifndef SINGLE_SLICE_ENV
  #(
      parameter T1IP_ENABLE = 0
  )
`endif
(
  // Clocks
  input logic  gated_clk,
  input logic  rtl_clk,

  // Resets
  input logic  rst_n,
  input logic  cxl_or_conv_rst_n, //cxlreset or conventional reset

  `ifndef SINGLE_SLICE_ENV
  input logic [35:0] hdm_size_256mb,
  `endif

  input logic mc_mem_active,

  input logic [mc_ecc_pkg::MC_STATUS_T_BW-1:0]      ddr_mc_status,
  input logic [mc_ecc_pkg::MEM_DEV_STATUS_T_BW-1:0] mem_dev_status,
 
  input  mc_ecc_pkg::mc_err_cnt_t  [cxlip_top_pkg::MC_CHANNEL-1:0]                mc_err_cnt ,

  `ifndef ORIGINAL_CCV_AFU_MODE
      output logic cafu_user_enabled_cxl_io,
  `endif
  
 // `ifdef CPI_MODE
    /*
      AXI-MM interface - write address channel
    */
    output logic [AFU_AXI_MAX_ADDR_WIDTH-1:0]         awaddr, 
    output logic [AFU_AXI_BURST_WIDTH-1:0]            awburst,
    output logic [AFU_AXI_CACHE_WIDTH-1:0]            awcache,
    output logic [AFU_AXI_MAX_ID_WIDTH-1:0]           awid,
    output logic [AFU_AXI_MAX_BURST_LENGTH_WIDTH-1:0] awlen,
    output logic [AFU_AXI_LOCK_WIDTH-1:0]             awlock,
    output logic [AFU_AXI_QOS_WIDTH-1:0]              awqos,
    output logic [AFU_AXI_PROT_WIDTH-1:0]             awprot,
     input                                            awready,
    output logic [AFU_AXI_REGION_WIDTH-1:0]           awregion,
    output logic [AFU_AXI_SIZE_WIDTH-1:0]             awsize,
    output logic [AFU_AXI_AWUSER_WIDTH-1:0]           awuser,
    output logic                                      awvalid,
    /*
      AXI-MM interface - write data channel
    */
    output logic [AFU_AXI_MAX_DATA_WIDTH-1:0]     wdata,
    //output logic [AFU_AXI_MAX_ID_WIDTH-1:0]       wid,
    output logic                                  wlast,
     input                                        wready,
    output logic [(AFU_AXI_MAX_DATA_WIDTH/8)-1:0] wstrb,
    output logic [AFU_AXI_WUSER_WIDTH-1:0]        wuser,
    output logic                                  wvalid,  
    /*
      AXI-MM interface - write response channel
    */ 
     input [AFU_AXI_MAX_ID_WIDTH-1:0] bid,
    output logic                      bready,
     input [AFU_AXI_RESP_WIDTH-1:0]   bresp,
     input [AFU_AXI_BUSER_WIDTH-1:0]  buser,
     input                            bvalid,
    /*
      AXI-MM interface - read address channel
    */
    output logic [AFU_AXI_MAX_ADDR_WIDTH-1:0]         araddr,
    output logic [AFU_AXI_BURST_WIDTH-1:0]            arburst,
    output logic [AFU_AXI_CACHE_WIDTH-1:0]            arcache,
    output logic [AFU_AXI_MAX_ID_WIDTH-1:0]           arid,
    output logic [AFU_AXI_MAX_BURST_LENGTH_WIDTH-1:0] arlen,
    output logic [AFU_AXI_LOCK_WIDTH-1:0]             arlock,
    output logic [AFU_AXI_PROT_WIDTH-1:0]             arprot,
    output logic [AFU_AXI_QOS_WIDTH-1:0]              arqos,
     input                                            arready,
    output logic [AFU_AXI_REGION_WIDTH-1:0]           arregion,
    output logic [AFU_AXI_SIZE_WIDTH-1:0]             arsize,
    output logic [AFU_AXI_ARUSER_WIDTH-1:0]           aruser,
    output logic                                      arvalid,
    /*
      AXI-MM interface - read response channel
    */ 
     input [AFU_AXI_MAX_DATA_WIDTH-1:0] rdata,
     input [AFU_AXI_MAX_ID_WIDTH-1:0]   rid,
     input                              rlast,
    output logic                        rready,
     input [AFU_AXI_RESP_WIDTH-1:0]     rresp,
     input [AFU_AXI_RUSER_WIDTH-1:0]    ruser,
     input                              rvalid,

  `ifndef ORIGINAL_CCV_AFU_MODE
    /* bios based memory base address
    */
     input [31:0] cafu_csr0_conf_base_addr_high,
     input        cafu_csr0_conf_base_addr_high_valid,
     input [31:0] cafu_csr0_conf_base_addr_low,
     input        cafu_csr0_conf_base_addr_low_valid,
    /*   register access ports
    */
     input rtlgen_pkg_v12::cfg_req_64bit_t  treg_req,
    output rtlgen_pkg_v12::cfg_ack_64bit_t  treg_ack, 
  `else
    /* bios based memory base address
    */
     input [31:0] ccv_afu_conf_base_addr_high,
     input        ccv_afu_conf_base_addr_high_valid,
     input [31:0] ccv_afu_conf_base_addr_low,
     input        ccv_afu_conf_base_addr_low_valid,
    /*   register access ports
    */
     input ccv_afu_cfg_cr_req_t   treg_req,
    output ccv_afu_cfg_cr_ack_t   treg_ack,
  `endif
  //CXL RESET handshake signal to ED 
  output logic                                usr2ip_cxlreset_initiate, 
  input  logic                                ip2usr_cxlreset_error,
  input  logic                                ip2usr_cxlreset_complete, 

  `ifdef SINGLE_SLICE_ENV
    // copied over from sc_afu_wrapper
    input logic resetprep_en,
  `endif
  `ifndef SINGLE_SLICE_ENV
     input logic doe_poisoned_wr_err, 
  `endif

  output [ext_csr_if_pkg::CAFU2IP_CSR0_CFG_IF_WIDTH-1:0] cafu2ip_csr0_cfg_if,

  input logic [ext_csr_if_pkg::TMP_NEW_DVSEC_FBCTRL2_STATUS2_T_BW-1:0] ip2cafu_csr0_cfg_if
);

// =================================================================================================
/* config registers interface to/from registers to multi-write-algorithm-engine
*/
`ifndef ORIGINAL_CCV_AFU_MODE
  //cafu_csr0_cfg_cr_req_t          treg_req_cfg;
  //cafu_csr0_cfg_cr_ack_t          treg_ack_cfg;

  //cafu_csr0_cfg_cr_req_t          treg_req_doe;
  //cafu_csr0_cfg_cr_ack_t          treg_ack_doe;
  
  rtlgen_pkg_v12::cfg_req_64bit_t    treg_req_cfg;
  rtlgen_pkg_v12::cfg_ack_64bit_t    treg_ack_cfg;
  
  rtlgen_pkg_v12::cfg_req_64bit_t    treg_req_doe;
  rtlgen_pkg_v12::cfg_ack_64bit_t    treg_ack_doe;  
  
  tmp_cafu_csr0_cfg_pkg::tmp_CONFIG_TEST_START_ADDR_t        start_address_reg;
  tmp_cafu_csr0_cfg_pkg::tmp_CONFIG_TEST_WR_BACK_ADDR_t      write_back_address_reg;
  tmp_cafu_csr0_cfg_pkg::tmp_CONFIG_TEST_ADDR_INCRE_t        increment_reg;
  tmp_cafu_csr0_cfg_pkg::tmp_CONFIG_TEST_PATTERN_t           pattern_reg;
  tmp_cafu_csr0_cfg_pkg::tmp_CONFIG_TEST_BYTEMASK_t          byte_mask_reg;
  tmp_cafu_csr0_cfg_pkg::tmp_CONFIG_TEST_PATTERN_PARAM_t     pattern_config_reg;
  tmp_cafu_csr0_cfg_pkg::tmp_CONFIG_ALGO_SETTING_t           algorithm_config_reg;
  tmp_cafu_csr0_cfg_pkg::tmp_DEVICE_ERROR_LOG3_t             device_error_log3_reg;
  tmp_cafu_csr0_cfg_pkg::tmp_DEVICE_FORCE_DISABLE_t          device_force_disable_reg;
  tmp_cafu_csr0_cfg_pkg::tmp_DEVICE_ERROR_INJECTION_t        device_error_injection_reg;
  tmp_cafu_csr0_cfg_pkg::tmp_DEVICE_AFU_LATENCY_MODE_t       device_afu_latency_mode_reg;

  tmp_cafu_csr0_cfg_pkg::tmp_new_DEVICE_ERROR_LOG1_t         error_log_1_reg;
  tmp_cafu_csr0_cfg_pkg::tmp_new_DEVICE_ERROR_LOG2_t         error_log_2_reg;
  tmp_cafu_csr0_cfg_pkg::tmp_new_DEVICE_ERROR_LOG3_t         error_log_3_reg;
  tmp_cafu_csr0_cfg_pkg::tmp_new_DEVICE_ERROR_LOG4_t         error_log_4_reg;
  tmp_cafu_csr0_cfg_pkg::tmp_new_DEVICE_ERROR_LOG5_t         error_log_5_reg;
  tmp_cafu_csr0_cfg_pkg::tmp_new_DEVICE_AFU_STATUS1_t        device_afu_status_1_reg;
  tmp_cafu_csr0_cfg_pkg::tmp_new_DEVICE_AFU_STATUS2_t        device_afu_status_2_reg;
  tmp_cafu_csr0_cfg_pkg::tmp_new_CONFIG_CXL_ERRORS_t         config_and_cxl_errors_reg;
  tmp_cafu_csr0_cfg_pkg::tmp_new_DEVICE_ERROR_INJECTION_t    new_device_error_injection_reg;
  tmp_cafu_csr0_cfg_pkg::tmp_new_DEVICE_AFU_LATENCY_MODE_t   new_device_afu_latency_mode_reg;

  tmp_cafu_csr0_cfg_pkg::tmp_new_DEVICE_AXI2CPI_STATUS_1_t   new_inputs_to_DEVICE_AXI2CPI_STATUS_1;
  tmp_cafu_csr0_cfg_pkg::tmp_new_DEVICE_AXI2CPI_STATUS_2_t   new_inputs_to_DEVICE_AXI2CPI_STATUS_2;

  tmp_cafu_csr0_cfg_pkg::tmp_DEVICE_AXI2CPI_STATUS_1_t   current_DEVICE_AXI2CPI_STATUS_1;
  tmp_cafu_csr0_cfg_pkg::tmp_DEVICE_AXI2CPI_STATUS_2_t   current_DEVICE_AXI2CPI_STATUS_2;
`else
  cafu_csr0_cfg_cr_req_t          treg_req_cfg;
  cafu_csr0_cfg_cr_ack_t          treg_ack_cfg;

  CONFIG_TEST_START_ADDR_t        start_address_reg;
  CONFIG_TEST_WR_BACK_ADDR_t      write_back_address_reg;
  CONFIG_TEST_ADDR_INCRE_t        increment_reg;
  CONFIG_TEST_PATTERN_t           pattern_reg;
  CONFIG_TEST_BYTEMASK_t          byte_mask_reg;
  CONFIG_TEST_PATTERN_PARAM_t     pattern_config_reg;
  CONFIG_ALGO_SETTING_t           algorithm_config_reg;
  DEVICE_ERROR_LOG3_t             device_error_log3_reg;
  DEVICE_FORCE_DISABLE_t          device_force_disable_reg;
  DEVICE_ERROR_INJECTION_t        device_error_injection_reg;

  new_DEVICE_ERROR_LOG1_t         error_log_1_reg;
  new_DEVICE_ERROR_LOG2_t         error_log_2_reg;
  new_DEVICE_ERROR_LOG3_t         error_log_3_reg;
  new_DEVICE_ERROR_LOG4_t         error_log_4_reg;
  new_DEVICE_ERROR_LOG5_t         error_log_5_reg;
  new_DEVICE_AFU_STATUS1_t        device_afu_status_1_reg;
  new_DEVICE_AFU_STATUS2_t        device_afu_status_2_reg;
  new_CONFIG_CXL_ERRORS_t         config_and_cxl_errors_reg;
  new_DEVICE_ERROR_INJECTION_t    new_device_error_injection_reg;

  new_DEVICE_AXI2CPI_STATUS_1_t   new_inputs_to_DEVICE_AXI2CPI_STATUS_1;
  new_DEVICE_AXI2CPI_STATUS_2_t   new_inputs_to_DEVICE_AXI2CPI_STATUS_2;

  DEVICE_AXI2CPI_STATUS_1_t   current_DEVICE_AXI2CPI_STATUS_1;
  DEVICE_AXI2CPI_STATUS_2_t   current_DEVICE_AXI2CPI_STATUS_2;
`endif

`ifndef SINGLE_SLICE_ENV
  tmp_cafu_csr0_cfg_pkg::tmp_DVSEC_FBRANGE1SZHIGH_t  POR_DVSEC_FBRANGE1SZHIGH;
  tmp_cafu_csr0_cfg_pkg::tmp_DVSEC_FBRANGE1SZLOW_t   POR_DVSEC_FBRANGE1SZLOW;
  tmp_cafu_csr0_cfg_pkg::tmp_DVSEC_FBCAP_HDR2_t      POR_DVSEC_FBCAP_HDR2;
  tmp_cafu_csr0_cfg_pkg::tmp_DVSEC_HDR1_t            POR_DVSEC_HDR1;
  tmp_cafu_csr0_cfg_pkg::tmp_DVSEC_FBLOCK_t          POR_DVSEC_FBLOCK;
`endif  // ifndef T2IP_

  //tmp_cafu_csr0_cfg_pkg::tmp_new_DVSEC_FBCTRL2_STATUS2_t     new_dvsec_fbctrl2_status2;
  tmp_cafu_csr0_cfg_pkg::tmp_load_DVSEC_FBCTRL2_STATUS2_t    load_dvsec_fbctrl2_status2;
  tmp_cafu_csr0_cfg_pkg::tmp_new_DVSEC_FBCTRL_STATUS_t       viral_status_in;
  tmp_cafu_csr0_cfg_pkg::tmp_DVSEC_FBCAP_HDR2_t              dvsec_fbcap_hdr2;
  tmp_cafu_csr0_cfg_pkg::tmp_DVSEC_FBCTRL2_STATUS2_t         dvsec_fbctrl2_status2;
  tmp_cafu_csr0_cfg_pkg::tmp_DVSEC_FBCTRL_STATUS_t           dvsec_fbctrl_status;
  tmp_cafu_csr0_cfg_pkg::tmp_MC_STATUS_t                     new_ddr_mc_status_Q;
  tmp_cafu_csr0_cfg_pkg::tmp_new_CXL_MEM_DEV_STATUS_t        cxl_mem_dev_status ;

// =================================================================================================
/* config registers interface to/from other cafu csr0 logic
*/
tmp_cafu_csr0_cfg_pkg::tmp_HDM_DEC_GBL_CTRL_t      hdm_dec_gbl_ctrl;
tmp_cafu_csr0_cfg_pkg::tmp_HDM_DEC_CTRL_t          hdm_dec_ctrl;    

tmp_cafu_csr0_cfg_pkg::tmp_new_DEVMEM_SBECNT_t          new_devmem_sbecnt_Q;
tmp_cafu_csr0_cfg_pkg::tmp_new_DEVMEM_DBECNT_t          new_devmem_dbecnt_Q;
tmp_cafu_csr0_cfg_pkg::tmp_new_DEVMEM_POISONCNT_t       new_devmem_poisoncnt_Q;   

tmp_cafu_csr0_cfg_pkg::tmp_DVSEC_FBRANGE1HIGH_t    dvsec_fbrange1high;
tmp_cafu_csr0_cfg_pkg::tmp_DVSEC_FBRANGE1LOW_t     dvsec_fbrange1low;
tmp_cafu_csr0_cfg_pkg::tmp_DVSEC_FBRANGE1SZHIGH_t  fbrange1_sz_high;
tmp_cafu_csr0_cfg_pkg::tmp_DVSEC_FBRANGE1SZLOW_t   fbrange1_sz_low;

tmp_cafu_csr0_cfg_pkg::tmp_HDM_DEC_BASEHIGH_t      hdm_dec_basehigh;
tmp_cafu_csr0_cfg_pkg::tmp_HDM_DEC_BASELOW_t       hdm_dec_baselow;
tmp_cafu_csr0_cfg_pkg::tmp_HDM_DEC_SIZEHIGH_t      hdm_dec_sizehigh;
tmp_cafu_csr0_cfg_pkg::tmp_HDM_DEC_SIZELOW_t       hdm_dec_sizelow;

//tmp_cafu_csr0_cfg_pkg::tmp_DVSEC_FBCAP_HDR2_t       POR_DVSEC_FBCAP_HDR2;
//tmp_cafu_csr0_cfg_pkg::tmp_DVSEC_FBCAP_HDR2_t       dvsec_fbcap_hdr2;
//tmp_cafu_csr0_cfg_pkg::tmp_DVSEC_FBCTRL2_STATUS2_t  dvsec_fbctrl2_status2;
//tmp_cafu_csr0_cfg_pkg::tmp_DVSEC_FBCTRL_STATUS_t    dvsec_fbctrl_status;

tmp_cafu_csr0_cfg_pkg::tmp_MBOX_EVENTINJ_t              bbs_mbox_eventinj;
tmp_cafu_csr0_cfg_pkg::tmp_CXL_MB_CMD_t                 cxl_mb_cmd;
tmp_cafu_csr0_cfg_pkg::tmp_CXL_MB_CTRL_t                cxl_mb_ctrl;
tmp_cafu_csr0_cfg_pkg::tmp_load_CXL_MB_CMD_t            hyc_load_cxl_mb_cmd;
tmp_cafu_csr0_cfg_pkg::tmp_new_CXL_MB_CMD_t             hyc_new_cxl_mb_cmd;
tmp_cafu_csr0_cfg_pkg::tmp_load_CXL_MB_CTRL_t           hyc_load_cxl_mb_ctrl;
tmp_cafu_csr0_cfg_pkg::tmp_new_CXL_MB_CTRL_t            hyc_new_cxl_mb_ctrl;
tmp_cafu_csr0_cfg_pkg::tmp_new_CXL_MB_STATUS_t          hyc_mb_status;
tmp_cafu_csr0_cfg_pkg::tmp_CXL_DEV_CAP_EVENT_STATUS_t   hyc_dev_cap_event_status;
tmp_cafu_csr0_cfg_pkg::tmp_new_DOE_CTLREG_t             new_doe_ctlreg;
tmp_cafu_csr0_cfg_pkg::tmp_load_DOE_CTLREG_t            load_doe_ctlreg;
tmp_cafu_csr0_cfg_pkg::tmp_DOE_CTLREG_t                 doe_ctlreg;
tmp_cafu_csr0_cfg_pkg::tmp_new_DOE_STSREG_t             new_doe_stsreg;
tmp_cafu_csr0_cfg_pkg::tmp_load_DOE_STSREG_t            load_doe_stsreg;
tmp_cafu_csr0_cfg_pkg::tmp_lock_HDM_DEC_CTRL_t          lock_hdm_dec_ctrl;

logic [1:0]                                             load_CDAT_0_stg;
logic [1:0]                                             load_CDAT_1_stg;

tmp_cafu_csr0_cfg_pkg::tmp_load_CDAT_0_t                load_CDAT_0_reg;
tmp_cafu_csr0_cfg_pkg::tmp_load_CDAT_1_t                load_CDAT_1_reg;

tmp_cafu_csr0_cfg_pkg::tmp_new_CDAT_0_t                 new_CDAT_0_In;
tmp_cafu_csr0_cfg_pkg::tmp_new_CDAT_1_t                 new_CDAT_1_In;

logic [63:0]                                            mbox_ram_dout;
logic                                                   hyc_hw_mbox_ram_rd_en;
logic [7:0]                                             hyc_hw_mbox_ram_rd_addr;
logic                                                   hyc_hw_mbox_ram_wr_en;
logic [7:0]                                             hyc_hw_mbox_ram_wr_addr;
logic [63:0]                                            hyc_hw_mbox_ram_wr_data;

logic [31:0]                                            cdat_0, cdat_1, cdat_2, cdat_3;
logic [31:0]                                            dsmas_0, dsmas_1, dsmas_2, dsmas_3, dsmas_4, dsmas_5;
logic [31:0]                                            dslbis_0, dslbis_1, dslbis_2, dslbis_3, dslbis_4, dslbis_5;
logic [31:0]                                            dsis_0, dsis_1;
logic [31:0]                                            dsemts_0, dsemts_1, dsemts_2, dsemts_3, dsemts_4, dsemts_5;

ext_csr_if_pkg::CxlDeviceType_e                         cxl_dev_type_mb;

tmp_cafu_csr0_cfg_pkg::tmp_new_DVSEC_FBCTRL2_STATUS2_t     new_dvsec_fbctrl2_status2;

// =================================================================================================
/*  map the axi signals to the interface */
//internal signals to connect mwae, cafu_mem_target to output
t_axi4_wr_addr_ch      cafu_axi_aw;
t_axi4_wr_data_ch      cafu_axi_w;
t_axi4_wr_resp_ch      cafu_axi_b;
t_axi4_rd_addr_ch      cafu_axi_ar;
t_axi4_rd_resp_ch      cafu_axi_r;
t_axi4_wr_addr_ready   cafu_axi_awready;
t_axi4_wr_data_ready   cafu_axi_wready;   
t_axi4_wr_resp_ready   cafu_axi_bready;
t_axi4_rd_addr_ready   cafu_axi_arready;
t_axi4_rd_resp_ready   cafu_axi_rready;

t_axi4_wr_addr_ch      mwae_axi_aw;
t_axi4_wr_data_ch      mwae_axi_w;
t_axi4_wr_resp_ch      mwae_axi_b;
t_axi4_rd_addr_ch      mwae_axi_ar;
t_axi4_rd_resp_ch      mwae_axi_r;
t_axi4_wr_addr_ready   mwae_axi_awready;
t_axi4_wr_data_ready   mwae_axi_wready;   
t_axi4_wr_resp_ready   mwae_axi_bready;
t_axi4_rd_addr_ready   mwae_axi_arready;
t_axi4_rd_resp_ready   mwae_axi_rready;

`ifdef CPI_MODE
  t_axi4_wr_addr_ch      axi2cpi_axi_aw;
  t_axi4_wr_data_ch      axi2cpi_axi_w;
  t_axi4_wr_resp_ch      axi2cpi_axi_b;
  t_axi4_rd_addr_ch      axi2cpi_axi_ar;
  t_axi4_rd_resp_ch      axi2cpi_axi_r;
  t_axi4_wr_addr_ready   axi2cpi_axi_awready;
  t_axi4_wr_data_ready   axi2cpi_axi_wready;   
  t_axi4_wr_resp_ready   axi2cpi_axi_bready;
  t_axi4_rd_addr_ready   axi2cpi_axi_arready;
  t_axi4_rd_resp_ready   axi2cpi_axi_rready;
`endif

// =================================================================================================
/* flag from mwae indicating that HW wants to set the error status field of the
   ERROR_LOG3 cfg reg.
   Software will then set this field to zero to clear all error log registers.
*/
logic mwae_to_cfg_enable_new_error_log3_error_status;

logic locked_protocol_type;
// =================================================================================================
// I/F for cafu_csr0 regs needed by CXL IP
ext_csr_if_pkg::cafu2ip_csr0_cfg_if_t    cafu2ip_csr0_cfg_if_tmp;

always_comb
begin
  cafu2ip_csr0_cfg_if_tmp = 'd0;

  cafu2ip_csr0_cfg_if_tmp.dvsec_fbcap_hdr2      = dvsec_fbcap_hdr2;
  cafu2ip_csr0_cfg_if_tmp.dvsec_fbctrl2_status2 = dvsec_fbctrl2_status2;
  cafu2ip_csr0_cfg_if_tmp.dvsec_fbctrl_status   = dvsec_fbctrl_status;
end

assign cafu2ip_csr0_cfg_if = cafu2ip_csr0_cfg_if_tmp;
assign usr2ip_cxlreset_initiate                  = dvsec_fbctrl2_status2.initiate_cxl_reset;

`ifdef SINGLE_SLICE_ENV
   assign o_dvsec_fbcap_hdr2      = dvsec_fbcap_hdr2;
   assign o_dvsec_fbctrl2_status2 = dvsec_fbctrl2_status2;
   assign o_dvsec_fbctrl_status   = dvsec_fbctrl_status;
`endif

// I/F for cafu_csr0 regs needed by CXL IP


assign new_dvsec_fbctrl2_status2 = tmp_cafu_csr0_cfg_pkg::tmp_new_DVSEC_FBCTRL2_STATUS2_t'( 
                                   {ip2cafu_csr0_cfg_if[ext_csr_if_pkg::TMP_NEW_DVSEC_FBCTRL2_STATUS2_T_BW-1:5],ip2usr_cxlreset_error,ip2usr_cxlreset_complete,
                                    ip2cafu_csr0_cfg_if[2:0]});

assign load_dvsec_fbctrl2_status2.initiate_cache_wb_and_inv     = dvsec_fbctrl2_status2.initiate_cache_wb_and_inv;  
assign load_dvsec_fbctrl2_status2.initiate_cxl_reset            = dvsec_fbctrl2_status2.initiate_cxl_reset;
//assign load_dvsec_fbctrl2_status2.cache_invalid                 = 1'b1;
//assign load_dvsec_fbctrl2_status2.cxl_reset_complete            = 1'b1;
//assign load_dvsec_fbctrl2_status2.cxl_reset_error               = 1'b1;
//assign load_dvsec_fbctrl2_status2.power_mgt_init_complete       = 1'b1;

// =================================================================================================
always_comb
begin
    awid                    =   cafu_axi_aw.awid;
    awaddr                  =   cafu_axi_aw.awaddr;
    awlen                   =   cafu_axi_aw.awlen;
    awsize                  =   cafu_axi_aw.awsize;
    awburst                 =   cafu_axi_aw.awburst;
    awprot                  =   cafu_axi_aw.awprot;
    awqos                   =   cafu_axi_aw.awqos;
    awuser                  =   cafu_axi_aw.awuser;
    awvalid                 =   cafu_axi_aw.awvalid;
    awcache                 =   cafu_axi_aw.awcache;
    awlock                  =   cafu_axi_aw.awlock;
    awregion                =   cafu_axi_aw.awregion;
    cafu_axi_awready        =   awready;
    
    wdata                   =   cafu_axi_w.wdata;
    wstrb                   =   cafu_axi_w.wstrb;
    wlast                   =   cafu_axi_w.wlast;
    wuser                   =   cafu_axi_w.wuser;
    wvalid                  =   cafu_axi_w.wvalid;
    cafu_axi_wready         =   wready;
    
    cafu_axi_b.bid          =   bid;
    cafu_axi_b.bresp        =   t_axi4_resp_encoding'(bresp);
    cafu_axi_b.buser        =   buser;   //t_axi4_buser_opcode'(buser);
    cafu_axi_b.bvalid       =   bvalid;
    bready                  =   cafu_axi_bready;
    
    arid                    =   cafu_axi_ar.arid;
    araddr                  =   cafu_axi_ar.araddr;
    arlen                   =   cafu_axi_ar.arlen;
    arsize                  =   cafu_axi_ar.arsize;
    arburst                 =   cafu_axi_ar.arburst;
    arprot                  =   cafu_axi_ar.arprot;
    arqos                   =   cafu_axi_ar.arqos;
    aruser                  =   cafu_axi_ar.aruser;
    arvalid                 =   cafu_axi_ar.arvalid;
    arcache                 =   cafu_axi_ar.arcache;
    arlock                  =   cafu_axi_ar.arlock;
    arregion                =   cafu_axi_ar.arregion;
    cafu_axi_arready        =   arready;
    
    cafu_axi_r.rid          =   rid;
    cafu_axi_r.rdata        =   rdata;
    cafu_axi_r.rresp        =   t_axi4_resp_encoding'(rresp);
    cafu_axi_r.rlast        =   rlast;
    cafu_axi_r.ruser        =   t_axi4_ruser'(ruser); //t_axi4_ruser_opcode'(ruser);
    cafu_axi_r.rvalid       =   rvalid;
    rready                  =   cafu_axi_rready;
end

// =================================================================================================
//`ifdef CPI_MODE

// =================================================================================================
`ifdef CPI_MODE
  /* if in CPI_MODE, we want cxl.cache traffic to go to CPI interface but cxl_io traffic to keep
        going to axi via cafu_mem_target.
   */
  always_comb
  begin
    cafu_axi_aw = (cafu_user_enabled_cxl_io == 1'b1) ? mwae_axi_aw : 'd0;
    cafu_axi_w  = (cafu_user_enabled_cxl_io == 1'b1) ? mwae_axi_w  : 'd0;
    cafu_axi_ar = (cafu_user_enabled_cxl_io == 1'b1) ? mwae_axi_ar : 'd0;

    axi2cpi_axi_aw = (cafu_user_enabled_cxl_io == 1'b1) ? 'd0 : mwae_axi_aw;
    axi2cpi_axi_w  = (cafu_user_enabled_cxl_io == 1'b1) ? 'd0 : mwae_axi_w;
    axi2cpi_axi_ar = (cafu_user_enabled_cxl_io == 1'b1) ? 'd0 : mwae_axi_ar;

    cafu_axi_bready = (cafu_user_enabled_cxl_io == 1'b1) ? mwae_axi_bready : 1'b0;
    cafu_axi_rready = (cafu_user_enabled_cxl_io == 1'b1) ? mwae_axi_rready : 1'b0;

    axi2cpi_axi_bready = (cafu_user_enabled_cxl_io == 1'b1) ? 1'b0 : mwae_axi_bready;
    axi2cpi_axi_rready = (cafu_user_enabled_cxl_io == 1'b1) ? 1'b0 : mwae_axi_rready;

    mwae_axi_b = (cafu_user_enabled_cxl_io == 1'b1) ? cafu_axi_b : axi2cpi_axi_b;
    mwae_axi_r = (cafu_user_enabled_cxl_io == 1'b1) ? cafu_axi_r : axi2cpi_axi_r;

    mwae_axi_awready = (cafu_user_enabled_cxl_io == 1'b1) ? cafu_axi_awready : axi2cpi_axi_awready;
    mwae_axi_wready  = (cafu_user_enabled_cxl_io == 1'b1) ? cafu_axi_wready  : axi2cpi_axi_wready;
    mwae_axi_arready = (cafu_user_enabled_cxl_io == 1'b1) ? cafu_axi_arready : axi2cpi_axi_arready;
  end

`else
  /* if not in CPI_MODE, just assign the axi signals to/from cafu_mem_target to the axi signals
        to/from mwae_top
   */
  /* instance of cafu_mem_target 
   * mawe_top      ->|
   * cafu_csr0_cfg ->|
   *                 | cafu_mem_target               
   */
  cafu_mem_target u_cafu_mem_target (
        .clk (rtl_clk),
        .rst (~rst_n),
        
        .mwae_axi_aw           (mwae_axi_aw),
        .mwae_axi_w            (mwae_axi_w),
        .mwae_axi_b            (mwae_axi_b),
        .mwae_axi_awready      (mwae_axi_awready),
        .mwae_axi_wready       (mwae_axi_wready),
        .mwae_axi_bready       (mwae_axi_bready), 
        
        .mwae_axi_ar           (mwae_axi_ar),
        .mwae_axi_r            (mwae_axi_r),    
        .mwae_axi_arready      (mwae_axi_arready),
        .mwae_axi_rready       (mwae_axi_rready),
        
        .cafu_axi_aw           (cafu_axi_aw),
        .cafu_axi_w            (cafu_axi_w),
        .cafu_axi_b            (cafu_axi_b),
        .cafu_axi_awready      (cafu_axi_awready),
        .cafu_axi_wready       (cafu_axi_wready),
        .cafu_axi_bready       (cafu_axi_bready),         
        
        .cafu_axi_ar           (cafu_axi_ar),
        .cafu_axi_r            (cafu_axi_r),    
        .cafu_axi_arready      (cafu_axi_arready),
        .cafu_axi_rready       (cafu_axi_rready),        
        
        .hdm_dec_gbl_ctrl      (hdm_dec_gbl_ctrl),  
        .hdm_dec_ctrl          (hdm_dec_ctrl), 
        .dvsec_fbrange1high    (dvsec_fbrange1high),                   
        .dvsec_fbrange1low     (dvsec_fbrange1low), 
        .fbrange1_sz_high      (fbrange1_sz_high),  
        .fbrange1_sz_low       (fbrange1_sz_low),   
        .hdm_dec_basehigh      (hdm_dec_basehigh),
        .hdm_dec_baselow       (hdm_dec_baselow),                   
        .hdm_dec_sizehigh      (hdm_dec_sizehigh), 
        .hdm_dec_sizelow       (hdm_dec_sizelow)
    );

`endif

// =================================================================================================
cafu_devreg_mailbox   u_cafu_devreg_mailbox
(
  .cxlbbs_clk          (rtl_clk),
  .cxlbbs_pwrgood_rst  (~rst_n),   //power good reset
  .cxlbbs_rst          (~rst_n),   //warm reset
  .sbr_clk_i           (rtl_clk),  //Sideband Clk
  .sbr_rstb_i          (rst_n),    //Sideband Reset

  .bbs_mbox_eventinj,

  .cxl_mb_cmd,
  .cxl_mb_ctrl,

  .hyc_mem_active  (mc_mem_active),
  .mbox_ram_dout,
 
  `ifdef SINGLE_SLICE_ENV
     .mc_err_cnt  ('0),
  `else
      .mc_err_cnt ( mc_err_cnt ),
  `endif  // ifdef SINGLE_SLICE_ENV

  .hyc_load_cxl_mb_cmd,
  .hyc_new_cxl_mb_cmd,

  .hyc_load_cxl_mb_ctrl,
  .hyc_new_cxl_mb_ctrl,

  .hyc_mb_status,
  .hyc_dev_cap_event_status,
  
  .hyc_hw_mbox_ram_rd_en,
  .hyc_hw_mbox_ram_rd_addr,
  .hyc_hw_mbox_ram_wr_en,
  .hyc_hw_mbox_ram_wr_addr,
  .hyc_hw_mbox_ram_wr_data
);

// =================================================================================================
cafu_csr_doe u_cafu_csr_doe (
    .clk                (rtl_clk),
    .rst                (~rst_n),

    // CXL Device Type
    .cxl_dev_type       (cxl_dev_type_mb),
  `ifndef SINGLE_SLICE_ENV
    //Poisoned CFG Write to DOE CFG register error flag
    .doe_poisoned_wr_err (doe_poisoned_wr_err), 
  `else 
    .doe_poisoned_wr_err (1'b0), 
   `endif
    // Target Register Access Interface for DOE Req/Ack
    .treg_req_doe        (treg_req_doe),
    .treg_ack_doe        (treg_ack_doe),

    // DOE Config Registers
    .cdat_0,
    .cdat_1,
    .cdat_2,
    .cdat_3,
    .dsmas_0,
    .dsmas_1,
    .dsmas_2,
    .dsmas_3,
    .dsmas_4,
    .dsmas_5,
    .dslbis_0,
    .dslbis_1,
    .dslbis_2,
    .dslbis_3,
    .dslbis_4,
    .dslbis_5,
    .dsis_0,
    .dsis_1,
    .dsemts_0,
    .dsemts_1,
    .dsemts_2,
    .dsemts_3,
    .dsemts_4,
    .dsemts_5,

    // DOE Controls
    .doe_abort          (doe_ctlreg.doe_abort),
    .doe_go             (doe_ctlreg.doe_go),
    .doe_ready          (new_doe_stsreg.data_object_ready),
    .doe_busy           (new_doe_stsreg.doe_busy),
    .doe_error          (new_doe_stsreg.doe_error)
);

// =================================================================================================
/*
 *   instance of the multi-write-algorithm-engine module
 */
mwae_top   inst_mwae_top
(
    .rtl_clk        ( rtl_clk ),
    .reset_n        ( rst_n ),
    
    /*
       AXI-MM interface - this afu is the initator
    */
    .o_axi_wr_addr_chan ( mwae_axi_aw ),
    .i_axi_awready      ( mwae_axi_awready ),

    .o_axi_wr_data_chan ( mwae_axi_w      ),
    .i_axi_wready       ( mwae_axi_wready ),

    .i_axi_wr_resp_chan ( mwae_axi_b      ),
    .o_axi_bready       ( mwae_axi_bready ),

    .o_axi_rd_addr_chan ( mwae_axi_ar ),
    .i_axi_arready      ( mwae_axi_arready ),

    .i_axi_rd_resp_chan ( mwae_axi_r      ),
    .o_axi_rready       ( mwae_axi_rready ),
 
    /*  August 2023 - send out locked protocol type reg to higher level modules
     */
    .o_locked_protocol_type ( locked_protocol_type ),

    /*
     * temporary place holds for config registers interface
    */   
    .start_address_reg        ( start_address_reg ),
    .write_back_address_reg   ( write_back_address_reg ),
    .increment_reg            ( increment_reg ),
    .pattern_reg              ( pattern_reg ),
    .bytemask_reg             ( byte_mask_reg ),
    .pattern_config_reg       ( pattern_config_reg ),
    .algorithm_config_reg     ( algorithm_config_reg ),
    .device_error_log3_reg    ( device_error_log3_reg ),
    .device_force_disable_reg ( device_force_disable_reg ),

    .config_and_cxl_errors_reg ( config_and_cxl_errors_reg  ),
    .device_afu_status_1_reg   ( device_afu_status_1_reg    ),
    .device_afu_status_2_reg   ( device_afu_status_2_reg    ),

    .new_device_error_injection_reg ( new_device_error_injection_reg ), 
    .device_error_injection_reg     (     device_error_injection_reg ), 

    .new_device_afu_latency_mode_reg ( new_device_afu_latency_mode_reg ),
    .device_afu_latency_mode_reg     (     device_afu_latency_mode_reg ),

    .error_log_1_reg ( error_log_1_reg ),
    .error_log_2_reg ( error_log_2_reg ),
    .error_log_3_reg ( error_log_3_reg ),
    .error_log_4_reg ( error_log_4_reg ),
    .error_log_5_reg ( error_log_5_reg ),

    .record_error_out ( mwae_to_cfg_enable_new_error_log3_error_status )
);

// =================================================================================================
//`ifdef CPI_MODE

// =================================================================================================
//`ifdef CPI_MODE

// =================================================================================================
/* instance of the config registers 

*/
`ifndef ORIGINAL_CCV_AFU_MODE

  /* August 2023 - send out locked protocol type reg to higher level modules
     Use here to stage IO enable
   */
  //assign cafu_user_enabled_cxl_io = ( algorithm_config_reg.interface_protocol_type == 3'b001 );

  logic cafu_user_enabled_cxl_io_stg_1;
  
  assign cafu_user_enabled_cxl_io_stg_1 = ( locked_protocol_type == 3'b001 );
  
  always_ff @( posedge rtl_clk )
  begin
    cafu_user_enabled_cxl_io <= cafu_user_enabled_cxl_io_stg_1;
  end
   
  //Assign doe_ctlreg values to cause 1 cycle pulse
  assign load_doe_ctlreg.doe_go            = doe_ctlreg.doe_go;
  assign load_doe_ctlreg.doe_abort         = doe_ctlreg.doe_abort;
  assign new_doe_ctlreg.doe_go             = 1'b0;
  assign new_doe_ctlreg.doe_abort          = 1'b0;

  //Assign doe_stsreg values
  //assign load_doe_stsreg.data_object_ready = 1'b1;
  //assign load_doe_stsreg.doe_error         = 1'b1;
  assign load_doe_stsreg.doe_int_status    = 1'b0;
  //assign load_doe_stsreg.doe_busy          = 1'b1;
  assign new_doe_stsreg.doe_int_status     = 1'b0;

  // =================================================================================================
  logic   hdm_dec_lock1_Q, hdm_dec_lock2_Q, hdm_dec_commit_Q;
  //HDM DECODER
  //Assign HDM DEC CTRL lock bits
  assign lock_hdm_dec_ctrl.target_dev_type        = hdm_dec_lock1_Q;
  assign lock_hdm_dec_ctrl.commit                 = hdm_dec_lock2_Q;
  assign lock_hdm_dec_ctrl.lock_on_commit         = hdm_dec_lock1_Q;
  assign lock_hdm_dec_ctrl.interleave_ways        = hdm_dec_lock1_Q;
  assign lock_hdm_dec_ctrl.interleave_granularity = hdm_dec_lock1_Q;

  always_ff @(posedge rtl_clk)
  begin
       hdm_dec_lock1_Q     <=   hdm_dec_ctrl.committed;
       hdm_dec_lock2_Q     <=   hdm_dec_ctrl.committed && hdm_dec_ctrl.lock_on_commit;
       hdm_dec_commit_Q    <=   hdm_dec_ctrl.commit;
  end

  //----------------------------------------------------------
  // BBS_DEVMEM_*CNT - Device Memory Error Count
  //----------------------------------------------------------


 always_ff @(posedge rtl_clk) begin
    new_devmem_sbecnt_Q.chan0_cnt    <= mc_err_cnt[0].SBECnt;
    new_devmem_dbecnt_Q.chan0_cnt    <= mc_err_cnt[0].DBECnt;
    new_devmem_poisoncnt_Q.chan0_cnt <= mc_err_cnt[0].PoisonRtnCnt;
 end

 generate
    if (cxlip_top_pkg::MC_CHANNEL == 2) begin : GenMc1ErrCnt
       always_ff @(posedge rtl_clk) begin
          new_devmem_sbecnt_Q.chan1_cnt    <= mc_err_cnt[1].SBECnt;
          new_devmem_dbecnt_Q.chan1_cnt    <= mc_err_cnt[1].DBECnt;
          new_devmem_poisoncnt_Q.chan1_cnt <= mc_err_cnt[1].PoisonRtnCnt;
       end
    end
    else begin : GenMc1ErrCnt
       always_comb begin
          new_devmem_sbecnt_Q.chan1_cnt    = '0;
          new_devmem_dbecnt_Q.chan1_cnt    = '0;
          new_devmem_poisoncnt_Q.chan1_cnt = '0;
       end
    end
 endgenerate

  // =================================================================================================
  cafu_reg_router    u_cafu_reg_router
  (
  //clock and reset
  .rst                             (~rst_n),
  .clk                             (rtl_clk),

  //Target Register Access Interface IP SIDE
  .treg_req_ep                     (treg_req),      // Req: IP to router
  .treg_ack_ep                     (treg_ack),      // Ack: router to IP

  //Target Register Access Interface CFG SIDE
  .treg_req_cfg                    (treg_req_cfg),  // Req: router to config
  .treg_ack_cfg                    (treg_ack_cfg),  // Ack: config to router

  //Target Register Access Interface DOE SIDE
  .treg_req_doe                    (treg_req_doe),  // Req: router to doe
  .treg_ack_doe                    (treg_ack_doe),  // Ack: router to doe

  //HW Mailbox RAM R/W
  .hw_mbox_ram_rd_en    (hyc_hw_mbox_ram_rd_en),
  .hw_mbox_ram_rd_addr  (hyc_hw_mbox_ram_rd_addr),
  .hw_mbox_ram_wr_en    (hyc_hw_mbox_ram_wr_en),
  .hw_mbox_ram_wr_addr  (hyc_hw_mbox_ram_wr_addr),
  .hw_mbox_ram_wr_data  (hyc_hw_mbox_ram_wr_data),
  .mbox_ram_dout
  );
 
    assign POR_DVSEC_FBCAP_HDR2.mem_capable     = 1'b1;
    assign new_CDAT_0_In                        = ext_csr_if_pkg::TYPE2_CDAT_0; // CDAT Length
    assign new_CDAT_1_In                        = ext_csr_if_pkg::TYPE2_CDAT_1; // CDAT Checksum and Revision

  // DOE CDAT POR Value assignments
  // Cast strap values to CxlDeviceType_e type
  always_comb cxl_dev_type_mb = CxlDeviceType_e'({POR_DVSEC_FBCAP_HDR2.mem_capable, 1'b1}); // {mem_capable, cache_capable} Type 1 and 2 devices cache_capable = 1'b1

  always_ff @(posedge rtl_clk)
  begin
    if (!rst_n) begin
        load_CDAT_0_stg <= 1'b0;
        load_CDAT_1_stg <= 1'b0;
    end else begin
        load_CDAT_0_stg <= {load_CDAT_0_stg[0], 1'b1};
        load_CDAT_1_stg <= {load_CDAT_1_stg[0], 1'b1};
    end
  end

  always_comb
  begin
    load_CDAT_0_reg     = (load_CDAT_0_stg[0] & (~load_CDAT_0_stg[1]));
    load_CDAT_1_reg     = (load_CDAT_1_stg[0] & (~load_CDAT_1_stg[1]));
  end

  // =================================================================================================
  //----------------------------------------------------------
  // DVSEC capabilities
  //----------------------------------------------------------
  `ifndef SINGLE_SLICE_ENV
     generate if (T1IP_ENABLE == 1'b0 )
     begin
        //DVSEC_FBRANGE1SZHIGH
        assign POR_DVSEC_FBRANGE1SZHIGH.memory_size          = hdm_size_256mb[35:4];
        //DVSEC_FBRANGE1SZLOW    
        assign POR_DVSEC_FBRANGE1SZLOW.media_type            = 3'b010;
        assign POR_DVSEC_FBRANGE1SZLOW.mem_active            = mc_mem_active;
        assign POR_DVSEC_FBRANGE1SZLOW.memory_active_timeout = 3'b001;
        assign POR_DVSEC_FBRANGE1SZLOW.memory_class          = 3'b010;
        assign POR_DVSEC_FBRANGE1SZLOW.memory_size_low       = hdm_size_256mb[3:0];
        assign POR_DVSEC_FBRANGE1SZLOW.mem_valid             = 1'b1  ;                 
        assign POR_DVSEC_FBRANGE1SZLOW.desired_interleave    = 3'b000;
        //DVSEC_FBCAP_HDR2   
        //assign POR_DVSEC_FBCAP_HDR2.mem_capable              = 1'b1   ;                       
        assign POR_DVSEC_FBCAP_HDR2.mem_hwInit_mode          = 1'b1   ;             
        assign POR_DVSEC_FBCAP_HDR2.hdm_count                = 2'b01  ;                
        // mem_dev_status   
        assign cxl_mem_dev_status               = mem_dev_status;
      end
     else begin
       //DVSEC_FBRANGE1SZHIGH
       assign POR_DVSEC_FBRANGE1SZHIGH.memory_size          = 32'h00000000;
       //DVSEC_FBRANGE1SZLOW    
       assign POR_DVSEC_FBRANGE1SZLOW.media_type            = 3'b000;
       assign POR_DVSEC_FBRANGE1SZLOW.mem_active            = 1'b0  ;
       assign POR_DVSEC_FBRANGE1SZLOW.memory_active_timeout = 3'b000;
       assign POR_DVSEC_FBRANGE1SZLOW.memory_class          = 3'b000;
       assign POR_DVSEC_FBRANGE1SZLOW.memory_size_low       = 4'h0 ;
       assign POR_DVSEC_FBRANGE1SZLOW.mem_valid             = 1'b0   ;                                    
       assign POR_DVSEC_FBRANGE1SZLOW.desired_interleave    = 3'b000;
       //DVSEC_FBCAP_HDR2   
       //assign POR_DVSEC_FBCAP_HDR2.mem_capable              = 1'b0    ;                       
       assign POR_DVSEC_FBCAP_HDR2.mem_hwInit_mode          = 1'b1   ;             
       assign POR_DVSEC_FBCAP_HDR2.hdm_count                = 2'b00  ;                
       // mem_dev_status   
       assign cxl_mem_dev_status               =   8'h10;
     end
     endgenerate 

     //DVSEC_FBLOCK 
     assign POR_DVSEC_FBLOCK.cache_size_unit               = 4'h1;
     assign POR_DVSEC_FBLOCK.cache_size                    = 8'h2; 
     //DVSEC_HDR1 
     assign POR_DVSEC_HDR1.dvsec_revision                  = 4'h1;
     assign POR_DVSEC_HDR1.dvsec_vendor_id                 = 16'h1E98;
     //DVSEC_FBCAP_HDR2   
     assign POR_DVSEC_FBCAP_HDR2.cxl_reset_capable         = 1'b1;
     assign POR_DVSEC_FBCAP_HDR2.cxl_reset_mem_clr_capable = 1'b0;
     assign POR_DVSEC_FBCAP_HDR2.cxl_reset_timeout         = 3'b010;
     assign POR_DVSEC_FBCAP_HDR2.pm_init_comp_capable      = 1'b1;
     assign POR_DVSEC_FBCAP_HDR2.cache_wb_and_inv_capable  = 1'b1;
     assign POR_DVSEC_FBCAP_HDR2.cache_capable             = 1'b1;

     //----------------------------------------------------------
     // BBS_MC_STATUS - Memory Controller Status
     //----------------------------------------------------------
     always_ff @(posedge rtl_clk)
     begin
        new_ddr_mc_status_Q <= tmp_cafu_csr0_cfg_pkg::tmp_MC_STATUS_t'(ddr_mc_status);
     end
  `endif  // ifndef SINGLE_SLICE_ENV

  // =================================================================================================
  cafu_csr0_cfg   inst_cafu_csr0_cfg
  (
    .gated_clk ( gated_clk ),
    .rtl_clk   ( rtl_clk   ),
    .rst_n     ( rst_n     ),
    .cxl_or_conv_rst_n ( cxl_or_conv_rst_n ),  //cxlreset or conventional reset
    .pwr_rst_n ( rst_n     ),
    .req       ( treg_req_cfg ),
    .ack       ( treg_ack_cfg ),

    // Register Inputs
    .load_CDAT_0 (load_CDAT_0_reg),
    .load_CDAT_1 (load_CDAT_1_reg),
    //.load_CXL_DVSEC_TEST_CNF_BASE_HIGH ( cafu_csr0_conf_base_addr_high_valid ),
    //.load_CXL_DVSEC_TEST_CNF_BASE_LOW  ( cafu_csr0_conf_base_addr_low_valid  ),
    .load_CXL_MB_CMD (hyc_load_cxl_mb_cmd),
    .load_CXL_MB_CTRL (hyc_load_cxl_mb_ctrl),
    .load_DEVICE_ERROR_LOG3 ( mwae_to_cfg_enable_new_error_log3_error_status ),
    .load_DEVICE_EVENT_COUNT ( 1'b0 ),
    .load_DOE_CTLREG (load_doe_ctlreg),
    .load_DOE_RDMAILREG ( 1'b0 ),
    .load_DOE_STSREG (load_doe_stsreg),
    .load_DOE_WRMAILREG ( 1'b0 ),
    .load_DVSEC_FBCTRL2_STATUS2 ( load_dvsec_fbctrl2_status2 ),
    .load_DVSEC_FBCTRL_STATUS   ( 1'b0 ),

    .lock_HDM_DEC_BASEHIGH ( hdm_dec_lock1_Q ),
    .lock_HDM_DEC_BASELOW  ( hdm_dec_lock1_Q ),
    .lock_HDM_DEC_CTRL     ( lock_hdm_dec_ctrl ),
    .lock_HDM_DEC_DPAHIGH  ( hdm_dec_lock1_Q ),
    .lock_HDM_DEC_DPALOW   ( hdm_dec_lock1_Q ),
    .lock_HDM_DEC_SIZEHIGH ( hdm_dec_lock1_Q ),
    .lock_HDM_DEC_SIZELOW  ( hdm_dec_lock1_Q ),

    .new_CDAT_0 (new_CDAT_0_In),
    .new_CDAT_1 (new_CDAT_1_In),
    .new_CONFIG_CXL_ERRORS ( config_and_cxl_errors_reg ),
    .new_CONFIG_DEVICE_INJECTION ( 2'd0 ),
    .new_CXL_DEV_CAP_EVENT_STATUS (hyc_dev_cap_event_status),
    .new_CXL_DVSEC_TEST_CNF_BASE_HIGH ( cafu_csr0_conf_base_addr_high ),
    .new_CXL_DVSEC_TEST_CNF_BASE_LOW ( cafu_csr0_conf_base_addr_low[27:0] ),
    .new_CXL_MB_BK_CMD_STATUS ( {16'd0, 16'd0, 7'd0, 16'd0} ),
    .new_CXL_MB_CMD  (hyc_new_cxl_mb_cmd),
    .new_CXL_MB_CTRL (hyc_new_cxl_mb_ctrl),
    .new_CXL_MB_STATUS (hyc_mb_status),
    .new_DEVICE_AFU_LATENCY_MODE( new_device_afu_latency_mode_reg ),
    .new_DEVICE_AFU_STATUS1 ( device_afu_status_1_reg   ),
    .new_DEVICE_AFU_STATUS2 ( device_afu_status_2_reg   ),
    .new_DEVICE_ERROR_INJECTION ( new_device_error_injection_reg ),
    .new_DEVICE_ERROR_LOG1  ( error_log_1_reg  ),
    .new_DEVICE_ERROR_LOG2  ( error_log_2_reg  ),
    .new_DEVICE_ERROR_LOG3  ( error_log_3_reg  ),
    .new_DEVICE_ERROR_LOG4  ( error_log_4_reg  ),
    .new_DEVICE_ERROR_LOG5  ( error_log_5_reg  ),
    .new_DEVICE_EVENT_COUNT ( 64'h0000_0000 ),
    .new_DOE_CTLREG (new_doe_ctlreg),
    .new_DOE_RDMAILREG ( 32'd0 ),
    .new_DOE_STSREG (new_doe_stsreg),
    .new_DOE_WRMAILREG ( 32'd0 ),
    .new_DVSEC_FBCTRL2_STATUS2 ( new_dvsec_fbctrl2_status2 ),
    .new_DVSEC_FBCTRL_STATUS ( 1'b0 ),

    `ifdef SINGLE_SLICE_ENV
       .new_CXL_MEM_DEV_STATUS ( {3'd0, 1'b1, 2'b01, 1'b0, 1'b0} ),
       .new_DEVMEM_DBECNT      ( {32'd0, 32'd0} ),
       .new_DEVMEM_POISONCNT   ( {32'd0, 32'd0} ),
       .new_DEVMEM_SBECNT      ( {32'd0, 32'd0} ),
       .new_HDM_DEC_CTRL       ( 1'b0 ),
       .new_MC_STATUS          ( {16'd0, 16'd0} ),
    `else   
       .new_CXL_MEM_DEV_STATUS (cxl_mem_dev_status ),
       .new_DEVMEM_DBECNT      ( new_devmem_dbecnt_Q ),
       .new_DEVMEM_POISONCNT   ( new_devmem_poisoncnt_Q ),
       .new_DEVMEM_SBECNT      ( new_devmem_sbecnt_Q ),
       .new_HDM_DEC_CTRL       ( hdm_dec_commit_Q ),
       .new_MC_STATUS          (new_ddr_mc_status_Q ),
    `endif  // ifdef SINGLE_SLICE_ENV

    .new_DEVICE_AXI2CPI_STATUS_1 ( 'd0 ),
    .new_DEVICE_AXI2CPI_STATUS_2 ( 'd0 ),


    // Misc Inputs
    .CXL_DVSEC_TEST_CAP2_cache_size_device ( 14'h0147  ),
    .CXL_DVSEC_TEST_CAP2_cache_size_unit ( 2'b01     ),
   
    `ifdef SINGLE_SLICE_ENV
       .POR_DVSEC_FBCAP_HDR2_cache_capable ( 1'b1 ),
       .POR_DVSEC_FBCAP_HDR2_cache_wb_and_inv_capable ( 1'b1 ),
       .POR_DVSEC_FBCAP_HDR2_cxl_reset_capable ( 1'b1 ),
       .POR_DVSEC_FBCAP_HDR2_cxl_reset_mem_clr_capable ( 1'b0 ),
       .POR_DVSEC_FBCAP_HDR2_cxl_reset_timeout ( 3'b010 ),
       .POR_DVSEC_FBCAP_HDR2_hdm_count ( 2'b01 ),
       .POR_DVSEC_FBCAP_HDR2_mem_capable ( POR_DVSEC_FBCAP_HDR2.mem_capable ),
       .POR_DVSEC_FBCAP_HDR2_mem_hwinit_mode ( 1'b1 ),
       .POR_DVSEC_FBCAP_HDR2_pm_init_comp_capable ( 1'b1 ),
       .POR_DVSEC_FBLOCK_cache_size ( 8'b00000010 ),
       .POR_DVSEC_FBLOCK_cache_size_unit ( 4'b0001 ),
       .POR_DVSEC_FBRANGE1SZHIGH_memory_size ( 32'h00000001 ),
       .POR_DVSEC_FBRANGE1SZLOW_desired_interleave ( 3'b000 ),
       .POR_DVSEC_FBRANGE1SZLOW_media_type ( 3'b010 ),
       .POR_DVSEC_FBRANGE1SZLOW_mem_active ( 1'b1 ),
       .POR_DVSEC_FBRANGE1SZLOW_mem_valid ( 1'b1 ),
       .POR_DVSEC_FBRANGE1SZLOW_memory_active_timeout ( 3'b001 ),
       .POR_DVSEC_FBRANGE1SZLOW_memory_class ( 3'b010 ),
       .POR_DVSEC_FBRANGE1SZLOW_memory_size_low ( 4'h0 ),
       .POR_DVSEC_HDR1_dvsec_revision ( 4'h1 ),
       .POR_DVSEC_HDR1_dvsec_vendor_id ( 16'h1E98 ),
    `else
       .POR_DVSEC_FBCAP_HDR2_cache_capable                      ( POR_DVSEC_FBCAP_HDR2.cache_capable ),
       .POR_DVSEC_FBCAP_HDR2_cache_wb_and_inv_capable           ( POR_DVSEC_FBCAP_HDR2.cache_wb_and_inv_capable ),
       .POR_DVSEC_FBCAP_HDR2_cxl_reset_capable                  ( POR_DVSEC_FBCAP_HDR2.cxl_reset_capable ),
       .POR_DVSEC_FBCAP_HDR2_cxl_reset_mem_clr_capable          ( POR_DVSEC_FBCAP_HDR2.cxl_reset_mem_clr_capable ),
       .POR_DVSEC_FBCAP_HDR2_cxl_reset_timeout                  ( POR_DVSEC_FBCAP_HDR2.cxl_reset_timeout ),
       .POR_DVSEC_FBCAP_HDR2_mem_capable                        ( POR_DVSEC_FBCAP_HDR2.mem_capable        ),
       .POR_DVSEC_FBCAP_HDR2_mem_hwinit_mode                    ( POR_DVSEC_FBCAP_HDR2.mem_hwInit_mode    ),
       .POR_DVSEC_FBCAP_HDR2_hdm_count                          ( POR_DVSEC_FBCAP_HDR2.hdm_count          ),     // 2bits 
       .POR_DVSEC_FBCAP_HDR2_pm_init_comp_capable               ( POR_DVSEC_FBCAP_HDR2.pm_init_comp_capable ),
       .POR_DVSEC_FBLOCK_cache_size                             ( POR_DVSEC_FBLOCK.cache_size ),
       .POR_DVSEC_FBLOCK_cache_size_unit                        ( POR_DVSEC_FBLOCK.cache_size_unit ),
       .POR_DVSEC_FBRANGE1SZHIGH_memory_size                    ( POR_DVSEC_FBRANGE1SZHIGH.memory_size ),
       .POR_DVSEC_FBRANGE1SZLOW_desired_interleave              ( POR_DVSEC_FBRANGE1SZLOW.desired_interleave ),
       .POR_DVSEC_FBRANGE1SZLOW_media_type                      ( POR_DVSEC_FBRANGE1SZLOW.media_type ),
       .POR_DVSEC_FBRANGE1SZLOW_mem_active                      ( POR_DVSEC_FBRANGE1SZLOW.mem_active ),
       .POR_DVSEC_FBRANGE1SZLOW_memory_active_timeout           ( POR_DVSEC_FBRANGE1SZLOW.memory_active_timeout ),
       .POR_DVSEC_FBRANGE1SZLOW_memory_class                    ( POR_DVSEC_FBRANGE1SZLOW.memory_class ),
       .POR_DVSEC_FBRANGE1SZLOW_mem_valid                       ( POR_DVSEC_FBRANGE1SZLOW.mem_valid       ),
       .POR_DVSEC_FBRANGE1SZLOW_memory_size_low                 ( POR_DVSEC_FBRANGE1SZLOW.memory_size_low ),
       .POR_DVSEC_HDR1_dvsec_revision                           ( POR_DVSEC_HDR1.dvsec_revision ),
       .POR_DVSEC_HDR1_dvsec_vendor_id                          ( POR_DVSEC_HDR1.dvsec_vendor_id ),
    `endif  // ifdef SINGLE_SLICE_ENV

//   `ifdef CPI_MODE
     .support_cache_dirty_evict(    1'b1 ),
     .support_cache_read_current(   1'b1 ),
     .support_cache_read_down(      1'b1 ),
     .support_cache_read_shared(    1'b1 ),
     .support_cache_write_itom(     1'b1 ),
     .support_cache_write_wow_inv(  1'b1 ),
     .support_cache_write_wow_invf( 1'b1 ),
//   `endif
    // Register Outputs
    .CDAT_0 (cdat_0),
    .CDAT_1 (cdat_1),
    .CDAT_2 (cdat_2),
    .CDAT_3 (cdat_3),
    .CONFIG_ALGO_SETTING ( algorithm_config_reg   ),
    .CONFIG_CXL_ERRORS (),
    .CONFIG_DEVICE_INJECTION (),
    .CONFIG_TEST_ADDR_INCRE     ( increment_reg          ),
    .CONFIG_TEST_BYTEMASK       ( byte_mask_reg          ),
    .CONFIG_TEST_PATTERN        ( pattern_reg            ),
    .CONFIG_TEST_PATTERN_PARAM  ( pattern_config_reg     ),
    .CONFIG_TEST_START_ADDR     ( start_address_reg      ),
    .CONFIG_TEST_WR_BACK_ADDR   ( write_back_address_reg ),
    .CXL_DEV_CAP_ARRAY_0 (),
    .CXL_DEV_CAP_ARRAY_1 (),
    .CXL_DEV_CAP_EVENT_STATUS (),
    .CXL_DEV_CAP_HDR1_0 (),
    .CXL_DEV_CAP_HDR1_1 (),
    .CXL_DEV_CAP_HDR1_2 (),
    .CXL_DEV_CAP_HDR2_0 (),
    .CXL_DEV_CAP_HDR2_1 (),
    .CXL_DEV_CAP_HDR2_2 (),
    .CXL_DEV_CAP_HDR3_0 (),
    .CXL_DEV_CAP_HDR3_1 (),
    .CXL_DEV_CAP_HDR3_2 (),
    .CXL_DVSEC_HEADER_1 (),
    .CXL_DVSEC_HEADER_2 (),
    .CXL_DVSEC_TEST_CAP1 (),
    .CXL_DVSEC_TEST_CAP2 (),
    .CXL_DVSEC_TEST_CNF_BASE_HIGH (),
    .CXL_DVSEC_TEST_CNF_BASE_LOW  (),
    .CXL_DVSEC_TEST_LOCK (),
    .CXL_MB_BK_CMD_STATUS (),
    .CXL_MB_CAP (),
    .CXL_MB_CMD (cxl_mb_cmd),
    .CXL_MB_CTRL (cxl_mb_ctrl),
    .CXL_MB_PAY_END (),
    .CXL_MB_PAY_START (),
    .CXL_MB_STATUS (),
    .CXL_MEM_DEV_STATUS (),
    .DEVICE_AFU_LATENCY_MODE( device_afu_latency_mode_reg ),
    .DEVICE_AFU_STATUS1 (),
    .DEVICE_AFU_STATUS2 (),
    .DEVICE_AXI2CPI_STATUS_1 ( current_DEVICE_AXI2CPI_STATUS_1 ),
    .DEVICE_AXI2CPI_STATUS_2 ( current_DEVICE_AXI2CPI_STATUS_2 ),
    .DEVICE_ERROR_INJECTION ( device_error_injection_reg ),
    .DEVICE_ERROR_LOG1 (),
    .DEVICE_ERROR_LOG2 (),
    .DEVICE_ERROR_LOG3 ( device_error_log3_reg ),
    .DEVICE_ERROR_LOG4 (),
    .DEVICE_ERROR_LOG5 (),
    .DEVICE_EVENT_COUNT (),
    .DEVICE_EVENT_CTRL  (),
    .DEVICE_FORCE_DISABLE ( device_force_disable_reg ),
    .DEVMEM_DBECNT (),
    .DEVMEM_POISONCNT (),
    .DEVMEM_SBECNT (),
    .DOE_CAPREG (),
    .DOE_CTLREG (doe_ctlreg),
    .DOE_RDMAILREG (),
    .DOE_STSREG (),
    .DOE_WRMAILREG (),
    .DSEMTS_0 (dsemts_0),
    .DSEMTS_1 (dsemts_1),
    .DSEMTS_2 (dsemts_2),
    .DSEMTS_3 (dsemts_3),
    .DSEMTS_4 (dsemts_4),
    .DSEMTS_5 (dsemts_5),
    .DSIS_0 (dsis_0),
    .DSIS_1 (dsis_1),
    .DSLBIS_0 (dslbis_0),
    .DSLBIS_1 (dslbis_1),
    .DSLBIS_2 (dslbis_2),
    .DSLBIS_3 (dslbis_3),
    .DSLBIS_4 (dslbis_4),
    .DSLBIS_5 (dslbis_5),
    .DSMAS_0 (dsmas_0),
    .DSMAS_1 (dsmas_1),
    .DSMAS_2 (dsmas_2),
    .DSMAS_3 (dsmas_3),
    .DSMAS_4 (dsmas_4),
    .DSMAS_5 (dsmas_5),
    .DVSEC_DEV (),
    .DVSEC_DOE (),
    .DVSEC_FBCAP_HDR2 (dvsec_fbcap_hdr2),
    .DVSEC_FBCTRL2_STATUS2 (dvsec_fbctrl2_status2),
    .DVSEC_FBCTRL_STATUS (dvsec_fbctrl_status),
    .DVSEC_FBLOCK (),
    .DVSEC_FBRANGE1HIGH (dvsec_fbrange1high),
    .DVSEC_FBRANGE1LOW (dvsec_fbrange1low),
    .DVSEC_FBRANGE1SZHIGH (fbrange1_sz_high),
    .DVSEC_FBRANGE1SZLOW (fbrange1_sz_low),
    .DVSEC_FBRANGE2HIGH (),
    .DVSEC_FBRANGE2LOW (),
    .DVSEC_FBRANGE2SZHIGH (),
    .DVSEC_FBRANGE2SZLOW (),
    .DVSEC_HDR1 (),
    .DVSEC_TEST_CAP (),
    .HDM_DEC_BASEHIGH (hdm_dec_basehigh),
    .HDM_DEC_BASELOW (hdm_dec_baselow),
    .HDM_DEC_CAP (),
    .HDM_DEC_CTRL (hdm_dec_ctrl),
    .HDM_DEC_DPAHIGH (),
    .HDM_DEC_DPALOW (),
    .HDM_DEC_GBL_CTRL (hdm_dec_gbl_ctrl),
    .HDM_DEC_SIZEHIGH (hdm_dec_sizehigh),
    .HDM_DEC_SIZELOW (hdm_dec_sizelow),
    .MBOX_EVENTINJ (bbs_mbox_eventinj),
    .MC_STATUS ()
  );

`else   // use original ccv afu cfg

  ccv_afu_cfg     inst_ccv_afu_cfg
  ( //lintra s-2096
    .gated_clk ( gated_clk ),
    .rtl_clk   ( rtl_clk   ),
    .rst_n     ( rst_n     ),
    .req       ( treg_req  ),
    .ack       ( treg_ack  ),

    .load_CXL_DVSEC_TEST_CNF_BASE_HIGH ( ccv_afu_conf_base_addr_high_valid ),
    .new_CXL_DVSEC_TEST_CNF_BASE_HIGH  ( ccv_afu_conf_base_addr_high       ),
    .load_CXL_DVSEC_TEST_CNF_BASE_LOW  ( ccv_afu_conf_base_addr_low_valid  ),
    .new_CXL_DVSEC_TEST_CNF_BASE_LOW   ( ccv_afu_conf_base_addr_low[27:0]  ),

  // error_status field in DEVICE_ERROR_LOG3 is RW/0C/V
  // seems to serve as an enable for selecting hardware over software
    .load_DEVICE_ERROR_LOG3 ( mwae_to_cfg_enable_new_error_log3_error_status ),

  // event count field in DEVICE_EVENT_COUNT is RW/V
  // seems to serve as an enable for selecting hardware over software
    .load_DEVICE_EVENT_COUNT ( 1'b0 ),
     .new_DEVICE_EVENT_COUNT ( 64'h0000_0000 ),

  // DEVICE ERROR LOG1, LOG2, LOG3, LOG4, LOG5 are RO/V
    .new_DEVICE_ERROR_LOG1  ( error_log_1_reg  ),
    .new_DEVICE_ERROR_LOG2  ( error_log_2_reg  ),
    .new_DEVICE_ERROR_LOG3  ( error_log_3_reg  ),
    .new_DEVICE_ERROR_LOG4  ( error_log_4_reg  ),
    .new_DEVICE_ERROR_LOG5  ( error_log_5_reg  ),

    .new_DEVICE_ERROR_INJECTION ( new_device_error_injection_reg ),
    .DEVICE_ERROR_INJECTION     ( device_error_injection_reg     ),

    .new_CONFIG_CXL_ERRORS  ( config_and_cxl_errors_reg ),
    .new_DEVICE_AFU_STATUS1 ( device_afu_status_1_reg   ),
    .new_DEVICE_AFU_STATUS2 ( device_afu_status_2_reg   ),

    .CXL_DVSEC_TEST_CAP2_cache_size_device ( 14'h0147  ),
    .CXL_DVSEC_TEST_CAP2_cache_size_unit   ( 2'b01     ),

    .new_CONFIG_DEVICE_INJECTION ( 2'd0 ),
    .CONFIG_DEVICE_INJECTION     ( ),

    .CONFIG_ALGO_SETTING        ( algorithm_config_reg   ),
    .CONFIG_TEST_ADDR_INCRE     ( increment_reg          ),
    .CONFIG_TEST_BYTEMASK       ( byte_mask_reg          ),
    .CONFIG_TEST_PATTERN        ( pattern_reg            ),
    .CONFIG_TEST_PATTERN_PARAM  ( pattern_config_reg     ),
    .CONFIG_TEST_START_ADDR     ( start_address_reg      ),
    .CONFIG_TEST_WR_BACK_ADDR   ( write_back_address_reg ),

    .DEVICE_ERROR_LOG1 (),
    .DEVICE_ERROR_LOG2 (),
    .DEVICE_ERROR_LOG3 ( device_error_log3_reg ),
    .DEVICE_ERROR_LOG4 (),
    .DEVICE_ERROR_LOG5 (),

    .CONFIG_CXL_ERRORS    (),
    .DEVICE_AFU_STATUS1   (),
    .DEVICE_AFU_STATUS2   (),
    .DEVICE_FORCE_DISABLE ( device_force_disable_reg ),

    .DEVICE_EVENT_COUNT (),
    .DEVICE_EVENT_CTRL  (),
    .CXL_DVSEC_HEADER_1 (),
    .CXL_DVSEC_HEADER_2 (),
        .DVSEC_TEST_CAP  (),
    .CXL_DVSEC_TEST_CAP1 (),
    .CXL_DVSEC_TEST_CAP2 (),
    .CXL_DVSEC_TEST_CNF_BASE_HIGH (),
    .CXL_DVSEC_TEST_CNF_BASE_LOW  (),
    .CXL_DVSEC_TEST_LOCK ()
  );

`endif

endmodule

