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
`include "ccv_afu_globals.vh.iv"

//module ccv_afu_iosf_wrapper
module cafu_csr0_iosf_wrapper
  import rtlgen_pkg_v12::*;
  import ccv_afu_pkg::*;
  import afu_axi_if_pkg::*;
  import mc_ecc_pkg::*;
  import cxlip_top_pkg::*;
  //import tmp_cafu_csr0_cfg_pkg::*;
  import ext_csr_if_pkg::*;


(
  /*
    assuming clock for axi-mm (all channels) and AFU are the same to avoid clock
    domain crossing.
  */
      // Clocks
  input logic  gated_clk,
  input logic  rtl_clk,
  input logic  axi4_mm_clk,

    // Resets
  input logic  pwr_rst_n,
  input logic  rst_n,
  input logic  axi4_mm_rst_n,

  `ifndef ORIGINAL_CCV_AFU_MODE
      output logic cafu_user_enabled_cxl_io,
  `endif
  
  input logic mc_mem_active,

  input logic [mc_ecc_pkg::MC_STATUS_T_BW-1:0]      ddr_mc_status,
  input logic [mc_ecc_pkg::MEM_DEV_STATUS_T_BW-1:0] mem_dev_status,
 
  input logic [cxlip_top_pkg::MC_CHANNEL-1:0][mc_ecc_pkg::MC_ERR_CNT_WIDTH-1:0] mc_err_cnt,
  
  //  `ifdef CPI_MODE
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
  `else
    /* bios based memory base address
    */
     input [31:0] ccv_afu_conf_base_addr_high,
     input        ccv_afu_conf_base_addr_high_valid,
     input [31:0] ccv_afu_conf_base_addr_low,
     input        ccv_afu_conf_base_addr_low_valid,
  `endif

  // External CSR <--> BBS
  output logic [ext_csr_if_pkg::CAFU2IP_CSR0_CFG_IF_WIDTH-1:0]    cafu2ip_csr0_cfg_if,

  input logic [ext_csr_if_pkg::TMP_NEW_DVSEC_FBCTRL2_STATUS2_T_BW-1:0] ip2cafu_csr0_cfg_if,

  // BBS <--> AFU quiesce interface
  // copied over from sc_afu_wrapper
  input logic                   resetprep_en,

  // ISM signals
  // copied over from sc_afu_wrapper
  input logic [2:0]             side_ism_fabric,
  output logic [2:0]            side_ism_agent,

  // SC <--> IOSF-SB
  // copied over from sc_afu_wrapper   
  output logic                            mnpput,   // Master Non-Posted Put
  output logic                            mpcput,   // Master Posted / Completion Put
  input  logic                            mnpcup,   // Master Non-Posted Credit Update
  input  logic                            mpccup,   // Master Posted / Completion Credit Update
  output logic                            meom,     // Master End of Message
  output logic [31:0]                     mpayload, // Master Payload
  output logic                            mparity,  // Master Parity
  input  logic                            tnpput,   // Target Non-Posted Put
  input  logic                            tpcput,   // Target Posted / Completion Put
  output logic                            tnpcup,   // Target Non-Posted Credit Update
  output logic                            tpccup,   // Target Posted / Completion Credit Update
  input  logic                            teom,     // Target End of Message
  input  logic [31:0]                     tpayload, // Target Payload
  input  logic                            tparity   // Target Parity
);

// =================================================================================================
cfg_req_64bit_t   treg_req;
cfg_ack_64bit_t   treg_ack;

// =================================================================================================
/*    07/12/2022 - copied over from sc_afu_wrapper.sv
*/
ial_tc_iosf_sb_ep_64b 
#(
  .ASYNC_ENDPOINT (1),   //Make the Endpoint Async
  .PAYLOAD_WIDTH  (32)   //Payload Width
) 
u_ial_tc_iosf_sb_ep
(
  //clock and reset
  .router_clk                      ( gated_clk ),    // (pClk),
  .router_rst_b                    ( rst_n ),        //(~pSoftReset),
  .core_clk                        ( rtl_clk ),      //(pClk),

  //ISM signals
  .side_ism_fabric                 (side_ism_fabric),
  .side_ism_agent                  (side_ism_agent),

  // Egress port interface to the IOSF Sideband Channel
  .mpccup                          (mpccup),        //
  .mnpcup                          (mnpcup),        //
  .mpcput                          (mpcput),        //
  .mnpput                          (mnpput),        //
  .meom                            (meom),          //
  .mpayload                        (mpayload),      //
  .mparity                         (mparity),       //

  // Ingress port interface to the IOSF Sideband Channel
  .tpccup                          (tpccup),        //
  .tnpcup                          (tnpcup),        //
  .tpcput                          (tpcput),        //
  .tnpput                          (tnpput),        //
  .teom                            (teom),          //
  .tpayload                        (tpayload),      //
  .tparity                         (tparity),       //

  //Posted Target Message Interface
  .tmsg_pcfree                     (1'b1),          //Unused Interface
  .tmsg_pcput                      (),
  .tmsg_pcmsgip                    (),
  .tmsg_pccmpl                     (),
  .tmsg_pceom                      (),
  .tmsg_pcpayload                  (),
  .tmsg_pcvalid                    (),

  //Non-Posted Target Message Interface
  .tmsg_npclaim                    (1'b0),          //Unused Interface
  .tmsg_npfree                     (1'b1),
  .tmsg_npput                      (),
  .tmsg_npmsgip                    (),
  .tmsg_npeom                      (),
  .tmsg_nppayload                  (),
  .tmsg_npvalid                    (),

  //Posted Master Message Interface
  .mmsg_pcirdy                     ('0),            //Unused Interface
  .mmsg_pceom                      ('0),
  .mmsg_pcpayload                  ('0),
  .mmsg_pcparity                   ('0),
  .mmsg_pctrdy                     (),
  .mmsg_pcmsgip                    (),
  .mmsg_pcsel                      (),

  //Non-Posted Master Message Interface
  .mmsg_npirdy                     ('0),            //Unused Interface
  .mmsg_npeom                      ('0),
  .mmsg_nppayload                  ('0),
  .mmsg_npparity                   ('0),
  .mmsg_nptrdy                     (),
  .mmsg_npmsgip                    (),
  .mmsg_npsel                      (),

  //Target Register Access Interface
  .treg_req                        (treg_req),
  .treg_ack                        (treg_ack),

  //Master Register Access Interface
  .mreg_trdy                       (),              //Unused Interface
  .mreg_pmsgip                     (),
  .mreg_nmsgip                     (),

  .mreg_irdy                       (1'b0),
  .mreg_npwrite                    (1'b0),
  .mreg_dest                       (8'b00000000),
  .mreg_source                     (8'b00000000),
  .mreg_opcode                     (8'b00000000),
  .mreg_addrlen                    (1'b0),
  .mreg_bar                        (3'b000),
  .mreg_tag                        (3'b000),
  .mreg_be                         (4'b0000),
  .mreg_fid                        (8'b00000000),
  .mreg_addr                       (32'h0000_0000),
  .mreg_wdata                      (32'h0000_0000),
  .mreg_sairs_valid                (1'b0),
  .mreg_sai                        (8'b00000000),
  .mreg_rs                         (4'b0000),
  .mreg_hier_destid                (8'b00000000),
  .mreg_hier_srcid                 (8'b00000000)
);

// =================================================================================================
//cafu_csr0_wrapper    inst_ccv_afu_wrapper
cafu_csr0_wrapper   inst_cafu_csr0_wrapper
(
  /*
    assuming clock for axi-mm (all channels) and AFU are the same to avoid clock
    domain crossing.
  */
      // Clocks
  .gated_clk   ( gated_clk ),
  .rtl_clk     ( rtl_clk ),

    // Resets
  .rst_n         ( rst_n ),
  .cxl_or_conv_rst_n     ( rst_n ),

  `ifndef ORIGINAL_CCV_AFU_MODE
     .cafu_user_enabled_cxl_io( cafu_user_enabeld_cxl_io ),
  `endif
  
  .mc_mem_active  ( mc_mem_active ),
  .ddr_mc_status  ( ddr_mc_status ),
  .mem_dev_status ( mem_dev_status ),
  .mc_err_cnt     ( mc_err_cnt ),
  
  //`ifdef CPI_MODE
    /*
      AXI-MM interface - write address channel
    */
    .awid         ( awid ),
    .awaddr       ( awaddr ),
    .awlen        ( awlen ),
    .awsize       ( awsize ),
    .awburst      ( awburst ),
    .awprot       ( awprot ),
    .awqos        ( awqos ),
    .awuser       ( awuser ),
    .awvalid      ( awvalid ),
    .awcache      ( awcache ),
    .awlock       ( awlock ),
    .awregion     ( awregion ),
    .awready      ( awready ),
    /*
      AXI-MM interface - write data channel
    */
    .wdata        ( wdata ),
    .wstrb        ( wstrb ),
    .wlast        ( wlast ),
    .wuser        ( wuser ),
    .wvalid       ( wvalid ),
    //  .wid          ( wid ),
    .wready       ( wready ),
    /*
      AXI-MM interface - write response channel
    */ 
    .bid          ( bid ),
    .bresp        ( bresp ),
    .buser        ( buser ),
    .bvalid       ( bvalid ),
    .bready       ( bready ),
    /*
      AXI-MM interface - read address channel
    */
    .arid         ( arid ),
    .araddr       ( araddr ),
    .arlen        ( arlen ),
    .arsize       ( arsize ),
    .arburst      ( arburst ),
    .arprot       ( arprot ),
    .arqos        ( arqos ),
    .aruser       ( aruser ),
    .arvalid      ( arvalid ),
    .arcache      ( arcache ),
    .arlock       ( arlock ),
    .arregion     ( arregion ),
    .arready      ( arready ),
    /*
      AXI-MM interface - read response channel
    */ 
    .rid          ( rid ),
    .rdata        ( rdata ),
    .rlast        ( rlast ),
    .rresp        ( rresp ),
    .ruser        ( ruser ),
    .rvalid       ( rvalid ),
    .rready       ( rready ),

  `ifndef ORIGINAL_CCV_AFU_MODE
    /* bios based memory base address
    */
    .cafu_csr0_conf_base_addr_high       ( cafu_csr0_conf_base_addr_high     ),
    .cafu_csr0_conf_base_addr_high_valid ( cafu_csr0_conf_base_addr_high_valid ),
    .cafu_csr0_conf_base_addr_low        ( cafu_csr0_conf_base_addr_low      ),
    .cafu_csr0_conf_base_addr_low_valid  ( cafu_csr0_conf_base_addr_low_valid  ),
  `else
    /* bios based memory base address
    */
    .ccv_afu_conf_base_addr_high       ( ccv_afu_conf_base_addr_high       ),
    .ccv_afu_conf_base_addr_high_valid ( ccv_afu_conf_base_addr_high_valid ),
    .ccv_afu_conf_base_addr_low        ( ccv_afu_conf_base_addr_low        ),
    .ccv_afu_conf_base_addr_low_valid  ( ccv_afu_conf_base_addr_low_valid  ),
  `endif

  /*
     to config registers
  */
  .treg_req ( treg_req ),
  .treg_ack ( treg_ack ),

  .cafu2ip_csr0_cfg_if( cafu2ip_csr0_cfg_if ),
 
  .ip2cafu_csr0_cfg_if ( ip2cafu_csr0_cfg_if ),

  // BBS <--> AFU quiesce interface
  // copied over from sc_afu_wrapper
  .resetprep_en        ( resetprep_en )
);


endmodule

