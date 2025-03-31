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


//------------------------------------------------------------
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
//------------------------------------------------------------

`include "ed_define.svh.iv"
`include "avst4to1_pld_if.svh.iv"


module avst4to1_ss_rx_hdr_data_fifos #(
  parameter CORE_NUM = 0,
  parameter APP_CORES = 1,
  parameter DATA_FIFO_ADDR_WIDTH = 9 // Data FIFO depth 2^9 = 512/8 = (max 512B payload)
) (
//
// PLD IF
//
  input                  pld_clk,                                   // Clock (Core)
  input                  pld_rst_n,
  
  avst4to1_if.rx              pld_rx,

  
  output logic [2:0]     pld_rx_hdr_crdup,                           // bit 2:CPLH, bit 1:NPH, bit 0:PH
  output logic [5:0]     pld_rx_hdr_crdup_cnt,                       // bit [5:4]:CPLH, bit [3:2]:NPH, bit [1:0]:PH
  output logic           pld_rx_data_crdup,
  
  output logic [2:0]     Dec_cpl_Hcrdt_avail,
  output logic [2:0]     Dec_np_Hcrdt_avail,
  output logic [2:0]     Dec_p_Hcrdt_avail,

  output logic [11:0]    pld_rx_np_crdup,                           
  output logic [11:0]    pld_rx_p_crdup,
  output logic [11:0]    pld_rx_cpl_crdup,

//
  input                  avst4to1_prim_clk,                        
  input                  avst4to1_prim_rst_n,                       
                         
  input                  crd_prim_rst_n,                            // init only reset
                         
                         
  input  [1:0]           avst4to1_core_max_payload,                 // 00: 128B
                                                                    // 01: 256B
                                                                    // 10: 512B
                                                                    // 11: reserved
  // RX side
  input                  avst4to1_rx_data_avail[APP_CORES-1:0],          // p/cpl
  input                  avst4to1_rx_hdr_avail[APP_CORES-1:0],           // p/cpl
  input                  avst4to1_rx_nph_hdr_avail[APP_CORES-1:0],       // np
  
  output logic           avst4to1_vf_active[APP_CORES-1:0],
  output logic [10:0]    avst4to1_vf_num[APP_CORES-1:0],
  output logic [2:0]     avst4to1_pf_num[APP_CORES-1:0],
  output logic [2:0]     avst4to1_bar_range[APP_CORES-1:0],
  output logic           avst4to1_rx_tlp_abort[APP_CORES-1:0],
  
  output logic           avst4to1_rx_sop[APP_CORES-1:0],
  output logic           avst4to1_rx_eop[APP_CORES-1:0],
  output logic [127:0]   avst4to1_rx_hdr[APP_CORES-1:0], 
  output logic [31:0]    avst4to1_rx_prefix[APP_CORES-1:0],
  output logic           avst4to1_rx_passthrough[APP_CORES-1:0],
  output logic           avst4to1_rx_prefix_valid[APP_CORES-1:0],
  output logic[11:0]     avst4to1_rx_RSSAI_prefix[APP_CORES-1:0],
  output logic           avst4to1_rx_RSSAI_prefix_valid[APP_CORES-1:0],
  output logic [511:0]   avst4to1_rx_data[APP_CORES-1:0],
  output logic [15:0]    avst4to1_rx_data_dw_valid[APP_CORES-1:0]
);
//----------------------------------------------------------------------------//

localparam MAX_N_DATA_CRD = (2**DATA_FIFO_ADDR_WIDTH)/(8+1); // (2^DATA_FIFO_ADDR_WIDTH)/8 data cycles for 512B + 1 ECRC
localparam MAX_FUNC_NUM = (APP_CORES**2);

avst4to1_if       pld_rx_i();
avst4to1_if       avst4to1_if_i_f();
avst4to1_if       avst4to1_if_i_ff();
avst4to1_if       avst4to1_if_i_fff();
avst4to1_if       avst4to1_if_i_ffff();
avst4to1_if       avst4to1_if_i_fffff();

avst4to1_if       core_avst4to1_if();

logic        bcast_msg_s0_i;
logic        bcast_msg_s1_i;
logic        bcast_msg_s0_f;
logic        bcast_msg_s1_f;
logic        bcast_msg_s0_ff;
logic        bcast_msg_s1_ff;
logic        core_bcast_msg_s0;
logic        core_bcast_msg_s1;
logic        bcast_msg_s2_i;
logic        bcast_msg_s3_i;
logic        bcast_msg_s2_f;
logic        bcast_msg_s3_f;
logic        bcast_msg_s2_ff;
logic        bcast_msg_s3_ff;
logic        core_bcast_msg_s2;
logic        core_bcast_msg_s3;

logic        func_num_val_s0;
logic        bcast_msg_s0;
logic [7:0]  func_num_s0;
logic        mem_addr_val_s0;
logic        mem_64b_addr_s0;
logic [63:0] mem_addr_s0;

logic        func_num_val_s1;
logic        bcast_msg_s1;
logic [7:0]  func_num_s1;
logic        mem_addr_val_s1;
logic        mem_64b_addr_s1;
logic [63:0] mem_addr_s1;

  logic        func_num_val_s2;
  logic        bcast_msg_s2;
  logic [7:0]  func_num_s2;
  logic        mem_addr_val_s2;
  logic        mem_64b_addr_s2;
  logic [63:0] mem_addr_s2;
  
  logic        func_num_val_s3;
  logic        bcast_msg_s3;
  logic [7:0]  func_num_s3;
  logic        mem_addr_val_s3;
  logic        mem_64b_addr_s3;
  logic [63:0] mem_addr_s3;

logic        tlp_decode_s0;
logic        tlp_active_s0;
logic        hit_active_s0;
logic        hit_active_s0_clr;
logic        hit_active_s0_set;
logic        s0_select_core[APP_CORES-1:0];

logic        tlp_decode_s1;
logic        tlp_active_s1;
logic        hit_active_s1;
logic        hit_active_s1_clr;
logic        hit_active_s1_set;
logic        s1_select_core[APP_CORES-1:0];

logic        tlp_decode_s2;
logic        tlp_active_s2;
logic        hit_active_s2;
logic        hit_active_s2_clr;
logic        hit_active_s2_set;
logic        s2_select_core[APP_CORES-1:0];

logic        tlp_decode_s3;
logic        tlp_active_s3;
logic        hit_active_s3;
logic        hit_active_s3_clr;
logic        hit_active_s3_set;
logic        s3_select_core[APP_CORES-1:0];

logic        tlp_decode_s0_f;
logic        tlp_active_s0_f;
logic        hit_active_s0_f;
logic        s0_select_core_f[APP_CORES-1:0];

logic        tlp_decode_s1_f;
logic        tlp_active_s1_f;
logic        hit_active_s1_f;
logic        s1_select_core_f[APP_CORES-1:0];

  logic        tlp_decode_s2_f;
  logic        tlp_active_s2_f;
  logic        hit_active_s2_f;
  logic        s2_select_core_f[APP_CORES-1:0];
  
  logic        tlp_decode_s3_f;
  logic        tlp_active_s3_f;
  logic        hit_active_s3_f;
  logic        s3_select_core_f[APP_CORES-1:0];

logic [5:0]  all_cores_pld_rx_hdr_crdup_cnt;
logic [2:0]  all_cores_pld_rx_hdr_crdup;
logic        all_cores_pld_rx_data_crdup;

logic [2:0]  core_pld_rx_hdr_crdup;
logic [APP_CORES-1:0] core_pld_rx_data_crdup;


logic [11:0] core_pld_rx_np_crdup;
logic [11:0] core_pld_rx_p_crdup;
logic [11:0] core_pld_rx_cpl_crdup;


logic [1:0] all_cores_pld_rx_hdr_np_crd;
logic [1:0] all_cores_pld_rx_hdr_p_crd;  
logic [1:0] all_cores_pld_rx_hdr_cpl_crd;

logic [11:0] all_cores_pld_rx_data_np_crd;
logic [11:0] all_cores_pld_rx_data_p_crd;  
logic [11:0] all_cores_pld_rx_data_cpl_crd;

logic [1:0] tlp_crd_type_s0;
logic [1:0] tlp_crd_type_s0_f;
logic [1:0] tlp_crd_type_s0_ff;
logic [1:0] tlp_crd_type_s0_fff;

logic [1:0] tlp_crd_type_s1;
logic [1:0] tlp_crd_type_s1_f;
logic [1:0] tlp_crd_type_s1_ff;
logic [1:0] tlp_crd_type_s1_fff;

logic s0_Dec_cpl_Hcrdt_avail;
logic s0_Dec_np_Hcrdt_avail;
logic s0_Dec_p_Hcrdt_avail;
logic s1_Dec_cpl_Hcrdt_avail;
logic s1_Dec_np_Hcrdt_avail;
logic s1_Dec_p_Hcrdt_avail;
logic s2_Dec_cpl_Hcrdt_avail;
logic s2_Dec_np_Hcrdt_avail;
logic s2_Dec_p_Hcrdt_avail;
logic s3_Dec_cpl_Hcrdt_avail;
logic s3_Dec_np_Hcrdt_avail;
logic s3_Dec_p_Hcrdt_avail;

  logic [1:0] tlp_crd_type_s2;
  logic [1:0] tlp_crd_type_s2_f;
  logic [1:0] tlp_crd_type_s2_ff;
  logic [1:0] tlp_crd_type_s2_fff;
  
  logic [1:0] tlp_crd_type_s3;
  logic [1:0] tlp_crd_type_s3_f;
  logic [1:0] tlp_crd_type_s3_ff;
  logic [1:0] tlp_crd_type_s3_fff;

genvar core;
//----------------------------------------------------------------------------//

//
// Input flop
//
always @(posedge pld_clk)
begin                                       
    // S0  
    pld_rx_i.rx_st_hdr_s0_o                 <=  pld_rx.rx_st_hdr_s0_o;
    pld_rx_i.rx_st_hdr_par_s0_o             <=  pld_rx.rx_st_hdr_par_s0_o;
    pld_rx_i.rx_st_tlp_prfx_s0_o            <=  pld_rx.rx_st_tlp_prfx_s0_o;
    pld_rx_i.rx_st_tlp_prfx_par_s0_o        <=  pld_rx.rx_st_tlp_prfx_par_s0_o;
    pld_rx_i.rx_st_sop_s0_o                 <=  pld_rx.rx_st_sop_s0_o;
    pld_rx_i.rx_st_eop_s0_o                 <=  pld_rx.rx_st_eop_s0_o;
    pld_rx_i.rx_st_data_s0_o                <=  pld_rx.rx_st_data_s0_o;
    pld_rx_i.rx_st_data_par_s0_o            <=  pld_rx.rx_st_data_par_s0_o;
    pld_rx_i.rx_st_empty_s0_o               <=  pld_rx.rx_st_empty_s0_o;
    pld_rx_i.rx_st_tlp_RSSAI_prfx_s0_o      <=  pld_rx.rx_st_tlp_RSSAI_prfx_s0_o;
    pld_rx_i.rx_st_tlp_RSSAI_prfx_par_s0_o  <=  pld_rx.rx_st_tlp_RSSAI_prfx_par_s0_o;
    pld_rx_i.rx_st_passthrough_s0_o         <=  pld_rx.rx_st_passthrough_s0_o;
    pld_rx_i.rx_st_vfactive_s0_o            <=  pld_rx.rx_st_vfactive_s0_o;
    pld_rx_i.rx_st_vfnum_s0_o               <=  pld_rx.rx_st_vfnum_s0_o;
    pld_rx_i.rx_st_pfnum_s0_o               <=  pld_rx.rx_st_pfnum_s0_o;
    pld_rx_i.rx_st_bar_s0_o                 <=  pld_rx.rx_st_bar_s0_o;
    pld_rx_i.rx_st_dvalid_s0_o              <=  pld_rx.rx_st_dvalid_s0_o;
    pld_rx_i.rx_st_hvalid_s0_o              <=  pld_rx.rx_st_hvalid_s0_o;
    pld_rx_i.rx_st_pvalid_s0_o              <=  pld_rx.rx_st_pvalid_s0_o;
    // S1  
    pld_rx_i.rx_st_hdr_s1_o                 <=  pld_rx.rx_st_hdr_s1_o;
    pld_rx_i.rx_st_hdr_par_s1_o             <=  pld_rx.rx_st_hdr_par_s1_o;
    pld_rx_i.rx_st_tlp_prfx_s1_o            <=  pld_rx.rx_st_tlp_prfx_s1_o;
    pld_rx_i.rx_st_tlp_prfx_par_s1_o        <=  pld_rx.rx_st_tlp_prfx_par_s1_o;
    pld_rx_i.rx_st_sop_s1_o                 <=  pld_rx.rx_st_sop_s1_o;
    pld_rx_i.rx_st_eop_s1_o                 <=  pld_rx.rx_st_eop_s1_o;
    pld_rx_i.rx_st_data_s1_o                <=  pld_rx.rx_st_data_s1_o;
    pld_rx_i.rx_st_data_par_s1_o            <=  pld_rx.rx_st_data_par_s1_o;
    pld_rx_i.rx_st_empty_s1_o               <=  pld_rx.rx_st_empty_s1_o;
    pld_rx_i.rx_st_tlp_RSSAI_prfx_s1_o      <=  pld_rx.rx_st_tlp_RSSAI_prfx_s1_o;
    pld_rx_i.rx_st_tlp_RSSAI_prfx_par_s1_o  <=  pld_rx.rx_st_tlp_RSSAI_prfx_par_s1_o;
    pld_rx_i.rx_st_passthrough_s1_o         <=  pld_rx.rx_st_passthrough_s1_o;
    pld_rx_i.rx_st_vfactive_s1_o            <=  pld_rx.rx_st_vfactive_s1_o;
    pld_rx_i.rx_st_vfnum_s1_o               <=  pld_rx.rx_st_vfnum_s1_o;
    pld_rx_i.rx_st_pfnum_s1_o               <=  pld_rx.rx_st_pfnum_s1_o;
    pld_rx_i.rx_st_bar_s1_o                 <=  pld_rx.rx_st_bar_s1_o;
    pld_rx_i.rx_st_dvalid_s1_o              <=  pld_rx.rx_st_dvalid_s1_o;
    pld_rx_i.rx_st_hvalid_s1_o              <=  pld_rx.rx_st_hvalid_s1_o;
    pld_rx_i.rx_st_pvalid_s1_o              <=  pld_rx.rx_st_pvalid_s1_o;
    // S2  
    pld_rx_i.rx_st_hdr_s2_o                 <=  pld_rx.rx_st_hdr_s2_o;
    pld_rx_i.rx_st_hdr_par_s2_o             <=  pld_rx.rx_st_hdr_par_s2_o;
    pld_rx_i.rx_st_tlp_prfx_s2_o            <=  pld_rx.rx_st_tlp_prfx_s2_o;
    pld_rx_i.rx_st_tlp_prfx_par_s2_o        <=  pld_rx.rx_st_tlp_prfx_par_s2_o;
    pld_rx_i.rx_st_sop_s2_o                 <=  pld_rx.rx_st_sop_s2_o;
    pld_rx_i.rx_st_eop_s2_o                 <=  pld_rx.rx_st_eop_s2_o;
    pld_rx_i.rx_st_data_s2_o                <=  pld_rx.rx_st_data_s2_o;
    pld_rx_i.rx_st_data_par_s2_o            <=  pld_rx.rx_st_data_par_s2_o;
    pld_rx_i.rx_st_empty_s2_o               <=  pld_rx.rx_st_empty_s2_o;
    pld_rx_i.rx_st_tlp_RSSAI_prfx_s2_o      <=  pld_rx.rx_st_tlp_RSSAI_prfx_s2_o;
    pld_rx_i.rx_st_tlp_RSSAI_prfx_par_s2_o  <=  pld_rx.rx_st_tlp_RSSAI_prfx_par_s2_o;
    pld_rx_i.rx_st_passthrough_s2_o         <=  pld_rx.rx_st_passthrough_s2_o;
    pld_rx_i.rx_st_vfactive_s2_o            <=  pld_rx.rx_st_vfactive_s2_o;
    pld_rx_i.rx_st_vfnum_s2_o               <=  pld_rx.rx_st_vfnum_s2_o;
    pld_rx_i.rx_st_pfnum_s2_o               <=  pld_rx.rx_st_pfnum_s2_o;
    pld_rx_i.rx_st_bar_s2_o                 <=  pld_rx.rx_st_bar_s2_o;
    pld_rx_i.rx_st_dvalid_s2_o              <=  pld_rx.rx_st_dvalid_s2_o;
    pld_rx_i.rx_st_hvalid_s2_o              <=  pld_rx.rx_st_hvalid_s2_o;
    pld_rx_i.rx_st_pvalid_s2_o              <=  pld_rx.rx_st_pvalid_s2_o;
    // S3  
    pld_rx_i.rx_st_hdr_s3_o                 <=  pld_rx.rx_st_hdr_s3_o;
    pld_rx_i.rx_st_hdr_par_s3_o             <=  pld_rx.rx_st_hdr_par_s3_o;
    pld_rx_i.rx_st_tlp_prfx_s3_o            <=  pld_rx.rx_st_tlp_prfx_s3_o;
    pld_rx_i.rx_st_tlp_prfx_par_s3_o        <=  pld_rx.rx_st_tlp_prfx_par_s3_o;
    pld_rx_i.rx_st_sop_s3_o                 <=  pld_rx.rx_st_sop_s3_o;
    pld_rx_i.rx_st_eop_s3_o                 <=  pld_rx.rx_st_eop_s3_o;
    pld_rx_i.rx_st_data_s3_o                <=  pld_rx.rx_st_data_s3_o;
    pld_rx_i.rx_st_data_par_s3_o            <=  pld_rx.rx_st_data_par_s3_o;
    pld_rx_i.rx_st_empty_s3_o               <=  pld_rx.rx_st_empty_s3_o;
    pld_rx_i.rx_st_tlp_RSSAI_prfx_s3_o      <=  pld_rx.rx_st_tlp_RSSAI_prfx_s3_o;
    pld_rx_i.rx_st_tlp_RSSAI_prfx_par_s3_o  <=  pld_rx.rx_st_tlp_RSSAI_prfx_par_s3_o;
    pld_rx_i.rx_st_passthrough_s3_o         <=  pld_rx.rx_st_passthrough_s3_o;
    pld_rx_i.rx_st_vfactive_s3_o            <=  pld_rx.rx_st_vfactive_s3_o;
    pld_rx_i.rx_st_vfnum_s3_o               <=  pld_rx.rx_st_vfnum_s3_o;
    pld_rx_i.rx_st_pfnum_s3_o               <=  pld_rx.rx_st_pfnum_s3_o;
    pld_rx_i.rx_st_bar_s3_o                 <=  pld_rx.rx_st_bar_s3_o;
    pld_rx_i.rx_st_dvalid_s3_o              <=  pld_rx.rx_st_dvalid_s3_o;
    pld_rx_i.rx_st_hvalid_s3_o              <=  pld_rx.rx_st_hvalid_s3_o;
    pld_rx_i.rx_st_pvalid_s3_o              <=  pld_rx.rx_st_pvalid_s3_o;
end                                         

always @(posedge pld_clk)
begin                                              
    // S0  
    avst4to1_if_i_f.rx_st_hdr_s0_o                 <=  pld_rx_i.rx_st_hdr_s0_o;
    avst4to1_if_i_f.rx_st_hdr_par_s0_o             <=  pld_rx_i.rx_st_hdr_par_s0_o;
    avst4to1_if_i_f.rx_st_tlp_prfx_s0_o            <=  pld_rx_i.rx_st_tlp_prfx_s0_o;
    avst4to1_if_i_f.rx_st_tlp_prfx_par_s0_o        <=  pld_rx_i.rx_st_tlp_prfx_par_s0_o;
    avst4to1_if_i_f.rx_st_sop_s0_o                 <=  pld_rx_i.rx_st_sop_s0_o;
    avst4to1_if_i_f.rx_st_eop_s0_o                 <=  pld_rx_i.rx_st_eop_s0_o;
    avst4to1_if_i_f.rx_st_data_s0_o                <=  pld_rx_i.rx_st_data_s0_o;
    avst4to1_if_i_f.rx_st_data_par_s0_o            <=  pld_rx_i.rx_st_data_par_s0_o;
    avst4to1_if_i_f.rx_st_empty_s0_o               <=  pld_rx_i.rx_st_empty_s0_o;
    avst4to1_if_i_f.rx_st_tlp_RSSAI_prfx_s0_o      <=  pld_rx_i.rx_st_tlp_RSSAI_prfx_s0_o;
    avst4to1_if_i_f.rx_st_tlp_RSSAI_prfx_par_s0_o  <=  pld_rx_i.rx_st_tlp_RSSAI_prfx_par_s0_o;
    avst4to1_if_i_f.rx_st_passthrough_s0_o         <=  pld_rx_i.rx_st_passthrough_s0_o;
    avst4to1_if_i_f.rx_st_vfactive_s0_o            <=  pld_rx_i.rx_st_vfactive_s0_o;
    avst4to1_if_i_f.rx_st_vfnum_s0_o               <=  pld_rx_i.rx_st_vfnum_s0_o;
    avst4to1_if_i_f.rx_st_pfnum_s0_o               <=  pld_rx_i.rx_st_pfnum_s0_o;
    avst4to1_if_i_f.rx_st_bar_s0_o                 <=  pld_rx_i.rx_st_bar_s0_o;
    avst4to1_if_i_f.rx_st_dvalid_s0_o              <=  pld_rx_i.rx_st_dvalid_s0_o;
    avst4to1_if_i_f.rx_st_hvalid_s0_o              <=  pld_rx_i.rx_st_hvalid_s0_o;
    avst4to1_if_i_f.rx_st_pvalid_s0_o              <=  pld_rx_i.rx_st_pvalid_s0_o;
    // S1  
    avst4to1_if_i_f.rx_st_hdr_s1_o                 <=  pld_rx_i.rx_st_hdr_s1_o;
    avst4to1_if_i_f.rx_st_hdr_par_s1_o             <=  pld_rx_i.rx_st_hdr_par_s1_o;
    avst4to1_if_i_f.rx_st_tlp_prfx_s1_o            <=  pld_rx_i.rx_st_tlp_prfx_s1_o;
    avst4to1_if_i_f.rx_st_tlp_prfx_par_s1_o        <=  pld_rx_i.rx_st_tlp_prfx_par_s1_o;
    avst4to1_if_i_f.rx_st_sop_s1_o                 <=  pld_rx_i.rx_st_sop_s1_o;
    avst4to1_if_i_f.rx_st_eop_s1_o                 <=  pld_rx_i.rx_st_eop_s1_o;
    avst4to1_if_i_f.rx_st_data_s1_o                <=  pld_rx_i.rx_st_data_s1_o;
    avst4to1_if_i_f.rx_st_data_par_s1_o            <=  pld_rx_i.rx_st_data_par_s1_o;
    avst4to1_if_i_f.rx_st_empty_s1_o               <=  pld_rx_i.rx_st_empty_s1_o;
    avst4to1_if_i_f.rx_st_tlp_RSSAI_prfx_s1_o      <=  pld_rx_i.rx_st_tlp_RSSAI_prfx_s1_o;
    avst4to1_if_i_f.rx_st_tlp_RSSAI_prfx_par_s1_o  <=  pld_rx_i.rx_st_tlp_RSSAI_prfx_par_s1_o;
    avst4to1_if_i_f.rx_st_passthrough_s1_o         <=  pld_rx_i.rx_st_passthrough_s1_o;
    avst4to1_if_i_f.rx_st_vfactive_s1_o            <=  pld_rx_i.rx_st_vfactive_s1_o;
    avst4to1_if_i_f.rx_st_vfnum_s1_o               <=  pld_rx_i.rx_st_vfnum_s1_o;
    avst4to1_if_i_f.rx_st_pfnum_s1_o               <=  pld_rx_i.rx_st_pfnum_s1_o;
    avst4to1_if_i_f.rx_st_bar_s1_o                 <=  pld_rx_i.rx_st_bar_s1_o;
    avst4to1_if_i_f.rx_st_dvalid_s1_o              <=  pld_rx_i.rx_st_dvalid_s1_o;
    avst4to1_if_i_f.rx_st_hvalid_s1_o              <=  pld_rx_i.rx_st_hvalid_s1_o;
    avst4to1_if_i_f.rx_st_pvalid_s1_o              <=  pld_rx_i.rx_st_pvalid_s1_o;
    // S2  
    avst4to1_if_i_f.rx_st_hdr_s2_o                 <=  pld_rx_i.rx_st_hdr_s2_o;
    avst4to1_if_i_f.rx_st_hdr_par_s2_o             <=  pld_rx_i.rx_st_hdr_par_s2_o;
    avst4to1_if_i_f.rx_st_tlp_prfx_s2_o            <=  pld_rx_i.rx_st_tlp_prfx_s2_o;
    avst4to1_if_i_f.rx_st_tlp_prfx_par_s2_o        <=  pld_rx_i.rx_st_tlp_prfx_par_s2_o;
    avst4to1_if_i_f.rx_st_sop_s2_o                 <=  pld_rx_i.rx_st_sop_s2_o;
    avst4to1_if_i_f.rx_st_eop_s2_o                 <=  pld_rx_i.rx_st_eop_s2_o;
    avst4to1_if_i_f.rx_st_data_s2_o                <=  pld_rx_i.rx_st_data_s2_o;
    avst4to1_if_i_f.rx_st_data_par_s2_o            <=  pld_rx_i.rx_st_data_par_s2_o;
    avst4to1_if_i_f.rx_st_empty_s2_o               <=  pld_rx_i.rx_st_empty_s2_o;
    avst4to1_if_i_f.rx_st_tlp_RSSAI_prfx_s2_o      <=  pld_rx_i.rx_st_tlp_RSSAI_prfx_s2_o;
    avst4to1_if_i_f.rx_st_tlp_RSSAI_prfx_par_s2_o  <=  pld_rx_i.rx_st_tlp_RSSAI_prfx_par_s2_o;
    avst4to1_if_i_f.rx_st_passthrough_s2_o         <=  pld_rx_i.rx_st_passthrough_s2_o;
    avst4to1_if_i_f.rx_st_vfactive_s2_o            <=  pld_rx_i.rx_st_vfactive_s2_o;
    avst4to1_if_i_f.rx_st_vfnum_s2_o               <=  pld_rx_i.rx_st_vfnum_s2_o;
    avst4to1_if_i_f.rx_st_pfnum_s2_o               <=  pld_rx_i.rx_st_pfnum_s2_o;
    avst4to1_if_i_f.rx_st_bar_s2_o                 <=  pld_rx_i.rx_st_bar_s2_o;
    avst4to1_if_i_f.rx_st_dvalid_s2_o              <=  pld_rx_i.rx_st_dvalid_s2_o;
    avst4to1_if_i_f.rx_st_hvalid_s2_o              <=  pld_rx_i.rx_st_hvalid_s2_o;
    avst4to1_if_i_f.rx_st_pvalid_s2_o              <=  pld_rx_i.rx_st_pvalid_s2_o;
    // S3  
    avst4to1_if_i_f.rx_st_hdr_s3_o                 <=  pld_rx_i.rx_st_hdr_s3_o;
    avst4to1_if_i_f.rx_st_hdr_par_s3_o             <=  pld_rx_i.rx_st_hdr_par_s3_o;
    avst4to1_if_i_f.rx_st_tlp_prfx_s3_o            <=  pld_rx_i.rx_st_tlp_prfx_s3_o;
    avst4to1_if_i_f.rx_st_tlp_prfx_par_s3_o        <=  pld_rx_i.rx_st_tlp_prfx_par_s3_o;
    avst4to1_if_i_f.rx_st_sop_s3_o                 <=  pld_rx_i.rx_st_sop_s3_o;
    avst4to1_if_i_f.rx_st_eop_s3_o                 <=  pld_rx_i.rx_st_eop_s3_o;
    avst4to1_if_i_f.rx_st_data_s3_o                <=  pld_rx_i.rx_st_data_s3_o;
    avst4to1_if_i_f.rx_st_data_par_s3_o            <=  pld_rx_i.rx_st_data_par_s3_o;
    avst4to1_if_i_f.rx_st_empty_s3_o               <=  pld_rx_i.rx_st_empty_s3_o;
    avst4to1_if_i_f.rx_st_tlp_RSSAI_prfx_s3_o      <=  pld_rx_i.rx_st_tlp_RSSAI_prfx_s3_o;
    avst4to1_if_i_f.rx_st_tlp_RSSAI_prfx_par_s3_o  <=  pld_rx_i.rx_st_tlp_RSSAI_prfx_par_s3_o;
    avst4to1_if_i_f.rx_st_passthrough_s3_o         <=  pld_rx_i.rx_st_passthrough_s3_o;
    avst4to1_if_i_f.rx_st_vfactive_s3_o            <=  pld_rx_i.rx_st_vfactive_s3_o;
    avst4to1_if_i_f.rx_st_vfnum_s3_o               <=  pld_rx_i.rx_st_vfnum_s3_o;
    avst4to1_if_i_f.rx_st_pfnum_s3_o               <=  pld_rx_i.rx_st_pfnum_s3_o;
    avst4to1_if_i_f.rx_st_bar_s3_o                 <=  pld_rx_i.rx_st_bar_s3_o;
    avst4to1_if_i_f.rx_st_dvalid_s3_o              <=  pld_rx_i.rx_st_dvalid_s3_o;
    avst4to1_if_i_f.rx_st_hvalid_s3_o              <=  pld_rx_i.rx_st_hvalid_s3_o;
    avst4to1_if_i_f.rx_st_pvalid_s3_o              <=  pld_rx_i.rx_st_pvalid_s3_o;
end                                                

//
// TLP Headers Decode
//
// S0
avst4to1_ss_tlp_hdr_decode tlp_hdr_decode_s0(
  .pld_clk      (pld_clk),
  .pld_rst_n    (pld_rst_n),
  
  .tlp_valid    (pld_rx_i.rx_st_hvalid_s0_o),
  .tlp_sop      (pld_rx_i.rx_st_sop_s0_o),
  .tlp_hdr      (pld_rx_i.rx_st_hdr_s0_o[127:0]),
  
  .func_num_val (func_num_val_s0),
  .bcast_msg    (bcast_msg_s0),
  .func_num     (func_num_s0),
  
  .mem_addr_val (mem_addr_val_s0),
  .mem_64b_addr (mem_64b_addr_s0),
  .mem_addr     (mem_addr_s0    ),
  
  .tlp_crd_type (tlp_crd_type_s0[1:0])
);
always @(posedge pld_clk)
begin
  if (~pld_rst_n) begin
    s0_Dec_cpl_Hcrdt_avail <= 1'd0;
    s0_Dec_np_Hcrdt_avail  <= 1'd0;
    s0_Dec_p_Hcrdt_avail   <= 1'd0;
  end
  else begin
    if (func_num_val_s0 | mem_addr_val_s0) begin
      case (tlp_crd_type_s0[1:0])
      2'b11:
        begin
          s0_Dec_cpl_Hcrdt_avail <= 1'd0;
          s0_Dec_np_Hcrdt_avail <= 1'd0;
          s0_Dec_p_Hcrdt_avail <= 1'd0;
        end
      2'b10:
        begin
          s0_Dec_cpl_Hcrdt_avail <= 1'd1;
          s0_Dec_np_Hcrdt_avail <= 1'd0;
          s0_Dec_p_Hcrdt_avail <= 1'd0;
        end
      2'b01:
        begin
          s0_Dec_cpl_Hcrdt_avail <= 1'd0;
          s0_Dec_np_Hcrdt_avail <= 1'd1;
          s0_Dec_p_Hcrdt_avail <= 1'd0;
        end
      2'b0:
        begin
          s0_Dec_cpl_Hcrdt_avail <= 1'd0;
          s0_Dec_np_Hcrdt_avail <= 1'd0;
          s0_Dec_p_Hcrdt_avail <= 1'd1;
        end
      endcase
    end
    else begin
      s0_Dec_cpl_Hcrdt_avail <= 1'd0;
      s0_Dec_np_Hcrdt_avail <= 1'd0;
      s0_Dec_p_Hcrdt_avail <= 1'd0;
    end
  end
end

// S1
avst4to1_ss_tlp_hdr_decode tlp_hdr_decode_s1(
  .pld_clk      (pld_clk),
  .pld_rst_n    (pld_rst_n),
  
  .tlp_valid    (pld_rx_i.rx_st_hvalid_s1_o),
  .tlp_sop      (pld_rx_i.rx_st_sop_s1_o),
  .tlp_hdr      (pld_rx_i.rx_st_hdr_s1_o[127:0]),
  
  .func_num_val (func_num_val_s1),
  .bcast_msg    (bcast_msg_s1),
  .func_num     (func_num_s1),
  
  .mem_addr_val (mem_addr_val_s1),
  .mem_64b_addr (mem_64b_addr_s1),
  .mem_addr     (mem_addr_s1    ),
  
  .tlp_crd_type (tlp_crd_type_s1[1:0])
);
always @(posedge pld_clk)
begin
  if (~pld_rst_n) begin
    s1_Dec_cpl_Hcrdt_avail <= 1'd0;
    s1_Dec_np_Hcrdt_avail  <= 1'd0;
    s1_Dec_p_Hcrdt_avail   <= 1'd0;
  end
  else begin
    if (func_num_val_s1 | mem_addr_val_s1) begin
      case (tlp_crd_type_s1[1:0])
      2'b11:
        begin
          s1_Dec_cpl_Hcrdt_avail <= 1'd0;
          s1_Dec_np_Hcrdt_avail <= 1'd0;
          s1_Dec_p_Hcrdt_avail <= 1'd0;
        end
      2'b10:
        begin
          s1_Dec_cpl_Hcrdt_avail <= 1'd1;
          s1_Dec_np_Hcrdt_avail <= 1'd0;
          s1_Dec_p_Hcrdt_avail <= 1'd0;
        end
      2'b01:
        begin
          s1_Dec_cpl_Hcrdt_avail <= 1'd0;
          s1_Dec_np_Hcrdt_avail <= 1'd1;
          s1_Dec_p_Hcrdt_avail <= 1'd0;
        end
      2'b0:
        begin
          s1_Dec_cpl_Hcrdt_avail <= 1'd0;
          s1_Dec_np_Hcrdt_avail <= 1'd0;
          s1_Dec_p_Hcrdt_avail <= 1'd1;
        end
      endcase
    end
    else begin
      s1_Dec_cpl_Hcrdt_avail <= 1'd0;
      s1_Dec_np_Hcrdt_avail <= 1'd0;
      s1_Dec_p_Hcrdt_avail <= 1'd0;
    end
  end
end

  // S2
  avst4to1_ss_tlp_hdr_decode tlp_hdr_decode_s2(
    .pld_clk      (pld_clk),
    .pld_rst_n    (pld_rst_n),
    
    .tlp_valid    (pld_rx_i.rx_st_hvalid_s2_o),
    .tlp_sop      (pld_rx_i.rx_st_sop_s2_o),
    .tlp_hdr      (pld_rx_i.rx_st_hdr_s2_o[127:0]),
    
    .func_num_val (func_num_val_s2),
    .bcast_msg    (bcast_msg_s2),
    .func_num     (func_num_s2),
    
    .mem_addr_val (mem_addr_val_s2),
    .mem_64b_addr (mem_64b_addr_s2),
    .mem_addr     (mem_addr_s2    ),
    
    .tlp_crd_type (tlp_crd_type_s2[1:0])
  );
always @(posedge pld_clk)
begin
  if (~pld_rst_n) begin
    s2_Dec_cpl_Hcrdt_avail <= 1'd0;
    s2_Dec_np_Hcrdt_avail  <= 1'd0;
    s2_Dec_p_Hcrdt_avail   <= 1'd0;
  end
  else begin
    if (func_num_val_s2 | mem_addr_val_s2) begin
      case (tlp_crd_type_s2[1:0])
      2'b11:
        begin
          s2_Dec_cpl_Hcrdt_avail <= 1'd0;
          s2_Dec_np_Hcrdt_avail <= 1'd0;
          s2_Dec_p_Hcrdt_avail <= 1'd0;
        end
      2'b10:
        begin
          s2_Dec_cpl_Hcrdt_avail <= 1'd1;
          s2_Dec_np_Hcrdt_avail <= 1'd0;
          s2_Dec_p_Hcrdt_avail <= 1'd0;
        end
      2'b01:
        begin
          s2_Dec_cpl_Hcrdt_avail <= 1'd0;
          s2_Dec_np_Hcrdt_avail <= 1'd1;
          s2_Dec_p_Hcrdt_avail <= 1'd0;
        end
      2'b0:
        begin
          s2_Dec_cpl_Hcrdt_avail <= 1'd0;
          s2_Dec_np_Hcrdt_avail <= 1'd0;
          s2_Dec_p_Hcrdt_avail <= 1'd1;
        end
      endcase
    end
    else begin
      s2_Dec_cpl_Hcrdt_avail <= 1'd0;
      s2_Dec_np_Hcrdt_avail <= 1'd0;
      s2_Dec_p_Hcrdt_avail <= 1'd0;
    end
  end
end

  // S3
  avst4to1_ss_tlp_hdr_decode tlp_hdr_decode_s3(
    .pld_clk      (pld_clk),
    .pld_rst_n    (pld_rst_n),
    
    .tlp_valid    (pld_rx_i.rx_st_hvalid_s3_o),
    .tlp_sop      (pld_rx_i.rx_st_sop_s3_o),
    .tlp_hdr      (pld_rx_i.rx_st_hdr_s3_o[127:0]),
    
    .func_num_val (func_num_val_s3),
    .bcast_msg    (bcast_msg_s3),
    .func_num     (func_num_s3),
    
    .mem_addr_val (mem_addr_val_s3),
    .mem_64b_addr (mem_64b_addr_s3),
    .mem_addr     (mem_addr_s3    ),
    
    .tlp_crd_type (tlp_crd_type_s3[1:0])
  );

always @(posedge pld_clk)
begin // {
  if (~pld_rst_n) begin
    s3_Dec_cpl_Hcrdt_avail <= 1'd0;
    s3_Dec_np_Hcrdt_avail  <= 1'd0;
    s3_Dec_p_Hcrdt_avail   <= 1'd0;
  end
  else begin
    if (func_num_val_s3 | mem_addr_val_s3) begin
      case (tlp_crd_type_s3[1:0])
      2'b11:
        begin
          s3_Dec_cpl_Hcrdt_avail <= 1'd0;
          s3_Dec_np_Hcrdt_avail <= 1'd0;
          s3_Dec_p_Hcrdt_avail <= 1'd0;
        end
      2'b10:
        begin
          s3_Dec_cpl_Hcrdt_avail <= 1'd1;
          s3_Dec_np_Hcrdt_avail <= 1'd0;
          s3_Dec_p_Hcrdt_avail <= 1'd0;
        end
      2'b01:
        begin
          s3_Dec_cpl_Hcrdt_avail <= 1'd0;
          s3_Dec_np_Hcrdt_avail <= 1'd1;
          s3_Dec_p_Hcrdt_avail <= 1'd0;
        end
      2'b0:
        begin
          s3_Dec_cpl_Hcrdt_avail <= 1'd0;
          s3_Dec_np_Hcrdt_avail <= 1'd0;
          s3_Dec_p_Hcrdt_avail <= 1'd1;
        end
      endcase
    end
    else begin
      s3_Dec_cpl_Hcrdt_avail <= 1'd0;
      s3_Dec_np_Hcrdt_avail <= 1'd0;
      s3_Dec_p_Hcrdt_avail <= 1'd0;
    end
  end
end // }

always @(posedge pld_clk)
begin
  if (~pld_rst_n) begin
    Dec_cpl_Hcrdt_avail[2:0] <= 3'd0;
    Dec_np_Hcrdt_avail[2:0] <= 3'd0;
    Dec_p_Hcrdt_avail[2:0] <= 3'd0;
  end
  else begin
    Dec_cpl_Hcrdt_avail[2:0] <= s3_Dec_cpl_Hcrdt_avail + s2_Dec_cpl_Hcrdt_avail + s1_Dec_cpl_Hcrdt_avail + s0_Dec_cpl_Hcrdt_avail;
    Dec_np_Hcrdt_avail[2:0]  <= s3_Dec_np_Hcrdt_avail  + s2_Dec_np_Hcrdt_avail  + s1_Dec_np_Hcrdt_avail  + s0_Dec_np_Hcrdt_avail;
    Dec_p_Hcrdt_avail[2:0]   <= s3_Dec_p_Hcrdt_avail   + s2_Dec_p_Hcrdt_avail   + s1_Dec_p_Hcrdt_avail   + s0_Dec_p_Hcrdt_avail;
  end
end
 


always @(posedge pld_clk)
begin
  if (~pld_rst_n) begin
    bcast_msg_s0_i <= 0;
    bcast_msg_s1_i <= 0;
    bcast_msg_s2_i <= 0;
    bcast_msg_s3_i <= 0;
  end
  else begin
    bcast_msg_s0_i <= bcast_msg_s0;
    bcast_msg_s1_i <= bcast_msg_s1;
    bcast_msg_s2_i <= bcast_msg_s2;
    bcast_msg_s3_i <= bcast_msg_s3;
  end
  end

  //--
always @(posedge pld_clk)
begin // {
    if (~pld_rst_n) begin // {
      
      tlp_decode_s0 <= 1'd0;
      tlp_active_s0 <= 1'd0;
      hit_active_s0_clr <= 1'd0;
      hit_active_s0_set <= 1'd0;
      
      tlp_decode_s1 <= 1'd0;
      tlp_active_s1 <= 1'd0;
      hit_active_s1_clr <= 1'd0;
      hit_active_s1_set <= 1'd0;
      
        tlp_decode_s2 <= 1'd0;
        tlp_active_s2 <= 1'd0;
        hit_active_s2_clr <= 1'd0;
        hit_active_s2_set <= 1'd0;
        
        tlp_decode_s3 <= 1'd0;
        tlp_active_s3 <= 1'd0;
        hit_active_s3_clr <= 1'd0;
        hit_active_s3_set <= 1'd0;
      
    end // }
    else begin // {
       //
       // S0 route
       case ({mem_addr_val_s0, func_num_val_s0})
       2'b11: // ERR
         begin // {
           tlp_decode_s0 <= 1'd1;
           hit_active_s0_set <= 1'd0;
           
           if (avst4to1_if_i_f.rx_st_eop_s0_o | avst4to1_if_i_f.rx_st_eop_s1_o | avst4to1_if_i_f.rx_st_eop_s2_o | avst4to1_if_i_f.rx_st_eop_s3_o) begin // {
             tlp_active_s0 <= 1'd0;
             hit_active_s0_clr <= 1'd1;
           end // }
           else begin // {
             tlp_active_s0 <= 1'd1;
             hit_active_s0_clr <= 1'd0;
           end // }
         end // }
           
       2'b10: // address decode
         begin // {
           tlp_decode_s0 <= 1'd1;
           
           if (avst4to1_if_i_f.rx_st_eop_s0_o | avst4to1_if_i_f.rx_st_eop_s1_o | avst4to1_if_i_f.rx_st_eop_s2_o | avst4to1_if_i_f.rx_st_eop_s3_o) begin // {
             tlp_active_s0 <= 1'd0;
             hit_active_s0_set <= 1'd0;
             hit_active_s0_clr <= 1'd1;
           end // }
           else begin // {
             tlp_active_s0 <= 1'd1;
             hit_active_s0_set <= 1'd1;
             hit_active_s0_clr <= 1'd0;
           end // }
// decode 64 bit bars
         end // }
       2'b01: // function decode
         begin // {
           tlp_decode_s0 <= 1'd1;
           
           if (avst4to1_if_i_f.rx_st_eop_s0_o | avst4to1_if_i_f.rx_st_eop_s1_o | avst4to1_if_i_f.rx_st_eop_s2_o | avst4to1_if_i_f.rx_st_eop_s3_o) begin // {
             tlp_active_s0 <= 1'd0;
             hit_active_s0_set <= 1'd0;
             hit_active_s0_clr <= 1'd1;
           end // }
           else begin // {
             tlp_active_s0 <= 1'd1;
             hit_active_s0_set <= 1'd1;
             hit_active_s0_clr <= 1'd0;
           end // }
           
         end // }
       2'b00: // no sop
         begin // {
           tlp_decode_s0 <= 1'd0;
           hit_active_s0_set <= 1'd0;
           
             if (avst4to1_if_i_f.rx_st_dvalid_s0_o & avst4to1_if_i_f.rx_st_eop_s0_o & tlp_active_s0) begin // {
               tlp_active_s0 <= 1'd0;
               hit_active_s0_clr <= 1'd1;
             end // }
             else begin // {
               if (avst4to1_if_i_f.rx_st_dvalid_s1_o & avst4to1_if_i_f.rx_st_eop_s1_o & tlp_active_s0) begin // {
                 tlp_active_s0 <= 1'd0;
                 hit_active_s0_clr <= 1'd1;
               end // }
               else begin // {
                 if (avst4to1_if_i_f.rx_st_dvalid_s2_o & avst4to1_if_i_f.rx_st_eop_s2_o & tlp_active_s0) begin // {
                   tlp_active_s0 <= 1'd0;
                   hit_active_s0_clr <= 1'd1;
                 end // }
                 else begin // {
                   if (avst4to1_if_i_f.rx_st_dvalid_s3_o & avst4to1_if_i_f.rx_st_eop_s3_o & tlp_active_s0) begin // {
                     tlp_active_s0 <= 1'd0;
                     hit_active_s0_clr <= 1'd1;
                   end // }
                   else begin // {
                     hit_active_s0_clr <= 1'd0;
                   end // }
                 end // }
               end // }
             end // }
         end // }
         endcase // case
       //
       // S1 route
       case ({mem_addr_val_s1, func_num_val_s1})
       2'b11: // ERR
         begin // {
           tlp_decode_s1 <= 1'd1;
           hit_active_s1_set <= 1'd0;
           
           if (avst4to1_if_i_f.rx_st_eop_s1_o | avst4to1_if_i_f.rx_st_eop_s2_o | avst4to1_if_i_f.rx_st_eop_s3_o) begin // {
             tlp_active_s1 <= 1'd0;
             hit_active_s1_clr <= 1'd1;
           end // }
           else begin // {
             tlp_active_s1 <= 1'd1;
             hit_active_s1_clr <= 1'd0;
           end // }
           
         end // }
       2'b10: // address decode
         begin // {
           tlp_decode_s1 <= 1'd1;
           
           if (avst4to1_if_i_f.rx_st_eop_s1_o | avst4to1_if_i_f.rx_st_eop_s2_o | avst4to1_if_i_f.rx_st_eop_s3_o) begin // {
             tlp_active_s1 <= 1'd0;
             hit_active_s1_set <= 1'd0;
             hit_active_s1_clr <= 1'd1;
           end // }
           else begin // {
             tlp_active_s1 <= 1'd1;
             hit_active_s1_set <= 1'd1;
             hit_active_s1_clr <= 1'd0;
           end // }
         end // }
       2'b01: // function decode
         begin // {
           tlp_decode_s1 <= 1'd1;
           
           
           if (avst4to1_if_i_f.rx_st_eop_s1_o | avst4to1_if_i_f.rx_st_eop_s2_o | avst4to1_if_i_f.rx_st_eop_s3_o) begin // {
             tlp_active_s1 <= 1'd0;
             hit_active_s1_set <= 1'd0;
             hit_active_s1_clr <= 1'd1;
           end // }
           else begin // {
             tlp_active_s1 <= 1'd1;
             hit_active_s1_set <= 1'd1;
             hit_active_s1_clr <= 1'd0;
           end // }
           
         end // }
       2'b00: // no sop
         begin // {
           tlp_decode_s1 <= 1'd0;
           hit_active_s1_set <= 1'd0;
           
             if (avst4to1_if_i_f.rx_st_dvalid_s1_o & avst4to1_if_i_f.rx_st_eop_s1_o & tlp_active_s1) begin // {
               tlp_active_s1 <= 1'd0;
               hit_active_s1_clr <= 1'd1;
             end // }
             else begin // {
               if (avst4to1_if_i_f.rx_st_dvalid_s2_o & avst4to1_if_i_f.rx_st_eop_s2_o & tlp_active_s1) begin // {
                 tlp_active_s1 <= 1'd0;
                 hit_active_s1_clr <= 1'd1;
               end // }
               else begin // {
                 if (avst4to1_if_i_f.rx_st_dvalid_s3_o & avst4to1_if_i_f.rx_st_eop_s3_o & tlp_active_s1) begin // {
                   tlp_active_s1 <= 1'd0;
                   hit_active_s1_clr <= 1'd1;
                 end // }
                 else begin // {
                   if (avst4to1_if_i_f.rx_st_dvalid_s0_o & avst4to1_if_i_f.rx_st_eop_s0_o & tlp_active_s1) begin // {
                     tlp_active_s1 <= 1'd0;
                     hit_active_s1_clr <= 1'd1;
                   end // }
                   else begin // {
                     hit_active_s1_clr <= 1'd0;
                   end // }
                 end // }
               end // }
             end // }
             end // }
         endcase // case
       //
       // S2 route
       case ({mem_addr_val_s2, func_num_val_s2})
       2'b11: // ERR
         begin // {
           tlp_decode_s2 <= 1'd1;
           hit_active_s2_set <= 1'd0;
           
           if (avst4to1_if_i_f.rx_st_eop_s2_o | avst4to1_if_i_f.rx_st_eop_s3_o) begin // {
             tlp_active_s2 <= 1'd0;
             hit_active_s2_clr <= 1'd1;
           end // }
           else begin // {
             tlp_active_s2 <= 1'd1;
             hit_active_s2_clr <= 1'd0;
           end // }
         end // }
       2'b10: // address decode
         begin // {
           tlp_decode_s2 <= 1'd1;
           
           if (avst4to1_if_i_f.rx_st_eop_s2_o | avst4to1_if_i_f.rx_st_eop_s3_o) begin // {
             tlp_active_s2 <= 1'd0;
             hit_active_s2_set <= 1'd0;
             hit_active_s2_clr <= 1'd1;
           end // }
           else begin // {
             tlp_active_s2 <= 1'd1;
             hit_active_s2_set <= 1'd1;
             hit_active_s2_clr <= 1'd0;
           end // }
         end // }
       2'b01: // function decode
         begin // {
           tlp_decode_s2 <= 1'd1;
           
           if (avst4to1_if_i_f.rx_st_eop_s2_o | avst4to1_if_i_f.rx_st_eop_s3_o) begin // {
             tlp_active_s2 <= 1'd0;
             hit_active_s2_set <= 1'd0;
             hit_active_s2_clr <= 1'd1;
           end // }
           else begin // {
             tlp_active_s2 <= 1'd1;
             hit_active_s2_set <= 1'd1;
             hit_active_s2_clr <= 1'd0;
           end // }
         end // }
       2'b00: // no sop
         begin // {
           tlp_decode_s2 <= 1'd0;
           hit_active_s2_set <= 1'd0;
           
             if (avst4to1_if_i_f.rx_st_dvalid_s2_o & avst4to1_if_i_f.rx_st_eop_s2_o & tlp_active_s2) begin // {
               tlp_active_s2 <= 1'd0;
               hit_active_s2_clr <= 1'd1;
             end // }
             else begin // {
               if (avst4to1_if_i_f.rx_st_dvalid_s3_o & avst4to1_if_i_f.rx_st_eop_s3_o & tlp_active_s2) begin // {
                 tlp_active_s2 <= 1'd0;
                 hit_active_s2_clr <= 1'd1;
               end // }
               else begin // {
                 if (avst4to1_if_i_f.rx_st_dvalid_s0_o & avst4to1_if_i_f.rx_st_eop_s0_o & tlp_active_s2) begin // {
                   tlp_active_s2 <= 1'd0;
                   hit_active_s2_clr <= 1'd1;
                 end // }
                 else begin // {
                   if (avst4to1_if_i_f.rx_st_dvalid_s1_o & avst4to1_if_i_f.rx_st_eop_s1_o & tlp_active_s2) begin // {
                     tlp_active_s2 <= 1'd0;
                     hit_active_s2_clr <= 1'd1;
                   end // }
                   else begin // {
                     hit_active_s2_clr <= 1'd0;
                   end // }
                 end // }
               end // }
             end // }
             end // }
         endcase // case
       //
       // S3 route
       case ({mem_addr_val_s3, func_num_val_s3})
       2'b11: // ERR
         begin // {
           tlp_decode_s3 <= 1'd1;
           hit_active_s3_set <= 1'd0;
           
           if (avst4to1_if_i_f.rx_st_eop_s3_o) begin // {
             tlp_active_s3 <= 1'd0;
             hit_active_s3_clr <= 1'd1;
           end // }
           else begin // {
             tlp_active_s3 <= 1'd1;
             hit_active_s3_clr <= 1'd0;
           end // }
         end // }
       2'b10: // address decode
         begin // {
           tlp_decode_s3 <= 1'd1;
           
           if (avst4to1_if_i_f.rx_st_eop_s3_o) begin // {
             tlp_active_s3 <= 1'd0;
             hit_active_s3_set <= 1'd0;
             hit_active_s3_clr <= 1'd1;
           end // }
           else begin // {
             tlp_active_s3 <= 1'd1;
             hit_active_s3_set <= 1'd1;
             hit_active_s3_clr <= 1'd0;
           end // }
         end // }
       2'b01: // function decode
         begin // {
           tlp_decode_s3 <= 1'd1;
           
           if (avst4to1_if_i_f.rx_st_eop_s3_o) begin // {
             tlp_active_s3 <= 1'd0;
             hit_active_s3_set <= 1'd0;
             hit_active_s3_clr <= 1'd1;
           end // }
           else begin // {
             tlp_active_s3 <= 1'd1;
             hit_active_s3_set <= 1'd1;
             hit_active_s3_clr <= 1'd0;
           end // }
         end // }
       2'b00: // no sop
         begin // {
           tlp_decode_s3 <= 1'd0;
           hit_active_s3_set <= 1'd0;
           
             if (avst4to1_if_i_f.rx_st_dvalid_s3_o & avst4to1_if_i_f.rx_st_eop_s3_o & tlp_active_s3) begin // {
               tlp_active_s3 <= 1'd0;
               hit_active_s3_clr <= 1'd1;
             end // }
             else begin // {
               if (avst4to1_if_i_f.rx_st_dvalid_s0_o & avst4to1_if_i_f.rx_st_eop_s0_o & tlp_active_s3) begin // {
                 tlp_active_s3 <= 1'd0;
                 hit_active_s3_clr <= 1'd1;
               end // }
               else begin // {
                 if (avst4to1_if_i_f.rx_st_dvalid_s1_o & avst4to1_if_i_f.rx_st_eop_s1_o & tlp_active_s3) begin // {
                   tlp_active_s3 <= 1'd0;
                   hit_active_s3_clr <= 1'd1;
                 end // }
                 else begin // {
                   if (avst4to1_if_i_f.rx_st_dvalid_s2_o & avst4to1_if_i_f.rx_st_eop_s2_o & tlp_active_s3) begin // {
                     tlp_active_s3 <= 1'd0;
                     hit_active_s3_clr <= 1'd1;
                   end // }
                   else begin // {
                     hit_active_s3_clr <= 1'd0;
                   end // }
                 end // }
               end // }
             end // }
             end // }
         endcase // }case
   end // } if-else
  end // }  // end-always


  //--

always @(posedge pld_clk)
begin
  if (~pld_rst_n) begin
    tlp_crd_type_s0_f[1:0] <= 2'd0;
    tlp_crd_type_s1_f[1:0] <= 2'd0;
    tlp_crd_type_s2_f[1:0] <= 2'd0;
    tlp_crd_type_s3_f[1:0] <= 2'd0;
  end
  else begin
  tlp_crd_type_s0_f[1:0] <= (avst4to1_if_i_f.rx_st_sop_s0_o & avst4to1_if_i_f.rx_st_hvalid_s0_o) ? tlp_crd_type_s0[1:0] : 
                            (tlp_active_s3 ? tlp_crd_type_s3_f[1:0] : 
                            (tlp_active_s2 ? tlp_crd_type_s2_f[1:0] :
                            (tlp_active_s1 ? tlp_crd_type_s1_f[1:0] : tlp_crd_type_s0_f[1:0])));
  tlp_crd_type_s1_f[1:0] <= (avst4to1_if_i_f.rx_st_sop_s1_o & avst4to1_if_i_f.rx_st_hvalid_s1_o) ? tlp_crd_type_s1[1:0] : 
                            (avst4to1_if_i_f.rx_st_sop_s0_o & avst4to1_if_i_f.rx_st_hvalid_s0_o) ? tlp_crd_type_s0[1:0] :
                            (tlp_active_s3) ? tlp_crd_type_s3_f[1:0] : 
                            (tlp_active_s2) ? tlp_crd_type_s2_f[1:0] : 
                            (tlp_active_s1) ? tlp_crd_type_s1_f[1:0] : 
                            (tlp_active_s0) ? tlp_crd_type_s0_f[1:0] : tlp_crd_type_s1_f[1:0];
  tlp_crd_type_s2_f[1:0] <= (avst4to1_if_i_f.rx_st_sop_s2_o & avst4to1_if_i_f.rx_st_hvalid_s2_o) ? tlp_crd_type_s2[1:0] : 
                            (avst4to1_if_i_f.rx_st_sop_s1_o & avst4to1_if_i_f.rx_st_hvalid_s1_o) ? tlp_crd_type_s1[1:0] : 
                            (avst4to1_if_i_f.rx_st_sop_s0_o & avst4to1_if_i_f.rx_st_hvalid_s0_o) ? tlp_crd_type_s0[1:0] : 
                            (tlp_active_s3) ? tlp_crd_type_s3_f[1:0] :
                            (tlp_active_s2) ? tlp_crd_type_s2_f[1:0] : 
                            (tlp_active_s1) ? tlp_crd_type_s1_f[1:0] : 
                            (tlp_active_s0) ? tlp_crd_type_s0_f[1:0] : tlp_crd_type_s2_f[1:0];
  tlp_crd_type_s3_f[1:0] <= (avst4to1_if_i_f.rx_st_sop_s3_o & avst4to1_if_i_f.rx_st_hvalid_s3_o) ? tlp_crd_type_s3[1:0] : 
                            (avst4to1_if_i_f.rx_st_sop_s2_o & avst4to1_if_i_f.rx_st_hvalid_s2_o) ? tlp_crd_type_s2[1:0] : 
                            (avst4to1_if_i_f.rx_st_sop_s1_o & avst4to1_if_i_f.rx_st_hvalid_s1_o) ? tlp_crd_type_s1[1:0] : 
                            (avst4to1_if_i_f.rx_st_sop_s0_o & avst4to1_if_i_f.rx_st_hvalid_s0_o) ? tlp_crd_type_s0[1:0] :
                            (tlp_active_s3) ? tlp_crd_type_s3_f[1:0] :                            
                            (tlp_active_s2) ? tlp_crd_type_s2_f[1:0] : 
                            (tlp_active_s1) ? tlp_crd_type_s1_f[1:0] : 
                            (tlp_active_s0) ? tlp_crd_type_s0_f[1:0] : tlp_crd_type_s3_f[1:0];
  end
end

always @(posedge pld_clk)
begin // {
  // flopping 3rd time
  // S0
  avst4to1_if_i_ff.rx_st_hdr_s0_o          <= avst4to1_if_i_f.rx_st_hdr_s0_o;
  avst4to1_if_i_ff.rx_st_hdr_par_s0_o      <= avst4to1_if_i_f.rx_st_hdr_par_s0_o;
  avst4to1_if_i_ff.rx_st_tlp_prfx_s0_o     <= avst4to1_if_i_f.rx_st_tlp_prfx_s0_o;
  avst4to1_if_i_ff.rx_st_tlp_prfx_par_s0_o <= avst4to1_if_i_f.rx_st_tlp_prfx_par_s0_o;
  
  avst4to1_if_i_ff.rx_st_sop_s0_o          <= avst4to1_if_i_f.rx_st_sop_s0_o;
  avst4to1_if_i_ff.rx_st_eop_s0_o          <= avst4to1_if_i_f.rx_st_eop_s0_o;
  
  avst4to1_if_i_ff.rx_st_data_s0_o         <= avst4to1_if_i_f.rx_st_data_s0_o;
  avst4to1_if_i_ff.rx_st_data_par_s0_o     <= avst4to1_if_i_f.rx_st_data_par_s0_o;
  
  avst4to1_if_i_ff.rx_st_empty_s0_o        <= avst4to1_if_i_f.rx_st_empty_s0_o;

    avst4to1_if_i_ff.rx_st_tlp_RSSAI_prfx_s0_o     <= avst4to1_if_i_f.rx_st_tlp_RSSAI_prfx_s0_o;
    avst4to1_if_i_ff.rx_st_tlp_RSSAI_prfx_par_s0_o <= avst4to1_if_i_f.rx_st_tlp_RSSAI_prfx_par_s0_o;
    avst4to1_if_i_ff.rx_st_passthrough_s0_o <= avst4to1_if_i_f.rx_st_passthrough_s0_o;
  
  avst4to1_if_i_ff.rx_st_vfactive_s0_o     <= avst4to1_if_i_f.rx_st_vfactive_s0_o;
  avst4to1_if_i_ff.rx_st_vfnum_s0_o        <= avst4to1_if_i_f.rx_st_vfnum_s0_o;
  avst4to1_if_i_ff.rx_st_pfnum_s0_o        <= avst4to1_if_i_f.rx_st_pfnum_s0_o;
  avst4to1_if_i_ff.rx_st_bar_s0_o          <= avst4to1_if_i_f.rx_st_bar_s0_o;
  
  avst4to1_if_i_ff.rx_st_dvalid_s0_o       <= avst4to1_if_i_f.rx_st_dvalid_s0_o;
  avst4to1_if_i_ff.rx_st_hvalid_s0_o       <= avst4to1_if_i_f.rx_st_hvalid_s0_o;
  avst4to1_if_i_ff.rx_st_pvalid_s0_o       <= avst4to1_if_i_f.rx_st_pvalid_s0_o;
  // S1
  avst4to1_if_i_ff.rx_st_hdr_s1_o          <= avst4to1_if_i_f.rx_st_hdr_s1_o;
  avst4to1_if_i_ff.rx_st_hdr_par_s1_o      <= avst4to1_if_i_f.rx_st_hdr_par_s1_o;
  avst4to1_if_i_ff.rx_st_tlp_prfx_s1_o     <= avst4to1_if_i_f.rx_st_tlp_prfx_s1_o;
  avst4to1_if_i_ff.rx_st_tlp_prfx_par_s1_o <= avst4to1_if_i_f.rx_st_tlp_prfx_par_s1_o;
  
  avst4to1_if_i_ff.rx_st_sop_s1_o          <= avst4to1_if_i_f.rx_st_sop_s1_o;
  avst4to1_if_i_ff.rx_st_eop_s1_o          <= avst4to1_if_i_f.rx_st_eop_s1_o;
  
  avst4to1_if_i_ff.rx_st_data_s1_o         <= avst4to1_if_i_f.rx_st_data_s1_o;
  avst4to1_if_i_ff.rx_st_data_par_s1_o     <= avst4to1_if_i_f.rx_st_data_par_s1_o;
  
  avst4to1_if_i_ff.rx_st_empty_s1_o        <= avst4to1_if_i_f.rx_st_empty_s1_o;
  
    avst4to1_if_i_ff.rx_st_tlp_RSSAI_prfx_s1_o     <= avst4to1_if_i_f.rx_st_tlp_RSSAI_prfx_s1_o;
    avst4to1_if_i_ff.rx_st_tlp_RSSAI_prfx_par_s1_o <= avst4to1_if_i_f.rx_st_tlp_RSSAI_prfx_par_s1_o;
    avst4to1_if_i_ff.rx_st_passthrough_s1_o <= avst4to1_if_i_f.rx_st_passthrough_s1_o;

  avst4to1_if_i_ff.rx_st_vfactive_s1_o     <= avst4to1_if_i_f.rx_st_vfactive_s1_o;
  avst4to1_if_i_ff.rx_st_vfnum_s1_o        <= avst4to1_if_i_f.rx_st_vfnum_s1_o;
  avst4to1_if_i_ff.rx_st_pfnum_s1_o        <= avst4to1_if_i_f.rx_st_pfnum_s1_o;
  avst4to1_if_i_ff.rx_st_bar_s1_o          <= avst4to1_if_i_f.rx_st_bar_s1_o;
  
  avst4to1_if_i_ff.rx_st_dvalid_s1_o       <= avst4to1_if_i_f.rx_st_dvalid_s1_o;
  avst4to1_if_i_ff.rx_st_hvalid_s1_o       <= avst4to1_if_i_f.rx_st_hvalid_s1_o;
  avst4to1_if_i_ff.rx_st_pvalid_s1_o       <= avst4to1_if_i_f.rx_st_pvalid_s1_o;

  // S2
  avst4to1_if_i_ff.rx_st_hdr_s2_o          <= avst4to1_if_i_f.rx_st_hdr_s2_o;
  avst4to1_if_i_ff.rx_st_hdr_par_s2_o      <= avst4to1_if_i_f.rx_st_hdr_par_s2_o;
  avst4to1_if_i_ff.rx_st_tlp_prfx_s2_o     <= avst4to1_if_i_f.rx_st_tlp_prfx_s2_o;
  avst4to1_if_i_ff.rx_st_tlp_prfx_par_s2_o <= avst4to1_if_i_f.rx_st_tlp_prfx_par_s2_o;
    avst4to1_if_i_ff.rx_st_tlp_RSSAI_prfx_s2_o     <= avst4to1_if_i_f.rx_st_tlp_RSSAI_prfx_s2_o;
    avst4to1_if_i_ff.rx_st_tlp_RSSAI_prfx_par_s2_o <= avst4to1_if_i_f.rx_st_tlp_RSSAI_prfx_par_s2_o;
    avst4to1_if_i_ff.rx_st_passthrough_s2_o <= avst4to1_if_i_f.rx_st_passthrough_s2_o;
  
  avst4to1_if_i_ff.rx_st_vfactive_s2_o     <= avst4to1_if_i_f.rx_st_vfactive_s2_o;
  avst4to1_if_i_ff.rx_st_vfnum_s2_o        <= avst4to1_if_i_f.rx_st_vfnum_s2_o;
  avst4to1_if_i_ff.rx_st_pfnum_s2_o        <= avst4to1_if_i_f.rx_st_pfnum_s2_o;
  avst4to1_if_i_ff.rx_st_bar_s2_o          <= avst4to1_if_i_f.rx_st_bar_s2_o;
  
  avst4to1_if_i_ff.rx_st_sop_s2_o          <= avst4to1_if_i_f.rx_st_sop_s2_o;
  avst4to1_if_i_ff.rx_st_eop_s2_o          <= avst4to1_if_i_f.rx_st_eop_s2_o;
  
  avst4to1_if_i_ff.rx_st_data_s2_o         <= avst4to1_if_i_f.rx_st_data_s2_o;
  avst4to1_if_i_ff.rx_st_data_par_s2_o     <= avst4to1_if_i_f.rx_st_data_par_s2_o;
  
  avst4to1_if_i_ff.rx_st_empty_s2_o        <= avst4to1_if_i_f.rx_st_empty_s2_o;
  
  avst4to1_if_i_ff.rx_st_dvalid_s2_o       <= avst4to1_if_i_f.rx_st_dvalid_s2_o;
  avst4to1_if_i_ff.rx_st_hvalid_s2_o       <= avst4to1_if_i_f.rx_st_hvalid_s2_o;
  avst4to1_if_i_ff.rx_st_pvalid_s2_o       <= avst4to1_if_i_f.rx_st_pvalid_s2_o;
  // S3
  avst4to1_if_i_ff.rx_st_hdr_s3_o          <= avst4to1_if_i_f.rx_st_hdr_s3_o;
  avst4to1_if_i_ff.rx_st_hdr_par_s3_o      <= avst4to1_if_i_f.rx_st_hdr_par_s3_o;
  avst4to1_if_i_ff.rx_st_tlp_prfx_s3_o     <= avst4to1_if_i_f.rx_st_tlp_prfx_s3_o;
  avst4to1_if_i_ff.rx_st_tlp_prfx_par_s3_o <= avst4to1_if_i_f.rx_st_tlp_prfx_par_s3_o;
    avst4to1_if_i_ff.rx_st_tlp_RSSAI_prfx_s3_o     <= avst4to1_if_i_f.rx_st_tlp_RSSAI_prfx_s3_o;
    avst4to1_if_i_ff.rx_st_tlp_RSSAI_prfx_par_s3_o <= avst4to1_if_i_f.rx_st_tlp_RSSAI_prfx_par_s3_o;
    avst4to1_if_i_ff.rx_st_passthrough_s3_o <= avst4to1_if_i_f.rx_st_passthrough_s3_o;
  
  avst4to1_if_i_ff.rx_st_vfactive_s3_o     <= avst4to1_if_i_f.rx_st_vfactive_s3_o;
  avst4to1_if_i_ff.rx_st_vfnum_s3_o        <= avst4to1_if_i_f.rx_st_vfnum_s3_o;
  avst4to1_if_i_ff.rx_st_pfnum_s3_o        <= avst4to1_if_i_f.rx_st_pfnum_s3_o;
  avst4to1_if_i_ff.rx_st_bar_s3_o          <= avst4to1_if_i_f.rx_st_bar_s3_o;
  
  avst4to1_if_i_ff.rx_st_sop_s3_o          <= avst4to1_if_i_f.rx_st_sop_s3_o;
  avst4to1_if_i_ff.rx_st_eop_s3_o          <= avst4to1_if_i_f.rx_st_eop_s3_o;
  
  avst4to1_if_i_ff.rx_st_data_s3_o         <= avst4to1_if_i_f.rx_st_data_s3_o;
  avst4to1_if_i_ff.rx_st_data_par_s3_o     <= avst4to1_if_i_f.rx_st_data_par_s3_o;
  
  avst4to1_if_i_ff.rx_st_empty_s3_o        <= avst4to1_if_i_f.rx_st_empty_s3_o;
  
  avst4to1_if_i_ff.rx_st_dvalid_s3_o       <= avst4to1_if_i_f.rx_st_dvalid_s3_o;
  avst4to1_if_i_ff.rx_st_hvalid_s3_o       <= avst4to1_if_i_f.rx_st_hvalid_s3_o;
  avst4to1_if_i_ff.rx_st_pvalid_s3_o       <= avst4to1_if_i_f.rx_st_pvalid_s3_o;
end // }
//
// extra flop
//


always @(posedge pld_clk)
begin
  bcast_msg_s0_f  <= bcast_msg_s0_i;
  bcast_msg_s1_f  <= bcast_msg_s1_i;
  
  tlp_decode_s0_f <= tlp_decode_s0;
  tlp_active_s0_f <= tlp_active_s0;
  
  tlp_decode_s1_f <= tlp_decode_s1;
  tlp_active_s1_f <= tlp_active_s1;
  
  bcast_msg_s2_f  <= bcast_msg_s2_i;
  bcast_msg_s3_f  <= bcast_msg_s3_i;
  
  tlp_decode_s2_f <= tlp_decode_s2;
  tlp_active_s2_f <= tlp_active_s2;
  
  tlp_decode_s3_f <= tlp_decode_s3;
  tlp_active_s3_f <= tlp_active_s3;

end

always @(posedge pld_clk) 
begin // {
  tlp_crd_type_s0_ff[1:0]              <= tlp_crd_type_s0_f[1:0];
  tlp_crd_type_s1_ff[1:0]              <= tlp_crd_type_s1_f[1:0];
  tlp_crd_type_s2_ff[1:0]              <= tlp_crd_type_s2_f[1:0];
  tlp_crd_type_s3_ff[1:0]              <= tlp_crd_type_s3_f[1:0];
  // S0
  avst4to1_if_i_fff.rx_st_hdr_s0_o          <= avst4to1_if_i_ff.rx_st_hdr_s0_o;
  avst4to1_if_i_fff.rx_st_hdr_par_s0_o      <= avst4to1_if_i_ff.rx_st_hdr_par_s0_o;
  avst4to1_if_i_fff.rx_st_tlp_prfx_s0_o     <= avst4to1_if_i_ff.rx_st_tlp_prfx_s0_o;
  avst4to1_if_i_fff.rx_st_tlp_prfx_par_s0_o <= avst4to1_if_i_ff.rx_st_tlp_prfx_par_s0_o;
  
  avst4to1_if_i_fff.rx_st_sop_s0_o          <= avst4to1_if_i_ff.rx_st_sop_s0_o;
  avst4to1_if_i_fff.rx_st_eop_s0_o          <= avst4to1_if_i_ff.rx_st_eop_s0_o;
  
  avst4to1_if_i_fff.rx_st_data_s0_o         <= avst4to1_if_i_ff.rx_st_data_s0_o;
  avst4to1_if_i_fff.rx_st_data_par_s0_o     <= avst4to1_if_i_ff.rx_st_data_par_s0_o;
  
  avst4to1_if_i_fff.rx_st_empty_s0_o        <= avst4to1_if_i_ff.rx_st_empty_s0_o;
  
    avst4to1_if_i_fff.rx_st_tlp_RSSAI_prfx_s0_o     <= avst4to1_if_i_ff.rx_st_tlp_RSSAI_prfx_s0_o;
    avst4to1_if_i_fff.rx_st_tlp_RSSAI_prfx_par_s0_o <= avst4to1_if_i_ff.rx_st_tlp_RSSAI_prfx_par_s0_o;
    avst4to1_if_i_fff.rx_st_passthrough_s0_o <= avst4to1_if_i_ff.rx_st_passthrough_s0_o;
  
  avst4to1_if_i_fff.rx_st_vfactive_s0_o     <= avst4to1_if_i_ff.rx_st_vfactive_s0_o;
  avst4to1_if_i_fff.rx_st_vfnum_s0_o        <= avst4to1_if_i_ff.rx_st_vfnum_s0_o;
  avst4to1_if_i_fff.rx_st_pfnum_s0_o        <= avst4to1_if_i_ff.rx_st_pfnum_s0_o;
  avst4to1_if_i_fff.rx_st_bar_s0_o          <= avst4to1_if_i_ff.rx_st_bar_s0_o;
  
  avst4to1_if_i_fff.rx_st_dvalid_s0_o       <= avst4to1_if_i_ff.rx_st_dvalid_s0_o;
  avst4to1_if_i_fff.rx_st_hvalid_s0_o       <= avst4to1_if_i_ff.rx_st_hvalid_s0_o;
  avst4to1_if_i_fff.rx_st_pvalid_s0_o       <= avst4to1_if_i_ff.rx_st_pvalid_s0_o;
  // S1
  avst4to1_if_i_fff.rx_st_hdr_s1_o          <= avst4to1_if_i_ff.rx_st_hdr_s1_o;
  avst4to1_if_i_fff.rx_st_hdr_par_s1_o      <= avst4to1_if_i_ff.rx_st_hdr_par_s1_o;
  avst4to1_if_i_fff.rx_st_tlp_prfx_s1_o     <= avst4to1_if_i_ff.rx_st_tlp_prfx_s1_o;
  avst4to1_if_i_fff.rx_st_tlp_prfx_par_s1_o <= avst4to1_if_i_ff.rx_st_tlp_prfx_par_s1_o;
  
  avst4to1_if_i_fff.rx_st_sop_s1_o          <= avst4to1_if_i_ff.rx_st_sop_s1_o;
  avst4to1_if_i_fff.rx_st_eop_s1_o          <= avst4to1_if_i_ff.rx_st_eop_s1_o;
  
  avst4to1_if_i_fff.rx_st_data_s1_o         <= avst4to1_if_i_ff.rx_st_data_s1_o;
  avst4to1_if_i_fff.rx_st_data_par_s1_o     <= avst4to1_if_i_ff.rx_st_data_par_s1_o;
  
  avst4to1_if_i_fff.rx_st_empty_s1_o        <= avst4to1_if_i_ff.rx_st_empty_s1_o;
  
    avst4to1_if_i_fff.rx_st_tlp_RSSAI_prfx_s1_o     <= avst4to1_if_i_ff.rx_st_tlp_RSSAI_prfx_s1_o;
    avst4to1_if_i_fff.rx_st_tlp_RSSAI_prfx_par_s1_o <= avst4to1_if_i_ff.rx_st_tlp_RSSAI_prfx_par_s1_o;
    avst4to1_if_i_fff.rx_st_passthrough_s1_o <= avst4to1_if_i_ff.rx_st_passthrough_s1_o;

  avst4to1_if_i_fff.rx_st_vfactive_s1_o     <= avst4to1_if_i_ff.rx_st_vfactive_s1_o;
  avst4to1_if_i_fff.rx_st_vfnum_s1_o        <= avst4to1_if_i_ff.rx_st_vfnum_s1_o;
  avst4to1_if_i_fff.rx_st_pfnum_s1_o        <= avst4to1_if_i_ff.rx_st_pfnum_s1_o;
  avst4to1_if_i_fff.rx_st_bar_s1_o          <= avst4to1_if_i_ff.rx_st_bar_s1_o;
  
  avst4to1_if_i_fff.rx_st_dvalid_s1_o       <= avst4to1_if_i_ff.rx_st_dvalid_s1_o;
  avst4to1_if_i_fff.rx_st_hvalid_s1_o       <= avst4to1_if_i_ff.rx_st_hvalid_s1_o;
  avst4to1_if_i_fff.rx_st_pvalid_s1_o       <= avst4to1_if_i_ff.rx_st_pvalid_s1_o;

  // S2
  avst4to1_if_i_fff.rx_st_hdr_s2_o          <= avst4to1_if_i_ff.rx_st_hdr_s2_o;
  avst4to1_if_i_fff.rx_st_hdr_par_s2_o      <= avst4to1_if_i_ff.rx_st_hdr_par_s2_o;
  avst4to1_if_i_fff.rx_st_tlp_prfx_s2_o     <= avst4to1_if_i_ff.rx_st_tlp_prfx_s2_o;
  avst4to1_if_i_fff.rx_st_tlp_prfx_par_s2_o <= avst4to1_if_i_ff.rx_st_tlp_prfx_par_s2_o;
    avst4to1_if_i_fff.rx_st_tlp_RSSAI_prfx_s2_o     <= avst4to1_if_i_ff.rx_st_tlp_RSSAI_prfx_s2_o;
    avst4to1_if_i_fff.rx_st_tlp_RSSAI_prfx_par_s2_o <= avst4to1_if_i_ff.rx_st_tlp_RSSAI_prfx_par_s2_o;
    avst4to1_if_i_fff.rx_st_passthrough_s2_o <= avst4to1_if_i_ff.rx_st_passthrough_s2_o;
  
  avst4to1_if_i_fff.rx_st_vfactive_s2_o     <= avst4to1_if_i_ff.rx_st_vfactive_s2_o;
  avst4to1_if_i_fff.rx_st_vfnum_s2_o        <= avst4to1_if_i_ff.rx_st_vfnum_s2_o;
  avst4to1_if_i_fff.rx_st_pfnum_s2_o        <= avst4to1_if_i_ff.rx_st_pfnum_s2_o;
  avst4to1_if_i_fff.rx_st_bar_s2_o          <= avst4to1_if_i_ff.rx_st_bar_s2_o;
  
  avst4to1_if_i_fff.rx_st_sop_s2_o          <= avst4to1_if_i_ff.rx_st_sop_s2_o;
  avst4to1_if_i_fff.rx_st_eop_s2_o          <= avst4to1_if_i_ff.rx_st_eop_s2_o;
  
  avst4to1_if_i_fff.rx_st_data_s2_o         <= avst4to1_if_i_ff.rx_st_data_s2_o;
  avst4to1_if_i_fff.rx_st_data_par_s2_o     <= avst4to1_if_i_ff.rx_st_data_par_s2_o;
  
  avst4to1_if_i_fff.rx_st_empty_s2_o        <= avst4to1_if_i_ff.rx_st_empty_s2_o;
  
  avst4to1_if_i_fff.rx_st_dvalid_s2_o       <= avst4to1_if_i_ff.rx_st_dvalid_s2_o;
  avst4to1_if_i_fff.rx_st_hvalid_s2_o       <= avst4to1_if_i_ff.rx_st_hvalid_s2_o;
  avst4to1_if_i_fff.rx_st_pvalid_s2_o       <= avst4to1_if_i_ff.rx_st_pvalid_s2_o;
  // S3
  avst4to1_if_i_fff.rx_st_hdr_s3_o          <= avst4to1_if_i_ff.rx_st_hdr_s3_o;
  avst4to1_if_i_fff.rx_st_hdr_par_s3_o      <= avst4to1_if_i_ff.rx_st_hdr_par_s3_o;
  avst4to1_if_i_fff.rx_st_tlp_prfx_s3_o     <= avst4to1_if_i_ff.rx_st_tlp_prfx_s3_o;
  avst4to1_if_i_fff.rx_st_tlp_prfx_par_s3_o <= avst4to1_if_i_ff.rx_st_tlp_prfx_par_s3_o;
    avst4to1_if_i_fff.rx_st_tlp_RSSAI_prfx_s3_o     <= avst4to1_if_i_ff.rx_st_tlp_RSSAI_prfx_s3_o;
    avst4to1_if_i_fff.rx_st_tlp_RSSAI_prfx_par_s3_o <= avst4to1_if_i_ff.rx_st_tlp_RSSAI_prfx_par_s3_o;
    avst4to1_if_i_fff.rx_st_passthrough_s3_o <= avst4to1_if_i_ff.rx_st_passthrough_s3_o;
  
  avst4to1_if_i_fff.rx_st_vfactive_s3_o     <= avst4to1_if_i_ff.rx_st_vfactive_s3_o;
  avst4to1_if_i_fff.rx_st_vfnum_s3_o        <= avst4to1_if_i_ff.rx_st_vfnum_s3_o;
  avst4to1_if_i_fff.rx_st_pfnum_s3_o        <= avst4to1_if_i_ff.rx_st_pfnum_s3_o;
  avst4to1_if_i_fff.rx_st_bar_s3_o          <= avst4to1_if_i_ff.rx_st_bar_s3_o;
  
  avst4to1_if_i_fff.rx_st_sop_s3_o          <= avst4to1_if_i_ff.rx_st_sop_s3_o;
  avst4to1_if_i_fff.rx_st_eop_s3_o          <= avst4to1_if_i_ff.rx_st_eop_s3_o;
  
  avst4to1_if_i_fff.rx_st_data_s3_o         <= avst4to1_if_i_ff.rx_st_data_s3_o;
  avst4to1_if_i_fff.rx_st_data_par_s3_o     <= avst4to1_if_i_ff.rx_st_data_par_s3_o;
  
  avst4to1_if_i_fff.rx_st_empty_s3_o        <= avst4to1_if_i_ff.rx_st_empty_s3_o;
  
  avst4to1_if_i_fff.rx_st_dvalid_s3_o       <= avst4to1_if_i_ff.rx_st_dvalid_s3_o;
  avst4to1_if_i_fff.rx_st_hvalid_s3_o       <= avst4to1_if_i_ff.rx_st_hvalid_s3_o;
  avst4to1_if_i_fff.rx_st_pvalid_s3_o       <= avst4to1_if_i_ff.rx_st_pvalid_s3_o;

end //}


assign s0_select_core[0] = 'd1;
assign s1_select_core[0] = 'd1;
assign s2_select_core[0] = 'd1;
assign s3_select_core[0] = 'd1;


always @(posedge pld_clk)
begin
  if (~pld_rst_n) begin
    bcast_msg_s0_ff  <= 1'b0;
    bcast_msg_s1_ff  <= 1'b0;
    
    hit_active_s0_f <= 1'b0;
    hit_active_s1_f <= 1'b0;
    
    tlp_crd_type_s0_fff[1:0] <= 2'd3;
    tlp_crd_type_s1_fff[1:0] <= 2'd3;
    
    bcast_msg_s2_ff  <= 1'b0;
    bcast_msg_s3_ff  <= 1'b0;
    
    hit_active_s2_f <= 1'b0;
    hit_active_s3_f <= 1'b0;
    
    tlp_crd_type_s2_fff[1:0] <= 2'd3;
    tlp_crd_type_s3_fff[1:0] <= 2'd3;
  end
  else begin
    hit_active_s0_f <= hit_active_s0;
    hit_active_s1_f <= hit_active_s1;
    
    tlp_crd_type_s0_fff[1:0] <= tlp_crd_type_s0_ff[1:0];
    tlp_crd_type_s1_fff[1:0] <= tlp_crd_type_s1_ff[1:0];
    
    if (avst4to1_if_i_fff.rx_st_sop_s0_o | avst4to1_if_i_fff.rx_st_sop_s1_o | avst4to1_if_i_fff.rx_st_sop_s2_o | avst4to1_if_i_fff.rx_st_sop_s3_o) begin
      bcast_msg_s0_ff <= bcast_msg_s0_f;
      bcast_msg_s1_ff <= bcast_msg_s1_f;
      bcast_msg_s2_ff <= bcast_msg_s2_f;
      bcast_msg_s3_ff <= bcast_msg_s3_f;
    end
    
    hit_active_s2_f <= hit_active_s2;
    hit_active_s3_f <= hit_active_s3;
    
    tlp_crd_type_s2_fff[1:0] <= tlp_crd_type_s2_ff[1:0];
    tlp_crd_type_s3_fff[1:0] <= tlp_crd_type_s3_ff[1:0];
  end
end

always @(posedge pld_clk)
begin // {
  // S0
  avst4to1_if_i_ffff.rx_st_hdr_s0_o          <= avst4to1_if_i_fff.rx_st_hdr_s0_o;
  avst4to1_if_i_ffff.rx_st_hdr_par_s0_o      <= avst4to1_if_i_fff.rx_st_hdr_par_s0_o;
  avst4to1_if_i_ffff.rx_st_tlp_prfx_s0_o     <= avst4to1_if_i_fff.rx_st_tlp_prfx_s0_o;
  avst4to1_if_i_ffff.rx_st_tlp_prfx_par_s0_o <= avst4to1_if_i_fff.rx_st_tlp_prfx_par_s0_o;
  
  avst4to1_if_i_ffff.rx_st_sop_s0_o          <= avst4to1_if_i_fff.rx_st_sop_s0_o;
  avst4to1_if_i_ffff.rx_st_eop_s0_o          <= avst4to1_if_i_fff.rx_st_eop_s0_o;
  
  avst4to1_if_i_ffff.rx_st_data_s0_o         <= avst4to1_if_i_fff.rx_st_data_s0_o;
  avst4to1_if_i_ffff.rx_st_data_par_s0_o     <= avst4to1_if_i_fff.rx_st_data_par_s0_o;
  
  avst4to1_if_i_ffff.rx_st_empty_s0_o        <= avst4to1_if_i_fff.rx_st_empty_s0_o;
  
    avst4to1_if_i_ffff.rx_st_tlp_RSSAI_prfx_s0_o     <= avst4to1_if_i_fff.rx_st_tlp_RSSAI_prfx_s0_o;
    avst4to1_if_i_ffff.rx_st_tlp_RSSAI_prfx_par_s0_o <= avst4to1_if_i_fff.rx_st_tlp_RSSAI_prfx_par_s0_o;
    avst4to1_if_i_ffff.rx_st_passthrough_s0_o <= avst4to1_if_i_fff.rx_st_passthrough_s0_o;
  
  avst4to1_if_i_ffff.rx_st_vfactive_s0_o     <= avst4to1_if_i_fff.rx_st_vfactive_s0_o;
  avst4to1_if_i_ffff.rx_st_vfnum_s0_o        <= avst4to1_if_i_fff.rx_st_vfnum_s0_o;
  avst4to1_if_i_ffff.rx_st_pfnum_s0_o        <= avst4to1_if_i_fff.rx_st_pfnum_s0_o;
  avst4to1_if_i_ffff.rx_st_bar_s0_o          <= avst4to1_if_i_fff.rx_st_bar_s0_o;

  avst4to1_if_i_ffff.rx_st_dvalid_s0_o        <= avst4to1_if_i_fff.rx_st_dvalid_s0_o;
  avst4to1_if_i_ffff.rx_st_hvalid_s0_o        <= avst4to1_if_i_fff.rx_st_hvalid_s0_o;
  avst4to1_if_i_ffff.rx_st_pvalid_s0_o        <= avst4to1_if_i_fff.rx_st_pvalid_s0_o;
  // S1
  avst4to1_if_i_ffff.rx_st_hdr_s1_o          <= avst4to1_if_i_fff.rx_st_hdr_s1_o;
  avst4to1_if_i_ffff.rx_st_hdr_par_s1_o      <= avst4to1_if_i_fff.rx_st_hdr_par_s1_o;
  avst4to1_if_i_ffff.rx_st_tlp_prfx_s1_o     <= avst4to1_if_i_fff.rx_st_tlp_prfx_s1_o;
  avst4to1_if_i_ffff.rx_st_tlp_prfx_par_s1_o <= avst4to1_if_i_fff.rx_st_tlp_prfx_par_s1_o;
  
  avst4to1_if_i_ffff.rx_st_sop_s1_o          <= avst4to1_if_i_fff.rx_st_sop_s1_o;
  avst4to1_if_i_ffff.rx_st_eop_s1_o          <= avst4to1_if_i_fff.rx_st_eop_s1_o;
  
  avst4to1_if_i_ffff.rx_st_data_s1_o         <= avst4to1_if_i_fff.rx_st_data_s1_o;
  avst4to1_if_i_ffff.rx_st_data_par_s1_o     <= avst4to1_if_i_fff.rx_st_data_par_s1_o;
  
  avst4to1_if_i_ffff.rx_st_empty_s1_o        <= avst4to1_if_i_fff.rx_st_empty_s1_o;
  
    avst4to1_if_i_ffff.rx_st_tlp_RSSAI_prfx_s1_o     <= avst4to1_if_i_fff.rx_st_tlp_RSSAI_prfx_s1_o;
    avst4to1_if_i_ffff.rx_st_tlp_RSSAI_prfx_par_s1_o <= avst4to1_if_i_fff.rx_st_tlp_RSSAI_prfx_par_s1_o;
    avst4to1_if_i_ffff.rx_st_passthrough_s1_o <= avst4to1_if_i_fff.rx_st_passthrough_s1_o;
  
  avst4to1_if_i_ffff.rx_st_vfactive_s1_o     <= avst4to1_if_i_fff.rx_st_vfactive_s1_o;
  avst4to1_if_i_ffff.rx_st_vfnum_s1_o        <= avst4to1_if_i_fff.rx_st_vfnum_s1_o;
  avst4to1_if_i_ffff.rx_st_pfnum_s1_o        <= avst4to1_if_i_fff.rx_st_pfnum_s1_o;
  avst4to1_if_i_ffff.rx_st_bar_s1_o          <= avst4to1_if_i_fff.rx_st_bar_s1_o;

  avst4to1_if_i_ffff.rx_st_dvalid_s1_o        <= avst4to1_if_i_fff.rx_st_dvalid_s1_o;
  avst4to1_if_i_ffff.rx_st_hvalid_s1_o        <= avst4to1_if_i_fff.rx_st_hvalid_s1_o;
  avst4to1_if_i_ffff.rx_st_pvalid_s1_o        <= avst4to1_if_i_fff.rx_st_pvalid_s1_o;

  // S2
  avst4to1_if_i_ffff.rx_st_hdr_s2_o          <= avst4to1_if_i_fff.rx_st_hdr_s2_o;
  avst4to1_if_i_ffff.rx_st_hdr_par_s2_o      <= avst4to1_if_i_fff.rx_st_hdr_par_s2_o;
  avst4to1_if_i_ffff.rx_st_tlp_prfx_s2_o     <= avst4to1_if_i_fff.rx_st_tlp_prfx_s2_o;
  avst4to1_if_i_ffff.rx_st_tlp_prfx_par_s2_o <= avst4to1_if_i_fff.rx_st_tlp_prfx_par_s2_o;
    avst4to1_if_i_ffff.rx_st_tlp_RSSAI_prfx_s2_o     <= avst4to1_if_i_fff.rx_st_tlp_RSSAI_prfx_s2_o;
    avst4to1_if_i_ffff.rx_st_tlp_RSSAI_prfx_par_s2_o <= avst4to1_if_i_fff.rx_st_tlp_RSSAI_prfx_par_s2_o;
    avst4to1_if_i_ffff.rx_st_passthrough_s2_o <= avst4to1_if_i_fff.rx_st_passthrough_s2_o;

  avst4to1_if_i_ffff.rx_st_vfactive_s2_o     <= avst4to1_if_i_fff.rx_st_vfactive_s2_o;
  avst4to1_if_i_ffff.rx_st_vfnum_s2_o        <= avst4to1_if_i_fff.rx_st_vfnum_s2_o;
  avst4to1_if_i_ffff.rx_st_pfnum_s2_o        <= avst4to1_if_i_fff.rx_st_pfnum_s2_o;
  avst4to1_if_i_ffff.rx_st_bar_s2_o          <= avst4to1_if_i_fff.rx_st_bar_s2_o;
  
  avst4to1_if_i_ffff.rx_st_sop_s2_o          <= avst4to1_if_i_fff.rx_st_sop_s2_o;
  avst4to1_if_i_ffff.rx_st_eop_s2_o          <= avst4to1_if_i_fff.rx_st_eop_s2_o;
  
  avst4to1_if_i_ffff.rx_st_data_s2_o         <= avst4to1_if_i_fff.rx_st_data_s2_o;
  avst4to1_if_i_ffff.rx_st_data_par_s2_o     <= avst4to1_if_i_fff.rx_st_data_par_s2_o;
  
  avst4to1_if_i_ffff.rx_st_empty_s2_o        <= avst4to1_if_i_fff.rx_st_empty_s2_o;
  
  avst4to1_if_i_ffff.rx_st_dvalid_s2_o       <= avst4to1_if_i_fff.rx_st_dvalid_s2_o;
  avst4to1_if_i_ffff.rx_st_hvalid_s2_o       <= avst4to1_if_i_fff.rx_st_hvalid_s2_o;
  avst4to1_if_i_ffff.rx_st_pvalid_s2_o       <= avst4to1_if_i_fff.rx_st_pvalid_s2_o;
  // S3
  avst4to1_if_i_ffff.rx_st_hdr_s3_o          <= avst4to1_if_i_fff.rx_st_hdr_s3_o;
  avst4to1_if_i_ffff.rx_st_hdr_par_s3_o      <= avst4to1_if_i_fff.rx_st_hdr_par_s3_o;
  avst4to1_if_i_ffff.rx_st_tlp_prfx_s3_o     <= avst4to1_if_i_fff.rx_st_tlp_prfx_s3_o;
  avst4to1_if_i_ffff.rx_st_tlp_prfx_par_s3_o <= avst4to1_if_i_fff.rx_st_tlp_prfx_par_s3_o;
    avst4to1_if_i_ffff.rx_st_tlp_RSSAI_prfx_s3_o     <= avst4to1_if_i_fff.rx_st_tlp_RSSAI_prfx_s3_o;
    avst4to1_if_i_ffff.rx_st_tlp_RSSAI_prfx_par_s3_o <= avst4to1_if_i_fff.rx_st_tlp_RSSAI_prfx_par_s3_o;
    avst4to1_if_i_ffff.rx_st_passthrough_s3_o <= avst4to1_if_i_fff.rx_st_passthrough_s3_o;
  
  avst4to1_if_i_ffff.rx_st_vfactive_s3_o     <= avst4to1_if_i_fff.rx_st_vfactive_s3_o;
  avst4to1_if_i_ffff.rx_st_vfnum_s3_o        <= avst4to1_if_i_fff.rx_st_vfnum_s3_o;
  avst4to1_if_i_ffff.rx_st_pfnum_s3_o        <= avst4to1_if_i_fff.rx_st_pfnum_s3_o;
  avst4to1_if_i_ffff.rx_st_bar_s3_o          <= avst4to1_if_i_fff.rx_st_bar_s3_o;

  avst4to1_if_i_ffff.rx_st_sop_s3_o          <= avst4to1_if_i_fff.rx_st_sop_s3_o;
  avst4to1_if_i_ffff.rx_st_eop_s3_o          <= avst4to1_if_i_fff.rx_st_eop_s3_o;
  
  avst4to1_if_i_ffff.rx_st_data_s3_o         <= avst4to1_if_i_fff.rx_st_data_s3_o;
  avst4to1_if_i_ffff.rx_st_data_par_s3_o     <= avst4to1_if_i_fff.rx_st_data_par_s3_o;
  
  avst4to1_if_i_ffff.rx_st_empty_s3_o        <= avst4to1_if_i_fff.rx_st_empty_s3_o;
  
  avst4to1_if_i_ffff.rx_st_dvalid_s3_o       <= avst4to1_if_i_fff.rx_st_dvalid_s3_o;
  avst4to1_if_i_ffff.rx_st_hvalid_s3_o       <= avst4to1_if_i_fff.rx_st_hvalid_s3_o;
  avst4to1_if_i_ffff.rx_st_pvalid_s3_o       <= avst4to1_if_i_fff.rx_st_pvalid_s3_o;

end // }

//
// Credits
//
  always @(posedge pld_clk)
  begin
     if (~pld_rst_n)
       begin
         pld_rx_hdr_crdup[2:0]  <= 3'd0;
         pld_rx_hdr_crdup_cnt[5:0] <= 6'd0;
         pld_rx_data_crdup      <= 1'd0;
         
         pld_rx_np_crdup[11:0]  <= 12'd0;
         pld_rx_p_crdup[11:0]   <= 12'd0;
         pld_rx_cpl_crdup[11:0] <= 12'd0;
       end
     else
       begin
         pld_rx_hdr_crdup[2:0]  <= all_cores_pld_rx_hdr_crdup[2:0];
         pld_rx_hdr_crdup_cnt[5:0] <= all_cores_pld_rx_hdr_crdup_cnt[5:0];
         pld_rx_data_crdup      <= all_cores_pld_rx_data_crdup;
         
         pld_rx_np_crdup[11:0]  <= all_cores_pld_rx_data_np_crd[11:0];
         pld_rx_p_crdup[11:0]   <= all_cores_pld_rx_data_p_crd[11:0];
         pld_rx_cpl_crdup[11:0] <= all_cores_pld_rx_data_cpl_crd[11:0];
       end
  end

  assign all_cores_pld_rx_hdr_crdup_cnt = add_cores_rx_hdr_crd_cnt(core_pld_rx_hdr_crdup);
  
  assign all_cores_pld_rx_hdr_crdup[2:0] = core_pld_rx_hdr_crdup; 
  assign all_cores_pld_rx_data_crdup = | core_pld_rx_data_crdup;
  
  //
  // ADD cores rx header credits to give back to ip
  function [5:0] add_cores_rx_hdr_crd_cnt;
       input [2:0] core_rx_hdr_crd_in ;
       
       integer i;
       logic [1:0]add_cores_rx_hdr_crd[2:0]; 
  begin
      add_cores_rx_hdr_crd_cnt[5:0] = 6'd0;
      for (i=0; i<3; i++) begin
         add_cores_rx_hdr_crd[i][1:0] = 2'd0;
      end
         add_cores_rx_hdr_crd[0] = add_cores_rx_hdr_crd[0] + core_rx_hdr_crd_in[0];
         add_cores_rx_hdr_crd[1] = add_cores_rx_hdr_crd[1] + core_rx_hdr_crd_in[1];
         add_cores_rx_hdr_crd[2] = add_cores_rx_hdr_crd[2] + core_rx_hdr_crd_in[2];
      add_cores_rx_hdr_crd_cnt[5:0] = {add_cores_rx_hdr_crd[2][1:0], add_cores_rx_hdr_crd[1][1:0], add_cores_rx_hdr_crd[0][1:0]};
  end
  endfunction

  // OR cores rx header credits to give back to ip
  function [2:0] or_cores_rx_hdr_crd;
       input [2:0] core_rx_hdr_crd_in ;
       
       integer i;
  begin
      or_cores_rx_hdr_crd[2:0] = 3'd0;
         or_cores_rx_hdr_crd[0] = or_cores_rx_hdr_crd[0] | core_rx_hdr_crd_in[0];
         or_cores_rx_hdr_crd[0] = or_cores_rx_hdr_crd[0] | core_rx_hdr_crd_in[0];
         or_cores_rx_hdr_crd[1] = or_cores_rx_hdr_crd[1] | core_rx_hdr_crd_in[1];
         or_cores_rx_hdr_crd[2] = or_cores_rx_hdr_crd[2] | core_rx_hdr_crd_in[2];
  end
  endfunction


assign all_cores_pld_rx_data_np_crd[11:0]  = add_cores_rx_data_crd(core_pld_rx_np_crdup);
assign all_cores_pld_rx_data_p_crd[11:0]   = add_cores_rx_data_crd(core_pld_rx_p_crdup);
assign all_cores_pld_rx_data_cpl_crd[11:0] = add_cores_rx_data_crd(core_pld_rx_cpl_crdup);

// ADD cores rx data credits to give back to ip
function [11:0] add_cores_rx_data_crd;
     input [11:0] core_rx_crd_in ;
     
     integer i;
begin
    add_cores_rx_data_crd[11:0] = 12'd0;
       add_cores_rx_data_crd[11:0] = add_cores_rx_data_crd[11:0] + core_rx_crd_in[11:0];
end
endfunction

//
// Core FIFO's
//
generate begin : rx_core_fifos_logic  // {

assign core_bcast_msg_s0                  =  bcast_msg_s0_ff;
assign core_bcast_msg_s1                  =  bcast_msg_s1_ff;
// S0
assign core_avst4to1_if.rx_st_hdr_s0_o          = avst4to1_if_i_ffff.rx_st_hdr_s0_o;
assign core_avst4to1_if.rx_st_hdr_par_s0_o      = avst4to1_if_i_ffff.rx_st_hdr_par_s0_o;
assign core_avst4to1_if.rx_st_tlp_prfx_s0_o     = avst4to1_if_i_ffff.rx_st_tlp_prfx_s0_o;
assign core_avst4to1_if.rx_st_tlp_prfx_par_s0_o = avst4to1_if_i_ffff.rx_st_tlp_prfx_par_s0_o;

assign core_avst4to1_if.rx_st_sop_s0_o          =  avst4to1_if_i_ffff.rx_st_sop_s0_o ;
assign core_avst4to1_if.rx_st_eop_s0_o          =  avst4to1_if_i_ffff.rx_st_eop_s0_o ;

assign core_avst4to1_if.rx_st_data_s0_o         = avst4to1_if_i_ffff.rx_st_data_s0_o;
assign core_avst4to1_if.rx_st_data_par_s0_o     = avst4to1_if_i_ffff.rx_st_data_par_s0_o;

assign core_avst4to1_if.rx_st_empty_s0_o        = avst4to1_if_i_ffff.rx_st_empty_s0_o;

    assign core_avst4to1_if.rx_st_tlp_RSSAI_prfx_s0_o     = avst4to1_if_i_ffff.rx_st_tlp_RSSAI_prfx_s0_o;
    assign core_avst4to1_if.rx_st_tlp_RSSAI_prfx_par_s0_o = avst4to1_if_i_ffff.rx_st_tlp_RSSAI_prfx_par_s0_o;
    assign core_avst4to1_if.rx_st_passthrough_s0_o = avst4to1_if_i_ffff.rx_st_passthrough_s0_o;
  
  assign core_avst4to1_if.rx_st_vfactive_s0_o     = avst4to1_if_i_ffff.rx_st_vfactive_s0_o;
  assign core_avst4to1_if.rx_st_vfnum_s0_o        = avst4to1_if_i_ffff.rx_st_vfnum_s0_o;
  assign core_avst4to1_if.rx_st_pfnum_s0_o        = avst4to1_if_i_ffff.rx_st_pfnum_s0_o;
  assign core_avst4to1_if.rx_st_bar_s0_o          = avst4to1_if_i_ffff.rx_st_bar_s0_o;
  
  assign core_avst4to1_if.rx_st_dvalid_s0_o       =  avst4to1_if_i_ffff.rx_st_dvalid_s0_o ;
  assign core_avst4to1_if.rx_st_hvalid_s0_o       =  avst4to1_if_i_ffff.rx_st_hvalid_s0_o ;
  assign core_avst4to1_if.rx_st_pvalid_s0_o       =  avst4to1_if_i_ffff.rx_st_pvalid_s0_o ;
// S1
assign core_avst4to1_if.rx_st_hdr_s1_o          = avst4to1_if_i_ffff.rx_st_hdr_s1_o;
assign core_avst4to1_if.rx_st_hdr_par_s1_o      = avst4to1_if_i_ffff.rx_st_hdr_par_s1_o;
assign core_avst4to1_if.rx_st_tlp_prfx_s1_o     = avst4to1_if_i_ffff.rx_st_tlp_prfx_s1_o;
assign core_avst4to1_if.rx_st_tlp_prfx_par_s1_o = avst4to1_if_i_ffff.rx_st_tlp_prfx_par_s1_o;

assign core_avst4to1_if.rx_st_sop_s1_o          = avst4to1_if_i_ffff.rx_st_sop_s1_o ;
assign core_avst4to1_if.rx_st_eop_s1_o          = avst4to1_if_i_ffff.rx_st_eop_s1_o ;

assign core_avst4to1_if.rx_st_data_s1_o         = avst4to1_if_i_ffff.rx_st_data_s1_o;
assign core_avst4to1_if.rx_st_data_par_s1_o     = avst4to1_if_i_ffff.rx_st_data_par_s1_o;

assign core_avst4to1_if.rx_st_empty_s1_o        = avst4to1_if_i_ffff.rx_st_empty_s1_o;

    assign core_avst4to1_if.rx_st_tlp_RSSAI_prfx_s1_o     = avst4to1_if_i_ffff.rx_st_tlp_RSSAI_prfx_s1_o;
    assign core_avst4to1_if.rx_st_tlp_RSSAI_prfx_par_s1_o = avst4to1_if_i_ffff.rx_st_tlp_RSSAI_prfx_par_s1_o;
    assign core_avst4to1_if.rx_st_passthrough_s1_o = avst4to1_if_i_ffff.rx_st_passthrough_s1_o;

  assign core_avst4to1_if.rx_st_vfactive_s1_o     = avst4to1_if_i_ffff.rx_st_vfactive_s1_o;
  assign core_avst4to1_if.rx_st_vfnum_s1_o        = avst4to1_if_i_ffff.rx_st_vfnum_s1_o;
  assign core_avst4to1_if.rx_st_pfnum_s1_o        = avst4to1_if_i_ffff.rx_st_pfnum_s1_o;
  assign core_avst4to1_if.rx_st_bar_s1_o          = avst4to1_if_i_ffff.rx_st_bar_s1_o;
  
  assign core_avst4to1_if.rx_st_dvalid_s1_o       =  avst4to1_if_i_ffff.rx_st_dvalid_s1_o ;
  assign core_avst4to1_if.rx_st_hvalid_s1_o       =  avst4to1_if_i_ffff.rx_st_hvalid_s1_o ;
  assign core_avst4to1_if.rx_st_pvalid_s1_o       =  avst4to1_if_i_ffff.rx_st_pvalid_s1_o ;

  assign core_bcast_msg_s2                  =  bcast_msg_s2_ff;
  assign core_bcast_msg_s3                  =  bcast_msg_s3_ff;
  
  // S2
  assign core_avst4to1_if.rx_st_hdr_s2_o          = avst4to1_if_i_ffff.rx_st_hdr_s2_o;
  assign core_avst4to1_if.rx_st_hdr_par_s2_o      = avst4to1_if_i_ffff.rx_st_hdr_par_s2_o;
  assign core_avst4to1_if.rx_st_tlp_prfx_s2_o     = avst4to1_if_i_ffff.rx_st_tlp_prfx_s2_o;
  assign core_avst4to1_if.rx_st_tlp_prfx_par_s2_o = avst4to1_if_i_ffff.rx_st_tlp_prfx_par_s2_o;
    assign core_avst4to1_if.rx_st_tlp_RSSAI_prfx_s2_o     = avst4to1_if_i_ffff.rx_st_tlp_RSSAI_prfx_s2_o;
    assign core_avst4to1_if.rx_st_tlp_RSSAI_prfx_par_s2_o = avst4to1_if_i_ffff.rx_st_tlp_RSSAI_prfx_par_s2_o;
    assign core_avst4to1_if.rx_st_passthrough_s2_o = avst4to1_if_i_ffff.rx_st_passthrough_s2_o;
  
  assign core_avst4to1_if.rx_st_vfactive_s2_o     = avst4to1_if_i_ffff.rx_st_vfactive_s2_o;
  assign core_avst4to1_if.rx_st_vfnum_s2_o        = avst4to1_if_i_ffff.rx_st_vfnum_s2_o;
  assign core_avst4to1_if.rx_st_pfnum_s2_o        = avst4to1_if_i_ffff.rx_st_pfnum_s2_o;
  assign core_avst4to1_if.rx_st_bar_s2_o          = avst4to1_if_i_ffff.rx_st_bar_s2_o;

  assign core_avst4to1_if.rx_st_sop_s2_o          =  avst4to1_if_i_ffff.rx_st_sop_s2_o ;
  assign core_avst4to1_if.rx_st_eop_s2_o          =  avst4to1_if_i_ffff.rx_st_eop_s2_o ;
  
  assign core_avst4to1_if.rx_st_data_s2_o         = avst4to1_if_i_ffff.rx_st_data_s2_o;
  assign core_avst4to1_if.rx_st_data_par_s2_o     = avst4to1_if_i_ffff.rx_st_data_par_s2_o;
  
  assign core_avst4to1_if.rx_st_empty_s2_o        = avst4to1_if_i_ffff.rx_st_empty_s2_o;
  
  assign core_avst4to1_if.rx_st_dvalid_s2_o       =  avst4to1_if_i_ffff.rx_st_dvalid_s2_o ;
  assign core_avst4to1_if.rx_st_hvalid_s2_o       =  avst4to1_if_i_ffff.rx_st_hvalid_s2_o ;
  assign core_avst4to1_if.rx_st_pvalid_s2_o       =  avst4to1_if_i_ffff.rx_st_pvalid_s2_o ;
  // S3
  assign core_avst4to1_if.rx_st_hdr_s3_o          = avst4to1_if_i_ffff.rx_st_hdr_s3_o;
  assign core_avst4to1_if.rx_st_hdr_par_s3_o      = avst4to1_if_i_ffff.rx_st_hdr_par_s3_o;
  assign core_avst4to1_if.rx_st_tlp_prfx_s3_o     = avst4to1_if_i_ffff.rx_st_tlp_prfx_s3_o;
  assign core_avst4to1_if.rx_st_tlp_prfx_par_s3_o = avst4to1_if_i_ffff.rx_st_tlp_prfx_par_s3_o;
    assign core_avst4to1_if.rx_st_tlp_RSSAI_prfx_s3_o     = avst4to1_if_i_ffff.rx_st_tlp_RSSAI_prfx_s3_o;
    assign core_avst4to1_if.rx_st_tlp_RSSAI_prfx_par_s3_o = avst4to1_if_i_ffff.rx_st_tlp_RSSAI_prfx_par_s3_o;
    assign core_avst4to1_if.rx_st_passthrough_s3_o = avst4to1_if_i_ffff.rx_st_passthrough_s3_o;
  
  assign core_avst4to1_if.rx_st_vfactive_s3_o     = avst4to1_if_i_ffff.rx_st_vfactive_s3_o;
  assign core_avst4to1_if.rx_st_vfnum_s3_o        = avst4to1_if_i_ffff.rx_st_vfnum_s3_o;
  assign core_avst4to1_if.rx_st_pfnum_s3_o        = avst4to1_if_i_ffff.rx_st_pfnum_s3_o;
  assign core_avst4to1_if.rx_st_bar_s3_o          = avst4to1_if_i_ffff.rx_st_bar_s3_o;

  assign core_avst4to1_if.rx_st_sop_s3_o          =  avst4to1_if_i_ffff.rx_st_sop_s3_o ;
  assign core_avst4to1_if.rx_st_eop_s3_o          =  avst4to1_if_i_ffff.rx_st_eop_s3_o ;
  
  assign core_avst4to1_if.rx_st_data_s3_o         = avst4to1_if_i_ffff.rx_st_data_s3_o;
  assign core_avst4to1_if.rx_st_data_par_s3_o     = avst4to1_if_i_ffff.rx_st_data_par_s3_o;
  
  assign core_avst4to1_if.rx_st_empty_s3_o        = avst4to1_if_i_ffff.rx_st_empty_s3_o;
  
  assign core_avst4to1_if.rx_st_dvalid_s3_o       =  avst4to1_if_i_ffff.rx_st_dvalid_s3_o ;
  assign core_avst4to1_if.rx_st_hvalid_s3_o       =  avst4to1_if_i_ffff.rx_st_hvalid_s3_o ;
  assign core_avst4to1_if.rx_st_pvalid_s3_o       =  avst4to1_if_i_ffff.rx_st_pvalid_s3_o ;


//
// DATA/HDR FIFO's
//
avst4to1_ss_rx_core_fifos #(
  .CORE_NUM(0),
  .DATA_FIFO_ADDR_WIDTH(DATA_FIFO_ADDR_WIDTH)                  // Data FIFO depth 2^9 = 512/8 = (max 512B payload)
) rx_core_fifos (
  .pld_clk              (pld_clk  ),                           // Clock (Core)
  .pld_rst_n            (pld_rst_n),
  
  .pld_rx               (core_avst4to1_if.rx),
  
  .pld_rx_hdr_crdup     (core_pld_rx_hdr_crdup ),        // 2:CPLH 1:NPH 0:PH
  .pld_rx_data_crdup    (core_pld_rx_data_crdup),
  
  .pld_rx_np_crdup      (core_pld_rx_np_crdup ),         // number of 256b data entries
  .pld_rx_p_crdup       (core_pld_rx_p_crdup  ),
  .pld_rx_cpl_crdup     (core_pld_rx_cpl_crdup),
  
  .tlp_crd_type_s0      (tlp_crd_type_s0_fff[1:0]),
  .tlp_crd_type_s1      (tlp_crd_type_s1_fff[1:0]),
  .tlp_crd_type_s2      (tlp_crd_type_s2_fff[1:0]),
  .tlp_crd_type_s3      (tlp_crd_type_s3_fff[1:0]),

  .bcast_msg_s0         (1'b0), 
  .bcast_msg_s1         (1'b0), 
  .bcast_msg_s2         (1'b0), 
  .bcast_msg_s3         (1'b0), 
//
//
  .avst4to1_prim_clk         (avst4to1_prim_clk  ),                      // Core clock
  .avst4to1_prim_rst_n       (avst4to1_prim_rst_n),                      // Core clock reset
  
  .crd_prim_rst_n            (crd_prim_rst_n),                      
  
  .avst4to1_core_max_payload (avst4to1_core_max_payload),      
  // RX side
  .avst4to1_rx_data_avail    (avst4to1_rx_data_avail[0]   ),          // p/cpl data
  .avst4to1_rx_hdr_avail     (avst4to1_rx_hdr_avail[0]    ),          // p/cpl hdr
  .avst4to1_rx_nph_hdr_avail (avst4to1_rx_nph_hdr_avail[0]),          // np hdr
  
  .avst4to1_vf_active        (avst4to1_vf_active   [0]),
  .avst4to1_vf_num           (avst4to1_vf_num      [0]),
  .avst4to1_pf_num           (avst4to1_pf_num      [0]),
  .avst4to1_bar_range        (avst4to1_bar_range   [0]),
  .avst4to1_rx_tlp_abort     (avst4to1_rx_tlp_abort[0]),
  
  .avst4to1_rx_sop           (avst4to1_rx_sop      [0]),
  .avst4to1_rx_eop           (avst4to1_rx_eop      [0]),
  .avst4to1_rx_hdr           (avst4to1_rx_hdr      [0]),
  .avst4to1_rx_prefix        (avst4to1_rx_prefix   [0]),
    .avst4to1_rx_passthrough (avst4to1_rx_passthrough [0]),
  .avst4to1_rx_prefix_valid  (avst4to1_rx_prefix_valid[0]),
    .avst4to1_rx_RSSAI_prefix  (avst4to1_rx_RSSAI_prefix[0]),
    .avst4to1_rx_RSSAI_prefix_valid  (avst4to1_rx_RSSAI_prefix_valid[0]),
  .avst4to1_rx_data          (avst4to1_rx_data     [0]),
  .avst4to1_rx_data_dw_valid (avst4to1_rx_data_dw_valid[0])
);

end endgenerate 

//---


// synthesis translate_off 
//
logic       sop_w_data[0:0];
logic       tlp_start[0:0];
logic       missing_sop[0:0];
logic       missing_eop[0:0];
logic       misaligned_data[0:0];
logic       missing_eop_dw_valid[0:0];

always @(posedge avst4to1_prim_clk)
begin : out_rx_hdr_data_sop_eop_chks
   if (~crd_prim_rst_n)
     begin
       sop_w_data[0] <= 'd0;
       tlp_start[0] <= 'd0;
       missing_sop[0] <= 'd0;
       missing_eop[0] <= 'd0;
       misaligned_data[0] <= 'd0;
       missing_eop_dw_valid[0] <= 'd0;
     end
   else
     begin
       case ({avst4to1_rx_eop[0], avst4to1_rx_sop[0]})
       2'b11:
         begin
           sop_w_data[0] <= 'd0;
           tlp_start[0] <= 'd0;
           missing_sop[0] <= 'd0;
           misaligned_data[0] <= 'd0;
           missing_eop_dw_valid[0] <= 'd0;
           
           if (tlp_start[0])
             begin
               $display("AVST4to1(0%0d  RX Side): Missing EOP @%0t", 0, $time);
               missing_eop[0] <= 'd1;
             end
           else
             missing_eop[0] <= 'd0;
         end
       2'b10:
         begin
           sop_w_data[0] <= 'd0;
           tlp_start[0] <= 'd0;
           missing_eop[0] <= 'd0;
           misaligned_data[0] <= 'd0;
           
           if (sop_w_data[0] & avst4to1_rx_data_dw_valid[0] == 'd0)
             begin
               $display("AVST4to1(0%0d  RX Side): Missing EOP Data Valids @%0t", 0, $time);
               missing_eop_dw_valid[0] <= 'd1;
             end
           else
             missing_eop_dw_valid[0] <= 'd0;
           
           if (~tlp_start[0])
             begin
               $display("AVST4to1(0%0d  RX Side): Missing SOP @%0t", 0, $time);
               missing_sop[0] <= 'd1;
             end
           else
             missing_sop[0] <= 'd0;
         end
       2'b01:
         begin
           sop_w_data[0] <= 'd1;
           tlp_start[0] <= 'd1;
           missing_sop[0] <= 'd0;
           misaligned_data[0] <= 'd0;
           missing_eop_dw_valid[0] <= 'd0;
           
           if (tlp_start[0])
             begin
               $display("AVST4to1(0%0d  RX Side): Missing EOP @%0t", 0, $time);
               missing_eop[0] <= 'd1;
             end
           else
             missing_eop[0] <= 'd0;
         end
       2'b00:
         begin
           missing_sop[0] <= 'd0;
           missing_eop[0] <= 'd0;
           missing_eop_dw_valid[0] <= 'd0;
           
           if (tlp_start[0])
             misaligned_data[0] <= 'd0;
           else
             if (avst4to1_rx_data_dw_valid[0][15:0] != 16'd0)
               begin
               	 $display("AVST4to1(0%0d  RX Side): Misaligned Data @%0t", 0, $time);
                 misaligned_data[0] <= 'd1;
               end
             else
               misaligned_data[0] <= 'd0;
         end
       endcase
     end
end
//synthesis translate_on




//---


endmodule
