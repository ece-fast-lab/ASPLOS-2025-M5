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

`include "avst4to1_pld_if.svh.iv"


module avst4to1_ss_rx_core_fifos #(
  parameter CORE_NUM = 0,
  parameter DATA_FIFO_ADDR_WIDTH = 9 // Data FIFO depth 2^9 = 512/8 = (max 512B payload)
) (
//
// PLD IF
//
  input                pld_clk,                                    
  input                pld_rst_n,
  
  avst4to1_if.rx            pld_rx,
  
  output logic [2:0]   pld_rx_hdr_crdup,                           // 2:CPLH 1:NPH 0:PH
  output logic         pld_rx_data_crdup,
  
  output logic [11:0]  pld_rx_np_crdup,                            // number of 256b data entries
  output logic [11:0]  pld_rx_p_crdup,
  output logic [11:0]  pld_rx_cpl_crdup,
  
  input [1:0]          tlp_crd_type_s0,
  input [1:0]          tlp_crd_type_s1,
  input [1:0]          tlp_crd_type_s2,
  input [1:0]          tlp_crd_type_s3,
  input                bcast_msg_s0,
  input                bcast_msg_s1,
  input                bcast_msg_s2,
  input                bcast_msg_s3,
//
//
  input                avst4to1_prim_clk,                             
  input                avst4to1_prim_rst_n,                          
  
  input                crd_prim_rst_n,                             
  
  input  [1:0]         avst4to1_core_max_payload,                  // 00: 128B
                                                                   // 01: 256B
                                                                   // 10: 512B
                                                                   // 11: reserved
  // RX side
  input                avst4to1_rx_data_avail,                     // p/cpl
  input                avst4to1_rx_hdr_avail,                      // p/cpl
  input                avst4to1_rx_nph_hdr_avail,                  // np
  
  output logic         avst4to1_vf_active,
  output logic [10:0]  avst4to1_vf_num,
  output logic [2:0]   avst4to1_pf_num,
  output logic [2:0]   avst4to1_bar_range,
  
  output logic         avst4to1_rx_tlp_abort,
  
  output logic         avst4to1_rx_sop,
  output logic         avst4to1_rx_eop,
  output logic [127:0] avst4to1_rx_hdr, 
  output logic [31:0]  avst4to1_rx_prefix,
  output logic         avst4to1_rx_prefix_valid,
  output logic [11:0]  avst4to1_rx_RSSAI_prefix,
  output logic         avst4to1_rx_RSSAI_prefix_valid,
  output logic         avst4to1_rx_passthrough,
  output logic [511:0] avst4to1_rx_data,
  output logic [15:0]  avst4to1_rx_data_dw_valid
);
//----------------------------------------------------------------------------//
localparam MAX_N_DATA_CRD = (2**DATA_FIFO_ADDR_WIDTH)/8; // (2^DATA_FIFO_ADDR_WIDTH)/8 data cycles for 512B
localparam HDR_FIFO_ADDR_WIDTH = $clog2(MAX_N_DATA_CRD)+3; // Header FIFO depth 2^5 = 32 

logic [4:0] fifo_ctrl_st;
parameter [4:0]  CTRL_IDLE        = 5'h1,
                 RD_HDR_S0_FIFO   = 5'h2,
                 RD_HDR_S1_FIFO   = 5'h4,
                 RD_HDR_S2_FIFO   = 5'h8,
                 RD_HDR_S3_FIFO   = 5'h10;

logic [1:0] fifo_sel_crd_type;
logic [1:0] fifo_sel_crd_type_f;
logic [1:0] fifo_sel_crd_type_ff;
logic [1:0] tlp_crd_type_s0_f;
logic [1:0] tlp_crd_type_s1_f;
logic [2:0] tlp_crd_type_s0_f_decode;
logic [2:0] tlp_crd_type_s1_f_decode;
logic [1:0] fifo_sel_crd_type_s0;
logic [1:0] fifo_sel_crd_type_s1;
logic [1:0] tlp_crd_type_s2_f;
logic [1:0] tlp_crd_type_s3_f;
logic [1:0] fifo_sel_crd_type_s2;
logic [1:0] fifo_sel_crd_type_s3;
parameter [1:0]  CPL_TLP          = 2,
                 NP_TLP           = 1,
                 P_TLP            = 0;
logic rx_valid_s0;
logic rx_valid_s1;
logic hdr_sop_s0;
logic hdr_sop_s0_f;
logic hdr_sop_s1;
logic hdr_sop_s1_f;

logic tlp_is_np_s0;
logic tlp_is_np_s0_f;
logic tlp_is_np_s1;
logic tlp_is_np_s1_f;

logic hdr_eop_s0;
logic hdr_eop_s0_f;
logic hdr_eop_s0_ff;
logic hdr_eop_s1;
logic hdr_eop_s1_f;
logic hdr_eop_s1_ff;
logic hdr_sop_valid_s0;
logic hdr_sop_valid_s0_f;
logic hdr_sop_valid_s1;
logic hdr_sop_valid_s1_f;
logic hdr_eop_valid_s0;
logic hdr_eop_valid_s0_f;
logic hdr_eop_valid_s0_ff;
logic hdr_eop_valid_s1;
logic hdr_eop_valid_s1_f;
logic hdr_eop_valid_s1_ff;
logic rx_valid_s2;
logic rx_valid_s3;
logic rx_hvalid_s0;
logic rx_hvalid_s1;
logic rx_hvalid_s2;
logic rx_hvalid_s3;
logic hdr_sop_s2;
logic hdr_sop_s2_f;
logic hdr_sop_s3;
logic hdr_sop_s3_f;
logic hdr_eop_s2;
logic hdr_eop_s2_f;
logic hdr_eop_s3;
logic hdr_eop_s3_f;
logic tlp_is_np_s2;
logic tlp_is_np_s2_f;
logic tlp_is_np_s3;
logic tlp_is_np_s3_f;
logic hdr_sop_valid_s2;
logic hdr_sop_valid_s2_f;
logic hdr_sop_valid_s3;
logic hdr_sop_valid_s3_f;
logic hdr_eop_valid_s2;
logic hdr_eop_valid_s2_f;
logic hdr_eop_valid_s2_ff;
logic hdr_eop_valid_s3;
logic hdr_eop_valid_s3_f;
logic hdr_eop_valid_s3_ff;
logic hdr_ctrl_dout_sop_s2;
logic hdr_ctrl_dout_sop_s3;
logic hdr_dout_is_np_s2;
logic hdr_dout_is_np_s3;
logic hdr_ctrl_dout_sop_s0;
logic hdr_ctrl_dout_sop_s1;

logic hdr_dout_is_np_s0;
logic hdr_dout_is_np_s1;

logic [7:0] fifo_hdr_ctrl_din;
logic [7:0] fifo_hdr_ctrl_dout;
logic fifo_hdr_ctrl_wr_en;
logic fifo_hdr_ctrl_rd_en;
logic fifo_hdr_ctrl_full;
logic fifo_hdr_ctrl_empty;
logic [194:0] fifo_hdr_din_s0;
logic [194:0] fifo_hdr_dout_s0;
logic fifo_hdr_wr_en_s0; 
logic fifo_hdr_rd_en_s0; 
logic fifo_hdr_full_s0;
logic fifo_hdr_empty_s0;
logic [127:0] fifo_hdr_dout_s0_endian;
logic [127:0] fifo_hdr_dout_s0_endian_f;
logic [31:0]  fifo_hdr_dout_prfx_s0;
logic [31:0]  fifo_hdr_dout_prfx_s0_endian;
logic [31:0]  fifo_hdr_dout_prfx_s0_endian_f;
logic fifo_hdr_dout_prfx_val_s0;
logic fifo_hdr_dout_RSSAI_prfx_val_s0;
logic [11:0]  fifo_hdr_dout_RSSAI_prfx_s0;
logic [11:0]  fifo_hdr_dout_RSSAI_prfx_s0_f;
logic         fifo_hdr_dout_pass_thru_s0;
logic         fifo_hdr_dout_pass_thru_s0_f;
logic         fifo_hdr_dout_vf_active_s0;
logic [10:0]  fifo_hdr_dout_vf_num_s0;
logic [2:0]   fifo_hdr_dout_pf_num_s0;
logic [2:0]   fifo_hdr_dout_bar_range_s0;

logic [10:0]  fifo_hdr_dout_vf_num_s0_f;
logic         fifo_hdr_dout_vf_active_s0_f;
logic [2:0]   fifo_hdr_dout_pf_num_s0_f;
logic [2:0]   fifo_hdr_dout_bar_range_s0_f;

logic [194:0] fifo_hdr_din_s1;
logic [194:0] fifo_hdr_dout_s1;
logic fifo_hdr_wr_en_s1; 
logic fifo_hdr_rd_en_s1; 
logic fifo_hdr_full_s1;
logic fifo_hdr_empty_s1;
logic [127:0] fifo_hdr_dout_s1_endian;
logic [127:0] fifo_hdr_dout_s1_endian_f;
logic [31:0]  fifo_hdr_dout_prfx_s1;
logic [31:0]  fifo_hdr_dout_prfx_s1_endian;
logic [31:0]  fifo_hdr_dout_prfx_s1_endian_f;
logic fifo_hdr_dout_prfx_val_s1;
logic fifo_hdr_dout_RSSAI_prfx_val_s1;
logic [11:0]  fifo_hdr_dout_RSSAI_prfx_s1;
logic [11:0]  fifo_hdr_dout_RSSAI_prfx_s1_f;
logic         fifo_hdr_dout_pass_thru_s1;
logic         fifo_hdr_dout_pass_thru_s1_f;
logic         fifo_hdr_dout_vf_active_s1;
logic [10:0]  fifo_hdr_dout_vf_num_s1;
logic [2:0]   fifo_hdr_dout_pf_num_s1;
logic [2:0]   fifo_hdr_dout_bar_range_s1;

logic         fifo_hdr_dout_vf_active_s1_f;
logic [10:0]  fifo_hdr_dout_vf_num_s1_f;
logic [2:0]   fifo_hdr_dout_pf_num_s1_f;
logic [2:0]   fifo_hdr_dout_bar_range_s1_f;

logic [194:0] fifo_hdr_din_s2;
logic [194:0] fifo_hdr_dout_s2;


logic fifo_hdr_wr_en_s2; 
logic fifo_hdr_rd_en_s2; 
logic fifo_hdr_full_s2;
logic fifo_hdr_empty_s2;

logic [127:0] fifo_hdr_dout_s2_endian;
logic [127:0] fifo_hdr_dout_s2_endian_f;
logic [31:0]  fifo_hdr_dout_prfx_s2;
logic [31:0]  fifo_hdr_dout_prfx_s2_endian;
logic [31:0]  fifo_hdr_dout_prfx_s2_endian_f;
logic fifo_hdr_dout_prfx_val_s2;
logic fifo_hdr_dout_RSSAI_prfx_val_s2;
logic [11:0]  fifo_hdr_dout_RSSAI_prfx_s2;
logic [11:0]  fifo_hdr_dout_RSSAI_prfx_s2_f;
logic         fifo_hdr_dout_vf_active_s2;
logic [10:0]  fifo_hdr_dout_vf_num_s2;
logic [2:0]   fifo_hdr_dout_pf_num_s2;
logic [2:0]   fifo_hdr_dout_bar_range_s2;

logic         fifo_hdr_dout_vf_active_s2_f;
logic [10:0]  fifo_hdr_dout_vf_num_s2_f;
logic [2:0]   fifo_hdr_dout_pf_num_s2_f;
logic [2:0]   fifo_hdr_dout_bar_range_s2_f;
logic         fifo_hdr_dout_pass_thru_s2;
logic         fifo_hdr_dout_pass_thru_s2_f;

logic [194:0] fifo_hdr_din_s3;
logic [194:0] fifo_hdr_dout_s3;

logic fifo_hdr_wr_en_s3; 
logic fifo_hdr_rd_en_s3; 
logic fifo_hdr_full_s3;
logic fifo_hdr_empty_s3;

logic [127:0] fifo_hdr_dout_s3_endian;
logic [127:0] fifo_hdr_dout_s3_endian_f;
logic [31:0]  fifo_hdr_dout_prfx_s3;
logic [31:0]  fifo_hdr_dout_prfx_s3_endian;
logic [31:0]  fifo_hdr_dout_prfx_s3_endian_f;
logic fifo_hdr_dout_prfx_val_s3;
logic fifo_hdr_dout_RSSAI_prfx_val_s3;
logic [11:0]  fifo_hdr_dout_RSSAI_prfx_s3;
logic [11:0]  fifo_hdr_dout_RSSAI_prfx_s3_f;
logic         fifo_hdr_dout_vf_active_s3;
logic [10:0]  fifo_hdr_dout_vf_num_s3;
logic [2:0]   fifo_hdr_dout_pf_num_s3;
logic [2:0]   fifo_hdr_dout_bar_range_s3;

logic         fifo_hdr_dout_vf_active_s3_f;
logic [10:0]  fifo_hdr_dout_vf_num_s3_f;
logic [2:0]   fifo_hdr_dout_pf_num_s3_f;
logic [2:0]   fifo_hdr_dout_bar_range_s3_f;
logic         fifo_hdr_dout_pass_thru_s3;
logic         fifo_hdr_dout_pass_thru_s3_f;

logic [15:0] data_dw_valid_s0;
logic [15:0] data_dw_valid_s1;

logic [262:0] fifo_data_din_s0;
logic [262:0] fifo_data_din_s0_f[2:0] /* synthesis preserve */;
logic fifo_data_wr_en_s0;
logic [2:0] fifo_data_wr_en_s0_f /* synthesis preserve */;
logic fifo_data_rd_en_s0; 
logic fifo_data_full_s0;
logic fifo_data_empty_s0;
logic fifo_data_empty_s0_f;
logic [262:0] fifo_data_dout_s0;
logic [2:0] data_dout_empty_s0;
logic data_dout_eop_s0;
logic data_dout_eop_s0_i;
logic data_dout_sop_s0;
logic data_dout_sop_s0_i;
logic [255:0] data_dout_s0;
logic [255:0] data_dout_s0_i;
logic data_dout_valid_s0;
logic data_dout_tlp_abort_s0;

logic [262:0] fifo_data_din_s1;
logic [262:0] fifo_data_din_s1_f[2:0] /* synthesis preserve */;
logic fifo_data_wr_en_s1;
logic [2:0]fifo_data_wr_en_s1_f /* synthesis preserve */;
logic fifo_data_rd_en_s1; 
logic fifo_data_full_s1;
logic fifo_data_empty_s1;
logic fifo_data_empty_s1_f;
logic [262:0] fifo_data_dout_s1;
logic [2:0] data_dout_empty_s1;
logic data_dout_eop_s1;
logic data_dout_eop_s1_i;
logic data_dout_sop_s1;
logic data_dout_sop_s1_i;
logic [255:0] data_dout_s1;
logic [255:0] data_dout_s1_i;
logic data_dout_valid_s1;
logic data_dout_tlp_abort_s1;

logic [15:0] data_dw_valid_s2;
logic [15:0] data_dw_valid_s3;

logic [262:0] fifo_data_din_s2;
logic [262:0] fifo_data_din_s2_f[2:0] /* synthesis preserve */;
logic fifo_data_wr_en_s2;
logic [2:0] fifo_data_wr_en_s2_f /* synthesis preserve */;
logic fifo_data_rd_en_s2; 
logic fifo_data_full_s2;
logic fifo_data_empty_s2;
logic fifo_data_empty_s2_f;
logic [262:0] fifo_data_dout_s2;
logic [2:0] data_dout_empty_s2;
logic data_dout_eop_s2;
logic data_dout_eop_s2_i;
logic data_dout_sop_s2;
logic data_dout_sop_s2_i;
logic [255:0] data_dout_s2;
logic [255:0] data_dout_s2_i;
logic data_dout_valid_s2;
logic data_dout_tlp_abort_s2;

logic [262:0] fifo_data_din_s3;
logic [262:0] fifo_data_din_s3_f[2:0] /* synthesis preserve */;
logic fifo_data_wr_en_s3;
logic [2:0] fifo_data_wr_en_s3_f /* synthesis preserve */;
logic fifo_data_rd_en_s3; 
logic fifo_data_full_s3;
logic fifo_data_empty_s3;
logic fifo_data_empty_s3_f;
logic [262:0] fifo_data_dout_s3;
logic [2:0] data_dout_empty_s3;
logic data_dout_eop_s3;
logic data_dout_eop_s3_i;
logic data_dout_sop_s3;
logic data_dout_sop_s3_i;
logic [255:0] data_dout_s3;
logic [255:0] data_dout_s3_i;
logic data_dout_valid_s3;
logic data_dout_tlp_abort_s3;

logic hdr_data_en;
logic hdr_data_en_f;
logic [1:0] hdr_sel;
logic [1:0] data_sel;
logic [1:0] data_sel_f;
logic [11:0]  prim_rx_np_crdup_i;
logic [11:0]  prim_rx_p_crdup_i;
logic [11:0]  prim_rx_cpl_crdup_i;
logic [11:0]  prim_rx_np_crdup_f;
logic [11:0]  prim_rx_p_crdup_f;
logic [11:0]  prim_rx_cpl_crdup_f;
logic [39:0]  hdr_data_crd_fifo_din;
logic [39:0]  hdr_data_crd_fifo_dout;
logic [39:0]  hdr_data_crd_fifo_dout_f;
logic         hdr_data_crd_fifo_full;
logic         hdr_data_crd_fifo_empty;
logic         hdr_data_crd_fifo_empty_f;
logic         data_dout_sop_s0_f;
logic         data_dout_eop_s0_f;
logic [2:0]   data_dout_empty_s0_i;
logic [2:0]   data_dout_empty_s0_f;
logic [255:0] data_dout_s0_f;
logic         data_dout_valid_s0_f;
logic         data_dout_tlp_abort_s0_i;
logic         data_dout_tlp_abort_s0_f;
logic         data_dout_bcast_msg_s0_i;
logic         data_dout_bcast_msg_s0_f;
logic         data_dout_sop_s1_f;
logic         data_dout_sop_s1_f_i;
logic         data_dout_eop_s1_f;
logic [2:0]   data_dout_empty_s1_i;
logic [2:0]   data_dout_empty_s1_f;
logic [255:0] data_dout_s1_f;
logic         data_dout_valid_s1_f;
logic         data_dout_tlp_abort_s1_i;
logic         data_dout_tlp_abort_s1_f;
logic         data_dout_bcast_msg_s1_i;
logic         data_dout_bcast_msg_s1_f;
logic         data_dout_sop_s2_f;
logic         data_dout_sop_s2_f_i;
logic         data_dout_eop_s2_f;
logic [2:0]   data_dout_empty_s2_i;
logic [2:0]   data_dout_empty_s2_f;
logic [255:0] data_dout_s2_f;
logic         data_dout_valid_s2_f;
logic         data_dout_tlp_abort_s2_i;
logic         data_dout_tlp_abort_s2_f;
logic         data_dout_bcast_msg_s2_i;
logic         data_dout_bcast_msg_s2_f;
logic         data_dout_sop_s3_f;
logic         data_dout_sop_s3_f_i;
logic         data_dout_eop_s3_f;
logic [2:0]   data_dout_empty_s3_i;
logic [2:0]   data_dout_empty_s3_f;
logic [255:0] data_dout_s3_f;
logic         data_dout_valid_s3_f;
logic         data_dout_tlp_abort_s3_i;
logic         data_dout_tlp_abort_s3_f;
logic         data_dout_bcast_msg_s3_i;
logic         data_dout_bcast_msg_s3_f;
logic         avst4to1_rx_sop_i;
logic         avst4to1_rx_sop_i_f;
logic         avst4to1_rx_eop_i;
logic         avst4to1_rx_eop_i_f;
logic         avst4to1_rx_eop_i_ff;
logic [511:0] avst4to1_rx_data_i;
logic [15:0]  avst4to1_rx_data_dw_valid_i;
logic [15:0]  avst4to1_rx_data_dw_valid_ii;
logic [15:0]  avst4to1_rx_data_dw_valid_ii_f;
logic [127:0] avst4to1_rx_hdr_i;
logic [127:0] avst4to1_rx_hdr_i_f;
logic [31:0]  avst4to1_rx_prefix_i;
logic         avst4to1_rx_passthrough_i;
logic         avst4to1_rx_prefix_valid_i;
logic [11:0]  avst4to1_rx_RSSAI_prefix_i;
logic         avst4to1_rx_RSSAI_prefix_valid_i;
logic         avst4to1_vf_active_i;
logic [10:0]  avst4to1_vf_num_i;
logic [2:0]   avst4to1_pf_num_i;
logic [2:0]   avst4to1_bar_range_i;
logic         avst4to1_rx_tlp_abort_i;
logic         first_S1_cycle;
logic         second_tlp;
logic         third_tlp;
logic         fourth_tlp;
logic [3:0]   data_512b_cycles_per_crd;
logic         wr_n_data_cycles;
logic         wr_n_data_cycles_f;
logic         wr_n_data_cycles_ff;
logic [3:0]   n_data_cycles;
logic         sop_in_data_cycle;
logic         cpl_sop_in_data_cycle;
logic         np_sop_in_data_cycle;
logic         p_sop_in_data_cycle;
logic         cpl_sop_in_data_cycle_f;
logic         np_sop_in_data_cycle_f;
logic         p_sop_in_data_cycle_f;
logic fifo_data_wr_en_s0_i[2:0];
logic [262:0] fifo_data_din_s0_i[2:0];
logic fifo_data_full_s0_i[2:0];
logic fifo_data_rd_en_s0_ii[2:0];
logic fifo_data_rd_en_s0_iii[2:0];
logic fifo_data_empty_s0_i[2:0];
logic [262:0] fifo_data_dout_s0_i[2:0];
logic fifo_data_eop_s0_i[2:0];
logic fifo_data_wr_en_s1_i[2:0];
logic [262:0] fifo_data_din_s1_i[2:0];
logic fifo_data_full_s1_i[2:0];
logic fifo_data_rd_en_s1_ii[2:0];
logic fifo_data_rd_en_s1_iii[2:0];
logic fifo_data_empty_s1_i[2:0];
logic [262:0] fifo_data_dout_s1_i[2:0];
logic fifo_data_eop_s1_i[2:0];
logic fifo_data_wr_en_s2_i[2:0];
logic [262:0] fifo_data_din_s2_i[2:0];
logic fifo_data_full_s2_i[2:0];
logic fifo_data_rd_en_s2_ii[2:0];
logic fifo_data_rd_en_s2_iii[2:0];
logic fifo_data_empty_s2_i[2:0];
logic [262:0] fifo_data_dout_s2_i[2:0];
logic fifo_data_eop_s2_i[2:0];
logic fifo_data_wr_en_s3_i[2:0];
logic [262:0] fifo_data_din_s3_i[2:0];
logic fifo_data_full_s3_i[2:0];
logic fifo_data_rd_en_s3_ii[2:0];
logic fifo_data_rd_en_s3_iii[2:0];
logic fifo_data_empty_s3_i[2:0];
logic [262:0] fifo_data_dout_s3_i[2:0];
logic fifo_data_eop_s3_i[2:0];
logic fifo_tlp_eop_wr_en;
logic fifo_tlp_eop_rd_en;
logic fifo_tlp_eop_full;
logic fifo_tlp_eop_empty;
logic fifo_tlp_eop_empty_f;
logic [2:0] fifo_tlp_eop_din;
logic [2:0] fifo_tlp_eop_dout;
logic [2:0] fifo_tlp_eop_dout_f;
logic [2:0] fifo_tlp_eop_dout_d;
logic data_cycle;
logic [1:0] curr_data_cycle;
logic two_eops;
logic two_eops_f;
logic avst4to1_tlp_w_data;
logic avst4to1_tlp_w_data_f;
logic avst4to1_tlp_w_data_ff;
logic avst4to1_bcast_msg_type;
logic avst4to1_bcast_msg_type_f;
logic avst4to1_bcast_msg_type_ff;
logic delay_4_empty_upd;

genvar crd_type;
//----------------------------------------------------------------------------//
//synthesis translate_off 
logic         sop_s0_val;
logic         eop_s0_val;
logic         sop_s1_val;
logic         eop_s1_val;


logic         sop_s2_val;
logic         eop_s2_val;
logic         sop_s3_val;
logic         eop_s3_val;


logic         tlp_start;
logic         missing_sop;
logic         missing_eop;
logic         misaligned_data;

logic [10:0]  wr_tlp_index, rd_tlp_index;
logic [127:0] tlp_cycle_chk [2047:0];

  assign sop_s0_val = pld_rx.rx_st_sop_s0_o & pld_rx.rx_st_hvalid_s0_o;
  assign eop_s0_val = pld_rx.rx_st_eop_s0_o & (pld_rx.rx_st_dvalid_s0_o | pld_rx.rx_st_hvalid_s0_o);
  assign sop_s1_val = pld_rx.rx_st_sop_s1_o & pld_rx.rx_st_hvalid_s1_o;
  assign eop_s1_val = pld_rx.rx_st_eop_s1_o & (pld_rx.rx_st_dvalid_s1_o | pld_rx.rx_st_hvalid_s1_o);
  assign sop_s2_val = pld_rx.rx_st_sop_s2_o & pld_rx.rx_st_hvalid_s2_o;
  assign eop_s2_val = pld_rx.rx_st_eop_s2_o & (pld_rx.rx_st_dvalid_s2_o | pld_rx.rx_st_hvalid_s2_o);
  assign sop_s3_val = pld_rx.rx_st_sop_s3_o & pld_rx.rx_st_hvalid_s3_o;
  assign eop_s3_val = pld_rx.rx_st_eop_s3_o & (pld_rx.rx_st_dvalid_s3_o | pld_rx.rx_st_hvalid_s3_o);

always @(posedge pld_clk)
begin : in_tlp_cycle_chks
   if (~pld_rst_n)
     begin
       wr_tlp_index <= 'd0;
     end
   else
     begin
       case ({sop_s3_val, sop_s2_val, sop_s1_val, sop_s0_val})
       4'b1111:
         begin
           wr_tlp_index <= wr_tlp_index + 4;
           tlp_cycle_chk[wr_tlp_index] <= pld_rx.rx_st_hdr_s0_o[127:0];
           if (wr_tlp_index == 2047)
             begin
               tlp_cycle_chk[0] <= pld_rx.rx_st_hdr_s1_o[127:0];
               tlp_cycle_chk[1] <= pld_rx.rx_st_hdr_s2_o[127:0];
               tlp_cycle_chk[2] <= pld_rx.rx_st_hdr_s3_o[127:0];
             end
           else
             begin
               if (wr_tlp_index == 2046)
                 begin
                   tlp_cycle_chk[wr_tlp_index+1] <= pld_rx.rx_st_hdr_s1_o[127:0];
                   tlp_cycle_chk[0] <= pld_rx.rx_st_hdr_s2_o[127:0];
                   tlp_cycle_chk[1] <= pld_rx.rx_st_hdr_s3_o[127:0];
                 end
               else
                 begin
                   if (wr_tlp_index == 2045)
                     begin
                       tlp_cycle_chk[wr_tlp_index+1] <= pld_rx.rx_st_hdr_s1_o[127:0];
                       tlp_cycle_chk[wr_tlp_index+2] <= pld_rx.rx_st_hdr_s2_o[127:0];
                       tlp_cycle_chk[0] <= pld_rx.rx_st_hdr_s3_o[127:0];
                     end
                   else
                     begin
                       tlp_cycle_chk[wr_tlp_index+1] <= pld_rx.rx_st_hdr_s1_o[127:0];
                       tlp_cycle_chk[wr_tlp_index+2] <= pld_rx.rx_st_hdr_s2_o[127:0];
                       tlp_cycle_chk[wr_tlp_index+3] <= pld_rx.rx_st_hdr_s3_o[127:0];
                     end
                 end
             end
         end
       4'b1110:
         begin
           wr_tlp_index <= wr_tlp_index + 3;
           tlp_cycle_chk[wr_tlp_index] <= pld_rx.rx_st_hdr_s1_o[127:0];
           if (wr_tlp_index == 2047)
             begin
               tlp_cycle_chk[0] <= pld_rx.rx_st_hdr_s2_o[127:0];
               tlp_cycle_chk[1] <= pld_rx.rx_st_hdr_s3_o[127:0];
             end
           else
             begin
               if (wr_tlp_index == 2046)
                 begin
                   tlp_cycle_chk[wr_tlp_index+1] <= pld_rx.rx_st_hdr_s2_o[127:0];
                   tlp_cycle_chk[0] <= pld_rx.rx_st_hdr_s3_o[127:0];
                 end
               else
                 begin
                   tlp_cycle_chk[wr_tlp_index+1] <= pld_rx.rx_st_hdr_s2_o[127:0];
                   tlp_cycle_chk[wr_tlp_index+2] <= pld_rx.rx_st_hdr_s3_o[127:0];
                 end
             end
         end
       4'b1101:
         begin
           wr_tlp_index <= wr_tlp_index + 3;
           tlp_cycle_chk[wr_tlp_index] <= pld_rx.rx_st_hdr_s0_o[127:0];
           if (wr_tlp_index == 2047)
             begin
               tlp_cycle_chk[0] <= pld_rx.rx_st_hdr_s2_o[127:0];
               tlp_cycle_chk[1] <= pld_rx.rx_st_hdr_s3_o[127:0];
             end
           else
             begin
               if (wr_tlp_index == 2046)
                 begin
                   tlp_cycle_chk[wr_tlp_index+1] <= pld_rx.rx_st_hdr_s2_o[127:0];
                   tlp_cycle_chk[0] <= pld_rx.rx_st_hdr_s3_o[127:0];
                 end
               else
                 begin
                   tlp_cycle_chk[wr_tlp_index+1] <= pld_rx.rx_st_hdr_s2_o[127:0];
                   tlp_cycle_chk[wr_tlp_index+2] <= pld_rx.rx_st_hdr_s3_o[127:0];
                 end
             end
         end
       4'b1100:
         begin
           wr_tlp_index <= wr_tlp_index + 2;
           tlp_cycle_chk[wr_tlp_index] <= pld_rx.rx_st_hdr_s2_o[127:0];
           if (wr_tlp_index == 2047)
             tlp_cycle_chk[0] <= pld_rx.rx_st_hdr_s3_o[127:0];
           else
             tlp_cycle_chk[wr_tlp_index+1] <= pld_rx.rx_st_hdr_s3_o[127:0];
         end
       4'b1011:
         begin
           wr_tlp_index <= wr_tlp_index + 3;
           tlp_cycle_chk[wr_tlp_index] <= pld_rx.rx_st_hdr_s0_o[127:0];
           if (wr_tlp_index == 2047)
             begin
               tlp_cycle_chk[0] <= pld_rx.rx_st_hdr_s1_o[127:0];
               tlp_cycle_chk[1] <= pld_rx.rx_st_hdr_s3_o[127:0];
             end
           else
             begin
               if (wr_tlp_index == 2046)
                 begin
                   tlp_cycle_chk[wr_tlp_index+1] <= pld_rx.rx_st_hdr_s1_o[127:0];
                   tlp_cycle_chk[0] <= pld_rx.rx_st_hdr_s3_o[127:0];
                 end
               else
                 begin
                   tlp_cycle_chk[wr_tlp_index+1] <= pld_rx.rx_st_hdr_s1_o[127:0];
                   tlp_cycle_chk[wr_tlp_index+2] <= pld_rx.rx_st_hdr_s3_o[127:0];
                 end
             end
         end
       4'b1010:
         begin
           wr_tlp_index <= wr_tlp_index + 2;
           tlp_cycle_chk[wr_tlp_index] <= pld_rx.rx_st_hdr_s1_o[127:0];
           if (wr_tlp_index == 2047)
             tlp_cycle_chk[0] <= pld_rx.rx_st_hdr_s3_o[127:0];
           else
             tlp_cycle_chk[wr_tlp_index+1] <= pld_rx.rx_st_hdr_s3_o[127:0];
         end
       4'b1001:
         begin
           wr_tlp_index <= wr_tlp_index + 2;
           tlp_cycle_chk[wr_tlp_index] <= pld_rx.rx_st_hdr_s0_o[127:0];
           if (wr_tlp_index == 2047)
             tlp_cycle_chk[0] <= pld_rx.rx_st_hdr_s3_o[127:0];
           else
             tlp_cycle_chk[wr_tlp_index+1] <= pld_rx.rx_st_hdr_s3_o[127:0];
         end
       4'b1000:
         begin
           wr_tlp_index <= wr_tlp_index + 1;
           tlp_cycle_chk[wr_tlp_index] <= pld_rx.rx_st_hdr_s3_o[127:0];
         end
       4'b0111:
         begin
           wr_tlp_index <= wr_tlp_index + 3;
           tlp_cycle_chk[wr_tlp_index] <= pld_rx.rx_st_hdr_s0_o[127:0];
           if (wr_tlp_index == 2047)
             begin
               tlp_cycle_chk[0] <= pld_rx.rx_st_hdr_s1_o[127:0];
               tlp_cycle_chk[1] <= pld_rx.rx_st_hdr_s2_o[127:0];
             end
           else
             begin
               if (wr_tlp_index == 2046)
                 begin
                   tlp_cycle_chk[wr_tlp_index+1] <= pld_rx.rx_st_hdr_s1_o[127:0];
                   tlp_cycle_chk[0] <= pld_rx.rx_st_hdr_s2_o[127:0];
                 end
               else
                 begin
                   tlp_cycle_chk[wr_tlp_index+1] <= pld_rx.rx_st_hdr_s1_o[127:0];
                   tlp_cycle_chk[wr_tlp_index+2] <= pld_rx.rx_st_hdr_s2_o[127:0];
                 end
             end
         end
       4'b0110:
         begin
           wr_tlp_index <= wr_tlp_index + 2;
           tlp_cycle_chk[wr_tlp_index] <= pld_rx.rx_st_hdr_s1_o[127:0];
           if (wr_tlp_index == 2047)
             tlp_cycle_chk[0] <= pld_rx.rx_st_hdr_s2_o[127:0];
           else
             tlp_cycle_chk[wr_tlp_index+1] <= pld_rx.rx_st_hdr_s2_o[127:0];
         end
       4'b0101:
         begin
           wr_tlp_index <= wr_tlp_index + 2;
           tlp_cycle_chk[wr_tlp_index] <= pld_rx.rx_st_hdr_s0_o[127:0];
           if (wr_tlp_index == 2047)
             tlp_cycle_chk[0] <= pld_rx.rx_st_hdr_s2_o[127:0];
           else
             tlp_cycle_chk[wr_tlp_index+1] <= pld_rx.rx_st_hdr_s2_o[127:0];
         end
       4'b0100:
         begin
           wr_tlp_index <= wr_tlp_index + 1;
           tlp_cycle_chk[wr_tlp_index] <= pld_rx.rx_st_hdr_s2_o[127:0];
         end
       4'b0011:
         begin
           wr_tlp_index <= wr_tlp_index + 2;
           tlp_cycle_chk[wr_tlp_index] <= pld_rx.rx_st_hdr_s0_o[127:0];
           if (wr_tlp_index == 2047)
             tlp_cycle_chk[0] <= pld_rx.rx_st_hdr_s1_o[127:0];
           else
             tlp_cycle_chk[wr_tlp_index+1] <= pld_rx.rx_st_hdr_s1_o[127:0];
         end
       4'b0010:
         begin
           wr_tlp_index <= wr_tlp_index + 1;
           tlp_cycle_chk[wr_tlp_index] <= pld_rx.rx_st_hdr_s1_o[127:0];
         end
       4'b0001:
         begin
           wr_tlp_index <= wr_tlp_index + 1;
           tlp_cycle_chk[wr_tlp_index] <= pld_rx.rx_st_hdr_s0_o[127:0];
         end
       4'b0000:
         begin
         end
       endcase
     end
end

//synthesis translate_on
//
//
//
assign hdr_sop_s0 = pld_rx.rx_st_sop_s0_o;
assign hdr_eop_s0 = pld_rx.rx_st_eop_s0_o;
assign hdr_sop_s1 = pld_rx.rx_st_sop_s1_o;
assign hdr_eop_s1 = pld_rx.rx_st_eop_s1_o;
assign hdr_sop_s2 = pld_rx.rx_st_sop_s2_o;
assign hdr_eop_s2 = pld_rx.rx_st_eop_s2_o;
assign hdr_sop_s3 = pld_rx.rx_st_sop_s3_o;
assign hdr_eop_s3 = pld_rx.rx_st_eop_s3_o;
assign rx_valid_s0 = pld_rx.rx_st_dvalid_s0_o;
assign rx_valid_s1 = pld_rx.rx_st_dvalid_s1_o;
assign rx_valid_s2 = pld_rx.rx_st_dvalid_s2_o;
assign rx_valid_s3 = pld_rx.rx_st_dvalid_s3_o;
assign rx_hvalid_s0 = pld_rx.rx_st_hvalid_s0_o;
assign rx_hvalid_s1 = pld_rx.rx_st_hvalid_s1_o;
assign rx_hvalid_s2 = pld_rx.rx_st_hvalid_s2_o;
assign rx_hvalid_s3 = pld_rx.rx_st_hvalid_s3_o;
assign hdr_sop_valid_s0 = hdr_sop_s0 & rx_hvalid_s0;
assign hdr_eop_valid_s0 = hdr_eop_s0 & (rx_hvalid_s0 | rx_valid_s0);
assign hdr_sop_valid_s1 = hdr_sop_s1 & rx_hvalid_s1;
assign hdr_eop_valid_s1 = hdr_eop_s1 & (rx_hvalid_s1 | rx_valid_s1);
assign hdr_sop_valid_s2 = hdr_sop_s2 & rx_hvalid_s2;
assign hdr_eop_valid_s2 = hdr_eop_s2 & (rx_hvalid_s2 | rx_valid_s2);
assign hdr_sop_valid_s3 = hdr_sop_s3 & rx_hvalid_s3;
assign hdr_eop_valid_s3 = hdr_eop_s3 & (rx_hvalid_s3 | rx_valid_s3);


always @(posedge pld_clk)
begin
   if (~pld_rst_n)
     begin
       hdr_sop_s0_f <= 1'd0;
       hdr_sop_s1_f <= 1'd0;
       hdr_sop_valid_s0_f <= 1'd0;
       hdr_sop_valid_s1_f <= 1'd0;
       hdr_eop_s0_f <= 1'd0;
       hdr_eop_s1_f <= 1'd0;
       hdr_eop_s0_ff <= 1'd0;
       hdr_eop_s1_ff <= 1'd0;
       hdr_eop_valid_s0_f <= 1'd0;
       hdr_eop_valid_s1_f <= 1'd0;
       hdr_eop_valid_s0_ff <= 1'd0;
       hdr_eop_valid_s1_ff <= 1'd0;    
       tlp_is_np_s0_f <= 1'd0;
       tlp_is_np_s1_f <= 1'd0;
       hdr_sop_s2_f <= 1'd0;
       hdr_sop_s3_f <= 1'd0;
       hdr_sop_valid_s2_f <= 1'd0;
       hdr_sop_valid_s3_f <= 1'd0;
       hdr_eop_s2_f <= 1'd0;
       hdr_eop_s3_f <= 1'd0;
       hdr_eop_valid_s2_f <= 1'd0;
       hdr_eop_valid_s3_f <= 1'd0;
       hdr_eop_valid_s2_ff <= 1'd0;
       hdr_eop_valid_s3_ff <= 1'd0;  
       tlp_is_np_s2_f <= 1'd0;
       tlp_is_np_s3_f <= 1'd0;
     end
   else
     begin
       hdr_sop_s0_f <= hdr_sop_s0;
       hdr_sop_s1_f <= hdr_sop_s1;
       hdr_sop_valid_s0_f <= hdr_sop_valid_s0;
       hdr_sop_valid_s1_f <= hdr_sop_valid_s1;
       hdr_eop_s0_f <= hdr_eop_s0;
       hdr_eop_s1_f <= hdr_eop_s1;
       hdr_eop_s0_ff <= hdr_eop_s0_f;
       hdr_eop_s1_ff <= hdr_eop_s1_f;
       hdr_eop_valid_s0_f <= hdr_eop_valid_s0;
       hdr_eop_valid_s1_f <= hdr_eop_valid_s1;
       hdr_eop_valid_s0_ff <= hdr_eop_valid_s0_f;
       hdr_eop_valid_s1_ff <= hdr_eop_valid_s1_f;
       tlp_is_np_s0_f <= tlp_is_np_s0;
       tlp_is_np_s1_f <= tlp_is_np_s1;
       
   
       hdr_sop_s2_f <= hdr_sop_s2;
       hdr_sop_s3_f <= hdr_sop_s3;
       hdr_sop_valid_s2_f <= hdr_sop_valid_s2;
       hdr_sop_valid_s3_f <= hdr_sop_valid_s3;
       hdr_eop_s2_f <= hdr_eop_s2;
       hdr_eop_s3_f <= hdr_eop_s3;
       hdr_eop_valid_s2_f <= hdr_eop_valid_s2;
       hdr_eop_valid_s3_f <= hdr_eop_valid_s3;
       hdr_eop_valid_s2_ff <= hdr_eop_valid_s2_f;
       hdr_eop_valid_s3_ff <= hdr_eop_valid_s3_f;
         tlp_is_np_s2_f <= tlp_is_np_s2;
         tlp_is_np_s3_f <= tlp_is_np_s3;
     
     end
end

//
// TLP Header Decode
//
// synthesis translate_off
//
  avst4to1_ss_tlp_hdr_decode tlp_hdr_decode_s0(
    .pld_clk      (pld_clk),
    .pld_rst_n    (pld_rst_n),
    .tlp_valid    (pld_rx.rx_st_hvalid_s0_o),
    .tlp_sop      (pld_rx.rx_st_sop_s0_o),
    .tlp_hdr      (pld_rx.rx_st_hdr_s0_o[127:0]),
    // unconnected ports
    .tlp_crd_type (),
    .func_num_val(),
    .bcast_msg(),
    .func_num(),
    .mem_addr_val(),
    .mem_64b_addr(),
    .mem_addr()
  );
  
  avst4to1_ss_tlp_hdr_decode tlp_hdr_decode_s1(
    .pld_clk      (pld_clk),
    .pld_rst_n    (pld_rst_n),
    .tlp_valid    (pld_rx.rx_st_hvalid_s1_o),
    .tlp_sop      (pld_rx.rx_st_sop_s1_o),
    .tlp_hdr      (pld_rx.rx_st_hdr_s1_o[127:0]),
    // unconnected ports
    .tlp_crd_type (),
    .func_num_val(),
    .bcast_msg(),
    .func_num(),
    .mem_addr_val(),
    .mem_64b_addr(),
    .mem_addr()
  );
    avst4to1_ss_tlp_hdr_decode tlp_hdr_decode_s2(
      .pld_clk      (pld_clk),
      .pld_rst_n    (pld_rst_n),
      
      .tlp_valid    (pld_rx.rx_st_hvalid_s2_o),
      .tlp_sop      (pld_rx.rx_st_sop_s2_o),
      .tlp_hdr      (pld_rx.rx_st_hdr_s2_o[127:0]),
      
      // unconnected ports
      .tlp_crd_type (),
      .func_num_val(),
      .bcast_msg(),
      .func_num(),
      .mem_addr_val(),
      .mem_64b_addr(),
      .mem_addr()
    );
    
    avst4to1_ss_tlp_hdr_decode tlp_hdr_decode_s3(
      .pld_clk      (pld_clk),
      .pld_rst_n    (pld_rst_n),
      
      .tlp_valid    (pld_rx.rx_st_hvalid_s3_o),
      .tlp_sop      (pld_rx.rx_st_sop_s3_o),
      .tlp_hdr      (pld_rx.rx_st_hdr_s3_o[127:0]),
      
      // unconnected ports
      .tlp_crd_type (),
      .func_num_val(),
      .bcast_msg(),
      .func_num(),
      .mem_addr_val(),
      .mem_64b_addr(),
      .mem_addr()
    );
//synthesis translate_on

assign tlp_is_np_s0 = tlp_crd_type_s0[1:0] == 2'd1 ? 1'd1 : 1'd0;
assign tlp_is_np_s1 = tlp_crd_type_s1[1:0] == 2'd1 ? 1'd1 : 1'd0;
assign tlp_is_np_s2 = tlp_crd_type_s2[1:0] == 2'd1 ? 1'd1 : 1'd0;
assign tlp_is_np_s3 = tlp_crd_type_s3[1:0] == 2'd1 ? 1'd1 : 1'd0;
//
// Update RX credits
//

assign pld_rx_hdr_crdup[2:0]  = hdr_data_crd_fifo_empty_f ? 3'd0 : hdr_data_crd_fifo_dout_f[39:37];
assign pld_rx_data_crdup      = hdr_data_crd_fifo_empty_f ? 1'd0 : hdr_data_crd_fifo_dout_f[36];
assign pld_rx_cpl_crdup[11:0] = hdr_data_crd_fifo_empty_f | ~pld_rx_data_crdup ? 12'd0 : hdr_data_crd_fifo_dout_f[11:0];
assign pld_rx_np_crdup[11:0]  = hdr_data_crd_fifo_empty_f | ~pld_rx_data_crdup ? 12'd0 : hdr_data_crd_fifo_dout_f[23:12];
assign pld_rx_p_crdup[11:0]   = hdr_data_crd_fifo_empty_f | ~pld_rx_data_crdup ? 12'd0 : hdr_data_crd_fifo_dout_f[35:24];
assign hdr_data_crd_fifo_din[39:0] = {cpl_sop_in_data_cycle_f, np_sop_in_data_cycle_f, p_sop_in_data_cycle_f, wr_n_data_cycles_ff, prim_rx_p_crdup_f[11:0], prim_rx_np_crdup_f[11:0], prim_rx_cpl_crdup_f[11:0]};

avst4to1_ss_fifo_vcd 
  #(
    .SYNC(0),           

    .IN_DATAWIDTH(40),   
    .OUT_DATAWIDTH(40),    

    .ADDRWIDTH(6),      
    .FULL_DURING_RST(1),
    .FWFT_ENABLE(1),    
    .FREQ_IMPROVE(0),   
    .USE_ASYNC_RST(1)   
  )
hdr_data_crd_fifo (
    .rst(~crd_prim_rst_n), 
    .wr_clock(avst4to1_prim_clk),
    .rd_clock(pld_clk),
    .wr_en(1'b1), 
    .rd_en(~hdr_data_crd_fifo_empty),
    .full(hdr_data_crd_fifo_full),
    .empty(hdr_data_crd_fifo_empty), 
    .din(hdr_data_crd_fifo_din[39:0]),  
    .dout(hdr_data_crd_fifo_dout[39:0]),
    // unconnected ports
    .prog_full_offset(),
    .prog_empty_offset(),
    .prog_full(),
    .prog_empty(),
    .underflow(),
    .overflow(),
    .word_cnt_rd_side(),
    .word_cnt_wr_side()
);

always @(posedge pld_clk)
begin
       hdr_data_crd_fifo_empty_f <= hdr_data_crd_fifo_empty;
       hdr_data_crd_fifo_dout_f <= hdr_data_crd_fifo_dout;
end
//
//
always_comb
begin
  case(avst4to1_core_max_payload[1:0])
  2'b11 : // RESERVED
    begin
      // blocking all credit updates since it's not valid
      data_512b_cycles_per_crd[3:0] = 4'd0;
    end
  2'b10 : // 512B max payload/64B per data cycle
    begin
      data_512b_cycles_per_crd[3:0] = 4'd8;
    end
  2'b01 : // 256B max payload/64B per data cycle
    begin
      data_512b_cycles_per_crd[3:0] = 4'd4;
    end
  2'b00 : // 128B max payload/64B per data cycle
    begin
      data_512b_cycles_per_crd[3:0] = 4'd2; //128B (Max data payload size) / 64B (data_fifo_byte_width)
    end
  endcase
end


assign avst4to1_rx_data_dw_valid_ii[15:0] = (avst4to1_rx_eop_i & avst4to1_rx_hdr_i[23]) ? ((avst4to1_rx_data_dw_valid_i[15:0] != 16'd0) ? avst4to1_rx_data_dw_valid_i[15:0] >> 1 : avst4to1_rx_data_dw_valid_i[15:0]) : avst4to1_rx_data_dw_valid_i[15:0];

always @(posedge avst4to1_prim_clk) 
begin
  if (~avst4to1_prim_rst_n)
    begin
      avst4to1_rx_sop_i_f <= 1'd0;
      
      avst4to1_rx_data_dw_valid_ii_f[15:0] <= 16'd0;
      avst4to1_rx_hdr_i_f[127:0] <= 128'd0;
       
      wr_n_data_cycles <= 1'd0;
      wr_n_data_cycles_f <= 1'd0;
      wr_n_data_cycles_ff <= 1'd0;
      n_data_cycles[3:0] <= 4'd0;
      sop_in_data_cycle <= 1'd0;
    end
  else
    begin
      avst4to1_rx_sop_i_f <= avst4to1_rx_sop_i;
      avst4to1_rx_data_dw_valid_ii_f[15:0] <= avst4to1_rx_data_dw_valid_ii[15:0];
      avst4to1_rx_hdr_i_f[127:0] <= avst4to1_rx_hdr_i[127:0];
      wr_n_data_cycles_f <= wr_n_data_cycles;
      wr_n_data_cycles_ff <= wr_n_data_cycles_f;
      
      if (avst4to1_rx_data_dw_valid_ii_f[0]) begin
        wr_n_data_cycles <= 1'd1;
        n_data_cycles[3:0] <= avst4to1_rx_data_dw_valid_ii_f[12] + avst4to1_rx_data_dw_valid_ii_f[8] + avst4to1_rx_data_dw_valid_ii_f[4] + avst4to1_rx_data_dw_valid_ii_f[0];
        if (avst4to1_rx_sop_i_f)
           sop_in_data_cycle <= 1'd1;
        else
           sop_in_data_cycle <= 1'd0;
      end
      else begin
        n_data_cycles[3:0] <= 4'd0;
        if (avst4to1_rx_sop_i_f) begin
          wr_n_data_cycles <= 1'd1;
          sop_in_data_cycle <= 1'd1;
        end
        else begin
          wr_n_data_cycles <= 1'd0;
          sop_in_data_cycle <= 1'd0;
        end
      end
    end
end


always @(posedge avst4to1_prim_clk)
begin
   if (~crd_prim_rst_n)
     begin
       avst4to1_tlp_w_data <= 1'd0;
       avst4to1_tlp_w_data_f <= 1'd0;
       avst4to1_tlp_w_data_ff <= 1'd0;

       avst4to1_bcast_msg_type_f <= 1'd0;
       avst4to1_bcast_msg_type_ff <= 1'd0;
       
       fifo_sel_crd_type_f[1:0] <= 2'd0;
       fifo_sel_crd_type_ff[1:0] <= 2'd0;
       
       avst4to1_rx_eop_i_f <= 1'b0;
       avst4to1_rx_eop_i_ff <= 1'b0;
       
       prim_rx_cpl_crdup_i[11:0] <= 12'd0;
       prim_rx_np_crdup_i[11:0] <= 12'd0;
       prim_rx_p_crdup_i[11:0] <= 12'd0;
       
       prim_rx_cpl_crdup_f[11:0] <= 12'd0;
       prim_rx_np_crdup_f[11:0] <= 12'd0;
       prim_rx_p_crdup_f[11:0] <= 12'd0;
       cpl_sop_in_data_cycle   <= 1'd0;
       np_sop_in_data_cycle    <= 1'd0;
       p_sop_in_data_cycle     <= 1'd0;
       cpl_sop_in_data_cycle_f <= 1'd0;
       np_sop_in_data_cycle_f  <= 1'd0;
       p_sop_in_data_cycle_f   <= 1'd0;
     end
   else
     begin
       avst4to1_tlp_w_data <= avst4to1_rx_hdr_i[6];
       avst4to1_tlp_w_data_f <= avst4to1_tlp_w_data;
       avst4to1_tlp_w_data_ff <= avst4to1_tlp_w_data_f;

       if (avst4to1_rx_sop_i)
         avst4to1_bcast_msg_type_f <= avst4to1_bcast_msg_type;

       avst4to1_bcast_msg_type_ff <= avst4to1_bcast_msg_type_f;
       fifo_sel_crd_type_f[1:0] <= fifo_sel_crd_type[1:0];
       fifo_sel_crd_type_ff[1:0] <= fifo_sel_crd_type_f[1:0];
       avst4to1_rx_eop_i_f <= avst4to1_rx_eop_i;
       avst4to1_rx_eop_i_ff <= avst4to1_rx_eop_i_f;
       prim_rx_cpl_crdup_f[11:0] <= prim_rx_cpl_crdup_i[11:0];
       prim_rx_np_crdup_f[11:0]  <= prim_rx_np_crdup_i[11:0];
       prim_rx_p_crdup_f[11:0]   <= prim_rx_p_crdup_i[11:0];
       cpl_sop_in_data_cycle_f <= cpl_sop_in_data_cycle;
       np_sop_in_data_cycle_f  <= np_sop_in_data_cycle;
       p_sop_in_data_cycle_f   <= p_sop_in_data_cycle;
       
       if (wr_n_data_cycles & ~avst4to1_bcast_msg_type_ff)
         begin
           case (fifo_sel_crd_type_ff[1:0])
           CPL_TLP:
             begin
                 cpl_sop_in_data_cycle <= sop_in_data_cycle;
                 np_sop_in_data_cycle <= 1'd0;
                 p_sop_in_data_cycle <= 1'd0;
                 if (avst4to1_tlp_w_data_f) 
                  prim_rx_cpl_crdup_i[11:0] <= {8'd0, n_data_cycles[3:0]};
             end
           NP_TLP:
             begin
                 cpl_sop_in_data_cycle <= 1'd0;
                 np_sop_in_data_cycle <= sop_in_data_cycle;
                 p_sop_in_data_cycle <= 1'd0;
                 if (avst4to1_tlp_w_data_f)
                   prim_rx_np_crdup_i[11:0] <= {8'd0, n_data_cycles[3:0]};
             end
           P_TLP:
             begin
                 cpl_sop_in_data_cycle <= 1'd0;
                 np_sop_in_data_cycle <= 1'd0;
                 p_sop_in_data_cycle <= sop_in_data_cycle;
                 if (avst4to1_tlp_w_data_f)
                   prim_rx_p_crdup_i[11:0] <= {8'd0, n_data_cycles[3:0]};
             end
           default:
             begin
               cpl_sop_in_data_cycle <= 1'd0;
               np_sop_in_data_cycle <= 1'd0;
               p_sop_in_data_cycle <= 1'd0; 
               prim_rx_cpl_crdup_i[11:0] <= 12'd0;
               prim_rx_np_crdup_i[11:0] <= 12'd0;
               prim_rx_p_crdup_i[11:0] <= 12'd0;
             end
           endcase
         end
         else begin
           cpl_sop_in_data_cycle <= 1'd0;
           np_sop_in_data_cycle <= 1'd0;
           p_sop_in_data_cycle <= 1'd0;
           prim_rx_cpl_crdup_i[11:0] <= 12'd0;
           prim_rx_np_crdup_i[11:0] <= 12'd0;
           prim_rx_p_crdup_i[11:0] <= 12'd0;
         end
     end
end
//
// FIFO's Control State Machine
//

always @(posedge avst4to1_prim_clk) 
begin
   if (~avst4to1_prim_rst_n)
     begin
       fifo_hdr_ctrl_rd_en <= 1'd0;
       fifo_hdr_rd_en_s0 <= 1'd0;
       fifo_hdr_rd_en_s1 <= 1'd0;
       fifo_data_rd_en_s0 <= 1'd0;
       fifo_data_rd_en_s1 <= 1'd0;
       fifo_hdr_rd_en_s2 <= 1'd0;
       fifo_hdr_rd_en_s3 <= 1'd0;
       fifo_data_rd_en_s2 <= 1'd0;
       fifo_data_rd_en_s3 <= 1'd0;  
       two_eops <= 1'd0;
       fifo_tlp_eop_rd_en <= 1'd0;
       hdr_data_en <= 1'd0;
       hdr_data_en_f <= 1'd0;
       hdr_sel[1:0] <= 2'd0;
       data_sel[1:0]<= 2'd0;
       data_sel_f[1:0] <= 2'd0;
       data_cycle <= 1'd0;
       curr_data_cycle[1:0] <= 2'd0;
       first_S1_cycle <= 1'd0;
       second_tlp <= 1'd0;
       third_tlp <= 1'd0;
       fourth_tlp <= 1'd0;
       delay_4_empty_upd <= 1'd0;
       fifo_tlp_eop_dout_f <= 'd0;
       fifo_ctrl_st <= CTRL_IDLE;
     end
   else
     begin
       data_sel_f <= data_sel;
       hdr_data_en_f <= hdr_data_en;
       
       case(fifo_ctrl_st)
       CTRL_IDLE :
          begin
            data_cycle <= 1'd0;
            fifo_hdr_rd_en_s0 <= 1'd0;
            fifo_hdr_rd_en_s1 <= 1'd0;
            fifo_data_rd_en_s0 <= 1'd0;
            fifo_data_rd_en_s1 <= 1'd0;
            fifo_hdr_rd_en_s2 <= 1'd0;
            fifo_hdr_rd_en_s3 <= 1'd0;
            fifo_data_rd_en_s2 <= 1'd0;
            fifo_data_rd_en_s3 <= 1'd0;
            if (~fifo_hdr_ctrl_empty & ~fifo_tlp_eop_empty & avst4to1_rx_data_avail & avst4to1_rx_hdr_avail & avst4to1_rx_nph_hdr_avail & delay_4_empty_upd)
              begin
                // S0
                if (hdr_ctrl_dout_sop_s0 & ~second_tlp)
                  begin 
                    data_sel[1:0] <= 2'd0;
                    hdr_sel[1:0] <= 2'd0;
                    curr_data_cycle[1:0] <= 2'd0;
                    first_S1_cycle <= 1'd0;
                    third_tlp <= 1'd0;
                    fourth_tlp <= 1'd0;
                    
                    if ((avst4to1_rx_nph_hdr_avail & hdr_dout_is_np_s0) | 
                                               (~fifo_data_empty_s0 & avst4to1_rx_data_avail & avst4to1_rx_hdr_avail & ~hdr_dout_is_np_s0))
                      begin
                        hdr_data_en <= 1'd1;
                        if (hdr_ctrl_dout_sop_s3 | hdr_ctrl_dout_sop_s2 | hdr_ctrl_dout_sop_s1)
                          begin
                            second_tlp <= 1'd1;
                            fifo_hdr_ctrl_rd_en <= 1'd0;
                          end
                        else
                          begin
                            second_tlp <= 1'd0;
                            fifo_hdr_ctrl_rd_en <= 1'd1;
                          end
                        if (~fifo_tlp_eop_dout[1] & fifo_tlp_eop_dout[0])
                          begin
                            two_eops <= 1'd0;
                            fifo_tlp_eop_rd_en <= 1'd1;
                            fifo_tlp_eop_dout_f <= 'd0;
                          end
                        else
                          begin
                            two_eops <= 1'd1;
                            
                            fifo_tlp_eop_rd_en <= 1'd0;
                            //fifo_tlp_eop_dout_f <= fifo_tlp_eop_dout - 'd1;
                            fifo_tlp_eop_dout_f <= fifo_tlp_eop_dout_f - 'd1;
                          end
                        
                        fifo_ctrl_st <= RD_HDR_S0_FIFO;
                      end
                    else
                      begin
                        second_tlp <= 1'd0;
                        
                        fifo_tlp_eop_rd_en <= 1'd0;
                        fifo_hdr_ctrl_rd_en <= 1'd0;
                        
                        fifo_ctrl_st <= CTRL_IDLE;
                      end
                  end
                else
                  begin
                    // S1
                    first_S1_cycle <= 1'd1;
                    if (hdr_ctrl_dout_sop_s1 & ~third_tlp)
                      begin
                        data_sel[1:0] <= 2'd1;
                        hdr_sel[1:0] <= 2'd1;
                        curr_data_cycle[1:0] <= 2'd1;
                        fourth_tlp <= 1'd0;
                        if ((avst4to1_rx_nph_hdr_avail & hdr_dout_is_np_s1) | 
                                                   (~fifo_data_empty_s1 & avst4to1_rx_data_avail & avst4to1_rx_hdr_avail & ~hdr_dout_is_np_s1))
                          begin
                            hdr_data_en <= 1'd1;
                            if (hdr_ctrl_dout_sop_s3 | hdr_ctrl_dout_sop_s2)
                              begin
                                third_tlp <= 1'd1;
                                fifo_hdr_ctrl_rd_en <= 1'd0;
                              end
                            else
                              begin
                                second_tlp <= 1'd0;
                                third_tlp <= 1'd0;
                                fifo_hdr_ctrl_rd_en <= 1'd1;
                              end
                                if ((~fifo_tlp_eop_dout_f[1] & fifo_tlp_eop_dout_f[0]))
                                  begin
                                    two_eops <= 1'd0;
                                    fifo_tlp_eop_rd_en <= 1'd1;
                                    fifo_tlp_eop_dout_f <= 'd0;
                                  end
                                else
                                  begin
                                    two_eops <= 1'd1;
                                    fifo_tlp_eop_rd_en <= 1'd0;
                                    fifo_tlp_eop_dout_f <= fifo_tlp_eop_dout_f - 'd1;
                                  end
                            fifo_ctrl_st <= RD_HDR_S1_FIFO;
                          end
                        else 
                          begin
                            third_tlp <= 1'd0;
                            fifo_tlp_eop_rd_en <= 1'd0;
                            fifo_hdr_ctrl_rd_en <= 1'd0;
                            fifo_ctrl_st <= CTRL_IDLE;
                          end
                      end
                    else
                      begin
                        // S2
                        if (hdr_ctrl_dout_sop_s2 & ~fourth_tlp)
                          begin
                            data_sel[1:0] <= 2'd2;
                            hdr_sel[1:0] <= 2'd2;
                            
                            curr_data_cycle[1:0] <= 2'd2;
                            
                            if ((avst4to1_rx_nph_hdr_avail & hdr_dout_is_np_s2) | 
                                                       (~fifo_data_empty_s2 & avst4to1_rx_data_avail & avst4to1_rx_hdr_avail & ~hdr_dout_is_np_s2))
                              begin
                                hdr_data_en <= 1'd1;
                                
                                if (hdr_ctrl_dout_sop_s3)
                                  begin
                                    fourth_tlp <= 1'd1;
                                    
                                    fifo_hdr_ctrl_rd_en <= 1'd0;
                                  end
                                else
                                  begin
                                    second_tlp <= 1'd0;
                                    third_tlp <= 1'd0;
                                    fourth_tlp <= 1'd0;
                                    
                                    fifo_hdr_ctrl_rd_en <= 1'd1;
                                  end
                                    if ((~fifo_tlp_eop_dout_f[1] & fifo_tlp_eop_dout_f[0]))
                                      begin
                                        two_eops <= 1'd0;
                                        
                                        fifo_tlp_eop_rd_en <= 1'd1;
                                        fifo_tlp_eop_dout_f <= 'd0;
                                      end
                                    else
                                      begin
                                        two_eops <= 1'd1;
                                        
                                        fifo_tlp_eop_rd_en <= 1'd0;
                                        fifo_tlp_eop_dout_f <= fifo_tlp_eop_dout_f - 'd1;
                                      end
                                fifo_ctrl_st <= RD_HDR_S2_FIFO;
                              end
                            else 
                              begin
                                fourth_tlp <= 1'd0;
                                
                                fifo_tlp_eop_rd_en <= 1'd0;
                                fifo_hdr_ctrl_rd_en <= 1'd0;
                                
                                fifo_ctrl_st <= CTRL_IDLE;
                              end
                          end
                        else
                          begin
                            // S3
                            data_sel[1:0] <= 2'd3;
                            hdr_sel[1:0] <= 2'd3;
                            
                            curr_data_cycle[1:0] <= 2'd3;
                            
                            if ((avst4to1_rx_nph_hdr_avail & hdr_dout_is_np_s3) | 
                                                       (~fifo_data_empty_s3 & avst4to1_rx_data_avail & avst4to1_rx_hdr_avail & ~hdr_dout_is_np_s3))
                              begin
                                hdr_data_en <= 1'd1;
                                
                                second_tlp <= 1'd0;
                                third_tlp <= 1'd0;
                                fourth_tlp <= 1'd0;
                                
                                fifo_hdr_ctrl_rd_en <= 1'd1;
                                
                                if ((~fifo_tlp_eop_dout_f[1] & fifo_tlp_eop_dout_f[0]))
                                  begin
                                    two_eops <= 1'd0;
                                    
                                    fifo_tlp_eop_rd_en <= 1'd1;
                                    fifo_tlp_eop_dout_f <= 'd0;
                                  end
                                else
                                  begin
                                    two_eops <= 1'd1;
                                    
                                    fifo_tlp_eop_rd_en <= 1'd0;
                                    fifo_tlp_eop_dout_f <= fifo_tlp_eop_dout_f - 'd1;
                                  end
                                
                                fifo_ctrl_st <= RD_HDR_S3_FIFO;
                              end
                            else 
                              begin
                                fifo_tlp_eop_rd_en <= 1'd0;
                                fifo_hdr_ctrl_rd_en <= 1'd0;
                                
                                fifo_ctrl_st <= CTRL_IDLE;
                              end
                          end
                      end
                  end
              end
            else
              begin
                if (~two_eops)
                  fifo_tlp_eop_dout_f <= fifo_tlp_eop_dout;
                hdr_data_en <= 1'd0;
                data_sel[1:0] <= 2'd0;
                hdr_sel[1:0] <= 2'd0;
                delay_4_empty_upd <= 1'd1;
                first_S1_cycle <= 1'd0;
                if (fifo_tlp_eop_empty)
                  two_eops <= 1'd0;
                if (fifo_hdr_ctrl_empty)
                  begin
                    second_tlp <= 1'd0;
                    third_tlp <= 1'd0;
                    fourth_tlp <= 1'd0;
                  end
                fifo_tlp_eop_rd_en <= 1'd0;
                fifo_hdr_ctrl_rd_en <= 1'd0;
                fifo_ctrl_st <= CTRL_IDLE;
              end
          end
       RD_HDR_S0_FIFO :
          begin
            first_S1_cycle <= 1'd0;
            
            fifo_tlp_eop_rd_en <= 1'd0;
            fifo_hdr_ctrl_rd_en <= 1'd0;
            
            delay_4_empty_upd <= 1'd0;
            if (hdr_data_en)
              data_cycle <= ~data_cycle;
            
            if (hdr_data_en)
              curr_data_cycle[1:0] <= curr_data_cycle[1:0] + 2'd2;
            
            hdr_sel[1:0] <= 2'd0;
            data_sel[1:0] <= 2'd0;
            
            if (data_cycle)
              fifo_data_rd_en_s0 <= 1'd0;
            else
              fifo_data_rd_en_s0 <= 1'd1;
            
            if (((data_dout_eop_s0) & hdr_data_en) | (data_cycle))
              fifo_data_rd_en_s1 <= 1'd0;
            else
              fifo_data_rd_en_s1 <= 1'd1;
            
            if ((data_dout_eop_s1 & hdr_data_en) | (~data_cycle))
              fifo_data_rd_en_s2 <= 1'd0;
            else
              fifo_data_rd_en_s2 <= 1'd1;
            
            if ((data_dout_eop_s2 & hdr_data_en) | (~data_cycle))
              fifo_data_rd_en_s3 <= 1'd0;
            else
              fifo_data_rd_en_s3 <= 1'd1;
            
            if ((((data_dout_eop_s1 | data_dout_eop_s0) & ~data_cycle) |
                 ((data_dout_eop_s3 | data_dout_eop_s2) & data_cycle)) & hdr_data_en)
              begin
                hdr_data_en <= 1'd0;
                fifo_hdr_rd_en_s0 <= 1'd1;
                
                fifo_ctrl_st <= CTRL_IDLE;
              end
            else
              begin
                fifo_ctrl_st <= RD_HDR_S0_FIFO;
              end
          end
       RD_HDR_S1_FIFO :
          begin
            fifo_tlp_eop_rd_en <= 1'd0;
            fifo_hdr_ctrl_rd_en <= 1'd0;
            
            delay_4_empty_upd <= 1'd0;
            if (hdr_data_en)
              data_cycle <= ~data_cycle;
            if (hdr_data_en)
              curr_data_cycle[1:0] <= curr_data_cycle[1:0] + 2'd2;
            
            hdr_sel[1:0] <= 2'd1;
            data_sel[1:0] <= 2'd1;
            if (data_cycle)
              fifo_data_rd_en_s1 <= 1'd0;
            else
              fifo_data_rd_en_s1 <= 1'd1;
            
            if ((data_dout_eop_s1 & hdr_data_en) | data_cycle)
              fifo_data_rd_en_s2 <= 1'd0;
            else
              fifo_data_rd_en_s2 <= 1'd1;
            
            if ((data_dout_eop_s2 & hdr_data_en) | ~data_cycle)
              fifo_data_rd_en_s3 <= 1'd0;
            else
              fifo_data_rd_en_s3 <= 1'd1;
            
            if ((data_dout_eop_s3 & hdr_data_en) | ~data_cycle)
              fifo_data_rd_en_s0 <= 1'd0;
            else
              fifo_data_rd_en_s0 <= 1'd1;
            
            if ((((data_dout_eop_s2 | data_dout_eop_s1) & ~data_cycle) |
                 ((data_dout_eop_s0 | data_dout_eop_s3) &  data_cycle)) & hdr_data_en)
              begin
                hdr_data_en <= 1'd0;
                fifo_hdr_rd_en_s1 <= 1'd1;
                fifo_ctrl_st <= CTRL_IDLE;
              end
            else
              begin
                fifo_ctrl_st <= RD_HDR_S1_FIFO;
              end
          end
       RD_HDR_S2_FIFO :
          begin
            delay_4_empty_upd <= 1'd0;
            
            if (hdr_data_en)
            data_cycle <= ~data_cycle;
            
            first_S1_cycle <= 1'd0;
            fifo_tlp_eop_rd_en <= 1'd0;
            fifo_hdr_ctrl_rd_en <= 1'd0;
            
            if (hdr_data_en)
              curr_data_cycle[1:0] <= curr_data_cycle[1:0] + 2'd2;
            
            hdr_sel[1:0] <= 2'd2;
            data_sel[1:0] <= 2'd2;
            
            if (data_cycle)
              fifo_data_rd_en_s2 <= 1'd0;
            else
              fifo_data_rd_en_s2 <= 1'd1;
            
            if (((data_dout_eop_s2) & hdr_data_en) | (data_cycle))
              fifo_data_rd_en_s3 <= 1'd0;
            else
              fifo_data_rd_en_s3 <= 1'd1;
            
            if ((data_dout_eop_s3 & hdr_data_en) | (~data_cycle))
              fifo_data_rd_en_s0 <= 1'd0;
            else
              fifo_data_rd_en_s0 <= 1'd1;
            
            if ((data_dout_eop_s0 & hdr_data_en) | (~data_cycle))
              fifo_data_rd_en_s1 <= 1'd0;
            else
              fifo_data_rd_en_s1 <= 1'd1;
            
            if ((((data_dout_eop_s3 | data_dout_eop_s2) & ~data_cycle) |
                 ((data_dout_eop_s1 | data_dout_eop_s0) & data_cycle)) & hdr_data_en)
              begin
                hdr_data_en <= 1'd0;
                fifo_hdr_rd_en_s2 <= 1'd1;
                
                fifo_ctrl_st <= CTRL_IDLE;
              end
            else
              begin
                fifo_ctrl_st <= RD_HDR_S2_FIFO;
              end
          end
       RD_HDR_S3_FIFO :
          begin
            delay_4_empty_upd <= 1'd0;
            
            if (hdr_data_en)
              data_cycle <= ~data_cycle;
            
            second_tlp <= 1'd0;
            third_tlp <= 1'd0;
            fourth_tlp <= 1'd0;
            
            first_S1_cycle <= 1'd0;
            fifo_tlp_eop_rd_en <= 1'd0;
            fifo_hdr_ctrl_rd_en <= 1'd0;
            
            if (hdr_data_en)
              curr_data_cycle[1:0] <= curr_data_cycle[1:0] + 2'd2;
            
            hdr_sel[1:0] <= 2'd3;
            data_sel[1:0] <= 2'd3;
            
            if (data_cycle)
              fifo_data_rd_en_s3 <= 1'd0;
            else
              fifo_data_rd_en_s3 <= 1'd1;
            
            if ((data_dout_eop_s3 & hdr_data_en) | data_cycle)
              fifo_data_rd_en_s0 <= 1'd0;
            else
              fifo_data_rd_en_s0 <= 1'd1;
            
            if ((data_dout_eop_s0 & hdr_data_en) | ~data_cycle)
              fifo_data_rd_en_s1 <= 1'd0;
            else
              fifo_data_rd_en_s1 <= 1'd1;
            
            if ((data_dout_eop_s1 & hdr_data_en) | ~data_cycle)
              fifo_data_rd_en_s2 <= 1'd0;
            else
              fifo_data_rd_en_s2 <= 1'd1;
            
            if ((((data_dout_eop_s0 | data_dout_eop_s3) & ~data_cycle) |
                 ((data_dout_eop_s2 | data_dout_eop_s1) &  data_cycle)) & hdr_data_en)
              begin
                hdr_data_en <= 1'd0;
                fifo_hdr_rd_en_s3 <= 1'd1;
                
                fifo_ctrl_st <= CTRL_IDLE;
              end
            else
              begin
                fifo_ctrl_st <= RD_HDR_S3_FIFO;
              end
          end
       endcase
     end
end

//
// HDR/Data Control FIFO
//
  assign fifo_hdr_ctrl_wr_en = (hdr_sop_valid_s3_f | hdr_sop_valid_s2_f | hdr_sop_valid_s1_f | hdr_sop_valid_s0_f);
  assign fifo_hdr_ctrl_din[7:0] = {tlp_is_np_s3_f, tlp_is_np_s2_f, tlp_is_np_s1_f, tlp_is_np_s0_f, hdr_sop_s3_f, hdr_sop_s2_f, hdr_sop_s1_f, hdr_sop_s0_f};
  
  assign {hdr_dout_is_np_s3, hdr_dout_is_np_s2, hdr_dout_is_np_s1, hdr_dout_is_np_s0, hdr_ctrl_dout_sop_s3, hdr_ctrl_dout_sop_s2, hdr_ctrl_dout_sop_s1, hdr_ctrl_dout_sop_s0} = fifo_hdr_ctrl_empty ? 8'd0 : fifo_hdr_ctrl_dout[7:0];

avst4to1_ss_fifo_vcd
  #(
    .SYNC(0),           
                        
    .IN_DATAWIDTH(8),   
    .OUT_DATAWIDTH(8),    
    .ADDRWIDTH(HDR_FIFO_ADDR_WIDTH+1),      
    .FULL_DURING_RST(1),  
    .FWFT_ENABLE(1),    
    .FREQ_IMPROVE(0),   
    .USE_ASYNC_RST(1)   
  )
fifo_hdr_ctrl (
    .rst(~pld_rst_n), 
    .wr_clock(pld_clk),
    .rd_clock(avst4to1_prim_clk),
    .wr_en(fifo_hdr_ctrl_wr_en), 
    .rd_en(fifo_hdr_ctrl_rd_en), 
    .din(fifo_hdr_ctrl_din[7:0]),
    .dout(fifo_hdr_ctrl_dout[7:0]),
    .full(fifo_hdr_ctrl_full),
    .empty(fifo_hdr_ctrl_empty), 
    // unconnected ports
    .prog_full_offset(),
    .prog_empty_offset(),
    .prog_full(),
    .prog_empty(),
    .underflow(),
    .overflow(),
    .word_cnt_rd_side(),
    .word_cnt_wr_side()
);


assign fifo_tlp_eop_wr_en = hdr_eop_valid_s3_ff | hdr_eop_valid_s2_ff | hdr_eop_valid_s1_ff | hdr_eop_valid_s0_ff;
assign fifo_tlp_eop_din[2:0] = hdr_eop_valid_s3_ff + hdr_eop_valid_s2_ff + hdr_eop_valid_s1_ff + hdr_eop_valid_s0_ff;

always_ff@(posedge pld_clk) fifo_tlp_eop_empty_f <= fifo_tlp_eop_empty;
always_ff@(posedge pld_clk) fifo_tlp_eop_dout_d <= fifo_tlp_eop_dout; 
always_ff@(posedge pld_clk) two_eops_f <= two_eops ; 

avst4to1_ss_fifo_vcd
  #(
    .SYNC(0),           
                        
    .IN_DATAWIDTH(3),   
    .OUT_DATAWIDTH(3),    
    .ADDRWIDTH(HDR_FIFO_ADDR_WIDTH+1),      
    .FULL_DURING_RST(1),  
    .FWFT_ENABLE(1),    
    .FREQ_IMPROVE(0),   
    .RD_PIPE(0),   
    .USE_ASYNC_RST(1)   
  )
tlp_eop (
    .rst(~pld_rst_n), 
    .wr_clock(pld_clk),
    .rd_clock(avst4to1_prim_clk),
    .wr_en(fifo_tlp_eop_wr_en), 
    .rd_en(fifo_tlp_eop_rd_en), 
    .din(fifo_tlp_eop_din[2:0]),
    .dout(fifo_tlp_eop_dout[2:0]),
    .full(fifo_tlp_eop_full),
    .empty(fifo_tlp_eop_empty), 
    // unconnected ports
    .prog_full_offset(),
    .prog_empty_offset(),
    .prog_full(),
    .prog_empty(),
    .underflow(),
    .overflow(),
    .word_cnt_rd_side(),
    .word_cnt_wr_side()
);

// synthesis translate_off

always @(posedge pld_clk)
begin
  if (pld_rst_n)
    begin
      if (fifo_hdr_ctrl_full & fifo_hdr_ctrl_wr_en)
        $display("AVST4to1(CORE%0d RX Side): HDR CTRL FIFO Overflow @%0t", CORE_NUM, $time);
    end
end

always @(posedge pld_clk)
begin
  if (pld_rst_n)
    begin
      if (fifo_tlp_eop_full & fifo_tlp_eop_wr_en)
        $display("AVST4to1(CORE%0d RX Side): TLP EOP FIFO Overflow @%0t", CORE_NUM, $time);
    end
end
//synthesis translate_on


//
// Header FIFO's
//
logic fifo_hdr_wr_en_s0_f;
logic fifo_hdr_wr_en_s1_f;
logic fifo_hdr_wr_en_s2_f;
logic fifo_hdr_wr_en_s3_f;
logic [194:0] fifo_hdr_din_s0_f;
logic [194:0] fifo_hdr_din_s1_f;
logic [194:0] fifo_hdr_din_s2_f;
logic [194:0] fifo_hdr_din_s3_f;


      assign  fifo_hdr_din_s0 = {pld_rx.rx_st_passthrough_s0_o, tlp_crd_type_s0[1:0], pld_rx.rx_st_pvalid_s0_o[1:0], pld_rx.rx_st_tlp_RSSAI_prfx_s0_o[11:0], pld_rx.rx_st_tlp_prfx_s0_o[31:0], pld_rx.rx_st_vfactive_s0_o, pld_rx.rx_st_vfnum_s0_o[10:0], pld_rx.rx_st_pfnum_s0_o[2:0], 
                                                  pld_rx.rx_st_bar_s0_o[2:0], pld_rx.rx_st_hdr_s0_o[127:0]};
      assign  fifo_hdr_din_s1 = {pld_rx.rx_st_passthrough_s1_o, tlp_crd_type_s1[1:0], pld_rx.rx_st_pvalid_s1_o[1:0], pld_rx.rx_st_tlp_RSSAI_prfx_s1_o[11:0], pld_rx.rx_st_tlp_prfx_s1_o[31:0], pld_rx.rx_st_vfactive_s1_o, pld_rx.rx_st_vfnum_s1_o[10:0], pld_rx.rx_st_pfnum_s1_o[2:0], 
                                                  pld_rx.rx_st_bar_s1_o[2:0], pld_rx.rx_st_hdr_s1_o[127:0]};
      assign  fifo_hdr_din_s2 = {pld_rx.rx_st_passthrough_s2_o, tlp_crd_type_s2[1:0], pld_rx.rx_st_pvalid_s2_o[1:0], pld_rx.rx_st_tlp_RSSAI_prfx_s2_o[11:0], pld_rx.rx_st_tlp_prfx_s2_o[31:0], pld_rx.rx_st_vfactive_s2_o, pld_rx.rx_st_vfnum_s2_o[10:0], pld_rx.rx_st_pfnum_s2_o[2:0], 
                                                  pld_rx.rx_st_bar_s2_o[2:0], pld_rx.rx_st_hdr_s2_o[127:0]};
      assign  fifo_hdr_din_s3 = {pld_rx.rx_st_passthrough_s3_o, tlp_crd_type_s3[1:0], pld_rx.rx_st_pvalid_s3_o[1:0], pld_rx.rx_st_tlp_RSSAI_prfx_s3_o[11:0], pld_rx.rx_st_tlp_prfx_s3_o[31:0], pld_rx.rx_st_vfactive_s3_o, pld_rx.rx_st_vfnum_s3_o[10:0], pld_rx.rx_st_pfnum_s3_o[2:0], 
                                                  pld_rx.rx_st_bar_s3_o[2:0], pld_rx.rx_st_hdr_s3_o[127:0]};

assign  fifo_hdr_wr_en_s0 = hdr_sop_valid_s0;
assign  fifo_hdr_wr_en_s1 = hdr_sop_valid_s1;
assign  fifo_hdr_wr_en_s2 = hdr_sop_valid_s2;
assign  fifo_hdr_wr_en_s3 = hdr_sop_valid_s3;


always @(posedge pld_clk)
begin
  if (~pld_rst_n)
    begin
      fifo_hdr_wr_en_s0_f <= 1'd0;
      fifo_hdr_wr_en_s1_f <= 1'd0;
      fifo_hdr_wr_en_s2_f <= 1'd0;
      fifo_hdr_wr_en_s3_f <= 1'd0;
      fifo_hdr_din_s0_f[194:0] <= 195'h0;
      fifo_hdr_din_s1_f[194:0] <= 195'h0;
      fifo_hdr_din_s2_f[194:0] <= 195'h0;
      fifo_hdr_din_s3_f[194:0] <= 195'h0;
    end
  else
    begin
      fifo_hdr_wr_en_s0_f <= fifo_hdr_wr_en_s0;
      fifo_hdr_wr_en_s1_f <= fifo_hdr_wr_en_s1;
      fifo_hdr_wr_en_s2_f <= fifo_hdr_wr_en_s2;
      fifo_hdr_wr_en_s3_f <= fifo_hdr_wr_en_s3;
      fifo_hdr_din_s0_f[194:0] <= fifo_hdr_din_s0[194:0];
      fifo_hdr_din_s1_f[194:0] <= fifo_hdr_din_s1[194:0];
      fifo_hdr_din_s2_f[194:0] <= fifo_hdr_din_s2[194:0];
      fifo_hdr_din_s3_f[194:0] <= fifo_hdr_din_s3[194:0];
    end
end



avst4to1_ss_fifo_vcd 
  #(
    .SYNC(0),           
                        
    .IN_DATAWIDTH(195),   
    .OUT_DATAWIDTH(195),  
    .ADDRWIDTH(HDR_FIFO_ADDR_WIDTH),      
    .FULL_DURING_RST(1),  
    .FWFT_ENABLE(1),      
    .FREQ_IMPROVE(0),     
    .USE_ASYNC_RST(1),    
    .RAM_TYPE("M20K")
  )
s0_hdr_fifo (
    .rst(~pld_rst_n), 
    .wr_clock(pld_clk),
    .rd_clock(avst4to1_prim_clk),
    .wr_en(fifo_hdr_wr_en_s0_f), 
    .rd_en(fifo_hdr_rd_en_s0),
    .din(fifo_hdr_din_s0_f[194:0]),
    .dout(fifo_hdr_dout_s0[194:0]),
    .full(fifo_hdr_full_s0),
    .empty(fifo_hdr_empty_s0), 
    // unconnected ports
    .prog_full_offset(),
    .prog_empty_offset(),
    .prog_full(),
    .prog_empty(),
    .underflow(),
    .overflow(),
    .word_cnt_rd_side(),
    .word_cnt_wr_side()
);


assign fifo_hdr_dout_pass_thru_s0 = fifo_hdr_empty_s0 ? 1'd0 : fifo_hdr_dout_s0[194];


assign fifo_sel_crd_type_s0[1:0] = fifo_hdr_empty_s0 ? 2'd3 : fifo_hdr_dout_s0[193:192];
assign fifo_hdr_dout_prfx_val_s0 = fifo_hdr_dout_s0[190];
assign fifo_hdr_dout_RSSAI_prfx_val_s0 = fifo_hdr_dout_s0[191];
assign fifo_hdr_dout_RSSAI_prfx_s0[11:0] = fifo_hdr_dout_s0[189:178];
assign fifo_hdr_dout_prfx_s0[31:0] = fifo_hdr_dout_s0[177:146];
assign {fifo_hdr_dout_vf_active_s0, fifo_hdr_dout_vf_num_s0[10:0], fifo_hdr_dout_pf_num_s0[2:0], fifo_hdr_dout_bar_range_s0[2:0]} = fifo_hdr_dout_s0[145:128];

    always @(posedge pld_clk)
    begin
      fifo_hdr_dout_vf_active_s0_f <= fifo_hdr_dout_vf_active_s0;
      fifo_hdr_dout_vf_num_s0_f[10:0] <= fifo_hdr_dout_vf_num_s0[10:0];
      fifo_hdr_dout_pf_num_s0_f[2:0] <= fifo_hdr_dout_pf_num_s0[2:0];
      fifo_hdr_dout_bar_range_s0_f[2:0] <= fifo_hdr_dout_bar_range_s0[2:0];
      fifo_hdr_dout_pass_thru_s0_f <= fifo_hdr_dout_pass_thru_s0;
    end

// synthesis translate_off

always @(posedge pld_clk)
begin
  if (pld_rst_n)
    begin
      if (fifo_hdr_full_s0 & fifo_hdr_wr_en_s0)
        begin
          if (tlp_crd_type_s0[1:0] == 2'd0)
            $display("AVST4to1(CORE%0d PLD S0 RX Side): Posted Header FIFO Overflow @%0t", CORE_NUM, $time);
          
          if (tlp_crd_type_s0[1:0] == 2'd1)
            $display("AVST4to1(CORE%0d PLD S0 RX Side): Non-Posted Header FIFO Overflow @%0t", CORE_NUM, $time);
          
          if (tlp_crd_type_s0[1:0] == 2'd2)
            $display("AVST4to1(CORE%0d PLD S0 RX Side): Completion Header FIFO Overflow @%0t", CORE_NUM, $time);
          
        end
    end
end
//synthesis translate_on

avst4to1_ss_fifo_vcd 
  #(
    .SYNC(0),           
                        
    .IN_DATAWIDTH(195),   
    .OUT_DATAWIDTH(195),  
    .ADDRWIDTH(HDR_FIFO_ADDR_WIDTH),      
    .FULL_DURING_RST(1),  
    .FWFT_ENABLE(1),      
    .FREQ_IMPROVE(0),     
    .USE_ASYNC_RST(1),    
    .RAM_TYPE("M20K")
  )
s1_hdr_fifo (
    .rst(~pld_rst_n), 
    .wr_clock(pld_clk),
    .rd_clock(avst4to1_prim_clk),
    .wr_en(fifo_hdr_wr_en_s1_f), 
    .rd_en(fifo_hdr_rd_en_s1), 
    .din(fifo_hdr_din_s1_f[194:0]),
    .dout(fifo_hdr_dout_s1[194:0]),
    .full(fifo_hdr_full_s1),
    .empty(fifo_hdr_empty_s1), 
    // unconnected ports
    .prog_full_offset(),
    .prog_empty_offset(),
    .prog_full(),
    .prog_empty(),
    .underflow(),
    .overflow(),
    .word_cnt_rd_side(),
    .word_cnt_wr_side()
);

assign fifo_hdr_dout_pass_thru_s1 = fifo_hdr_empty_s1 ? 1'd0 : fifo_hdr_dout_s1[194];


assign fifo_sel_crd_type_s1[1:0] = fifo_hdr_empty_s1 ? 2'd3 : fifo_hdr_dout_s1[193:192];
assign fifo_hdr_dout_prfx_val_s1 = fifo_hdr_dout_s1[190];
assign fifo_hdr_dout_RSSAI_prfx_val_s1 = fifo_hdr_dout_s1[191];
assign fifo_hdr_dout_RSSAI_prfx_s1[11:0] = fifo_hdr_dout_s1[189:178];
assign fifo_hdr_dout_prfx_s1[31:0] = fifo_hdr_dout_s1[177:146];
assign {fifo_hdr_dout_vf_active_s1, fifo_hdr_dout_vf_num_s1[10:0], fifo_hdr_dout_pf_num_s1[2:0], fifo_hdr_dout_bar_range_s1[2:0]} = fifo_hdr_dout_s1[145:128];


    always @(posedge pld_clk)
    begin
      fifo_hdr_dout_vf_active_s1_f <= fifo_hdr_dout_vf_active_s1;
      fifo_hdr_dout_vf_num_s1_f[10:0] <= fifo_hdr_dout_vf_num_s1[10:0];
      fifo_hdr_dout_pf_num_s1_f[2:0] <= fifo_hdr_dout_pf_num_s1[2:0];
      fifo_hdr_dout_bar_range_s1_f[2:0] <= fifo_hdr_dout_bar_range_s1[2:0];
      fifo_hdr_dout_pass_thru_s1_f <= fifo_hdr_dout_pass_thru_s1;
    end

// synthesis translate_off

always @(posedge pld_clk)
begin
  if (pld_rst_n)
    begin
      if (fifo_hdr_full_s1 & fifo_hdr_wr_en_s1)
        begin
          if (tlp_crd_type_s1[1:0] == 2'd0)
            $display("AVST4to1(CORE%0d PLD S1 RX Side): Posted Header FIFO Overflow @%0t", CORE_NUM, $time);
          
          if (tlp_crd_type_s1[1:0] == 2'd1)
            $display("AVST4to1(CORE%0d PLD S1 RX Side): Non-Posted Header FIFO Overflow @%0t", CORE_NUM, $time);
          
          if (tlp_crd_type_s1[1:0] == 2'd2)
            $display("AVST4to1(CORE%0d PLD S1 RX Side): Completion Header FIFO Overflow @%0t", CORE_NUM, $time);
          
        end
    end
end
//synthesis translate_on


  // S2
  avst4to1_ss_fifo_vcd 
    #(
  .SYNC(0),           
                      
  .IN_DATAWIDTH(195),   
  .OUT_DATAWIDTH(195),  
  .ADDRWIDTH(HDR_FIFO_ADDR_WIDTH),      
  .FULL_DURING_RST(1),  
  .FWFT_ENABLE(1),      
  .FREQ_IMPROVE(0),     
  .USE_ASYNC_RST(1),    
  .RAM_TYPE("M20K")
  )
s2_hdr_fifo (
    .rst(~pld_rst_n), 
    .wr_clock(pld_clk),
    .rd_clock(avst4to1_prim_clk),
    .wr_en(fifo_hdr_wr_en_s2_f), 
    .rd_en(fifo_hdr_rd_en_s2), 
    .din(fifo_hdr_din_s2_f[194:0]),
    .dout(fifo_hdr_dout_s2[194:0]),
    .full(fifo_hdr_full_s2),
    .empty(fifo_hdr_empty_s2), 
    // unconnected ports
    .prog_full_offset(),
    .prog_empty_offset(),
    .prog_full(),
    .prog_empty(),
    .underflow(),
    .overflow(),
    .word_cnt_rd_side(),
    .word_cnt_wr_side()
);

assign fifo_hdr_dout_pass_thru_s2 = fifo_hdr_empty_s2 ? 1'd0 : fifo_hdr_dout_s2[194];
  
assign fifo_sel_crd_type_s2[1:0] = fifo_hdr_empty_s2 ? 2'd3 : fifo_hdr_dout_s2[193:192];
assign fifo_hdr_dout_prfx_val_s2 = fifo_hdr_dout_s2[190];
assign fifo_hdr_dout_RSSAI_prfx_val_s2 = fifo_hdr_dout_s2[191];
assign fifo_hdr_dout_RSSAI_prfx_s2[11:0] = fifo_hdr_dout_s2[189:178];
assign fifo_hdr_dout_prfx_s2[31:0] = fifo_hdr_empty_s2 ? 2'd3 : fifo_hdr_dout_s2[177:146];
assign {fifo_hdr_dout_vf_active_s2, fifo_hdr_dout_vf_num_s2[10:0], fifo_hdr_dout_pf_num_s2[2:0], fifo_hdr_dout_bar_range_s2[2:0]} = fifo_hdr_dout_s2[145:128];

    always @(posedge pld_clk)
    begin
      fifo_hdr_dout_vf_active_s2_f <= fifo_hdr_dout_vf_active_s2;
      fifo_hdr_dout_vf_num_s2_f[10:0] <= fifo_hdr_dout_vf_num_s2[10:0];
      fifo_hdr_dout_pf_num_s2_f[2:0] <= fifo_hdr_dout_pf_num_s2[2:0];
      fifo_hdr_dout_bar_range_s2_f[2:0] <= fifo_hdr_dout_bar_range_s2[2:0];
      fifo_hdr_dout_pass_thru_s2_f <= fifo_hdr_dout_pass_thru_s2;
    end
  
// synthesis translate_off

  always @(posedge pld_clk)
  begin
    if (pld_rst_n)
      begin
        if (fifo_hdr_full_s2 & fifo_hdr_wr_en_s2)
          begin
            if (tlp_crd_type_s2[1:0] == 2'd0)
              $display("AVST4to1(CORE%0d PLD S2 RX Side): Posted Header FIFO Overflow @%0t", CORE_NUM, $time);
            
            if (tlp_crd_type_s2[1:0] == 2'd1)
              $display("AVST4to1(CORE%0d PLD S2 RX Side): Non-Posted Header FIFO Overflow @%0t", CORE_NUM, $time);
            
            if (tlp_crd_type_s2[1:0] == 2'd2)
              $display("AVST4to1(CORE%0d PLD S2 RX Side): Completion Header FIFO Overflow @%0t", CORE_NUM, $time);
            
          end
      end
  end
  //synthesis translate_on
  // S3
  avst4to1_ss_fifo_vcd 
    #(
    .SYNC(0),           
                        
    .IN_DATAWIDTH(195),   
    .OUT_DATAWIDTH(195),  
    .ADDRWIDTH(HDR_FIFO_ADDR_WIDTH),      
    .FULL_DURING_RST(1),  
    .FWFT_ENABLE(1),      
    .FREQ_IMPROVE(0),     
    .USE_ASYNC_RST(1),    
    .RAM_TYPE("M20K")
    )
  s3_hdr_fifo (
      .rst(~pld_rst_n), 
      .wr_clock(pld_clk),
      .rd_clock(avst4to1_prim_clk),
      .wr_en(fifo_hdr_wr_en_s3_f), 
      .rd_en(fifo_hdr_rd_en_s3), 
      .din(fifo_hdr_din_s3_f[194:0]),
      .dout(fifo_hdr_dout_s3[194:0]),
      .full(fifo_hdr_full_s3),
      .empty(fifo_hdr_empty_s3), 
      // unconnected ports
      .prog_full_offset(),
      .prog_empty_offset(),
      .prog_full(),
      .prog_empty(),
      .underflow(),
      .overflow(),
      .word_cnt_rd_side(),
      .word_cnt_wr_side()
  );

  assign fifo_hdr_dout_pass_thru_s3 = fifo_hdr_empty_s3 ? 1'd0 : fifo_hdr_dout_s3[194];
  
  assign fifo_sel_crd_type_s3[1:0] = fifo_hdr_empty_s3 ? 2'd3 : fifo_hdr_dout_s3[193:192];
  assign fifo_hdr_dout_prfx_val_s3 = fifo_hdr_dout_s3[190];
  assign fifo_hdr_dout_RSSAI_prfx_val_s3 = fifo_hdr_dout_s3[191];
  assign fifo_hdr_dout_RSSAI_prfx_s3[11:0] = fifo_hdr_dout_s3[189:178];
  assign fifo_hdr_dout_prfx_s3[31:0] = fifo_hdr_empty_s3 ? 2'd3 : fifo_hdr_dout_s3[177:146];
  assign {fifo_hdr_dout_vf_active_s3, fifo_hdr_dout_vf_num_s3[10:0], fifo_hdr_dout_pf_num_s3[2:0], fifo_hdr_dout_bar_range_s3[2:0]} = fifo_hdr_dout_s3[145:128];
  
    always @(posedge pld_clk)
    begin
      fifo_hdr_dout_vf_active_s3_f <= fifo_hdr_dout_vf_active_s3;
      fifo_hdr_dout_vf_num_s3_f[10:0] <= fifo_hdr_dout_vf_num_s3[10:0];
      fifo_hdr_dout_pf_num_s3_f[2:0] <= fifo_hdr_dout_pf_num_s3[2:0];
      fifo_hdr_dout_bar_range_s3_f[2:0] <= fifo_hdr_dout_bar_range_s3[2:0];
      fifo_hdr_dout_pass_thru_s3_f <= fifo_hdr_dout_pass_thru_s3;
    end
  

//
// Data FIFO's

assign fifo_data_din_s0[262:0] = {bcast_msg_s0, 1'd0, pld_rx.rx_st_empty_s0_o[2:0], pld_rx.rx_st_eop_s0_o, pld_rx.rx_st_sop_s0_o, pld_rx.rx_st_data_s0_o[255:0]};
assign fifo_data_wr_en_s0 = pld_rx.rx_st_dvalid_s0_o | pld_rx.rx_st_hvalid_s0_o;
assign fifo_data_din_s1[262:0] = {bcast_msg_s1, 1'd0, pld_rx.rx_st_empty_s1_o[2:0], pld_rx.rx_st_eop_s1_o, pld_rx.rx_st_sop_s1_o, pld_rx.rx_st_data_s1_o[255:0]};
assign fifo_data_wr_en_s1 = pld_rx.rx_st_dvalid_s1_o | pld_rx.rx_st_hvalid_s1_o;
assign fifo_data_din_s2[262:0] = {bcast_msg_s2, 1'd0, pld_rx.rx_st_empty_s2_o[2:0], pld_rx.rx_st_eop_s2_o, pld_rx.rx_st_sop_s2_o, pld_rx.rx_st_data_s2_o[255:0]};
assign fifo_data_wr_en_s2 = pld_rx.rx_st_dvalid_s2_o | pld_rx.rx_st_hvalid_s2_o;
assign fifo_data_din_s3[262:0] = {bcast_msg_s3, 1'd0, pld_rx.rx_st_empty_s3_o[2:0], pld_rx.rx_st_eop_s3_o, pld_rx.rx_st_sop_s3_o, pld_rx.rx_st_data_s3_o[255:0]};
assign fifo_data_wr_en_s3 = pld_rx.rx_st_dvalid_s3_o | pld_rx.rx_st_hvalid_s3_o;

always @(posedge pld_clk)
begin
  if (~pld_rst_n)
    begin
      fifo_data_wr_en_s0_f <= 3'd0;
      fifo_data_wr_en_s1_f <= 3'd0;
      fifo_data_wr_en_s2_f <= 3'd0;
      fifo_data_wr_en_s3_f <= 3'd0;
    end
  else
    begin
      tlp_crd_type_s0_f[1:0] <= tlp_crd_type_s0[1:0];
      tlp_crd_type_s0_f_decode[2] <= (tlp_crd_type_s0[1:0] == 2'b10)? 1'b1 : 1'b0;
      tlp_crd_type_s0_f_decode[1] <= (tlp_crd_type_s0[1:0] == 2'b01)? 1'b1 : 1'b0;
      tlp_crd_type_s0_f_decode[0] <= (tlp_crd_type_s0[1:0] == 2'b00)? 1'b1 : 1'b0;
      fifo_data_wr_en_s0_f[2] <= fifo_data_wr_en_s0;
      fifo_data_wr_en_s0_f[1] <= fifo_data_wr_en_s0;
      fifo_data_wr_en_s0_f[0] <= fifo_data_wr_en_s0;
      fifo_data_din_s0_f[2] <= fifo_data_din_s0[262:0];
      fifo_data_din_s0_f[1] <= fifo_data_din_s0[262:0];
      fifo_data_din_s0_f[0] <= fifo_data_din_s0[262:0];
      tlp_crd_type_s1_f[1:0] <= tlp_crd_type_s1[1:0];
      tlp_crd_type_s1_f_decode[2] <= (tlp_crd_type_s1[1:0] == 2'b10)? 1'b1 : 1'b0;
      tlp_crd_type_s1_f_decode[1] <= (tlp_crd_type_s1[1:0] == 2'b01)? 1'b1 : 1'b0;
      tlp_crd_type_s1_f_decode[0] <= (tlp_crd_type_s1[1:0] == 2'b00)? 1'b1 : 1'b0;
      fifo_data_wr_en_s1_f[2] <= fifo_data_wr_en_s1;
      fifo_data_wr_en_s1_f[1] <= fifo_data_wr_en_s1;
      fifo_data_wr_en_s1_f[0] <= fifo_data_wr_en_s1;
      fifo_data_din_s1_f[2] <= fifo_data_din_s1[262:0];
      fifo_data_din_s1_f[1] <= fifo_data_din_s1[262:0];
      fifo_data_din_s1_f[0] <= fifo_data_din_s1[262:0];
      tlp_crd_type_s2_f[1:0] <= tlp_crd_type_s2[1:0];
      fifo_data_wr_en_s2_f[2] <= fifo_data_wr_en_s2;
      fifo_data_wr_en_s2_f[1] <= fifo_data_wr_en_s2;
      fifo_data_wr_en_s2_f[0] <= fifo_data_wr_en_s2;
      fifo_data_din_s2_f[2] <= fifo_data_din_s2[262:0];
      fifo_data_din_s2_f[1] <= fifo_data_din_s2[262:0];
      fifo_data_din_s2_f[0] <= fifo_data_din_s2[262:0];
      tlp_crd_type_s3_f[1:0] <= tlp_crd_type_s3[1:0];
      fifo_data_wr_en_s3_f[2] <= fifo_data_wr_en_s3;
      fifo_data_wr_en_s3_f[1] <= fifo_data_wr_en_s3;
      fifo_data_wr_en_s3_f[0] <= fifo_data_wr_en_s3;
      fifo_data_din_s3_f[2] <= fifo_data_din_s3[262:0];
      fifo_data_din_s3_f[1] <= fifo_data_din_s3[262:0];
      fifo_data_din_s3_f[0] <= fifo_data_din_s3[262:0];
    end
end

//
// credit type: 00-P, 01-NP, 10-CPL, 11-ERR

always@(*)
begin
  fifo_data_empty_s0 = 1'd0;
  fifo_data_empty_s1 = 1'd0;
  fifo_data_full_s0 = 1'd0;
  fifo_data_full_s1 = 1'd0;
  fifo_data_dout_s0[262:0] = 263'd0;
  fifo_data_dout_s1[262:0] = 263'd0;
  fifo_data_empty_s2 = 1'd0;
  fifo_data_empty_s3 = 1'd0;
  fifo_data_full_s2 = 1'd0;
  fifo_data_full_s3 = 1'd0;
  fifo_data_dout_s2[262:0] = 263'd0;
  fifo_data_dout_s3[262:0] = 263'd0;
  for (int crd_sel=0; crd_sel<3; crd_sel++) begin
    if (fifo_sel_crd_type[1:0] == crd_sel) begin
      fifo_data_empty_s0 = fifo_data_empty_s0_i[crd_sel];
      fifo_data_empty_s1 = fifo_data_empty_s1_i[crd_sel];
      fifo_data_full_s0 = fifo_data_full_s0_i[crd_sel];
      fifo_data_full_s1 = fifo_data_full_s1_i[crd_sel];
      fifo_data_dout_s0[262:0] = fifo_data_dout_s0_i[crd_sel];
      fifo_data_dout_s1[262:0] = fifo_data_dout_s1_i[crd_sel];
      fifo_data_empty_s2 = fifo_data_empty_s2_i[crd_sel];
      fifo_data_empty_s3 = fifo_data_empty_s3_i[crd_sel];
      fifo_data_full_s2 = fifo_data_full_s2_i[crd_sel];
      fifo_data_full_s3 = fifo_data_full_s3_i[crd_sel];
      fifo_data_dout_s2[262:0] = fifo_data_dout_s2_i[crd_sel];
      fifo_data_dout_s3[262:0] = fifo_data_dout_s3_i[crd_sel];
    end
  end
end

generate for(crd_type=0;crd_type<3;crd_type++) begin : crd_type_rx_data_fifos

assign fifo_data_wr_en_s0_i[crd_type] = (tlp_crd_type_s0_f[1:0] == crd_type) ? fifo_data_wr_en_s0_f[crd_type] : 1'b0;
assign fifo_data_wr_en_s1_i[crd_type] = (tlp_crd_type_s1_f[1:0] == crd_type) ? fifo_data_wr_en_s1_f[crd_type] : 1'b0;

assign fifo_data_din_s0_i[crd_type]   = (tlp_crd_type_s0_f_decode[crd_type]) ? fifo_data_din_s0_f[crd_type] : 1'b0;
assign fifo_data_din_s1_i[crd_type]   = (tlp_crd_type_s1_f_decode[crd_type]) ? fifo_data_din_s1_f[crd_type] : 1'b0;

assign fifo_data_rd_en_s0_ii[crd_type] = (fifo_sel_crd_type[1:0] == crd_type) ? fifo_data_rd_en_s0 : 1'b0;
assign fifo_data_rd_en_s1_ii[crd_type] = (fifo_sel_crd_type[1:0] == crd_type) ? fifo_data_rd_en_s1 : 1'b0;

  assign fifo_data_rd_en_s0_iii[crd_type] = data_sel_f[1] ? (data_sel_f[0] ? (fifo_data_rd_en_s0_ii[crd_type] & ~fifo_data_empty_s0_i[crd_type]) : (fifo_data_rd_en_s0_ii[crd_type] & ~fifo_data_empty_s0_i[crd_type])) :
                                                            (data_sel_f[0] ? (fifo_data_rd_en_s0_ii[crd_type] & ~fifo_data_empty_s0_i[crd_type]) : (fifo_data_rd_en_s0_ii[crd_type] & ~fifo_data_empty_s0_i[crd_type]));
  assign fifo_data_rd_en_s1_iii[crd_type] = data_sel_f[1] ? (data_sel_f[0] ? (fifo_data_rd_en_s1_ii[crd_type] & ~fifo_data_empty_s1_i[crd_type]) : (fifo_data_rd_en_s1_ii[crd_type] & ~fifo_data_empty_s1_i[crd_type])) :
                                                            (data_sel_f[0] ? (fifo_data_rd_en_s1_ii[crd_type] & ~fifo_data_empty_s1_i[crd_type]) : (fifo_data_rd_en_s1_ii[crd_type] & ~fifo_data_empty_s1_i[crd_type]));


assign fifo_data_eop_s0_i[crd_type] = fifo_data_empty_s0_i[crd_type] ? 'd0 : fifo_data_dout_s0_i[crd_type][257];
assign fifo_data_eop_s1_i[crd_type] = fifo_data_empty_s1_i[crd_type] ? 'd0 : fifo_data_dout_s1_i[crd_type][257];

avst4to1_ss_rx_data_fifos #(
  .DATA_FIFO_WIDTH(263),
  .DATA_FIFO_ADDR_WIDTH(DATA_FIFO_ADDR_WIDTH+1),
  .RAM_TYPE("M20K")
) rx_data_fifos_s1_s0 (
//
// PLD SIDE FIFO
//
  .pld_clk             (pld_clk       ),
  .pld_rst_n           (pld_rst_n     ),
  
  .fifo_data_wr_en_s0  (fifo_data_wr_en_s0_i[crd_type]),
  .fifo_data_full_s0   (fifo_data_full_s0_i[crd_type] ),
  .fifo_data_din_s0    (fifo_data_din_s0_i[crd_type]  ),
  .fifo_data_wr_en_s1  (fifo_data_wr_en_s1_i[crd_type]),
  .fifo_data_full_s1   (fifo_data_full_s1_i[crd_type] ),
  .fifo_data_din_s1    (fifo_data_din_s1_i[crd_type]  ),
//
// PRIM SIDE FIFO
//
  .avst4to1_prim_clk        (avst4to1_prim_clk  ),
  .avst4to1_prim_rst_n      (avst4to1_prim_rst_n),
  
  .fifo_data_rd_en_s0  (fifo_data_rd_en_s0_iii[crd_type]),
  .fifo_data_empty_s0  (fifo_data_empty_s0_i[crd_type]),
  .fifo_data_dout_s0   (fifo_data_dout_s0_i[crd_type] ),
  
  .fifo_data_rd_en_s1  (fifo_data_rd_en_s1_iii[crd_type]),
  .fifo_data_empty_s1  (fifo_data_empty_s1_i[crd_type]),
  .fifo_data_dout_s1   (fifo_data_dout_s1_i[crd_type] )
);
// synthesis translate_off

always @(posedge pld_clk)
begin
   if (pld_rst_n)
     begin
       // S0
       if (fifo_data_full_s0_i[crd_type] & fifo_data_wr_en_s0_i[crd_type])
         begin
           if (crd_type == 0)
             $display("AVST4to1(CORE%0d PLD S0 RX Side): Posted Data FIFO Overflow @%0t", CORE_NUM, $time);
           
           if (crd_type == 1)
             $display("AVST4to1(CORE%0d PLD S0 RX Side): Non-Posted Data FIFO Overflow @%0t", CORE_NUM, $time);
           
           if (crd_type == 2)
             $display("AVST4to1(CORE%0d PLD S0 RX Side): Completion Data FIFO Overflow @%0t", CORE_NUM, $time);
           
         end
       
       // S1
       if (fifo_data_full_s1_i[crd_type] & fifo_data_wr_en_s1_i[crd_type])
         begin
           if (crd_type == 0)
             $display("AVST4to1(CORE%0d PLD S1 RX Side): Posted Data FIFO Overflow @%0t", CORE_NUM, $time);
           
           if (crd_type == 1)
             $display("AVST4to1(CORE%0d PLD S1 RX Side): Non-Posted Data FIFO Overflow @%0t", CORE_NUM, $time);
           
           if (crd_type == 2)
             $display("AVST4to1(CORE%0d PLD S1 RX Side): Completion Data FIFO Overflow @%0t", CORE_NUM, $time);
           
         end
       
     end
end
//synthesis translate_on


  assign fifo_data_wr_en_s2_i[crd_type] = (tlp_crd_type_s2_f[1:0] == crd_type) ? fifo_data_wr_en_s2_f[crd_type] : 1'b0;
  assign fifo_data_wr_en_s3_i[crd_type] = (tlp_crd_type_s3_f[1:0] == crd_type) ? fifo_data_wr_en_s3_f[crd_type] : 1'b0;
  
  assign fifo_data_din_s2_i[crd_type]   = (tlp_crd_type_s2_f[1:0] == crd_type) ? fifo_data_din_s2_f[crd_type] : 1'b0;
  assign fifo_data_din_s3_i[crd_type]   = (tlp_crd_type_s3_f[1:0] == crd_type) ? fifo_data_din_s3_f[crd_type] : 1'b0;
  
  assign fifo_data_rd_en_s2_ii[crd_type] = (fifo_sel_crd_type[1:0] == crd_type) ? fifo_data_rd_en_s2 : 1'b0;
  assign fifo_data_rd_en_s3_ii[crd_type] = (fifo_sel_crd_type[1:0] == crd_type) ? fifo_data_rd_en_s3 : 1'b0;
  
  assign fifo_data_rd_en_s2_iii[crd_type] = data_sel_f[1] ? (data_sel_f[0] ? (fifo_data_rd_en_s2_ii[crd_type] & ~fifo_data_empty_s2_i[crd_type]) : (fifo_data_rd_en_s2_ii[crd_type] & ~fifo_data_empty_s2_i[crd_type])) :
                                                            (data_sel_f[0] ? (fifo_data_rd_en_s2_ii[crd_type] & ~fifo_data_empty_s2_i[crd_type]) : (fifo_data_rd_en_s2_ii[crd_type] & ~fifo_data_empty_s2_i[crd_type]));
  assign fifo_data_rd_en_s3_iii[crd_type] = data_sel_f[1] ? (data_sel_f[0] ? (fifo_data_rd_en_s3_ii[crd_type] & ~fifo_data_empty_s3_i[crd_type]) : (fifo_data_rd_en_s3_ii[crd_type] & ~fifo_data_empty_s3_i[crd_type])) :
                                                            (data_sel_f[0] ? (fifo_data_rd_en_s3_ii[crd_type] & ~fifo_data_empty_s3_i[crd_type]) : (fifo_data_rd_en_s3_ii[crd_type] & ~fifo_data_empty_s3_i[crd_type]));

  assign fifo_data_eop_s2_i[crd_type] = fifo_data_empty_s2_i[crd_type] ? 'd0 : fifo_data_dout_s2_i[crd_type][257];
  assign fifo_data_eop_s3_i[crd_type] = fifo_data_empty_s3_i[crd_type] ? 'd0 : fifo_data_dout_s3_i[crd_type][257];
  
  avst4to1_ss_rx_data_fifos #(
    .DATA_FIFO_WIDTH(263),
    .DATA_FIFO_ADDR_WIDTH(DATA_FIFO_ADDR_WIDTH+1)
  ) rx_data_fifos_s3_s2 (
  //
  // PLD SIDE FIFO
  //
    .pld_clk             (pld_clk       ),
    .pld_rst_n           (pld_rst_n     ),
    
    .fifo_data_wr_en_s0  (fifo_data_wr_en_s2_i[crd_type]),
    .fifo_data_full_s0   (fifo_data_full_s2_i[crd_type] ),
    .fifo_data_din_s0    (fifo_data_din_s2_i[crd_type]  ),
    
    .fifo_data_wr_en_s1  (fifo_data_wr_en_s3_i[crd_type]),
    .fifo_data_full_s1   (fifo_data_full_s3_i[crd_type] ),
    .fifo_data_din_s1    (fifo_data_din_s3_i[crd_type]  ),
  //
  // PRIM SIDE FIFO
  //
    .avst4to1_prim_clk        (avst4to1_prim_clk  ),
    .avst4to1_prim_rst_n      (avst4to1_prim_rst_n),
    
    .fifo_data_rd_en_s0  (fifo_data_rd_en_s2_iii[crd_type]),
    .fifo_data_empty_s0  (fifo_data_empty_s2_i[crd_type]),
    .fifo_data_dout_s0   (fifo_data_dout_s2_i[crd_type] ),
    
    .fifo_data_rd_en_s1  (fifo_data_rd_en_s3_iii[crd_type]),
    .fifo_data_empty_s1  (fifo_data_empty_s3_i[crd_type]),
    .fifo_data_dout_s1   (fifo_data_dout_s3_i[crd_type] )
  );
 // synthesis translate_off
 
  always @(posedge pld_clk)
  begin
     if (pld_rst_n)
       begin
         // s2
         if (fifo_data_full_s2_i[crd_type] & fifo_data_wr_en_s2_i[crd_type])
             begin
             if (crd_type == 0)
               $display("AVST4to1(CORE%0d PLD S2 RX Side): Posted Data FIFO Overflow @%0t", CORE_NUM, $time);
             
             if (crd_type == 1)
               $display("AVST4to1(CORE%0d PLD S2 RX Side): Non-Posted Data FIFO Overflow @%0t", CORE_NUM, $time);
             
             if (crd_type == 2)
               $display("AVST4to1(CORE%0d PLD S2 RX Side): Completion Data FIFO Overflow @%0t", CORE_NUM, $time);
             
           end
         // s3
         if (fifo_data_full_s3_i[crd_type] & fifo_data_wr_en_s3_i[crd_type])
             begin
             if (crd_type == 0)
               $display("AVST4to1(CORE%0d PLD S3 RX Side): Posted Data FIFO Overflow @%0t", CORE_NUM, $time);
             
             if (crd_type == 1)
               $display("AVST4to1(CORE%0d PLD S3 RX Side): Non-Posted Data FIFO Overflow @%0t", CORE_NUM, $time);
             
             if (crd_type == 2)
               $display("AVST4to1(CORE%0d PLD S3 RX Side): Completion Data FIFO Overflow @%0t", CORE_NUM, $time);
             
           end
         
       end
  end
//synthesis translate_on


end endgenerate

assign data_dout_sop_s0       = fifo_data_empty_s0 ? 1'd0 : data_dout_sop_s0_i;
assign data_dout_eop_s0       = fifo_data_empty_s0 ? 1'd0 : data_dout_eop_s0_i;
assign data_dout_s0[255:0]    = fifo_data_empty_s0 ? data_dout_s0_f[255:0] : data_dout_s0_i[255:0];
assign data_dout_valid_s0     = fifo_data_empty_s0 ? 1'd0 : 1'd1;
assign data_dout_bcast_msg_s0 = fifo_data_empty_s0 ? 1'd0 : data_dout_bcast_msg_s0_i;

assign data_dout_sop_s1       = fifo_data_empty_s1 ? 1'd0 : data_dout_sop_s1_i;
assign data_dout_eop_s1       = fifo_data_empty_s1 ? 1'd0 : data_dout_eop_s1_i;
assign data_dout_s1[255:0]    = fifo_data_empty_s1 ? data_dout_s1_f[255:0] : data_dout_s1_i[255:0];
assign data_dout_valid_s1     = fifo_data_empty_s1 ? 1'd0 : 1'd1;
assign data_dout_bcast_msg_s1 = fifo_data_empty_s1 ? 1'd0 : data_dout_bcast_msg_s1_i;
assign {data_dout_bcast_msg_s0_i, data_dout_tlp_abort_s0_i, data_dout_empty_s0[2:0], data_dout_eop_s0_i, data_dout_sop_s0_i, data_dout_s0_i[255:0]} = fifo_data_dout_s0[262:0];
assign {data_dout_bcast_msg_s1_i, data_dout_tlp_abort_s1_i, data_dout_empty_s1[2:0], data_dout_eop_s1_i, data_dout_sop_s1_i, data_dout_s1_i[255:0]} = fifo_data_dout_s1[262:0];
assign data_dout_empty_s0_i[2:0] = fifo_data_empty_s0 ? data_dout_empty_s0_f[2:0] : data_dout_empty_s0[2:0];
assign data_dout_empty_s1_i[2:0] = fifo_data_empty_s1 ? data_dout_empty_s1_f[2:0] : data_dout_empty_s1[2:0];

always @(posedge avst4to1_prim_clk) 
begin
   fifo_data_empty_s0_f <= fifo_data_empty_s0;
   data_dout_sop_s0_f <= data_dout_sop_s0;
   data_dout_eop_s0_f <= data_dout_eop_s0;
   data_dout_tlp_abort_s0_f  <= data_dout_tlp_abort_s0;
   data_dout_empty_s0_f[2:0] <= data_dout_empty_s0_i[2:0];
   data_dout_valid_s0_f <= data_dout_valid_s0;
   data_dout_bcast_msg_s0_f  <= data_dout_bcast_msg_s0;
   fifo_data_empty_s1_f <= fifo_data_empty_s1;
   data_dout_sop_s1_f <= data_dout_sop_s1;
   data_dout_eop_s1_f <= data_dout_eop_s1;
   data_dout_tlp_abort_s1_f  <= data_dout_tlp_abort_s1;
   data_dout_empty_s1_f[2:0] <= data_dout_empty_s1_i[2:0];
   data_dout_valid_s1_f <= data_dout_valid_s1;
   data_dout_bcast_msg_s1_f  <= data_dout_bcast_msg_s1;
end

assign data_dout_sop_s2       = fifo_data_empty_s2 ? 1'd0 : data_dout_sop_s2_i;
assign data_dout_eop_s2       = fifo_data_empty_s2 ? 1'd0 : data_dout_eop_s2_i;
assign data_dout_s2[255:0]    = fifo_data_empty_s2 ? data_dout_s2_f[255:0] : data_dout_s2_i[255:0];
assign data_dout_valid_s2     = fifo_data_empty_s2 ? 1'd0 : 1'd1;
assign data_dout_bcast_msg_s2 = fifo_data_empty_s2 ? 1'd0 : data_dout_bcast_msg_s2_i;
assign data_dout_sop_s3       = fifo_data_empty_s3 ? 1'd0 : data_dout_sop_s3_i;
assign data_dout_eop_s3       = fifo_data_empty_s3 ? 1'd0 : data_dout_eop_s3_i;
assign data_dout_s3[255:0]    = fifo_data_empty_s3 ? data_dout_s3_f[255:0] : data_dout_s3_i[255:0];
assign data_dout_valid_s3     = fifo_data_empty_s3 ? 1'd0 : 1'd1;
assign data_dout_bcast_msg_s3 = fifo_data_empty_s3 ? 1'd0 : data_dout_bcast_msg_s3_i;
assign {data_dout_bcast_msg_s2_i, data_dout_tlp_abort_s2_i, data_dout_empty_s2[2:0], data_dout_eop_s2_i, data_dout_sop_s2_i, data_dout_s2_i[255:0]} = fifo_data_dout_s2[262:0];
assign {data_dout_bcast_msg_s3_i, data_dout_tlp_abort_s3_i, data_dout_empty_s3[2:0], data_dout_eop_s3_i, data_dout_sop_s3_i, data_dout_s3_i[255:0]} = fifo_data_dout_s3[262:0];
assign data_dout_empty_s2_i[2:0] = fifo_data_empty_s2 ? data_dout_empty_s2_f[2:0] : data_dout_empty_s2[2:0];
assign data_dout_empty_s3_i[2:0] = fifo_data_empty_s3 ? data_dout_empty_s3_f[2:0] : data_dout_empty_s3[2:0];

always @(posedge avst4to1_prim_clk) 
begin
   fifo_data_empty_s2_f <= fifo_data_empty_s2;
   
   data_dout_sop_s2_f <= data_dout_sop_s2;
   data_dout_eop_s2_f <= data_dout_eop_s2;
   data_dout_tlp_abort_s2_f  <= data_dout_tlp_abort_s2;
   data_dout_empty_s2_f[2:0] <= data_dout_empty_s2_i[2:0];
   data_dout_valid_s2_f <= data_dout_valid_s2;
   data_dout_bcast_msg_s2_f  <= data_dout_bcast_msg_s2;
   fifo_data_empty_s3_f <= fifo_data_empty_s3;
   data_dout_sop_s3_f <= data_dout_sop_s3;
   data_dout_eop_s3_f <= data_dout_eop_s3;
   data_dout_tlp_abort_s3_f  <= data_dout_tlp_abort_s3;
   data_dout_empty_s3_f[2:0] <= data_dout_empty_s3_i[2:0];
   data_dout_valid_s3_f <= data_dout_valid_s3;
   data_dout_bcast_msg_s3_f  <= data_dout_bcast_msg_s3;
end

//
// convert from big to little endian
always @(*) 
begin
  for (int i=0; i< 128; i=i+8)
  begin
    fifo_hdr_dout_s0_endian[(i+0) +: 8] = fifo_hdr_dout_s0[(127-i) -: 8];
    fifo_hdr_dout_s1_endian[(i+0) +: 8] = fifo_hdr_dout_s1[(127-i) -: 8];
  end
end

always @(*) 
begin
  //for (int i=0; i< 32; i=i+8)
  //begin
  //  fifo_hdr_dout_prfx_s0_endian[(i+0) +: 8] = fifo_hdr_dout_prfx_s0[(31-i) -: 8];
  //  fifo_hdr_dout_prfx_s1_endian[(i+0) +: 8] = fifo_hdr_dout_prfx_s1[(31-i) -: 8];
  //end
    fifo_hdr_dout_prfx_s0_endian = fifo_hdr_dout_prfx_s0;
    fifo_hdr_dout_prfx_s1_endian = fifo_hdr_dout_prfx_s1;
end

always @(posedge avst4to1_prim_clk) 
begin
  fifo_hdr_dout_prfx_s0_endian_f[31:0] <= fifo_hdr_dout_prfx_s0_endian[31:0];
  fifo_hdr_dout_s0_endian_f[127:0] <= fifo_hdr_dout_s0_endian[127:0];
  data_dout_s0_f[255:0] <= data_dout_s0[255:0];
  fifo_hdr_dout_prfx_s1_endian_f[31:0] <= fifo_hdr_dout_prfx_s1_endian[31:0];
  fifo_hdr_dout_s1_endian_f[127:0] <= fifo_hdr_dout_s1_endian[127:0];
  data_dout_s1_f[255:0] <= data_dout_s1[255:0];
  fifo_hdr_dout_RSSAI_prfx_s0_f[11:0] <= fifo_hdr_dout_RSSAI_prfx_s0[11:0];
  fifo_hdr_dout_RSSAI_prfx_s1_f[11:0] <= fifo_hdr_dout_RSSAI_prfx_s1[11:0];
end


  always @(*) 
  begin
    for (int i=0; i< 128; i=i+8)
    begin
      fifo_hdr_dout_s2_endian[(i+0) +: 8] = fifo_hdr_dout_s2[(127-i) -: 8];
      fifo_hdr_dout_s3_endian[(i+0) +: 8] = fifo_hdr_dout_s3[(127-i) -: 8];
    end
  end
  
  always @(*) 
  begin
    //for (int i=0; i< 32; i=i+8)
    //begin
    //  fifo_hdr_dout_prfx_s2_endian[(i+0) +: 8] = fifo_hdr_dout_prfx_s2[(31-i) -: 8];
    //  fifo_hdr_dout_prfx_s3_endian[(i+0) +: 8] = fifo_hdr_dout_prfx_s3[(31-i) -: 8];
    //end
      fifo_hdr_dout_prfx_s2_endian = fifo_hdr_dout_prfx_s2;
      fifo_hdr_dout_prfx_s3_endian = fifo_hdr_dout_prfx_s3;
  end
  
  always @(posedge avst4to1_prim_clk) 
  begin
    fifo_hdr_dout_prfx_s2_endian_f[31:0] <= fifo_hdr_dout_prfx_s2_endian[31:0];
    fifo_hdr_dout_s2_endian_f[127:0] <= fifo_hdr_dout_s2_endian[127:0];
    data_dout_s2_f[255:0] <= data_dout_s2[255:0];
    fifo_hdr_dout_prfx_s3_endian_f[31:0] <= fifo_hdr_dout_prfx_s3_endian[31:0];
    fifo_hdr_dout_s3_endian_f[127:0] <= fifo_hdr_dout_s3_endian[127:0];
    data_dout_s3_f[255:0] <= data_dout_s3[255:0];
    fifo_hdr_dout_RSSAI_prfx_s2_f[11:0] <= fifo_hdr_dout_RSSAI_prfx_s2[11:0];
    fifo_hdr_dout_RSSAI_prfx_s3_f[11:0] <= fifo_hdr_dout_RSSAI_prfx_s3[11:0];

  end

//
// convert dw empty to dw valid

always_comb
  begin
    case(data_dout_eop_s0)
      1'b1:
        begin
          if ((fifo_ctrl_st > 'd1) & (avst4to1_rx_hdr_i[6] | avst4to1_rx_hdr_i[23])) begin
            case(data_dout_empty_s0_i[2:0])
            3'b111 :
              begin
                data_dw_valid_s0[7:0] = 8'h01;
              end
            3'b110 :
              begin
                data_dw_valid_s0[7:0] = 8'h03;
              end
            3'b101 :
              begin
                data_dw_valid_s0[7:0] = 8'h07;
              end
            3'b100 :
              begin
                data_dw_valid_s0[7:0] = 8'h0f;
              end
            3'b011 :
              begin
                data_dw_valid_s0[7:0] = 8'h1f;
              end
            3'b010 :
              begin
                data_dw_valid_s0[7:0] = 8'h3f;
              end
            3'b001 :
              begin
                data_dw_valid_s0[7:0] = 8'h7f;
              end
            3'b000 :
              begin
                data_dw_valid_s0[7:0] = 8'hff;
              end
            endcase
          end
          else
            data_dw_valid_s0[7:0] = 8'h00;
        end
      1'b0:
        begin
          data_dw_valid_s0[7:0] = 8'hff;
        end
    endcase
  end


always_comb
  begin
    case(data_dout_eop_s1)
      1'b1:
        begin
          if ((fifo_ctrl_st > 'd1) & (avst4to1_rx_hdr_i[6] | avst4to1_rx_hdr_i[23])) begin
            case(data_dout_empty_s1_i[2:0])
            3'b111 :
              begin
                data_dw_valid_s1[7:0] = 8'h01;
              end
            3'b110 :
              begin
                data_dw_valid_s1[7:0] = 8'h03;
              end
            3'b101 :
              begin
                data_dw_valid_s1[7:0] = 8'h07;
              end
            3'b100 :
              begin
                data_dw_valid_s1[7:0] = 8'h0f;
              end
            3'b011 :
              begin
                data_dw_valid_s1[7:0] = 8'h1f;
              end
            3'b010 :
              begin
                data_dw_valid_s1[7:0] = 8'h3f;
              end
            3'b001 :
              begin
                data_dw_valid_s1[7:0] = 8'h7f;
              end
            3'b000 :
              begin
                data_dw_valid_s1[7:0] = 8'hff;
              end
            endcase
           end
          else
            data_dw_valid_s1[7:0] = 8'h00;
        end
      1'b0:
        begin
          data_dw_valid_s1[7:0] = 8'hff;
        end
    endcase
  end

  always_comb
    begin
      case(data_dout_eop_s2)
        1'b1:
          begin
          if ((fifo_ctrl_st > 'd1) & (avst4to1_rx_hdr_i[6] | avst4to1_rx_hdr_i[23])) begin
              case(data_dout_empty_s2_i[2:0])
              3'b111 :
                begin
                  data_dw_valid_s2[7:0] = 8'h01;
                end
              3'b110 :
                begin
                  data_dw_valid_s2[7:0] = 8'h03;
                end
              3'b101 :
                begin
                  data_dw_valid_s2[7:0] = 8'h07;
                end
              3'b100 :
                begin
                  data_dw_valid_s2[7:0] = 8'h0f;
                end
              3'b011 :
                begin
                  data_dw_valid_s2[7:0] = 8'h1f;
                end
              3'b010 :
                begin
                  data_dw_valid_s2[7:0] = 8'h3f;
                end
              3'b001 :
                begin
                  data_dw_valid_s2[7:0] = 8'h7f;
                end
              3'b000 :
                begin
                  data_dw_valid_s2[7:0] = 8'hff;
                end
              endcase
             end
            else
              data_dw_valid_s2[7:0] = 8'h00;
          end
        1'b0:
          begin
            data_dw_valid_s2[7:0] = 8'hff;
          end
      endcase
    end


  always_comb
    begin
      case(data_dout_eop_s3)
        1'b1:
          begin
           if ((fifo_ctrl_st > 'd1) & (avst4to1_rx_hdr_i[6] | avst4to1_rx_hdr_i[23])) begin
              case(data_dout_empty_s3_i[2:0])
              3'b111 :
                begin
                  data_dw_valid_s3[7:0] = 8'h01;
                end
              3'b110 :
                begin
                  data_dw_valid_s3[7:0] = 8'h03;
                end
              3'b101 :
                begin
                  data_dw_valid_s3[7:0] = 8'h07;
                end
              3'b100 :
                begin
                  data_dw_valid_s3[7:0] = 8'h0f;
                end
              3'b011 :
                begin
                  data_dw_valid_s3[7:0] = 8'h1f;
                end
              3'b010 :
                begin
                  data_dw_valid_s3[7:0] = 8'h3f;
                end
              3'b001 :
                begin
                  data_dw_valid_s3[7:0] = 8'h7f;
                end
              3'b000 :
                begin
                  data_dw_valid_s3[7:0] = 8'hff;
                end
              endcase
             end
            else
              data_dw_valid_s3[7:0] = 8'h00;
          end
        1'b0:
          begin
            data_dw_valid_s3[7:0] = 8'hff;
          end
      endcase
    end


  //
  // TLP Header Decode for Credit Type
  //
// synthesis translate_off

  avst4to1_ss_tlp_hdr_decode avst4to1_tlp_hdr_decode_s0(
    .pld_clk      (avst4to1_prim_clk),
    .pld_rst_n    (avst4to1_prim_rst_n),
    .tlp_valid    (data_dout_sop_s0),
    .tlp_sop      (data_dout_sop_s0),
    .tlp_hdr      (fifo_hdr_dout_s0[127:0]),
    // unconnected ports
//    .tlp_crd_type (tlp_crd_type_s0[1:0])
    .tlp_crd_type (),
    .func_num_val(),
    .bcast_msg(),
    .func_num(),
    .mem_addr_val(),
    .mem_64b_addr(),
    .mem_addr()
  );
  avst4to1_ss_tlp_hdr_decode avst4to1_tlp_hdr_decode_s1(
    .pld_clk      (avst4to1_prim_clk),
    .pld_rst_n    (avst4to1_prim_rst_n),
    
    .tlp_valid    (data_dout_sop_s1),
    .tlp_sop      (data_dout_sop_s1),
    .tlp_hdr      (fifo_hdr_dout_s1[127:0]),
    
    // unconnected ports
//    .tlp_crd_type (tlp_crd_type_s1[1:0])
    .tlp_crd_type (),
    .func_num_val(),
    .bcast_msg(),
    .func_num(),
    .mem_addr_val(),
    .mem_64b_addr(),
    .mem_addr()
  );
    avst4to1_ss_tlp_hdr_decode avst4to1_tlp_hdr_decode_s2(
      .pld_clk      (avst4to1_prim_clk),
      .pld_rst_n    (avst4to1_prim_rst_n),
      
      .tlp_valid    (data_dout_sop_s2),
      .tlp_sop      (data_dout_sop_s2),
      .tlp_hdr      (fifo_hdr_dout_s2[127:0]),
      
      // unconnected ports
  //    .tlp_crd_type (tlp_crd_type_s2[1:0])
      .tlp_crd_type (),
      .func_num_val(),
      .bcast_msg(),
      .func_num(),
      .mem_addr_val(),
      .mem_64b_addr(),
      .mem_addr()
    );
    
    avst4to1_ss_tlp_hdr_decode avst4to1_tlp_hdr_decode_s3(
      .pld_clk      (avst4to1_prim_clk),
      .pld_rst_n    (avst4to1_prim_rst_n),
      
      .tlp_valid    (data_dout_sop_s3),
      .tlp_sop      (data_dout_sop_s3),
      .tlp_hdr      (fifo_hdr_dout_s3[127:0]),
      
      // unconnected ports
      .tlp_crd_type (),
      .func_num_val(),
      .bcast_msg(),
      .func_num(),
      .mem_addr_val(),
      .mem_64b_addr(),
      .mem_addr()
    );
 //synthesis translate_on
  


  assign avst4to1_bcast_msg_type      = hdr_data_en ? (curr_data_cycle[1] ? (curr_data_cycle[0] ? data_dout_bcast_msg_s3 : data_dout_bcast_msg_s2) : 
                                                 (curr_data_cycle[0] ? data_dout_bcast_msg_s1 : data_dout_bcast_msg_s0)) : 1'd0;
  
  assign fifo_sel_crd_type[1:0]  = data_sel[1] ? (data_sel[0] ? fifo_sel_crd_type_s3[1:0] : fifo_sel_crd_type_s2[1:0]):
                                                 (data_sel[0] ? fifo_sel_crd_type_s1[1:0] : fifo_sel_crd_type_s0[1:0]);
  //
  // output assignments
  //
  assign avst4to1_rx_sop_i     = hdr_data_en ? (curr_data_cycle[1] ? (curr_data_cycle[0] ? data_dout_sop_s3 : data_dout_sop_s2) : 
                                                                (curr_data_cycle[0] ? data_dout_sop_s1 : data_dout_sop_s0)) : 1'd0;
  
  assign avst4to1_rx_eop_i     = hdr_data_en ? (curr_data_cycle[1] ? (curr_data_cycle[0] ? (data_dout_eop_s0 | data_dout_eop_s3) : (data_dout_eop_s3 | data_dout_eop_s2)) : 
                                                                (curr_data_cycle[0] ? (data_dout_eop_s2 | data_dout_eop_s1) : (data_dout_eop_s1 | data_dout_eop_s0))) : 1'd0;
  
  assign avst4to1_rx_hdr_i    = hdr_sel[1] ? (hdr_sel[0] ? (fifo_hdr_empty_s3 ? fifo_hdr_dout_s3_endian_f : fifo_hdr_dout_s3_endian) : (fifo_hdr_empty_s2 ? fifo_hdr_dout_s2_endian_f : fifo_hdr_dout_s2_endian)):
                                        (hdr_sel[0] ? (fifo_hdr_empty_s1 ? fifo_hdr_dout_s1_endian_f : fifo_hdr_dout_s1_endian) : (fifo_hdr_empty_s0 ? fifo_hdr_dout_s0_endian_f : fifo_hdr_dout_s0_endian));
  
  assign avst4to1_rx_prefix_i = hdr_sel[1] ? (hdr_sel[0] ? (fifo_hdr_empty_s3 ? fifo_hdr_dout_prfx_s3_endian_f : fifo_hdr_dout_prfx_s3_endian) : (fifo_hdr_empty_s2 ? fifo_hdr_dout_prfx_s2_endian_f : fifo_hdr_dout_prfx_s2_endian)):
                                        (hdr_sel[0] ? (fifo_hdr_empty_s1 ? fifo_hdr_dout_prfx_s1_endian_f : fifo_hdr_dout_prfx_s1_endian) : (fifo_hdr_empty_s0 ? fifo_hdr_dout_prfx_s0_endian_f : fifo_hdr_dout_prfx_s0_endian));
  
  assign avst4to1_rx_prefix_valid_i  = hdr_data_en ? hdr_sel[1] ? (hdr_sel[0] ? fifo_hdr_dout_prfx_val_s3 & data_dout_sop_s3 : fifo_hdr_dout_prfx_val_s2 & data_dout_sop_s2):
                                                             (hdr_sel[0] ? fifo_hdr_dout_prfx_val_s1 & data_dout_sop_s1 : fifo_hdr_dout_prfx_val_s0 & data_dout_sop_s0) : 1'd0;
  
  assign avst4to1_rx_data_i   = curr_data_cycle[1] ? (curr_data_cycle[0] ? {data_dout_s0, data_dout_s3} : {data_dout_s3, data_dout_s2}) : 
                                                (curr_data_cycle[0] ? {data_dout_s2, data_dout_s1} : {data_dout_s1, data_dout_s0});
  

  assign avst4to1_rx_data_dw_valid_i[7:0]  = hdr_data_en ? (curr_data_cycle[1] ? (curr_data_cycle[0] ? data_dw_valid_s3 : data_dw_valid_s2) : (curr_data_cycle[0] ? data_dw_valid_s1 : data_dw_valid_s0)) : 8'd0;
  
  assign avst4to1_rx_data_dw_valid_i[15:8] = hdr_data_en ? (curr_data_cycle[1] ? (curr_data_cycle[0] ? (data_dout_eop_s3 ? 8'd0 : data_dw_valid_s0) : (data_dout_eop_s2 ? 8'd0 : data_dw_valid_s3)) : 
                                                                            (curr_data_cycle[0] ? (data_dout_eop_s1 ? 8'd0 : data_dw_valid_s2) : (data_dout_eop_s0 ? 8'd0 : data_dw_valid_s1))) : 8'd0;
  assign avst4to1_rx_RSSAI_prefix_i  = hdr_sel[1] ? (hdr_sel[0] ? (fifo_hdr_empty_s3 ? fifo_hdr_dout_RSSAI_prfx_s3_f : fifo_hdr_dout_RSSAI_prfx_s3) : (fifo_hdr_empty_s2 ? fifo_hdr_dout_RSSAI_prfx_s2_f : fifo_hdr_dout_RSSAI_prfx_s2)):
                                                 (hdr_sel[0] ? (fifo_hdr_empty_s1 ? fifo_hdr_dout_RSSAI_prfx_s1_f : fifo_hdr_dout_RSSAI_prfx_s1) : (fifo_hdr_empty_s0 ? fifo_hdr_dout_RSSAI_prfx_s0_f : fifo_hdr_dout_RSSAI_prfx_s0));
    
  assign avst4to1_rx_RSSAI_prefix_valid_i  = hdr_data_en ? hdr_sel[1] ? (hdr_sel[0] ? fifo_hdr_dout_RSSAI_prfx_val_s3 & data_dout_sop_s3 : fifo_hdr_dout_RSSAI_prfx_val_s2 & data_dout_sop_s2):
                                                                     (hdr_sel[0] ? fifo_hdr_dout_RSSAI_prfx_val_s1 & data_dout_sop_s1 : fifo_hdr_dout_RSSAI_prfx_val_s0 & data_dout_sop_s0) : 1'd0;
  
  assign avst4to1_vf_active_i = 1'd0;
  assign avst4to1_vf_num_i    = 11'd0;
  assign avst4to1_pf_num_i    = 3'd0;
  assign avst4to1_bar_range_i = 3'd0;
  assign avst4to1_rx_tlp_abort_i  = 1'b0;
  assign avst4to1_rx_passthrough_i = hdr_sel[1] ? (hdr_sel[0] ? (fifo_hdr_empty_s3 ? fifo_hdr_dout_pass_thru_s3_f : fifo_hdr_dout_pass_thru_s3) : (fifo_hdr_empty_s2 ? fifo_hdr_dout_pass_thru_s2_f : fifo_hdr_dout_pass_thru_s2)): (hdr_sel[0] ? (fifo_hdr_empty_s1 ? fifo_hdr_dout_pass_thru_s1_f : fifo_hdr_dout_pass_thru_s1) : (fifo_hdr_empty_s0 ? fifo_hdr_dout_pass_thru_s0_f : fifo_hdr_dout_pass_thru_s0));

//
// ff1
//
always @(posedge avst4to1_prim_clk) 
begin
   if (~avst4to1_prim_rst_n)
     begin
       avst4to1_rx_sop       <= 1'd0;
       avst4to1_rx_eop       <= 1'd0;
       avst4to1_rx_hdr       <= 128'd0;
       avst4to1_rx_prefix    <= 32'd0;
       avst4to1_rx_data      <= 512'd0;
       avst4to1_rx_data_dw_valid <= 16'd0;
       avst4to1_vf_active    <= 1'd0;
       avst4to1_vf_num       <= 11'd0;
       avst4to1_pf_num       <= 3'd0;
       avst4to1_bar_range    <= 3'd0;
       avst4to1_rx_passthrough   <= 1'd0;
       avst4to1_rx_tlp_abort <= 1'd0;
     end
   else
     begin
       avst4to1_rx_sop    <= avst4to1_rx_sop_i;
       avst4to1_rx_eop    <= avst4to1_rx_eop_i;
       avst4to1_rx_hdr    <= avst4to1_rx_hdr_i;
       avst4to1_rx_prefix <= avst4to1_rx_prefix_i;
       avst4to1_rx_prefix_valid <= avst4to1_rx_prefix_valid_i;
       avst4to1_rx_RSSAI_prefix <= avst4to1_rx_RSSAI_prefix_i;
       avst4to1_rx_RSSAI_prefix_valid <= avst4to1_rx_RSSAI_prefix_valid_i;
       avst4to1_rx_passthrough   <= avst4to1_rx_passthrough_i;
       avst4to1_vf_active <= 1'd0;
       avst4to1_vf_num    <= 11'd0;
       avst4to1_pf_num    <= 3'd0;
       avst4to1_bar_range <= 3'd0;
       avst4to1_rx_data   <= avst4to1_rx_data_i;
       avst4to1_rx_data_dw_valid <= avst4to1_rx_data_dw_valid_i;
       avst4to1_rx_tlp_abort <= 1'b0;
     end
end


// synthesis translate_off 
//
logic [127:0] actual_avst4to1_rx_hdr;

always @(*) 
begin
  for (int i=0; i< 128; i=i+8)
  begin
    actual_avst4to1_rx_hdr[(i+0) +: 8] = avst4to1_rx_hdr[(127-i) -: 8];
  end
end

always @(posedge avst4to1_prim_clk)
begin : out_tlp_cycle_chks
   if (~avst4to1_prim_rst_n)
     begin
       rd_tlp_index <= 'd0;
     end
   else
     begin
       case (avst4to1_rx_sop)
       1'b1:
         begin
           rd_tlp_index <= rd_tlp_index + 1;
           if (tlp_cycle_chk[rd_tlp_index] != actual_avst4to1_rx_hdr[127:0])
             begin 
               $display("AVST4to1(CORE%0d RX Side): Mismatch in TLP cycle - %0d, @%0t:", CORE_NUM, rd_tlp_index, $time);
               $display("     actual   - %h", actual_avst4to1_rx_hdr);
               $display("     expected - %h", tlp_cycle_chk[rd_tlp_index]);
             end
         end
       1'b0:
         begin
         end
       endcase
     end
end

//synthesis translate_on

endmodule
