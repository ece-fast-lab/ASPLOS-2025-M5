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
// Creation Date : Feb, 2023
// Description   : CAFU Register Router
//

import gbl_pkg::*;
import rtlgen_pkg_v12::*;

module cafu_reg_router (

  //clock and reset
  input  logic                             rst,
  input  logic                             clk,

  //Target Register Access Interface EP SIDE
  input  rtlgen_pkg_v12::cfg_req_64bit_t   treg_req_ep,
  output rtlgen_pkg_v12::cfg_ack_64bit_t   treg_ack_ep,

  //Target Register Access Interface CFG SIDE
  output rtlgen_pkg_v12::cfg_req_64bit_t   treg_req_cfg,
  input  rtlgen_pkg_v12::cfg_ack_64bit_t   treg_ack_cfg,

  //Target Register Access Interface DOE SIDE
  output rtlgen_pkg_v12::cfg_req_64bit_t   treg_req_doe,
  input  rtlgen_pkg_v12::cfg_ack_64bit_t   treg_ack_doe,
  
  //HW Mailbox RAM R/W
  input  logic                             hw_mbox_ram_rd_en,
  input  logic [7:0]                       hw_mbox_ram_rd_addr,
  input  logic                             hw_mbox_ram_wr_en,
  input  logic [7:0]                       hw_mbox_ram_wr_addr,
  input  logic [63:0]                      hw_mbox_ram_wr_data,
  output logic [63:0]                      mbox_ram_dout
);

  localparam MAILBOX_LOW  = 24'h180080;
  localparam MAILBOX_HIGH = 24'h18087F;

  localparam DOE_WR_MBOX  = 24'h000F50;
  localparam DOE_RD_MBOX  = 24'h000F54;

  rtlgen_pkg_v12::cfg_req_64bit_t   treg_req_ram;
  rtlgen_pkg_v12::cfg_ack_64bit_t   treg_ack_ram;

  logic             pick_doe;
  logic             mailbox_ack;
  logic             mailbox_wt;
  logic [1:0]       mailbox_wt_ack;
  logic             mailbox_rd;
  logic [1:0]       mailbox_rd_ack;
  logic [1:0]       mailbox_dw_hi;
  logic [7:0]       mailbox_be;
  logic [63:0]      mailbox_din;

  always @(posedge clk)
    begin
      if (rst)
        begin
          treg_req_cfg <= '0;
          treg_req_ram <= '0;
          treg_req_doe <= '0;
          pick_doe     <= 1'b0;
          mailbox_wt   <= 1'b0;
          mailbox_rd   <= 1'b0;
        end
      else
        begin
          if    ((treg_req_ep.valid == 1'b1) && 
                ((treg_req_ep.addr.mem == DOE_RD_MBOX) || (treg_req_ep.addr.mem == DOE_WR_MBOX) ||    // Address belongs to DOE Mailbox - Mem access //wlm: DOE Read Data Mailbox or DOE Write Data Mailbox, so turn on pick_doe decode
                 (treg_req_ep.addr.cfg == DOE_RD_MBOX) || (treg_req_ep.addr.cfg == DOE_WR_MBOX)) )    // Address belongs to DOE Mailbox - Cfg access //wlm: DOE Read Data Mailbox or DOE Write Data Mailbox, so turn on pick_doe decode
            begin
              treg_req_cfg <= '0;                                                                  // Turn off Register Path
              treg_req_ram <= '0;                                                                  // Turn off Mailbox Path
              treg_req_doe <= treg_req_ep;                                                         // Turn on DOE Path
              pick_doe     <= 1'b1;                                                                // Turn on DOE mux
              mailbox_wt   <= 1'b0;                                                                // Turn off RAM write
              mailbox_rd   <= 1'b0;                                                                // Turn off RAM read
            end
          else if   ((treg_req_ep.valid == 1'b1) &&
                    ((treg_req_ep.addr.mem >= MAILBOX_LOW) && (treg_req_ep.addr.mem <= MAILBOX_HIGH)))// Address belongs to Device Mailbox           //wlm: payload portion of CXL Device Regs, so turn on pick_ram decode
            begin
              treg_req_cfg <= '0;                                                                  // Turn off Register Path
              treg_req_ram.valid <= treg_req_ep.valid;                                             // Turn on Mailbox Path
              treg_req_ram.data  <= treg_req_ep.data;                                              // Turn on Mailbox Path
              treg_req_ram.be    <= treg_req_ep.be;                                                // Turn on Mailbox Path
              treg_req_ram.addr.mem <= treg_req_ep.addr.mem - MAILBOX_LOW;                         // Turn on Mailbox Path
              treg_req_doe <= '0;                                                                  // Turn off DOE Path
              pick_doe     <= 1'b0;                                                                // Turn off DOE mux
              mailbox_wt   <= treg_req_ep.valid && (treg_req_ep.opcode == 4'h1);                   // Write control
              mailbox_rd   <= treg_req_ep.valid && (treg_req_ep.opcode == 4'h0);                   // Read control
            end
          else                                                                                     // Address belongs to Registers               //wlm: NOT(doe mailbox) AND NOT(CXL Device regs payload), turn on register decode
            begin
              treg_req_cfg <= treg_req_ep;                                                         // Turn on Register Path
              treg_req_ram <= '0;                                                                  // Turn off Mailbox Path
              treg_req_doe <= '0;                                                                  // Turn off DOE Path
              pick_doe     <= 1'b0;                                                                // Turn off DOE mux
              mailbox_wt   <= 1'b0;                                                                // Turn off Mailbox Wt
              mailbox_rd   <= 1'b0;                                                                // Turn off Mailbox Rd
            end
        end
    end

  assign mailbox_ack     = mailbox_wt_ack[1] | mailbox_rd_ack[1];

  always @(posedge clk)
    begin
      if (rst)
        treg_ack_ep <= '0;
      else if (pick_doe)                                                                           // Send back DOE Data
        treg_ack_ep <= treg_ack_doe;
      else if (mailbox_ack)                                                                        // Send back RAM Data
        treg_ack_ep <= treg_ack_ram;
      else                                                                                         // Send back Register Data
        treg_ack_ep <= treg_ack_cfg;
    end

///////////////////////////////
// Device Mailbox Ram
///////////////////////////////

  assign mailbox_be  = treg_req_ram.addr.mem[2] ? {treg_req_ram.be[3:0],4'b0}     : treg_req_ram.be;   // Shift BE if accessing upper half
  assign mailbox_din = treg_req_ram.addr.mem[2] ? {treg_req_ram.data[31:0],32'b0} : treg_req_ram.data; // Shift DIN if accessing upper half

  logic             mbox_ram_we;
  logic [7:0]       mbox_ram_be;
  logic [7:0]       mbox_ram_waddr;
  logic [63:0]      mbox_ram_din;
  logic [7:0]       mbox_ram_raddr;

  assign mbox_ram_we    = mailbox_wt | hw_mbox_ram_wr_en;
  assign mbox_ram_be    = hw_mbox_ram_wr_en ? '1 : mailbox_be;
  assign mbox_ram_waddr = hw_mbox_ram_wr_en ? hw_mbox_ram_wr_addr : treg_req_ram.addr.mem[10:3];
  assign mbox_ram_din   = hw_mbox_ram_wr_en ? hw_mbox_ram_wr_data : mailbox_din;
  assign mbox_ram_raddr = hw_mbox_ram_rd_en ? hw_mbox_ram_rd_addr : treg_req_ram.addr.mem[10:3];

 /* assign topram_access_bbs_mbox_t.wen     =mbox_ram_we    ;
  assign topram_access_bbs_mbox_t.ben     =mbox_ram_be    ;
  assign topram_access_bbs_mbox_t.waddr   =mbox_ram_waddr ;
  assign topram_access_bbs_mbox_t.wdata   =mbox_ram_din   ;
  assign topram_access_bbs_mbox_t.raddr   =mbox_ram_raddr ;
  assign mbox_ram_dout = topram_access_bbs_mbox_t.rdata     ;*/
  
  cafu_ram_1r1w_be #(
      .BUS_SIZE_ADDR(8),
      .BUS_SIZE_DATA(64)
      )
      mbox_payload_ram
      (
      .clk    (clk),
      .we     (mbox_ram_we),
      .be     (mbox_ram_be),
      .waddr  (mbox_ram_waddr),
      .din    (mbox_ram_din),
      .raddr  (mbox_ram_raddr),
      .dout   (mbox_ram_dout)
      );

  // Delay the Mailbox ack by 2 clk cycles since GRAM output is delayed by
  // 2 clk cycles.
  always_ff @(posedge clk)
  begin
    if (rst) begin
        mailbox_wt_ack  <= '0;
        mailbox_rd_ack  <= '0;
        mailbox_dw_hi   <= '0;
    end else begin
        mailbox_wt_ack[0]  <= mailbox_wt;
        mailbox_wt_ack[1]  <= mailbox_wt_ack[0];

        mailbox_rd_ack[0]  <= mailbox_rd;
        mailbox_rd_ack[1]  <= mailbox_rd_ack[0];

        mailbox_dw_hi[0]   <= treg_req_ram.addr.mem[2];
        mailbox_dw_hi[1]   <= mailbox_dw_hi[0];
    end
  end


  assign treg_ack_ram.read_valid      = mailbox_rd_ack[1];
  assign treg_ack_ram.read_miss       = '0;
  assign treg_ack_ram.write_valid     = mailbox_wt_ack[1];
  assign treg_ack_ram.write_miss      = '0;
  assign treg_ack_ram.sai_successfull = 1'b1;
  assign treg_ack_ram.data            = mailbox_dw_hi[1] ? {32'b0,mbox_ram_dout[63:32]} : mbox_ram_dout;  // Shift DOUT if accessing upper half

endmodule
