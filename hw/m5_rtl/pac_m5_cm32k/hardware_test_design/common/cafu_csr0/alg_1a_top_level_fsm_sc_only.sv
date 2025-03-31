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

module alg_1a_top_level_fsm_sc_only
    import ccv_afu_pkg::*;
(
  input clk,
  input reset_n,    // active low reset
  input enable_in,

  /*  signals from configuration and debug registersre
  */
  input [31:0] address_set_offset_reg,
  input [2:0]  algorithm_reg,
  input [31:0] base_pattern_reg,
  input [51:0] base_start_address_reg,
  input [51:0] base_write_back_address_reg,
  input        enable_self_checking_reg,              // active high
  input        force_disable_afu,                     // active high
  input        i_mode_single_transaction_multi_loop,  // active high
  input        i_mode_single_transaction_one_loop,    // active high
  input [7:0]  number_of_address_increments_reg,
  input [7:0]  number_of_loops_reg,
  input [7:0]  number_of_sets_reg,
  input        pattern_parameter_reg,

  /*  signals for latency mode
  */
  input writes_only_mode_enable,
  input  reads_only_mode_enable,

  output logic [19:0] extended_loop_count,

  /*  signals to/from the execute stage
  */
   input       execute_busy_flag,
   input       execute_slverr_received,
  output logic enable_execute_flag,

  /*  signals to/from the self checking verify stage
  */
   input       sc_verify_busy_flag,
   input       sc_verify_error_found_flag,
   input       sc_verify_poison_received,
   input       sc_verify_slverr_received,
  output logic enable_sc_verify_flag,

  /*  output signals used across AFU
  */
  output logic [31:0] current_P,
  output logic [51:0] current_X,
  output logic [51:0] current_Z,
  output logic [9:0]  loop_count,
  output logic [4:0]  set_count,
  output logic        set_to_busy,
  output logic        set_to_not_busy,
  output logic        busy_flag
);

// =================================================================================================
typedef enum logic [3:0] {
  IDLE               = 'd0,
  INIT               = 'd1,
  EXECUTE_START      = 'd2,
  EXECUTE_WAIT       = 'd3,
  VERIFY_START       = 'd4,
  VERIFY_WAIT        = 'd5,
  SET_COUNT_CHECK    = 'd6,
  LOOP_COUNT_CHECK   = 'd7,
  DISABLE_STARTED    = 'd8,
  COMPLETE           = 'd9,
  CHECK_IF_ERROR     = 'd10,
  INCR_SET           = 'd11
} fsm_enum;

fsm_enum    state;
fsm_enum    next_state;

// =================================================================================================
logic        increment_loop;
logic        increment_set;
logic        infinite_looping;
logic        init_loop;
logic [31:0] next_P;
logic [51:0] next_X;
logic [51:0] next_Z;
logic [37:0] real_set_offset;
logic        set_next_set;
logic        single_transaction_only;

// =================================================================================================
/* Page 603 "NumberOfLoops: if set to 0, device continues looping across address 
               and set increments indefinitely"
*/
always_comb
begin
      infinite_looping = ( number_of_loops_reg == 8'd0 );
end

// =================================================================================================
/* Page 603 "NumberOfAddrIncrements: Sets the value of "N" for all 3 Algorithms. 
               A vlaue of 0 implies only the first write (base address) is going 
               to be issued by device."
     Page 603 "NumberOfSets: A value of 0 implies that only the first write is 
               going to be issued by the device. If both NumberOfAddressIncrements 
               and NumberOfSets is zero, only a single transaction (to the base address)
               should be issued by the device [NumberOfLoops should be set to 1 for this case]."
*/
always_comb
begin
      single_transaction_only = ( (number_of_address_increments_reg == 8'd0)
				& (number_of_sets_reg == 8'd0) );
end

// =================================================================================================
/* Page 602 "SetOffset: The value in this register should be left shiftd by 
               6 bits before using as address increment"
*/
always_comb
begin
      real_set_offset = address_set_offset_reg << 6;
end

// =================================================================================================
always_ff @( posedge clk )
begin
       if( reset_n == 1'b0 )           state <= IDLE;
  else if( force_disable_afu == 1'b1 ) state <= COMPLETE;  // make sure set_to_not_busy pulses
  else                                 state <= next_state;
end

// =================================================================================================
/* Inidactes that the CCV AFU (and this FSM) have been enabled and is running a test
*/
always_ff @( posedge clk )
begin
       if( reset_n == 1'b0 )           busy_flag  <= 1'b0;
  else if( force_disable_afu == 1'b1 ) busy_flag  <= 1'b0;
  else if( set_to_busy == 1'b1 )       busy_flag  <= 1'b1;
  else if( set_to_not_busy == 1'b1 )   busy_flag  <= 1'b0;
  else                                 busy_flag  <= busy_flag;
end

// =================================================================================================
/* NumberOfLoops: If set to 0, device continues looping across address and set 
   increments indefinitely. Otherwise, it indicates the number of loops to run 
   through for address and set increments.
*/
always_ff @( posedge clk )
begin
       if( reset_n == 1'b0 )        loop_count  <= 'd0;
  else if( set_to_busy == 1'b1 )    loop_count  <= 'd0;
  else if( increment_loop == 1'b1 ) loop_count  <= loop_count + 'd1;
  else                              loop_count  <= loop_count;
end


always_ff @( posedge clk )
begin
       if( reset_n == 1'b0 )        extended_loop_count  <= 'd0;
  else if( set_to_busy == 1'b1 )    extended_loop_count  <= 'd0;
  else if( increment_loop == 1'b1 ) extended_loop_count  <= extended_loop_count + 'd1;
  else                              extended_loop_count  <= extended_loop_count;
end

// =================================================================================================
/* NumberOfSets: A value of 0 implies that only the first write is going to be 
   issued by the device. If both NumberOfAddIncrements and NumberOfSets is zero, 
   only a single transaction (to the base address) should be issued by the device 
   [NumberOfLoops should be set to 1 for this case].
   For Algorithm 1a and 1b:
       Bits 19:16 gives the number of sets.
       Bits 23:20 give the number of bogus writes in Algorithm 1b.
   For Algorithm 2:
       Bits 23:16 gives the number of iterations.
*/
always_ff @( posedge clk )
begin
       if( reset_n == 1'b0 )       set_count  <= 'd0;
  else if( init_loop == 1'b1 )     set_count  <= 'd0;
  else if( increment_set == 1'b1 ) set_count  <= set_count + 5'd1;
  else                             set_count  <= set_count;
end

// =================================================================================================
/* the base address to write to for this set
*/
always_ff @( posedge clk )
begin
       if( reset_n == 1'b0 )      current_X  <= 'd0;
  else if( init_loop == 1'b1 )    current_X  <= base_start_address_reg;
  else if( set_next_set == 1'b1 ) current_X  <= next_X;
  else                            current_X  <= current_X;
end

// =================================================================================================
/* The base address to write results to for non-self-checking verify
*/
always_ff @( posedge clk )
begin
       if( reset_n == 1'b0 )          current_Z  <= 'd0;
  else if( init_loop == 1'b1 )        current_Z  <= base_write_back_address_reg;
  else if( set_next_set == 1'b1 )     current_Z  <= next_Z;
  else                                current_Z  <= current_Z;
end

// =================================================================================================
/* the base pattern to write for this set
*/
always_ff @( posedge clk )
begin : register_current_p
       if( reset_n == 1'b0 )          current_P  <= 'd0;
  else if( init_loop == 1'b1 )        current_P  <= base_pattern_reg;
  else if( set_next_set == 1'b1 )     current_P  <= next_P;
  else                                current_P  <= current_P;
end

// =================================================================================================
always_ff @( posedge clk )
begin : register_next_x
       if( reset_n == 1'b0 )          next_X  <= 'd0;
  else if( init_loop == 1'b1 )        next_X  <= base_start_address_reg;
  else if( increment_set == 1'b1 )    next_X  <= next_X + real_set_offset;
  else                                next_X  <= next_X;
end

// =================================================================================================
always_ff @( posedge clk )
begin : register_next_z
       if( reset_n == 1'b0 )          next_Z  <= 'd0;
  else if( init_loop == 1'b1 )        next_Z  <= base_write_back_address_reg;
  else if( increment_set == 1'b1 )    next_Z  <= next_Z + real_set_offset;
  else                                next_Z  <= next_Z;
end

// =================================================================================================
always_ff @( posedge clk )
begin : register_next_p
       if( reset_n == 1'b0 )                next_P  <= 32'd0;
  else if( init_loop == 1'b1 )              next_P  <= base_pattern_reg;
  else if( increment_set == 1'b1 )
  begin
    if( pattern_parameter_reg == 1'b1 )     next_P  <= next_P + 32'd1 + number_of_address_increments_reg;
    else                                    next_P  <= base_pattern_reg;
  end
  else                                      next_P  <= next_P;
end

// =================================================================================================
always_comb
begin
  init_loop = 1'b0;
  set_to_busy = 1'b0;
  increment_set = 1'b0;
  increment_loop = 1'b0;
  set_next_set = 1'b0;
  set_to_not_busy = 1'b0;
  enable_execute_flag = 1'b0;
  enable_sc_verify_flag = 1'b0;


  case( state )
    IDLE :
    begin
      if( enable_in == 1'b1 )                     next_state = INIT;
      else                                        next_state = IDLE;

      if( enable_in == 1'b1 )                    set_to_busy = 1'b1;
    end

    INIT :
    begin
                                                   init_loop = 1'b1;
      if( reads_only_mode_enable == 1'b0 )        next_state = EXECUTE_START;
      else                                        next_state = VERIFY_START;
    end

    EXECUTE_START :   
    begin
                                         enable_execute_flag = 1'b1;
                                                  next_state = EXECUTE_WAIT;
    end

    EXECUTE_WAIT :   
    begin
           if( execute_busy_flag == 1'b1 )        next_state = EXECUTE_WAIT;
      else if( writes_only_mode_enable == 1'b1 )  next_state = INCR_SET;
      else                                        next_state = VERIFY_START;
    end

    INCR_SET :
    begin
           if( algorithm_reg != 3'b001 )                      next_state = DISABLE_STARTED; // graceful disable
      else if( execute_slverr_received == 1'b1 )              next_state = COMPLETE;
      else if( i_mode_single_transaction_one_loop == 1'b1 )   next_state = COMPLETE;
      else if( i_mode_single_transaction_multi_loop == 1'b1 ) next_state = SET_COUNT_CHECK;
      else begin
                                                              next_state = SET_COUNT_CHECK;
		                                           increment_set = 1'b1;
      end
    end

    VERIFY_START :
    begin
                                      enable_sc_verify_flag  = 1'b1;
                                                  next_state = VERIFY_WAIT;
    end

    VERIFY_WAIT :
    begin
           if( algorithm_reg != 3'b001 )          next_state = DISABLE_STARTED; // graceful disable
      else if( sc_verify_busy_flag == 1'b1 )      next_state = VERIFY_WAIT;
      else                                        next_state = CHECK_IF_ERROR;
    end

    CHECK_IF_ERROR :
    begin
      if( algorithm_reg != 3'b001 ) 
      begin
                                                  next_state = DISABLE_STARTED; // graceful disable
      end
      else if( ( sc_verify_poison_received == 1'b1 )
             | ( sc_verify_slverr_received == 1'b1 ) 
             | ( execute_slverr_received == 1'b1 )
             | ( i_mode_single_transaction_one_loop == 1'b1 )
             )
      begin
                                                  next_state = COMPLETE;
      end
      else if( ( reads_only_mode_enable == 1'b0 )
             & ( sc_verify_error_found_flag == 1'b1 )
             )
      begin
                                                  next_state = COMPLETE;
      end
      else if( i_mode_single_transaction_multi_loop == 1'b1 )
      begin
                                                  next_state = SET_COUNT_CHECK;
      end
      else begin
                                                  next_state = SET_COUNT_CHECK;
		                               increment_set = 1'b1;
      end
    end

    SET_COUNT_CHECK :
    begin
           if( algorithm_reg != 3'b001 )          next_state = DISABLE_STARTED;
      else if( set_count >= number_of_sets_reg[3:0] )
      begin
                                                  next_state = LOOP_COUNT_CHECK;
                                              increment_loop = 1'b1;
      end
      else if( reads_only_mode_enable == 1'b1 )
      begin
                                                  next_state = VERIFY_START;
                                                set_next_set = 1'b1;
      end
      else begin
                                                  next_state = EXECUTE_START;
                                                set_next_set = 1'b1;
      end
    end

    LOOP_COUNT_CHECK :
    begin
           if( algorithm_reg == 3'b000 )           next_state = DISABLE_STARTED;
      else if( infinite_looping == 1'b1 )          next_state = INIT;
      else if( loop_count >= number_of_loops_reg ) next_state = COMPLETE;
      else                                         next_state = INIT;
    end

    DISABLE_STARTED :
    begin
           if( sc_verify_error_found_flag == 1'b1 ) next_state = COMPLETE;
      else if( sc_verify_busy_flag == 1'b1 )        next_state = DISABLE_STARTED;
      else                                          next_state = COMPLETE;
    end

    COMPLETE :
    begin
                                                  next_state = IDLE;
                                             set_to_not_busy = 1'b1;
    end

    default :                                     next_state = IDLE;
  endcase
end


endmodule
