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
///////////////////////////////////////////////////////////////////////
`include "ccv_afu_globals.vh.iv"

module alg_1a_execute_write_axi_fsm
  import afu_axi_if_pkg::*;
#(
   parameter FIFO_DATA_WIDTH = 16,
   parameter FIFO_PTR_WIDTH  = 4
)
(
  input clk,
  input reset_n,

  input [63:0]  byte_mask_reg,
  input         force_disable_afu,
  input [511:0] pipe_4_ERP,
  input [8:0]   pipe_4_N,
  input         set_to_busy,
  input         set_to_not_busy,
  input [3:0]   write_semantics_cache_reg,

  input [FIFO_PTR_WIDTH-1:0]  fifo_count,
  input [8:0]                 fifo_out_N,
  input [51:0]                fifo_out_addr,
  input                       fifo_empty,

  output logic                fifo_pop,
  output logic                clock_addr_chan,

  /*  signals for latency mode
   */
   input latency_mode_enabled,
   input lm_rsp2axi_write_rsp_rcvd,

  output logic lm_axi2rsp_write_req_sent,

  /* signals for AXI-MM write address channel
  */
  input  t_axi4_wr_addr_ready  awready,
  output t_axi4_wr_addr_ch     write_addr_chan,

  /* signals for AXI-MM write data channel
  */
  input  t_axi4_wr_data_ready  wready,
  output t_axi4_wr_data_ch     write_data_chan
);

/*   ================================================================================================
*/
typedef enum logic [3:0] {
  IDLE               = 4'd0,
  WAIT_TIL_NOT_EMPTY = 4'd1,
  FIRST_WAIT         = 4'd2,
  FIRST_POP          = 4'd3,
  FIRST_AWVALID      = 4'd4,
  FIRST_AWREADY      = 4'd5,
  NEXT_AWREADY       = 4'd6,
  LAST_AWREADY       = 4'd7,
  CHECK_FIFO         = 4'd12,
  SEND_AXI           = 4'd13,
  WAIT_AWREADY       = 4'd14,
  WAIT_VERIFY        = 4'd15
} fsm_enum;

/*   ================================================================================================
*/
fsm_enum axi_state;
fsm_enum axi_next_state;

logic clear_addr_chan;
logic clear_data_chan;
logic clock_data_chan;

/*   ================================================================================================
*/
always_ff @( posedge clk )
begin
       if( reset_n == 1'b0 )            axi_state <= IDLE;
  else if( force_disable_afu == 1'b1 )  axi_state <= IDLE;
  else                                  axi_state <= axi_next_state;
end

/*   ================================================================================================
*/
always_comb
begin
         fifo_pop = 1'b0;
  clock_addr_chan = 1'b0;
  clear_addr_chan = 1'b0;
  clock_data_chan = 1'b0;
  clear_data_chan = 1'b0;

  lm_axi2rsp_write_req_sent = 1'b0;

  case( axi_state )
    IDLE :
    begin
      if( set_to_busy == 1'b1 )                   axi_next_state = WAIT_TIL_NOT_EMPTY;
      else                                        axi_next_state = IDLE;
    end

    WAIT_TIL_NOT_EMPTY :
    begin
           if( set_to_not_busy == 1'b1 )          axi_next_state = IDLE;
      else if( fifo_count > 'd0 )                 axi_next_state = FIRST_WAIT;
      else                                        axi_next_state = WAIT_TIL_NOT_EMPTY;

                                                 clear_addr_chan = 1'b1;
                                                 clear_data_chan = 1'b1;
    end

    FIRST_WAIT :
    begin
      /*   needed because fifo's count updates cycle before avialable for pop
      */
                                                   axi_next_state = FIRST_POP;
    end

    FIRST_POP :
    begin
      /* fifo had at least 4 entries, so pop fifo
      */
      if( latency_mode_enabled == 1'b0 )          axi_next_state = FIRST_AWVALID;
      else                                        axi_next_state = SEND_AXI;

                                                        fifo_pop = 1'b1;
    end

    FIRST_AWVALID :
    begin
      /* assign the first fifo popped entry arriving to the axi addr channel
      */
                                                 clock_addr_chan = 1'b1;
                                                 clock_data_chan = 1'b1;

      if( fifo_empty == 1'b0 ) 
      begin
                                                  axi_next_state = FIRST_AWREADY;
                                                        fifo_pop = 1'b1;
      end
      else begin     // there was only one packet
                                                  axi_next_state = LAST_AWREADY;
      end
    end

    FIRST_AWREADY :
    begin
      /* here because more than one packet is in the fifo
      */
      if( awready == 1'b0 )   // wait on the awready for the first packet
      begin
                                                  axi_next_state = FIRST_AWREADY;
      end
      else if( fifo_empty == 1'b0 )     // clock the second packet and pop for the third
      begin
                                                  axi_next_state = NEXT_AWREADY;
                                                 clock_addr_chan = 1'b1;
                                                 clock_data_chan = 1'b1;
                                                        fifo_pop = 1'b1;
      end
      else begin   // clock the second packet but no third to pop
                                                  axi_next_state = LAST_AWREADY;
                                                 clock_addr_chan = 1'b1;
                                                 clock_data_chan = 1'b1;
      end
    end

    NEXT_AWREADY :
    begin
      if( awready == 1'b0 )   // wait on the next awready
      begin
                                                  axi_next_state = NEXT_AWREADY;
      end
      else if( fifo_empty == 1'b0 )  // clock next packet, pop packet after it
      begin
                                                  axi_next_state = NEXT_AWREADY;
                                                 clock_addr_chan = 1'b1;
                                                 clock_data_chan = 1'b1;
                                                        fifo_pop = 1'b1;
      end
      else begin                // clock next packet but none after it
                                                  axi_next_state = LAST_AWREADY;
                                                 clock_addr_chan = 1'b1;
                                                 clock_data_chan = 1'b1;
      end
    end

    LAST_AWREADY :
    begin
      if( awready == 1'b0 )
      begin
                                                  axi_next_state = LAST_AWREADY;
      end
      else begin
                                                 clear_addr_chan = 1'b1;
                                                 clear_data_chan = 1'b1;
                                                  axi_next_state = WAIT_TIL_NOT_EMPTY;
      end
    end

    SEND_AXI :
    begin
       /*  assumes pop already occured
      */
                                                  axi_next_state = WAIT_AWREADY;
                                                 clock_addr_chan = 1'b1;
                                                 clock_data_chan = 1'b1;
                                       lm_axi2rsp_write_req_sent = 1'b1;
    end

    WAIT_AWREADY :
    begin
      if( awready == 1'b0 )                       axi_next_state = WAIT_AWREADY;
      else begin
                                                  axi_next_state = WAIT_VERIFY;
                                                 clear_addr_chan = 1'b1;
                                                 clear_data_chan = 1'b1;
      end
    end

    WAIT_VERIFY :
    begin
           if( set_to_not_busy == 1'b1 )           axi_next_state = IDLE;
      else if( lm_rsp2axi_write_rsp_rcvd == 1'b1 ) axi_next_state = CHECK_FIFO;
      else                                         axi_next_state = WAIT_VERIFY;
    end

    CHECK_FIFO :
    begin
      if( fifo_empty == 1'b0 )
      begin
                                                  axi_next_state = SEND_AXI;
                                                        fifo_pop = 1'b1;
      end
      else begin
                                                  axi_next_state = WAIT_TIL_NOT_EMPTY;
      end
    end


    default : axi_next_state = IDLE;
  endcase
end

/*   ================================================================================================
     clock the write address channel
*/
logic awvalid;

logic [AFU_AXI_MAX_ID_WIDTH-1:0]   awid;
logic [AFU_AXI_MAX_ADDR_WIDTH-1:0] awaddr; 

always_ff @( posedge clk )
begin
  if( reset_n == 1'b0 )
  begin
    awvalid <= 1'b0;
    awaddr  <=  'd0;
    awid    <=  'd0;
  end
  else if( clear_addr_chan == 1'b1 )
  begin
    awvalid <= 1'b0;
    awaddr  <=  'd0;
    awid    <=  'd0;
  end
  else if( clock_addr_chan == 1'b1 ) 
  begin
    awvalid <= 1'b1;
    awaddr  <= {fifo_out_addr[51:6],6'd0};
    awid    <= fifo_out_N;
  end
  else begin
    awvalid <= awvalid;
    awaddr  <= awaddr;
    awid    <= awid;
  end
end


always_comb
begin
    write_addr_chan.awvalid = awvalid;
    write_addr_chan.awaddr  = awaddr;
    write_addr_chan.awid    = awid;

    write_addr_chan.awlen    = 'd0;
    write_addr_chan.awsize   = esize_512;
    write_addr_chan.awburst  = eburst_FIXED;
    write_addr_chan.awprot   = eprot_UNPRIV_NONSEC_DATA;      // ?????
    write_addr_chan.awqos    = eqos_BEST_EFFORT;              // ?????
    write_addr_chan.awcache  = ecache_aw_DEVICE_BUFFERABLE;   // ?????
    write_addr_chan.awlock   = elock_NORMAL;                  // ?????
    write_addr_chan.awregion = 'd0;                           // ?????

    write_addr_chan.awuser.do_not_send_d2hreq = 1'b0;

    case( write_semantics_cache_reg )
      `ifdef INC_AC_WSC_0
             4'd0 :         write_addr_chan.awuser.opcode = eWR_I_SO;
      `endif
      `ifdef INC_AC_WSC_1
             4'd1 :         write_addr_chan.awuser.opcode = eWR_M;
      `endif
      `ifdef INC_AC_WSC_2
             4'd2 :         write_addr_chan.awuser.opcode = eWR_M;
      `endif
      `ifdef INC_AC_WSC_3
             4'd3 :         write_addr_chan.awuser.opcode = eWR_I_WO;
      `endif
      `ifdef INC_AC_WSC_4
             4'd4 :         write_addr_chan.awuser.opcode = eWR_I_WO;
      `endif
      `ifdef INC_AC_WSC_5
             4'd5 :         write_addr_chan.awuser.opcode = eWR_I_SO;
      `endif
      `ifdef INC_AC_WSC_6
             4'd6 :         write_addr_chan.awuser.opcode = eWR_M;
      `endif
      `ifdef INC_AC_WSC_7
             4'd7 :         write_addr_chan.awuser.opcode = eWR_M;
      `endif
      default :             write_addr_chan.awuser.opcode = eWR_M;
    endcase
end

/*   ================================================================================================
     clock the write data channel
*/
logic wvalid;
logic wlast;

logic [AFU_AXI_MAX_DATA_WIDTH-1:0]   wdata;
logic [AFU_AXI_MAX_DATA_WIDTH/8-1:0] wstrb;

always_ff @( posedge clk )
begin
  if( reset_n == 1'b0 )
  begin
    wvalid <= 1'b0;
    wlast  <= 1'b0;
    wdata  <=  'd0;
    wstrb  <=  'd0;
  end
  else if( clear_data_chan == 1'b1 )
  begin
    wvalid <= 1'b0;
    wlast  <= 1'b0;
    wdata  <=  'd0;
    wstrb  <=  'd0;
  end
  else if( clock_data_chan == 1'b1 )
  begin
    wvalid <= 1'b1;
    wlast  <= 1'b1;
    wdata  <= pipe_4_ERP;
    wstrb  <= byte_mask_reg;
  end
  else begin
    wvalid <= wvalid;
    wlast  <= wlast;
    wdata  <= wdata;
    wstrb  <= wstrb;
  end
end


always_comb
begin
  write_data_chan.wvalid = wvalid;
  write_data_chan.wlast  = wlast;
  write_data_chan.wdata  = wdata;
  write_data_chan.wstrb  = wstrb;
  write_data_chan.wuser.poison = 1'b0;
end

endmodule
