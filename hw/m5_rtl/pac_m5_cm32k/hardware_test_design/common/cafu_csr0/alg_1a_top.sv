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

module alg_1a_top
    import ccv_afu_pkg::*;
    import ccv_afu_alg1a_pkg::*;
    import afu_axi_if_pkg::*;
(
  input clk,
  input reset_n,    // active low reset

  /*  signals for latency mode
  */
  input latency_mode_enable,
  input writes_only_mode_enable,
  input  reads_only_mode_enable,

  output logic [19:0] extended_loop_count,

  /* signals to/from ccv afu top-level FSM
  */
   input       i_enable,                                  // active high
   input       i_mwae_busy,                               // active high
   input       i_mwae_set_to_busy,                        // active high
  output logic o_alg1a_busy,                              // active high
  output logic o_execute_phase_busy,                      // active high
  output logic o_execute_response_slverr_received,        // active high
  output logic o_verify_sc_phase_busy,                    // active high
  output logic o_verify_sc_record_error,                  // active high
  output logic o_verify_sc_response_poison_received,      // active high
  output logic o_verify_sc_response_slverr_received,      // active high

  /*  AXI-MM interface channels
  */  
  output t_axi4_wr_addr_ch      o_from_execute_axi_wr_addr,
  output t_axi4_wr_data_ch      o_from_execute_axi_wr_data,
  output t_axi4_wr_resp_ready   o_from_execute_axi_bready,
   input t_axi4_wr_addr_ready   i_to_execute_axi_awready,
   input t_axi4_wr_data_ready   i_to_execute_axi_wready,
   input t_axi4_wr_resp_ch      i_to_execute_axi_wr_resp,

  output t_axi4_rd_addr_ch     o_from_verify_sc_axi_rd_addr,
  output t_axi4_rd_resp_ready  o_from_verify_sc_axi_rready,
   input t_axi4_rd_addr_ready  i_to_verify_sc_axi_arready,
   input t_axi4_rd_resp_ch     i_to_verify_sc_axi_rd_resp,

  /* signals to ccv afu top-level FSM and debug registers
   */
  output logic [7:0]  o_error_addr_increment,
  output logic [31:0] o_error_expected_pattern,
  output logic [31:0] o_error_received_pattern,
  output logic [51:0] o_error_address,
  output logic [5:0]  o_error_byte_offset,

  /*  signals from configuration and debug registers
  */
  input [31:0] i_addr_increment_value_reg,
  input [2:0]  i_algorithm_reg,
  input [31:0] i_base_pattern_reg,
  input [51:0] i_base_start_address_reg,
  input [51:0] i_base_write_back_address_reg,
  input [63:0] i_byte_mask_reg,
  input        i_force_disable_reg,                   // active high
  input        i_mode_single_transaction_multi_loop,  // active high
  input        i_mode_single_transaction_one_loop,    // active high
  input        i_mode_single_transaction_per_set,     // active high
  input [7:0]  i_number_address_increments_reg,
  input [7:0]  i_number_loops_reg,
  input [7:0]  i_number_sets_reg,
  input        i_pattern_parameter_reg,
  input [2:0]  i_pattern_size_reg,
  input [37:0] i_real_address_increment,
  input [37:0] i_real_set_offset,
  input [8:0]  i_real_total_transactions_per_set,
  input        i_self_checking_enabled_reg,
  input [31:0] i_set_offset_reg,
  input [2:0]  i_verify_read_semantics_cache_reg,
  input [3:0]  i_write_semantics_cache_reg,

  output logic [31:0] o_current_P,
  output logic [51:0] o_current_X,
  output logic [9:0]  o_loop_count,
  output logic [4:0]  o_set_count
);

/* =======================================================================================
*/
logic enable_execute_stage;
logic enable_verify_sc_stage;
logic verify_sc_stage_busy;
logic verify_sc_stage_error_found;
logic enable_verify_sc_response_phase;
logic verify_sc_response_phase_busy;
logic enable_verify_nsc_stage;
logic verify_nsc_stage_busy;
logic alg1a_top_set_to_busy;
logic alg1a_set_to_not_busy;
logic enable_execute_response_phase;
logic execute_response_phase_busy;

logic [51:0] current_Z;

/* =======================================================================================
   signals for latency mode
*/
logic lm_rsp2axi_write_rsp_rcvd;
logic lm_axi2rsp_write_req_sent;
logic lm_rsp2axi_read_rsp_rcvd;
logic lm_axi2rsp_read_req_sent;

/* ======================================================================================= inject bad bit
   this should not be synthesized, just for verification  !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

   grabbing from the environment variables
      ERROR_PATTERN_ENABLE
      ERROR_PATTERN_LOOP
      ERROR_PATTERN_SET
      ERROR_PATTERN_N
      ERROR_PATTERN_BYTE
      ERROR_PATTERN_BIT
   set by sourcing the script error_patterns_script.sh
*/
`ifdef INCLUDE_TESTING_INJECT_BAD_BIT

  logic [511:0] data_with_bad_bit;

  testing_inject_pattern   inst_inject_bad_bit
  (
    .clk     ( clk ),
    .reset_n ( reset_n ),
    .i_loop  ( o_loop_count[7:0] ),
    .i_set   ( o_set_count[3:0]  ),
    .i_data  ( i_to_verify_sc_axi_rd_resp.rdata    ),
    .i_id    ( i_to_verify_sc_axi_rd_resp.rid[7:0] ),
    .i_valid ( i_to_verify_sc_axi_rd_resp.rvalid   ),
    .o_data  ( data_with_bad_bit )
  );

  t_axi4_rd_resp_ch    to_verify_sc_axi_rd_resp;

  always_comb
  begin
    to_verify_sc_axi_rd_resp.rvalid = i_to_verify_sc_axi_rd_resp.rvalid;
    to_verify_sc_axi_rd_resp.rid    = i_to_verify_sc_axi_rd_resp.rid;
    to_verify_sc_axi_rd_resp.rdata  = data_with_bad_bit;
    to_verify_sc_axi_rd_resp.rresp  = i_to_verify_sc_axi_rd_resp.rresp;
    to_verify_sc_axi_rd_resp.rlast  = i_to_verify_sc_axi_rd_resp.rlast;
    to_verify_sc_axi_rd_resp.ruser  = i_to_verify_sc_axi_rd_resp.ruser;
  end
`endif

/* =======================================================================================
*/
alg_1a_top_level_fsm_sc_only     inst_alg_1a_top_fsm
(
    .clk (clk),
    .reset_n (reset_n),
    .enable_in (i_enable),  // from ccv afu top level fsm

  /*  signals from configuration and debug registersre
  */
    .address_set_offset_reg           ( i_set_offset_reg                ),
    .algorithm_reg                    ( i_algorithm_reg                 ),
    .base_pattern_reg                 ( i_base_pattern_reg              ),
    .base_start_address_reg           ( i_base_start_address_reg        ),
    .base_write_back_address_reg      ( i_base_write_back_address_reg   ),
    .enable_self_checking_reg         ( i_self_checking_enabled_reg     ),
    .force_disable_afu                ( i_force_disable_reg             ),
    .number_of_address_increments_reg ( i_number_address_increments_reg ),
    .number_of_loops_reg              ( i_number_loops_reg              ),
    .number_of_sets_reg               ( i_number_sets_reg               ),
    .pattern_parameter_reg            ( i_pattern_parameter_reg         ),

    .i_mode_single_transaction_multi_loop ( i_mode_single_transaction_multi_loop ),
    .i_mode_single_transaction_one_loop   ( i_mode_single_transaction_one_loop   ),

  /*  signals for latency mode
  */
    .writes_only_mode_enable( writes_only_mode_enable ),
    .reads_only_mode_enable(   reads_only_mode_enable ),

    .extended_loop_count( extended_loop_count ),

  /*  signals to/from the execute stage
  */
    .enable_execute_flag     ( enable_execute_stage ),
    .execute_slverr_received ( o_execute_response_slverr_received ),
    .execute_busy_flag       ( o_execute_phase_busy ),

  /*  signals to/from the self checking verify stage
  */
    .enable_sc_verify_flag      ( enable_verify_sc_stage      ),
    .sc_verify_busy_flag        ( o_verify_sc_phase_busy      ),
    .sc_verify_error_found_flag ( verify_sc_stage_error_found ),
    .sc_verify_poison_received  ( o_verify_sc_response_poison_received ),
    .sc_verify_slverr_received  ( o_verify_sc_response_slverr_received ),


  /*  output signals used across AFU
  */
    .current_P       ( o_current_P           ),
    .current_X       ( o_current_X           ),
    .current_Z       ( current_Z             ),
    .loop_count      ( o_loop_count          ),
    .set_count       ( o_set_count           ),
    .set_to_busy     ( alg1a_set_to_busy     ),
    .set_to_not_busy ( alg1a_set_to_not_busy ),
    .busy_flag       ( o_alg1a_busy          )
);

// =================================================================================================
alg_1a_execute_write     inst_alg1a_execute_write
(
  .clk (clk),
  .reset_n (reset_n),

  /* signals to/from ccv afu top-level FSM
  */
  .current_P_in     ( o_current_P            ),
  .current_X_in     ( o_current_X            ),
  .enable_in        ( enable_execute_stage ),
  .execute_busy_out ( o_execute_phase_busy   ),

  /*  signals to/from the Algorithm 1a response count phase
  */
  .response_phase_busy            ( execute_response_phase_busy   ),
  .start_response_count_phase_out ( enable_execute_response_phase ),

  /* signals for AXI-MM write address channel
  */
  .awready         ( i_to_execute_axi_awready   ),
  .write_addr_chan ( o_from_execute_axi_wr_addr ),

  /* signals for AXI-MM write data channel
  */
  .wready          ( i_to_execute_axi_wready    ),
  .write_data_chan ( o_from_execute_axi_wr_data ),

   /*  signals for latency mode
    */
  .latency_mode_enabled( latency_mode_enable ),
  .lm_rsp2axi_write_rsp_rcvd( lm_rsp2axi_write_rsp_rcvd ),
  .lm_axi2rsp_write_req_sent( lm_axi2rsp_write_req_sent ),

  /*  signals from configuration and debug registers
  */
  .address_increment_reg            ( i_addr_increment_value_reg        ),
  .byte_mask_reg                    ( i_byte_mask_reg                   ),
  .force_disable_afu                ( i_force_disable_reg               ),
  .NAI                              ( i_real_total_transactions_per_set ),
  .number_of_address_increments_reg ( i_number_address_increments_reg   ),
  .pattern_size_reg                 ( i_pattern_size_reg                ),
  .RAI                              ( i_real_address_increment          ),
  .write_semantics_cache_reg        ( i_write_semantics_cache_reg       ),

  .single_transaction_per_set       ( i_mode_single_transaction_multi_loop
                                    | i_mode_single_transaction_one_loop
                                    | i_mode_single_transaction_per_set   )
);

// =================================================================================================
alg_1a_execute_response_count     inst_alg1a_execute_response
(
  .clk (clk),
  .reset_n (reset_n),

  /*  signals to/from the write phase FSM of the execute stage of Algorithm 1a
  */
  .enable_in ( enable_execute_response_phase ),

  /*  signals around a SLVERR on the AXI write response channel
  */
  .clear_slverr    ( i_mwae_set_to_busy                 ),
  .slverr_received ( o_execute_response_slverr_received ),
  .busy_out        ( execute_response_phase_busy ),

   /*  signals for latency mode
    */
   .latency_mode_enabled( latency_mode_enable ),
   .lm_rsp2axi_write_rsp_rcvd( lm_rsp2axi_write_rsp_rcvd ),
   .lm_axi2rsp_write_req_sent( lm_axi2rsp_write_req_sent ),

  /* signals for AXI-MM write responses channel
  */
  .bready          ( o_from_execute_axi_bready ),
  .write_resp_chan ( i_to_execute_axi_wr_resp  ),

  /*  signals from configuration and debug registers
  */
  .NAI                              ( i_real_total_transactions_per_set ),
  .number_of_address_increments_reg ( i_number_address_increments_reg   ),
  .force_disable_afu                ( i_force_disable_reg               ),

  .single_transaction_per_set       ( i_mode_single_transaction_multi_loop
                                    | i_mode_single_transaction_one_loop
                                    | i_mode_single_transaction_per_set   )
);

// =================================================================================================
alg_1a_verify_sc_read    inst_alg1a_verify_sc_read
(
    .clk (clk),
    .reset_n (reset_n),
    /* signals to/from ccv afu top-level FSM
    */
    .busy_flag_out ( o_verify_sc_phase_busy ),
    .enable_in     ( enable_verify_sc_stage ),

    /*  signals for latency mode
     */
    .latency_mode_enabled( latency_mode_enable ),
    .lm_rsp2axi_read_rsp_rcvd( lm_rsp2axi_read_rsp_rcvd ),
    .lm_axi2rsp_read_req_sent( lm_axi2rsp_read_req_sent ),

    /*  signals to/from the Algorithm 1a self checking verify
      reponse phase
    */
    .start_response_phase_out ( enable_verify_sc_response_phase ),
    .response_phase_busy_flag ( verify_sc_response_phase_busy   ),

    /* signals for AXI-MM read address channel
    */
    .arready        ( i_to_verify_sc_axi_arready   ),
    .read_addr_chan ( o_from_verify_sc_axi_rd_addr ),

    /*   signals from the alg1a top level FSM
    */
    .current_X_in ( o_current_X ),

    /*  signals from configuration and debug registers
    */
    .address_increment_reg            ( i_addr_increment_value_reg        ),
    .force_disable_afu                ( i_force_disable_reg               ),
    .NAI                              ( i_real_total_transactions_per_set ),
    .number_of_address_increments_reg ( i_number_address_increments_reg   ),
    .RAI                              ( i_real_address_increment          ),
    .verify_semantics_cache_reg       ( i_verify_read_semantics_cache_reg ),

    .single_transaction_per_set       ( i_mode_single_transaction_multi_loop
                                      | i_mode_single_transaction_one_loop
                                      | i_mode_single_transaction_per_set   )
);

// =================================================================================================
alg_1a_verify_sc_response   inst_alg_1a_verify_sc_response
(
    .clk (clk),
    .reset_n (reset_n),

    /*  signals from the Algorithm 1a self checking verify
      read phase
    */
    .enable_in ( enable_verify_sc_response_phase ),
    .i_mwae_busy( i_mwae_busy ),

    .busy_out ( verify_sc_response_phase_busy ),

    /*  signals for latency mode
     */
    .latency_mode_enabled( latency_mode_enable ),
    .lm_rsp2axi_read_rsp_rcvd( lm_rsp2axi_read_rsp_rcvd ),
    .lm_axi2rsp_read_req_sent( lm_axi2rsp_read_req_sent ),

    /*  signals for read only mode to skip error recordings
     */
    .reads_only_mode_enable( reads_only_mode_enable ),

    /*   signals from the top level FSM
    */
    .clear_errors_in ( i_mwae_set_to_busy ),
    .current_P_in    ( o_current_P        ),
    .current_X_in    ( o_current_X        ),

    /* signals to ccv afu top-level FSM and debug registers
    */
    .error_address          ( o_error_address             ),
    .error_addr_increment   ( o_error_addr_increment      ),
    .error_byte_offset      ( o_error_byte_offset         ),
    .error_expected_pattern ( o_error_expected_pattern    ),
    .error_found_out        ( verify_sc_stage_error_found ),
    .error_received_pattern ( o_error_received_pattern    ),
    .record_error_flag_out  ( o_verify_sc_record_error    ),

    .poison_received        ( o_verify_sc_response_poison_received ),
    .slverr_received        ( o_verify_sc_response_slverr_received ),

    /* signals for AXI-MM read address channel
    */
`ifdef INCLUDE_TESTING_INJECT_BAD_BIT
    .read_resp_chan ( to_verify_sc_axi_rd_resp    ),
    .rready         ( o_from_verify_sc_axi_rready ),
`else
    .read_resp_chan ( i_to_verify_sc_axi_rd_resp  ),
    .rready         ( o_from_verify_sc_axi_rready ),
`endif

    /*  signals from configuration and debug registers
    */
    .address_increment_reg            ( i_addr_increment_value_reg        ),
    .byte_mask_reg                    ( i_byte_mask_reg                   ),
    .force_disable_afu                ( i_force_disable_reg               ),
    .NAI                              ( i_real_total_transactions_per_set ),
    .number_of_address_increments_reg ( i_number_address_increments_reg   ),
    .pattern_size_reg                 ( i_pattern_size_reg                ),
    .RAI                              ( i_real_address_increment          ),

    .single_transaction_per_set       ( i_mode_single_transaction_multi_loop
                                      | i_mode_single_transaction_one_loop
                                      | i_mode_single_transaction_per_set   )
);


endmodule
