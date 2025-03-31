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

module alg_1a_execute_write
    import ccv_afu_pkg::*;
    import ccv_afu_alg1a_pkg::*;
    import afu_axi_if_pkg::*;
(
  input clk,
  input reset_n,    // active low reset

  /* signals to/from ccv afu top-level FSM
  */
  input        enable_in,       // active high
  input [31:0] current_P_in,
  input [51:0] current_X_in,

  output logic   execute_busy_out,

  /*  signals to/from the Algorithm 1a response count phase
  */
  output logic start_response_count_phase_out,
  input        response_phase_busy,             // active high, response count < NAI flag

  /* signals for AXI-MM write address channel
  */
  input  t_axi4_wr_addr_ready  awready,
  output t_axi4_wr_addr_ch     write_addr_chan,

  /* signals for AXI-MM write data channel
  */
  input  t_axi4_wr_data_ready  wready,
  output t_axi4_wr_data_ch     write_data_chan,

  /*  signals for latency mode
   */
   input latency_mode_enabled,
   input lm_rsp2axi_write_rsp_rcvd,
  output lm_axi2rsp_write_req_sent,

  /*  signals from configuration and debug registers
  */
  input [31:0] address_increment_reg,
  input [63:0] byte_mask_reg,
  input [2:0]  pattern_size_reg,
  input [8:0]  NAI,
  input [7:0]  number_of_address_increments_reg,
  input [37:0] RAI,
  input        single_transaction_per_set,         // active high
  input [3:0]  write_semantics_cache_reg,
  input        force_disable_afu                   // active high
);

/*
enum type for the FSM of the Algorithm 1a, execute write phase
*/
typedef enum logic [2:0] {
  IDLE               = 3'h0,
  START_N            = 3'h1,
  WAIT_ON_N          = 3'h2,
  WAIT_ON_RESPONSES  = 3'h3,
  COMPLETE           = 3'h4
} alg_1a_wp_fsm_enum;
    
alg_1a_wp_fsm_enum   state;
alg_1a_wp_fsm_enum   next_state;

logic [8:0] pipe_1_N;
logic [8:0] pipe_2_N;
logic [8:0] pipe_3_N;
//logic [8:0] pipe_4_N;

logic [31:0] pipe_1_P;

logic [51:0] pipe_2_YN;
logic [51:0] pipe_3_addr;

logic [31:0]  RP;
logic [511:0] ERP;

logic [31:0]  pipe_2_RP;
logic [31:0]  pipe_3_RP;

logic  pipe_1_valid;
logic  pipe_2_valid;
logic  pipe_3_valid;

logic set_to_busy;
logic set_to_not_busy;


/*   ================================================================================================
*/
// signals added for FIFO
localparam FIFO_WIDTH = 9 + 52 + 32;

logic fifo_pop;
logic fifo_full;
logic fifo_empty;
logic fifo_thresh;
logic clock_addr_chan;

logic [FIFO_WIDTH-1:0] fifo_data_out;

logic [8:0]  fifo_out_N;
logic [51:0] fifo_out_addr;
logic [31:0] fifo_out_RP;
logic [3:0]  fifo_count;

/*   ================================================================================================
     handle the state register
*/
always_ff @( posedge clk )
begin : register_state
       if( reset_n == 1'b0 )            state <= IDLE;
  else if( force_disable_afu == 1'b1 )  state <= COMPLETE;   // so that set_to_not_busy pulses
  else                                  state <= next_state;
end

/*   ================================================================================================
     handle the next state logic
*/
always_comb
begin : comb_next_state
  set_to_busy = 1'b0;
  set_to_not_busy = 1'b0;
  start_response_count_phase_out = 1'b0;


  case( state )
    IDLE :
    begin
        if( enable_in == 1'b1 )  next_state = START_N;
        else                     next_state = IDLE;

        if( enable_in == 1'b1 )  set_to_busy = 1'b1;
    end

    START_N :
    begin
      start_response_count_phase_out  = 1'b1;
                          next_state  = WAIT_ON_N;
    end

    WAIT_ON_N :
    begin
             if( force_disable_afu == 1'b1 )  next_state = COMPLETE;
        else if( pipe_1_N < NAI )             next_state = WAIT_ON_N;
        else                                  next_state = WAIT_ON_RESPONSES;

        if( force_disable_afu == 1'b1 )       set_to_not_busy = 1'b1;
    end

    WAIT_ON_RESPONSES :
    begin
             if( force_disable_afu == 1'b1 )   next_state = COMPLETE;
        else if( response_phase_busy == 1'b1 ) next_state = WAIT_ON_RESPONSES;
        else                                   next_state = COMPLETE;

        if( force_disable_afu == 1'b1 )        set_to_not_busy = 1'b1;
    end

    COMPLETE :
    begin
        set_to_not_busy  = 1'b1;
        next_state       = IDLE;
    end

    default :   next_state = IDLE;
  endcase
end


/*   ================================================================================================
*/
/* indicates that this module (and the write phase module) is busy
*/
always_ff @( posedge clk )
begin 
       if( reset_n == 1'b0 )          execute_busy_out  <= 1'b0;
  else if( set_to_busy == 1'b1 )      execute_busy_out  <= 1'b1;
  else if( set_to_not_busy == 1'b1 )  execute_busy_out  <= 1'b0;
  else                                execute_busy_out  <= execute_busy_out;
end


/*   ================================================================================================  pipe stage 1
*/
/* initiates the "valid packets" that will flow through the pipeline
*/
/*
always_ff @( posedge clk )
begin
       if( reset_n == 1'b0 )                    pipe_1_valid  <= 1'b0;
  else if( set_to_busy == 1'b1 )                pipe_1_valid  <= 1'b1;
  else if( execute_busy_out == 1'b0 )           pipe_1_valid  <= 1'b0;
  else if( single_transaction_per_set == 1'b1 ) pipe_1_valid  <= 1'b0; // only pulse valid once
  else if( pipe_1_N < (NAI) )                   pipe_1_valid  <= 1'b1;
  else if( fifo_full == 1'b1 )
  begin
    if( pipe_2_N < NAI )                        pipe_1_valid <= 1'b1;
    else                                        pipe_1_valid <= 1'b0;
  end
  else                                          pipe_1_valid  <= 1'b0;
end
*/
always_ff @( posedge clk )
begin
       if( reset_n == 1'b0 )                    pipe_1_valid  <= 1'b0;
  else if( set_to_busy == 1'b1 )                pipe_1_valid  <= 1'b1;
  else if( execute_busy_out == 1'b0 )           pipe_1_valid  <= 1'b0;
  else if( single_transaction_per_set == 1'b1 ) pipe_1_valid  <= 1'b0; // only pulse valid once
  else if( fifo_thresh == 1'b1 )                pipe_1_valid  <= 1'b0;
  else if( pipe_1_N < (NAI) )                   pipe_1_valid  <= 1'b1;
  else                                          pipe_1_valid  <= 1'b0;
end

/* N represents the number of address increments, which is the inner loop within a set
*/
/*
always_ff @( posedge clk )
begin
       if( reset_n == 1'b0 )           pipe_1_N  <= 'd0;
  else if( set_to_busy == 1'b1 )       pipe_1_N  <= 'd0;
  else if( execute_busy_out == 1'b0 )  pipe_1_N  <= 'd0;
  else if( fifo_full == 1'b1 )         pipe_1_N  <= pipe_1_N;
  else if( pipe_1_N < (NAI) )          pipe_1_N  <= pipe_1_N + 'd1;
  else                                 pipe_1_N  <= pipe_1_N;
end
*/
always_ff @( posedge clk )
begin
       if( reset_n == 1'b0 )           pipe_1_N  <= 'd0;
  else if( set_to_busy == 1'b1 )       pipe_1_N  <= 'd0;
  else if( execute_busy_out == 1'b0 )  pipe_1_N  <= 'd0;
  else if( fifo_thresh == 1'b1 )       pipe_1_N  <= pipe_1_N;
  else if( pipe_1_N < (NAI) )          pipe_1_N  <= pipe_1_N + 'd1;
  else                                 pipe_1_N  <= pipe_1_N;
end


/* P is the pattern to be written. it increments by one for each address increment
*/
always_ff @( posedge clk )
begin
       if( reset_n == 1'b0 )           pipe_1_P  <= 'd0;
  else if( set_to_busy == 1'b1 )       pipe_1_P  <= current_P_in;
  else if( execute_busy_out == 1'b0 )  pipe_1_P  <= 'd0;
  else if( fifo_thresh == 1'b1 )       pipe_1_P  <= pipe_1_P;
  else if( pipe_1_N < (NAI) )          pipe_1_P  <= pipe_1_P + 'd1;
  else                                 pipe_1_P  <= pipe_1_P;
end


/*   ================================================================================================ pipe stage 2
*/
always_ff @( posedge clk )
begin
       if( reset_n == 1'b0 )           pipe_2_valid  <= 1'b0;
  else if( execute_busy_out == 1'b0 )  pipe_2_valid  <= 1'b0;
//  else if( fifo_full == 1'b1 )         pipe_2_valid  <= pipe_2_valid;
//  else if( fifo_thresh == 1'b1 )       pipe_2_valid  <= pipe_2_valid;
  else                                 pipe_2_valid  <= pipe_1_valid;
end

always_ff @( posedge clk )
begin
       if( reset_n == 1'b0 )           pipe_2_N  <= 'd0;
  else if( execute_busy_out == 1'b0 )  pipe_2_N  <= 'd0;
//  else if( fifo_full == 1'b1 )         pipe_2_N  <= pipe_2_N;
//  else if( fifo_thresh == 1'b1 )       pipe_2_N  <= pipe_2_N;
  else if( pipe_1_valid == 1'b0 )      pipe_2_N  <= pipe_2_N;
  else                                 pipe_2_N  <= pipe_1_N;
end

/* multiple the N value by the real address increment value
*/
always_ff @( posedge clk )
begin
       if( reset_n == 1'b0 )           pipe_2_YN  <= 'd0;
  else if( execute_busy_out == 1'b0 )  pipe_2_YN  <= 'd0;
//  else if( fifo_full == 1'b1 )         pipe_2_YN  <= pipe_2_YN;
//  else if( fifo_thresh == 1'b1 )       pipe_2_YN  <= pipe_2_YN;
  else if( pipe_1_valid == 1'b0 )      pipe_2_YN  <= pipe_2_YN;
  else if( pipe_1_N == 'd0 )           pipe_2_YN  <= 'd0;
  else                                 pipe_2_YN  <= pipe_2_YN + RAI;
//  else                                 pipe_2_YN  <= pipe_1_N * RAI;
end

/* PatternSize: Defines what size (in bytes) of P or Bto use starting from least 
   significant byte. As an example, if this is programmed to 3b011, only the lower 3 
   bytes of P and B registers will be used as the pattern. This will be programmed 
   consistently with the ByteMask field, for example, in the given example, the ByteMask 
   would always be in sets of three consecutive bytes
*/
always_ff @( posedge clk )
begin
       if( reset_n == 1'b0 )           pipe_2_RP  <= 'd0;
  else if( execute_busy_out == 1'b0 )  pipe_2_RP  <= 'd0;
//  else if( fifo_full == 1'b1 )         pipe_2_RP  <= pipe_2_RP;
//  else if( fifo_thresh == 1'b1 )       pipe_2_RP  <= pipe_2_RP;
  else if( pipe_1_valid == 1'b0 )      pipe_2_RP  <= pipe_2_RP;
  else if( pattern_size_reg == 3'd4 )  pipe_2_RP  <= pipe_1_P;
  else if( pattern_size_reg == 3'd2 )  pipe_2_RP  <= pipe_1_P[15:0];
  else if( pattern_size_reg == 3'd1 )  pipe_2_RP  <= pipe_1_P[7:0];
  else if( pattern_size_reg == 3'd0 )  pipe_2_RP  <= 'd0;
  else                                 pipe_2_RP  <= pipe_2_RP;
end

/*   ================================================================================================ pipe stage 3
*/
always_ff @( posedge clk )
begin
       if( reset_n == 1'b0 )           pipe_3_valid  <= 1'b0;
  else if( execute_busy_out == 1'b0 )  pipe_3_valid  <= 1'b0;
//  else if( fifo_full == 1'b1 )         pipe_3_valid  <= pipe_3_valid;
//  else if( fifo_thresh == 1'b1 )       pipe_3_valid  <= pipe_3_valid;
  else                                 pipe_3_valid  <= pipe_2_valid;
end

always_ff @( posedge clk )
begin
       if( reset_n == 1'b0 )           pipe_3_N  <= 'd0;
  else if( execute_busy_out == 1'b0 )  pipe_3_N  <= 'd0;
//  else if( fifo_full == 1'b1 )         pipe_3_N  <= pipe_3_N;
//  else if( fifo_thresh == 1'b1 )       pipe_3_N  <= pipe_3_N;
  else if( pipe_2_valid == 1'b0 )      pipe_3_N  <= pipe_3_N;
  else                                 pipe_3_N  <= pipe_2_N;
end

/* This would be X+Y*N, which is the address to write to
*/
always_ff @( posedge clk )
begin
       if( reset_n == 1'b0 )           pipe_3_addr  <= 'd0;
  else if( execute_busy_out == 1'b0 )  pipe_3_addr  <= 'd0;
//  else if( fifo_full == 1'b1 )         pipe_3_addr  <= pipe_3_addr;
//  else if( fifo_thresh == 1'b1 )       pipe_3_addr  <= pipe_3_addr;
  else if( pipe_2_valid == 1'b0 )      pipe_3_addr  <= pipe_3_addr;
  else                                 pipe_3_addr  <= pipe_2_YN + current_X_in;
end

always_ff @( posedge clk )
begin
       if( reset_n == 1'b0 )           pipe_3_RP  <= 'd0;
  else if( execute_busy_out == 1'b0 )  pipe_3_RP  <= 'd0;
//  else if( fifo_full == 1'b1 )         pipe_3_RP  <= pipe_3_RP;
//  else if( fifo_thresh == 1'b1 )       pipe_3_RP  <= pipe_3_RP;
  else if( pipe_2_valid == 1'b0 )      pipe_3_RP  <= pipe_3_RP;
  else                                 pipe_3_RP  <= pipe_2_RP;
end

/*   ================================================================================================ fifo
*/
fifo_sync_1
#(
   .DATA_WIDTH( FIFO_WIDTH ),
   .FIFO_DEPTH( 16 ),
   .PTR_WIDTH( 4 ),
   .THRESHOLD( 10 )
)
inst_fifo
(
  .clk            ( clk ),
  .reset_n        ( reset_n ),
  .i_data         ( {pipe_3_N, pipe_3_addr, pipe_3_RP} ),
  .i_write_enable ( pipe_3_valid ),
  .i_read_enable  ( fifo_pop     ),
  .i_clear_fifo   ( set_to_busy  ),
  .o_data         ( {fifo_out_N, fifo_out_addr, fifo_out_RP} ),
  .o_empty        ( fifo_empty   ),
  .o_full         ( fifo_full    ),
  .o_count        ( fifo_count   ),
  .o_thresh       ( fifo_thresh  )
);


/*   ================================================================================================  axi fsm
*/
alg_1a_execute_write_axi_fsm    inst_alg1a_exe_wr_axi_fsm
(
  .clk        ( clk        ),
  .reset_n    ( reset_n    ),
  .awready    ( awready    ),
  .wready     ( wready     ),
  .fifo_count ( fifo_count ),
  .fifo_empty ( fifo_empty ),
  .fifo_pop   ( fifo_pop   ),

  .fifo_out_N    ( fifo_out_N    ),
  .fifo_out_addr ( fifo_out_addr ),

  .byte_mask_reg     ( byte_mask_reg     ),
  .clock_addr_chan   ( clock_addr_chan   ),
  .force_disable_afu ( force_disable_afu ),
  .pipe_4_ERP        ( ERP               ),  // pipe_4_ERP        ),
  .pipe_4_N          ( fifo_out_N        ),  // pipe_4_N          ),
  .set_to_not_busy   ( set_to_not_busy   ),
  .set_to_busy       ( set_to_busy       ),

  .write_semantics_cache_reg ( write_semantics_cache_reg ),

  .latency_mode_enabled( latency_mode_enabled ),
  .lm_rsp2axi_write_rsp_rcvd( lm_rsp2axi_write_rsp_rcvd ),
  .lm_axi2rsp_write_req_sent( lm_axi2rsp_write_req_sent ),

  .write_addr_chan ( write_addr_chan ),
  .write_data_chan ( write_data_chan )
);

/*   ================================================================================================ pipe stage 4
*/
/* ByteMask: 1 bit per byte of the cacheline to indicate which bytes of the 
   cacheline are modified by the device in Algorithms 1a, 1b and 2. This 
   will be programmed consistently with the StartAddress1 register
*/
pattern_expand_by_byte_mask_ver2   inst_pebbm
(
   .byte_mask_reg_in    ( byte_mask_reg    ),
   .pattern_size_reg_in ( pattern_size_reg ),
   .pattern32_in        ( fifo_out_RP       ),
   .pattern16_in        ( fifo_out_RP[15:0] ),
   .pattern8_in         ( fifo_out_RP[7:0]  ),
   .pattern_out         ( ERP              )
);


endmodule
