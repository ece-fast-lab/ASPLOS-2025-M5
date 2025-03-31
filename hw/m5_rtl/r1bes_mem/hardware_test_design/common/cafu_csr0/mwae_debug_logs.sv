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

module mwae_debug_logs
   import ccv_afu_pkg::*;
//   import ccv_afu_cfg_pkg::*;
   import tmp_cafu_csr0_cfg_pkg::*;
(
  input clk,
  input reset_n,                //  active low

  /*  signals for reads-only and writes-only mode
      DO NOT LOG CXL CACHE ERRORS
   */
  input writes_only_mode_enable,
  input  reads_only_mode_enable,

  /* signal from top-level FSM's set_to_busy flag
  */
  input i_mwae_top_fsm_set_to_busy,       //  active high
  input i_mwae_top_fsm_busy,              //  active high

  `ifdef SUPPORT_ALGORITHM_1A
    `ifdef ALG_1A_SUPPORT_SELF_CHECK
           input         i_alg_1a_error_found_flag,
           input [31:0]  i_alg_1a_error_observed_pattern,
           input [31:0]  i_alg_1a_error_expected_pattern,
           input [7:0]   i_alg_1a_error_loop_number,
           input [5:0]   i_alg_1a_error_byte_offset,
           input [3:0]   i_alg_1a_error_set_number,
           input [7:0]   i_alg_1a_error_address_increment,

           input [CCV_AFU_ADDR_WIDTH-1:0]  i_alg_1a_error_address,
    `endif
  `endif

  `ifdef SUPPORT_ALGORITHM_1B
    `ifdef ALG_1B_SUPPORT_SELF_CHECK
           input         i_alg_1b_error_found_flag,
           input [31:0]  i_alg_1b_error_observed_pattern,
           input [31:0]  i_alg_1b_error_expected_pattern,
           input [7:0]   i_alg_1b_error_loop_number,
           input [7:0]   i_alg_1b_error_byte_offset,
           input [3:0]   i_alg_1b_error_set_number,
           input [7:0]   i_alg_1b_error_address_increment,

           input [CCV_AFU_ADDR_WIDTH-1:0]  i_alg_1b_error_address,
    `endif
  `endif

  /* signals from CFG regs
  */
  input  i_debug_log3_error_status_reg,
  input  i_enable_self_checking_reg,
  input  i_forceful_disable_reg,

  /* signals from response phases
  */
  input i_slverr_on_write_response,   // active high
  input i_slverr_on_read_response,    // active high
  input i_poison_on_read_response,    // active high

  /* registers that are RW to hardware
  */
   output tmp_cafu_csr0_cfg_pkg::tmp_new_DEVICE_ERROR_LOG1_t   error_log_1_reg,
   output tmp_cafu_csr0_cfg_pkg::tmp_new_DEVICE_ERROR_LOG2_t   error_log_2_reg,
   output tmp_cafu_csr0_cfg_pkg::tmp_new_DEVICE_ERROR_LOG3_t   error_log_3_reg,
   output tmp_cafu_csr0_cfg_pkg::tmp_new_DEVICE_ERROR_LOG4_t   error_log_4_reg,
   output tmp_cafu_csr0_cfg_pkg::tmp_new_DEVICE_ERROR_LOG5_t   error_log_5_reg,

   output logic record_error_out   // active high
);

logic record_error;
logic error_found_flag;
logic clear_error;
logic record_error_other;

logic [7:0]  error_byte_offset;
logic [7:0]  error_loop_number;
logic [3:0]  error_set_number;
logic [7:0]  error_address_increment;
logic [31:0] error_observed_pattern;
logic [31:0] error_expected_pattern;
logic [63:0] error_address;

/*
 *   need error_found_flag from either algorithm 1a or 1b in self-checking mode
 */
`ifdef SUPPORT_ALGORITHM_1A
  `ifdef SUPPORT_ALGORITHM_1B
    `ifdef ALG_1A_SUPPORT_SELF_CHECK
      `ifdef ALG_1B_SUPPORT_SELF_CHECK
             assign error_found_flag        = i_alg_1a_error_found_flag | i_alg_1b_error_found_flag;
             assign error_observed_pattern  = ( i_alg_1a_error_found_flag == 1'b1 ) ? i_alg_1a_error_observed_pattern  : i_alg_1b_error_observed_pattern;
             assign error_expected_pattern  = ( i_alg_1a_error_found_flag == 1'b1 ) ? i_alg_1a_error_expected_pattern  : i_alg_1b_error_expected_pattern;
             assign error_byte_offset       = ( i_alg_1a_error_found_flag == 1'b1 ) ? i_alg_1a_error_byte_offset       : i_alg_1b_error_byte_offset;
             assign error_loop_number       = ( i_alg_1a_error_found_flag == 1'b1 ) ? i_alg_1a_error_loop_number       : i_alg_1b_error_loop_number;
             assign error_set_number        = ( i_alg_1a_error_found_flag == 1'b1 ) ? i_alg_1a_error_set_number        : i_alg_1b_error_set_number;
             assign error_address_increment = ( i_alg_1a_error_found_flag == 1'b1 ) ? i_alg_1a_error_address_increment : i_alg_1b_error_address_increment;
             assign error_address           = ( i_alg_1a_error_found_flag == 1'b1 ) ? i_alg_1a_error_address           : i_alg_1b_error_address;
      `else
             assign error_found_flag        = i_alg_1a_error_found_flag;
             assign error_observed_pattern  = i_alg_1a_error_observed_pattern;
             assign error_expected_pattern  = i_alg_1a_error_expected_pattern;
             assign error_byte_offset       = i_alg_1a_error_byte_offset;
             assign error_loop_number       = i_alg_1a_error_loop_number;
             assign error_set_number        = i_alg_1a_error_set_number;
             assign error_address_increment = i_alg_1a_error_address_increment;
             assign error_address           = i_alg_1a_error_address;
      `endif
    `else
      `ifdef ALG_1B_SUPPORT_SELF_CHECK
             assign error_found_flag        = i_alg_1b_error_found_flag;
             assign error_observed_pattern  = i_alg_1b_error_observed_pattern;
             assign error_expected_pattern  = i_alg_1b_error_expected_pattern;
             assign error_byte_offset       = i_alg_1b_error_byte_offset;
             assign error_loop_number       = i_alg_1b_error_loop_number;
             assign error_set_number        = i_alg_1b_error_set_number;
             assign error_address_increment = i_alg_1b_error_address_increment;
             assign error_address           = i_alg_1b_error_address;
      `else
             assign error_found_flag        = 1'b0;
             assign error_observed_pattern  = 'd0;
             assign error_expected_pattern  = 'd0;
             assign error_byte_offset       = 'd0;
             assign error_loop_number       = 'd0;
             assign error_set_number        = 'd0;
             assign error_address_increment = 'd0;
             assign error_address           = 'd0;
      `endif
    `endif
  `else
    `ifdef ALG_1A_SUPPORT_SELF_CHECK
             assign error_found_flag        = i_alg_1a_error_found_flag;
             assign error_observed_pattern  = i_alg_1a_error_observed_pattern;
             assign error_expected_pattern  = i_alg_1a_error_expected_pattern;
             assign error_byte_offset       = i_alg_1a_error_byte_offset;
             assign error_loop_number       = i_alg_1a_error_loop_number;
             assign error_set_number        = i_alg_1a_error_set_number;
             assign error_address_increment = i_alg_1a_error_address_increment;
             assign error_address           = i_alg_1a_error_address;
    `else
             assign error_found_flag        = 1'b0;
             assign error_observed_pattern  = 'd0;
             assign error_expected_pattern  = 'd0;
             assign error_byte_offset       = 'd0;
             assign error_loop_number       = 'd0;
             assign error_set_number        = 'd0;
             assign error_address_increment = 'd0;
             assign error_address           = 'd0;
    `endif
  `endif
`else
  `ifdef SUPPORT_ALGORITHM_1B
    `ifdef ALG_1B_SUPPORT_SELF_CHECK
             assign error_found_flag        = i_alg_1b_error_found_flag;
             assign error_observed_pattern  = i_alg_1b_error_observed_pattern;
             assign error_expected_pattern  = i_alg_1b_error_expected_pattern;
             assign error_byte_offset       = i_alg_1b_error_byte_offset;
             assign error_loop_number       = i_alg_1b_error_loop_number;
             assign error_set_number        = i_alg_1b_error_set_number;
             assign error_address_increment = i_alg_1b_error_address_increment;
             assign error_address           = i_alg_1b_error_address;
    `else
             assign error_found_flag        = 1'b0;
             assign error_observed_pattern  = 'd0;
             assign error_expected_pattern  = 'd0;
             assign error_byte_offset       = 'd0;
             assign error_loop_number       = 'd0;
             assign error_set_number        = 'd0;
             assign error_address_increment = 'd0;
             assign error_address           = 'd0;
    `endif
  `else
             assign error_found_flag        = 1'b0;
             assign error_observed_pattern  = 'd0;
             assign error_expected_pattern  = 'd0;
             assign error_byte_offset       = 'd0;
             assign error_loop_number       = 'd0;
             assign error_set_number        = 'd0;
             assign error_address_increment = 'd0;
             assign error_address           = 'd0;
  `endif
`endif

/* =======================================================================================   FSM
*/
typedef enum logic [2:0] {
  IDLE     = 3'h0,
  RECORD   = 3'd1,
  SEND     = 3'd2,
  WAIT     = 3'd3,
  COMPLETE = 3'd4, 
  OTHER1   = 3'd5,
  OTHER2   = 3'd6
} error_log_fsm_enum;

error_log_fsm_enum    state;
error_log_fsm_enum    next_state;


always_ff @( posedge clk )
begin : register_state
       if( reset_n == 1'b0 )                 state <= IDLE;
  else if( i_forceful_disable_reg == 1'b1 )  state <= IDLE;
  else if( writes_only_mode_enable == 1'b1 ) state <= IDLE; // do not log errors in writes only mode
  else if(  reads_only_mode_enable == 1'b1 ) state <= IDLE; // do not log errors in reads only mode
  else                                       state <= next_state;
end


always_comb
begin : comb_next_state
  record_error_other = 1'b0;
  record_error_out   = 1'b0;
  record_error       = 1'b0;
  clear_error        = 1'b0;

  case( state )
    IDLE :
    begin
      if( i_mwae_top_fsm_busy == 1'b0 )
      begin
           next_state = IDLE;
      end
      else if( ( i_enable_self_checking_reg == 1'b1 )
             & ( error_found_flag == 1'b1 )
             )
      begin
           next_state = RECORD;
      end
      else if( ( i_slverr_on_write_response == 1'b1 )
             | ( i_slverr_on_read_response  == 1'b1 )
             | ( i_poison_on_read_response  == 1'b1 )
             )
      begin
           next_state = OTHER1;
      end
      else begin
           next_state = IDLE;
      end
    end

    RECORD :
    begin
           record_error = 1'b1;
           next_state   = SEND;
    end

    OTHER1 :
    begin
           record_error_other = 1'b1;
           next_state         = SEND;
    end

    SEND : 
    begin
          record_error_out = 1'b1;
          next_state       = WAIT;
    end

    WAIT :
    begin
      if( i_debug_log3_error_status_reg == 1'b1 )  next_state = WAIT;
      else                                         next_state = COMPLETE;

      if( i_debug_log3_error_status_reg == 1'b0 )  clear_error = 1'b1;
    end

    COMPLETE : 
    begin
         next_state = IDLE;
    end
  endcase
end

/* =======================================================================================   error log 1
*/
always_ff @( posedge clk )
begin
    if( reset_n == 1'b0 )
    begin
        error_log_1_reg.observed_pattern1  <= 32'd0;
        error_log_1_reg.expected_pattern1  <= 32'd0;
    end
    else if( ( i_mwae_top_fsm_set_to_busy == 1'b1 )
           | ( clear_error == 1'b1 )
           )
    begin
        error_log_1_reg.observed_pattern1  <= 32'd0;
        error_log_1_reg.expected_pattern1  <= 32'd0;
    end
    else if( record_error == 1'b1 )
    begin
        error_log_1_reg.observed_pattern1  <= error_observed_pattern;
        error_log_1_reg.expected_pattern1  <= error_expected_pattern;
    end
    else begin
        error_log_1_reg.observed_pattern1  <= error_log_1_reg.observed_pattern1;
        error_log_1_reg.expected_pattern1  <= error_log_1_reg.expected_pattern1;
    end
end

/* =======================================================================================   error log 2
*/
always_ff @( posedge clk )
begin
    if( reset_n == 1'b0 )
    begin
        error_log_2_reg.observed_pattern2  <= 32'd0;
        error_log_2_reg.expected_pattern2  <= 32'd0;
    end
    else if( ( i_mwae_top_fsm_set_to_busy == 1'b1 )
           | ( clear_error == 1'b1 )
           )
    begin
        error_log_2_reg.observed_pattern2  <= 32'd0;
        error_log_2_reg.expected_pattern2  <= 32'd0;
    end
    else if( record_error == 1'b1 )
    begin
        error_log_2_reg.observed_pattern2  <= error_observed_pattern;
        error_log_2_reg.expected_pattern2  <= error_expected_pattern;
    end
    else begin
        error_log_2_reg.observed_pattern2  <= error_log_2_reg.observed_pattern2;
        error_log_2_reg.expected_pattern2  <= error_log_2_reg.expected_pattern2;
    end
end

/* =======================================================================================   error log 3
*/
always_ff @( posedge clk )
begin
    if( reset_n == 1'b0 )
    begin
        error_log_3_reg.error_status    <= 1'b0;
        error_log_3_reg.loop_numb       <= 8'd0;
        error_log_3_reg.byte_offset     <= 8'd0;
    end
    else if( ( i_mwae_top_fsm_set_to_busy == 1'b1 )
           | ( clear_error == 1'b1 )
           )
    begin
        error_log_3_reg.error_status    <= 1'b0;
        error_log_3_reg.loop_numb       <= 8'd0;
        error_log_3_reg.byte_offset     <= 8'd0;
    end
    else if( record_error == 1'b1 )
    begin
        error_log_3_reg.error_status    <= 1'b1;
        error_log_3_reg.loop_numb       <= error_loop_number;
        error_log_3_reg.byte_offset     <= error_byte_offset;
    end
    else if( record_error_other == 1'b1 )
    begin
        error_log_3_reg.error_status    <= 1'b1;
        error_log_3_reg.loop_numb       <= error_loop_number;
        error_log_3_reg.byte_offset     <= 8'd0;
    end
    else begin
        error_log_3_reg.error_status    <= error_log_3_reg.error_status;
        error_log_3_reg.loop_numb       <= error_log_3_reg.loop_numb;
        error_log_3_reg.byte_offset     <= error_log_3_reg.byte_offset;
    end
end

/* =======================================================================================   error log 4
*/
always_ff @( posedge clk )
begin
    if( reset_n == 1'b0 )
    begin
        error_log_4_reg.set_number          <= 'd0;
        error_log_4_reg.address_increment   <= 'd0;
    end
    else if( ( i_mwae_top_fsm_set_to_busy == 1'b1 )
           | ( clear_error == 1'b1 )
           )
    begin
        error_log_4_reg.set_number          <= 'd0;
        error_log_4_reg.address_increment   <= 'd0;
    end
    else if( record_error == 1'b1 )
    begin
        error_log_4_reg.set_number          <= error_set_number;
        error_log_4_reg.address_increment   <= error_address_increment;
    end
    else begin
        error_log_4_reg.set_number          <= error_log_4_reg.set_number;
        error_log_4_reg.address_increment   <= error_log_4_reg.address_increment;
    end
end

/* =======================================================================================   error log 5
*/
always_ff @( posedge clk )
begin
    if( reset_n == 1'b0 )
    begin
        error_log_5_reg.address_of_first_error  <= 64'd0;
    end
    else if( ( i_mwae_top_fsm_set_to_busy == 1'b1 )
           | ( clear_error == 1'b1 )
           )
    begin
        error_log_5_reg.address_of_first_error  <= 64'd0;
    end
    else if( record_error == 1'b1 )
    begin
        error_log_5_reg.address_of_first_error  <= error_address;
    end
    else begin
        error_log_5_reg.address_of_first_error  <= error_log_5_reg.address_of_first_error;
    end
end




endmodule


