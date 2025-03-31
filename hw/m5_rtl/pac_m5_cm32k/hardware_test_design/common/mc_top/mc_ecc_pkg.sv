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
// Creation Date : Feb, 2023
// Description   : SBCNT/DBCNT 

package mc_ecc_pkg;

import tmp_cafu_csr0_cfg_pkg::*;

localparam MC_STATUS_T_BW      = $bits( tmp_cafu_csr0_cfg_pkg::tmp_MC_STATUS_t );
localparam MEM_DEV_STATUS_T_BW = $bits( tmp_cafu_csr0_cfg_pkg::tmp_new_CXL_MEM_DEV_STATUS_t );

//-------------------------
//------ Dev Mem Interfaces
//-------------------------

 typedef struct packed {
    logic [7:0]                      SBE;
    logic [7:0]                      DBE;
    logic                            Valid;
 } mc_rddata_ecc_t;

  typedef enum logic [1:0] {
    M2S_METAVALUE_INVALID       = 2'b00,
    M2S_METAVALUE_RSVD1         = 2'b01,
    M2S_METAVALUE_ANY           = 2'b10,
    M2S_METAVALUE_SHARED        = 2'b11
  } M2S_MetaValue_e;

  typedef enum logic [1:0] {
    M2S_METAFIELD_META0         = 2'b00,
    M2S_METAFIELD_RSVD1         = 2'b01,
    M2S_METAFIELD_RSVD2         = 2'b10,
    M2S_METAFIELD_NOOP          = 2'b11
  } M2S_MetaField_e;

localparam  CL_ADDR_MSB = 51;
localparam  CL_ADDR_LSB = 6;
typedef logic [CL_ADDR_MSB:CL_ADDR_LSB]        Cl_Addr_t;

localparam  M2SQ_ENTRIES  = 64; // Number of M2S Requests/M2S RWD allowed outstanding
localparam  M2SQ_WIDTH = $clog2(M2SQ_ENTRIES);

typedef struct packed {
    logic [255:0]   Data1;
    logic [255:0]   Data0;
} DataCL_t;

typedef struct packed {
        DataCL_t                     Data;
        logic [3:0]                  EventTriggerB;
        M2S_MetaValue_e              MetaValue;
        M2S_MetaField_e              MetaField;
        logic                        Poison;
} dev_mem_rd_data_t;


 typedef struct packed {
    dev_mem_rd_data_t                RdData;
    mc_rddata_ecc_t                  RdDataECC;
    logic                            RdDataValid;
    logic                            CdcWrFifoEmpty;
    logic                            CdcWrFifoFull;
    logic [M2SQ_WIDTH:0]             CdcWrFifoUsedW;
    logic                            McReady;
    logic                            cxlmem_ready;
 } mc_devmem_if_t;

 typedef struct packed {
    Cl_Addr_t                        DevAddr;            //46
    logic [32:0]                     SBECnt;             //33
    logic [32:0]                     DBECnt;             //33
    logic [32:0]                     PoisonRtnCnt;       //33
    logic                            NewSBE;          
    logic                            NewDBE;
    logic                            NewPoisonRtn;
    logic                            NewPartialWr;
 } mc_err_cnt_t;


localparam MC_ERR_CNT_WIDTH = $bits(mc_err_cnt_t); //149;
  

endpackage : mc_ecc_pkg

