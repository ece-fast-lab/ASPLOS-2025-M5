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

module mc_channel_adapter 
#(
parameter  MC_HA_DP_ADDR_WIDTH       = 46,
parameter  MC_HA_DP_DATA_WIDTH       = 512,
parameter  MC_ECC_EN                 = 0, // 0 - OFF; 1 - ON
parameter  MC_ECC_ENC_LATENCY        = 0, // supported option 0 and 1; (latency in emif_usr_clk cycles)
parameter  MC_ECC_DEC_LATENCY        = 1, // supported option 1 and 2; (latency in emif_usr_clk cycles)
parameter  MC_RAM_INIT_W_ZERO_EN     = 1, // 0 - OFF; 1 - ON
parameter  EMIF_AMM_ADDR_WIDTH       = 27,
parameter  EMIF_AMM_DATA_WIDTH       = 576,
parameter  EMIF_AMM_BURST_WIDTH      = 7,
parameter  EMIF_AMM_BE_WIDTH         = 72,
parameter  REG_ON_REQFIFO_INPUT_EN   = 0, // 0 - OFF; 1 - ON; (1 - adds latency of 1 eclk)
parameter  REG_ON_REQFIFO_OUTPUT_EN  = 0, // 0 - OFF; 1 - ON; (1 - adds latency of 1 emif_usr_clk)
parameter  REG_ON_RSPFIFO_OUTPUT_EN  = 0, // 0 - OFF; 1 - ON; (1 - adds latency of 1 eclk)

// == localparam ==
localparam MC_MDATA_WIDTH            = 14, // increase of value requires change of rspfifo width
// ==== ALTECC ====
localparam ALTECC_DATAWORD_WIDTH     = 64,
localparam ALTECC_CODEWORD_WIDTH     = 72,
localparam ALTECC_INST_NUMBER        = MC_HA_DP_DATA_WIDTH / ALTECC_DATAWORD_WIDTH,

localparam MC_HA_DP_SYMBOL_WIDTH     = 8,
localparam MC_HA_DP_BE_WIDTH         = MC_HA_DP_DATA_WIDTH / MC_HA_DP_SYMBOL_WIDTH,

// Note below FIFO plocalparams are not changing real fifo parameters.
// To change real fifo parameters use IP Paremeter Editor
// DATA WIDTH of REQFIFO (640) is set wider than actually needed, to avoid change of fifo IP settings
//   for cases when DDR4 DIMM memory of other (bigger) size is used
localparam REQFIFO_DEPTH_WIDTH         = 6,
localparam REQFIFO_DATA_WIDTH          = 640,
localparam RSPFIFO_DEPTH_WIDTH         = 6,
localparam RSPFIFO_DATA_WIDTH          = 560,
localparam MC_SR_STAT_WIDTH            = 5,
// define a bits of mc_sr_status_eclk
localparam MC_SR_STAT_EMIF_CAL_FAIL    = 0,
localparam MC_SR_STAT_EMIF_CAL_SUCCESS = 1,
localparam MC_SR_STAT_EMIF_RESET_DONE  = 2,
localparam MC_SR_STAT_EMIF_PLL_LOCKED  = 3,
localparam MC_SR_STAT_RAM_INIT_DONE    = 4,
localparam RST_REG_NUM                 = 2
)
(
input  logic                            eclk                       , // input,    width = 1,
input  logic                            reset_n_eclk               , // input,    width = 1,

input  logic [MC_HA_DP_ADDR_WIDTH-1:0]  mc_baseaddr_cl             , // input,    width = 46
input  logic                            mc_baseaddr_cl_vld         , // input,    width = 1

output logic                            mc2iafu_ready_eclk         ,
input  logic                            iafu2mc_read_eclk          ,
input  logic                            iafu2mc_write_eclk         ,
input  logic                            iafu2mc_write_poison_eclk  ,
input  logic                            iafu2mc_write_ras_sbe_eclk ,
input  logic                            iafu2mc_write_ras_dbe_eclk ,
input  logic [MC_HA_DP_ADDR_WIDTH-1:0]  iafu2mc_address_eclk       ,
input  logic [MC_MDATA_WIDTH-1:0]       iafu2mc_req_mdata_eclk     ,
output logic [MC_HA_DP_DATA_WIDTH-1:0]  mc2iafu_readdata_eclk      ,
output logic [MC_MDATA_WIDTH-1:0]       mc2iafu_rsp_mdata_eclk     ,
input  logic [MC_HA_DP_DATA_WIDTH-1:0]  iafu2mc_writedata_eclk     ,
input  logic [MC_HA_DP_BE_WIDTH-1:0]    iafu2mc_byteenable_eclk    ,
output logic                            mc2iafu_read_poison_eclk   ,
output logic                            mc2iafu_readdatavalid_eclk ,
// Error Correction Code (ECC)
// Note *ecc_err_* are valid when mc2iafu_ecc_err_valid_eclk == 1
// If both mc2iafu_readdatavalid_eclk == 1 and mc2iafu_ecc_err_valid_eclk == 1
//   then *ecc_err_* are related to mc2iafu_readdata_eclk
// If mc2iafu_readdatavalid_eclk == 0 and mc2iafu_ecc_err_valid_eclk == 1
//   then *ecc_err_* are related to partial write. "Partial write" functionality is realised as read-modify-write function.
//   Readdata for this read is kept internal (not visible on mc_channel_adapter output), but ECC statuses are provided.
output logic [ALTECC_INST_NUMBER-1:0]   mc2iafu_ecc_err_corrected_eclk ,
output logic [ALTECC_INST_NUMBER-1:0]   mc2iafu_ecc_err_detected_eclk  ,
output logic [ALTECC_INST_NUMBER-1:0]   mc2iafu_ecc_err_fatal_eclk     ,
output logic [ALTECC_INST_NUMBER-1:0]   mc2iafu_ecc_err_syn_e_eclk     ,
output logic                            mc2iafu_ecc_err_valid_eclk     ,

input  logic                            emif_usr_clk               , // EMIF User Clock
input  logic                            emif_usr_reset_n           , // EMIF reset
input  logic                            emif_pll_locked            ,
input  logic                            emif_reset_done            ,
input  logic                            emif_cal_success           ,
input  logic                            emif_cal_fail              ,

output logic [MC_SR_STAT_WIDTH-1:0]     mc_sr_status_eclk          ,

  input logic [ALTECC_INST_NUMBER-1:0]     mem_ecc_err_corrected_rmw_mclk,
  input logic [ALTECC_INST_NUMBER-1:0]     mem_ecc_err_detected_rmw_mclk ,
  input logic [ALTECC_INST_NUMBER-1:0]     mem_ecc_err_fatal_rmw_mclk    ,
  input logic [ALTECC_INST_NUMBER-1:0]     mem_ecc_err_syn_e_rmw_mclk    ,
  input logic                              mem_read_poison_rmw_mclk      ,
  input logic                              mem_readdatavalid_rmw_mclk    ,
  input logic [MC_HA_DP_DATA_WIDTH-1:0]    mem_readdata_rmw_mclk         ,
  input logic                              mem_ready_rmw_mclk            ,

  output logic [MC_HA_DP_DATA_WIDTH-1:0]   mem_writedata_rmw_mclk       ,
  output logic [MC_HA_DP_BE_WIDTH-1:0]     mem_byteenable_rmw_mclk      ,
  output logic                             mem_write_ras_sbe_mclk       ,
  output logic                             mem_write_ras_dbe_mclk       ,
  output logic [EMIF_AMM_ADDR_WIDTH-1:0]   mem_address_rmw_mclk         ,
  output logic                             mem_read_rmw_mclk            ,
  output logic                             mem_write_rmw_mclk           ,
  output logic                             mem_write_poison_rmw_mclk    ,

  // reqfifo
  output logic [REQFIFO_DATA_WIDTH-1:0]    reqfifo_data_in_eclk    ,
  input  logic [REQFIFO_DATA_WIDTH-1:0]    reqfifo_data_out_mclk   ,
  output logic                             reqfifo_wen_eclk        ,
  output logic                             reqfifo_ren_mclk        ,
  input  logic                             reqfifo_empty_mclk      ,
  input  logic [REQFIFO_DEPTH_WIDTH-1:0]   reqfifo_wrusedw_eclk    ,
  input  logic                             reqfifo_full_eclk       ,
  input  logic                             reqfifo_empty_eclk      ,
  output logic [REQFIFO_DEPTH_WIDTH-1:0]   reqfifo_fill_level_eclk ,

  // rspfifo
  output logic [RSPFIFO_DATA_WIDTH-1:0]    rspfifo_data_in_mclk  ,
  input  logic [RSPFIFO_DATA_WIDTH-1:0]    rspfifo_data_out_eclk ,
  output logic                             rspfifo_wen_mclk      ,
  output logic                             rspfifo_ren_eclk      ,
  input  logic                             rspfifo_full_mclk     ,
  input  logic                             rspfifo_empty_eclk    ,

  output logic [RST_REG_NUM-1:0]           emif_usr_reset_n_reg
    );
    
  logic [6:0]   rd_cntr;

  typedef struct packed {
    logic                            write;
    logic                            partial_write;
    logic                            read;
    logic [MC_HA_DP_DATA_WIDTH-1:0]  writedata;
    logic                            write_poison;
    logic [MC_HA_DP_BE_WIDTH-1:0]    byteenable;
    logic [EMIF_AMM_ADDR_WIDTH-1:0]  address;
    logic [MC_MDATA_WIDTH-1:0]       req_mdata;
    logic                            write_ras_sbe;
    logic                            write_ras_dbe;    
  } req_data_t;

  localparam REQ_DATA_T_WIDTH = $bits(req_data_t);
  req_data_t       req_data_in_eclk;
  req_data_t       req_data_out_mclk;

  typedef struct packed {
    logic                            read_poison;
    logic [ALTECC_INST_NUMBER-1:0]   ecc_err_corrected;
    logic [ALTECC_INST_NUMBER-1:0]   ecc_err_detected;
    logic [ALTECC_INST_NUMBER-1:0]   ecc_err_fatal;
    logic [ALTECC_INST_NUMBER-1:0]   ecc_err_syn_e;
    logic [MC_MDATA_WIDTH-1:0]       rsp_mdata;
    logic [MC_HA_DP_DATA_WIDTH-1:0]  readdata;
    logic                            readdatavalid;
  } rspfifo_data_t;

  rspfifo_data_t   rspfifo_data_in_mclk_intf;
  rspfifo_data_t   rspfifo_data_out_eclk_intf;

  logic emif_reset_done_eclk;

logic emif_cal_success_eclk, emif_cal_fail_eclk, emif_pll_locked_eclk;
logic ram_init_done_mclk, ram_init_done_eclk;
logic [EMIF_AMM_ADDR_WIDTH-1:0] ram_init_addr_mclk;

logic [MC_HA_DP_DATA_WIDTH-1:0] mem_writedata_mclk, mem_readdata_mclk;
logic [MC_HA_DP_ADDR_WIDTH-1:0] iafu2mc_address_minus_baseaddr_eclk;
logic [EMIF_AMM_ADDR_WIDTH-1:0] mem_address_mclk;
logic [MC_MDATA_WIDTH-1:0]      mem_req_mdata_mclk, mem_rsp_mdata_mclk;
logic [MC_HA_DP_BE_WIDTH-1:0]   mem_byteenable_mclk;
logic                           mem_ready_mclk, mem_read_mclk, mem_write_mclk;
logic                           mem_readdatavalid_mclk;
logic                           mem_write_poison_mclk, mem_read_poison_mclk;
 
logic [ALTECC_INST_NUMBER-1:0]  mem_ecc_err_corrected_mclk;
logic [ALTECC_INST_NUMBER-1:0]  mem_ecc_err_detected_mclk;
logic [ALTECC_INST_NUMBER-1:0]  mem_ecc_err_fatal_mclk;
logic [ALTECC_INST_NUMBER-1:0]  mem_ecc_err_syn_e_mclk;
logic                           mem_ecc_err_valid_mclk;

logic iafu2mc_write_or_read_active;
logic mem_write_partial_mclk;

logic [MC_HA_DP_BE_WIDTH-1:0]   byteenable_all_ones;

//logic [RST_REG_NUM-1:0] emif_usr_reset_n_reg;

generate
   if (RST_REG_NUM == 1) begin : rst_reg_num_one

      always_ff @(posedge emif_usr_clk) begin
         emif_usr_reset_n_reg <= emif_usr_reset_n;
      end

   end
   else begin : rst_reg_num_more_than_one

      always_ff @(posedge emif_usr_clk) begin
         emif_usr_reset_n_reg <= {emif_usr_reset_n_reg[RST_REG_NUM-2:0],emif_usr_reset_n};
      end

   end
endgenerate

////-----------------------------------------------------------------------------------------------------
//// Status signals combined into single bus to make it easier to add/remove status bits later.
////-----------------------------------------------------------------------------------------------------
always_ff @(posedge eclk) begin
   mc_sr_status_eclk[ MC_SR_STAT_EMIF_CAL_FAIL    ] <= emif_cal_fail_eclk    ;
   mc_sr_status_eclk[ MC_SR_STAT_EMIF_CAL_SUCCESS ] <= emif_cal_success_eclk ;
   mc_sr_status_eclk[ MC_SR_STAT_EMIF_RESET_DONE  ] <= emif_reset_done_eclk  ;
   mc_sr_status_eclk[ MC_SR_STAT_EMIF_PLL_LOCKED  ] <= emif_pll_locked_eclk  ;
   mc_sr_status_eclk[ MC_SR_STAT_RAM_INIT_DONE    ] <= ram_init_done_eclk    ;
end

//-------------------------------------------------------------------------------------------------------------------
//-------------------------------------------------------------------------------------------------------------------

assign iafu2mc_address_minus_baseaddr_eclk = iafu2mc_address_eclk - mc_baseaddr_cl[MC_HA_DP_ADDR_WIDTH-1:1];
assign byteenable_all_ones = '1;

generate
   if (REG_ON_REQFIFO_INPUT_EN == 1) begin : reg_on_reqfifo_input_on

      always_ff @(posedge eclk) begin
         if (mc2iafu_ready_eclk) begin
            req_data_in_eclk.write_poison  <= iafu2mc_write_poison_eclk;
            req_data_in_eclk.req_mdata     <= iafu2mc_req_mdata_eclk;
            req_data_in_eclk.write         <= iafu2mc_write_eclk;
            req_data_in_eclk.read          <= iafu2mc_read_eclk;
            req_data_in_eclk.byteenable    <= iafu2mc_byteenable_eclk;
            req_data_in_eclk.address       <= iafu2mc_address_minus_baseaddr_eclk[EMIF_AMM_ADDR_WIDTH-1:0];
            req_data_in_eclk.writedata     <= iafu2mc_writedata_eclk;
            req_data_in_eclk.partial_write <= iafu2mc_write_eclk & (iafu2mc_byteenable_eclk != byteenable_all_ones);
            req_data_in_eclk.write_ras_sbe      <= iafu2mc_write_ras_sbe_eclk;
            req_data_in_eclk.write_ras_dbe      <= iafu2mc_write_ras_dbe_eclk;

            iafu2mc_write_or_read_active   <= iafu2mc_write_eclk | iafu2mc_read_eclk;
         end

         if (~reset_n_eclk) begin
            iafu2mc_write_or_read_active <= 1'b0;
         end
      end

   end
   else begin : reg_on_reqfifo_input_off

      always_comb begin
         req_data_in_eclk.write_poison  = iafu2mc_write_poison_eclk;
         req_data_in_eclk.write_ras_sbe = iafu2mc_write_ras_sbe_eclk;
         req_data_in_eclk.write_ras_dbe = iafu2mc_write_ras_dbe_eclk;          
         req_data_in_eclk.req_mdata     = iafu2mc_req_mdata_eclk;
         req_data_in_eclk.write         = iafu2mc_write_eclk;
         req_data_in_eclk.read          = iafu2mc_read_eclk;
         req_data_in_eclk.byteenable    = iafu2mc_byteenable_eclk;
         req_data_in_eclk.address       = iafu2mc_address_minus_baseaddr_eclk[EMIF_AMM_ADDR_WIDTH-1:0];
         req_data_in_eclk.writedata     = iafu2mc_writedata_eclk;
         req_data_in_eclk.partial_write = iafu2mc_write_eclk & (iafu2mc_byteenable_eclk != byteenable_all_ones);

         iafu2mc_write_or_read_active   = iafu2mc_write_eclk | iafu2mc_read_eclk;
      end

   end
endgenerate

assign reqfifo_fill_level_eclk = reqfifo_wrusedw_eclk;

assign mc2iafu_ready_eclk = ~reqfifo_full_eclk & ram_init_done_eclk & mc_baseaddr_cl_vld;
//always_ff @(posedge clk) begin
//   mc2iafu_ready_eclk <= (reqfifo_wrusedw_eclk != 2**REQFIFO_DEPTH_WIDTH-1) & (reqfifo_wrusedw_eclk != 2**REQFIFO_DEPTH_WIDTH-2) & ~reqfifo_full_eclk & ram_init_done_eclk & mc_baseaddr_cl_vld;
//end

generate
   if (REG_ON_REQFIFO_OUTPUT_EN == 1) begin : reg_on_reqfifo_output_on

      always_ff @(posedge emif_usr_clk) begin
         if (mem_ready_mclk) begin
            if (ram_init_done_mclk) begin
               mem_write_partial_mclk <= ~reqfifo_empty_mclk & ~rd_cntr[6] & req_data_out_mclk.partial_write;
               mem_write_mclk         <= ~reqfifo_empty_mclk & ~rd_cntr[6] & req_data_out_mclk.write;
               mem_read_mclk          <= ~reqfifo_empty_mclk & ~rd_cntr[6] & req_data_out_mclk.read;
               mem_write_ras_sbe_mclk <= ~reqfifo_empty_mclk & req_data_out_mclk.write_ras_sbe;
               mem_write_ras_dbe_mclk <= ~reqfifo_empty_mclk & req_data_out_mclk.write_ras_dbe;               
                                         
               mem_write_poison_mclk  <= req_data_out_mclk.write_poison;
               mem_write_ras_sbe_mclk <= req_data_out_mclk.write_ras_sbe;
               mem_write_ras_dbe_mclk <= req_data_out_mclk.write_ras_dbe;                
               mem_byteenable_mclk    <= req_data_out_mclk.byteenable;
               mem_address_mclk       <= req_data_out_mclk.address;
               mem_writedata_mclk     <= req_data_out_mclk.writedata;
            end
            else begin
               mem_write_partial_mclk <= 1'b0;
               mem_write_mclk         <= 1'b1;
               mem_read_mclk          <= 1'b0;

               mem_write_poison_mclk  <= 1'b0;
               mem_write_ras_sbe_mclk <= 1'b0;
               mem_write_ras_dbe_mclk <= 1'b0;                 
               mem_byteenable_mclk    <= '1;
               mem_address_mclk       <= ram_init_addr_mclk;
               mem_writedata_mclk     <= '0;
            end
            mem_req_mdata_mclk     <= req_data_out_mclk.req_mdata;
         end

         if (~emif_usr_reset_n_reg[RST_REG_NUM-1]) begin
            mem_write_partial_mclk <= 1'b0;
            mem_write_mclk         <= 1'b0;
            mem_read_mclk          <= 1'b0;
         end
      end

   end
   else if (MC_RAM_INIT_W_ZERO_EN == 1) begin : reg_on_reqfifo_output_off_and_ram_init_on

      always_comb begin
         if (ram_init_done_mclk) begin
            mem_write_partial_mclk = ~reqfifo_empty_mclk & req_data_out_mclk.partial_write;
            mem_write_mclk         = ~reqfifo_empty_mclk & req_data_out_mclk.write;
            mem_read_mclk          = ~reqfifo_empty_mclk & req_data_out_mclk.read;

            mem_write_poison_mclk  = req_data_out_mclk.write_poison;
            mem_write_ras_sbe_mclk = req_data_out_mclk.write_ras_sbe;
            mem_write_ras_dbe_mclk = req_data_out_mclk.write_ras_dbe;             
            mem_byteenable_mclk    = req_data_out_mclk.byteenable;
            mem_address_mclk       = req_data_out_mclk.address;
            mem_writedata_mclk     = req_data_out_mclk.writedata;
         end
         else begin
            mem_write_partial_mclk = 1'b0;
            mem_write_mclk         = emif_usr_reset_n_reg[RST_REG_NUM-1];
            mem_read_mclk          = 1'b0;

            mem_write_poison_mclk  = 1'b0;
            mem_write_ras_sbe_mclk = 1'b0;
            mem_write_ras_dbe_mclk = 1'b0;            
            mem_byteenable_mclk    = '1;
            mem_address_mclk       = ram_init_addr_mclk;
            mem_writedata_mclk     = '0;
         end
         mem_req_mdata_mclk     = req_data_out_mclk.req_mdata;
      end

   end
   else begin : reg_on_reqfifo_output_off_and_ram_init_off

      always_comb begin
         mem_write_partial_mclk = emif_usr_reset_n_reg[RST_REG_NUM-1] & ~reqfifo_empty_mclk & req_data_out_mclk.partial_write;
         mem_write_mclk         = emif_usr_reset_n_reg[RST_REG_NUM-1] & ~reqfifo_empty_mclk & req_data_out_mclk.write;
         mem_read_mclk          = emif_usr_reset_n_reg[RST_REG_NUM-1] & ~reqfifo_empty_mclk & req_data_out_mclk.read;

         mem_write_poison_mclk  = req_data_out_mclk.write_poison;
         mem_write_ras_sbe_mclk = req_data_out_mclk.write_ras_sbe;
         mem_write_ras_dbe_mclk = req_data_out_mclk.write_ras_dbe;          
         mem_byteenable_mclk    = req_data_out_mclk.byteenable;
         mem_address_mclk       = req_data_out_mclk.address;
         mem_writedata_mclk     = req_data_out_mclk.writedata;

         mem_req_mdata_mclk     = req_data_out_mclk.req_mdata;
      end

   end
endgenerate

assign reqfifo_wen_eclk = mc2iafu_ready_eclk & iafu2mc_write_or_read_active;
assign reqfifo_ren_mclk = mem_ready_mclk & ~reqfifo_empty_mclk & emif_usr_reset_n_reg[RST_REG_NUM-1] & ~rd_cntr[6];

altera_std_synchronizer_nocut #(
        .depth(3)
) synchronizer_nocut_1 (
        .clk            (eclk),
        .reset_n        (1'b1),
        .din            (emif_cal_fail),
        .dout           (emif_cal_fail_eclk)
);
altera_std_synchronizer_nocut #(
        .depth(3)
) synchronizer_nocut_2 (
        .clk            (eclk),
        .reset_n        (1'b1),
        .din            (emif_cal_success),
        .dout           (emif_cal_success_eclk)
);
altera_std_synchronizer_nocut #(
        .depth(3)
) synchronizer_nocut_3 (
        .clk            (eclk),
        .reset_n        (1'b1),
        .din            (emif_reset_done),
        .dout           (emif_reset_done_eclk)
);
  altera_std_synchronizer_nocut #(
        .depth(3)
) synchronizer_nocut_4 (
        .clk            (eclk),
        .reset_n        (1'b1),
        .din            (ram_init_done_mclk),
        .dout           (ram_init_done_eclk)
);
  altera_std_synchronizer_nocut #(
        .depth(3)
) synchronizer_nocut_5 (
        .clk            (eclk),
        .reset_n        (1'b1),
        .din            (emif_pll_locked),
        .dout           (emif_pll_locked_eclk)
);

//-----------------------------------------------------------------------------------------------------------------------------------------------------------
// Initialize RAM by writing all zeros after reset.
//-----------------------------------------------------------------------------------------------------------------------------------------------------------
generate
   if (MC_RAM_INIT_W_ZERO_EN == 1) begin : ram_init_on

      always_ff @(posedge emif_usr_clk) begin
         if (mem_ready_mclk & ~ram_init_done_mclk) begin
            ram_init_addr_mclk <= ram_init_addr_mclk + 1'b1;
         end
      //`ifdef SIM_MODE
      `ifdef SIM_MC_RAM_INIT_W_ZERO_PARTIAL_ONLY // To skip whole or majority of memory initialization
         if (mem_ready_mclk && (ram_init_addr_mclk == 0)) begin // only address 0 will be initialized
//      `elsif ENABLE_DDRT
//            if (mem_ready_mclk && (ram_init_addr_mclk == 46'h4F00_001F))
      `else
         // Init complete after writing last address
         if (mem_ready_mclk && (ram_init_addr_mclk == (2**EMIF_AMM_ADDR_WIDTH - 1))) begin
      `endif
            ram_init_done_mclk  <= 1'b1;
         end

         if (~emif_usr_reset_n_reg[RST_REG_NUM-1]) begin
            ram_init_addr_mclk <= '0;
            ram_init_done_mclk <= 1'b0;
         end
      end

   end
   else begin : ram_init_off

      always_comb begin
         ram_init_addr_mclk <= '0;
         ram_init_done_mclk <= 1'b1;
      end

   end
endgenerate

    // Note DATA WIDTH of REQFIFO (640) is set wider than actually needed, to avoid change of fifo IP settings
    //   for cases when DDR4 DIMM memory of other (bigger) size is used
always_comb 
begin
        reqfifo_data_in_eclk[REQ_DATA_T_WIDTH-1:0] = req_data_in_eclk;
        reqfifo_data_in_eclk[REQFIFO_DATA_WIDTH-1:REQ_DATA_T_WIDTH] = '0;

        req_data_out_mclk = reqfifo_data_out_mclk[REQ_DATA_T_WIDTH-1:0];
end

always_comb
begin
    rspfifo_data_out_eclk_intf = rspfifo_data_out_eclk;
end

generate
   if (REG_ON_RSPFIFO_OUTPUT_EN == 1) begin : reg_on_rspfifo_output_on

      always_ff @(posedge eclk) begin
         mc2iafu_read_poison_eclk       <= rspfifo_data_out_eclk_intf.read_poison       ;
         mc2iafu_rsp_mdata_eclk         <= rspfifo_data_out_eclk_intf.rsp_mdata         ;
         mc2iafu_readdata_eclk          <= rspfifo_data_out_eclk_intf.readdata          ;
         mc2iafu_ecc_err_corrected_eclk <= rspfifo_data_out_eclk_intf.ecc_err_corrected ;
         mc2iafu_ecc_err_detected_eclk  <= rspfifo_data_out_eclk_intf.ecc_err_detected  ;
         mc2iafu_ecc_err_fatal_eclk     <= rspfifo_data_out_eclk_intf.ecc_err_fatal     ;
         mc2iafu_ecc_err_syn_e_eclk     <= rspfifo_data_out_eclk_intf.ecc_err_syn_e     ;

         mc2iafu_ecc_err_valid_eclk     <= ~rspfifo_empty_eclk                     ;
         mc2iafu_readdatavalid_eclk     <= ~rspfifo_empty_eclk & rspfifo_data_out_eclk_intf.readdatavalid;

         if (~reset_n_eclk) begin
            mc2iafu_readdatavalid_eclk  <= 1'b0;
            mc2iafu_ecc_err_valid_eclk  <= 1'b0;
         end
      end

   end
   else begin : reg_on_rspfifo_output_off

      always_comb begin
         mc2iafu_read_poison_eclk       = rspfifo_data_out_eclk_intf.read_poison       ;
         mc2iafu_rsp_mdata_eclk         = rspfifo_data_out_eclk_intf.rsp_mdata         ;
         mc2iafu_readdata_eclk          = rspfifo_data_out_eclk_intf.readdata          ;
         mc2iafu_ecc_err_corrected_eclk = rspfifo_data_out_eclk_intf.ecc_err_corrected ;
         mc2iafu_ecc_err_detected_eclk  = rspfifo_data_out_eclk_intf.ecc_err_detected  ;
         mc2iafu_ecc_err_fatal_eclk     = rspfifo_data_out_eclk_intf.ecc_err_fatal     ;
         mc2iafu_ecc_err_syn_e_eclk     = rspfifo_data_out_eclk_intf.ecc_err_syn_e     ;

         mc2iafu_ecc_err_valid_eclk     = ~rspfifo_empty_eclk                     ;
         mc2iafu_readdatavalid_eclk     = ~rspfifo_empty_eclk & rspfifo_data_out_eclk_intf.readdatavalid;
      end

   end
endgenerate

assign rspfifo_ren_eclk = ~rspfifo_empty_eclk;
assign rspfifo_wen_mclk = mem_ecc_err_valid_mclk;

always_comb begin
   rspfifo_data_in_mclk_intf.read_poison       = mem_read_poison_mclk       ;
   rspfifo_data_in_mclk_intf.ecc_err_corrected = mem_ecc_err_corrected_mclk ;
   rspfifo_data_in_mclk_intf.ecc_err_detected  = mem_ecc_err_detected_mclk  ;
   rspfifo_data_in_mclk_intf.ecc_err_fatal     = mem_ecc_err_fatal_mclk     ;
   rspfifo_data_in_mclk_intf.ecc_err_syn_e     = mem_ecc_err_syn_e_mclk     ;
   rspfifo_data_in_mclk_intf.rsp_mdata         = mem_rsp_mdata_mclk         ;
   rspfifo_data_in_mclk_intf.readdata          = mem_readdata_mclk          ;
   rspfifo_data_in_mclk_intf.readdatavalid     = mem_readdatavalid_mclk     ;

   rspfifo_data_in_mclk = rspfifo_data_in_mclk_intf;
end

//assign emif_init_done_eclk = emif_reset_done & emif_cal_success;

assign mem_rsp_mdata_mclk = '0;

mc_rmw_shim #(
  .ADDR_WIDTH         ( EMIF_AMM_ADDR_WIDTH ),
  .DATA_WIDTH         ( MC_HA_DP_DATA_WIDTH ),
  .ALTECC_INST_NUMBER ( ALTECC_INST_NUMBER  )
)
mc_rmw_shim_inst (
  .mem_clk                       ( emif_usr_clk                   ),
  .mem_reset_n                   ( emif_usr_reset_n_reg[RST_REG_NUM-1] ),
  .rd_cntr                       ( rd_cntr                        ),
  .mem_ready_ha_mclk             ( mem_ready_mclk                 ),
  .mem_read_ha_mclk              ( mem_read_mclk                  ),
  .mem_write_ha_mclk             ( mem_write_mclk                 ),
  .mem_write_poison_ha_mclk      ( mem_write_poison_mclk          ),
  .mem_write_partial_ha_mclk     ( mem_write_partial_mclk         ),
  .mem_address_ha_mclk           ( mem_address_mclk               ),
  .mem_writedata_ha_mclk         ( mem_writedata_mclk             ),
  .mem_byteenable_ha_mclk        ( mem_byteenable_mclk            ),
  .mem_readdata_ha_mclk          ( mem_readdata_mclk              ),
  .mem_read_poison_ha_mclk       ( mem_read_poison_mclk           ),
  .mem_readdatavalid_ha_mclk     ( mem_readdatavalid_mclk         ),
  .mem_ecc_err_corrected_ha_mclk ( mem_ecc_err_corrected_mclk     ),
  .mem_ecc_err_detected_ha_mclk  ( mem_ecc_err_detected_mclk      ),
  .mem_ecc_err_fatal_ha_mclk     ( mem_ecc_err_fatal_mclk         ),
  .mem_ecc_err_syn_e_ha_mclk     ( mem_ecc_err_syn_e_mclk         ),
  .mem_ecc_err_valid_ha_mclk     ( mem_ecc_err_valid_mclk         ),
  .mem_ready_mclk                ( mem_ready_rmw_mclk             ),
  .mem_read_mclk                 ( mem_read_rmw_mclk              ),
  .mem_write_mclk                ( mem_write_rmw_mclk             ),
  .mem_write_poison_mclk         ( mem_write_poison_rmw_mclk      ),
  .mem_address_mclk              ( mem_address_rmw_mclk           ),
  .mem_writedata_mclk            ( mem_writedata_rmw_mclk         ),
  .mem_byteenable_mclk           ( mem_byteenable_rmw_mclk        ),
  .mem_readdata_mclk             ( mem_readdata_rmw_mclk          ),
  .mem_read_poison_mclk          ( mem_read_poison_rmw_mclk       ),
  .mem_readdatavalid_mclk        ( mem_readdatavalid_rmw_mclk     ),
  .mem_ecc_err_corrected_mclk    ( mem_ecc_err_corrected_rmw_mclk ),
  .mem_ecc_err_detected_mclk     ( mem_ecc_err_detected_rmw_mclk  ),
  .mem_ecc_err_fatal_mclk        ( mem_ecc_err_fatal_rmw_mclk     ),
  .mem_ecc_err_syn_e_mclk        ( mem_ecc_err_syn_e_rmw_mclk     )
);


endmodule
