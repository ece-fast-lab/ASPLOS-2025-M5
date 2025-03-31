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




module avst4to1_ss_rx_crd_lmt #(
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
  input              pld_clk,                               // Clock (Core)
  input              pld_rst_n,                             // Reset (Core)
  input              pld_init_done_rst_n,
  
  avst4to1_if.rx_crd      pld_rx_crd,
  input              tx_init_pulse,
  
  
  input              avst4to1_prim_clk,                          
  input              avst4to1_prim_rst_n,                        

  input              avst4to1_np_hdr_crd_pop,
  input [1:0]        avst4to1_np_hdr_crd_pop_cnt,

  input [2:0]        pld_rx_hdr_crdup,                      // 2:CPLH 1:NPH 0:PH
  input [5:0]        pld_rx_hdr_crdup_cnt,                  // bit [5:4]:CPLH, bit [3:2]:NPH, bit [1:0]:PH
  input              pld_rx_data_crdup,
  
  input [2:0]        Dec_cpl_Hcrdt_avail,
  input [2:0]        Dec_np_Hcrdt_avail,
  input [2:0]        Dec_p_Hcrdt_avail,
  
  output logic [7:0] Hcrd_cpl_avail_cnt,  
  output logic [7:0] Hcrd_np_avail_cnt,
  output logic [7:0] Hcrd_p_avail_cnt,
  
  input [11:0]       pld_rx_np_crdup,                       // number of 256b data entries
  input [11:0]       pld_rx_p_crdup,
  input [11:0]       pld_rx_cpl_crdup
);
//----------------------------------------------------------------------------//

logic [7:0]     rx_p_hdr_max_crd;                         // maximum posted header credits
logic [7:0]     rx_np_hdr_max_crd;                        // maximum non-posted header credits
logic [7:0]     rx_cpl_hdr_max_crd;                       // maximum completions header credits


logic [5:0]     rx_Hcrdt_update_cnt;                      // # of encoded credits given when corresponding *Hcrdt_update* is asserted.
                                                                          //   [5:4] CPLH credits
                                                                          //   [3:2] NPH credits
                                                                          //   [1:0] PH credits
logic [2:0]     rx_Hcrdt_update;                          // 2:CPLH 1:NPH 0:PH
                                                                          //   1==credits indicated by corresponding *Hcrdt_cnt* bits
                                                                          //   are being grantedVersion 2.42.3 5/15/20195/2/2019 Intel Confidential 14 of 19
                                                                          //   1 credit=1 header, including TLP Prefix(if present and
                                                                          //   supported)
                                                                          //   Used both during header credit init phase(as described
                                                                          //   below), and during normal operation, to indicate
                                                                          //   master can increment its corresponding credit counter.
                                                                          //   (master decrements corresponding credit counter
                                                                          //   whenever it sends data)
logic [2:0]     rx_Hcrdt_init;                            // 2:CPLH 1:NPH 0:PH
                                                                          //   Asserted=1 to request begin header credit init phase, remains
                                                                          //   asserted for entire header credit init phase. After master asserts
                                                                          //   *Hcrdt_init_ack*, credits are transferred on *Hcrdt_update* and
                                                                          //   *Hcrdt_cnt* each clock cycle. Deasserted=0 to indicate completion
                                                                          //   of credit init phase.
logic [2:0]     rx_Hcrdt_init_ack;                        // 2:CPLH 1:NPH 0:PH
                                                                          //   Master asserts ack=1 to indicate readiness to begin header credit
                                                                          //   init phase.
logic [11:0]    rx_Dcrdt_update_cnt;                      // # of encoded credits given when corresponding
                                                                          //   *Dcrdt_update* is asserted
                                                                          //   [11:8] CPLD credits
                                                                          //   [7:4] NPD credits
                                                                          //   [3:0] PD credits
logic [2:0]     rx_Dcrdt_update;                          // 2:CPLD 1:NPD 0:PD
                                                                          //   1==credits indicated by corresponding *Dcrdt_cnt* bits
                                                                          //   are being granted
                                                                          //   1 credit=4DW=16B
                                                                          //   Used both during data credit init phase(as described
                                                                          //   below), and during normal operation, to indicate
                                                                          //   master can increment its corresponding credit counter.
                                                                          //   (master decrements corresponding credit counter
                                                                          //   whenever it sends data)
logic [2:0]     rx_Dcrdt_init;                            // 2:CPLD 1:NPD 0:PD
                                                                          //   Asserted=1 to request begin data credit init phase, remains asserted
                                                                          //   for entire data credit init phase. After master asserts
                                                                          //   *Dcrdt_init_ack*, credits are transferred on *Dcrdt_update* and
                                                                          //   *Dcrdt_cnt* each clock cycle. Deasserted=0 to indicate completion
                                                                          //   of credit init phase.
logic [2:0]     rx_Dcrdt_init_ack;                        // 2:CPLD 1:NPD 0:PD
                                                                          //   Master asserts ack=1 to indicate readiness to begin data credit init
                                                                          //   phase.
logic           avst4to1_np_hdr_crd_fifo_full;
logic           avst4to1_np_hdr_crd_fifo_empty; 
logic [2:0]     avst4to1_np_hdr_crd_fifo_din;  
logic [2:0]     avst4to1_np_hdr_crd_fifo_dout;

logic           pld_rx_hdr_crd_upd;
logic [1:0]     pld_rx_hdr_crd_upd_cnt;

//----------------------------------------------------------------------------//


assign rx_p_hdr_max_crd[7:0]          = P_HDR_CRDT  ; // 'd11; 
assign rx_np_hdr_max_crd[7:0]         = NP_HDR_CRDT ; // 'd11; 
assign rx_cpl_hdr_max_crd[7:0]        = CPL_HDR_CRDT; //'d10; 

assign rx_Hcrdt_init_ack              = pld_rx_crd.rx_Hcrdt_init_ack;
assign pld_rx_crd.rx_Hcrdt_update_cnt = rx_Hcrdt_update_cnt;
assign pld_rx_crd.rx_Hcrdt_update     = rx_Hcrdt_update;
assign pld_rx_crd.rx_Hcrdt_init       = rx_Hcrdt_init;

assign rx_Dcrdt_init_ack              = pld_rx_crd.rx_Dcrdt_init_ack;
assign pld_rx_crd.rx_Dcrdt_update_cnt = rx_Dcrdt_update_cnt;
assign pld_rx_crd.rx_Dcrdt_update     = rx_Dcrdt_update;
assign pld_rx_crd.rx_Dcrdt_init       = rx_Dcrdt_init;

// CPL Credit
avst4to1_ss_rx_crd_type #(
  .MAX_N_HDR_CRD        (CPL_HDR_CRDT ), //(12'd10), 
  .MAX_N_DATA_CRD       (CPL_DATA_CRDT ), //(16'd85), 
  .DATA_FIFO_ADDR_WIDTH (DATA_FIFO_ADDR_WIDTH+1)
) cpl_rx_crd (
  .rx_hdr_max_crd      (rx_cpl_hdr_max_crd),

  .pld_clk             (pld_clk),
  .pld_rst_n           (pld_rst_n),
  .pld_init_done_rst_n (pld_init_done_rst_n),
  .tx_init_pulse       (tx_init_pulse),
  
  .send_rx_Hcrdt_update (pld_rx_hdr_crdup[2]),
  .send_rx_Hcrdt_cnt    (pld_rx_hdr_crdup_cnt[5:4]),
  .send_rx_Dcrdt_update (pld_rx_data_crdup),
  .send_rx_Dcrdt_cnt    (pld_rx_cpl_crdup[3:0]),
  
  .Dec_Hcrdt_avail     (Dec_cpl_Hcrdt_avail[2:0]),
  .Hcrd_avail_cnt      (Hcrd_cpl_avail_cnt[7:0]),

  .rx_Hcrdt_init_ack   (rx_Hcrdt_init_ack[2]),
  .rx_Dcrdt_init_ack   (rx_Dcrdt_init_ack[2]),
  
  .rx_Hcrdt_update_cnt (rx_Hcrdt_update_cnt[5:4]),
  .rx_Hcrdt_update     (rx_Hcrdt_update[2]),
  .rx_Hcrdt_init       (rx_Hcrdt_init[2]),
  
  .rx_Dcrdt_update_cnt (rx_Dcrdt_update_cnt[11:8]),
  .rx_Dcrdt_update     (rx_Dcrdt_update[2]),
  .rx_Dcrdt_init       (rx_Dcrdt_init[2])
);

// NP Credit
assign avst4to1_np_hdr_crd_fifo_din[2:0] = {avst4to1_np_hdr_crd_pop, avst4to1_np_hdr_crd_pop_cnt[1:0]};

avst4to1_ss_fifo_vcd 
  #(
    .SYNC(0),           
                        
    .IN_DATAWIDTH(3),   
    .OUT_DATAWIDTH(3),    
    .ADDRWIDTH(6),      
    .FULL_DURING_RST(1),
    .FWFT_ENABLE(1),    
    .FREQ_IMPROVE(0),   
    .USE_ASYNC_RST(1)   
  )
avst4to1_np_hdr_crd_fifo (
    .rst(~avst4to1_prim_rst_n), 
    .wr_clock(avst4to1_prim_clk),
    .rd_clock(pld_clk),
    .wr_en(~avst4to1_np_hdr_crd_fifo_full), 
    .rd_en(~avst4to1_np_hdr_crd_fifo_empty),
    .full(avst4to1_np_hdr_crd_fifo_full),
    .empty(avst4to1_np_hdr_crd_fifo_empty), 
    .din(avst4to1_np_hdr_crd_fifo_din[2:0]),  
    .dout(avst4to1_np_hdr_crd_fifo_dout[2:0]),
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

assign pld_rx_hdr_crd_upd = avst4to1_np_hdr_crd_fifo_empty ? 1'd0 : avst4to1_np_hdr_crd_fifo_dout[2];
assign pld_rx_hdr_crd_upd_cnt[1:0] = avst4to1_np_hdr_crd_fifo_empty ? 2'd0 : avst4to1_np_hdr_crd_fifo_dout[1:0];
avst4to1_ss_rx_crd_type #(
  .MAX_N_HDR_CRD        (NP_HDR_CRDT), //(12'd11), 
  .MAX_N_DATA_CRD       (NP_DATA_CRDT), //(16'd85), 
  .DATA_FIFO_ADDR_WIDTH (16)
) np_rx_crd(
  .rx_hdr_max_crd      (rx_np_hdr_max_crd),
  
  .pld_clk             (pld_clk),
  .pld_rst_n           (pld_rst_n),
  .pld_init_done_rst_n (pld_init_done_rst_n),
  .tx_init_pulse       (tx_init_pulse),

  .send_rx_Hcrdt_update (pld_rx_hdr_crd_upd),
  .send_rx_Hcrdt_cnt    (pld_rx_hdr_crd_upd_cnt[1:0]),
  .send_rx_Dcrdt_update (pld_rx_data_crdup),
  .send_rx_Dcrdt_cnt    (pld_rx_np_crdup[3:0]),

  .Dec_Hcrdt_avail     (Dec_np_Hcrdt_avail[2:0]),
  .Hcrd_avail_cnt      (Hcrd_np_avail_cnt[7:0]),
  
  .rx_Hcrdt_init_ack   (rx_Hcrdt_init_ack[1]),
  .rx_Dcrdt_init_ack   (rx_Dcrdt_init_ack[1]),
  
  .rx_Hcrdt_update_cnt (rx_Hcrdt_update_cnt[3:2]),
  .rx_Hcrdt_update     (rx_Hcrdt_update[1]),
  .rx_Hcrdt_init       (rx_Hcrdt_init[1]),
  
  .rx_Dcrdt_update_cnt (rx_Dcrdt_update_cnt[7:4]),
  .rx_Dcrdt_update     (rx_Dcrdt_update[1]),
  .rx_Dcrdt_init       (rx_Dcrdt_init[1])
);

// P Credit
avst4to1_ss_rx_crd_type #(
  .MAX_N_HDR_CRD        (P_HDR_CRDT), //(12'd11), 
  .MAX_N_DATA_CRD       (P_DATA_CRDT), //(16'd85), 
  .DATA_FIFO_ADDR_WIDTH (DATA_FIFO_ADDR_WIDTH+1)
) p_rx_crd(
  .rx_hdr_max_crd      (rx_p_hdr_max_crd),
  
  .pld_clk             (pld_clk),
  .pld_rst_n           (pld_rst_n),
  .pld_init_done_rst_n (pld_init_done_rst_n),
  .tx_init_pulse       (tx_init_pulse),
  
  .send_rx_Hcrdt_update (pld_rx_hdr_crdup[0]),
  .send_rx_Hcrdt_cnt    (pld_rx_hdr_crdup_cnt[1:0]),
  .send_rx_Dcrdt_update (pld_rx_data_crdup),
  .send_rx_Dcrdt_cnt    (pld_rx_p_crdup[3:0]),
  
  .Dec_Hcrdt_avail     (Dec_p_Hcrdt_avail[2:0]),
  .Hcrd_avail_cnt      (Hcrd_p_avail_cnt[7:0]),
  
  .rx_Hcrdt_init_ack   (rx_Hcrdt_init_ack[0]),
  .rx_Dcrdt_init_ack   (rx_Dcrdt_init_ack[0]),
  
  .rx_Hcrdt_update_cnt (rx_Hcrdt_update_cnt[1:0]),
  .rx_Hcrdt_update     (rx_Hcrdt_update[0]),
  .rx_Hcrdt_init       (rx_Hcrdt_init[0]),
  
  .rx_Dcrdt_update_cnt (rx_Dcrdt_update_cnt[3:0]),
  .rx_Dcrdt_update     (rx_Dcrdt_update[0]),
  .rx_Dcrdt_init       (rx_Dcrdt_init[0])
);
endmodule
