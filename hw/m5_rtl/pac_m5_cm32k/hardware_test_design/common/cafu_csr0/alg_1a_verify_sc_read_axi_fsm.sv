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

module alg_1a_verify_sc_read_axi_fsm
    import afu_axi_if_pkg::*;
#(
   parameter FIFO_PTR_WIDTH = 4
)
(
  input clk,
  input reset_n,    // active low reset

  input         force_disable_afu,                 // active high
  input         set_to_busy,
  input         set_to_not_busy,
  input [2:0]   verify_semantics_cache_reg,
  
  input [FIFO_PTR_WIDTH-1:0]  fifo_count,
  input                       fifo_empty,
  input [8:0]                 fifo_out_N,
  input [51:0]                fifo_out_addr,
  output logic                fifo_pop,

  /*  signals for latency mode
   */
   input latency_mode_enabled,
   input lm_rsp2axi_read_rsp_rcvd,

  output logic lm_axi2rsp_read_req_sent,

  /* signals for AXI-MM read address channel
  */
  output t_axi4_rd_addr_ch          read_addr_chan,
  input  t_axi4_rd_addr_ready       arready
);

/*   ================================================================================================
*/
typedef enum logic [3:0] {
  IDLE            = 'd0,
  WAIT_NOT_EMPTY  = 'd1,
  FIRST_WAIT      = 'd2,
  FIRST_POP       = 'd3,
  FIRST_ARVALID   = 'd4,
  FIRST_ARREADY   = 'd5,
  NEXT_ARREADY    = 'd6,
  LAST_ARREADY    = 'd7,
  CHECK_FIFO      = 'd8,
  SEND_AXI        = 'd9,
  WAIT_AWREADY    = 'd10,
  WAIT_VERIFY     = 'd11
} fsm_enum;

fsm_enum   state;
fsm_enum   next_state;

logic clock_addr_chan;
logic clear_addr_chan;

/*   ================================================================================================
*/
always_ff @( posedge clk )
begin : register_axi_state
       if( reset_n == 1'b0 )            state <= IDLE;
  else if( force_disable_afu == 1'b1 )  state <= IDLE;
  else                                  state <= next_state;
end

/*   ================================================================================================
*/
always_comb
begin : comb_axi_next_state
           fifo_pop = 1'b0;
    clock_addr_chan = 1'b0;
    clear_addr_chan = 1'b0;
    lm_axi2rsp_read_req_sent = 1'b0;

  case( state )
    IDLE :
    begin
      if( set_to_busy == 1'b1 )                   next_state = WAIT_NOT_EMPTY;
      else                                        next_state = IDLE;
    end

    WAIT_NOT_EMPTY :
    begin
           if( set_to_not_busy == 1'b1 )          next_state = IDLE;
      else if( fifo_count > 'd0 )                 next_state = FIRST_WAIT;
      else                                        next_state = WAIT_NOT_EMPTY;
    end

    FIRST_WAIT :
    begin 
      /*   needed because fifo's count updates cycle before avialable for pop
      */
                                                  next_state = FIRST_POP;
    end

    FIRST_POP :
    begin
      /* fifo had at least 4 entries, so pop fifo
      */
                                                    fifo_pop = 1'b1;

      if( latency_mode_enabled == 1'b0 )          next_state = FIRST_ARVALID;
      else                                        next_state = SEND_AXI;
    end

    FIRST_ARVALID :
    begin
      /* assign the first fifo popped entry arriving to the axi addr channel
      */
                                             clock_addr_chan = 1'b1;

      if( fifo_empty == 1'b0 )                      fifo_pop = 1'b1;

      if( fifo_empty == 1'b0 )                    next_state = FIRST_ARREADY;
      else                                        next_state = LAST_ARREADY; // only one packet in the fifo
    end

    FIRST_ARREADY :
    begin
      /* here because more than one packet is in the fifo
      */
      if( arready == 1'b0 )    // wait on the arready for the first packet
      begin
                                                  next_state = FIRST_ARREADY;
      end
      else begin
           if( fifo_empty == 1'b0 )  // clock the second packet and pop for the third
           begin
                                                  next_state = NEXT_ARREADY;
	                                     clock_addr_chan = 1'b1;
                                                    fifo_pop = 1'b1;
           end
           else begin    // clock the second and final packet
                                                  next_state = LAST_ARREADY;
	                                     clock_addr_chan = 1'b1;
           end
      end
    end

    NEXT_ARREADY :
    begin
      if( arready == 1'b0 )   // wait for the next arready
      begin
                                                  next_state = NEXT_ARREADY;
      end
      else begin
           if( fifo_empty == 1'b0 )  // clock next packet, pop packet after it
           begin
                                                  next_state = NEXT_ARREADY;
                                             clock_addr_chan = 1'b1;
                                                    fifo_pop = 1'b1;
           end
           else begin      // clock the next and final packet
                                                  next_state = LAST_ARREADY;
                                             clock_addr_chan = 1'b1;
           end
      end
    end

    LAST_ARREADY :
    begin
      if( arready == 1'b0 )
      begin
                                                  next_state = LAST_ARREADY;
      end
      else begin
	                                     clear_addr_chan = 1'b1;
                                                  next_state = WAIT_NOT_EMPTY;
      end
    end

    SEND_AXI :
    begin
                                             clock_addr_chan = 1'b1;
                                    lm_axi2rsp_read_req_sent = 1'b1;
                                                  next_state = WAIT_AWREADY;
    end

    WAIT_AWREADY :
    begin
      if( arready == 1'b1 )                  clear_addr_chan = 1'b1;

      if( arready == 1'b1 )                       next_state = WAIT_VERIFY;
      else                                        next_state = WAIT_AWREADY;
    end

    WAIT_VERIFY :
    begin
           if( set_to_not_busy == 1'b1 )          next_state = IDLE;
      else if( lm_rsp2axi_read_rsp_rcvd == 1'b0 ) next_state = WAIT_VERIFY;
      else                                        next_state = CHECK_FIFO;
    end

    CHECK_FIFO :
    begin
      if( fifo_empty == 'd0 )                       fifo_pop = 1'b1;

      if( fifo_empty == 'd0 )                     next_state = SEND_AXI;
      else                                        next_state = WAIT_NOT_EMPTY;
    end

    default :                                     next_state = IDLE;
  endcase
end

/*   ================================================================================================
*/
logic arvalid;

logic [AFU_AXI_MAX_ID_WIDTH-1:0]   arid;
logic [AFU_AXI_MAX_ADDR_WIDTH-1:0] araddr;

always_ff @( posedge clk )
begin
  if( reset_n == 1'b0 )
  begin
    arvalid <= 1'b0;
    araddr  <=  'd0;
    arid    <=  'd0;
  end
  else if( clear_addr_chan == 1'b1 )
  begin
    arvalid <= 1'b0;
    araddr  <=  'd0;
    arid    <=  'd0;
  end
  else if( clock_addr_chan == 1'b1 )
  begin
    arvalid <= 1'b1;
    araddr  <= {fifo_out_addr[51:6], 6'd0};
    arid    <= fifo_out_N;
  end
  else begin
    arvalid <= arvalid;
    araddr  <= araddr;
    arid    <= arid;
  end
end

/*   ================================================================================================
*/
always_comb
begin
    read_addr_chan.arvalid = arvalid;
    read_addr_chan.araddr  = araddr;
    read_addr_chan.arid    = arid;

    read_addr_chan.arlen        = 0;
    read_addr_chan.arsize       = esize_512;
    read_addr_chan.arburst      = eburst_INCR;
    read_addr_chan.arprot       = eprot_UNPRIV_NONSEC_DATA;    // ??????????
    read_addr_chan.arqos        = eqos_BEST_EFFORT;            // ??????????
    read_addr_chan.arcache      = ecache_ar_DEVICE_BUFFERABLE; // ??????????
    read_addr_chan.arlock       = elock_NORMAL;                // ??????????
    read_addr_chan.arregion     = 'd0;                         // ??????????

    read_addr_chan.aruser.do_not_send_d2hreq = 1'b0;

    case( verify_semantics_cache_reg )
        3'h0 :                          read_addr_chan.aruser.opcode <= eRD_I;
        3'h1 :                          read_addr_chan.aruser.opcode <= eRD_S;
        3'H2 :                          read_addr_chan.aruser.opcode <= eRD_EM;
        default :                       read_addr_chan.aruser.opcode <= eRD_I;
    endcase
end


endmodule
