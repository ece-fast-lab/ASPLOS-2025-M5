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


`include "ed_define.svh.iv"

`include "avst4to1_pld_if.svh.iv"



module cxl_ed_avst_4to1_rx_side #(
  parameter APP_CORES = 1,
  parameter P_HDR_CRDT    = 8,
  parameter NP_HDR_CRDT   = 8,
  parameter CPL_HDR_CRDT  = 8,
  parameter P_DATA_CRDT   = 32,
  parameter NP_DATA_CRDT  = 32, 
  parameter CPL_DATA_CRDT = 32,
  parameter DATA_FIFO_ADDR_WIDTH = 9 // Data FIFO depth 2^9 = 512/8 = (max 512B payload)
) (
//
// PLD IF
//
  input               pld_clk,                                   // PLD Clock
  input               pld_rst_n,
  input               pld_init_done_rst_n,
  
  avst4to1_if.rx           pld_rx,
  avst4to1_if.rx_crd       pld_rx_crd,
  
  input               crd_prim_rst_n,                      // init only reset
  input  [2:0]        tx_init,
//
//
  input               avst4to1_prim_clk,                        // Core clock
  input               avst4to1_prim_rst_n,                      // Core clock reset
  
  input  [1:0]        avst4to1_core_max_payload,                // 00: 128B
                                                          // 01: 256B
                                                          // 10: 512B
                                                          // 11: reserved
  
  // RX side
  input               [APP_CORES-1:0]avst4to1_np_hdr_crd_pop,

  input               avst4to1_rx_data_avail[APP_CORES-1:0],
  input               avst4to1_rx_hdr_avail[APP_CORES-1:0],                 // p/cpl
  input               avst4to1_rx_nph_hdr_avail[APP_CORES-1:0],             // np
  
  output logic        avst4to1_vf_active[APP_CORES-1:0],
  output logic[10:0]  avst4to1_vf_num[APP_CORES-1:0],
  output logic[2:0]   avst4to1_pf_num[APP_CORES-1:0],
  output logic[2:0]   avst4to1_bar_range[APP_CORES-1:0],
  output logic        avst4to1_rx_tlp_abort[APP_CORES-1:0],
  
  output logic        avst4to1_rx_sop[APP_CORES-1:0],
  output logic        avst4to1_rx_eop[APP_CORES-1:0],
  output logic[127:0] avst4to1_rx_hdr[APP_CORES-1:0], 
  output logic[31:0]  avst4to1_rx_prefix[APP_CORES-1:0],
  output logic        avst4to1_rx_passthrough[APP_CORES-1:0],
  output logic        avst4to1_rx_prefix_valid[APP_CORES-1:0],
  output logic[11:0]  avst4to1_rx_RSSAI_prefix[APP_CORES-1:0],
  output logic        avst4to1_rx_RSSAI_prefix_valid[APP_CORES-1:0],
  output logic[511:0] avst4to1_rx_data[APP_CORES-1:0],
  output logic[15:0]  avst4to1_rx_data_dw_valid[APP_CORES-1:0]
);
//----------------------------------------------------------------------------//
// 
//----------------------------------------------------------------------------//

logic    pld_rst_n_cp1;
logic    pld_rst_n_cp2;
   
  always@(posedge pld_clk or negedge pld_rst_n)
    begin
    if (pld_rst_n == 1'b0) 
      begin
        pld_rst_n_cp1 <= 1'b0;
        pld_rst_n_cp2 <= 1'b0;
      end
    else
      begin    
        pld_rst_n_cp1 <= pld_rst_n;
        pld_rst_n_cp2 <= pld_rst_n;
      end
    end 

   
avst4to1_if             pld_test_if();

logic              avst4to1_np_hdr_crd_pop_i;
logic [1:0]        avst4to1_np_hdr_crd_pop_cnt_i;

logic [2:0]        pld_rx_hdr_crdup;
logic [5:0]        pld_rx_hdr_crdup_cnt;
logic              pld_rx_data_crdup;

logic [2:0]        Dec_cpl_Hcrdt_avail;
logic [2:0]        Dec_np_Hcrdt_avail;
logic [2:0]        Dec_p_Hcrdt_avail;

logic [7:0]        Hcrd_cpl_avail_cnt;
logic [7:0]        Hcrd_np_avail_cnt;
logic [7:0]        Hcrd_p_avail_cnt;

logic [11:0]       pld_rx_np_crdup;
logic [11:0]       pld_rx_p_crdup;
logic [11:0]       pld_rx_cpl_crdup;

avst4to1_if             pld_rx_i();
//
// Credits
//
assign avst4to1_np_hdr_crd_pop_i = avst4to1_np_hdr_crd_pop > 'd0 ? 1'd1 : 1'd0;
assign avst4to1_np_hdr_crd_pop_cnt_i[1:0] = avst4to1_np_hdr_crd_pop > 'd2 ? 2'd2 : (avst4to1_np_hdr_crd_pop > 'd0 ? 2'd1 : 2'd0);

logic tx_init_pulse;
logic tx_init_one_bit;
assign tx_init_one_bit = |tx_init;
logic tx_init_one_bit_f;
always_ff@(posedge pld_clk)
begin
        tx_init_one_bit_f <= tx_init_one_bit;
end

assign tx_init_pulse = tx_init_one_bit & ~tx_init_one_bit_f;

avst4to1_ss_rx_crd_lmt #(
  .APP_CORES  (APP_CORES),
  .P_HDR_CRDT   (  P_HDR_CRDT   ),
  .NP_HDR_CRDT  (  NP_HDR_CRDT  ),
  .CPL_HDR_CRDT (  CPL_HDR_CRDT ),
  .P_DATA_CRDT  (  P_DATA_CRDT  ),
  .NP_DATA_CRDT (  NP_DATA_CRDT ), 
  .CPL_DATA_CRDT(  CPL_DATA_CRDT),
  .DATA_FIFO_ADDR_WIDTH (DATA_FIFO_ADDR_WIDTH)
) rx_crd_lmt_inst (
    .pld_clk                                      (pld_clk),
    .pld_rst_n                                    (pld_rst_n_cp1),
    .pld_init_done_rst_n                          (pld_init_done_rst_n),
    .pld_rx_crd                                   (pld_rx_crd),
    .tx_init_pulse                                (tx_init_pulse),
    .avst4to1_prim_clk                            (avst4to1_prim_clk),
    .avst4to1_prim_rst_n                          (avst4to1_prim_rst_n),
    .avst4to1_np_hdr_crd_pop                      (avst4to1_np_hdr_crd_pop_i),
    .avst4to1_np_hdr_crd_pop_cnt                  (avst4to1_np_hdr_crd_pop_cnt_i[1:0]),
    .pld_rx_hdr_crdup                             (pld_rx_hdr_crdup),
    .pld_rx_hdr_crdup_cnt                         (pld_rx_hdr_crdup_cnt),  
    .pld_rx_data_crdup                            (pld_rx_data_crdup),
    .Dec_cpl_Hcrdt_avail                          (Dec_cpl_Hcrdt_avail[2:0]),
    .Dec_np_Hcrdt_avail                           (Dec_np_Hcrdt_avail[2:0]),
    .Dec_p_Hcrdt_avail                            (Dec_p_Hcrdt_avail[2:0]),
    .Hcrd_cpl_avail_cnt                           (Hcrd_cpl_avail_cnt[7:0]),
    .Hcrd_np_avail_cnt                            (Hcrd_np_avail_cnt[7:0]),
    .Hcrd_p_avail_cnt                             (Hcrd_p_avail_cnt[7:0]),
    .pld_rx_np_crdup                              (pld_rx_np_crdup),
    .pld_rx_p_crdup                               (pld_rx_p_crdup),
    .pld_rx_cpl_crdup                             (pld_rx_cpl_crdup)
    );                                            
//
//  FIFO's
//


avst4to1_ss_rx_hdr_data_fifos #(
  .APP_CORES  (APP_CORES),
  .DATA_FIFO_ADDR_WIDTH (DATA_FIFO_ADDR_WIDTH)
)rx_hdr_data_fifos_inst (
    .pld_clk                         (pld_clk),                         
    .pld_rst_n                       (pld_rst_n),                       
    .pld_rx                          (pld_rx),                          
    .crd_prim_rst_n                  (crd_prim_rst_n),                  
    .avst4to1_core_max_payload       (avst4to1_core_max_payload),       
    .pld_rx_hdr_crdup                (pld_rx_hdr_crdup),
    .pld_rx_hdr_crdup_cnt            (pld_rx_hdr_crdup_cnt),
    .pld_rx_data_crdup               (pld_rx_data_crdup),
    .Dec_cpl_Hcrdt_avail             (Dec_cpl_Hcrdt_avail[2:0]),        
    .Dec_np_Hcrdt_avail              (Dec_np_Hcrdt_avail[2:0]),         
    .Dec_p_Hcrdt_avail               (Dec_p_Hcrdt_avail[2:0]),          
    .pld_rx_np_crdup                 (pld_rx_np_crdup),                 
    .pld_rx_p_crdup                  (pld_rx_p_crdup),                  
    .pld_rx_cpl_crdup                (pld_rx_cpl_crdup),                
    .avst4to1_prim_clk               (avst4to1_prim_clk),               
    .avst4to1_prim_rst_n             (avst4to1_prim_rst_n),             
    .avst4to1_rx_data_avail          (avst4to1_rx_data_avail),          
    .avst4to1_rx_hdr_avail           (avst4to1_rx_hdr_avail),           
    .avst4to1_rx_nph_hdr_avail       (avst4to1_rx_nph_hdr_avail),       
    .avst4to1_vf_active              (avst4to1_vf_active),              
    .avst4to1_vf_num                 (avst4to1_vf_num),                 
    .avst4to1_pf_num                 (avst4to1_pf_num),                 
    .avst4to1_bar_range              (avst4to1_bar_range),              
    .avst4to1_rx_tlp_abort           (avst4to1_rx_tlp_abort),           
    .avst4to1_rx_sop                 (avst4to1_rx_sop),                 
    .avst4to1_rx_eop                 (avst4to1_rx_eop),                 
    .avst4to1_rx_hdr                 (avst4to1_rx_hdr),                 
    .avst4to1_rx_prefix              (avst4to1_rx_prefix),              
    .avst4to1_rx_passthrough         (avst4to1_rx_passthrough),         
    .avst4to1_rx_prefix_valid        (avst4to1_rx_prefix_valid),        
    .avst4to1_rx_RSSAI_prefix        (avst4to1_rx_RSSAI_prefix),        
    .avst4to1_rx_RSSAI_prefix_valid  (avst4to1_rx_RSSAI_prefix_valid),  
    .avst4to1_rx_data                (avst4to1_rx_data),                
    .avst4to1_rx_data_dw_valid       (avst4to1_rx_data_dw_valid)        
    );                                                                  




endmodule
