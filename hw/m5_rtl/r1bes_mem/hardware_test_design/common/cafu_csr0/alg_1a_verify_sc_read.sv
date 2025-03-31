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

module alg_1a_verify_sc_read
    import ccv_afu_pkg::*;
    import afu_axi_if_pkg::*;
(
  input clk,
  input reset_n,    // active low reset

  /* signals to/from ccv afu top-level FSM
  */
  input enable_in,       // active high

  /*  signals for latency mode
   */
   input latency_mode_enabled,
   input lm_rsp2axi_read_rsp_rcvd,
  output lm_axi2rsp_read_req_sent,

  /*  signals from configuration and debug registers  
  */
  input [31:0] address_increment_reg,
  input        force_disable_afu,                 // active high
  input [8:0]  NAI,
  input [7:0]  number_of_address_increments_reg,
  input        single_transaction_per_set,         // active high
  input [37:0] RAI,
  input [2:0]  verify_semantics_cache_reg,
  
  /*   signals from the top level FSM
   */
  input [51:0] current_X_in,

  /*  signals to/from the Algorithm 1a self checking verify
      reponse phase
  */
  output logic busy_flag_out,             // active high
  output logic start_response_phase_out,  // active high
  input        response_phase_busy_flag,  // active high, flag that response count < NAI

  /* signals for AXI-MM read address channel
  */
  output t_axi4_rd_addr_ch          read_addr_chan,
  input  t_axi4_rd_addr_ready       arready
);
    
/*
        enum type for the FSM of the Algorithm 1a, verify self-checking read phase
*/
typedef enum logic [2:0] {
  IDLE               = 3'h0,
  START              = 3'h1,
  WAIT_ON_N          = 3'h2,
  WAIT_ON_RESPONSES  = 3'h3,
  COMPLETE           = 3'h4
} alg_1a_scv_rp_fsm_enum;

alg_1a_scv_rp_fsm_enum   state;
alg_1a_scv_rp_fsm_enum   next_state;

logic set_to_busy;
logic set_to_not_busy;
    
logic pipe_1_valid;
logic pipe_2_valid;
logic pipe_3_valid;
    
logic [8:0]     pipe_1_N;
logic [8:0]     pipe_2_N;
logic [8:0]     pipe_3_N;

logic [51:0]    pipe_2_YN;
logic [51:0]    pipe_3_addr;

logic [3:0]  fifo_count;
logic        fifo_empty;
logic        fifo_full;
logic [51:0] fifo_out_addr;
logic [8:0]  fifo_out_N;
logic        fifo_pop;
logic        fifo_thresh;

/*   ================================================================================================
*/
always_ff @( posedge clk )
begin : register_state
       if( reset_n == 1'b0 )            state <= IDLE;
  else if( force_disable_afu == 1'b1 )  state <= COMPLETE;   // so that set_to_not_busy pulses
  else                                  state <= next_state;
end

/*   ================================================================================================
*/    
always_comb
begin : comb_next_state
  set_to_busy = 1'b0;
  set_to_not_busy = 1'b0;
  start_response_phase_out = 1'b0;

  case( state )
    IDLE :
    begin
      if( enable_in == 1'b1 )  next_state = START;
      else                     next_state = IDLE;

      if( enable_in == 1'b1 )  set_to_busy = 1'b1;
    end

    START :
    begin
          start_response_phase_out = 1'b1;
                        next_state = WAIT_ON_N;
    end

    WAIT_ON_N :
    begin
           if( force_disable_afu == 1'b1 )  next_state = COMPLETE;
      else if( pipe_1_N < NAI )             next_state = WAIT_ON_N;
      else                                  next_state = WAIT_ON_RESPONSES;
    end

    WAIT_ON_RESPONSES :
    begin
           if( force_disable_afu == 1'b1 )         next_state = COMPLETE;
      else if( response_phase_busy_flag == 1'b1 )  next_state = WAIT_ON_RESPONSES;
      else                                         next_state = COMPLETE;
    end

    COMPLETE :
    begin
             set_to_not_busy = 1'b1;
             next_state      = IDLE;
    end

    default :  next_state = IDLE;
  endcase
end

/*   ================================================================================================
*/
always_ff @( posedge clk )
begin
       if( reset_n == 1'b0 )          busy_flag_out <= 1'b0;
  else if( set_to_busy == 1'b1 )      busy_flag_out <= 1'b1;
  else if( set_to_not_busy == 1'b1 )  busy_flag_out <= 1'b0;
  else                                busy_flag_out <= busy_flag_out;
end

/*   ================================================================================================  pipe stage 1
*/
/*
 *  valid that starts the "packet is valid" through the pipeline
 */
/*
always_ff @( posedge clk )
begin
       if( reset_n == 1'b0 )                    pipe_1_valid <= 1'b0;
  else if( set_to_busy == 1'b1 )                pipe_1_valid <= 1'b1;
  else if( busy_flag_out == 1'b0 )              pipe_1_valid <= 1'b0;
  else if( single_transaction_per_set == 1'b1 ) pipe_1_valid <= 1'b0; // only pulse valid once
  else if( pipe_1_N < NAI )                     pipe_1_valid <= 1'b1; // count less than NAI
  else if( fifo_full == 1'b1 )
  begin
    if( pipe_2_N < NAI )                        pipe_1_valid <= 1'b1;
    else                                        pipe_1_valid <= 1'b0;
  end
  else                                          pipe_1_valid <= 1'b0;
end
*/
always_ff @( posedge clk )
begin
       if( reset_n == 1'b0 )                    pipe_1_valid <= 1'b0;
  else if( set_to_busy == 1'b1 )                pipe_1_valid <= 1'b1;
  else if( busy_flag_out == 1'b0 )              pipe_1_valid <= 1'b0;
  else if( single_transaction_per_set == 1'b1 ) pipe_1_valid <= 1'b0; // only pulse valid once
  else if( fifo_thresh == 1'b1 )                pipe_1_valid <= 1'b0;
  else if( pipe_1_N < NAI )                     pipe_1_valid <= 1'b1; // count less than NAI
  else                                          pipe_1_valid <= 1'b0;
end


/*
 *   N is used for address calculation, the looping variable that is multiplied
 *      by the address increment value
 */
always_ff @( posedge clk )
begin
       if( reset_n == 1'b0 )          pipe_1_N <= 'd0;
  else if( set_to_busy == 1'b1 )      pipe_1_N <= 'd0;
  else if( busy_flag_out == 1'b0 )    pipe_1_N <= 'd0;
  else if( fifo_thresh == 1 )         pipe_1_N <= pipe_1_N;
  else if( pipe_1_N < NAI )           pipe_1_N <= pipe_1_N + 'd1;
  else                                pipe_1_N <= pipe_1_N;
end

/*   ================================================================================================  pipe stage 2
*/
always_ff @( posedge clk )
begin
       if( reset_n == 1'b0 )          pipe_2_valid <= 1'b0;
  else if( busy_flag_out == 1'b0 )    pipe_2_valid <= 1'b0;
//  else if( fifo_full == 1'b1 )        pipe_2_valid <= pipe_2_valid;
//  else if( fifo_thresh == 1'b1 )      pipe_2_valid <= pipe_2_valid;  
  else                                pipe_2_valid <= pipe_1_valid;
end

always_ff @( posedge clk )
begin
       if( reset_n == 1'b0 )          pipe_2_N <= 'd0;
  else if( busy_flag_out == 1'b0 )    pipe_2_N <= 'd0;
//  else if( fifo_full == 1'b1 )        pipe_2_N <= pipe_2_N;
//  else if( fifo_thresh == 1'b1 )      pipe_2_N <= pipe_2_N;
  else if( pipe_1_valid == 1'b0 )     pipe_2_N <= pipe_2_N;
  else                                pipe_2_N <= pipe_1_N;
end

/*
 *   N is used for address calculation, the looping variable that is multiplied
 *      by the address increment value
 */
always_ff @( posedge clk )
begin
       if( reset_n == 1'b0 )          pipe_2_YN <= 'd0;
  else if( busy_flag_out == 1'b0 )    pipe_2_YN <= 'd0;
//  else if( fifo_full == 1'b1 )        pipe_2_YN <= pipe_2_YN;
//  else if( fifo_thresh == 1'b1 )      pipe_2_YN <= pipe_2_YN;
  else if( pipe_1_valid == 1'b0 )     pipe_2_YN <= pipe_2_YN;
  else if( pipe_1_N == 'd0 )          pipe_2_YN <= 'd0;
  else                                pipe_2_YN <= pipe_2_YN + RAI;
end

/*   ================================================================================================  pipe stage 3
*/
always_ff @( posedge clk )
begin
       if( reset_n == 1'b0 )          pipe_3_valid <= 1'b0;
  else if( busy_flag_out == 1'b0 )    pipe_3_valid <= 1'b0;
//  else if( fifo_full == 1'b1 )        pipe_3_valid <= pipe_3_valid;
//  else if( fifo_thresh == 1'b1 )      pipe_3_valid <= pipe_3_valid;
  else                                pipe_3_valid <= pipe_2_valid;
end

always_ff @( posedge clk )
begin
       if( reset_n == 1'b0 )          pipe_3_N <= 'd0;
  else if( busy_flag_out == 1'b0 )    pipe_3_N <= 'd0;
//  else if( fifo_full == 1'b1 )        pipe_3_N <= pipe_3_N;
//  else if( fifo_thresh == 1'b1 )      pipe_3_N <= pipe_3_N;
  else if( pipe_2_valid == 1'b0 )     pipe_3_N <= pipe_3_N;
  else                                pipe_3_N <= pipe_2_N;
end

/*
 *   add the ongoing address increment to the base address for the set
 */
always_ff @( posedge clk )
begin
       if( reset_n == 1'b0 )          pipe_3_addr <= 'd0;
  else if( busy_flag_out == 1'b0 )    pipe_3_addr <= 'd0;
//  else if( fifo_full == 1'b1 )        pipe_3_addr <= pipe_3_addr;
//  else if( fifo_thresh == 1'b1 )      pipe_3_addr <= pipe_3_addr;
  else if( pipe_2_valid == 1'b0 )     pipe_3_addr <= pipe_3_addr;
  else                                pipe_3_addr <= pipe_2_YN + current_X_in;
end

/*   ================================================================================================  fifo
*/
fifo_sync_1
#(
   .DATA_WIDTH( (9+52) ),
   .FIFO_DEPTH( 16 ),
   .PTR_WIDTH( 4 ),
   .THRESHOLD( 10 )
)
inst_fifo
(
  .clk            ( clk ),
  .reset_n        ( reset_n ),
  .i_data         ( {pipe_3_N, pipe_3_addr} ),
  .i_write_enable ( pipe_3_valid ),
  .i_read_enable  ( fifo_pop     ),
  .i_clear_fifo   ( set_to_busy  ),
  .o_data         ( {fifo_out_N, fifo_out_addr} ),
  .o_empty        ( fifo_empty   ),
  .o_full         ( fifo_full    ),
  .o_count        ( fifo_count   ),
  .o_thresh       ( fifo_thresh  )
);


/*   ================================================================================================  axi fsm
*/
alg_1a_verify_sc_read_axi_fsm
#(
   .FIFO_PTR_WIDTH ( 4 )
)
inst_verify_sc_axi_fsm
(
  .clk            ( clk ),
  .reset_n        ( reset_n ),

  .force_disable_afu ( force_disable_afu ),
  .set_to_busy       ( set_to_busy       ),
  .set_to_not_busy   ( set_to_not_busy   ),

  .latency_mode_enabled( latency_mode_enabled ),
  .lm_rsp2axi_read_rsp_rcvd( lm_rsp2axi_read_rsp_rcvd ),
  .lm_axi2rsp_read_req_sent( lm_axi2rsp_read_req_sent ),

  .verify_semantics_cache_reg ( verify_semantics_cache_reg ),

  .fifo_count    ( fifo_count    ),
  .fifo_empty    ( fifo_empty    ),
  .fifo_out_N    ( fifo_out_N    ),
  .fifo_out_addr ( fifo_out_addr ),
  .fifo_pop      ( fifo_pop      ),

  .read_addr_chan ( read_addr_chan ),
  .arready        ( arready        )
);


endmodule
