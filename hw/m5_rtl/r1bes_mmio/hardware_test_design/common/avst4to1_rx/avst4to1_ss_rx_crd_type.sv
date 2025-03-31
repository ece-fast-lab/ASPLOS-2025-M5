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


module avst4to1_ss_rx_crd_type #(
  parameter MAX_N_HDR_CRD = 12'd2,
  parameter MAX_N_DATA_CRD = 16'd32,
  parameter DATA_FIFO_ADDR_WIDTH = 9 // Data FIFO depth 2^9 = 512/8 = (max 512B payload)
) (
//
  input [7:0]        rx_hdr_max_crd,
//
// PLD IF
//
  input              pld_clk,                                       // Clock (Core)
  input              pld_rst_n,                                     // Reset (Core)
  input              pld_init_done_rst_n,
  
  input              tx_init_pulse,
  input              send_rx_Hcrdt_update,
  input [1:0]        send_rx_Hcrdt_cnt,
  input              send_rx_Dcrdt_update,
  input [3:0]        send_rx_Dcrdt_cnt,
  
  input [2:0]        Dec_Hcrdt_avail,
  
  output logic [7:0] Dcrd_avail_cnt,
  output logic [7:0] Hcrd_avail_cnt,
  
  input              rx_Hcrdt_init_ack,
  input              rx_Dcrdt_init_ack,
  
  output logic [1:0] rx_Hcrdt_update_cnt,                           // number of header entries
  output logic       rx_Hcrdt_update,
  output logic       rx_Hcrdt_init,
  
  output logic [3:0] rx_Dcrdt_update_cnt,                           // number of 16B data entries
  output logic       rx_Dcrdt_update,
  output logic       rx_Dcrdt_init
);
//----------------------------------------------------------------------------//


logic       update_hdr_crdt;
logic [1:0] send_rx_Hcrdt_cnt_f;
logic [1:0] send_rx_Hcrdt_cnt_ff;

logic [3:0] send_rx_Dcrdt_cnt_f;
logic [3:0] send_rx_Dcrdt_cnt_ff;

logic       update_data_crdt;
logic       update_data_crdt_f;

logic [1:0] Hcrd_init_xtra_hi_cnt;
logic [1:0] Dcrd_init_xtra_hi_cnt;

logic [2:0] rx_Dcrdt_st;
logic [2:0] rx_Hcrdt_st;

logic [15:0] Dcrd_init_cnt;
logic [11:0] Hcrd_init_cnt;
//----------------------------------------------------------------------------//
//
// Data Credit
always @(posedge pld_clk)
begin
    if (~pld_rst_n) begin
       send_rx_Dcrdt_cnt_f[3:0] <= 4'd0;
       send_rx_Dcrdt_cnt_ff[3:0] <= 4'd0;
       
       update_data_crdt <= 1'd0;
       
       Dcrd_init_xtra_hi_cnt[1:0] <= 2'd0;
       
       rx_Dcrdt_update_cnt[3:0] <= 4'd0;
       rx_Dcrdt_update <= 1'd0;
       rx_Dcrdt_init <= 1'd0;
       
       Dcrd_init_cnt[15:0] <= 16'd0;
       
       rx_Dcrdt_st[2:0] <= 3'd0;
    end
    else begin
       send_rx_Dcrdt_cnt_f[3:0]  <= send_rx_Dcrdt_cnt[3:0];
       send_rx_Dcrdt_cnt_ff[3:0] <= send_rx_Dcrdt_cnt_f[3:0];
       
       if (send_rx_Dcrdt_update & (send_rx_Dcrdt_cnt[3:0] > 4'd0))
          update_data_crdt <= 1'd1;
       else
          update_data_crdt <= 1'd0;
       
       case (rx_Dcrdt_st[2:0])
       3'b000: // Start Credit Init
         begin
           Dcrd_init_xtra_hi_cnt[1:0] <= 2'd0;
           
           rx_Dcrdt_update_cnt[3:0] <= 4'd0;
           rx_Dcrdt_update <= 1'd0;
           rx_Dcrdt_init <= 1'd1;
           
           Dcrd_init_cnt[15:0] <= MAX_N_DATA_CRD[15:0];
           
           if (rx_Dcrdt_init_ack)
              rx_Dcrdt_st[2:0] <= 3'b001;
           else
              rx_Dcrdt_st[2:0] <= 3'b000;
         end
       3'b001: // Send Init Credit
         begin
           Dcrd_init_xtra_hi_cnt[1:0] <= 2'd0;
           
           rx_Dcrdt_update <= 1'd1;
           rx_Dcrdt_init <= 1'd1;
           
           if (Dcrd_init_cnt[15:0] >= 16'h0f) begin
              rx_Dcrdt_update_cnt[3:0] <= 4'hf;
              Dcrd_init_cnt[15:0] <= Dcrd_init_cnt[15:0] - 16'h0f;
           end
           else begin
              Dcrd_init_cnt[15:0] <= 16'd0;
              rx_Dcrdt_update_cnt[3:0] <= Dcrd_init_cnt[3:0];
           end
           
           if (tx_init_pulse)
              rx_Dcrdt_st[2:0] <= 3'b000;
           else if (Dcrd_init_cnt[15:0] <= 16'h0f)
              rx_Dcrdt_st[2:0] <= 3'b010;
           else
              rx_Dcrdt_st[2:0] <= 3'b001;
         end
       3'b010: // Hold Inir High
         begin
           rx_Dcrdt_update_cnt[3:0] <= 4'd0;
           rx_Dcrdt_update <= 1'd0;
           rx_Dcrdt_init <= 1'd0;
           
           Dcrd_init_xtra_hi_cnt[1:0] <= Dcrd_init_xtra_hi_cnt[1:0] + 2'd1;
           
           if (tx_init_pulse)
              rx_Dcrdt_st[2:0] <= 3'b000;
           else if (Dcrd_init_xtra_hi_cnt[1:0] == 2'd3)
              rx_Dcrdt_st[2:0] <= 3'b011;
           else
              rx_Dcrdt_st[2:0] <= 3'b010;
         end
       3'b011: // Credit Ready
         begin
           Dcrd_init_xtra_hi_cnt[1:0] <= 2'd0;
           
           rx_Dcrdt_update_cnt[3:0] <= 4'd0;
           rx_Dcrdt_update <= 1'd0;
           rx_Dcrdt_init <= 1'd0;
           
           if (tx_init_pulse)
              rx_Dcrdt_st[2:0] <= 3'b000;
           else if (update_data_crdt)
              rx_Dcrdt_st[2:0] <= 3'b100;
           else
              rx_Dcrdt_st[2:0] <= 3'b011;
         end
       3'b100: // Update Credit
         begin
           Dcrd_init_xtra_hi_cnt[1:0] <= 2'd0;
           
           rx_Dcrdt_update_cnt[3:0] <= send_rx_Dcrdt_cnt_ff[3:0];
           rx_Dcrdt_update <= 1'd1;
           rx_Dcrdt_init <= 1'd0;
           
           if (tx_init_pulse)
              rx_Dcrdt_st[2:0] <= 3'b000;
           else if (~update_data_crdt)
              rx_Dcrdt_st[2:0] <= 3'b011;
           else
              rx_Dcrdt_st[2:0] <= 3'b100;
         end
       endcase
    end
end
//
// Header Credit
always @(posedge pld_clk)
begin
    if (~pld_rst_n) begin
       send_rx_Hcrdt_cnt_f[1:0] <= 2'd0;
       send_rx_Hcrdt_cnt_ff[1:0] <= 2'd0;
       
       Hcrd_init_xtra_hi_cnt[1:0] <= 2'd0;
       
       rx_Hcrdt_update_cnt[1:0] <= 2'd0;
       rx_Hcrdt_update <= 1'd0;
       rx_Hcrdt_init <= 1'd0;
       
       update_hdr_crdt <= 1'd0;
       
       Hcrd_init_cnt[11:0] <= 12'd0;
       
       rx_Hcrdt_st[2:0] <= 3'd0;
    end
    else begin
       send_rx_Hcrdt_cnt_f[1:0] <= send_rx_Hcrdt_cnt[1:0];
       send_rx_Hcrdt_cnt_ff[1:0] <= send_rx_Hcrdt_cnt_f[1:0];
       
       if (send_rx_Hcrdt_update & (send_rx_Hcrdt_cnt[1:0] > 2'd0))
          update_hdr_crdt <= 1'd1;
       else
          update_hdr_crdt <= 1'd0;
       
       case (rx_Hcrdt_st[2:0])
       3'b000: // Start Credit Init
         begin
           Hcrd_init_xtra_hi_cnt[1:0] <= 2'd0;
           
           rx_Hcrdt_update_cnt[1:0] <= 2'd0;
           rx_Hcrdt_update <= 1'd0;
           rx_Hcrdt_init <= 1'd1;
           
           Hcrd_init_cnt[11:0] <= {4'd0, rx_hdr_max_crd[7:0]};
           
           if (rx_Hcrdt_init_ack)
              rx_Hcrdt_st[2:0] <= 3'b001;
           else
              rx_Hcrdt_st[2:0] <= 3'b000;
         end
       3'b001: // Send Init Credit
         begin
           Hcrd_init_xtra_hi_cnt[1:0] <= 2'd0;
           
           rx_Hcrdt_update <= 1'd1;
           rx_Hcrdt_init <= 1'd1;
           
           if (Hcrd_init_cnt[11:0] >= 12'h03) begin
              rx_Hcrdt_update_cnt[1:0] <= 2'd3;
              Hcrd_init_cnt[11:0] <= Hcrd_init_cnt[11:0] - 12'h03;
           end
           else begin
              Hcrd_init_cnt[11:0] <= 12'd0;
              rx_Hcrdt_update_cnt[1:0] <= Hcrd_init_cnt[1:0];
           end
           
           if (tx_init_pulse)
              rx_Hcrdt_st[2:0] <= 3'b000;
           else if (Hcrd_init_cnt[11:0] <= 12'd3)
              rx_Hcrdt_st[2:0] <= 3'b010;
           else
              rx_Hcrdt_st[2:0] <= 3'b001;
         end
       3'b010: // Hold Init High
         begin
           rx_Hcrdt_update_cnt[1:0] <= 2'd0;
           rx_Hcrdt_update <= 1'd0;
           rx_Hcrdt_init <= 1'd1;
           
           Hcrd_init_xtra_hi_cnt[1:0] <= Hcrd_init_xtra_hi_cnt[1:0] + 2'd1;
           
           if (tx_init_pulse)
              rx_Hcrdt_st[2:0] <= 3'b000;
           else if (Hcrd_init_xtra_hi_cnt[1:0] == 2'd3)
              rx_Hcrdt_st[2:0] <= 3'b011;
           else
              rx_Hcrdt_st[2:0] <= 3'b010;
         end
       3'b011: // Credit Init Ready
         begin
           Hcrd_init_xtra_hi_cnt[1:0] <= 2'd0;
           
           rx_Hcrdt_update_cnt[1:0] <= 2'd0;
           rx_Hcrdt_update <= 1'd0;
           rx_Hcrdt_init <= 1'd0;
           
           if (tx_init_pulse)
              rx_Hcrdt_st[2:0] <= 3'b000;
           else if (update_hdr_crdt)
              rx_Hcrdt_st[2:0] <= 3'b100;
           else
              rx_Hcrdt_st[2:0] <= 3'b011;
         end
       3'b100: // Update Credit
         begin
           Hcrd_init_xtra_hi_cnt[1:0] <= 2'd0;
           
           rx_Hcrdt_update_cnt[1:0] <= send_rx_Hcrdt_cnt_ff[1:0];
           rx_Hcrdt_update <= 1'd1;
           rx_Hcrdt_init <= 1'd0;
           
           if (tx_init_pulse)
              rx_Hcrdt_st[2:0] <= 3'b000;
           else if (~update_hdr_crdt)
              rx_Hcrdt_st[2:0] <= 3'b011;
           else
              rx_Hcrdt_st[2:0] <= 3'b100;
         end
       endcase
    end
end
//
// Avail Credit
//
always @(posedge pld_clk)
begin
  if (~pld_rst_n) begin
     Hcrd_avail_cnt[7:0] <= 8'd0;
     Dcrd_avail_cnt[7:0] <= 8'd0;
  end
  else begin
     // data
     if (rx_Dcrdt_update) begin
       if (rx_Dcrdt_init)
         Dcrd_avail_cnt[7:0] <= Dcrd_avail_cnt[7:0] + {4'd0, rx_Dcrdt_update_cnt[3:0]};
     end
     // header
     if (rx_Hcrdt_update) begin
       if (rx_Hcrdt_init) begin
         Hcrd_avail_cnt[7:0] <= Hcrd_avail_cnt[7:0] + {6'd0, rx_Hcrdt_update_cnt[1:0]};
       end
       else begin
         if (Dec_Hcrdt_avail[2:0] != 3'd0)
           Hcrd_avail_cnt[7:0] <= Hcrd_avail_cnt[7:0] + {6'd0, rx_Hcrdt_update_cnt[1:0]} - {5'd0, Dec_Hcrdt_avail[2:0]};
         else
           Hcrd_avail_cnt[7:0] <= Hcrd_avail_cnt[7:0] + {6'd0, rx_Hcrdt_update_cnt[1:0]};
       end
     end
     else begin
       if (Dec_Hcrdt_avail[2:0] != 3'd0)
         Hcrd_avail_cnt[7:0] <= Hcrd_avail_cnt[7:0] - {5'd0, Dec_Hcrdt_avail[2:0]};
     end
  end
end


endmodule
