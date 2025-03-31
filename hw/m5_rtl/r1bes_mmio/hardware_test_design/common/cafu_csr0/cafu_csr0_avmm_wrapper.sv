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
/*                COHERENCE-COMPLIANCE VALIDATION AFU

  Description   : FPGA CXL Compliance Engine Initiator AFU
                  Speaks to the AXI-to-CCIP+ translator.
                  This afu is the initiatior
                  The axi-to-ccip+ is the responder

  initial -> 07/12/2022 -> Antony Mathew
*/
//`include "cxl_ip_defines.svh.iv"
//import rtlgen_pkg_v12::*;
import ccv_afu_pkg::*;
import afu_axi_if_pkg::*;
import ext_csr_if_pkg::*;
import tmp_cafu_csr0_cfg_pkg::*;
import cxlip_top_pkg::*;
import mc_ecc_pkg::*;

`ifdef ORIGINAL_CCV_AFU_MODE
   import ccv_afu_cfg_pkg::*;
`else
   import cafu_csr0_cfg_pkg::*;
`endif



module cafu_csr0_avmm_wrapper
    import rtlgen_pkg_v12::*;
#(
   parameter T1IP_ENABLE              = 0 
)

(
      // Clocks
  input logic  csr_avmm_clk, // AVMM clock : 125MHz
  input logic  rtl_clk, //450 SIP clk
  input logic  axi4_mm_clk, 

    // Resets
  input logic  csr_avmm_rstn,
  input logic  rst_n,
  input logic  axi4_mm_rst_n,
  input logic  cxl_or_conv_rst_n,
  input  logic [35:0]       hdm_size_256mb , 
  input  tmp_cafu_csr0_cfg_pkg::tmp_MC_STATUS_t                   ddr_mc_status,
  input  logic                            mc_mem_active,                     
  input  tmp_cafu_csr0_cfg_pkg::tmp_new_CXL_MEM_DEV_STATUS_t      mem_dev_status,
  input  mc_ecc_pkg::mc_err_cnt_t  [cxlip_top_pkg::MC_CHANNEL-1:0]                mc_err_cnt ,
 
  `ifndef ORIGINAL_CCV_AFU_MODE
      output logic cafu_user_enabled_cxl_io,
  `endif

//  `ifdef CPI_MODE
  /*
    AXI-MM interface - write address channel
  */
  output logic [11:0]               awid,
  output logic [63:0]               awaddr, 
  output logic [9:0]                awlen,
  output logic [2:0]                awsize,
  output logic [1:0]                awburst,
  output logic [2:0]                awprot,
  output logic [3:0]                awqos,
  output logic [5:0]                awuser,
  output logic                      awvalid,
  output logic [3:0]                awcache,
  output logic [1:0]                awlock,
  output logic [3:0]                awregion,
   input                            awready,
  
  /*
    AXI-MM interface - write data channel
  */
  output logic [511:0]              wdata,
  output logic [(512/8)-1:0]        wstrb,
  output logic                      wlast,
  output logic [0:0]                wuser,
  output logic                      wvalid,
  output logic [15:0]               wid,
   input                            wready,
  
  /*
    AXI-MM interface - write response channel
  */ 
   input [11:0]                     bid,
   input [1:0]                      bresp,
   input [3:0]                      buser,
   input                            bvalid,
  output logic                      bready,
  
  /*
    AXI-MM interface - read address channel
  */
  output logic [11:0]               arid,
  output logic [63:0]               araddr,
  output logic [9:0]                arlen,
  output logic [2:0]                arsize,
  output logic [1:0]                arburst,
  output logic [2:0]                arprot,
  output logic [3:0]                arqos,
  output logic [5:0]                aruser,
  output logic                      arvalid,
  output logic [3:0]                arcache,
  output logic [1:0]                arlock,
  output logic [3:0]                arregion,
   input                            arready,

  /*
    AXI-MM interface - read response channel
  */ 
   input [11:0]                     rid,
   input [511:0]                    rdata,
   input [1:0]                      rresp,
   input                            rlast,
   input                            ruser,
   input                            rvalid,
  output logic                      rready,
   
   output  logic [95:0]         cafu2ip_csr0_cfg_if,
   input   logic [5:0]          ip2cafu_csr0_cfg_if,
//  `endif
  
//`ifndef ORIGINAL_CCV_AFU_MODE
//    /* bios based memory base address
//    */
//     input [31:0] cafu_csr0_conf_base_addr_high,
//     input        cafu_csr0_conf_base_addr_high_valid,
//     input [31:0] cafu_csr0_conf_base_addr_low,
//     input        cafu_csr0_conf_base_addr_low_valid,
//    /*   register access ports
//    */
//  //   input cafu_csr0_cfg_cr_req_t  treg_req,
//  //  output cafu_csr0_cfg_cr_ack_t  treg_ack,
//`else
//    /* bios based memory base address
//    */
     input [31:0] ccv_afu_conf_base_addr_high,
     input        ccv_afu_conf_base_addr_high_valid,
     input [27:0] ccv_afu_conf_base_addr_low,
     input        ccv_afu_conf_base_addr_low_valid,

    //CXL RESET handshake signal to ED 
    output logic                                usr2ip_cxlreset_initiate, 
    input  logic                                ip2usr_cxlreset_error,
    input  logic                                ip2usr_cxlreset_complete,  

//    /*   register access ports
//    */
 //    input ccv_afu_cfg_cr_req_t   treg_req,
 //   output ccv_afu_cfg_cr_ack_t   treg_ack,
//`endif

  
 // // SC <--> CXL
 // // copied over from sc_afu_wrapper
 // output logic                  afu_cxl_ext5,
 // output logic                  afu_cxl_ext6,

 // //input logic [APP_CORES-1:0]   cxl_afu_ext5,
 // //input logic [APP_CORES-1:0]   cxl_afu_ext6,
 // input logic [0:0]   cxl_afu_ext5,
 // input logic [0:0]   cxl_afu_ext6,

 // // CXL-IP <--> AFU quiesce interface
 // // copied over from sc_afu_wrapper
 // input logic                   resetprep_en,
 // input logic                   bfe_afu_quiesce_req,
 // output logic                  afu_bfe_quiesce_ack,


  // SC <--> AVMM-INTERCONNECT

//// bios based memory base address
//input  logic [31:0] ccv_afu_conf_base_addr_high ,
//input  logic        ccv_afu_conf_base_addr_high_valid,
//input  logic [27:0] ccv_afu_conf_base_addr_low ,
//input  logic        ccv_afu_conf_base_addr_low_valid,

  
  //CSR Access AVMM Bus
 
  output logic        csr_avmm_waitrequest,  
  output logic [63:0] csr_avmm_readdata,
  output logic        csr_avmm_readdatavalid,
  input  logic [63:0] csr_avmm_writedata,
  input  logic        csr_avmm_poison,
  input  logic [21:0] csr_avmm_address,
  input  logic        csr_avmm_write,
  input  logic        csr_avmm_read, 
  input  logic [7:0]  csr_avmm_byteenable
   
);

cfg_req_64bit_t   treg_req;
cfg_ack_64bit_t   treg_ack;

cfg_req_64bit_t                    treg_req_fifo;   //from FIFO
cfg_ack_64bit_t                    treg_ack_fifo;   //from FIFO
 
logic doe_poisoned_wr_err; 

   ccv_afu_csr_avmm_slave ccv_afu_csr_avmm_slave_inst(
       .clk                 (csr_avmm_clk),
       .reset_n             (csr_avmm_rstn),
       .rtl_clk             (rtl_clk),
       .rtl_rstn            (rst_n) , 
       .writedata           (csr_avmm_writedata),
       .read                (csr_avmm_read),
       .write               (csr_avmm_write),
       .byteenable          (csr_avmm_byteenable),
       .readdata            (csr_avmm_readdata),
       .readdatavalid       (csr_avmm_readdatavalid),
       .address             (csr_avmm_address),
       .poison              (csr_avmm_poison),
       .waitrequest         (csr_avmm_waitrequest),
       .doe_poisoned_wr_err (doe_poisoned_wr_err),
       .treg_req            (treg_req                ),
       .treg_ack            (treg_ack_fifo           )
   );

//AVMM Interconnect (125Mhz) <-> ccv_afu_csr_avmm_slave (125MHz) <-> Need CDC(125MHz to 450MHz) <-> ccv_afu_wrapper (450MHz)

//Need to implement CDC Bridge 125 to 450MHz


ccv_afu_cdc_fifo ccv_afu_cdc_fifo_inst (

    //Inputs
    .rst(~rst_n),
    .clk(rtl_clk),
    .sbr_clk_i(csr_avmm_clk),
    .sbr_rstb_i(csr_avmm_rstn),
    .treg_np('0),
    .treg_req,                         // Request from avmm interconnect
    .treg_ack (treg_ack),              // Ack from cfg

    //Outputs
    .treg_req_fifo,                    // Request from FIFO
    .treg_ack_fifo                     // Ack from FIFO
);


cafu_csr0_wrapper  
#(
  .T1IP_ENABLE            (T1IP_ENABLE        )
)
inst_cafu_csr0_wrapper 
(
  /*
    assuming clock for axi-mm (all channels) and AFU are the same to avoid clock
    domain crossing.
  */
      // Clocks
  .gated_clk   ( rtl_clk ),
  .rtl_clk     ( rtl_clk ),
 // .axi4_mm_clk ( axi4_mm_clk ),

    // Resets
  .rst_n                  ( rst_n ),
  .cxl_or_conv_rst_n      (cxl_or_conv_rst_n),
  .hdm_size_256mb         (hdm_size_256mb ),
  .ddr_mc_status          (ddr_mc_status),
  .mc_mem_active          (mc_mem_active),
  .mem_dev_status         (mem_dev_status),
  .mc_err_cnt             (mc_err_cnt),
  .doe_poisoned_wr_err    (doe_poisoned_wr_err),
//  .axi4_mm_rst_n ( axi4_mm_rst_n ),

  `ifndef ORIGINAL_CCV_AFU_MODE
    .cafu_user_enabled_cxl_io                            ( cafu_user_enabled_cxl_io       ),
  `endif

// `ifdef CPI_MODE

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
 // .wid          ( wid ),
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
  
  .cafu2ip_csr0_cfg_if  (cafu2ip_csr0_cfg_if),
  .ip2cafu_csr0_cfg_if  (ip2cafu_csr0_cfg_if),
  .usr2ip_cxlreset_initiate(usr2ip_cxlreset_initiate), 
  .ip2usr_cxlreset_error   (ip2usr_cxlreset_error   ),
  .ip2usr_cxlreset_complete(ip2usr_cxlreset_complete), 

  `ifndef ORIGINAL_CCV_AFU_MODE
 .cafu_csr0_conf_base_addr_high       ( ccv_afu_conf_base_addr_high       ),
 .cafu_csr0_conf_base_addr_high_valid ( ccv_afu_conf_base_addr_high_valid ),
 .cafu_csr0_conf_base_addr_low        ( ccv_afu_conf_base_addr_low        ),
 .cafu_csr0_conf_base_addr_low_valid  ( ccv_afu_conf_base_addr_low_valid  ),

  `else
 .ccv_afu_conf_base_addr_high       ( ccv_afu_conf_base_addr_high       ),
 .ccv_afu_conf_base_addr_high_valid ( ccv_afu_conf_base_addr_high_valid ),
 .ccv_afu_conf_base_addr_low        ( ccv_afu_conf_base_addr_low        ),
 .ccv_afu_conf_base_addr_low_valid  ( ccv_afu_conf_base_addr_low_valid  ),
  `endif
  
  /*
     to config registers
  */
  .treg_req ( treg_req_fifo ),
  .treg_ack ( treg_ack )

  //// SC <--> CXL
  //// copied over from sc_afu_wrapper
  //.afu_cxl_ext5 ( afu_cxl_ext5 ),
  //.afu_cxl_ext6 ( afu_cxl_ext6 ),
  //.cxl_afu_ext5 ( cxl_afu_ext5 ),
  //.cxl_afu_ext6 ( cxl_afu_ext6 ),

  //// CXL-IP <--> AFU quiesce interface
  //// copied over from sc_afu_wrapper
  //.resetprep_en        ( resetprep_en ),
  //.bfe_afu_quiesce_req ( bfe_afu_quiesce_req ),
  //.afu_bfe_quiesce_ack ( afu_bfe_quiesce_ack )
);



endmodule



