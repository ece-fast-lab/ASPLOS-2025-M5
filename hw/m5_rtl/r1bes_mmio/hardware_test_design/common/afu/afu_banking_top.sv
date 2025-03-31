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


// Copyright 2022 Intel Corporation.
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

`ifndef vivado 
`include "cxl_type2_defines.svh.iv"
`else
`include "cxl_type2_defines.svh"
`endif

//import afu_axi_if_pkg::*;
import mc_axi_if_pkg::*;
//import cxlip_top_pkg::*;

module afu_top
#(
  // common parameter
  parameter ADDR_SIZE = 33,
  parameter CNT_SIZE = 14,

  // CM-sketch parameter
  parameter W = 32768,
  parameter W_UNIT = 4096,
  parameter NUM_SKETCH = W / W_UNIT,
  parameter SKETCH_INDEX_SIZE = $clog2(NUM_SKETCH),
  parameter COLUMN_INDEX_SIZE = $clog2(W_UNIT),
  parameter NUM_HASH = 4, // number of hash function, MUST be exponential of 2
  parameter HASH_SIZE = $clog2(W),

  // sorted CAM parameter
  parameter NUM_ENTRY = 25,
  parameter INDEX_SIZE = 5 // $clog2(NUM_ENTRY)
)
(
  input  logic            afu_clk,
  input  logic            afu_rstn,
  
  // hot cache tracker interface
  input                   cache_query_en,
  output                  cache_query_ready,
  output                  cache_mig_addr_en,
  output [ADDR_SIZE-1:0]  cache_mig_addr,
  input                   cache_mig_addr_ready,

  input                   page_query_en,
  output                  page_query_ready,
  output                  page_mig_addr_en,
  output [ADDR_SIZE-1:0]  page_mig_addr,
  input                   page_mig_addr_ready,
  output                  mem_chan_rd_en,
  input  [ADDR_SIZE-1:0]  csr_addr_ub,
  input  [ADDR_SIZE-1:0]  csr_addr_lb,
  
  
  input   mc_axi_if_pkg::t_to_mc_axi4     cxlip2iafu_to_mc_axi4,
  output  mc_axi_if_pkg::t_to_mc_axi4     iafu2mc_to_mc_axi4,
  input   mc_axi_if_pkg::t_from_mc_axi4   mc2iafu_from_mc_axi4,
  output  mc_axi_if_pkg::t_from_mc_axi4   iafu2cxlip_from_mc_axi4

/*
  `ifdef OOORSP_MC_AXI2AVMM 
     // April 2023 - Supporting out of order responses with AXI4
      input mc_axi_if_pkg::t_to_mc_axi4    [cxlip_top_pkg::MC_CHANNEL-1:0] cxlip2iafu_to_mc_axi4,
      output mc_axi_if_pkg::t_to_mc_axi4   [cxlip_top_pkg::MC_CHANNEL-1:0] iafu2mc_to_mc_axi4 ,
      input mc_axi_if_pkg::t_from_mc_axi4  [cxlip_top_pkg::MC_CHANNEL-1:0] mc2iafu_from_mc_axi4,
      output mc_axi_if_pkg::t_from_mc_axi4 [cxlip_top_pkg::MC_CHANNEL-1:0] iafu2cxlip_from_mc_axi4
  `else
    input  logic [cxlip_top_pkg::MC_CHANNEL-1:0]             mc2iafu_ready_eclk,
    input  logic [cxlip_top_pkg::MC_CHANNEL-1:0]             mc2iafu_read_poison_eclk,
    input  logic [cxlip_top_pkg::MC_CHANNEL-1:0]             mc2iafu_readdatavalid_eclk,
    // Error Correction Code (ECC)
    // Note *ecc_err_* are valid when mc2iafu_readdatavalid_eclk is active
    input  logic [cxlip_top_pkg::ALTECC_INST_NUMBER-1:0]     mc2iafu_ecc_err_corrected_eclk  [cxlip_top_pkg::MC_CHANNEL-1:0],
    input  logic [cxlip_top_pkg::ALTECC_INST_NUMBER-1:0]     mc2iafu_ecc_err_detected_eclk   [cxlip_top_pkg::MC_CHANNEL-1:0],
    input  logic [cxlip_top_pkg::ALTECC_INST_NUMBER-1:0]     mc2iafu_ecc_err_fatal_eclk      [cxlip_top_pkg::MC_CHANNEL-1:0],
    input  logic [cxlip_top_pkg::ALTECC_INST_NUMBER-1:0]     mc2iafu_ecc_err_syn_e_eclk      [cxlip_top_pkg::MC_CHANNEL-1:0],
    input  logic [cxlip_top_pkg::MC_CHANNEL-1:0]             mc2iafu_ecc_err_valid_eclk,
    input  logic [cxlip_top_pkg::MC_CHANNEL-1:0]             mc2iafu_cxlmem_ready,
    input  logic [cxlip_top_pkg::MC_HA_DP_DATA_WIDTH-1:0]    mc2iafu_readdata_eclk           [cxlip_top_pkg::MC_CHANNEL-1:0],
    input  logic [cxlip_top_pkg::MC_MDATA_WIDTH-1:0]         mc2iafu_rsp_mdata_eclk          [cxlip_top_pkg::MC_CHANNEL-1:0],
    
    
    output logic [cxlip_top_pkg::MC_HA_DP_DATA_WIDTH-1:0]    iafu2mc_writedata_eclk          [cxlip_top_pkg::MC_CHANNEL-1:0],
    output logic [cxlip_top_pkg::MC_HA_DP_BE_WIDTH-1:0]      iafu2mc_byteenable_eclk         [cxlip_top_pkg::MC_CHANNEL-1:0],
    output logic [cxlip_top_pkg::MC_CHANNEL-1:0]             iafu2mc_read_eclk,
    output logic [cxlip_top_pkg::MC_CHANNEL-1:0]             iafu2mc_write_eclk,
    output logic [cxlip_top_pkg::MC_CHANNEL-1:0]             iafu2mc_write_poison_eclk,
    output logic [cxlip_top_pkg::MC_CHANNEL-1:0]             iafu2mc_write_ras_sbe_eclk,    
    output logic [cxlip_top_pkg::MC_CHANNEL-1:0]             iafu2mc_write_ras_dbe_eclk,    
    //output logic [cxlip_top_pkg::MC_HA_DP_ADDR_WIDTH-1:0]    iafu2mc_address_eclk            [cxlip_top_pkg::MC_CHANNEL-1:0],
    output logic [(cxlip_top_pkg::CXLIP_FULL_ADDR_MSB):(cxlip_top_pkg::CXLIP_FULL_ADDR_LSB)]    iafu2mc_address_eclk            [cxlip_top_pkg::MC_CHANNEL-1:0],
    output logic [cxlip_top_pkg::MC_MDATA_WIDTH-1:0]         iafu2mc_req_mdata_eclk          [cxlip_top_pkg::MC_CHANNEL-1:0],

                //CXL_IP to AFU to MC TOP Passthrough signals
    output  logic [cxlip_top_pkg::MC_CHANNEL-1:0]             iafu2cxlip_ready_eclk,
    output  logic [cxlip_top_pkg::MC_CHANNEL-1:0]             iafu2cxlip_read_poison_eclk,
    output  logic [cxlip_top_pkg::MC_CHANNEL-1:0]             iafu2cxlip_readdatavalid_eclk,
    // Error Correction Code (ECC)
    // Note *ecc_err_* are valid when mc2iafu_readdatavalid_eclk is active
    output  logic [cxlip_top_pkg::ALTECC_INST_NUMBER-1:0]     iafu2cxlip_ecc_err_corrected_eclk  [cxlip_top_pkg::MC_CHANNEL-1:0],
    output  logic [cxlip_top_pkg::ALTECC_INST_NUMBER-1:0]     iafu2cxlip_ecc_err_detected_eclk   [cxlip_top_pkg::MC_CHANNEL-1:0],
    output  logic [cxlip_top_pkg::ALTECC_INST_NUMBER-1:0]     iafu2cxlip_ecc_err_fatal_eclk      [cxlip_top_pkg::MC_CHANNEL-1:0],
    output  logic [cxlip_top_pkg::ALTECC_INST_NUMBER-1:0]     iafu2cxlip_ecc_err_syn_e_eclk      [cxlip_top_pkg::MC_CHANNEL-1:0],
    output  logic [cxlip_top_pkg::MC_CHANNEL-1:0]             iafu2cxlip_ecc_err_valid_eclk,
    output  logic [cxlip_top_pkg::MC_CHANNEL-1:0]             iafu2cxlip_cxlmem_ready,
    output  logic [cxlip_top_pkg::MC_HA_DP_DATA_WIDTH-1:0]    iafu2cxlip_readdata_eclk           [cxlip_top_pkg::MC_CHANNEL-1:0],
    output  logic [cxlip_top_pkg::MC_MDATA_WIDTH-1:0]         iafu2cxlip_rsp_mdata_eclk          [cxlip_top_pkg::MC_CHANNEL-1:0],
    
    input logic [cxlip_top_pkg::MC_HA_DP_DATA_WIDTH-1:0]      cxlip2iafu_writedata_eclk          [cxlip_top_pkg::MC_CHANNEL-1:0],
    input logic [cxlip_top_pkg::MC_HA_DP_BE_WIDTH-1:0]        cxlip2iafu_byteenable_eclk         [cxlip_top_pkg::MC_CHANNEL-1:0],
    input logic [cxlip_top_pkg::MC_CHANNEL-1:0]               cxlip2iafu_read_eclk,
    input logic [cxlip_top_pkg::MC_CHANNEL-1:0]               cxlip2iafu_write_eclk,
    input logic [cxlip_top_pkg::MC_CHANNEL-1:0]               cxlip2iafu_write_poison_eclk,
    input logic [cxlip_top_pkg::MC_CHANNEL-1:0]               cxlip2iafu_write_ras_sbe_eclk,    
    input logic [cxlip_top_pkg::MC_CHANNEL-1:0]               cxlip2iafu_write_ras_dbe_eclk,    
    //input logic [cxlip_top_pkg::MC_HA_DP_ADDR_WIDTH-1:0]      cxlip2iafu_address_eclk            [cxlip_top_pkg::MC_CHANNEL-1:0],
    input logic [(cxlip_top_pkg::CXLIP_FULL_ADDR_MSB):(cxlip_top_pkg::CXLIP_FULL_ADDR_LSB)]    cxlip2iafu_address_eclk            [cxlip_top_pkg::MC_CHANNEL-1:0],  //added from 22ww18a
    input logic [cxlip_top_pkg::MC_MDATA_WIDTH-1:0]           cxlip2iafu_req_mdata_eclk          [cxlip_top_pkg::MC_CHANNEL-1:0]
 `endif    
    */
);

localparam MC_CHANNEL  = 1;
localparam PAGE_ADDR_SIZE   = 21;
localparam CACHE_ADDR_SIZE  = 27;
//  logic [(cxlip_top_pkg::CXLIP_FULL_ADDR_MSB):(cxlip_top_pkg::CXLIP_FULL_ADDR_LSB)]    cxlip2iafu_chan_address_eclk            [cxlip_top_pkg::MC_CHANNEL-1:0];  //added from 22ww18a
//
//  always_comb begin
//    for (int i=0; i<cxlip_top_pkg::MC_CHANNEL; i++) begin
//      cxlip2iafu_chan_address_eclk[i] = { '0, cxlip2iafu_address_eclk[i][(cxlip_top_pkg::CXLIP_CHAN_ADDR_MSB):(cxlip_top_pkg::CXLIP_CHAN_ADDR_LSB)] };
//    end
//  end

assign iafu2mc_to_mc_axi4      = cxlip2iafu_to_mc_axi4;
assign iafu2cxlip_from_mc_axi4 = mc2iafu_from_mc_axi4;
/*
//Passthrough User can implement the AFU logic here 
  `ifdef OOORSP_MC_AXI2AVMM 
      assign iafu2mc_to_mc_axi4      = cxlip2iafu_to_mc_axi4;
      assign iafu2cxlip_from_mc_axi4 = mc2iafu_from_mc_axi4;
  `else
    assign iafu2cxlip_ready_eclk                = mc2iafu_ready_eclk             ;
    assign iafu2cxlip_read_poison_eclk          = mc2iafu_read_poison_eclk       ;
    assign iafu2cxlip_readdatavalid_eclk        = mc2iafu_readdatavalid_eclk     ;
    assign iafu2cxlip_ecc_err_corrected_eclk    = mc2iafu_ecc_err_corrected_eclk ;
    assign iafu2cxlip_ecc_err_detected_eclk     = mc2iafu_ecc_err_detected_eclk  ;
    assign iafu2cxlip_ecc_err_fatal_eclk        = mc2iafu_ecc_err_fatal_eclk     ;
    assign iafu2cxlip_ecc_err_syn_e_eclk        = mc2iafu_ecc_err_syn_e_eclk     ;
    assign iafu2cxlip_ecc_err_valid_eclk        = mc2iafu_ecc_err_valid_eclk     ;
    assign iafu2cxlip_cxlmem_ready              = mc2iafu_cxlmem_ready           ;
    assign iafu2cxlip_readdata_eclk             = mc2iafu_readdata_eclk          ;
    assign iafu2cxlip_rsp_mdata_eclk            = mc2iafu_rsp_mdata_eclk         ;  


    assign iafu2mc_writedata_eclk               = cxlip2iafu_writedata_eclk     ;
    assign iafu2mc_byteenable_eclk              = cxlip2iafu_byteenable_eclk    ;
    assign iafu2mc_read_eclk                    = cxlip2iafu_read_eclk          ;
    assign iafu2mc_write_eclk                   = cxlip2iafu_write_eclk         ;
    assign iafu2mc_write_poison_eclk            = cxlip2iafu_write_poison_eclk  ;
    assign iafu2mc_write_ras_sbe_eclk           = cxlip2iafu_write_ras_sbe_eclk ;
    assign iafu2mc_write_ras_dbe_eclk           = cxlip2iafu_write_ras_dbe_eclk ;
    //assign iafu2mc_address_eclk                 = cxlip2iafu_chan_address_eclk       ;
    assign iafu2mc_address_eclk                 = cxlip2iafu_address_eclk       ;
    assign iafu2mc_req_mdata_eclk               = cxlip2iafu_req_mdata_eclk     ;
  `endif
*/
// user-define module
hot_tracker_top
#(
  // common parameter
  .ADDR_SIZE(ADDR_SIZE),
  .DATA_SIZE(CACHE_ADDR_SIZE),
  .CNT_SIZE(CNT_SIZE),

  // CM-sketch parameter
  .W(W),
  .W_UNIT(W_UNIT),
  .NUM_SKETCH(NUM_SKETCH),
  .SKETCH_INDEX_SIZE(SKETCH_INDEX_SIZE),
  .COLUMN_INDEX_SIZE(COLUMN_INDEX_SIZE),  
  .NUM_HASH(NUM_HASH),
  .HASH_SIZE(HASH_SIZE),

  // sorted CAM parameter
  .NUM_ENTRY(NUM_ENTRY),
  .INDEX_SIZE(INDEX_SIZE)
)
  cache_hot_tracker_top
(
  .clk                      (afu_clk),
  .rstn                     (afu_rstn),

//`ifdef OOORSP_MC_AXI2AVMM // April 2023 - Supporting out of order responses with AXI4
  .cxlip2iafu_to_mc_axi4    ( cxlip2iafu_to_mc_axi4    ), //( cxlip2iafu_to_mc_axi4  [(2*chanCount+ONE_OR_ZERO):(2*chanCount)]    ), //cxlip2iafu_to_mc_axi4 
  .mc2iafu_from_mc_axi4     ( mc2iafu_from_mc_axi4     ), //( iafu2cxlip_from_mc_axi4[(2*chanCount+ONE_OR_ZERO):(2*chanCount)]  ), //iafu2cxlip_from_mc_axi4
  //`else

  // hot tracker interface
  .query_en                 (cache_query_en),
  .query_ready              (cache_query_ready),

  .mig_addr_en              (cache_mig_addr_en),
  .mig_addr                 (cache_mig_addr),
  .mig_addr_ready           (cache_mig_addr_ready),
  .mem_chan_rd_en           (),

  .csr_addr_ub              (csr_addr_ub),
  .csr_addr_lb              (csr_addr_lb)
);

hot_tracker_top
#(
  // common parameter
  .ADDR_SIZE(ADDR_SIZE),
  .DATA_SIZE(PAGE_ADDR_SIZE),
  .CNT_SIZE(CNT_SIZE),

  // CM-sketch parameter
  .W(W),
  .W_UNIT(W_UNIT),
  .NUM_SKETCH(NUM_SKETCH),
  .SKETCH_INDEX_SIZE(SKETCH_INDEX_SIZE),
  .COLUMN_INDEX_SIZE(COLUMN_INDEX_SIZE),  
  .NUM_HASH(NUM_HASH),
  .HASH_SIZE(HASH_SIZE),

  // sorted CAM parameter
  .NUM_ENTRY(NUM_ENTRY),
  .INDEX_SIZE(INDEX_SIZE)
)
  page_hot_tracker_top
(
  .clk                      (afu_clk),
  .rstn                     (afu_rstn),

//`ifdef OOORSP_MC_AXI2AVMM // April 2023 - Supporting out of order responses with AXI4
  .cxlip2iafu_to_mc_axi4    ( cxlip2iafu_to_mc_axi4    ), //( cxlip2iafu_to_mc_axi4  [(2*chanCount+ONE_OR_ZERO):(2*chanCount)]    ), //cxlip2iafu_to_mc_axi4 
  .mc2iafu_from_mc_axi4     ( mc2iafu_from_mc_axi4     ), //( iafu2cxlip_from_mc_axi4[(2*chanCount+ONE_OR_ZERO):(2*chanCount)]  ), //iafu2cxlip_from_mc_axi4
  //`else

  // hot tracker interface
  .query_en                 (page_query_en),
  .query_ready              (page_query_ready),

  .mig_addr_en              (page_mig_addr_en),
  .mig_addr                 (page_mig_addr),
  .mig_addr_ready           (page_mig_addr_ready),
  .mem_chan_rd_en           (mem_chan_rd_en),
  
  .csr_addr_ub              (csr_addr_ub),
  .csr_addr_lb              (csr_addr_lb)
);

endmodule
