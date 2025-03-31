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

module alg_1a_execute_response_count
    import ccv_afu_pkg::*;
    import afu_axi_if_pkg::*;
(
  input logic clk,
  input logic reset_n,    // active low reset

  /*  signals to/from the write phase FSM of the execute stage of Algorithm 1a
  */
  input logic enable_in,       // active high

  /*  signals around a SLVERR on the AXI write response channel
  */
  input logic clear_slverr,    // active high

  output logic slverr_received,
  output logic busy_out,  // active hight

  /*  signals for latency mode
   */
  input logic latency_mode_enabled,
  input logic lm_axi2rsp_write_req_sent,

  output logic lm_rsp2axi_write_rsp_rcvd,

  /* signals for AXI-MM write responses channel
  */
  output t_axi4_wr_resp_ready  bready,
  input  t_axi4_wr_resp_ch     write_resp_chan,

  /*  signals from configuration and debug registers
  */
  input logic [8:0] NAI,
  input logic [7:0] number_of_address_increments_reg,
  input logic       single_transaction_per_set,        // active high
  input logic      force_disable_afu                   // active high
);
    
// =================================================================================================
typedef enum logic [2:0] {
  IDLE          = 'd0,
  START         = 'd1,
  CHECK_COUNT   = 'd2,
  COMPLETE      = 'd3,
  AWAIT_REQ     = 'd4,
  AWAIT_RSP     = 'd5,
  CHECK_COUNT_2 = 'd6
} fsm_enum;

fsm_enum   state;
fsm_enum   next_state;

// =================================================================================================
logic initialize;
logic pipe_1_valid;
logic pipe_2_valid;
logic pipe_2_slverr_received;
logic set_to_not_busy;

logic [8:0] pipe_3_response_count;
logic [8:0] NAI_clkd;

t_axi4_resp_encoding  pipe_1_resp;

// =================================================================================================
always_ff @( posedge clk )
begin
       if( reset_n == 1'b0 )           NAI_clkd <= 9'd0;
  else if( force_disable_afu == 1'b1 ) NAI_clkd <= 9'd0;
  else if( enable_in == 1'b1 )         NAI_clkd <= NAI;
  else                                 NAI_clkd <= NAI_clkd;
end

// =================================================================================================
always_ff @( posedge clk )
begin
       if( reset_n == 1'b0 )         busy_out <= 1'b0;
  else if( initialize == 1'b1 )      busy_out <= 1'b1;
  else if( set_to_not_busy == 1'b1 ) busy_out <= 1'b0;
  else                               busy_out <= busy_out;
end

// =================================================================================================
/*  this is the BREADY signal to the AXI-MM write response channel
*/
always_ff @( posedge clk )
begin
       if( reset_n == 1'b0 )                      bready <= 1'b0;
  else if( initialize == 1'b1 )                   bready <= 1'b1;
  else if( single_transaction_per_set == 1'b1 )
  begin
    if( pipe_3_response_count < 1 )               bready <= bready;
    else                                          bready <= 1'b0;
  end
  else if( pipe_3_response_count < (NAI_clkd+1) ) bready <= bready;
  else                                            bready <= 1'b0;
end

// =================================================================================================
/*  treating the BREADY signal as a 'busy' flag for this module
    if BREADY is low, valids are low
    if BREADY is high, clock the BVALID signal of the AXI-MM write response channel
*/
always_ff @( posedge clk )
begin
       if( reset_n == 1'b0 ) pipe_1_valid <= 1'b0;
  else if( bready == 1'b0 )  pipe_1_valid <= 1'b0;
  else                       pipe_1_valid <= write_resp_chan.bvalid;
end

// =================================================================================================
/*  treating the BREADY signal as a 'busy' flag for this module
    if BREADY is low, set to zero
    if BREADY is high, clock the BRESP signal of the AXI-MM write response channel
*/
always_ff @( posedge clk )
begin
       if( reset_n == 1'b0 ) pipe_1_resp <= eresp_EXOKAY;
  else if( bready == 1'b0 )  pipe_1_resp <= eresp_EXOKAY;
  else                       pipe_1_resp <= write_resp_chan.bresp;
end

// =================================================================================================
/*  treating the BREADY signal as a 'busy' flag for this module
    if BREADY is low, valids are low
    if BREADY is high, clock the result of the logic indicating a valid write response
*/
always_ff @( posedge clk )
begin
       if( reset_n == 1'b0 ) pipe_2_valid <= 1'b0;
  else if( bready == 1'b0 )  pipe_2_valid <= 1'b0;
  else                       pipe_2_valid <= pipe_1_valid; // want to count slverr in response count
  //else begin
  //     pipe_2_valid <= ( ( pipe_1_valid == 1'b1 )
  //                     & ( pipe_1_resp  == eresp_OKAY )
  //                     );
  //end
end

// =================================================================================================
/*  treating the BREADY signal as a 'busy' flag for this module
    if BREADY is low, set to zero
    if BREADY is high, increment by the value in pipe_2_valid (1 or 0)
*/
always_ff @( posedge clk )
begin
       if( reset_n == 1'b0 )    pipe_3_response_count <= 9'd0;
  else if( initialize == 1'b1 ) pipe_3_response_count <= 9'd0;
  else if( bready == 1'b0 )     pipe_3_response_count <= 9'd0;
  else                          pipe_3_response_count <= pipe_3_response_count + {8'd0, pipe_2_valid};
end

// =================================================================================================
/* Have to monitor bresp for a SLVERR. If received, treat like an error and record
   all errors the same except for patterns.
*/
always_ff @( posedge clk )
begin
       if( reset_n == 1'b0 )      pipe_2_slverr_received <= 1'b0;
  else if( clear_slverr == 1'b1 ) pipe_2_slverr_received <= 1'b0;
  else if( bready == 1'b0 )       pipe_2_slverr_received <= 1'b0;
  else begin
       pipe_2_slverr_received <= ( ( pipe_1_valid == 1'b1 )
                                 & ( pipe_1_resp  == eresp_SLVERR ) )
                                 | pipe_2_slverr_received;          // once dedicated, keep it until clear
  end
end


assign slverr_received = pipe_2_slverr_received;

// =================================================================================================
always_ff @( posedge clk )
begin
       if( reset_n == 1'b0 )                state <= IDLE;
  else if( force_disable_afu== 1'b1 )       state <= COMPLETE;   // so that set_to_not_busy pulses
  else if( pipe_2_slverr_received == 1'b1 ) state <= COMPLETE;   // so that set_to_not_busy pulses
  else                                      state <= next_state;
end

// =================================================================================================
always_comb
begin
  initialize = 1'b0;
  set_to_not_busy = 1'b0;
  lm_rsp2axi_write_rsp_rcvd = 1'b0;

  case( state )
    IDLE : 
    begin
      if( enable_in == 1'b1 )
      begin
                                                  next_state = START;
                                                  initialize = 1'b1;
      end
      else begin
                                                  next_state = IDLE;
      end
    end

    START :
    begin
      if( latency_mode_enabled == 1'b0 )          next_state = CHECK_COUNT;
      else                                        next_state = AWAIT_REQ;
    end

    CHECK_COUNT :
    begin
           if( force_disable_afu == 1'b1 )            next_state = COMPLETE;
      else if( single_transaction_per_set == 1'b1 )
      begin
           if( pipe_3_response_count == 'd0 )         next_state = CHECK_COUNT;
           else                                       next_state = COMPLETE;
      end
      else if( pipe_3_response_count < (NAI_clkd+1) ) next_state = CHECK_COUNT;
      else                                            next_state = COMPLETE;
    end

    COMPLETE :
    begin
                                             set_to_not_busy = 1'b1;
                                                  next_state = IDLE;
    end

    AWAIT_REQ :
    begin
           if( force_disable_afu == 1'b1 )         next_state = COMPLETE;
      else if( lm_axi2rsp_write_req_sent == 1'b0 ) next_state = AWAIT_REQ;
      else                                         next_state = AWAIT_RSP;
    end

    AWAIT_RSP :
    begin
           if( force_disable_afu == 1'b1 )        next_state = COMPLETE;
      else if( pipe_2_valid == 1'b0 )             next_state = AWAIT_RSP;
      else                                        next_state = CHECK_COUNT_2;
    end

    CHECK_COUNT_2 :
    begin
      if( force_disable_afu == 1'b1 )
      begin
                                                  next_state = COMPLETE;
      end
      else if( pipe_3_response_count < (NAI_clkd+1) )
      begin
                                   lm_rsp2axi_write_rsp_rcvd = 1'b1;
                                                  next_state = AWAIT_REQ;
      end
      else begin
                                   lm_rsp2axi_write_rsp_rcvd = 1'b1;
                                                  next_state = COMPLETE;
      end
    end

    default :                                     next_state = IDLE;
  endcase
end


endmodule
