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

module mwae_top_level_fsm
    import ccv_afu_pkg::*;
(
  input clk,
  input reset_n,    // active low reset

  /*  signals to/from the multi write algorithms engine
  */
  `ifdef SUPPORT_ALGORITHM_1A
    output logic enable_alg_1a,
     input       alg_1a_busy_flag,
  `endif
  `ifdef SUPPORT_ALGORITHM_1B
    output logic enable_alg_1b,
     input       alg_1b_busy_flag,
  `endif
  `ifdef SUPPORT_ALGORITHM_2
    output logic enable_alg_2,
     input       alg_2_busy_flag,
  `endif

  /*  signals from configuration and debug registers
  */
  input [2:0]  algorithm_reg,
  input [2:0]  execute_read_semantics_cache_reg,
  input        forceful_disable_reg,
  input [2:0]  interface_protocol_reg,
  input [2:0]  pattern_size_reg,
  input [51:0] start_address_reg,
  input [2:0]  verify_read_semantics_cache_reg,
  input [3:0]  write_semantics_cache_reg,
  input        unsupported_cache_flush_error,

  /*  signals to configuration and debug registers
  */
  output logic busy_flag,
  output logic set_to_busy,
  output logic config_check_fail_out,
  output logic lock_config,

  output config_check_t  illegal_config_out
);

logic set_to_not_busy;
logic gracefully_disable;
logic reset_graceful_disable;

logic [2:0] current_algorithm_value;
logic [2:0] previous_algorithm_value;

logic       config_check_fail;

config_check_t  illegal_config;

/* =================================================================================================
   module for determining illegal configuration settings based
   on CXL 2.0 Spec
*/
mwae_config_check   inst_mwae_config_check
(
  .clk               ( clk               ),
  .reset_n           ( reset_n           ),
  .i_enable          ( set_to_busy       ),
  .o_config_errors   ( illegal_config    ),
  .algorithm_reg     ( algorithm_reg     ),
  .pattern_size_reg  ( pattern_size_reg  ),
  .start_address_reg ( start_address_reg ),

  .execute_read_semantics_cache_reg ( execute_read_semantics_cache_reg ),
  .interface_protocol_reg           ( interface_protocol_reg           ),
  .verify_read_semantics_cache_reg  ( verify_read_semantics_cache_reg  ),
  .write_semantics_cache_reg        ( write_semantics_cache_reg        )
);


always_ff @( posedge clk )
begin
  if( reset_n == 1'b0 ) illegal_config_out <= 'd0;
  else                  illegal_config_out <= illegal_config;
end


always_ff @( posedge clk )
begin
    config_check_fail_out <= config_check_fail;
end

/* =================================================================================================
*/
typedef enum logic [3:0] {
  IDLE               = 4'd0,
  SET_BUSY           = 4'd1,
  LOCK_CONFIG        = 4'd2,
  CHECK_CONFIG       = 4'd3,
  CONFIG_FAIL        = 4'd4,
  ALG_SELECT         = 4'd5,
  AWAIT_ALG_ZERO     = 4'd6,
  ALG_1A_START       = 4'd7,
  ALG_1A_WAIT        = 4'd8,
  ALG_1A_COMPLETE    = 4'd9,
  ALG_1B_START       = 4'd10,
  ALG_1B_WAIT        = 4'd11,
  ALG_1B_COMPLETE    = 4'd12,
  ALG_2_START        = 4'd13,
  ALG_2_WAIT         = 4'd14,
  ALG_2_COMPLETE     = 4'd15

} top_level_fsm_enum;

top_level_fsm_enum    state;
top_level_fsm_enum    next_state;


always_ff @( posedge clk )
begin : register_state
       if( reset_n == 1'b0 )               state <= IDLE;
  else if( forceful_disable_reg == 1'b1 )  state <= IDLE;
  else                                     state <= next_state;
end


always_comb
begin : comb_next_state
  set_to_busy            = 1'b0;
  set_to_not_busy        = 1'b0;
  config_check_fail      = 1'b0;
  reset_graceful_disable = 1'b0;
  lock_config            = 1'b0;

  `ifdef SUPPORT_ALGORITHM_1A
     enable_alg_1a     = 1'b0;
  `endif
  `ifdef SUPPORT_ALGORITHM_1B
     enable_alg_1b     = 1'b0;
  `endif
  `ifdef SUPPORT_ALGORITHM_2
     enable_alg_2      = 1'b0;
  `endif

  case( state )
    IDLE :
    begin
      if( algorithm_reg == 3'b000 )      next_state = IDLE;
      else                               next_state = LOCK_CONFIG;
    end

    LOCK_CONFIG :
    begin
                                        lock_config = 1'b1;
                                         next_state = SET_BUSY;
    end

    SET_BUSY :
    begin
                                        set_to_busy = 1'b1;
                                         next_state = CHECK_CONFIG;
    end

    CHECK_CONFIG :
    begin
      if( illegal_config == 0 )          next_state = ALG_SELECT;
      else begin
                                         next_state = CONFIG_FAIL;
                                  config_check_fail = 1'b1;
      end
    end

    CONFIG_FAIL :
    begin
                                    set_to_not_busy = 1'b1;
                                         next_state = AWAIT_ALG_ZERO;
    end

    ALG_SELECT :
    begin
      case( algorithm_reg )
        `ifdef SUPPORT_ALGORITHM_1A
            3'b001 :
            begin
	                                 next_state = ALG_1A_START;
	                              enable_alg_1a = 1'b1;
            end
        `endif
        `ifdef SUPPORT_ALGORITHM_1B
            3'b010 :
            begin
	                                 next_state = ALG_1B_START;
	                              enable_alg_1b = 1'b1;
            end
        `endif
        `ifdef SUPPORT_ALGORITHM_2
            3'b100 :
            begin
	                                 next_state = ALG_2_START;
	                               enable_alg_2 = 1'b1;
            end
        `endif
	    default :
            begin
                                         next_state = AWAIT_ALG_ZERO;
                                    set_to_not_busy = 1'b1;
            end
      endcase
    end

  `ifdef SUPPORT_ALGORITHM_1A
    ALG_1A_START :
    begin
                                         next_state = ALG_1A_WAIT;
    end

    ALG_1A_WAIT :
    begin
       if( alg_1a_busy_flag == 1'b0 )    next_state = ALG_1A_COMPLETE;
       else                              next_state = ALG_1A_WAIT;
    end

    ALG_1A_COMPLETE :
    begin
                                         next_state = AWAIT_ALG_ZERO;
                                    set_to_not_busy = 1'b1;
    end
  `endif

    AWAIT_ALG_ZERO :
    begin
        if( algorithm_reg == 3'd0 )      next_state = IDLE;
        else                             next_state = AWAIT_ALG_ZERO;
    end

    default :                            next_state = IDLE;
  endcase
end


/* Inidactes that the CCV AFU (and this FSM) have been enabled and is running a test
*/
always_ff @( posedge clk )
begin : reg_busy_flag
       if( reset_n == 1'b0 )                  busy_flag  <= 1'b0;
  else if( forceful_disable_reg == 1'b1 )     busy_flag  <= 1'b0;
  else if( set_to_busy == 1'b1 )              busy_flag  <= 1'b1;
  else if( set_to_not_busy == 1'b1 )          busy_flag  <= 1'b0;
  else                                        busy_flag  <= busy_flag;
end


always_ff @( posedge clk )
begin : reg_current_algorithm_value
       if( reset_n == 1'b0 )                 current_algorithm_value <= 3'd0;
  else if( set_to_busy == 1'b1 )             current_algorithm_value <= algorithm_reg;
  else if( reset_graceful_disable == 1'b1 )  current_algorithm_value <= algorithm_reg;
  else if( busy_flag == 1'b1 )               current_algorithm_value <= algorithm_reg;
  else                                       current_algorithm_value <= current_algorithm_value;
end


always_ff @( posedge clk )
begin : reg_previous_algorithm_value
       if( reset_n == 1'b0 )                 previous_algorithm_value <= 3'd0;
  else if( set_to_busy == 1'b1 )             previous_algorithm_value <= algorithm_reg;
  else if( reset_graceful_disable == 1'b1 )  previous_algorithm_value <= algorithm_reg;
  else if( busy_flag == 1'b1 )               previous_algorithm_value <= current_algorithm_value;
  else                                       previous_algorithm_value <= previous_algorithm_value;
end


always_ff @( posedge clk )
begin : reg_gracefully_disable
       if( reset_n == 1'b0 )                 gracefully_disable <= 1'b0;
  else if( set_to_busy == 1'b1 )             gracefully_disable <= 1'b0;
  else if( reset_graceful_disable == 1'b1 )  gracefully_disable <= 1'b0;
  else if( busy_flag == 1'b0 )               gracefully_disable <= 1'b0;
  else begin
       `ifdef FLUSHCACHE_NOT_SUPPORTED
                                             gracefully_disable <= gracefully_disable
                                                                 | (current_algorithm_value != previous_algorithm_value)
                                                                 | unsupported_cache_flush_error;
       `else
                                             gracefully_disable <= gracefully_disable
                                                                 | (current_algorithm_value != previous_algorithm_value);
       `endif
  end
end



endmodule
