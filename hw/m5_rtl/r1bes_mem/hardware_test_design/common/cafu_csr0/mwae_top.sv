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

`include "cxl_ed_defines.svh.iv"
module mwae_top   // multi_write_algorithms_engine_top
  import ccv_afu_pkg::*;
  import afu_axi_if_pkg::*;
//  import ccv_afu_cfg_pkg::*;
  import tmp_cafu_csr0_cfg_pkg::*;
#(
   parameter SUPPORT_ALG1A     = 1,
   parameter SUPPORT_ALG1A_NSC = 0,
   parameter SUPPORT_ALG1A_SC  = 1,
   parameter SUPPORT_ALG1B     = 0,
   parameter SUPPORT_ALG1B_NSC = 0,
   parameter SUPPORT_ALG1B_SC  = 0,
   parameter SUPPORT_ALG2      = 0
)
(
  /* assuming clock for axi-mm (all channels) and AFU are the same to avoid clock
     domain crossing.
  */
  input logic  rtl_clk,
  input logic  reset_n,

  /* flag from mwae indicating that HW wants to set the error status field of the
     ERROR_LOG3 cfg reg.
     Software will then set this field to zero to clear all error log registers.
  */
  output logic record_error_out,    // active high

  input tmp_cafu_csr0_cfg_pkg::tmp_CONFIG_TEST_START_ADDR_t     start_address_reg,
  input tmp_cafu_csr0_cfg_pkg::tmp_CONFIG_TEST_WR_BACK_ADDR_t   write_back_address_reg,
  input tmp_cafu_csr0_cfg_pkg::tmp_CONFIG_TEST_ADDR_INCRE_t     increment_reg,
  input tmp_cafu_csr0_cfg_pkg::tmp_CONFIG_TEST_PATTERN_t        pattern_reg,
  input tmp_cafu_csr0_cfg_pkg::tmp_CONFIG_TEST_BYTEMASK_t       bytemask_reg,
  input tmp_cafu_csr0_cfg_pkg::tmp_CONFIG_TEST_PATTERN_PARAM_t  pattern_config_reg,
  input tmp_cafu_csr0_cfg_pkg::tmp_CONFIG_ALGO_SETTING_t        algorithm_config_reg,
  input tmp_cafu_csr0_cfg_pkg::tmp_DEVICE_ERROR_LOG3_t          device_error_log3_reg,
  input tmp_cafu_csr0_cfg_pkg::tmp_DEVICE_FORCE_DISABLE_t       device_force_disable_reg,
  input tmp_cafu_csr0_cfg_pkg::tmp_DEVICE_ERROR_INJECTION_t     device_error_injection_reg,
  input tmp_cafu_csr0_cfg_pkg::tmp_DEVICE_AFU_LATENCY_MODE_t    device_afu_latency_mode_reg,

  output tmp_cafu_csr0_cfg_pkg::tmp_new_CONFIG_CXL_ERRORS_t         config_and_cxl_errors_reg,
  output tmp_cafu_csr0_cfg_pkg::tmp_new_DEVICE_AFU_STATUS1_t        device_afu_status_1_reg,
  output tmp_cafu_csr0_cfg_pkg::tmp_new_DEVICE_AFU_STATUS2_t        device_afu_status_2_reg,
  output tmp_cafu_csr0_cfg_pkg::tmp_new_DEVICE_ERROR_LOG1_t         error_log_1_reg,
  output tmp_cafu_csr0_cfg_pkg::tmp_new_DEVICE_ERROR_LOG2_t         error_log_2_reg,
  output tmp_cafu_csr0_cfg_pkg::tmp_new_DEVICE_ERROR_LOG3_t         error_log_3_reg,
  output tmp_cafu_csr0_cfg_pkg::tmp_new_DEVICE_ERROR_LOG4_t         error_log_4_reg,
  output tmp_cafu_csr0_cfg_pkg::tmp_new_DEVICE_ERROR_LOG5_t         error_log_5_reg,
  output tmp_cafu_csr0_cfg_pkg::tmp_new_DEVICE_ERROR_INJECTION_t    new_device_error_injection_reg,
  output tmp_cafu_csr0_cfg_pkg::tmp_new_DEVICE_AFU_LATENCY_MODE_t   new_device_afu_latency_mode_reg,

  /* August 2023 - send out locked protocol type reg to higher level modules
   */
  output logic o_locked_protocol_type,

  /* AXI-MM interface - this afu is the initator
  */
  output t_axi4_wr_addr_ch      o_axi_wr_addr_chan,
   input t_axi4_wr_addr_ready   i_axi_awready,
  output t_axi4_wr_data_ch      o_axi_wr_data_chan,
   input t_axi4_wr_data_ready   i_axi_wready,
   input t_axi4_wr_resp_ch      i_axi_wr_resp_chan,
  output t_axi4_wr_resp_ready   o_axi_bready,

  output t_axi4_rd_addr_ch      o_axi_rd_addr_chan,
   input t_axi4_rd_addr_ready   i_axi_arready,
   input t_axi4_rd_resp_ch      i_axi_rd_resp_chan,
  output t_axi4_rd_resp_ready   o_axi_rready
);

/* =================================================================================================
*/
logic mwae_top_fsm_lock_config;
logic mwae_top_fsm_busy;
logic mwae_top_fsm_set_to_busy;
logic mwae_top_fsm_illegal_config_fail;

config_check_t mwae_top_fsm_illegal_config_status;

/* =================================================================================================
   signals for algorithm 1A
*/
`ifdef SUPPORT_ALGORITHM_1A
       logic enable_alg_1a;
       logic alg_1a_busy_flag;
       logic alg1a_execute_phase_busy;
       logic alg_1a_execute_response_slverr_received;

       logic [51:0] alg_1a_current_base_address;
       logic [31:0] alg_1a_current_base_pattern;
       logic [9:0]  alg_1a_current_loop_count;
       logic [4:0]  alg_1a_current_set_count;

   `ifdef ALG_1A_SUPPORT_SELF_CHECK
          logic [CCV_AFU_ADDR_WIDTH-1:0] alg_1a_error_address;

          logic        alg_1a_verify_sc_busy;
          logic        alg_1a_verify_sc_record_error;
          logic [7:0]  alg_1a_error_addr_increment;
          logic [31:0] alg_1a_error_expected_pattern;
          logic [31:0] alg_1a_error_received_pattern;
          logic [5:0]  alg_1a_error_byte_offset;
          logic        alg_1a_verify_sc_response_poison_received;
          logic        alg_1a_verify_sc_response_slverr_received;

          t_axi4_rd_addr_ch     alg_1a_verify_sc_axi_rd_addr;
          t_axi4_rd_resp_ready  alg_1a_verify_sc_axi_rready;
          t_axi4_rd_addr_ready  alg_1a_verify_sc_axi_arready;
          t_axi4_rd_resp_ch     alg_1a_verify_sc_axi_rd_resp;
   `endif
`endif

/* =================================================================================================
   signals for algorithm 1B
*/
`ifdef SUPPORT_ALGORITHM_1B
       logic enable_alg_1b;
       logic alg_1b_busy_flag;
`endif

/* =================================================================================================
   signals for algorithm 2
*/
`ifdef SUPPORT_ALGORITHM_2
       logic enable_alg_2;
       logic alg_2_busy_flag;
`endif

/* =================================================================================================
*/
logic [CCV_AFU_ADDR_WIDTH-1:0] base_start_address_reg;
logic [CCV_AFU_ADDR_WIDTH-1:0] base_write_back_address_reg;

logic [31:0]    address_increment_reg;
logic [31:0]    address_set_offset_reg;
logic [31:0]    base_pattern_reg;
logic [31:0]    base_bogus_pattern_reg;
logic [63:0]    byte_mask_reg;
logic           pattern_parameter_reg;
logic [2:0]     pattern_size_reg;
    
logic [2:0]     verify_semantics_cache_reg;
logic [2:0]     exeucte_read_semantics_reg;
logic           flush_cache_reg;
logic [3:0]     write_semantics_cache_reg;
logic [2:0]     interface_protocol_type_reg;
logic           address_is_virtual_reg;
logic [7:0]     number_of_loops_reg;
logic [7:0]     number_of_sets_reg;
logic [7:0]     number_of_address_incrs_reg;
logic           enable_self_checking_reg;
logic [2:0]     algorithm_reg;

logic force_disable_afu;
logic error_log3_error_status;
logic latency_mode_enable_reg;
logic writes_only_mode_enable_reg;
logic reads_only_mode_enable_reg;

logic [19:0] extended_loop_count;

/* =================================================================================================
   The algorithm field of the algorithm configuration registers starts a test.
   Setting the algorithm field back to zero starts a graceful disable
*/
always_comb
begin
  if( reset_n == 1'b0 ) algorithm_reg = 3'd0;
  else                  algorithm_reg = algorithm_config_reg.test_algorithm_type;
end

/* =================================================================================================
*/
always_comb
begin
  if( reset_n == 1'b0 ) force_disable_afu <= 1'b0;
  else                  force_disable_afu <= device_force_disable_reg.forcefully_disable_afu;
end

/* =================================================================================================
*/
always_comb
begin
  if( reset_n == 1'b0 ) error_log3_error_status <= 1'b0;
  else                  error_log3_error_status <= device_error_log3_reg.error_status;
end

/* =================================================================================================
   Handle the remainder of the configuration registers and fields
*/
always_ff @( posedge rtl_clk )
begin
  if( reset_n == 1'b0 )
  begin
    address_increment_reg       <= 32'd0;
    address_is_virtual_reg      <= 1'b0;
    address_set_offset_reg      <= 32'd0;
    base_bogus_pattern_reg      <= 32'd0;
    base_pattern_reg            <= 32'd0;
    base_start_address_reg      <= 64'd0;
    base_write_back_address_reg <= 64'd0;
    byte_mask_reg               <= 64'd0;
    enable_self_checking_reg    <= 1'b1;
    exeucte_read_semantics_reg  <= 3'd0;
    flush_cache_reg             <= 1'b0;
    interface_protocol_type_reg <= 3'd0;
    number_of_address_incrs_reg <= 8'd0;
    number_of_loops_reg         <= 8'd0;
    number_of_sets_reg          <= 8'd0;
    pattern_parameter_reg       <= 1'b0;
    pattern_size_reg            <= 3'd0;
    verify_semantics_cache_reg  <= 3'd0;
    write_semantics_cache_reg   <= 4'd0;
    latency_mode_enable_reg     <= 1'b0;
    writes_only_mode_enable_reg <= 1'b0;
    reads_only_mode_enable_reg  <= 1'b0;
  end
  else if( mwae_top_fsm_lock_config == 1'b1 )
  begin
    address_increment_reg       <= increment_reg.config_test_addr_incre;
    address_is_virtual_reg      <= algorithm_config_reg.address_is_virtual;
    address_set_offset_reg      <= increment_reg.config_test_addr_setoffset;
    base_bogus_pattern_reg      <= pattern_reg.algorithm_pattern2;
    base_pattern_reg            <= pattern_reg.algorithm_pattern1;
    base_start_address_reg      <= start_address_reg.config_test_start_addr;
    base_write_back_address_reg <= write_back_address_reg.config_test_wrback_addr;
    byte_mask_reg               <= bytemask_reg.cacheline_bytemask;
    enable_self_checking_reg    <= algorithm_config_reg.device_selfchecking;
    exeucte_read_semantics_reg  <= algorithm_config_reg.execute_read_semantics;
    flush_cache_reg             <= algorithm_config_reg.flush_cache;
    interface_protocol_type_reg <= algorithm_config_reg.interface_protocol_type;
    number_of_address_incrs_reg <= algorithm_config_reg.num_of_increments;
    number_of_loops_reg         <= algorithm_config_reg.num_of_loops;
    number_of_sets_reg          <= algorithm_config_reg.num_of_sets;
    pattern_parameter_reg       <= pattern_config_reg.pattern_parameter;
    pattern_size_reg            <= pattern_config_reg.pattern_size;
    verify_semantics_cache_reg  <= algorithm_config_reg.verify_semantics_cache;
    write_semantics_cache_reg   <= algorithm_config_reg.write_semantics_cache;
    latency_mode_enable_reg     <= device_afu_latency_mode_reg.latency_mode_enable;
    writes_only_mode_enable_reg <= device_afu_latency_mode_reg.writes_only_mode_enable;
    reads_only_mode_enable_reg  <= device_afu_latency_mode_reg.reads_only_mode_enable;
  end
  else begin
    address_increment_reg       <= address_increment_reg;
    address_is_virtual_reg      <= address_is_virtual_reg;
    address_set_offset_reg      <= address_set_offset_reg;
    base_bogus_pattern_reg      <= base_bogus_pattern_reg;
    base_pattern_reg            <= base_pattern_reg;
    base_start_address_reg      <= base_start_address_reg;
    base_write_back_address_reg <= base_write_back_address_reg;
    byte_mask_reg               <= byte_mask_reg;
    enable_self_checking_reg    <= enable_self_checking_reg;
    exeucte_read_semantics_reg  <= exeucte_read_semantics_reg;
    flush_cache_reg             <= flush_cache_reg;
    interface_protocol_type_reg <= interface_protocol_type_reg;
    number_of_address_incrs_reg <= number_of_address_incrs_reg;
    number_of_loops_reg         <= number_of_loops_reg;
    number_of_sets_reg          <= number_of_sets_reg;
    pattern_parameter_reg       <= pattern_parameter_reg;
    pattern_size_reg            <= pattern_size_reg;
    verify_semantics_cache_reg  <= verify_semantics_cache_reg;
    write_semantics_cache_reg   <= write_semantics_cache_reg;
    latency_mode_enable_reg     <= latency_mode_enable_reg;
    writes_only_mode_enable_reg <= writes_only_mode_enable_reg;
    reads_only_mode_enable_reg  <= reads_only_mode_enable_reg;
  end
end

/* =================================================================================================
   August 2023 - send out locked protocol type reg to higher level modules
 */
assign o_locked_protocol_type = interface_protocol_type_reg;

/* =================================================================================================
   Added for latency mode registers
*/
logic [19:0] total_number_loops;
logic        clear_number_loops;


always_comb
begin
  new_device_afu_latency_mode_reg.total_number_loops = total_number_loops;

  clear_number_loops = device_afu_latency_mode_reg.clear_number_loops;
end


always_ff @( posedge rtl_clk )
begin
       if( reset_n == 1'b0 )            total_number_loops <= 'd0;
  else if( clear_number_loops == 1'b1 ) total_number_loops <= 'd0;
  else                                  total_number_loops <= extended_loop_count;
end

/* ======================================================================================= POISON INJECTION
*/
`ifdef INCLUDE_POISON_INJECTION
       logic poison_injection_busy;
       logic set_wuser_poison;

  mwae_poison_injection   inst_poison_injection
  (
    .clk                    ( rtl_clk ),
    .reset_n                ( reset_n ),
    .wvalid                 ( alg_1a_execute_axi_wr_data.wvalid ),
    .poison_injection_start ( device_error_injection_reg.CachePoisonInjectionStart ),
    .force_disable_afu      ( force_disable_afu     ),
    .poison_injection_busy  ( poison_injection_busy ),
    .set_wuser_poison       ( set_wuser_poison      )
  );

`endif

/* =======================================================================================  AXI PORTS
   just assign axi ports to alg 1a execute and verify self checking for now
*/
t_axi4_wr_addr_ch     alg_1a_execute_axi_wr_addr;
t_axi4_wr_data_ch     alg_1a_execute_axi_wr_data;
t_axi4_wr_resp_ch     alg_1a_execute_axi_wr_resp;

t_axi4_wr_addr_ready  alg_1a_execute_axi_awready;
t_axi4_wr_data_ready  alg_1a_execute_axi_wready;
t_axi4_wr_resp_ready  alg_1a_execute_axi_bready;

assign o_axi_wr_addr_chan          = alg_1a_execute_axi_wr_addr;
assign alg_1a_execute_axi_awready  = i_axi_awready;
assign alg_1a_execute_axi_wready   = i_axi_wready;
assign alg_1a_execute_axi_wr_resp  = i_axi_wr_resp_chan;
assign o_axi_bready                = alg_1a_execute_axi_bready;

assign o_axi_rd_addr_chan           = alg_1a_verify_sc_axi_rd_addr;
assign alg_1a_verify_sc_axi_arready = i_axi_arready;
assign alg_1a_verify_sc_axi_rd_resp = i_axi_rd_resp_chan;
assign o_axi_rready                 = alg_1a_verify_sc_axi_rready;

`ifdef INCLUDE_POISON_INJECTION
       assign o_axi_wr_data_chan.wdata  = alg_1a_execute_axi_wr_data.wdata;
       assign o_axi_wr_data_chan.wlast  = alg_1a_execute_axi_wr_data.wlast;
       assign o_axi_wr_data_chan.wstrb  = alg_1a_execute_axi_wr_data.wstrb;
       assign o_axi_wr_data_chan.wvalid = alg_1a_execute_axi_wr_data.wvalid;

       assign o_axi_wr_data_chan.wuser.poison = (set_wuser_poison == 1'b1) ? 1'b1 : 
                                                      alg_1a_execute_axi_wr_data.wuser.poison;
`else
       assign o_axi_wr_data_chan          = alg_1a_execute_axi_wr_data;
`endif

/* =======================================================================================
   CXL 2.0 Spec page 603
   If both NumberOfAddIncrements and NumberOfSets is zero, only a single transaction (to the base address)
   should be issued by the device [NumberOfLoops should be set to 1 for this case]
*/
logic mode_single_transaction_one_loop;
logic mode_single_transaction_multi_loop;
logic mode_single_transaction_per_set;

always_ff @( posedge rtl_clk )
begin
  if( reset_n == 1'b0 )   mode_single_transaction_one_loop <= 1'b0;
  else begin
              mode_single_transaction_one_loop <= ( number_of_address_incrs_reg == 'd0 )
                                                & ( number_of_sets_reg == 'd0 )
                                                & ( number_of_loops_reg == 'd1 );
  end
end

/*  same as above but either infinite looping or 2+ loops
*/
always_ff @( posedge rtl_clk )
begin
  if( reset_n == 1'b0 )   mode_single_transaction_multi_loop <= 1'b0;
  else begin
              mode_single_transaction_multi_loop <= ( number_of_address_incrs_reg == 'd0 )
                                                  & ( number_of_sets_reg == 'd0 )
                                                  & ( number_of_loops_reg != 'd1 );
  end
end

always_ff @( posedge rtl_clk )
begin
  if( reset_n == 1'b0 )   mode_single_transaction_per_set <= 1'b0;
  else                    mode_single_transaction_per_set <= ( number_of_address_incrs_reg == 'd0 );
end

/* =======================================================================================
   CXL 2.0 Spec page 602
   AddressIncrement: Indicates the increment for address (Y) in Algorithms 1a,1b and 2. 
   The value in this register should be left shifted by 6 bits before using as address increment.
*/
logic [37:0] real_address_increment;

always_ff @( posedge rtl_clk )
begin
  if( reset_n == 1'b0 ) real_address_increment <= 'd0;
  else                  real_address_increment <= address_increment_reg << 6;
end

/* =======================================================================================
   CXL 2.0 Spec page 602
   SetOffset: Indicates the set offset increment for address (X) and (Z) in Algorithms 1a,1b and 2.
   The value in this register should be left shifted by 6 bits before using as address increment.
*/
logic [37:0] real_set_offset;

always_ff @( posedge rtl_clk )
begin
  if( reset_n == 1'b0 ) real_set_offset <= 'd0;
  else                  real_set_offset <= address_set_offset_reg << 6;
end

/* =======================================================================================
   if write semantics cache register is set to 4'd0 or 4'd1 or 4'd4, then it's full cacheline writes
   so the bytemask should be all 1's
*/
logic [63:0] real_byte_mask_reg;

always_ff @( posedge rtl_clk )
begin
       if( reset_n == 1'b0 )                   real_byte_mask_reg <= 'd0;
  else if( (interface_protocol_type_reg == 3'b010) & (write_semantics_cache_reg) == 4'd0 ) real_byte_mask_reg <= 64'hFFFF_FFFF_FFFF_FFFF;
  else if( (interface_protocol_type_reg == 3'b010) & (write_semantics_cache_reg) == 4'd1 ) real_byte_mask_reg <= 64'hFFFF_FFFF_FFFF_FFFF;
  else if( (interface_protocol_type_reg == 3'b010) & (write_semantics_cache_reg) == 4'd4 ) real_byte_mask_reg <= 64'hFFFF_FFFF_FFFF_FFFF;
  else                                         real_byte_mask_reg <= byte_mask_reg;
end

/* =======================================================================================
  CXL 2.0 Spec page 485 Figure 192
  writes go from base (N=0) to N (set by number_address_increments)
  so real transactions count is N+1
*/
logic [8:0] real_total_transactions_per_set;

always_ff @( posedge rtl_clk )
begin
       if( reset_n == 1'b0 )                            real_total_transactions_per_set <= 'd0;
  else if( mode_single_transaction_multi_loop == 1'b1 ) real_total_transactions_per_set <= 'd1;
  else if( mode_single_transaction_one_loop   == 1'b1 ) real_total_transactions_per_set <= 'd1;
  else if( mode_single_transaction_per_set    == 1'b1 ) real_total_transactions_per_set <= 'd1;
  else                                                  real_total_transactions_per_set <= (number_of_address_incrs_reg );
end

/* ================================================================================ FLUSHCACHE_NOT_SUPPORTED
   page 604, Table 268 of CXL 2.0 Spec
   FlushCache field
   cacheflush is not currently supported. If software sets it, raise the appropriate error bit stop running
*/
`ifdef FLUSHCACHE_NOT_SUPPORTED
       logic unsupported_cache_flush_error;

  always@( posedge rtl_clk )
  begin
         if( reset_n == 1'b0 )         unsupported_cache_flush_error <= 1'b0;
    else if( algorithm_reg == 1'b0 )   unsupported_cache_flush_error <= 1'b0;
    else if( flush_cache_reg == 1'b1 ) unsupported_cache_flush_error <= 1'b1;
    else                               unsupported_cache_flush_error <= unsupported_cache_flush_error;
  end

`endif

/* =======================================================================================
*/
mwae_error_injection_regs  inst_mwae_error_injection_regs
(
  .clk     ( rtl_clk ),
  .reset_n ( reset_n ),

  `ifdef INCLUDE_POISON_INJECTION
         .algorithm_reg              ( algorithm_reg         ),
         .force_disable_afu          ( force_disable_afu     ),
         .i_cache_poison_inject_busy ( poison_injection_busy ),
  `endif

  .new_device_error_injection_reg ( new_device_error_injection_reg )
);

/* =======================================================================================
   handle the config and cxl error register out to software
*/
mwae_config_and_cxl_errors_reg   inst_mwae_config_and_cxl_errors_reg
(
  .clk                        ( rtl_clk ),
  .reset_n                    ( reset_n ),
  .i_mwae_top_fsm_set_to_busy ( mwae_top_fsm_set_to_busy ),
  .i_valid_illegal_config     ( mwae_top_fsm_illegal_config_fail ),
  .i_config_check_values      ( mwae_top_fsm_illegal_config_status ),

  .i_slverr_on_write_response ( alg_1a_execute_response_slverr_received   ),
  .i_slverr_on_read_response  ( alg_1a_verify_sc_response_slverr_received ),
  .i_poison_on_read_response  ( alg_1a_verify_sc_response_poison_received ),

  .unsupported_cache_flush_error ( unsupported_cache_flush_error ),

  .config_and_cxl_errors_reg  ( config_and_cxl_errors_reg )
);
 
/* =======================================================================================
   handle the AFU status registers out to software
*/
logic [51:0] afu_status_reg_current_base_address;
logic [31:0] afu_status_reg_current_base_pattern;
logic [7:0]  afu_status_reg_current_loop_num;
logic [3:0]  afu_status_reg_current_set_num;

assign afu_status_reg_current_base_address = alg_1a_current_base_address;
assign afu_status_reg_current_base_pattern = alg_1a_current_base_pattern;
assign afu_status_reg_current_loop_num     = alg_1a_current_loop_count[7:0];
assign afu_status_reg_current_set_num      = alg_1a_current_set_count;

mwae_afu_status_regs   inst_mwae_afu_status_regs
(
  .clk                        ( rtl_clk ),
  .reset_n                    ( reset_n ),
  .i_mwea_top_level_fsm_busy  ( mwae_top_fsm_busy ),

  `ifdef SUPPORT_ALGORITHM_1A
         .i_alg_1a_execute_busy ( alg1a_execute_phase_busy ),
  `else
         .i_alg_1a_execute_busy ( 1'b0 ),
  `endif

  `ifdef SUPPORT_ALGORITHM_1B
         .i_alg_1b_execute_busy ( alg1b_execute_phase_busy ),
  `else
         .i_alg_1b_execute_busy ( 1'b0 ),
  `endif

  `ifdef SUPPORT_ALGORITHM_2
         .i_alg_2_execute_busy  ( alg2_execute_phase_busy ),
  `else
         .i_alg_2_execute_busy  ( 1'b0 ),
  `endif

  `ifdef SUPPORT_ALGORITHM_1A
     `ifdef ALG_1A_SUPPORT_SELF_CHECK
         .i_alg_1a_verify_sc_busy      ( alg_1a_verify_sc_busy ),
     `else
         .i_alg_1a_verify_sc_busy      ( 1'b0 ),
     `endif
  `else
         .i_alg_1a_verify_sc_busy      ( 1'b0 ),
  `endif

  `ifdef SUPPORT_ALGORITHM_1A
     `ifdef ALG_1A_SUPPORT_NON_SELF_CHECK
         .i_alg_1a_verify_nsc_busy     ( alg_1a_verify_nsc_busy ),
     `else
         .i_alg_1a_verify_nsc_busy     ( 1'b0 ),
     `endif
  `else
         .i_alg_1a_verify_nsc_busy     ( 1'b0 ),
  `endif

  `ifdef SUPPORT_ALGORITHM_1B
     `ifdef ALG_1B_SUPPORT_SELF_CHECK
         .i_alg_1b_verify_sc_busy      ( alg_1b_verify_sc_busy ),
     `else
         .i_alg_1b_verify_sc_busy      ( 1'b0 ),
     `endif
  `else
         .i_alg_1b_verify_sc_busy      ( 1'b0 ),
  `endif

  `ifdef SUPPORT_ALGORITHM_1B
     `ifdef ALG_1B_SUPPORT_NON_SELF_CHECK
         .i_alg_1b_verify_nsc_busy     ( alg_1b_verify_nsc_busy ),
     `else
         .i_alg_1b_verify_nsc_busy     ( 1'b0 ),
     `endif
  `else
         .i_alg_1b_verify_nsc_busy     ( 1'b0 ),
  `endif

  .i_current_loop_number  ( afu_status_reg_current_loop_num     ),
  .i_current_set_number   ( afu_status_reg_current_set_num      ),
  .i_current_base_pattern ( afu_status_reg_current_base_pattern ),
  .i_current_base_address ( afu_status_reg_current_base_address ),

  .device_afu_status_1_reg ( device_afu_status_1_reg ),
  .device_afu_status_2_reg ( device_afu_status_2_reg )
);

/* =======================================================================================
   handle the debug registers from hardware to software
*/
mwae_debug_logs   inst_debug_log_regs
(
  .clk                           ( rtl_clk ),
  .reset_n                       ( reset_n ),

  /*  signals for latency mode
   */
  .writes_only_mode_enable( writes_only_mode_enable_reg ),
  .reads_only_mode_enable(   reads_only_mode_enable_reg ),

  .i_mwae_top_fsm_set_to_busy    ( mwae_top_fsm_set_to_busy ),
  .i_mwae_top_fsm_busy           ( mwae_top_fsm_busy        ),
  .i_debug_log3_error_status_reg ( error_log3_error_status  ),
  .i_enable_self_checking_reg    ( enable_self_checking_reg ),
  .i_forceful_disable_reg        ( force_disable_afu        ),

  `ifdef SUPPORT_ALGORITHM_1A
    `ifdef ALG_1A_SUPPORT_SELF_CHECK
           .i_alg_1a_error_found_flag               ( alg_1a_verify_sc_record_error    ),
           .i_alg_1a_error_observed_pattern         ( alg_1a_error_received_pattern    ),
           .i_alg_1a_error_expected_pattern         ( alg_1a_error_expected_pattern    ),
           .i_alg_1a_error_loop_number              ( alg_1a_current_loop_count[7:0]   ),
           .i_alg_1a_error_byte_offset              ( alg_1a_error_byte_offset         ),
           .i_alg_1a_error_set_number               ( alg_1a_current_set_count[3:0]    ),
           .i_alg_1a_error_address_increment        ( alg_1a_error_addr_increment      ),
           .i_alg_1a_error_address                  ( alg_1a_error_address             ),
    `endif
  `endif

  `ifdef SUPPORT_ALGORITHM_1B
    `ifdef ALG_1B_SUPPORT_SELF_CHECK
           .i_alg_1b_error_found_flag               (),
           .i_alg_1b_error_observed_pattern         (),
           .i_alg_1b_error_expected_pattern         (),
           .i_alg_1b_error_loop_number              (),
           .i_alg_1b_error_byte_offset              (),
           .i_alg_1b_error_set_number               (),
           .i_alg_1b_error_address_increment        (),
           .i_alg_1b_error_address                  (),
    `endif
  `endif

  .i_slverr_on_write_response ( alg_1a_execute_response_slverr_received   ),
  .i_slverr_on_read_response  ( alg_1a_verify_sc_response_slverr_received ),
  .i_poison_on_read_response  ( alg_1a_verify_sc_response_poison_received ),

  .error_log_1_reg    ( error_log_1_reg    ),
  .error_log_2_reg    ( error_log_2_reg    ),
  .error_log_3_reg    ( error_log_3_reg    ),
  .error_log_4_reg    ( error_log_4_reg    ),
  .error_log_5_reg    ( error_log_5_reg    ),
  .record_error_out   ( record_error_out   )
);

/* =======================================================================================
*/
mwae_top_level_fsm    inst_mwae_top_fsm
(
  .clk ( rtl_clk ),
  .reset_n ( reset_n ),

  /*  signals from configuration and debug registersre
  */
  .algorithm_reg                    ( algorithm_reg               ),
  .execute_read_semantics_cache_reg ( exeucte_read_semantics_reg  ),
  .forceful_disable_reg             ( force_disable_afu           ),
  .interface_protocol_reg           ( interface_protocol_type_reg ),
  .pattern_size_reg                 ( pattern_size_reg            ),
  .start_address_reg                ( base_start_address_reg      ),
  .verify_read_semantics_cache_reg  ( verify_semantics_cache_reg  ),
  .write_semantics_cache_reg        ( write_semantics_cache_reg   ),
  .unsupported_cache_flush_error    ( unsupported_cache_flush_error ),

  /*  signals to/from the multi write algorithms engine
  */
  `ifdef SUPPORT_ALGORITHM_1A
         .enable_alg_1a    ( enable_alg_1a    ),
         .alg_1a_busy_flag ( alg_1a_busy_flag ),
  `endif
  `ifdef SUPPORT_ALGORITHM_1B
         .enable_alg_1b    ( enable_alg_1b    ),
         .alg_1b_busy_flag ( alg_1b_busy_flag ),
  `endif
  `ifdef SUPPORT_ALGORITHM_2
         .enable_alg_2     ( enable_alg_2     ),
         .alg_2_busy_flag  ( alg_2_busy_flag  ),
  `endif

  /*  signals to configuration and debug registersre
  */
  .lock_config           ( mwae_top_fsm_lock_config           ),
  .busy_flag             ( mwae_top_fsm_busy                  ),
  .set_to_busy           ( mwae_top_fsm_set_to_busy           ),
  .config_check_fail_out ( mwae_top_fsm_illegal_config_fail   ),
  .illegal_config_out    ( mwae_top_fsm_illegal_config_status )
);

/* =======================================================================================
*/
//`ifdef SUPPORT_ALGORITHM_1A
generate if( SUPPORT_ALG1A == 1 )
begin : gen_alg_1a_top
  alg_1a_top   inst_alg_1a_top
  (
    .clk ( rtl_clk ),
    .reset_n ( reset_n ),

    /*  signals for latency mode
    */
    .latency_mode_enable( latency_mode_enable_reg ),
    .writes_only_mode_enable( writes_only_mode_enable_reg ),
    .reads_only_mode_enable(   reads_only_mode_enable_reg ),

    .extended_loop_count( extended_loop_count ),

    /* signals to/from ccv afu top-level FSM
    */
    .i_enable             ( enable_alg_1a            ),
    .i_mwae_busy          ( mwae_top_fsm_busy        ),
    .i_mwae_set_to_busy   ( mwae_top_fsm_set_to_busy ),
    .o_alg1a_busy         ( alg_1a_busy_flag         ),

    .o_execute_phase_busy               ( alg1a_execute_phase_busy ),
    .o_execute_response_slverr_received ( alg_1a_execute_response_slverr_received ),

    `ifdef ALG_1A_SUPPORT_SELF_CHECK
           .o_verify_sc_phase_busy    ( alg_1a_verify_sc_busy         ),
           .o_verify_sc_record_error  ( alg_1a_verify_sc_record_error ),

           .o_verify_sc_response_poison_received ( alg_1a_verify_sc_response_poison_received ),
           .o_verify_sc_response_slverr_received ( alg_1a_verify_sc_response_slverr_received ),
    `endif

    `ifdef ALG_1A_SUPPORT_NON_SELF_CHECK
           .o_verify_nsc_phase_busy   ( alg_1a_verify_nsc_busy        ),
    `endif

    /* signals to ccv afu top-level FSM and debug registers
    */
    `ifdef ALG_1A_SUPPORT_SELF_CHECK
           .o_error_addr_increment   ( alg_1a_error_addr_increment   ),
           .o_error_expected_pattern ( alg_1a_error_expected_pattern ),
           .o_error_received_pattern ( alg_1a_error_received_pattern ),
           .o_error_address          ( alg_1a_error_address          ),
           .o_error_byte_offset      ( alg_1a_error_byte_offset      ),
    `endif

    /*  AXI-MM interface channels
    */  
    `ifdef ALG_1A_SUPPORT_SELF_CHECK
           .o_from_verify_sc_axi_rd_addr ( alg_1a_verify_sc_axi_rd_addr ),
           .o_from_verify_sc_axi_rready  ( alg_1a_verify_sc_axi_rready  ),
           .i_to_verify_sc_axi_arready   ( alg_1a_verify_sc_axi_arready ),
           .i_to_verify_sc_axi_rd_resp   ( alg_1a_verify_sc_axi_rd_resp ),
    `endif

    `ifdef ALG_1A_SUPPORT_NON_SELF_CHECK
           .o_from_verify_nsc_axi_wr_addr ( alg_1a_verify_nsc_axi_wr_addr ),
           .o_from_verify_nsc_axi_wr_data ( alg_1a_verify_nsc_axi_wr_data ),
	   .o_from_verify_nsc_axi_bready  ( alg_1a_verify_nsc_axi_bready  ),
           .o_from_verify_nsc_axi_rd_addr ( alg_1a_verify_nsc_axi_rd_addr ),
           .o_from_verify_nsc_axi_rready  ( alg_1a_verify_nsc_axi_rready  ),
           .i_to_verify_nsc_axi_awready   ( alg_1a_verify_nsc_axi_awready ),
           .i_to_verify_nsc_axi_wready    ( alg_1a_verify_nsc_axi_wready  ),
           .i_to_verify_nsc_axi_wr_resp   ( alg_1a_verify_nsc_axi_wr_resp ),
           .i_to_verify_nsc_axi_arready   ( alg_1a_verify_nsc_axi_arready ),
           .i_to_verify_nsc_axi_rd_resp   ( alg_1a_verify_nsc_axi_rd_resp ),
    `endif

     .o_from_execute_axi_wr_addr ( alg_1a_execute_axi_wr_addr ),
     .o_from_execute_axi_wr_data ( alg_1a_execute_axi_wr_data ),
     .o_from_execute_axi_bready  ( alg_1a_execute_axi_bready  ),
     .i_to_execute_axi_awready   ( alg_1a_execute_axi_awready ),
     .i_to_execute_axi_wready    ( alg_1a_execute_axi_wready  ),
     .i_to_execute_axi_wr_resp   ( alg_1a_execute_axi_wr_resp ),

     /*  signals from configuration and debug registers
     */ 
     .i_addr_increment_value_reg           ( address_increment_reg              ),
     .i_algorithm_reg                      ( algorithm_reg                      ),
     .i_base_pattern_reg                   ( base_pattern_reg                   ),
     .i_base_start_address_reg             ( base_start_address_reg             ),
     .i_base_write_back_address_reg        ( base_write_back_address_reg        ),
     .i_byte_mask_reg                      ( real_byte_mask_reg                 ),
     .i_force_disable_reg                  ( force_disable_afu                  ),
     .i_mode_single_transaction_multi_loop ( mode_single_transaction_multi_loop ),
     .i_mode_single_transaction_one_loop   ( mode_single_transaction_one_loop   ),
     .i_mode_single_transaction_per_set    ( mode_single_transaction_per_set    ),
     .i_number_address_increments_reg      ( number_of_address_incrs_reg        ),
     .i_number_loops_reg                   ( number_of_loops_reg                ),
     .i_number_sets_reg                    ( number_of_sets_reg                 ),
     .i_pattern_parameter_reg              ( pattern_parameter_reg              ),
     .i_pattern_size_reg                   ( pattern_size_reg                   ),
     .i_real_address_increment             ( real_address_increment             ),
     .i_real_set_offset                    ( real_set_offset                    ),
     .i_real_total_transactions_per_set    ( real_total_transactions_per_set    ),
     .i_self_checking_enabled_reg          ( enable_self_checking_reg           ),
     .i_set_offset_reg                     ( address_set_offset_reg             ),
     .i_verify_read_semantics_cache_reg    ( verify_semantics_cache_reg         ),
     .i_write_semantics_cache_reg          ( write_semantics_cache_reg          ),
     .o_current_P                          ( alg_1a_current_base_pattern        ),
     .o_current_X                          ( alg_1a_current_base_address        ),
     .o_loop_count                         ( alg_1a_current_loop_count          ),
     .o_set_count                          ( alg_1a_current_set_count           )
  );
end
endgenerate
//`endif


endmodule
