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


module ccv_afu_cdc_fifo_vcd #(
    parameter SYNC                  = 0,      //'1' value means synchronous FIFO, '0' value means asynchronous FIFO
                                              //When synchronous, user should write clock value only to wr_clock.                          
    parameter IN_DATAWIDTH          = 10,     //input data length. in asymmetric FIFO the input to output ratio should be an integer.      
    parameter OUT_DATAWIDTH         = 10,     //output data length.in asymmetric FIFO the input to output ratio should be an integer.      
    parameter ADDRWIDTH             = 8,      //2^ADDRWIDTH=FIFO depth. sets ram dimensions according to max(IN_DATAWIDTH,OUT_DATAWIDTH)   
    parameter FULL_DURING_RST       = 1,      //'1' value means that full flag is high during reset, '0' value means that full flag is low during reset.
    parameter FWFT_ENABLE           = 1,      //when FWFT_ENABLE mode,user should sample the output data with synchronized reset.
    parameter FREQ_IMPROVE          = 1,      // in order to improve design frequency, user should set this parameter to '1' value.Note: use this parameter only when truly necessary.
    parameter USE_ASYNC_RST         = 0,      // when clock is not availible during reset must set to 1
    parameter RAM_TYPE              = "MLAB", // "AUTO" or "MLAB" or "M20K".
    parameter SHOWAHEAD             = "ON",   // "ON" = showahead mode; "OFF" = normal mode.
    parameter UOFLOW_CHECKING       = "ON"    // "ON" = under/over flow checking; "OFF" = n0 under/over flow checking
    )
    
    (
    input  logic                    rst                 , //During reset and 4 cycles afterwards, no rd_en nor wr_en operations are allowed.
                                                          //Reset signal should be asserted for four cycles of rd_clock.
    input  logic                    wr_clock            , 
    input  logic                    rd_clock            , 
    input  logic                    wr_en               , 
    input  logic                    rd_en               , 
    input  logic[IN_DATAWIDTH-1:0]  din                 , 
    input  logic[ADDRWIDTH-1:0]     prog_full_offset    , //functional only for symmetric case
    input  logic[ADDRWIDTH-1:0]     prog_empty_offset   , //functional only for symmetric case
                                      //In order to prevent option of changing offset during a FIFO operation, 
                                      //insert offset values to each instantiation when mapping.
    output logic                    full                ,
    output logic                    empty               ,
    output logic[OUT_DATAWIDTH-1:0] dout                ,
    output logic                    prog_full           ,
    output logic                    prog_empty          ,
    output logic                    underflow           ,
    output logic                    overflow            ,
    output logic[ADDRWIDTH-1:0]     word_cnt_rd_side    ,  //functional only for symmetric case
    output logic[ADDRWIDTH-1:0]     word_cnt_wr_side       //functional only for symmetric case
);

localparam FIFO_WIDTH = (IN_DATAWIDTH < OUT_DATAWIDTH) ? OUT_DATAWIDTH : IN_DATAWIDTH;
localparam FWFT_ENABLE_I = (IN_DATAWIDTH > OUT_DATAWIDTH) ? 1 : FWFT_ENABLE;
localparam FIFO_DEPTH = 2**ADDRWIDTH;
//localparam SHOWAHEAD = "ON";  // "ON" = showahead mode; "OFF" = normal mode.
//localparam RAM_TYPE = "AUTO"; // "AUTO" or "MLAB" or "M20K".

localparam CLKS_SYNC = SYNC==1 ? "TRUE" : "FALSE";
localparam SYNC_DELAYPIPE = SYNC==1 ? 3 : 5;

localparam REG_RAM_OUT = SHOWAHEAD=="ON" ? "OFF" : "ON";

//integer prog_empty_value = prog_empty_offset;
//integer prog_full_value  = prog_full_offset;
//
//localparam INT_PROG_EMPTY = prog_empty_value;
//localparam INT_PROG_FULL  = prog_full_value;

localparam INT_PROG_EMPTY = FIFO_DEPTH/4;
localparam INT_PROG_FULL  = (FIFO_DEPTH*3)/4;

logic wr_clk;
logic rd_clk;

logic aclr;
logic [3:0] sclr;

always @(posedge wr_clock, posedge rst) begin
  if(rst) begin
    sclr <= 4'hf;
  end else begin
   //DRC sclr <= {sclr[2:0],rst};
    sclr <= {sclr[2:0],1'b0};
  end
end

assign aclr = sclr[3];

`ifdef SINGLE_CLK_FIFO
 scfifo scfifo_component
 (
 .clock (wr_clk),
 .data (din),
 .rdreq (rd_en),
 .wrreq (wr_en),
 .empty (empty),
 .full (full),
 .q (dout),
 .usedw (word_cnt_wr_side),
 .aclr (aclr),
// .aclr (rst),
 .almost_empty (),
 .almost_full (),
 .eccstatus (),
 .sclr (sclr)
// .sclr (rst) // switch to sync reset
 );
 defparam
 scfifo_component.add_ram_output_register = REG_RAM_OUT,
 scfifo_component.enable_ecc = "FALSE",
 scfifo_component.intended_device_family = "Agilex",
// scfifo_component.lpm_hint = (RAM_TYPE == "MLAB") ? "RAM_BLOCK_TYPE=MLAB" : ((RAM_TYPE == "M20K") ? "RAM_BLOCK_TYPE=M20K" : ""),
 scfifo_component.ram_block_type = RAM_TYPE,
 scfifo_component.lpm_numwords = FIFO_DEPTH,
 scfifo_component.lpm_showahead = SHOWAHEAD,
 scfifo_component.lpm_type = "scfifo",
 scfifo_component.lpm_width = FIFO_WIDTH,
 scfifo_component.lpm_widthu = ADDRWIDTH+1,
 scfifo_component.overflow_checking = "ON",
 scfifo_component.underflow_checking = "ON",
 scfifo_component.use_eab = "ON";
 
`else
dcfifo dcfifo_component
 (
 .data (din),
 .rdclk (rd_clk),
 .rdreq (rd_en),
 .wrclk (wr_clk),
 .wrreq (wr_en),
 .q (dout),
 .rdempty (empty),
 .rdusedw (word_cnt_rd_side),
 .wrfull (full),
 .wrusedw (word_cnt_wr_side),
  .aclr (aclr),
// .aclr (rst),
 .rdfull (),
 .wrempty ()
 );
 defparam
  dcfifo_component.enable_ecc  = "FALSE",
  dcfifo_component.add_usedw_msb_bit = "OFF",
  dcfifo_component.lpm_widthu = ADDRWIDTH,
 // use as a pair
// dcfifo_component.add_usedw_msb_bit = "ON",
// dcfifo_component.lpm_widthu = ADDRWIDTH+1,
 
 dcfifo_component.clocks_are_synchronized = CLKS_SYNC,
// dcfifo_component.enable_ecc = "FALSE",
 dcfifo_component.intended_device_family = "Agilex",
// dcfifo_component.lpm_hint = (RAM_TYPE == "MLAB") ? "RAM_BLOCK_TYPE=MLAB" : ((RAM_TYPE == "M20K") ? "RAM_BLOCK_TYPE=M20K" : ""),
 dcfifo_component.lpm_hint  = "DISABLE_DCFIFO_EMBEDDED_TIMING_CONSTRAINT=TRUE",
 dcfifo_component.ram_block_type = RAM_TYPE,
 dcfifo_component.lpm_numwords = FIFO_DEPTH,
 dcfifo_component.lpm_showahead = SHOWAHEAD,
 dcfifo_component.lpm_type = "dcfifo",
 dcfifo_component.lpm_width = FIFO_WIDTH,
 dcfifo_component.overflow_checking = UOFLOW_CHECKING,
// dcfifo_component.overflow_checking = "ON",
// dcfifo_component.almost_empty_value = INT_PROG_EMPTY,
   dcfifo_component.read_aclr_synch = "OFF",
 dcfifo_component.rdsync_delaypipe = SYNC_DELAYPIPE,
 dcfifo_component.underflow_checking = UOFLOW_CHECKING,
// dcfifo_component.underflow_checking = "ON",
// dcfifo_component.almost_full_value = INT_PROG_FULL,
   dcfifo_component.write_aclr_synch = "OFF",
 dcfifo_component.wrsync_delaypipe = SYNC_DELAYPIPE,
 dcfifo_component.use_eab = "ON";
`endif

assign wr_clk = wr_clock;					
assign rd_clk = (SYNC) ? wr_clock : rd_clock;			//for synchronous FIFO

assign prog_empty = word_cnt_rd_side <= prog_empty_offset;
assign prog_full  = word_cnt_wr_side >= prog_full_offset;

`ifdef VCS
if (IN_DATAWIDTH < OUT_DATAWIDTH)
begin
    always_comb
    begin
      assert_ratio_error : assert ( OUT_DATAWIDTH % IN_DATAWIDTH == 0 ) 
        else $error("failed: invalid ratio! ratio should be integer (remainder is not allowed)");
    end
end
else
begin
  if (IN_DATAWIDTH > OUT_DATAWIDTH)
  begin
    always_comb                                                                
    begin                                                                      
      assert_ratio_error : assert ( IN_DATAWIDTH % OUT_DATAWIDTH == 0 ) 
      else $error("failed: invalid ratio! ratio should be integer (remainder is not allowed)");
    end
  end
  else //(IN_DATAWIDTH == OUT_DATAWIDTH)
  begin
    
  end
end
`endif


endmodule      
