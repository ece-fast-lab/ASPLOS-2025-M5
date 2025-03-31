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
// Description   : CAFU Device Register Mailbox Event Log Logic
//


module cafu_devreg_mailbox_elog
(
  input  logic           cxlbbs_clk,
  input  logic           cxlbbs_rst,
  input  logic           elogWrStart,
  input  logic [63:0]    elogSrcDataIn  [15:0],
  input  logic           elogClrRcrdEn,
  input  logic [3:0]     elogClrRcrdHndl,
  input  logic           elogClrAllRcrdEn,
  input  logic           elogRdAllRcrdStart,
  input  logic [7:0]     elogRcrdHandleHi,
  input  logic [63:0]    crntTimestamp,

  output logic           elogHndlInUse_Q,
  output logic [63:0]    elogRdData,
  output logic           elogRdDataVld_Q,
  output logic           elogRdAllRcrdDone_Q,
  output logic           elogSrcDataRdActive_Q,
  output logic [63:0]    elogFirstOvfEvTmstmp_Q,
  output logic           elogFlagsMoreEvRcrds_Q,
  output logic           elogFlagsOvf_Q,
  output logic [63:0]    elogLastOvfEvTmstmp_Q,
  output logic [15:0]    elogOvfErrCnt_Q,
  output logic [20:0]    elogPayloadLen_Q,
  output logic [15:0]    elogEvRcrdCnt_Q
);


logic          elogCERS1Valid_Q;
logic          elogClrAllHndl_Q;
logic          elogInitRamRdAddr_Q;
logic          elogInitRamRdBaseAddr_Q;
logic [20:0]   elogPayloadLen_In;
logic [3:0]    elogRamBaseWrAddr;
logic          elogRamFull;
logic [7:0]    elogRamRdAddr_Q;
logic [7:0]    elogRamRdBaseAddr_Q;
logic [63:0]   elogRamRdData_Q;
logic          elogRamRdEn_Q;
logic [1:0]    elogRamRdEnStg_Q;
//logic [7:0]    elogRamWrAddr_Q;
logic [3:0]    elogRamWrAddr_Q;
logic [63:0]   elogRamWrData_Q;
logic          elogRamWrEn_Q;
logic          elogRcrdCntSmpl_Q;
logic [15:0]   elogRcrdHandle;
logic          elogRdAllRcrdFirstCyc_Q;
logic [4:0]    elogRdRcrdCnt_Q;
logic          elogSetHndlInUse;
logic          elogSetRamWrEn;
logic [3:0]    elogSrcDataLastIdx;
logic [3:0]    elogSrcDataRdIdx_Q;
logic          elogSrcDataRdIdxMatchLast;
logic          elogStartFirstRcrdRd;
logic          elogUpdtOvfInfo_Q;


//--------------------------------------------------------------------
// Each event record is 128B.
// Event log RAM can store 1 event record (RAM capacity is 128B).
//--------------------------------------------------------------------

//--------------------------------
// Write record to event log RAM
//--------------------------------

assign elogRamBaseWrAddr = '0;

assign elogSetRamWrEn = elogSrcDataRdActive_Q & ~elogRamWrEn_Q;

// Generate event log RAM WrEn and addr to store event record
always_ff @(posedge cxlbbs_clk) begin
  if (cxlbbs_rst) begin
    elogRamWrEn_Q <= 1'b0;
  end
  else if (elogSetRamWrEn) begin
    elogRamWrEn_Q   <= 1'b1;
    elogRamWrAddr_Q <= elogRamBaseWrAddr;
  end
  else if (elogRamWrEn_Q) begin
    elogRamWrAddr_Q <= elogRamWrAddr_Q + 'd1;

    if (~elogSrcDataRdActive_Q) begin
      elogRamWrEn_Q <= 1'b0;
    end
  end
end

assign elogRamFull = elogHndlInUse_Q;

assign elogSrcDataLastIdx        = 'd15;
assign elogSrcDataRdIdxMatchLast = (elogSrcDataRdIdx_Q == elogSrcDataLastIdx);

// Walk event source data to store in event log RAM
always_ff @(posedge cxlbbs_clk) begin
  if (cxlbbs_rst) begin
    elogSrcDataRdActive_Q <= 1'b0;
  end
  else if (elogWrStart & ~elogRamFull) begin
    elogSrcDataRdActive_Q <= 1'b1;
    elogSrcDataRdIdx_Q    <= '0;
  end
  else if (elogSrcDataRdActive_Q) begin
    elogRamWrData_Q    <= elogSrcDataIn[elogSrcDataRdIdx_Q];
    elogSrcDataRdIdx_Q <= elogSrcDataRdIdx_Q + 'd1;

    if (elogSrcDataRdIdxMatchLast) begin
      elogSrcDataRdActive_Q <= 1'b0;
    end
  end
end

// Generate pulse to update overflow event info
always_ff @(posedge cxlbbs_clk) begin
  if (cxlbbs_rst | elogUpdtOvfInfo_Q) begin
    elogUpdtOvfInfo_Q <= 1'b0;
  end
  else if (elogWrStart & elogRamFull) begin
    elogUpdtOvfInfo_Q <= 1'b1;
  end
end

// For each overflow event:
// - Increment overflow error count
// - Update Last Overflow Event Timestamp
// - If first overflow, update First Overflow Event Timestamp
always_ff @(posedge cxlbbs_clk) begin
  if (cxlbbs_rst) begin
    elogFlagsOvf_Q         <= 1'b0;
    elogOvfErrCnt_Q        <= '0;
    elogFirstOvfEvTmstmp_Q <= '0;
    elogLastOvfEvTmstmp_Q  <= '0;
  end
  else if (elogClrRcrdEn | elogClrAllRcrdEn) begin
    elogFlagsOvf_Q <= 1'b0;
  end
  else if (elogUpdtOvfInfo_Q) begin
    elogFlagsOvf_Q        <= 1'b1;
    elogLastOvfEvTmstmp_Q <= crntTimestamp;

    if (~elogFlagsOvf_Q) begin
      elogFirstOvfEvTmstmp_Q <= crntTimestamp;
    end

    // Increment count if not saturated
    if (elogOvfErrCnt_Q != '1) begin
      elogOvfErrCnt_Q <= elogOvfErrCnt_Q + 'd1;
    end
  end
end

// There is at most one record to provide for Get Event Records.
// Since Get Event Records output payload can always handle one record
// plus header info, MoreEvRcrds is always 0.
assign elogFlagsMoreEvRcrds_Q = '0;

//---------------------------------------
// Record reading for Get Event Records
//---------------------------------------

// - Payload length for Get Event Records is:
//   (32 bytes) + (# records * 128 bytes)
always_comb begin
  case (elogHndlInUse_Q) inside
    1'b0:    elogPayloadLen_In = 'h020;
    1'b1:    elogPayloadLen_In = 'h0A0;
    default: elogPayloadLen_In = 'h020;
  endcase
end

// When starting Get Event Records, capture snapshot of current event record count.
// Any records stored after snapshot captured will not be returned for this Get Event Records.
always_ff @(posedge cxlbbs_clk) begin
  if (elogRdAllRcrdStart) begin
    elogRcrdCntSmpl_Q <= elogHndlInUse_Q;
    elogPayloadLen_Q  <= elogPayloadLen_In;
  end
end

assign elogEvRcrdCnt_Q = {15'h0, elogRcrdCntSmpl_Q};

always_ff @(posedge cxlbbs_clk) begin
  if (cxlbbs_rst | elogRdAllRcrdFirstCyc_Q) begin
    elogRdAllRcrdFirstCyc_Q <= 1'b0;
  end
  else if (elogRdAllRcrdStart) begin
    elogRdAllRcrdFirstCyc_Q <= 1'b1;
  end
end

assign elogStartFirstRcrdRd = elogRdAllRcrdFirstCyc_Q & (elogRcrdCntSmpl_Q != 'd0);

// For Get Event Records, track number of records read from event log RAM to support done calculation
always_ff @(posedge cxlbbs_clk) begin
  if (elogStartFirstRcrdRd) begin
    elogRdRcrdCnt_Q <= 'd1;
  end
  else if (elogRamRdEn_Q & (elogRamRdAddr_Q[3:0] == 4'hD)) begin
    elogRdRcrdCnt_Q <= elogRdRcrdCnt_Q + 'd1;
  end
end

always_ff @(posedge cxlbbs_clk) begin
  if (cxlbbs_rst | elogInitRamRdBaseAddr_Q) begin
    elogInitRamRdBaseAddr_Q <= 1'b0;
  end
  else if (elogStartFirstRcrdRd) begin
    elogInitRamRdBaseAddr_Q <= 1'b1;
  end
end

// Capture next event log RAM base address from OrdHLst
always_ff @(posedge cxlbbs_clk) begin
  if (cxlbbs_rst | elogInitRamRdAddr_Q) begin
    elogInitRamRdAddr_Q <= 1'b0;
  end
  else if (elogInitRamRdBaseAddr_Q) begin
    elogInitRamRdAddr_Q <= 1'b1;
  end
end

assign elogRamRdBaseAddr_Q = '0;

// An event record is stored in 16 sequential event log RAM addresses:
// - BaseAddr, BaseAddr+'h1, BaseAddr+'h2, ... , BaseAddr+'hF
always_ff @(posedge cxlbbs_clk) begin
  if (cxlbbs_rst) begin
    elogRamRdEn_Q <= 1'b0;
  end
  else if (elogInitRamRdAddr_Q) begin
    elogRamRdAddr_Q <= elogRamRdBaseAddr_Q;
    elogRamRdEn_Q   <= 1'b1;
  end
  else if (elogRamRdEn_Q & (elogRamRdAddr_Q[3:0] != 4'hF)) begin
    elogRamRdAddr_Q <= elogRamRdAddr_Q + 'd1;
    elogRamRdEn_Q   <= 1'b1;
  end
  else begin
    elogRamRdEn_Q <= 1'b0;
  end
end

// An event log RAM read takes two cycles.  Pipe event log RAM RdEn to calculate RdDataVld.
always_ff @(posedge cxlbbs_clk) begin
  if (cxlbbs_rst) begin
    elogRamRdEnStg_Q <= '0;
  end
  else if (elogRamRdEn_Q | (|elogRamRdEnStg_Q)) begin
    elogRamRdEnStg_Q <= {elogRamRdEnStg_Q[0], elogRamRdEn_Q};
  end
end

// Done asserts the cycle after the last RdDataVld or if there are no records to read
always_ff @(posedge cxlbbs_clk) begin
  if (cxlbbs_rst | elogRdAllRcrdDone_Q) begin
   elogRdAllRcrdDone_Q <= 1'b0;
  end
  else if ((elogRamRdEnStg_Q[1:0] == 2'b10) | (elogRdAllRcrdFirstCyc_Q & (elogRcrdCntSmpl_Q == 'd0)) ) begin
   elogRdAllRcrdDone_Q <= 1'b1;
  end
end

// Each record handle is generated when a record is read.
// The handle's high 8 bits are a constant module input value that identifies this event log.
// The handle's low 8 bits are always zero because there can be at most only one record.
assign elogRcrdHandle = {elogRcrdHandleHi, 8'd0};

// Record handle is inserted into read data from addr 'hN2.  Addr 'hN2 read data is valid when read addr is 'hN4.
assign elogRdData = (elogRamRdAddr_Q[3:0] == 4'h4)
                    ? {elogRamRdData_Q[63:48], elogRcrdHandle, elogRamRdData_Q[31:0]}
                    : elogRamRdData_Q;

assign elogRdDataVld_Q = elogRamRdEnStg_Q[1];

// Event log RAM
cafu_ram_1r1w
  #(.BUS_SIZE_ADDR  (4),
    .BUS_SIZE_DATA  (64)
   )
  elogRam
    (.clk    (cxlbbs_clk),
     .we     (elogRamWrEn_Q),
     .waddr  (elogRamWrAddr_Q),
     .din    (elogRamWrData_Q),
     .raddr  (elogRamRdAddr_Q),
     .dout   (elogRamRdData_Q)
    );

//-----------------------
// Event record handles
//-----------------------

// Each event record has an associated 4-bit handle.
// The handle is used to:
// - Determine the event record's base address in the event log RAM.
// - Build a 16-bit event record handle when providing event records for Get Event Records command.

assign elogSetHndlInUse = elogSetRamWrEn;

// - elogHndlInUse_Q tracks if handle 0 is currently in use.
//   - Handle 0 is the only possible handle
// - When a new record is stored using handle 0, elogHndlInUse_Q is set.
// - When a handle 0 record is cleard, elogHndlInUse_Q is cleared.
always_ff @(posedge cxlbbs_clk) begin
  if (cxlbbs_rst | elogClrAllHndl_Q) begin
    elogHndlInUse_Q <= 1'b0;
  end
  else if (elogSetHndlInUse) begin
    elogHndlInUse_Q <= 1'b1;
  end
  else if (elogCERS1Valid_Q) begin
    elogHndlInUse_Q <= 1'b0;
  end
end

always_ff @(posedge cxlbbs_clk) begin
  if (cxlbbs_rst | elogClrAllHndl_Q) begin
    elogClrAllHndl_Q <= 1'b0;
  end
  else if (elogClrAllRcrdEn) begin
    elogClrAllHndl_Q <= 1'b1;
  end
end

always_ff @(posedge cxlbbs_clk) begin
  if (cxlbbs_rst | elogCERS1Valid_Q) begin
    elogCERS1Valid_Q <= 1'b0;
  end
  else if (elogClrRcrdEn) begin
    elogCERS1Valid_Q <= 1'b1;
  end
end


endmodule
