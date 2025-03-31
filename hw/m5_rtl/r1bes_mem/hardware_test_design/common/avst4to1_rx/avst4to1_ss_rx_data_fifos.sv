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

module avst4to1_ss_rx_data_fifos #(
  parameter DATA_FIFO_WIDTH = 256,
  parameter DATA_FIFO_ADDR_WIDTH = 9, // Data FIFO depth 2^9 = 512/8 = (max 512B payload)
  parameter RAM_TYPE = "M20K",        // "AUTO" or "MLAB" or "M20K".
  parameter SHOWAHEAD = "ON",         // "ON" = showahead mode; "OFF" = normal mode.
  parameter UOFLOW_CHECKING = "OFF",  // "ON" = under/over flow checking; "OFF" = n0 under/over flow checking
  parameter XTRA_FLOP = "OFF"         // "ON" = extra input flop; "OFF" = no extra input flop

) (
//
// PLD SIDE FIFO
//
  input                pld_clk,                              // PLD clock (Core)
  input                pld_rst_n,
  
  input                fifo_data_wr_en_s0,
  output logic         fifo_data_full_s0,
  input  [DATA_FIFO_WIDTH-1:0] fifo_data_din_s0,
  
  input                fifo_data_wr_en_s1,
  output logic         fifo_data_full_s1,
  input  [DATA_FIFO_WIDTH-1:0] fifo_data_din_s1,
//
// PRIM SIDE FIFO
//
  input                avst4to1_prim_clk,                         // Core clock
  input                avst4to1_prim_rst_n,                       // Core clock reset
  
  input                fifo_data_rd_en_s0,
  output logic         fifo_data_empty_s0,
  output logic [DATA_FIFO_WIDTH-1:0] fifo_data_dout_s0,
  
  input                fifo_data_rd_en_s1,
  output logic         fifo_data_empty_s1,
  output logic [DATA_FIFO_WIDTH-1:0] fifo_data_dout_s1
);
//----------------------------------------------------------------------------//
localparam SHOWAHEAD_I = SHOWAHEAD == "ON" ? 1 : 0;

logic  fifo_data_wr_en_s0_i;
logic  fifo_data_wr_en_s0_i_f;
logic  fifo_data_wr_en_s0_ii;
logic  [DATA_FIFO_WIDTH-1:0] fifo_data_din_s0_i;
logic  [DATA_FIFO_WIDTH-1:0] fifo_data_din_s0_i_f;
logic  [DATA_FIFO_WIDTH-1:0] fifo_data_din_s0_ii;
logic  fifo_data_rd_en_s0_i;

logic  fifo_data_wr_en_s1_i;
logic  fifo_data_wr_en_s1_i_f;
logic  fifo_data_wr_en_s1_ii;
logic  [DATA_FIFO_WIDTH-1:0] fifo_data_din_s1_i;
logic  [DATA_FIFO_WIDTH-1:0] fifo_data_din_s1_i_f;
logic  [DATA_FIFO_WIDTH-1:0] fifo_data_din_s1_ii;
logic  fifo_data_rd_en_s1_i;
//----------------------------------------------------------------------------//

assign fifo_data_wr_en_s0_i  = fifo_data_wr_en_s0;
assign fifo_data_wr_en_s0_ii = XTRA_FLOP == "ON" ? fifo_data_wr_en_s0_i_f : fifo_data_wr_en_s0_i;
assign fifo_data_din_s0_ii   = XTRA_FLOP == "ON" ? fifo_data_din_s0_i_f : fifo_data_din_s0;

assign fifo_data_rd_en_s0_i  = UOFLOW_CHECKING == "OFF" ? fifo_data_rd_en_s0 & ~fifo_data_empty_s0 : fifo_data_rd_en_s0;



always @(posedge pld_clk)
begin
  if (~pld_rst_n)
    begin
      fifo_data_wr_en_s0_i_f <= 1'd0;
      fifo_data_wr_en_s1_i_f <= 1'd0;
    end
  else
    begin
      fifo_data_wr_en_s0_i_f <= fifo_data_wr_en_s0_i;
      fifo_data_din_s0_i_f <= fifo_data_din_s0;
      
      fifo_data_wr_en_s1_i_f <= fifo_data_wr_en_s1_i;
      fifo_data_din_s1_i_f <= fifo_data_din_s1;
    end
end

avst4to1_ss_fifo_vcd 
  #(
    .SYNC(0),           
                        
    .IN_DATAWIDTH(DATA_FIFO_WIDTH),     
    .OUT_DATAWIDTH(DATA_FIFO_WIDTH),    
    .ADDRWIDTH(DATA_FIFO_ADDR_WIDTH),   
    .FULL_DURING_RST(1),  
    .FWFT_ENABLE(SHOWAHEAD_I), 
                               
    .FREQ_IMPROVE(0),     
    .USE_ASYNC_RST(1),    
    .RAM_TYPE(RAM_TYPE),
    .UOFLOW_CHECKING(UOFLOW_CHECKING)
  )
s0_data_fifo (
    .rst(~pld_rst_n), 
    .wr_clock(pld_clk),
    .rd_clock(avst4to1_prim_clk),
    .wr_en(fifo_data_wr_en_s0_ii), 
    .rd_en(fifo_data_rd_en_s0_i), 
    .din(fifo_data_din_s0_ii[DATA_FIFO_WIDTH-1:0]),  
    .full(fifo_data_full_s0),
    .empty(fifo_data_empty_s0), 
    .dout(fifo_data_dout_s0[DATA_FIFO_WIDTH-1:0]),
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

assign fifo_data_wr_en_s1_i  = fifo_data_wr_en_s1;
assign fifo_data_wr_en_s1_ii = XTRA_FLOP == "ON" ? fifo_data_wr_en_s1_i_f : fifo_data_wr_en_s1_i;
assign fifo_data_din_s1_ii   = XTRA_FLOP == "ON" ? fifo_data_din_s1_i_f : fifo_data_din_s1;


assign fifo_data_rd_en_s1_i  = UOFLOW_CHECKING == "OFF" ? fifo_data_rd_en_s1 & ~fifo_data_empty_s1 : fifo_data_rd_en_s1;

avst4to1_ss_fifo_vcd 
  #(
    .SYNC(0),           
                        
    .IN_DATAWIDTH(DATA_FIFO_WIDTH),     
    .OUT_DATAWIDTH(DATA_FIFO_WIDTH),    
    .ADDRWIDTH(DATA_FIFO_ADDR_WIDTH),   
    .FULL_DURING_RST(1),  
    .FWFT_ENABLE(SHOWAHEAD_I), 
                               
    .FREQ_IMPROVE(0),     
    .USE_ASYNC_RST(1),    
    .RAM_TYPE(RAM_TYPE),
    .UOFLOW_CHECKING(UOFLOW_CHECKING)
  )
s1_data_fifo (
    .rst(~pld_rst_n), 
    .wr_clock(pld_clk),
    .rd_clock(avst4to1_prim_clk),
    .wr_en(fifo_data_wr_en_s1_ii), 
    .rd_en(fifo_data_rd_en_s1_i), 
    .din(fifo_data_din_s1_ii[DATA_FIFO_WIDTH-1:0]),  
    .full(fifo_data_full_s1),
    .empty(fifo_data_empty_s1), 
    .dout(fifo_data_dout_s1[DATA_FIFO_WIDTH-1:0]),
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

endmodule
