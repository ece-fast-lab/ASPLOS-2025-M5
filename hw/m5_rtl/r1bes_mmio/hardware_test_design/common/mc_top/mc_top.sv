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
`include "cxl_ed_defines.svh.iv"

module mc_top
  import mc_axi_if_pkg::*;
  import mc_ecc_pkg::*;
#(
   parameter MC_CHANNEL               = 2, // valid options are 1 and 2

   parameter MC_HA_DDR4_ADDR_WIDTH    = 17,
   parameter MC_HA_DDR4_BA_WIDTH      = 2,
   parameter MC_HA_DDR4_BG_WIDTH      = 2,
   parameter MC_HA_DDR4_CK_WIDTH      = 1,
   parameter MC_HA_DDR4_CKE_WIDTH     = 1,
   parameter MC_HA_DDR4_CS_WIDTH      = 1,
   parameter MC_HA_DDR4_ODT_WIDTH     = 1,
   parameter MC_HA_DDR4_DQ_WIDTH      = 72,
 `ifdef ENABLE_DDR_DBI_PINS
   parameter MC_HA_DDR4_DQS_WIDTH      = 9,
   parameter MC_HA_DDR4_DBI_WIDTH      = 9,
 `else 
   parameter MC_HA_DDR4_DQS_WIDTH      = 18,
 `endif    
   
   parameter EMIF_AMM_ADDR_WIDTH      = 27,
   parameter EMIF_AMM_DATA_WIDTH      = 576,
   parameter EMIF_AMM_BURST_WIDTH     = 7,
   parameter EMIF_AMM_BE_WIDTH        = 72,
   parameter REG_ON_REQFIFO_INPUT_EN  = 0, // 0 - OFF; 1 - ON; (1 - adds latency of 1 eclk)
   parameter REG_ON_REQFIFO_OUTPUT_EN = 0, // 0 - OFF; 1 - ON; (1 - adds latency of 1 emif_usr_clk)
   parameter REG_ON_RSPFIFO_OUTPUT_EN = 0, // 0 - OFF; 1 - ON; (1 - adds latency of 1 eclk)

   parameter MC_HA_DP_ADDR_WIDTH      = 46,
   parameter MC_HA_DP_DATA_WIDTH      = 512,
   parameter MC_ECC_EN                = 1, // 0 - OFF; 1 - ON
   parameter MC_ECC_ENC_LATENCY       = 0, // supported option 0 and 1; (latency in emif_usr_clk cycles)
   parameter MC_ECC_DEC_LATENCY       = 1, // supported option 1 and 2; (latency in emif_usr_clk cycles)
   parameter MC_RAM_INIT_W_ZERO_EN    = 1, // 0 - OFF; 1 - ON
   parameter MEMSIZE_WIDTH            = 64,

   // == localparam ==
   localparam MC_MDATA_WIDTH          = 14, // increase of value requires change of rspfifo width in mc_channel_adapter
   localparam MC_SR_STAT_WIDTH        = 5,
   localparam MC_HA_DP_SYMBOL_WIDTH   = 8,
   localparam MC_HA_DP_BE_WIDTH       = MC_HA_DP_DATA_WIDTH / MC_HA_DP_SYMBOL_WIDTH,
   localparam REQFIFO_DEPTH_WIDTH     = 6,
   localparam RSPFIFO_DEPTH_WIDTH     = 6,

   // ==== ALTECC ====
   localparam ALTECC_DATAWORD_WIDTH   = 64,
   localparam ALTECC_WIDTH_CODEWORD   = 72,
   localparam ALTECC_INST_NUMBER      = MC_HA_DP_DATA_WIDTH / ALTECC_DATAWORD_WIDTH,

   //   March 2022 - bringing up from mc_channel_adapter.sv
   localparam RST_REG_NUM             = 2,

   //   March 2022 - brining upt from mc_ecc.sv
   localparam ALTECC_CODEWORD_WIDTH   = 72,
   localparam AVMM_S_DATA_WIDTH       = 512,
   localparam AVMM_M_DATA_WIDTH       = ALTECC_INST_NUMBER * ALTECC_CODEWORD_WIDTH,
  
   // Apirl 2023 - for axi2avmm bridge
   parameter FULL_ADDR_MSB = 51,
   parameter FULL_ADDR_LSB =  6,
  
   // June 2023 - Change for address aliasing for Zsc7
   parameter CHAN_ADDR_MSB = 51,
   parameter CHAN_ADDR_LSB =  6
)
(
  input logic 				  eclk ,
  input logic 				  reset_n_eclk ,

  output logic [MEMSIZE_WIDTH-1:0] 	  mc2ha_memsize , // Size (in bytes) of memory exposed to BIOS (assigned constant value)
  output logic [MC_SR_STAT_WIDTH-1:0] 	  mc_sr_status_eclk [MC_CHANNEL-1:0], // Memory Controller Status
  output  mc_ecc_pkg::mc_err_cnt_t  [MC_CHANNEL-1:0]                mc_err_cnt ,
 
  // April 2023 - Supporting out of order responses with AXI4
   input mc_axi_if_pkg::t_to_mc_axi4   [MC_CHANNEL-1:0] iafu2mc_to_mc_axi4,
  output mc_axi_if_pkg::t_from_mc_axi4 [MC_CHANNEL-1:0] mc2iafu_from_mc_axi4,
 
`ifdef HDM_SIM_CFG_USE_BASIC_MEM
   output logic [EMIF_AMM_ADDR_WIDTH-1:0]    mem_address_rmw_mclk           [MC_CHANNEL-1:0];
 
`endif

    // == DDR4 Interface ==
   input logic [MC_CHANNEL-1:0] mem_refclk, // EMIF PLL reference clock	
  output logic [MC_CHANNEL-1:0] mem_act_n,	
  output logic [MC_CHANNEL-1:0] mem_reset_n,
  output logic [MC_CHANNEL-1:0] mem_par,
   input logic [MC_CHANNEL-1:0] mem_oct_rzqin,
   input logic [MC_CHANNEL-1:0] mem_alert_n,	
	
  output logic [MC_CHANNEL-1:0][MC_HA_DDR4_CK_WIDTH-1:0]   mem_ck, // DDR4 interface signals
  output logic [MC_CHANNEL-1:0][MC_HA_DDR4_CK_WIDTH-1:0]   mem_ck_n,
  output logic [MC_CHANNEL-1:0][MC_HA_DDR4_ADDR_WIDTH-1:0] mem_a,
  output logic [MC_CHANNEL-1:0][MC_HA_DDR4_BA_WIDTH-1:0]   mem_ba,
  output logic [MC_CHANNEL-1:0][MC_HA_DDR4_BG_WIDTH-1:0]   mem_bg,
  output logic [MC_CHANNEL-1:0][MC_HA_DDR4_CKE_WIDTH-1:0]  mem_cke,
  output logic [MC_CHANNEL-1:0][MC_HA_DDR4_CS_WIDTH-1:0]   mem_cs_n,
  output logic [MC_CHANNEL-1:0][MC_HA_DDR4_ODT_WIDTH-1:0]  mem_odt,

  inout wire [MC_CHANNEL-1:0][MC_HA_DDR4_DQS_WIDTH-1:0] mem_dqs,
  inout wire [MC_CHANNEL-1:0][MC_HA_DDR4_DQS_WIDTH-1:0] mem_dqs_n,
  inout wire [MC_CHANNEL-1:0][MC_HA_DDR4_DQ_WIDTH-1:0]  mem_dq,
  inout wire [MC_CHANNEL-1:0][MC_HA_DDR4_DBI_WIDTH-1:0] mem_dbi_n
);

  /*  March 2022 -> signals added when moving Quartus IP modules up from mc_emif.sv
  */
  logic [4095:0]         calbus_seq_param_tbl [MC_CHANNEL-1:0]; // emif_fm_0:calbus_seq_param_tbl -> emif_cal_0:calbus_seq_param_tbl_0
  logic [31:0]           calbus_rdata [MC_CHANNEL-1:0];         // emif_fm_0:calbus_rdata -> emif_cal_0:calbus_rdata_0
  logic [31:0]           calbus_wdata   [MC_CHANNEL-1:0];       // emif_cal_0:calbus_wdata_0 -> emif_fm_0:calbus_wdata
  logic [19:0]           calbus_address [MC_CHANNEL-1:0];       // emif_cal_0:calbus_address_0 -> emif_fm_0:calbus_address
  logic [MC_CHANNEL-1:0] calbus_read;                           // emif_cal_0:calbus_read_0 -> emif_fm_0:calbus_read
  logic [MC_CHANNEL-1:0] calbus_write;                          // emif_cal_0:calbus_write_0 -> emif_fm_0:calbus_write
  logic 		 calbus_clk;                            // emif_cal_0:calbus_clk -> [emif_fm_0:calbus_clk, emif_fm_1:calbus_clk]

  logic [MEMSIZE_WIDTH-1:0]          mc_chan_memsize      [MC_CHANNEL-1:0];
  logic [MC_HA_DP_ADDR_WIDTH-1:0]    mc_baseaddr_cl;
  logic                              mc_baseaddr_cl_vld;

  logic [MC_CHANNEL-1:0]             emif_amm_read;                        //  width = 1,
  logic [MC_CHANNEL-1:0]             emif_amm_write;                       //  width = 1,
  logic [EMIF_AMM_ADDR_WIDTH-1:0]    emif_amm_address    [MC_CHANNEL-1:0]; //  width = 27,
  logic [EMIF_AMM_DATA_WIDTH-1:0]    emif_amm_writedata  [MC_CHANNEL-1:0]; //  width = 576,
  logic [EMIF_AMM_BURST_WIDTH-1:0]   emif_amm_burstcount [MC_CHANNEL-1:0]; //  width = 7,
  logic [EMIF_AMM_BE_WIDTH-1:0]      emif_amm_byteenable [MC_CHANNEL-1:0]; //  width = 72,
  logic [MC_CHANNEL-1:0]             emif_amm_readdatavalid;               //  width = 1,
  logic [MC_CHANNEL-1:0]             emif_amm_ready;                       //  width = 1,
  logic [EMIF_AMM_DATA_WIDTH-1:0]    emif_amm_readdata [MC_CHANNEL-1:0];   //  width = 576

  logic [MC_CHANNEL-1:0]  emif_usr_clk;
  logic [MC_CHANNEL-1:0]  emif_usr_reset_n;
  logic [MC_CHANNEL-1:0]  local_cal_success;
  logic [MC_CHANNEL-1:0]  local_cal_fail;
  logic [MC_CHANNEL-1:0]  local_reset_done;
  logic [MC_CHANNEL-1:0]  pll_ref_clk_out;
  logic [MC_CHANNEL-1:0]  pll_locked;

  /*  March 2022 -> signals added when moving Quartus IP modules up from mc_channel_adapter.sv
  */
  logic [ALTECC_INST_NUMBER-1:0]     mem_ecc_err_corrected_rmw_mclk [MC_CHANNEL-1:0];
  logic [ALTECC_INST_NUMBER-1:0]     mem_ecc_err_detected_rmw_mclk  [MC_CHANNEL-1:0];
  logic [ALTECC_INST_NUMBER-1:0]     mem_ecc_err_fatal_rmw_mclk     [MC_CHANNEL-1:0];
  logic [ALTECC_INST_NUMBER-1:0]     mem_ecc_err_syn_e_rmw_mclk     [MC_CHANNEL-1:0];
  logic [MC_HA_DP_DATA_WIDTH-1:0]    mem_readdata_rmw_mclk          [MC_CHANNEL-1:0];
  logic [MC_HA_DP_DATA_WIDTH-1:0]    mem_writedata_rmw_mclk         [MC_CHANNEL-1:0];
  logic [MC_HA_DP_BE_WIDTH-1:0]      mem_byteenable_rmw_mclk        [MC_CHANNEL-1:0];
  logic [EMIF_AMM_ADDR_WIDTH-1:0]    mem_address_rmw_mclk           [MC_CHANNEL-1:0];

  logic [MC_CHANNEL-1:0]             mem_read_poison_rmw_mclk  ;
  logic [MC_CHANNEL-1:0]             mem_readdatavalid_rmw_mclk;
  logic [MC_CHANNEL-1:0]             mem_ready_rmw_mclk        ;
  logic [MC_CHANNEL-1:0]             mem_write_ras_sbe_mclk    ;
  logic [MC_CHANNEL-1:0]             mem_write_ras_dbe_mclk    ;
  logic [MC_CHANNEL-1:0]             mem_read_rmw_mclk         ;
  logic [MC_CHANNEL-1:0]             mem_write_rmw_mclk        ;
  logic [MC_CHANNEL-1:0]             mem_write_poison_rmw_mclk ;

  // reqfifo
  localparam REQFIFO_DATA_WIDTH = 640;
  logic [REQFIFO_DATA_WIDTH-1:0]    reqfifo_data_in_eclk    [MC_CHANNEL-1:0];
  logic [REQFIFO_DATA_WIDTH-1:0]    reqfifo_data_out_mclk   [MC_CHANNEL-1:0];
  logic [REQFIFO_DEPTH_WIDTH-1:0]   reqfifo_wrusedw_eclk    [MC_CHANNEL-1:0];

  logic [MC_CHANNEL-1:0]            reqfifo_wen_eclk;
  logic [MC_CHANNEL-1:0]            reqfifo_ren_mclk;
  logic [MC_CHANNEL-1:0]            reqfifo_empty_mclk;

  // rspfifo
  localparam RSPFIFO_DATA_WIDTH = 560;
  logic [RSPFIFO_DATA_WIDTH-1:0]    rspfifo_data_in_mclk  [MC_CHANNEL-1:0];
  logic [RSPFIFO_DATA_WIDTH-1:0]    rspfifo_data_out_eclk [MC_CHANNEL-1:0];

  logic [MC_CHANNEL-1:0]            rspfifo_wen_mclk;
  logic [MC_CHANNEL-1:0]            rspfifo_ren_eclk;
  logic [MC_CHANNEL-1:0]            rspfifo_full_mclk;

  logic [RST_REG_NUM-1:0]           emif_usr_reset_n_reg [MC_CHANNEL-1:0];
  

  // reqfifo
  logic [MC_CHANNEL-1:0] 	        reqfifo_full_eclk;
  logic [MC_CHANNEL-1:0] 	        reqfifo_empty_eclk;
  logic [REQFIFO_DEPTH_WIDTH-1:0] reqfifo_fill_level_eclk [MC_CHANNEL-1:0];
 
  // rspfifo
  logic [MC_CHANNEL-1:0] 	        rspfifo_full_eclk;
  logic [MC_CHANNEL-1:0] 	        rspfifo_empty_eclk;
  logic [RSPFIFO_DEPTH_WIDTH-1:0] rspfifo_fill_level_eclk [MC_CHANNEL-1:0];
	
`ifdef INCLUDE_CXLMEM_READY
    logic [MC_CHANNEL-1:0] cxlmem_ready;
`endif

  mc_ecc_pkg::mc_devmem_if_t  [MC_CHANNEL-1:0]  mc_devmem_if, mc_devmem_if_tmgstg1_in, mc_devmem_if_tmgstg1_q;
// ====================================================================================================================
/* April 2023 - support for out of order resposnes via AXI4
 */
`ifndef T1IP
  `ifdef OOORSP_MC_AXI2AVMM
     // == MC <--> iAFU signals ==
     logic [MC_CHANNEL-1:0] iafu2mc_read_eclk; // AVMM read request from iAFU
     logic [MC_CHANNEL-1:0] iafu2mc_write_eclk; // AVMM write request from iAFU
     logic [MC_CHANNEL-1:0] iafu2mc_write_poison_eclk; // AVMM write poison from iAFU
     logic [MC_CHANNEL-1:0] iafu2mc_write_ras_sbe_eclk; // AVMM write poison from iAFU
     logic [MC_CHANNEL-1:0] iafu2mc_write_ras_dbe_eclk; // AVMM write poison from iAFU
   
     logic [MC_CHANNEL-1:0] mc2iafu_ready_eclk; // AVMM ready to iAFU   
     logic [MC_CHANNEL-1:0] mc2iafu_read_poison_eclk; //  width = 1,
     logic [MC_CHANNEL-1:0] mc2iafu_readdatavalid_eclk; // AVMM read data valid to iAFU
   
     logic [MC_HA_DP_ADDR_WIDTH-1:0] iafu2mc_address_eclk    [MC_CHANNEL-1:0]; // AVMM address from iAFU
     logic [MC_MDATA_WIDTH-1:0] 	 iafu2mc_req_mdata_eclk  [MC_CHANNEL-1:0]; // AVMM reqeust MDATA  from iAFU
     logic [MC_HA_DP_DATA_WIDTH-1:0] iafu2mc_writedata_eclk  [MC_CHANNEL-1:0]; // AVMM write data from iAFU
     logic [MC_HA_DP_BE_WIDTH-1:0]   iafu2mc_byteenable_eclk [MC_CHANNEL-1:0]; // AVMM byte enable from iAFU

     logic [MC_HA_DP_DATA_WIDTH-1:0] mc2iafu_readdata_eclk  [MC_CHANNEL-1:0]; // AVMM read data to iAFU
     logic [MC_MDATA_WIDTH-1:0]      mc2iafu_rsp_mdata_eclk [MC_CHANNEL-1:0]; // AVMM response MDATA to iAFU

     // Error Correction Code (ECC)
     // Note *ecc_err_* are valid when mc2iafu_ecc_err_valid_eclk == 1
     // If both mc2iafu_readdatavalid_eclk == 1 and mc2iafu_ecc_err_valid_eclk == 1
     //   then *ecc_err_* are related to mc2iafu_readdata_eclk
     // If mc2iafu_readdatavalid_eclk == 0 and mc2iafu_ecc_err_valid_eclk == 1
     //   then *ecc_err_* are related to partial write. "Partial write" functionality is realised as read-modify-write function.
     //   Readdata for this read is kept internal (not visible on mc_top output), but ECC statuses are provided.
     logic [ALTECC_INST_NUMBER-1:0] mc2iafu_ecc_err_corrected_eclk [MC_CHANNEL-1:0];
     logic [ALTECC_INST_NUMBER-1:0] mc2iafu_ecc_err_detected_eclk  [MC_CHANNEL-1:0];
     logic [ALTECC_INST_NUMBER-1:0] mc2iafu_ecc_err_fatal_eclk     [MC_CHANNEL-1:0];
     logic [ALTECC_INST_NUMBER-1:0] mc2iafu_ecc_err_syn_e_eclk     [MC_CHANNEL-1:0];
     logic [MC_CHANNEL-1:0] 	    mc2iafu_ecc_err_valid_eclk;

     // convert to packed
     logic [MC_CHANNEL-1:0][MC_HA_DP_ADDR_WIDTH-1:0]    address_eclk; // out of axi2avmm
     logic [MC_CHANNEL-1:0][MC_MDATA_WIDTH-1:0]       req_mdata_eclk; // out of axi2avmm
     logic [MC_CHANNEL-1:0][MC_HA_DP_DATA_WIDTH-1:0]  writedata_eclk; // out of axi2avmm
     logic [MC_CHANNEL-1:0][MC_HA_DP_BE_WIDTH-1:0]   byteenable_eclk; // out of axi2avmm
   
     logic [MC_CHANNEL-1:0][MC_HA_DP_DATA_WIDTH-1:0]         readdata_eclk; // in to axi2avmm
     logic [MC_CHANNEL-1:0][MC_MDATA_WIDTH-1:0]             rsp_mdata_eclk; // in to axi2avmm
     //logic [MC_CHANNEL-1:0][REQFIFO_DEPTH_WIDTH-1:0] reqFifoFillLevel_eclk; // in to axi2avmm

     logic [MC_CHANNEL-1:0][ALTECC_INST_NUMBER-1:0] ecc_err_corrected_eclk; // in to axi2avmm
     logic [MC_CHANNEL-1:0][ALTECC_INST_NUMBER-1:0] ecc_err_detected_eclk;  // in to axi2avmm
     logic [MC_CHANNEL-1:0][ALTECC_INST_NUMBER-1:0] ecc_err_fatal_eclk;     // in to axi2avmm
     logic [MC_CHANNEL-1:0][ALTECC_INST_NUMBER-1:0] ecc_err_syn_e_eclk;     // in to axi2avmm

     generate
     begin : gen_packed_structs
       always_comb
       begin
         for( integer mc = 0 ; mc < MC_CHANNEL ; mc=mc+1 )
	     begin
              iafu2mc_address_eclk[mc] =    address_eclk[mc];
            iafu2mc_req_mdata_eclk[mc] =  req_mdata_eclk[mc];
            iafu2mc_writedata_eclk[mc] =  writedata_eclk[mc];
           iafu2mc_byteenable_eclk[mc] = byteenable_eclk[mc];

		           readdata_eclk[mc] =   mc2iafu_readdata_eclk[mc];
                  rsp_mdata_eclk[mc] =  mc2iafu_rsp_mdata_eclk[mc];
           //reqFifoFillLevel_eclk[mc] = reqfifo_fill_level_eclk[mc];
		 
		   ecc_err_corrected_eclk[mc] = mc2iafu_ecc_err_corrected_eclk[mc];
		    ecc_err_detected_eclk[mc] =  mc2iafu_ecc_err_detected_eclk[mc];
		       ecc_err_fatal_eclk[mc] =     mc2iafu_ecc_err_fatal_eclk[mc];
		       ecc_err_syn_e_eclk[mc] =     mc2iafu_ecc_err_syn_e_eclk[mc];
	     end // end for
       end   // end always
     end     // end gen
     endgenerate
   
   axi2avmm_bridge
   #(
     .NUM_MC_CHANS     ( MC_CHANNEL ),
     .REQ_MDATA_BW     ( MC_MDATA_WIDTH ),
     .DATA_BW          ( MC_HA_DP_DATA_WIDTH ),
     .DATA_BE_BW       ( MC_HA_DP_BE_WIDTH ),
     .FULL_ADDR_MSB    ( FULL_ADDR_MSB ),
     .FULL_ADDR_LSB    ( FULL_ADDR_LSB ),
     .CHAN_ADDR_MSB    ( CHAN_ADDR_MSB ),
     .CHAN_ADDR_LSB    ( CHAN_ADDR_LSB ),
     .REQFIFO_DEPTH_BW ( REQFIFO_DEPTH_WIDTH ),
     .ALTECC_INST_BW   ( ALTECC_INST_NUMBER )   
    )
   inst_axi2avmm_bridge
   (
      .ip_clk   ( eclk ),
      .ip_rst_n ( reset_n_eclk ),

      /* AXI4 signals
       */
      .i_to_mc_axi4   ( iafu2mc_to_mc_axi4   ),
      .o_from_mc_axi4 ( mc2iafu_from_mc_axi4 ),
	  
      /* AVMM signals to MC logic
       */
      .o_avmm_read          ( iafu2mc_read_eclk ),
      .o_avmm_write         ( iafu2mc_write_eclk ),
      .o_avmm_write_poison  ( iafu2mc_write_poison_eclk ),
      .o_avmm_write_ras_sbe ( iafu2mc_write_ras_sbe_eclk ),
      .o_avmm_write_ras_dbe ( iafu2mc_write_ras_dbe_eclk ),
      .o_avmm_req_mdata     ( req_mdata_eclk ),
      .o_avmm_writedata     ( writedata_eclk ),
      .o_avmm_byteenable    ( byteenable_eclk ),
      .o_avmm_address       ( address_eclk ),

      /* AVMM signals from MC logic
         Error Correction Code (ECC)
         Note *ecc_err_* are valid when iafu2cxlip_readdatavalid_eclk is active
       */
	  `ifdef INCLUDE_CXLMEM_READY
         .i_avmm_ready              ( cxlmem_ready ),	  
	  `else
	     .i_avmm_ready              ( mc2iafu_ready_eclk ),
	  `endif

      .i_avmm_read_poison        ( mc2iafu_read_poison_eclk ),
      .i_avmm_ecc_err_valid      ( mc2iafu_ecc_err_valid_eclk ),
      .i_avmm_readdatavalid      ( mc2iafu_readdatavalid_eclk ),
      //.i_avmm_reqfifo_full       ( reqfifo_full_eclk ),
      .i_avmm_rsp_mdata          ( rsp_mdata_eclk ),
      .i_avmm_readdata           ( readdata_eclk ),
      //.i_avmm_reqfifo_fill_level ( reqFifoFillLevel_eclk ),
      .i_avmm_ecc_err_corrected  ( ecc_err_corrected_eclk ),
      .i_avmm_ecc_err_syn_e      ( ecc_err_syn_e_eclk ),
      .i_avmm_ecc_err_fatal      ( ecc_err_fatal_eclk ),
      .i_avmm_ecc_err_detected   ( ecc_err_detected_eclk )
   );
  `endif
`endif

  /*  March 2022 -> signals added when moving Quartus IP modules up from mc_ecc.sv
  */
  logic [AVMM_M_DATA_WIDTH-1:0]  ecc_in_avmm_s_writedata_w_ecc [MC_CHANNEL-1:0];
  logic [AVMM_S_DATA_WIDTH-1:0]  ecc_in_avmm_s_readdata        [MC_CHANNEL-1:0];

  assign mc_baseaddr_cl = '0;
  assign mc_baseaddr_cl_vld = 1'b1;

  always_comb 
  begin
    mc2ha_memsize = 0;
    for (int i=0; i<MC_CHANNEL; i=i+1)
    begin
      mc2ha_memsize = mc2ha_memsize + mc_chan_memsize[i];
    end
  end

  generate   // generate for channel adapter
  for( genvar chanCount = 0; chanCount < MC_CHANNEL; chanCount=chanCount+1 )
  begin : GEN_CHAN_COUNT_CHAN_ADAPT

    `ifdef INCLUDE_CXLMEM_READY
        mc_cxlmem_ready_control     mc_cxlmem_ready_control_inst       // "interface" logic handling the ready flag to the bbs
        (
            .clk                                     ( eclk                               ),
            .reset_al                                ( reset_n_eclk                       ),
            .from_mc_ch_adpt_mc2iafu_ready_eclk      ( mc2iafu_ready_eclk[chanCount]      ),
            .from_mc_ch_adpt_reqfifo_full_eclk       ( reqfifo_full_eclk[chanCount]       ),
            .from_mc_ch_adpt_reqfifo_empty_eclk      ( reqfifo_empty_eclk[chanCount]      ),
            .from_mc_ch_adpt_reqfifo_fill_level_eclk ( reqfifo_fill_level_eclk[chanCount] ),
            .to_bbs_cxlmem_ready                     ( cxlmem_ready[chanCount]            )
        );
     `endif

    mc_channel_adapter 
    #(
      .MC_HA_DP_ADDR_WIDTH      (MC_HA_DP_ADDR_WIDTH     ),
      .MC_HA_DP_DATA_WIDTH      (MC_HA_DP_DATA_WIDTH     ),
      .MC_ECC_EN                (MC_ECC_EN               ),
      .MC_ECC_ENC_LATENCY       (MC_ECC_ENC_LATENCY      ),
      .MC_ECC_DEC_LATENCY       (MC_ECC_DEC_LATENCY      ),
      .MC_RAM_INIT_W_ZERO_EN    (MC_RAM_INIT_W_ZERO_EN   ),
      .EMIF_AMM_ADDR_WIDTH      (EMIF_AMM_ADDR_WIDTH     ),
      .EMIF_AMM_DATA_WIDTH      (EMIF_AMM_DATA_WIDTH     ),
      .EMIF_AMM_BURST_WIDTH     (EMIF_AMM_BURST_WIDTH    ),
      .EMIF_AMM_BE_WIDTH        (EMIF_AMM_BE_WIDTH       ),
      .REG_ON_REQFIFO_INPUT_EN  (REG_ON_REQFIFO_INPUT_EN ),
      .REG_ON_REQFIFO_OUTPUT_EN (REG_ON_REQFIFO_OUTPUT_EN),
      .REG_ON_RSPFIFO_OUTPUT_EN (REG_ON_RSPFIFO_OUTPUT_EN)
    )
    mc_channel_adapter_inst 
    (
      .eclk                         (eclk                          ), // input,    width = 1,
      .reset_n_eclk                 (reset_n_eclk                  ), // input,    width = 1,

      .mc_baseaddr_cl               (mc_baseaddr_cl                ), 
      .mc_baseaddr_cl_vld           (mc_baseaddr_cl_vld            ), //                      mc_ha     : Base address registers have been set

      // iAFU signals
      .mc2iafu_ready_eclk         ( mc2iafu_ready_eclk[chanCount]          ), //  input,   width = 1,
      .iafu2mc_read_eclk          ( iafu2mc_read_eclk[chanCount]           ), // output,   width = 1,
      .iafu2mc_write_eclk         ( iafu2mc_write_eclk[chanCount]          ), // output,   width = 1,
      .iafu2mc_write_poison_eclk  ( iafu2mc_write_poison_eclk[chanCount]   ), // output,   width = 1,
      .iafu2mc_write_ras_sbe_eclk ( iafu2mc_write_ras_sbe_eclk[chanCount]  ), // output,   width = 1,
      .iafu2mc_write_ras_dbe_eclk ( iafu2mc_write_ras_dbe_eclk[chanCount]  ), // output,   width = 1,
      .iafu2mc_address_eclk       ( iafu2mc_address_eclk[chanCount]        ), // output,   width = 46,
      .iafu2mc_req_mdata_eclk     ( iafu2mc_req_mdata_eclk[chanCount]      ), // output,   width = 46,
      .mc2iafu_readdata_eclk      ( mc2iafu_readdata_eclk[chanCount]       ), //  input,   width = 512,
      .mc2iafu_rsp_mdata_eclk     ( mc2iafu_rsp_mdata_eclk[chanCount]      ), //  input,   width = 512,
      .iafu2mc_writedata_eclk     ( iafu2mc_writedata_eclk[chanCount]      ), // output,   width = 512,
      .iafu2mc_byteenable_eclk    ( iafu2mc_byteenable_eclk[chanCount]     ), // output,   width = 64,
      .mc2iafu_read_poison_eclk   ( mc2iafu_read_poison_eclk[chanCount]    ), // output,   width = 1,
      .mc2iafu_readdatavalid_eclk ( mc2iafu_readdatavalid_eclk[chanCount]  ), //  input,   width = 1,

      // Error Correction Code (ECC)
      .mc2iafu_ecc_err_corrected_eclk( mc2iafu_ecc_err_corrected_eclk[chanCount] ),
      .mc2iafu_ecc_err_detected_eclk ( mc2iafu_ecc_err_detected_eclk[chanCount]  ),
      .mc2iafu_ecc_err_fatal_eclk    ( mc2iafu_ecc_err_fatal_eclk[chanCount]     ),
      .mc2iafu_ecc_err_syn_e_eclk    ( mc2iafu_ecc_err_syn_e_eclk[chanCount]     ),
      .mc2iafu_ecc_err_valid_eclk    ( mc2iafu_ecc_err_valid_eclk[chanCount]     ),

      .emif_usr_clk                  (emif_usr_clk[chanCount]                 ),
      .emif_usr_reset_n              (emif_usr_reset_n[chanCount]             ),
      .emif_pll_locked               (pll_locked[chanCount]              ),
      .emif_reset_done               (local_reset_done[chanCount]              ),
      .emif_cal_success              (local_cal_success[chanCount]             ),
      .emif_cal_fail                 (local_cal_fail[chanCount]                ),

      .mc_sr_status_eclk             (mc_sr_status_eclk[chanCount]            ), // output,

      .mem_ecc_err_corrected_rmw_mclk ( mem_ecc_err_corrected_rmw_mclk[chanCount] ),
      .mem_ecc_err_detected_rmw_mclk  ( mem_ecc_err_detected_rmw_mclk[chanCount]  ),
      .mem_ecc_err_fatal_rmw_mclk     ( mem_ecc_err_fatal_rmw_mclk[chanCount]     ),
      .mem_ecc_err_syn_e_rmw_mclk     ( mem_ecc_err_syn_e_rmw_mclk[chanCount]     ),
      .mem_read_poison_rmw_mclk       ( mem_read_poison_rmw_mclk[chanCount]       ),
      .mem_readdatavalid_rmw_mclk     ( mem_readdatavalid_rmw_mclk[chanCount]     ),
      .mem_readdata_rmw_mclk          ( mem_readdata_rmw_mclk[chanCount]          ),
      .mem_ready_rmw_mclk             ( mem_ready_rmw_mclk[chanCount]             ),
      .mem_writedata_rmw_mclk         ( mem_writedata_rmw_mclk[chanCount]         ),
      .mem_byteenable_rmw_mclk        ( mem_byteenable_rmw_mclk[chanCount]        ),
      .mem_write_ras_sbe_mclk         ( mem_write_ras_sbe_mclk[chanCount]         ),
      .mem_write_ras_dbe_mclk         ( mem_write_ras_dbe_mclk[chanCount]         ),
      .mem_address_rmw_mclk           ( mem_address_rmw_mclk[chanCount]           ),
      .mem_read_rmw_mclk              ( mem_read_rmw_mclk[chanCount]              ),
      .mem_write_rmw_mclk             ( mem_write_rmw_mclk[chanCount]             ),
      .mem_write_poison_rmw_mclk      ( mem_write_poison_rmw_mclk[chanCount]      ),

      .reqfifo_data_in_eclk    ( reqfifo_data_in_eclk[chanCount]    ),
      .reqfifo_data_out_mclk   ( reqfifo_data_out_mclk[chanCount]   ),
      .reqfifo_wen_eclk        ( reqfifo_wen_eclk[chanCount]        ),
      .reqfifo_ren_mclk        ( reqfifo_ren_mclk[chanCount]        ),
      .reqfifo_empty_mclk      ( reqfifo_empty_mclk[chanCount]      ),
      .reqfifo_wrusedw_eclk    ( reqfifo_wrusedw_eclk[chanCount]    ),
      .reqfifo_full_eclk       ( reqfifo_full_eclk[chanCount]       ),
      .reqfifo_empty_eclk      ( reqfifo_empty_eclk[chanCount]      ),
      .reqfifo_fill_level_eclk ( reqfifo_fill_level_eclk[chanCount] ),

      .rspfifo_data_in_mclk    ( rspfifo_data_in_mclk[chanCount]  ),
      .rspfifo_data_out_eclk   ( rspfifo_data_out_eclk[chanCount] ),
      .rspfifo_wen_mclk        ( rspfifo_wen_mclk[chanCount]      ),
      .rspfifo_ren_eclk        ( rspfifo_ren_eclk[chanCount]      ),
      .rspfifo_full_mclk       ( rspfifo_full_mclk[chanCount]     ),
      .rspfifo_empty_eclk      ( rspfifo_empty_eclk[chanCount]    ),

      .emif_usr_reset_n_reg    ( emif_usr_reset_n_reg[chanCount] )
    );

  end   // for( genvar chanCount = 0; chanCount < MC_CHANNEL; chanCount=chanCount+1 )
  endgenerate   // generate for channel adapter

  // ==============================================================================================
  `ifndef INCLUDE_CXLMEM_READY
     logic [MC_CHANNEL-1:0] reqfifo_full_eclk_tmp;
  `endif
  
  generate  // generate for reqfifo and rspfifo
  for( genvar chanCount = 0; chanCount < MC_CHANNEL; chanCount=chanCount+1 )
  begin : GEN_CHAN_COUNT_REG_RSP_FIFO
    
    `ifndef INCLUDE_CXLMEM_READY
       assign reqfifo_full_eclk[chanCount] = reqfifo_full_eclk_tmp[chanCount] | ( reqfifo_wrusedw_eclk[chanCount] >= 'd62 );
    `endif
	   
    //width = 640; depth=64
    reqfifo  reqfifo_inst
    (
       .data    ( reqfifo_data_in_eclk[chanCount]  ), //  input,  width = 640,  fifo_input.datain
       .wrreq   ( reqfifo_wen_eclk[chanCount]      ), //  input,  width = 1,              .wrreq
       .rdreq   ( reqfifo_ren_mclk[chanCount]      ), //  input,  width = 1,              .rdreq
       .wrclk   ( eclk                             ), //  input,  width = 1,              .wrclk
       .rdclk   ( emif_usr_clk[chanCount]          ), //  input,  width = 1,              .rdclk
       .aclr    ( ~reset_n_eclk                    ), //  input,  width = 1,              .aclr
       .q       ( reqfifo_data_out_mclk[chanCount] ), //  output, width = 640, fifo_output.dataout
       .wrusedw ( reqfifo_wrusedw_eclk[chanCount]  ), //  output, width = 6,              .wrusedw
       .rdempty ( reqfifo_empty_mclk[chanCount]    ), //  output, width = 1,              .rdempty
	 
	   `ifdef INCLUDE_CXLMEM_READY
         .wrfull  ( reqfifo_full_eclk[chanCount]     ), //  output, width = 1,              .wrfull
	   `else
	     .wrfull  ( reqfifo_full_eclk_tmp[chanCount] ),
	   `endif
	 
       .wrempty ( reqfifo_empty_eclk[chanCount]    )  //  output, width = 1,              .wrempty
    );
 
    //width = 560; depth=64
    rspfifo   rspfifo_inst 
    (
       .data    ( rspfifo_data_in_mclk[chanCount]    ), //  input,   width = 560,  fifo_input.datain
       .wrreq   ( rspfifo_wen_mclk[chanCount]        ), //  input,   width = 1,              .wrreq
       .rdreq   ( rspfifo_ren_eclk[chanCount]        ), //  input,   width = 1,              .rdreq
       .wrclk   ( emif_usr_clk[chanCount]            ), //  input,   width = 1,              .wrclk
       .rdclk   ( eclk                               ), //  input,   width = 1,              .rdclk
       .aclr    ( ~reset_n_eclk                      ), //  input,   width = 1,              .aclr
       .q       ( rspfifo_data_out_eclk[chanCount]   ), //  output,  width = 560, fifo_output.dataout
       .rdusedw ( rspfifo_fill_level_eclk[chanCount] ), //  output,  width = 6,              .rdusedw
       .rdfull  ( rspfifo_full_eclk[chanCount]       ), //  output,  width = 1,              .rdfull
       .rdempty ( rspfifo_empty_eclk[chanCount]      ), //  output,  width = 1,              .rdempty
       .wrfull  ( rspfifo_full_mclk[chanCount]       )  //  output,  width = 1,              .wrfull
    );

  end   // for( genvar chanCount = 0; chanCount < MC_CHANNEL; chanCount=chanCount+1 )
  endgenerate   // generate for reqfifo and rspfifo

  generate     // generate for mc_ecc inst
  if (MC_ECC_EN == 1) 
  begin : GEN_ECC_ON

    for( genvar chanCount = 0; chanCount < MC_CHANNEL; chanCount=chanCount+1 )
    begin : GEN_CHAN_COUNT_ECC_ON

      mc_ecc #(
         .MC_ECC_EN          (MC_ECC_EN           ),
         .MC_ECC_ENC_LATENCY (MC_ECC_ENC_LATENCY  ),
         .MC_ECC_DEC_LATENCY (MC_ECC_DEC_LATENCY  ),
         .AVMM_ADDR_WIDTH    (EMIF_AMM_ADDR_WIDTH ),
         .AVMM_S_DATA_WIDTH  (MC_HA_DP_DATA_WIDTH )
      )
      mc_ecc_inst
      (
          .clk                     (emif_usr_clk[chanCount]                        ), // input  logic
          .reset_n                 (emif_usr_reset_n_reg[chanCount][RST_REG_NUM-1] ), // input  logic

          .avmm_s_ready            (mem_ready_rmw_mclk[chanCount]             ), // output logic
          .avmm_s_read             (mem_read_rmw_mclk[chanCount]              ), // input  logic
          .avmm_s_write            (mem_write_rmw_mclk[chanCount]             ), // input  logic
          .avmm_s_write_poison     (mem_write_poison_rmw_mclk[chanCount]      ), // input  logic
          .avmm_s_write_ras_sbe    (mem_write_ras_sbe_mclk[chanCount]         ), // input  logic
          .avmm_s_write_ras_dbe    (mem_write_ras_dbe_mclk[chanCount]         ), // input  logic
          .avmm_s_address          (mem_address_rmw_mclk[chanCount]           ), // input  logic [AVMM_S_ADDR_WIDTH-1:0]
          .avmm_s_readdata         (mem_readdata_rmw_mclk[chanCount]          ), // output logic [AVMM_S_DATA_WIDTH-1:0]
          .avmm_s_writedata        (mem_writedata_rmw_mclk[chanCount]         ), // input  logic [AVMM_S_DATA_WIDTH-1:0]
          .avmm_s_byteenable       (mem_byteenable_rmw_mclk[chanCount]        ), // input  logic [AVMM_S_BE_WIDTH-1:0]
          .avmm_s_read_poison      (mem_read_poison_rmw_mclk[chanCount]       ), // output logic
          .avmm_s_readdatavalid    (mem_readdatavalid_rmw_mclk[chanCount]     ), // output logic

//          .avmm_s_ecc_err_corrected(mem_ecc_err_corrected_rmw_mclk[chanCount] ), // output logic [ALTECC_INST_NUMBER-1:0]
//          .avmm_s_ecc_err_detected (mem_ecc_err_detected_rmw_mclk[chanCount]  ), // output logic [ALTECC_INST_NUMBER-1:0]
          .avmm_s_ecc_err_fatal    (mem_ecc_err_fatal_rmw_mclk[chanCount]     ), // output logic [ALTECC_INST_NUMBER-1:0]
//          .avmm_s_ecc_err_syn_e    (mem_ecc_err_syn_e_rmw_mclk[chanCount]     ), // output logic [ALTECC_INST_NUMBER-1:0]

          .avmm_m_ready            (emif_amm_ready[chanCount]         ), // input  logic
          .avmm_m_read             (emif_amm_read[chanCount]          ), // output logic
          .avmm_m_write            (emif_amm_write[chanCount]         ), // output logic
          .avmm_m_address          (emif_amm_address[chanCount]       ), // output logic [AVMM_M_ADDR_WIDTH-1:0]
          .avmm_m_writedata        (emif_amm_writedata[chanCount]     ), // output logic [AVMM_M_DATA_WIDTH-1:0]
          .avmm_m_byteenable       (emif_amm_byteenable[chanCount]    ), // output logic [AVMM_M_BE_WIDTH-1:0]
          .avmm_m_readdata         (emif_amm_readdata[chanCount]      ), // input  logic [AVMM_M_DATA_WIDTH-1:0]
          .avmm_m_readdatavalid    (emif_amm_readdatavalid[chanCount] ), // input  logic

          .in_avmm_s_writedata_w_ecc ( ecc_in_avmm_s_writedata_w_ecc[chanCount] ),
          .in_avmm_s_readdata        ( ecc_in_avmm_s_readdata[chanCount]        )
      );

    end   // for( genvar chanCount = 0; chanCount < MC_CHANNEL; chanCount=chanCount+1 ) 
  end   // if (MC_ECC_EN == 1) 
  else begin : GEN_ECC_OFF

    for( genvar chanCount = 0; chanCount < MC_CHANNEL; chanCount=chanCount+1 )
    begin : GEN_CHAN_COUNT_ECC_OFF

        always_comb 
        begin
          // == to emif ==
            emif_amm_read[ chanCount ]       = mem_read_rmw_mclk[    chanCount ];
            emif_amm_write[ chanCount ]      = mem_write_rmw_mclk[   chanCount ];
            emif_amm_address[ chanCount ]    = mem_address_rmw_mclk[ chanCount ];
            emif_amm_byteenable[ chanCount ] = '1;

            emif_amm_writedata[ chanCount ][MC_HA_DP_DATA_WIDTH-1:0]                     = mem_writedata_rmw_mclk[    chanCount ];
            emif_amm_writedata[ chanCount ][MC_HA_DP_DATA_WIDTH]                         = mem_write_poison_rmw_mclk[ chanCount ];
            emif_amm_writedata[ chanCount ][EMIF_AMM_DATA_WIDTH-1:MC_HA_DP_DATA_WIDTH+1] = '0;

          // == from emif ==
            mem_ready_rmw_mclk[chanCount]              = emif_amm_ready[chanCount] ;

          // ==== releaded to read response ====
            mem_readdata_rmw_mclk[ chanCount ]       = emif_amm_readdata[ chanCount ][MC_HA_DP_DATA_WIDTH-1:0];
            mem_read_poison_rmw_mclk[ chanCount ]    = emif_amm_readdata[ chanCount ][MC_HA_DP_DATA_WIDTH];
            mem_readdatavalid_rmw_mclk[ chanCount ]  = emif_amm_readdatavalid[ chanCount ] ;
        end

        always_comb 
        begin
            mem_ecc_err_corrected_rmw_mclk[ chanCount ] = '0;
            mem_ecc_err_detected_rmw_mclk[ chanCount ]  = '0;
            mem_ecc_err_fatal_rmw_mclk[ chanCount ]     = '0;
            mem_ecc_err_syn_e_rmw_mclk[ chanCount ]     = '0;
        end

    end   // for( genvar chanCount = 0; chanCount < MC_CHANNEL; chanCount=chanCount+1 ) 
  end   // if (MC_ECC_EN != 1) 
  endgenerate   // generate for mc_ecc inst 

  generate   // generate emif_amm_burstcount
    for( genvar chanCount = 0; chanCount < MC_CHANNEL; chanCount=chanCount+1 )
    begin : GEN_CHAN_COUNT_BURSTCOUNT

      assign emif_amm_burstcount[ chanCount ] = {{EMIF_AMM_BURST_WIDTH-1{1'b0}},1'b1};

    end
  endgenerate   // generate emif_amm_burstcount

  generate     // generate for ecc enc latency 9
    if (MC_ECC_EN == 1) 
    begin : GEN_ECC_ENC_LATENCY_0
      for( genvar chanCount = 0; chanCount < MC_CHANNEL; chanCount=chanCount+1 )
      begin : GEN_ECC_ENC_LATENCY_0_chanCount
        for( genvar alteccCount = 0; alteccCount < ALTECC_INST_NUMBER; alteccCount=alteccCount+1 )
        begin : GEN_ECC_ENC_LATENCY_0_alteccCount

            altecc_enc_latency0   altecc_enc_latency0_inst
            (
               .data ( mem_writedata_rmw_mclk[chanCount][alteccCount*ALTECC_DATAWORD_WIDTH +: ALTECC_DATAWORD_WIDTH] ),        //   input,  width = 64, data.data
               .q    ( ecc_in_avmm_s_writedata_w_ecc[chanCount][alteccCount*ALTECC_CODEWORD_WIDTH +: ALTECC_CODEWORD_WIDTH] )  //  output,  width = 72,    q.q
            );

        end      // end GEN_ECC_ENC_LATENCY_0_alteccCount
      end        // end GEN_ECC_ENC_LATENCY_0_chanCount
    end          // end GEN_ECC_ENC_LATENCY_0
  endgenerate    // generate for ecc enc latency 9

  generate   // generate for ecc dec latency 1-2
    if ( (MC_ECC_EN == 1) && (MC_ECC_DEC_LATENCY == 1) )
    begin : GEN_ECC_DEC_LATENCY_1
       for( genvar chanCount = 0; chanCount < MC_CHANNEL; chanCount=chanCount+1 )
       begin : GEN_ECC_DEC_LATENCY_1_chanCount
          for( genvar alteccCount = 0; alteccCount < ALTECC_INST_NUMBER; alteccCount=alteccCount+1 )
          begin : GEN_ECC_DEC_LATENCY_1_alteccCount

            altecc_dec_latency1   altecc_dec_latency1_inst 
            (
              .data          ( emif_amm_readdata[chanCount][alteccCount*ALTECC_CODEWORD_WIDTH +: ALTECC_CODEWORD_WIDTH] ),      //  input,  width = 72, data.data
              .q             ( ecc_in_avmm_s_readdata[chanCount][alteccCount*ALTECC_DATAWORD_WIDTH +: ALTECC_DATAWORD_WIDTH] ), // output,  width = 64, q.q
              .err_corrected ( mem_ecc_err_corrected_rmw_mclk[chanCount][alteccCount] ),                                            // output,   width = 1, err_corrected.err_corrected
              .err_detected  ( mem_ecc_err_detected_rmw_mclk[chanCount][alteccCount]  ),                                            // output,   width = 1,  err_detected.err_detected
              .err_fatal     ( mem_ecc_err_fatal_rmw_mclk[chanCount][alteccCount]     ),                                            // output logic [ALTECC_INST_NUMBER-1:0]
              .syn_e         ( mem_ecc_err_syn_e_rmw_mclk[chanCount][alteccCount]     ),                                            // output logic [ALTECC_INST_NUMBER-1:0]
              .clock         ( emif_usr_clk[chanCount]                              )
            );

          end      // end GEN_ECC_DEC_LATENCY_1_alteccCount
       end        // end GEN_ECC_DEC_LATENCY_1_chanCount
    end          // end GEN_ECC_DEC_LATENCY_1
    else if ( (MC_ECC_EN == 1) && (MC_ECC_DEC_LATENCY == 2) )
    begin : GEN_ECC_DEC_LATENCY_2
       for( genvar chanCount = 0; chanCount < MC_CHANNEL; chanCount=chanCount+1 )
       begin : GEN_ECC_DEC_LATENCY_2_chanCount
          for( genvar alteccCount = 0; alteccCount < ALTECC_INST_NUMBER; alteccCount=alteccCount+1 )
          begin : GEN_ECC_DEC_LATENCY_2_alteccCount

            altecc_dec_latency2   altecc_dec_inst 
            (
              .data          ( emif_amm_readdata[chanCount][(alteccount * ALTECC_CODEWORD_WIDTH) +: ALTECC_CODEWORD_WIDTH] ),      //  input,  width = 72, data.data
              .q             ( ecc_in_avmm_s_readdata[chanCount][(alteccCount * ALTECC_DATAWORD_WIDTH) +: ALTECC_DATAWORD_WIDTH] ), // output,  width = 64, q.q
              .err_corrected ( mem_ecc_err_corrected_rmw_mclk[chanCount][alteccCount] ),                                            // output,   width = 1, err_corrected.err_corrected
              .err_detected  ( mem_ecc_err_detected_rmw_mclk[chanCount][alteccCount]  ),                                            // output,   width = 1,  err_detected.err_detected
              .err_fatal     ( mem_ecc_err_fatal_rmw_mclk[chanCount][alteccCount]     ),                                            // output logic [ALTECC_INST_NUMBER-1:0]
              .syn_e         ( mem_ecc_err_syn_e_rmw_mclk[chanCount][alteccCount]     ),                                            // output logic [ALTECC_INST_NUMBER-1:0]
              .clock         ( emif_usr_clk[chanCount]                              )
            );

          end      // end GEN_ECC_DEC_LATENCY_2_alteccCount
       end        // end GEN_ECC_DEC_LATENCY_2_chanCount
    end          // end GEN_ECC_DEC_LATENCY_2
  endgenerate    // generate for ecc dec latency 1-2

///////////////////////////////       March 2022 - modules that were down in mc_emif.sv but moved up for mpib branch
`ifndef REVB_DEVKIT
  
  generate for( genvar chanCount = 0; chanCount < MC_CHANNEL; chanCount=chanCount+1 )
  begin : GEN_CHAN_COUNT_EMIF
        //    assign mc_chan_memsize[chanCount] = 64'h20_0000_0000;  // 128 GB
        //    assign mc_chan_memsize[chanCount] = 64'h8_0000_0000;  // 32 GB
        //    assign mc_chan_memsize[chanCount] = 64'h2_0000_0000;  // 8 GB
        // == memory channel size in bytes (assuming 512 bit words, not counting 64 ECC bits) ==
        assign mc_chan_memsize[chanCount] = 2**EMIF_AMM_ADDR_WIDTH << 6;  // shift left by 6 as each row has 64 bytes

        emif   emif_inst 
        (
           .oct_rzqin            (mem_oct_rzqin[chanCount] ),        //   input,     width = 1,                oct.oct_rzqin
           .mem_ck               (mem_ck[chanCount]        ),        //  output,     width = 1,                mem.mem_ck
           .mem_ck_n             (mem_ck_n[chanCount]      ),        //  output,     width = 1,                   .mem_ck_n
           .mem_a                (mem_a[chanCount]         ),        //  output,    width = 17,                   .mem_a
           .mem_act_n            (mem_act_n[chanCount]     ),        //  output,     width = 1,                   .mem_act_n
           .mem_ba               (mem_ba[chanCount]        ),        //  output,     width = 2,                   .mem_ba
           .mem_bg               (mem_bg[chanCount]        ),        //  output,     width = 2,                   .mem_bg
           .mem_cke              (mem_cke[chanCount]       ),        //  output,     width = 2,                   .mem_cke
           .mem_cs_n             (mem_cs_n[chanCount]      ),        //  output,     width = 2,                   .mem_cs_n
           .mem_odt              (mem_odt[chanCount]       ),        //  output,     width = 2,                   .mem_odt
           .mem_reset_n          (mem_reset_n[chanCount]   ),        //  output,     width = 1,                   .mem_reset_n
           .mem_par              (mem_par[chanCount]       ),        //  output,     width = 1,                   .mem_par
           .mem_alert_n          (mem_alert_n[chanCount]   ),        //   input,     width = 1,                   .mem_alert_n
           .mem_dqs              (mem_dqs[chanCount]       ),        //   inout,     width = 9,                   .mem_dqs
           .mem_dqs_n            (mem_dqs_n[chanCount]     ),        //   inout,     width = 9,                   .mem_dqs_n
           .mem_dq               (mem_dq[chanCount]        ),        //   inout,    width = 72,                   .mem_dq
           .mem_dbi_n            (mem_dbi_n[chanCount]     ),        //   inout,     width = 9,                   .mem_dbi_n

           .pll_ref_clk          (mem_refclk[chanCount]      ),      //   input,     width = 1,        pll_ref_clk.clk
           .pll_ref_clk_out      (pll_ref_clk_out[chanCount] ),      //  output,     width = 1,    pll_ref_clk_out.clk
           .pll_locked           (pll_locked[chanCount]      ),      //  output,     width = 1,         pll_locked.pll_locked

           .local_reset_req      (1'b0),                             //   input,     width = 1,    local_reset_req.local_reset_req
           .local_reset_done     (local_reset_done[chanCount]  ),    //  output,     width = 1, local_reset_status.local_reset_done
           .local_cal_success    (local_cal_success[chanCount] ),    //  output,     width = 1,             status.local_cal_success
           .local_cal_fail       (local_cal_fail[chanCount]    ),    //  output,     width = 1,                   .local_cal_fail

           .emif_usr_reset_n     (emif_usr_reset_n[chanCount]  ),    //  output,     width = 1,   emif_usr_reset_n.reset_n
           .emif_usr_clk         (emif_usr_clk[chanCount]      ),    //  output,     width = 1,       emif_usr_clk.clk

           .amm_read_0           (emif_amm_read[chanCount]          ),    //   input,     width = 1,                   .read
           .amm_write_0          (emif_amm_write[chanCount]         ),    //   input,     width = 1,                   .write
           .amm_address_0        (emif_amm_address[chanCount]       ),    //   input,    width = 27,                   .address
           .amm_writedata_0      (emif_amm_writedata[chanCount]     ),    //   input,   width = 576,                   .writedata
           .amm_burstcount_0     (emif_amm_burstcount[chanCount]    ),    //   input,     width = 7,                   .burstcount
           .amm_byteenable_0     (emif_amm_byteenable[chanCount]    ),    //   input,    width = 72,                   .byteenable
           .amm_ready_0          (emif_amm_ready[chanCount]         ),    //  output,     width = 1,         ctrl_amm_0.waitrequest_n
           .amm_readdata_0       (emif_amm_readdata[chanCount]      ),    //  output,   width = 576,                   .readdata
           .amm_readdatavalid_0  (emif_amm_readdatavalid[chanCount] ),    //  output,     width = 1,                   .readdatavalid

           .calbus_read          (calbus_read[chanCount]          ),  //   input,     width = 1,        emif_calbus.calbus_read
           .calbus_write         (calbus_write[chanCount]         ),  //   input,     width = 1,                   .calbus_write
           .calbus_address       (calbus_address[chanCount]       ),  //   input,    width = 20,                   .calbus_address
           .calbus_wdata         (calbus_wdata[chanCount]         ),  //   input,    width = 32,                   .calbus_wdata
           .calbus_clk           (calbus_clk                      ),  //   input,     width = 1,    emif_calbus_clk.clk
           .calbus_rdata         (calbus_rdata[chanCount]         ),  //  output,    width = 32,                   .calbus_rdata
           .calbus_seq_param_tbl (calbus_seq_param_tbl[chanCount] )   //  output,  width = 4096,                   .calbus_seq_param_tbl
        );
  end
  endgenerate

`else  // ifndef REVB_DEVKIT

  generate for( genvar chanCount = 0; chanCount < MC_CHANNEL; chanCount=chanCount+1 )
  begin : GEN_CHAN_COUNT_EMIF
    //    assign mc_chan_memsize[chanCount] = 64'h20_0000_0000;  // 128 GB
    //    assign mc_chan_memsize[chanCount] = 64'h8_0000_0000;  // 32 GB
    //    assign mc_chan_memsize[chanCount] = 64'h2_0000_0000;  // 8 GB
    // == memory channel size in bytes (assuming 512 bit words, not counting 64 ECC bits) ==
    assign mc_chan_memsize[chanCount] = 2**EMIF_AMM_ADDR_WIDTH << 6;  // shift left by 6 as each row has 64 bytes
    
    if (chanCount == 0)
    begin: NON_HPS_MEM

        emif   emif_inst 
        (
           .oct_rzqin            (mem_oct_rzqin[chanCount] ),        //   input,     width = 1,                oct.oct_rzqin
           .mem_ck               (mem_ck[chanCount]        ),        //  output,     width = 1,                mem.mem_ck
           .mem_ck_n             (mem_ck_n[chanCount]      ),        //  output,     width = 1,                   .mem_ck_n
           .mem_a                (mem_a[chanCount]         ),        //  output,    width = 17,                   .mem_a
           .mem_act_n            (mem_act_n[chanCount]     ),        //  output,     width = 1,                   .mem_act_n
           .mem_ba               (mem_ba[chanCount]        ),        //  output,     width = 2,                   .mem_ba
           .mem_bg               (mem_bg[chanCount]        ),        //  output,     width = 2,                   .mem_bg
           .mem_cke              (mem_cke[chanCount]       ),        //  output,     width = 2,                   .mem_cke
           .mem_cs_n             (mem_cs_n[chanCount]      ),        //  output,     width = 2,                   .mem_cs_n
           .mem_odt              (mem_odt[chanCount]       ),        //  output,     width = 2,                   .mem_odt
           .mem_reset_n          (mem_reset_n[chanCount]   ),        //  output,     width = 1,                   .mem_reset_n
           .mem_par              (mem_par[chanCount]       ),        //  output,     width = 1,                   .mem_par
           .mem_alert_n          (mem_alert_n[chanCount]   ),        //   input,     width = 1,                   .mem_alert_n
           .mem_dqs              (mem_dqs[chanCount]       ),        //   inout,     width = 9,                   .mem_dqs
           .mem_dqs_n            (mem_dqs_n[chanCount]     ),        //   inout,     width = 9,                   .mem_dqs_n
           .mem_dq               (mem_dq[chanCount]        ),        //   inout,    width = 72,                   .mem_dq
         `ifdef ENABLE_DDR_DBI_PINS
           .mem_dbi_n            (mem_dbi_n[chanCount]),                                    //   inout,     width = 9,                   .mem_dbi_n
         `endif
           .pll_ref_clk          (mem_refclk[chanCount]      ),      //   input,     width = 1,        pll_ref_clk.clk
           .pll_ref_clk_out      (pll_ref_clk_out[chanCount] ),      //  output,     width = 1,    pll_ref_clk_out.clk
           .pll_locked           (pll_locked[chanCount]      ),      //  output,     width = 1,         pll_locked.pll_locked

           .local_reset_req      (1'b0),                             //   input,     width = 1,    local_reset_req.local_reset_req
           .local_reset_done     (local_reset_done[chanCount]  ),    //  output,     width = 1, local_reset_status.local_reset_done
           .local_cal_success    (local_cal_success[chanCount] ),    //  output,     width = 1,             status.local_cal_success
           .local_cal_fail       (local_cal_fail[chanCount]    ),    //  output,     width = 1,                   .local_cal_fail

           .emif_usr_reset_n     (emif_usr_reset_n[chanCount]  ),    //  output,     width = 1,   emif_usr_reset_n.reset_n
           .emif_usr_clk         (emif_usr_clk[chanCount]      ),    //  output,     width = 1,       emif_usr_clk.clk

           .amm_read_0           (emif_amm_read[chanCount]          ),    //   input,     width = 1,                   .read
           .amm_write_0          (emif_amm_write[chanCount]         ),    //   input,     width = 1,                   .write
           .amm_address_0        (emif_amm_address[chanCount]       ),    //   input,    width = 27,                   .address
           .amm_writedata_0      (emif_amm_writedata[chanCount]     ),    //   input,   width = 576,                   .writedata
           .amm_burstcount_0     (emif_amm_burstcount[chanCount]    ),    //   input,     width = 7, 
         `ifdef ENABLE_DDR_DBI_PINS
           .amm_byteenable_0     (emif_amm_byteenable[chanCount]),          //   input,    width = 72,                   .byteenable
         `endif          
           .amm_ready_0          (emif_amm_ready[chanCount]         ),    //  output,     width = 1,         ctrl_amm_0.waitrequest_n
           .amm_readdata_0       (emif_amm_readdata[chanCount]      ),    //  output,   width = 576,                   .readdata
           .amm_readdatavalid_0  (emif_amm_readdatavalid[chanCount] ),    //  output,     width = 1,                   .readdatavalid

           .calbus_read          (calbus_read[chanCount]          ),  //   input,     width = 1,        emif_calbus.calbus_read
           .calbus_write         (calbus_write[chanCount]         ),  //   input,     width = 1,                   .calbus_write
           .calbus_address       (calbus_address[chanCount]       ),  //   input,    width = 20,                   .calbus_address
           .calbus_wdata         (calbus_wdata[chanCount]         ),  //   input,    width = 32,                   .calbus_wdata
           .calbus_clk           (calbus_clk                      ),  //   input,     width = 1,    emif_calbus_clk.clk
           .calbus_rdata         (calbus_rdata[chanCount]         ),  //  output,    width = 32,                   .calbus_rdata
           .calbus_seq_param_tbl (calbus_seq_param_tbl[chanCount] )   //  output,  width = 4096,                   .calbus_seq_param_tbl
        );

    end
    if (chanCount == 1)
    begin : HPS_MEM

		emif2   emif_inst_2 
        (
           .oct_rzqin            (mem_oct_rzqin[chanCount] ),        //   input,     width = 1,                oct.oct_rzqin
           .mem_ck               (mem_ck[chanCount]        ),        //  output,     width = 1,                mem.mem_ck
           .mem_ck_n             (mem_ck_n[chanCount]      ),        //  output,     width = 1,                   .mem_ck_n
           .mem_a                (mem_a[chanCount]         ),        //  output,    width = 17,                   .mem_a
           .mem_act_n            (mem_act_n[chanCount]     ),        //  output,     width = 1,                   .mem_act_n
           .mem_ba               (mem_ba[chanCount]        ),        //  output,     width = 2,                   .mem_ba
           .mem_bg               (mem_bg[chanCount]        ),        //  output,     width = 2,                   .mem_bg
           .mem_cke              (mem_cke[chanCount]       ),        //  output,     width = 2,                   .mem_cke
           .mem_cs_n             (mem_cs_n[chanCount]      ),        //  output,     width = 2,                   .mem_cs_n
           .mem_odt              (mem_odt[chanCount]       ),        //  output,     width = 2,                   .mem_odt
           .mem_reset_n          (mem_reset_n[chanCount]   ),        //  output,     width = 1,                   .mem_reset_n
           .mem_par              (mem_par[chanCount]       ),        //  output,     width = 1,                   .mem_par
           .mem_alert_n          (mem_alert_n[chanCount]   ),        //   input,     width = 1,                   .mem_alert_n
           .mem_dqs              (mem_dqs[chanCount]       ),        //   inout,     width = 9,                   .mem_dqs
           .mem_dqs_n            (mem_dqs_n[chanCount]     ),        //   inout,     width = 9,                   .mem_dqs_n
           .mem_dq               (mem_dq[chanCount]        ),        //   inout,    width = 72,                   .mem_dq
         `ifdef ENABLE_DDR_DBI_PINS
           .mem_dbi_n            (mem_dbi_n[chanCount]),                                    //   inout,     width = 9,                   .mem_dbi_n
         `endif
           .pll_ref_clk          (mem_refclk[chanCount]      ),      //   input,     width = 1,        pll_ref_clk.clk
           //.pll_ref_clk_out      (pll_ref_clk_out[chanCount] ),      //  output,     width = 1,    pll_ref_clk_out.clk
           .pll_locked           (pll_locked[chanCount]      ),      //  output,     width = 1,         pll_locked.pll_locked

           .local_reset_req      (1'b0),                             //   input,     width = 1,    local_reset_req.local_reset_req
           .local_reset_done     (local_reset_done[chanCount]  ),    //  output,     width = 1, local_reset_status.local_reset_done
           .local_cal_success    (local_cal_success[chanCount] ),    //  output,     width = 1,             status.local_cal_success
           .local_cal_fail       (local_cal_fail[chanCount]    ),    //  output,     width = 1,                   .local_cal_fail

           .emif_usr_reset_n     (emif_usr_reset_n[chanCount]  ),    //  output,     width = 1,   emif_usr_reset_n.reset_n
           .emif_usr_clk         (emif_usr_clk[chanCount]      ),    //  output,     width = 1,       emif_usr_clk.clk

           .amm_read_0           (emif_amm_read[chanCount]          ),    //   input,     width = 1,                   .read
           .amm_write_0          (emif_amm_write[chanCount]         ),    //   input,     width = 1,                   .write
           .amm_address_0        (emif_amm_address[chanCount]       ),    //   input,    width = 27,                   .address
           .amm_writedata_0      (emif_amm_writedata[chanCount]     ),    //   input,   width = 576,                   .writedata
           .amm_burstcount_0     (emif_amm_burstcount[chanCount]    ),    //   input,     width = 7, 
         `ifdef ENABLE_DDR_DBI_PINS
           .amm_byteenable_0     (emif_amm_byteenable[chanCount]),          //   input,    width = 72,                   .byteenable
         `endif          
           .amm_ready_0          (emif_amm_ready[chanCount]         ),    //  output,     width = 1,         ctrl_amm_0.waitrequest_n
           .amm_readdata_0       (emif_amm_readdata[chanCount]      ),    //  output,   width = 576,                   .readdata
           .amm_readdatavalid_0  (emif_amm_readdatavalid[chanCount] ),    //  output,     width = 1,                   .readdatavalid

           .calbus_read          (calbus_read[chanCount]          ),  //   input,     width = 1,        emif_calbus.calbus_read
           .calbus_write         (calbus_write[chanCount]         ),  //   input,     width = 1,                   .calbus_write
           .calbus_address       (calbus_address[chanCount]       ),  //   input,    width = 20,                   .calbus_address
           .calbus_wdata         (calbus_wdata[chanCount]         ),  //   input,    width = 32,                   .calbus_wdata
           .calbus_clk           (calbus_clk                      ),  //   input,     width = 1,    emif_calbus_clk.clk
           .calbus_rdata         (calbus_rdata[chanCount]         ),  //  output,    width = 32,                   .calbus_rdata
           .calbus_seq_param_tbl (calbus_seq_param_tbl[chanCount] )   //  output,  width = 4096,                   .calbus_seq_param_tbl
        );
    end
  end
  endgenerate

`endif  // ifndef REVB_DEVKIT

generate if (MC_CHANNEL == 1) 
begin : GEN_CAL_ONE_MEM_CHANNEL
        emif_cal_one_ch  emif_cal_one_ch_inst 
        (
            .calbus_clk             (calbus_clk              ),  //  output,     width = 1, emif_calbus_clk.clk
            .calbus_read_0          (calbus_read[0]          ),  //  output,     width = 1,   emif_calbus_0.calbus_read
            .calbus_write_0         (calbus_write[0]         ),  //  output,     width = 1,                .calbus_write
            .calbus_address_0       (calbus_address[0]       ),  //  output,    width = 20,                .calbus_address
            .calbus_wdata_0         (calbus_wdata[0]         ),  //  output,    width = 32,                .calbus_wdata
            .calbus_rdata_0         (calbus_rdata[0]         ),  //   input,    width = 32,                .calbus_rdata
            .calbus_seq_param_tbl_0 (calbus_seq_param_tbl[0] )   //   input,  width = 4096,                .calbus_seq_param_tbl
        );
end
else begin : GEN_CAL_TWO_MEM_CHANNELS
        emif_cal_two_ch  emif_cal_two_ch_inst 
        (
            .calbus_clk             (calbus_clk              ),  //  output,     width = 1, emif_calbus_clk.clk

            .calbus_read_0          (calbus_read[0]          ),  //  output,     width = 1,   emif_calbus_0.calbus_read
            .calbus_write_0         (calbus_write[0]         ),  //  output,     width = 1,                .calbus_write
            .calbus_address_0       (calbus_address[0]       ),  //  output,    width = 20,                .calbus_address
            .calbus_wdata_0         (calbus_wdata[0]         ),  //  output,    width = 32,                .calbus_wdata
            .calbus_rdata_0         (calbus_rdata[0]         ),  //   input,    width = 32,                .calbus_rdata
            .calbus_seq_param_tbl_0 (calbus_seq_param_tbl[0] ),  //   input,  width = 4096,                .calbus_seq_param_tbl

            .calbus_read_1          (calbus_read[1]          ),  //  output,     width = 1,   emif_calbus_1.calbus_read
            .calbus_write_1         (calbus_write[1]         ),  //  output,     width = 1,                .calbus_write
            .calbus_address_1       (calbus_address[1]       ),  //  output,    width = 20,                .calbus_address
            .calbus_wdata_1         (calbus_wdata[1]         ),  //  output,    width = 32,                .calbus_wdata
            .calbus_rdata_1         (calbus_rdata[1]         ),  //   input,    width = 32,                .calbus_rdata
            .calbus_seq_param_tbl_1 (calbus_seq_param_tbl[1] )   //   input,  width = 4096,                .calbus_seq_param_tbl
        );
    end
  endgenerate



//------------------------
//   SBE/DBE CNT 
//------------------------
//


  //--------------------------------------------------------------------
  // DDR Memory Controller Interface
  //--------------------------------------------------------------------

  always_comb begin
    for (int i=0; i<MC_CHANNEL; i++) begin
      {mc_devmem_if_tmgstg1_in[i].RdData.Data.Data1, mc_devmem_if_tmgstg1_in[i].RdData.Data.Data0} = mc2iafu_readdata_eclk[i];
      mc_devmem_if_tmgstg1_in[i].RdData.Poison        = mc2iafu_read_poison_eclk[i];
      mc_devmem_if_tmgstg1_in[i].RdData.MetaField     = mc_ecc_pkg::M2S_METAFIELD_NOOP;
      mc_devmem_if_tmgstg1_in[i].RdData.MetaValue     = mc_ecc_pkg::M2S_METAVALUE_INVALID;
      mc_devmem_if_tmgstg1_in[i].RdData.EventTriggerB = '0;
      mc_devmem_if_tmgstg1_in[i].RdDataECC.SBE        = mc2iafu_ecc_err_corrected_eclk[i] | mc2iafu_ecc_err_syn_e_eclk[i];
      mc_devmem_if_tmgstg1_in[i].RdDataECC.DBE        = mc2iafu_ecc_err_fatal_eclk[i];
      mc_devmem_if_tmgstg1_in[i].RdDataECC.Valid      = mc2iafu_ecc_err_valid_eclk[i];
      mc_devmem_if_tmgstg1_in[i].RdDataValid          = mc2iafu_readdatavalid_eclk[i];
      mc_devmem_if_tmgstg1_in[i].McReady              = mc2iafu_ready_eclk[i];  // ~ReqFifoFull & RamInitDone
      mc_devmem_if_tmgstg1_in[i].CdcWrFifoUsedW       = {1'b0, reqfifo_fill_level_eclk[i]};
      mc_devmem_if_tmgstg1_in[i].CdcWrFifoFull        = reqfifo_full_eclk[i];
      mc_devmem_if_tmgstg1_in[i].CdcWrFifoEmpty       = reqfifo_empty_eclk[i];
      mc_devmem_if_tmgstg1_in[i].cxlmem_ready         = cxlmem_ready[i];  // user defined & controlled memory controller ready flag
    end
  end
  // Add register stage for timing
  always_ff @(posedge eclk) begin
    mc_devmem_if_tmgstg1_q <= mc_devmem_if_tmgstg1_in;
  end

  assign mc_devmem_if = mc_devmem_if_tmgstg1_q;


    for (genvar numb=0; numb < MC_CHANNEL; numb++) begin : NumDev
   
       	    mc_devmem_top  mc_devmem_top_inst 
        (
            .clk             (eclk     ),  
            .rst             (~reset_n_eclk     ),  
            .mc_devmem_if    (mc_devmem_if[numb ]     ),  
            .mc_err_cnt      (mc_err_cnt[numb] )   
    );

    end






endmodule
