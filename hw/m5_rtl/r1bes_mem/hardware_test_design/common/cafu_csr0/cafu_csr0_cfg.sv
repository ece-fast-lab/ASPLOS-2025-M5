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


//lintra push -60039
//lintra push -68099
`include "cafu_csr0_reg_macros.vh.iv"
// This include is still needed for RTLGEN_LCB
`include "rtlgen_include_v12.vh.iv"

//lintra push -68094

// ===================================================================
// Flops macros 
// ===================================================================

`ifndef RTLGEN_CAFU_CSR0_CFG_FF
`define RTLGEN_CAFU_CSR0_CFG_FF(rtl_clk, rst_n, rst_val, d, q) \
    always_ff @(posedge rtl_clk, negedge rst_n) \
        if (!rst_n) q <= rst_val; \
        else        q <= d;
`endif // RTLGEN_CAFU_CSR0_CFG_FF

`ifndef RTLGEN_CAFU_CSR0_CFG_EN_FF
`define RTLGEN_CAFU_CSR0_CFG_EN_FF(rtl_clk, rst_n, rst_val, en, d, q) \
    always_ff @(posedge rtl_clk, negedge rst_n) \
        if (!rst_n) q <= rst_val; \
        else \
            if (en) q <= d;
`endif // RTLGEN_CAFU_CSR0_CFG_EN_FF

`ifndef RTLGEN_CAFU_CSR0_CFG_FF_NEGEDGE
`define RTLGEN_CAFU_CSR0_CFG_FF_NEGEDGE(rtl_clk, rst_n, rst_val, d, q) \
    always_ff @(negedge rtl_clk, negedge rst_n) \
        if (!rst_n) q <= rst_val; \
        else        q <= d;
`endif // RTLGEN_CAFU_CSR0_CFG_FF_NEGEDGE

`ifndef RTLGEN_CAFU_CSR0_CFG_EN_FF_NEGEDGE
`define RTLGEN_CAFU_CSR0_CFG_EN_FF_NEGEDGE(rtl_clk, rst_n, rst_val, en, d, q) \
    always_ff @(negedge rtl_clk, negedge rst_n) \
        if (!rst_n) q <= rst_val; \
        else \
            if (en) q <= d;
`endif // RTLGEN_CAFU_CSR0_CFG_EN_FF_NEGEDGE

`ifndef RTLGEN_CAFU_CSR0_CFG_FF_RSTD
`define RTLGEN_CAFU_CSR0_CFG_FF_RSTD(rtl_clk, rst_n, rst_val, d, q) \
   genvar \gen_``d`` ; \
   generate \
      if (1) begin : \ff_rstd_``d`` \
         logic [$bits(q)-1:0] rst_vec, set_vec, d_vec, q_vec; \
         assign rst_vec = !rst_n ? ~rst_val : '0; \
         assign set_vec = !rst_n ? rst_val : '0; \
         assign d_vec = d; \
         assign q = q_vec; \
         for ( \gen_``d`` = 0 ; \gen_``d`` < $bits(q) ; \gen_``d`` = \gen_``d`` + 1)  \
            always_ff @(posedge rtl_clk, posedge rst_vec[ \gen_``d`` ], posedge set_vec[ \gen_``d`` ]) \
               if (rst_vec[ \gen_``d`` ]) \
                  q_vec[ \gen_``d`` ] <= '0; \
               else if (set_vec[ \gen_``d`` ]) \
                  q_vec[ \gen_``d`` ] <= '1; \
               else   \
                  q_vec[ \gen_``d`` ] <= d_vec[ \gen_``d`` ]; \
      end \
   endgenerate       
`endif // RTLGEN_CAFU_CSR0_CFG_FF_RSTD

`ifndef RTLGEN_CAFU_CSR0_CFG_EN_FF_RSTD
`define RTLGEN_CAFU_CSR0_CFG_EN_FF_RSTD(rtl_clk, rst_n, rst_val, en, d, q) \
   genvar \gen_``d`` ; \
   generate \
      if (1) begin : \en_ff_rstd_``d`` \
         logic [$bits(q)-1:0] rst_vec, set_vec, d_vec, q_vec; \
         assign rst_vec = !rst_n ? ~rst_val : '0; \
         assign set_vec = !rst_n ? rst_val : '0; \
         assign d_vec = d; \
         assign q = q_vec; \
         for ( \gen_``d`` = 0 ; \gen_``d`` < $bits(q) ; \gen_``d`` = \gen_``d`` + 1)  \
            always_ff @(posedge rtl_clk, posedge rst_vec[ \gen_``d`` ], posedge set_vec[ \gen_``d`` ]) \
               if (rst_vec[ \gen_``d`` ]) \
                  q_vec[ \gen_``d`` ] <= '0; \
               else if (set_vec[ \gen_``d`` ]) \
                  q_vec[ \gen_``d`` ] <= '1; \
               else if (en)  \
                  q_vec[ \gen_``d`` ] <= d_vec[ \gen_``d`` ]; \
      end \
   endgenerate       
`endif // RTLGEN_CAFU_CSR0_CFG_EN_FF_RSTD



`ifndef RTLGEN_CAFU_CSR0_CFG_FF_SYNCRST
`define RTLGEN_CAFU_CSR0_CFG_FF_SYNCRST(rtl_clk, syncrst_n, rst_val, d, q) \
    always_ff @(posedge rtl_clk) \
        if (!syncrst_n) q <= rst_val; \
        else        q <= d;
`endif // RTLGEN_CAFU_CSR0_CFG_FF_SYNCRST

`ifndef RTLGEN_CAFU_CSR0_CFG_EN_FF_SYNCRST
`define RTLGEN_CAFU_CSR0_CFG_EN_FF_SYNCRST(rtl_clk, syncrst_n, rst_val, en, d, q) \
    always_ff @(posedge rtl_clk) \
        if (!syncrst_n) q <= rst_val; \
        else \
            if (en) q <= d;
`endif // RTLGEN_CAFU_CSR0_CFG_EN_FF_SYNCRST

`ifndef RTLGEN_CAFU_CSR0_CFG_FF_NEGEDGE_SYNCRST
`define RTLGEN_CAFU_CSR0_CFG_FF_NEGEDGE_SYNCRST(rtl_clk, syncrst_n, rst_val, d, q) \
    always_ff @(negedge rtl_clk) \
        if (!syncrst_n) q <= rst_val; \
        else        q <= d;
`endif // RTLGEN_CAFU_CSR0_CFG_FF_NEGEDGE_SYNCRST

`ifndef RTLGEN_CAFU_CSR0_CFG_EN_FF_NEGEDGE_SYNCRST
`define RTLGEN_CAFU_CSR0_CFG_EN_FF_NEGEDGE_SYNCRST(rtl_clk, syncrst_n, rst_val, en, d, q) \
    always_ff @(negedge rtl_clk) \
        if (!syncrst_n) q <= rst_val; \
        else \
            if (en) q <= d;
`endif // RTLGEN_CAFU_CSR0_CFG_EN_FF_NEGEDGE_SYNCRST

// BOTHRST is cancelled. Should not be used. 
//
// `ifndef RTLGEN_CAFU_CSR0_CFG_FF_BOTHRST
// `define RTLGEN_CAFU_CSR0_CFG_FF_BOTHRST(rtl_clk, rst_n, syncrst_n, rst_val, d, q) \
//     always_ff @(posedge rtl_clk, negedge rst_n) \
//         if (!rst_n) q <= rst_val; \
//         else if (!syncrst_n) q <= rst_val; \
//         else        q <= d;
// `endif // RTLGEN_CAFU_CSR0_CFG_FF_BOTHRST
// 
// `ifndef RTLGEN_CAFU_CSR0_CFG_EN_FF_BOTHRST
// `define RTLGEN_CAFU_CSR0_CFG_EN_FF_BOTHRST(rtl_clk, rst_n, syncrst_n, rst_val, en, d, q) \
//     always_ff @(posedge rtl_clk, negedge rst_n) \
//         if (!rst_n) q <= rst_val; \
//         else if (!syncrst_n) q <= rst_val; \
//         else if (en) q <= d;
// 
// `endif // RTLGEN_CAFU_CSR0_CFG_EN_FF_BOTHRST


// ===================================================================
// Latch macros -- compatible with nhm_macros RST_LATCH & EN_RST_LATCH
// ===================================================================

`ifndef RTLGEN_CAFU_CSR0_CFG_LATCH_LOW
`define RTLGEN_CAFU_CSR0_CFG_LATCH_LOW(rtl_clk, d, q) \
   always_latch if ((`ifdef LINTRA_OL (* ol_clock *) `endif (~rtl_clk))) q <= d;   
`endif // RTLGEN_CAFU_CSR0_CFG_LATCH_LOW

`ifndef RTLGEN_CAFU_CSR0_CFG_PH2_FF
`define RTLGEN_CAFU_CSR0_CFG_PH2_FF(rtl_clk, d, q) \
    always_ff @(posedge rtl_clk) \
     q <= d;
`endif // RTLGEN_CAFU_CSR0_CFG_PH2_FF

// Can't be override
`ifndef RTLGEN_CAFU_CSR0_CFG_LATCH_LOW_ASSIGN
`define RTLGEN_CAFU_CSR0_CFG_LATCH_LOW_ASSIGN(n) \
   `RTLGEN_CAFU_CSR0_CFG_LATCH_LOW(gated_clk,``n``,``n``_low)
`endif // RTLGEN_CAFU_CSR0_CFG_LATCH_LOW_ASSIGN

// Can't be override
`ifndef RTLGEN_CAFU_CSR0_CFG_PH2_FF_ASSIGN
`define RTLGEN_CAFU_CSR0_CFG_PH2_FF_ASSIGN(n) \
   `RTLGEN_CAFU_CSR0_CFG_PH2_FF(gated_clk,``n``,``n``_low)
`endif // RTLGEN_CAFU_CSR0_CFG_PH2_FF_ASSIGN

`ifndef RTLGEN_CAFU_CSR0_CFG_LATCH
`define RTLGEN_CAFU_CSR0_CFG_LATCH(rtl_clk, rst_n, rst_val, d, q) \
   always_latch                                     \
      begin                                         \
         if (!rst_n) q <= rst_val;                  \
         else if ((`ifdef LINTRA_OL (* ol_clock *) `endif (rtl_clk))) q <= d; \
      end                                           
`endif // RTLGEN_CAFU_CSR0_CFG_LATCH

// In order not to touch regular LATCH_LOW (without reset) for backward compatible, 
//  an additional LATCH_LOW macro was added for reset with suffix _ASYNCRST 
`ifndef RTLGEN_CAFU_CSR0_CFG_LATCH_LOW_ASYNCRST
`define RTLGEN_CAFU_CSR0_CFG_LATCH_LOW_ASYNCRST(rtl_clk, rst_n, rst_val, d, q) \
   always_latch                                     \
      begin                                         \
         if (!rst_n) q <= rst_val;                  \
         else if ((`ifdef LINTRA_OL (* ol_clock *) `endif (~rtl_clk))) q <= d; \
      end                                           
`endif // RTLGEN_CAFU_CSR0_CFG_LATCH_LOW_ASYNCRST

`ifndef RTLGEN_CAFU_CSR0_CFG_EN_LATCH
`define RTLGEN_CAFU_CSR0_CFG_EN_LATCH(rtl_clk, rst_n, rst_val, en, d, q) \
   always_latch                                            \
      begin                                                \
         if (!rst_n) q <= rst_val;                         \
         else if ((`ifdef LINTRA_OL (* ol_clock *) `endif (rtl_clk))) begin \
              if (en) q <= d;                              \
         end                                               \
      end                                                  
`endif // RTLGEN_CAFU_CSR0_CFG_EN_LATCH

`ifndef RTLGEN_CAFU_CSR0_CFG_EN_LATCH_LOW
`define RTLGEN_CAFU_CSR0_CFG_EN_LATCH_LOW(rtl_clk, rst_n, rst_val, en, d, q) \
   always_latch                                            \
      begin                                                \
         if (!rst_n) q <= rst_val;                         \
         else if ((`ifdef LINTRA_OL (* ol_clock *) `endif (~rtl_clk))) begin \
              if (en) q <= d;                              \
         end                                               \
      end                                                  
`endif // RTLGEN_CAFU_CSR0_CFG_EN_LATCH_LOW

`ifndef RTLGEN_CAFU_CSR0_CFG_LATCH_SYNCRST
`define RTLGEN_CAFU_CSR0_CFG_LATCH_SYNCRST(rtl_clk, syncrst_n, rst_val, d, q) \
   always_latch                                     \
      begin                                         \
         if ((`ifdef LINTRA_OL (* ol_clock *) `endif (rtl_clk))) \
            if (!syncrst_n) q <= rst_val;           \
            else            q <=  d;                \
      end                                           
`endif // RTLGEN_CAFU_CSR0_CFG_LATCH_SYNCRST

`ifndef RTLGEN_CAFU_CSR0_CFG_LATCH_LOW_SYNCRST
`define RTLGEN_CAFU_CSR0_CFG_LATCH_LOW_SYNCRST(rtl_clk, syncrst_n, rst_val, d, q) \
   always_latch                                     \
      begin                                         \
         if ((`ifdef LINTRA_OL (* ol_clock *) `endif (~rtl_clk))) \
            if (!syncrst_n) q <= rst_val;           \
            else            q <=  d;                \
      end                                           
`endif // RTLGEN_CAFU_CSR0_CFG_LATCH_LOW_SYNCRST

`ifndef RTLGEN_CAFU_CSR0_CFG_EN_LATCH_SYNCRST
`define RTLGEN_CAFU_CSR0_CFG_EN_LATCH_SYNCRST(rtl_clk, syncrst_n, rst_val, en, d, q) \
   always_latch                                            \
      begin                                                \
         if ((`ifdef LINTRA_OL (* ol_clock *) `endif (rtl_clk)))  \
            if (!syncrst_n) q <= rst_val;                  \
            else if (en)    q <=  d;                       \
      end                                                  
`endif // RTLGEN_CAFU_CSR0_CFG_EN_LATCH_SYNCRST

`ifndef RTLGEN_CAFU_CSR0_CFG_EN_LATCH_LOW_SYNCRST
`define RTLGEN_CAFU_CSR0_CFG_EN_LATCH_LOW_SYNCRST(rtl_clk, syncrst_n, rst_val, en, d, q) \
   always_latch                                            \
      begin                                                \
         if ((`ifdef LINTRA_OL (* ol_clock *) `endif (~rtl_clk)))  \
            if (!syncrst_n) q <= rst_val;                  \
            else if (en)    q <=  d;                       \
      end                                                  
`endif // RTLGEN_CAFU_CSR0_CFG_EN_LATCH_LOW_SYNCRST

// BOTHRST is cancelled. Should not be used. 
// 
// `ifndef RTLGEN_CAFU_CSR0_CFG_LATCH_BOTHRST
// `define RTLGEN_CAFU_CSR0_CFG_LATCH_BOTHRST(rtl_clk, rst_n, syncrst_n, rst_val, d, q) \
//    always_latch                                     \
//       begin                                         \
//          if (!rst_n) q <= rst_val;                  \
//          else if (`ifdef LINTRA _OL(* ol_clock *) `endif (rtl_clk)) \
//             if (!syncrst_n) q <= rst_val;           \
//             else            q <=  d;                \
//       end                                           
// `endif // RTLGEN_CAFU_CSR0_CFG_LATCH_BOTHRST
// 
// `ifndef RTLGEN_CAFU_CSR0_CFG_EN_LATCH_BOTHRST
// `define RTLGEN_CAFU_CSR0_CFG_EN_LATCH_BOTHRST(rtl_clk, rst_n, syncrst_n, rst_val, en, d, q) \
//    always_latch                                     \
//       begin                                         \
//          if (!rst_n) q <= rst_val;                  \
//          else if ((`ifdef LINTRA_OL (* ol_clock *) `endif (rtl_clk))) \
//             if (!syncrst_n) q <= rst_val;           \
//             else if (en)    q <=  d;                \
//       end                                           
// `endif // RTLGEN_CAFU_CSR0_CFG_EN_LATCH_BOTHRST


// ===================================================================
// LCB macros 
// ===================================================================

`ifndef RTLGEN_CAFU_CSR0_CFG_LCB_HOLD_REQ_2CYCLES
`define RTLGEN_CAFU_CSR0_CFG_LCB_HOLD_REQ_2CYCLES(clock, enable, lcb_clk) \
   always_comb lcb_clk = {$bits(lcb_clk){clock}} & enable;
`endif // RTLGEN_CAFU_CSR0_CFG_LCB_HOLD_REQ_2CYCLES

`ifndef RTLGEN_CAFU_CSR0_CFG_LCB_HOLD_REQ_2CYCLES_SYNCRST
`define RTLGEN_CAFU_CSR0_CFG_LCB_HOLD_REQ_2CYCLES_SYNCRST(clock, enable, lcb_clk, sync_rst) \
   always_comb lcb_clk = {$bits(lcb_clk){clock}} & (enable | {$bits(lcb_clk){!sync_rst}});
`endif // RTLGEN_CAFU_CSR0_CFG_LCB_HOLD_REQ_2CYCLES_SYNCRST


`ifndef RTLGEN_CAFU_CSR0_CFG_LCB_DELAY_FFEN
`define RTLGEN_CAFU_CSR0_CFG_LCB_DELAY_FFEN(clock, delay_rst_n, enable, lcb_clk, dly_seq_type, close_ff_type, nxt_expr) \
   logic [$bits(lcb_clk)-1:0] ``enable``_dly_up;  \
   logic [$bits(lcb_clk)-1:0] ``enable``_close_up;  \
   logic [$bits(lcb_clk)-1:0] ``enable``_nxt; \
   logic [$bits(lcb_clk)-1:0] ``enable``_dly; \
   logic [$bits(lcb_clk)-1:0] ``enable``_close; \
   always_comb ``enable``_nxt = ``nxt_expr``; \
   always_comb ``enable``_dly_up = ``enable``_nxt | ``enable``_close; \
   always_comb ``enable``_close_up = ``enable``_dly | ``enable``_close; \
   genvar ``enable``_gen_var ; \
   generate \
      if (1) begin : rtlgen_lcb_``enable``_dly \
         for ( ``enable``_gen_var = 0 ; ``enable``_gen_var < $bits(lcb_clk); ``enable``_gen_var = ``enable``_gen_var + 1) begin \
  `RTLGEN_CAFU_CSR0_CFG_``close_ff_type``(clock,delay_rst_n,1'b0,``enable``_close_up[ ``enable``_gen_var ],``enable``_dly[ ``enable``_gen_var ],``enable``_close[ ``enable``_gen_var ]) \
  `RTLGEN_CAFU_CSR0_CFG_``dly_seq_type``(clock,delay_rst_n,1'b0,``enable``_dly_up[ ``enable``_gen_var ],``enable``_nxt[ ``enable``_gen_var ],``enable``_dly[ ``enable``_gen_var ]) \
         end      \
      end      \
   endgenerate \
   always_comb lcb_clk = {$bits(lcb_clk){clock}} & ``enable``_dly;
`endif // RTLGEN_CAFU_CSR0_CFG_LCB_DELAY_EN


`ifndef RTLGEN_CAFU_CSR0_CFG_LCB_DELAY_EN
`define RTLGEN_CAFU_CSR0_CFG_LCB_DELAY_EN(clock, delay_rst_n, enable, lcb_clk, seq_type, nxt_expr) \
   logic [$bits(lcb_clk)-1:0] ``enable``_up;  \
   logic [$bits(lcb_clk)-1:0] ``enable``_nxt; \
   logic [$bits(lcb_clk)-1:0] ``enable``_dly; \
   always_comb ``enable``_nxt = ``nxt_expr``; \
   always_comb ``enable``_up = ``enable``_nxt | ``enable``_dly; \
   genvar ``enable``_gen_var ; \
   generate \
      if (1) begin : rtlgen_lcb_``enable``_dly \
         for ( ``enable``_gen_var = 0 ; ``enable``_gen_var < $bits(lcb_clk); ``enable``_gen_var = ``enable``_gen_var + 1) \
  `RTLGEN_CAFU_CSR0_CFG_``seq_type``(clock,delay_rst_n,1'b0,``enable``_up[ ``enable``_gen_var ],``enable``_nxt[ ``enable``_gen_var ],``enable``_dly[ ``enable``_gen_var ]) \
      end      \
   endgenerate \
   always_comb lcb_clk = {$bits(lcb_clk){clock}} & ``enable``_dly;
`endif // RTLGEN_CAFU_CSR0_CFG_LCB_DELAY_EN

`ifndef RTLGEN_CAFU_CSR0_CFG_LCB_DELAY
`define RTLGEN_CAFU_CSR0_CFG_LCB_DELAY(clock, delay_rst_n, enable, lcb_clk, seq_type, nxt_expr) \
   logic [$bits(lcb_clk)-1:0] ``enable``_nxt; \
   logic [$bits(lcb_clk)-1:0] ``enable``_dly; \
   always_comb ``enable``_nxt = ``nxt_expr``; \
   genvar ``enable``_gen_var ; \
   generate \
      if (1) begin : rtlgen_lcb_``enable``_dly \
         for ( ``enable``_gen_var = 0 ; ``enable``_gen_var < $bits(lcb_clk); ``enable``_gen_var = ``enable``_gen_var + 1) \
  `RTLGEN_CAFU_CSR0_CFG_``seq_type``(clock,delay_rst_n,1'b0,``enable``_nxt[ ``enable``_gen_var ],``enable``_dly[ ``enable``_gen_var ]) \
      end      \
   endgenerate \
   always_comb lcb_clk = {$bits(lcb_clk){clock}} & ``enable``_dly;
`endif // RTLGEN_CAFU_CSR0_CFG_LCB_DELAY

// LCB MODE: LATCH_FFEN_LOW
`ifndef RTLGEN_CAFU_CSR0_CFG_LCB_LATCH_FFEN_LOW
`define RTLGEN_CAFU_CSR0_CFG_LCB_LATCH_FFEN_LOW(clock, delay_rst_n, enable, lcb_clk) \
   `RTLGEN_CAFU_CSR0_CFG_LCB_DELAY_FFEN(clock,delay_rst_n,enable,lcb_clk,EN_LATCH_LOW,EN_FF_NEGEDGE,enable) 
`endif // RTLGEN_CAFU_CSR0_CFG_LCB_LATCH_FFEN_LOW

`ifndef RTLGEN_CAFU_CSR0_CFG_LCB_LATCH_FFEN_LOW_SYNCRST
`define RTLGEN_CAFU_CSR0_CFG_LCB_LATCH_FFEN_LOW_SYNCRST(clock, delay_rst_n, enable, lcb_clk, sync_rst) \
   `RTLGEN_CAFU_CSR0_CFG_LCB_DELAY_FFEN(clock,1'b1,enable,lcb_clk,EN_LATCH_LOW_SYNCRST,EN_FF_NEGEDGE_SYNCRST,enable|{$bits(lcb_clk){!sync_rst}}) 
`endif // RTLGEN_CAFU_CSR0_CFG_LCB_LATCH_FFEN_LOW_SYNCRST

// LCB MODE: LATCH_EN_LOW
`ifndef RTLGEN_CAFU_CSR0_CFG_LCB_LATCH_EN_LOW
`define RTLGEN_CAFU_CSR0_CFG_LCB_LATCH_EN_LOW(clock, delay_rst_n, enable, lcb_clk) \
   `RTLGEN_CAFU_CSR0_CFG_LCB_DELAY_EN(clock,delay_rst_n,enable,lcb_clk,EN_LATCH_LOW,enable)
`endif // RTLGEN_CAFU_CSR0_CFG_LCB_LATCH_EN_LOW

`ifndef RTLGEN_CAFU_CSR0_CFG_LCB_LATCH_EN_LOW_SYNCRST
`define RTLGEN_CAFU_CSR0_CFG_LCB_LATCH_EN_LOW_SYNCRST(clock, delay_rst_n, enable, lcb_clk, sync_rst) \
   `RTLGEN_CAFU_CSR0_CFG_LCB_DELAY_EN(clock,1'b1,enable,lcb_clk,EN_LATCH_LOW_SYNCRST,enable|{$bits(lcb_clk){!sync_rst}})
`endif // RTLGEN_CAFU_CSR0_CFG_LCB_LATCH_EN_LOW_SYNCRST

// LCB MODE: LATCH_LOW
`ifndef RTLGEN_CAFU_CSR0_CFG_LCB_LATCH_LOW
`define RTLGEN_CAFU_CSR0_CFG_LCB_LATCH_LOW(clock, delay_rst_n, enable, lcb_clk) \
   `RTLGEN_CAFU_CSR0_CFG_LCB_DELAY(clock,delay_rst_n,enable,lcb_clk,LATCH_LOW_ASYNCRST,enable)
`endif // RTLGEN_CAFU_CSR0_CFG_LCB_LATCH_LOW

`ifndef RTLGEN_CAFU_CSR0_CFG_LCB_LATCH_LOW_SYNCRST
`define RTLGEN_CAFU_CSR0_CFG_LCB_LATCH_LOW_SYNCRST(clock, delay_rst_n, enable, lcb_clk, sync_rst) \
   `RTLGEN_CAFU_CSR0_CFG_LCB_DELAY(clock,1'b1,enable,lcb_clk,LATCH_LOW_SYNCRST,enable|{$bits(lcb_clk){!sync_rst}})
`endif // RTLGEN_CAFU_CSR0_CFG_LCB_LATCH_LOW_SYNCRST

// LCB MODE: FF_NEGEDGE
`ifndef RTLGEN_CAFU_CSR0_CFG_LCB_FF_NEGEDGE
`define RTLGEN_CAFU_CSR0_CFG_LCB_FF_NEGEDGE(clock, delay_rst_n, enable, lcb_clk)  \
   `RTLGEN_CAFU_CSR0_CFG_LCB_DELAY_EN(clock,delay_rst_n,enable,lcb_clk,EN_FF_NEGEDGE,enable)
`endif // RTLGEN_CAFU_CSR0_CFG_LCB_FF_NEGEDGE

`ifndef RTLGEN_CAFU_CSR0_CFG_LCB_FF_NEGEDGE_SYNCRST
`define RTLGEN_CAFU_CSR0_CFG_LCB_FF_NEGEDGE_SYNCRST(clock, delay_rst_n, enable, lcb_clk, sync_rst) \
   `RTLGEN_CAFU_CSR0_CFG_LCB_DELAY_EN(clock,1'b1,enable,lcb_clk,EN_FF_NEGEDGE_SYNCRST,enable|{$bits(lcb_clk){!sync_rst}})
`endif // RTLGEN_CAFU_CSR0_CFG_LCB_FF_NEGEDGE_SYNCRST

// LCB MODE: FF_POSEDGE
`ifndef RTLGEN_CAFU_CSR0_CFG_LCB_FF_POSEDGE
`define RTLGEN_CAFU_CSR0_CFG_LCB_FF_POSEDGE(clock, delay_rst_n, enable, lcb_clk)  \
   `RTLGEN_CAFU_CSR0_CFG_LCB_DELAY_EN(clock,delay_rst_n,enable,lcb_clk,EN_FF,enable)
`endif // RTLGEN_CAFU_CSR0_CFG_LCB_FF_POSEDGE

`ifndef RTLGEN_CAFU_CSR0_CFG_LCB_FF_POSEDGE_SYNCRST
`define RTLGEN_CAFU_CSR0_CFG_LCB_FF_POSEDGE_SYNCRST(clock, delay_rst_n, enable, lcb_clk, sync_rst) \
   `RTLGEN_CAFU_CSR0_CFG_LCB_DELAY_EN(clock,1'b1,enable,lcb_clk,EN_FF_SYNCRST,enable|{$bits(lcb_clk){!sync_rst}})
`endif // RTLGEN_CAFU_CSR0_CFG_LCB_FF_POSEDGE_SYNCRST



//lintra pop

module cafu_csr0_cfg ( //lintra s-2096
    // Clocks
    gated_clk,
    rtl_clk,

    // Resets
    cxl_or_conv_rst_n,
    pwr_rst_n,
    rst_n,


    // Register Inputs
    load_CDAT_0,
    load_CDAT_1,
    load_CXL_MB_CMD,
    load_CXL_MB_CTRL,
    load_DEVICE_ERROR_LOG3,
    load_DEVICE_EVENT_COUNT,
    load_DOE_CTLREG,
    load_DOE_RDMAILREG,
    load_DOE_STSREG,
    load_DOE_WRMAILREG,
    load_DVSEC_FBCTRL2_STATUS2,
    load_DVSEC_FBCTRL_STATUS,

    lock_HDM_DEC_BASEHIGH,
    lock_HDM_DEC_BASELOW,
    lock_HDM_DEC_CTRL,
    lock_HDM_DEC_DPAHIGH,
    lock_HDM_DEC_DPALOW,
    lock_HDM_DEC_SIZEHIGH,
    lock_HDM_DEC_SIZELOW,

    new_CDAT_0,
    new_CDAT_1,
    new_CONFIG_CXL_ERRORS,
    new_CONFIG_DEVICE_INJECTION,
    new_CXL_DEV_CAP_EVENT_STATUS,
    new_CXL_DVSEC_TEST_CNF_BASE_HIGH,
    new_CXL_DVSEC_TEST_CNF_BASE_LOW,
    new_CXL_MB_BK_CMD_STATUS,
    new_CXL_MB_CMD,
    new_CXL_MB_CTRL,
    new_CXL_MB_STATUS,
    new_CXL_MEM_DEV_STATUS,
    new_DEVICE_AFU_LATENCY_MODE,
    new_DEVICE_AFU_STATUS1,
    new_DEVICE_AFU_STATUS2,
    new_DEVICE_AXI2CPI_STATUS_1,
    new_DEVICE_AXI2CPI_STATUS_2,
    new_DEVICE_ERROR_INJECTION,
    new_DEVICE_ERROR_LOG1,
    new_DEVICE_ERROR_LOG2,
    new_DEVICE_ERROR_LOG3,
    new_DEVICE_ERROR_LOG4,
    new_DEVICE_ERROR_LOG5,
    new_DEVICE_EVENT_COUNT,
    new_DEVMEM_DBECNT,
    new_DEVMEM_POISONCNT,
    new_DEVMEM_SBECNT,
    new_DOE_CTLREG,
    new_DOE_RDMAILREG,
    new_DOE_STSREG,
    new_DOE_WRMAILREG,
    new_DVSEC_FBCTRL2_STATUS2,
    new_DVSEC_FBCTRL_STATUS,
    new_HDM_DEC_CTRL,
    new_MC_STATUS,


    // Misc Inputs
    CXL_DVSEC_TEST_CAP2_cache_size_device,
    CXL_DVSEC_TEST_CAP2_cache_size_unit,
    POR_DVSEC_FBCAP_HDR2_cache_capable,
    POR_DVSEC_FBCAP_HDR2_cache_wb_and_inv_capable,
    POR_DVSEC_FBCAP_HDR2_cxl_reset_capable,
    POR_DVSEC_FBCAP_HDR2_cxl_reset_mem_clr_capable,
    POR_DVSEC_FBCAP_HDR2_cxl_reset_timeout,
    POR_DVSEC_FBCAP_HDR2_hdm_count,
    POR_DVSEC_FBCAP_HDR2_mem_capable,
    POR_DVSEC_FBCAP_HDR2_mem_hwinit_mode,
    POR_DVSEC_FBCAP_HDR2_pm_init_comp_capable,
    POR_DVSEC_FBLOCK_cache_size,
    POR_DVSEC_FBLOCK_cache_size_unit,
    POR_DVSEC_FBRANGE1SZHIGH_memory_size,
    POR_DVSEC_FBRANGE1SZLOW_desired_interleave,
    POR_DVSEC_FBRANGE1SZLOW_media_type,
    POR_DVSEC_FBRANGE1SZLOW_mem_active,
    POR_DVSEC_FBRANGE1SZLOW_mem_valid,
    POR_DVSEC_FBRANGE1SZLOW_memory_active_timeout,
    POR_DVSEC_FBRANGE1SZLOW_memory_class,
    POR_DVSEC_FBRANGE1SZLOW_memory_size_low,
    POR_DVSEC_HDR1_dvsec_revision,
    POR_DVSEC_HDR1_dvsec_vendor_id,
    support_cache_dirty_evict,
    support_cache_read_current,
    support_cache_read_down,
    support_cache_read_shared,
    support_cache_write_itom,
    support_cache_write_wow_inv,
    support_cache_write_wow_invf,

    // Register Outputs
    CDAT_0,
    CDAT_1,
    CDAT_2,
    CDAT_3,
    CONFIG_ALGO_SETTING,
    CONFIG_CXL_ERRORS,
    CONFIG_DEVICE_INJECTION,
    CONFIG_TEST_ADDR_INCRE,
    CONFIG_TEST_BYTEMASK,
    CONFIG_TEST_PATTERN,
    CONFIG_TEST_PATTERN_PARAM,
    CONFIG_TEST_START_ADDR,
    CONFIG_TEST_WR_BACK_ADDR,
    CXL_DEV_CAP_ARRAY_0,
    CXL_DEV_CAP_ARRAY_1,
    CXL_DEV_CAP_EVENT_STATUS,
    CXL_DEV_CAP_HDR1_0,
    CXL_DEV_CAP_HDR1_1,
    CXL_DEV_CAP_HDR1_2,
    CXL_DEV_CAP_HDR2_0,
    CXL_DEV_CAP_HDR2_1,
    CXL_DEV_CAP_HDR2_2,
    CXL_DEV_CAP_HDR3_0,
    CXL_DEV_CAP_HDR3_1,
    CXL_DEV_CAP_HDR3_2,
    CXL_DVSEC_HEADER_1,
    CXL_DVSEC_HEADER_2,
    CXL_DVSEC_TEST_CAP1,
    CXL_DVSEC_TEST_CAP2,
    CXL_DVSEC_TEST_CNF_BASE_HIGH,
    CXL_DVSEC_TEST_CNF_BASE_LOW,
    CXL_DVSEC_TEST_LOCK,
    CXL_MB_BK_CMD_STATUS,
    CXL_MB_CAP,
    CXL_MB_CMD,
    CXL_MB_CTRL,
    CXL_MB_PAY_END,
    CXL_MB_PAY_START,
    CXL_MB_STATUS,
    CXL_MEM_DEV_STATUS,
    DEVICE_AFU_LATENCY_MODE,
    DEVICE_AFU_STATUS1,
    DEVICE_AFU_STATUS2,
    DEVICE_AXI2CPI_STATUS_1,
    DEVICE_AXI2CPI_STATUS_2,
    DEVICE_ERROR_INJECTION,
    DEVICE_ERROR_LOG1,
    DEVICE_ERROR_LOG2,
    DEVICE_ERROR_LOG3,
    DEVICE_ERROR_LOG4,
    DEVICE_ERROR_LOG5,
    DEVICE_EVENT_COUNT,
    DEVICE_EVENT_CTRL,
    DEVICE_FORCE_DISABLE,
    DEVMEM_DBECNT,
    DEVMEM_POISONCNT,
    DEVMEM_SBECNT,
    DOE_CAPREG,
    DOE_CTLREG,
    DOE_RDMAILREG,
    DOE_STSREG,
    DOE_WRMAILREG,
    DSEMTS_0,
    DSEMTS_1,
    DSEMTS_2,
    DSEMTS_3,
    DSEMTS_4,
    DSEMTS_5,
    DSIS_0,
    DSIS_1,
    DSLBIS_0,
    DSLBIS_1,
    DSLBIS_2,
    DSLBIS_3,
    DSLBIS_4,
    DSLBIS_5,
    DSMAS_0,
    DSMAS_1,
    DSMAS_2,
    DSMAS_3,
    DSMAS_4,
    DSMAS_5,
    DVSEC_DEV,
    DVSEC_DOE,
    DVSEC_FBCAP_HDR2,
    DVSEC_FBCTRL2_STATUS2,
    DVSEC_FBCTRL_STATUS,
    DVSEC_FBLOCK,
    DVSEC_FBRANGE1HIGH,
    DVSEC_FBRANGE1LOW,
    DVSEC_FBRANGE1SZHIGH,
    DVSEC_FBRANGE1SZLOW,
    DVSEC_FBRANGE2HIGH,
    DVSEC_FBRANGE2LOW,
    DVSEC_FBRANGE2SZHIGH,
    DVSEC_FBRANGE2SZLOW,
    DVSEC_HDR1,
    DVSEC_TEST_CAP,
    HDM_DEC_BASEHIGH,
    HDM_DEC_BASELOW,
    HDM_DEC_CAP,
    HDM_DEC_CTRL,
    HDM_DEC_DPAHIGH,
    HDM_DEC_DPALOW,
    HDM_DEC_GBL_CTRL,
    HDM_DEC_SIZEHIGH,
    HDM_DEC_SIZELOW,
    MBOX_EVENTINJ,
    MC_STATUS,


    // Register signals for HandCoded registers





    // Config Access
    req,
    ack
    

);

import cafu_csr0_cfg_pkg::*;
import rtlgen_pkg_v12::*;

parameter  CAFU_CSR0_CFG_CFG_ADDR_MSB = 11;
parameter  CAFU_CSR0_CFG_MEM_ADDR_MSB = 47;
parameter [CAFU_CSR0_CFG_MEM_ADDR_MSB:0] MEM_INST_SB_OFFSET = {CAFU_CSR0_CFG_MEM_ADDR_MSB+1{1'b0}};
parameter [CAFU_CSR0_CFG_CFG_ADDR_MSB:0] CFG_INST_SB_OFFSET = {CAFU_CSR0_CFG_CFG_ADDR_MSB+1{1'b0}};
parameter [2:0] MEM_INST_SB_SB_BAR = 3'b0;
parameter [7:0] CFG_INST_SB_SB_FID = 8'h0;
parameter [7:0] MEM_INST_SB_SB_FID = 8'h0;
localparam  ADDR_LSB_BUS_ALIGN = 3;
localparam [CAFU_CSR0_CFG_CFG_ADDR_MSB-ADDR_LSB_BUS_ALIGN:0] DVSEC_DEV_DECODE_ADDR = DVSEC_DEV_CR_ADDR[CAFU_CSR0_CFG_CFG_ADDR_MSB:ADDR_LSB_BUS_ALIGN] + CFG_INST_SB_OFFSET[CAFU_CSR0_CFG_CFG_ADDR_MSB:ADDR_LSB_BUS_ALIGN];
localparam [CAFU_CSR0_CFG_CFG_ADDR_MSB-ADDR_LSB_BUS_ALIGN:0] DVSEC_HDR1_DECODE_ADDR = DVSEC_HDR1_CR_ADDR[CAFU_CSR0_CFG_CFG_ADDR_MSB:ADDR_LSB_BUS_ALIGN] + CFG_INST_SB_OFFSET[CAFU_CSR0_CFG_CFG_ADDR_MSB:ADDR_LSB_BUS_ALIGN];
localparam [CAFU_CSR0_CFG_CFG_ADDR_MSB-ADDR_LSB_BUS_ALIGN:0] DVSEC_FBCAP_HDR2_DECODE_ADDR = DVSEC_FBCAP_HDR2_CR_ADDR[CAFU_CSR0_CFG_CFG_ADDR_MSB:ADDR_LSB_BUS_ALIGN] + CFG_INST_SB_OFFSET[CAFU_CSR0_CFG_CFG_ADDR_MSB:ADDR_LSB_BUS_ALIGN];
localparam [CAFU_CSR0_CFG_CFG_ADDR_MSB-ADDR_LSB_BUS_ALIGN:0] DVSEC_FBCTRL_STATUS_DECODE_ADDR = DVSEC_FBCTRL_STATUS_CR_ADDR[CAFU_CSR0_CFG_CFG_ADDR_MSB:ADDR_LSB_BUS_ALIGN] + CFG_INST_SB_OFFSET[CAFU_CSR0_CFG_CFG_ADDR_MSB:ADDR_LSB_BUS_ALIGN];
localparam [CAFU_CSR0_CFG_CFG_ADDR_MSB-ADDR_LSB_BUS_ALIGN:0] DVSEC_FBCTRL2_STATUS2_DECODE_ADDR = DVSEC_FBCTRL2_STATUS2_CR_ADDR[CAFU_CSR0_CFG_CFG_ADDR_MSB:ADDR_LSB_BUS_ALIGN] + CFG_INST_SB_OFFSET[CAFU_CSR0_CFG_CFG_ADDR_MSB:ADDR_LSB_BUS_ALIGN];
localparam [CAFU_CSR0_CFG_CFG_ADDR_MSB-ADDR_LSB_BUS_ALIGN:0] DVSEC_FBLOCK_DECODE_ADDR = DVSEC_FBLOCK_CR_ADDR[CAFU_CSR0_CFG_CFG_ADDR_MSB:ADDR_LSB_BUS_ALIGN] + CFG_INST_SB_OFFSET[CAFU_CSR0_CFG_CFG_ADDR_MSB:ADDR_LSB_BUS_ALIGN];
localparam [CAFU_CSR0_CFG_CFG_ADDR_MSB-ADDR_LSB_BUS_ALIGN:0] DVSEC_FBRANGE1SZHIGH_DECODE_ADDR = DVSEC_FBRANGE1SZHIGH_CR_ADDR[CAFU_CSR0_CFG_CFG_ADDR_MSB:ADDR_LSB_BUS_ALIGN] + CFG_INST_SB_OFFSET[CAFU_CSR0_CFG_CFG_ADDR_MSB:ADDR_LSB_BUS_ALIGN];
localparam [CAFU_CSR0_CFG_CFG_ADDR_MSB-ADDR_LSB_BUS_ALIGN:0] DVSEC_FBRANGE1SZLOW_DECODE_ADDR = DVSEC_FBRANGE1SZLOW_CR_ADDR[CAFU_CSR0_CFG_CFG_ADDR_MSB:ADDR_LSB_BUS_ALIGN] + CFG_INST_SB_OFFSET[CAFU_CSR0_CFG_CFG_ADDR_MSB:ADDR_LSB_BUS_ALIGN];
localparam [CAFU_CSR0_CFG_CFG_ADDR_MSB-ADDR_LSB_BUS_ALIGN:0] DVSEC_FBRANGE1HIGH_DECODE_ADDR = DVSEC_FBRANGE1HIGH_CR_ADDR[CAFU_CSR0_CFG_CFG_ADDR_MSB:ADDR_LSB_BUS_ALIGN] + CFG_INST_SB_OFFSET[CAFU_CSR0_CFG_CFG_ADDR_MSB:ADDR_LSB_BUS_ALIGN];
localparam [CAFU_CSR0_CFG_CFG_ADDR_MSB-ADDR_LSB_BUS_ALIGN:0] DVSEC_FBRANGE1LOW_DECODE_ADDR = DVSEC_FBRANGE1LOW_CR_ADDR[CAFU_CSR0_CFG_CFG_ADDR_MSB:ADDR_LSB_BUS_ALIGN] + CFG_INST_SB_OFFSET[CAFU_CSR0_CFG_CFG_ADDR_MSB:ADDR_LSB_BUS_ALIGN];
localparam [CAFU_CSR0_CFG_CFG_ADDR_MSB-ADDR_LSB_BUS_ALIGN:0] DVSEC_FBRANGE2SZHIGH_DECODE_ADDR = DVSEC_FBRANGE2SZHIGH_CR_ADDR[CAFU_CSR0_CFG_CFG_ADDR_MSB:ADDR_LSB_BUS_ALIGN] + CFG_INST_SB_OFFSET[CAFU_CSR0_CFG_CFG_ADDR_MSB:ADDR_LSB_BUS_ALIGN];
localparam [CAFU_CSR0_CFG_CFG_ADDR_MSB-ADDR_LSB_BUS_ALIGN:0] DVSEC_FBRANGE2SZLOW_DECODE_ADDR = DVSEC_FBRANGE2SZLOW_CR_ADDR[CAFU_CSR0_CFG_CFG_ADDR_MSB:ADDR_LSB_BUS_ALIGN] + CFG_INST_SB_OFFSET[CAFU_CSR0_CFG_CFG_ADDR_MSB:ADDR_LSB_BUS_ALIGN];
localparam [CAFU_CSR0_CFG_CFG_ADDR_MSB-ADDR_LSB_BUS_ALIGN:0] DVSEC_FBRANGE2HIGH_DECODE_ADDR = DVSEC_FBRANGE2HIGH_CR_ADDR[CAFU_CSR0_CFG_CFG_ADDR_MSB:ADDR_LSB_BUS_ALIGN] + CFG_INST_SB_OFFSET[CAFU_CSR0_CFG_CFG_ADDR_MSB:ADDR_LSB_BUS_ALIGN];
localparam [CAFU_CSR0_CFG_CFG_ADDR_MSB-ADDR_LSB_BUS_ALIGN:0] DVSEC_FBRANGE2LOW_DECODE_ADDR = DVSEC_FBRANGE2LOW_CR_ADDR[CAFU_CSR0_CFG_CFG_ADDR_MSB:ADDR_LSB_BUS_ALIGN] + CFG_INST_SB_OFFSET[CAFU_CSR0_CFG_CFG_ADDR_MSB:ADDR_LSB_BUS_ALIGN];
localparam [CAFU_CSR0_CFG_CFG_ADDR_MSB-ADDR_LSB_BUS_ALIGN:0] DVSEC_DOE_DECODE_ADDR = DVSEC_DOE_CR_ADDR[CAFU_CSR0_CFG_CFG_ADDR_MSB:ADDR_LSB_BUS_ALIGN] + CFG_INST_SB_OFFSET[CAFU_CSR0_CFG_CFG_ADDR_MSB:ADDR_LSB_BUS_ALIGN];
localparam [CAFU_CSR0_CFG_CFG_ADDR_MSB-ADDR_LSB_BUS_ALIGN:0] DOE_CAPREG_DECODE_ADDR = DOE_CAPREG_CR_ADDR[CAFU_CSR0_CFG_CFG_ADDR_MSB:ADDR_LSB_BUS_ALIGN] + CFG_INST_SB_OFFSET[CAFU_CSR0_CFG_CFG_ADDR_MSB:ADDR_LSB_BUS_ALIGN];
localparam [CAFU_CSR0_CFG_CFG_ADDR_MSB-ADDR_LSB_BUS_ALIGN:0] DOE_CTLREG_DECODE_ADDR = DOE_CTLREG_CR_ADDR[CAFU_CSR0_CFG_CFG_ADDR_MSB:ADDR_LSB_BUS_ALIGN] + CFG_INST_SB_OFFSET[CAFU_CSR0_CFG_CFG_ADDR_MSB:ADDR_LSB_BUS_ALIGN];
localparam [CAFU_CSR0_CFG_CFG_ADDR_MSB-ADDR_LSB_BUS_ALIGN:0] DOE_STSREG_DECODE_ADDR = DOE_STSREG_CR_ADDR[CAFU_CSR0_CFG_CFG_ADDR_MSB:ADDR_LSB_BUS_ALIGN] + CFG_INST_SB_OFFSET[CAFU_CSR0_CFG_CFG_ADDR_MSB:ADDR_LSB_BUS_ALIGN];
localparam [CAFU_CSR0_CFG_CFG_ADDR_MSB-ADDR_LSB_BUS_ALIGN:0] DOE_WRMAILREG_DECODE_ADDR = DOE_WRMAILREG_CR_ADDR[CAFU_CSR0_CFG_CFG_ADDR_MSB:ADDR_LSB_BUS_ALIGN] + CFG_INST_SB_OFFSET[CAFU_CSR0_CFG_CFG_ADDR_MSB:ADDR_LSB_BUS_ALIGN];
localparam [CAFU_CSR0_CFG_CFG_ADDR_MSB-ADDR_LSB_BUS_ALIGN:0] DOE_RDMAILREG_DECODE_ADDR = DOE_RDMAILREG_CR_ADDR[CAFU_CSR0_CFG_CFG_ADDR_MSB:ADDR_LSB_BUS_ALIGN] + CFG_INST_SB_OFFSET[CAFU_CSR0_CFG_CFG_ADDR_MSB:ADDR_LSB_BUS_ALIGN];
localparam [CAFU_CSR0_CFG_CFG_ADDR_MSB-ADDR_LSB_BUS_ALIGN:0] DVSEC_TEST_CAP_DECODE_ADDR = DVSEC_TEST_CAP_CR_ADDR[CAFU_CSR0_CFG_CFG_ADDR_MSB:ADDR_LSB_BUS_ALIGN] + CFG_INST_SB_OFFSET[CAFU_CSR0_CFG_CFG_ADDR_MSB:ADDR_LSB_BUS_ALIGN];
localparam [CAFU_CSR0_CFG_CFG_ADDR_MSB-ADDR_LSB_BUS_ALIGN:0] CXL_DVSEC_HEADER_1_DECODE_ADDR = CXL_DVSEC_HEADER_1_CR_ADDR[CAFU_CSR0_CFG_CFG_ADDR_MSB:ADDR_LSB_BUS_ALIGN] + CFG_INST_SB_OFFSET[CAFU_CSR0_CFG_CFG_ADDR_MSB:ADDR_LSB_BUS_ALIGN];
localparam [CAFU_CSR0_CFG_CFG_ADDR_MSB-ADDR_LSB_BUS_ALIGN:0] CXL_DVSEC_HEADER_2_DECODE_ADDR = CXL_DVSEC_HEADER_2_CR_ADDR[CAFU_CSR0_CFG_CFG_ADDR_MSB:ADDR_LSB_BUS_ALIGN] + CFG_INST_SB_OFFSET[CAFU_CSR0_CFG_CFG_ADDR_MSB:ADDR_LSB_BUS_ALIGN];
localparam [CAFU_CSR0_CFG_CFG_ADDR_MSB-ADDR_LSB_BUS_ALIGN:0] CXL_DVSEC_TEST_LOCK_DECODE_ADDR = CXL_DVSEC_TEST_LOCK_CR_ADDR[CAFU_CSR0_CFG_CFG_ADDR_MSB:ADDR_LSB_BUS_ALIGN] + CFG_INST_SB_OFFSET[CAFU_CSR0_CFG_CFG_ADDR_MSB:ADDR_LSB_BUS_ALIGN];
localparam [CAFU_CSR0_CFG_CFG_ADDR_MSB-ADDR_LSB_BUS_ALIGN:0] CXL_DVSEC_TEST_CAP1_DECODE_ADDR = CXL_DVSEC_TEST_CAP1_CR_ADDR[CAFU_CSR0_CFG_CFG_ADDR_MSB:ADDR_LSB_BUS_ALIGN] + CFG_INST_SB_OFFSET[CAFU_CSR0_CFG_CFG_ADDR_MSB:ADDR_LSB_BUS_ALIGN];
localparam [CAFU_CSR0_CFG_CFG_ADDR_MSB-ADDR_LSB_BUS_ALIGN:0] CXL_DVSEC_TEST_CAP2_DECODE_ADDR = CXL_DVSEC_TEST_CAP2_CR_ADDR[CAFU_CSR0_CFG_CFG_ADDR_MSB:ADDR_LSB_BUS_ALIGN] + CFG_INST_SB_OFFSET[CAFU_CSR0_CFG_CFG_ADDR_MSB:ADDR_LSB_BUS_ALIGN];
localparam [CAFU_CSR0_CFG_CFG_ADDR_MSB-ADDR_LSB_BUS_ALIGN:0] CXL_DVSEC_TEST_CNF_BASE_LOW_DECODE_ADDR = CXL_DVSEC_TEST_CNF_BASE_LOW_CR_ADDR[CAFU_CSR0_CFG_CFG_ADDR_MSB:ADDR_LSB_BUS_ALIGN] + CFG_INST_SB_OFFSET[CAFU_CSR0_CFG_CFG_ADDR_MSB:ADDR_LSB_BUS_ALIGN];
localparam [CAFU_CSR0_CFG_CFG_ADDR_MSB-ADDR_LSB_BUS_ALIGN:0] CXL_DVSEC_TEST_CNF_BASE_HIGH_DECODE_ADDR = CXL_DVSEC_TEST_CNF_BASE_HIGH_CR_ADDR[CAFU_CSR0_CFG_CFG_ADDR_MSB:ADDR_LSB_BUS_ALIGN] + CFG_INST_SB_OFFSET[CAFU_CSR0_CFG_CFG_ADDR_MSB:ADDR_LSB_BUS_ALIGN];
localparam [CAFU_CSR0_CFG_MEM_ADDR_MSB-ADDR_LSB_BUS_ALIGN:0] CXL_DEV_CAP_ARRAY_0_DECODE_ADDR = CXL_DEV_CAP_ARRAY_0_CR_ADDR[CAFU_CSR0_CFG_MEM_ADDR_MSB:ADDR_LSB_BUS_ALIGN] + MEM_INST_SB_OFFSET[CAFU_CSR0_CFG_MEM_ADDR_MSB:ADDR_LSB_BUS_ALIGN];
localparam [CAFU_CSR0_CFG_MEM_ADDR_MSB-ADDR_LSB_BUS_ALIGN:0] CXL_DEV_CAP_ARRAY_1_DECODE_ADDR = CXL_DEV_CAP_ARRAY_1_CR_ADDR[CAFU_CSR0_CFG_MEM_ADDR_MSB:ADDR_LSB_BUS_ALIGN] + MEM_INST_SB_OFFSET[CAFU_CSR0_CFG_MEM_ADDR_MSB:ADDR_LSB_BUS_ALIGN];
localparam [CAFU_CSR0_CFG_MEM_ADDR_MSB-ADDR_LSB_BUS_ALIGN:0] CXL_DEV_CAP_HDR1_0_DECODE_ADDR = CXL_DEV_CAP_HDR1_0_CR_ADDR[CAFU_CSR0_CFG_MEM_ADDR_MSB:ADDR_LSB_BUS_ALIGN] + MEM_INST_SB_OFFSET[CAFU_CSR0_CFG_MEM_ADDR_MSB:ADDR_LSB_BUS_ALIGN];
localparam [CAFU_CSR0_CFG_MEM_ADDR_MSB-ADDR_LSB_BUS_ALIGN:0] CXL_DEV_CAP_HDR1_1_DECODE_ADDR = CXL_DEV_CAP_HDR1_1_CR_ADDR[CAFU_CSR0_CFG_MEM_ADDR_MSB:ADDR_LSB_BUS_ALIGN] + MEM_INST_SB_OFFSET[CAFU_CSR0_CFG_MEM_ADDR_MSB:ADDR_LSB_BUS_ALIGN];
localparam [CAFU_CSR0_CFG_MEM_ADDR_MSB-ADDR_LSB_BUS_ALIGN:0] CXL_DEV_CAP_HDR1_2_DECODE_ADDR = CXL_DEV_CAP_HDR1_2_CR_ADDR[CAFU_CSR0_CFG_MEM_ADDR_MSB:ADDR_LSB_BUS_ALIGN] + MEM_INST_SB_OFFSET[CAFU_CSR0_CFG_MEM_ADDR_MSB:ADDR_LSB_BUS_ALIGN];
localparam [CAFU_CSR0_CFG_MEM_ADDR_MSB-ADDR_LSB_BUS_ALIGN:0] CXL_DEV_CAP_HDR2_0_DECODE_ADDR = CXL_DEV_CAP_HDR2_0_CR_ADDR[CAFU_CSR0_CFG_MEM_ADDR_MSB:ADDR_LSB_BUS_ALIGN] + MEM_INST_SB_OFFSET[CAFU_CSR0_CFG_MEM_ADDR_MSB:ADDR_LSB_BUS_ALIGN];
localparam [CAFU_CSR0_CFG_MEM_ADDR_MSB-ADDR_LSB_BUS_ALIGN:0] CXL_DEV_CAP_HDR2_1_DECODE_ADDR = CXL_DEV_CAP_HDR2_1_CR_ADDR[CAFU_CSR0_CFG_MEM_ADDR_MSB:ADDR_LSB_BUS_ALIGN] + MEM_INST_SB_OFFSET[CAFU_CSR0_CFG_MEM_ADDR_MSB:ADDR_LSB_BUS_ALIGN];
localparam [CAFU_CSR0_CFG_MEM_ADDR_MSB-ADDR_LSB_BUS_ALIGN:0] CXL_DEV_CAP_HDR2_2_DECODE_ADDR = CXL_DEV_CAP_HDR2_2_CR_ADDR[CAFU_CSR0_CFG_MEM_ADDR_MSB:ADDR_LSB_BUS_ALIGN] + MEM_INST_SB_OFFSET[CAFU_CSR0_CFG_MEM_ADDR_MSB:ADDR_LSB_BUS_ALIGN];
localparam [CAFU_CSR0_CFG_MEM_ADDR_MSB-ADDR_LSB_BUS_ALIGN:0] CXL_DEV_CAP_HDR3_0_DECODE_ADDR = CXL_DEV_CAP_HDR3_0_CR_ADDR[CAFU_CSR0_CFG_MEM_ADDR_MSB:ADDR_LSB_BUS_ALIGN] + MEM_INST_SB_OFFSET[CAFU_CSR0_CFG_MEM_ADDR_MSB:ADDR_LSB_BUS_ALIGN];
localparam [CAFU_CSR0_CFG_MEM_ADDR_MSB-ADDR_LSB_BUS_ALIGN:0] CXL_DEV_CAP_HDR3_1_DECODE_ADDR = CXL_DEV_CAP_HDR3_1_CR_ADDR[CAFU_CSR0_CFG_MEM_ADDR_MSB:ADDR_LSB_BUS_ALIGN] + MEM_INST_SB_OFFSET[CAFU_CSR0_CFG_MEM_ADDR_MSB:ADDR_LSB_BUS_ALIGN];
localparam [CAFU_CSR0_CFG_MEM_ADDR_MSB-ADDR_LSB_BUS_ALIGN:0] CXL_DEV_CAP_HDR3_2_DECODE_ADDR = CXL_DEV_CAP_HDR3_2_CR_ADDR[CAFU_CSR0_CFG_MEM_ADDR_MSB:ADDR_LSB_BUS_ALIGN] + MEM_INST_SB_OFFSET[CAFU_CSR0_CFG_MEM_ADDR_MSB:ADDR_LSB_BUS_ALIGN];
localparam [CAFU_CSR0_CFG_MEM_ADDR_MSB-ADDR_LSB_BUS_ALIGN:0] CXL_DEV_CAP_EVENT_STATUS_DECODE_ADDR = CXL_DEV_CAP_EVENT_STATUS_CR_ADDR[CAFU_CSR0_CFG_MEM_ADDR_MSB:ADDR_LSB_BUS_ALIGN] + MEM_INST_SB_OFFSET[CAFU_CSR0_CFG_MEM_ADDR_MSB:ADDR_LSB_BUS_ALIGN];
localparam [CAFU_CSR0_CFG_MEM_ADDR_MSB-ADDR_LSB_BUS_ALIGN:0] CXL_MEM_DEV_STATUS_DECODE_ADDR = CXL_MEM_DEV_STATUS_CR_ADDR[CAFU_CSR0_CFG_MEM_ADDR_MSB:ADDR_LSB_BUS_ALIGN] + MEM_INST_SB_OFFSET[CAFU_CSR0_CFG_MEM_ADDR_MSB:ADDR_LSB_BUS_ALIGN];
localparam [CAFU_CSR0_CFG_MEM_ADDR_MSB-ADDR_LSB_BUS_ALIGN:0] CXL_MB_CAP_DECODE_ADDR = CXL_MB_CAP_CR_ADDR[CAFU_CSR0_CFG_MEM_ADDR_MSB:ADDR_LSB_BUS_ALIGN] + MEM_INST_SB_OFFSET[CAFU_CSR0_CFG_MEM_ADDR_MSB:ADDR_LSB_BUS_ALIGN];
localparam [CAFU_CSR0_CFG_MEM_ADDR_MSB-ADDR_LSB_BUS_ALIGN:0] CXL_MB_CTRL_DECODE_ADDR = CXL_MB_CTRL_CR_ADDR[CAFU_CSR0_CFG_MEM_ADDR_MSB:ADDR_LSB_BUS_ALIGN] + MEM_INST_SB_OFFSET[CAFU_CSR0_CFG_MEM_ADDR_MSB:ADDR_LSB_BUS_ALIGN];
localparam [CAFU_CSR0_CFG_MEM_ADDR_MSB-ADDR_LSB_BUS_ALIGN:0] CXL_MB_CMD_DECODE_ADDR = CXL_MB_CMD_CR_ADDR[CAFU_CSR0_CFG_MEM_ADDR_MSB:ADDR_LSB_BUS_ALIGN] + MEM_INST_SB_OFFSET[CAFU_CSR0_CFG_MEM_ADDR_MSB:ADDR_LSB_BUS_ALIGN];
localparam [CAFU_CSR0_CFG_MEM_ADDR_MSB-ADDR_LSB_BUS_ALIGN:0] CXL_MB_STATUS_DECODE_ADDR = CXL_MB_STATUS_CR_ADDR[CAFU_CSR0_CFG_MEM_ADDR_MSB:ADDR_LSB_BUS_ALIGN] + MEM_INST_SB_OFFSET[CAFU_CSR0_CFG_MEM_ADDR_MSB:ADDR_LSB_BUS_ALIGN];
localparam [CAFU_CSR0_CFG_MEM_ADDR_MSB-ADDR_LSB_BUS_ALIGN:0] CXL_MB_BK_CMD_STATUS_DECODE_ADDR = CXL_MB_BK_CMD_STATUS_CR_ADDR[CAFU_CSR0_CFG_MEM_ADDR_MSB:ADDR_LSB_BUS_ALIGN] + MEM_INST_SB_OFFSET[CAFU_CSR0_CFG_MEM_ADDR_MSB:ADDR_LSB_BUS_ALIGN];
localparam [CAFU_CSR0_CFG_MEM_ADDR_MSB-ADDR_LSB_BUS_ALIGN:0] CXL_MB_PAY_START_DECODE_ADDR = CXL_MB_PAY_START_CR_ADDR[CAFU_CSR0_CFG_MEM_ADDR_MSB:ADDR_LSB_BUS_ALIGN] + MEM_INST_SB_OFFSET[CAFU_CSR0_CFG_MEM_ADDR_MSB:ADDR_LSB_BUS_ALIGN];
localparam [CAFU_CSR0_CFG_MEM_ADDR_MSB-ADDR_LSB_BUS_ALIGN:0] CXL_MB_PAY_END_DECODE_ADDR = CXL_MB_PAY_END_CR_ADDR[CAFU_CSR0_CFG_MEM_ADDR_MSB:ADDR_LSB_BUS_ALIGN] + MEM_INST_SB_OFFSET[CAFU_CSR0_CFG_MEM_ADDR_MSB:ADDR_LSB_BUS_ALIGN];
localparam [CAFU_CSR0_CFG_MEM_ADDR_MSB-ADDR_LSB_BUS_ALIGN:0] HDM_DEC_CAP_DECODE_ADDR = HDM_DEC_CAP_CR_ADDR[CAFU_CSR0_CFG_MEM_ADDR_MSB:ADDR_LSB_BUS_ALIGN] + MEM_INST_SB_OFFSET[CAFU_CSR0_CFG_MEM_ADDR_MSB:ADDR_LSB_BUS_ALIGN];
localparam [CAFU_CSR0_CFG_MEM_ADDR_MSB-ADDR_LSB_BUS_ALIGN:0] HDM_DEC_GBL_CTRL_DECODE_ADDR = HDM_DEC_GBL_CTRL_CR_ADDR[CAFU_CSR0_CFG_MEM_ADDR_MSB:ADDR_LSB_BUS_ALIGN] + MEM_INST_SB_OFFSET[CAFU_CSR0_CFG_MEM_ADDR_MSB:ADDR_LSB_BUS_ALIGN];
localparam [CAFU_CSR0_CFG_MEM_ADDR_MSB-ADDR_LSB_BUS_ALIGN:0] HDM_DEC_BASELOW_DECODE_ADDR = HDM_DEC_BASELOW_CR_ADDR[CAFU_CSR0_CFG_MEM_ADDR_MSB:ADDR_LSB_BUS_ALIGN] + MEM_INST_SB_OFFSET[CAFU_CSR0_CFG_MEM_ADDR_MSB:ADDR_LSB_BUS_ALIGN];
localparam [CAFU_CSR0_CFG_MEM_ADDR_MSB-ADDR_LSB_BUS_ALIGN:0] HDM_DEC_BASEHIGH_DECODE_ADDR = HDM_DEC_BASEHIGH_CR_ADDR[CAFU_CSR0_CFG_MEM_ADDR_MSB:ADDR_LSB_BUS_ALIGN] + MEM_INST_SB_OFFSET[CAFU_CSR0_CFG_MEM_ADDR_MSB:ADDR_LSB_BUS_ALIGN];
localparam [CAFU_CSR0_CFG_MEM_ADDR_MSB-ADDR_LSB_BUS_ALIGN:0] HDM_DEC_SIZELOW_DECODE_ADDR = HDM_DEC_SIZELOW_CR_ADDR[CAFU_CSR0_CFG_MEM_ADDR_MSB:ADDR_LSB_BUS_ALIGN] + MEM_INST_SB_OFFSET[CAFU_CSR0_CFG_MEM_ADDR_MSB:ADDR_LSB_BUS_ALIGN];
localparam [CAFU_CSR0_CFG_MEM_ADDR_MSB-ADDR_LSB_BUS_ALIGN:0] HDM_DEC_SIZEHIGH_DECODE_ADDR = HDM_DEC_SIZEHIGH_CR_ADDR[CAFU_CSR0_CFG_MEM_ADDR_MSB:ADDR_LSB_BUS_ALIGN] + MEM_INST_SB_OFFSET[CAFU_CSR0_CFG_MEM_ADDR_MSB:ADDR_LSB_BUS_ALIGN];
localparam [CAFU_CSR0_CFG_MEM_ADDR_MSB-ADDR_LSB_BUS_ALIGN:0] HDM_DEC_CTRL_DECODE_ADDR = HDM_DEC_CTRL_CR_ADDR[CAFU_CSR0_CFG_MEM_ADDR_MSB:ADDR_LSB_BUS_ALIGN] + MEM_INST_SB_OFFSET[CAFU_CSR0_CFG_MEM_ADDR_MSB:ADDR_LSB_BUS_ALIGN];
localparam [CAFU_CSR0_CFG_MEM_ADDR_MSB-ADDR_LSB_BUS_ALIGN:0] HDM_DEC_DPALOW_DECODE_ADDR = HDM_DEC_DPALOW_CR_ADDR[CAFU_CSR0_CFG_MEM_ADDR_MSB:ADDR_LSB_BUS_ALIGN] + MEM_INST_SB_OFFSET[CAFU_CSR0_CFG_MEM_ADDR_MSB:ADDR_LSB_BUS_ALIGN];
localparam [CAFU_CSR0_CFG_MEM_ADDR_MSB-ADDR_LSB_BUS_ALIGN:0] HDM_DEC_DPAHIGH_DECODE_ADDR = HDM_DEC_DPAHIGH_CR_ADDR[CAFU_CSR0_CFG_MEM_ADDR_MSB:ADDR_LSB_BUS_ALIGN] + MEM_INST_SB_OFFSET[CAFU_CSR0_CFG_MEM_ADDR_MSB:ADDR_LSB_BUS_ALIGN];
localparam [CAFU_CSR0_CFG_MEM_ADDR_MSB-ADDR_LSB_BUS_ALIGN:0] CONFIG_TEST_START_ADDR_DECODE_ADDR = CONFIG_TEST_START_ADDR_CR_ADDR[CAFU_CSR0_CFG_MEM_ADDR_MSB:ADDR_LSB_BUS_ALIGN] + MEM_INST_SB_OFFSET[CAFU_CSR0_CFG_MEM_ADDR_MSB:ADDR_LSB_BUS_ALIGN];
localparam [CAFU_CSR0_CFG_MEM_ADDR_MSB-ADDR_LSB_BUS_ALIGN:0] CONFIG_TEST_WR_BACK_ADDR_DECODE_ADDR = CONFIG_TEST_WR_BACK_ADDR_CR_ADDR[CAFU_CSR0_CFG_MEM_ADDR_MSB:ADDR_LSB_BUS_ALIGN] + MEM_INST_SB_OFFSET[CAFU_CSR0_CFG_MEM_ADDR_MSB:ADDR_LSB_BUS_ALIGN];
localparam [CAFU_CSR0_CFG_MEM_ADDR_MSB-ADDR_LSB_BUS_ALIGN:0] CONFIG_TEST_ADDR_INCRE_DECODE_ADDR = CONFIG_TEST_ADDR_INCRE_CR_ADDR[CAFU_CSR0_CFG_MEM_ADDR_MSB:ADDR_LSB_BUS_ALIGN] + MEM_INST_SB_OFFSET[CAFU_CSR0_CFG_MEM_ADDR_MSB:ADDR_LSB_BUS_ALIGN];
localparam [CAFU_CSR0_CFG_MEM_ADDR_MSB-ADDR_LSB_BUS_ALIGN:0] CONFIG_TEST_PATTERN_DECODE_ADDR = CONFIG_TEST_PATTERN_CR_ADDR[CAFU_CSR0_CFG_MEM_ADDR_MSB:ADDR_LSB_BUS_ALIGN] + MEM_INST_SB_OFFSET[CAFU_CSR0_CFG_MEM_ADDR_MSB:ADDR_LSB_BUS_ALIGN];
localparam [CAFU_CSR0_CFG_MEM_ADDR_MSB-ADDR_LSB_BUS_ALIGN:0] CONFIG_TEST_BYTEMASK_DECODE_ADDR = CONFIG_TEST_BYTEMASK_CR_ADDR[CAFU_CSR0_CFG_MEM_ADDR_MSB:ADDR_LSB_BUS_ALIGN] + MEM_INST_SB_OFFSET[CAFU_CSR0_CFG_MEM_ADDR_MSB:ADDR_LSB_BUS_ALIGN];
localparam [CAFU_CSR0_CFG_MEM_ADDR_MSB-ADDR_LSB_BUS_ALIGN:0] CONFIG_TEST_PATTERN_PARAM_DECODE_ADDR = CONFIG_TEST_PATTERN_PARAM_CR_ADDR[CAFU_CSR0_CFG_MEM_ADDR_MSB:ADDR_LSB_BUS_ALIGN] + MEM_INST_SB_OFFSET[CAFU_CSR0_CFG_MEM_ADDR_MSB:ADDR_LSB_BUS_ALIGN];
localparam [CAFU_CSR0_CFG_MEM_ADDR_MSB-ADDR_LSB_BUS_ALIGN:0] CONFIG_ALGO_SETTING_DECODE_ADDR = CONFIG_ALGO_SETTING_CR_ADDR[CAFU_CSR0_CFG_MEM_ADDR_MSB:ADDR_LSB_BUS_ALIGN] + MEM_INST_SB_OFFSET[CAFU_CSR0_CFG_MEM_ADDR_MSB:ADDR_LSB_BUS_ALIGN];
localparam [CAFU_CSR0_CFG_MEM_ADDR_MSB-ADDR_LSB_BUS_ALIGN:0] CONFIG_DEVICE_INJECTION_DECODE_ADDR = CONFIG_DEVICE_INJECTION_CR_ADDR[CAFU_CSR0_CFG_MEM_ADDR_MSB:ADDR_LSB_BUS_ALIGN] + MEM_INST_SB_OFFSET[CAFU_CSR0_CFG_MEM_ADDR_MSB:ADDR_LSB_BUS_ALIGN];
localparam [CAFU_CSR0_CFG_MEM_ADDR_MSB-ADDR_LSB_BUS_ALIGN:0] DEVICE_ERROR_LOG1_DECODE_ADDR = DEVICE_ERROR_LOG1_CR_ADDR[CAFU_CSR0_CFG_MEM_ADDR_MSB:ADDR_LSB_BUS_ALIGN] + MEM_INST_SB_OFFSET[CAFU_CSR0_CFG_MEM_ADDR_MSB:ADDR_LSB_BUS_ALIGN];
localparam [CAFU_CSR0_CFG_MEM_ADDR_MSB-ADDR_LSB_BUS_ALIGN:0] DEVICE_ERROR_LOG2_DECODE_ADDR = DEVICE_ERROR_LOG2_CR_ADDR[CAFU_CSR0_CFG_MEM_ADDR_MSB:ADDR_LSB_BUS_ALIGN] + MEM_INST_SB_OFFSET[CAFU_CSR0_CFG_MEM_ADDR_MSB:ADDR_LSB_BUS_ALIGN];
localparam [CAFU_CSR0_CFG_MEM_ADDR_MSB-ADDR_LSB_BUS_ALIGN:0] DEVICE_ERROR_LOG3_DECODE_ADDR = DEVICE_ERROR_LOG3_CR_ADDR[CAFU_CSR0_CFG_MEM_ADDR_MSB:ADDR_LSB_BUS_ALIGN] + MEM_INST_SB_OFFSET[CAFU_CSR0_CFG_MEM_ADDR_MSB:ADDR_LSB_BUS_ALIGN];
localparam [CAFU_CSR0_CFG_MEM_ADDR_MSB-ADDR_LSB_BUS_ALIGN:0] DEVICE_EVENT_CTRL_DECODE_ADDR = DEVICE_EVENT_CTRL_CR_ADDR[CAFU_CSR0_CFG_MEM_ADDR_MSB:ADDR_LSB_BUS_ALIGN] + MEM_INST_SB_OFFSET[CAFU_CSR0_CFG_MEM_ADDR_MSB:ADDR_LSB_BUS_ALIGN];
localparam [CAFU_CSR0_CFG_MEM_ADDR_MSB-ADDR_LSB_BUS_ALIGN:0] DEVICE_EVENT_COUNT_DECODE_ADDR = DEVICE_EVENT_COUNT_CR_ADDR[CAFU_CSR0_CFG_MEM_ADDR_MSB:ADDR_LSB_BUS_ALIGN] + MEM_INST_SB_OFFSET[CAFU_CSR0_CFG_MEM_ADDR_MSB:ADDR_LSB_BUS_ALIGN];
localparam [CAFU_CSR0_CFG_MEM_ADDR_MSB-ADDR_LSB_BUS_ALIGN:0] DEVICE_ERROR_INJECTION_DECODE_ADDR = DEVICE_ERROR_INJECTION_CR_ADDR[CAFU_CSR0_CFG_MEM_ADDR_MSB:ADDR_LSB_BUS_ALIGN] + MEM_INST_SB_OFFSET[CAFU_CSR0_CFG_MEM_ADDR_MSB:ADDR_LSB_BUS_ALIGN];
localparam [CAFU_CSR0_CFG_MEM_ADDR_MSB-ADDR_LSB_BUS_ALIGN:0] DEVICE_FORCE_DISABLE_DECODE_ADDR = DEVICE_FORCE_DISABLE_CR_ADDR[CAFU_CSR0_CFG_MEM_ADDR_MSB:ADDR_LSB_BUS_ALIGN] + MEM_INST_SB_OFFSET[CAFU_CSR0_CFG_MEM_ADDR_MSB:ADDR_LSB_BUS_ALIGN];
localparam [CAFU_CSR0_CFG_MEM_ADDR_MSB-ADDR_LSB_BUS_ALIGN:0] DEVICE_ERROR_LOG4_DECODE_ADDR = DEVICE_ERROR_LOG4_CR_ADDR[CAFU_CSR0_CFG_MEM_ADDR_MSB:ADDR_LSB_BUS_ALIGN] + MEM_INST_SB_OFFSET[CAFU_CSR0_CFG_MEM_ADDR_MSB:ADDR_LSB_BUS_ALIGN];
localparam [CAFU_CSR0_CFG_MEM_ADDR_MSB-ADDR_LSB_BUS_ALIGN:0] DEVICE_ERROR_LOG5_DECODE_ADDR = DEVICE_ERROR_LOG5_CR_ADDR[CAFU_CSR0_CFG_MEM_ADDR_MSB:ADDR_LSB_BUS_ALIGN] + MEM_INST_SB_OFFSET[CAFU_CSR0_CFG_MEM_ADDR_MSB:ADDR_LSB_BUS_ALIGN];
localparam [CAFU_CSR0_CFG_MEM_ADDR_MSB-ADDR_LSB_BUS_ALIGN:0] CONFIG_CXL_ERRORS_DECODE_ADDR = CONFIG_CXL_ERRORS_CR_ADDR[CAFU_CSR0_CFG_MEM_ADDR_MSB:ADDR_LSB_BUS_ALIGN] + MEM_INST_SB_OFFSET[CAFU_CSR0_CFG_MEM_ADDR_MSB:ADDR_LSB_BUS_ALIGN];
localparam [CAFU_CSR0_CFG_MEM_ADDR_MSB-ADDR_LSB_BUS_ALIGN:0] DEVICE_AFU_STATUS1_DECODE_ADDR = DEVICE_AFU_STATUS1_CR_ADDR[CAFU_CSR0_CFG_MEM_ADDR_MSB:ADDR_LSB_BUS_ALIGN] + MEM_INST_SB_OFFSET[CAFU_CSR0_CFG_MEM_ADDR_MSB:ADDR_LSB_BUS_ALIGN];
localparam [CAFU_CSR0_CFG_MEM_ADDR_MSB-ADDR_LSB_BUS_ALIGN:0] DEVICE_AFU_STATUS2_DECODE_ADDR = DEVICE_AFU_STATUS2_CR_ADDR[CAFU_CSR0_CFG_MEM_ADDR_MSB:ADDR_LSB_BUS_ALIGN] + MEM_INST_SB_OFFSET[CAFU_CSR0_CFG_MEM_ADDR_MSB:ADDR_LSB_BUS_ALIGN];
localparam [CAFU_CSR0_CFG_MEM_ADDR_MSB-ADDR_LSB_BUS_ALIGN:0] DEVICE_AXI2CPI_STATUS_1_DECODE_ADDR = DEVICE_AXI2CPI_STATUS_1_CR_ADDR[CAFU_CSR0_CFG_MEM_ADDR_MSB:ADDR_LSB_BUS_ALIGN] + MEM_INST_SB_OFFSET[CAFU_CSR0_CFG_MEM_ADDR_MSB:ADDR_LSB_BUS_ALIGN];
localparam [CAFU_CSR0_CFG_MEM_ADDR_MSB-ADDR_LSB_BUS_ALIGN:0] DEVICE_AXI2CPI_STATUS_2_DECODE_ADDR = DEVICE_AXI2CPI_STATUS_2_CR_ADDR[CAFU_CSR0_CFG_MEM_ADDR_MSB:ADDR_LSB_BUS_ALIGN] + MEM_INST_SB_OFFSET[CAFU_CSR0_CFG_MEM_ADDR_MSB:ADDR_LSB_BUS_ALIGN];
localparam [CAFU_CSR0_CFG_MEM_ADDR_MSB-ADDR_LSB_BUS_ALIGN:0] CDAT_0_DECODE_ADDR = CDAT_0_CR_ADDR[CAFU_CSR0_CFG_MEM_ADDR_MSB:ADDR_LSB_BUS_ALIGN] + MEM_INST_SB_OFFSET[CAFU_CSR0_CFG_MEM_ADDR_MSB:ADDR_LSB_BUS_ALIGN];
localparam [CAFU_CSR0_CFG_MEM_ADDR_MSB-ADDR_LSB_BUS_ALIGN:0] CDAT_1_DECODE_ADDR = CDAT_1_CR_ADDR[CAFU_CSR0_CFG_MEM_ADDR_MSB:ADDR_LSB_BUS_ALIGN] + MEM_INST_SB_OFFSET[CAFU_CSR0_CFG_MEM_ADDR_MSB:ADDR_LSB_BUS_ALIGN];
localparam [CAFU_CSR0_CFG_MEM_ADDR_MSB-ADDR_LSB_BUS_ALIGN:0] CDAT_2_DECODE_ADDR = CDAT_2_CR_ADDR[CAFU_CSR0_CFG_MEM_ADDR_MSB:ADDR_LSB_BUS_ALIGN] + MEM_INST_SB_OFFSET[CAFU_CSR0_CFG_MEM_ADDR_MSB:ADDR_LSB_BUS_ALIGN];
localparam [CAFU_CSR0_CFG_MEM_ADDR_MSB-ADDR_LSB_BUS_ALIGN:0] CDAT_3_DECODE_ADDR = CDAT_3_CR_ADDR[CAFU_CSR0_CFG_MEM_ADDR_MSB:ADDR_LSB_BUS_ALIGN] + MEM_INST_SB_OFFSET[CAFU_CSR0_CFG_MEM_ADDR_MSB:ADDR_LSB_BUS_ALIGN];
localparam [CAFU_CSR0_CFG_MEM_ADDR_MSB-ADDR_LSB_BUS_ALIGN:0] DSMAS_0_DECODE_ADDR = DSMAS_0_CR_ADDR[CAFU_CSR0_CFG_MEM_ADDR_MSB:ADDR_LSB_BUS_ALIGN] + MEM_INST_SB_OFFSET[CAFU_CSR0_CFG_MEM_ADDR_MSB:ADDR_LSB_BUS_ALIGN];
localparam [CAFU_CSR0_CFG_MEM_ADDR_MSB-ADDR_LSB_BUS_ALIGN:0] DSMAS_1_DECODE_ADDR = DSMAS_1_CR_ADDR[CAFU_CSR0_CFG_MEM_ADDR_MSB:ADDR_LSB_BUS_ALIGN] + MEM_INST_SB_OFFSET[CAFU_CSR0_CFG_MEM_ADDR_MSB:ADDR_LSB_BUS_ALIGN];
localparam [CAFU_CSR0_CFG_MEM_ADDR_MSB-ADDR_LSB_BUS_ALIGN:0] DSMAS_2_DECODE_ADDR = DSMAS_2_CR_ADDR[CAFU_CSR0_CFG_MEM_ADDR_MSB:ADDR_LSB_BUS_ALIGN] + MEM_INST_SB_OFFSET[CAFU_CSR0_CFG_MEM_ADDR_MSB:ADDR_LSB_BUS_ALIGN];
localparam [CAFU_CSR0_CFG_MEM_ADDR_MSB-ADDR_LSB_BUS_ALIGN:0] DSMAS_3_DECODE_ADDR = DSMAS_3_CR_ADDR[CAFU_CSR0_CFG_MEM_ADDR_MSB:ADDR_LSB_BUS_ALIGN] + MEM_INST_SB_OFFSET[CAFU_CSR0_CFG_MEM_ADDR_MSB:ADDR_LSB_BUS_ALIGN];
localparam [CAFU_CSR0_CFG_MEM_ADDR_MSB-ADDR_LSB_BUS_ALIGN:0] DSMAS_4_DECODE_ADDR = DSMAS_4_CR_ADDR[CAFU_CSR0_CFG_MEM_ADDR_MSB:ADDR_LSB_BUS_ALIGN] + MEM_INST_SB_OFFSET[CAFU_CSR0_CFG_MEM_ADDR_MSB:ADDR_LSB_BUS_ALIGN];
localparam [CAFU_CSR0_CFG_MEM_ADDR_MSB-ADDR_LSB_BUS_ALIGN:0] DSMAS_5_DECODE_ADDR = DSMAS_5_CR_ADDR[CAFU_CSR0_CFG_MEM_ADDR_MSB:ADDR_LSB_BUS_ALIGN] + MEM_INST_SB_OFFSET[CAFU_CSR0_CFG_MEM_ADDR_MSB:ADDR_LSB_BUS_ALIGN];
localparam [CAFU_CSR0_CFG_MEM_ADDR_MSB-ADDR_LSB_BUS_ALIGN:0] DSIS_0_DECODE_ADDR = DSIS_0_CR_ADDR[CAFU_CSR0_CFG_MEM_ADDR_MSB:ADDR_LSB_BUS_ALIGN] + MEM_INST_SB_OFFSET[CAFU_CSR0_CFG_MEM_ADDR_MSB:ADDR_LSB_BUS_ALIGN];
localparam [CAFU_CSR0_CFG_MEM_ADDR_MSB-ADDR_LSB_BUS_ALIGN:0] DSIS_1_DECODE_ADDR = DSIS_1_CR_ADDR[CAFU_CSR0_CFG_MEM_ADDR_MSB:ADDR_LSB_BUS_ALIGN] + MEM_INST_SB_OFFSET[CAFU_CSR0_CFG_MEM_ADDR_MSB:ADDR_LSB_BUS_ALIGN];
localparam [CAFU_CSR0_CFG_MEM_ADDR_MSB-ADDR_LSB_BUS_ALIGN:0] DSLBIS_0_DECODE_ADDR = DSLBIS_0_CR_ADDR[CAFU_CSR0_CFG_MEM_ADDR_MSB:ADDR_LSB_BUS_ALIGN] + MEM_INST_SB_OFFSET[CAFU_CSR0_CFG_MEM_ADDR_MSB:ADDR_LSB_BUS_ALIGN];
localparam [CAFU_CSR0_CFG_MEM_ADDR_MSB-ADDR_LSB_BUS_ALIGN:0] DSLBIS_1_DECODE_ADDR = DSLBIS_1_CR_ADDR[CAFU_CSR0_CFG_MEM_ADDR_MSB:ADDR_LSB_BUS_ALIGN] + MEM_INST_SB_OFFSET[CAFU_CSR0_CFG_MEM_ADDR_MSB:ADDR_LSB_BUS_ALIGN];
localparam [CAFU_CSR0_CFG_MEM_ADDR_MSB-ADDR_LSB_BUS_ALIGN:0] DSLBIS_2_DECODE_ADDR = DSLBIS_2_CR_ADDR[CAFU_CSR0_CFG_MEM_ADDR_MSB:ADDR_LSB_BUS_ALIGN] + MEM_INST_SB_OFFSET[CAFU_CSR0_CFG_MEM_ADDR_MSB:ADDR_LSB_BUS_ALIGN];
localparam [CAFU_CSR0_CFG_MEM_ADDR_MSB-ADDR_LSB_BUS_ALIGN:0] DSLBIS_3_DECODE_ADDR = DSLBIS_3_CR_ADDR[CAFU_CSR0_CFG_MEM_ADDR_MSB:ADDR_LSB_BUS_ALIGN] + MEM_INST_SB_OFFSET[CAFU_CSR0_CFG_MEM_ADDR_MSB:ADDR_LSB_BUS_ALIGN];
localparam [CAFU_CSR0_CFG_MEM_ADDR_MSB-ADDR_LSB_BUS_ALIGN:0] DSLBIS_4_DECODE_ADDR = DSLBIS_4_CR_ADDR[CAFU_CSR0_CFG_MEM_ADDR_MSB:ADDR_LSB_BUS_ALIGN] + MEM_INST_SB_OFFSET[CAFU_CSR0_CFG_MEM_ADDR_MSB:ADDR_LSB_BUS_ALIGN];
localparam [CAFU_CSR0_CFG_MEM_ADDR_MSB-ADDR_LSB_BUS_ALIGN:0] DSLBIS_5_DECODE_ADDR = DSLBIS_5_CR_ADDR[CAFU_CSR0_CFG_MEM_ADDR_MSB:ADDR_LSB_BUS_ALIGN] + MEM_INST_SB_OFFSET[CAFU_CSR0_CFG_MEM_ADDR_MSB:ADDR_LSB_BUS_ALIGN];
localparam [CAFU_CSR0_CFG_MEM_ADDR_MSB-ADDR_LSB_BUS_ALIGN:0] DSEMTS_0_DECODE_ADDR = DSEMTS_0_CR_ADDR[CAFU_CSR0_CFG_MEM_ADDR_MSB:ADDR_LSB_BUS_ALIGN] + MEM_INST_SB_OFFSET[CAFU_CSR0_CFG_MEM_ADDR_MSB:ADDR_LSB_BUS_ALIGN];
localparam [CAFU_CSR0_CFG_MEM_ADDR_MSB-ADDR_LSB_BUS_ALIGN:0] DSEMTS_1_DECODE_ADDR = DSEMTS_1_CR_ADDR[CAFU_CSR0_CFG_MEM_ADDR_MSB:ADDR_LSB_BUS_ALIGN] + MEM_INST_SB_OFFSET[CAFU_CSR0_CFG_MEM_ADDR_MSB:ADDR_LSB_BUS_ALIGN];
localparam [CAFU_CSR0_CFG_MEM_ADDR_MSB-ADDR_LSB_BUS_ALIGN:0] DSEMTS_2_DECODE_ADDR = DSEMTS_2_CR_ADDR[CAFU_CSR0_CFG_MEM_ADDR_MSB:ADDR_LSB_BUS_ALIGN] + MEM_INST_SB_OFFSET[CAFU_CSR0_CFG_MEM_ADDR_MSB:ADDR_LSB_BUS_ALIGN];
localparam [CAFU_CSR0_CFG_MEM_ADDR_MSB-ADDR_LSB_BUS_ALIGN:0] DSEMTS_3_DECODE_ADDR = DSEMTS_3_CR_ADDR[CAFU_CSR0_CFG_MEM_ADDR_MSB:ADDR_LSB_BUS_ALIGN] + MEM_INST_SB_OFFSET[CAFU_CSR0_CFG_MEM_ADDR_MSB:ADDR_LSB_BUS_ALIGN];
localparam [CAFU_CSR0_CFG_MEM_ADDR_MSB-ADDR_LSB_BUS_ALIGN:0] DSEMTS_4_DECODE_ADDR = DSEMTS_4_CR_ADDR[CAFU_CSR0_CFG_MEM_ADDR_MSB:ADDR_LSB_BUS_ALIGN] + MEM_INST_SB_OFFSET[CAFU_CSR0_CFG_MEM_ADDR_MSB:ADDR_LSB_BUS_ALIGN];
localparam [CAFU_CSR0_CFG_MEM_ADDR_MSB-ADDR_LSB_BUS_ALIGN:0] DSEMTS_5_DECODE_ADDR = DSEMTS_5_CR_ADDR[CAFU_CSR0_CFG_MEM_ADDR_MSB:ADDR_LSB_BUS_ALIGN] + MEM_INST_SB_OFFSET[CAFU_CSR0_CFG_MEM_ADDR_MSB:ADDR_LSB_BUS_ALIGN];
localparam [CAFU_CSR0_CFG_MEM_ADDR_MSB-ADDR_LSB_BUS_ALIGN:0] MC_STATUS_DECODE_ADDR = MC_STATUS_CR_ADDR[CAFU_CSR0_CFG_MEM_ADDR_MSB:ADDR_LSB_BUS_ALIGN] + MEM_INST_SB_OFFSET[CAFU_CSR0_CFG_MEM_ADDR_MSB:ADDR_LSB_BUS_ALIGN];
localparam [CAFU_CSR0_CFG_MEM_ADDR_MSB-ADDR_LSB_BUS_ALIGN:0] DEVMEM_SBECNT_DECODE_ADDR = DEVMEM_SBECNT_CR_ADDR[CAFU_CSR0_CFG_MEM_ADDR_MSB:ADDR_LSB_BUS_ALIGN] + MEM_INST_SB_OFFSET[CAFU_CSR0_CFG_MEM_ADDR_MSB:ADDR_LSB_BUS_ALIGN];
localparam [CAFU_CSR0_CFG_MEM_ADDR_MSB-ADDR_LSB_BUS_ALIGN:0] DEVMEM_DBECNT_DECODE_ADDR = DEVMEM_DBECNT_CR_ADDR[CAFU_CSR0_CFG_MEM_ADDR_MSB:ADDR_LSB_BUS_ALIGN] + MEM_INST_SB_OFFSET[CAFU_CSR0_CFG_MEM_ADDR_MSB:ADDR_LSB_BUS_ALIGN];
localparam [CAFU_CSR0_CFG_MEM_ADDR_MSB-ADDR_LSB_BUS_ALIGN:0] DEVMEM_POISONCNT_DECODE_ADDR = DEVMEM_POISONCNT_CR_ADDR[CAFU_CSR0_CFG_MEM_ADDR_MSB:ADDR_LSB_BUS_ALIGN] + MEM_INST_SB_OFFSET[CAFU_CSR0_CFG_MEM_ADDR_MSB:ADDR_LSB_BUS_ALIGN];
localparam [CAFU_CSR0_CFG_MEM_ADDR_MSB-ADDR_LSB_BUS_ALIGN:0] MBOX_EVENTINJ_DECODE_ADDR = MBOX_EVENTINJ_CR_ADDR[CAFU_CSR0_CFG_MEM_ADDR_MSB:ADDR_LSB_BUS_ALIGN] + MEM_INST_SB_OFFSET[CAFU_CSR0_CFG_MEM_ADDR_MSB:ADDR_LSB_BUS_ALIGN];
localparam [CAFU_CSR0_CFG_MEM_ADDR_MSB-ADDR_LSB_BUS_ALIGN:0] DEVICE_AFU_LATENCY_MODE_DECODE_ADDR = DEVICE_AFU_LATENCY_MODE_CR_ADDR[CAFU_CSR0_CFG_MEM_ADDR_MSB:ADDR_LSB_BUS_ALIGN] + MEM_INST_SB_OFFSET[CAFU_CSR0_CFG_MEM_ADDR_MSB:ADDR_LSB_BUS_ALIGN];

    // Clocks
input logic  gated_clk;
input logic  rtl_clk;

    // Resets
input logic  cxl_or_conv_rst_n;
input logic  pwr_rst_n;
input logic  rst_n;


    // Register Inputs
input load_CDAT_0_t  load_CDAT_0;
input load_CDAT_1_t  load_CDAT_1;
input load_CXL_MB_CMD_t  load_CXL_MB_CMD;
input load_CXL_MB_CTRL_t  load_CXL_MB_CTRL;
input load_DEVICE_ERROR_LOG3_t  load_DEVICE_ERROR_LOG3;
input load_DEVICE_EVENT_COUNT_t  load_DEVICE_EVENT_COUNT;
input load_DOE_CTLREG_t  load_DOE_CTLREG;
input load_DOE_RDMAILREG_t  load_DOE_RDMAILREG;
input load_DOE_STSREG_t  load_DOE_STSREG;
input load_DOE_WRMAILREG_t  load_DOE_WRMAILREG;
input load_DVSEC_FBCTRL2_STATUS2_t  load_DVSEC_FBCTRL2_STATUS2;
input load_DVSEC_FBCTRL_STATUS_t  load_DVSEC_FBCTRL_STATUS;

input lock_HDM_DEC_BASEHIGH_t  lock_HDM_DEC_BASEHIGH;
input lock_HDM_DEC_BASELOW_t  lock_HDM_DEC_BASELOW;
input lock_HDM_DEC_CTRL_t  lock_HDM_DEC_CTRL;
input lock_HDM_DEC_DPAHIGH_t  lock_HDM_DEC_DPAHIGH;
input lock_HDM_DEC_DPALOW_t  lock_HDM_DEC_DPALOW;
input lock_HDM_DEC_SIZEHIGH_t  lock_HDM_DEC_SIZEHIGH;
input lock_HDM_DEC_SIZELOW_t  lock_HDM_DEC_SIZELOW;

input new_CDAT_0_t  new_CDAT_0;
input new_CDAT_1_t  new_CDAT_1;
input new_CONFIG_CXL_ERRORS_t  new_CONFIG_CXL_ERRORS;
input new_CONFIG_DEVICE_INJECTION_t  new_CONFIG_DEVICE_INJECTION;
input new_CXL_DEV_CAP_EVENT_STATUS_t  new_CXL_DEV_CAP_EVENT_STATUS;
input new_CXL_DVSEC_TEST_CNF_BASE_HIGH_t  new_CXL_DVSEC_TEST_CNF_BASE_HIGH;
input new_CXL_DVSEC_TEST_CNF_BASE_LOW_t  new_CXL_DVSEC_TEST_CNF_BASE_LOW;
input new_CXL_MB_BK_CMD_STATUS_t  new_CXL_MB_BK_CMD_STATUS;
input new_CXL_MB_CMD_t  new_CXL_MB_CMD;
input new_CXL_MB_CTRL_t  new_CXL_MB_CTRL;
input new_CXL_MB_STATUS_t  new_CXL_MB_STATUS;
input new_CXL_MEM_DEV_STATUS_t  new_CXL_MEM_DEV_STATUS;
input new_DEVICE_AFU_LATENCY_MODE_t  new_DEVICE_AFU_LATENCY_MODE;
input new_DEVICE_AFU_STATUS1_t  new_DEVICE_AFU_STATUS1;
input new_DEVICE_AFU_STATUS2_t  new_DEVICE_AFU_STATUS2;
input new_DEVICE_AXI2CPI_STATUS_1_t  new_DEVICE_AXI2CPI_STATUS_1;
input new_DEVICE_AXI2CPI_STATUS_2_t  new_DEVICE_AXI2CPI_STATUS_2;
input new_DEVICE_ERROR_INJECTION_t  new_DEVICE_ERROR_INJECTION;
input new_DEVICE_ERROR_LOG1_t  new_DEVICE_ERROR_LOG1;
input new_DEVICE_ERROR_LOG2_t  new_DEVICE_ERROR_LOG2;
input new_DEVICE_ERROR_LOG3_t  new_DEVICE_ERROR_LOG3;
input new_DEVICE_ERROR_LOG4_t  new_DEVICE_ERROR_LOG4;
input new_DEVICE_ERROR_LOG5_t  new_DEVICE_ERROR_LOG5;
input new_DEVICE_EVENT_COUNT_t  new_DEVICE_EVENT_COUNT;
input new_DEVMEM_DBECNT_t  new_DEVMEM_DBECNT;
input new_DEVMEM_POISONCNT_t  new_DEVMEM_POISONCNT;
input new_DEVMEM_SBECNT_t  new_DEVMEM_SBECNT;
input new_DOE_CTLREG_t  new_DOE_CTLREG;
input new_DOE_RDMAILREG_t  new_DOE_RDMAILREG;
input new_DOE_STSREG_t  new_DOE_STSREG;
input new_DOE_WRMAILREG_t  new_DOE_WRMAILREG;
input new_DVSEC_FBCTRL2_STATUS2_t  new_DVSEC_FBCTRL2_STATUS2;
input new_DVSEC_FBCTRL_STATUS_t  new_DVSEC_FBCTRL_STATUS;
input new_HDM_DEC_CTRL_t  new_HDM_DEC_CTRL;
input new_MC_STATUS_t  new_MC_STATUS;


    // Misc Inputs
input logic [13:0] CXL_DVSEC_TEST_CAP2_cache_size_device;
input logic [1:0] CXL_DVSEC_TEST_CAP2_cache_size_unit;
input logic [0:0] POR_DVSEC_FBCAP_HDR2_cache_capable;
input logic [0:0] POR_DVSEC_FBCAP_HDR2_cache_wb_and_inv_capable;
input logic [0:0] POR_DVSEC_FBCAP_HDR2_cxl_reset_capable;
input logic [0:0] POR_DVSEC_FBCAP_HDR2_cxl_reset_mem_clr_capable;
input logic [2:0] POR_DVSEC_FBCAP_HDR2_cxl_reset_timeout;
input logic [1:0] POR_DVSEC_FBCAP_HDR2_hdm_count;
input logic [0:0] POR_DVSEC_FBCAP_HDR2_mem_capable;
input logic [0:0] POR_DVSEC_FBCAP_HDR2_mem_hwinit_mode;
input logic [0:0] POR_DVSEC_FBCAP_HDR2_pm_init_comp_capable;
input logic [7:0] POR_DVSEC_FBLOCK_cache_size;
input logic [3:0] POR_DVSEC_FBLOCK_cache_size_unit;
input logic [31:0] POR_DVSEC_FBRANGE1SZHIGH_memory_size;
input logic [2:0] POR_DVSEC_FBRANGE1SZLOW_desired_interleave;
input logic [2:0] POR_DVSEC_FBRANGE1SZLOW_media_type;
input logic [0:0] POR_DVSEC_FBRANGE1SZLOW_mem_active;
input logic [0:0] POR_DVSEC_FBRANGE1SZLOW_mem_valid;
input logic [2:0] POR_DVSEC_FBRANGE1SZLOW_memory_active_timeout;
input logic [2:0] POR_DVSEC_FBRANGE1SZLOW_memory_class;
input logic [3:0] POR_DVSEC_FBRANGE1SZLOW_memory_size_low;
input logic [3:0] POR_DVSEC_HDR1_dvsec_revision;
input logic [15:0] POR_DVSEC_HDR1_dvsec_vendor_id;
input logic [0:0] support_cache_dirty_evict;
input logic [0:0] support_cache_read_current;
input logic [0:0] support_cache_read_down;
input logic [0:0] support_cache_read_shared;
input logic [0:0] support_cache_write_itom;
input logic [0:0] support_cache_write_wow_inv;
input logic [0:0] support_cache_write_wow_invf;

    // Register Outputs
output CDAT_0_t  CDAT_0;
output CDAT_1_t  CDAT_1;
output CDAT_2_t  CDAT_2;
output CDAT_3_t  CDAT_3;
output CONFIG_ALGO_SETTING_t  CONFIG_ALGO_SETTING;
output CONFIG_CXL_ERRORS_t  CONFIG_CXL_ERRORS;
output CONFIG_DEVICE_INJECTION_t  CONFIG_DEVICE_INJECTION;
output CONFIG_TEST_ADDR_INCRE_t  CONFIG_TEST_ADDR_INCRE;
output CONFIG_TEST_BYTEMASK_t  CONFIG_TEST_BYTEMASK;
output CONFIG_TEST_PATTERN_t  CONFIG_TEST_PATTERN;
output CONFIG_TEST_PATTERN_PARAM_t  CONFIG_TEST_PATTERN_PARAM;
output CONFIG_TEST_START_ADDR_t  CONFIG_TEST_START_ADDR;
output CONFIG_TEST_WR_BACK_ADDR_t  CONFIG_TEST_WR_BACK_ADDR;
output CXL_DEV_CAP_ARRAY_0_t  CXL_DEV_CAP_ARRAY_0;
output CXL_DEV_CAP_ARRAY_1_t  CXL_DEV_CAP_ARRAY_1;
output CXL_DEV_CAP_EVENT_STATUS_t  CXL_DEV_CAP_EVENT_STATUS;
output CXL_DEV_CAP_HDR1_0_t  CXL_DEV_CAP_HDR1_0;
output CXL_DEV_CAP_HDR1_1_t  CXL_DEV_CAP_HDR1_1;
output CXL_DEV_CAP_HDR1_2_t  CXL_DEV_CAP_HDR1_2;
output CXL_DEV_CAP_HDR2_0_t  CXL_DEV_CAP_HDR2_0;
output CXL_DEV_CAP_HDR2_1_t  CXL_DEV_CAP_HDR2_1;
output CXL_DEV_CAP_HDR2_2_t  CXL_DEV_CAP_HDR2_2;
output CXL_DEV_CAP_HDR3_0_t  CXL_DEV_CAP_HDR3_0;
output CXL_DEV_CAP_HDR3_1_t  CXL_DEV_CAP_HDR3_1;
output CXL_DEV_CAP_HDR3_2_t  CXL_DEV_CAP_HDR3_2;
output CXL_DVSEC_HEADER_1_t  CXL_DVSEC_HEADER_1;
output CXL_DVSEC_HEADER_2_t  CXL_DVSEC_HEADER_2;
output CXL_DVSEC_TEST_CAP1_t  CXL_DVSEC_TEST_CAP1;
output CXL_DVSEC_TEST_CAP2_t  CXL_DVSEC_TEST_CAP2;
output CXL_DVSEC_TEST_CNF_BASE_HIGH_t  CXL_DVSEC_TEST_CNF_BASE_HIGH;
output CXL_DVSEC_TEST_CNF_BASE_LOW_t  CXL_DVSEC_TEST_CNF_BASE_LOW;
output CXL_DVSEC_TEST_LOCK_t  CXL_DVSEC_TEST_LOCK;
output CXL_MB_BK_CMD_STATUS_t  CXL_MB_BK_CMD_STATUS;
output CXL_MB_CAP_t  CXL_MB_CAP;
output CXL_MB_CMD_t  CXL_MB_CMD;
output CXL_MB_CTRL_t  CXL_MB_CTRL;
output CXL_MB_PAY_END_t  CXL_MB_PAY_END;
output CXL_MB_PAY_START_t  CXL_MB_PAY_START;
output CXL_MB_STATUS_t  CXL_MB_STATUS;
output CXL_MEM_DEV_STATUS_t  CXL_MEM_DEV_STATUS;
output DEVICE_AFU_LATENCY_MODE_t  DEVICE_AFU_LATENCY_MODE;
output DEVICE_AFU_STATUS1_t  DEVICE_AFU_STATUS1;
output DEVICE_AFU_STATUS2_t  DEVICE_AFU_STATUS2;
output DEVICE_AXI2CPI_STATUS_1_t  DEVICE_AXI2CPI_STATUS_1;
output DEVICE_AXI2CPI_STATUS_2_t  DEVICE_AXI2CPI_STATUS_2;
output DEVICE_ERROR_INJECTION_t  DEVICE_ERROR_INJECTION;
output DEVICE_ERROR_LOG1_t  DEVICE_ERROR_LOG1;
output DEVICE_ERROR_LOG2_t  DEVICE_ERROR_LOG2;
output DEVICE_ERROR_LOG3_t  DEVICE_ERROR_LOG3;
output DEVICE_ERROR_LOG4_t  DEVICE_ERROR_LOG4;
output DEVICE_ERROR_LOG5_t  DEVICE_ERROR_LOG5;
output DEVICE_EVENT_COUNT_t  DEVICE_EVENT_COUNT;
output DEVICE_EVENT_CTRL_t  DEVICE_EVENT_CTRL;
output DEVICE_FORCE_DISABLE_t  DEVICE_FORCE_DISABLE;
output DEVMEM_DBECNT_t  DEVMEM_DBECNT;
output DEVMEM_POISONCNT_t  DEVMEM_POISONCNT;
output DEVMEM_SBECNT_t  DEVMEM_SBECNT;
output DOE_CAPREG_t  DOE_CAPREG;
output DOE_CTLREG_t  DOE_CTLREG;
output DOE_RDMAILREG_t  DOE_RDMAILREG;
output DOE_STSREG_t  DOE_STSREG;
output DOE_WRMAILREG_t  DOE_WRMAILREG;
output DSEMTS_0_t  DSEMTS_0;
output DSEMTS_1_t  DSEMTS_1;
output DSEMTS_2_t  DSEMTS_2;
output DSEMTS_3_t  DSEMTS_3;
output DSEMTS_4_t  DSEMTS_4;
output DSEMTS_5_t  DSEMTS_5;
output DSIS_0_t  DSIS_0;
output DSIS_1_t  DSIS_1;
output DSLBIS_0_t  DSLBIS_0;
output DSLBIS_1_t  DSLBIS_1;
output DSLBIS_2_t  DSLBIS_2;
output DSLBIS_3_t  DSLBIS_3;
output DSLBIS_4_t  DSLBIS_4;
output DSLBIS_5_t  DSLBIS_5;
output DSMAS_0_t  DSMAS_0;
output DSMAS_1_t  DSMAS_1;
output DSMAS_2_t  DSMAS_2;
output DSMAS_3_t  DSMAS_3;
output DSMAS_4_t  DSMAS_4;
output DSMAS_5_t  DSMAS_5;
output DVSEC_DEV_t  DVSEC_DEV;
output DVSEC_DOE_t  DVSEC_DOE;
output DVSEC_FBCAP_HDR2_t  DVSEC_FBCAP_HDR2;
output DVSEC_FBCTRL2_STATUS2_t  DVSEC_FBCTRL2_STATUS2;
output DVSEC_FBCTRL_STATUS_t  DVSEC_FBCTRL_STATUS;
output DVSEC_FBLOCK_t  DVSEC_FBLOCK;
output DVSEC_FBRANGE1HIGH_t  DVSEC_FBRANGE1HIGH;
output DVSEC_FBRANGE1LOW_t  DVSEC_FBRANGE1LOW;
output DVSEC_FBRANGE1SZHIGH_t  DVSEC_FBRANGE1SZHIGH;
output DVSEC_FBRANGE1SZLOW_t  DVSEC_FBRANGE1SZLOW;
output DVSEC_FBRANGE2HIGH_t  DVSEC_FBRANGE2HIGH;
output DVSEC_FBRANGE2LOW_t  DVSEC_FBRANGE2LOW;
output DVSEC_FBRANGE2SZHIGH_t  DVSEC_FBRANGE2SZHIGH;
output DVSEC_FBRANGE2SZLOW_t  DVSEC_FBRANGE2SZLOW;
output DVSEC_HDR1_t  DVSEC_HDR1;
output DVSEC_TEST_CAP_t  DVSEC_TEST_CAP;
output HDM_DEC_BASEHIGH_t  HDM_DEC_BASEHIGH;
output HDM_DEC_BASELOW_t  HDM_DEC_BASELOW;
output HDM_DEC_CAP_t  HDM_DEC_CAP;
output HDM_DEC_CTRL_t  HDM_DEC_CTRL;
output HDM_DEC_DPAHIGH_t  HDM_DEC_DPAHIGH;
output HDM_DEC_DPALOW_t  HDM_DEC_DPALOW;
output HDM_DEC_GBL_CTRL_t  HDM_DEC_GBL_CTRL;
output HDM_DEC_SIZEHIGH_t  HDM_DEC_SIZEHIGH;
output HDM_DEC_SIZELOW_t  HDM_DEC_SIZELOW;
output MBOX_EVENTINJ_t  MBOX_EVENTINJ;
output MC_STATUS_t  MC_STATUS;


    // Register signals for HandCoded registers





    // Config Access
input cafu_csr0_cfg_cr_req_t  req;
output cafu_csr0_cfg_cr_ack_t  ack;
    

// ======================================================================
// begin decode and addr logic section {


function automatic logic f_IsCFGRd (
    input logic [3:0] req_opcode
);
    f_IsCFGRd = (req_opcode == CFGRD); 
endfunction : f_IsCFGRd

function automatic logic f_IsCFGWr (
    input logic [3:0] req_opcode
);
    f_IsCFGWr = (req_opcode == CFGWR); 
endfunction : f_IsCFGWr

function automatic logic [CR_REQ_ADDR_HI:0] f_CFGAddr (
    input cafu_csr0_cfg_cr_req_t req
);
begin
    f_CFGAddr[CR_REQ_ADDR_HI:0] = 48'h0;
    f_CFGAddr[CR_CFG_ADDR_HI:0] = 
       req.addr.cfg.offset[CR_CFG_ADDR_HI:0];
end
endfunction : f_CFGAddr


function automatic logic f_IsMEMRd (
    input logic [3:0] req_opcode
);
    f_IsMEMRd = (req_opcode == MRD); 
endfunction : f_IsMEMRd

function automatic logic f_IsMEMWr (
    input logic [3:0] req_opcode
);
    f_IsMEMWr = (req_opcode == MWR); 
endfunction : f_IsMEMWr

function automatic logic [CR_REQ_ADDR_HI:0] f_MEMAddr (
    input cafu_csr0_cfg_cr_req_t req
);
begin
    f_MEMAddr[CR_REQ_ADDR_HI:0] = 48'h0;
    f_MEMAddr[CR_MEM_ADDR_HI:0] = 
       req.addr.mem.offset[CR_MEM_ADDR_HI:0];
end
endfunction : f_MEMAddr


function automatic logic f_IsRdOpCode (
    input logic [3:0] req_opcode
);
    f_IsRdOpCode = (!req_opcode[0]); 
endfunction : f_IsRdOpCode

function automatic logic f_IsWrOpCode (
    input logic [3:0] req_opcode
);
    f_IsWrOpCode = (req_opcode[0]); 
endfunction : f_IsWrOpCode

// Shared registers definitions





logic [3:0] req_opcode;
always_comb req_opcode = {1'b0, req.opcode[2:0]};

logic req_valid;
assign req_valid = req.valid;

logic [7:0] req_fid;
assign req_fid = req.fid;
logic [2:0] req_bar;
assign req_bar = req.bar;


logic IsWrOpcode;
logic IsRdOpcode;
assign IsWrOpcode = f_IsWrOpCode(req_opcode);
assign IsRdOpcode = f_IsRdOpCode(req_opcode);

logic IsCFGRd;
logic IsCFGWr;
assign IsCFGRd = f_IsCFGRd(req_opcode);
assign IsCFGWr = f_IsCFGWr(req_opcode);

logic IsMEMRd;
logic IsMEMWr;
assign IsMEMRd = f_IsMEMRd(req_opcode);
assign IsMEMWr = f_IsMEMWr(req_opcode);


logic [47:0] req_addr;
always_comb begin : REQ_ADDR_BLOCK
    unique casez (req_opcode) 
        CFGRD: begin 
            req_addr = f_CFGAddr(req);
        end 
        CFGWR: begin
            req_addr = f_CFGAddr(req);
        end 
        MRD: begin 
            req_addr = f_MEMAddr(req);
        end 
        MWR: begin
            req_addr = f_MEMAddr(req);
        end 
        default: begin
           req_addr = 48'h0;
        end
    endcase 
end

logic [CAFU_CSR0_CFG_CFG_ADDR_MSB-ADDR_LSB_BUS_ALIGN:0] case_req_addr_CAFU_CSR0_CFG_CFG;
assign case_req_addr_CAFU_CSR0_CFG_CFG = req_addr[CAFU_CSR0_CFG_CFG_ADDR_MSB:ADDR_LSB_BUS_ALIGN];
logic [CAFU_CSR0_CFG_MEM_ADDR_MSB-ADDR_LSB_BUS_ALIGN:0] case_req_addr_CAFU_CSR0_CFG_MEM;
assign case_req_addr_CAFU_CSR0_CFG_MEM = req_addr[CAFU_CSR0_CFG_MEM_ADDR_MSB:ADDR_LSB_BUS_ALIGN];
logic high_dword;
always_comb high_dword = req_addr[2];
logic [7:0] be;
always_comb begin 
    unique casez (high_dword) 
        0: be = {8{req.valid}} & req.be;
        1: be = {8{req.valid}} & {req.be[3:0],4'h0};
        // default are needed to reduce compiler warnings. 
        default: be = {8{req.valid}} & req.be; 
    endcase
end
logic [7:0] sai_successfull_per_byte;
logic [63:0] read_data;
logic [63:0] write_data;



logic sb_fid_cond_cfg_inst_sb;
always_comb begin : sb_fid_cond_cfg_inst_sb_BLOCK
    unique casez (req_fid) 
		CFG_INST_SB_SB_FID: sb_fid_cond_cfg_inst_sb = 1;
		default: sb_fid_cond_cfg_inst_sb = 0;
    endcase 
end


logic sb_fid_cond_mem_inst_sb;
always_comb begin : sb_fid_cond_mem_inst_sb_BLOCK
    unique casez (req_fid) 
		MEM_INST_SB_SB_FID: sb_fid_cond_mem_inst_sb = 1;
		default: sb_fid_cond_mem_inst_sb = 0;
    endcase 
end


logic sb_bar_cond_mem_inst_sb;
always_comb begin : sb_bar_cond_mem_inst_sb_BLOCK
    unique casez (req_bar) 
		MEM_INST_SB_SB_BAR: sb_bar_cond_mem_inst_sb = 1;
		default: sb_bar_cond_mem_inst_sb = 0;
    endcase 
end


// ======================================================================
// begin register logic section {

//---------------------------------------------------------------------
// DVSEC_DEV Address Decode

// ----------------------------------------------------------------------
// DVSEC_DEV.dvsec_cap_id x8 RO, using RO template.
assign DVSEC_DEV.dvsec_cap_id = 16'h23;



// ----------------------------------------------------------------------
// DVSEC_DEV.dvsec_cap_version x4 RO, using RO template.
assign DVSEC_DEV.dvsec_cap_version = 4'h1;



// ----------------------------------------------------------------------
// DVSEC_DEV.next_cap_offset x8 RO, using RO template.
assign DVSEC_DEV.next_cap_offset = 12'hF40;



//---------------------------------------------------------------------
// DVSEC_HDR1 Address Decode

// ----------------------------------------------------------------------
// DVSEC_HDR1.dvsec_vendor_id x8 RO, using RO template.
assign DVSEC_HDR1.dvsec_vendor_id = POR_DVSEC_HDR1_dvsec_vendor_id;



// ----------------------------------------------------------------------
// DVSEC_HDR1.dvsec_revision x4 RO, using RO template.
assign DVSEC_HDR1.dvsec_revision = POR_DVSEC_HDR1_dvsec_revision;



// ----------------------------------------------------------------------
// DVSEC_HDR1.dvsec_length x8 RO, using RO template.
assign DVSEC_HDR1.dvsec_length = 12'h38;



//---------------------------------------------------------------------
// DVSEC_FBCAP_HDR2 Address Decode

// ----------------------------------------------------------------------
// DVSEC_FBCAP_HDR2.dvsec_id x8 RO, using RO template.
assign DVSEC_FBCAP_HDR2.dvsec_id = 16'h0;



// ----------------------------------------------------------------------
// DVSEC_FBCAP_HDR2.cache_capable x1 RO, using RO template.
assign DVSEC_FBCAP_HDR2.cache_capable = POR_DVSEC_FBCAP_HDR2_cache_capable;



// ----------------------------------------------------------------------
// DVSEC_FBCAP_HDR2.io_capable x1 RO, using RO template.
assign DVSEC_FBCAP_HDR2.io_capable = 1'h1;



// ----------------------------------------------------------------------
// DVSEC_FBCAP_HDR2.mem_capable x1 RO, using RO template.
assign DVSEC_FBCAP_HDR2.mem_capable = POR_DVSEC_FBCAP_HDR2_mem_capable;



// ----------------------------------------------------------------------
// DVSEC_FBCAP_HDR2.mem_hwInit_mode x1 RO, using RO template.
assign DVSEC_FBCAP_HDR2.mem_hwInit_mode = POR_DVSEC_FBCAP_HDR2_mem_hwinit_mode;



// ----------------------------------------------------------------------
// DVSEC_FBCAP_HDR2.hdm_count x2 RO, using RO template.
assign DVSEC_FBCAP_HDR2.hdm_count = POR_DVSEC_FBCAP_HDR2_hdm_count;



// ----------------------------------------------------------------------
// DVSEC_FBCAP_HDR2.cache_wb_and_inv_capable x1 RO, using RO template.
assign DVSEC_FBCAP_HDR2.cache_wb_and_inv_capable = POR_DVSEC_FBCAP_HDR2_cache_wb_and_inv_capable;



// ----------------------------------------------------------------------
// DVSEC_FBCAP_HDR2.cxl_reset_capable x1 RO, using RO template.
assign DVSEC_FBCAP_HDR2.cxl_reset_capable = POR_DVSEC_FBCAP_HDR2_cxl_reset_capable;



// ----------------------------------------------------------------------
// DVSEC_FBCAP_HDR2.cxl_reset_timeout x3 RO, using RO template.
assign DVSEC_FBCAP_HDR2.cxl_reset_timeout = POR_DVSEC_FBCAP_HDR2_cxl_reset_timeout;



// ----------------------------------------------------------------------
// DVSEC_FBCAP_HDR2.cxl_reset_mem_clr_capable x1 RO, using RO template.
assign DVSEC_FBCAP_HDR2.cxl_reset_mem_clr_capable = POR_DVSEC_FBCAP_HDR2_cxl_reset_mem_clr_capable;



// ----------------------------------------------------------------------
// DVSEC_FBCAP_HDR2.mld x1 RO, using RO template.
assign DVSEC_FBCAP_HDR2.mld = 1'h0;



// ----------------------------------------------------------------------
// DVSEC_FBCAP_HDR2.viral_capable x1 RO, using RO template.
assign DVSEC_FBCAP_HDR2.viral_capable = 1'h1;



// ----------------------------------------------------------------------
// DVSEC_FBCAP_HDR2.pm_init_comp_capable x1 RO, using RO template.
assign DVSEC_FBCAP_HDR2.pm_init_comp_capable = POR_DVSEC_FBCAP_HDR2_pm_init_comp_capable;



//---------------------------------------------------------------------
// DVSEC_FBCTRL_STATUS Address Decode
logic  addr_decode_DVSEC_FBCTRL_STATUS;
logic  write_req_DVSEC_FBCTRL_STATUS;
always_comb begin
   addr_decode_DVSEC_FBCTRL_STATUS = (req_addr[CAFU_CSR0_CFG_CFG_ADDR_MSB:ADDR_LSB_BUS_ALIGN] == DVSEC_FBCTRL_STATUS_DECODE_ADDR) && req.valid ;
   write_req_DVSEC_FBCTRL_STATUS = IsCFGWr && addr_decode_DVSEC_FBCTRL_STATUS && sb_fid_cond_cfg_inst_sb;
end

// ----------------------------------------------------------------------
// DVSEC_FBCTRL_STATUS.cache_enable x1 RW/L, using RW/L template.
logic [0:0] req_up_DVSEC_FBCTRL_STATUS_cache_enable;
always_comb begin
 req_up_DVSEC_FBCTRL_STATUS_cache_enable[0] = 
   {write_req_DVSEC_FBCTRL_STATUS & be[4]}
;
end

logic  lock_lcl_DVSEC_FBCTRL_STATUS_cache_enable;
always_comb begin
 lock_lcl_DVSEC_FBCTRL_STATUS_cache_enable = ((DVSEC_FBLOCK.config_lock == 1'h1));
end

logic [0:0] up_DVSEC_FBCTRL_STATUS_cache_enable;
always_comb begin
 up_DVSEC_FBCTRL_STATUS_cache_enable = 
   (req_up_DVSEC_FBCTRL_STATUS_cache_enable & {1{~lock_lcl_DVSEC_FBCTRL_STATUS_cache_enable}});

end


logic [0:0] nxt_DVSEC_FBCTRL_STATUS_cache_enable;
always_comb begin
 nxt_DVSEC_FBCTRL_STATUS_cache_enable = write_data[32:32];

end
`RTLGEN_CAFU_CSR0_CFG_EN_FF(gated_clk, rst_n, 1'h0, up_DVSEC_FBCTRL_STATUS_cache_enable[0], nxt_DVSEC_FBCTRL_STATUS_cache_enable[0:0], DVSEC_FBCTRL_STATUS.cache_enable[0:0])

// ----------------------------------------------------------------------
// DVSEC_FBCTRL_STATUS.io_enable x1 RO, using RO template.
assign DVSEC_FBCTRL_STATUS.io_enable = 1'h1;



// ----------------------------------------------------------------------
// DVSEC_FBCTRL_STATUS.mem_enable x1 RW/L, using RW/L template.
logic [0:0] req_up_DVSEC_FBCTRL_STATUS_mem_enable;
always_comb begin
 req_up_DVSEC_FBCTRL_STATUS_mem_enable[0] = 
   {write_req_DVSEC_FBCTRL_STATUS & be[4]}
;
end

logic  lock_lcl_DVSEC_FBCTRL_STATUS_mem_enable;
always_comb begin
 lock_lcl_DVSEC_FBCTRL_STATUS_mem_enable = ((DVSEC_FBLOCK.config_lock == 1'h1));
end

logic [0:0] up_DVSEC_FBCTRL_STATUS_mem_enable;
always_comb begin
 up_DVSEC_FBCTRL_STATUS_mem_enable = 
   (req_up_DVSEC_FBCTRL_STATUS_mem_enable & {1{~lock_lcl_DVSEC_FBCTRL_STATUS_mem_enable}});

end


logic [0:0] nxt_DVSEC_FBCTRL_STATUS_mem_enable;
always_comb begin
 nxt_DVSEC_FBCTRL_STATUS_mem_enable = write_data[34:34];

end
`RTLGEN_CAFU_CSR0_CFG_EN_FF(gated_clk, rst_n, 1'h0, up_DVSEC_FBCTRL_STATUS_mem_enable[0], nxt_DVSEC_FBCTRL_STATUS_mem_enable[0:0], DVSEC_FBCTRL_STATUS.mem_enable[0:0])

// ----------------------------------------------------------------------
// DVSEC_FBCTRL_STATUS.cache_sf_coverage x5 RW/L, using RW/L template.
logic [0:0] req_up_DVSEC_FBCTRL_STATUS_cache_sf_coverage;
always_comb begin
 req_up_DVSEC_FBCTRL_STATUS_cache_sf_coverage[0] = 
   {write_req_DVSEC_FBCTRL_STATUS & be[4]}
;
end

logic  lock_lcl_DVSEC_FBCTRL_STATUS_cache_sf_coverage;
always_comb begin
 lock_lcl_DVSEC_FBCTRL_STATUS_cache_sf_coverage = ((DVSEC_FBLOCK.config_lock == 1'h1));
end

logic [0:0] up_DVSEC_FBCTRL_STATUS_cache_sf_coverage;
always_comb begin
 up_DVSEC_FBCTRL_STATUS_cache_sf_coverage = 
   (req_up_DVSEC_FBCTRL_STATUS_cache_sf_coverage & {1{~lock_lcl_DVSEC_FBCTRL_STATUS_cache_sf_coverage}});

end


logic [4:0] nxt_DVSEC_FBCTRL_STATUS_cache_sf_coverage;
always_comb begin
 nxt_DVSEC_FBCTRL_STATUS_cache_sf_coverage = write_data[39:35];

end
`RTLGEN_CAFU_CSR0_CFG_EN_FF(gated_clk, rst_n, 5'h0, up_DVSEC_FBCTRL_STATUS_cache_sf_coverage[0], nxt_DVSEC_FBCTRL_STATUS_cache_sf_coverage[4:0], DVSEC_FBCTRL_STATUS.cache_sf_coverage[4:0])

// ----------------------------------------------------------------------
// DVSEC_FBCTRL_STATUS.cache_sf_granularity x3 RW/L, using RW/L template.
logic [0:0] req_up_DVSEC_FBCTRL_STATUS_cache_sf_granularity;
always_comb begin
 req_up_DVSEC_FBCTRL_STATUS_cache_sf_granularity[0] = 
   {write_req_DVSEC_FBCTRL_STATUS & be[5]}
;
end

logic  lock_lcl_DVSEC_FBCTRL_STATUS_cache_sf_granularity;
always_comb begin
 lock_lcl_DVSEC_FBCTRL_STATUS_cache_sf_granularity = ((DVSEC_FBLOCK.config_lock == 1'h1));
end

logic [0:0] up_DVSEC_FBCTRL_STATUS_cache_sf_granularity;
always_comb begin
 up_DVSEC_FBCTRL_STATUS_cache_sf_granularity = 
   (req_up_DVSEC_FBCTRL_STATUS_cache_sf_granularity & {1{~lock_lcl_DVSEC_FBCTRL_STATUS_cache_sf_granularity}});

end


logic [2:0] nxt_DVSEC_FBCTRL_STATUS_cache_sf_granularity;
always_comb begin
 nxt_DVSEC_FBCTRL_STATUS_cache_sf_granularity = write_data[42:40];

end
`RTLGEN_CAFU_CSR0_CFG_EN_FF(gated_clk, rst_n, 3'h0, up_DVSEC_FBCTRL_STATUS_cache_sf_granularity[0], nxt_DVSEC_FBCTRL_STATUS_cache_sf_granularity[2:0], DVSEC_FBCTRL_STATUS.cache_sf_granularity[2:0])

// ----------------------------------------------------------------------
// DVSEC_FBCTRL_STATUS.cache_clean_eviction x1 RW/L, using RW/L template.
logic [0:0] req_up_DVSEC_FBCTRL_STATUS_cache_clean_eviction;
always_comb begin
 req_up_DVSEC_FBCTRL_STATUS_cache_clean_eviction[0] = 
   {write_req_DVSEC_FBCTRL_STATUS & be[5]}
;
end

logic  lock_lcl_DVSEC_FBCTRL_STATUS_cache_clean_eviction;
always_comb begin
 lock_lcl_DVSEC_FBCTRL_STATUS_cache_clean_eviction = ((DVSEC_FBLOCK.config_lock == 1'h1));
end

logic [0:0] up_DVSEC_FBCTRL_STATUS_cache_clean_eviction;
always_comb begin
 up_DVSEC_FBCTRL_STATUS_cache_clean_eviction = 
   (req_up_DVSEC_FBCTRL_STATUS_cache_clean_eviction & {1{~lock_lcl_DVSEC_FBCTRL_STATUS_cache_clean_eviction}});

end


logic [0:0] nxt_DVSEC_FBCTRL_STATUS_cache_clean_eviction;
always_comb begin
 nxt_DVSEC_FBCTRL_STATUS_cache_clean_eviction = write_data[43:43];

end
`RTLGEN_CAFU_CSR0_CFG_EN_FF(gated_clk, rst_n, 1'h0, up_DVSEC_FBCTRL_STATUS_cache_clean_eviction[0], nxt_DVSEC_FBCTRL_STATUS_cache_clean_eviction[0:0], DVSEC_FBCTRL_STATUS.cache_clean_eviction[0:0])

// ----------------------------------------------------------------------
// DVSEC_FBCTRL_STATUS.viral_enable x1 RW/L, using RW/L template.
logic [0:0] req_up_DVSEC_FBCTRL_STATUS_viral_enable;
always_comb begin
 req_up_DVSEC_FBCTRL_STATUS_viral_enable[0] = 
   {write_req_DVSEC_FBCTRL_STATUS & be[5]}
;
end

logic  lock_lcl_DVSEC_FBCTRL_STATUS_viral_enable;
always_comb begin
 lock_lcl_DVSEC_FBCTRL_STATUS_viral_enable = ((DVSEC_FBLOCK.config_lock == 1'h1));
end

logic [0:0] up_DVSEC_FBCTRL_STATUS_viral_enable;
always_comb begin
 up_DVSEC_FBCTRL_STATUS_viral_enable = 
   (req_up_DVSEC_FBCTRL_STATUS_viral_enable & {1{~lock_lcl_DVSEC_FBCTRL_STATUS_viral_enable}});

end


logic [0:0] nxt_DVSEC_FBCTRL_STATUS_viral_enable;
always_comb begin
 nxt_DVSEC_FBCTRL_STATUS_viral_enable = write_data[46:46];

end
`RTLGEN_CAFU_CSR0_CFG_EN_FF(gated_clk, rst_n, 1'h0, up_DVSEC_FBCTRL_STATUS_viral_enable[0], nxt_DVSEC_FBCTRL_STATUS_viral_enable[0:0], DVSEC_FBCTRL_STATUS.viral_enable[0:0])

// ----------------------------------------------------------------------
// DVSEC_FBCTRL_STATUS.viral_status x1 RW/1C/V/P, using RW/1C/V/P template.
// clear the each bit when writing a 1
logic [0:0] req_up_DVSEC_FBCTRL_STATUS_viral_status;
always_comb begin
 req_up_DVSEC_FBCTRL_STATUS_viral_status[0:0] = 
   {1{write_req_DVSEC_FBCTRL_STATUS & be[7]}}
;
end

logic [0:0] clr_DVSEC_FBCTRL_STATUS_viral_status;
always_comb begin
 clr_DVSEC_FBCTRL_STATUS_viral_status = write_data[62:62] & req_up_DVSEC_FBCTRL_STATUS_viral_status;

end
logic [0:0] swwr_DVSEC_FBCTRL_STATUS_viral_status;
logic [0:0] sw_nxt_DVSEC_FBCTRL_STATUS_viral_status;
always_comb begin
 swwr_DVSEC_FBCTRL_STATUS_viral_status = clr_DVSEC_FBCTRL_STATUS_viral_status;
 sw_nxt_DVSEC_FBCTRL_STATUS_viral_status = {1{1'b0}};

end
logic [0:0] up_DVSEC_FBCTRL_STATUS_viral_status;
logic [0:0] nxt_DVSEC_FBCTRL_STATUS_viral_status;
always_comb begin
 up_DVSEC_FBCTRL_STATUS_viral_status = 
   swwr_DVSEC_FBCTRL_STATUS_viral_status | {1{load_DVSEC_FBCTRL_STATUS.viral_status}};
end
always_comb begin
 nxt_DVSEC_FBCTRL_STATUS_viral_status[0] = 
    load_DVSEC_FBCTRL_STATUS.viral_status ?
    new_DVSEC_FBCTRL_STATUS.viral_status[0] :
    sw_nxt_DVSEC_FBCTRL_STATUS_viral_status[0];
end



`RTLGEN_CAFU_CSR0_CFG_EN_FF(rtl_clk, pwr_rst_n, 1'h0, up_DVSEC_FBCTRL_STATUS_viral_status[0], nxt_DVSEC_FBCTRL_STATUS_viral_status[0], DVSEC_FBCTRL_STATUS.viral_status[0])

//---------------------------------------------------------------------
// DVSEC_FBCTRL2_STATUS2 Address Decode
logic  addr_decode_DVSEC_FBCTRL2_STATUS2;
logic  write_req_DVSEC_FBCTRL2_STATUS2;
always_comb begin
   addr_decode_DVSEC_FBCTRL2_STATUS2 = (req_addr[CAFU_CSR0_CFG_CFG_ADDR_MSB:ADDR_LSB_BUS_ALIGN] == DVSEC_FBCTRL2_STATUS2_DECODE_ADDR) && req.valid ;
   write_req_DVSEC_FBCTRL2_STATUS2 = IsCFGWr && addr_decode_DVSEC_FBCTRL2_STATUS2 && sb_fid_cond_cfg_inst_sb;
end

// ----------------------------------------------------------------------
// DVSEC_FBCTRL2_STATUS2.disable_caching x1 RW, using RW template.
logic [0:0] up_DVSEC_FBCTRL2_STATUS2_disable_caching;
always_comb begin
 up_DVSEC_FBCTRL2_STATUS2_disable_caching =
    ({1{write_req_DVSEC_FBCTRL2_STATUS2 }} &
    be[0:0]);
end

logic [0:0] nxt_DVSEC_FBCTRL2_STATUS2_disable_caching;
always_comb begin
 nxt_DVSEC_FBCTRL2_STATUS2_disable_caching = write_data[0:0];

end


`RTLGEN_CAFU_CSR0_CFG_EN_FF_SYNCRST(gated_clk, cxl_or_conv_rst_n, 1'h0, up_DVSEC_FBCTRL2_STATUS2_disable_caching[0], nxt_DVSEC_FBCTRL2_STATUS2_disable_caching[0:0], DVSEC_FBCTRL2_STATUS2.disable_caching[0:0])

// ----------------------------------------------------------------------
// DVSEC_FBCTRL2_STATUS2.initiate_cache_wb_and_inv x1 RW/1S/V, using RW/1S/V template.
logic [0:0] req_up_DVSEC_FBCTRL2_STATUS2_initiate_cache_wb_and_inv;
always_comb begin
 req_up_DVSEC_FBCTRL2_STATUS2_initiate_cache_wb_and_inv[0:0] = 
   {1{write_req_DVSEC_FBCTRL2_STATUS2 & be[0]}}
;
end

logic [0:0] set_DVSEC_FBCTRL2_STATUS2_initiate_cache_wb_and_inv;
always_comb begin
 set_DVSEC_FBCTRL2_STATUS2_initiate_cache_wb_and_inv = write_data[1:1] & req_up_DVSEC_FBCTRL2_STATUS2_initiate_cache_wb_and_inv;

end
logic [0:0] swwr_DVSEC_FBCTRL2_STATUS2_initiate_cache_wb_and_inv;
logic [0:0] sw_nxt_DVSEC_FBCTRL2_STATUS2_initiate_cache_wb_and_inv;
always_comb begin
 swwr_DVSEC_FBCTRL2_STATUS2_initiate_cache_wb_and_inv = set_DVSEC_FBCTRL2_STATUS2_initiate_cache_wb_and_inv;
 sw_nxt_DVSEC_FBCTRL2_STATUS2_initiate_cache_wb_and_inv = {1{1'b1}};

end
logic [0:0] up_DVSEC_FBCTRL2_STATUS2_initiate_cache_wb_and_inv;
logic [0:0] nxt_DVSEC_FBCTRL2_STATUS2_initiate_cache_wb_and_inv;
always_comb begin
 up_DVSEC_FBCTRL2_STATUS2_initiate_cache_wb_and_inv = 
   swwr_DVSEC_FBCTRL2_STATUS2_initiate_cache_wb_and_inv | {1{load_DVSEC_FBCTRL2_STATUS2.initiate_cache_wb_and_inv}};
end
always_comb begin
 nxt_DVSEC_FBCTRL2_STATUS2_initiate_cache_wb_and_inv[0] = 
    load_DVSEC_FBCTRL2_STATUS2.initiate_cache_wb_and_inv ?
    new_DVSEC_FBCTRL2_STATUS2.initiate_cache_wb_and_inv[0] :
    sw_nxt_DVSEC_FBCTRL2_STATUS2_initiate_cache_wb_and_inv[0];
end



`RTLGEN_CAFU_CSR0_CFG_EN_FF(rtl_clk, rst_n, 1'h0, up_DVSEC_FBCTRL2_STATUS2_initiate_cache_wb_and_inv[0], nxt_DVSEC_FBCTRL2_STATUS2_initiate_cache_wb_and_inv[0], DVSEC_FBCTRL2_STATUS2.initiate_cache_wb_and_inv[0])

// ----------------------------------------------------------------------
// DVSEC_FBCTRL2_STATUS2.initiate_cxl_reset x1 RW/1S/V, using RW/1S/V template.
logic [0:0] req_up_DVSEC_FBCTRL2_STATUS2_initiate_cxl_reset;
always_comb begin
 req_up_DVSEC_FBCTRL2_STATUS2_initiate_cxl_reset[0:0] = 
   {1{write_req_DVSEC_FBCTRL2_STATUS2 & be[0]}}
;
end

logic [0:0] set_DVSEC_FBCTRL2_STATUS2_initiate_cxl_reset;
always_comb begin
 set_DVSEC_FBCTRL2_STATUS2_initiate_cxl_reset = write_data[2:2] & req_up_DVSEC_FBCTRL2_STATUS2_initiate_cxl_reset;

end
logic [0:0] swwr_DVSEC_FBCTRL2_STATUS2_initiate_cxl_reset;
logic [0:0] sw_nxt_DVSEC_FBCTRL2_STATUS2_initiate_cxl_reset;
always_comb begin
 swwr_DVSEC_FBCTRL2_STATUS2_initiate_cxl_reset = set_DVSEC_FBCTRL2_STATUS2_initiate_cxl_reset;
 sw_nxt_DVSEC_FBCTRL2_STATUS2_initiate_cxl_reset = {1{1'b1}};

end
logic [0:0] up_DVSEC_FBCTRL2_STATUS2_initiate_cxl_reset;
logic [0:0] nxt_DVSEC_FBCTRL2_STATUS2_initiate_cxl_reset;
always_comb begin
 up_DVSEC_FBCTRL2_STATUS2_initiate_cxl_reset = 
   swwr_DVSEC_FBCTRL2_STATUS2_initiate_cxl_reset | {1{load_DVSEC_FBCTRL2_STATUS2.initiate_cxl_reset}};
end
always_comb begin
 nxt_DVSEC_FBCTRL2_STATUS2_initiate_cxl_reset[0] = 
    load_DVSEC_FBCTRL2_STATUS2.initiate_cxl_reset ?
    new_DVSEC_FBCTRL2_STATUS2.initiate_cxl_reset[0] :
    sw_nxt_DVSEC_FBCTRL2_STATUS2_initiate_cxl_reset[0];
end



`RTLGEN_CAFU_CSR0_CFG_EN_FF(rtl_clk, rst_n, 1'h0, up_DVSEC_FBCTRL2_STATUS2_initiate_cxl_reset[0], nxt_DVSEC_FBCTRL2_STATUS2_initiate_cxl_reset[0], DVSEC_FBCTRL2_STATUS2.initiate_cxl_reset[0])

// ----------------------------------------------------------------------
// DVSEC_FBCTRL2_STATUS2.cxl_reset_mem_clr_enable x1 RW, using RW template.
logic [0:0] up_DVSEC_FBCTRL2_STATUS2_cxl_reset_mem_clr_enable;
always_comb begin
 up_DVSEC_FBCTRL2_STATUS2_cxl_reset_mem_clr_enable =
    ({1{write_req_DVSEC_FBCTRL2_STATUS2 }} &
    be[0:0]);
end

logic [0:0] nxt_DVSEC_FBCTRL2_STATUS2_cxl_reset_mem_clr_enable;
always_comb begin
 nxt_DVSEC_FBCTRL2_STATUS2_cxl_reset_mem_clr_enable = write_data[3:3];

end


`RTLGEN_CAFU_CSR0_CFG_EN_FF_SYNCRST(gated_clk, cxl_or_conv_rst_n, 1'h0, up_DVSEC_FBCTRL2_STATUS2_cxl_reset_mem_clr_enable[0], nxt_DVSEC_FBCTRL2_STATUS2_cxl_reset_mem_clr_enable[0:0], DVSEC_FBCTRL2_STATUS2.cxl_reset_mem_clr_enable[0:0])
// ----------------------------------------------------------------------
// DVSEC_FBCTRL2_STATUS2.cache_invalid x1 RO/V, using RO/V template.
assign DVSEC_FBCTRL2_STATUS2.cache_invalid = new_DVSEC_FBCTRL2_STATUS2.cache_invalid;



// ----------------------------------------------------------------------
// DVSEC_FBCTRL2_STATUS2.cxl_reset_complete x1 RO/V, using RO/V template.
assign DVSEC_FBCTRL2_STATUS2.cxl_reset_complete = new_DVSEC_FBCTRL2_STATUS2.cxl_reset_complete;



// ----------------------------------------------------------------------
// DVSEC_FBCTRL2_STATUS2.cxl_reset_error x1 RO/V, using RO/V template.
assign DVSEC_FBCTRL2_STATUS2.cxl_reset_error = new_DVSEC_FBCTRL2_STATUS2.cxl_reset_error;



// ----------------------------------------------------------------------
// DVSEC_FBCTRL2_STATUS2.power_mgt_init_complete x1 RO/V, using RO/V template.
assign DVSEC_FBCTRL2_STATUS2.power_mgt_init_complete = new_DVSEC_FBCTRL2_STATUS2.power_mgt_init_complete;




//---------------------------------------------------------------------
// DVSEC_FBLOCK Address Decode
logic  addr_decode_DVSEC_FBLOCK;
logic  write_req_DVSEC_FBLOCK;
always_comb begin
   addr_decode_DVSEC_FBLOCK = (req_addr[CAFU_CSR0_CFG_CFG_ADDR_MSB:ADDR_LSB_BUS_ALIGN] == DVSEC_FBLOCK_DECODE_ADDR) && req.valid ;
   write_req_DVSEC_FBLOCK = IsCFGWr && addr_decode_DVSEC_FBLOCK && sb_fid_cond_cfg_inst_sb;
end

// ----------------------------------------------------------------------
// DVSEC_FBLOCK.config_lock x1 RW/L, using RW/L template.
logic [0:0] req_up_DVSEC_FBLOCK_config_lock;
always_comb begin
 req_up_DVSEC_FBLOCK_config_lock[0] = 
   {write_req_DVSEC_FBLOCK & be[4]}
;
end

logic  lock_lcl_DVSEC_FBLOCK_config_lock;
always_comb begin
 lock_lcl_DVSEC_FBLOCK_config_lock = ((DVSEC_FBLOCK.config_lock == 1'h1));
end

logic [0:0] up_DVSEC_FBLOCK_config_lock;
always_comb begin
 up_DVSEC_FBLOCK_config_lock = 
   (req_up_DVSEC_FBLOCK_config_lock & {1{~lock_lcl_DVSEC_FBLOCK_config_lock}});

end


logic [0:0] nxt_DVSEC_FBLOCK_config_lock;
always_comb begin
 nxt_DVSEC_FBLOCK_config_lock = write_data[32:32];

end
`RTLGEN_CAFU_CSR0_CFG_EN_FF(gated_clk, rst_n, 1'h0, up_DVSEC_FBLOCK_config_lock[0], nxt_DVSEC_FBLOCK_config_lock[0:0], DVSEC_FBLOCK.config_lock[0:0])

// ----------------------------------------------------------------------
// DVSEC_FBLOCK.cache_size_unit x4 RO, using RO template.
assign DVSEC_FBLOCK.cache_size_unit = POR_DVSEC_FBLOCK_cache_size_unit;



// ----------------------------------------------------------------------
// DVSEC_FBLOCK.cache_size x8 RO, using RO template.
assign DVSEC_FBLOCK.cache_size = POR_DVSEC_FBLOCK_cache_size;



//---------------------------------------------------------------------
// DVSEC_FBRANGE1SZHIGH Address Decode

// ----------------------------------------------------------------------
// DVSEC_FBRANGE1SZHIGH.memory_size x8 RO, using RO template.
assign DVSEC_FBRANGE1SZHIGH.memory_size = POR_DVSEC_FBRANGE1SZHIGH_memory_size;



//---------------------------------------------------------------------
// DVSEC_FBRANGE1SZLOW Address Decode

// ----------------------------------------------------------------------
// DVSEC_FBRANGE1SZLOW.mem_valid x1 RO, using RO template.
assign DVSEC_FBRANGE1SZLOW.mem_valid = POR_DVSEC_FBRANGE1SZLOW_mem_valid;



// ----------------------------------------------------------------------
// DVSEC_FBRANGE1SZLOW.mem_active x1 RO, using RO template.
assign DVSEC_FBRANGE1SZLOW.mem_active = POR_DVSEC_FBRANGE1SZLOW_mem_active;



// ----------------------------------------------------------------------
// DVSEC_FBRANGE1SZLOW.media_type x3 RO, using RO template.
assign DVSEC_FBRANGE1SZLOW.media_type = POR_DVSEC_FBRANGE1SZLOW_media_type;



// ----------------------------------------------------------------------
// DVSEC_FBRANGE1SZLOW.memory_class x3 RO, using RO template.
assign DVSEC_FBRANGE1SZLOW.memory_class = POR_DVSEC_FBRANGE1SZLOW_memory_class;



// ----------------------------------------------------------------------
// DVSEC_FBRANGE1SZLOW.desired_interleave x3 RO, using RO template.
assign DVSEC_FBRANGE1SZLOW.desired_interleave = POR_DVSEC_FBRANGE1SZLOW_desired_interleave;



// ----------------------------------------------------------------------
// DVSEC_FBRANGE1SZLOW.memory_active_timeout x3 RO, using RO template.
assign DVSEC_FBRANGE1SZLOW.memory_active_timeout = POR_DVSEC_FBRANGE1SZLOW_memory_active_timeout;



// ----------------------------------------------------------------------
// DVSEC_FBRANGE1SZLOW.memory_size_low x4 RO, using RO template.
assign DVSEC_FBRANGE1SZLOW.memory_size_low = POR_DVSEC_FBRANGE1SZLOW_memory_size_low;



//---------------------------------------------------------------------
// DVSEC_FBRANGE1HIGH Address Decode
logic  addr_decode_DVSEC_FBRANGE1HIGH;
logic  write_req_DVSEC_FBRANGE1HIGH;
always_comb begin
   addr_decode_DVSEC_FBRANGE1HIGH = (req_addr[CAFU_CSR0_CFG_CFG_ADDR_MSB:ADDR_LSB_BUS_ALIGN] == DVSEC_FBRANGE1HIGH_DECODE_ADDR) && req.valid ;
   write_req_DVSEC_FBRANGE1HIGH = IsCFGWr && addr_decode_DVSEC_FBRANGE1HIGH && sb_fid_cond_cfg_inst_sb;
end

// ----------------------------------------------------------------------
// DVSEC_FBRANGE1HIGH.memory_base_high x8 RW/L, using RW/L template.
logic [3:0] req_up_DVSEC_FBRANGE1HIGH_memory_base_high;
always_comb begin
 req_up_DVSEC_FBRANGE1HIGH_memory_base_high[0] = 
   {write_req_DVSEC_FBRANGE1HIGH & be[0]}
;
 req_up_DVSEC_FBRANGE1HIGH_memory_base_high[1] = 
   {write_req_DVSEC_FBRANGE1HIGH & be[1]}
;
 req_up_DVSEC_FBRANGE1HIGH_memory_base_high[2] = 
   {write_req_DVSEC_FBRANGE1HIGH & be[2]}
;
 req_up_DVSEC_FBRANGE1HIGH_memory_base_high[3] = 
   {write_req_DVSEC_FBRANGE1HIGH & be[3]}
;
end

logic  lock_lcl_DVSEC_FBRANGE1HIGH_memory_base_high;
always_comb begin
 lock_lcl_DVSEC_FBRANGE1HIGH_memory_base_high = ((DVSEC_FBLOCK.config_lock == 1'h1));
end

logic [3:0] up_DVSEC_FBRANGE1HIGH_memory_base_high;
always_comb begin
 up_DVSEC_FBRANGE1HIGH_memory_base_high = 
   (req_up_DVSEC_FBRANGE1HIGH_memory_base_high & {4{~lock_lcl_DVSEC_FBRANGE1HIGH_memory_base_high}});

end


logic [31:0] nxt_DVSEC_FBRANGE1HIGH_memory_base_high;
always_comb begin
 nxt_DVSEC_FBRANGE1HIGH_memory_base_high = write_data[31:0];

end
`RTLGEN_CAFU_CSR0_CFG_EN_FF(gated_clk, rst_n, 8'h0, up_DVSEC_FBRANGE1HIGH_memory_base_high[0], nxt_DVSEC_FBRANGE1HIGH_memory_base_high[7:0], DVSEC_FBRANGE1HIGH.memory_base_high[7:0])
`RTLGEN_CAFU_CSR0_CFG_EN_FF(gated_clk, rst_n, 8'h0, up_DVSEC_FBRANGE1HIGH_memory_base_high[1], nxt_DVSEC_FBRANGE1HIGH_memory_base_high[15:8], DVSEC_FBRANGE1HIGH.memory_base_high[15:8])
`RTLGEN_CAFU_CSR0_CFG_EN_FF(gated_clk, rst_n, 8'h0, up_DVSEC_FBRANGE1HIGH_memory_base_high[2], nxt_DVSEC_FBRANGE1HIGH_memory_base_high[23:16], DVSEC_FBRANGE1HIGH.memory_base_high[23:16])
`RTLGEN_CAFU_CSR0_CFG_EN_FF(gated_clk, rst_n, 8'h0, up_DVSEC_FBRANGE1HIGH_memory_base_high[3], nxt_DVSEC_FBRANGE1HIGH_memory_base_high[31:24], DVSEC_FBRANGE1HIGH.memory_base_high[31:24])

//---------------------------------------------------------------------
// DVSEC_FBRANGE1LOW Address Decode
logic  addr_decode_DVSEC_FBRANGE1LOW;
logic  write_req_DVSEC_FBRANGE1LOW;
always_comb begin
   addr_decode_DVSEC_FBRANGE1LOW = (req_addr[CAFU_CSR0_CFG_CFG_ADDR_MSB:ADDR_LSB_BUS_ALIGN] == DVSEC_FBRANGE1LOW_DECODE_ADDR) && req.valid ;
   write_req_DVSEC_FBRANGE1LOW = IsCFGWr && addr_decode_DVSEC_FBRANGE1LOW && sb_fid_cond_cfg_inst_sb;
end

// ----------------------------------------------------------------------
// DVSEC_FBRANGE1LOW.memory_base_low x4 RW/L, using RW/L template.
logic [0:0] req_up_DVSEC_FBRANGE1LOW_memory_base_low;
always_comb begin
 req_up_DVSEC_FBRANGE1LOW_memory_base_low[0] = 
   {write_req_DVSEC_FBRANGE1LOW & be[7]}
;
end

logic  lock_lcl_DVSEC_FBRANGE1LOW_memory_base_low;
always_comb begin
 lock_lcl_DVSEC_FBRANGE1LOW_memory_base_low = ((DVSEC_FBLOCK.config_lock == 1'h1));
end

logic [0:0] up_DVSEC_FBRANGE1LOW_memory_base_low;
always_comb begin
 up_DVSEC_FBRANGE1LOW_memory_base_low = 
   (req_up_DVSEC_FBRANGE1LOW_memory_base_low & {1{~lock_lcl_DVSEC_FBRANGE1LOW_memory_base_low}});

end


logic [3:0] nxt_DVSEC_FBRANGE1LOW_memory_base_low;
always_comb begin
 nxt_DVSEC_FBRANGE1LOW_memory_base_low = write_data[63:60];

end
`RTLGEN_CAFU_CSR0_CFG_EN_FF(gated_clk, rst_n, 4'h0, up_DVSEC_FBRANGE1LOW_memory_base_low[0], nxt_DVSEC_FBRANGE1LOW_memory_base_low[3:0], DVSEC_FBRANGE1LOW.memory_base_low[3:0])

//---------------------------------------------------------------------
// DVSEC_FBRANGE2SZHIGH Address Decode

// ----------------------------------------------------------------------
// DVSEC_FBRANGE2SZHIGH.memory_size x8 RO, using RO template.
assign DVSEC_FBRANGE2SZHIGH.memory_size = 32'h0;



//---------------------------------------------------------------------
// DVSEC_FBRANGE2SZLOW Address Decode

// ----------------------------------------------------------------------
// DVSEC_FBRANGE2SZLOW.mem_valid x1 RO, using RO template.
assign DVSEC_FBRANGE2SZLOW.mem_valid = 1'h0;



// ----------------------------------------------------------------------
// DVSEC_FBRANGE2SZLOW.mem_active x1 RO, using RO template.
assign DVSEC_FBRANGE2SZLOW.mem_active = 1'h0;



// ----------------------------------------------------------------------
// DVSEC_FBRANGE2SZLOW.media_type x3 RO, using RO template.
assign DVSEC_FBRANGE2SZLOW.media_type = 3'h0;



// ----------------------------------------------------------------------
// DVSEC_FBRANGE2SZLOW.memory_class x3 RO, using RO template.
assign DVSEC_FBRANGE2SZLOW.memory_class = 3'h0;



// ----------------------------------------------------------------------
// DVSEC_FBRANGE2SZLOW.desired_interleave x3 RO, using RO template.
assign DVSEC_FBRANGE2SZLOW.desired_interleave = 3'h0;



// ----------------------------------------------------------------------
// DVSEC_FBRANGE2SZLOW.memory_active_timeout x3 RO, using RO template.
assign DVSEC_FBRANGE2SZLOW.memory_active_timeout = 3'h0;



// ----------------------------------------------------------------------
// DVSEC_FBRANGE2SZLOW.memory_size_low x4 RO, using RO template.
assign DVSEC_FBRANGE2SZLOW.memory_size_low = 4'h0;



//---------------------------------------------------------------------
// DVSEC_FBRANGE2HIGH Address Decode
logic  addr_decode_DVSEC_FBRANGE2HIGH;
logic  write_req_DVSEC_FBRANGE2HIGH;
always_comb begin
   addr_decode_DVSEC_FBRANGE2HIGH = (req_addr[CAFU_CSR0_CFG_CFG_ADDR_MSB:ADDR_LSB_BUS_ALIGN] == DVSEC_FBRANGE2HIGH_DECODE_ADDR) && req.valid ;
   write_req_DVSEC_FBRANGE2HIGH = IsCFGWr && addr_decode_DVSEC_FBRANGE2HIGH && sb_fid_cond_cfg_inst_sb;
end

// ----------------------------------------------------------------------
// DVSEC_FBRANGE2HIGH.memory_base_high x8 RW/L, using RW/L template.
logic [3:0] req_up_DVSEC_FBRANGE2HIGH_memory_base_high;
always_comb begin
 req_up_DVSEC_FBRANGE2HIGH_memory_base_high[0] = 
   {write_req_DVSEC_FBRANGE2HIGH & be[0]}
;
 req_up_DVSEC_FBRANGE2HIGH_memory_base_high[1] = 
   {write_req_DVSEC_FBRANGE2HIGH & be[1]}
;
 req_up_DVSEC_FBRANGE2HIGH_memory_base_high[2] = 
   {write_req_DVSEC_FBRANGE2HIGH & be[2]}
;
 req_up_DVSEC_FBRANGE2HIGH_memory_base_high[3] = 
   {write_req_DVSEC_FBRANGE2HIGH & be[3]}
;
end

logic  lock_lcl_DVSEC_FBRANGE2HIGH_memory_base_high;
always_comb begin
 lock_lcl_DVSEC_FBRANGE2HIGH_memory_base_high = ((DVSEC_FBLOCK.config_lock == 1'h1));
end

logic [3:0] up_DVSEC_FBRANGE2HIGH_memory_base_high;
always_comb begin
 up_DVSEC_FBRANGE2HIGH_memory_base_high = 
   (req_up_DVSEC_FBRANGE2HIGH_memory_base_high & {4{~lock_lcl_DVSEC_FBRANGE2HIGH_memory_base_high}});

end


logic [31:0] nxt_DVSEC_FBRANGE2HIGH_memory_base_high;
always_comb begin
 nxt_DVSEC_FBRANGE2HIGH_memory_base_high = write_data[31:0];

end
`RTLGEN_CAFU_CSR0_CFG_EN_FF(gated_clk, rst_n, 8'h0, up_DVSEC_FBRANGE2HIGH_memory_base_high[0], nxt_DVSEC_FBRANGE2HIGH_memory_base_high[7:0], DVSEC_FBRANGE2HIGH.memory_base_high[7:0])
`RTLGEN_CAFU_CSR0_CFG_EN_FF(gated_clk, rst_n, 8'h0, up_DVSEC_FBRANGE2HIGH_memory_base_high[1], nxt_DVSEC_FBRANGE2HIGH_memory_base_high[15:8], DVSEC_FBRANGE2HIGH.memory_base_high[15:8])
`RTLGEN_CAFU_CSR0_CFG_EN_FF(gated_clk, rst_n, 8'h0, up_DVSEC_FBRANGE2HIGH_memory_base_high[2], nxt_DVSEC_FBRANGE2HIGH_memory_base_high[23:16], DVSEC_FBRANGE2HIGH.memory_base_high[23:16])
`RTLGEN_CAFU_CSR0_CFG_EN_FF(gated_clk, rst_n, 8'h0, up_DVSEC_FBRANGE2HIGH_memory_base_high[3], nxt_DVSEC_FBRANGE2HIGH_memory_base_high[31:24], DVSEC_FBRANGE2HIGH.memory_base_high[31:24])

//---------------------------------------------------------------------
// DVSEC_FBRANGE2LOW Address Decode
logic  addr_decode_DVSEC_FBRANGE2LOW;
logic  write_req_DVSEC_FBRANGE2LOW;
always_comb begin
   addr_decode_DVSEC_FBRANGE2LOW = (req_addr[CAFU_CSR0_CFG_CFG_ADDR_MSB:ADDR_LSB_BUS_ALIGN] == DVSEC_FBRANGE2LOW_DECODE_ADDR) && req.valid ;
   write_req_DVSEC_FBRANGE2LOW = IsCFGWr && addr_decode_DVSEC_FBRANGE2LOW && sb_fid_cond_cfg_inst_sb;
end

// ----------------------------------------------------------------------
// DVSEC_FBRANGE2LOW.memory_base_low x4 RW/L, using RW/L template.
logic [0:0] req_up_DVSEC_FBRANGE2LOW_memory_base_low;
always_comb begin
 req_up_DVSEC_FBRANGE2LOW_memory_base_low[0] = 
   {write_req_DVSEC_FBRANGE2LOW & be[7]}
;
end

logic  lock_lcl_DVSEC_FBRANGE2LOW_memory_base_low;
always_comb begin
 lock_lcl_DVSEC_FBRANGE2LOW_memory_base_low = ((DVSEC_FBLOCK.config_lock == 1'h1));
end

logic [0:0] up_DVSEC_FBRANGE2LOW_memory_base_low;
always_comb begin
 up_DVSEC_FBRANGE2LOW_memory_base_low = 
   (req_up_DVSEC_FBRANGE2LOW_memory_base_low & {1{~lock_lcl_DVSEC_FBRANGE2LOW_memory_base_low}});

end


logic [3:0] nxt_DVSEC_FBRANGE2LOW_memory_base_low;
always_comb begin
 nxt_DVSEC_FBRANGE2LOW_memory_base_low = write_data[63:60];

end
`RTLGEN_CAFU_CSR0_CFG_EN_FF(gated_clk, rst_n, 4'h0, up_DVSEC_FBRANGE2LOW_memory_base_low[0], nxt_DVSEC_FBRANGE2LOW_memory_base_low[3:0], DVSEC_FBRANGE2LOW.memory_base_low[3:0])

//---------------------------------------------------------------------
// DVSEC_DOE Address Decode

// ----------------------------------------------------------------------
// DVSEC_DOE.dvsec_cap_id x8 RO, using RO template.
assign DVSEC_DOE.dvsec_cap_id = 16'h2E;



// ----------------------------------------------------------------------
// DVSEC_DOE.dvsec_cap_version x4 RO, using RO template.
assign DVSEC_DOE.dvsec_cap_version = 4'h1;



// ----------------------------------------------------------------------
// DVSEC_DOE.next_cap_offset x8 RO, using RO template.
assign DVSEC_DOE.next_cap_offset = 12'hF60;



//---------------------------------------------------------------------
// DOE_CAPREG Address Decode

// ----------------------------------------------------------------------
// DOE_CAPREG.doe_int_support x1 RO, using RO template.
assign DOE_CAPREG.doe_int_support = 1'h0;



// ----------------------------------------------------------------------
// DOE_CAPREG.doe_int_msg x4 RO, using RO template.
assign DOE_CAPREG.doe_int_msg = 11'h0;



//---------------------------------------------------------------------
// DOE_CTLREG Address Decode
logic  addr_decode_DOE_CTLREG;
logic  write_req_DOE_CTLREG;
always_comb begin
   addr_decode_DOE_CTLREG = (req_addr[CAFU_CSR0_CFG_CFG_ADDR_MSB:ADDR_LSB_BUS_ALIGN] == DOE_CTLREG_DECODE_ADDR) && req.valid ;
   write_req_DOE_CTLREG = IsCFGWr && addr_decode_DOE_CTLREG && sb_fid_cond_cfg_inst_sb;
end

// ----------------------------------------------------------------------
// DOE_CTLREG.doe_abort x1 RW/V, using RW/V template.
logic [0:0] req_up_DOE_CTLREG_doe_abort;
always_comb begin
 req_up_DOE_CTLREG_doe_abort[0] = 
   {write_req_DOE_CTLREG & be[0]}
;
end

logic [0:0] swwr_DOE_CTLREG_doe_abort;
always_comb begin
 swwr_DOE_CTLREG_doe_abort = req_up_DOE_CTLREG_doe_abort;

end


logic [0:0] up_DOE_CTLREG_doe_abort;
logic [0:0] nxt_DOE_CTLREG_doe_abort;
always_comb begin
 up_DOE_CTLREG_doe_abort =
    swwr_DOE_CTLREG_doe_abort |
    {1{load_DOE_CTLREG.doe_abort}};
end
always_comb begin
 nxt_DOE_CTLREG_doe_abort[0:0] = 
    swwr_DOE_CTLREG_doe_abort[0] ?
    write_data[0:0] :
    new_DOE_CTLREG.doe_abort[0:0];
end

`RTLGEN_CAFU_CSR0_CFG_EN_FF(rtl_clk, rst_n, 1'h0, up_DOE_CTLREG_doe_abort[0], nxt_DOE_CTLREG_doe_abort[0:0], DOE_CTLREG.doe_abort[0:0])

// ----------------------------------------------------------------------
// DOE_CTLREG.doe_int_enb x1 RW, using RW template.
logic [0:0] up_DOE_CTLREG_doe_int_enb;
always_comb begin
 up_DOE_CTLREG_doe_int_enb =
    ({1{write_req_DOE_CTLREG }} &
    be[0:0]);
end

logic [0:0] nxt_DOE_CTLREG_doe_int_enb;
always_comb begin
 nxt_DOE_CTLREG_doe_int_enb = write_data[1:1];

end


`RTLGEN_CAFU_CSR0_CFG_EN_FF_SYNCRST(gated_clk, cxl_or_conv_rst_n, 1'h0, up_DOE_CTLREG_doe_int_enb[0], nxt_DOE_CTLREG_doe_int_enb[0:0], DOE_CTLREG.doe_int_enb[0:0])

// ----------------------------------------------------------------------
// DOE_CTLREG.doe_go x1 RW/V, using RW/V template.
logic [0:0] req_up_DOE_CTLREG_doe_go;
always_comb begin
 req_up_DOE_CTLREG_doe_go[0] = 
   {write_req_DOE_CTLREG & be[3]}
;
end

logic [0:0] swwr_DOE_CTLREG_doe_go;
always_comb begin
 swwr_DOE_CTLREG_doe_go = req_up_DOE_CTLREG_doe_go;

end


logic [0:0] up_DOE_CTLREG_doe_go;
logic [0:0] nxt_DOE_CTLREG_doe_go;
always_comb begin
 up_DOE_CTLREG_doe_go =
    swwr_DOE_CTLREG_doe_go |
    {1{load_DOE_CTLREG.doe_go}};
end
always_comb begin
 nxt_DOE_CTLREG_doe_go[0:0] = 
    swwr_DOE_CTLREG_doe_go[0] ?
    write_data[31:31] :
    new_DOE_CTLREG.doe_go[0:0];
end

`RTLGEN_CAFU_CSR0_CFG_EN_FF(rtl_clk, rst_n, 1'h0, up_DOE_CTLREG_doe_go[0], nxt_DOE_CTLREG_doe_go[0:0], DOE_CTLREG.doe_go[0:0])

//---------------------------------------------------------------------
// DOE_STSREG Address Decode
logic  addr_decode_DOE_STSREG;
logic  write_req_DOE_STSREG;
always_comb begin
   addr_decode_DOE_STSREG = (req_addr[CAFU_CSR0_CFG_CFG_ADDR_MSB:ADDR_LSB_BUS_ALIGN] == DOE_STSREG_DECODE_ADDR) && req.valid ;
   write_req_DOE_STSREG = IsCFGWr && addr_decode_DOE_STSREG && sb_fid_cond_cfg_inst_sb;
end
// ----------------------------------------------------------------------
// DOE_STSREG.doe_busy x1 RO/V, using RO/V template.
assign DOE_STSREG.doe_busy = new_DOE_STSREG.doe_busy;




// ----------------------------------------------------------------------
// DOE_STSREG.doe_int_status x1 RW/1C/V, using RW/1C/V template.
// clear the each bit when writing a 1
logic [0:0] req_up_DOE_STSREG_doe_int_status;
always_comb begin
 req_up_DOE_STSREG_doe_int_status[0:0] = 
   {1{write_req_DOE_STSREG & be[4]}}
;
end

logic [0:0] clr_DOE_STSREG_doe_int_status;
always_comb begin
 clr_DOE_STSREG_doe_int_status = write_data[33:33] & req_up_DOE_STSREG_doe_int_status;

end
logic [0:0] swwr_DOE_STSREG_doe_int_status;
logic [0:0] sw_nxt_DOE_STSREG_doe_int_status;
always_comb begin
 swwr_DOE_STSREG_doe_int_status = clr_DOE_STSREG_doe_int_status;
 sw_nxt_DOE_STSREG_doe_int_status = {1{1'b0}};

end
logic [0:0] up_DOE_STSREG_doe_int_status;
logic [0:0] nxt_DOE_STSREG_doe_int_status;
always_comb begin
 up_DOE_STSREG_doe_int_status = 
   swwr_DOE_STSREG_doe_int_status | {1{load_DOE_STSREG.doe_int_status}};
end
always_comb begin
 nxt_DOE_STSREG_doe_int_status[0] = 
    load_DOE_STSREG.doe_int_status ?
    new_DOE_STSREG.doe_int_status[0] :
    sw_nxt_DOE_STSREG_doe_int_status[0];
end



`RTLGEN_CAFU_CSR0_CFG_EN_FF_SYNCRST(rtl_clk, cxl_or_conv_rst_n, 1'h0, up_DOE_STSREG_doe_int_status[0], nxt_DOE_STSREG_doe_int_status[0], DOE_STSREG.doe_int_status[0])
// ----------------------------------------------------------------------
// DOE_STSREG.doe_error x1 RO/V, using RO/V template.
assign DOE_STSREG.doe_error = new_DOE_STSREG.doe_error;



// ----------------------------------------------------------------------
// DOE_STSREG.data_object_ready x1 RO/V, using RO/V template.
assign DOE_STSREG.data_object_ready = new_DOE_STSREG.data_object_ready;




//---------------------------------------------------------------------
// DOE_WRMAILREG Address Decode
logic  addr_decode_DOE_WRMAILREG;
logic  write_req_DOE_WRMAILREG;
always_comb begin
   addr_decode_DOE_WRMAILREG = (req_addr[CAFU_CSR0_CFG_CFG_ADDR_MSB:ADDR_LSB_BUS_ALIGN] == DOE_WRMAILREG_DECODE_ADDR) && req.valid ;
   write_req_DOE_WRMAILREG = IsCFGWr && addr_decode_DOE_WRMAILREG && sb_fid_cond_cfg_inst_sb;
end

// ----------------------------------------------------------------------
// DOE_WRMAILREG.doe_wr_data_mailbox x8 RW/V, using RW/V template.
logic [3:0] req_up_DOE_WRMAILREG_doe_wr_data_mailbox;
always_comb begin
 req_up_DOE_WRMAILREG_doe_wr_data_mailbox[0] = 
   {write_req_DOE_WRMAILREG & be[0]}
;
 req_up_DOE_WRMAILREG_doe_wr_data_mailbox[1] = 
   {write_req_DOE_WRMAILREG & be[1]}
;
 req_up_DOE_WRMAILREG_doe_wr_data_mailbox[2] = 
   {write_req_DOE_WRMAILREG & be[2]}
;
 req_up_DOE_WRMAILREG_doe_wr_data_mailbox[3] = 
   {write_req_DOE_WRMAILREG & be[3]}
;
end

logic [3:0] swwr_DOE_WRMAILREG_doe_wr_data_mailbox;
always_comb begin
 swwr_DOE_WRMAILREG_doe_wr_data_mailbox = req_up_DOE_WRMAILREG_doe_wr_data_mailbox;

end


logic [3:0] up_DOE_WRMAILREG_doe_wr_data_mailbox;
logic [31:0] nxt_DOE_WRMAILREG_doe_wr_data_mailbox;
always_comb begin
 up_DOE_WRMAILREG_doe_wr_data_mailbox =
    swwr_DOE_WRMAILREG_doe_wr_data_mailbox |
    {4{load_DOE_WRMAILREG.doe_wr_data_mailbox}};
end
always_comb begin
 nxt_DOE_WRMAILREG_doe_wr_data_mailbox[7:0] = 
    swwr_DOE_WRMAILREG_doe_wr_data_mailbox[0] ?
    write_data[7:0] :
    new_DOE_WRMAILREG.doe_wr_data_mailbox[7:0];
 nxt_DOE_WRMAILREG_doe_wr_data_mailbox[15:8] = 
    swwr_DOE_WRMAILREG_doe_wr_data_mailbox[1] ?
    write_data[15:8] :
    new_DOE_WRMAILREG.doe_wr_data_mailbox[15:8];
 nxt_DOE_WRMAILREG_doe_wr_data_mailbox[23:16] = 
    swwr_DOE_WRMAILREG_doe_wr_data_mailbox[2] ?
    write_data[23:16] :
    new_DOE_WRMAILREG.doe_wr_data_mailbox[23:16];
 nxt_DOE_WRMAILREG_doe_wr_data_mailbox[31:24] = 
    swwr_DOE_WRMAILREG_doe_wr_data_mailbox[3] ?
    write_data[31:24] :
    new_DOE_WRMAILREG.doe_wr_data_mailbox[31:24];
end

`RTLGEN_CAFU_CSR0_CFG_EN_FF_SYNCRST(rtl_clk, cxl_or_conv_rst_n, 8'h0, up_DOE_WRMAILREG_doe_wr_data_mailbox[0], nxt_DOE_WRMAILREG_doe_wr_data_mailbox[7:0], DOE_WRMAILREG.doe_wr_data_mailbox[7:0])
`RTLGEN_CAFU_CSR0_CFG_EN_FF_SYNCRST(rtl_clk, cxl_or_conv_rst_n, 8'h0, up_DOE_WRMAILREG_doe_wr_data_mailbox[1], nxt_DOE_WRMAILREG_doe_wr_data_mailbox[15:8], DOE_WRMAILREG.doe_wr_data_mailbox[15:8])
`RTLGEN_CAFU_CSR0_CFG_EN_FF_SYNCRST(rtl_clk, cxl_or_conv_rst_n, 8'h0, up_DOE_WRMAILREG_doe_wr_data_mailbox[2], nxt_DOE_WRMAILREG_doe_wr_data_mailbox[23:16], DOE_WRMAILREG.doe_wr_data_mailbox[23:16])
`RTLGEN_CAFU_CSR0_CFG_EN_FF_SYNCRST(rtl_clk, cxl_or_conv_rst_n, 8'h0, up_DOE_WRMAILREG_doe_wr_data_mailbox[3], nxt_DOE_WRMAILREG_doe_wr_data_mailbox[31:24], DOE_WRMAILREG.doe_wr_data_mailbox[31:24])

//---------------------------------------------------------------------
// DOE_RDMAILREG Address Decode
logic  addr_decode_DOE_RDMAILREG;
logic  write_req_DOE_RDMAILREG;
always_comb begin
   addr_decode_DOE_RDMAILREG = (req_addr[CAFU_CSR0_CFG_CFG_ADDR_MSB:ADDR_LSB_BUS_ALIGN] == DOE_RDMAILREG_DECODE_ADDR) && req.valid ;
   write_req_DOE_RDMAILREG = IsCFGWr && addr_decode_DOE_RDMAILREG && sb_fid_cond_cfg_inst_sb;
end

// ----------------------------------------------------------------------
// DOE_RDMAILREG.doe_rd_data_mailbox x8 RW/V, using RW/V template.
logic [3:0] req_up_DOE_RDMAILREG_doe_rd_data_mailbox;
always_comb begin
 req_up_DOE_RDMAILREG_doe_rd_data_mailbox[0] = 
   {write_req_DOE_RDMAILREG & be[4]}
;
 req_up_DOE_RDMAILREG_doe_rd_data_mailbox[1] = 
   {write_req_DOE_RDMAILREG & be[5]}
;
 req_up_DOE_RDMAILREG_doe_rd_data_mailbox[2] = 
   {write_req_DOE_RDMAILREG & be[6]}
;
 req_up_DOE_RDMAILREG_doe_rd_data_mailbox[3] = 
   {write_req_DOE_RDMAILREG & be[7]}
;
end

logic [3:0] swwr_DOE_RDMAILREG_doe_rd_data_mailbox;
always_comb begin
 swwr_DOE_RDMAILREG_doe_rd_data_mailbox = req_up_DOE_RDMAILREG_doe_rd_data_mailbox;

end


logic [3:0] up_DOE_RDMAILREG_doe_rd_data_mailbox;
logic [31:0] nxt_DOE_RDMAILREG_doe_rd_data_mailbox;
always_comb begin
 up_DOE_RDMAILREG_doe_rd_data_mailbox =
    swwr_DOE_RDMAILREG_doe_rd_data_mailbox |
    {4{load_DOE_RDMAILREG.doe_rd_data_mailbox}};
end
always_comb begin
 nxt_DOE_RDMAILREG_doe_rd_data_mailbox[7:0] = 
    swwr_DOE_RDMAILREG_doe_rd_data_mailbox[0] ?
    write_data[39:32] :
    new_DOE_RDMAILREG.doe_rd_data_mailbox[7:0];
 nxt_DOE_RDMAILREG_doe_rd_data_mailbox[15:8] = 
    swwr_DOE_RDMAILREG_doe_rd_data_mailbox[1] ?
    write_data[47:40] :
    new_DOE_RDMAILREG.doe_rd_data_mailbox[15:8];
 nxt_DOE_RDMAILREG_doe_rd_data_mailbox[23:16] = 
    swwr_DOE_RDMAILREG_doe_rd_data_mailbox[2] ?
    write_data[55:48] :
    new_DOE_RDMAILREG.doe_rd_data_mailbox[23:16];
 nxt_DOE_RDMAILREG_doe_rd_data_mailbox[31:24] = 
    swwr_DOE_RDMAILREG_doe_rd_data_mailbox[3] ?
    write_data[63:56] :
    new_DOE_RDMAILREG.doe_rd_data_mailbox[31:24];
end

`RTLGEN_CAFU_CSR0_CFG_EN_FF_SYNCRST(rtl_clk, cxl_or_conv_rst_n, 8'h0, up_DOE_RDMAILREG_doe_rd_data_mailbox[0], nxt_DOE_RDMAILREG_doe_rd_data_mailbox[7:0], DOE_RDMAILREG.doe_rd_data_mailbox[7:0])
`RTLGEN_CAFU_CSR0_CFG_EN_FF_SYNCRST(rtl_clk, cxl_or_conv_rst_n, 8'h0, up_DOE_RDMAILREG_doe_rd_data_mailbox[1], nxt_DOE_RDMAILREG_doe_rd_data_mailbox[15:8], DOE_RDMAILREG.doe_rd_data_mailbox[15:8])
`RTLGEN_CAFU_CSR0_CFG_EN_FF_SYNCRST(rtl_clk, cxl_or_conv_rst_n, 8'h0, up_DOE_RDMAILREG_doe_rd_data_mailbox[2], nxt_DOE_RDMAILREG_doe_rd_data_mailbox[23:16], DOE_RDMAILREG.doe_rd_data_mailbox[23:16])
`RTLGEN_CAFU_CSR0_CFG_EN_FF_SYNCRST(rtl_clk, cxl_or_conv_rst_n, 8'h0, up_DOE_RDMAILREG_doe_rd_data_mailbox[3], nxt_DOE_RDMAILREG_doe_rd_data_mailbox[31:24], DOE_RDMAILREG.doe_rd_data_mailbox[31:24])

//---------------------------------------------------------------------
// DVSEC_TEST_CAP Address Decode

// ----------------------------------------------------------------------
// DVSEC_TEST_CAP.test_cap_id x8 RO, using RO template.
assign DVSEC_TEST_CAP.test_cap_id = 16'h23;



// ----------------------------------------------------------------------
// DVSEC_TEST_CAP.test_cap_version x4 RO, using RO template.
assign DVSEC_TEST_CAP.test_cap_version = 4'h1;



// ----------------------------------------------------------------------
// DVSEC_TEST_CAP.next_cap_offset x8 RO, using RO template.
assign DVSEC_TEST_CAP.next_cap_offset = 12'h0;



//---------------------------------------------------------------------
// CXL_DVSEC_HEADER_1 Address Decode

// ----------------------------------------------------------------------
// CXL_DVSEC_HEADER_1.dvsec_vend_id x8 RO, using RO template.
assign CXL_DVSEC_HEADER_1.dvsec_vend_id = 16'h1E98;



// ----------------------------------------------------------------------
// CXL_DVSEC_HEADER_1.dvsec_revision x4 RO, using RO template.
assign CXL_DVSEC_HEADER_1.dvsec_revision = 4'h0;



// ----------------------------------------------------------------------
// CXL_DVSEC_HEADER_1.dvsec_length x8 RO, using RO template.
assign CXL_DVSEC_HEADER_1.dvsec_length = 12'h22;



//---------------------------------------------------------------------
// CXL_DVSEC_HEADER_2 Address Decode

// ----------------------------------------------------------------------
// CXL_DVSEC_HEADER_2.dvsec_id x8 RO, using RO template.
assign CXL_DVSEC_HEADER_2.dvsec_id = 16'hA;



//---------------------------------------------------------------------
// CXL_DVSEC_TEST_LOCK Address Decode
logic  addr_decode_CXL_DVSEC_TEST_LOCK;
logic  write_req_CXL_DVSEC_TEST_LOCK;
always_comb begin
   addr_decode_CXL_DVSEC_TEST_LOCK = (req_addr[CAFU_CSR0_CFG_CFG_ADDR_MSB:ADDR_LSB_BUS_ALIGN] == CXL_DVSEC_TEST_LOCK_DECODE_ADDR) && req.valid ;
   write_req_CXL_DVSEC_TEST_LOCK = IsCFGWr && addr_decode_CXL_DVSEC_TEST_LOCK && sb_fid_cond_cfg_inst_sb;
end

// ----------------------------------------------------------------------
// CXL_DVSEC_TEST_LOCK.test_config_lock x1 RW/L, using RW/L template.
logic [0:0] req_up_CXL_DVSEC_TEST_LOCK_test_config_lock;
always_comb begin
 req_up_CXL_DVSEC_TEST_LOCK_test_config_lock[0] = 
   {write_req_CXL_DVSEC_TEST_LOCK & be[2]}
;
end

logic  lock_lcl_CXL_DVSEC_TEST_LOCK_test_config_lock;
always_comb begin
 lock_lcl_CXL_DVSEC_TEST_LOCK_test_config_lock = ((CXL_DVSEC_TEST_LOCK.test_config_lock == 1'h1));
end

logic [0:0] up_CXL_DVSEC_TEST_LOCK_test_config_lock;
always_comb begin
 up_CXL_DVSEC_TEST_LOCK_test_config_lock = 
   (req_up_CXL_DVSEC_TEST_LOCK_test_config_lock & {1{~lock_lcl_CXL_DVSEC_TEST_LOCK_test_config_lock}});

end


logic [0:0] nxt_CXL_DVSEC_TEST_LOCK_test_config_lock;
always_comb begin
 nxt_CXL_DVSEC_TEST_LOCK_test_config_lock = write_data[16:16];

end
`RTLGEN_CAFU_CSR0_CFG_EN_FF(gated_clk, rst_n, 1'h0, up_CXL_DVSEC_TEST_LOCK_test_config_lock[0], nxt_CXL_DVSEC_TEST_LOCK_test_config_lock[0:0], CXL_DVSEC_TEST_LOCK.test_config_lock[0:0])

//---------------------------------------------------------------------
// CXL_DVSEC_TEST_CAP1 Address Decode

// ----------------------------------------------------------------------
// CXL_DVSEC_TEST_CAP1.algo_selfcheck_enb x1 RO, using RO template.
assign CXL_DVSEC_TEST_CAP1.algo_selfcheck_enb = 1'h1;



// ----------------------------------------------------------------------
// CXL_DVSEC_TEST_CAP1.algotype_1a x1 RO, using RO template.
assign CXL_DVSEC_TEST_CAP1.algotype_1a = 1'h1;



// ----------------------------------------------------------------------
// CXL_DVSEC_TEST_CAP1.algotype_1b x1 RO, using RO template.
assign CXL_DVSEC_TEST_CAP1.algotype_1b = 1'h0;



// ----------------------------------------------------------------------
// CXL_DVSEC_TEST_CAP1.algotype_2 x1 RO, using RO template.
assign CXL_DVSEC_TEST_CAP1.algotype_2 = 1'h0;



// ----------------------------------------------------------------------
// CXL_DVSEC_TEST_CAP1.cache_rdcurrent x1 RO, using RO template.
assign CXL_DVSEC_TEST_CAP1.cache_rdcurrent = support_cache_read_current;



// ----------------------------------------------------------------------
// CXL_DVSEC_TEST_CAP1.cache_rdown x1 RO, using RO template.
assign CXL_DVSEC_TEST_CAP1.cache_rdown = support_cache_read_down;



// ----------------------------------------------------------------------
// CXL_DVSEC_TEST_CAP1.cache_rdshared x1 RO, using RO template.
assign CXL_DVSEC_TEST_CAP1.cache_rdshared = support_cache_read_shared;



// ----------------------------------------------------------------------
// CXL_DVSEC_TEST_CAP1.cache_rdany x1 RO, using RO template.
assign CXL_DVSEC_TEST_CAP1.cache_rdany = 1'h0;



// ----------------------------------------------------------------------
// CXL_DVSEC_TEST_CAP1.cache_rdown_nodata x1 RO, using RO template.
assign CXL_DVSEC_TEST_CAP1.cache_rdown_nodata = 1'h0;



// ----------------------------------------------------------------------
// CXL_DVSEC_TEST_CAP1.cache_itom_wr x1 RO, using RO template.
assign CXL_DVSEC_TEST_CAP1.cache_itom_wr = support_cache_write_itom;



// ----------------------------------------------------------------------
// CXL_DVSEC_TEST_CAP1.cache_mem_wr x1 RO, using RO template.
assign CXL_DVSEC_TEST_CAP1.cache_mem_wr = 1'h0;



// ----------------------------------------------------------------------
// CXL_DVSEC_TEST_CAP1.cache_cl_flush x1 RO, using RO template.
assign CXL_DVSEC_TEST_CAP1.cache_cl_flush = 1'h0;



// ----------------------------------------------------------------------
// CXL_DVSEC_TEST_CAP1.cache_clean_evict x1 RO, using RO template.
assign CXL_DVSEC_TEST_CAP1.cache_clean_evict = 1'h0;



// ----------------------------------------------------------------------
// CXL_DVSEC_TEST_CAP1.cache_dirty_evict x1 RO, using RO template.
assign CXL_DVSEC_TEST_CAP1.cache_dirty_evict = support_cache_dirty_evict;



// ----------------------------------------------------------------------
// CXL_DVSEC_TEST_CAP1.cache_clean_evict_nodata x1 RO, using RO template.
assign CXL_DVSEC_TEST_CAP1.cache_clean_evict_nodata = 1'h0;



// ----------------------------------------------------------------------
// CXL_DVSEC_TEST_CAP1.cache_wow_inv x1 RO, using RO template.
assign CXL_DVSEC_TEST_CAP1.cache_wow_inv = support_cache_write_wow_inv;



// ----------------------------------------------------------------------
// CXL_DVSEC_TEST_CAP1.cache_wow_invf x1 RO, using RO template.
assign CXL_DVSEC_TEST_CAP1.cache_wow_invf = support_cache_write_wow_invf;



// ----------------------------------------------------------------------
// CXL_DVSEC_TEST_CAP1.cache_wr_inv x1 RO, using RO template.
assign CXL_DVSEC_TEST_CAP1.cache_wr_inv = 1'h0;



// ----------------------------------------------------------------------
// CXL_DVSEC_TEST_CAP1.cache_flushed x1 RO, using RO template.
assign CXL_DVSEC_TEST_CAP1.cache_flushed = 1'h0;



// ----------------------------------------------------------------------
// CXL_DVSEC_TEST_CAP1.unexpect_cmpletion x1 RO, using RO template.
assign CXL_DVSEC_TEST_CAP1.unexpect_cmpletion = 1'h0;



// ----------------------------------------------------------------------
// CXL_DVSEC_TEST_CAP1.cmplte_timeout_injection x1 RO, using RO template.
assign CXL_DVSEC_TEST_CAP1.cmplte_timeout_injection = 1'h0;



// ----------------------------------------------------------------------
// CXL_DVSEC_TEST_CAP1.test_config_size x8 RO, using RO template.
assign CXL_DVSEC_TEST_CAP1.test_config_size = 8'h0;



//---------------------------------------------------------------------
// CXL_DVSEC_TEST_CAP2 Address Decode

// ----------------------------------------------------------------------
// CXL_DVSEC_TEST_CAP2.cache_size_device x6 RO, using RO template.
assign CXL_DVSEC_TEST_CAP2.cache_size_device = CXL_DVSEC_TEST_CAP2_cache_size_device;



// ----------------------------------------------------------------------
// CXL_DVSEC_TEST_CAP2.cache_size_unit x2 RO, using RO template.
assign CXL_DVSEC_TEST_CAP2.cache_size_unit = CXL_DVSEC_TEST_CAP2_cache_size_unit;



//---------------------------------------------------------------------
// CXL_DVSEC_TEST_CNF_BASE_LOW Address Decode

// ----------------------------------------------------------------------
// CXL_DVSEC_TEST_CNF_BASE_LOW.mem_space_indicator x1 RO, using RO template.
assign CXL_DVSEC_TEST_CNF_BASE_LOW.mem_space_indicator = 1'h0;



// ----------------------------------------------------------------------
// CXL_DVSEC_TEST_CNF_BASE_LOW.base_reg_type x2 RO, using RO template.
assign CXL_DVSEC_TEST_CNF_BASE_LOW.base_reg_type = 2'h0;


// ----------------------------------------------------------------------
// CXL_DVSEC_TEST_CNF_BASE_LOW.test_config_base_low x8 RO/V, using RO/V template.
assign CXL_DVSEC_TEST_CNF_BASE_LOW.test_config_base_low = new_CXL_DVSEC_TEST_CNF_BASE_LOW.test_config_base_low;




//---------------------------------------------------------------------
// CXL_DVSEC_TEST_CNF_BASE_HIGH Address Decode
// ----------------------------------------------------------------------
// CXL_DVSEC_TEST_CNF_BASE_HIGH.test_config_base_high x8 RO/V, using RO/V template.
assign CXL_DVSEC_TEST_CNF_BASE_HIGH.test_config_base_high = new_CXL_DVSEC_TEST_CNF_BASE_HIGH.test_config_base_high;




//---------------------------------------------------------------------
// CXL_DEV_CAP_ARRAY_0 Address Decode

// ----------------------------------------------------------------------
// CXL_DEV_CAP_ARRAY_0.cap_id x8 RO, using RO template.
assign CXL_DEV_CAP_ARRAY_0.cap_id = 16'h0;



// ----------------------------------------------------------------------
// CXL_DEV_CAP_ARRAY_0.version x8 RO, using RO template.
assign CXL_DEV_CAP_ARRAY_0.version = 8'h1;



//---------------------------------------------------------------------
// CXL_DEV_CAP_ARRAY_1 Address Decode

// ----------------------------------------------------------------------
// CXL_DEV_CAP_ARRAY_1.cap_cnt x8 RO, using RO template.
assign CXL_DEV_CAP_ARRAY_1.cap_cnt = 16'h3;



//---------------------------------------------------------------------
// CXL_DEV_CAP_HDR1_0 Address Decode

// ----------------------------------------------------------------------
// CXL_DEV_CAP_HDR1_0.cap_id x8 RO, using RO template.
assign CXL_DEV_CAP_HDR1_0.cap_id = 16'h1;



// ----------------------------------------------------------------------
// CXL_DEV_CAP_HDR1_0.version x8 RO, using RO template.
assign CXL_DEV_CAP_HDR1_0.version = 8'h1;



//---------------------------------------------------------------------
// CXL_DEV_CAP_HDR1_1 Address Decode

// ----------------------------------------------------------------------
// CXL_DEV_CAP_HDR1_1.offset x8 RO, using RO template.
assign CXL_DEV_CAP_HDR1_1.offset = 32'h50;



//---------------------------------------------------------------------
// CXL_DEV_CAP_HDR1_2 Address Decode

// ----------------------------------------------------------------------
// CXL_DEV_CAP_HDR1_2.length x8 RO, using RO template.
assign CXL_DEV_CAP_HDR1_2.length = 32'h8;



//---------------------------------------------------------------------
// CXL_DEV_CAP_HDR2_0 Address Decode

// ----------------------------------------------------------------------
// CXL_DEV_CAP_HDR2_0.cap_id x8 RO, using RO template.
assign CXL_DEV_CAP_HDR2_0.cap_id = 16'h4000;



// ----------------------------------------------------------------------
// CXL_DEV_CAP_HDR2_0.version x8 RO, using RO template.
assign CXL_DEV_CAP_HDR2_0.version = 8'h1;



//---------------------------------------------------------------------
// CXL_DEV_CAP_HDR2_1 Address Decode

// ----------------------------------------------------------------------
// CXL_DEV_CAP_HDR2_1.offset x8 RO, using RO template.
assign CXL_DEV_CAP_HDR2_1.offset = 32'h58;



//---------------------------------------------------------------------
// CXL_DEV_CAP_HDR2_2 Address Decode

// ----------------------------------------------------------------------
// CXL_DEV_CAP_HDR2_2.length x8 RO, using RO template.
assign CXL_DEV_CAP_HDR2_2.length = 32'h8;



//---------------------------------------------------------------------
// CXL_DEV_CAP_HDR3_0 Address Decode

// ----------------------------------------------------------------------
// CXL_DEV_CAP_HDR3_0.cap_id x8 RO, using RO template.
assign CXL_DEV_CAP_HDR3_0.cap_id = 16'h2;



// ----------------------------------------------------------------------
// CXL_DEV_CAP_HDR3_0.version x8 RO, using RO template.
assign CXL_DEV_CAP_HDR3_0.version = 8'h1;



//---------------------------------------------------------------------
// CXL_DEV_CAP_HDR3_1 Address Decode

// ----------------------------------------------------------------------
// CXL_DEV_CAP_HDR3_1.offset x8 RO, using RO template.
assign CXL_DEV_CAP_HDR3_1.offset = 32'h60;



//---------------------------------------------------------------------
// CXL_DEV_CAP_HDR3_2 Address Decode

// ----------------------------------------------------------------------
// CXL_DEV_CAP_HDR3_2.length x8 RO, using RO template.
assign CXL_DEV_CAP_HDR3_2.length = 32'h820;



//---------------------------------------------------------------------
// CXL_DEV_CAP_EVENT_STATUS Address Decode
// ----------------------------------------------------------------------
// CXL_DEV_CAP_EVENT_STATUS.info_event_log x1 RO/V, using RO/V template.
assign CXL_DEV_CAP_EVENT_STATUS.info_event_log = new_CXL_DEV_CAP_EVENT_STATUS.info_event_log;



// ----------------------------------------------------------------------
// CXL_DEV_CAP_EVENT_STATUS.warning_event_log x1 RO/V, using RO/V template.
assign CXL_DEV_CAP_EVENT_STATUS.warning_event_log = new_CXL_DEV_CAP_EVENT_STATUS.warning_event_log;



// ----------------------------------------------------------------------
// CXL_DEV_CAP_EVENT_STATUS.failure_event_log x1 RO/V, using RO/V template.
assign CXL_DEV_CAP_EVENT_STATUS.failure_event_log = new_CXL_DEV_CAP_EVENT_STATUS.failure_event_log;



// ----------------------------------------------------------------------
// CXL_DEV_CAP_EVENT_STATUS.fatal_event_log x1 RO/V, using RO/V template.
assign CXL_DEV_CAP_EVENT_STATUS.fatal_event_log = new_CXL_DEV_CAP_EVENT_STATUS.fatal_event_log;




//---------------------------------------------------------------------
// CXL_MEM_DEV_STATUS Address Decode
// ----------------------------------------------------------------------
// CXL_MEM_DEV_STATUS.device_fatal x1 RO/V, using RO/V template.
assign CXL_MEM_DEV_STATUS.device_fatal = new_CXL_MEM_DEV_STATUS.device_fatal;



// ----------------------------------------------------------------------
// CXL_MEM_DEV_STATUS.fw_halt x1 RO/V, using RO/V template.
assign CXL_MEM_DEV_STATUS.fw_halt = new_CXL_MEM_DEV_STATUS.fw_halt;



// ----------------------------------------------------------------------
// CXL_MEM_DEV_STATUS.media_status x2 RO/V, using RO/V template.
assign CXL_MEM_DEV_STATUS.media_status = new_CXL_MEM_DEV_STATUS.media_status;



// ----------------------------------------------------------------------
// CXL_MEM_DEV_STATUS.mailbox_if_ready x1 RO/V, using RO/V template.
assign CXL_MEM_DEV_STATUS.mailbox_if_ready = new_CXL_MEM_DEV_STATUS.mailbox_if_ready;



// ----------------------------------------------------------------------
// CXL_MEM_DEV_STATUS.reset_needed x3 RO/V, using RO/V template.
assign CXL_MEM_DEV_STATUS.reset_needed = new_CXL_MEM_DEV_STATUS.reset_needed;




//---------------------------------------------------------------------
// CXL_MB_CAP Address Decode

// ----------------------------------------------------------------------
// CXL_MB_CAP.payload_size x5 RO, using RO template.
assign CXL_MB_CAP.payload_size = 5'hB;



// ----------------------------------------------------------------------
// CXL_MB_CAP.mb_doorbell_int_cap x1 RO, using RO template.
assign CXL_MB_CAP.mb_doorbell_int_cap = 1'h0;



// ----------------------------------------------------------------------
// CXL_MB_CAP.bk_cmd_comp_int_cap x1 RO, using RO template.
assign CXL_MB_CAP.bk_cmd_comp_int_cap = 1'h0;



// ----------------------------------------------------------------------
// CXL_MB_CAP.int_msg_num x3 RO, using RO template.
assign CXL_MB_CAP.int_msg_num = 4'h0;



//---------------------------------------------------------------------
// CXL_MB_CTRL Address Decode
logic  addr_decode_CXL_MB_CTRL;
logic  write_req_CXL_MB_CTRL;
always_comb begin
   addr_decode_CXL_MB_CTRL = (req_addr[CAFU_CSR0_CFG_MEM_ADDR_MSB:ADDR_LSB_BUS_ALIGN] == CXL_MB_CTRL_DECODE_ADDR) && req.valid ;
   write_req_CXL_MB_CTRL = IsMEMWr && addr_decode_CXL_MB_CTRL && sb_fid_cond_mem_inst_sb && sb_bar_cond_mem_inst_sb;
end

// ----------------------------------------------------------------------
// CXL_MB_CTRL.doorbell x1 RW/V, using RW/V template.
logic [0:0] req_up_CXL_MB_CTRL_doorbell;
always_comb begin
 req_up_CXL_MB_CTRL_doorbell[0] = 
   {write_req_CXL_MB_CTRL & be[4]}
;
end

logic [0:0] swwr_CXL_MB_CTRL_doorbell;
always_comb begin
 swwr_CXL_MB_CTRL_doorbell = req_up_CXL_MB_CTRL_doorbell;

end


logic [0:0] up_CXL_MB_CTRL_doorbell;
logic [0:0] nxt_CXL_MB_CTRL_doorbell;
always_comb begin
 up_CXL_MB_CTRL_doorbell =
    swwr_CXL_MB_CTRL_doorbell |
    {1{load_CXL_MB_CTRL.doorbell}};
end
always_comb begin
 nxt_CXL_MB_CTRL_doorbell[0:0] = 
    swwr_CXL_MB_CTRL_doorbell[0] ?
    write_data[32:32] :
    new_CXL_MB_CTRL.doorbell[0:0];
end

`RTLGEN_CAFU_CSR0_CFG_EN_FF_SYNCRST(rtl_clk, cxl_or_conv_rst_n, 1'h0, up_CXL_MB_CTRL_doorbell[0], nxt_CXL_MB_CTRL_doorbell[0:0], CXL_MB_CTRL.doorbell[0:0])

// ----------------------------------------------------------------------
// CXL_MB_CTRL.mb_doorbell_int x1 RW, using RW template.
logic [0:0] up_CXL_MB_CTRL_mb_doorbell_int;
always_comb begin
 up_CXL_MB_CTRL_mb_doorbell_int =
    ({1{write_req_CXL_MB_CTRL }} &
    be[4:4]);
end

logic [0:0] nxt_CXL_MB_CTRL_mb_doorbell_int;
always_comb begin
 nxt_CXL_MB_CTRL_mb_doorbell_int = write_data[33:33];

end


`RTLGEN_CAFU_CSR0_CFG_EN_FF_SYNCRST(gated_clk, cxl_or_conv_rst_n, 1'h0, up_CXL_MB_CTRL_mb_doorbell_int[0], nxt_CXL_MB_CTRL_mb_doorbell_int[0:0], CXL_MB_CTRL.mb_doorbell_int[0:0])

// ----------------------------------------------------------------------
// CXL_MB_CTRL.bk_cmd_comp_int x1 RW, using RW template.
logic [0:0] up_CXL_MB_CTRL_bk_cmd_comp_int;
always_comb begin
 up_CXL_MB_CTRL_bk_cmd_comp_int =
    ({1{write_req_CXL_MB_CTRL }} &
    be[4:4]);
end

logic [0:0] nxt_CXL_MB_CTRL_bk_cmd_comp_int;
always_comb begin
 nxt_CXL_MB_CTRL_bk_cmd_comp_int = write_data[34:34];

end


`RTLGEN_CAFU_CSR0_CFG_EN_FF_SYNCRST(gated_clk, cxl_or_conv_rst_n, 1'h0, up_CXL_MB_CTRL_bk_cmd_comp_int[0], nxt_CXL_MB_CTRL_bk_cmd_comp_int[0:0], CXL_MB_CTRL.bk_cmd_comp_int[0:0])

//---------------------------------------------------------------------
// CXL_MB_CMD Address Decode
logic  addr_decode_CXL_MB_CMD;
logic  write_req_CXL_MB_CMD;
always_comb begin
   addr_decode_CXL_MB_CMD = (req_addr[CAFU_CSR0_CFG_MEM_ADDR_MSB:ADDR_LSB_BUS_ALIGN] == CXL_MB_CMD_DECODE_ADDR) && req.valid ;
   write_req_CXL_MB_CMD = IsMEMWr && addr_decode_CXL_MB_CMD && sb_fid_cond_mem_inst_sb && sb_bar_cond_mem_inst_sb;
end

// ----------------------------------------------------------------------
// CXL_MB_CMD.command_op x8 RW, using RW template.
logic [1:0] up_CXL_MB_CMD_command_op;
always_comb begin
 up_CXL_MB_CMD_command_op =
    ({2{write_req_CXL_MB_CMD }} &
    be[1:0]);
end

logic [15:0] nxt_CXL_MB_CMD_command_op;
always_comb begin
 nxt_CXL_MB_CMD_command_op = write_data[15:0];

end


`RTLGEN_CAFU_CSR0_CFG_EN_FF_SYNCRST(gated_clk, cxl_or_conv_rst_n, 8'h0, up_CXL_MB_CMD_command_op[0], nxt_CXL_MB_CMD_command_op[7:0], CXL_MB_CMD.command_op[7:0])
`RTLGEN_CAFU_CSR0_CFG_EN_FF_SYNCRST(gated_clk, cxl_or_conv_rst_n, 8'h0, up_CXL_MB_CMD_command_op[1], nxt_CXL_MB_CMD_command_op[15:8], CXL_MB_CMD.command_op[15:8])

// ----------------------------------------------------------------------
// CXL_MB_CMD.payload_len x5 RW/V, using RW/V template.
logic [2:0] req_up_CXL_MB_CMD_payload_len;
always_comb begin
 req_up_CXL_MB_CMD_payload_len[0] = 
   {write_req_CXL_MB_CMD & be[2]}
;
 req_up_CXL_MB_CMD_payload_len[1] = 
   {write_req_CXL_MB_CMD & be[3]}
;
 req_up_CXL_MB_CMD_payload_len[2] = 
   {write_req_CXL_MB_CMD & be[4]}
;
end

logic [2:0] swwr_CXL_MB_CMD_payload_len;
always_comb begin
 swwr_CXL_MB_CMD_payload_len = req_up_CXL_MB_CMD_payload_len;

end


logic [2:0] up_CXL_MB_CMD_payload_len;
logic [20:0] nxt_CXL_MB_CMD_payload_len;
always_comb begin
 up_CXL_MB_CMD_payload_len =
    swwr_CXL_MB_CMD_payload_len |
    {3{load_CXL_MB_CMD.payload_len}};
end
always_comb begin
 nxt_CXL_MB_CMD_payload_len[7:0] = 
    swwr_CXL_MB_CMD_payload_len[0] ?
    write_data[23:16] :
    new_CXL_MB_CMD.payload_len[7:0];
 nxt_CXL_MB_CMD_payload_len[15:8] = 
    swwr_CXL_MB_CMD_payload_len[1] ?
    write_data[31:24] :
    new_CXL_MB_CMD.payload_len[15:8];
 nxt_CXL_MB_CMD_payload_len[20:16] = 
    swwr_CXL_MB_CMD_payload_len[2] ?
    write_data[36:32] :
    new_CXL_MB_CMD.payload_len[20:16];
end

`RTLGEN_CAFU_CSR0_CFG_EN_FF_SYNCRST(rtl_clk, cxl_or_conv_rst_n, 8'h0, up_CXL_MB_CMD_payload_len[0], nxt_CXL_MB_CMD_payload_len[7:0], CXL_MB_CMD.payload_len[7:0])
`RTLGEN_CAFU_CSR0_CFG_EN_FF_SYNCRST(rtl_clk, cxl_or_conv_rst_n, 8'h0, up_CXL_MB_CMD_payload_len[1], nxt_CXL_MB_CMD_payload_len[15:8], CXL_MB_CMD.payload_len[15:8])
`RTLGEN_CAFU_CSR0_CFG_EN_FF_SYNCRST(rtl_clk, cxl_or_conv_rst_n, 5'h0, up_CXL_MB_CMD_payload_len[2], nxt_CXL_MB_CMD_payload_len[20:16], CXL_MB_CMD.payload_len[20:16])

//---------------------------------------------------------------------
// CXL_MB_STATUS Address Decode
// ----------------------------------------------------------------------
// CXL_MB_STATUS.bk_operation x1 RO/V, using RO/V template.
assign CXL_MB_STATUS.bk_operation = new_CXL_MB_STATUS.bk_operation;



// ----------------------------------------------------------------------
// CXL_MB_STATUS.return_code x8 RO/V, using RO/V template.
assign CXL_MB_STATUS.return_code = new_CXL_MB_STATUS.return_code;



// ----------------------------------------------------------------------
// CXL_MB_STATUS.vendor_specfic_ext_status x8 RO/V, using RO/V template.
assign CXL_MB_STATUS.vendor_specfic_ext_status = new_CXL_MB_STATUS.vendor_specfic_ext_status;




//---------------------------------------------------------------------
// CXL_MB_BK_CMD_STATUS Address Decode
// ----------------------------------------------------------------------
// CXL_MB_BK_CMD_STATUS.cmd_opcode x8 RO/V, using RO/V template.
assign CXL_MB_BK_CMD_STATUS.cmd_opcode = new_CXL_MB_BK_CMD_STATUS.cmd_opcode;



// ----------------------------------------------------------------------
// CXL_MB_BK_CMD_STATUS.percentage_comp x7 RO/V, using RO/V template.
assign CXL_MB_BK_CMD_STATUS.percentage_comp = new_CXL_MB_BK_CMD_STATUS.percentage_comp;



// ----------------------------------------------------------------------
// CXL_MB_BK_CMD_STATUS.return_code x8 RO/V, using RO/V template.
assign CXL_MB_BK_CMD_STATUS.return_code = new_CXL_MB_BK_CMD_STATUS.return_code;



// ----------------------------------------------------------------------
// CXL_MB_BK_CMD_STATUS.vendor_specfic_ext_status x8 RO/V, using RO/V template.
assign CXL_MB_BK_CMD_STATUS.vendor_specfic_ext_status = new_CXL_MB_BK_CMD_STATUS.vendor_specfic_ext_status;




//---------------------------------------------------------------------
// CXL_MB_PAY_START Address Decode
logic  addr_decode_CXL_MB_PAY_START;
logic  write_req_CXL_MB_PAY_START;
always_comb begin
   addr_decode_CXL_MB_PAY_START = (req_addr[CAFU_CSR0_CFG_MEM_ADDR_MSB:ADDR_LSB_BUS_ALIGN] == CXL_MB_PAY_START_DECODE_ADDR) && req.valid ;
   write_req_CXL_MB_PAY_START = IsMEMWr && addr_decode_CXL_MB_PAY_START && sb_fid_cond_mem_inst_sb && sb_bar_cond_mem_inst_sb;
end

// ----------------------------------------------------------------------
// CXL_MB_PAY_START.mailbox_payload_start x8 RW, using RW template.
logic [3:0] up_CXL_MB_PAY_START_mailbox_payload_start;
always_comb begin
 up_CXL_MB_PAY_START_mailbox_payload_start =
    ({4{write_req_CXL_MB_PAY_START }} &
    be[3:0]);
end

logic [31:0] nxt_CXL_MB_PAY_START_mailbox_payload_start;
always_comb begin
 nxt_CXL_MB_PAY_START_mailbox_payload_start = write_data[31:0];

end


`RTLGEN_CAFU_CSR0_CFG_EN_FF_SYNCRST(gated_clk, cxl_or_conv_rst_n, 8'h0, up_CXL_MB_PAY_START_mailbox_payload_start[0], nxt_CXL_MB_PAY_START_mailbox_payload_start[7:0], CXL_MB_PAY_START.mailbox_payload_start[7:0])
`RTLGEN_CAFU_CSR0_CFG_EN_FF_SYNCRST(gated_clk, cxl_or_conv_rst_n, 8'h0, up_CXL_MB_PAY_START_mailbox_payload_start[1], nxt_CXL_MB_PAY_START_mailbox_payload_start[15:8], CXL_MB_PAY_START.mailbox_payload_start[15:8])
`RTLGEN_CAFU_CSR0_CFG_EN_FF_SYNCRST(gated_clk, cxl_or_conv_rst_n, 8'h0, up_CXL_MB_PAY_START_mailbox_payload_start[2], nxt_CXL_MB_PAY_START_mailbox_payload_start[23:16], CXL_MB_PAY_START.mailbox_payload_start[23:16])
`RTLGEN_CAFU_CSR0_CFG_EN_FF_SYNCRST(gated_clk, cxl_or_conv_rst_n, 8'h0, up_CXL_MB_PAY_START_mailbox_payload_start[3], nxt_CXL_MB_PAY_START_mailbox_payload_start[31:24], CXL_MB_PAY_START.mailbox_payload_start[31:24])

//---------------------------------------------------------------------
// CXL_MB_PAY_END Address Decode
logic  addr_decode_CXL_MB_PAY_END;
logic  write_req_CXL_MB_PAY_END;
always_comb begin
   addr_decode_CXL_MB_PAY_END = (req_addr[CAFU_CSR0_CFG_MEM_ADDR_MSB:ADDR_LSB_BUS_ALIGN] == CXL_MB_PAY_END_DECODE_ADDR) && req.valid ;
   write_req_CXL_MB_PAY_END = IsMEMWr && addr_decode_CXL_MB_PAY_END && sb_fid_cond_mem_inst_sb && sb_bar_cond_mem_inst_sb;
end

// ----------------------------------------------------------------------
// CXL_MB_PAY_END.mailbox_payload_end x8 RW, using RW template.
logic [3:0] up_CXL_MB_PAY_END_mailbox_payload_end;
always_comb begin
 up_CXL_MB_PAY_END_mailbox_payload_end =
    ({4{write_req_CXL_MB_PAY_END }} &
    be[7:4]);
end

logic [31:0] nxt_CXL_MB_PAY_END_mailbox_payload_end;
always_comb begin
 nxt_CXL_MB_PAY_END_mailbox_payload_end = write_data[63:32];

end


`RTLGEN_CAFU_CSR0_CFG_EN_FF_SYNCRST(gated_clk, cxl_or_conv_rst_n, 8'h0, up_CXL_MB_PAY_END_mailbox_payload_end[0], nxt_CXL_MB_PAY_END_mailbox_payload_end[7:0], CXL_MB_PAY_END.mailbox_payload_end[7:0])
`RTLGEN_CAFU_CSR0_CFG_EN_FF_SYNCRST(gated_clk, cxl_or_conv_rst_n, 8'h0, up_CXL_MB_PAY_END_mailbox_payload_end[1], nxt_CXL_MB_PAY_END_mailbox_payload_end[15:8], CXL_MB_PAY_END.mailbox_payload_end[15:8])
`RTLGEN_CAFU_CSR0_CFG_EN_FF_SYNCRST(gated_clk, cxl_or_conv_rst_n, 8'h0, up_CXL_MB_PAY_END_mailbox_payload_end[2], nxt_CXL_MB_PAY_END_mailbox_payload_end[23:16], CXL_MB_PAY_END.mailbox_payload_end[23:16])
`RTLGEN_CAFU_CSR0_CFG_EN_FF_SYNCRST(gated_clk, cxl_or_conv_rst_n, 8'h0, up_CXL_MB_PAY_END_mailbox_payload_end[3], nxt_CXL_MB_PAY_END_mailbox_payload_end[31:24], CXL_MB_PAY_END.mailbox_payload_end[31:24])

//---------------------------------------------------------------------
// HDM_DEC_CAP Address Decode

// ----------------------------------------------------------------------
// HDM_DEC_CAP.dec_cnt x4 RO, using RO template.
assign HDM_DEC_CAP.dec_cnt = 4'h0;



// ----------------------------------------------------------------------
// HDM_DEC_CAP.tgt_cnt x4 RO, using RO template.
assign HDM_DEC_CAP.tgt_cnt = 4'h0;



// ----------------------------------------------------------------------
// HDM_DEC_CAP.addr11_8 x1 RO, using RO template.
assign HDM_DEC_CAP.addr11_8 = 1'h0;



// ----------------------------------------------------------------------
// HDM_DEC_CAP.addr14_12 x1 RO, using RO template.
assign HDM_DEC_CAP.addr14_12 = 1'h0;



// ----------------------------------------------------------------------
// HDM_DEC_CAP.poison_on_err x1 RO, using RO template.
assign HDM_DEC_CAP.poison_on_err = 1'h0;



// ----------------------------------------------------------------------
// HDM_DEC_CAP.support_3_6_12_way x1 RO, using RO template.
assign HDM_DEC_CAP.support_3_6_12_way = 1'h0;



// ----------------------------------------------------------------------
// HDM_DEC_CAP.support_16_way x1 RO, using RO template.
assign HDM_DEC_CAP.support_16_way = 1'h0;



//---------------------------------------------------------------------
// HDM_DEC_GBL_CTRL Address Decode
logic  addr_decode_HDM_DEC_GBL_CTRL;
logic  write_req_HDM_DEC_GBL_CTRL;
always_comb begin
   addr_decode_HDM_DEC_GBL_CTRL = (req_addr[CAFU_CSR0_CFG_MEM_ADDR_MSB:ADDR_LSB_BUS_ALIGN] == HDM_DEC_GBL_CTRL_DECODE_ADDR) && req.valid ;
   write_req_HDM_DEC_GBL_CTRL = IsMEMWr && addr_decode_HDM_DEC_GBL_CTRL && sb_fid_cond_mem_inst_sb && sb_bar_cond_mem_inst_sb;
end

// ----------------------------------------------------------------------
// HDM_DEC_GBL_CTRL.poison_on_err_enable x1 RO, using RO template.
assign HDM_DEC_GBL_CTRL.poison_on_err_enable = 1'h0;



// ----------------------------------------------------------------------
// HDM_DEC_GBL_CTRL.dec_enable x1 RW, using RW template.
logic [0:0] up_HDM_DEC_GBL_CTRL_dec_enable;
always_comb begin
 up_HDM_DEC_GBL_CTRL_dec_enable =
    ({1{write_req_HDM_DEC_GBL_CTRL }} &
    be[4:4]);
end

logic [0:0] nxt_HDM_DEC_GBL_CTRL_dec_enable;
always_comb begin
 nxt_HDM_DEC_GBL_CTRL_dec_enable = write_data[33:33];

end


`RTLGEN_CAFU_CSR0_CFG_EN_FF_SYNCRST(gated_clk, cxl_or_conv_rst_n, 1'h0, up_HDM_DEC_GBL_CTRL_dec_enable[0], nxt_HDM_DEC_GBL_CTRL_dec_enable[0:0], HDM_DEC_GBL_CTRL.dec_enable[0:0])

//---------------------------------------------------------------------
// HDM_DEC_BASELOW Address Decode
logic  addr_decode_HDM_DEC_BASELOW;
logic  write_req_HDM_DEC_BASELOW;
always_comb begin
   addr_decode_HDM_DEC_BASELOW = (req_addr[CAFU_CSR0_CFG_MEM_ADDR_MSB:ADDR_LSB_BUS_ALIGN] == HDM_DEC_BASELOW_DECODE_ADDR) && req.valid ;
   write_req_HDM_DEC_BASELOW = IsMEMWr && addr_decode_HDM_DEC_BASELOW && sb_fid_cond_mem_inst_sb && sb_bar_cond_mem_inst_sb;
end

// ----------------------------------------------------------------------
// HDM_DEC_BASELOW.mem_base_low x4 RW/L, using RW/L template.
logic [0:0] req_up_HDM_DEC_BASELOW_mem_base_low;
always_comb begin
 req_up_HDM_DEC_BASELOW_mem_base_low[0] = 
   {write_req_HDM_DEC_BASELOW & be[3]}
;
end



logic [0:0] up_HDM_DEC_BASELOW_mem_base_low;
always_comb begin
 up_HDM_DEC_BASELOW_mem_base_low = 
   (req_up_HDM_DEC_BASELOW_mem_base_low & {1{~(lock_HDM_DEC_BASELOW.mem_base_low)}});

end


logic [3:0] nxt_HDM_DEC_BASELOW_mem_base_low;
always_comb begin
 nxt_HDM_DEC_BASELOW_mem_base_low = write_data[31:28];

end
`RTLGEN_CAFU_CSR0_CFG_EN_FF(gated_clk, rst_n, 4'h0, up_HDM_DEC_BASELOW_mem_base_low[0], nxt_HDM_DEC_BASELOW_mem_base_low[3:0], HDM_DEC_BASELOW.mem_base_low[3:0])

//---------------------------------------------------------------------
// HDM_DEC_BASEHIGH Address Decode
logic  addr_decode_HDM_DEC_BASEHIGH;
logic  write_req_HDM_DEC_BASEHIGH;
always_comb begin
   addr_decode_HDM_DEC_BASEHIGH = (req_addr[CAFU_CSR0_CFG_MEM_ADDR_MSB:ADDR_LSB_BUS_ALIGN] == HDM_DEC_BASEHIGH_DECODE_ADDR) && req.valid ;
   write_req_HDM_DEC_BASEHIGH = IsMEMWr && addr_decode_HDM_DEC_BASEHIGH && sb_fid_cond_mem_inst_sb && sb_bar_cond_mem_inst_sb;
end

// ----------------------------------------------------------------------
// HDM_DEC_BASEHIGH.mem_base_high x8 RW/L, using RW/L template.
logic [3:0] req_up_HDM_DEC_BASEHIGH_mem_base_high;
always_comb begin
 req_up_HDM_DEC_BASEHIGH_mem_base_high[0] = 
   {write_req_HDM_DEC_BASEHIGH & be[4]}
;
 req_up_HDM_DEC_BASEHIGH_mem_base_high[1] = 
   {write_req_HDM_DEC_BASEHIGH & be[5]}
;
 req_up_HDM_DEC_BASEHIGH_mem_base_high[2] = 
   {write_req_HDM_DEC_BASEHIGH & be[6]}
;
 req_up_HDM_DEC_BASEHIGH_mem_base_high[3] = 
   {write_req_HDM_DEC_BASEHIGH & be[7]}
;
end



logic [3:0] up_HDM_DEC_BASEHIGH_mem_base_high;
always_comb begin
 up_HDM_DEC_BASEHIGH_mem_base_high = 
   (req_up_HDM_DEC_BASEHIGH_mem_base_high & {4{~(lock_HDM_DEC_BASEHIGH.mem_base_high)}});

end


logic [31:0] nxt_HDM_DEC_BASEHIGH_mem_base_high;
always_comb begin
 nxt_HDM_DEC_BASEHIGH_mem_base_high = write_data[63:32];

end
`RTLGEN_CAFU_CSR0_CFG_EN_FF(gated_clk, rst_n, 8'h0, up_HDM_DEC_BASEHIGH_mem_base_high[0], nxt_HDM_DEC_BASEHIGH_mem_base_high[7:0], HDM_DEC_BASEHIGH.mem_base_high[7:0])
`RTLGEN_CAFU_CSR0_CFG_EN_FF(gated_clk, rst_n, 8'h0, up_HDM_DEC_BASEHIGH_mem_base_high[1], nxt_HDM_DEC_BASEHIGH_mem_base_high[15:8], HDM_DEC_BASEHIGH.mem_base_high[15:8])
`RTLGEN_CAFU_CSR0_CFG_EN_FF(gated_clk, rst_n, 8'h0, up_HDM_DEC_BASEHIGH_mem_base_high[2], nxt_HDM_DEC_BASEHIGH_mem_base_high[23:16], HDM_DEC_BASEHIGH.mem_base_high[23:16])
`RTLGEN_CAFU_CSR0_CFG_EN_FF(gated_clk, rst_n, 8'h0, up_HDM_DEC_BASEHIGH_mem_base_high[3], nxt_HDM_DEC_BASEHIGH_mem_base_high[31:24], HDM_DEC_BASEHIGH.mem_base_high[31:24])

//---------------------------------------------------------------------
// HDM_DEC_SIZELOW Address Decode
logic  addr_decode_HDM_DEC_SIZELOW;
logic  write_req_HDM_DEC_SIZELOW;
always_comb begin
   addr_decode_HDM_DEC_SIZELOW = (req_addr[CAFU_CSR0_CFG_MEM_ADDR_MSB:ADDR_LSB_BUS_ALIGN] == HDM_DEC_SIZELOW_DECODE_ADDR) && req.valid ;
   write_req_HDM_DEC_SIZELOW = IsMEMWr && addr_decode_HDM_DEC_SIZELOW && sb_fid_cond_mem_inst_sb && sb_bar_cond_mem_inst_sb;
end

// ----------------------------------------------------------------------
// HDM_DEC_SIZELOW.mem_size_low x4 RW/L, using RW/L template.
logic [0:0] req_up_HDM_DEC_SIZELOW_mem_size_low;
always_comb begin
 req_up_HDM_DEC_SIZELOW_mem_size_low[0] = 
   {write_req_HDM_DEC_SIZELOW & be[3]}
;
end



logic [0:0] up_HDM_DEC_SIZELOW_mem_size_low;
always_comb begin
 up_HDM_DEC_SIZELOW_mem_size_low = 
   (req_up_HDM_DEC_SIZELOW_mem_size_low & {1{~(lock_HDM_DEC_SIZELOW.mem_size_low)}});

end


logic [3:0] nxt_HDM_DEC_SIZELOW_mem_size_low;
always_comb begin
 nxt_HDM_DEC_SIZELOW_mem_size_low = write_data[31:28];

end
`RTLGEN_CAFU_CSR0_CFG_EN_FF(gated_clk, rst_n, 4'h0, up_HDM_DEC_SIZELOW_mem_size_low[0], nxt_HDM_DEC_SIZELOW_mem_size_low[3:0], HDM_DEC_SIZELOW.mem_size_low[3:0])

//---------------------------------------------------------------------
// HDM_DEC_SIZEHIGH Address Decode
logic  addr_decode_HDM_DEC_SIZEHIGH;
logic  write_req_HDM_DEC_SIZEHIGH;
always_comb begin
   addr_decode_HDM_DEC_SIZEHIGH = (req_addr[CAFU_CSR0_CFG_MEM_ADDR_MSB:ADDR_LSB_BUS_ALIGN] == HDM_DEC_SIZEHIGH_DECODE_ADDR) && req.valid ;
   write_req_HDM_DEC_SIZEHIGH = IsMEMWr && addr_decode_HDM_DEC_SIZEHIGH && sb_fid_cond_mem_inst_sb && sb_bar_cond_mem_inst_sb;
end

// ----------------------------------------------------------------------
// HDM_DEC_SIZEHIGH.mem_size_high x8 RW/L, using RW/L template.
logic [3:0] req_up_HDM_DEC_SIZEHIGH_mem_size_high;
always_comb begin
 req_up_HDM_DEC_SIZEHIGH_mem_size_high[0] = 
   {write_req_HDM_DEC_SIZEHIGH & be[4]}
;
 req_up_HDM_DEC_SIZEHIGH_mem_size_high[1] = 
   {write_req_HDM_DEC_SIZEHIGH & be[5]}
;
 req_up_HDM_DEC_SIZEHIGH_mem_size_high[2] = 
   {write_req_HDM_DEC_SIZEHIGH & be[6]}
;
 req_up_HDM_DEC_SIZEHIGH_mem_size_high[3] = 
   {write_req_HDM_DEC_SIZEHIGH & be[7]}
;
end



logic [3:0] up_HDM_DEC_SIZEHIGH_mem_size_high;
always_comb begin
 up_HDM_DEC_SIZEHIGH_mem_size_high = 
   (req_up_HDM_DEC_SIZEHIGH_mem_size_high & {4{~(lock_HDM_DEC_SIZEHIGH.mem_size_high)}});

end


logic [31:0] nxt_HDM_DEC_SIZEHIGH_mem_size_high;
always_comb begin
 nxt_HDM_DEC_SIZEHIGH_mem_size_high = write_data[63:32];

end
`RTLGEN_CAFU_CSR0_CFG_EN_FF(gated_clk, rst_n, 8'h0, up_HDM_DEC_SIZEHIGH_mem_size_high[0], nxt_HDM_DEC_SIZEHIGH_mem_size_high[7:0], HDM_DEC_SIZEHIGH.mem_size_high[7:0])
`RTLGEN_CAFU_CSR0_CFG_EN_FF(gated_clk, rst_n, 8'h0, up_HDM_DEC_SIZEHIGH_mem_size_high[1], nxt_HDM_DEC_SIZEHIGH_mem_size_high[15:8], HDM_DEC_SIZEHIGH.mem_size_high[15:8])
`RTLGEN_CAFU_CSR0_CFG_EN_FF(gated_clk, rst_n, 8'h0, up_HDM_DEC_SIZEHIGH_mem_size_high[2], nxt_HDM_DEC_SIZEHIGH_mem_size_high[23:16], HDM_DEC_SIZEHIGH.mem_size_high[23:16])
`RTLGEN_CAFU_CSR0_CFG_EN_FF(gated_clk, rst_n, 8'h0, up_HDM_DEC_SIZEHIGH_mem_size_high[3], nxt_HDM_DEC_SIZEHIGH_mem_size_high[31:24], HDM_DEC_SIZEHIGH.mem_size_high[31:24])

//---------------------------------------------------------------------
// HDM_DEC_CTRL Address Decode
logic  addr_decode_HDM_DEC_CTRL;
logic  write_req_HDM_DEC_CTRL;
always_comb begin
   addr_decode_HDM_DEC_CTRL = (req_addr[CAFU_CSR0_CFG_MEM_ADDR_MSB:ADDR_LSB_BUS_ALIGN] == HDM_DEC_CTRL_DECODE_ADDR) && req.valid ;
   write_req_HDM_DEC_CTRL = IsMEMWr && addr_decode_HDM_DEC_CTRL && sb_fid_cond_mem_inst_sb && sb_bar_cond_mem_inst_sb;
end

// ----------------------------------------------------------------------
// HDM_DEC_CTRL.interleave_granularity x4 RW/L, using RW/L template.
logic [0:0] req_up_HDM_DEC_CTRL_interleave_granularity;
always_comb begin
 req_up_HDM_DEC_CTRL_interleave_granularity[0] = 
   {write_req_HDM_DEC_CTRL & be[0]}
;
end



logic [0:0] up_HDM_DEC_CTRL_interleave_granularity;
always_comb begin
 up_HDM_DEC_CTRL_interleave_granularity = 
   (req_up_HDM_DEC_CTRL_interleave_granularity & {1{~(lock_HDM_DEC_CTRL.interleave_granularity)}});

end


logic [3:0] nxt_HDM_DEC_CTRL_interleave_granularity;
always_comb begin
 nxt_HDM_DEC_CTRL_interleave_granularity = write_data[3:0];

end
`RTLGEN_CAFU_CSR0_CFG_EN_FF(gated_clk, rst_n, 4'h0, up_HDM_DEC_CTRL_interleave_granularity[0], nxt_HDM_DEC_CTRL_interleave_granularity[3:0], HDM_DEC_CTRL.interleave_granularity[3:0])

// ----------------------------------------------------------------------
// HDM_DEC_CTRL.interleave_ways x4 RW/L, using RW/L template.
logic [0:0] req_up_HDM_DEC_CTRL_interleave_ways;
always_comb begin
 req_up_HDM_DEC_CTRL_interleave_ways[0] = 
   {write_req_HDM_DEC_CTRL & be[0]}
;
end



logic [0:0] up_HDM_DEC_CTRL_interleave_ways;
always_comb begin
 up_HDM_DEC_CTRL_interleave_ways = 
   (req_up_HDM_DEC_CTRL_interleave_ways & {1{~(lock_HDM_DEC_CTRL.interleave_ways)}});

end


logic [3:0] nxt_HDM_DEC_CTRL_interleave_ways;
always_comb begin
 nxt_HDM_DEC_CTRL_interleave_ways = write_data[7:4];

end
`RTLGEN_CAFU_CSR0_CFG_EN_FF(gated_clk, rst_n, 4'h0, up_HDM_DEC_CTRL_interleave_ways[0], nxt_HDM_DEC_CTRL_interleave_ways[3:0], HDM_DEC_CTRL.interleave_ways[3:0])

// ----------------------------------------------------------------------
// HDM_DEC_CTRL.lock_on_commit x1 RW/L, using RW/L template.
logic [0:0] req_up_HDM_DEC_CTRL_lock_on_commit;
always_comb begin
 req_up_HDM_DEC_CTRL_lock_on_commit[0] = 
   {write_req_HDM_DEC_CTRL & be[1]}
;
end



logic [0:0] up_HDM_DEC_CTRL_lock_on_commit;
always_comb begin
 up_HDM_DEC_CTRL_lock_on_commit = 
   (req_up_HDM_DEC_CTRL_lock_on_commit & {1{~(lock_HDM_DEC_CTRL.lock_on_commit)}});

end


logic [0:0] nxt_HDM_DEC_CTRL_lock_on_commit;
always_comb begin
 nxt_HDM_DEC_CTRL_lock_on_commit = write_data[8:8];

end
`RTLGEN_CAFU_CSR0_CFG_EN_FF(gated_clk, rst_n, 1'h0, up_HDM_DEC_CTRL_lock_on_commit[0], nxt_HDM_DEC_CTRL_lock_on_commit[0:0], HDM_DEC_CTRL.lock_on_commit[0:0])

// ----------------------------------------------------------------------
// HDM_DEC_CTRL.commit x1 RW/L, using RW/L template.
logic [0:0] req_up_HDM_DEC_CTRL_commit;
always_comb begin
 req_up_HDM_DEC_CTRL_commit[0] = 
   {write_req_HDM_DEC_CTRL & be[1]}
;
end



logic [0:0] up_HDM_DEC_CTRL_commit;
always_comb begin
 up_HDM_DEC_CTRL_commit = 
   (req_up_HDM_DEC_CTRL_commit & {1{~(lock_HDM_DEC_CTRL.commit)}});

end


logic [0:0] nxt_HDM_DEC_CTRL_commit;
always_comb begin
 nxt_HDM_DEC_CTRL_commit = write_data[9:9];

end
`RTLGEN_CAFU_CSR0_CFG_EN_FF(gated_clk, rst_n, 1'h0, up_HDM_DEC_CTRL_commit[0], nxt_HDM_DEC_CTRL_commit[0:0], HDM_DEC_CTRL.commit[0:0])
// ----------------------------------------------------------------------
// HDM_DEC_CTRL.committed x1 RO/V, using RO/V template.
assign HDM_DEC_CTRL.committed = new_HDM_DEC_CTRL.committed;




// ----------------------------------------------------------------------
// HDM_DEC_CTRL.err_not_committed x1 RO, using RO template.
assign HDM_DEC_CTRL.err_not_committed = 1'h0;



// ----------------------------------------------------------------------
// HDM_DEC_CTRL.target_dev_type x1 RW/L, using RW/L template.
logic [0:0] req_up_HDM_DEC_CTRL_target_dev_type;
always_comb begin
 req_up_HDM_DEC_CTRL_target_dev_type[0] = 
   {write_req_HDM_DEC_CTRL & be[1]}
;
end



logic [0:0] up_HDM_DEC_CTRL_target_dev_type;
always_comb begin
 up_HDM_DEC_CTRL_target_dev_type = 
   (req_up_HDM_DEC_CTRL_target_dev_type & {1{~(lock_HDM_DEC_CTRL.target_dev_type)}});

end


logic [0:0] nxt_HDM_DEC_CTRL_target_dev_type;
always_comb begin
 nxt_HDM_DEC_CTRL_target_dev_type = write_data[12:12];

end
`RTLGEN_CAFU_CSR0_CFG_EN_FF(gated_clk, rst_n, 1'h0, up_HDM_DEC_CTRL_target_dev_type[0], nxt_HDM_DEC_CTRL_target_dev_type[0:0], HDM_DEC_CTRL.target_dev_type[0:0])

//---------------------------------------------------------------------
// HDM_DEC_DPALOW Address Decode
logic  addr_decode_HDM_DEC_DPALOW;
logic  write_req_HDM_DEC_DPALOW;
always_comb begin
   addr_decode_HDM_DEC_DPALOW = (req_addr[CAFU_CSR0_CFG_MEM_ADDR_MSB:ADDR_LSB_BUS_ALIGN] == HDM_DEC_DPALOW_DECODE_ADDR) && req.valid ;
   write_req_HDM_DEC_DPALOW = IsMEMWr && addr_decode_HDM_DEC_DPALOW && sb_fid_cond_mem_inst_sb && sb_bar_cond_mem_inst_sb;
end

// ----------------------------------------------------------------------
// HDM_DEC_DPALOW.dpa_skip_low x4 RW/L, using RW/L template.
logic [0:0] req_up_HDM_DEC_DPALOW_dpa_skip_low;
always_comb begin
 req_up_HDM_DEC_DPALOW_dpa_skip_low[0] = 
   {write_req_HDM_DEC_DPALOW & be[7]}
;
end



logic [0:0] up_HDM_DEC_DPALOW_dpa_skip_low;
always_comb begin
 up_HDM_DEC_DPALOW_dpa_skip_low = 
   (req_up_HDM_DEC_DPALOW_dpa_skip_low & {1{~(lock_HDM_DEC_DPALOW.dpa_skip_low)}});

end


logic [3:0] nxt_HDM_DEC_DPALOW_dpa_skip_low;
always_comb begin
 nxt_HDM_DEC_DPALOW_dpa_skip_low = write_data[63:60];

end
`RTLGEN_CAFU_CSR0_CFG_EN_FF(gated_clk, rst_n, 4'h0, up_HDM_DEC_DPALOW_dpa_skip_low[0], nxt_HDM_DEC_DPALOW_dpa_skip_low[3:0], HDM_DEC_DPALOW.dpa_skip_low[3:0])

//---------------------------------------------------------------------
// HDM_DEC_DPAHIGH Address Decode
logic  addr_decode_HDM_DEC_DPAHIGH;
logic  write_req_HDM_DEC_DPAHIGH;
always_comb begin
   addr_decode_HDM_DEC_DPAHIGH = (req_addr[CAFU_CSR0_CFG_MEM_ADDR_MSB:ADDR_LSB_BUS_ALIGN] == HDM_DEC_DPAHIGH_DECODE_ADDR) && req.valid ;
   write_req_HDM_DEC_DPAHIGH = IsMEMWr && addr_decode_HDM_DEC_DPAHIGH && sb_fid_cond_mem_inst_sb && sb_bar_cond_mem_inst_sb;
end

// ----------------------------------------------------------------------
// HDM_DEC_DPAHIGH.dpa_skip_high x8 RW/L, using RW/L template.
logic [3:0] req_up_HDM_DEC_DPAHIGH_dpa_skip_high;
always_comb begin
 req_up_HDM_DEC_DPAHIGH_dpa_skip_high[0] = 
   {write_req_HDM_DEC_DPAHIGH & be[0]}
;
 req_up_HDM_DEC_DPAHIGH_dpa_skip_high[1] = 
   {write_req_HDM_DEC_DPAHIGH & be[1]}
;
 req_up_HDM_DEC_DPAHIGH_dpa_skip_high[2] = 
   {write_req_HDM_DEC_DPAHIGH & be[2]}
;
 req_up_HDM_DEC_DPAHIGH_dpa_skip_high[3] = 
   {write_req_HDM_DEC_DPAHIGH & be[3]}
;
end



logic [3:0] up_HDM_DEC_DPAHIGH_dpa_skip_high;
always_comb begin
 up_HDM_DEC_DPAHIGH_dpa_skip_high = 
   (req_up_HDM_DEC_DPAHIGH_dpa_skip_high & {4{~(lock_HDM_DEC_DPAHIGH.dpa_skip_high)}});

end


logic [31:0] nxt_HDM_DEC_DPAHIGH_dpa_skip_high;
always_comb begin
 nxt_HDM_DEC_DPAHIGH_dpa_skip_high = write_data[31:0];

end
`RTLGEN_CAFU_CSR0_CFG_EN_FF(gated_clk, rst_n, 8'h0, up_HDM_DEC_DPAHIGH_dpa_skip_high[0], nxt_HDM_DEC_DPAHIGH_dpa_skip_high[7:0], HDM_DEC_DPAHIGH.dpa_skip_high[7:0])
`RTLGEN_CAFU_CSR0_CFG_EN_FF(gated_clk, rst_n, 8'h0, up_HDM_DEC_DPAHIGH_dpa_skip_high[1], nxt_HDM_DEC_DPAHIGH_dpa_skip_high[15:8], HDM_DEC_DPAHIGH.dpa_skip_high[15:8])
`RTLGEN_CAFU_CSR0_CFG_EN_FF(gated_clk, rst_n, 8'h0, up_HDM_DEC_DPAHIGH_dpa_skip_high[2], nxt_HDM_DEC_DPAHIGH_dpa_skip_high[23:16], HDM_DEC_DPAHIGH.dpa_skip_high[23:16])
`RTLGEN_CAFU_CSR0_CFG_EN_FF(gated_clk, rst_n, 8'h0, up_HDM_DEC_DPAHIGH_dpa_skip_high[3], nxt_HDM_DEC_DPAHIGH_dpa_skip_high[31:24], HDM_DEC_DPAHIGH.dpa_skip_high[31:24])

//---------------------------------------------------------------------
// CONFIG_TEST_START_ADDR Address Decode
logic  addr_decode_CONFIG_TEST_START_ADDR;
logic  write_req_CONFIG_TEST_START_ADDR;
always_comb begin
   addr_decode_CONFIG_TEST_START_ADDR = (req_addr[CAFU_CSR0_CFG_MEM_ADDR_MSB:ADDR_LSB_BUS_ALIGN] == CONFIG_TEST_START_ADDR_DECODE_ADDR) && req.valid ;
   write_req_CONFIG_TEST_START_ADDR = IsMEMWr && addr_decode_CONFIG_TEST_START_ADDR && sb_fid_cond_mem_inst_sb && sb_bar_cond_mem_inst_sb;
end

// ----------------------------------------------------------------------
// CONFIG_TEST_START_ADDR.config_test_start_addr x4 RW, using RW template.
logic [6:0] up_CONFIG_TEST_START_ADDR_config_test_start_addr;
always_comb begin
 up_CONFIG_TEST_START_ADDR_config_test_start_addr =
    ({7{write_req_CONFIG_TEST_START_ADDR }} &
    be[6:0]);
end

logic [51:0] nxt_CONFIG_TEST_START_ADDR_config_test_start_addr;
always_comb begin
 nxt_CONFIG_TEST_START_ADDR_config_test_start_addr = write_data[51:0];

end


`RTLGEN_CAFU_CSR0_CFG_EN_FF_SYNCRST(gated_clk, cxl_or_conv_rst_n, 8'h0, up_CONFIG_TEST_START_ADDR_config_test_start_addr[0], nxt_CONFIG_TEST_START_ADDR_config_test_start_addr[7:0], CONFIG_TEST_START_ADDR.config_test_start_addr[7:0])
`RTLGEN_CAFU_CSR0_CFG_EN_FF_SYNCRST(gated_clk, cxl_or_conv_rst_n, 8'h0, up_CONFIG_TEST_START_ADDR_config_test_start_addr[1], nxt_CONFIG_TEST_START_ADDR_config_test_start_addr[15:8], CONFIG_TEST_START_ADDR.config_test_start_addr[15:8])
`RTLGEN_CAFU_CSR0_CFG_EN_FF_SYNCRST(gated_clk, cxl_or_conv_rst_n, 8'h0, up_CONFIG_TEST_START_ADDR_config_test_start_addr[2], nxt_CONFIG_TEST_START_ADDR_config_test_start_addr[23:16], CONFIG_TEST_START_ADDR.config_test_start_addr[23:16])
`RTLGEN_CAFU_CSR0_CFG_EN_FF_SYNCRST(gated_clk, cxl_or_conv_rst_n, 8'h0, up_CONFIG_TEST_START_ADDR_config_test_start_addr[3], nxt_CONFIG_TEST_START_ADDR_config_test_start_addr[31:24], CONFIG_TEST_START_ADDR.config_test_start_addr[31:24])
`RTLGEN_CAFU_CSR0_CFG_EN_FF_SYNCRST(gated_clk, cxl_or_conv_rst_n, 8'h0, up_CONFIG_TEST_START_ADDR_config_test_start_addr[4], nxt_CONFIG_TEST_START_ADDR_config_test_start_addr[39:32], CONFIG_TEST_START_ADDR.config_test_start_addr[39:32])
`RTLGEN_CAFU_CSR0_CFG_EN_FF_SYNCRST(gated_clk, cxl_or_conv_rst_n, 8'h0, up_CONFIG_TEST_START_ADDR_config_test_start_addr[5], nxt_CONFIG_TEST_START_ADDR_config_test_start_addr[47:40], CONFIG_TEST_START_ADDR.config_test_start_addr[47:40])
`RTLGEN_CAFU_CSR0_CFG_EN_FF_SYNCRST(gated_clk, cxl_or_conv_rst_n, 4'h0, up_CONFIG_TEST_START_ADDR_config_test_start_addr[6], nxt_CONFIG_TEST_START_ADDR_config_test_start_addr[51:48], CONFIG_TEST_START_ADDR.config_test_start_addr[51:48])

//---------------------------------------------------------------------
// CONFIG_TEST_WR_BACK_ADDR Address Decode
logic  addr_decode_CONFIG_TEST_WR_BACK_ADDR;
logic  write_req_CONFIG_TEST_WR_BACK_ADDR;
always_comb begin
   addr_decode_CONFIG_TEST_WR_BACK_ADDR = (req_addr[CAFU_CSR0_CFG_MEM_ADDR_MSB:ADDR_LSB_BUS_ALIGN] == CONFIG_TEST_WR_BACK_ADDR_DECODE_ADDR) && req.valid ;
   write_req_CONFIG_TEST_WR_BACK_ADDR = IsMEMWr && addr_decode_CONFIG_TEST_WR_BACK_ADDR && sb_fid_cond_mem_inst_sb && sb_bar_cond_mem_inst_sb;
end

// ----------------------------------------------------------------------
// CONFIG_TEST_WR_BACK_ADDR.config_test_wrback_addr x4 RW, using RW template.
logic [6:0] up_CONFIG_TEST_WR_BACK_ADDR_config_test_wrback_addr;
always_comb begin
 up_CONFIG_TEST_WR_BACK_ADDR_config_test_wrback_addr =
    ({7{write_req_CONFIG_TEST_WR_BACK_ADDR }} &
    be[6:0]);
end

logic [51:0] nxt_CONFIG_TEST_WR_BACK_ADDR_config_test_wrback_addr;
always_comb begin
 nxt_CONFIG_TEST_WR_BACK_ADDR_config_test_wrback_addr = write_data[51:0];

end


`RTLGEN_CAFU_CSR0_CFG_EN_FF_SYNCRST(gated_clk, cxl_or_conv_rst_n, 8'h0, up_CONFIG_TEST_WR_BACK_ADDR_config_test_wrback_addr[0], nxt_CONFIG_TEST_WR_BACK_ADDR_config_test_wrback_addr[7:0], CONFIG_TEST_WR_BACK_ADDR.config_test_wrback_addr[7:0])
`RTLGEN_CAFU_CSR0_CFG_EN_FF_SYNCRST(gated_clk, cxl_or_conv_rst_n, 8'h0, up_CONFIG_TEST_WR_BACK_ADDR_config_test_wrback_addr[1], nxt_CONFIG_TEST_WR_BACK_ADDR_config_test_wrback_addr[15:8], CONFIG_TEST_WR_BACK_ADDR.config_test_wrback_addr[15:8])
`RTLGEN_CAFU_CSR0_CFG_EN_FF_SYNCRST(gated_clk, cxl_or_conv_rst_n, 8'h0, up_CONFIG_TEST_WR_BACK_ADDR_config_test_wrback_addr[2], nxt_CONFIG_TEST_WR_BACK_ADDR_config_test_wrback_addr[23:16], CONFIG_TEST_WR_BACK_ADDR.config_test_wrback_addr[23:16])
`RTLGEN_CAFU_CSR0_CFG_EN_FF_SYNCRST(gated_clk, cxl_or_conv_rst_n, 8'h0, up_CONFIG_TEST_WR_BACK_ADDR_config_test_wrback_addr[3], nxt_CONFIG_TEST_WR_BACK_ADDR_config_test_wrback_addr[31:24], CONFIG_TEST_WR_BACK_ADDR.config_test_wrback_addr[31:24])
`RTLGEN_CAFU_CSR0_CFG_EN_FF_SYNCRST(gated_clk, cxl_or_conv_rst_n, 8'h0, up_CONFIG_TEST_WR_BACK_ADDR_config_test_wrback_addr[4], nxt_CONFIG_TEST_WR_BACK_ADDR_config_test_wrback_addr[39:32], CONFIG_TEST_WR_BACK_ADDR.config_test_wrback_addr[39:32])
`RTLGEN_CAFU_CSR0_CFG_EN_FF_SYNCRST(gated_clk, cxl_or_conv_rst_n, 8'h0, up_CONFIG_TEST_WR_BACK_ADDR_config_test_wrback_addr[5], nxt_CONFIG_TEST_WR_BACK_ADDR_config_test_wrback_addr[47:40], CONFIG_TEST_WR_BACK_ADDR.config_test_wrback_addr[47:40])
`RTLGEN_CAFU_CSR0_CFG_EN_FF_SYNCRST(gated_clk, cxl_or_conv_rst_n, 4'h0, up_CONFIG_TEST_WR_BACK_ADDR_config_test_wrback_addr[6], nxt_CONFIG_TEST_WR_BACK_ADDR_config_test_wrback_addr[51:48], CONFIG_TEST_WR_BACK_ADDR.config_test_wrback_addr[51:48])

//---------------------------------------------------------------------
// CONFIG_TEST_ADDR_INCRE Address Decode
logic  addr_decode_CONFIG_TEST_ADDR_INCRE;
logic  write_req_CONFIG_TEST_ADDR_INCRE;
always_comb begin
   addr_decode_CONFIG_TEST_ADDR_INCRE = (req_addr[CAFU_CSR0_CFG_MEM_ADDR_MSB:ADDR_LSB_BUS_ALIGN] == CONFIG_TEST_ADDR_INCRE_DECODE_ADDR) && req.valid ;
   write_req_CONFIG_TEST_ADDR_INCRE = IsMEMWr && addr_decode_CONFIG_TEST_ADDR_INCRE && sb_fid_cond_mem_inst_sb && sb_bar_cond_mem_inst_sb;
end

// ----------------------------------------------------------------------
// CONFIG_TEST_ADDR_INCRE.config_test_addr_incre x8 RW, using RW template.
logic [3:0] up_CONFIG_TEST_ADDR_INCRE_config_test_addr_incre;
always_comb begin
 up_CONFIG_TEST_ADDR_INCRE_config_test_addr_incre =
    ({4{write_req_CONFIG_TEST_ADDR_INCRE }} &
    be[3:0]);
end

logic [31:0] nxt_CONFIG_TEST_ADDR_INCRE_config_test_addr_incre;
always_comb begin
 nxt_CONFIG_TEST_ADDR_INCRE_config_test_addr_incre = write_data[31:0];

end


`RTLGEN_CAFU_CSR0_CFG_EN_FF_SYNCRST(gated_clk, cxl_or_conv_rst_n, 8'h0, up_CONFIG_TEST_ADDR_INCRE_config_test_addr_incre[0], nxt_CONFIG_TEST_ADDR_INCRE_config_test_addr_incre[7:0], CONFIG_TEST_ADDR_INCRE.config_test_addr_incre[7:0])
`RTLGEN_CAFU_CSR0_CFG_EN_FF_SYNCRST(gated_clk, cxl_or_conv_rst_n, 8'h0, up_CONFIG_TEST_ADDR_INCRE_config_test_addr_incre[1], nxt_CONFIG_TEST_ADDR_INCRE_config_test_addr_incre[15:8], CONFIG_TEST_ADDR_INCRE.config_test_addr_incre[15:8])
`RTLGEN_CAFU_CSR0_CFG_EN_FF_SYNCRST(gated_clk, cxl_or_conv_rst_n, 8'h0, up_CONFIG_TEST_ADDR_INCRE_config_test_addr_incre[2], nxt_CONFIG_TEST_ADDR_INCRE_config_test_addr_incre[23:16], CONFIG_TEST_ADDR_INCRE.config_test_addr_incre[23:16])
`RTLGEN_CAFU_CSR0_CFG_EN_FF_SYNCRST(gated_clk, cxl_or_conv_rst_n, 8'h0, up_CONFIG_TEST_ADDR_INCRE_config_test_addr_incre[3], nxt_CONFIG_TEST_ADDR_INCRE_config_test_addr_incre[31:24], CONFIG_TEST_ADDR_INCRE.config_test_addr_incre[31:24])

// ----------------------------------------------------------------------
// CONFIG_TEST_ADDR_INCRE.config_test_addr_setoffset x8 RW, using RW template.
logic [3:0] up_CONFIG_TEST_ADDR_INCRE_config_test_addr_setoffset;
always_comb begin
 up_CONFIG_TEST_ADDR_INCRE_config_test_addr_setoffset =
    ({4{write_req_CONFIG_TEST_ADDR_INCRE }} &
    be[7:4]);
end

logic [31:0] nxt_CONFIG_TEST_ADDR_INCRE_config_test_addr_setoffset;
always_comb begin
 nxt_CONFIG_TEST_ADDR_INCRE_config_test_addr_setoffset = write_data[63:32];

end


`RTLGEN_CAFU_CSR0_CFG_EN_FF_SYNCRST(gated_clk, cxl_or_conv_rst_n, 8'h0, up_CONFIG_TEST_ADDR_INCRE_config_test_addr_setoffset[0], nxt_CONFIG_TEST_ADDR_INCRE_config_test_addr_setoffset[7:0], CONFIG_TEST_ADDR_INCRE.config_test_addr_setoffset[7:0])
`RTLGEN_CAFU_CSR0_CFG_EN_FF_SYNCRST(gated_clk, cxl_or_conv_rst_n, 8'h0, up_CONFIG_TEST_ADDR_INCRE_config_test_addr_setoffset[1], nxt_CONFIG_TEST_ADDR_INCRE_config_test_addr_setoffset[15:8], CONFIG_TEST_ADDR_INCRE.config_test_addr_setoffset[15:8])
`RTLGEN_CAFU_CSR0_CFG_EN_FF_SYNCRST(gated_clk, cxl_or_conv_rst_n, 8'h0, up_CONFIG_TEST_ADDR_INCRE_config_test_addr_setoffset[2], nxt_CONFIG_TEST_ADDR_INCRE_config_test_addr_setoffset[23:16], CONFIG_TEST_ADDR_INCRE.config_test_addr_setoffset[23:16])
`RTLGEN_CAFU_CSR0_CFG_EN_FF_SYNCRST(gated_clk, cxl_or_conv_rst_n, 8'h0, up_CONFIG_TEST_ADDR_INCRE_config_test_addr_setoffset[3], nxt_CONFIG_TEST_ADDR_INCRE_config_test_addr_setoffset[31:24], CONFIG_TEST_ADDR_INCRE.config_test_addr_setoffset[31:24])

//---------------------------------------------------------------------
// CONFIG_TEST_PATTERN Address Decode
logic  addr_decode_CONFIG_TEST_PATTERN;
logic  write_req_CONFIG_TEST_PATTERN;
always_comb begin
   addr_decode_CONFIG_TEST_PATTERN = (req_addr[CAFU_CSR0_CFG_MEM_ADDR_MSB:ADDR_LSB_BUS_ALIGN] == CONFIG_TEST_PATTERN_DECODE_ADDR) && req.valid ;
   write_req_CONFIG_TEST_PATTERN = IsMEMWr && addr_decode_CONFIG_TEST_PATTERN && sb_fid_cond_mem_inst_sb && sb_bar_cond_mem_inst_sb;
end

// ----------------------------------------------------------------------
// CONFIG_TEST_PATTERN.algorithm_pattern1 x8 RW, using RW template.
logic [3:0] up_CONFIG_TEST_PATTERN_algorithm_pattern1;
always_comb begin
 up_CONFIG_TEST_PATTERN_algorithm_pattern1 =
    ({4{write_req_CONFIG_TEST_PATTERN }} &
    be[3:0]);
end

logic [31:0] nxt_CONFIG_TEST_PATTERN_algorithm_pattern1;
always_comb begin
 nxt_CONFIG_TEST_PATTERN_algorithm_pattern1 = write_data[31:0];

end


`RTLGEN_CAFU_CSR0_CFG_EN_FF_SYNCRST(gated_clk, cxl_or_conv_rst_n, 8'h0, up_CONFIG_TEST_PATTERN_algorithm_pattern1[0], nxt_CONFIG_TEST_PATTERN_algorithm_pattern1[7:0], CONFIG_TEST_PATTERN.algorithm_pattern1[7:0])
`RTLGEN_CAFU_CSR0_CFG_EN_FF_SYNCRST(gated_clk, cxl_or_conv_rst_n, 8'h0, up_CONFIG_TEST_PATTERN_algorithm_pattern1[1], nxt_CONFIG_TEST_PATTERN_algorithm_pattern1[15:8], CONFIG_TEST_PATTERN.algorithm_pattern1[15:8])
`RTLGEN_CAFU_CSR0_CFG_EN_FF_SYNCRST(gated_clk, cxl_or_conv_rst_n, 8'h0, up_CONFIG_TEST_PATTERN_algorithm_pattern1[2], nxt_CONFIG_TEST_PATTERN_algorithm_pattern1[23:16], CONFIG_TEST_PATTERN.algorithm_pattern1[23:16])
`RTLGEN_CAFU_CSR0_CFG_EN_FF_SYNCRST(gated_clk, cxl_or_conv_rst_n, 8'h0, up_CONFIG_TEST_PATTERN_algorithm_pattern1[3], nxt_CONFIG_TEST_PATTERN_algorithm_pattern1[31:24], CONFIG_TEST_PATTERN.algorithm_pattern1[31:24])

// ----------------------------------------------------------------------
// CONFIG_TEST_PATTERN.algorithm_pattern2 x8 RW, using RW template.
logic [3:0] up_CONFIG_TEST_PATTERN_algorithm_pattern2;
always_comb begin
 up_CONFIG_TEST_PATTERN_algorithm_pattern2 =
    ({4{write_req_CONFIG_TEST_PATTERN }} &
    be[7:4]);
end

logic [31:0] nxt_CONFIG_TEST_PATTERN_algorithm_pattern2;
always_comb begin
 nxt_CONFIG_TEST_PATTERN_algorithm_pattern2 = write_data[63:32];

end


`RTLGEN_CAFU_CSR0_CFG_EN_FF_SYNCRST(gated_clk, cxl_or_conv_rst_n, 8'h0, up_CONFIG_TEST_PATTERN_algorithm_pattern2[0], nxt_CONFIG_TEST_PATTERN_algorithm_pattern2[7:0], CONFIG_TEST_PATTERN.algorithm_pattern2[7:0])
`RTLGEN_CAFU_CSR0_CFG_EN_FF_SYNCRST(gated_clk, cxl_or_conv_rst_n, 8'h0, up_CONFIG_TEST_PATTERN_algorithm_pattern2[1], nxt_CONFIG_TEST_PATTERN_algorithm_pattern2[15:8], CONFIG_TEST_PATTERN.algorithm_pattern2[15:8])
`RTLGEN_CAFU_CSR0_CFG_EN_FF_SYNCRST(gated_clk, cxl_or_conv_rst_n, 8'h0, up_CONFIG_TEST_PATTERN_algorithm_pattern2[2], nxt_CONFIG_TEST_PATTERN_algorithm_pattern2[23:16], CONFIG_TEST_PATTERN.algorithm_pattern2[23:16])
`RTLGEN_CAFU_CSR0_CFG_EN_FF_SYNCRST(gated_clk, cxl_or_conv_rst_n, 8'h0, up_CONFIG_TEST_PATTERN_algorithm_pattern2[3], nxt_CONFIG_TEST_PATTERN_algorithm_pattern2[31:24], CONFIG_TEST_PATTERN.algorithm_pattern2[31:24])

//---------------------------------------------------------------------
// CONFIG_TEST_BYTEMASK Address Decode
logic  addr_decode_CONFIG_TEST_BYTEMASK;
logic  write_req_CONFIG_TEST_BYTEMASK;
always_comb begin
   addr_decode_CONFIG_TEST_BYTEMASK = (req_addr[CAFU_CSR0_CFG_MEM_ADDR_MSB:ADDR_LSB_BUS_ALIGN] == CONFIG_TEST_BYTEMASK_DECODE_ADDR) && req.valid ;
   write_req_CONFIG_TEST_BYTEMASK = IsMEMWr && addr_decode_CONFIG_TEST_BYTEMASK && sb_fid_cond_mem_inst_sb && sb_bar_cond_mem_inst_sb;
end

// ----------------------------------------------------------------------
// CONFIG_TEST_BYTEMASK.cacheline_bytemask x8 RW, using RW template.
logic [7:0] up_CONFIG_TEST_BYTEMASK_cacheline_bytemask;
always_comb begin
 up_CONFIG_TEST_BYTEMASK_cacheline_bytemask =
    ({8{write_req_CONFIG_TEST_BYTEMASK }} &
    be[7:0]);
end

logic [63:0] nxt_CONFIG_TEST_BYTEMASK_cacheline_bytemask;
always_comb begin
 nxt_CONFIG_TEST_BYTEMASK_cacheline_bytemask = write_data[63:0];

end


`RTLGEN_CAFU_CSR0_CFG_EN_FF_SYNCRST(gated_clk, cxl_or_conv_rst_n, 8'h0, up_CONFIG_TEST_BYTEMASK_cacheline_bytemask[0], nxt_CONFIG_TEST_BYTEMASK_cacheline_bytemask[7:0], CONFIG_TEST_BYTEMASK.cacheline_bytemask[7:0])
`RTLGEN_CAFU_CSR0_CFG_EN_FF_SYNCRST(gated_clk, cxl_or_conv_rst_n, 8'h0, up_CONFIG_TEST_BYTEMASK_cacheline_bytemask[1], nxt_CONFIG_TEST_BYTEMASK_cacheline_bytemask[15:8], CONFIG_TEST_BYTEMASK.cacheline_bytemask[15:8])
`RTLGEN_CAFU_CSR0_CFG_EN_FF_SYNCRST(gated_clk, cxl_or_conv_rst_n, 8'h0, up_CONFIG_TEST_BYTEMASK_cacheline_bytemask[2], nxt_CONFIG_TEST_BYTEMASK_cacheline_bytemask[23:16], CONFIG_TEST_BYTEMASK.cacheline_bytemask[23:16])
`RTLGEN_CAFU_CSR0_CFG_EN_FF_SYNCRST(gated_clk, cxl_or_conv_rst_n, 8'h0, up_CONFIG_TEST_BYTEMASK_cacheline_bytemask[3], nxt_CONFIG_TEST_BYTEMASK_cacheline_bytemask[31:24], CONFIG_TEST_BYTEMASK.cacheline_bytemask[31:24])
`RTLGEN_CAFU_CSR0_CFG_EN_FF_SYNCRST(gated_clk, cxl_or_conv_rst_n, 8'h0, up_CONFIG_TEST_BYTEMASK_cacheline_bytemask[4], nxt_CONFIG_TEST_BYTEMASK_cacheline_bytemask[39:32], CONFIG_TEST_BYTEMASK.cacheline_bytemask[39:32])
`RTLGEN_CAFU_CSR0_CFG_EN_FF_SYNCRST(gated_clk, cxl_or_conv_rst_n, 8'h0, up_CONFIG_TEST_BYTEMASK_cacheline_bytemask[5], nxt_CONFIG_TEST_BYTEMASK_cacheline_bytemask[47:40], CONFIG_TEST_BYTEMASK.cacheline_bytemask[47:40])
`RTLGEN_CAFU_CSR0_CFG_EN_FF_SYNCRST(gated_clk, cxl_or_conv_rst_n, 8'h0, up_CONFIG_TEST_BYTEMASK_cacheline_bytemask[6], nxt_CONFIG_TEST_BYTEMASK_cacheline_bytemask[55:48], CONFIG_TEST_BYTEMASK.cacheline_bytemask[55:48])
`RTLGEN_CAFU_CSR0_CFG_EN_FF_SYNCRST(gated_clk, cxl_or_conv_rst_n, 8'h0, up_CONFIG_TEST_BYTEMASK_cacheline_bytemask[7], nxt_CONFIG_TEST_BYTEMASK_cacheline_bytemask[63:56], CONFIG_TEST_BYTEMASK.cacheline_bytemask[63:56])

//---------------------------------------------------------------------
// CONFIG_TEST_PATTERN_PARAM Address Decode
logic  addr_decode_CONFIG_TEST_PATTERN_PARAM;
logic  write_req_CONFIG_TEST_PATTERN_PARAM;
always_comb begin
   addr_decode_CONFIG_TEST_PATTERN_PARAM = (req_addr[CAFU_CSR0_CFG_MEM_ADDR_MSB:ADDR_LSB_BUS_ALIGN] == CONFIG_TEST_PATTERN_PARAM_DECODE_ADDR) && req.valid ;
   write_req_CONFIG_TEST_PATTERN_PARAM = IsMEMWr && addr_decode_CONFIG_TEST_PATTERN_PARAM && sb_fid_cond_mem_inst_sb && sb_bar_cond_mem_inst_sb;
end

// ----------------------------------------------------------------------
// CONFIG_TEST_PATTERN_PARAM.pattern_size x3 RW, using RW template.
logic [0:0] up_CONFIG_TEST_PATTERN_PARAM_pattern_size;
always_comb begin
 up_CONFIG_TEST_PATTERN_PARAM_pattern_size =
    ({1{write_req_CONFIG_TEST_PATTERN_PARAM }} &
    be[0:0]);
end

logic [2:0] nxt_CONFIG_TEST_PATTERN_PARAM_pattern_size;
always_comb begin
 nxt_CONFIG_TEST_PATTERN_PARAM_pattern_size = write_data[2:0];

end


`RTLGEN_CAFU_CSR0_CFG_EN_FF_SYNCRST(gated_clk, cxl_or_conv_rst_n, 3'h0, up_CONFIG_TEST_PATTERN_PARAM_pattern_size[0], nxt_CONFIG_TEST_PATTERN_PARAM_pattern_size[2:0], CONFIG_TEST_PATTERN_PARAM.pattern_size[2:0])

// ----------------------------------------------------------------------
// CONFIG_TEST_PATTERN_PARAM.pattern_parameter x1 RW, using RW template.
logic [0:0] up_CONFIG_TEST_PATTERN_PARAM_pattern_parameter;
always_comb begin
 up_CONFIG_TEST_PATTERN_PARAM_pattern_parameter =
    ({1{write_req_CONFIG_TEST_PATTERN_PARAM }} &
    be[0:0]);
end

logic [0:0] nxt_CONFIG_TEST_PATTERN_PARAM_pattern_parameter;
always_comb begin
 nxt_CONFIG_TEST_PATTERN_PARAM_pattern_parameter = write_data[3:3];

end


`RTLGEN_CAFU_CSR0_CFG_EN_FF_SYNCRST(gated_clk, cxl_or_conv_rst_n, 1'h0, up_CONFIG_TEST_PATTERN_PARAM_pattern_parameter[0], nxt_CONFIG_TEST_PATTERN_PARAM_pattern_parameter[0:0], CONFIG_TEST_PATTERN_PARAM.pattern_parameter[0:0])

//---------------------------------------------------------------------
// CONFIG_ALGO_SETTING Address Decode
logic  addr_decode_CONFIG_ALGO_SETTING;
logic  write_req_CONFIG_ALGO_SETTING;
always_comb begin
   addr_decode_CONFIG_ALGO_SETTING = (req_addr[CAFU_CSR0_CFG_MEM_ADDR_MSB:ADDR_LSB_BUS_ALIGN] == CONFIG_ALGO_SETTING_DECODE_ADDR) && req.valid ;
   write_req_CONFIG_ALGO_SETTING = IsMEMWr && addr_decode_CONFIG_ALGO_SETTING && sb_fid_cond_mem_inst_sb && sb_bar_cond_mem_inst_sb;
end

// ----------------------------------------------------------------------
// CONFIG_ALGO_SETTING.test_algorithm_type x3 RW/L, using RW/L template.
logic [0:0] req_up_CONFIG_ALGO_SETTING_test_algorithm_type;
always_comb begin
 req_up_CONFIG_ALGO_SETTING_test_algorithm_type[0] = 
   {write_req_CONFIG_ALGO_SETTING & be[0]}
;
end

logic  lock_lcl_CONFIG_ALGO_SETTING_test_algorithm_type;
always_comb begin
 lock_lcl_CONFIG_ALGO_SETTING_test_algorithm_type = ((CXL_DVSEC_TEST_LOCK.test_config_lock == 1'h1));
end

logic [0:0] up_CONFIG_ALGO_SETTING_test_algorithm_type;
always_comb begin
 up_CONFIG_ALGO_SETTING_test_algorithm_type = 
   (req_up_CONFIG_ALGO_SETTING_test_algorithm_type & {1{~lock_lcl_CONFIG_ALGO_SETTING_test_algorithm_type}});

end


logic [2:0] nxt_CONFIG_ALGO_SETTING_test_algorithm_type;
always_comb begin
 nxt_CONFIG_ALGO_SETTING_test_algorithm_type = write_data[2:0];

end
`RTLGEN_CAFU_CSR0_CFG_EN_FF(gated_clk, rst_n, 3'h0, up_CONFIG_ALGO_SETTING_test_algorithm_type[0], nxt_CONFIG_ALGO_SETTING_test_algorithm_type[2:0], CONFIG_ALGO_SETTING.test_algorithm_type[2:0])

// ----------------------------------------------------------------------
// CONFIG_ALGO_SETTING.device_selfchecking x1 RW, using RW template.
logic [0:0] up_CONFIG_ALGO_SETTING_device_selfchecking;
always_comb begin
 up_CONFIG_ALGO_SETTING_device_selfchecking =
    ({1{write_req_CONFIG_ALGO_SETTING }} &
    be[0:0]);
end

logic [0:0] nxt_CONFIG_ALGO_SETTING_device_selfchecking;
always_comb begin
 nxt_CONFIG_ALGO_SETTING_device_selfchecking = write_data[3:3];

end


`RTLGEN_CAFU_CSR0_CFG_EN_FF_SYNCRST(gated_clk, cxl_or_conv_rst_n, 1'h0, up_CONFIG_ALGO_SETTING_device_selfchecking[0], nxt_CONFIG_ALGO_SETTING_device_selfchecking[0:0], CONFIG_ALGO_SETTING.device_selfchecking[0:0])

// ----------------------------------------------------------------------
// CONFIG_ALGO_SETTING.num_of_increments x8 RW, using RW template.
logic [0:0] up_CONFIG_ALGO_SETTING_num_of_increments;
always_comb begin
 up_CONFIG_ALGO_SETTING_num_of_increments =
    ({1{write_req_CONFIG_ALGO_SETTING }} &
    be[1:1]);
end

logic [7:0] nxt_CONFIG_ALGO_SETTING_num_of_increments;
always_comb begin
 nxt_CONFIG_ALGO_SETTING_num_of_increments = write_data[15:8];

end


`RTLGEN_CAFU_CSR0_CFG_EN_FF_SYNCRST(gated_clk, cxl_or_conv_rst_n, 8'h0, up_CONFIG_ALGO_SETTING_num_of_increments[0], nxt_CONFIG_ALGO_SETTING_num_of_increments[7:0], CONFIG_ALGO_SETTING.num_of_increments[7:0])

// ----------------------------------------------------------------------
// CONFIG_ALGO_SETTING.num_of_sets x8 RW, using RW template.
logic [0:0] up_CONFIG_ALGO_SETTING_num_of_sets;
always_comb begin
 up_CONFIG_ALGO_SETTING_num_of_sets =
    ({1{write_req_CONFIG_ALGO_SETTING }} &
    be[2:2]);
end

logic [7:0] nxt_CONFIG_ALGO_SETTING_num_of_sets;
always_comb begin
 nxt_CONFIG_ALGO_SETTING_num_of_sets = write_data[23:16];

end


`RTLGEN_CAFU_CSR0_CFG_EN_FF_SYNCRST(gated_clk, cxl_or_conv_rst_n, 8'h0, up_CONFIG_ALGO_SETTING_num_of_sets[0], nxt_CONFIG_ALGO_SETTING_num_of_sets[7:0], CONFIG_ALGO_SETTING.num_of_sets[7:0])

// ----------------------------------------------------------------------
// CONFIG_ALGO_SETTING.num_of_loops x8 RW, using RW template.
logic [0:0] up_CONFIG_ALGO_SETTING_num_of_loops;
always_comb begin
 up_CONFIG_ALGO_SETTING_num_of_loops =
    ({1{write_req_CONFIG_ALGO_SETTING }} &
    be[3:3]);
end

logic [7:0] nxt_CONFIG_ALGO_SETTING_num_of_loops;
always_comb begin
 nxt_CONFIG_ALGO_SETTING_num_of_loops = write_data[31:24];

end


`RTLGEN_CAFU_CSR0_CFG_EN_FF_SYNCRST(gated_clk, cxl_or_conv_rst_n, 8'h0, up_CONFIG_ALGO_SETTING_num_of_loops[0], nxt_CONFIG_ALGO_SETTING_num_of_loops[7:0], CONFIG_ALGO_SETTING.num_of_loops[7:0])

// ----------------------------------------------------------------------
// CONFIG_ALGO_SETTING.address_is_virtual x1 RW, using RW template.
logic [0:0] up_CONFIG_ALGO_SETTING_address_is_virtual;
always_comb begin
 up_CONFIG_ALGO_SETTING_address_is_virtual =
    ({1{write_req_CONFIG_ALGO_SETTING }} &
    be[4:4]);
end

logic [0:0] nxt_CONFIG_ALGO_SETTING_address_is_virtual;
always_comb begin
 nxt_CONFIG_ALGO_SETTING_address_is_virtual = write_data[32:32];

end


`RTLGEN_CAFU_CSR0_CFG_EN_FF_SYNCRST(gated_clk, cxl_or_conv_rst_n, 1'h0, up_CONFIG_ALGO_SETTING_address_is_virtual[0], nxt_CONFIG_ALGO_SETTING_address_is_virtual[0:0], CONFIG_ALGO_SETTING.address_is_virtual[0:0])

// ----------------------------------------------------------------------
// CONFIG_ALGO_SETTING.interface_protocol_type x3 RW, using RW template.
logic [0:0] up_CONFIG_ALGO_SETTING_interface_protocol_type;
always_comb begin
 up_CONFIG_ALGO_SETTING_interface_protocol_type =
    ({1{write_req_CONFIG_ALGO_SETTING }} &
    be[4:4]);
end

logic [2:0] nxt_CONFIG_ALGO_SETTING_interface_protocol_type;
always_comb begin
 nxt_CONFIG_ALGO_SETTING_interface_protocol_type = write_data[35:33];

end


`RTLGEN_CAFU_CSR0_CFG_EN_FF_SYNCRST(gated_clk, cxl_or_conv_rst_n, 3'h0, up_CONFIG_ALGO_SETTING_interface_protocol_type[0], nxt_CONFIG_ALGO_SETTING_interface_protocol_type[2:0], CONFIG_ALGO_SETTING.interface_protocol_type[2:0])

// ----------------------------------------------------------------------
// CONFIG_ALGO_SETTING.write_semantics_cache x4 RW, using RW template.
logic [0:0] up_CONFIG_ALGO_SETTING_write_semantics_cache;
always_comb begin
 up_CONFIG_ALGO_SETTING_write_semantics_cache =
    ({1{write_req_CONFIG_ALGO_SETTING }} &
    be[4:4]);
end

logic [3:0] nxt_CONFIG_ALGO_SETTING_write_semantics_cache;
always_comb begin
 nxt_CONFIG_ALGO_SETTING_write_semantics_cache = write_data[39:36];

end


`RTLGEN_CAFU_CSR0_CFG_EN_FF_SYNCRST(gated_clk, cxl_or_conv_rst_n, 4'h0, up_CONFIG_ALGO_SETTING_write_semantics_cache[0], nxt_CONFIG_ALGO_SETTING_write_semantics_cache[3:0], CONFIG_ALGO_SETTING.write_semantics_cache[3:0])

// ----------------------------------------------------------------------
// CONFIG_ALGO_SETTING.flush_cache x1 RW/L, using RW/L template.
logic [0:0] req_up_CONFIG_ALGO_SETTING_flush_cache;
always_comb begin
 req_up_CONFIG_ALGO_SETTING_flush_cache[0] = 
   {write_req_CONFIG_ALGO_SETTING & be[5]}
;
end

logic  lock_lcl_CONFIG_ALGO_SETTING_flush_cache;
always_comb begin
 lock_lcl_CONFIG_ALGO_SETTING_flush_cache = ((CXL_DVSEC_TEST_LOCK.test_config_lock == 1'h1));
end

logic [0:0] up_CONFIG_ALGO_SETTING_flush_cache;
always_comb begin
 up_CONFIG_ALGO_SETTING_flush_cache = 
   (req_up_CONFIG_ALGO_SETTING_flush_cache & {1{~lock_lcl_CONFIG_ALGO_SETTING_flush_cache}});

end


logic [0:0] nxt_CONFIG_ALGO_SETTING_flush_cache;
always_comb begin
 nxt_CONFIG_ALGO_SETTING_flush_cache = write_data[40:40];

end
`RTLGEN_CAFU_CSR0_CFG_EN_FF(gated_clk, rst_n, 1'h0, up_CONFIG_ALGO_SETTING_flush_cache[0], nxt_CONFIG_ALGO_SETTING_flush_cache[0:0], CONFIG_ALGO_SETTING.flush_cache[0:0])

// ----------------------------------------------------------------------
// CONFIG_ALGO_SETTING.execute_read_semantics x3 RW, using RW template.
logic [0:0] up_CONFIG_ALGO_SETTING_execute_read_semantics;
always_comb begin
 up_CONFIG_ALGO_SETTING_execute_read_semantics =
    ({1{write_req_CONFIG_ALGO_SETTING }} &
    be[5:5]);
end

logic [2:0] nxt_CONFIG_ALGO_SETTING_execute_read_semantics;
always_comb begin
 nxt_CONFIG_ALGO_SETTING_execute_read_semantics = write_data[43:41];

end


`RTLGEN_CAFU_CSR0_CFG_EN_FF_SYNCRST(gated_clk, cxl_or_conv_rst_n, 3'h0, up_CONFIG_ALGO_SETTING_execute_read_semantics[0], nxt_CONFIG_ALGO_SETTING_execute_read_semantics[2:0], CONFIG_ALGO_SETTING.execute_read_semantics[2:0])

// ----------------------------------------------------------------------
// CONFIG_ALGO_SETTING.verify_semantics_cache x3 RW, using RW template.
logic [0:0] up_CONFIG_ALGO_SETTING_verify_semantics_cache;
always_comb begin
 up_CONFIG_ALGO_SETTING_verify_semantics_cache =
    ({1{write_req_CONFIG_ALGO_SETTING }} &
    be[5:5]);
end

logic [2:0] nxt_CONFIG_ALGO_SETTING_verify_semantics_cache;
always_comb begin
 nxt_CONFIG_ALGO_SETTING_verify_semantics_cache = write_data[46:44];

end


`RTLGEN_CAFU_CSR0_CFG_EN_FF_SYNCRST(gated_clk, cxl_or_conv_rst_n, 3'h0, up_CONFIG_ALGO_SETTING_verify_semantics_cache[0], nxt_CONFIG_ALGO_SETTING_verify_semantics_cache[2:0], CONFIG_ALGO_SETTING.verify_semantics_cache[2:0])

//---------------------------------------------------------------------
// CONFIG_DEVICE_INJECTION Address Decode
logic  addr_decode_CONFIG_DEVICE_INJECTION;
logic  write_req_CONFIG_DEVICE_INJECTION;
always_comb begin
   addr_decode_CONFIG_DEVICE_INJECTION = (req_addr[CAFU_CSR0_CFG_MEM_ADDR_MSB:ADDR_LSB_BUS_ALIGN] == CONFIG_DEVICE_INJECTION_DECODE_ADDR) && req.valid ;
   write_req_CONFIG_DEVICE_INJECTION = IsMEMWr && addr_decode_CONFIG_DEVICE_INJECTION && sb_fid_cond_mem_inst_sb && sb_bar_cond_mem_inst_sb;
end

// ----------------------------------------------------------------------
// CONFIG_DEVICE_INJECTION.unexp_compl_inject x1 RW/L, using RW/L template.
logic [0:0] req_up_CONFIG_DEVICE_INJECTION_unexp_compl_inject;
always_comb begin
 req_up_CONFIG_DEVICE_INJECTION_unexp_compl_inject[0] = 
   {write_req_CONFIG_DEVICE_INJECTION & be[0]}
;
end

logic  lock_lcl_CONFIG_DEVICE_INJECTION_unexp_compl_inject;
always_comb begin
 lock_lcl_CONFIG_DEVICE_INJECTION_unexp_compl_inject = ((CXL_DVSEC_TEST_LOCK.test_config_lock == 1'h1));
end

logic [0:0] up_CONFIG_DEVICE_INJECTION_unexp_compl_inject;
always_comb begin
 up_CONFIG_DEVICE_INJECTION_unexp_compl_inject = 
   (req_up_CONFIG_DEVICE_INJECTION_unexp_compl_inject & {1{~lock_lcl_CONFIG_DEVICE_INJECTION_unexp_compl_inject}});

end


logic [0:0] nxt_CONFIG_DEVICE_INJECTION_unexp_compl_inject;
always_comb begin
 nxt_CONFIG_DEVICE_INJECTION_unexp_compl_inject = write_data[0:0];

end
`RTLGEN_CAFU_CSR0_CFG_EN_FF(gated_clk, rst_n, 1'h0, up_CONFIG_DEVICE_INJECTION_unexp_compl_inject[0], nxt_CONFIG_DEVICE_INJECTION_unexp_compl_inject[0:0], CONFIG_DEVICE_INJECTION.unexp_compl_inject[0:0])
// ----------------------------------------------------------------------
// CONFIG_DEVICE_INJECTION.unexp_compl_inject_busy x1 RO/V, using RO/V template.
assign CONFIG_DEVICE_INJECTION.unexp_compl_inject_busy = new_CONFIG_DEVICE_INJECTION.unexp_compl_inject_busy;




// ----------------------------------------------------------------------
// CONFIG_DEVICE_INJECTION.completer_timeout x1 RW/L, using RW/L template.
logic [0:0] req_up_CONFIG_DEVICE_INJECTION_completer_timeout;
always_comb begin
 req_up_CONFIG_DEVICE_INJECTION_completer_timeout[0] = 
   {write_req_CONFIG_DEVICE_INJECTION & be[0]}
;
end

logic  lock_lcl_CONFIG_DEVICE_INJECTION_completer_timeout;
always_comb begin
 lock_lcl_CONFIG_DEVICE_INJECTION_completer_timeout = ((CXL_DVSEC_TEST_LOCK.test_config_lock == 1'h1));
end

logic [0:0] up_CONFIG_DEVICE_INJECTION_completer_timeout;
always_comb begin
 up_CONFIG_DEVICE_INJECTION_completer_timeout = 
   (req_up_CONFIG_DEVICE_INJECTION_completer_timeout & {1{~lock_lcl_CONFIG_DEVICE_INJECTION_completer_timeout}});

end


logic [0:0] nxt_CONFIG_DEVICE_INJECTION_completer_timeout;
always_comb begin
 nxt_CONFIG_DEVICE_INJECTION_completer_timeout = write_data[2:2];

end
`RTLGEN_CAFU_CSR0_CFG_EN_FF(gated_clk, rst_n, 1'h0, up_CONFIG_DEVICE_INJECTION_completer_timeout[0], nxt_CONFIG_DEVICE_INJECTION_completer_timeout[0:0], CONFIG_DEVICE_INJECTION.completer_timeout[0:0])
// ----------------------------------------------------------------------
// CONFIG_DEVICE_INJECTION.completer_timeout_inj_busy x1 RO/V, using RO/V template.
assign CONFIG_DEVICE_INJECTION.completer_timeout_inj_busy = new_CONFIG_DEVICE_INJECTION.completer_timeout_inj_busy;




//---------------------------------------------------------------------
// DEVICE_ERROR_LOG1 Address Decode
// ----------------------------------------------------------------------
// DEVICE_ERROR_LOG1.expected_pattern1 x8 RO/V, using RO/V template.
assign DEVICE_ERROR_LOG1.expected_pattern1 = new_DEVICE_ERROR_LOG1.expected_pattern1;



// ----------------------------------------------------------------------
// DEVICE_ERROR_LOG1.observed_pattern1 x8 RO/V, using RO/V template.
assign DEVICE_ERROR_LOG1.observed_pattern1 = new_DEVICE_ERROR_LOG1.observed_pattern1;




//---------------------------------------------------------------------
// DEVICE_ERROR_LOG2 Address Decode
// ----------------------------------------------------------------------
// DEVICE_ERROR_LOG2.expected_pattern2 x8 RO/V, using RO/V template.
assign DEVICE_ERROR_LOG2.expected_pattern2 = new_DEVICE_ERROR_LOG2.expected_pattern2;



// ----------------------------------------------------------------------
// DEVICE_ERROR_LOG2.observed_pattern2 x8 RO/V, using RO/V template.
assign DEVICE_ERROR_LOG2.observed_pattern2 = new_DEVICE_ERROR_LOG2.observed_pattern2;




//---------------------------------------------------------------------
// DEVICE_ERROR_LOG3 Address Decode
logic  addr_decode_DEVICE_ERROR_LOG3;
logic  write_req_DEVICE_ERROR_LOG3;
always_comb begin
   addr_decode_DEVICE_ERROR_LOG3 = (req_addr[CAFU_CSR0_CFG_MEM_ADDR_MSB:ADDR_LSB_BUS_ALIGN] == DEVICE_ERROR_LOG3_DECODE_ADDR) && req.valid ;
   write_req_DEVICE_ERROR_LOG3 = IsMEMWr && addr_decode_DEVICE_ERROR_LOG3 && sb_fid_cond_mem_inst_sb && sb_bar_cond_mem_inst_sb;
end
// ----------------------------------------------------------------------
// DEVICE_ERROR_LOG3.byte_offset x8 RO/V, using RO/V template.
assign DEVICE_ERROR_LOG3.byte_offset = new_DEVICE_ERROR_LOG3.byte_offset;



// ----------------------------------------------------------------------
// DEVICE_ERROR_LOG3.loop_numb x8 RO/V, using RO/V template.
assign DEVICE_ERROR_LOG3.loop_numb = new_DEVICE_ERROR_LOG3.loop_numb;




// ----------------------------------------------------------------------
// DEVICE_ERROR_LOG3.error_status x1 RW/1C/V, using RW/1C/V template.
// clear the each bit when writing a 1
logic [0:0] req_up_DEVICE_ERROR_LOG3_error_status;
always_comb begin
 req_up_DEVICE_ERROR_LOG3_error_status[0:0] = 
   {1{write_req_DEVICE_ERROR_LOG3 & be[2]}}
;
end

logic [0:0] clr_DEVICE_ERROR_LOG3_error_status;
always_comb begin
 clr_DEVICE_ERROR_LOG3_error_status = write_data[16:16] & req_up_DEVICE_ERROR_LOG3_error_status;

end
logic [0:0] swwr_DEVICE_ERROR_LOG3_error_status;
logic [0:0] sw_nxt_DEVICE_ERROR_LOG3_error_status;
always_comb begin
 swwr_DEVICE_ERROR_LOG3_error_status = clr_DEVICE_ERROR_LOG3_error_status;
 sw_nxt_DEVICE_ERROR_LOG3_error_status = {1{1'b0}};

end
logic [0:0] up_DEVICE_ERROR_LOG3_error_status;
logic [0:0] nxt_DEVICE_ERROR_LOG3_error_status;
always_comb begin
 up_DEVICE_ERROR_LOG3_error_status = 
   swwr_DEVICE_ERROR_LOG3_error_status | {1{load_DEVICE_ERROR_LOG3.error_status}};
end
always_comb begin
 nxt_DEVICE_ERROR_LOG3_error_status[0] = 
    load_DEVICE_ERROR_LOG3.error_status ?
    new_DEVICE_ERROR_LOG3.error_status[0] :
    sw_nxt_DEVICE_ERROR_LOG3_error_status[0];
end



`RTLGEN_CAFU_CSR0_CFG_EN_FF_SYNCRST(rtl_clk, cxl_or_conv_rst_n, 1'h0, up_DEVICE_ERROR_LOG3_error_status[0], nxt_DEVICE_ERROR_LOG3_error_status[0], DEVICE_ERROR_LOG3.error_status[0])

//---------------------------------------------------------------------
// DEVICE_EVENT_CTRL Address Decode
logic  addr_decode_DEVICE_EVENT_CTRL;
logic  write_req_DEVICE_EVENT_CTRL;
always_comb begin
   addr_decode_DEVICE_EVENT_CTRL = (req_addr[CAFU_CSR0_CFG_MEM_ADDR_MSB:ADDR_LSB_BUS_ALIGN] == DEVICE_EVENT_CTRL_DECODE_ADDR) && req.valid ;
   write_req_DEVICE_EVENT_CTRL = IsMEMWr && addr_decode_DEVICE_EVENT_CTRL && sb_fid_cond_mem_inst_sb && sb_bar_cond_mem_inst_sb;
end

// ----------------------------------------------------------------------
// DEVICE_EVENT_CTRL.available_event_select x8 RW, using RW template.
logic [0:0] up_DEVICE_EVENT_CTRL_available_event_select;
always_comb begin
 up_DEVICE_EVENT_CTRL_available_event_select =
    ({1{write_req_DEVICE_EVENT_CTRL }} &
    be[0:0]);
end

logic [7:0] nxt_DEVICE_EVENT_CTRL_available_event_select;
always_comb begin
 nxt_DEVICE_EVENT_CTRL_available_event_select = write_data[7:0];

end


`RTLGEN_CAFU_CSR0_CFG_EN_FF_SYNCRST(gated_clk, cxl_or_conv_rst_n, 8'h0, up_DEVICE_EVENT_CTRL_available_event_select[0], nxt_DEVICE_EVENT_CTRL_available_event_select[7:0], DEVICE_EVENT_CTRL.available_event_select[7:0])

// ----------------------------------------------------------------------
// DEVICE_EVENT_CTRL.sub_event_select x8 RW, using RW template.
logic [0:0] up_DEVICE_EVENT_CTRL_sub_event_select;
always_comb begin
 up_DEVICE_EVENT_CTRL_sub_event_select =
    ({1{write_req_DEVICE_EVENT_CTRL }} &
    be[1:1]);
end

logic [7:0] nxt_DEVICE_EVENT_CTRL_sub_event_select;
always_comb begin
 nxt_DEVICE_EVENT_CTRL_sub_event_select = write_data[15:8];

end


`RTLGEN_CAFU_CSR0_CFG_EN_FF_SYNCRST(gated_clk, cxl_or_conv_rst_n, 8'h0, up_DEVICE_EVENT_CTRL_sub_event_select[0], nxt_DEVICE_EVENT_CTRL_sub_event_select[7:0], DEVICE_EVENT_CTRL.sub_event_select[7:0])

// ----------------------------------------------------------------------
// DEVICE_EVENT_CTRL.event_counter_reset x1 RW, using RW template.
logic [0:0] up_DEVICE_EVENT_CTRL_event_counter_reset;
always_comb begin
 up_DEVICE_EVENT_CTRL_event_counter_reset =
    ({1{write_req_DEVICE_EVENT_CTRL }} &
    be[2:2]);
end

logic [0:0] nxt_DEVICE_EVENT_CTRL_event_counter_reset;
always_comb begin
 nxt_DEVICE_EVENT_CTRL_event_counter_reset = write_data[17:17];

end


`RTLGEN_CAFU_CSR0_CFG_EN_FF_SYNCRST(gated_clk, cxl_or_conv_rst_n, 1'h0, up_DEVICE_EVENT_CTRL_event_counter_reset[0], nxt_DEVICE_EVENT_CTRL_event_counter_reset[0:0], DEVICE_EVENT_CTRL.event_counter_reset[0:0])

// ----------------------------------------------------------------------
// DEVICE_EVENT_CTRL.event_edge_detect x1 RW, using RW template.
logic [0:0] up_DEVICE_EVENT_CTRL_event_edge_detect;
always_comb begin
 up_DEVICE_EVENT_CTRL_event_edge_detect =
    ({1{write_req_DEVICE_EVENT_CTRL }} &
    be[2:2]);
end

logic [0:0] nxt_DEVICE_EVENT_CTRL_event_edge_detect;
always_comb begin
 nxt_DEVICE_EVENT_CTRL_event_edge_detect = write_data[18:18];

end


`RTLGEN_CAFU_CSR0_CFG_EN_FF_SYNCRST(gated_clk, cxl_or_conv_rst_n, 1'h0, up_DEVICE_EVENT_CTRL_event_edge_detect[0], nxt_DEVICE_EVENT_CTRL_event_edge_detect[0:0], DEVICE_EVENT_CTRL.event_edge_detect[0:0])

//---------------------------------------------------------------------
// DEVICE_EVENT_COUNT Address Decode
logic  addr_decode_DEVICE_EVENT_COUNT;
logic  write_req_DEVICE_EVENT_COUNT;
always_comb begin
   addr_decode_DEVICE_EVENT_COUNT = (req_addr[CAFU_CSR0_CFG_MEM_ADDR_MSB:ADDR_LSB_BUS_ALIGN] == DEVICE_EVENT_COUNT_DECODE_ADDR) && req.valid ;
   write_req_DEVICE_EVENT_COUNT = IsMEMWr && addr_decode_DEVICE_EVENT_COUNT && sb_fid_cond_mem_inst_sb && sb_bar_cond_mem_inst_sb;
end

// ----------------------------------------------------------------------
// DEVICE_EVENT_COUNT.event_count x8 RW/V, using RW/V template.
logic [7:0] req_up_DEVICE_EVENT_COUNT_event_count;
always_comb begin
 req_up_DEVICE_EVENT_COUNT_event_count[0] = 
   {write_req_DEVICE_EVENT_COUNT & be[0]}
;
 req_up_DEVICE_EVENT_COUNT_event_count[1] = 
   {write_req_DEVICE_EVENT_COUNT & be[1]}
;
 req_up_DEVICE_EVENT_COUNT_event_count[2] = 
   {write_req_DEVICE_EVENT_COUNT & be[2]}
;
 req_up_DEVICE_EVENT_COUNT_event_count[3] = 
   {write_req_DEVICE_EVENT_COUNT & be[3]}
;
 req_up_DEVICE_EVENT_COUNT_event_count[4] = 
   {write_req_DEVICE_EVENT_COUNT & be[4]}
;
 req_up_DEVICE_EVENT_COUNT_event_count[5] = 
   {write_req_DEVICE_EVENT_COUNT & be[5]}
;
 req_up_DEVICE_EVENT_COUNT_event_count[6] = 
   {write_req_DEVICE_EVENT_COUNT & be[6]}
;
 req_up_DEVICE_EVENT_COUNT_event_count[7] = 
   {write_req_DEVICE_EVENT_COUNT & be[7]}
;
end

logic [7:0] swwr_DEVICE_EVENT_COUNT_event_count;
always_comb begin
 swwr_DEVICE_EVENT_COUNT_event_count = req_up_DEVICE_EVENT_COUNT_event_count;

end


logic [7:0] up_DEVICE_EVENT_COUNT_event_count;
logic [63:0] nxt_DEVICE_EVENT_COUNT_event_count;
always_comb begin
 up_DEVICE_EVENT_COUNT_event_count =
    swwr_DEVICE_EVENT_COUNT_event_count |
    {8{load_DEVICE_EVENT_COUNT.event_count}};
end
always_comb begin
 nxt_DEVICE_EVENT_COUNT_event_count[7:0] = 
    swwr_DEVICE_EVENT_COUNT_event_count[0] ?
    write_data[7:0] :
    new_DEVICE_EVENT_COUNT.event_count[7:0];
 nxt_DEVICE_EVENT_COUNT_event_count[15:8] = 
    swwr_DEVICE_EVENT_COUNT_event_count[1] ?
    write_data[15:8] :
    new_DEVICE_EVENT_COUNT.event_count[15:8];
 nxt_DEVICE_EVENT_COUNT_event_count[23:16] = 
    swwr_DEVICE_EVENT_COUNT_event_count[2] ?
    write_data[23:16] :
    new_DEVICE_EVENT_COUNT.event_count[23:16];
 nxt_DEVICE_EVENT_COUNT_event_count[31:24] = 
    swwr_DEVICE_EVENT_COUNT_event_count[3] ?
    write_data[31:24] :
    new_DEVICE_EVENT_COUNT.event_count[31:24];
 nxt_DEVICE_EVENT_COUNT_event_count[39:32] = 
    swwr_DEVICE_EVENT_COUNT_event_count[4] ?
    write_data[39:32] :
    new_DEVICE_EVENT_COUNT.event_count[39:32];
 nxt_DEVICE_EVENT_COUNT_event_count[47:40] = 
    swwr_DEVICE_EVENT_COUNT_event_count[5] ?
    write_data[47:40] :
    new_DEVICE_EVENT_COUNT.event_count[47:40];
 nxt_DEVICE_EVENT_COUNT_event_count[55:48] = 
    swwr_DEVICE_EVENT_COUNT_event_count[6] ?
    write_data[55:48] :
    new_DEVICE_EVENT_COUNT.event_count[55:48];
 nxt_DEVICE_EVENT_COUNT_event_count[63:56] = 
    swwr_DEVICE_EVENT_COUNT_event_count[7] ?
    write_data[63:56] :
    new_DEVICE_EVENT_COUNT.event_count[63:56];
end

`RTLGEN_CAFU_CSR0_CFG_EN_FF_SYNCRST(rtl_clk, cxl_or_conv_rst_n, 8'h0, up_DEVICE_EVENT_COUNT_event_count[0], nxt_DEVICE_EVENT_COUNT_event_count[7:0], DEVICE_EVENT_COUNT.event_count[7:0])
`RTLGEN_CAFU_CSR0_CFG_EN_FF_SYNCRST(rtl_clk, cxl_or_conv_rst_n, 8'h0, up_DEVICE_EVENT_COUNT_event_count[1], nxt_DEVICE_EVENT_COUNT_event_count[15:8], DEVICE_EVENT_COUNT.event_count[15:8])
`RTLGEN_CAFU_CSR0_CFG_EN_FF_SYNCRST(rtl_clk, cxl_or_conv_rst_n, 8'h0, up_DEVICE_EVENT_COUNT_event_count[2], nxt_DEVICE_EVENT_COUNT_event_count[23:16], DEVICE_EVENT_COUNT.event_count[23:16])
`RTLGEN_CAFU_CSR0_CFG_EN_FF_SYNCRST(rtl_clk, cxl_or_conv_rst_n, 8'h0, up_DEVICE_EVENT_COUNT_event_count[3], nxt_DEVICE_EVENT_COUNT_event_count[31:24], DEVICE_EVENT_COUNT.event_count[31:24])
`RTLGEN_CAFU_CSR0_CFG_EN_FF_SYNCRST(rtl_clk, cxl_or_conv_rst_n, 8'h0, up_DEVICE_EVENT_COUNT_event_count[4], nxt_DEVICE_EVENT_COUNT_event_count[39:32], DEVICE_EVENT_COUNT.event_count[39:32])
`RTLGEN_CAFU_CSR0_CFG_EN_FF_SYNCRST(rtl_clk, cxl_or_conv_rst_n, 8'h0, up_DEVICE_EVENT_COUNT_event_count[5], nxt_DEVICE_EVENT_COUNT_event_count[47:40], DEVICE_EVENT_COUNT.event_count[47:40])
`RTLGEN_CAFU_CSR0_CFG_EN_FF_SYNCRST(rtl_clk, cxl_or_conv_rst_n, 8'h0, up_DEVICE_EVENT_COUNT_event_count[6], nxt_DEVICE_EVENT_COUNT_event_count[55:48], DEVICE_EVENT_COUNT.event_count[55:48])
`RTLGEN_CAFU_CSR0_CFG_EN_FF_SYNCRST(rtl_clk, cxl_or_conv_rst_n, 8'h0, up_DEVICE_EVENT_COUNT_event_count[7], nxt_DEVICE_EVENT_COUNT_event_count[63:56], DEVICE_EVENT_COUNT.event_count[63:56])

//---------------------------------------------------------------------
// DEVICE_ERROR_INJECTION Address Decode
logic  addr_decode_DEVICE_ERROR_INJECTION;
logic  write_req_DEVICE_ERROR_INJECTION;
always_comb begin
   addr_decode_DEVICE_ERROR_INJECTION = (req_addr[CAFU_CSR0_CFG_MEM_ADDR_MSB:ADDR_LSB_BUS_ALIGN] == DEVICE_ERROR_INJECTION_DECODE_ADDR) && req.valid ;
   write_req_DEVICE_ERROR_INJECTION = IsMEMWr && addr_decode_DEVICE_ERROR_INJECTION && sb_fid_cond_mem_inst_sb && sb_bar_cond_mem_inst_sb;
end

// ----------------------------------------------------------------------
// DEVICE_ERROR_INJECTION.CachePoisonInjectionStart x1 RW/L, using RW/L template.
logic [0:0] req_up_DEVICE_ERROR_INJECTION_CachePoisonInjectionStart;
always_comb begin
 req_up_DEVICE_ERROR_INJECTION_CachePoisonInjectionStart[0] = 
   {write_req_DEVICE_ERROR_INJECTION & be[0]}
;
end

logic  lock_lcl_DEVICE_ERROR_INJECTION_CachePoisonInjectionStart;
always_comb begin
 lock_lcl_DEVICE_ERROR_INJECTION_CachePoisonInjectionStart = ((CXL_DVSEC_TEST_LOCK.test_config_lock == 1'h1));
end

logic [0:0] up_DEVICE_ERROR_INJECTION_CachePoisonInjectionStart;
always_comb begin
 up_DEVICE_ERROR_INJECTION_CachePoisonInjectionStart = 
   (req_up_DEVICE_ERROR_INJECTION_CachePoisonInjectionStart & {1{~lock_lcl_DEVICE_ERROR_INJECTION_CachePoisonInjectionStart}});

end


logic [0:0] nxt_DEVICE_ERROR_INJECTION_CachePoisonInjectionStart;
always_comb begin
 nxt_DEVICE_ERROR_INJECTION_CachePoisonInjectionStart = write_data[0:0];

end
`RTLGEN_CAFU_CSR0_CFG_EN_FF(gated_clk, rst_n, 1'h0, up_DEVICE_ERROR_INJECTION_CachePoisonInjectionStart[0], nxt_DEVICE_ERROR_INJECTION_CachePoisonInjectionStart[0:0], DEVICE_ERROR_INJECTION.CachePoisonInjectionStart[0:0])
// ----------------------------------------------------------------------
// DEVICE_ERROR_INJECTION.CachePoisonInjectionBusy x1 RO/V, using RO/V template.
assign DEVICE_ERROR_INJECTION.CachePoisonInjectionBusy = new_DEVICE_ERROR_INJECTION.CachePoisonInjectionBusy;




// ----------------------------------------------------------------------
// DEVICE_ERROR_INJECTION.MemPoisonInjectionStart x1 RW/L, using RW/L template.
logic [0:0] req_up_DEVICE_ERROR_INJECTION_MemPoisonInjectionStart;
always_comb begin
 req_up_DEVICE_ERROR_INJECTION_MemPoisonInjectionStart[0] = 
   {write_req_DEVICE_ERROR_INJECTION & be[0]}
;
end

logic  lock_lcl_DEVICE_ERROR_INJECTION_MemPoisonInjectionStart;
always_comb begin
 lock_lcl_DEVICE_ERROR_INJECTION_MemPoisonInjectionStart = ((CXL_DVSEC_TEST_LOCK.test_config_lock == 1'h1));
end

logic [0:0] up_DEVICE_ERROR_INJECTION_MemPoisonInjectionStart;
always_comb begin
 up_DEVICE_ERROR_INJECTION_MemPoisonInjectionStart = 
   (req_up_DEVICE_ERROR_INJECTION_MemPoisonInjectionStart & {1{~lock_lcl_DEVICE_ERROR_INJECTION_MemPoisonInjectionStart}});

end


logic [0:0] nxt_DEVICE_ERROR_INJECTION_MemPoisonInjectionStart;
always_comb begin
 nxt_DEVICE_ERROR_INJECTION_MemPoisonInjectionStart = write_data[2:2];

end
`RTLGEN_CAFU_CSR0_CFG_EN_FF(gated_clk, rst_n, 1'h0, up_DEVICE_ERROR_INJECTION_MemPoisonInjectionStart[0], nxt_DEVICE_ERROR_INJECTION_MemPoisonInjectionStart[0:0], DEVICE_ERROR_INJECTION.MemPoisonInjectionStart[0:0])

// ----------------------------------------------------------------------
// DEVICE_ERROR_INJECTION.MemPoisonInjectionBusy x1 RO, using RO template.
assign DEVICE_ERROR_INJECTION.MemPoisonInjectionBusy = 1'h0;



// ----------------------------------------------------------------------
// DEVICE_ERROR_INJECTION.IOPoisonInjectionStart x1 RO, using RO template.
assign DEVICE_ERROR_INJECTION.IOPoisonInjectionStart = 1'h0;



// ----------------------------------------------------------------------
// DEVICE_ERROR_INJECTION.IOPoisonInjectionBusy x1 RO, using RO template.
assign DEVICE_ERROR_INJECTION.IOPoisonInjectionBusy = 1'h0;



// ----------------------------------------------------------------------
// DEVICE_ERROR_INJECTION.CacheMemCRCInjection x2 RO, using RO template.
assign DEVICE_ERROR_INJECTION.CacheMemCRCInjection = 2'h0;



// ----------------------------------------------------------------------
// DEVICE_ERROR_INJECTION.CacheMemCRCInjectionCount x2 RO, using RO template.
assign DEVICE_ERROR_INJECTION.CacheMemCRCInjectionCount = 2'h0;



// ----------------------------------------------------------------------
// DEVICE_ERROR_INJECTION.CacheMemCRCInjectionBusy x1 RO, using RO template.
assign DEVICE_ERROR_INJECTION.CacheMemCRCInjectionBusy = 1'h0;



//---------------------------------------------------------------------
// DEVICE_FORCE_DISABLE Address Decode
logic  addr_decode_DEVICE_FORCE_DISABLE;
logic  write_req_DEVICE_FORCE_DISABLE;
always_comb begin
   addr_decode_DEVICE_FORCE_DISABLE = (req_addr[CAFU_CSR0_CFG_MEM_ADDR_MSB:ADDR_LSB_BUS_ALIGN] == DEVICE_FORCE_DISABLE_DECODE_ADDR) && req.valid ;
   write_req_DEVICE_FORCE_DISABLE = IsMEMWr && addr_decode_DEVICE_FORCE_DISABLE && sb_fid_cond_mem_inst_sb && sb_bar_cond_mem_inst_sb;
end

// ----------------------------------------------------------------------
// DEVICE_FORCE_DISABLE.forcefully_disable_afu x1 RW, using RW template.
logic [0:0] up_DEVICE_FORCE_DISABLE_forcefully_disable_afu;
always_comb begin
 up_DEVICE_FORCE_DISABLE_forcefully_disable_afu =
    ({1{write_req_DEVICE_FORCE_DISABLE }} &
    be[0:0]);
end

logic [0:0] nxt_DEVICE_FORCE_DISABLE_forcefully_disable_afu;
always_comb begin
 nxt_DEVICE_FORCE_DISABLE_forcefully_disable_afu = write_data[0:0];

end


`RTLGEN_CAFU_CSR0_CFG_EN_FF_SYNCRST(gated_clk, cxl_or_conv_rst_n, 1'h0, up_DEVICE_FORCE_DISABLE_forcefully_disable_afu[0], nxt_DEVICE_FORCE_DISABLE_forcefully_disable_afu[0:0], DEVICE_FORCE_DISABLE.forcefully_disable_afu[0:0])

//---------------------------------------------------------------------
// DEVICE_ERROR_LOG4 Address Decode
// ----------------------------------------------------------------------
// DEVICE_ERROR_LOG4.address_increment x8 RO/V, using RO/V template.
assign DEVICE_ERROR_LOG4.address_increment = new_DEVICE_ERROR_LOG4.address_increment;



// ----------------------------------------------------------------------
// DEVICE_ERROR_LOG4.set_number x4 RO/V, using RO/V template.
assign DEVICE_ERROR_LOG4.set_number = new_DEVICE_ERROR_LOG4.set_number;




//---------------------------------------------------------------------
// DEVICE_ERROR_LOG5 Address Decode
// ----------------------------------------------------------------------
// DEVICE_ERROR_LOG5.address_of_first_error x4 RO/V, using RO/V template.
assign DEVICE_ERROR_LOG5.address_of_first_error = new_DEVICE_ERROR_LOG5.address_of_first_error;




//---------------------------------------------------------------------
// CONFIG_CXL_ERRORS Address Decode
// ----------------------------------------------------------------------
// CONFIG_CXL_ERRORS.illegal_protocol x1 RO/V, using RO/V template.
assign CONFIG_CXL_ERRORS.illegal_protocol = new_CONFIG_CXL_ERRORS.illegal_protocol;



// ----------------------------------------------------------------------
// CONFIG_CXL_ERRORS.illegal_write_semantics x1 RO/V, using RO/V template.
assign CONFIG_CXL_ERRORS.illegal_write_semantics = new_CONFIG_CXL_ERRORS.illegal_write_semantics;



// ----------------------------------------------------------------------
// CONFIG_CXL_ERRORS.illegal_execute_read_semantics x1 RO/V, using RO/V template.
assign CONFIG_CXL_ERRORS.illegal_execute_read_semantics = new_CONFIG_CXL_ERRORS.illegal_execute_read_semantics;



// ----------------------------------------------------------------------
// CONFIG_CXL_ERRORS.illegal_verify_read_semantics x1 RO/V, using RO/V template.
assign CONFIG_CXL_ERRORS.illegal_verify_read_semantics = new_CONFIG_CXL_ERRORS.illegal_verify_read_semantics;



// ----------------------------------------------------------------------
// CONFIG_CXL_ERRORS.illegal_pattern_size x1 RO/V, using RO/V template.
assign CONFIG_CXL_ERRORS.illegal_pattern_size = new_CONFIG_CXL_ERRORS.illegal_pattern_size;



// ----------------------------------------------------------------------
// CONFIG_CXL_ERRORS.illegal_base_address x1 RO/V, using RO/V template.
assign CONFIG_CXL_ERRORS.illegal_base_address = new_CONFIG_CXL_ERRORS.illegal_base_address;



// ----------------------------------------------------------------------
// CONFIG_CXL_ERRORS.illegal_cache_flush_call x1 RO/V, using RO/V template.
assign CONFIG_CXL_ERRORS.illegal_cache_flush_call = new_CONFIG_CXL_ERRORS.illegal_cache_flush_call;



// ----------------------------------------------------------------------
// CONFIG_CXL_ERRORS.poison_on_read_response x1 RO/V, using RO/V template.
assign CONFIG_CXL_ERRORS.poison_on_read_response = new_CONFIG_CXL_ERRORS.poison_on_read_response;



// ----------------------------------------------------------------------
// CONFIG_CXL_ERRORS.slverr_on_read_response x1 RO/V, using RO/V template.
assign CONFIG_CXL_ERRORS.slverr_on_read_response = new_CONFIG_CXL_ERRORS.slverr_on_read_response;



// ----------------------------------------------------------------------
// CONFIG_CXL_ERRORS.slverr_on_write_response x1 RO/V, using RO/V template.
assign CONFIG_CXL_ERRORS.slverr_on_write_response = new_CONFIG_CXL_ERRORS.slverr_on_write_response;




//---------------------------------------------------------------------
// DEVICE_AFU_STATUS1 Address Decode
// ----------------------------------------------------------------------
// DEVICE_AFU_STATUS1.afu_busy x1 RO/V, using RO/V template.
assign DEVICE_AFU_STATUS1.afu_busy = new_DEVICE_AFU_STATUS1.afu_busy;



// ----------------------------------------------------------------------
// DEVICE_AFU_STATUS1.alg_execute_busy x1 RO/V, using RO/V template.
assign DEVICE_AFU_STATUS1.alg_execute_busy = new_DEVICE_AFU_STATUS1.alg_execute_busy;



// ----------------------------------------------------------------------
// DEVICE_AFU_STATUS1.alg_verify_nsc_busy x1 RO/V, using RO/V template.
assign DEVICE_AFU_STATUS1.alg_verify_nsc_busy = new_DEVICE_AFU_STATUS1.alg_verify_nsc_busy;



// ----------------------------------------------------------------------
// DEVICE_AFU_STATUS1.alg_verify_sc_busy x1 RO/V, using RO/V template.
assign DEVICE_AFU_STATUS1.alg_verify_sc_busy = new_DEVICE_AFU_STATUS1.alg_verify_sc_busy;



// ----------------------------------------------------------------------
// DEVICE_AFU_STATUS1.loop_number x4 RO/V, using RO/V template.
assign DEVICE_AFU_STATUS1.loop_number = new_DEVICE_AFU_STATUS1.loop_number;



// ----------------------------------------------------------------------
// DEVICE_AFU_STATUS1.set_number x4 RO/V, using RO/V template.
assign DEVICE_AFU_STATUS1.set_number = new_DEVICE_AFU_STATUS1.set_number;



// ----------------------------------------------------------------------
// DEVICE_AFU_STATUS1.current_base_pattern x8 RO/V, using RO/V template.
assign DEVICE_AFU_STATUS1.current_base_pattern = new_DEVICE_AFU_STATUS1.current_base_pattern;




//---------------------------------------------------------------------
// DEVICE_AFU_STATUS2 Address Decode
// ----------------------------------------------------------------------
// DEVICE_AFU_STATUS2.current_base_address x4 RO/V, using RO/V template.
assign DEVICE_AFU_STATUS2.current_base_address = new_DEVICE_AFU_STATUS2.current_base_address;




//---------------------------------------------------------------------
// DEVICE_AXI2CPI_STATUS_1 Address Decode
logic  addr_decode_DEVICE_AXI2CPI_STATUS_1;
logic  write_req_DEVICE_AXI2CPI_STATUS_1;
always_comb begin
   addr_decode_DEVICE_AXI2CPI_STATUS_1 = (req_addr[CAFU_CSR0_CFG_MEM_ADDR_MSB:ADDR_LSB_BUS_ALIGN] == DEVICE_AXI2CPI_STATUS_1_DECODE_ADDR) && req.valid ;
   write_req_DEVICE_AXI2CPI_STATUS_1 = IsMEMWr && addr_decode_DEVICE_AXI2CPI_STATUS_1 && sb_fid_cond_mem_inst_sb && sb_bar_cond_mem_inst_sb;
end

// ----------------------------------------------------------------------
// DEVICE_AXI2CPI_STATUS_1.clear x1 RW, using RW template.
logic [0:0] up_DEVICE_AXI2CPI_STATUS_1_clear;
always_comb begin
 up_DEVICE_AXI2CPI_STATUS_1_clear =
    ({1{write_req_DEVICE_AXI2CPI_STATUS_1 }} &
    be[0:0]);
end

logic [0:0] nxt_DEVICE_AXI2CPI_STATUS_1_clear;
always_comb begin
 nxt_DEVICE_AXI2CPI_STATUS_1_clear = write_data[0:0];

end


`RTLGEN_CAFU_CSR0_CFG_EN_FF_SYNCRST(gated_clk, cxl_or_conv_rst_n, 1'h0, up_DEVICE_AXI2CPI_STATUS_1_clear[0], nxt_DEVICE_AXI2CPI_STATUS_1_clear[0:0], DEVICE_AXI2CPI_STATUS_1.clear[0:0])
// ----------------------------------------------------------------------
// DEVICE_AXI2CPI_STATUS_1.axi2cpi_busy x1 RO/V, using RO/V template.
assign DEVICE_AXI2CPI_STATUS_1.axi2cpi_busy = new_DEVICE_AXI2CPI_STATUS_1.axi2cpi_busy;



// ----------------------------------------------------------------------
// DEVICE_AXI2CPI_STATUS_1.config_error_status x1 RO/V, using RO/V template.
assign DEVICE_AXI2CPI_STATUS_1.config_error_status = new_DEVICE_AXI2CPI_STATUS_1.config_error_status;



// ----------------------------------------------------------------------
// DEVICE_AXI2CPI_STATUS_1.cafu_csr0_write_semantic x1 RO/V, using RO/V template.
assign DEVICE_AXI2CPI_STATUS_1.cafu_csr0_write_semantic = new_DEVICE_AXI2CPI_STATUS_1.cafu_csr0_write_semantic;



// ----------------------------------------------------------------------
// DEVICE_AXI2CPI_STATUS_1.cafu_csr0_read_semantic x3 RO/V, using RO/V template.
assign DEVICE_AXI2CPI_STATUS_1.cafu_csr0_read_semantic = new_DEVICE_AXI2CPI_STATUS_1.cafu_csr0_read_semantic;



// ----------------------------------------------------------------------
// DEVICE_AXI2CPI_STATUS_1.write_opcode_error_status x1 RO/V, using RO/V template.
assign DEVICE_AXI2CPI_STATUS_1.write_opcode_error_status = new_DEVICE_AXI2CPI_STATUS_1.write_opcode_error_status;



// ----------------------------------------------------------------------
// DEVICE_AXI2CPI_STATUS_1.write_awid x2 RO/V, using RO/V template.
assign DEVICE_AXI2CPI_STATUS_1.write_awid = new_DEVICE_AXI2CPI_STATUS_1.write_awid;



// ----------------------------------------------------------------------
// DEVICE_AXI2CPI_STATUS_1.write_awuser_opcode x4 RO/V, using RO/V template.
assign DEVICE_AXI2CPI_STATUS_1.write_awuser_opcode = new_DEVICE_AXI2CPI_STATUS_1.write_awuser_opcode;



// ----------------------------------------------------------------------
// DEVICE_AXI2CPI_STATUS_1.read_opcode_error_status x1 RO/V, using RO/V template.
assign DEVICE_AXI2CPI_STATUS_1.read_opcode_error_status = new_DEVICE_AXI2CPI_STATUS_1.read_opcode_error_status;



// ----------------------------------------------------------------------
// DEVICE_AXI2CPI_STATUS_1.read_arid x4 RO/V, using RO/V template.
assign DEVICE_AXI2CPI_STATUS_1.read_arid = new_DEVICE_AXI2CPI_STATUS_1.read_arid;



// ----------------------------------------------------------------------
// DEVICE_AXI2CPI_STATUS_1.read_aruser_opcode x4 RO/V, using RO/V template.
assign DEVICE_AXI2CPI_STATUS_1.read_aruser_opcode = new_DEVICE_AXI2CPI_STATUS_1.read_aruser_opcode;




//---------------------------------------------------------------------
// DEVICE_AXI2CPI_STATUS_2 Address Decode
logic  addr_decode_DEVICE_AXI2CPI_STATUS_2;
logic  write_req_DEVICE_AXI2CPI_STATUS_2;
always_comb begin
   addr_decode_DEVICE_AXI2CPI_STATUS_2 = (req_addr[CAFU_CSR0_CFG_MEM_ADDR_MSB:ADDR_LSB_BUS_ALIGN] == DEVICE_AXI2CPI_STATUS_2_DECODE_ADDR) && req.valid ;
   write_req_DEVICE_AXI2CPI_STATUS_2 = IsMEMWr && addr_decode_DEVICE_AXI2CPI_STATUS_2 && sb_fid_cond_mem_inst_sb && sb_bar_cond_mem_inst_sb;
end

// ----------------------------------------------------------------------
// DEVICE_AXI2CPI_STATUS_2.clear x1 RW, using RW template.
logic [0:0] up_DEVICE_AXI2CPI_STATUS_2_clear;
always_comb begin
 up_DEVICE_AXI2CPI_STATUS_2_clear =
    ({1{write_req_DEVICE_AXI2CPI_STATUS_2 }} &
    be[0:0]);
end

logic [0:0] nxt_DEVICE_AXI2CPI_STATUS_2_clear;
always_comb begin
 nxt_DEVICE_AXI2CPI_STATUS_2_clear = write_data[0:0];

end


`RTLGEN_CAFU_CSR0_CFG_EN_FF_SYNCRST(gated_clk, cxl_or_conv_rst_n, 1'h0, up_DEVICE_AXI2CPI_STATUS_2_clear[0], nxt_DEVICE_AXI2CPI_STATUS_2_clear[0:0], DEVICE_AXI2CPI_STATUS_2.clear[0:0])
// ----------------------------------------------------------------------
// DEVICE_AXI2CPI_STATUS_2.header_parity_error_status x1 RO/V, using RO/V template.
assign DEVICE_AXI2CPI_STATUS_2.header_parity_error_status = new_DEVICE_AXI2CPI_STATUS_2.header_parity_error_status;



// ----------------------------------------------------------------------
// DEVICE_AXI2CPI_STATUS_2.data_parity_error_status x1 RO/V, using RO/V template.
assign DEVICE_AXI2CPI_STATUS_2.data_parity_error_status = new_DEVICE_AXI2CPI_STATUS_2.data_parity_error_status;



// ----------------------------------------------------------------------
// DEVICE_AXI2CPI_STATUS_2.ccv_afu_arid x1 RO/V, using RO/V template.
assign DEVICE_AXI2CPI_STATUS_2.ccv_afu_arid = new_DEVICE_AXI2CPI_STATUS_2.ccv_afu_arid;



// ----------------------------------------------------------------------
// DEVICE_AXI2CPI_STATUS_2.address x8 RO/V, using RO/V template.
assign DEVICE_AXI2CPI_STATUS_2.address = new_DEVICE_AXI2CPI_STATUS_2.address;




//---------------------------------------------------------------------
// CDAT_0 Address Decode
logic  addr_decode_CDAT_0;
logic  write_req_CDAT_0;
always_comb begin
   addr_decode_CDAT_0 = (req_addr[CAFU_CSR0_CFG_MEM_ADDR_MSB:ADDR_LSB_BUS_ALIGN] == CDAT_0_DECODE_ADDR) && req.valid ;
   write_req_CDAT_0 = IsMEMWr && addr_decode_CDAT_0 && sb_fid_cond_mem_inst_sb && sb_bar_cond_mem_inst_sb;
end

// ----------------------------------------------------------------------
// CDAT_0.cdat_0 x8 RW/V, using RW/V template.
logic [3:0] req_up_CDAT_0_cdat_0;
always_comb begin
 req_up_CDAT_0_cdat_0[0] = 
   {write_req_CDAT_0 & be[0]}
;
 req_up_CDAT_0_cdat_0[1] = 
   {write_req_CDAT_0 & be[1]}
;
 req_up_CDAT_0_cdat_0[2] = 
   {write_req_CDAT_0 & be[2]}
;
 req_up_CDAT_0_cdat_0[3] = 
   {write_req_CDAT_0 & be[3]}
;
end

logic [3:0] swwr_CDAT_0_cdat_0;
always_comb begin
 swwr_CDAT_0_cdat_0 = req_up_CDAT_0_cdat_0;

end


logic [3:0] up_CDAT_0_cdat_0;
logic [31:0] nxt_CDAT_0_cdat_0;
always_comb begin
 up_CDAT_0_cdat_0 =
    swwr_CDAT_0_cdat_0 |
    {4{load_CDAT_0.cdat_0}};
end
always_comb begin
 nxt_CDAT_0_cdat_0[7:0] = 
    swwr_CDAT_0_cdat_0[0] ?
    write_data[7:0] :
    new_CDAT_0.cdat_0[7:0];
 nxt_CDAT_0_cdat_0[15:8] = 
    swwr_CDAT_0_cdat_0[1] ?
    write_data[15:8] :
    new_CDAT_0.cdat_0[15:8];
 nxt_CDAT_0_cdat_0[23:16] = 
    swwr_CDAT_0_cdat_0[2] ?
    write_data[23:16] :
    new_CDAT_0.cdat_0[23:16];
 nxt_CDAT_0_cdat_0[31:24] = 
    swwr_CDAT_0_cdat_0[3] ?
    write_data[31:24] :
    new_CDAT_0.cdat_0[31:24];
end

`RTLGEN_CAFU_CSR0_CFG_EN_FF(rtl_clk, rst_n, 8'h60, up_CDAT_0_cdat_0[0], nxt_CDAT_0_cdat_0[7:0], CDAT_0.cdat_0[7:0])
`RTLGEN_CAFU_CSR0_CFG_EN_FF(rtl_clk, rst_n, 8'h0, up_CDAT_0_cdat_0[1], nxt_CDAT_0_cdat_0[15:8], CDAT_0.cdat_0[15:8])
`RTLGEN_CAFU_CSR0_CFG_EN_FF(rtl_clk, rst_n, 8'h0, up_CDAT_0_cdat_0[2], nxt_CDAT_0_cdat_0[23:16], CDAT_0.cdat_0[23:16])
`RTLGEN_CAFU_CSR0_CFG_EN_FF(rtl_clk, rst_n, 8'h0, up_CDAT_0_cdat_0[3], nxt_CDAT_0_cdat_0[31:24], CDAT_0.cdat_0[31:24])

//---------------------------------------------------------------------
// CDAT_1 Address Decode
logic  addr_decode_CDAT_1;
logic  write_req_CDAT_1;
always_comb begin
   addr_decode_CDAT_1 = (req_addr[CAFU_CSR0_CFG_MEM_ADDR_MSB:ADDR_LSB_BUS_ALIGN] == CDAT_1_DECODE_ADDR) && req.valid ;
   write_req_CDAT_1 = IsMEMWr && addr_decode_CDAT_1 && sb_fid_cond_mem_inst_sb && sb_bar_cond_mem_inst_sb;
end

// ----------------------------------------------------------------------
// CDAT_1.cdat_1 x8 RW/V, using RW/V template.
logic [3:0] req_up_CDAT_1_cdat_1;
always_comb begin
 req_up_CDAT_1_cdat_1[0] = 
   {write_req_CDAT_1 & be[4]}
;
 req_up_CDAT_1_cdat_1[1] = 
   {write_req_CDAT_1 & be[5]}
;
 req_up_CDAT_1_cdat_1[2] = 
   {write_req_CDAT_1 & be[6]}
;
 req_up_CDAT_1_cdat_1[3] = 
   {write_req_CDAT_1 & be[7]}
;
end

logic [3:0] swwr_CDAT_1_cdat_1;
always_comb begin
 swwr_CDAT_1_cdat_1 = req_up_CDAT_1_cdat_1;

end


logic [3:0] up_CDAT_1_cdat_1;
logic [31:0] nxt_CDAT_1_cdat_1;
always_comb begin
 up_CDAT_1_cdat_1 =
    swwr_CDAT_1_cdat_1 |
    {4{load_CDAT_1.cdat_1}};
end
always_comb begin
 nxt_CDAT_1_cdat_1[7:0] = 
    swwr_CDAT_1_cdat_1[0] ?
    write_data[39:32] :
    new_CDAT_1.cdat_1[7:0];
 nxt_CDAT_1_cdat_1[15:8] = 
    swwr_CDAT_1_cdat_1[1] ?
    write_data[47:40] :
    new_CDAT_1.cdat_1[15:8];
 nxt_CDAT_1_cdat_1[23:16] = 
    swwr_CDAT_1_cdat_1[2] ?
    write_data[55:48] :
    new_CDAT_1.cdat_1[23:16];
 nxt_CDAT_1_cdat_1[31:24] = 
    swwr_CDAT_1_cdat_1[3] ?
    write_data[63:56] :
    new_CDAT_1.cdat_1[31:24];
end

`RTLGEN_CAFU_CSR0_CFG_EN_FF(rtl_clk, rst_n, 8'h1, up_CDAT_1_cdat_1[0], nxt_CDAT_1_cdat_1[7:0], CDAT_1.cdat_1[7:0])
`RTLGEN_CAFU_CSR0_CFG_EN_FF(rtl_clk, rst_n, 8'h41, up_CDAT_1_cdat_1[1], nxt_CDAT_1_cdat_1[15:8], CDAT_1.cdat_1[15:8])
`RTLGEN_CAFU_CSR0_CFG_EN_FF(rtl_clk, rst_n, 8'h0, up_CDAT_1_cdat_1[2], nxt_CDAT_1_cdat_1[23:16], CDAT_1.cdat_1[23:16])
`RTLGEN_CAFU_CSR0_CFG_EN_FF(rtl_clk, rst_n, 8'h0, up_CDAT_1_cdat_1[3], nxt_CDAT_1_cdat_1[31:24], CDAT_1.cdat_1[31:24])

//---------------------------------------------------------------------
// CDAT_2 Address Decode
logic  addr_decode_CDAT_2;
logic  write_req_CDAT_2;
always_comb begin
   addr_decode_CDAT_2 = (req_addr[CAFU_CSR0_CFG_MEM_ADDR_MSB:ADDR_LSB_BUS_ALIGN] == CDAT_2_DECODE_ADDR) && req.valid ;
   write_req_CDAT_2 = IsMEMWr && addr_decode_CDAT_2 && sb_fid_cond_mem_inst_sb && sb_bar_cond_mem_inst_sb;
end

// ----------------------------------------------------------------------
// CDAT_2.cdat_2 x8 RW, using RW template.
logic [3:0] up_CDAT_2_cdat_2;
always_comb begin
 up_CDAT_2_cdat_2 =
    ({4{write_req_CDAT_2 }} &
    be[3:0]);
end

logic [31:0] nxt_CDAT_2_cdat_2;
always_comb begin
 nxt_CDAT_2_cdat_2 = write_data[31:0];

end


`RTLGEN_CAFU_CSR0_CFG_EN_FF(gated_clk, rst_n, 8'h0, up_CDAT_2_cdat_2[0], nxt_CDAT_2_cdat_2[7:0], CDAT_2.cdat_2[7:0])
`RTLGEN_CAFU_CSR0_CFG_EN_FF(gated_clk, rst_n, 8'h0, up_CDAT_2_cdat_2[1], nxt_CDAT_2_cdat_2[15:8], CDAT_2.cdat_2[15:8])
`RTLGEN_CAFU_CSR0_CFG_EN_FF(gated_clk, rst_n, 8'h0, up_CDAT_2_cdat_2[2], nxt_CDAT_2_cdat_2[23:16], CDAT_2.cdat_2[23:16])
`RTLGEN_CAFU_CSR0_CFG_EN_FF(gated_clk, rst_n, 8'h0, up_CDAT_2_cdat_2[3], nxt_CDAT_2_cdat_2[31:24], CDAT_2.cdat_2[31:24])

//---------------------------------------------------------------------
// CDAT_3 Address Decode
logic  addr_decode_CDAT_3;
logic  write_req_CDAT_3;
always_comb begin
   addr_decode_CDAT_3 = (req_addr[CAFU_CSR0_CFG_MEM_ADDR_MSB:ADDR_LSB_BUS_ALIGN] == CDAT_3_DECODE_ADDR) && req.valid ;
   write_req_CDAT_3 = IsMEMWr && addr_decode_CDAT_3 && sb_fid_cond_mem_inst_sb && sb_bar_cond_mem_inst_sb;
end

// ----------------------------------------------------------------------
// CDAT_3.cdat_3 x8 RW, using RW template.
logic [3:0] up_CDAT_3_cdat_3;
always_comb begin
 up_CDAT_3_cdat_3 =
    ({4{write_req_CDAT_3 }} &
    be[7:4]);
end

logic [31:0] nxt_CDAT_3_cdat_3;
always_comb begin
 nxt_CDAT_3_cdat_3 = write_data[63:32];

end


`RTLGEN_CAFU_CSR0_CFG_EN_FF(gated_clk, rst_n, 8'h0, up_CDAT_3_cdat_3[0], nxt_CDAT_3_cdat_3[7:0], CDAT_3.cdat_3[7:0])
`RTLGEN_CAFU_CSR0_CFG_EN_FF(gated_clk, rst_n, 8'h0, up_CDAT_3_cdat_3[1], nxt_CDAT_3_cdat_3[15:8], CDAT_3.cdat_3[15:8])
`RTLGEN_CAFU_CSR0_CFG_EN_FF(gated_clk, rst_n, 8'h0, up_CDAT_3_cdat_3[2], nxt_CDAT_3_cdat_3[23:16], CDAT_3.cdat_3[23:16])
`RTLGEN_CAFU_CSR0_CFG_EN_FF(gated_clk, rst_n, 8'h0, up_CDAT_3_cdat_3[3], nxt_CDAT_3_cdat_3[31:24], CDAT_3.cdat_3[31:24])

//---------------------------------------------------------------------
// DSMAS_0 Address Decode
logic  addr_decode_DSMAS_0;
logic  write_req_DSMAS_0;
always_comb begin
   addr_decode_DSMAS_0 = (req_addr[CAFU_CSR0_CFG_MEM_ADDR_MSB:ADDR_LSB_BUS_ALIGN] == DSMAS_0_DECODE_ADDR) && req.valid ;
   write_req_DSMAS_0 = IsMEMWr && addr_decode_DSMAS_0 && sb_fid_cond_mem_inst_sb && sb_bar_cond_mem_inst_sb;
end

// ----------------------------------------------------------------------
// DSMAS_0.dsmas_0 x8 RW, using RW template.
logic [3:0] up_DSMAS_0_dsmas_0;
always_comb begin
 up_DSMAS_0_dsmas_0 =
    ({4{write_req_DSMAS_0 }} &
    be[3:0]);
end

logic [31:0] nxt_DSMAS_0_dsmas_0;
always_comb begin
 nxt_DSMAS_0_dsmas_0 = write_data[31:0];

end


`RTLGEN_CAFU_CSR0_CFG_EN_FF(gated_clk, rst_n, 8'h0, up_DSMAS_0_dsmas_0[0], nxt_DSMAS_0_dsmas_0[7:0], DSMAS_0.dsmas_0[7:0])
`RTLGEN_CAFU_CSR0_CFG_EN_FF(gated_clk, rst_n, 8'h0, up_DSMAS_0_dsmas_0[1], nxt_DSMAS_0_dsmas_0[15:8], DSMAS_0.dsmas_0[15:8])
`RTLGEN_CAFU_CSR0_CFG_EN_FF(gated_clk, rst_n, 8'h18, up_DSMAS_0_dsmas_0[2], nxt_DSMAS_0_dsmas_0[23:16], DSMAS_0.dsmas_0[23:16])
`RTLGEN_CAFU_CSR0_CFG_EN_FF(gated_clk, rst_n, 8'h0, up_DSMAS_0_dsmas_0[3], nxt_DSMAS_0_dsmas_0[31:24], DSMAS_0.dsmas_0[31:24])

//---------------------------------------------------------------------
// DSMAS_1 Address Decode
logic  addr_decode_DSMAS_1;
logic  write_req_DSMAS_1;
always_comb begin
   addr_decode_DSMAS_1 = (req_addr[CAFU_CSR0_CFG_MEM_ADDR_MSB:ADDR_LSB_BUS_ALIGN] == DSMAS_1_DECODE_ADDR) && req.valid ;
   write_req_DSMAS_1 = IsMEMWr && addr_decode_DSMAS_1 && sb_fid_cond_mem_inst_sb && sb_bar_cond_mem_inst_sb;
end

// ----------------------------------------------------------------------
// DSMAS_1.dsmas_1 x8 RW, using RW template.
logic [3:0] up_DSMAS_1_dsmas_1;
always_comb begin
 up_DSMAS_1_dsmas_1 =
    ({4{write_req_DSMAS_1 }} &
    be[7:4]);
end

logic [31:0] nxt_DSMAS_1_dsmas_1;
always_comb begin
 nxt_DSMAS_1_dsmas_1 = write_data[63:32];

end


`RTLGEN_CAFU_CSR0_CFG_EN_FF(gated_clk, rst_n, 8'h0, up_DSMAS_1_dsmas_1[0], nxt_DSMAS_1_dsmas_1[7:0], DSMAS_1.dsmas_1[7:0])
`RTLGEN_CAFU_CSR0_CFG_EN_FF(gated_clk, rst_n, 8'h0, up_DSMAS_1_dsmas_1[1], nxt_DSMAS_1_dsmas_1[15:8], DSMAS_1.dsmas_1[15:8])
`RTLGEN_CAFU_CSR0_CFG_EN_FF(gated_clk, rst_n, 8'h0, up_DSMAS_1_dsmas_1[2], nxt_DSMAS_1_dsmas_1[23:16], DSMAS_1.dsmas_1[23:16])
`RTLGEN_CAFU_CSR0_CFG_EN_FF(gated_clk, rst_n, 8'h0, up_DSMAS_1_dsmas_1[3], nxt_DSMAS_1_dsmas_1[31:24], DSMAS_1.dsmas_1[31:24])

//---------------------------------------------------------------------
// DSMAS_2 Address Decode
logic  addr_decode_DSMAS_2;
logic  write_req_DSMAS_2;
always_comb begin
   addr_decode_DSMAS_2 = (req_addr[CAFU_CSR0_CFG_MEM_ADDR_MSB:ADDR_LSB_BUS_ALIGN] == DSMAS_2_DECODE_ADDR) && req.valid ;
   write_req_DSMAS_2 = IsMEMWr && addr_decode_DSMAS_2 && sb_fid_cond_mem_inst_sb && sb_bar_cond_mem_inst_sb;
end

// ----------------------------------------------------------------------
// DSMAS_2.dsmas_2 x8 RW, using RW template.
logic [3:0] up_DSMAS_2_dsmas_2;
always_comb begin
 up_DSMAS_2_dsmas_2 =
    ({4{write_req_DSMAS_2 }} &
    be[3:0]);
end

logic [31:0] nxt_DSMAS_2_dsmas_2;
always_comb begin
 nxt_DSMAS_2_dsmas_2 = write_data[31:0];

end


`RTLGEN_CAFU_CSR0_CFG_EN_FF(gated_clk, rst_n, 8'h0, up_DSMAS_2_dsmas_2[0], nxt_DSMAS_2_dsmas_2[7:0], DSMAS_2.dsmas_2[7:0])
`RTLGEN_CAFU_CSR0_CFG_EN_FF(gated_clk, rst_n, 8'h0, up_DSMAS_2_dsmas_2[1], nxt_DSMAS_2_dsmas_2[15:8], DSMAS_2.dsmas_2[15:8])
`RTLGEN_CAFU_CSR0_CFG_EN_FF(gated_clk, rst_n, 8'h0, up_DSMAS_2_dsmas_2[2], nxt_DSMAS_2_dsmas_2[23:16], DSMAS_2.dsmas_2[23:16])
`RTLGEN_CAFU_CSR0_CFG_EN_FF(gated_clk, rst_n, 8'h0, up_DSMAS_2_dsmas_2[3], nxt_DSMAS_2_dsmas_2[31:24], DSMAS_2.dsmas_2[31:24])

//---------------------------------------------------------------------
// DSMAS_3 Address Decode
logic  addr_decode_DSMAS_3;
logic  write_req_DSMAS_3;
always_comb begin
   addr_decode_DSMAS_3 = (req_addr[CAFU_CSR0_CFG_MEM_ADDR_MSB:ADDR_LSB_BUS_ALIGN] == DSMAS_3_DECODE_ADDR) && req.valid ;
   write_req_DSMAS_3 = IsMEMWr && addr_decode_DSMAS_3 && sb_fid_cond_mem_inst_sb && sb_bar_cond_mem_inst_sb;
end

// ----------------------------------------------------------------------
// DSMAS_3.dsmas_3 x8 RW, using RW template.
logic [3:0] up_DSMAS_3_dsmas_3;
always_comb begin
 up_DSMAS_3_dsmas_3 =
    ({4{write_req_DSMAS_3 }} &
    be[7:4]);
end

logic [31:0] nxt_DSMAS_3_dsmas_3;
always_comb begin
 nxt_DSMAS_3_dsmas_3 = write_data[63:32];

end


`RTLGEN_CAFU_CSR0_CFG_EN_FF(gated_clk, rst_n, 8'h0, up_DSMAS_3_dsmas_3[0], nxt_DSMAS_3_dsmas_3[7:0], DSMAS_3.dsmas_3[7:0])
`RTLGEN_CAFU_CSR0_CFG_EN_FF(gated_clk, rst_n, 8'h0, up_DSMAS_3_dsmas_3[1], nxt_DSMAS_3_dsmas_3[15:8], DSMAS_3.dsmas_3[15:8])
`RTLGEN_CAFU_CSR0_CFG_EN_FF(gated_clk, rst_n, 8'h0, up_DSMAS_3_dsmas_3[2], nxt_DSMAS_3_dsmas_3[23:16], DSMAS_3.dsmas_3[23:16])
`RTLGEN_CAFU_CSR0_CFG_EN_FF(gated_clk, rst_n, 8'h0, up_DSMAS_3_dsmas_3[3], nxt_DSMAS_3_dsmas_3[31:24], DSMAS_3.dsmas_3[31:24])

//---------------------------------------------------------------------
// DSMAS_4 Address Decode
logic  addr_decode_DSMAS_4;
logic  write_req_DSMAS_4;
always_comb begin
   addr_decode_DSMAS_4 = (req_addr[CAFU_CSR0_CFG_MEM_ADDR_MSB:ADDR_LSB_BUS_ALIGN] == DSMAS_4_DECODE_ADDR) && req.valid ;
   write_req_DSMAS_4 = IsMEMWr && addr_decode_DSMAS_4 && sb_fid_cond_mem_inst_sb && sb_bar_cond_mem_inst_sb;
end

// ----------------------------------------------------------------------
// DSMAS_4.dsmas_4 x8 RW, using RW template.
logic [3:0] up_DSMAS_4_dsmas_4;
always_comb begin
 up_DSMAS_4_dsmas_4 =
    ({4{write_req_DSMAS_4 }} &
    be[3:0]);
end

logic [31:0] nxt_DSMAS_4_dsmas_4;
always_comb begin
 nxt_DSMAS_4_dsmas_4 = write_data[31:0];

end


`RTLGEN_CAFU_CSR0_CFG_EN_FF(gated_clk, rst_n, 8'h0, up_DSMAS_4_dsmas_4[0], nxt_DSMAS_4_dsmas_4[7:0], DSMAS_4.dsmas_4[7:0])
`RTLGEN_CAFU_CSR0_CFG_EN_FF(gated_clk, rst_n, 8'h0, up_DSMAS_4_dsmas_4[1], nxt_DSMAS_4_dsmas_4[15:8], DSMAS_4.dsmas_4[15:8])
`RTLGEN_CAFU_CSR0_CFG_EN_FF(gated_clk, rst_n, 8'h0, up_DSMAS_4_dsmas_4[2], nxt_DSMAS_4_dsmas_4[23:16], DSMAS_4.dsmas_4[23:16])
`RTLGEN_CAFU_CSR0_CFG_EN_FF(gated_clk, rst_n, 8'h0, up_DSMAS_4_dsmas_4[3], nxt_DSMAS_4_dsmas_4[31:24], DSMAS_4.dsmas_4[31:24])

//---------------------------------------------------------------------
// DSMAS_5 Address Decode
logic  addr_decode_DSMAS_5;
logic  write_req_DSMAS_5;
always_comb begin
   addr_decode_DSMAS_5 = (req_addr[CAFU_CSR0_CFG_MEM_ADDR_MSB:ADDR_LSB_BUS_ALIGN] == DSMAS_5_DECODE_ADDR) && req.valid ;
   write_req_DSMAS_5 = IsMEMWr && addr_decode_DSMAS_5 && sb_fid_cond_mem_inst_sb && sb_bar_cond_mem_inst_sb;
end

// ----------------------------------------------------------------------
// DSMAS_5.dsmas_5 x8 RW, using RW template.
logic [3:0] up_DSMAS_5_dsmas_5;
always_comb begin
 up_DSMAS_5_dsmas_5 =
    ({4{write_req_DSMAS_5 }} &
    be[7:4]);
end

logic [31:0] nxt_DSMAS_5_dsmas_5;
always_comb begin
 nxt_DSMAS_5_dsmas_5 = write_data[63:32];

end


`RTLGEN_CAFU_CSR0_CFG_EN_FF(gated_clk, rst_n, 8'h4, up_DSMAS_5_dsmas_5[0], nxt_DSMAS_5_dsmas_5[7:0], DSMAS_5.dsmas_5[7:0])
`RTLGEN_CAFU_CSR0_CFG_EN_FF(gated_clk, rst_n, 8'h0, up_DSMAS_5_dsmas_5[1], nxt_DSMAS_5_dsmas_5[15:8], DSMAS_5.dsmas_5[15:8])
`RTLGEN_CAFU_CSR0_CFG_EN_FF(gated_clk, rst_n, 8'h0, up_DSMAS_5_dsmas_5[2], nxt_DSMAS_5_dsmas_5[23:16], DSMAS_5.dsmas_5[23:16])
`RTLGEN_CAFU_CSR0_CFG_EN_FF(gated_clk, rst_n, 8'h0, up_DSMAS_5_dsmas_5[3], nxt_DSMAS_5_dsmas_5[31:24], DSMAS_5.dsmas_5[31:24])

//---------------------------------------------------------------------
// DSIS_0 Address Decode
logic  addr_decode_DSIS_0;
logic  write_req_DSIS_0;
always_comb begin
   addr_decode_DSIS_0 = (req_addr[CAFU_CSR0_CFG_MEM_ADDR_MSB:ADDR_LSB_BUS_ALIGN] == DSIS_0_DECODE_ADDR) && req.valid ;
   write_req_DSIS_0 = IsMEMWr && addr_decode_DSIS_0 && sb_fid_cond_mem_inst_sb && sb_bar_cond_mem_inst_sb;
end

// ----------------------------------------------------------------------
// DSIS_0.dsis_0 x8 RW, using RW template.
logic [3:0] up_DSIS_0_dsis_0;
always_comb begin
 up_DSIS_0_dsis_0 =
    ({4{write_req_DSIS_0 }} &
    be[3:0]);
end

logic [31:0] nxt_DSIS_0_dsis_0;
always_comb begin
 nxt_DSIS_0_dsis_0 = write_data[31:0];

end


`RTLGEN_CAFU_CSR0_CFG_EN_FF(gated_clk, rst_n, 8'h3, up_DSIS_0_dsis_0[0], nxt_DSIS_0_dsis_0[7:0], DSIS_0.dsis_0[7:0])
`RTLGEN_CAFU_CSR0_CFG_EN_FF(gated_clk, rst_n, 8'h0, up_DSIS_0_dsis_0[1], nxt_DSIS_0_dsis_0[15:8], DSIS_0.dsis_0[15:8])
`RTLGEN_CAFU_CSR0_CFG_EN_FF(gated_clk, rst_n, 8'h8, up_DSIS_0_dsis_0[2], nxt_DSIS_0_dsis_0[23:16], DSIS_0.dsis_0[23:16])
`RTLGEN_CAFU_CSR0_CFG_EN_FF(gated_clk, rst_n, 8'h0, up_DSIS_0_dsis_0[3], nxt_DSIS_0_dsis_0[31:24], DSIS_0.dsis_0[31:24])

//---------------------------------------------------------------------
// DSIS_1 Address Decode
logic  addr_decode_DSIS_1;
logic  write_req_DSIS_1;
always_comb begin
   addr_decode_DSIS_1 = (req_addr[CAFU_CSR0_CFG_MEM_ADDR_MSB:ADDR_LSB_BUS_ALIGN] == DSIS_1_DECODE_ADDR) && req.valid ;
   write_req_DSIS_1 = IsMEMWr && addr_decode_DSIS_1 && sb_fid_cond_mem_inst_sb && sb_bar_cond_mem_inst_sb;
end

// ----------------------------------------------------------------------
// DSIS_1.dsis_1 x8 RW, using RW template.
logic [3:0] up_DSIS_1_dsis_1;
always_comb begin
 up_DSIS_1_dsis_1 =
    ({4{write_req_DSIS_1 }} &
    be[7:4]);
end

logic [31:0] nxt_DSIS_1_dsis_1;
always_comb begin
 nxt_DSIS_1_dsis_1 = write_data[63:32];

end


`RTLGEN_CAFU_CSR0_CFG_EN_FF(gated_clk, rst_n, 8'h1, up_DSIS_1_dsis_1[0], nxt_DSIS_1_dsis_1[7:0], DSIS_1.dsis_1[7:0])
`RTLGEN_CAFU_CSR0_CFG_EN_FF(gated_clk, rst_n, 8'h0, up_DSIS_1_dsis_1[1], nxt_DSIS_1_dsis_1[15:8], DSIS_1.dsis_1[15:8])
`RTLGEN_CAFU_CSR0_CFG_EN_FF(gated_clk, rst_n, 8'h0, up_DSIS_1_dsis_1[2], nxt_DSIS_1_dsis_1[23:16], DSIS_1.dsis_1[23:16])
`RTLGEN_CAFU_CSR0_CFG_EN_FF(gated_clk, rst_n, 8'h0, up_DSIS_1_dsis_1[3], nxt_DSIS_1_dsis_1[31:24], DSIS_1.dsis_1[31:24])

//---------------------------------------------------------------------
// DSLBIS_0 Address Decode
logic  addr_decode_DSLBIS_0;
logic  write_req_DSLBIS_0;
always_comb begin
   addr_decode_DSLBIS_0 = (req_addr[CAFU_CSR0_CFG_MEM_ADDR_MSB:ADDR_LSB_BUS_ALIGN] == DSLBIS_0_DECODE_ADDR) && req.valid ;
   write_req_DSLBIS_0 = IsMEMWr && addr_decode_DSLBIS_0 && sb_fid_cond_mem_inst_sb && sb_bar_cond_mem_inst_sb;
end

// ----------------------------------------------------------------------
// DSLBIS_0.dslbis_0 x8 RW, using RW template.
logic [3:0] up_DSLBIS_0_dslbis_0;
always_comb begin
 up_DSLBIS_0_dslbis_0 =
    ({4{write_req_DSLBIS_0 }} &
    be[3:0]);
end

logic [31:0] nxt_DSLBIS_0_dslbis_0;
always_comb begin
 nxt_DSLBIS_0_dslbis_0 = write_data[31:0];

end


`RTLGEN_CAFU_CSR0_CFG_EN_FF(gated_clk, rst_n, 8'h1, up_DSLBIS_0_dslbis_0[0], nxt_DSLBIS_0_dslbis_0[7:0], DSLBIS_0.dslbis_0[7:0])
`RTLGEN_CAFU_CSR0_CFG_EN_FF(gated_clk, rst_n, 8'h0, up_DSLBIS_0_dslbis_0[1], nxt_DSLBIS_0_dslbis_0[15:8], DSLBIS_0.dslbis_0[15:8])
`RTLGEN_CAFU_CSR0_CFG_EN_FF(gated_clk, rst_n, 8'h18, up_DSLBIS_0_dslbis_0[2], nxt_DSLBIS_0_dslbis_0[23:16], DSLBIS_0.dslbis_0[23:16])
`RTLGEN_CAFU_CSR0_CFG_EN_FF(gated_clk, rst_n, 8'h0, up_DSLBIS_0_dslbis_0[3], nxt_DSLBIS_0_dslbis_0[31:24], DSLBIS_0.dslbis_0[31:24])

//---------------------------------------------------------------------
// DSLBIS_1 Address Decode
logic  addr_decode_DSLBIS_1;
logic  write_req_DSLBIS_1;
always_comb begin
   addr_decode_DSLBIS_1 = (req_addr[CAFU_CSR0_CFG_MEM_ADDR_MSB:ADDR_LSB_BUS_ALIGN] == DSLBIS_1_DECODE_ADDR) && req.valid ;
   write_req_DSLBIS_1 = IsMEMWr && addr_decode_DSLBIS_1 && sb_fid_cond_mem_inst_sb && sb_bar_cond_mem_inst_sb;
end

// ----------------------------------------------------------------------
// DSLBIS_1.dslbis_1 x8 RW, using RW template.
logic [3:0] up_DSLBIS_1_dslbis_1;
always_comb begin
 up_DSLBIS_1_dslbis_1 =
    ({4{write_req_DSLBIS_1 }} &
    be[7:4]);
end

logic [31:0] nxt_DSLBIS_1_dslbis_1;
always_comb begin
 nxt_DSLBIS_1_dslbis_1 = write_data[63:32];

end


`RTLGEN_CAFU_CSR0_CFG_EN_FF(gated_clk, rst_n, 8'h0, up_DSLBIS_1_dslbis_1[0], nxt_DSLBIS_1_dslbis_1[7:0], DSLBIS_1.dslbis_1[7:0])
`RTLGEN_CAFU_CSR0_CFG_EN_FF(gated_clk, rst_n, 8'h0, up_DSLBIS_1_dslbis_1[1], nxt_DSLBIS_1_dslbis_1[15:8], DSLBIS_1.dslbis_1[15:8])
`RTLGEN_CAFU_CSR0_CFG_EN_FF(gated_clk, rst_n, 8'h0, up_DSLBIS_1_dslbis_1[2], nxt_DSLBIS_1_dslbis_1[23:16], DSLBIS_1.dslbis_1[23:16])
`RTLGEN_CAFU_CSR0_CFG_EN_FF(gated_clk, rst_n, 8'h0, up_DSLBIS_1_dslbis_1[3], nxt_DSLBIS_1_dslbis_1[31:24], DSLBIS_1.dslbis_1[31:24])

//---------------------------------------------------------------------
// DSLBIS_2 Address Decode
logic  addr_decode_DSLBIS_2;
logic  write_req_DSLBIS_2;
always_comb begin
   addr_decode_DSLBIS_2 = (req_addr[CAFU_CSR0_CFG_MEM_ADDR_MSB:ADDR_LSB_BUS_ALIGN] == DSLBIS_2_DECODE_ADDR) && req.valid ;
   write_req_DSLBIS_2 = IsMEMWr && addr_decode_DSLBIS_2 && sb_fid_cond_mem_inst_sb && sb_bar_cond_mem_inst_sb;
end

// ----------------------------------------------------------------------
// DSLBIS_2.dslbis_2 x8 RW, using RW template.
logic [3:0] up_DSLBIS_2_dslbis_2;
always_comb begin
 up_DSLBIS_2_dslbis_2 =
    ({4{write_req_DSLBIS_2 }} &
    be[3:0]);
end

logic [31:0] nxt_DSLBIS_2_dslbis_2;
always_comb begin
 nxt_DSLBIS_2_dslbis_2 = write_data[31:0];

end


`RTLGEN_CAFU_CSR0_CFG_EN_FF(gated_clk, rst_n, 8'h0, up_DSLBIS_2_dslbis_2[0], nxt_DSLBIS_2_dslbis_2[7:0], DSLBIS_2.dslbis_2[7:0])
`RTLGEN_CAFU_CSR0_CFG_EN_FF(gated_clk, rst_n, 8'h0, up_DSLBIS_2_dslbis_2[1], nxt_DSLBIS_2_dslbis_2[15:8], DSLBIS_2.dslbis_2[15:8])
`RTLGEN_CAFU_CSR0_CFG_EN_FF(gated_clk, rst_n, 8'h0, up_DSLBIS_2_dslbis_2[2], nxt_DSLBIS_2_dslbis_2[23:16], DSLBIS_2.dslbis_2[23:16])
`RTLGEN_CAFU_CSR0_CFG_EN_FF(gated_clk, rst_n, 8'h0, up_DSLBIS_2_dslbis_2[3], nxt_DSLBIS_2_dslbis_2[31:24], DSLBIS_2.dslbis_2[31:24])

//---------------------------------------------------------------------
// DSLBIS_3 Address Decode
logic  addr_decode_DSLBIS_3;
logic  write_req_DSLBIS_3;
always_comb begin
   addr_decode_DSLBIS_3 = (req_addr[CAFU_CSR0_CFG_MEM_ADDR_MSB:ADDR_LSB_BUS_ALIGN] == DSLBIS_3_DECODE_ADDR) && req.valid ;
   write_req_DSLBIS_3 = IsMEMWr && addr_decode_DSLBIS_3 && sb_fid_cond_mem_inst_sb && sb_bar_cond_mem_inst_sb;
end

// ----------------------------------------------------------------------
// DSLBIS_3.dslbis_3 x8 RW, using RW template.
logic [3:0] up_DSLBIS_3_dslbis_3;
always_comb begin
 up_DSLBIS_3_dslbis_3 =
    ({4{write_req_DSLBIS_3 }} &
    be[7:4]);
end

logic [31:0] nxt_DSLBIS_3_dslbis_3;
always_comb begin
 nxt_DSLBIS_3_dslbis_3 = write_data[63:32];

end


`RTLGEN_CAFU_CSR0_CFG_EN_FF(gated_clk, rst_n, 8'h0, up_DSLBIS_3_dslbis_3[0], nxt_DSLBIS_3_dslbis_3[7:0], DSLBIS_3.dslbis_3[7:0])
`RTLGEN_CAFU_CSR0_CFG_EN_FF(gated_clk, rst_n, 8'h0, up_DSLBIS_3_dslbis_3[1], nxt_DSLBIS_3_dslbis_3[15:8], DSLBIS_3.dslbis_3[15:8])
`RTLGEN_CAFU_CSR0_CFG_EN_FF(gated_clk, rst_n, 8'h0, up_DSLBIS_3_dslbis_3[2], nxt_DSLBIS_3_dslbis_3[23:16], DSLBIS_3.dslbis_3[23:16])
`RTLGEN_CAFU_CSR0_CFG_EN_FF(gated_clk, rst_n, 8'h0, up_DSLBIS_3_dslbis_3[3], nxt_DSLBIS_3_dslbis_3[31:24], DSLBIS_3.dslbis_3[31:24])

//---------------------------------------------------------------------
// DSLBIS_4 Address Decode
logic  addr_decode_DSLBIS_4;
logic  write_req_DSLBIS_4;
always_comb begin
   addr_decode_DSLBIS_4 = (req_addr[CAFU_CSR0_CFG_MEM_ADDR_MSB:ADDR_LSB_BUS_ALIGN] == DSLBIS_4_DECODE_ADDR) && req.valid ;
   write_req_DSLBIS_4 = IsMEMWr && addr_decode_DSLBIS_4 && sb_fid_cond_mem_inst_sb && sb_bar_cond_mem_inst_sb;
end

// ----------------------------------------------------------------------
// DSLBIS_4.dslbis_4 x8 RW, using RW template.
logic [3:0] up_DSLBIS_4_dslbis_4;
always_comb begin
 up_DSLBIS_4_dslbis_4 =
    ({4{write_req_DSLBIS_4 }} &
    be[3:0]);
end

logic [31:0] nxt_DSLBIS_4_dslbis_4;
always_comb begin
 nxt_DSLBIS_4_dslbis_4 = write_data[31:0];

end


`RTLGEN_CAFU_CSR0_CFG_EN_FF(gated_clk, rst_n, 8'h0, up_DSLBIS_4_dslbis_4[0], nxt_DSLBIS_4_dslbis_4[7:0], DSLBIS_4.dslbis_4[7:0])
`RTLGEN_CAFU_CSR0_CFG_EN_FF(gated_clk, rst_n, 8'h0, up_DSLBIS_4_dslbis_4[1], nxt_DSLBIS_4_dslbis_4[15:8], DSLBIS_4.dslbis_4[15:8])
`RTLGEN_CAFU_CSR0_CFG_EN_FF(gated_clk, rst_n, 8'h0, up_DSLBIS_4_dslbis_4[2], nxt_DSLBIS_4_dslbis_4[23:16], DSLBIS_4.dslbis_4[23:16])
`RTLGEN_CAFU_CSR0_CFG_EN_FF(gated_clk, rst_n, 8'h0, up_DSLBIS_4_dslbis_4[3], nxt_DSLBIS_4_dslbis_4[31:24], DSLBIS_4.dslbis_4[31:24])

//---------------------------------------------------------------------
// DSLBIS_5 Address Decode
logic  addr_decode_DSLBIS_5;
logic  write_req_DSLBIS_5;
always_comb begin
   addr_decode_DSLBIS_5 = (req_addr[CAFU_CSR0_CFG_MEM_ADDR_MSB:ADDR_LSB_BUS_ALIGN] == DSLBIS_5_DECODE_ADDR) && req.valid ;
   write_req_DSLBIS_5 = IsMEMWr && addr_decode_DSLBIS_5 && sb_fid_cond_mem_inst_sb && sb_bar_cond_mem_inst_sb;
end

// ----------------------------------------------------------------------
// DSLBIS_5.dslbis_5 x8 RW, using RW template.
logic [3:0] up_DSLBIS_5_dslbis_5;
always_comb begin
 up_DSLBIS_5_dslbis_5 =
    ({4{write_req_DSLBIS_5 }} &
    be[7:4]);
end

logic [31:0] nxt_DSLBIS_5_dslbis_5;
always_comb begin
 nxt_DSLBIS_5_dslbis_5 = write_data[63:32];

end


`RTLGEN_CAFU_CSR0_CFG_EN_FF(gated_clk, rst_n, 8'h0, up_DSLBIS_5_dslbis_5[0], nxt_DSLBIS_5_dslbis_5[7:0], DSLBIS_5.dslbis_5[7:0])
`RTLGEN_CAFU_CSR0_CFG_EN_FF(gated_clk, rst_n, 8'h0, up_DSLBIS_5_dslbis_5[1], nxt_DSLBIS_5_dslbis_5[15:8], DSLBIS_5.dslbis_5[15:8])
`RTLGEN_CAFU_CSR0_CFG_EN_FF(gated_clk, rst_n, 8'h0, up_DSLBIS_5_dslbis_5[2], nxt_DSLBIS_5_dslbis_5[23:16], DSLBIS_5.dslbis_5[23:16])
`RTLGEN_CAFU_CSR0_CFG_EN_FF(gated_clk, rst_n, 8'h0, up_DSLBIS_5_dslbis_5[3], nxt_DSLBIS_5_dslbis_5[31:24], DSLBIS_5.dslbis_5[31:24])

//---------------------------------------------------------------------
// DSEMTS_0 Address Decode
logic  addr_decode_DSEMTS_0;
logic  write_req_DSEMTS_0;
always_comb begin
   addr_decode_DSEMTS_0 = (req_addr[CAFU_CSR0_CFG_MEM_ADDR_MSB:ADDR_LSB_BUS_ALIGN] == DSEMTS_0_DECODE_ADDR) && req.valid ;
   write_req_DSEMTS_0 = IsMEMWr && addr_decode_DSEMTS_0 && sb_fid_cond_mem_inst_sb && sb_bar_cond_mem_inst_sb;
end

// ----------------------------------------------------------------------
// DSEMTS_0.dsemts_0 x8 RW, using RW template.
logic [3:0] up_DSEMTS_0_dsemts_0;
always_comb begin
 up_DSEMTS_0_dsemts_0 =
    ({4{write_req_DSEMTS_0 }} &
    be[3:0]);
end

logic [31:0] nxt_DSEMTS_0_dsemts_0;
always_comb begin
 nxt_DSEMTS_0_dsemts_0 = write_data[31:0];

end


`RTLGEN_CAFU_CSR0_CFG_EN_FF(gated_clk, rst_n, 8'h4, up_DSEMTS_0_dsemts_0[0], nxt_DSEMTS_0_dsemts_0[7:0], DSEMTS_0.dsemts_0[7:0])
`RTLGEN_CAFU_CSR0_CFG_EN_FF(gated_clk, rst_n, 8'h0, up_DSEMTS_0_dsemts_0[1], nxt_DSEMTS_0_dsemts_0[15:8], DSEMTS_0.dsemts_0[15:8])
`RTLGEN_CAFU_CSR0_CFG_EN_FF(gated_clk, rst_n, 8'h18, up_DSEMTS_0_dsemts_0[2], nxt_DSEMTS_0_dsemts_0[23:16], DSEMTS_0.dsemts_0[23:16])
`RTLGEN_CAFU_CSR0_CFG_EN_FF(gated_clk, rst_n, 8'h0, up_DSEMTS_0_dsemts_0[3], nxt_DSEMTS_0_dsemts_0[31:24], DSEMTS_0.dsemts_0[31:24])

//---------------------------------------------------------------------
// DSEMTS_1 Address Decode
logic  addr_decode_DSEMTS_1;
logic  write_req_DSEMTS_1;
always_comb begin
   addr_decode_DSEMTS_1 = (req_addr[CAFU_CSR0_CFG_MEM_ADDR_MSB:ADDR_LSB_BUS_ALIGN] == DSEMTS_1_DECODE_ADDR) && req.valid ;
   write_req_DSEMTS_1 = IsMEMWr && addr_decode_DSEMTS_1 && sb_fid_cond_mem_inst_sb && sb_bar_cond_mem_inst_sb;
end

// ----------------------------------------------------------------------
// DSEMTS_1.dsemts_1 x8 RW, using RW template.
logic [3:0] up_DSEMTS_1_dsemts_1;
always_comb begin
 up_DSEMTS_1_dsemts_1 =
    ({4{write_req_DSEMTS_1 }} &
    be[7:4]);
end

logic [31:0] nxt_DSEMTS_1_dsemts_1;
always_comb begin
 nxt_DSEMTS_1_dsemts_1 = write_data[63:32];

end


`RTLGEN_CAFU_CSR0_CFG_EN_FF(gated_clk, rst_n, 8'h0, up_DSEMTS_1_dsemts_1[0], nxt_DSEMTS_1_dsemts_1[7:0], DSEMTS_1.dsemts_1[7:0])
`RTLGEN_CAFU_CSR0_CFG_EN_FF(gated_clk, rst_n, 8'h1, up_DSEMTS_1_dsemts_1[1], nxt_DSEMTS_1_dsemts_1[15:8], DSEMTS_1.dsemts_1[15:8])
`RTLGEN_CAFU_CSR0_CFG_EN_FF(gated_clk, rst_n, 8'h0, up_DSEMTS_1_dsemts_1[2], nxt_DSEMTS_1_dsemts_1[23:16], DSEMTS_1.dsemts_1[23:16])
`RTLGEN_CAFU_CSR0_CFG_EN_FF(gated_clk, rst_n, 8'h0, up_DSEMTS_1_dsemts_1[3], nxt_DSEMTS_1_dsemts_1[31:24], DSEMTS_1.dsemts_1[31:24])

//---------------------------------------------------------------------
// DSEMTS_2 Address Decode
logic  addr_decode_DSEMTS_2;
logic  write_req_DSEMTS_2;
always_comb begin
   addr_decode_DSEMTS_2 = (req_addr[CAFU_CSR0_CFG_MEM_ADDR_MSB:ADDR_LSB_BUS_ALIGN] == DSEMTS_2_DECODE_ADDR) && req.valid ;
   write_req_DSEMTS_2 = IsMEMWr && addr_decode_DSEMTS_2 && sb_fid_cond_mem_inst_sb && sb_bar_cond_mem_inst_sb;
end

// ----------------------------------------------------------------------
// DSEMTS_2.dsemts_2 x8 RW, using RW template.
logic [3:0] up_DSEMTS_2_dsemts_2;
always_comb begin
 up_DSEMTS_2_dsemts_2 =
    ({4{write_req_DSEMTS_2 }} &
    be[3:0]);
end

logic [31:0] nxt_DSEMTS_2_dsemts_2;
always_comb begin
 nxt_DSEMTS_2_dsemts_2 = write_data[31:0];

end


`RTLGEN_CAFU_CSR0_CFG_EN_FF(gated_clk, rst_n, 8'h0, up_DSEMTS_2_dsemts_2[0], nxt_DSEMTS_2_dsemts_2[7:0], DSEMTS_2.dsemts_2[7:0])
`RTLGEN_CAFU_CSR0_CFG_EN_FF(gated_clk, rst_n, 8'h0, up_DSEMTS_2_dsemts_2[1], nxt_DSEMTS_2_dsemts_2[15:8], DSEMTS_2.dsemts_2[15:8])
`RTLGEN_CAFU_CSR0_CFG_EN_FF(gated_clk, rst_n, 8'h0, up_DSEMTS_2_dsemts_2[2], nxt_DSEMTS_2_dsemts_2[23:16], DSEMTS_2.dsemts_2[23:16])
`RTLGEN_CAFU_CSR0_CFG_EN_FF(gated_clk, rst_n, 8'h0, up_DSEMTS_2_dsemts_2[3], nxt_DSEMTS_2_dsemts_2[31:24], DSEMTS_2.dsemts_2[31:24])

//---------------------------------------------------------------------
// DSEMTS_3 Address Decode
logic  addr_decode_DSEMTS_3;
logic  write_req_DSEMTS_3;
always_comb begin
   addr_decode_DSEMTS_3 = (req_addr[CAFU_CSR0_CFG_MEM_ADDR_MSB:ADDR_LSB_BUS_ALIGN] == DSEMTS_3_DECODE_ADDR) && req.valid ;
   write_req_DSEMTS_3 = IsMEMWr && addr_decode_DSEMTS_3 && sb_fid_cond_mem_inst_sb && sb_bar_cond_mem_inst_sb;
end

// ----------------------------------------------------------------------
// DSEMTS_3.dsemts_3 x8 RW, using RW template.
logic [3:0] up_DSEMTS_3_dsemts_3;
always_comb begin
 up_DSEMTS_3_dsemts_3 =
    ({4{write_req_DSEMTS_3 }} &
    be[7:4]);
end

logic [31:0] nxt_DSEMTS_3_dsemts_3;
always_comb begin
 nxt_DSEMTS_3_dsemts_3 = write_data[63:32];

end


`RTLGEN_CAFU_CSR0_CFG_EN_FF(gated_clk, rst_n, 8'h0, up_DSEMTS_3_dsemts_3[0], nxt_DSEMTS_3_dsemts_3[7:0], DSEMTS_3.dsemts_3[7:0])
`RTLGEN_CAFU_CSR0_CFG_EN_FF(gated_clk, rst_n, 8'h0, up_DSEMTS_3_dsemts_3[1], nxt_DSEMTS_3_dsemts_3[15:8], DSEMTS_3.dsemts_3[15:8])
`RTLGEN_CAFU_CSR0_CFG_EN_FF(gated_clk, rst_n, 8'h0, up_DSEMTS_3_dsemts_3[2], nxt_DSEMTS_3_dsemts_3[23:16], DSEMTS_3.dsemts_3[23:16])
`RTLGEN_CAFU_CSR0_CFG_EN_FF(gated_clk, rst_n, 8'h0, up_DSEMTS_3_dsemts_3[3], nxt_DSEMTS_3_dsemts_3[31:24], DSEMTS_3.dsemts_3[31:24])

//---------------------------------------------------------------------
// DSEMTS_4 Address Decode
logic  addr_decode_DSEMTS_4;
logic  write_req_DSEMTS_4;
always_comb begin
   addr_decode_DSEMTS_4 = (req_addr[CAFU_CSR0_CFG_MEM_ADDR_MSB:ADDR_LSB_BUS_ALIGN] == DSEMTS_4_DECODE_ADDR) && req.valid ;
   write_req_DSEMTS_4 = IsMEMWr && addr_decode_DSEMTS_4 && sb_fid_cond_mem_inst_sb && sb_bar_cond_mem_inst_sb;
end

// ----------------------------------------------------------------------
// DSEMTS_4.dsemts_4 x8 RW, using RW template.
logic [3:0] up_DSEMTS_4_dsemts_4;
always_comb begin
 up_DSEMTS_4_dsemts_4 =
    ({4{write_req_DSEMTS_4 }} &
    be[3:0]);
end

logic [31:0] nxt_DSEMTS_4_dsemts_4;
always_comb begin
 nxt_DSEMTS_4_dsemts_4 = write_data[31:0];

end


`RTLGEN_CAFU_CSR0_CFG_EN_FF(gated_clk, rst_n, 8'h0, up_DSEMTS_4_dsemts_4[0], nxt_DSEMTS_4_dsemts_4[7:0], DSEMTS_4.dsemts_4[7:0])
`RTLGEN_CAFU_CSR0_CFG_EN_FF(gated_clk, rst_n, 8'h0, up_DSEMTS_4_dsemts_4[1], nxt_DSEMTS_4_dsemts_4[15:8], DSEMTS_4.dsemts_4[15:8])
`RTLGEN_CAFU_CSR0_CFG_EN_FF(gated_clk, rst_n, 8'h0, up_DSEMTS_4_dsemts_4[2], nxt_DSEMTS_4_dsemts_4[23:16], DSEMTS_4.dsemts_4[23:16])
`RTLGEN_CAFU_CSR0_CFG_EN_FF(gated_clk, rst_n, 8'h0, up_DSEMTS_4_dsemts_4[3], nxt_DSEMTS_4_dsemts_4[31:24], DSEMTS_4.dsemts_4[31:24])

//---------------------------------------------------------------------
// DSEMTS_5 Address Decode
logic  addr_decode_DSEMTS_5;
logic  write_req_DSEMTS_5;
always_comb begin
   addr_decode_DSEMTS_5 = (req_addr[CAFU_CSR0_CFG_MEM_ADDR_MSB:ADDR_LSB_BUS_ALIGN] == DSEMTS_5_DECODE_ADDR) && req.valid ;
   write_req_DSEMTS_5 = IsMEMWr && addr_decode_DSEMTS_5 && sb_fid_cond_mem_inst_sb && sb_bar_cond_mem_inst_sb;
end

// ----------------------------------------------------------------------
// DSEMTS_5.dsemts_5 x8 RW, using RW template.
logic [3:0] up_DSEMTS_5_dsemts_5;
always_comb begin
 up_DSEMTS_5_dsemts_5 =
    ({4{write_req_DSEMTS_5 }} &
    be[7:4]);
end

logic [31:0] nxt_DSEMTS_5_dsemts_5;
always_comb begin
 nxt_DSEMTS_5_dsemts_5 = write_data[63:32];

end


`RTLGEN_CAFU_CSR0_CFG_EN_FF(gated_clk, rst_n, 8'h0, up_DSEMTS_5_dsemts_5[0], nxt_DSEMTS_5_dsemts_5[7:0], DSEMTS_5.dsemts_5[7:0])
`RTLGEN_CAFU_CSR0_CFG_EN_FF(gated_clk, rst_n, 8'h0, up_DSEMTS_5_dsemts_5[1], nxt_DSEMTS_5_dsemts_5[15:8], DSEMTS_5.dsemts_5[15:8])
`RTLGEN_CAFU_CSR0_CFG_EN_FF(gated_clk, rst_n, 8'h0, up_DSEMTS_5_dsemts_5[2], nxt_DSEMTS_5_dsemts_5[23:16], DSEMTS_5.dsemts_5[23:16])
`RTLGEN_CAFU_CSR0_CFG_EN_FF(gated_clk, rst_n, 8'h0, up_DSEMTS_5_dsemts_5[3], nxt_DSEMTS_5_dsemts_5[31:24], DSEMTS_5.dsemts_5[31:24])

//---------------------------------------------------------------------
// MC_STATUS Address Decode
// ----------------------------------------------------------------------
// MC_STATUS.mc0_status x8 RO/V, using RO/V template.
assign MC_STATUS.mc0_status = new_MC_STATUS.mc0_status;



// ----------------------------------------------------------------------
// MC_STATUS.mc1_status x8 RO/V, using RO/V template.
assign MC_STATUS.mc1_status = new_MC_STATUS.mc1_status;




//---------------------------------------------------------------------
// DEVMEM_SBECNT Address Decode
// ----------------------------------------------------------------------
// DEVMEM_SBECNT.chan0_cnt x8 RO/V, using RO/V template.
assign DEVMEM_SBECNT.chan0_cnt = new_DEVMEM_SBECNT.chan0_cnt;



// ----------------------------------------------------------------------
// DEVMEM_SBECNT.chan1_cnt x8 RO/V, using RO/V template.
assign DEVMEM_SBECNT.chan1_cnt = new_DEVMEM_SBECNT.chan1_cnt;




//---------------------------------------------------------------------
// DEVMEM_DBECNT Address Decode
// ----------------------------------------------------------------------
// DEVMEM_DBECNT.chan0_cnt x8 RO/V, using RO/V template.
assign DEVMEM_DBECNT.chan0_cnt = new_DEVMEM_DBECNT.chan0_cnt;



// ----------------------------------------------------------------------
// DEVMEM_DBECNT.chan1_cnt x8 RO/V, using RO/V template.
assign DEVMEM_DBECNT.chan1_cnt = new_DEVMEM_DBECNT.chan1_cnt;




//---------------------------------------------------------------------
// DEVMEM_POISONCNT Address Decode
// ----------------------------------------------------------------------
// DEVMEM_POISONCNT.chan0_cnt x8 RO/V, using RO/V template.
assign DEVMEM_POISONCNT.chan0_cnt = new_DEVMEM_POISONCNT.chan0_cnt;



// ----------------------------------------------------------------------
// DEVMEM_POISONCNT.chan1_cnt x8 RO/V, using RO/V template.
assign DEVMEM_POISONCNT.chan1_cnt = new_DEVMEM_POISONCNT.chan1_cnt;




//---------------------------------------------------------------------
// MBOX_EVENTINJ Address Decode
logic  addr_decode_MBOX_EVENTINJ;
logic  write_req_MBOX_EVENTINJ;
always_comb begin
   addr_decode_MBOX_EVENTINJ = (req_addr[CAFU_CSR0_CFG_MEM_ADDR_MSB:ADDR_LSB_BUS_ALIGN] == MBOX_EVENTINJ_DECODE_ADDR) && req.valid ;
   write_req_MBOX_EVENTINJ = IsMEMWr && addr_decode_MBOX_EVENTINJ && sb_fid_cond_mem_inst_sb && sb_bar_cond_mem_inst_sb;
end

// ----------------------------------------------------------------------
// MBOX_EVENTINJ.event_trigger x1 RW, using RW template.
logic [0:0] up_MBOX_EVENTINJ_event_trigger;
always_comb begin
 up_MBOX_EVENTINJ_event_trigger =
    ({1{write_req_MBOX_EVENTINJ }} &
    be[0:0]);
end

logic [0:0] nxt_MBOX_EVENTINJ_event_trigger;
always_comb begin
 nxt_MBOX_EVENTINJ_event_trigger = write_data[0:0];

end


`RTLGEN_CAFU_CSR0_CFG_EN_FF(gated_clk, rst_n, 1'h0, up_MBOX_EVENTINJ_event_trigger[0], nxt_MBOX_EVENTINJ_event_trigger[0:0], MBOX_EVENTINJ.event_trigger[0:0])

// ----------------------------------------------------------------------
// MBOX_EVENTINJ.event_severity x2 RW, using RW template.
logic [0:0] up_MBOX_EVENTINJ_event_severity;
always_comb begin
 up_MBOX_EVENTINJ_event_severity =
    ({1{write_req_MBOX_EVENTINJ }} &
    be[0:0]);
end

logic [1:0] nxt_MBOX_EVENTINJ_event_severity;
always_comb begin
 nxt_MBOX_EVENTINJ_event_severity = write_data[2:1];

end


`RTLGEN_CAFU_CSR0_CFG_EN_FF(gated_clk, rst_n, 2'h0, up_MBOX_EVENTINJ_event_severity[0], nxt_MBOX_EVENTINJ_event_severity[1:0], MBOX_EVENTINJ.event_severity[1:0])

// ----------------------------------------------------------------------
// MBOX_EVENTINJ.event_record x1 RW, using RW template.
logic [0:0] up_MBOX_EVENTINJ_event_record;
always_comb begin
 up_MBOX_EVENTINJ_event_record =
    ({1{write_req_MBOX_EVENTINJ }} &
    be[0:0]);
end

logic [0:0] nxt_MBOX_EVENTINJ_event_record;
always_comb begin
 nxt_MBOX_EVENTINJ_event_record = write_data[3:3];

end


`RTLGEN_CAFU_CSR0_CFG_EN_FF(gated_clk, rst_n, 1'h0, up_MBOX_EVENTINJ_event_record[0], nxt_MBOX_EVENTINJ_event_record[0:0], MBOX_EVENTINJ.event_record[0:0])

// ----------------------------------------------------------------------
// MBOX_EVENTINJ.reserved x8 RW, using RW template.
logic [3:0] up_MBOX_EVENTINJ_reserved;
always_comb begin
 up_MBOX_EVENTINJ_reserved =
    ({4{write_req_MBOX_EVENTINJ }} &
    be[3:0]);
end

logic [27:0] nxt_MBOX_EVENTINJ_reserved;
always_comb begin
 nxt_MBOX_EVENTINJ_reserved = write_data[31:4];

end


`RTLGEN_CAFU_CSR0_CFG_EN_FF(gated_clk, rst_n, 4'h0, up_MBOX_EVENTINJ_reserved[0], nxt_MBOX_EVENTINJ_reserved[3:0], MBOX_EVENTINJ.reserved[3:0])
`RTLGEN_CAFU_CSR0_CFG_EN_FF(gated_clk, rst_n, 8'h0, up_MBOX_EVENTINJ_reserved[1], nxt_MBOX_EVENTINJ_reserved[11:4], MBOX_EVENTINJ.reserved[11:4])
`RTLGEN_CAFU_CSR0_CFG_EN_FF(gated_clk, rst_n, 8'h0, up_MBOX_EVENTINJ_reserved[2], nxt_MBOX_EVENTINJ_reserved[19:12], MBOX_EVENTINJ.reserved[19:12])
`RTLGEN_CAFU_CSR0_CFG_EN_FF(gated_clk, rst_n, 8'h0, up_MBOX_EVENTINJ_reserved[3], nxt_MBOX_EVENTINJ_reserved[27:20], MBOX_EVENTINJ.reserved[27:20])

//---------------------------------------------------------------------
// DEVICE_AFU_LATENCY_MODE Address Decode
logic  addr_decode_DEVICE_AFU_LATENCY_MODE;
logic  write_req_DEVICE_AFU_LATENCY_MODE;
always_comb begin
   addr_decode_DEVICE_AFU_LATENCY_MODE = (req_addr[CAFU_CSR0_CFG_MEM_ADDR_MSB:ADDR_LSB_BUS_ALIGN] == DEVICE_AFU_LATENCY_MODE_DECODE_ADDR) && req.valid ;
   write_req_DEVICE_AFU_LATENCY_MODE = IsMEMWr && addr_decode_DEVICE_AFU_LATENCY_MODE && sb_fid_cond_mem_inst_sb && sb_bar_cond_mem_inst_sb;
end

// ----------------------------------------------------------------------
// DEVICE_AFU_LATENCY_MODE.latency_mode_enable x1 RW, using RW template.
logic [0:0] up_DEVICE_AFU_LATENCY_MODE_latency_mode_enable;
always_comb begin
 up_DEVICE_AFU_LATENCY_MODE_latency_mode_enable =
    ({1{write_req_DEVICE_AFU_LATENCY_MODE }} &
    be[0:0]);
end

logic [0:0] nxt_DEVICE_AFU_LATENCY_MODE_latency_mode_enable;
always_comb begin
 nxt_DEVICE_AFU_LATENCY_MODE_latency_mode_enable = write_data[0:0];

end


`RTLGEN_CAFU_CSR0_CFG_EN_FF_SYNCRST(gated_clk, cxl_or_conv_rst_n, 1'h0, up_DEVICE_AFU_LATENCY_MODE_latency_mode_enable[0], nxt_DEVICE_AFU_LATENCY_MODE_latency_mode_enable[0:0], DEVICE_AFU_LATENCY_MODE.latency_mode_enable[0:0])

// ----------------------------------------------------------------------
// DEVICE_AFU_LATENCY_MODE.writes_only_mode_enable x1 RW, using RW template.
logic [0:0] up_DEVICE_AFU_LATENCY_MODE_writes_only_mode_enable;
always_comb begin
 up_DEVICE_AFU_LATENCY_MODE_writes_only_mode_enable =
    ({1{write_req_DEVICE_AFU_LATENCY_MODE }} &
    be[0:0]);
end

logic [0:0] nxt_DEVICE_AFU_LATENCY_MODE_writes_only_mode_enable;
always_comb begin
 nxt_DEVICE_AFU_LATENCY_MODE_writes_only_mode_enable = write_data[1:1];

end


`RTLGEN_CAFU_CSR0_CFG_EN_FF_SYNCRST(gated_clk, cxl_or_conv_rst_n, 1'h0, up_DEVICE_AFU_LATENCY_MODE_writes_only_mode_enable[0], nxt_DEVICE_AFU_LATENCY_MODE_writes_only_mode_enable[0:0], DEVICE_AFU_LATENCY_MODE.writes_only_mode_enable[0:0])

// ----------------------------------------------------------------------
// DEVICE_AFU_LATENCY_MODE.reads_only_mode_enable x1 RW, using RW template.
logic [0:0] up_DEVICE_AFU_LATENCY_MODE_reads_only_mode_enable;
always_comb begin
 up_DEVICE_AFU_LATENCY_MODE_reads_only_mode_enable =
    ({1{write_req_DEVICE_AFU_LATENCY_MODE }} &
    be[0:0]);
end

logic [0:0] nxt_DEVICE_AFU_LATENCY_MODE_reads_only_mode_enable;
always_comb begin
 nxt_DEVICE_AFU_LATENCY_MODE_reads_only_mode_enable = write_data[2:2];

end


`RTLGEN_CAFU_CSR0_CFG_EN_FF_SYNCRST(gated_clk, cxl_or_conv_rst_n, 1'h0, up_DEVICE_AFU_LATENCY_MODE_reads_only_mode_enable[0], nxt_DEVICE_AFU_LATENCY_MODE_reads_only_mode_enable[0:0], DEVICE_AFU_LATENCY_MODE.reads_only_mode_enable[0:0])
// ----------------------------------------------------------------------
// DEVICE_AFU_LATENCY_MODE.total_number_loops x7 RO/V, using RO/V template.
assign DEVICE_AFU_LATENCY_MODE.total_number_loops = new_DEVICE_AFU_LATENCY_MODE.total_number_loops;




// ----------------------------------------------------------------------
// DEVICE_AFU_LATENCY_MODE.clear_number_loops x1 RW, using RW template.
logic [0:0] up_DEVICE_AFU_LATENCY_MODE_clear_number_loops;
always_comb begin
 up_DEVICE_AFU_LATENCY_MODE_clear_number_loops =
    ({1{write_req_DEVICE_AFU_LATENCY_MODE }} &
    be[7:7]);
end

logic [0:0] nxt_DEVICE_AFU_LATENCY_MODE_clear_number_loops;
always_comb begin
 nxt_DEVICE_AFU_LATENCY_MODE_clear_number_loops = write_data[63:63];

end


`RTLGEN_CAFU_CSR0_CFG_EN_FF_SYNCRST(gated_clk, cxl_or_conv_rst_n, 1'h0, up_DEVICE_AFU_LATENCY_MODE_clear_number_loops[0], nxt_DEVICE_AFU_LATENCY_MODE_clear_number_loops[0:0], DEVICE_AFU_LATENCY_MODE.clear_number_loops[0:0])
// Shared registers assignments


// end register logic section }

always_comb begin : MISS_VALID_BLOCK

   unique casez (req_opcode) 
      CFGRD: begin
         ack.read_valid = req_valid;
         ack.write_valid  = 1'b0; 
         ack.write_miss = ack.write_valid; 
         unique casez (case_req_addr_CAFU_CSR0_CFG_CFG) 
           DVSEC_DEV_DECODE_ADDR: begin
              unique casez (req_fid)
                 CFG_INST_SB_SB_FID: ack.read_miss = 1'b0;
                 default: ack.read_miss = ack.read_valid;
              endcase
           end
           DVSEC_FBCAP_HDR2_DECODE_ADDR: begin
              unique casez (req_fid)
                 CFG_INST_SB_SB_FID: ack.read_miss = 1'b0;
                 default: ack.read_miss = ack.read_valid;
              endcase
           end
           DVSEC_FBCTRL2_STATUS2_DECODE_ADDR: begin
              unique casez (req_fid)
                 CFG_INST_SB_SB_FID: ack.read_miss = 1'b0;
                 default: ack.read_miss = ack.read_valid;
              endcase
           end
           DVSEC_FBRANGE1SZHIGH_DECODE_ADDR: begin
              unique casez (req_fid)
                 CFG_INST_SB_SB_FID: ack.read_miss = 1'b0;
                 default: ack.read_miss = ack.read_valid;
              endcase
           end
           DVSEC_FBRANGE1HIGH_DECODE_ADDR: begin
              unique casez (req_fid)
                 CFG_INST_SB_SB_FID: ack.read_miss = 1'b0;
                 default: ack.read_miss = ack.read_valid;
              endcase
           end
           DVSEC_FBRANGE2SZHIGH_DECODE_ADDR: begin
              unique casez (req_fid)
                 CFG_INST_SB_SB_FID: ack.read_miss = 1'b0;
                 default: ack.read_miss = ack.read_valid;
              endcase
           end
           DVSEC_FBRANGE2HIGH_DECODE_ADDR: begin
              unique casez (req_fid)
                 CFG_INST_SB_SB_FID: ack.read_miss = 1'b0;
                 default: ack.read_miss = ack.read_valid;
              endcase
           end
           DVSEC_DOE_DECODE_ADDR: begin
              unique casez (req_fid)
                 CFG_INST_SB_SB_FID: ack.read_miss = 1'b0;
                 default: ack.read_miss = ack.read_valid;
              endcase
           end
           DOE_CTLREG_DECODE_ADDR: begin
              unique casez (req_fid)
                 CFG_INST_SB_SB_FID: ack.read_miss = 1'b0;
                 default: ack.read_miss = ack.read_valid;
              endcase
           end
           DOE_WRMAILREG_DECODE_ADDR: begin
              unique casez (req_fid)
                 CFG_INST_SB_SB_FID: ack.read_miss = 1'b0;
                 default: ack.read_miss = ack.read_valid;
              endcase
           end
           DVSEC_TEST_CAP_DECODE_ADDR: begin
              unique casez (req_fid)
                 CFG_INST_SB_SB_FID: ack.read_miss = 1'b0;
                 default: ack.read_miss = ack.read_valid;
              endcase
           end
           CXL_DVSEC_HEADER_2_DECODE_ADDR: begin
              unique casez (req_fid)
                 CFG_INST_SB_SB_FID: ack.read_miss = 1'b0;
                 default: ack.read_miss = ack.read_valid;
              endcase
           end
           CXL_DVSEC_TEST_CAP2_DECODE_ADDR: begin
              unique casez (req_fid)
                 CFG_INST_SB_SB_FID: ack.read_miss = 1'b0;
                 default: ack.read_miss = ack.read_valid;
              endcase
           end
           CXL_DVSEC_TEST_CNF_BASE_HIGH_DECODE_ADDR: begin
              unique casez (req_fid)
                 CFG_INST_SB_SB_FID: ack.read_miss = 1'b0;
                 default: ack.read_miss = ack.read_valid;
              endcase
           end
            default: ack.read_miss  = ack.read_valid; 
         endcase
      end    
      CFGWR: begin
         ack.write_valid = req_valid;
         ack.read_valid  = 1'b0; 
         ack.read_miss = ack.read_valid;
         unique casez (case_req_addr_CAFU_CSR0_CFG_CFG) 
           DVSEC_DEV_DECODE_ADDR: begin
              unique casez (req_fid)
                 CFG_INST_SB_SB_FID: ack.write_miss = 1'b0;
                 default: ack.write_miss = ack.write_valid;
              endcase
           end
           DVSEC_FBCAP_HDR2_DECODE_ADDR: begin
              unique casez (req_fid)
                 CFG_INST_SB_SB_FID: ack.write_miss = 1'b0;
                 default: ack.write_miss = ack.write_valid;
              endcase
           end
           DVSEC_FBCTRL2_STATUS2_DECODE_ADDR: begin
              unique casez (req_fid)
                 CFG_INST_SB_SB_FID: ack.write_miss = 1'b0;
                 default: ack.write_miss = ack.write_valid;
              endcase
           end
           DVSEC_FBRANGE1SZHIGH_DECODE_ADDR: begin
              unique casez (req_fid)
                 CFG_INST_SB_SB_FID: ack.write_miss = 1'b0;
                 default: ack.write_miss = ack.write_valid;
              endcase
           end
           DVSEC_FBRANGE1HIGH_DECODE_ADDR: begin
              unique casez (req_fid)
                 CFG_INST_SB_SB_FID: ack.write_miss = 1'b0;
                 default: ack.write_miss = ack.write_valid;
              endcase
           end
           DVSEC_FBRANGE2SZHIGH_DECODE_ADDR: begin
              unique casez (req_fid)
                 CFG_INST_SB_SB_FID: ack.write_miss = 1'b0;
                 default: ack.write_miss = ack.write_valid;
              endcase
           end
           DVSEC_FBRANGE2HIGH_DECODE_ADDR: begin
              unique casez (req_fid)
                 CFG_INST_SB_SB_FID: ack.write_miss = 1'b0;
                 default: ack.write_miss = ack.write_valid;
              endcase
           end
           DVSEC_DOE_DECODE_ADDR: begin
              unique casez (req_fid)
                 CFG_INST_SB_SB_FID: ack.write_miss = 1'b0;
                 default: ack.write_miss = ack.write_valid;
              endcase
           end
           DOE_CTLREG_DECODE_ADDR: begin
              unique casez (req_fid)
                 CFG_INST_SB_SB_FID: ack.write_miss = 1'b0;
                 default: ack.write_miss = ack.write_valid;
              endcase
           end
           DOE_WRMAILREG_DECODE_ADDR: begin
              unique casez (req_fid)
                 CFG_INST_SB_SB_FID: ack.write_miss = 1'b0;
                 default: ack.write_miss = ack.write_valid;
              endcase
           end
           DVSEC_TEST_CAP_DECODE_ADDR: begin
              unique casez (req_fid)
                 CFG_INST_SB_SB_FID: ack.write_miss = 1'b0;
                 default: ack.write_miss = ack.write_valid;
              endcase
           end
           CXL_DVSEC_HEADER_2_DECODE_ADDR: begin
              unique casez (req_fid)
                 CFG_INST_SB_SB_FID: ack.write_miss = 1'b0;
                 default: ack.write_miss = ack.write_valid;
              endcase
           end
           CXL_DVSEC_TEST_CAP2_DECODE_ADDR: begin
              unique casez (req_fid)
                 CFG_INST_SB_SB_FID: ack.write_miss = 1'b0;
                 default: ack.write_miss = ack.write_valid;
              endcase
           end
           CXL_DVSEC_TEST_CNF_BASE_HIGH_DECODE_ADDR: begin
              unique casez (req_fid)
                 CFG_INST_SB_SB_FID: ack.write_miss = 1'b0;
                 default: ack.write_miss = ack.write_valid;
              endcase
           end
            default: ack.write_miss = ack.write_valid;
         endcase 
      end  
      MRD: begin
         ack.read_valid = req_valid;
         ack.write_valid  = 1'b0; 
         ack.write_miss = ack.write_valid; 
         unique casez (case_req_addr_CAFU_CSR0_CFG_MEM) 
           CXL_DEV_CAP_ARRAY_0_DECODE_ADDR: begin
              unique casez ({req_fid,req_bar})
                 {MEM_INST_SB_SB_FID,MEM_INST_SB_SB_BAR}: ack.read_miss = 1'b0;
                 default: ack.read_miss = ack.read_valid;
              endcase
           end
           CXL_DEV_CAP_HDR1_0_DECODE_ADDR: begin
              unique casez ({req_fid,req_bar})
                 {MEM_INST_SB_SB_FID,MEM_INST_SB_SB_BAR}: ack.read_miss = 1'b0;
                 default: ack.read_miss = ack.read_valid;
              endcase
           end
           CXL_DEV_CAP_HDR1_2_DECODE_ADDR: begin
              unique casez ({req_fid,req_bar})
                 {MEM_INST_SB_SB_FID,MEM_INST_SB_SB_BAR}: ack.read_miss = 1'b0;
                 default: ack.read_miss = ack.read_valid;
              endcase
           end
           CXL_DEV_CAP_HDR2_0_DECODE_ADDR: begin
              unique casez ({req_fid,req_bar})
                 {MEM_INST_SB_SB_FID,MEM_INST_SB_SB_BAR}: ack.read_miss = 1'b0;
                 default: ack.read_miss = ack.read_valid;
              endcase
           end
           CXL_DEV_CAP_HDR2_2_DECODE_ADDR: begin
              unique casez ({req_fid,req_bar})
                 {MEM_INST_SB_SB_FID,MEM_INST_SB_SB_BAR}: ack.read_miss = 1'b0;
                 default: ack.read_miss = ack.read_valid;
              endcase
           end
           CXL_DEV_CAP_HDR3_0_DECODE_ADDR: begin
              unique casez ({req_fid,req_bar})
                 {MEM_INST_SB_SB_FID,MEM_INST_SB_SB_BAR}: ack.read_miss = 1'b0;
                 default: ack.read_miss = ack.read_valid;
              endcase
           end
           CXL_DEV_CAP_HDR3_2_DECODE_ADDR: begin
              unique casez ({req_fid,req_bar})
                 {MEM_INST_SB_SB_FID,MEM_INST_SB_SB_BAR}: ack.read_miss = 1'b0;
                 default: ack.read_miss = ack.read_valid;
              endcase
           end
           CXL_DEV_CAP_EVENT_STATUS_DECODE_ADDR: begin
              unique casez ({req_fid,req_bar})
                 {MEM_INST_SB_SB_FID,MEM_INST_SB_SB_BAR}: ack.read_miss = 1'b0;
                 default: ack.read_miss = ack.read_valid;
              endcase
           end
           CXL_MEM_DEV_STATUS_DECODE_ADDR: begin
              unique casez ({req_fid,req_bar})
                 {MEM_INST_SB_SB_FID,MEM_INST_SB_SB_BAR}: ack.read_miss = 1'b0;
                 default: ack.read_miss = ack.read_valid;
              endcase
           end
           CXL_MB_CAP_DECODE_ADDR: begin
              unique casez ({req_fid,req_bar})
                 {MEM_INST_SB_SB_FID,MEM_INST_SB_SB_BAR}: ack.read_miss = 1'b0;
                 default: ack.read_miss = ack.read_valid;
              endcase
           end
           CXL_MB_CMD_DECODE_ADDR: begin
              unique casez ({req_fid,req_bar})
                 {MEM_INST_SB_SB_FID,MEM_INST_SB_SB_BAR}: ack.read_miss = 1'b0;
                 default: ack.read_miss = ack.read_valid;
              endcase
           end
           CXL_MB_STATUS_DECODE_ADDR: begin
              unique casez ({req_fid,req_bar})
                 {MEM_INST_SB_SB_FID,MEM_INST_SB_SB_BAR}: ack.read_miss = 1'b0;
                 default: ack.read_miss = ack.read_valid;
              endcase
           end
           CXL_MB_BK_CMD_STATUS_DECODE_ADDR: begin
              unique casez ({req_fid,req_bar})
                 {MEM_INST_SB_SB_FID,MEM_INST_SB_SB_BAR}: ack.read_miss = 1'b0;
                 default: ack.read_miss = ack.read_valid;
              endcase
           end
           CXL_MB_PAY_START_DECODE_ADDR: begin
              unique casez ({req_fid,req_bar})
                 {MEM_INST_SB_SB_FID,MEM_INST_SB_SB_BAR}: ack.read_miss = 1'b0;
                 default: ack.read_miss = ack.read_valid;
              endcase
           end
           CXL_MB_PAY_END_DECODE_ADDR: begin
              unique casez ({req_fid,req_bar})
                 {MEM_INST_SB_SB_FID,MEM_INST_SB_SB_BAR}: ack.read_miss = 1'b0;
                 default: ack.read_miss = ack.read_valid;
              endcase
           end
           HDM_DEC_CAP_DECODE_ADDR: begin
              unique casez ({req_fid,req_bar})
                 {MEM_INST_SB_SB_FID,MEM_INST_SB_SB_BAR}: ack.read_miss = 1'b0;
                 default: ack.read_miss = ack.read_valid;
              endcase
           end
           HDM_DEC_BASELOW_DECODE_ADDR: begin
              unique casez ({req_fid,req_bar})
                 {MEM_INST_SB_SB_FID,MEM_INST_SB_SB_BAR}: ack.read_miss = 1'b0;
                 default: ack.read_miss = ack.read_valid;
              endcase
           end
           HDM_DEC_SIZELOW_DECODE_ADDR: begin
              unique casez ({req_fid,req_bar})
                 {MEM_INST_SB_SB_FID,MEM_INST_SB_SB_BAR}: ack.read_miss = 1'b0;
                 default: ack.read_miss = ack.read_valid;
              endcase
           end
           HDM_DEC_CTRL_DECODE_ADDR: begin
              unique casez ({req_fid,req_bar})
                 {MEM_INST_SB_SB_FID,MEM_INST_SB_SB_BAR}: ack.read_miss = 1'b0;
                 default: ack.read_miss = ack.read_valid;
              endcase
           end
           HDM_DEC_DPAHIGH_DECODE_ADDR: begin
              unique casez ({req_fid,req_bar})
                 {MEM_INST_SB_SB_FID,MEM_INST_SB_SB_BAR}: ack.read_miss = 1'b0;
                 default: ack.read_miss = ack.read_valid;
              endcase
           end
           CONFIG_TEST_START_ADDR_DECODE_ADDR: begin
              unique casez ({req_fid,req_bar})
                 {MEM_INST_SB_SB_FID,MEM_INST_SB_SB_BAR}: ack.read_miss = 1'b0;
                 default: ack.read_miss = ack.read_valid;
              endcase
           end
           CONFIG_TEST_WR_BACK_ADDR_DECODE_ADDR: begin
              unique casez ({req_fid,req_bar})
                 {MEM_INST_SB_SB_FID,MEM_INST_SB_SB_BAR}: ack.read_miss = 1'b0;
                 default: ack.read_miss = ack.read_valid;
              endcase
           end
           CONFIG_TEST_ADDR_INCRE_DECODE_ADDR: begin
              unique casez ({req_fid,req_bar})
                 {MEM_INST_SB_SB_FID,MEM_INST_SB_SB_BAR}: ack.read_miss = 1'b0;
                 default: ack.read_miss = ack.read_valid;
              endcase
           end
           CONFIG_TEST_PATTERN_DECODE_ADDR: begin
              unique casez ({req_fid,req_bar})
                 {MEM_INST_SB_SB_FID,MEM_INST_SB_SB_BAR}: ack.read_miss = 1'b0;
                 default: ack.read_miss = ack.read_valid;
              endcase
           end
           CONFIG_TEST_BYTEMASK_DECODE_ADDR: begin
              unique casez ({req_fid,req_bar})
                 {MEM_INST_SB_SB_FID,MEM_INST_SB_SB_BAR}: ack.read_miss = 1'b0;
                 default: ack.read_miss = ack.read_valid;
              endcase
           end
           CONFIG_TEST_PATTERN_PARAM_DECODE_ADDR: begin
              unique casez ({req_fid,req_bar})
                 {MEM_INST_SB_SB_FID,MEM_INST_SB_SB_BAR}: ack.read_miss = 1'b0;
                 default: ack.read_miss = ack.read_valid;
              endcase
           end
           CONFIG_ALGO_SETTING_DECODE_ADDR: begin
              unique casez ({req_fid,req_bar})
                 {MEM_INST_SB_SB_FID,MEM_INST_SB_SB_BAR}: ack.read_miss = 1'b0;
                 default: ack.read_miss = ack.read_valid;
              endcase
           end
           CONFIG_DEVICE_INJECTION_DECODE_ADDR: begin
              unique casez ({req_fid,req_bar})
                 {MEM_INST_SB_SB_FID,MEM_INST_SB_SB_BAR}: ack.read_miss = 1'b0;
                 default: ack.read_miss = ack.read_valid;
              endcase
           end
           DEVICE_ERROR_LOG1_DECODE_ADDR: begin
              unique casez ({req_fid,req_bar})
                 {MEM_INST_SB_SB_FID,MEM_INST_SB_SB_BAR}: ack.read_miss = 1'b0;
                 default: ack.read_miss = ack.read_valid;
              endcase
           end
           DEVICE_ERROR_LOG2_DECODE_ADDR: begin
              unique casez ({req_fid,req_bar})
                 {MEM_INST_SB_SB_FID,MEM_INST_SB_SB_BAR}: ack.read_miss = 1'b0;
                 default: ack.read_miss = ack.read_valid;
              endcase
           end
           DEVICE_ERROR_LOG3_DECODE_ADDR: begin
              unique casez ({req_fid,req_bar})
                 {MEM_INST_SB_SB_FID,MEM_INST_SB_SB_BAR}: ack.read_miss = 1'b0;
                 default: ack.read_miss = ack.read_valid;
              endcase
           end
           DEVICE_EVENT_CTRL_DECODE_ADDR: begin
              unique casez ({req_fid,req_bar})
                 {MEM_INST_SB_SB_FID,MEM_INST_SB_SB_BAR}: ack.read_miss = 1'b0;
                 default: ack.read_miss = ack.read_valid;
              endcase
           end
           DEVICE_EVENT_COUNT_DECODE_ADDR: begin
              unique casez ({req_fid,req_bar})
                 {MEM_INST_SB_SB_FID,MEM_INST_SB_SB_BAR}: ack.read_miss = 1'b0;
                 default: ack.read_miss = ack.read_valid;
              endcase
           end
           DEVICE_ERROR_INJECTION_DECODE_ADDR: begin
              unique casez ({req_fid,req_bar})
                 {MEM_INST_SB_SB_FID,MEM_INST_SB_SB_BAR}: ack.read_miss = 1'b0;
                 default: ack.read_miss = ack.read_valid;
              endcase
           end
           DEVICE_FORCE_DISABLE_DECODE_ADDR: begin
              unique casez ({req_fid,req_bar})
                 {MEM_INST_SB_SB_FID,MEM_INST_SB_SB_BAR}: ack.read_miss = 1'b0;
                 default: ack.read_miss = ack.read_valid;
              endcase
           end
           DEVICE_ERROR_LOG4_DECODE_ADDR: begin
              unique casez ({req_fid,req_bar})
                 {MEM_INST_SB_SB_FID,MEM_INST_SB_SB_BAR}: ack.read_miss = 1'b0;
                 default: ack.read_miss = ack.read_valid;
              endcase
           end
           DEVICE_ERROR_LOG5_DECODE_ADDR: begin
              unique casez ({req_fid,req_bar})
                 {MEM_INST_SB_SB_FID,MEM_INST_SB_SB_BAR}: ack.read_miss = 1'b0;
                 default: ack.read_miss = ack.read_valid;
              endcase
           end
           CONFIG_CXL_ERRORS_DECODE_ADDR: begin
              unique casez ({req_fid,req_bar})
                 {MEM_INST_SB_SB_FID,MEM_INST_SB_SB_BAR}: ack.read_miss = 1'b0;
                 default: ack.read_miss = ack.read_valid;
              endcase
           end
           DEVICE_AFU_STATUS1_DECODE_ADDR: begin
              unique casez ({req_fid,req_bar})
                 {MEM_INST_SB_SB_FID,MEM_INST_SB_SB_BAR}: ack.read_miss = 1'b0;
                 default: ack.read_miss = ack.read_valid;
              endcase
           end
           DEVICE_AFU_STATUS2_DECODE_ADDR: begin
              unique casez ({req_fid,req_bar})
                 {MEM_INST_SB_SB_FID,MEM_INST_SB_SB_BAR}: ack.read_miss = 1'b0;
                 default: ack.read_miss = ack.read_valid;
              endcase
           end
           DEVICE_AXI2CPI_STATUS_1_DECODE_ADDR: begin
              unique casez ({req_fid,req_bar})
                 {MEM_INST_SB_SB_FID,MEM_INST_SB_SB_BAR}: ack.read_miss = 1'b0;
                 default: ack.read_miss = ack.read_valid;
              endcase
           end
           DEVICE_AXI2CPI_STATUS_2_DECODE_ADDR: begin
              unique casez ({req_fid,req_bar})
                 {MEM_INST_SB_SB_FID,MEM_INST_SB_SB_BAR}: ack.read_miss = 1'b0;
                 default: ack.read_miss = ack.read_valid;
              endcase
           end
           CDAT_0_DECODE_ADDR: begin
              unique casez ({req_fid,req_bar})
                 {MEM_INST_SB_SB_FID,MEM_INST_SB_SB_BAR}: ack.read_miss = 1'b0;
                 default: ack.read_miss = ack.read_valid;
              endcase
           end
           CDAT_2_DECODE_ADDR: begin
              unique casez ({req_fid,req_bar})
                 {MEM_INST_SB_SB_FID,MEM_INST_SB_SB_BAR}: ack.read_miss = 1'b0;
                 default: ack.read_miss = ack.read_valid;
              endcase
           end
           DSMAS_0_DECODE_ADDR: begin
              unique casez ({req_fid,req_bar})
                 {MEM_INST_SB_SB_FID,MEM_INST_SB_SB_BAR}: ack.read_miss = 1'b0;
                 default: ack.read_miss = ack.read_valid;
              endcase
           end
           DSMAS_2_DECODE_ADDR: begin
              unique casez ({req_fid,req_bar})
                 {MEM_INST_SB_SB_FID,MEM_INST_SB_SB_BAR}: ack.read_miss = 1'b0;
                 default: ack.read_miss = ack.read_valid;
              endcase
           end
           DSMAS_4_DECODE_ADDR: begin
              unique casez ({req_fid,req_bar})
                 {MEM_INST_SB_SB_FID,MEM_INST_SB_SB_BAR}: ack.read_miss = 1'b0;
                 default: ack.read_miss = ack.read_valid;
              endcase
           end
           DSIS_0_DECODE_ADDR: begin
              unique casez ({req_fid,req_bar})
                 {MEM_INST_SB_SB_FID,MEM_INST_SB_SB_BAR}: ack.read_miss = 1'b0;
                 default: ack.read_miss = ack.read_valid;
              endcase
           end
           DSLBIS_0_DECODE_ADDR: begin
              unique casez ({req_fid,req_bar})
                 {MEM_INST_SB_SB_FID,MEM_INST_SB_SB_BAR}: ack.read_miss = 1'b0;
                 default: ack.read_miss = ack.read_valid;
              endcase
           end
           DSLBIS_2_DECODE_ADDR: begin
              unique casez ({req_fid,req_bar})
                 {MEM_INST_SB_SB_FID,MEM_INST_SB_SB_BAR}: ack.read_miss = 1'b0;
                 default: ack.read_miss = ack.read_valid;
              endcase
           end
           DSLBIS_4_DECODE_ADDR: begin
              unique casez ({req_fid,req_bar})
                 {MEM_INST_SB_SB_FID,MEM_INST_SB_SB_BAR}: ack.read_miss = 1'b0;
                 default: ack.read_miss = ack.read_valid;
              endcase
           end
           DSEMTS_0_DECODE_ADDR: begin
              unique casez ({req_fid,req_bar})
                 {MEM_INST_SB_SB_FID,MEM_INST_SB_SB_BAR}: ack.read_miss = 1'b0;
                 default: ack.read_miss = ack.read_valid;
              endcase
           end
           DSEMTS_2_DECODE_ADDR: begin
              unique casez ({req_fid,req_bar})
                 {MEM_INST_SB_SB_FID,MEM_INST_SB_SB_BAR}: ack.read_miss = 1'b0;
                 default: ack.read_miss = ack.read_valid;
              endcase
           end
           DSEMTS_4_DECODE_ADDR: begin
              unique casez ({req_fid,req_bar})
                 {MEM_INST_SB_SB_FID,MEM_INST_SB_SB_BAR}: ack.read_miss = 1'b0;
                 default: ack.read_miss = ack.read_valid;
              endcase
           end
           MC_STATUS_DECODE_ADDR: begin
              unique casez ({req_fid,req_bar})
                 {MEM_INST_SB_SB_FID,MEM_INST_SB_SB_BAR}: ack.read_miss = 1'b0;
                 default: ack.read_miss = ack.read_valid;
              endcase
           end
           DEVMEM_SBECNT_DECODE_ADDR: begin
              unique casez ({req_fid,req_bar})
                 {MEM_INST_SB_SB_FID,MEM_INST_SB_SB_BAR}: ack.read_miss = 1'b0;
                 default: ack.read_miss = ack.read_valid;
              endcase
           end
           DEVMEM_DBECNT_DECODE_ADDR: begin
              unique casez ({req_fid,req_bar})
                 {MEM_INST_SB_SB_FID,MEM_INST_SB_SB_BAR}: ack.read_miss = 1'b0;
                 default: ack.read_miss = ack.read_valid;
              endcase
           end
           DEVMEM_POISONCNT_DECODE_ADDR: begin
              unique casez ({req_fid,req_bar})
                 {MEM_INST_SB_SB_FID,MEM_INST_SB_SB_BAR}: ack.read_miss = 1'b0;
                 default: ack.read_miss = ack.read_valid;
              endcase
           end
           MBOX_EVENTINJ_DECODE_ADDR: begin
              unique casez ({req_fid,req_bar})
                 {MEM_INST_SB_SB_FID,MEM_INST_SB_SB_BAR}: ack.read_miss = 1'b0;
                 default: ack.read_miss = ack.read_valid;
              endcase
           end
           DEVICE_AFU_LATENCY_MODE_DECODE_ADDR: begin
              unique casez ({req_fid,req_bar})
                 {MEM_INST_SB_SB_FID,MEM_INST_SB_SB_BAR}: ack.read_miss = 1'b0;
                 default: ack.read_miss = ack.read_valid;
              endcase
           end
            default: ack.read_miss  = ack.read_valid; 
         endcase
      end    
      MWR: begin
         ack.write_valid = req_valid;
         ack.read_valid  = 1'b0; 
         ack.read_miss = ack.read_valid;
         unique casez (case_req_addr_CAFU_CSR0_CFG_MEM) 
           CXL_DEV_CAP_ARRAY_0_DECODE_ADDR: begin
              unique casez ({req_fid,req_bar})
                 {MEM_INST_SB_SB_FID,MEM_INST_SB_SB_BAR}: ack.write_miss = 1'b0;
                 default: ack.write_miss = ack.write_valid;
              endcase
           end
           CXL_DEV_CAP_HDR1_0_DECODE_ADDR: begin
              unique casez ({req_fid,req_bar})
                 {MEM_INST_SB_SB_FID,MEM_INST_SB_SB_BAR}: ack.write_miss = 1'b0;
                 default: ack.write_miss = ack.write_valid;
              endcase
           end
           CXL_DEV_CAP_HDR1_2_DECODE_ADDR: begin
              unique casez ({req_fid,req_bar})
                 {MEM_INST_SB_SB_FID,MEM_INST_SB_SB_BAR}: ack.write_miss = 1'b0;
                 default: ack.write_miss = ack.write_valid;
              endcase
           end
           CXL_DEV_CAP_HDR2_0_DECODE_ADDR: begin
              unique casez ({req_fid,req_bar})
                 {MEM_INST_SB_SB_FID,MEM_INST_SB_SB_BAR}: ack.write_miss = 1'b0;
                 default: ack.write_miss = ack.write_valid;
              endcase
           end
           CXL_DEV_CAP_HDR2_2_DECODE_ADDR: begin
              unique casez ({req_fid,req_bar})
                 {MEM_INST_SB_SB_FID,MEM_INST_SB_SB_BAR}: ack.write_miss = 1'b0;
                 default: ack.write_miss = ack.write_valid;
              endcase
           end
           CXL_DEV_CAP_HDR3_0_DECODE_ADDR: begin
              unique casez ({req_fid,req_bar})
                 {MEM_INST_SB_SB_FID,MEM_INST_SB_SB_BAR}: ack.write_miss = 1'b0;
                 default: ack.write_miss = ack.write_valid;
              endcase
           end
           CXL_DEV_CAP_HDR3_2_DECODE_ADDR: begin
              unique casez ({req_fid,req_bar})
                 {MEM_INST_SB_SB_FID,MEM_INST_SB_SB_BAR}: ack.write_miss = 1'b0;
                 default: ack.write_miss = ack.write_valid;
              endcase
           end
           CXL_DEV_CAP_EVENT_STATUS_DECODE_ADDR: begin
              unique casez ({req_fid,req_bar})
                 {MEM_INST_SB_SB_FID,MEM_INST_SB_SB_BAR}: ack.write_miss = 1'b0;
                 default: ack.write_miss = ack.write_valid;
              endcase
           end
           CXL_MEM_DEV_STATUS_DECODE_ADDR: begin
              unique casez ({req_fid,req_bar})
                 {MEM_INST_SB_SB_FID,MEM_INST_SB_SB_BAR}: ack.write_miss = 1'b0;
                 default: ack.write_miss = ack.write_valid;
              endcase
           end
           CXL_MB_CAP_DECODE_ADDR: begin
              unique casez ({req_fid,req_bar})
                 {MEM_INST_SB_SB_FID,MEM_INST_SB_SB_BAR}: ack.write_miss = 1'b0;
                 default: ack.write_miss = ack.write_valid;
              endcase
           end
           CXL_MB_CMD_DECODE_ADDR: begin
              unique casez ({req_fid,req_bar})
                 {MEM_INST_SB_SB_FID,MEM_INST_SB_SB_BAR}: ack.write_miss = 1'b0;
                 default: ack.write_miss = ack.write_valid;
              endcase
           end
           CXL_MB_STATUS_DECODE_ADDR: begin
              unique casez ({req_fid,req_bar})
                 {MEM_INST_SB_SB_FID,MEM_INST_SB_SB_BAR}: ack.write_miss = 1'b0;
                 default: ack.write_miss = ack.write_valid;
              endcase
           end
           CXL_MB_BK_CMD_STATUS_DECODE_ADDR: begin
              unique casez ({req_fid,req_bar})
                 {MEM_INST_SB_SB_FID,MEM_INST_SB_SB_BAR}: ack.write_miss = 1'b0;
                 default: ack.write_miss = ack.write_valid;
              endcase
           end
           CXL_MB_PAY_START_DECODE_ADDR: begin
              unique casez ({req_fid,req_bar})
                 {MEM_INST_SB_SB_FID,MEM_INST_SB_SB_BAR}: ack.write_miss = 1'b0;
                 default: ack.write_miss = ack.write_valid;
              endcase
           end
           CXL_MB_PAY_END_DECODE_ADDR: begin
              unique casez ({req_fid,req_bar})
                 {MEM_INST_SB_SB_FID,MEM_INST_SB_SB_BAR}: ack.write_miss = 1'b0;
                 default: ack.write_miss = ack.write_valid;
              endcase
           end
           HDM_DEC_CAP_DECODE_ADDR: begin
              unique casez ({req_fid,req_bar})
                 {MEM_INST_SB_SB_FID,MEM_INST_SB_SB_BAR}: ack.write_miss = 1'b0;
                 default: ack.write_miss = ack.write_valid;
              endcase
           end
           HDM_DEC_BASELOW_DECODE_ADDR: begin
              unique casez ({req_fid,req_bar})
                 {MEM_INST_SB_SB_FID,MEM_INST_SB_SB_BAR}: ack.write_miss = 1'b0;
                 default: ack.write_miss = ack.write_valid;
              endcase
           end
           HDM_DEC_SIZELOW_DECODE_ADDR: begin
              unique casez ({req_fid,req_bar})
                 {MEM_INST_SB_SB_FID,MEM_INST_SB_SB_BAR}: ack.write_miss = 1'b0;
                 default: ack.write_miss = ack.write_valid;
              endcase
           end
           HDM_DEC_CTRL_DECODE_ADDR: begin
              unique casez ({req_fid,req_bar})
                 {MEM_INST_SB_SB_FID,MEM_INST_SB_SB_BAR}: ack.write_miss = 1'b0;
                 default: ack.write_miss = ack.write_valid;
              endcase
           end
           HDM_DEC_DPAHIGH_DECODE_ADDR: begin
              unique casez ({req_fid,req_bar})
                 {MEM_INST_SB_SB_FID,MEM_INST_SB_SB_BAR}: ack.write_miss = 1'b0;
                 default: ack.write_miss = ack.write_valid;
              endcase
           end
           CONFIG_TEST_START_ADDR_DECODE_ADDR: begin
              unique casez ({req_fid,req_bar})
                 {MEM_INST_SB_SB_FID,MEM_INST_SB_SB_BAR}: ack.write_miss = 1'b0;
                 default: ack.write_miss = ack.write_valid;
              endcase
           end
           CONFIG_TEST_WR_BACK_ADDR_DECODE_ADDR: begin
              unique casez ({req_fid,req_bar})
                 {MEM_INST_SB_SB_FID,MEM_INST_SB_SB_BAR}: ack.write_miss = 1'b0;
                 default: ack.write_miss = ack.write_valid;
              endcase
           end
           CONFIG_TEST_ADDR_INCRE_DECODE_ADDR: begin
              unique casez ({req_fid,req_bar})
                 {MEM_INST_SB_SB_FID,MEM_INST_SB_SB_BAR}: ack.write_miss = 1'b0;
                 default: ack.write_miss = ack.write_valid;
              endcase
           end
           CONFIG_TEST_PATTERN_DECODE_ADDR: begin
              unique casez ({req_fid,req_bar})
                 {MEM_INST_SB_SB_FID,MEM_INST_SB_SB_BAR}: ack.write_miss = 1'b0;
                 default: ack.write_miss = ack.write_valid;
              endcase
           end
           CONFIG_TEST_BYTEMASK_DECODE_ADDR: begin
              unique casez ({req_fid,req_bar})
                 {MEM_INST_SB_SB_FID,MEM_INST_SB_SB_BAR}: ack.write_miss = 1'b0;
                 default: ack.write_miss = ack.write_valid;
              endcase
           end
           CONFIG_TEST_PATTERN_PARAM_DECODE_ADDR: begin
              unique casez ({req_fid,req_bar})
                 {MEM_INST_SB_SB_FID,MEM_INST_SB_SB_BAR}: ack.write_miss = 1'b0;
                 default: ack.write_miss = ack.write_valid;
              endcase
           end
           CONFIG_ALGO_SETTING_DECODE_ADDR: begin
              unique casez ({req_fid,req_bar})
                 {MEM_INST_SB_SB_FID,MEM_INST_SB_SB_BAR}: ack.write_miss = 1'b0;
                 default: ack.write_miss = ack.write_valid;
              endcase
           end
           CONFIG_DEVICE_INJECTION_DECODE_ADDR: begin
              unique casez ({req_fid,req_bar})
                 {MEM_INST_SB_SB_FID,MEM_INST_SB_SB_BAR}: ack.write_miss = 1'b0;
                 default: ack.write_miss = ack.write_valid;
              endcase
           end
           DEVICE_ERROR_LOG1_DECODE_ADDR: begin
              unique casez ({req_fid,req_bar})
                 {MEM_INST_SB_SB_FID,MEM_INST_SB_SB_BAR}: ack.write_miss = 1'b0;
                 default: ack.write_miss = ack.write_valid;
              endcase
           end
           DEVICE_ERROR_LOG2_DECODE_ADDR: begin
              unique casez ({req_fid,req_bar})
                 {MEM_INST_SB_SB_FID,MEM_INST_SB_SB_BAR}: ack.write_miss = 1'b0;
                 default: ack.write_miss = ack.write_valid;
              endcase
           end
           DEVICE_ERROR_LOG3_DECODE_ADDR: begin
              unique casez ({req_fid,req_bar})
                 {MEM_INST_SB_SB_FID,MEM_INST_SB_SB_BAR}: ack.write_miss = 1'b0;
                 default: ack.write_miss = ack.write_valid;
              endcase
           end
           DEVICE_EVENT_CTRL_DECODE_ADDR: begin
              unique casez ({req_fid,req_bar})
                 {MEM_INST_SB_SB_FID,MEM_INST_SB_SB_BAR}: ack.write_miss = 1'b0;
                 default: ack.write_miss = ack.write_valid;
              endcase
           end
           DEVICE_EVENT_COUNT_DECODE_ADDR: begin
              unique casez ({req_fid,req_bar})
                 {MEM_INST_SB_SB_FID,MEM_INST_SB_SB_BAR}: ack.write_miss = 1'b0;
                 default: ack.write_miss = ack.write_valid;
              endcase
           end
           DEVICE_ERROR_INJECTION_DECODE_ADDR: begin
              unique casez ({req_fid,req_bar})
                 {MEM_INST_SB_SB_FID,MEM_INST_SB_SB_BAR}: ack.write_miss = 1'b0;
                 default: ack.write_miss = ack.write_valid;
              endcase
           end
           DEVICE_FORCE_DISABLE_DECODE_ADDR: begin
              unique casez ({req_fid,req_bar})
                 {MEM_INST_SB_SB_FID,MEM_INST_SB_SB_BAR}: ack.write_miss = 1'b0;
                 default: ack.write_miss = ack.write_valid;
              endcase
           end
           DEVICE_ERROR_LOG4_DECODE_ADDR: begin
              unique casez ({req_fid,req_bar})
                 {MEM_INST_SB_SB_FID,MEM_INST_SB_SB_BAR}: ack.write_miss = 1'b0;
                 default: ack.write_miss = ack.write_valid;
              endcase
           end
           DEVICE_ERROR_LOG5_DECODE_ADDR: begin
              unique casez ({req_fid,req_bar})
                 {MEM_INST_SB_SB_FID,MEM_INST_SB_SB_BAR}: ack.write_miss = 1'b0;
                 default: ack.write_miss = ack.write_valid;
              endcase
           end
           CONFIG_CXL_ERRORS_DECODE_ADDR: begin
              unique casez ({req_fid,req_bar})
                 {MEM_INST_SB_SB_FID,MEM_INST_SB_SB_BAR}: ack.write_miss = 1'b0;
                 default: ack.write_miss = ack.write_valid;
              endcase
           end
           DEVICE_AFU_STATUS1_DECODE_ADDR: begin
              unique casez ({req_fid,req_bar})
                 {MEM_INST_SB_SB_FID,MEM_INST_SB_SB_BAR}: ack.write_miss = 1'b0;
                 default: ack.write_miss = ack.write_valid;
              endcase
           end
           DEVICE_AFU_STATUS2_DECODE_ADDR: begin
              unique casez ({req_fid,req_bar})
                 {MEM_INST_SB_SB_FID,MEM_INST_SB_SB_BAR}: ack.write_miss = 1'b0;
                 default: ack.write_miss = ack.write_valid;
              endcase
           end
           DEVICE_AXI2CPI_STATUS_1_DECODE_ADDR: begin
              unique casez ({req_fid,req_bar})
                 {MEM_INST_SB_SB_FID,MEM_INST_SB_SB_BAR}: ack.write_miss = 1'b0;
                 default: ack.write_miss = ack.write_valid;
              endcase
           end
           DEVICE_AXI2CPI_STATUS_2_DECODE_ADDR: begin
              unique casez ({req_fid,req_bar})
                 {MEM_INST_SB_SB_FID,MEM_INST_SB_SB_BAR}: ack.write_miss = 1'b0;
                 default: ack.write_miss = ack.write_valid;
              endcase
           end
           CDAT_0_DECODE_ADDR: begin
              unique casez ({req_fid,req_bar})
                 {MEM_INST_SB_SB_FID,MEM_INST_SB_SB_BAR}: ack.write_miss = 1'b0;
                 default: ack.write_miss = ack.write_valid;
              endcase
           end
           CDAT_2_DECODE_ADDR: begin
              unique casez ({req_fid,req_bar})
                 {MEM_INST_SB_SB_FID,MEM_INST_SB_SB_BAR}: ack.write_miss = 1'b0;
                 default: ack.write_miss = ack.write_valid;
              endcase
           end
           DSMAS_0_DECODE_ADDR: begin
              unique casez ({req_fid,req_bar})
                 {MEM_INST_SB_SB_FID,MEM_INST_SB_SB_BAR}: ack.write_miss = 1'b0;
                 default: ack.write_miss = ack.write_valid;
              endcase
           end
           DSMAS_2_DECODE_ADDR: begin
              unique casez ({req_fid,req_bar})
                 {MEM_INST_SB_SB_FID,MEM_INST_SB_SB_BAR}: ack.write_miss = 1'b0;
                 default: ack.write_miss = ack.write_valid;
              endcase
           end
           DSMAS_4_DECODE_ADDR: begin
              unique casez ({req_fid,req_bar})
                 {MEM_INST_SB_SB_FID,MEM_INST_SB_SB_BAR}: ack.write_miss = 1'b0;
                 default: ack.write_miss = ack.write_valid;
              endcase
           end
           DSIS_0_DECODE_ADDR: begin
              unique casez ({req_fid,req_bar})
                 {MEM_INST_SB_SB_FID,MEM_INST_SB_SB_BAR}: ack.write_miss = 1'b0;
                 default: ack.write_miss = ack.write_valid;
              endcase
           end
           DSLBIS_0_DECODE_ADDR: begin
              unique casez ({req_fid,req_bar})
                 {MEM_INST_SB_SB_FID,MEM_INST_SB_SB_BAR}: ack.write_miss = 1'b0;
                 default: ack.write_miss = ack.write_valid;
              endcase
           end
           DSLBIS_2_DECODE_ADDR: begin
              unique casez ({req_fid,req_bar})
                 {MEM_INST_SB_SB_FID,MEM_INST_SB_SB_BAR}: ack.write_miss = 1'b0;
                 default: ack.write_miss = ack.write_valid;
              endcase
           end
           DSLBIS_4_DECODE_ADDR: begin
              unique casez ({req_fid,req_bar})
                 {MEM_INST_SB_SB_FID,MEM_INST_SB_SB_BAR}: ack.write_miss = 1'b0;
                 default: ack.write_miss = ack.write_valid;
              endcase
           end
           DSEMTS_0_DECODE_ADDR: begin
              unique casez ({req_fid,req_bar})
                 {MEM_INST_SB_SB_FID,MEM_INST_SB_SB_BAR}: ack.write_miss = 1'b0;
                 default: ack.write_miss = ack.write_valid;
              endcase
           end
           DSEMTS_2_DECODE_ADDR: begin
              unique casez ({req_fid,req_bar})
                 {MEM_INST_SB_SB_FID,MEM_INST_SB_SB_BAR}: ack.write_miss = 1'b0;
                 default: ack.write_miss = ack.write_valid;
              endcase
           end
           DSEMTS_4_DECODE_ADDR: begin
              unique casez ({req_fid,req_bar})
                 {MEM_INST_SB_SB_FID,MEM_INST_SB_SB_BAR}: ack.write_miss = 1'b0;
                 default: ack.write_miss = ack.write_valid;
              endcase
           end
           MC_STATUS_DECODE_ADDR: begin
              unique casez ({req_fid,req_bar})
                 {MEM_INST_SB_SB_FID,MEM_INST_SB_SB_BAR}: ack.write_miss = 1'b0;
                 default: ack.write_miss = ack.write_valid;
              endcase
           end
           DEVMEM_SBECNT_DECODE_ADDR: begin
              unique casez ({req_fid,req_bar})
                 {MEM_INST_SB_SB_FID,MEM_INST_SB_SB_BAR}: ack.write_miss = 1'b0;
                 default: ack.write_miss = ack.write_valid;
              endcase
           end
           DEVMEM_DBECNT_DECODE_ADDR: begin
              unique casez ({req_fid,req_bar})
                 {MEM_INST_SB_SB_FID,MEM_INST_SB_SB_BAR}: ack.write_miss = 1'b0;
                 default: ack.write_miss = ack.write_valid;
              endcase
           end
           DEVMEM_POISONCNT_DECODE_ADDR: begin
              unique casez ({req_fid,req_bar})
                 {MEM_INST_SB_SB_FID,MEM_INST_SB_SB_BAR}: ack.write_miss = 1'b0;
                 default: ack.write_miss = ack.write_valid;
              endcase
           end
           MBOX_EVENTINJ_DECODE_ADDR: begin
              unique casez ({req_fid,req_bar})
                 {MEM_INST_SB_SB_FID,MEM_INST_SB_SB_BAR}: ack.write_miss = 1'b0;
                 default: ack.write_miss = ack.write_valid;
              endcase
           end
           DEVICE_AFU_LATENCY_MODE_DECODE_ADDR: begin
              unique casez ({req_fid,req_bar})
                 {MEM_INST_SB_SB_FID,MEM_INST_SB_SB_BAR}: ack.write_miss = 1'b0;
                 default: ack.write_miss = ack.write_valid;
              endcase
           end
            default: ack.write_miss = ack.write_valid;
         endcase 
      end  
      default: begin
         ack.write_valid  = req_valid & IsWrOpcode;
         ack.read_valid  = req_valid & IsRdOpcode;
         ack.read_miss  = ack.read_valid;
         ack.write_miss = ack.write_valid;
      end 
   endcase 
end

always_comb begin : SAI_BLOCK

   unique casez (req_opcode) 
      CFGRD: 
         unique casez (case_req_addr_CAFU_CSR0_CFG_CFG) 
           DVSEC_DEV_DECODE_ADDR: begin
              unique casez (req_fid)
                 CFG_INST_SB_SB_FID: sai_successfull_per_byte = {{4{1'b1}},{4{1'b1}}};
                 default: sai_successfull_per_byte = {8{1'b1}};
              endcase
           end
           DVSEC_FBCAP_HDR2_DECODE_ADDR: begin
              unique casez (req_fid)
                 CFG_INST_SB_SB_FID: sai_successfull_per_byte = {{4{1'b1}},{4{1'b1}}};
                 default: sai_successfull_per_byte = {8{1'b1}};
              endcase
           end
           DVSEC_FBCTRL2_STATUS2_DECODE_ADDR: begin
              unique casez (req_fid)
                 CFG_INST_SB_SB_FID: sai_successfull_per_byte = {{4{1'b1}},{4{1'b1}}};
                 default: sai_successfull_per_byte = {8{1'b1}};
              endcase
           end
           DVSEC_FBRANGE1SZHIGH_DECODE_ADDR: begin
              unique casez (req_fid)
                 CFG_INST_SB_SB_FID: sai_successfull_per_byte = {{4{1'b1}},{4{1'b1}}};
                 default: sai_successfull_per_byte = {8{1'b1}};
              endcase
           end
           DVSEC_FBRANGE1HIGH_DECODE_ADDR: begin
              unique casez (req_fid)
                 CFG_INST_SB_SB_FID: sai_successfull_per_byte = {{4{1'b1}},{4{1'b1}}};
                 default: sai_successfull_per_byte = {8{1'b1}};
              endcase
           end
           DVSEC_FBRANGE2SZHIGH_DECODE_ADDR: begin
              unique casez (req_fid)
                 CFG_INST_SB_SB_FID: sai_successfull_per_byte = {{4{1'b1}},{4{1'b1}}};
                 default: sai_successfull_per_byte = {8{1'b1}};
              endcase
           end
           DVSEC_FBRANGE2HIGH_DECODE_ADDR: begin
              unique casez (req_fid)
                 CFG_INST_SB_SB_FID: sai_successfull_per_byte = {{4{1'b1}},{4{1'b1}}};
                 default: sai_successfull_per_byte = {8{1'b1}};
              endcase
           end
           DVSEC_DOE_DECODE_ADDR: begin
              unique casez (req_fid)
                 CFG_INST_SB_SB_FID: sai_successfull_per_byte = {{4{1'b1}},{4{1'b1}}};
                 default: sai_successfull_per_byte = {8{1'b1}};
              endcase
           end
           DOE_CTLREG_DECODE_ADDR: begin
              unique casez (req_fid)
                 CFG_INST_SB_SB_FID: sai_successfull_per_byte = {{4{1'b1}},{4{1'b1}}};
                 default: sai_successfull_per_byte = {8{1'b1}};
              endcase
           end
           DOE_WRMAILREG_DECODE_ADDR: begin
              unique casez (req_fid)
                 CFG_INST_SB_SB_FID: sai_successfull_per_byte = {{4{1'b1}},{4{1'b1}}};
                 default: sai_successfull_per_byte = {8{1'b1}};
              endcase
           end
           DVSEC_TEST_CAP_DECODE_ADDR: begin
              unique casez (req_fid)
                 CFG_INST_SB_SB_FID: sai_successfull_per_byte = {{4{1'b1}},{4{1'b1}}};
                 default: sai_successfull_per_byte = {8{1'b1}};
              endcase
           end
           CXL_DVSEC_HEADER_2_DECODE_ADDR: begin
              unique casez (req_fid)
                 CFG_INST_SB_SB_FID: sai_successfull_per_byte = {{4{1'b1}},{2{1'b1}},{2{1'b1}}};
                 default: sai_successfull_per_byte = {8{1'b1}};
              endcase
           end
           CXL_DVSEC_TEST_CAP2_DECODE_ADDR: begin
              unique casez (req_fid)
                 CFG_INST_SB_SB_FID: sai_successfull_per_byte = {{4{1'b1}},{2{1'b1}},{2{1'b1}}};
                 default: sai_successfull_per_byte = {8{1'b1}};
              endcase
           end
           CXL_DVSEC_TEST_CNF_BASE_HIGH_DECODE_ADDR: begin
              unique casez (req_fid)
                 CFG_INST_SB_SB_FID: sai_successfull_per_byte = {{4{1'b1}},{4{1'b1}}};
                 default: sai_successfull_per_byte = {8{1'b1}};
              endcase
           end
            default: sai_successfull_per_byte = {8{1'b1}};
         endcase 
      CFGWR: 
         unique casez (case_req_addr_CAFU_CSR0_CFG_CFG) 
           DVSEC_DEV_DECODE_ADDR: begin
              unique casez (req_fid)
                 CFG_INST_SB_SB_FID: sai_successfull_per_byte = {{4{1'b1}},{4{1'b1}}};
                 default: sai_successfull_per_byte = {8{1'b1}};
              endcase
           end
           DVSEC_FBCAP_HDR2_DECODE_ADDR: begin
              unique casez (req_fid)
                 CFG_INST_SB_SB_FID: sai_successfull_per_byte = {{4{1'b1}},{4{1'b1}}};
                 default: sai_successfull_per_byte = {8{1'b1}};
              endcase
           end
           DVSEC_FBCTRL2_STATUS2_DECODE_ADDR: begin
              unique casez (req_fid)
                 CFG_INST_SB_SB_FID: sai_successfull_per_byte = {{4{1'b1}},{4{1'b1}}};
                 default: sai_successfull_per_byte = {8{1'b1}};
              endcase
           end
           DVSEC_FBRANGE1SZHIGH_DECODE_ADDR: begin
              unique casez (req_fid)
                 CFG_INST_SB_SB_FID: sai_successfull_per_byte = {{4{1'b1}},{4{1'b1}}};
                 default: sai_successfull_per_byte = {8{1'b1}};
              endcase
           end
           DVSEC_FBRANGE1HIGH_DECODE_ADDR: begin
              unique casez (req_fid)
                 CFG_INST_SB_SB_FID: sai_successfull_per_byte = {{4{1'b1}},{4{1'b1}}};
                 default: sai_successfull_per_byte = {8{1'b1}};
              endcase
           end
           DVSEC_FBRANGE2SZHIGH_DECODE_ADDR: begin
              unique casez (req_fid)
                 CFG_INST_SB_SB_FID: sai_successfull_per_byte = {{4{1'b1}},{4{1'b1}}};
                 default: sai_successfull_per_byte = {8{1'b1}};
              endcase
           end
           DVSEC_FBRANGE2HIGH_DECODE_ADDR: begin
              unique casez (req_fid)
                 CFG_INST_SB_SB_FID: sai_successfull_per_byte = {{4{1'b1}},{4{1'b1}}};
                 default: sai_successfull_per_byte = {8{1'b1}};
              endcase
           end
           DVSEC_DOE_DECODE_ADDR: begin
              unique casez (req_fid)
                 CFG_INST_SB_SB_FID: sai_successfull_per_byte = {{4{1'b1}},{4{1'b1}}};
                 default: sai_successfull_per_byte = {8{1'b1}};
              endcase
           end
           DOE_CTLREG_DECODE_ADDR: begin
              unique casez (req_fid)
                 CFG_INST_SB_SB_FID: sai_successfull_per_byte = {{4{1'b1}},{4{1'b1}}};
                 default: sai_successfull_per_byte = {8{1'b1}};
              endcase
           end
           DOE_WRMAILREG_DECODE_ADDR: begin
              unique casez (req_fid)
                 CFG_INST_SB_SB_FID: sai_successfull_per_byte = {{4{1'b1}},{4{1'b1}}};
                 default: sai_successfull_per_byte = {8{1'b1}};
              endcase
           end
           DVSEC_TEST_CAP_DECODE_ADDR: begin
              unique casez (req_fid)
                 CFG_INST_SB_SB_FID: sai_successfull_per_byte = {{4{1'b1}},{4{1'b1}}};
                 default: sai_successfull_per_byte = {8{1'b1}};
              endcase
           end
           CXL_DVSEC_HEADER_2_DECODE_ADDR: begin
              unique casez (req_fid)
                 CFG_INST_SB_SB_FID: sai_successfull_per_byte = {{4{1'b1}},{2{1'b1}},{2{1'b1}}};
                 default: sai_successfull_per_byte = {8{1'b1}};
              endcase
           end
           CXL_DVSEC_TEST_CAP2_DECODE_ADDR: begin
              unique casez (req_fid)
                 CFG_INST_SB_SB_FID: sai_successfull_per_byte = {{4{1'b1}},{2{1'b1}},{2{1'b1}}};
                 default: sai_successfull_per_byte = {8{1'b1}};
              endcase
           end
           CXL_DVSEC_TEST_CNF_BASE_HIGH_DECODE_ADDR: begin
              unique casez (req_fid)
                 CFG_INST_SB_SB_FID: sai_successfull_per_byte = {{4{1'b1}},{4{1'b1}}};
                 default: sai_successfull_per_byte = {8{1'b1}};
              endcase
           end
            default: sai_successfull_per_byte = {8{1'b1}};
         endcase 
      MRD: 
         unique casez (case_req_addr_CAFU_CSR0_CFG_MEM) 
           CXL_DEV_CAP_ARRAY_0_DECODE_ADDR: begin
              unique casez ({req_fid,req_bar})
                 {MEM_INST_SB_SB_FID,MEM_INST_SB_SB_BAR}: sai_successfull_per_byte = {{4{1'b1}},{4{1'b1}}};
                 default: sai_successfull_per_byte = {8{1'b1}};
              endcase
           end
           CXL_DEV_CAP_HDR1_0_DECODE_ADDR: begin
              unique casez ({req_fid,req_bar})
                 {MEM_INST_SB_SB_FID,MEM_INST_SB_SB_BAR}: sai_successfull_per_byte = {{4{1'b1}},{4{1'b1}}};
                 default: sai_successfull_per_byte = {8{1'b1}};
              endcase
           end
           CXL_DEV_CAP_HDR1_2_DECODE_ADDR: begin
              unique casez ({req_fid,req_bar})
                 {MEM_INST_SB_SB_FID,MEM_INST_SB_SB_BAR}: sai_successfull_per_byte = {{4{1'b1}},{4{1'b1}}};
                 default: sai_successfull_per_byte = {8{1'b1}};
              endcase
           end
           CXL_DEV_CAP_HDR2_0_DECODE_ADDR: begin
              unique casez ({req_fid,req_bar})
                 {MEM_INST_SB_SB_FID,MEM_INST_SB_SB_BAR}: sai_successfull_per_byte = {{4{1'b1}},{4{1'b1}}};
                 default: sai_successfull_per_byte = {8{1'b1}};
              endcase
           end
           CXL_DEV_CAP_HDR2_2_DECODE_ADDR: begin
              unique casez ({req_fid,req_bar})
                 {MEM_INST_SB_SB_FID,MEM_INST_SB_SB_BAR}: sai_successfull_per_byte = {{4{1'b1}},{4{1'b1}}};
                 default: sai_successfull_per_byte = {8{1'b1}};
              endcase
           end
           CXL_DEV_CAP_HDR3_0_DECODE_ADDR: begin
              unique casez ({req_fid,req_bar})
                 {MEM_INST_SB_SB_FID,MEM_INST_SB_SB_BAR}: sai_successfull_per_byte = {{4{1'b1}},{4{1'b1}}};
                 default: sai_successfull_per_byte = {8{1'b1}};
              endcase
           end
           CXL_DEV_CAP_HDR3_2_DECODE_ADDR: begin
              unique casez ({req_fid,req_bar})
                 {MEM_INST_SB_SB_FID,MEM_INST_SB_SB_BAR}: sai_successfull_per_byte = {{4{1'b1}},{4{1'b1}}};
                 default: sai_successfull_per_byte = {8{1'b1}};
              endcase
           end
           CXL_DEV_CAP_EVENT_STATUS_DECODE_ADDR: begin
              unique casez ({req_fid,req_bar})
                 {MEM_INST_SB_SB_FID,MEM_INST_SB_SB_BAR}: sai_successfull_per_byte = {{4{1'b1}},{4{1'b1}}};
                 default: sai_successfull_per_byte = {8{1'b1}};
              endcase
           end
           CXL_MEM_DEV_STATUS_DECODE_ADDR: begin
              unique casez ({req_fid,req_bar})
                 {MEM_INST_SB_SB_FID,MEM_INST_SB_SB_BAR}: sai_successfull_per_byte = {{4{1'b1}},{4{1'b1}}};
                 default: sai_successfull_per_byte = {8{1'b1}};
              endcase
           end
           CXL_MB_CAP_DECODE_ADDR: begin
              unique casez ({req_fid,req_bar})
                 {MEM_INST_SB_SB_FID,MEM_INST_SB_SB_BAR}: sai_successfull_per_byte = {{4{1'b1}},{4{1'b1}}};
                 default: sai_successfull_per_byte = {8{1'b1}};
              endcase
           end
           CXL_MB_CMD_DECODE_ADDR: begin
              unique casez ({req_fid,req_bar})
                 {MEM_INST_SB_SB_FID,MEM_INST_SB_SB_BAR}: sai_successfull_per_byte = {{8{1'b1}}};
                 default: sai_successfull_per_byte = {8{1'b1}};
              endcase
           end
           CXL_MB_STATUS_DECODE_ADDR: begin
              unique casez ({req_fid,req_bar})
                 {MEM_INST_SB_SB_FID,MEM_INST_SB_SB_BAR}: sai_successfull_per_byte = {{8{1'b1}}};
                 default: sai_successfull_per_byte = {8{1'b1}};
              endcase
           end
           CXL_MB_BK_CMD_STATUS_DECODE_ADDR: begin
              unique casez ({req_fid,req_bar})
                 {MEM_INST_SB_SB_FID,MEM_INST_SB_SB_BAR}: sai_successfull_per_byte = {{8{1'b1}}};
                 default: sai_successfull_per_byte = {8{1'b1}};
              endcase
           end
           CXL_MB_PAY_START_DECODE_ADDR: begin
              unique casez ({req_fid,req_bar})
                 {MEM_INST_SB_SB_FID,MEM_INST_SB_SB_BAR}: sai_successfull_per_byte = {{4{1'b1}},{4{1'b1}}};
                 default: sai_successfull_per_byte = {8{1'b1}};
              endcase
           end
           CXL_MB_PAY_END_DECODE_ADDR: begin
              unique casez ({req_fid,req_bar})
                 {MEM_INST_SB_SB_FID,MEM_INST_SB_SB_BAR}: sai_successfull_per_byte = {{4{1'b1}},{4{1'b1}}};
                 default: sai_successfull_per_byte = {8{1'b1}};
              endcase
           end
           HDM_DEC_CAP_DECODE_ADDR: begin
              unique casez ({req_fid,req_bar})
                 {MEM_INST_SB_SB_FID,MEM_INST_SB_SB_BAR}: sai_successfull_per_byte = {{4{1'b1}},{4{1'b1}}};
                 default: sai_successfull_per_byte = {8{1'b1}};
              endcase
           end
           HDM_DEC_BASELOW_DECODE_ADDR: begin
              unique casez ({req_fid,req_bar})
                 {MEM_INST_SB_SB_FID,MEM_INST_SB_SB_BAR}: sai_successfull_per_byte = {{4{1'b1}},{4{1'b1}}};
                 default: sai_successfull_per_byte = {8{1'b1}};
              endcase
           end
           HDM_DEC_SIZELOW_DECODE_ADDR: begin
              unique casez ({req_fid,req_bar})
                 {MEM_INST_SB_SB_FID,MEM_INST_SB_SB_BAR}: sai_successfull_per_byte = {{4{1'b1}},{4{1'b1}}};
                 default: sai_successfull_per_byte = {8{1'b1}};
              endcase
           end
           HDM_DEC_CTRL_DECODE_ADDR: begin
              unique casez ({req_fid,req_bar})
                 {MEM_INST_SB_SB_FID,MEM_INST_SB_SB_BAR}: sai_successfull_per_byte = {{4{1'b1}},{4{1'b1}}};
                 default: sai_successfull_per_byte = {8{1'b1}};
              endcase
           end
           HDM_DEC_DPAHIGH_DECODE_ADDR: begin
              unique casez ({req_fid,req_bar})
                 {MEM_INST_SB_SB_FID,MEM_INST_SB_SB_BAR}: sai_successfull_per_byte = {{4{1'b1}},{4{1'b1}}};
                 default: sai_successfull_per_byte = {8{1'b1}};
              endcase
           end
           CONFIG_TEST_START_ADDR_DECODE_ADDR: begin
              unique casez ({req_fid,req_bar})
                 {MEM_INST_SB_SB_FID,MEM_INST_SB_SB_BAR}: sai_successfull_per_byte = {{8{1'b1}}};
                 default: sai_successfull_per_byte = {8{1'b1}};
              endcase
           end
           CONFIG_TEST_WR_BACK_ADDR_DECODE_ADDR: begin
              unique casez ({req_fid,req_bar})
                 {MEM_INST_SB_SB_FID,MEM_INST_SB_SB_BAR}: sai_successfull_per_byte = {{8{1'b1}}};
                 default: sai_successfull_per_byte = {8{1'b1}};
              endcase
           end
           CONFIG_TEST_ADDR_INCRE_DECODE_ADDR: begin
              unique casez ({req_fid,req_bar})
                 {MEM_INST_SB_SB_FID,MEM_INST_SB_SB_BAR}: sai_successfull_per_byte = {{8{1'b1}}};
                 default: sai_successfull_per_byte = {8{1'b1}};
              endcase
           end
           CONFIG_TEST_PATTERN_DECODE_ADDR: begin
              unique casez ({req_fid,req_bar})
                 {MEM_INST_SB_SB_FID,MEM_INST_SB_SB_BAR}: sai_successfull_per_byte = {{8{1'b1}}};
                 default: sai_successfull_per_byte = {8{1'b1}};
              endcase
           end
           CONFIG_TEST_BYTEMASK_DECODE_ADDR: begin
              unique casez ({req_fid,req_bar})
                 {MEM_INST_SB_SB_FID,MEM_INST_SB_SB_BAR}: sai_successfull_per_byte = {{8{1'b1}}};
                 default: sai_successfull_per_byte = {8{1'b1}};
              endcase
           end
           CONFIG_TEST_PATTERN_PARAM_DECODE_ADDR: begin
              unique casez ({req_fid,req_bar})
                 {MEM_INST_SB_SB_FID,MEM_INST_SB_SB_BAR}: sai_successfull_per_byte = {{8{1'b1}}};
                 default: sai_successfull_per_byte = {8{1'b1}};
              endcase
           end
           CONFIG_ALGO_SETTING_DECODE_ADDR: begin
              unique casez ({req_fid,req_bar})
                 {MEM_INST_SB_SB_FID,MEM_INST_SB_SB_BAR}: sai_successfull_per_byte = {{8{1'b1}}};
                 default: sai_successfull_per_byte = {8{1'b1}};
              endcase
           end
           CONFIG_DEVICE_INJECTION_DECODE_ADDR: begin
              unique casez ({req_fid,req_bar})
                 {MEM_INST_SB_SB_FID,MEM_INST_SB_SB_BAR}: sai_successfull_per_byte = {{4{1'b1}},{4{1'b1}}};
                 default: sai_successfull_per_byte = {8{1'b1}};
              endcase
           end
           DEVICE_ERROR_LOG1_DECODE_ADDR: begin
              unique casez ({req_fid,req_bar})
                 {MEM_INST_SB_SB_FID,MEM_INST_SB_SB_BAR}: sai_successfull_per_byte = {{8{1'b1}}};
                 default: sai_successfull_per_byte = {8{1'b1}};
              endcase
           end
           DEVICE_ERROR_LOG2_DECODE_ADDR: begin
              unique casez ({req_fid,req_bar})
                 {MEM_INST_SB_SB_FID,MEM_INST_SB_SB_BAR}: sai_successfull_per_byte = {{8{1'b1}}};
                 default: sai_successfull_per_byte = {8{1'b1}};
              endcase
           end
           DEVICE_ERROR_LOG3_DECODE_ADDR: begin
              unique casez ({req_fid,req_bar})
                 {MEM_INST_SB_SB_FID,MEM_INST_SB_SB_BAR}: sai_successfull_per_byte = {{8{1'b1}}};
                 default: sai_successfull_per_byte = {8{1'b1}};
              endcase
           end
           DEVICE_EVENT_CTRL_DECODE_ADDR: begin
              unique casez ({req_fid,req_bar})
                 {MEM_INST_SB_SB_FID,MEM_INST_SB_SB_BAR}: sai_successfull_per_byte = {{8{1'b1}}};
                 default: sai_successfull_per_byte = {8{1'b1}};
              endcase
           end
           DEVICE_EVENT_COUNT_DECODE_ADDR: begin
              unique casez ({req_fid,req_bar})
                 {MEM_INST_SB_SB_FID,MEM_INST_SB_SB_BAR}: sai_successfull_per_byte = {{8{1'b1}}};
                 default: sai_successfull_per_byte = {8{1'b1}};
              endcase
           end
           DEVICE_ERROR_INJECTION_DECODE_ADDR: begin
              unique casez ({req_fid,req_bar})
                 {MEM_INST_SB_SB_FID,MEM_INST_SB_SB_BAR}: sai_successfull_per_byte = {{8{1'b1}}};
                 default: sai_successfull_per_byte = {8{1'b1}};
              endcase
           end
           DEVICE_FORCE_DISABLE_DECODE_ADDR: begin
              unique casez ({req_fid,req_bar})
                 {MEM_INST_SB_SB_FID,MEM_INST_SB_SB_BAR}: sai_successfull_per_byte = {{8{1'b1}}};
                 default: sai_successfull_per_byte = {8{1'b1}};
              endcase
           end
           DEVICE_ERROR_LOG4_DECODE_ADDR: begin
              unique casez ({req_fid,req_bar})
                 {MEM_INST_SB_SB_FID,MEM_INST_SB_SB_BAR}: sai_successfull_per_byte = {{8{1'b1}}};
                 default: sai_successfull_per_byte = {8{1'b1}};
              endcase
           end
           DEVICE_ERROR_LOG5_DECODE_ADDR: begin
              unique casez ({req_fid,req_bar})
                 {MEM_INST_SB_SB_FID,MEM_INST_SB_SB_BAR}: sai_successfull_per_byte = {{8{1'b1}}};
                 default: sai_successfull_per_byte = {8{1'b1}};
              endcase
           end
           CONFIG_CXL_ERRORS_DECODE_ADDR: begin
              unique casez ({req_fid,req_bar})
                 {MEM_INST_SB_SB_FID,MEM_INST_SB_SB_BAR}: sai_successfull_per_byte = {{8{1'b1}}};
                 default: sai_successfull_per_byte = {8{1'b1}};
              endcase
           end
           DEVICE_AFU_STATUS1_DECODE_ADDR: begin
              unique casez ({req_fid,req_bar})
                 {MEM_INST_SB_SB_FID,MEM_INST_SB_SB_BAR}: sai_successfull_per_byte = {{8{1'b1}}};
                 default: sai_successfull_per_byte = {8{1'b1}};
              endcase
           end
           DEVICE_AFU_STATUS2_DECODE_ADDR: begin
              unique casez ({req_fid,req_bar})
                 {MEM_INST_SB_SB_FID,MEM_INST_SB_SB_BAR}: sai_successfull_per_byte = {{8{1'b1}}};
                 default: sai_successfull_per_byte = {8{1'b1}};
              endcase
           end
           DEVICE_AXI2CPI_STATUS_1_DECODE_ADDR: begin
              unique casez ({req_fid,req_bar})
                 {MEM_INST_SB_SB_FID,MEM_INST_SB_SB_BAR}: sai_successfull_per_byte = {{8{1'b1}}};
                 default: sai_successfull_per_byte = {8{1'b1}};
              endcase
           end
           DEVICE_AXI2CPI_STATUS_2_DECODE_ADDR: begin
              unique casez ({req_fid,req_bar})
                 {MEM_INST_SB_SB_FID,MEM_INST_SB_SB_BAR}: sai_successfull_per_byte = {{8{1'b1}}};
                 default: sai_successfull_per_byte = {8{1'b1}};
              endcase
           end
           CDAT_0_DECODE_ADDR: begin
              unique casez ({req_fid,req_bar})
                 {MEM_INST_SB_SB_FID,MEM_INST_SB_SB_BAR}: sai_successfull_per_byte = {{4{1'b1}},{4{1'b1}}};
                 default: sai_successfull_per_byte = {8{1'b1}};
              endcase
           end
           CDAT_2_DECODE_ADDR: begin
              unique casez ({req_fid,req_bar})
                 {MEM_INST_SB_SB_FID,MEM_INST_SB_SB_BAR}: sai_successfull_per_byte = {{4{1'b1}},{4{1'b1}}};
                 default: sai_successfull_per_byte = {8{1'b1}};
              endcase
           end
           DSMAS_0_DECODE_ADDR: begin
              unique casez ({req_fid,req_bar})
                 {MEM_INST_SB_SB_FID,MEM_INST_SB_SB_BAR}: sai_successfull_per_byte = {{4{1'b1}},{4{1'b1}}};
                 default: sai_successfull_per_byte = {8{1'b1}};
              endcase
           end
           DSMAS_2_DECODE_ADDR: begin
              unique casez ({req_fid,req_bar})
                 {MEM_INST_SB_SB_FID,MEM_INST_SB_SB_BAR}: sai_successfull_per_byte = {{4{1'b1}},{4{1'b1}}};
                 default: sai_successfull_per_byte = {8{1'b1}};
              endcase
           end
           DSMAS_4_DECODE_ADDR: begin
              unique casez ({req_fid,req_bar})
                 {MEM_INST_SB_SB_FID,MEM_INST_SB_SB_BAR}: sai_successfull_per_byte = {{4{1'b1}},{4{1'b1}}};
                 default: sai_successfull_per_byte = {8{1'b1}};
              endcase
           end
           DSIS_0_DECODE_ADDR: begin
              unique casez ({req_fid,req_bar})
                 {MEM_INST_SB_SB_FID,MEM_INST_SB_SB_BAR}: sai_successfull_per_byte = {{4{1'b1}},{4{1'b1}}};
                 default: sai_successfull_per_byte = {8{1'b1}};
              endcase
           end
           DSLBIS_0_DECODE_ADDR: begin
              unique casez ({req_fid,req_bar})
                 {MEM_INST_SB_SB_FID,MEM_INST_SB_SB_BAR}: sai_successfull_per_byte = {{4{1'b1}},{4{1'b1}}};
                 default: sai_successfull_per_byte = {8{1'b1}};
              endcase
           end
           DSLBIS_2_DECODE_ADDR: begin
              unique casez ({req_fid,req_bar})
                 {MEM_INST_SB_SB_FID,MEM_INST_SB_SB_BAR}: sai_successfull_per_byte = {{4{1'b1}},{4{1'b1}}};
                 default: sai_successfull_per_byte = {8{1'b1}};
              endcase
           end
           DSLBIS_4_DECODE_ADDR: begin
              unique casez ({req_fid,req_bar})
                 {MEM_INST_SB_SB_FID,MEM_INST_SB_SB_BAR}: sai_successfull_per_byte = {{4{1'b1}},{4{1'b1}}};
                 default: sai_successfull_per_byte = {8{1'b1}};
              endcase
           end
           DSEMTS_0_DECODE_ADDR: begin
              unique casez ({req_fid,req_bar})
                 {MEM_INST_SB_SB_FID,MEM_INST_SB_SB_BAR}: sai_successfull_per_byte = {{4{1'b1}},{4{1'b1}}};
                 default: sai_successfull_per_byte = {8{1'b1}};
              endcase
           end
           DSEMTS_2_DECODE_ADDR: begin
              unique casez ({req_fid,req_bar})
                 {MEM_INST_SB_SB_FID,MEM_INST_SB_SB_BAR}: sai_successfull_per_byte = {{4{1'b1}},{4{1'b1}}};
                 default: sai_successfull_per_byte = {8{1'b1}};
              endcase
           end
           DSEMTS_4_DECODE_ADDR: begin
              unique casez ({req_fid,req_bar})
                 {MEM_INST_SB_SB_FID,MEM_INST_SB_SB_BAR}: sai_successfull_per_byte = {{4{1'b1}},{4{1'b1}}};
                 default: sai_successfull_per_byte = {8{1'b1}};
              endcase
           end
           MC_STATUS_DECODE_ADDR: begin
              unique casez ({req_fid,req_bar})
                 {MEM_INST_SB_SB_FID,MEM_INST_SB_SB_BAR}: sai_successfull_per_byte = {{4{1'b1}},{4{1'b1}}};
                 default: sai_successfull_per_byte = {8{1'b1}};
              endcase
           end
           DEVMEM_SBECNT_DECODE_ADDR: begin
              unique casez ({req_fid,req_bar})
                 {MEM_INST_SB_SB_FID,MEM_INST_SB_SB_BAR}: sai_successfull_per_byte = {{8{1'b1}}};
                 default: sai_successfull_per_byte = {8{1'b1}};
              endcase
           end
           DEVMEM_DBECNT_DECODE_ADDR: begin
              unique casez ({req_fid,req_bar})
                 {MEM_INST_SB_SB_FID,MEM_INST_SB_SB_BAR}: sai_successfull_per_byte = {{8{1'b1}}};
                 default: sai_successfull_per_byte = {8{1'b1}};
              endcase
           end
           DEVMEM_POISONCNT_DECODE_ADDR: begin
              unique casez ({req_fid,req_bar})
                 {MEM_INST_SB_SB_FID,MEM_INST_SB_SB_BAR}: sai_successfull_per_byte = {{8{1'b1}}};
                 default: sai_successfull_per_byte = {8{1'b1}};
              endcase
           end
           MBOX_EVENTINJ_DECODE_ADDR: begin
              unique casez ({req_fid,req_bar})
                 {MEM_INST_SB_SB_FID,MEM_INST_SB_SB_BAR}: sai_successfull_per_byte = {{4{1'b1}},{4{1'b1}}};
                 default: sai_successfull_per_byte = {8{1'b1}};
              endcase
           end
           DEVICE_AFU_LATENCY_MODE_DECODE_ADDR: begin
              unique casez ({req_fid,req_bar})
                 {MEM_INST_SB_SB_FID,MEM_INST_SB_SB_BAR}: sai_successfull_per_byte = {{8{1'b1}}};
                 default: sai_successfull_per_byte = {8{1'b1}};
              endcase
           end
            default: sai_successfull_per_byte = {8{1'b1}};
         endcase 
      MWR: 
         unique casez (case_req_addr_CAFU_CSR0_CFG_MEM) 
           CXL_DEV_CAP_ARRAY_0_DECODE_ADDR: begin
              unique casez ({req_fid,req_bar})
                 {MEM_INST_SB_SB_FID,MEM_INST_SB_SB_BAR}: sai_successfull_per_byte = {{4{1'b1}},{4{1'b1}}};
                 default: sai_successfull_per_byte = {8{1'b1}};
              endcase
           end
           CXL_DEV_CAP_HDR1_0_DECODE_ADDR: begin
              unique casez ({req_fid,req_bar})
                 {MEM_INST_SB_SB_FID,MEM_INST_SB_SB_BAR}: sai_successfull_per_byte = {{4{1'b1}},{4{1'b1}}};
                 default: sai_successfull_per_byte = {8{1'b1}};
              endcase
           end
           CXL_DEV_CAP_HDR1_2_DECODE_ADDR: begin
              unique casez ({req_fid,req_bar})
                 {MEM_INST_SB_SB_FID,MEM_INST_SB_SB_BAR}: sai_successfull_per_byte = {{4{1'b1}},{4{1'b1}}};
                 default: sai_successfull_per_byte = {8{1'b1}};
              endcase
           end
           CXL_DEV_CAP_HDR2_0_DECODE_ADDR: begin
              unique casez ({req_fid,req_bar})
                 {MEM_INST_SB_SB_FID,MEM_INST_SB_SB_BAR}: sai_successfull_per_byte = {{4{1'b1}},{4{1'b1}}};
                 default: sai_successfull_per_byte = {8{1'b1}};
              endcase
           end
           CXL_DEV_CAP_HDR2_2_DECODE_ADDR: begin
              unique casez ({req_fid,req_bar})
                 {MEM_INST_SB_SB_FID,MEM_INST_SB_SB_BAR}: sai_successfull_per_byte = {{4{1'b1}},{4{1'b1}}};
                 default: sai_successfull_per_byte = {8{1'b1}};
              endcase
           end
           CXL_DEV_CAP_HDR3_0_DECODE_ADDR: begin
              unique casez ({req_fid,req_bar})
                 {MEM_INST_SB_SB_FID,MEM_INST_SB_SB_BAR}: sai_successfull_per_byte = {{4{1'b1}},{4{1'b1}}};
                 default: sai_successfull_per_byte = {8{1'b1}};
              endcase
           end
           CXL_DEV_CAP_HDR3_2_DECODE_ADDR: begin
              unique casez ({req_fid,req_bar})
                 {MEM_INST_SB_SB_FID,MEM_INST_SB_SB_BAR}: sai_successfull_per_byte = {{4{1'b1}},{4{1'b1}}};
                 default: sai_successfull_per_byte = {8{1'b1}};
              endcase
           end
           CXL_DEV_CAP_EVENT_STATUS_DECODE_ADDR: begin
              unique casez ({req_fid,req_bar})
                 {MEM_INST_SB_SB_FID,MEM_INST_SB_SB_BAR}: sai_successfull_per_byte = {{4{1'b1}},{4{1'b1}}};
                 default: sai_successfull_per_byte = {8{1'b1}};
              endcase
           end
           CXL_MEM_DEV_STATUS_DECODE_ADDR: begin
              unique casez ({req_fid,req_bar})
                 {MEM_INST_SB_SB_FID,MEM_INST_SB_SB_BAR}: sai_successfull_per_byte = {{4{1'b1}},{4{1'b1}}};
                 default: sai_successfull_per_byte = {8{1'b1}};
              endcase
           end
           CXL_MB_CAP_DECODE_ADDR: begin
              unique casez ({req_fid,req_bar})
                 {MEM_INST_SB_SB_FID,MEM_INST_SB_SB_BAR}: sai_successfull_per_byte = {{4{1'b1}},{4{1'b1}}};
                 default: sai_successfull_per_byte = {8{1'b1}};
              endcase
           end
           CXL_MB_CMD_DECODE_ADDR: begin
              unique casez ({req_fid,req_bar})
                 {MEM_INST_SB_SB_FID,MEM_INST_SB_SB_BAR}: sai_successfull_per_byte = {{8{1'b1}}};
                 default: sai_successfull_per_byte = {8{1'b1}};
              endcase
           end
           CXL_MB_STATUS_DECODE_ADDR: begin
              unique casez ({req_fid,req_bar})
                 {MEM_INST_SB_SB_FID,MEM_INST_SB_SB_BAR}: sai_successfull_per_byte = {{8{1'b1}}};
                 default: sai_successfull_per_byte = {8{1'b1}};
              endcase
           end
           CXL_MB_BK_CMD_STATUS_DECODE_ADDR: begin
              unique casez ({req_fid,req_bar})
                 {MEM_INST_SB_SB_FID,MEM_INST_SB_SB_BAR}: sai_successfull_per_byte = {{8{1'b1}}};
                 default: sai_successfull_per_byte = {8{1'b1}};
              endcase
           end
           CXL_MB_PAY_START_DECODE_ADDR: begin
              unique casez ({req_fid,req_bar})
                 {MEM_INST_SB_SB_FID,MEM_INST_SB_SB_BAR}: sai_successfull_per_byte = {{4{1'b1}},{4{1'b1}}};
                 default: sai_successfull_per_byte = {8{1'b1}};
              endcase
           end
           CXL_MB_PAY_END_DECODE_ADDR: begin
              unique casez ({req_fid,req_bar})
                 {MEM_INST_SB_SB_FID,MEM_INST_SB_SB_BAR}: sai_successfull_per_byte = {{4{1'b1}},{4{1'b1}}};
                 default: sai_successfull_per_byte = {8{1'b1}};
              endcase
           end
           HDM_DEC_CAP_DECODE_ADDR: begin
              unique casez ({req_fid,req_bar})
                 {MEM_INST_SB_SB_FID,MEM_INST_SB_SB_BAR}: sai_successfull_per_byte = {{4{1'b1}},{4{1'b1}}};
                 default: sai_successfull_per_byte = {8{1'b1}};
              endcase
           end
           HDM_DEC_BASELOW_DECODE_ADDR: begin
              unique casez ({req_fid,req_bar})
                 {MEM_INST_SB_SB_FID,MEM_INST_SB_SB_BAR}: sai_successfull_per_byte = {{4{1'b1}},{4{1'b1}}};
                 default: sai_successfull_per_byte = {8{1'b1}};
              endcase
           end
           HDM_DEC_SIZELOW_DECODE_ADDR: begin
              unique casez ({req_fid,req_bar})
                 {MEM_INST_SB_SB_FID,MEM_INST_SB_SB_BAR}: sai_successfull_per_byte = {{4{1'b1}},{4{1'b1}}};
                 default: sai_successfull_per_byte = {8{1'b1}};
              endcase
           end
           HDM_DEC_CTRL_DECODE_ADDR: begin
              unique casez ({req_fid,req_bar})
                 {MEM_INST_SB_SB_FID,MEM_INST_SB_SB_BAR}: sai_successfull_per_byte = {{4{1'b1}},{4{1'b1}}};
                 default: sai_successfull_per_byte = {8{1'b1}};
              endcase
           end
           HDM_DEC_DPAHIGH_DECODE_ADDR: begin
              unique casez ({req_fid,req_bar})
                 {MEM_INST_SB_SB_FID,MEM_INST_SB_SB_BAR}: sai_successfull_per_byte = {{4{1'b1}},{4{1'b1}}};
                 default: sai_successfull_per_byte = {8{1'b1}};
              endcase
           end
           CONFIG_TEST_START_ADDR_DECODE_ADDR: begin
              unique casez ({req_fid,req_bar})
                 {MEM_INST_SB_SB_FID,MEM_INST_SB_SB_BAR}: sai_successfull_per_byte = {{8{1'b1}}};
                 default: sai_successfull_per_byte = {8{1'b1}};
              endcase
           end
           CONFIG_TEST_WR_BACK_ADDR_DECODE_ADDR: begin
              unique casez ({req_fid,req_bar})
                 {MEM_INST_SB_SB_FID,MEM_INST_SB_SB_BAR}: sai_successfull_per_byte = {{8{1'b1}}};
                 default: sai_successfull_per_byte = {8{1'b1}};
              endcase
           end
           CONFIG_TEST_ADDR_INCRE_DECODE_ADDR: begin
              unique casez ({req_fid,req_bar})
                 {MEM_INST_SB_SB_FID,MEM_INST_SB_SB_BAR}: sai_successfull_per_byte = {{8{1'b1}}};
                 default: sai_successfull_per_byte = {8{1'b1}};
              endcase
           end
           CONFIG_TEST_PATTERN_DECODE_ADDR: begin
              unique casez ({req_fid,req_bar})
                 {MEM_INST_SB_SB_FID,MEM_INST_SB_SB_BAR}: sai_successfull_per_byte = {{8{1'b1}}};
                 default: sai_successfull_per_byte = {8{1'b1}};
              endcase
           end
           CONFIG_TEST_BYTEMASK_DECODE_ADDR: begin
              unique casez ({req_fid,req_bar})
                 {MEM_INST_SB_SB_FID,MEM_INST_SB_SB_BAR}: sai_successfull_per_byte = {{8{1'b1}}};
                 default: sai_successfull_per_byte = {8{1'b1}};
              endcase
           end
           CONFIG_TEST_PATTERN_PARAM_DECODE_ADDR: begin
              unique casez ({req_fid,req_bar})
                 {MEM_INST_SB_SB_FID,MEM_INST_SB_SB_BAR}: sai_successfull_per_byte = {{8{1'b1}}};
                 default: sai_successfull_per_byte = {8{1'b1}};
              endcase
           end
           CONFIG_ALGO_SETTING_DECODE_ADDR: begin
              unique casez ({req_fid,req_bar})
                 {MEM_INST_SB_SB_FID,MEM_INST_SB_SB_BAR}: sai_successfull_per_byte = {{8{1'b1}}};
                 default: sai_successfull_per_byte = {8{1'b1}};
              endcase
           end
           CONFIG_DEVICE_INJECTION_DECODE_ADDR: begin
              unique casez ({req_fid,req_bar})
                 {MEM_INST_SB_SB_FID,MEM_INST_SB_SB_BAR}: sai_successfull_per_byte = {{4{1'b1}},{4{1'b1}}};
                 default: sai_successfull_per_byte = {8{1'b1}};
              endcase
           end
           DEVICE_ERROR_LOG1_DECODE_ADDR: begin
              unique casez ({req_fid,req_bar})
                 {MEM_INST_SB_SB_FID,MEM_INST_SB_SB_BAR}: sai_successfull_per_byte = {{8{1'b1}}};
                 default: sai_successfull_per_byte = {8{1'b1}};
              endcase
           end
           DEVICE_ERROR_LOG2_DECODE_ADDR: begin
              unique casez ({req_fid,req_bar})
                 {MEM_INST_SB_SB_FID,MEM_INST_SB_SB_BAR}: sai_successfull_per_byte = {{8{1'b1}}};
                 default: sai_successfull_per_byte = {8{1'b1}};
              endcase
           end
           DEVICE_ERROR_LOG3_DECODE_ADDR: begin
              unique casez ({req_fid,req_bar})
                 {MEM_INST_SB_SB_FID,MEM_INST_SB_SB_BAR}: sai_successfull_per_byte = {{8{1'b1}}};
                 default: sai_successfull_per_byte = {8{1'b1}};
              endcase
           end
           DEVICE_EVENT_CTRL_DECODE_ADDR: begin
              unique casez ({req_fid,req_bar})
                 {MEM_INST_SB_SB_FID,MEM_INST_SB_SB_BAR}: sai_successfull_per_byte = {{8{1'b1}}};
                 default: sai_successfull_per_byte = {8{1'b1}};
              endcase
           end
           DEVICE_EVENT_COUNT_DECODE_ADDR: begin
              unique casez ({req_fid,req_bar})
                 {MEM_INST_SB_SB_FID,MEM_INST_SB_SB_BAR}: sai_successfull_per_byte = {{8{1'b1}}};
                 default: sai_successfull_per_byte = {8{1'b1}};
              endcase
           end
           DEVICE_ERROR_INJECTION_DECODE_ADDR: begin
              unique casez ({req_fid,req_bar})
                 {MEM_INST_SB_SB_FID,MEM_INST_SB_SB_BAR}: sai_successfull_per_byte = {{8{1'b1}}};
                 default: sai_successfull_per_byte = {8{1'b1}};
              endcase
           end
           DEVICE_FORCE_DISABLE_DECODE_ADDR: begin
              unique casez ({req_fid,req_bar})
                 {MEM_INST_SB_SB_FID,MEM_INST_SB_SB_BAR}: sai_successfull_per_byte = {{8{1'b1}}};
                 default: sai_successfull_per_byte = {8{1'b1}};
              endcase
           end
           DEVICE_ERROR_LOG4_DECODE_ADDR: begin
              unique casez ({req_fid,req_bar})
                 {MEM_INST_SB_SB_FID,MEM_INST_SB_SB_BAR}: sai_successfull_per_byte = {{8{1'b1}}};
                 default: sai_successfull_per_byte = {8{1'b1}};
              endcase
           end
           DEVICE_ERROR_LOG5_DECODE_ADDR: begin
              unique casez ({req_fid,req_bar})
                 {MEM_INST_SB_SB_FID,MEM_INST_SB_SB_BAR}: sai_successfull_per_byte = {{8{1'b1}}};
                 default: sai_successfull_per_byte = {8{1'b1}};
              endcase
           end
           CONFIG_CXL_ERRORS_DECODE_ADDR: begin
              unique casez ({req_fid,req_bar})
                 {MEM_INST_SB_SB_FID,MEM_INST_SB_SB_BAR}: sai_successfull_per_byte = {{8{1'b1}}};
                 default: sai_successfull_per_byte = {8{1'b1}};
              endcase
           end
           DEVICE_AFU_STATUS1_DECODE_ADDR: begin
              unique casez ({req_fid,req_bar})
                 {MEM_INST_SB_SB_FID,MEM_INST_SB_SB_BAR}: sai_successfull_per_byte = {{8{1'b1}}};
                 default: sai_successfull_per_byte = {8{1'b1}};
              endcase
           end
           DEVICE_AFU_STATUS2_DECODE_ADDR: begin
              unique casez ({req_fid,req_bar})
                 {MEM_INST_SB_SB_FID,MEM_INST_SB_SB_BAR}: sai_successfull_per_byte = {{8{1'b1}}};
                 default: sai_successfull_per_byte = {8{1'b1}};
              endcase
           end
           DEVICE_AXI2CPI_STATUS_1_DECODE_ADDR: begin
              unique casez ({req_fid,req_bar})
                 {MEM_INST_SB_SB_FID,MEM_INST_SB_SB_BAR}: sai_successfull_per_byte = {{8{1'b1}}};
                 default: sai_successfull_per_byte = {8{1'b1}};
              endcase
           end
           DEVICE_AXI2CPI_STATUS_2_DECODE_ADDR: begin
              unique casez ({req_fid,req_bar})
                 {MEM_INST_SB_SB_FID,MEM_INST_SB_SB_BAR}: sai_successfull_per_byte = {{8{1'b1}}};
                 default: sai_successfull_per_byte = {8{1'b1}};
              endcase
           end
           CDAT_0_DECODE_ADDR: begin
              unique casez ({req_fid,req_bar})
                 {MEM_INST_SB_SB_FID,MEM_INST_SB_SB_BAR}: sai_successfull_per_byte = {{4{1'b1}},{4{1'b1}}};
                 default: sai_successfull_per_byte = {8{1'b1}};
              endcase
           end
           CDAT_2_DECODE_ADDR: begin
              unique casez ({req_fid,req_bar})
                 {MEM_INST_SB_SB_FID,MEM_INST_SB_SB_BAR}: sai_successfull_per_byte = {{4{1'b1}},{4{1'b1}}};
                 default: sai_successfull_per_byte = {8{1'b1}};
              endcase
           end
           DSMAS_0_DECODE_ADDR: begin
              unique casez ({req_fid,req_bar})
                 {MEM_INST_SB_SB_FID,MEM_INST_SB_SB_BAR}: sai_successfull_per_byte = {{4{1'b1}},{4{1'b1}}};
                 default: sai_successfull_per_byte = {8{1'b1}};
              endcase
           end
           DSMAS_2_DECODE_ADDR: begin
              unique casez ({req_fid,req_bar})
                 {MEM_INST_SB_SB_FID,MEM_INST_SB_SB_BAR}: sai_successfull_per_byte = {{4{1'b1}},{4{1'b1}}};
                 default: sai_successfull_per_byte = {8{1'b1}};
              endcase
           end
           DSMAS_4_DECODE_ADDR: begin
              unique casez ({req_fid,req_bar})
                 {MEM_INST_SB_SB_FID,MEM_INST_SB_SB_BAR}: sai_successfull_per_byte = {{4{1'b1}},{4{1'b1}}};
                 default: sai_successfull_per_byte = {8{1'b1}};
              endcase
           end
           DSIS_0_DECODE_ADDR: begin
              unique casez ({req_fid,req_bar})
                 {MEM_INST_SB_SB_FID,MEM_INST_SB_SB_BAR}: sai_successfull_per_byte = {{4{1'b1}},{4{1'b1}}};
                 default: sai_successfull_per_byte = {8{1'b1}};
              endcase
           end
           DSLBIS_0_DECODE_ADDR: begin
              unique casez ({req_fid,req_bar})
                 {MEM_INST_SB_SB_FID,MEM_INST_SB_SB_BAR}: sai_successfull_per_byte = {{4{1'b1}},{4{1'b1}}};
                 default: sai_successfull_per_byte = {8{1'b1}};
              endcase
           end
           DSLBIS_2_DECODE_ADDR: begin
              unique casez ({req_fid,req_bar})
                 {MEM_INST_SB_SB_FID,MEM_INST_SB_SB_BAR}: sai_successfull_per_byte = {{4{1'b1}},{4{1'b1}}};
                 default: sai_successfull_per_byte = {8{1'b1}};
              endcase
           end
           DSLBIS_4_DECODE_ADDR: begin
              unique casez ({req_fid,req_bar})
                 {MEM_INST_SB_SB_FID,MEM_INST_SB_SB_BAR}: sai_successfull_per_byte = {{4{1'b1}},{4{1'b1}}};
                 default: sai_successfull_per_byte = {8{1'b1}};
              endcase
           end
           DSEMTS_0_DECODE_ADDR: begin
              unique casez ({req_fid,req_bar})
                 {MEM_INST_SB_SB_FID,MEM_INST_SB_SB_BAR}: sai_successfull_per_byte = {{4{1'b1}},{4{1'b1}}};
                 default: sai_successfull_per_byte = {8{1'b1}};
              endcase
           end
           DSEMTS_2_DECODE_ADDR: begin
              unique casez ({req_fid,req_bar})
                 {MEM_INST_SB_SB_FID,MEM_INST_SB_SB_BAR}: sai_successfull_per_byte = {{4{1'b1}},{4{1'b1}}};
                 default: sai_successfull_per_byte = {8{1'b1}};
              endcase
           end
           DSEMTS_4_DECODE_ADDR: begin
              unique casez ({req_fid,req_bar})
                 {MEM_INST_SB_SB_FID,MEM_INST_SB_SB_BAR}: sai_successfull_per_byte = {{4{1'b1}},{4{1'b1}}};
                 default: sai_successfull_per_byte = {8{1'b1}};
              endcase
           end
           MC_STATUS_DECODE_ADDR: begin
              unique casez ({req_fid,req_bar})
                 {MEM_INST_SB_SB_FID,MEM_INST_SB_SB_BAR}: sai_successfull_per_byte = {{4{1'b1}},{4{1'b1}}};
                 default: sai_successfull_per_byte = {8{1'b1}};
              endcase
           end
           DEVMEM_SBECNT_DECODE_ADDR: begin
              unique casez ({req_fid,req_bar})
                 {MEM_INST_SB_SB_FID,MEM_INST_SB_SB_BAR}: sai_successfull_per_byte = {{8{1'b1}}};
                 default: sai_successfull_per_byte = {8{1'b1}};
              endcase
           end
           DEVMEM_DBECNT_DECODE_ADDR: begin
              unique casez ({req_fid,req_bar})
                 {MEM_INST_SB_SB_FID,MEM_INST_SB_SB_BAR}: sai_successfull_per_byte = {{8{1'b1}}};
                 default: sai_successfull_per_byte = {8{1'b1}};
              endcase
           end
           DEVMEM_POISONCNT_DECODE_ADDR: begin
              unique casez ({req_fid,req_bar})
                 {MEM_INST_SB_SB_FID,MEM_INST_SB_SB_BAR}: sai_successfull_per_byte = {{8{1'b1}}};
                 default: sai_successfull_per_byte = {8{1'b1}};
              endcase
           end
           MBOX_EVENTINJ_DECODE_ADDR: begin
              unique casez ({req_fid,req_bar})
                 {MEM_INST_SB_SB_FID,MEM_INST_SB_SB_BAR}: sai_successfull_per_byte = {{4{1'b1}},{4{1'b1}}};
                 default: sai_successfull_per_byte = {8{1'b1}};
              endcase
           end
           DEVICE_AFU_LATENCY_MODE_DECODE_ADDR: begin
              unique casez ({req_fid,req_bar})
                 {MEM_INST_SB_SB_FID,MEM_INST_SB_SB_BAR}: sai_successfull_per_byte = {{8{1'b1}}};
                 default: sai_successfull_per_byte = {8{1'b1}};
              endcase
           end
            default: sai_successfull_per_byte = {8{1'b1}};
         endcase 
      default: sai_successfull_per_byte = {8{1'b1}};
   endcase 
end


always_comb ack.sai_successfull = &(sai_successfull_per_byte | ~be);


// end decode and addr logic section }

// ======================================================================
// begin rdata section {

always_comb begin : READ_DATA_BLOCK

   unique casez (req_opcode) 
      CFGRD:
         unique casez (case_req_addr_CAFU_CSR0_CFG_CFG) 
           DVSEC_DEV_DECODE_ADDR: begin
              unique casez (req_fid)
                 CFG_INST_SB_SB_FID: read_data = {DVSEC_HDR1,DVSEC_DEV};
                 default: read_data = '0;
              endcase
           end
           DVSEC_FBCAP_HDR2_DECODE_ADDR: begin
              unique casez (req_fid)
                 CFG_INST_SB_SB_FID: read_data = {DVSEC_FBCTRL_STATUS,DVSEC_FBCAP_HDR2};
                 default: read_data = '0;
              endcase
           end
           DVSEC_FBCTRL2_STATUS2_DECODE_ADDR: begin
              unique casez (req_fid)
                 CFG_INST_SB_SB_FID: read_data = {DVSEC_FBLOCK,DVSEC_FBCTRL2_STATUS2};
                 default: read_data = '0;
              endcase
           end
           DVSEC_FBRANGE1SZHIGH_DECODE_ADDR: begin
              unique casez (req_fid)
                 CFG_INST_SB_SB_FID: read_data = {DVSEC_FBRANGE1SZLOW,DVSEC_FBRANGE1SZHIGH};
                 default: read_data = '0;
              endcase
           end
           DVSEC_FBRANGE1HIGH_DECODE_ADDR: begin
              unique casez (req_fid)
                 CFG_INST_SB_SB_FID: read_data = {DVSEC_FBRANGE1LOW,DVSEC_FBRANGE1HIGH};
                 default: read_data = '0;
              endcase
           end
           DVSEC_FBRANGE2SZHIGH_DECODE_ADDR: begin
              unique casez (req_fid)
                 CFG_INST_SB_SB_FID: read_data = {DVSEC_FBRANGE2SZLOW,DVSEC_FBRANGE2SZHIGH};
                 default: read_data = '0;
              endcase
           end
           DVSEC_FBRANGE2HIGH_DECODE_ADDR: begin
              unique casez (req_fid)
                 CFG_INST_SB_SB_FID: read_data = {DVSEC_FBRANGE2LOW,DVSEC_FBRANGE2HIGH};
                 default: read_data = '0;
              endcase
           end
           DVSEC_DOE_DECODE_ADDR: begin
              unique casez (req_fid)
                 CFG_INST_SB_SB_FID: read_data = {DOE_CAPREG,DVSEC_DOE};
                 default: read_data = '0;
              endcase
           end
           DOE_CTLREG_DECODE_ADDR: begin
              unique casez (req_fid)
                 CFG_INST_SB_SB_FID: read_data = {DOE_STSREG,DOE_CTLREG};
                 default: read_data = '0;
              endcase
           end
           DOE_WRMAILREG_DECODE_ADDR: begin
              unique casez (req_fid)
                 CFG_INST_SB_SB_FID: read_data = {DOE_RDMAILREG,DOE_WRMAILREG};
                 default: read_data = '0;
              endcase
           end
           DVSEC_TEST_CAP_DECODE_ADDR: begin
              unique casez (req_fid)
                 CFG_INST_SB_SB_FID: read_data = {CXL_DVSEC_HEADER_1,DVSEC_TEST_CAP};
                 default: read_data = '0;
              endcase
           end
           CXL_DVSEC_HEADER_2_DECODE_ADDR: begin
              unique casez (req_fid)
                 CFG_INST_SB_SB_FID: read_data = {CXL_DVSEC_TEST_CAP1,CXL_DVSEC_TEST_LOCK,CXL_DVSEC_HEADER_2};
                 default: read_data = '0;
              endcase
           end
           CXL_DVSEC_TEST_CAP2_DECODE_ADDR: begin
              unique casez (req_fid)
                 CFG_INST_SB_SB_FID: read_data = {CXL_DVSEC_TEST_CNF_BASE_LOW,16'h0,CXL_DVSEC_TEST_CAP2};
                 default: read_data = '0;
              endcase
           end
           CXL_DVSEC_TEST_CNF_BASE_HIGH_DECODE_ADDR: begin
              unique casez (req_fid)
                 CFG_INST_SB_SB_FID: read_data = {32'h0,CXL_DVSEC_TEST_CNF_BASE_HIGH};
                 default: read_data = '0;
              endcase
           end
         default : read_data = '0; 
      endcase
      MRD:
         unique casez (case_req_addr_CAFU_CSR0_CFG_MEM) 
           CXL_DEV_CAP_ARRAY_0_DECODE_ADDR: begin
              unique casez ({req_fid,req_bar})
                 {MEM_INST_SB_SB_FID,MEM_INST_SB_SB_BAR}: read_data = {CXL_DEV_CAP_ARRAY_1,CXL_DEV_CAP_ARRAY_0};
                 default: read_data = '0;
              endcase
           end
           CXL_DEV_CAP_HDR1_0_DECODE_ADDR: begin
              unique casez ({req_fid,req_bar})
                 {MEM_INST_SB_SB_FID,MEM_INST_SB_SB_BAR}: read_data = {CXL_DEV_CAP_HDR1_1,CXL_DEV_CAP_HDR1_0};
                 default: read_data = '0;
              endcase
           end
           CXL_DEV_CAP_HDR1_2_DECODE_ADDR: begin
              unique casez ({req_fid,req_bar})
                 {MEM_INST_SB_SB_FID,MEM_INST_SB_SB_BAR}: read_data = {32'h0,CXL_DEV_CAP_HDR1_2};
                 default: read_data = '0;
              endcase
           end
           CXL_DEV_CAP_HDR2_0_DECODE_ADDR: begin
              unique casez ({req_fid,req_bar})
                 {MEM_INST_SB_SB_FID,MEM_INST_SB_SB_BAR}: read_data = {CXL_DEV_CAP_HDR2_1,CXL_DEV_CAP_HDR2_0};
                 default: read_data = '0;
              endcase
           end
           CXL_DEV_CAP_HDR2_2_DECODE_ADDR: begin
              unique casez ({req_fid,req_bar})
                 {MEM_INST_SB_SB_FID,MEM_INST_SB_SB_BAR}: read_data = {32'h0,CXL_DEV_CAP_HDR2_2};
                 default: read_data = '0;
              endcase
           end
           CXL_DEV_CAP_HDR3_0_DECODE_ADDR: begin
              unique casez ({req_fid,req_bar})
                 {MEM_INST_SB_SB_FID,MEM_INST_SB_SB_BAR}: read_data = {CXL_DEV_CAP_HDR3_1,CXL_DEV_CAP_HDR3_0};
                 default: read_data = '0;
              endcase
           end
           CXL_DEV_CAP_HDR3_2_DECODE_ADDR: begin
              unique casez ({req_fid,req_bar})
                 {MEM_INST_SB_SB_FID,MEM_INST_SB_SB_BAR}: read_data = {32'h0,CXL_DEV_CAP_HDR3_2};
                 default: read_data = '0;
              endcase
           end
           CXL_DEV_CAP_EVENT_STATUS_DECODE_ADDR: begin
              unique casez ({req_fid,req_bar})
                 {MEM_INST_SB_SB_FID,MEM_INST_SB_SB_BAR}: read_data = {32'h0,CXL_DEV_CAP_EVENT_STATUS};
                 default: read_data = '0;
              endcase
           end
           CXL_MEM_DEV_STATUS_DECODE_ADDR: begin
              unique casez ({req_fid,req_bar})
                 {MEM_INST_SB_SB_FID,MEM_INST_SB_SB_BAR}: read_data = {32'h0,CXL_MEM_DEV_STATUS};
                 default: read_data = '0;
              endcase
           end
           CXL_MB_CAP_DECODE_ADDR: begin
              unique casez ({req_fid,req_bar})
                 {MEM_INST_SB_SB_FID,MEM_INST_SB_SB_BAR}: read_data = {CXL_MB_CTRL,CXL_MB_CAP};
                 default: read_data = '0;
              endcase
           end
           CXL_MB_CMD_DECODE_ADDR: begin
              unique casez ({req_fid,req_bar})
                 {MEM_INST_SB_SB_FID,MEM_INST_SB_SB_BAR}: read_data = {CXL_MB_CMD};
                 default: read_data = '0;
              endcase
           end
           CXL_MB_STATUS_DECODE_ADDR: begin
              unique casez ({req_fid,req_bar})
                 {MEM_INST_SB_SB_FID,MEM_INST_SB_SB_BAR}: read_data = {CXL_MB_STATUS};
                 default: read_data = '0;
              endcase
           end
           CXL_MB_BK_CMD_STATUS_DECODE_ADDR: begin
              unique casez ({req_fid,req_bar})
                 {MEM_INST_SB_SB_FID,MEM_INST_SB_SB_BAR}: read_data = {CXL_MB_BK_CMD_STATUS};
                 default: read_data = '0;
              endcase
           end
           CXL_MB_PAY_START_DECODE_ADDR: begin
              unique casez ({req_fid,req_bar})
                 {MEM_INST_SB_SB_FID,MEM_INST_SB_SB_BAR}: read_data = {32'h0,CXL_MB_PAY_START};
                 default: read_data = '0;
              endcase
           end
           CXL_MB_PAY_END_DECODE_ADDR: begin
              unique casez ({req_fid,req_bar})
                 {MEM_INST_SB_SB_FID,MEM_INST_SB_SB_BAR}: read_data = {CXL_MB_PAY_END,32'h0};
                 default: read_data = '0;
              endcase
           end
           HDM_DEC_CAP_DECODE_ADDR: begin
              unique casez ({req_fid,req_bar})
                 {MEM_INST_SB_SB_FID,MEM_INST_SB_SB_BAR}: read_data = {HDM_DEC_GBL_CTRL,HDM_DEC_CAP};
                 default: read_data = '0;
              endcase
           end
           HDM_DEC_BASELOW_DECODE_ADDR: begin
              unique casez ({req_fid,req_bar})
                 {MEM_INST_SB_SB_FID,MEM_INST_SB_SB_BAR}: read_data = {HDM_DEC_BASEHIGH,HDM_DEC_BASELOW};
                 default: read_data = '0;
              endcase
           end
           HDM_DEC_SIZELOW_DECODE_ADDR: begin
              unique casez ({req_fid,req_bar})
                 {MEM_INST_SB_SB_FID,MEM_INST_SB_SB_BAR}: read_data = {HDM_DEC_SIZEHIGH,HDM_DEC_SIZELOW};
                 default: read_data = '0;
              endcase
           end
           HDM_DEC_CTRL_DECODE_ADDR: begin
              unique casez ({req_fid,req_bar})
                 {MEM_INST_SB_SB_FID,MEM_INST_SB_SB_BAR}: read_data = {HDM_DEC_DPALOW,HDM_DEC_CTRL};
                 default: read_data = '0;
              endcase
           end
           HDM_DEC_DPAHIGH_DECODE_ADDR: begin
              unique casez ({req_fid,req_bar})
                 {MEM_INST_SB_SB_FID,MEM_INST_SB_SB_BAR}: read_data = {32'h0,HDM_DEC_DPAHIGH};
                 default: read_data = '0;
              endcase
           end
           CONFIG_TEST_START_ADDR_DECODE_ADDR: begin
              unique casez ({req_fid,req_bar})
                 {MEM_INST_SB_SB_FID,MEM_INST_SB_SB_BAR}: read_data = {CONFIG_TEST_START_ADDR};
                 default: read_data = '0;
              endcase
           end
           CONFIG_TEST_WR_BACK_ADDR_DECODE_ADDR: begin
              unique casez ({req_fid,req_bar})
                 {MEM_INST_SB_SB_FID,MEM_INST_SB_SB_BAR}: read_data = {CONFIG_TEST_WR_BACK_ADDR};
                 default: read_data = '0;
              endcase
           end
           CONFIG_TEST_ADDR_INCRE_DECODE_ADDR: begin
              unique casez ({req_fid,req_bar})
                 {MEM_INST_SB_SB_FID,MEM_INST_SB_SB_BAR}: read_data = {CONFIG_TEST_ADDR_INCRE};
                 default: read_data = '0;
              endcase
           end
           CONFIG_TEST_PATTERN_DECODE_ADDR: begin
              unique casez ({req_fid,req_bar})
                 {MEM_INST_SB_SB_FID,MEM_INST_SB_SB_BAR}: read_data = {CONFIG_TEST_PATTERN};
                 default: read_data = '0;
              endcase
           end
           CONFIG_TEST_BYTEMASK_DECODE_ADDR: begin
              unique casez ({req_fid,req_bar})
                 {MEM_INST_SB_SB_FID,MEM_INST_SB_SB_BAR}: read_data = {CONFIG_TEST_BYTEMASK};
                 default: read_data = '0;
              endcase
           end
           CONFIG_TEST_PATTERN_PARAM_DECODE_ADDR: begin
              unique casez ({req_fid,req_bar})
                 {MEM_INST_SB_SB_FID,MEM_INST_SB_SB_BAR}: read_data = {CONFIG_TEST_PATTERN_PARAM};
                 default: read_data = '0;
              endcase
           end
           CONFIG_ALGO_SETTING_DECODE_ADDR: begin
              unique casez ({req_fid,req_bar})
                 {MEM_INST_SB_SB_FID,MEM_INST_SB_SB_BAR}: read_data = {CONFIG_ALGO_SETTING};
                 default: read_data = '0;
              endcase
           end
           CONFIG_DEVICE_INJECTION_DECODE_ADDR: begin
              unique casez ({req_fid,req_bar})
                 {MEM_INST_SB_SB_FID,MEM_INST_SB_SB_BAR}: read_data = {32'h0,CONFIG_DEVICE_INJECTION};
                 default: read_data = '0;
              endcase
           end
           DEVICE_ERROR_LOG1_DECODE_ADDR: begin
              unique casez ({req_fid,req_bar})
                 {MEM_INST_SB_SB_FID,MEM_INST_SB_SB_BAR}: read_data = {DEVICE_ERROR_LOG1};
                 default: read_data = '0;
              endcase
           end
           DEVICE_ERROR_LOG2_DECODE_ADDR: begin
              unique casez ({req_fid,req_bar})
                 {MEM_INST_SB_SB_FID,MEM_INST_SB_SB_BAR}: read_data = {DEVICE_ERROR_LOG2};
                 default: read_data = '0;
              endcase
           end
           DEVICE_ERROR_LOG3_DECODE_ADDR: begin
              unique casez ({req_fid,req_bar})
                 {MEM_INST_SB_SB_FID,MEM_INST_SB_SB_BAR}: read_data = {DEVICE_ERROR_LOG3};
                 default: read_data = '0;
              endcase
           end
           DEVICE_EVENT_CTRL_DECODE_ADDR: begin
              unique casez ({req_fid,req_bar})
                 {MEM_INST_SB_SB_FID,MEM_INST_SB_SB_BAR}: read_data = {DEVICE_EVENT_CTRL};
                 default: read_data = '0;
              endcase
           end
           DEVICE_EVENT_COUNT_DECODE_ADDR: begin
              unique casez ({req_fid,req_bar})
                 {MEM_INST_SB_SB_FID,MEM_INST_SB_SB_BAR}: read_data = {DEVICE_EVENT_COUNT};
                 default: read_data = '0;
              endcase
           end
           DEVICE_ERROR_INJECTION_DECODE_ADDR: begin
              unique casez ({req_fid,req_bar})
                 {MEM_INST_SB_SB_FID,MEM_INST_SB_SB_BAR}: read_data = {DEVICE_ERROR_INJECTION};
                 default: read_data = '0;
              endcase
           end
           DEVICE_FORCE_DISABLE_DECODE_ADDR: begin
              unique casez ({req_fid,req_bar})
                 {MEM_INST_SB_SB_FID,MEM_INST_SB_SB_BAR}: read_data = {DEVICE_FORCE_DISABLE};
                 default: read_data = '0;
              endcase
           end
           DEVICE_ERROR_LOG4_DECODE_ADDR: begin
              unique casez ({req_fid,req_bar})
                 {MEM_INST_SB_SB_FID,MEM_INST_SB_SB_BAR}: read_data = {DEVICE_ERROR_LOG4};
                 default: read_data = '0;
              endcase
           end
           DEVICE_ERROR_LOG5_DECODE_ADDR: begin
              unique casez ({req_fid,req_bar})
                 {MEM_INST_SB_SB_FID,MEM_INST_SB_SB_BAR}: read_data = {DEVICE_ERROR_LOG5};
                 default: read_data = '0;
              endcase
           end
           CONFIG_CXL_ERRORS_DECODE_ADDR: begin
              unique casez ({req_fid,req_bar})
                 {MEM_INST_SB_SB_FID,MEM_INST_SB_SB_BAR}: read_data = {CONFIG_CXL_ERRORS};
                 default: read_data = '0;
              endcase
           end
           DEVICE_AFU_STATUS1_DECODE_ADDR: begin
              unique casez ({req_fid,req_bar})
                 {MEM_INST_SB_SB_FID,MEM_INST_SB_SB_BAR}: read_data = {DEVICE_AFU_STATUS1};
                 default: read_data = '0;
              endcase
           end
           DEVICE_AFU_STATUS2_DECODE_ADDR: begin
              unique casez ({req_fid,req_bar})
                 {MEM_INST_SB_SB_FID,MEM_INST_SB_SB_BAR}: read_data = {DEVICE_AFU_STATUS2};
                 default: read_data = '0;
              endcase
           end
           DEVICE_AXI2CPI_STATUS_1_DECODE_ADDR: begin
              unique casez ({req_fid,req_bar})
                 {MEM_INST_SB_SB_FID,MEM_INST_SB_SB_BAR}: read_data = {DEVICE_AXI2CPI_STATUS_1};
                 default: read_data = '0;
              endcase
           end
           DEVICE_AXI2CPI_STATUS_2_DECODE_ADDR: begin
              unique casez ({req_fid,req_bar})
                 {MEM_INST_SB_SB_FID,MEM_INST_SB_SB_BAR}: read_data = {DEVICE_AXI2CPI_STATUS_2};
                 default: read_data = '0;
              endcase
           end
           CDAT_0_DECODE_ADDR: begin
              unique casez ({req_fid,req_bar})
                 {MEM_INST_SB_SB_FID,MEM_INST_SB_SB_BAR}: read_data = {CDAT_1,CDAT_0};
                 default: read_data = '0;
              endcase
           end
           CDAT_2_DECODE_ADDR: begin
              unique casez ({req_fid,req_bar})
                 {MEM_INST_SB_SB_FID,MEM_INST_SB_SB_BAR}: read_data = {CDAT_3,CDAT_2};
                 default: read_data = '0;
              endcase
           end
           DSMAS_0_DECODE_ADDR: begin
              unique casez ({req_fid,req_bar})
                 {MEM_INST_SB_SB_FID,MEM_INST_SB_SB_BAR}: read_data = {DSMAS_1,DSMAS_0};
                 default: read_data = '0;
              endcase
           end
           DSMAS_2_DECODE_ADDR: begin
              unique casez ({req_fid,req_bar})
                 {MEM_INST_SB_SB_FID,MEM_INST_SB_SB_BAR}: read_data = {DSMAS_3,DSMAS_2};
                 default: read_data = '0;
              endcase
           end
           DSMAS_4_DECODE_ADDR: begin
              unique casez ({req_fid,req_bar})
                 {MEM_INST_SB_SB_FID,MEM_INST_SB_SB_BAR}: read_data = {DSMAS_5,DSMAS_4};
                 default: read_data = '0;
              endcase
           end
           DSIS_0_DECODE_ADDR: begin
              unique casez ({req_fid,req_bar})
                 {MEM_INST_SB_SB_FID,MEM_INST_SB_SB_BAR}: read_data = {DSIS_1,DSIS_0};
                 default: read_data = '0;
              endcase
           end
           DSLBIS_0_DECODE_ADDR: begin
              unique casez ({req_fid,req_bar})
                 {MEM_INST_SB_SB_FID,MEM_INST_SB_SB_BAR}: read_data = {DSLBIS_1,DSLBIS_0};
                 default: read_data = '0;
              endcase
           end
           DSLBIS_2_DECODE_ADDR: begin
              unique casez ({req_fid,req_bar})
                 {MEM_INST_SB_SB_FID,MEM_INST_SB_SB_BAR}: read_data = {DSLBIS_3,DSLBIS_2};
                 default: read_data = '0;
              endcase
           end
           DSLBIS_4_DECODE_ADDR: begin
              unique casez ({req_fid,req_bar})
                 {MEM_INST_SB_SB_FID,MEM_INST_SB_SB_BAR}: read_data = {DSLBIS_5,DSLBIS_4};
                 default: read_data = '0;
              endcase
           end
           DSEMTS_0_DECODE_ADDR: begin
              unique casez ({req_fid,req_bar})
                 {MEM_INST_SB_SB_FID,MEM_INST_SB_SB_BAR}: read_data = {DSEMTS_1,DSEMTS_0};
                 default: read_data = '0;
              endcase
           end
           DSEMTS_2_DECODE_ADDR: begin
              unique casez ({req_fid,req_bar})
                 {MEM_INST_SB_SB_FID,MEM_INST_SB_SB_BAR}: read_data = {DSEMTS_3,DSEMTS_2};
                 default: read_data = '0;
              endcase
           end
           DSEMTS_4_DECODE_ADDR: begin
              unique casez ({req_fid,req_bar})
                 {MEM_INST_SB_SB_FID,MEM_INST_SB_SB_BAR}: read_data = {DSEMTS_5,DSEMTS_4};
                 default: read_data = '0;
              endcase
           end
           MC_STATUS_DECODE_ADDR: begin
              unique casez ({req_fid,req_bar})
                 {MEM_INST_SB_SB_FID,MEM_INST_SB_SB_BAR}: read_data = {32'h0,MC_STATUS};
                 default: read_data = '0;
              endcase
           end
           DEVMEM_SBECNT_DECODE_ADDR: begin
              unique casez ({req_fid,req_bar})
                 {MEM_INST_SB_SB_FID,MEM_INST_SB_SB_BAR}: read_data = {DEVMEM_SBECNT};
                 default: read_data = '0;
              endcase
           end
           DEVMEM_DBECNT_DECODE_ADDR: begin
              unique casez ({req_fid,req_bar})
                 {MEM_INST_SB_SB_FID,MEM_INST_SB_SB_BAR}: read_data = {DEVMEM_DBECNT};
                 default: read_data = '0;
              endcase
           end
           DEVMEM_POISONCNT_DECODE_ADDR: begin
              unique casez ({req_fid,req_bar})
                 {MEM_INST_SB_SB_FID,MEM_INST_SB_SB_BAR}: read_data = {DEVMEM_POISONCNT};
                 default: read_data = '0;
              endcase
           end
           MBOX_EVENTINJ_DECODE_ADDR: begin
              unique casez ({req_fid,req_bar})
                 {MEM_INST_SB_SB_FID,MEM_INST_SB_SB_BAR}: read_data = {32'h0,MBOX_EVENTINJ};
                 default: read_data = '0;
              endcase
           end
           DEVICE_AFU_LATENCY_MODE_DECODE_ADDR: begin
              unique casez ({req_fid,req_bar})
                 {MEM_INST_SB_SB_FID,MEM_INST_SB_SB_BAR}: read_data = {DEVICE_AFU_LATENCY_MODE};
                 default: read_data = '0;
              endcase
           end
         default : read_data = '0; 
      endcase
      default : read_data = '0;  
   endcase
end

always_comb begin
    unique casez (high_dword) 
        0: ack.data = read_data &
                      { {8{be[7] & sai_successfull_per_byte[7]}}, {8{be[6] & sai_successfull_per_byte[6]}}, {8{be[5] & sai_successfull_per_byte[5]}}, {8{be[4] & sai_successfull_per_byte[4]}},
                        {8{be[3] & sai_successfull_per_byte[3]}}, {8{be[2] & sai_successfull_per_byte[2]}}, {8{be[1] & sai_successfull_per_byte[1]}}, {8{be[0] & sai_successfull_per_byte[0]}} };
        1: ack.data = {32'h0,read_data[63:32]} &
                      {32'h0, {8{be[7] & sai_successfull_per_byte[7]}}, {8{be[6] & sai_successfull_per_byte[6]}}, {8{be[5] & sai_successfull_per_byte[5]}}, {8{be[4] & sai_successfull_per_byte[4]}} };
        // default are needed to reduce compiler warnings. 
        default: ack.data = read_data &  
				  { {8{be[7] & sai_successfull_per_byte[7]}}, {8{be[6] & sai_successfull_per_byte[6]}}, {8{be[5] & sai_successfull_per_byte[5]}}, {8{be[4] & sai_successfull_per_byte[4]}},
					{8{be[3] & sai_successfull_per_byte[3]}}, {8{be[2] & sai_successfull_per_byte[2]}}, {8{be[1] & sai_successfull_per_byte[1]}}, {8{be[0] & sai_successfull_per_byte[0]}} };
    endcase
end

always_comb begin
    unique casez (high_dword) 
        0: write_data = req.data;
        1: write_data = {req.data[31:0],32'h0}; 
        // default are needed to reduce compiler warnings. 
        default: write_data = req.data; 
    endcase
end


// end rdata section }

// ======================================================================
// begin register RSVD init section {
always_comb begin
    DVSEC_FBCAP_HDR2.reserved0 = '0;
    DVSEC_FBCTRL_STATUS.reserved0 = '0;
    DVSEC_FBCTRL_STATUS.reserved1 = '0;
    DVSEC_FBCTRL_STATUS.reserved2 = '0;
    DVSEC_FBCTRL2_STATUS2.reserved0 = '0;
    DVSEC_FBCTRL2_STATUS2.reserved1 = '0;
    DVSEC_FBLOCK.reserved0 = '0;
    DVSEC_FBLOCK.reserved1 = '0;
    DVSEC_FBRANGE1SZLOW.reserved0 = '0;
    DVSEC_FBRANGE1SZLOW.reserved1 = '0;
    DVSEC_FBRANGE1LOW.reserved0 = '0;
    DVSEC_FBRANGE2SZLOW.reserved0 = '0;
    DVSEC_FBRANGE2SZLOW.reserved1 = '0;
    DVSEC_FBRANGE2LOW.reserved0 = '0;
    DOE_CAPREG.reserved0 = '0;
    DOE_CTLREG.reserved0 = '0;
    DOE_STSREG.reserved0 = '0;
    CXL_DVSEC_TEST_LOCK.reserved0 = '0;
    CXL_DVSEC_TEST_CAP1.reserved0 = '0;
    CXL_DVSEC_TEST_CNF_BASE_LOW.reserved0 = '0;
    CXL_DEV_CAP_ARRAY_0.reserved0 = '0;
    CXL_DEV_CAP_ARRAY_1.reserved0 = '0;
    CXL_DEV_CAP_HDR1_0.reserved0 = '0;
    CXL_DEV_CAP_HDR2_0.reserved0 = '0;
    CXL_DEV_CAP_HDR3_0.reserved0 = '0;
    CXL_DEV_CAP_EVENT_STATUS.reserved0 = '0;
    CXL_MEM_DEV_STATUS.reserved0 = '0;
    CXL_MB_CAP.reserved0 = '0;
    CXL_MB_CTRL.reserved0 = '0;
    CXL_MB_CMD.reserved0 = '0;
    CXL_MB_STATUS.reserved0 = '0;
    CXL_MB_BK_CMD_STATUS.reserved0 = '0;
    HDM_DEC_CAP.reserved0 = '0;
    HDM_DEC_GBL_CTRL.reserved0 = '0;
    HDM_DEC_BASELOW.reserved0 = '0;
    HDM_DEC_SIZELOW.reserved0 = '0;
    HDM_DEC_CTRL.reserved0 = '0;
    HDM_DEC_DPALOW.reserved0 = '0;
    CONFIG_TEST_START_ADDR.reserved0 = '0;
    CONFIG_TEST_WR_BACK_ADDR.reserved0 = '0;
    CONFIG_TEST_PATTERN_PARAM.reserved0 = '0;
    CONFIG_ALGO_SETTING.reserved0 = '0;
    CONFIG_ALGO_SETTING.reserved1 = '0;
    CONFIG_DEVICE_INJECTION.reserved0 = '0;
    DEVICE_ERROR_LOG3.reserved0 = '0;
    DEVICE_EVENT_CTRL.reserved0 = '0;
    DEVICE_EVENT_CTRL.reserved1 = '0;
    DEVICE_ERROR_INJECTION.reserved0 = '0;
    DEVICE_FORCE_DISABLE.reserved0 = '0;
    DEVICE_ERROR_LOG4.reserved0 = '0;
    DEVICE_ERROR_LOG5.reserved0 = '0;
    CONFIG_CXL_ERRORS.reserved0 = '0;
    DEVICE_AFU_STATUS1.reserved0 = '0;
    DEVICE_AFU_STATUS2.reserved0 = '0;
    DEVICE_AXI2CPI_STATUS_1.reserved0 = '0;
    DEVICE_AXI2CPI_STATUS_1.reserved1 = '0;
    DEVICE_AXI2CPI_STATUS_1.reserved2 = '0;
    DEVICE_AXI2CPI_STATUS_2.reserved0 = '0;
    DEVICE_AFU_LATENCY_MODE.reserved0 = '0;
end

// end register RSVD init section }


// ======================================================================
// begin unit parity section {


// end unit parity section }


endmodule
//lintra pop
//lintra pop
