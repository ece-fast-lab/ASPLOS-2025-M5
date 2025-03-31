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
module avst4to1_ss_rx_crd_check (
//
// PLD IF
//
  input            pld_clk,                               // Clock (Core)
  input            pld_rst_n,                             // Reset (Core)
  
  avst4to1_if.rx_crd    pld_rx_crd,
  
  avst4to1_if.rx        pld_rx,
  
  input [1:0]      tlp_crd_type_s0,
  input [1:0]      tlp_crd_type_s1,
  input [1:0]      tlp_crd_type_s2,
  input [1:0]      tlp_crd_type_s3
  
  
);
//----------------------------------------------------------------------------//
  avst4to1_if      pld_rx_f();
  
  logic [1:0] tlp_crd_type_s0_f;
  logic [1:0] tlp_crd_type_s1_f;
  logic [1:0] tlp_crd_type_s2_f;
  logic [1:0] tlp_crd_type_s3_f;

  logic [1:0] s0_hdr;
  logic [1:0] s1_hdr;
  logic [1:0] s2_hdr;
  logic [1:0] s3_hdr;

  logic [3:0] dec_d_p;
  logic [1:0] decr_d_p_s3, decr_d_p_s2, decr_d_p_s1, decr_d_p_s0;
  logic [3:0] dec_d_np;
  logic [1:0] decr_d_np_s3, decr_d_np_s2, decr_d_np_s1, decr_d_np_s0;
  logic [3:0] dec_d_cpl;
  logic [1:0] decr_d_cpl_s3, decr_d_cpl_s2, decr_d_cpl_s1, decr_d_cpl_s0;

  logic [15:0] rnr_d_p_avail;
  logic [15:0] rnr_d_np_avail;
  logic [15:0] rnr_d_cpl_avail;
  logic [1:0]  rnr_d_p_crd_st;
  logic [1:0]  rnr_d_np_crd_st;
  logic [1:0]  rnr_d_cpl_crd_st;
  
  logic [2:0] dec_hdr_p;
  logic decr_hdr_p_s3, decr_hdr_p_s2, decr_hdr_p_s1, decr_hdr_p_s0;
  logic [2:0] dec_hdr_np;
  logic decr_hdr_np_s3, decr_hdr_np_s2, decr_hdr_np_s1, decr_hdr_np_s0;
  logic [2:0] dec_hdr_cpl;
  logic decr_hdr_cpl_s3, decr_hdr_cpl_s2, decr_hdr_cpl_s1, decr_hdr_cpl_s0;
  
  logic [15:0] rnr_hdr_p_avail;
  logic [15:0] rnr_hdr_np_avail;
  logic [15:0] rnr_hdr_cpl_avail;
  logic [1:0]  rnr_hdr_p_crd_st;
  logic [1:0]  rnr_hdr_np_crd_st;
  logic [1:0]  rnr_hdr_cpl_crd_st;
  
//----------------------------------------------------------------------------//
  always @(posedge pld_clk)
  begin
    //S0
    tlp_crd_type_s0_f[1:0] <= tlp_crd_type_s0[1:0];
    pld_rx_f.rx_st_hvalid_s0_o <= pld_rx.rx_st_hvalid_s0_o;
    pld_rx_f.rx_st_sop_s0_o <= pld_rx.rx_st_sop_s0_o;
    pld_rx_f.rx_st_eop_s0_o <= pld_rx.rx_st_eop_s0_o;
    pld_rx_f.rx_st_dvalid_s0_o <= pld_rx.rx_st_dvalid_s0_o;
    pld_rx_f.rx_st_empty_s0_o[2:0] <= pld_rx.rx_st_empty_s0_o[2:0];
    //S1
    tlp_crd_type_s1_f[1:0] <= tlp_crd_type_s1[1:0];
    pld_rx_f.rx_st_hvalid_s1_o <= pld_rx.rx_st_hvalid_s1_o;
    pld_rx_f.rx_st_sop_s1_o <= pld_rx.rx_st_sop_s1_o;
    pld_rx_f.rx_st_eop_s1_o <= pld_rx.rx_st_eop_s1_o;
    pld_rx_f.rx_st_dvalid_s1_o <= pld_rx.rx_st_dvalid_s1_o;
    pld_rx_f.rx_st_empty_s1_o[2:0] <= pld_rx.rx_st_empty_s1_o[2:0];
    //S2
    tlp_crd_type_s2_f[1:0] <= tlp_crd_type_s2[1:0];
    pld_rx_f.rx_st_hvalid_s2_o <= pld_rx.rx_st_hvalid_s2_o;
    pld_rx_f.rx_st_sop_s2_o <= pld_rx.rx_st_sop_s2_o;
    pld_rx_f.rx_st_eop_s2_o <= pld_rx.rx_st_eop_s2_o;
    pld_rx_f.rx_st_dvalid_s2_o <= pld_rx.rx_st_dvalid_s2_o;
    pld_rx_f.rx_st_empty_s2_o[2:0] <= pld_rx.rx_st_empty_s2_o[2:0];
    //S3
    tlp_crd_type_s3_f[1:0] <= tlp_crd_type_s3[1:0];
    pld_rx_f.rx_st_hvalid_s3_o <= pld_rx.rx_st_hvalid_s3_o;
    pld_rx_f.rx_st_sop_s3_o <= pld_rx.rx_st_sop_s3_o;
    pld_rx_f.rx_st_eop_s3_o <= pld_rx.rx_st_eop_s3_o;
    pld_rx_f.rx_st_dvalid_s3_o <= pld_rx.rx_st_dvalid_s3_o;
    pld_rx_f.rx_st_empty_s3_o[2:0] <= pld_rx.rx_st_empty_s3_o[2:0];
  end

  //
  // Data Credit Check
  //
// P
  always @(posedge pld_clk)
  begin
    if (~pld_rst_n) begin
      rnr_d_p_avail[15:0] <= 16'd0;
      rnr_d_p_crd_st[1:0] <= 2'd0;
    end
    else begin
      case (rnr_d_p_crd_st[1:0])
      2'd0:
        begin
          if (pld_rx_crd.rx_Dcrdt_init[0])
            rnr_d_p_crd_st[1:0] <= 2'd1;
          else
            rnr_d_p_crd_st[1:0] <= 2'd0;
        end
      2'd1:
        begin
          if (pld_rx_crd.rx_Dcrdt_init[0] & pld_rx_crd.rx_Dcrdt_init_ack[0])
            rnr_d_p_crd_st[1:0] <= 2'd2;
          else
            rnr_d_p_crd_st[1:0] <= 2'd1;
        end
      2'd2:
        begin
          if (pld_rx_crd.rx_Dcrdt_init[0]) begin
            rnr_d_p_crd_st[1:0] <= 2'd2;
            if (pld_rx_crd.rx_Dcrdt_update[0])
              rnr_d_p_avail[15:0] <= rnr_d_p_avail[15:0] + pld_rx_crd.rx_Dcrdt_update_cnt[3:0];
          end
          else
            rnr_d_p_crd_st[1:0] <= 2'd3;
        end
      2'd3:
        begin
          rnr_d_p_crd_st[1:0] <= 2'd3;
          
          if (pld_rx_crd.rx_Dcrdt_update[0])
            rnr_d_p_avail[15:0] <= (rnr_d_p_avail[15:0] + pld_rx_crd.rx_Dcrdt_update_cnt[3:0]) - dec_d_p[3:0];
          else
            rnr_d_p_avail[15:0] <= rnr_d_p_avail[15:0] - dec_d_p[3:0];
        end
      endcase
    end
  end
// NP
  always @(posedge pld_clk)
  begin
    if (~pld_rst_n) begin
      rnr_d_np_avail[15:0] <= 16'd0;
      rnr_d_np_crd_st[1:0] <= 2'd0;
    end
    else begin
      case (rnr_d_np_crd_st[1:0])
      2'd0:
        begin
          if (pld_rx_crd.rx_Dcrdt_init[1])
            rnr_d_np_crd_st[1:0] <= 2'd1;
          else
            rnr_d_np_crd_st[1:0] <= 2'd0;
        end
      2'd1:
        begin
          if (pld_rx_crd.rx_Dcrdt_init[1] & pld_rx_crd.rx_Dcrdt_init_ack[1])
            rnr_d_np_crd_st[1:0] <= 2'd2;
          else
            rnr_d_np_crd_st[1:0] <= 2'd1;
        end
      2'd2:
        begin
          if (pld_rx_crd.rx_Dcrdt_init[1]) begin
            rnr_d_np_crd_st[1:0] <= 2'd2;
            if (pld_rx_crd.rx_Dcrdt_update[1])
              rnr_d_np_avail[15:0] <= rnr_d_np_avail[15:0] + pld_rx_crd.rx_Dcrdt_update_cnt[7:4];
          end
          else
            rnr_d_np_crd_st[1:0] <= 2'd3;
        end
      2'd3:
        begin
          rnr_d_np_crd_st[1:0] <= 2'd3;
          
          if (pld_rx_crd.rx_Dcrdt_update[1])
            rnr_d_np_avail[15:0] <= (rnr_d_np_avail[15:0] + pld_rx_crd.rx_Dcrdt_update_cnt[7:4]) - dec_d_np[3:0];
          else
            rnr_d_np_avail[15:0] <= rnr_d_np_avail[15:0] - dec_d_np[3:0];
        end
      endcase
    end
  end
// CPL
  always @(posedge pld_clk)
  begin
    if (~pld_rst_n) begin
      rnr_d_cpl_avail[15:0] <= 16'd0;
      rnr_d_cpl_crd_st[1:0] <= 2'd0;
    end
    else begin
      case (rnr_d_cpl_crd_st[1:0])
      2'd0:
        begin
          if (pld_rx_crd.rx_Dcrdt_init[2])
            rnr_d_cpl_crd_st[1:0] <= 2'd1;
          else
            rnr_d_cpl_crd_st[1:0] <= 2'd0;
        end
      2'd1:
        begin
          if (pld_rx_crd.rx_Dcrdt_init[2] & pld_rx_crd.rx_Dcrdt_init_ack[2])
            rnr_d_cpl_crd_st[1:0] <= 2'd2;
          else
            rnr_d_cpl_crd_st[1:0] <= 2'd1;
        end
      2'd2:
        begin
          if (pld_rx_crd.rx_Dcrdt_init[2]) begin
            rnr_d_cpl_crd_st[1:0] <= 2'd2;
            if (pld_rx_crd.rx_Dcrdt_update[2])
              rnr_d_cpl_avail[15:0] <= rnr_d_cpl_avail[15:0] + pld_rx_crd.rx_Dcrdt_update_cnt[11:8];
          end
          else
            rnr_d_cpl_crd_st[1:0] <= 2'd3;
        end
      2'd3:
        begin
          rnr_d_cpl_crd_st[1:0] <= 2'd3;
          
          if (pld_rx_crd.rx_Dcrdt_update[2])
            rnr_d_cpl_avail[15:0] <= (rnr_d_cpl_avail[15:0] + pld_rx_crd.rx_Dcrdt_update_cnt[11:8]) - dec_d_cpl[3:0];
          else
            rnr_d_cpl_avail[15:0] <= rnr_d_cpl_avail[15:0] - dec_d_cpl[3:0];
        end
      endcase
    end
  end
//    
  assign dec_d_p[3:0] = decr_d_p_s3 + decr_d_p_s2 + decr_d_p_s1 + decr_d_p_s0;
  assign dec_d_np[3:0] = decr_d_np_s3 + decr_d_np_s2 + decr_d_np_s1 + decr_d_np_s0;
  assign dec_d_cpl[3:0] = decr_d_cpl_s3 + decr_d_cpl_s2 + decr_d_cpl_s1 + decr_d_cpl_s0;
  
  always @(posedge pld_clk)
  begin
    //S0
    if (pld_rx.rx_st_hvalid_s0_o & pld_rx.rx_st_sop_s0_o) begin
      if (pld_rx.rx_st_eop_s0_o) begin
        s0_hdr <= {pld_rx.rx_st_hdr_s0_o[126], pld_rx.rx_st_hdr_s0_o[111]};
      end
      else begin
        s0_hdr <= {pld_rx.rx_st_hdr_s0_o[126], pld_rx.rx_st_hdr_s0_o[111]};
        if (~pld_rx.rx_st_hvalid_s1_o & pld_rx.rx_st_eop_s1_o) begin
          s1_hdr <= {pld_rx.rx_st_hdr_s0_o[126], pld_rx.rx_st_hdr_s0_o[111]};
        end
        else begin
          if (~pld_rx.rx_st_hvalid_s1_o) begin
            s1_hdr <= {pld_rx.rx_st_hdr_s0_o[126], pld_rx.rx_st_hdr_s0_o[111]};
          end
          if (~pld_rx.rx_st_hvalid_s2_o & pld_rx.rx_st_eop_s2_o) begin
            s2_hdr <= {pld_rx.rx_st_hdr_s0_o[126], pld_rx.rx_st_hdr_s0_o[111]};
          end
          else begin
            if (~pld_rx.rx_st_hvalid_s2_o)
              s2_hdr <= {pld_rx.rx_st_hdr_s0_o[126], pld_rx.rx_st_hdr_s0_o[111]};
            if (~pld_rx.rx_st_hvalid_s3_o)
              s3_hdr <= {pld_rx.rx_st_hdr_s0_o[126], pld_rx.rx_st_hdr_s0_o[111]};
          end
        end
      end
    end
    else begin
      s0_hdr <= s3_hdr;
    end
    //S1
    if (pld_rx.rx_st_hvalid_s1_o & pld_rx.rx_st_sop_s1_o) begin
      if (pld_rx.rx_st_eop_s1_o) begin
        s1_hdr <= {pld_rx.rx_st_hdr_s1_o[126], pld_rx.rx_st_hdr_s1_o[111]};
      end
      else begin
        s1_hdr <= {pld_rx.rx_st_hdr_s1_o[126], pld_rx.rx_st_hdr_s1_o[111]};
        if (~pld_rx.rx_st_hvalid_s2_o & pld_rx.rx_st_eop_s2_o) begin
          s2_hdr <= {pld_rx.rx_st_hdr_s1_o[126], pld_rx.rx_st_hdr_s1_o[111]};
        end
        else begin
          if (~pld_rx.rx_st_hvalid_s2_o)
            s2_hdr <= {pld_rx.rx_st_hdr_s1_o[126], pld_rx.rx_st_hdr_s1_o[111]};
          if (~pld_rx.rx_st_hvalid_s3_o)
            s3_hdr <= {pld_rx.rx_st_hdr_s1_o[126], pld_rx.rx_st_hdr_s1_o[111]};
        end
      end
    end
    else begin
      if (~pld_rx.rx_st_hvalid_s0_o)
        s1_hdr <= s3_hdr;
      else
        s1_hdr <= {pld_rx.rx_st_hdr_s0_o[126], pld_rx.rx_st_hdr_s0_o[111]};
    end
    //S2
    if (pld_rx.rx_st_hvalid_s2_o & pld_rx.rx_st_sop_s2_o) begin
      if (pld_rx.rx_st_eop_s2_o) begin
        s2_hdr <= {pld_rx.rx_st_hdr_s2_o[126], pld_rx.rx_st_hdr_s2_o[111]};
      end
      else begin
        s2_hdr <= {pld_rx.rx_st_hdr_s2_o[126], pld_rx.rx_st_hdr_s2_o[111]};
        if (~pld_rx.rx_st_hvalid_s3_o)
          s3_hdr <= {pld_rx.rx_st_hdr_s2_o[126], pld_rx.rx_st_hdr_s2_o[111]};
      end
    end
    else begin
      if (~pld_rx.rx_st_hvalid_s0_o & ~pld_rx.rx_st_hvalid_s1_o)
        s2_hdr <= s3_hdr;
      else
        if (pld_rx.rx_st_hvalid_s1_o)
          s2_hdr <= {pld_rx.rx_st_hdr_s1_o[126], pld_rx.rx_st_hdr_s1_o[111]};
        else
          s2_hdr <= {pld_rx.rx_st_hdr_s0_o[126], pld_rx.rx_st_hdr_s0_o[111]};
    end
    //S3
    if (pld_rx.rx_st_hvalid_s3_o & pld_rx.rx_st_sop_s3_o) begin
      s3_hdr <= {pld_rx.rx_st_hdr_s3_o[126], pld_rx.rx_st_hdr_s3_o[111]};
    end
    else begin
      if (~pld_rx.rx_st_hvalid_s0_o & ~pld_rx.rx_st_hvalid_s1_o & ~pld_rx.rx_st_hvalid_s2_o)
        s3_hdr <= s3_hdr;
      else
        if (pld_rx.rx_st_hvalid_s2_o)
          s3_hdr <= {pld_rx.rx_st_hdr_s2_o[126], pld_rx.rx_st_hdr_s2_o[111]};
        else
          if (pld_rx.rx_st_hvalid_s1_o)
            s3_hdr <= {pld_rx.rx_st_hdr_s1_o[126], pld_rx.rx_st_hdr_s1_o[111]};
          else
            s3_hdr <= {pld_rx.rx_st_hdr_s0_o[126], pld_rx.rx_st_hdr_s0_o[111]};

    end
  end
  
  always @(posedge pld_clk)
  begin
    //S0
    if (pld_rx_f.rx_st_dvalid_s0_o & s0_hdr[1]) begin
      // P
      if (tlp_crd_type_s0_f[1:0] == 2'd0)
        if (pld_rx_f.rx_st_eop_s0_o)
          if (pld_rx_f.rx_st_empty_s0_o[2])
            if (pld_rx_f.rx_st_empty_s0_o[1] & pld_rx_f.rx_st_empty_s0_o[0] & s0_hdr[0])
              decr_d_p_s0[1:0] <= 2'd0;
            else
              decr_d_p_s0[1:0] <= 2'd1;
          else
            if (pld_rx_f.rx_st_empty_s0_o[1] & pld_rx_f.rx_st_empty_s0_o[0] & s0_hdr[0])
              decr_d_p_s0[1:0] <= 2'd1;
            else
              decr_d_p_s0[1:0] <= 2'd2;
        else
          decr_d_p_s0[1:0] <= 2'd2;
      else
        decr_d_p_s0[1:0] <= 2'd0;
      // NP
      if (tlp_crd_type_s0_f[1:0] == 2'd1)
        if (pld_rx_f.rx_st_eop_s0_o)
          if (pld_rx_f.rx_st_empty_s0_o[2])
            if (pld_rx_f.rx_st_empty_s0_o[1] & pld_rx_f.rx_st_empty_s0_o[0] & s0_hdr[0])
              decr_d_np_s0[1:0] <= 2'd0;
            else
              decr_d_np_s0[1:0] <= 2'd1;
          else
            if (pld_rx_f.rx_st_empty_s0_o[1] & pld_rx_f.rx_st_empty_s0_o[0] & s0_hdr[0])
              decr_d_np_s0[1:0] <= 2'd1;
            else
              decr_d_np_s0[1:0] <= 2'd2;
        else
          decr_d_np_s0[1:0] <= 2'd2;
      else
        decr_d_np_s0[1:0] <= 2'd0;
      // CPL
      if (tlp_crd_type_s0_f[1:0] == 2'd2)
        if (pld_rx_f.rx_st_eop_s0_o)
          if (pld_rx_f.rx_st_empty_s0_o[2])
            if (pld_rx_f.rx_st_empty_s0_o[1] & pld_rx_f.rx_st_empty_s0_o[0] & s0_hdr[0])
              decr_d_cpl_s0[1:0] <= 2'd0;
            else
              decr_d_cpl_s0[1:0] <= 2'd1;
          else
            if (pld_rx_f.rx_st_empty_s0_o[1] & pld_rx_f.rx_st_empty_s0_o[0] & s0_hdr[0])
              decr_d_cpl_s0[1:0] <= 2'd1;
            else
              decr_d_cpl_s0[1:0] <= 2'd2;
        else
          decr_d_cpl_s0[1:0] <= 2'd2;
      else
        decr_d_cpl_s0[1:0] <= 2'd0;
    end
    else begin
      decr_d_p_s0[1:0] <= 2'd0;
      decr_d_np_s0[1:0] <= 2'd0;
      decr_d_cpl_s0[1:0] <= 2'd0;
    end
    //S1
    if (pld_rx_f.rx_st_dvalid_s1_o & s1_hdr[1]) begin
      // P
      if (tlp_crd_type_s1_f[1:0] == 2'd0)
        if (pld_rx_f.rx_st_eop_s1_o)
          if (pld_rx_f.rx_st_empty_s1_o[2])
            if (pld_rx_f.rx_st_empty_s1_o[1] & pld_rx_f.rx_st_empty_s1_o[0] & s1_hdr[0])
              decr_d_p_s1[1:0] <= 2'd0;
            else
              decr_d_p_s1[1:0] <= 2'd1;
          else
            if (pld_rx_f.rx_st_empty_s1_o[1] & pld_rx_f.rx_st_empty_s1_o[0] & s1_hdr[0])
              decr_d_p_s1[1:0] <= 2'd1;
            else
              decr_d_p_s1[1:0] <= 2'd2;
        else
          decr_d_p_s1[1:0] <= 2'd2;
      else
        decr_d_p_s1[1:0] <= 2'd0;
      // NP
      if (tlp_crd_type_s1_f[1:0] == 2'd1)
        if (pld_rx_f.rx_st_eop_s1_o)
          if (pld_rx_f.rx_st_empty_s1_o[2])
            if (pld_rx_f.rx_st_empty_s1_o[1] & pld_rx_f.rx_st_empty_s1_o[0] & s1_hdr[0])
              decr_d_np_s1[1:0] <= 2'd0;
            else
              decr_d_np_s1[1:0] <= 2'd1;
          else
            if (pld_rx_f.rx_st_empty_s1_o[1] & pld_rx_f.rx_st_empty_s1_o[0] & s1_hdr[0])
              decr_d_np_s1[1:0] <= 2'd1;
            else
              decr_d_np_s1[1:0] <= 2'd2;
        else
          decr_d_np_s1[1:0] <= 2'd2;
      else
        decr_d_np_s1[1:0] <= 2'd0;
      // CPL
      if (tlp_crd_type_s1_f[1:0] == 2'd2)
        if (pld_rx_f.rx_st_eop_s1_o)
          if (pld_rx_f.rx_st_empty_s1_o[2])
            if (pld_rx_f.rx_st_empty_s1_o[1] & pld_rx_f.rx_st_empty_s1_o[0] & s1_hdr[0])
              decr_d_cpl_s1[1:0] <= 2'd0;
            else
              decr_d_cpl_s1[1:0] <= 2'd1;
          else
            if (pld_rx_f.rx_st_empty_s1_o[1] & pld_rx_f.rx_st_empty_s1_o[0] & s1_hdr[0])
              decr_d_cpl_s1[1:0] <= 2'd1;
            else
              decr_d_cpl_s1[1:0] <= 2'd2;
        else
          decr_d_cpl_s1[1:0] <= 2'd2;
      else
        decr_d_cpl_s1[1:0] <= 2'd0;
    end
    else begin
      decr_d_p_s1[1:0] <= 2'd0;
      decr_d_np_s1[1:0] <= 2'd0;
      decr_d_cpl_s1[1:0] <= 2'd0;
    end
    //S2
    if (pld_rx_f.rx_st_dvalid_s2_o & s2_hdr[1]) begin
      // P
      if (tlp_crd_type_s2_f[1:0] == 2'd0)
        if (pld_rx_f.rx_st_eop_s2_o)
          if (pld_rx_f.rx_st_empty_s2_o[2])
            if (pld_rx_f.rx_st_empty_s2_o[1] & pld_rx_f.rx_st_empty_s2_o[0] & s2_hdr[0])
              decr_d_p_s2[1:0] <= 2'd0;
            else
              decr_d_p_s2[1:0] <= 2'd1;
          else
            if (pld_rx_f.rx_st_empty_s2_o[1] & pld_rx_f.rx_st_empty_s2_o[0] & s2_hdr[0])
              decr_d_p_s2[1:0] <= 2'd1;
            else
              decr_d_p_s2[1:0] <= 2'd2;
        else
          decr_d_p_s2[1:0] <= 2'd2;
      else
        decr_d_p_s2[1:0] <= 2'd0;
      // NP
      if (tlp_crd_type_s2_f[1:0] == 2'd1)
        if (pld_rx_f.rx_st_eop_s2_o)
          if (pld_rx_f.rx_st_empty_s2_o[2])
            if (pld_rx_f.rx_st_empty_s2_o[1] & pld_rx_f.rx_st_empty_s2_o[0] & s2_hdr[0])
              decr_d_np_s2[1:0] <= 2'd0;
            else
              decr_d_np_s2[1:0] <= 2'd1;
          else
            if (pld_rx_f.rx_st_empty_s2_o[1] & pld_rx_f.rx_st_empty_s2_o[0] & s2_hdr[0])
              decr_d_np_s2[1:0] <= 2'd1;
            else
              decr_d_np_s2[1:0] <= 2'd2;
        else
          decr_d_np_s2[1:0] <= 2'd2;
      else
        decr_d_np_s2[1:0] <= 2'd0;
      // CPL
      if (tlp_crd_type_s2_f[1:0] == 2'd2)
        if (pld_rx_f.rx_st_eop_s2_o)
          if (pld_rx_f.rx_st_empty_s2_o[2])
            if (pld_rx_f.rx_st_empty_s2_o[1] & pld_rx_f.rx_st_empty_s2_o[0] & s2_hdr[0])
              decr_d_cpl_s2[1:0] <= 2'd0;
            else
              decr_d_cpl_s2[1:0] <= 2'd1;
          else
            if (pld_rx_f.rx_st_empty_s2_o[1] & pld_rx_f.rx_st_empty_s2_o[0] & s2_hdr[0])
              decr_d_cpl_s2[1:0] <= 2'd1;
            else
              decr_d_cpl_s2[1:0] <= 2'd2;
        else
          decr_d_cpl_s2[1:0] <= 2'd2;
      else
        decr_d_cpl_s2[1:0] <= 2'd0;
    end
    else begin
      decr_d_p_s2[1:0] <= 2'd0;
      decr_d_np_s2[1:0] <= 2'd0;
      decr_d_cpl_s2[1:0] <= 2'd0;
    end
    //S3
    if (pld_rx_f.rx_st_dvalid_s3_o & s3_hdr[1]) begin
      // P
      if (tlp_crd_type_s3_f[1:0] == 2'd0)
        if (pld_rx_f.rx_st_eop_s3_o)
          if (pld_rx_f.rx_st_empty_s3_o[2])
            if (pld_rx_f.rx_st_empty_s3_o[1] & pld_rx_f.rx_st_empty_s3_o[0] & s3_hdr[0])
              decr_d_p_s3[1:0] <= 2'd0;
            else
              decr_d_p_s3[1:0] <= 2'd1;
          else
            if (pld_rx_f.rx_st_empty_s3_o[1] & pld_rx_f.rx_st_empty_s3_o[0] & s3_hdr[0])
              decr_d_p_s3[1:0] <= 2'd1;
            else
              decr_d_p_s3[1:0] <= 2'd2;
        else
          decr_d_p_s3[1:0] <= 2'd2;
      else
        decr_d_p_s3[1:0] <= 2'd0;
      // NP
      if (tlp_crd_type_s3_f[1:0] == 2'd1)
        if (pld_rx_f.rx_st_eop_s3_o)
          if (pld_rx_f.rx_st_empty_s3_o[2])
            if (pld_rx_f.rx_st_empty_s3_o[1] & pld_rx_f.rx_st_empty_s3_o[0] & s3_hdr[0])
              decr_d_np_s3[1:0] <= 2'd0;
            else
              decr_d_np_s3[1:0] <= 2'd1;
          else
            if (pld_rx_f.rx_st_empty_s3_o[1] & pld_rx_f.rx_st_empty_s3_o[0] & s3_hdr[0])
              decr_d_np_s3[1:0] <= 2'd1;
            else
              decr_d_np_s3[1:0] <= 2'd2;
        else
          decr_d_np_s3[1:0] <= 2'd2;
      else
        decr_d_np_s3[1:0] <= 2'd0;
      // CPL
      if (tlp_crd_type_s3_f[1:0] == 2'd2)
        if (pld_rx_f.rx_st_eop_s3_o)
          if (pld_rx_f.rx_st_empty_s3_o[2])
            if (pld_rx_f.rx_st_empty_s3_o[1] & pld_rx_f.rx_st_empty_s3_o[0] & s3_hdr[0])
              decr_d_cpl_s3[1:0] <= 2'd0;
            else
              decr_d_cpl_s3[1:0] <= 2'd1;
          else
            if (pld_rx_f.rx_st_empty_s3_o[1] & pld_rx_f.rx_st_empty_s3_o[0] & s3_hdr[0])
              decr_d_cpl_s3[1:0] <= 2'd1;
            else
              decr_d_cpl_s3[1:0] <= 2'd2;
        else
          decr_d_cpl_s3[1:0] <= 2'd2;
      else
        decr_d_cpl_s3[1:0] <= 2'd0;
    end
    else begin
      decr_d_p_s3[1:0] <= 2'd0;
      decr_d_np_s3[1:0] <= 2'd0;
      decr_d_cpl_s3[1:0] <= 2'd0;
    end
  end
  
  //
  // Header Credit Check
  //
// P
  always @(posedge pld_clk)
  begin
    if (~pld_rst_n) begin
      rnr_hdr_p_avail[15:0] <= 16'd0;
      rnr_hdr_p_crd_st[1:0] <= 2'd0;
    end
    else begin
      case (rnr_hdr_p_crd_st[1:0])
      2'd0:
        begin
          if (pld_rx_crd.rx_Hcrdt_init[0])
            rnr_hdr_p_crd_st[1:0] <= 2'd1;
          else
            rnr_hdr_p_crd_st[1:0] <= 2'd0;
        end
      2'd1:
        begin
          if (pld_rx_crd.rx_Hcrdt_init[0] & pld_rx_crd.rx_Hcrdt_init_ack[0])
            rnr_hdr_p_crd_st[1:0] <= 2'd2;
          else
            rnr_hdr_p_crd_st[1:0] <= 2'd1;
        end
      2'd2:
        begin
          if (pld_rx_crd.rx_Hcrdt_init[0]) begin
            rnr_hdr_p_crd_st[1:0] <= 2'd2;
            if (pld_rx_crd.rx_Hcrdt_update[0])
              rnr_hdr_p_avail[15:0] <= rnr_hdr_p_avail[15:0] + pld_rx_crd.rx_Hcrdt_update_cnt[1:0];
          end
          else
            rnr_hdr_p_crd_st[1:0] <= 2'd3;
        end
      2'd3:
        begin
          rnr_hdr_p_crd_st[1:0] <= 2'd3;
          
          if (pld_rx_crd.rx_Hcrdt_update[0])
            rnr_hdr_p_avail[15:0] <= (rnr_hdr_p_avail[15:0] + pld_rx_crd.rx_Hcrdt_update_cnt[1:0]) - dec_hdr_p[2:0];
          else
            rnr_hdr_p_avail[15:0] <= rnr_hdr_p_avail[15:0] - dec_hdr_p[2:0];
        end
      endcase
    end
  end
// NP
  always @(posedge pld_clk)
  begin
    if (~pld_rst_n) begin
      rnr_hdr_np_avail[15:0] <= 16'd0;
      rnr_hdr_np_crd_st[1:0] <= 2'd0;
    end
    else begin
      case (rnr_hdr_np_crd_st[1:0])
      2'd0:
        begin
          if (pld_rx_crd.rx_Hcrdt_init[1])
            rnr_hdr_np_crd_st[1:0] <= 2'd1;
          else
            rnr_hdr_np_crd_st[1:0] <= 2'd0;
        end
      2'd1:
        begin
          if (pld_rx_crd.rx_Hcrdt_init[1] & pld_rx_crd.rx_Hcrdt_init_ack[1])
            rnr_hdr_np_crd_st[1:0] <= 2'd2;
          else
            rnr_hdr_np_crd_st[1:0] <= 2'd1;
        end
      2'd2:
        begin
          if (pld_rx_crd.rx_Hcrdt_init[1]) begin
            rnr_hdr_np_crd_st[1:0] <= 2'd2;
            if (pld_rx_crd.rx_Hcrdt_update[1])
              rnr_hdr_np_avail[15:0] <= rnr_hdr_np_avail[15:0] + pld_rx_crd.rx_Hcrdt_update_cnt[3:2];
          end
          else
            rnr_hdr_np_crd_st[1:0] <= 2'd3;
        end
      2'd3:
        begin
          rnr_hdr_np_crd_st[1:0] <= 2'd3;
          
          if (pld_rx_crd.rx_Hcrdt_update[1])
            rnr_hdr_np_avail[15:0] <= (rnr_hdr_np_avail[15:0] + pld_rx_crd.rx_Hcrdt_update_cnt[3:2]) - dec_hdr_np[2:0];
          else
            rnr_hdr_np_avail[15:0] <= rnr_hdr_np_avail[15:0] - dec_hdr_np[2:0];
        end
      endcase
    end
  end
// CPL
  always @(posedge pld_clk)
  begin
    if (~pld_rst_n) begin
      rnr_hdr_cpl_avail[15:0] <= 16'd0;
      rnr_hdr_cpl_crd_st[1:0] <= 2'd0;
    end
    else begin
      case (rnr_hdr_cpl_crd_st[1:0])
      2'd0:
        begin
          if (pld_rx_crd.rx_Hcrdt_init[2])
            rnr_hdr_cpl_crd_st[1:0] <= 2'd1;
          else
            rnr_hdr_cpl_crd_st[1:0] <= 2'd0;
        end
      2'd1:
        begin
          if (pld_rx_crd.rx_Hcrdt_init[2] & pld_rx_crd.rx_Hcrdt_init_ack[2])
            rnr_hdr_cpl_crd_st[1:0] <= 2'd2;
          else
            rnr_hdr_cpl_crd_st[1:0] <= 2'd1;
        end
      2'd2:
        begin
          if (pld_rx_crd.rx_Hcrdt_init[2]) begin
            rnr_hdr_cpl_crd_st[1:0] <= 2'd2;
            if (pld_rx_crd.rx_Hcrdt_update[2])
              rnr_hdr_cpl_avail[15:0] <= rnr_hdr_cpl_avail[15:0] + pld_rx_crd.rx_Hcrdt_update_cnt[5:4];
          end
          else
            rnr_hdr_cpl_crd_st[1:0] <= 2'd3;
        end
      2'd3:
        begin
          rnr_hdr_cpl_crd_st[1:0] <= 2'd3;
          
          if (pld_rx_crd.rx_Hcrdt_update[2])
            rnr_hdr_cpl_avail[15:0] <= (rnr_hdr_cpl_avail[15:0] + pld_rx_crd.rx_Hcrdt_update_cnt[5:4]) - dec_hdr_cpl[2:0];
          else
            rnr_hdr_cpl_avail[15:0] <= rnr_hdr_cpl_avail[15:0] - dec_hdr_cpl[2:0];
        end
      endcase
    end
  end
  
  assign dec_hdr_p[2:0] = decr_hdr_p_s3 + decr_hdr_p_s2 + decr_hdr_p_s1 + decr_hdr_p_s0;
  assign dec_hdr_np[2:0] = decr_hdr_np_s3 + decr_hdr_np_s2 + decr_hdr_np_s1 + decr_hdr_np_s0;
  assign dec_hdr_cpl[2:0] = decr_hdr_cpl_s3 + decr_hdr_cpl_s2 + decr_hdr_cpl_s1 + decr_hdr_cpl_s0;
  
  
  always @(posedge pld_clk)
  begin
    //S0
    if (pld_rx_f.rx_st_hvalid_s0_o & pld_rx_f.rx_st_sop_s0_o) begin
      // P
      if (tlp_crd_type_s0_f[1:0] == 2'd0)
        decr_hdr_p_s0 <= 1'd1;
      else
        decr_hdr_p_s0 <= 1'd0;
      // NP
      if (tlp_crd_type_s0_f[1:0] == 2'd1)
        decr_hdr_np_s0 <= 1'd1;
      else
        decr_hdr_np_s0 <= 1'd0;
      // CPL
      if (tlp_crd_type_s0_f[1:0] == 2'd2)
        decr_hdr_cpl_s0 <= 1'd1;
      else
        decr_hdr_cpl_s0 <= 1'd0;
    end
    else begin
      decr_hdr_p_s0 <= 1'd0;
      decr_hdr_np_s0 <= 1'd0;
      decr_hdr_cpl_s0 <= 1'd0;
    end
    //S1
    if (pld_rx_f.rx_st_hvalid_s1_o & pld_rx_f.rx_st_sop_s1_o) begin
      // P
      if (tlp_crd_type_s1_f[1:0] == 2'd0)
        decr_hdr_p_s1 <= 1'd1;
      else
        decr_hdr_p_s1 <= 1'd0;
      // NP
      if (tlp_crd_type_s1_f[1:0] == 2'd1)
        decr_hdr_np_s1 <= 1'd1;
      else
        decr_hdr_np_s1 <= 1'd0;
      // CPL
      if (tlp_crd_type_s1_f[1:0] == 2'd2)
        decr_hdr_cpl_s1 <= 1'd1;
      else
        decr_hdr_cpl_s1 <= 1'd0;
    end
    else begin
      decr_hdr_p_s1 <= 1'd0;
      decr_hdr_np_s1 <= 1'd0;
      decr_hdr_cpl_s1 <= 1'd0;
    end
    //S2
    if (pld_rx_f.rx_st_hvalid_s2_o & pld_rx_f.rx_st_sop_s2_o) begin
      // P
      if (tlp_crd_type_s2_f[1:0] == 2'd0)
        decr_hdr_p_s2 <= 1'd1;
      else
        decr_hdr_p_s2 <= 1'd0;
      // NP
      if (tlp_crd_type_s2_f[1:0] == 2'd1)
        decr_hdr_np_s2 <= 1'd1;
      else
        decr_hdr_np_s2 <= 1'd0;
      // CPL
      if (tlp_crd_type_s2_f[1:0] == 2'd2)
        decr_hdr_cpl_s2 <= 1'd1;
      else
        decr_hdr_cpl_s2 <= 1'd0;
    end
    else begin
      decr_hdr_p_s2 <= 1'd0;
      decr_hdr_np_s2 <= 1'd0;
      decr_hdr_cpl_s2 <= 1'd0;
    end
    //S3
    if (pld_rx_f.rx_st_hvalid_s3_o & pld_rx_f.rx_st_sop_s3_o) begin
      // P
      if (tlp_crd_type_s3_f[1:0] == 2'd0)
        decr_hdr_p_s3 <= 1'd1;
      else
        decr_hdr_p_s3 <= 1'd0;
      // NP
      if (tlp_crd_type_s3_f[1:0] == 2'd1)
        decr_hdr_np_s3 <= 1'd1;
      else
        decr_hdr_np_s3 <= 1'd0;
      // CPL
      if (tlp_crd_type_s3_f[1:0] == 2'd2)
        decr_hdr_cpl_s3 <= 1'd1;
      else
        decr_hdr_cpl_s3 <= 1'd0;
    end
    else begin
      decr_hdr_p_s3 <= 1'd0;
      decr_hdr_np_s3 <= 1'd0;
      decr_hdr_cpl_s3 <= 1'd0;
    end
  end

endmodule
