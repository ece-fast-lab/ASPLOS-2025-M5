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


// Copyright 2023 Intel Corporation.
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
// Description   : CAFU Device Register Mailbox Logic
//

module cafu_devreg_mailbox
  import cxlip_top_pkg::*;
  import ext_csr_if_pkg::*;
  import tmp_cafu_csr0_cfg_pkg::*;
(
  input  logic                                                            cxlbbs_clk,
  input  logic                                                            cxlbbs_pwrgood_rst,    //power good reset
  input  logic                                                            cxlbbs_rst,            //warm reset
  input  logic                                                            sbr_clk_i,             //Sideband Clk
  input  logic                                                            sbr_rstb_i,            //Sideband Reset

  input  tmp_cafu_csr0_cfg_pkg::tmp_MBOX_EVENTINJ_t                       bbs_mbox_eventinj,
  input  tmp_cafu_csr0_cfg_pkg::tmp_CXL_MB_CMD_t                          cxl_mb_cmd,
  input  tmp_cafu_csr0_cfg_pkg::tmp_CXL_MB_CTRL_t                         cxl_mb_ctrl,

  input  logic                                                            hyc_mem_active,
  input  logic [63:0]                                                     mbox_ram_dout,

  output tmp_cafu_csr0_cfg_pkg::tmp_load_CXL_MB_CMD_t                     hyc_load_cxl_mb_cmd,
  output tmp_cafu_csr0_cfg_pkg::tmp_new_CXL_MB_CMD_t                      hyc_new_cxl_mb_cmd,

  output tmp_cafu_csr0_cfg_pkg::tmp_load_CXL_MB_CTRL_t                    hyc_load_cxl_mb_ctrl,
  output tmp_cafu_csr0_cfg_pkg::tmp_new_CXL_MB_CTRL_t                     hyc_new_cxl_mb_ctrl,

  output tmp_cafu_csr0_cfg_pkg::tmp_new_CXL_MB_STATUS_t                   hyc_mb_status,
  output tmp_cafu_csr0_cfg_pkg::tmp_CXL_DEV_CAP_EVENT_STATUS_t            hyc_dev_cap_event_status,

  output logic                                                            hyc_hw_mbox_ram_rd_en,
  output logic [7:0]                                                      hyc_hw_mbox_ram_rd_addr,
  output logic                                                            hyc_hw_mbox_ram_wr_en,
  output logic [7:0]                                                      hyc_hw_mbox_ram_wr_addr,
  output logic [63:0]                                                     hyc_hw_mbox_ram_wr_data,

  input  ext_csr_if_pkg::mc_err_cnt_t  [cxlip_top_pkg::MC_CHANNEL-1:0]    mc_err_cnt
);


  logic         cxlMbCtrlDoorbell_D1Q;
  logic         cxlMbCtrlDoorbellSet;
  logic [32:0]  mcAllChanDBECnt_Q;
  logic [32:0]  mcAllChanDBESum;
  logic         mcAllChanNewDBE;
  logic         mcAllChanNewPoisonRtn;
  logic         mcAllChanNewSBE;
  logic [32:0]  mcAllChanPoisonRtnCnt_Q;
  logic [32:0]  mcAllChanPoisonRtnSum;
  logic [32:0]  mcAllChanSBECnt_Q;
  logic         mcAllChanSBECntEnb;
  logic         mcAllChanSBECntHold_Q;
  logic         mcAllChanSBESaturate;
  logic [32:0]  mcAllChanSBESum;
  logic         mboxAlertCnfgCVMEEnAlert_Q;
  logic         mboxAlertCnfgCVMEEnAlertNext_Q;
  logic [1:0]   mboxAlertCnfgCVMEEnb;
  logic [15:0]  mboxAlertCnfgCVMEWarnThld_Q;
  logic         mboxCERClrAllRcrdEn_Q;
  logic         mboxCERElogTgtFail_Q;
  logic         mboxCERElogTgtFatal_Q;
  logic         mboxCERElogTgtInfo_Q;
  logic         mboxCERElogTgtWarn_Q;
  logic         mboxCERInvldHndlSeen_Q;
  logic         mboxCERIPyldChkEn_Q;
  logic         mboxCERIPyldChkFailUpdtRtnCd_In;
  logic         mboxCERIPyldChkFailUpdtRtnCd_Q;
  logic         mboxCERIPyldChkPassStartCER_Q;
  logic         mboxCERIPyldLenChkFail_In;
  logic         mboxCERIPyldLenChkFail_Q;
  logic         mboxCERIPyldParamChkFail_In;
  logic         mboxCERIPyldParamChkFail_Q;
  logic [1:0]   mboxCERLastRdHndlIdx_Q;
  logic [4:0]   mboxCERRdHndlCnt_Q;
  logic         mboxCERRdHndlCntMatchTotalCnt;
  logic         mboxCERRdHndlEn_Q;
  logic         mboxCERRdHndlEnNxtCyc_Q;
  logic [1:0]   mboxCERRdHndlIdx_Q;
  logic         mboxCERRdNxtIPyldAddr_Q;
  logic [15:0]  mboxCERS1Hndl_In;
  logic [15:0]  mboxCERS1Hndl_Q;
  logic         mboxCERS1HndlLegalIfRcrdVld;
  logic         mboxCERS1LastHndlRd_In;
  logic         mboxCERS1LastHndlRd_Q;
  logic         mboxCERS1Valid_Q;
  logic         mboxCERS2ElogHndlInUse_In;
  logic         mboxCERS2ElogHndlInUse_Q;
  logic [15:0]  mboxCERS2Hndl_Q;
  logic         mboxCERS2HndlLegal;
  logic         mboxCERS2HndlLegalIfRcrdVld_Q;
  logic         mboxCERS2LastHndlRd_Q;
  logic         mboxCERS2Valid_Q;
  logic [15:0]  mboxCERS3Hndl_Q;
  logic         mboxCERS3HndlLegal_Q;
  logic         mboxCERS3LastHndlRd_Q;
  logic         mboxCERS3Valid_Q;
  logic         mboxCERSetClrAllRcrdEn;
  logic         mboxCERLastHndlUpdtRtnCd_Q;
  logic         mboxCERSetLastHndlUpdtRtnCd;
  logic         mboxCERSetStartClnup;
  logic         mboxCERSetUpdtReturnCode;
  logic         mboxCERStartClnup_Q;
  logic         mboxCERStartFirstHndlChk;
  logic         mboxCERStartNxtHndlChk_Q;
  logic         mboxCERUpdtReturnCode_Q;
  logic         mboxClrCVMECntGTEWarnThld;
  logic         mboxClrEvRcrdsClrAllEv_Q;
  logic [7:0]   mboxClrEvRcrdsEvLog_Q;
  logic [15:0]  mboxClrEvRcrdsEvRcrdHndl_Q  [3:0];
  logic         mboxClrEvRcrdsFirstCyc_Q;
  logic [7:0]   mboxClrEvRcrdsNumEvRcrdHndl_Q;
  logic         mboxCmdActionNeedsIPyld_In;
  logic         mboxCmdActionNeedsIPyld_Q;
  logic         mboxCmdActionNeedsSync_In;
  logic         mboxCmdActionNeedsSync_Q;
  logic         mboxCVMECntGTEWarnThld_Q;
  logic [31:0]  mboxEvntIntrPlcy_Q;
  logic         mboxEvntIntrPlcyEnb;
  logic         mboxFastUpdtReturnCode_Q;
  logic         mboxGERAnyElogRdDataVld;
  logic [63:0]  mboxGERElogRdData_In;
  logic [63:0]  mboxGERElogRdData_Q, infoElogRdData, warnElogRdData, failElogRdData, fatalElogRdData;
  logic         mboxGERElogRdDataVld_Q, infoElogRdDataVld_Q, warnElogRdDataVld_Q, failElogRdDataVld_Q, fatalElogRdDataVld_Q;
  logic         mboxGERElogTgtFail_Q;
  logic         mboxGERElogTgtFatal_Q;
  logic         mboxGERElogTgtInfo_Q;
  logic         mboxGERElogTgtWarn_Q;
  logic [15:0]  mboxGEREvRcrdCnt_In;
  logic [15:0]  mboxGEREvRcrdCnt_Q, infoElogEvRcrdCnt_Q, warnElogEvRcrdCnt_Q, failElogEvRcrdCnt_Q, fatalElogEvRcrdCnt_Q;
  logic [63:0]  mboxGERFirstOvfEvTmstmp_In;
  logic [63:0]  mboxGERFirstOvfEvTmstmp_Q, infoElogFirstOvfEvTmstmp_Q, warnElogFirstOvfEvTmstmp_Q, failElogFirstOvfEvTmstmp_Q, fatalElogFirstOvfEvTmstmp_Q;
  logic         mboxGERFlagsMoreEvRcrds_In;
  logic         mboxGERFlagsMoreEvRcrds_Q, infoElogFlagsMoreEvRcrds_Q, warnElogFlagsMoreEvRcrds_Q, failElogFlagsMoreEvRcrds_Q, fatalElogFlagsMoreEvRcrds_Q;
  logic         mboxGERFlagsOvf_In;
  logic         mboxGERFlagsOvf_Q, infoElogFlagsOvf_Q, warnElogFlagsOvf_Q, failElogFlagsOvf_Q, fatalElogFlagsOvf_Q;
  logic         mboxGERIPyldChkEn_Q;
  logic         mboxGERIPyldChkPassRdAllRcrdStart_In;
  logic         mboxGERIPyldChkPassRdAllRcrdStart_Q;
  logic         mboxGERIPyldLenChkFail_In;
  logic         mboxGERIPyldLenChkFail_Q;
  logic         mboxGERIPyldParamChkFail_In;
  logic         mboxGERIPyldParamChkFail_Q;
  logic [63:0]  mboxGERLastOvfEvTmstmp_In;
  logic [63:0]  mboxGERLastOvfEvTmstmp_Q, infoElogLastOvfEvTmstmp_Q, warnElogLastOvfEvTmstmp_Q, failElogLastOvfEvTmstmp_Q, fatalElogLastOvfEvTmstmp_Q;
  logic [15:0]  mboxGEROvfErrCnt_In;
  logic [15:0]  mboxGEROvfErrCnt_Q, infoElogOvfErrCnt_Q, warnElogOvfErrCnt_Q, failElogOvfErrCnt_Q, fatalElogOvfErrCnt_Q;
  logic [20:0]  mboxGERPayloadLen_In;
  logic [20:0]  mboxGERPayloadLen_Q, infoElogPayloadLen_Q, warnElogPayloadLen_Q, failElogPayloadLen_Q, fatalElogPayloadLen_Q;
  logic         mboxGERRdAllRcrdActive_Q;
  logic         mboxGERRdAllRcrdDone_In,infoElogRdAllRcrdDone_Q,warnElogRdAllRcrdDone_Q,failElogRdAllRcrdDone_Q,fatalElogRdAllRcrdDone_Q;
  logic         mboxGERRdAllRcrdDone_Q;
  logic         mboxGERRdAllRcrdStart_Q;
  logic         mboxGERRdAllRcrdStartStg_Q;
  logic         mboxGERUpdtReturnCode_Q;
  logic [7:0]   mboxGetHealthInfoMediaStatus;
  logic         mboxGetLogMatchUUIDAllGrps;
  logic [7:0]   mboxGetLogMatchUUIDGrp_Q;
  logic         mboxGetLogUpdtReturnCode_Q;
  logic         mboxGetTimestampAck_S1;
  logic         mboxGetTimestampAck_S2;
  logic         mboxGetTimestampAck_S3;
  logic         mboxGetTimestampAck_S4;
  logic         mboxGetTimestampNewReq;
  logic         mboxGetTimestampReq_Q;
  logic         mboxGetTimestampReq_S1_rclk;
  logic         mboxGetTimestampReq_S2_rclk;
  logic         mboxGetTimestampReq_S3_rclk;
  logic         mboxGetTimestampReq_S4_rclk;
  logic         mboxGetTimestampSmplEnb_rclk;
  logic         mboxGetTimestampSyncDone;
  logic         mboxIPyldRdDonePulse_Q;
  logic         mboxNeedIPyldRdDonePulse_Q;
  logic         mboxNewReturnCodeNonSuccess_Q;
  logic         mboxNewReturnCodeSuccess_Q;
  logic [15:0]  mboxPyldReturnCode;
  logic [63:0]  mboxPyldSrcDataGetAlertCnfg     [8:0];
  logic [63:0]  mboxPyldSrcDataGetEvntIntrPlcy  [8:0];
  logic [63:0]  mboxPyldSrcDataGetEvRcrds       [8:0];
  logic [63:0]  mboxPyldSrcDataGetHealthInfo    [8:0];
  logic [63:0]  mboxPyldSrcDataGetLog           [8:0];
  logic [63:0]  mboxPyldSrcDataGetSupLogs       [8:0];
  logic [63:0]  mboxPyldSrcDataGetTimestamp     [8:0];
  logic [63:0]  mboxPyldSrcDataIdentMemDev      [8:0];
  logic [63:0]  mboxPyldSrcDataMux              [8:0];
  logic         mboxPyldLastRamWr;
  logic [7:0]   mboxPyldLastRdAddr_Q;
  logic         mboxPyldRdDataVld;
  logic [1:0]   mboxPyldRdEnStg_Q;
  logic         mboxPyldSrcDataRdEn_Q;
  logic [7:0]   mboxPyldSrcDataRdIdx_Q;
  logic [7:0]   mboxPyldSrcDataLastIdx_Q;
  logic         mboxOPyldWrStart_Q;
  logic         mboxSetAlertCnfgCVMEFldsVld_In;
  logic         mboxSetAlertCnfgCVMEFldsVld_Q;
  logic         mboxSetCVMECntGTEWarnThld;
  logic         mboxSetFastUpdtReturnCode;
  logic         mboxSetLoadDoorbell;
  logic         mboxSetOPyldWrStart;
  logic         mboxSetRamWrEn;
  logic         mboxSetTimestampAck_S1;
  logic         mboxSetTimestampAck_S2;
  logic         mboxSetTimestampAck_S3;
  logic         mboxSetTimestampAck_S4;
  logic [63:0]  mboxSetTimestampNewVal_Q;
  logic         mboxSetTimestampNewValRdy;
  logic         mboxSetTimestampReq_Q;
  logic         mboxSetTimestampReq_S1_rclk;
  logic         mboxSetTimestampReq_S2_rclk;
  logic         mboxSetTimestampReq_S3_rclk;
  logic         mboxSetTimestampReq_S4_rclk;
  logic         mboxSetTimestampSeen_Q;
  logic         mboxSetTimestampSyncDone;
  logic         mboxStartIPyldRdForClrEvRcrds;
  logic         mboxStartIPyldRdForCmdAction;
  logic         mboxStartIPyldRdForReturnCode;
  logic [63:0]  mboxTimestamp_Q_rclk;
  logic [63:0]  mboxTimestampSmpl_Q;
  logic [63:0]  mboxTimestampSmpl_Q_rclk;
  logic         mboxTimestampWrEn_rclk;
  logic         mboxUpdtAlertCnfg;
  logic         mboxUpdtClrEvRcrdsRegs;
  logic         mboxUpdtGetEvRcrdsRegs;
  logic         mboxUpdtGetLogMatchUUIDGrp;
  logic         mboxUpdtReturnCode;
  logic         ts_ref_clk;
  logic         infoElogClrAllRcrdEn, warnElogClrAllRcrdEn, failElogClrAllRcrdEn, fatalElogClrAllRcrdEn;
  logic         infoElogClrRcrdEn, warnElogClrRcrdEn, failElogClrRcrdEn, fatalElogClrRcrdEn;
  logic         infoElogHndlInUse_Q, warnElogHndlInUse_Q, failElogHndlInUse_Q, fatalElogHndlInUse_Q;
  logic         infoElogRdAllRcrdStart, warnElogRdAllRcrdStart, failElogRdAllRcrdStart, fatalElogRdAllRcrdStart;


  always_ff @(posedge cxlbbs_clk) begin
    cxlMbCtrlDoorbell_D1Q <= cxl_mb_ctrl.doorbell;
  end

  assign cxlMbCtrlDoorbellSet = cxl_mb_ctrl.doorbell & ~cxlMbCtrlDoorbell_D1Q;

  //-------------------------------------------------------------------------------------------
  // If doorbell set, start mailbox command sequence:
  // 1. Calculate return code
  //    - If (code == Success):
  //      - Update return code
  //      - Update output payload length
  //      - Move to "read input payload" step
  //    - If (code != Success):
  //      - Update return code
  //      - Stop command sequence.  Move to "clear doorbell" step.
  //    - Note: Some commands require input payload read to calculate return code
  // 2. Read input payload
  //    - If input payload exists:
  //      - Read payload and perform required actions
  //      - Move to "write output payload" step
  //    - If input payload does not exist, move to "write output payload" step
  // 3. Write output payload
  //    - If output payload needed:
  //      - Write payload
  //      - Move to "clear doorbell" step
  //    - If output payload not needed, move to "clear doorbell" step
  // 4. Clear doorbell
  //-------------------------------------------------------------------------------------------

  //------------------------
  // Calculate return code
  //------------------------

  always_comb begin
    case (cxl_mb_cmd.command_op) inside
      16'h0100: mboxPyldReturnCode = mboxGERIPyldParamChkFail_Q
                                     ? 16'h0002       // Invalid Parameter
                                     : mboxGERIPyldLenChkFail_Q
                                       ? 16'h0016     // Invalid Payload Length
                                       : 16'h0000;    // Success
      16'h0101: mboxPyldReturnCode = mboxCERIPyldParamChkFail_Q
                                     ? 16'h0002       // Invalid Parameter
                                     : mboxCERIPyldLenChkFail_Q
                                       ? 16'h0016     // Invalid Payload Length
                                       : (mboxCERInvldHndlSeen_Q & ~mboxClrEvRcrdsClrAllEv_Q)
                                         ? 16'h000E   // Invalid Handle
                                         : 16'h0000;  // Success
      16'h0102: mboxPyldReturnCode = (cxl_mb_cmd.payload_len == 'h0)
                                     ? 16'h0000    // Success
                                     : 16'h0016;   // Invalid Payload Length
      16'h0103: mboxPyldReturnCode = (cxl_mb_cmd.payload_len == 'h4)
                                     ? 16'h0000    // Success
                                     : 16'h0016;   // Invalid Payload Length
      16'h0300: mboxPyldReturnCode = (cxl_mb_cmd.payload_len == 'h0)
                                     ? 16'h0000    // Success
                                     : 16'h0016;   // Invalid Payload Length
      16'h0301: mboxPyldReturnCode = (cxl_mb_cmd.payload_len == 'h8)
                                     ? 16'h0000    // Success
                                     : 16'h0016;   // Invalid Payload Length
      16'h0400: mboxPyldReturnCode = (cxl_mb_cmd.payload_len == 'h0)
                                     ? 16'h0000    // Success
                                     : 16'h0016;   // Invalid Payload Length
      16'h0401: mboxPyldReturnCode = (cxl_mb_cmd.payload_len == 'h18)
                                     ? mboxGetLogMatchUUIDAllGrps
                                       ? 16'h0000  // Success
                                       : 16'h0002  // Invalid Parameter
                                     : 16'h0016;   // Invalid Payload Length
      16'h4000: mboxPyldReturnCode = (cxl_mb_cmd.payload_len == 'h0)
                                     ? 16'h0000    // Success
                                     : 16'h0016;   // Invalid Payload Length
      16'h4200: mboxPyldReturnCode = (cxl_mb_cmd.payload_len == 'h0)
                                     ? 16'h0000    // Success
                                     : 16'h0016;   // Invalid Payload Length
      16'h4201: mboxPyldReturnCode = (cxl_mb_cmd.payload_len == 'h0)
                                     ? 16'h0000    // Success
                                     : 16'h0016;   // Invalid Payload Length
      16'h4202: mboxPyldReturnCode = (cxl_mb_cmd.payload_len == 'hC)
                                     ? 16'h0000    // Success
                                     : 16'h0016;   // Invalid Payload Length
      default:  mboxPyldReturnCode = 16'h0003;     // Unsupported
    endcase
  end

  // If input payload not needed to calculate return code,
  // generate "fast" return code update.

  assign mboxSetFastUpdtReturnCode = cxlMbCtrlDoorbellSet
                                     & (cxl_mb_cmd.command_op != 16'h0100)
                                     & (cxl_mb_cmd.command_op != 16'h0101)
                                     & (cxl_mb_cmd.command_op != 16'h0401);

  always_ff @(posedge cxlbbs_clk) begin
    if (cxlbbs_rst) begin
      mboxFastUpdtReturnCode_Q <= 1'b0;
    end
    else if (mboxFastUpdtReturnCode_Q) begin
      mboxFastUpdtReturnCode_Q <= 1'b0;
    end
    else if (mboxSetFastUpdtReturnCode) begin
      mboxFastUpdtReturnCode_Q <= 1'b1;
    end
  end

  assign mboxCmdActionNeedsIPyld_In =   (cxl_mb_cmd.command_op == 16'h0103)
                                      | (cxl_mb_cmd.command_op == 16'h0301)
                                      | (cxl_mb_cmd.command_op == 16'h4202);

  assign mboxCmdActionNeedsSync_In = (cxl_mb_cmd.command_op == 16'h0301);

  always_ff @(posedge cxlbbs_clk) begin
    if (cxlMbCtrlDoorbellSet) begin
      mboxCmdActionNeedsIPyld_Q <= mboxCmdActionNeedsIPyld_In;
      mboxCmdActionNeedsSync_Q  <= mboxCmdActionNeedsSync_In;
    end
  end

  // - If doorbell set and input payload needed to calculate return code,
  //   begin reading input payload.
  // - If return code is Success and input payload needed to support command action,
  //   begin reading input payload.
  // - Clear Event Records requires input payload for both return code calculation
  //   and command action.

  assign mboxStartIPyldRdForReturnCode = cxlMbCtrlDoorbellSet & ((cxl_mb_cmd.command_op == 16'h0100) | (cxl_mb_cmd.command_op == 16'h0401));
  assign mboxStartIPyldRdForCmdAction  = mboxNewReturnCodeSuccess_Q & mboxCmdActionNeedsIPyld_Q;
  assign mboxStartIPyldRdForClrEvRcrds = cxlMbCtrlDoorbellSet & (cxl_mb_cmd.command_op == 16'h0101);

  always_ff @(posedge cxlbbs_clk) begin
    if (cxlbbs_rst) begin
      hyc_hw_mbox_ram_rd_en      <= 1'b0;
      mboxPyldRdEnStg_Q          <= '0;
      mboxIPyldRdDonePulse_Q     <= 1'b0;
      mboxNeedIPyldRdDonePulse_Q <= 1'b0;
    end
    else if (mboxIPyldRdDonePulse_Q) begin
      mboxIPyldRdDonePulse_Q     <= 1'b0;
      mboxNeedIPyldRdDonePulse_Q <= 1'b0;
    end
    // Begin input payload read (needed to calculate return code)
    else if (mboxStartIPyldRdForReturnCode) begin
      hyc_hw_mbox_ram_rd_en   <= 1'b1;
      hyc_hw_mbox_ram_rd_addr <= '0;
      mboxPyldRdEnStg_Q       <= '0;

      if (cxl_mb_cmd.command_op == 16'h0401) begin
        mboxPyldLastRdAddr_Q <= 'd1;
      end
      else begin
        mboxPyldLastRdAddr_Q <= 'd0;
      end
    end
    // Begin input payload read (needed to support command action)
    else if (mboxStartIPyldRdForCmdAction) begin
        hyc_hw_mbox_ram_rd_en      <= 1'b1;
        hyc_hw_mbox_ram_rd_addr    <= '0;
        mboxPyldRdEnStg_Q          <= '0;
        mboxNeedIPyldRdDonePulse_Q <= 1'b1;

      if (cxl_mb_cmd.command_op == 16'h4202) begin
        mboxPyldLastRdAddr_Q <= 'd1;
      end
      else begin
        mboxPyldLastRdAddr_Q <= 'd0;
      end
    end
    // Begin input payload read for Clear Event Records
    else if (mboxStartIPyldRdForClrEvRcrds) begin
      hyc_hw_mbox_ram_rd_en   <= 1'b1;
      hyc_hw_mbox_ram_rd_addr <= '0;
      mboxPyldLastRdAddr_Q    <= '0;
      mboxPyldRdEnStg_Q       <= '0;
    end
    // Continue input payload read for Clear Event Records
    else if (mboxCERRdNxtIPyldAddr_Q) begin
      hyc_hw_mbox_ram_rd_en   <= 1'b1;
      hyc_hw_mbox_ram_rd_addr <= hyc_hw_mbox_ram_rd_addr + 'd1;
      mboxPyldLastRdAddr_Q    <= mboxPyldLastRdAddr_Q + 'd1;
      mboxPyldRdEnStg_Q       <= '0;
    end
    // RAM read takes 2 cycles.  Shift register determines when RAM read data valid.
    else if (hyc_hw_mbox_ram_rd_en & (mboxPyldRdEnStg_Q == 2'b00)) begin
      mboxPyldRdEnStg_Q <= 2'b01;
    end
    else if (hyc_hw_mbox_ram_rd_en & mboxPyldRdEnStg_Q[0]) begin
      mboxPyldRdEnStg_Q <= 2'b10;
    end
    else if (hyc_hw_mbox_ram_rd_en & mboxPyldRdEnStg_Q[1]) begin
      mboxPyldRdEnStg_Q <= '0;

      if (hyc_hw_mbox_ram_rd_addr == mboxPyldLastRdAddr_Q) begin
        hyc_hw_mbox_ram_rd_en <= 1'b0;

        if (mboxNeedIPyldRdDonePulse_Q) begin
          mboxIPyldRdDonePulse_Q <= 1'b1;
        end
      end
      else begin
        hyc_hw_mbox_ram_rd_addr <= hyc_hw_mbox_ram_rd_addr + 'd1;
      end
    end
  end

  assign mboxPyldRdDataVld = mboxPyldRdEnStg_Q[1];

  // Mailbox command Get Log uses input payload to provide UUID.
  // Return code of Success requires UUID = CEL.

  assign mboxUpdtGetLogMatchUUIDGrp = mboxPyldRdDataVld & (cxl_mb_cmd.command_op == 16'h0401);

  always_ff @(posedge cxlbbs_clk) begin
    if (cxlbbs_rst) begin
      mboxGetLogUpdtReturnCode_Q <= 1'b0;
    end
    else if (mboxGetLogUpdtReturnCode_Q) begin
      mboxGetLogUpdtReturnCode_Q <= 1'b0;
    end
    else if (mboxUpdtGetLogMatchUUIDGrp) begin
      if (hyc_hw_mbox_ram_rd_addr == 'd0) begin
        mboxGetLogMatchUUIDGrp_Q[0] <= (mbox_ram_dout[15:0]  == 16'hA90D);
        mboxGetLogMatchUUIDGrp_Q[1] <= (mbox_ram_dout[31:16] == 16'hB5C0);
        mboxGetLogMatchUUIDGrp_Q[2] <= (mbox_ram_dout[47:32] == 16'h41BF);
        mboxGetLogMatchUUIDGrp_Q[3] <= (mbox_ram_dout[63:48] == 16'h784B);
      end
      else if (hyc_hw_mbox_ram_rd_addr == 'd1) begin
        mboxGetLogMatchUUIDGrp_Q[4] <= (mbox_ram_dout[15:0]  == 16'h798F);
        mboxGetLogMatchUUIDGrp_Q[5] <= (mbox_ram_dout[31:16] == 16'hB196);
        mboxGetLogMatchUUIDGrp_Q[6] <= (mbox_ram_dout[47:32] == 16'h3B62);
        mboxGetLogMatchUUIDGrp_Q[7] <= (mbox_ram_dout[63:48] == 16'h173F);
        mboxGetLogUpdtReturnCode_Q  <= 1'b1;
      end
    end
  end

  assign mboxGetLogMatchUUIDAllGrps = (&mboxGetLogMatchUUIDGrp_Q);

  assign mboxUpdtReturnCode = mboxGetLogUpdtReturnCode_Q | mboxGERUpdtReturnCode_Q | mboxCERUpdtReturnCode_Q | mboxFastUpdtReturnCode_Q;

  always_ff @(posedge cxlbbs_clk) begin
    if (cxlbbs_rst) begin
      hyc_mb_status <= '0;
    end
    else if (mboxUpdtReturnCode) begin
      hyc_mb_status.return_code <= mboxPyldReturnCode;
    end
  end

  always_ff @(posedge cxlbbs_clk) begin
    if (cxlbbs_rst) begin
      mboxNewReturnCodeSuccess_Q    <= 1'b0;
      mboxNewReturnCodeNonSuccess_Q <= 1'b0;
    end
    else if (mboxNewReturnCodeSuccess_Q) begin
      mboxNewReturnCodeSuccess_Q <= 1'b0;
    end
    else if (mboxNewReturnCodeNonSuccess_Q) begin
      mboxNewReturnCodeNonSuccess_Q <= 1'b0;
    end
    else if (mboxUpdtReturnCode) begin
      if (mboxPyldReturnCode == 16'h0000) begin
        mboxNewReturnCodeSuccess_Q <= 1'b1;
      end
      else begin
        mboxNewReturnCodeNonSuccess_Q <= 1'b1;
      end
    end
  end

  // Pulse load_payload_len to update output payload length if
  // success return code generated.
  always_ff @(posedge cxlbbs_clk) begin
    if (cxlbbs_rst) begin
      hyc_load_cxl_mb_cmd.payload_len <= 1'b0;
    end
    else if (mboxNewReturnCodeSuccess_Q) begin
      hyc_load_cxl_mb_cmd.payload_len <= 1'b1;
    end
    else if (hyc_load_cxl_mb_cmd.payload_len) begin
      hyc_load_cxl_mb_cmd.payload_len <= 1'b0;
    end
  end

  //-----------------------
  // Write output payload
  //-----------------------

  assign mboxSetOPyldWrStart = mboxCmdActionNeedsSync_Q
                               ? mboxSetTimestampSyncDone
                               : mboxCmdActionNeedsIPyld_Q
                                 ? mboxIPyldRdDonePulse_Q
                                 : (cxl_mb_cmd.command_op == 16'h0100)
                                   ? mboxGERRdAllRcrdDone_Q
                                   : mboxNewReturnCodeSuccess_Q;

  always_ff @(posedge cxlbbs_clk) begin
    if (cxlbbs_rst) begin
      mboxOPyldWrStart_Q <= 1'b0;
    end
    else if (mboxOPyldWrStart_Q) begin
      mboxOPyldWrStart_Q <= 1'b0;
    end
    else if (mboxSetOPyldWrStart) begin
      mboxOPyldWrStart_Q <= 1'b1;
    end
  end

  // Output payload source data mux
  // Output payload length mux
  always_comb begin
    case (cxl_mb_cmd.command_op) inside
      16'h0100: begin mboxPyldSrcDataMux             = mboxPyldSrcDataGetEvRcrds;
                      hyc_new_cxl_mb_cmd.payload_len = mboxGERPayloadLen_Q; end
      16'h0102: begin mboxPyldSrcDataMux             = mboxPyldSrcDataGetEvntIntrPlcy;
                      hyc_new_cxl_mb_cmd.payload_len = 'h4; end
      16'h0300: begin mboxPyldSrcDataMux             = mboxPyldSrcDataGetTimestamp;
                      hyc_new_cxl_mb_cmd.payload_len = 'h8; end
      16'h0400: begin mboxPyldSrcDataMux             = mboxPyldSrcDataGetSupLogs;
                      hyc_new_cxl_mb_cmd.payload_len = 'h1C; end
      16'h0401: begin mboxPyldSrcDataMux             = mboxPyldSrcDataGetLog;
                      hyc_new_cxl_mb_cmd.payload_len = 'h30; end
      16'h4000: begin mboxPyldSrcDataMux             = mboxPyldSrcDataIdentMemDev;
                      hyc_new_cxl_mb_cmd.payload_len = 'h43; end
      16'h4200: begin mboxPyldSrcDataMux             = mboxPyldSrcDataGetHealthInfo;
                      hyc_new_cxl_mb_cmd.payload_len = 'h12; end
      16'h4201: begin mboxPyldSrcDataMux             = mboxPyldSrcDataGetAlertCnfg;
                      hyc_new_cxl_mb_cmd.payload_len = 'h10; end
      default:  begin mboxPyldSrcDataMux             = '{default:0};
                      hyc_new_cxl_mb_cmd.payload_len = 'h0; end
    endcase
  end

  // - Mailbox command determines source data for output payload
  // - Unsupported commands do not write output payload
  // - Currently, all payloads are 72B
  //   - Total of 9 RAM writes (each write is 8B)
  //   - Any unused bytes at end of payload are zero

  always_ff @(posedge cxlbbs_clk) begin
    if (cxlbbs_rst) begin
      mboxPyldSrcDataRdEn_Q <= 1'b0;
    end
    else if (mboxOPyldWrStart_Q) begin
      mboxPyldSrcDataRdEn_Q    <= 1'b1;
      mboxPyldSrcDataRdIdx_Q   <= '0;

      if (cxl_mb_cmd.command_op == 16'h0100) begin
        mboxPyldSrcDataLastIdx_Q <= 'd3;  // Last index for payload header
      end
      else begin
        mboxPyldSrcDataLastIdx_Q <= 'd8;
      end
    end
    if (mboxPyldSrcDataRdEn_Q) begin
      mboxPyldSrcDataRdIdx_Q  <= mboxPyldSrcDataRdIdx_Q + 'd1;

      if (mboxPyldSrcDataRdIdx_Q == mboxPyldSrcDataLastIdx_Q) begin
        mboxPyldSrcDataRdEn_Q <= 1'b0;
      end
    end
  end

  always_ff @(posedge cxlbbs_clk) begin
    if (mboxPyldSrcDataRdEn_Q) begin
      hyc_hw_mbox_ram_wr_data <= mboxPyldSrcDataMux[mboxPyldSrcDataRdIdx_Q];
    end
    else if (mboxGERElogRdDataVld_Q) begin
      hyc_hw_mbox_ram_wr_data <= mboxGERElogRdData_Q;
    end
  end

  assign mboxSetRamWrEn = ~hyc_hw_mbox_ram_wr_en
                          & (mboxPyldSrcDataRdEn_Q | mboxGERElogRdDataVld_Q);

  always_ff @(posedge cxlbbs_clk) begin
    if (cxlbbs_rst) begin
      hyc_hw_mbox_ram_wr_en <= 1'b0;
    end
    else if (mboxSetRamWrEn) begin
      hyc_hw_mbox_ram_wr_en   <= 1'b1;

      if (mboxGERElogRdDataVld_Q) begin
        hyc_hw_mbox_ram_wr_addr <= 'd4;
      end
      else begin
        hyc_hw_mbox_ram_wr_addr <= '0;
      end
    end
    else if (hyc_hw_mbox_ram_wr_en) begin
      hyc_hw_mbox_ram_wr_addr <= hyc_hw_mbox_ram_wr_addr + 'd1;

      if (~mboxPyldSrcDataRdEn_Q & ~mboxGERElogRdDataVld_Q) begin
        hyc_hw_mbox_ram_wr_en <= 1'b0;
      end
    end
  end

  assign mboxPyldLastRamWr = hyc_hw_mbox_ram_wr_en & ~mboxPyldSrcDataRdEn_Q & ~mboxGERRdAllRcrdActive_Q;

  //-----------------
  // Clear doorbell
  //-----------------

  // Pulse load_doorbell one cycle to clear doorbell when:
  // - Last payload RAM write occurs
  // - Any non-success return code generated

  assign mboxSetLoadDoorbell = cxl_mb_ctrl.doorbell & (mboxPyldLastRamWr | mboxNewReturnCodeNonSuccess_Q);

  always_ff @(posedge cxlbbs_clk) begin
    if (cxlbbs_rst) begin
      hyc_load_cxl_mb_ctrl <= '0;
    end
    else if (mboxSetLoadDoorbell) begin
      hyc_load_cxl_mb_ctrl.doorbell <= 1'b1;
    end
    else if (hyc_load_cxl_mb_ctrl.doorbell) begin
      hyc_load_cxl_mb_ctrl.doorbell <= 1'b0;
    end
  end

  assign hyc_new_cxl_mb_ctrl.doorbell = 1'b0;

  //--------------------
  // Get Event Records
  //--------------------

  assign mboxUpdtGetEvRcrdsRegs = mboxPyldRdDataVld & (cxl_mb_cmd.command_op == 16'h0100);

  always_ff @(posedge cxlbbs_clk) begin
    if (mboxUpdtGetEvRcrdsRegs) begin
      mboxGERElogTgtInfo_Q  <= (mbox_ram_dout[7:0] == 'h00);
      mboxGERElogTgtWarn_Q  <= (mbox_ram_dout[7:0] == 'h01);
      mboxGERElogTgtFail_Q  <= (mbox_ram_dout[7:0] == 'h02);
      mboxGERElogTgtFatal_Q <= (mbox_ram_dout[7:0] == 'h03);
    end
  end

  assign mboxGERIPyldParamChkFail_In          =   ~mboxGERElogTgtInfo_Q & ~mboxGERElogTgtWarn_Q
                                                & ~mboxGERElogTgtFail_Q & ~mboxGERElogTgtFatal_Q;
  assign mboxGERIPyldLenChkFail_In            = (cxl_mb_cmd.payload_len != 'h1);
  assign mboxGERIPyldChkPassRdAllRcrdStart_In = ~mboxGERIPyldParamChkFail_In & ~mboxGERIPyldLenChkFail_In;

  always_ff @(posedge cxlbbs_clk) begin
    if (cxlbbs_rst) begin
      mboxGERIPyldChkEn_Q                 <= 1'b0;
      mboxGERUpdtReturnCode_Q             <= 1'b0;
      mboxGERIPyldChkPassRdAllRcrdStart_Q <= 1'b0;
    end
    else if (mboxGERUpdtReturnCode_Q) begin
      mboxGERUpdtReturnCode_Q             <= 1'b0;
      mboxGERIPyldChkPassRdAllRcrdStart_Q <= 1'b0;
    end
    else if (mboxUpdtGetEvRcrdsRegs) begin
      mboxGERIPyldChkEn_Q <= 1'b1;
    end
    else if (mboxGERIPyldChkEn_Q) begin
      mboxGERIPyldChkEn_Q                 <= 1'b0;
      mboxGERUpdtReturnCode_Q             <= 1'b1;
      mboxGERIPyldParamChkFail_Q          <= mboxGERIPyldParamChkFail_In;
      mboxGERIPyldLenChkFail_Q            <= mboxGERIPyldLenChkFail_In;
      mboxGERIPyldChkPassRdAllRcrdStart_Q <= mboxGERIPyldChkPassRdAllRcrdStart_In;
    end
  end

  assign infoElogRdAllRcrdStart  = mboxGERIPyldChkPassRdAllRcrdStart_Q & mboxGERElogTgtInfo_Q;
  assign warnElogRdAllRcrdStart  = mboxGERIPyldChkPassRdAllRcrdStart_Q & mboxGERElogTgtWarn_Q;
  assign failElogRdAllRcrdStart  = mboxGERIPyldChkPassRdAllRcrdStart_Q & mboxGERElogTgtFail_Q;
  assign fatalElogRdAllRcrdStart = mboxGERIPyldChkPassRdAllRcrdStart_Q & mboxGERElogTgtFatal_Q;

  always_ff @(posedge cxlbbs_clk) begin
    if (cxlbbs_rst) begin
      mboxGERRdAllRcrdActive_Q <= 1'b0;
    end
    else if (mboxGERIPyldChkPassRdAllRcrdStart_Q) begin
      mboxGERRdAllRcrdActive_Q <= 1'b1;
    end
    else if (mboxGERRdAllRcrdDone_Q) begin
      mboxGERRdAllRcrdActive_Q <= 1'b0;
    end
  end

  always_comb begin
    case ({mboxGERElogTgtFatal_Q,mboxGERElogTgtFail_Q,mboxGERElogTgtWarn_Q,mboxGERElogTgtInfo_Q}) inside
      4'b0001: begin
                 mboxGERFlagsOvf_In         = infoElogFlagsOvf_Q;
                 mboxGERFlagsMoreEvRcrds_In = infoElogFlagsMoreEvRcrds_Q;
                 mboxGEROvfErrCnt_In        = infoElogOvfErrCnt_Q;
                 mboxGERFirstOvfEvTmstmp_In = infoElogFirstOvfEvTmstmp_Q;
                 mboxGERLastOvfEvTmstmp_In  = infoElogLastOvfEvTmstmp_Q;
                 mboxGEREvRcrdCnt_In        = infoElogEvRcrdCnt_Q;
                 mboxGERElogRdData_In       = infoElogRdData;
                 mboxGERRdAllRcrdDone_In    = infoElogRdAllRcrdDone_Q;
                 mboxGERPayloadLen_In       = infoElogPayloadLen_Q;
               end
      4'b0010: begin
                 mboxGERFlagsOvf_In         = warnElogFlagsOvf_Q;
                 mboxGERFlagsMoreEvRcrds_In = warnElogFlagsMoreEvRcrds_Q;
                 mboxGEROvfErrCnt_In        = warnElogOvfErrCnt_Q;
                 mboxGERFirstOvfEvTmstmp_In = warnElogFirstOvfEvTmstmp_Q;
                 mboxGERLastOvfEvTmstmp_In  = warnElogLastOvfEvTmstmp_Q;
                 mboxGEREvRcrdCnt_In        = warnElogEvRcrdCnt_Q;
                 mboxGERElogRdData_In       = warnElogRdData;
                 mboxGERRdAllRcrdDone_In    = warnElogRdAllRcrdDone_Q;
                 mboxGERPayloadLen_In       = warnElogPayloadLen_Q;
               end
      4'b0100: begin
                 mboxGERFlagsOvf_In         = failElogFlagsOvf_Q;
                 mboxGERFlagsMoreEvRcrds_In = failElogFlagsMoreEvRcrds_Q;
                 mboxGEROvfErrCnt_In        = failElogOvfErrCnt_Q;
                 mboxGERFirstOvfEvTmstmp_In = failElogFirstOvfEvTmstmp_Q;
                 mboxGERLastOvfEvTmstmp_In  = failElogLastOvfEvTmstmp_Q;
                 mboxGEREvRcrdCnt_In        = failElogEvRcrdCnt_Q;
                 mboxGERElogRdData_In       = failElogRdData;
                 mboxGERRdAllRcrdDone_In    = failElogRdAllRcrdDone_Q;
                 mboxGERPayloadLen_In       = failElogPayloadLen_Q;
               end
      4'b1000: begin
                 mboxGERFlagsOvf_In         = fatalElogFlagsOvf_Q;
                 mboxGERFlagsMoreEvRcrds_In = fatalElogFlagsMoreEvRcrds_Q;
                 mboxGEROvfErrCnt_In        = fatalElogOvfErrCnt_Q;
                 mboxGERFirstOvfEvTmstmp_In = fatalElogFirstOvfEvTmstmp_Q;
                 mboxGERLastOvfEvTmstmp_In  = fatalElogLastOvfEvTmstmp_Q;
                 mboxGEREvRcrdCnt_In        = fatalElogEvRcrdCnt_Q;
                 mboxGERElogRdData_In       = fatalElogRdData;
                 mboxGERRdAllRcrdDone_In    = fatalElogRdAllRcrdDone_Q;
                 mboxGERPayloadLen_In       = fatalElogPayloadLen_Q;
               end
      default: begin
                 mboxGERFlagsOvf_In         = fatalElogFlagsOvf_Q;
                 mboxGERFlagsMoreEvRcrds_In = fatalElogFlagsMoreEvRcrds_Q;
                 mboxGEROvfErrCnt_In        = fatalElogOvfErrCnt_Q;
                 mboxGERFirstOvfEvTmstmp_In = fatalElogFirstOvfEvTmstmp_Q;
                 mboxGERLastOvfEvTmstmp_In  = fatalElogLastOvfEvTmstmp_Q;
                 mboxGEREvRcrdCnt_In        = fatalElogEvRcrdCnt_Q;
                 mboxGERElogRdData_In       = fatalElogRdData;
                 mboxGERRdAllRcrdDone_In    = fatalElogRdAllRcrdDone_Q;
                 mboxGERPayloadLen_In       = fatalElogPayloadLen_Q;
               end
    endcase
  end

  always_ff @(posedge cxlbbs_clk) begin
    if (cxlbbs_rst | mboxGERIPyldChkPassRdAllRcrdStart_Q | mboxGERRdAllRcrdStartStg_Q) begin
      mboxGERRdAllRcrdStartStg_Q <= mboxGERIPyldChkPassRdAllRcrdStart_Q;
    end
  end

  // Use staged version of Start to give EvRcrdCnt and PayloadLen time to update
  always_ff @(posedge cxlbbs_clk) begin
    if (mboxGERRdAllRcrdStartStg_Q) begin
      mboxGERFlagsOvf_Q         <= mboxGERFlagsOvf_In;
      mboxGERFlagsMoreEvRcrds_Q <= mboxGERFlagsMoreEvRcrds_In;
      mboxGEROvfErrCnt_Q        <= mboxGEROvfErrCnt_In;
      mboxGERFirstOvfEvTmstmp_Q <= mboxGERFirstOvfEvTmstmp_In;
      mboxGERLastOvfEvTmstmp_Q  <= mboxGERLastOvfEvTmstmp_In;
      mboxGEREvRcrdCnt_Q        <= mboxGEREvRcrdCnt_In;
      mboxGERPayloadLen_Q       <= mboxGERPayloadLen_In;
    end
  end

  assign mboxGERAnyElogRdDataVld = infoElogRdDataVld_Q | warnElogRdDataVld_Q
                                   | failElogRdDataVld_Q | fatalElogRdDataVld_Q;

  always_ff @(posedge cxlbbs_clk) begin
    if (cxlbbs_rst) begin
      mboxGERElogRdDataVld_Q <= 1'b0;
    end
    else if (mboxGERAnyElogRdDataVld) begin
      mboxGERElogRdDataVld_Q <= 1'b1;
      mboxGERElogRdData_Q    <= mboxGERElogRdData_In;
    end
    else if (mboxGERElogRdDataVld_Q) begin
      mboxGERElogRdDataVld_Q <= 1'b0;
    end
  end

  always_ff @(posedge cxlbbs_clk) begin
    if (cxlbbs_rst | mboxGERRdAllRcrdDone_In | mboxGERRdAllRcrdDone_Q) begin
      mboxGERRdAllRcrdDone_Q <= mboxGERRdAllRcrdDone_In;
    end
  end

  //----------------------
  // Clear Event Records
  //----------------------

  // When doorbell set:
  // - Read address 0 of input payload.
  //   - Update Clear Event Records attribute regs
  //   - Start input payload check
  // - Input payload check (mboxCERIPyldChkEn_Q)
  //   - If any attributes are invalid
  //     - Update return code with non-success value
  //     - Stop command sequence and clear doorbell
  //   - If all attributes are valid, start clear records sequence (mboxCERIPyldChkPassStartCER_Q)
  // - Clear records
  //   - If "clear all events" selected, issue clear all records command to targeted event log
  //   - If clearing events by handle, validate first handle (mboxCERStartFirstHndlChk)
  //     - First handle available from first input payload read
  //     - mboxCERS1-S3 stages validate handles
  //       - If handle is valid, S3 issues clear record command to targeted event log
  //       - If handle is not valid, set mboxCERInvldHndlSeen_Q
  //   - If more handles exist, read next input payload address to get next 1-4 handles (mboxCERRdNxtIPyldAddr_Q)
  //   - Continue checking handles and sending clear commands until no more handles
  // - Update return code
  // - Clear doorbell

  assign mboxCERIPyldParamChkFail_In =   (mboxClrEvRcrdsEvLog_Q > 'd3)
                                       | (~mboxClrEvRcrdsClrAllEv_Q & (mboxClrEvRcrdsNumEvRcrdHndl_Q == 'd0))
                                       | ( mboxClrEvRcrdsClrAllEv_Q & (mboxClrEvRcrdsNumEvRcrdHndl_Q != 'd0));

  // If handle count is zero, two input payload lengths are allowed (6 or 8).
  // - CXL spec says "varies" for length of "Event Record Handles" field (Clear Event Records Input Payload table).
  //   - If "varies" means 0-N, when zero handles provided then varies=0 and input payload length is 6.
  // - CXL spec says minimum input payload length is 8 (CXL Device Command Opcodes table).
  //   - When zero handles provided, "Event Record Handles" field is not meaningful but still treated as 2 bytes long
  //     resulting in an input payload length of 8.
  always_comb begin
    case (mboxClrEvRcrdsNumEvRcrdHndl_Q) inside
      8'h0:    mboxCERIPyldLenChkFail_In = (cxl_mb_cmd.payload_len != 'h6) & (cxl_mb_cmd.payload_len != 'h8);
      8'h1:    mboxCERIPyldLenChkFail_In = (cxl_mb_cmd.payload_len != 'h8);
      8'h2:    mboxCERIPyldLenChkFail_In = (cxl_mb_cmd.payload_len != 'hA);
      8'h3:    mboxCERIPyldLenChkFail_In = (cxl_mb_cmd.payload_len != 'hC);
      8'h4:    mboxCERIPyldLenChkFail_In = (cxl_mb_cmd.payload_len != 'hE);
      8'h5:    mboxCERIPyldLenChkFail_In = (cxl_mb_cmd.payload_len != 'h10);
      8'h6:    mboxCERIPyldLenChkFail_In = (cxl_mb_cmd.payload_len != 'h12);
      8'h7:    mboxCERIPyldLenChkFail_In = (cxl_mb_cmd.payload_len != 'h14);
      8'h8:    mboxCERIPyldLenChkFail_In = (cxl_mb_cmd.payload_len != 'h16);
      8'h9:    mboxCERIPyldLenChkFail_In = (cxl_mb_cmd.payload_len != 'h18);
      8'hA:    mboxCERIPyldLenChkFail_In = (cxl_mb_cmd.payload_len != 'h1A);
      8'hB:    mboxCERIPyldLenChkFail_In = (cxl_mb_cmd.payload_len != 'h1C);
      8'hC:    mboxCERIPyldLenChkFail_In = (cxl_mb_cmd.payload_len != 'h1E);
      8'hD:    mboxCERIPyldLenChkFail_In = (cxl_mb_cmd.payload_len != 'h20);
      8'hE:    mboxCERIPyldLenChkFail_In = (cxl_mb_cmd.payload_len != 'h22);
      8'hF:    mboxCERIPyldLenChkFail_In = (cxl_mb_cmd.payload_len != 'h24);
      default: mboxCERIPyldLenChkFail_In = 1'b1;
    endcase
  end

  assign mboxCERIPyldChkFailUpdtRtnCd_In = mboxCERIPyldParamChkFail_In | mboxCERIPyldLenChkFail_In;

  always_ff @(posedge cxlbbs_clk) begin
    if (cxlbbs_rst) begin
      mboxCERIPyldChkEn_Q            <= 1'b0;
      mboxCERIPyldChkFailUpdtRtnCd_Q <= 1'b0;
      mboxCERIPyldChkPassStartCER_Q  <= 1'b0;
    end
    else if (mboxCERIPyldChkFailUpdtRtnCd_Q) begin
      mboxCERIPyldChkFailUpdtRtnCd_Q <= 1'b0;
    end
    else if (mboxCERIPyldChkPassStartCER_Q) begin
      mboxCERIPyldChkPassStartCER_Q  <= 1'b0;
    end
    else if (mboxUpdtClrEvRcrdsRegs & (hyc_hw_mbox_ram_rd_addr == 'd0)) begin
      mboxCERIPyldChkEn_Q <= 1'b1;
    end
    else if (mboxCERIPyldChkEn_Q) begin
      mboxCERIPyldChkEn_Q            <= 1'b0;
      mboxCERIPyldParamChkFail_Q     <= mboxCERIPyldParamChkFail_In;
      mboxCERIPyldLenChkFail_Q       <= mboxCERIPyldLenChkFail_In;

      mboxCERIPyldChkFailUpdtRtnCd_Q <=  mboxCERIPyldChkFailUpdtRtnCd_In;
      mboxCERIPyldChkPassStartCER_Q  <= ~mboxCERIPyldChkFailUpdtRtnCd_In;
    end
  end

  assign mboxUpdtClrEvRcrdsRegs = mboxPyldRdDataVld & (cxl_mb_cmd.command_op == 16'h0101);

  always_ff @(posedge cxlbbs_clk) begin
    if (mboxUpdtClrEvRcrdsRegs) begin
      if (hyc_hw_mbox_ram_rd_addr == 'd0) begin
        mboxClrEvRcrdsEvLog_Q         <= mbox_ram_dout[7:0];    // Byte[0]
        mboxClrEvRcrdsClrAllEv_Q      <= mbox_ram_dout[8];      // Byte[1], Bit[0]
        mboxClrEvRcrdsNumEvRcrdHndl_Q <= mbox_ram_dout[23:16];  // Byte[2]
        mboxClrEvRcrdsEvRcrdHndl_Q[0] <= mbox_ram_dout[63:48];  // Byte[7:6]
      end
      else if (hyc_hw_mbox_ram_rd_addr != 'd0) begin
        mboxClrEvRcrdsEvRcrdHndl_Q[0] <= mbox_ram_dout[15:0];   // Byte[1:0]
        mboxClrEvRcrdsEvRcrdHndl_Q[1] <= mbox_ram_dout[31:16];  // Byte[3:2]
        mboxClrEvRcrdsEvRcrdHndl_Q[2] <= mbox_ram_dout[47:32];  // Byte[5:4]
        mboxClrEvRcrdsEvRcrdHndl_Q[3] <= mbox_ram_dout[63:48];  // Byte[7:6]
      end
    end
  end

  always_ff @(posedge cxlbbs_clk) begin
    if (cxlbbs_rst) begin
      mboxClrEvRcrdsFirstCyc_Q <= 1'b0;
    end
    else if (mboxClrEvRcrdsFirstCyc_Q) begin
      mboxClrEvRcrdsFirstCyc_Q <= 1'b0;
    end
    else if (mboxCERIPyldChkPassStartCER_Q) begin
      mboxClrEvRcrdsFirstCyc_Q <= 1'b1;
    end
  end

  always_ff @(posedge cxlbbs_clk) begin
    if (cxlbbs_rst) begin
      mboxCERStartNxtHndlChk_Q <= 1'b0;
    end
    else if (mboxCERStartNxtHndlChk_Q) begin
      mboxCERStartNxtHndlChk_Q <= 1'b0;
    end
    else if (mboxUpdtClrEvRcrdsRegs & (hyc_hw_mbox_ram_rd_addr != 'd0)) begin
      mboxCERStartNxtHndlChk_Q <= 1'b1;
    end
  end

  always_ff @(posedge cxlbbs_clk) begin
    if (mboxClrEvRcrdsFirstCyc_Q) begin
      mboxCERElogTgtInfo_Q  <= (mboxClrEvRcrdsEvLog_Q == 'h00);
      mboxCERElogTgtWarn_Q  <= (mboxClrEvRcrdsEvLog_Q == 'h01);
      mboxCERElogTgtFail_Q  <= (mboxClrEvRcrdsEvLog_Q == 'h02);
      mboxCERElogTgtFatal_Q <= (mboxClrEvRcrdsEvLog_Q == 'h03);
    end
  end

  assign mboxCERStartFirstHndlChk = mboxClrEvRcrdsFirstCyc_Q & ~mboxClrEvRcrdsClrAllEv_Q & (mboxClrEvRcrdsNumEvRcrdHndl_Q != 'd0);

  assign mboxCERRdHndlCntMatchTotalCnt = (mboxCERRdHndlCnt_Q == mboxClrEvRcrdsNumEvRcrdHndl_Q);

  always_ff @(posedge cxlbbs_clk) begin
    if (cxlbbs_rst) begin
      mboxCERRdHndlEn_Q       <= 1'b0;
      mboxCERRdHndlEnNxtCyc_Q <= 1'b0;
      mboxCERRdNxtIPyldAddr_Q <= 1'b0;
    end
    else if (mboxCERRdHndlEnNxtCyc_Q) begin
      mboxCERRdHndlEnNxtCyc_Q <= 1'b0;
      mboxCERRdHndlEn_Q  <= 1'b1;
      mboxCERRdHndlIdx_Q <= mboxCERRdHndlIdx_Q + 'd1;
      mboxCERRdHndlCnt_Q <= mboxCERRdHndlCnt_Q + 'd1;
    end
    else if (mboxCERRdNxtIPyldAddr_Q) begin
      mboxCERRdNxtIPyldAddr_Q <= 1'b0;
    end
    else if (mboxCERRdHndlEn_Q) begin
      if (mboxCERRdHndlCntMatchTotalCnt) begin
        mboxCERRdHndlEn_Q <= 1'b0;
      end
      else if (mboxCERRdHndlIdx_Q == mboxCERLastRdHndlIdx_Q) begin
        mboxCERRdHndlEn_Q       <= 1'b0;
        mboxCERRdNxtIPyldAddr_Q <= 1'b1;
      end
      // If more handles available to read, delay read for one cycle to allow current "clear event record"
      // time to update ordered handle list.
      else begin
        mboxCERRdHndlEn_Q       <= 1'b0;
        mboxCERRdHndlEnNxtCyc_Q <= 1'b1;
      end
    end
    else if (mboxCERStartFirstHndlChk) begin
      mboxCERRdHndlEn_Q      <= 1'b1;
      mboxCERRdHndlIdx_Q     <= '0;
      mboxCERLastRdHndlIdx_Q <= '0;
      mboxCERRdHndlCnt_Q     <= 'd1;
    end
    else if (mboxCERStartNxtHndlChk_Q) begin
      mboxCERRdHndlEn_Q      <= 1'b1;
      mboxCERRdHndlIdx_Q     <= '0;
      mboxCERLastRdHndlIdx_Q <= 'd3;
      mboxCERRdHndlCnt_Q     <= mboxCERRdHndlCnt_Q + 'd1;
    end
  end

  // mboxCERS1-S3 checks if handle is valid
  // - Handle: [15:12] Always 'h0
  //           [11:8]  Event log: 'h1=Info, 'h2=Warning, 'h4=Failure, 'h8=Fatal
  //           [7:4]   Handle ID: 'h0 - 'hF
  //           [3:0]   Always 'h0
  // - S1 checks handle [15:12], [11:8], [3:0]
  // - S2 checks handle [7:4]
  //   Handle ID specified must be in use for check to pass
  // - S3 issues clear command to event log if handle check passes
  //   - If handle check fails, clear command is not issued for handle.
  //     Handle checking continues (if any more exist), and clear command
  //     will issue for any subsequent valid handles.

  assign mboxCERS1Hndl_In = mboxCERRdHndlIdx_Q[1]
                            ? mboxCERRdHndlIdx_Q[0]
                              ? mboxClrEvRcrdsEvRcrdHndl_Q[3]
                              : mboxClrEvRcrdsEvRcrdHndl_Q[2]
                            : mboxCERRdHndlIdx_Q[0]
                              ? mboxClrEvRcrdsEvRcrdHndl_Q[1]
                              : mboxClrEvRcrdsEvRcrdHndl_Q[0];

  assign mboxCERS1LastHndlRd_In = mboxCERRdHndlCntMatchTotalCnt;

  always_ff @(posedge cxlbbs_clk) begin
    if (cxlbbs_rst) begin
      mboxCERS1Valid_Q <= 1'b0;
    end
    else if (mboxCERRdHndlEn_Q) begin
      mboxCERS1Valid_Q      <= 1'b1;
      mboxCERS1Hndl_Q       <= mboxCERS1Hndl_In;
      mboxCERS1LastHndlRd_Q <= mboxCERS1LastHndlRd_In;
    end
    else if (mboxCERS1Valid_Q) begin
      mboxCERS1Valid_Q <= 1'b0;
    end
  end

  assign mboxCERS1HndlLegalIfRcrdVld =   (mboxCERS1Hndl_Q[15:12] == 4'h0)
                                       & (  (mboxCERElogTgtInfo_Q  & (mboxCERS1Hndl_Q[11:8] == 4'h1))
                                          | (mboxCERElogTgtWarn_Q  & (mboxCERS1Hndl_Q[11:8] == 4'h2))
                                          | (mboxCERElogTgtFail_Q  & (mboxCERS1Hndl_Q[11:8] == 4'h4))
                                          | (mboxCERElogTgtFatal_Q & (mboxCERS1Hndl_Q[11:8] == 4'h8))
                                         )
                                       & (mboxCERS1Hndl_Q[3:0] == 4'h0);

  assign mboxCERS2ElogHndlInUse_In = mboxClrEvRcrdsEvLog_Q[1]
                                     ? mboxClrEvRcrdsEvLog_Q[0]
                                       ? fatalElogHndlInUse_Q
                                       : failElogHndlInUse_Q
                                     : mboxClrEvRcrdsEvLog_Q[0]
                                       ? warnElogHndlInUse_Q
                                       : infoElogHndlInUse_Q;

  always_ff @(posedge cxlbbs_clk) begin
    if (cxlbbs_rst) begin
      mboxCERS2Valid_Q <= 1'b0;
    end
    else if (mboxCERS1Valid_Q) begin
      mboxCERS2Valid_Q              <= 1'b1;
      mboxCERS2Hndl_Q               <= mboxCERS1Hndl_Q;
      mboxCERS2HndlLegalIfRcrdVld_Q <= mboxCERS1HndlLegalIfRcrdVld;
      mboxCERS2ElogHndlInUse_Q      <= mboxCERS2ElogHndlInUse_In;
      mboxCERS2LastHndlRd_Q         <= mboxCERS1LastHndlRd_Q;
    end
    else if (mboxCERS2Valid_Q) begin
      mboxCERS2Valid_Q <= 1'b0;
    end
  end

  // If HndlInUse=1, then handle 0 is valid.  Check CER handle is 0.
  assign mboxCERS2HndlLegal = mboxCERS2ElogHndlInUse_Q & (mboxCERS2Hndl_Q[7:4] == '0) & mboxCERS2HndlLegalIfRcrdVld_Q;

  always_ff @(posedge cxlbbs_clk) begin
    if (cxlbbs_rst) begin
      mboxCERS3Valid_Q <= 1'b0;
    end
    else if (mboxCERS2Valid_Q) begin
      mboxCERS3Valid_Q       <= 1'b1;
      mboxCERS3Hndl_Q        <= mboxCERS2Hndl_Q;
      mboxCERS3HndlLegal_Q   <= mboxCERS2HndlLegal;
      mboxCERS3LastHndlRd_Q  <= mboxCERS2LastHndlRd_Q;
    end
    else if (mboxCERS3Valid_Q) begin
      mboxCERS3Valid_Q <= 1'b0;
    end
  end

  assign infoElogClrRcrdEn  = mboxCERS3Valid_Q & mboxCERS3HndlLegal_Q & mboxCERElogTgtInfo_Q;
  assign warnElogClrRcrdEn  = mboxCERS3Valid_Q & mboxCERS3HndlLegal_Q & mboxCERElogTgtWarn_Q;
  assign failElogClrRcrdEn  = mboxCERS3Valid_Q & mboxCERS3HndlLegal_Q & mboxCERElogTgtFail_Q;
  assign fatalElogClrRcrdEn = mboxCERS3Valid_Q & mboxCERS3HndlLegal_Q & mboxCERElogTgtFatal_Q;

  always_ff @(posedge cxlbbs_clk) begin
    if (mboxCERStartFirstHndlChk) begin
      mboxCERInvldHndlSeen_Q <= 1'b0;
    end
    else if (mboxCERS3Valid_Q & ~mboxCERS3HndlLegal_Q) begin
      mboxCERInvldHndlSeen_Q <= 1'b1;
    end
  end

  assign mboxCERSetLastHndlUpdtRtnCd = mboxCERS3Valid_Q & mboxCERS3LastHndlRd_Q;

  always_ff @(posedge cxlbbs_clk) begin
    if (cxlbbs_rst | mboxCERLastHndlUpdtRtnCd_Q) begin
     mboxCERLastHndlUpdtRtnCd_Q <= 1'b0;
    end
    else if (mboxCERSetLastHndlUpdtRtnCd) begin
     mboxCERLastHndlUpdtRtnCd_Q <= 1'b1;
    end
  end

  assign mboxCERSetClrAllRcrdEn = mboxClrEvRcrdsFirstCyc_Q & mboxClrEvRcrdsClrAllEv_Q;

  always_ff @(posedge cxlbbs_clk) begin
    if (cxlbbs_rst | mboxCERClrAllRcrdEn_Q) begin
      mboxCERClrAllRcrdEn_Q <= 1'b0;
    end
    else if (mboxCERSetClrAllRcrdEn) begin
      mboxCERClrAllRcrdEn_Q <= 1'b1;
    end
  end

  assign infoElogClrAllRcrdEn  = mboxCERClrAllRcrdEn_Q & mboxCERElogTgtInfo_Q;
  assign warnElogClrAllRcrdEn  = mboxCERClrAllRcrdEn_Q & mboxCERElogTgtWarn_Q;
  assign failElogClrAllRcrdEn  = mboxCERClrAllRcrdEn_Q & mboxCERElogTgtFail_Q;
  assign fatalElogClrAllRcrdEn = mboxCERClrAllRcrdEn_Q & mboxCERElogTgtFatal_Q;

  assign mboxCERSetUpdtReturnCode =   mboxCERLastHndlUpdtRtnCd_Q
                                    | mboxCERClrAllRcrdEn_Q
                                    | mboxCERIPyldChkFailUpdtRtnCd_Q;

  always_ff @(posedge cxlbbs_clk) begin
    if (cxlbbs_rst | mboxCERUpdtReturnCode_Q) begin
      mboxCERUpdtReturnCode_Q <= 1'b0;
    end
    else if (mboxCERSetUpdtReturnCode) begin
      mboxCERUpdtReturnCode_Q <= 1'b1;
    end
  end

  //-----------------------------
  // Event Interrupt Policy Reg
  //-----------------------------

  // Read addr qualification not needed because only addr 0 is used
  assign mboxEvntIntrPlcyEnb = mboxPyldRdDataVld & (cxl_mb_cmd.command_op == 16'h0103);

  always_ff @(posedge cxlbbs_clk) begin
    if (cxlbbs_rst) begin
      mboxEvntIntrPlcy_Q <= '0;
    end
    else if (mboxEvntIntrPlcyEnb) begin
      mboxEvntIntrPlcy_Q <= mbox_ram_dout[31:0];
    end
  end

  //--------------------------
  // Alert Configuration Reg
  //--------------------------

  // - If CVME fields are valid, then update CVME Enable Alert and CVME Warning Threshold.
  //   - The CVME fields valid indication is contained in addr 0 of input payload.
  //   - Need to capture CVME fields valid indication for use with addr 1 of input payload.
  // - CVME Enable Alert and CVME Warning Threshold are in different addrs of input payload.
  //   - Save next CVME Enable Alert value and update official value same cycle CVME Warning Threshold updated.
  //   - This ensures threshold checking does not occur until threshold warning value is valid.

  assign mboxSetAlertCnfgCVMEFldsVld_In = mbox_ram_dout[3];

  assign mboxUpdtAlertCnfg       = mboxPyldRdDataVld & (cxl_mb_cmd.command_op == 16'h4202);
  assign mboxAlertCnfgCVMEEnb[0] = mboxUpdtAlertCnfg & mboxSetAlertCnfgCVMEFldsVld_In & (hyc_hw_mbox_ram_rd_addr == 'd0);
  assign mboxAlertCnfgCVMEEnb[1] = mboxUpdtAlertCnfg & mboxSetAlertCnfgCVMEFldsVld_Q  & (hyc_hw_mbox_ram_rd_addr == 'd1);

  always_ff @(posedge cxlbbs_clk) begin
    if (cxlbbs_rst) begin
      mboxSetAlertCnfgCVMEFldsVld_Q <= 1'b0;
    end
    else if (mboxAlertCnfgCVMEEnb[0]) begin
      mboxAlertCnfgCVMEEnAlertNext_Q <= mbox_ram_dout[11];
      mboxSetAlertCnfgCVMEFldsVld_Q  <= mboxSetAlertCnfgCVMEFldsVld_In;
    end
    else if (mboxAlertCnfgCVMEEnb[1]) begin
      mboxSetAlertCnfgCVMEFldsVld_Q <= 1'b0;  // Init FldsVld=0 for next set alert
    end
  end

  always_ff @(posedge cxlbbs_clk) begin
    if (cxlbbs_rst) begin
      mboxAlertCnfgCVMEEnAlert_Q  <= 1'b0;
      mboxAlertCnfgCVMEWarnThld_Q <= '0;
    end
    else if (mboxAlertCnfgCVMEEnb[1]) begin
      mboxAlertCnfgCVMEEnAlert_Q  <= mboxAlertCnfgCVMEEnAlertNext_Q;
      mboxAlertCnfgCVMEWarnThld_Q <= mbox_ram_dout[15:0];
    end
  end

  // Calculate if CVME warning threshold reached
  assign mboxSetCVMECntGTEWarnThld = mboxAlertCnfgCVMEEnAlert_Q & (mcAllChanSBECnt_Q >= mboxAlertCnfgCVMEWarnThld_Q)
                                     & ~mboxCVMECntGTEWarnThld_Q;

  // After CVME warning threshold reached, clear threshold reached if:
  // 1. Threshold reporting disabled
  // 2. Threshold changed to a value higher than current SBE count
  assign mboxClrCVMECntGTEWarnThld = mboxCVMECntGTEWarnThld_Q
                                     & (~mboxAlertCnfgCVMEEnAlert_Q | (mcAllChanSBECnt_Q < mboxAlertCnfgCVMEWarnThld_Q));

  always_ff @(posedge cxlbbs_clk) begin
    if (cxlbbs_rst | mboxClrCVMECntGTEWarnThld) begin
      mboxCVMECntGTEWarnThld_Q <= 1'b0;
    end
    else if (mboxSetCVMECntGTEWarnThld) begin
      mboxCVMECntGTEWarnThld_Q <= 1'b1;
    end
  end

  //-------------------------------------
  // Timestamp Logic - BBS clock domain
  //-------------------------------------

  assign mboxGetTimestampNewReq = mboxSetTimestampSeen_Q & ~mboxGetTimestampReq_Q & ~mboxGetTimestampAck_S4;

  always_ff @(posedge cxlbbs_clk) begin
    if (cxlbbs_rst) begin
      mboxGetTimestampReq_Q <= 1'b0;
    end
    else if (mboxGetTimestampNewReq) begin
      mboxGetTimestampReq_Q <= 1'b1;
    end
    else if (mboxGetTimestampSyncDone) begin
      mboxGetTimestampReq_Q <= 1'b0;
    end
  end

  // Sync set timestamp ack to bbs clk domain
  always_ff @(posedge cxlbbs_clk) begin
    mboxGetTimestampAck_S1 <= mboxGetTimestampReq_S4_rclk;
    mboxGetTimestampAck_S2 <= mboxGetTimestampAck_S1;
    mboxGetTimestampAck_S3 <= mboxGetTimestampAck_S2;
    mboxGetTimestampAck_S4 <= mboxGetTimestampAck_S3;
  end

  assign mboxGetTimestampSyncDone = mboxGetTimestampAck_S3 & ~mboxGetTimestampAck_S4;

  // Reset forces timestamp sample to zero
  // - If timestamp has not been updated via set timestamp, get timestamp must return timestamp of zero
  always_ff @(posedge cxlbbs_clk) begin
    if (cxlbbs_rst) begin
      mboxTimestampSmpl_Q <= '0;
    end
    else if (mboxGetTimestampSyncDone & mboxSetTimestampSeen_Q) begin
      mboxTimestampSmpl_Q <= mboxTimestampSmpl_Q_rclk;
    end
  end

  // Read addr qualification not needed because only addr 0 is used
  assign mboxSetTimestampNewValRdy = mboxPyldRdDataVld & (cxl_mb_cmd.command_op == 16'h0301);

  always_ff @(posedge cxlbbs_clk) begin
    if (mboxSetTimestampNewValRdy) begin
      mboxSetTimestampNewVal_Q <= mbox_ram_dout[63:0];
    end
  end

  always_ff @(posedge cxlbbs_clk) begin
    if (cxlbbs_rst) begin
      mboxSetTimestampReq_Q <= 1'b0;
    end
    else if (mboxSetTimestampNewValRdy) begin
      mboxSetTimestampReq_Q <= 1'b1;
    end
    else if (mboxSetTimestampSyncDone) begin
      mboxSetTimestampReq_Q <= 1'b0;
    end
  end

  // Sync set timestamp ack to bbs clk domain
  always_ff @(posedge cxlbbs_clk) begin
    mboxSetTimestampAck_S1 <= mboxSetTimestampReq_S3_rclk;
    mboxSetTimestampAck_S2 <= mboxSetTimestampAck_S1;
    mboxSetTimestampAck_S3 <= mboxSetTimestampAck_S2;
    mboxSetTimestampAck_S4 <= mboxSetTimestampAck_S3;
  end

  assign mboxSetTimestampSyncDone  = mboxSetTimestampAck_S3 & ~mboxSetTimestampAck_S4;

  always_ff @(posedge cxlbbs_clk) begin
    if (cxlbbs_rst) begin
      mboxSetTimestampSeen_Q <= 1'b0;
    end
    else if (mboxSetTimestampSyncDone) begin
      mboxSetTimestampSeen_Q <= 1'b1;
    end
  end

  //-------------------------------------
  // Timestamp Logic - Ref clock domain
  //-------------------------------------

  // 125MHz clock
  assign ts_ref_clk = sbr_clk_i;

  // Sync get timestamp req to ref clk domain
  always_ff @(posedge ts_ref_clk) begin
    mboxGetTimestampReq_S1_rclk <= mboxGetTimestampReq_Q;
    mboxGetTimestampReq_S2_rclk <= mboxGetTimestampReq_S1_rclk;
    mboxGetTimestampReq_S3_rclk <= mboxGetTimestampReq_S2_rclk;
    mboxGetTimestampReq_S4_rclk <= mboxGetTimestampReq_S3_rclk;
  end

  assign mboxGetTimestampSmplEnb_rclk = mboxGetTimestampReq_S3_rclk & ~mboxGetTimestampReq_S4_rclk;

  always_ff @(posedge ts_ref_clk) begin
    if (mboxGetTimestampSmplEnb_rclk) begin
      mboxTimestampSmpl_Q_rclk <= mboxTimestamp_Q_rclk;
    end
  end

  // Sync set timestamp req to ref clk domain
  always_ff @(posedge ts_ref_clk) begin
    mboxSetTimestampReq_S1_rclk <= mboxSetTimestampReq_Q;
    mboxSetTimestampReq_S2_rclk <= mboxSetTimestampReq_S1_rclk;
    mboxSetTimestampReq_S3_rclk <= mboxSetTimestampReq_S2_rclk;
    mboxSetTimestampReq_S4_rclk <= mboxSetTimestampReq_S3_rclk;
  end

  assign mboxTimestampWrEn_rclk = mboxSetTimestampReq_S3_rclk & ~mboxSetTimestampReq_S4_rclk;

  // Increment of 'd8 based on 125MHz clock (1 cycle = 8ns)
  always_ff @(posedge ts_ref_clk) begin
    if (mboxTimestampWrEn_rclk) begin
      mboxTimestamp_Q_rclk <= mboxSetTimestampNewVal_Q;
    end
    else begin
      mboxTimestamp_Q_rclk <= mboxTimestamp_Q_rclk + 'd8;
    end
  end

  //---------------------------------
  // Memory Controller Error Counts
  //---------------------------------

  always_comb begin
    mcAllChanSBESum       = '0;
    mcAllChanDBESum       = '0;
    mcAllChanPoisonRtnSum = '0;

    mcAllChanNewSBE       = 1'b0;
    mcAllChanNewDBE       = 1'b0;
    mcAllChanNewPoisonRtn = 1'b0;

    for (int i=0; i<cxlip_top_pkg::MC_CHANNEL; i++) begin
      mcAllChanSBESum       += mc_err_cnt[i].SBECnt;
      mcAllChanDBESum       += mc_err_cnt[i].DBECnt;
      mcAllChanPoisonRtnSum += mc_err_cnt[i].PoisonRtnCnt;

      mcAllChanNewSBE       |= mc_err_cnt[i].NewSBE;
      mcAllChanNewDBE       |= mc_err_cnt[i].NewDBE;
      mcAllChanNewPoisonRtn |= mc_err_cnt[i].NewPoisonRtn;
    end
  end

  // Corrected error count reported for mailbox commands saturates at 0xFFFF_FFFF.
  // Disable subsequent count updates if count saturates.
  assign mcAllChanSBESaturate = mcAllChanSBESum[32];
  assign mcAllChanSBECntEnb   = mcAllChanNewSBE & ~mcAllChanSBECntHold_Q;

  always_ff @(posedge cxlbbs_clk) begin
    if (cxlbbs_rst) begin
      mcAllChanSBECnt_Q     <= '0;
      mcAllChanSBECntHold_Q <= 1'b0;
    end
    else if (mcAllChanSBECntEnb) begin
      if (mcAllChanSBESaturate) begin
        mcAllChanSBECnt_Q     <= '1;
        mcAllChanSBECntHold_Q <= 1'b1;
      end
      else begin
        mcAllChanSBECnt_Q <= mcAllChanSBESum;
      end
    end
  end

  always_ff @(posedge cxlbbs_clk) begin
    if (cxlbbs_rst) begin
      mcAllChanDBECnt_Q <= '0;
    end
    else if (mcAllChanNewDBE) begin
      mcAllChanDBECnt_Q <= mcAllChanDBESum;
    end
  end

  always_ff @(posedge cxlbbs_clk) begin
    if (cxlbbs_rst) begin
      mcAllChanPoisonRtnCnt_Q <= '0;
    end
    else if (mcAllChanNewPoisonRtn) begin
      mcAllChanPoisonRtnCnt_Q <= mcAllChanPoisonRtnSum;
    end
  end

  //-------------------------------------
  // Get Event Records - Output Payload
  // Header payload only
  //-------------------------------------

  assign mboxPyldSrcDataGetEvRcrds[0] = {mboxGERFirstOvfEvTmstmp_Q[31:0],mboxGEROvfErrCnt_Q,14'd0,mboxGERFlagsMoreEvRcrds_Q,mboxGERFlagsOvf_Q};  // Byte[7:0]
  assign mboxPyldSrcDataGetEvRcrds[1] = {mboxGERLastOvfEvTmstmp_Q[31:0],mboxGERFirstOvfEvTmstmp_Q[63:32]};                                       // Byte[15:8]
  assign mboxPyldSrcDataGetEvRcrds[2] = {16'd0,mboxGEREvRcrdCnt_Q,mboxGERLastOvfEvTmstmp_Q[63:32]};                                              // Byte[23:16]
  assign mboxPyldSrcDataGetEvRcrds[3] = '0;                                                                                                      // Byte[31:24]
  assign mboxPyldSrcDataGetEvRcrds[4] = '0;
  assign mboxPyldSrcDataGetEvRcrds[5] = '0;
  assign mboxPyldSrcDataGetEvRcrds[6] = '0;
  assign mboxPyldSrcDataGetEvRcrds[7] = '0;
  assign mboxPyldSrcDataGetEvRcrds[8] = '0;

  //----------------------------------------------
  // Get Event Interrupt Policy - Output Payload
  //----------------------------------------------

  // Byte[0] = Informational Event Log Interrupt Settings
  // Byte[1] = Warning Event Log Interrupt Settings
  // Byte[2] = Failure Event Log Interrupt Settings
  // Byte[3] = Fatal Event Log Interrupt Settings

  assign mboxPyldSrcDataGetEvntIntrPlcy[0] = {'0, mboxEvntIntrPlcy_Q};  // Byte[3:0]
  assign mboxPyldSrcDataGetEvntIntrPlcy[1] = '0;
  assign mboxPyldSrcDataGetEvntIntrPlcy[2] = '0;                       
  assign mboxPyldSrcDataGetEvntIntrPlcy[3] = '0;
  assign mboxPyldSrcDataGetEvntIntrPlcy[4] = '0;
  assign mboxPyldSrcDataGetEvntIntrPlcy[5] = '0;
  assign mboxPyldSrcDataGetEvntIntrPlcy[6] = '0;
  assign mboxPyldSrcDataGetEvntIntrPlcy[7] = '0;
  assign mboxPyldSrcDataGetEvntIntrPlcy[8] = '0;

  //---------------------------------
  // Get Timestamp - Output Payload
  //---------------------------------

  // Byte[7:0] = Timestamp

  assign mboxPyldSrcDataGetTimestamp[0] = mboxTimestampSmpl_Q;  // Byte[7:0]
  assign mboxPyldSrcDataGetTimestamp[1] = '0;
  assign mboxPyldSrcDataGetTimestamp[2] = '0;                       
  assign mboxPyldSrcDataGetTimestamp[3] = '0;
  assign mboxPyldSrcDataGetTimestamp[4] = '0;
  assign mboxPyldSrcDataGetTimestamp[5] = '0;
  assign mboxPyldSrcDataGetTimestamp[6] = '0;
  assign mboxPyldSrcDataGetTimestamp[7] = '0;
  assign mboxPyldSrcDataGetTimestamp[8] = '0;

  //--------------------------------------
  // Get Supported Logs - Output Payload
  //--------------------------------------

  // Byte[1:0]   = Number of supported log entries
  //               One log entry supported: Command Effects Log (CEL)
  // Byte[7:2]   = Reserved
  // Byte[15:8]  = Supported log entry 1: Log identifier (high 8 bytes - big endian)
  //                                      UUID = CEL
  // Byte[23:16] = Supported log entry 1: Log identifier (low 8 bytes - big endian)
  //                                      UUID = CEL
  // Byte[27:24] = Supported log entry 1: Log size
  //                                      12 commands supported: 12 x 4B = 48B

  assign mboxPyldSrcDataGetSupLogs[0] = 64'h0000_0000_0000_0001;  // Byte[7:0]
  assign mboxPyldSrcDataGetSupLogs[1] = 64'h784B_41BF_B5C0_A90D;  // Byte[15:8]
  assign mboxPyldSrcDataGetSupLogs[2] = 64'h173F_3B62_B196_798F;  // Byte[23:16]
  assign mboxPyldSrcDataGetSupLogs[3] = 64'h0000_0000_0000_0030;  // Byte[27:24]
  assign mboxPyldSrcDataGetSupLogs[4] = '0;
  assign mboxPyldSrcDataGetSupLogs[5] = '0;
  assign mboxPyldSrcDataGetSupLogs[6] = '0;
  assign mboxPyldSrcDataGetSupLogs[7] = '0;
  assign mboxPyldSrcDataGetSupLogs[8] = '0;

  //---------------------------
  // Get Log - Output Payload
  //---------------------------

  // Byte[1:0]   = Command  1 CEL Entry: Opcode         (0x0100 - Get Event Records)
  // Byte[3:2]   = Command  1 CEL Entry: Command Effect (0x0000 - No command effects)
  // Byte[5:4]   = Command  2 CEL Entry: Opcode         (0x0101 - Clear Event Records)
  // Byte[7:6]   = Command  2 CEL Entry: Command Effect (0x0010 - Immediate Log Change)
  // Byte[9:8]   = Command  3 CEL Entry: Opcode         (0x0102 - Get Event Interrupt Policy)
  // Byte[11:10] = Command  3 CEL Entry: Command Effect (0x0000 - No command effects)
  // Byte[13:12] = Command  4 CEL Entry: Opcode         (0x0103 - Set Event Interrupt Policy)
  // Byte[15:14] = Command  4 CEL Entry: Command Effect (0x0000 - No command effects)
  // Byte[17:16] = Command  5 CEL Entry: Opcode         (0x0300 - Get Timestamp)
  // Byte[19:18] = Command  5 CEL Entry: Command Effect (0x0000 - No command effects)
  // Byte[21:20] = Command  6 CEL Entry: Opcode         (0x0301 - Set Timestamp)
  // Byte[23:22] = Command  6 CEL Entry: Command Effect (0x0008 - Immediate Policy Change)
  // Byte[25:24] = Command  7 CEL Entry: Opcode         (0x0400 - Get Supported Logs)
  // Byte[27:26] = Command  7 CEL Entry: Command Effect (0x0000 - No command effects)
  // Byte[29:28] = Command  8 CEL Entry: Opcode         (0x0401 - Get Log)
  // Byte[31:30] = Command  8 CEL Entry: Command Effect (0x0000 - No command effects)
  // Byte[33:32] = Command  9 CEL Entry: Opcode         (0x4000 - Identify Memory Device)
  // Byte[35:34] = Command  9 CEL Entry: Command Effect (0x0000 - No command effects)
  // Byte[37:36] = Command 10 CEL Entry: Opcode         (0x4200 - Get Health Info)
  // Byte[39:38] = Command 10 CEL Entry: Command Effect (0x0000 - No command effects)
  // Byte[41:40] = Command 11 CEL Entry: Opcode         (0x4201 - Get Alert Configuration)
  // Byte[43:42] = Command 11 CEL Entry: Command Effect (0x0000 - No command effects)
  // Byte[45:44] = Command 12 CEL Entry: Opcode         (0x4202 - Set Alert Configuration)
  // Byte[47:46] = Command 12 CEL Entry: Command Effect (0x0008 - Immediate Policy Change)

  assign mboxPyldSrcDataGetLog[0] = 64'h0010_0101_0000_0100;  // Byte[7:0]
  assign mboxPyldSrcDataGetLog[1] = 64'h0000_0103_0000_0102;  // Byte[15:8]
  assign mboxPyldSrcDataGetLog[2] = 64'h0008_0301_0000_0300;  // Byte[23:16]
  assign mboxPyldSrcDataGetLog[3] = 64'h0000_0401_0000_0400;  // Byte[31:24]
  assign mboxPyldSrcDataGetLog[4] = 64'h0000_4200_0000_4000;  // Byte[39:32]
  assign mboxPyldSrcDataGetLog[5] = 64'h0008_4202_0000_4201;  // Byte[47:40]
  assign mboxPyldSrcDataGetLog[6] = '0;
  assign mboxPyldSrcDataGetLog[7] = '0;
  assign mboxPyldSrcDataGetLog[8] = '0;

  //------------------------------------------
  // Identify Memory Device - Output Payload
  //------------------------------------------

  // Byte[15:0]  = FW Revision = 0
  //               Mailbox FW not supported
  // Byte[23:16] = Total Capacity = 0x100
  //               Memory in multiples of 256: 64GB = 256MB x 256
  // Byte[31:24] = Volatile Only Capacity = 0x100
  //               Memory in multiples of 256: 64GB = 256MB x 256
  // Byte[39:32] = Persistent Only Capacity = 0
  // Byte[47:40] = Partition Alignment = 0
  //               Amount of memory that can be partitioned as either volatile or persistent
  // Byte[49:48] = Informational Event Log Size = 1
  //               Number of events device can store before overflow
  // Byte[51:50] = Warning Event Log Size = 1
  //               Number of events device can store before overflow
  // Byte[53:52] = Failure Event Log Size = 1
  //               Number of events device can store before overflow
  // Byte[55:54] = Fatal Event Log Size = 1
  //               Number of events device can store before overflow
  // Byte[59:56] = LSA Size = 0
  //               Not used (persistent memory feature)
  // Byte[62:60] = Poison List Maximum Media Error Records = 0
  //               Not used (persistent memory feature)
  // Byte[64:63] = Inject Poison Limit = 0
  //               Poison injection not supported (0 = no limit)
  // Byte[65]    = Poison Handling Capabilities = 0
  //               No capabilities advertised
  // Byte[66]    = QoS Telemetry Capabilities = 0
  //               No capabilities advertised

  assign mboxPyldSrcDataIdentMemDev[0] = '0;                       // Byte[7:0]
  assign mboxPyldSrcDataIdentMemDev[1] = '0;                       // Byte[15:8]
  assign mboxPyldSrcDataIdentMemDev[2] = 64'h0000_0000_0000_0100;  // Byte[23:16]
  assign mboxPyldSrcDataIdentMemDev[3] = 64'h0000_0000_0000_0100;  // Byte[31:24]
  assign mboxPyldSrcDataIdentMemDev[4] = '0;                       // Byte[39:32]
  assign mboxPyldSrcDataIdentMemDev[5] = '0;                       // Byte[47:40]
  assign mboxPyldSrcDataIdentMemDev[6] = 64'h0001_0001_0001_0001;  // Byte[55:48]
  assign mboxPyldSrcDataIdentMemDev[7] = '0;                       // Byte[63:56]
  assign mboxPyldSrcDataIdentMemDev[8] = '0;                       // Byte[66:64]

  //-----------------------------------
  // Get Health Info - Output Payload
  //-----------------------------------

  // Byte[0]     = Health Status
  //               Bit[0]   = Maintenance Needed               = 0
  //               Bit[1]   = Performance Degraded             = 0
  //               Bit[2]   = Hardware Replacement Needed      = 0
  //               Bit[7:3] = Reserved                         = 0
  // Byte[1]     = Media Status                                = Reg Value (0x00=Normal or 0x01=Not Ready)
  // Byte[2]     = Additional Status
  //               Bit[1:0] = Life Used                        = 0 (Normal)
  //               Bit[3:2] = Device Temperature               = 0 (Normal)
  //               Bit[4]   = Corrected Volatile Error Count   = Reg Value (0=Normal or 1=Warning)
  //               Bit[5]   = Corrected Persistent Error Count = 0 (Normal)
  //               Bit[7:6] = Reserved                         = 0
  // Byte[3]     = Life Used                                   = 0xFF (Not implemented)
  // Byte[5:4]   = Device Temperature                          = 0xFFFF (Not implemented)
  // Byte[9:6]   = Dirty Shutdown Count                        = 0
  // Byte[13:10] = Corrected Volatile Error Count              = Reg Value
  // Byte[17:14] = Corrected Persistent Error Count            = 0
  //

  assign mboxGetHealthInfoMediaStatus = hyc_mem_active ? 8'h00 : 8'h01;  // 00=Normal, 01=Not Ready

  assign mboxPyldSrcDataGetHealthInfo[0] = {40'h0000_FFFF_FF,3'b000,mboxCVMECntGTEWarnThld_Q,4'h0,mboxGetHealthInfoMediaStatus,8'h00};  // Byte[7:0]
  assign mboxPyldSrcDataGetHealthInfo[1] = {16'h0000,mcAllChanSBECnt_Q[31:0],16'h0000};                                                 // Byte[15:8]
  assign mboxPyldSrcDataGetHealthInfo[2] = '0;                                                                                          // Byte[17:16]
  assign mboxPyldSrcDataGetHealthInfo[3] = '0;
  assign mboxPyldSrcDataGetHealthInfo[4] = '0;
  assign mboxPyldSrcDataGetHealthInfo[5] = '0;
  assign mboxPyldSrcDataGetHealthInfo[6] = '0;
  assign mboxPyldSrcDataGetHealthInfo[7] = '0;
  assign mboxPyldSrcDataGetHealthInfo[8] = '0;

  //-------------------------------------------
  // Get Alert Configuration - Output Payload
  //-------------------------------------------

  // Byte[0]     = Valid Alerts (which threshold fields are valid)
  //               Bit[0]   = Life Used Warning                         = 0
  //               Bit[1]   = Device Over-Temperature Warning           = 0
  //               Bit[2]   = Device Under-Temperature Warning          = 0
  //               Bit[3]   = Corrected Volatile Memory Error Warning   = Reg Value
  //               Bit[4]   = Corrected Persistent Memory Error Warning = 0
  //               Bit[7:5] = Reserved                                  = 0
  // Byte[1]     = Programmable Alerts (which alerts are programmable)
  //               Bit[0]   = Life Used Warning                         = 0
  //               Bit[1]   = Device Over-Temperature Warning           = 0
  //               Bit[2]   = Device Under-Temperature Warning          = 0
  //               Bit[3]   = Corrected Volatile Memory Error Warning   = 1
  //               Bit[4]   = Corrected Persistent Memory Error Warning = 0
  //               Bit[7:5] = Reserved                                  = 0
  // Byte[2]     = Life Used Critical Alert Threshold                   = 0x64
  //               Always valid and not programmable
  // Byte[3]     = Life Used Warning Threshold                          = 0
  //               Not valid and not programmable
  // Byte[5:4]   = Device Over-Temperature Critical Alert Threshold     = 0x7FFF
  //               Always valid and not programmable
  // Byte[7:6]   = Device Under-Temperature Critical Alert Threshold    = 0x8000
  //               Always valid and not programmable
  // Byte[9:8]   = Device Over-Temperature Warning Threshold            = 0
  //               Not valid and not programmable
  // Byte[11:10] = Device Under-Temperature Warning Threshold           = 0
  //               Not valid and not programmable
  // Byte[13:12] = Corrected Volatile Memory Error Warning Threshold    = Reg Value
  //               Valid and programmable
  // Byte[15:14] = Corrected Persistent Memory Error Warning Threshold  = 0
  //               Not valid and not programmable

  assign mboxPyldSrcDataGetAlertCnfg[0] = {60'h8000_7FFF_0064_080,mboxAlertCnfgCVMEEnAlert_Q,3'b000};  // Byte[7:0]
  assign mboxPyldSrcDataGetAlertCnfg[1] = {16'h0000,mboxAlertCnfgCVMEWarnThld_Q,32'h0000_0000};        // Byte[15:8]
  assign mboxPyldSrcDataGetAlertCnfg[2] = '0;
  assign mboxPyldSrcDataGetAlertCnfg[3] = '0;
  assign mboxPyldSrcDataGetAlertCnfg[4] = '0;
  assign mboxPyldSrcDataGetAlertCnfg[5] = '0;
  assign mboxPyldSrcDataGetAlertCnfg[6] = '0;
  assign mboxPyldSrcDataGetAlertCnfg[7] = '0;
  assign mboxPyldSrcDataGetAlertCnfg[8] = '0;

  //----------------------------------------------------
  //-------------------- Event Logs --------------------
  //----------------------------------------------------

  logic [63:0]   elogSrcDataDramEvRcrd    [15:0];
  logic [15:0]   elogWrAttrHandle;
  logic [63:0]   elogSrcDataMemModEvRcrd  [15:0];
  logic [63:0]   elogSrcDataEvRcrdMux     [15:0];

  logic [7:0]    elogWrAttrChannel_In, elogWrAttrChannel_Q;
  logic [7:0]    elogWrAttrEvRcrdLen;
  logic [63:0]   elogWrAttrPhyAddr_In, elogWrAttrPhyAddr_Q, Ch1_PhyAddr, Ch0_PhyAddr; 
  logic [7:0]    elogWrAttrTransType;
  logic [127:0]  uuidDramEvRcrd;
  logic [127:0]  uuidMemModEvRcrd;

  logic          infoElogSrcDataRdActive_Q, warnElogSrcDataRdActive_Q, failElogSrcDataRdActive_Q, fatalElogSrcDataRdActive_Q;
  logic          infoElogWrStart, warnElogWrStart, failElogWrStart, fatalElogWrStart;
  logic [7:0]    infoElogRcrdHandleHi, warnElogRcrdHandleHi, failElogRcrdHandleHi, fatalElogRcrdHandleHi;

  logic          elogSetWrStart;
  logic          elogWrStart_Q;
  logic          elogClrWrActive;
  logic          elogWrActive_Q;

  logic [1:0]    elogWrAttrSeverity_In, elogWrAttrSeverity_Q;
  logic [7:0]    elogWrAttrMemEvDescr_In, elogWrAttrMemEvDescr_Q;
  logic          elogWrSelDramRcrd_In, elogWrSelDramRcrd_Q;

  logic [7:0]    elogWrAttrMemEvType;
  logic [15:0]   elogWrAttrVldFlags;
  logic [7:0]    elogWrAttrDevEvType;

  logic          elogAllowCVMEWarnThld_Q;
  logic          elogClrAllowCVMEWarnThld;

  logic          elogCVMEWarnThldWrReq;

  logic          elogEvInjTrigStg_Q;
  logic          elogEvInjNewTrig;


  always_ff @(posedge cxlbbs_clk) begin
    elogEvInjTrigStg_Q <= bbs_mbox_eventinj.event_trigger;
  end

  assign elogEvInjNewTrig = bbs_mbox_eventinj.event_trigger & ~elogEvInjTrigStg_Q;

  assign elogCVMEWarnThldWrReq = mboxCVMECntGTEWarnThld_Q & elogAllowCVMEWarnThld_Q;

  // If a new event occurs while an older event is actively updating an event log,
  // the new event is dropped and does not update an event log.
  // If the new event is a CVMEWarnThld, it waits until event log updating is ready
  // and then updates the event log.
  assign elogSetWrStart = ((mcAllChanNewSBE & ~mboxAlertCnfgCVMEEnAlert_Q) | mcAllChanNewDBE | elogCVMEWarnThldWrReq | elogEvInjNewTrig)
                          & ~elogWrStart_Q & ~elogWrActive_Q;

  always_ff @(posedge cxlbbs_clk) begin
    if (cxlbbs_rst | elogWrStart_Q) begin
      elogWrStart_Q <= 1'b0;
    end
    else if (elogSetWrStart) begin
      elogWrStart_Q <= 1'b1;
    end
  end

  assign elogClrWrActive = elogWrActive_Q
                           & ~infoElogSrcDataRdActive_Q & ~warnElogSrcDataRdActive_Q
                           & ~failElogSrcDataRdActive_Q & ~fatalElogSrcDataRdActive_Q;

  always_ff @(posedge cxlbbs_clk) begin
    if (cxlbbs_rst | elogClrWrActive) begin
      elogWrActive_Q <= 1'b0;
    end
    else if (elogWrStart_Q) begin
      elogWrActive_Q <= 1'b1;
    end
  end

  // Event log priority:
  // 1. Injected               (Severity = ProgVal)
  // 2. DBE                    (Severity = Failure)
  // 3. CVME Warning Threshold (Severity = Warning)
  // 4. SBE                    (Severity = Warning)

  assign elogWrAttrSeverity_In   = elogEvInjNewTrig
                                   ? bbs_mbox_eventinj.event_severity
                                   : mcAllChanNewDBE ? 2'b10 : 2'b01;

  assign elogWrAttrMemEvDescr_In = {6'd0, (elogCVMEWarnThldWrReq & ~mcAllChanNewDBE), mcAllChanNewDBE};

  //currently only support 2 channels
  assign elogWrAttrChannel_In    = mcAllChanNewDBE                        // if DBE on any channel
                                   ? mc_err_cnt[0].NewDBE ? 8'd0 : 8'd1   // if DBE on chan 0, else chan 1
                                   : mc_err_cnt[0].NewSBE ? 8'd0 : 8'd1;  // else if SBE on chan 0, else ch 1

  // If DRAM record not selected, then defaults to memory module record
  assign elogWrSelDramRcrd_In    = elogEvInjNewTrig
                                   ? ~bbs_mbox_eventinj.event_record
                                   : mcAllChanNewSBE | mcAllChanNewDBE | elogCVMEWarnThldWrReq;
  
  generate
    if (cxlip_top_pkg::MC_CHANNEL == 2) begin : GenCh1PhyAddr
      assign Ch1_PhyAddr = (mc_err_cnt[1].NewPartialWr)        // if ecc event was for a parial write, don't know address, drive all 1s
                              ?   ({64{1'b1}}) 
                              :   ({ 12'd0, (mc_err_cnt[1].DevAddr), 6'd0 })  ; 
    end
    else begin : GenCh1PhyAddr
      assign Ch1_PhyAddr = '0;
    end
  endgenerate

  assign Ch0_PhyAddr = (mc_err_cnt[0].NewPartialWr)        // if ecc event was for a parial write, don't know address, drive all 1s
                          ?   ({64{1'b1}}) 
                          :   ({ 12'd0, (mc_err_cnt[0].DevAddr), 6'd0 })  ; 
  
                              
  always_comb begin

    elogWrAttrPhyAddr_In = {64{1'b1}};  // default to all 1's . This will be the address if using event injection

    if ( mcAllChanNewDBE | mcAllChanNewSBE ) begin // was there  any error? 
      if (elogWrAttrChannel_In == 'd0) begin      // which channel are we reporting an event for ? (only support 2 chan)
        //Per CXL2.0 Spec elogWrAttrPhyAddr[0] indicates volatile memory or not. So for our application, [0] is always set; thus we only update bits [63:1]
        elogWrAttrPhyAddr_In[63:1] = Ch0_PhyAddr[63:1]; 
      end
      else begin
        elogWrAttrPhyAddr_In[63:1] = Ch1_PhyAddr[63:1]; 
      end
    end  // any error?

  end 


  always_ff @(posedge cxlbbs_clk) begin
    if (elogSetWrStart) begin
      elogWrAttrSeverity_Q   <= elogWrAttrSeverity_In;
      elogWrAttrMemEvDescr_Q <= elogWrAttrMemEvDescr_In;
      elogWrAttrChannel_Q    <= elogWrAttrChannel_In;
      elogWrSelDramRcrd_Q    <= elogWrSelDramRcrd_In;
      elogWrAttrPhyAddr_Q    <= elogWrAttrPhyAddr_In;
    end
  end

  assign elogWrAttrEvRcrdLen  = 8'h80;
  assign elogWrAttrHandle     = 16'd0;  // Handle is generated when record is read via Get Event Records
  
  
  assign elogWrAttrMemEvType  = 8'h00;
  assign elogWrAttrTransType  = 8'h00;
  assign elogWrAttrVldFlags   = 16'h01;
  assign elogWrAttrDevEvType  = 8'h01;

  //--------------------
  // DRAM Event Record
  //--------------------

  assign uuidDramEvRcrd = 128'h2496_5CFB_9B4E_AFB8_AB4E_069C_B3CB_1D60;

  assign elogSrcDataDramEvRcrd[0]  = uuidDramEvRcrd[63:0];                                                                                          // Byte[7:0]
  assign elogSrcDataDramEvRcrd[1]  = uuidDramEvRcrd[127:64];                                                                                        // Byte[15:8]
  assign elogSrcDataDramEvRcrd[2]  = {16'd0,elogWrAttrHandle,22'd0,elogWrAttrSeverity_Q,elogWrAttrEvRcrdLen};                                       // Byte[23:16]
  assign elogSrcDataDramEvRcrd[3]  = mboxTimestampSmpl_Q;                                                                                           // Byte[31:24]
  assign elogSrcDataDramEvRcrd[4]  = '0;                                                                                                            // Byte[39:32]
  assign elogSrcDataDramEvRcrd[5]  = '0;                                                                                                            // Byte[47:40]
  assign elogSrcDataDramEvRcrd[6]  = elogWrAttrPhyAddr_Q;                                                                                             // Byte[55:48]
  assign elogSrcDataDramEvRcrd[7]  = {16'd0,elogWrAttrChannel_Q,elogWrAttrVldFlags,elogWrAttrTransType,elogWrAttrMemEvType,elogWrAttrMemEvDescr_Q}; // Byte[63:56]
  assign elogSrcDataDramEvRcrd[8]  = '0;                                                                                                            // Byte[71:64]
  assign elogSrcDataDramEvRcrd[9]  = '0;                                                                                                            // Byte[79:72]
  assign elogSrcDataDramEvRcrd[10] = '0;                                                                                                            // Byte[87:80]
  assign elogSrcDataDramEvRcrd[11] = '0;                                                                                                            // Byte[95:88]
  assign elogSrcDataDramEvRcrd[12] = '0;                                                                                                            // Byte[103:96]
  assign elogSrcDataDramEvRcrd[13] = '0;                                                                                                            // Byte[111:104]
  assign elogSrcDataDramEvRcrd[14] = '0;                                                                                                            // Byte[119:112]
  assign elogSrcDataDramEvRcrd[15] = '0;                                                                                                            // Byte[127:120]

  //-----------------------------
  // Memory Module Event Record
  //-----------------------------

  assign uuidMemModEvRcrd = 128'h74B7_13B1_BA79_86A5_3943_59DD_7574_92FE;

  assign elogSrcDataMemModEvRcrd[0]  = uuidMemModEvRcrd[63:0];                                                                // Byte[7:0]
  assign elogSrcDataMemModEvRcrd[1]  = uuidMemModEvRcrd[127:64];                                                              // Byte[15:8]
  assign elogSrcDataMemModEvRcrd[2]  = {16'd0,elogWrAttrHandle,22'd0,elogWrAttrSeverity_Q,elogWrAttrEvRcrdLen};               // Byte[23:16]
  assign elogSrcDataMemModEvRcrd[3]  = mboxTimestampSmpl_Q;                                                                   // Byte[31:24]
  assign elogSrcDataMemModEvRcrd[4]  = '0;                                                                                    // Byte[39:32]
  assign elogSrcDataMemModEvRcrd[5]  = '0;                                                                                    // Byte[47:40]
  assign elogSrcDataMemModEvRcrd[6]  = {mboxPyldSrcDataGetHealthInfo[0][55:0],elogWrAttrDevEvType};                           // Byte[55:48]
  assign elogSrcDataMemModEvRcrd[7]  = {mboxPyldSrcDataGetHealthInfo[1][55:0],mboxPyldSrcDataGetHealthInfo[0][63:56]};        // Byte[63:56]
  assign elogSrcDataMemModEvRcrd[8]  = {40'd0,mboxPyldSrcDataGetHealthInfo[2][15:0],mboxPyldSrcDataGetHealthInfo[1][63:56]};  // Byte[71:64]
  assign elogSrcDataMemModEvRcrd[9]  = '0;                                                                                    // Byte[79:72]
  assign elogSrcDataMemModEvRcrd[10] = '0;                                                                                    // Byte[87:80]
  assign elogSrcDataMemModEvRcrd[11] = '0;                                                                                    // Byte[95:88]
  assign elogSrcDataMemModEvRcrd[12] = '0;                                                                                    // Byte[103:96]
  assign elogSrcDataMemModEvRcrd[13] = '0;                                                                                    // Byte[111:104]
  assign elogSrcDataMemModEvRcrd[14] = '0;                                                                                    // Byte[119:112]
  assign elogSrcDataMemModEvRcrd[15] = '0;                                                                                    // Byte[127:120]


  assign elogClrAllowCVMEWarnThld = elogCVMEWarnThldWrReq & ~mcAllChanNewDBE & ~elogEvInjNewTrig
                                    & ~elogWrStart_Q & ~elogWrActive_Q;

  always_ff @(posedge cxlbbs_clk) begin
    if (cxlbbs_rst | mboxClrCVMECntGTEWarnThld) begin
      elogAllowCVMEWarnThld_Q <= 1'b1;
    end
    else if (elogClrAllowCVMEWarnThld) begin
      elogAllowCVMEWarnThld_Q <= 1'b0;
    end
  end

  logic    elogFatalNeedMemModEvUpdt_Q;
  logic    memActiveSeen_Q;

  always_ff @(posedge cxlbbs_clk) begin
    if (cxlbbs_rst) begin
      memActiveSeen_Q             <= 1'b0;
      elogFatalNeedMemModEvUpdt_Q <= 1'b0;
    end
    else if (elogFatalNeedMemModEvUpdt_Q) begin
      // if elogFatal availble to update, then clear "need update"
      // else hold "need update"
    end
    else if (hyc_mem_active & ~memActiveSeen_Q) begin
      memActiveSeen_Q <= 1'b1;
    end
    else if (memActiveSeen_Q & ~hyc_mem_active) begin
      elogFatalNeedMemModEvUpdt_Q <= 1'b1;
      memActiveSeen_Q             <= 1'b0;
    end
  end

  //-----------------
  // Event Log RAMs
  //-----------------

  assign elogSrcDataEvRcrdMux = elogWrSelDramRcrd_Q ? elogSrcDataDramEvRcrd : elogSrcDataMemModEvRcrd;

  assign infoElogWrStart  = elogWrStart_Q & (elogWrAttrSeverity_Q == 2'b00);
  assign warnElogWrStart  = elogWrStart_Q & (elogWrAttrSeverity_Q == 2'b01);
  assign failElogWrStart  = elogWrStart_Q & (elogWrAttrSeverity_Q == 2'b10);
  assign fatalElogWrStart = elogWrStart_Q & (elogWrAttrSeverity_Q == 2'b11);

  assign infoElogRcrdHandleHi  = 8'h01;
  assign warnElogRcrdHandleHi  = 8'h02;
  assign failElogRcrdHandleHi  = 8'h04;
  assign fatalElogRcrdHandleHi = 8'h08;

  cafu_devreg_mailbox_elog infoElog (
    .cxlbbs_clk,
    .cxlbbs_rst,
    .elogWrStart             (infoElogWrStart),
    .elogSrcDataIn           (elogSrcDataEvRcrdMux),
    .elogClrRcrdEn           (infoElogClrRcrdEn),
    .elogClrRcrdHndl         (mboxCERS3Hndl_Q[7:4]),
    .elogClrAllRcrdEn        (infoElogClrAllRcrdEn),
    .elogRdAllRcrdStart      (infoElogRdAllRcrdStart),
    .elogRcrdHandleHi        (infoElogRcrdHandleHi),
    .crntTimestamp           (mboxTimestampSmpl_Q),

    .elogHndlInUse_Q         (infoElogHndlInUse_Q),
    .elogRdData              (infoElogRdData),
    .elogRdDataVld_Q         (infoElogRdDataVld_Q),
    .elogRdAllRcrdDone_Q     (infoElogRdAllRcrdDone_Q),
    .elogSrcDataRdActive_Q   (infoElogSrcDataRdActive_Q),
    .elogFirstOvfEvTmstmp_Q  (infoElogFirstOvfEvTmstmp_Q),
    .elogFlagsMoreEvRcrds_Q  (infoElogFlagsMoreEvRcrds_Q),
    .elogFlagsOvf_Q          (infoElogFlagsOvf_Q),
    .elogLastOvfEvTmstmp_Q   (infoElogLastOvfEvTmstmp_Q),
    .elogOvfErrCnt_Q         (infoElogOvfErrCnt_Q),
    .elogPayloadLen_Q        (infoElogPayloadLen_Q),
    .elogEvRcrdCnt_Q         (infoElogEvRcrdCnt_Q)
  );

  cafu_devreg_mailbox_elog warnElog (
    .cxlbbs_clk,
    .cxlbbs_rst,
    .elogWrStart             (warnElogWrStart),
    .elogSrcDataIn           (elogSrcDataEvRcrdMux),
    .elogClrRcrdEn           (warnElogClrRcrdEn),
    .elogClrRcrdHndl         (mboxCERS3Hndl_Q[7:4]),
    .elogClrAllRcrdEn        (warnElogClrAllRcrdEn),
    .elogRdAllRcrdStart      (warnElogRdAllRcrdStart),
    .elogRcrdHandleHi        (warnElogRcrdHandleHi),
    .crntTimestamp           (mboxTimestampSmpl_Q),

    .elogHndlInUse_Q         (warnElogHndlInUse_Q),
    .elogRdData              (warnElogRdData),
    .elogRdDataVld_Q         (warnElogRdDataVld_Q),
    .elogRdAllRcrdDone_Q     (warnElogRdAllRcrdDone_Q),
    .elogSrcDataRdActive_Q   (warnElogSrcDataRdActive_Q),
    .elogFirstOvfEvTmstmp_Q  (warnElogFirstOvfEvTmstmp_Q),
    .elogFlagsMoreEvRcrds_Q  (warnElogFlagsMoreEvRcrds_Q),
    .elogFlagsOvf_Q          (warnElogFlagsOvf_Q),
    .elogLastOvfEvTmstmp_Q   (warnElogLastOvfEvTmstmp_Q),
    .elogOvfErrCnt_Q         (warnElogOvfErrCnt_Q),
    .elogPayloadLen_Q        (warnElogPayloadLen_Q),
    .elogEvRcrdCnt_Q         (warnElogEvRcrdCnt_Q)
  );

  cafu_devreg_mailbox_elog failElog (
    .cxlbbs_clk,
    .cxlbbs_rst,
    .elogWrStart             (failElogWrStart),
    .elogSrcDataIn           (elogSrcDataEvRcrdMux),
    .elogClrRcrdEn           (failElogClrRcrdEn),
    .elogClrRcrdHndl         (mboxCERS3Hndl_Q[7:4]),
    .elogClrAllRcrdEn        (failElogClrAllRcrdEn),
    .elogRdAllRcrdStart      (failElogRdAllRcrdStart),
    .elogRcrdHandleHi        (failElogRcrdHandleHi),
    .crntTimestamp           (mboxTimestampSmpl_Q),

    .elogHndlInUse_Q         (failElogHndlInUse_Q),
    .elogRdData              (failElogRdData),
    .elogRdDataVld_Q         (failElogRdDataVld_Q),
    .elogRdAllRcrdDone_Q     (failElogRdAllRcrdDone_Q),
    .elogSrcDataRdActive_Q   (failElogSrcDataRdActive_Q),
    .elogFirstOvfEvTmstmp_Q  (failElogFirstOvfEvTmstmp_Q),
    .elogFlagsMoreEvRcrds_Q  (failElogFlagsMoreEvRcrds_Q),
    .elogFlagsOvf_Q          (failElogFlagsOvf_Q),
    .elogLastOvfEvTmstmp_Q   (failElogLastOvfEvTmstmp_Q),
    .elogOvfErrCnt_Q         (failElogOvfErrCnt_Q),
    .elogPayloadLen_Q        (failElogPayloadLen_Q),
    .elogEvRcrdCnt_Q         (failElogEvRcrdCnt_Q)
  );

  cafu_devreg_mailbox_elog fatalElog (
    .cxlbbs_clk,
    .cxlbbs_rst,
    .elogWrStart             (fatalElogWrStart),
    .elogSrcDataIn           (elogSrcDataEvRcrdMux),
    .elogClrRcrdEn           (fatalElogClrRcrdEn),
    .elogClrRcrdHndl         (mboxCERS3Hndl_Q[7:4]),
    .elogClrAllRcrdEn        (fatalElogClrAllRcrdEn),
    .elogRdAllRcrdStart      (fatalElogRdAllRcrdStart),
    .elogRcrdHandleHi        (fatalElogRcrdHandleHi),
    .crntTimestamp           (mboxTimestampSmpl_Q),

    .elogHndlInUse_Q         (fatalElogHndlInUse_Q),
    .elogRdData              (fatalElogRdData),
    .elogRdDataVld_Q         (fatalElogRdDataVld_Q),
    .elogRdAllRcrdDone_Q     (fatalElogRdAllRcrdDone_Q),
    .elogSrcDataRdActive_Q   (fatalElogSrcDataRdActive_Q),
    .elogFirstOvfEvTmstmp_Q  (fatalElogFirstOvfEvTmstmp_Q),
    .elogFlagsMoreEvRcrds_Q  (fatalElogFlagsMoreEvRcrds_Q),
    .elogFlagsOvf_Q          (fatalElogFlagsOvf_Q),
    .elogLastOvfEvTmstmp_Q   (fatalElogLastOvfEvTmstmp_Q),
    .elogOvfErrCnt_Q         (fatalElogOvfErrCnt_Q),
    .elogPayloadLen_Q        (fatalElogPayloadLen_Q),
    .elogEvRcrdCnt_Q         (fatalElogEvRcrdCnt_Q)
  );


  always_ff @(posedge cxlbbs_clk) begin
    hyc_dev_cap_event_status.info_event_log    <= infoElogHndlInUse_Q;
    hyc_dev_cap_event_status.warning_event_log <= warnElogHndlInUse_Q;
    hyc_dev_cap_event_status.failure_event_log <= failElogHndlInUse_Q;
    hyc_dev_cap_event_status.fatal_event_log   <= fatalElogHndlInUse_Q;
  end

  assign hyc_dev_cap_event_status.reserved0 = '0;


endmodule
