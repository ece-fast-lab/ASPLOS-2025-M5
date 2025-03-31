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
// Creation Date : March, 2023
// Description   : Table Access DOE
//

import ext_csr_if_pkg::*;
import rtlgen_pkg_v12::*;

module cafu_csr_doe (
    input  logic                                clk,
    input  logic                                rst,

    // CXL Device Type
    input  ext_csr_if_pkg::CxlDeviceType_e      cxl_dev_type,

    //DOE poisoned Wr                            
    input                                       doe_poisoned_wr_err,


    // Target Register Access Interface for DOE Req/Ack
    input  rtlgen_pkg_v12::cfg_req_64bit_t      treg_req_doe,
    output rtlgen_pkg_v12::cfg_ack_64bit_t      treg_ack_doe,

    // DOE Config Registers
    input  logic [31:0]                         cdat_0,
    input  logic [31:0]                         cdat_1,
    input  logic [31:0]                         cdat_2,
    input  logic [31:0]                         cdat_3,
    input  logic [31:0]                         dsmas_0,
    input  logic [31:0]                         dsmas_1,
    input  logic [31:0]                         dsmas_2,
    input  logic [31:0]                         dsmas_3,
    input  logic [31:0]                         dsmas_4,
    input  logic [31:0]                         dsmas_5,
    input  logic [31:0]                         dslbis_0,
    input  logic [31:0]                         dslbis_1,
    input  logic [31:0]                         dslbis_2,
    input  logic [31:0]                         dslbis_3,
    input  logic [31:0]                         dslbis_4,
    input  logic [31:0]                         dslbis_5,
    input  logic [31:0]                         dsis_0,
    input  logic [31:0]                         dsis_1,
    input  logic [31:0]                         dsemts_0,
    input  logic [31:0]                         dsemts_1,
    input  logic [31:0]                         dsemts_2,
    input  logic [31:0]                         dsemts_3,
    input  logic [31:0]                         dsemts_4,
    input  logic [31:0]                         dsemts_5,

    // DOE Controls
    input  logic                                doe_abort,
    input  logic                                doe_go,
    output logic                                doe_ready,
    output logic                                doe_busy,
    output logic                                doe_error
);

localparam DOE_WR_MBOX  = 24'h000F50;
localparam DOE_RD_MBOX  = 24'h000F54;

logic [5:0]     doe_fsm;
logic [31:0]    wr_mbox_0, wr_mbox_1, wr_mbox_2;
logic [31:0]    curr_entry_handle;
logic           set_doe_err;

// make treg_req_doe.valid 1 clk cycle wide
logic           req_valid_doe_pipe;
logic           req_valid_doe;

always_ff @(posedge clk)
begin
    if (rst)
        req_valid_doe_pipe      <= 1'b0;
    else if (treg_req_doe.valid)
        req_valid_doe_pipe      <= 1'b1;
    else
        req_valid_doe_pipe      <= 1'b0;
end

assign req_valid_doe   = treg_req_doe.valid & ~req_valid_doe_pipe;

///////////////////////////////
// DOE Mailbox Support
///////////////////////////////

always_ff @(posedge clk) begin
    if (rst) begin
        doe_fsm <= 6'b000000; set_doe_err <= 1'b0;
    end
    else begin
    
        case (doe_fsm)                                                  //wlm: If   (1st 4B) wr (of Read Entry Request) to DOE Write Data Mailbox (mem or cfg) AND NOT(abort), goto Write 0
            6'b000000:                                  // Idle         //wlm: Else stay in current state
                if (req_valid_doe && ((treg_req_doe.opcode == 4'h1) || (treg_req_doe.opcode == 4'h5)) && ((treg_req_doe.addr.mem == DOE_WR_MBOX) || (treg_req_doe.addr.cfg == DOE_WR_MBOX)) && (doe_abort == 1'b0)) begin
                    doe_fsm <= 6'b000001; set_doe_err <= 1'b0;
                end else begin
                    doe_fsm <= 6'b000000; set_doe_err <= 1'b0;
                end

            6'b000001:                                  // Write 0      //wlm: If   Abort, goto Idle 
                if (doe_abort == 1'b1) begin                            //wlm: Else If (2nd 4B) wr (of Read Entry Request) to DOE Write Data Mailbox (mem or cfg), goto Write 1
                    doe_fsm <= 6'b000000; set_doe_err <= 1'b0;            //wlm:      Else stay in current state
                end else if (req_valid_doe && ((treg_req_doe.opcode == 4'h1) || (treg_req_doe.opcode == 4'h5)) && ((treg_req_doe.addr.mem == DOE_WR_MBOX) || (treg_req_doe.addr.cfg == DOE_WR_MBOX))) begin
                    doe_fsm <= 6'b000010; set_doe_err <= 1'b0;
                end else begin
                    doe_fsm <= 6'b000001; set_doe_err <= 1'b0;
                end

            6'b000010:                                  // Write 1  
                if (doe_abort == 1'b1) begin
                    doe_fsm <= 6'b000000; set_doe_err <= 1'b0;            //wlm: If   Abort, goto Idle
                end else if (wr_mbox_0[15:0] != 16'h0001) begin //Table Access protocol (Request HDR1 VendorID != 1)
                                                                        //wlm: Else If (3rd 4B) wr (of Read Entry Request) to DOE Write Data Mailbox (mem or cfg) AND valid EntryHandle, goto Write 2 
                    if (req_valid_doe && ((treg_req_doe.opcode == 4'h1) || (treg_req_doe.opcode == 4'h5)) && ((treg_req_doe.addr.mem == DOE_WR_MBOX) || (treg_req_doe.addr.cfg == DOE_WR_MBOX))) begin

                                                                        //THK: Valid EntryHandles in Type 1 device - CDAT Header, DSLBIS and DSIS
                        if ( cxl_dev_type == TYPE_1_DEV && ( (treg_req_doe.data[31:16] == 16'h0000) || (treg_req_doe.data[31:16] == 16'h0002) || (treg_req_doe.data[31:16] == 16'h0004) ) ) begin
                            doe_fsm <= 6'b000011; set_doe_err <= 1'b0;
                                                                        //THK: Valid EntryHandles in Type 2 device - CDAT Header, DSMAS, DSLBIS, DSIS and DSEMTS
                        end else if ( cxl_dev_type == TYPE_2_DEV && ( (treg_req_doe.data[31:16]==16'h0000) || (treg_req_doe.data[31:16]==16'h0001) || (treg_req_doe.data[31:16]==16'h0002) || (treg_req_doe.data[31:16]==16'h0004) || (treg_req_doe.data[31:16]==16'h0005) ) ) begin
                            doe_fsm <= 6'b000011; set_doe_err <= 1'b0;
                                                                        //THK: Valid EntryHandles in Type 3 device - CDAT Header, DSMAS, DSLBIS and DSEMTS
                        end else if ( cxl_dev_type == TYPE_3_DEV && ( (treg_req_doe.data[31:16]==16'h0000) || (treg_req_doe.data[31:16]==16'h0001) || (treg_req_doe.data[31:16]==16'h0002) || (treg_req_doe.data[31:16]==16'h0005) ) ) begin
                            doe_fsm <= 6'b000011; set_doe_err <= 1'b0;
                                                                        //THK: Else Unknown Device Configuration or invalid EntryHandle requested, goto Idle and set DOE Error.
                        end else begin
                            doe_fsm <= 6'b000000; set_doe_err <= 1'b1;
                        end
                        
                    end else begin                                      //wlm: Else stay in current state
                      doe_fsm <= 6'b000010; set_doe_err <= 1'b0;
                    end

                end else begin                                  //DOE Discovery protocol (Request HDR1 VendorID == 1)
                                                                        //wlm: Else If (3rd 4B) wr (of Read Entry Request) to DOE Write Data Mailbox (mem or cfg) AND valid Index, goto Write 2 
                    if (req_valid_doe && ((treg_req_doe.opcode == 4'h1) || (treg_req_doe.opcode == 4'h5)) && ((treg_req_doe.addr.mem == DOE_WR_MBOX) || (treg_req_doe.addr.cfg == DOE_WR_MBOX))) begin
                        if ( (treg_req_doe.data[7:0]==8'h00) || (treg_req_doe.data[7:0]==8'h01) ) begin
                            doe_fsm <= 6'b000011; set_doe_err <= 1'b0;
                        end else begin                                  //wlm: Else If (3rd 4B) wr (of Read Entry Request) to DOE Write Data Mailbox (mem or cfg) AND NOT(valid Index), set error and goto Idle 
                            doe_fsm <= 6'b000000; set_doe_err <= 1'b1;
                        end
                    end else begin                                      //wlm: Else stay in current state
                        doe_fsm <= 6'b000010; set_doe_err <= 1'b0;
                    end
                end

            6'b000011:                                  // Write 2      //wlm: If   Abort, goto Idle
                if (doe_abort == 1'b1) begin                            //wlm: Else If Go, goto Read 0 (Go is a pulse)
                    doe_fsm <= 6'b000000; set_doe_err <= 1'b0;            //wlm:      Else stay in current state
                end else if (doe_go == 1'b1) begin      // GO
                    doe_fsm <= 6'b001000; set_doe_err <= 1'b0;
                end else begin
                    doe_fsm <= 6'b000011; set_doe_err <= 1'b0;
                end

            6'b001000:                                  // Read 0       //wlm: If   Abort, goto Idle                                                                         
                if (doe_abort == 1'b1) begin                            //wlm: Else If wr to DOE Read Data Mailbox (mem or cfg) (assumed preceeded by 1st 4B rd of Read Entry Response from DOE Read Data Mailbox), goto Read 1
                    doe_fsm <= 6'b000000; set_doe_err <= 1'b0;            //wlm:      Else stay in current state
                end else if (req_valid_doe && ((treg_req_doe.opcode == 4'h1) || (treg_req_doe.opcode == 4'h5)) && ((treg_req_doe.addr.mem == DOE_RD_MBOX) || (treg_req_doe.addr.cfg == DOE_RD_MBOX))) begin
                    doe_fsm <= 6'b001001; set_doe_err <= 1'b0;
                end else begin
                    doe_fsm <= 6'b001000; set_doe_err <= 1'b0;
                end

            6'b001001:                                  // Read 1       //wlm: If   Abort, goto Idle                                                                          
                if (doe_abort == 1'b1) begin                            //wlm: Else If wr to DOE Read Data Mailbox (mem or cfg) (assumed preceeded by 2nd 4B rd of Read Entry Response from DOE Read Data Mailbox), goto Read 2
                    doe_fsm <= 6'b000000; set_doe_err <= 1'b0;            //wlm:      Else stay in current state
                end else if (req_valid_doe && ((treg_req_doe.opcode == 4'h1) || (treg_req_doe.opcode == 4'h5)) && ((treg_req_doe.addr.mem == DOE_RD_MBOX) || (treg_req_doe.addr.cfg == DOE_RD_MBOX))) begin
                    doe_fsm <= 6'b001010; set_doe_err <= 1'b0;
                end else begin
                    doe_fsm <= 6'b001001; set_doe_err <= 1'b0;
                end

            6'b001010:                                  // Read 2
                if (doe_abort == 1'b1) begin                            //wlm: If   Abort, goto Idle
                    doe_fsm <= 6'b000000; set_doe_err <= 1'b0;
                end else if (wr_mbox_0[15:0] != 16'h0001) begin //Table Access protocol (Request HDR1 VendorID != 1)
                                                                        //wlm: Else If wr to DOE Read Data Mailbox (mem or cfg) (assumed preceeded by 3rd 4B rd of Read Entry Response from DOE Read Data Mailbox), goto first state for next structure to be read from DOE Read Data Mailbox
                    if          (req_valid_doe && ((treg_req_doe.opcode == 4'h1) || (treg_req_doe.opcode == 4'h5)) && ((treg_req_doe.addr.mem == DOE_RD_MBOX) || (treg_req_doe.addr.cfg == DOE_RD_MBOX)) && (curr_entry_handle[31:16] == 16'h0000)) begin      //THK: goto CDAT  Header state read (cdat_0)   //wlm: EntryHandle is in upper 2B(31:16), not lower 2B(15:0)
                        doe_fsm <= 6'b001011; set_doe_err <= 1'b0;
                    end else if (req_valid_doe && ((treg_req_doe.opcode == 4'h1) || (treg_req_doe.opcode == 4'h5)) && ((treg_req_doe.addr.mem == DOE_RD_MBOX) || (treg_req_doe.addr.cfg == DOE_RD_MBOX)) && (curr_entry_handle[31:16] == 16'h0001)) begin      //THK: goto DSMAS        state read (dsmas_0)  //wlm: EntryHandle is in upper 2B(31:16), not lower 2B(15:0) 
                        doe_fsm <= 6'b001111; set_doe_err <= 1'b0;
                    end else if (req_valid_doe && ((treg_req_doe.opcode == 4'h1) || (treg_req_doe.opcode == 4'h5)) && ((treg_req_doe.addr.mem == DOE_RD_MBOX) || (treg_req_doe.addr.cfg == DOE_RD_MBOX)) && (curr_entry_handle[31:16] == 16'h0002)) begin      //THK: goto DSLBIS       state read (dslbis_0) //wlm: EntryHandle is in upper 2B(31:16), not lower 2B(15:0) 
                        doe_fsm <= 6'b010111; set_doe_err <= 1'b0;
                    end else if (req_valid_doe && ((treg_req_doe.opcode == 4'h1) || (treg_req_doe.opcode == 4'h5)) && ((treg_req_doe.addr.mem == DOE_RD_MBOX) || (treg_req_doe.addr.cfg == DOE_RD_MBOX)) && (curr_entry_handle[31:16] == 16'h0004)) begin      //THK: goto DSIS         state read (dsis_0)   //wlm: EntryHandle is in upper 2B(31:16), not lower 2B(15:0) 
                        doe_fsm <= 6'b010101; set_doe_err <= 1'b0;
                    end else if (req_valid_doe && ((treg_req_doe.opcode == 4'h1) || (treg_req_doe.opcode == 4'h5)) && ((treg_req_doe.addr.mem == DOE_RD_MBOX) || (treg_req_doe.addr.cfg == DOE_RD_MBOX)) && (curr_entry_handle[31:16] == 16'h0005)) begin      //THK: goto DSEMTS       state read (dsemts_0) //wlm: EntryHandle is in upper 2B(31:16), not lower 2B(15:0) 
                        doe_fsm <= 6'b011101; set_doe_err <= 1'b0;
                    end else begin                                      //wlm: else stay in current state
                        doe_fsm <= 6'b001010; set_doe_err <= 1'b0;
                    end

                end else begin                                  //DOE Discovery protocol (Request HDR1 VendorID == 1)
                                                                        //wlm: Else If wr to DOE Read Data Mailbox (mem or cfg) (assumed preceeded by 3rd 4B rd of Read Entry Response from DOE Read Data Mailbox), goto idle
                    if      (req_valid_doe && ((treg_req_doe.opcode == 4'h1) || (treg_req_doe.opcode == 4'h5)) && ((treg_req_doe.addr.mem == DOE_RD_MBOX) || (treg_req_doe.addr.cfg == DOE_RD_MBOX)) ) begin
                        doe_fsm <= 6'b000000; set_doe_err <= 1'b0;
                    end else begin                                      //wlm: else stay in current state
                        doe_fsm <= 6'b001010; set_doe_err <= 1'b0;
                    end
                end

            6'b001011:                                  // cdat_0       //wlm: If   Abort, goto Idle
                if (doe_abort == 1'b1) begin                            //wlm: Else If wr to DOE Read Data Mailbox (mem or cfg) (assumed preceeded by 1st 4B rd of CDAT Header from DOE Read Data Mailbox), goto cdat_1
                    doe_fsm <= 6'b000000; set_doe_err <= 1'b0;            //wlm:      Else stay in current state
                end else if (req_valid_doe && ((treg_req_doe.opcode == 4'h1) || (treg_req_doe.opcode == 4'h5)) && ((treg_req_doe.addr.mem == DOE_RD_MBOX) || (treg_req_doe.addr.cfg == DOE_RD_MBOX))) begin
                    doe_fsm <= 6'b001100; set_doe_err <= 1'b0;
                end else begin
                    doe_fsm <= 6'b001011; set_doe_err <= 1'b0;
                end

            6'b001100:                                  // cdat_1       //wlm: If   Abort, goto Idle                                                                          
                if (doe_abort == 1'b1) begin                            //wlm: Else If wr to DOE Read Data Mailbox (mem or cfg) (assumed preceeded by 2nd 4B rd of CDAT Header from DOE Read Data Mailbox), goto cdat_2
                    doe_fsm <= 6'b000000; set_doe_err <= 1'b0;            //wlm:      Else stay in current state
                end else if (req_valid_doe && ((treg_req_doe.opcode == 4'h1) || (treg_req_doe.opcode == 4'h5)) && ((treg_req_doe.addr.mem == DOE_RD_MBOX) || (treg_req_doe.addr.cfg == DOE_RD_MBOX))) begin
                    doe_fsm <= 6'b001101; set_doe_err <= 1'b0;
                end else begin
                    doe_fsm <= 6'b001100; set_doe_err <= 1'b0;
                end

            6'b001101:                                  // cdat_2       //wlm: If   Abort, goto Idle                                                                          
                if (doe_abort == 1'b1) begin                            //wlm: Else If wr to DOE Read Data Mailbox (mem or cfg) (assumed preceeded by 3rd 4B rd of CDAT Header from DOE Read Data Mailbox), goto cdat_3
                    doe_fsm <= 6'b000000; set_doe_err <= 1'b0;            //wlm:      Else stay in current state
                end else if (req_valid_doe && ((treg_req_doe.opcode == 4'h1) || (treg_req_doe.opcode == 4'h5)) && ((treg_req_doe.addr.mem == DOE_RD_MBOX) || (treg_req_doe.addr.cfg == DOE_RD_MBOX))) begin
                    doe_fsm <= 6'b001110; set_doe_err <= 1'b0;
                end else begin
                    doe_fsm <= 6'b001101; set_doe_err <= 1'b0;
                end

            6'b001110:                                  // cdat_3       //wlm: If   Abort, goto Idle                                                                          
                if (doe_abort == 1'b1) begin                            //wlm: Else If wr to DOE Read Data Mailbox (mem or cfg) (assumed preceeded by 4th 4B rd of CDAT Header from DOE Read Data Mailbox), goto idle
                    doe_fsm <= 6'b000000; set_doe_err <= 1'b0;            //wlm:      Else stay in current state
                end else if (req_valid_doe && ((treg_req_doe.opcode == 4'h1) || (treg_req_doe.opcode == 4'h5)) && ((treg_req_doe.addr.mem == DOE_RD_MBOX) || (treg_req_doe.addr.cfg == DOE_RD_MBOX))) begin
                    doe_fsm <= 6'b000000; set_doe_err <= 1'b0;    //last data , goto Idle
                end else begin
                    doe_fsm <= 5'b01110;  set_doe_err <= 1'b0;
                end

            6'b001111:                                  // dsmas_0      //wlm: If   Abort, goto Idle                                                                  
                if (doe_abort == 1'b1) begin                            //wlm: Else If wr to DOE Read Data Mailbox (mem or cfg) (assumed preceeded by 1st 4B rd of DSMAS data from DOE Read Data Mailbox), goto dsmas_1
                    doe_fsm <= 6'b000000; set_doe_err <= 1'b0;            //wlm:      Else stay in current state
                end else if (req_valid_doe && ((treg_req_doe.opcode == 4'h1) || (treg_req_doe.opcode == 4'h5)) && ((treg_req_doe.addr.mem == DOE_RD_MBOX) || (treg_req_doe.addr.cfg == DOE_RD_MBOX))) begin
                    doe_fsm <= 6'b010000; set_doe_err <= 1'b0;
                end else begin
                    doe_fsm <= 6'b001111; set_doe_err <= 1'b0;
                end

            6'b010000:                                  // dsmas_1      //wlm: If   Abort, goto Idle
                if (doe_abort == 1'b1) begin                            //wlm: Else If wr to DOE Read Data Mailbox (mem or cfg) (assumed preceeded by 2nd 4B rd of DSMAS data from DOE Read Data Mailbox), goto dsmas_2
                    doe_fsm <= 6'b000000; set_doe_err <= 1'b0;            //wlm:      Else stay in current state
                end else if (req_valid_doe && ((treg_req_doe.opcode == 4'h1) || (treg_req_doe.opcode == 4'h5)) && ((treg_req_doe.addr.mem == DOE_RD_MBOX) || (treg_req_doe.addr.cfg == DOE_RD_MBOX))) begin
                    doe_fsm <= 6'b010001; set_doe_err <= 1'b0;
                end else begin
                    doe_fsm <= 6'b010000; set_doe_err <= 1'b0;
                end

            6'b010001:                                  // dsmas_2      //wlm: If   Abort, goto Idle
                if (doe_abort == 1'b1) begin                            //wlm: Else If wr to DOE Read Data Mailbox (mem or cfg) (assumed preceeded by 3rd 4B rd of DSMAS data from DOE Read Data Mailbox), goto dsmas_3
                    doe_fsm <= 6'b000000; set_doe_err <= 1'b0;            //wlm:      Else stay in current state
                end else if (req_valid_doe && ((treg_req_doe.opcode == 4'h1) || (treg_req_doe.opcode == 4'h5)) && ((treg_req_doe.addr.mem == DOE_RD_MBOX) || (treg_req_doe.addr.cfg == DOE_RD_MBOX))) begin
                    doe_fsm <= 6'b010010; set_doe_err <= 1'b0;
                end else begin
                    doe_fsm <= 6'b010001; set_doe_err <= 1'b0;
                end

            6'b010010:                                  // dsmas_3      //wlm: If   Abort, goto Idle
                if (doe_abort == 1'b1) begin                            //wlm: Else If wr to DOE Read Data Mailbox (mem or cfg) (assumed preceeded by 4th 4B rd of DSMAS data from DOE Read Data Mailbox), goto dsmas_4
                    doe_fsm <= 6'b000000; set_doe_err <= 1'b0;            //wlm:      Else stay in current state
                end else if (req_valid_doe && ((treg_req_doe.opcode == 4'h1) || (treg_req_doe.opcode == 4'h5)) && ((treg_req_doe.addr.mem == DOE_RD_MBOX) || (treg_req_doe.addr.cfg == DOE_RD_MBOX))) begin
                    doe_fsm <= 6'b010011; set_doe_err <= 1'b0;
                end else begin
                    doe_fsm <= 6'b010010; set_doe_err <= 1'b0;
                end

            6'b010011:                                  // dsmas_4      //wlm: If   Abort, goto Idle                                                                  
                if (doe_abort == 1'b1) begin                            //wlm: Else If wr to DOE Read Data Mailbox (mem or cfg) (assumed preceeded by 5th 4B rd of DSMAS data from DOE Read Data Mailbox), goto dsmas_5
                    doe_fsm <= 6'b000000; set_doe_err <= 1'b0;            //wlm:      Else stay in current state
                end else if (req_valid_doe && ((treg_req_doe.opcode == 4'h1) || (treg_req_doe.opcode == 4'h5)) && ((treg_req_doe.addr.mem == DOE_RD_MBOX) || (treg_req_doe.addr.cfg == DOE_RD_MBOX))) begin
                    doe_fsm <= 6'b010100; set_doe_err <= 1'b0;
                end else begin
                    doe_fsm <= 6'b010011; set_doe_err <= 1'b0;
                end

            6'b010100:                                  // dsmas_5      //wlm: If   Abort, goto Idle                                                                  
                if (doe_abort == 1'b1) begin                            //wlm: Else If wr to DOE Read Data Mailbox (mem or cfg) (assumed preceeded by 6th 4B rd of DSMAS data from DOE Read Data Mailbox), goto idle
                    doe_fsm <= 6'b000000; set_doe_err <= 1'b0;            //wlm:      Else stay in current state
                end else if (req_valid_doe && ((treg_req_doe.opcode == 4'h1) || (treg_req_doe.opcode == 4'h5)) && ((treg_req_doe.addr.mem == DOE_RD_MBOX) || (treg_req_doe.addr.cfg == DOE_RD_MBOX))) begin
                    doe_fsm <= 6'b000000; set_doe_err <= 1'b0;    //finished with data, goto Idle
                end else begin
                    doe_fsm <= 5'b10100;
                end

            6'b010101:                                  // dsis_0       //wlm: If   Abort, goto Idle
                if (doe_abort == 1'b1) begin                            //wlm: Else If wr to DOE Read Data Mailbox (mem or cfg) (assumed preceeded by 1st 4B rd of DSIS data from DOE Read Data Mailbox), goto dsis_1
                    doe_fsm <= 6'b000000; set_doe_err <= 1'b0;            //wlm:      Else stay in current state
                end else if (req_valid_doe && ((treg_req_doe.opcode == 4'h1) || (treg_req_doe.opcode == 4'h5)) && ((treg_req_doe.addr.mem == DOE_RD_MBOX) || (treg_req_doe.addr.cfg == DOE_RD_MBOX))) begin
                    doe_fsm <= 6'b010110; set_doe_err <= 1'b0;
                end else begin
                    doe_fsm <= 6'b010101; set_doe_err <= 1'b0;
                end

            6'b010110:                                  // dsis_1       //wlm: If   Abort, goto Idle
                if (doe_abort == 1'b1) begin                            //wlm: Else If wr to DOE Read Data Mailbox (mem or cfg) (assumed preceeded by 2nd 4B rd of DSIS data from DOE Read Data Mailbox), goto idle
                    doe_fsm <= 6'b000000; set_doe_err <= 1'b0;            //wlm:      Else stay in current state
                end else if (req_valid_doe && ((treg_req_doe.opcode == 4'h1) || (treg_req_doe.opcode == 4'h5)) && ((treg_req_doe.addr.mem == DOE_RD_MBOX) || (treg_req_doe.addr.cfg == DOE_RD_MBOX))) begin
                    doe_fsm <= 6'b000000; set_doe_err <= 1'b0;  //finished with data, goto Idle
                end else begin
                    doe_fsm <= 5'b10110;  set_doe_err<=1'b0;
                end

            6'b010111:                                  // dslbis_0     //wlm: If   Abort, goto Idle
                if (doe_abort == 1'b1) begin                            //wlm: Else If wr to DOE Read Data Mailbox (mem or cfg) (assumed preceeded by 1st 4B rd of DSLBIS data from DOE Read Data Mailbox), goto dslbis_1
                    doe_fsm <= 6'b000000; set_doe_err <= 1'b0;            //wlm:      Else stay in current state
                end else if (req_valid_doe && ((treg_req_doe.opcode == 4'h1) || (treg_req_doe.opcode == 4'h5)) && ((treg_req_doe.addr.mem == DOE_RD_MBOX) || (treg_req_doe.addr.cfg == DOE_RD_MBOX))) begin
                    doe_fsm <= 6'b11000; set_doe_err <= 1'b0;
                end else begin
                    doe_fsm <= 5'b10111;  set_doe_err<=1'b0;
                end

            6'b011000:                                  // dslbis_1     //wlm: If   Abort, goto Idle
                if (doe_abort == 1'b1) begin                            //wlm: Else If wr to DOE Read Data Mailbox (mem or cfg) (assumed preceeded by 2nd 4B rd of DSLBIS data from DOE Read Data Mailbox), goto dslbis_2   
                    doe_fsm <= 6'b000000; set_doe_err <= 1'b0;            //wlm:      Else stay in current state
                end else if (req_valid_doe && ((treg_req_doe.opcode == 4'h1) || (treg_req_doe.opcode == 4'h5)) && ((treg_req_doe.addr.mem == DOE_RD_MBOX) || (treg_req_doe.addr.cfg == DOE_RD_MBOX))) begin
                    doe_fsm <= 6'b011001; set_doe_err <= 1'b0;
                end else begin
                    doe_fsm <= 6'b011000; set_doe_err <= 1'b0;
                end

            6'b011001:                                  // dslbis_2     //wlm: If   Abort, goto Idle
                if (doe_abort == 1'b1) begin                            //wlm: Else If wr to DOE Read Data Mailbox (mem or cfg) (assumed preceeded by 3rd 4B rd of DSLBIS data from DOE Read Data Mailbox), goto dslbis_3
                    doe_fsm <= 6'b000000; set_doe_err <= 1'b0;            //wlm:      Else stay in current state
                end else if (req_valid_doe && ((treg_req_doe.opcode == 4'h1) || (treg_req_doe.opcode == 4'h5)) && ((treg_req_doe.addr.mem == DOE_RD_MBOX) || (treg_req_doe.addr.cfg == DOE_RD_MBOX))) begin
                    doe_fsm <= 6'b011010; set_doe_err <= 1'b0;
                end else begin
                    doe_fsm <= 6'b011001; set_doe_err <= 1'b0;
                end

            6'b011010:                                  // dslbis_3     //wlm: If   Abort, goto Idle
                if (doe_abort == 1'b1) begin                            //wlm: Else If wr to DOE Read Data Mailbox (mem or cfg) (assumed preceeded by 4th 4B rd of DSLBIS data from DOE Read Data Mailbox), goto dslbis_4
                    doe_fsm <= 6'b000000; set_doe_err <= 1'b0;            //wlm:      Else stay in current state
                end else if (req_valid_doe && ((treg_req_doe.opcode == 4'h1) || (treg_req_doe.opcode == 4'h5)) && ((treg_req_doe.addr.mem == DOE_RD_MBOX) || (treg_req_doe.addr.cfg == DOE_RD_MBOX))) begin
                    doe_fsm <= 6'b011011; set_doe_err <= 1'b0;
                end else begin
                    doe_fsm <= 6'b011010; set_doe_err <= 1'b0;
                end

            6'b011011:                                  // dslbis_4     //wlm: If   Abort, goto Idle
                if (doe_abort == 1'b1) begin                            //wlm: Else If wr to DOE Read Data Mailbox (mem or cfg) (assumed preceeded by 5th 4B rd of DSLBIS data from DOE Read Data Mailbox), goto dslbis_5
                    doe_fsm <= 6'b000000; set_doe_err <= 1'b0;            //wlm:      Else stay in current state
                end else if (req_valid_doe && ((treg_req_doe.opcode == 4'h1) || (treg_req_doe.opcode == 4'h5)) && ((treg_req_doe.addr.mem == DOE_RD_MBOX) || (treg_req_doe.addr.cfg == DOE_RD_MBOX))) begin
                    doe_fsm <= 6'b011100; set_doe_err <= 1'b0;
                end else begin
                    doe_fsm <= 6'b011011; set_doe_err <= 1'b0;
                end

            6'b011100:                                  // dslbis_5     //wlm: If   Abort, goto Idle
                if (doe_abort == 1'b1) begin                            //wlm: Else If wr to DOE Read Data Mailbox (mem or cfg) (assumed preceeded by 6th 4B rd of DSLBIS data from DOE Read Data Mailbox), goto idle
                    doe_fsm <= 6'b000000; set_doe_err <= 1'b0;            //wlm:      Else stay in current state
                end else if (req_valid_doe && ((treg_req_doe.opcode == 4'h1) || (treg_req_doe.opcode == 4'h5)) && ((treg_req_doe.addr.mem == DOE_RD_MBOX) || (treg_req_doe.addr.cfg == DOE_RD_MBOX))) begin
                    doe_fsm <= 6'b000000; set_doe_err <= 1'b0;  //finished with data, back to Idle
                end else begin
                    doe_fsm <= 6'b011100; set_doe_err <= 1'b0;
                end

            6'b011101:                                  // dsemts_0     //wlm: If   Abort, goto Idle
                if (doe_abort == 1'b1) begin                            //wlm: Else If wr to DOE Read Data Mailbox (mem or cfg) (assumed preceeded by 1st 4B rd of DSEMTS data from DOE Read Data Mailbox), goto idle
                    doe_fsm <= 6'b000000; set_doe_err <= 1'b0;            //wlm:      Else stay in current state
                end else if (req_valid_doe && ((treg_req_doe.opcode == 4'h1) || (treg_req_doe.opcode == 4'h5)) && ((treg_req_doe.addr.mem == DOE_RD_MBOX) || (treg_req_doe.addr.cfg == DOE_RD_MBOX))) begin
                    doe_fsm <= 6'b011110; set_doe_err <= 1'b0;
                end else begin
                    doe_fsm <= 6'b011101; set_doe_err <= 1'b0;
                end

            6'b011110:                                  // dsemts_1     //wlm: If   Abort, goto Idle
                if (doe_abort == 1'b1) begin                            //wlm: Else If wr to DOE Read Data Mailbox (mem or cfg) (assumed preceeded by 2nd 4B rd of DSEMTS data from DOE Read Data Mailbox), goto idle
                    doe_fsm <= 6'b000000; set_doe_err <= 1'b0;            //wlm:      Else stay in current state
                end else if (req_valid_doe && ((treg_req_doe.opcode == 4'h1) || (treg_req_doe.opcode == 4'h5)) && ((treg_req_doe.addr.mem == DOE_RD_MBOX) || (treg_req_doe.addr.cfg == DOE_RD_MBOX))) begin
                    doe_fsm <= 6'b011111; set_doe_err <= 1'b0;
                end else begin
                    doe_fsm <= 6'b011110; set_doe_err <= 1'b0;
                end

            6'b011111:                                  // dsemts_2     //wlm: If   Abort, goto Idle
                if (doe_abort == 1'b1) begin                            //wlm: Else If wr to DOE Read Data Mailbox (mem or cfg) (assumed preceeded by 3rd 4B rd of DSEMTS data from DOE Read Data Mailbox), goto idle
                    doe_fsm <= 6'b000000; set_doe_err <= 1'b0;            //wlm:      Else stay in current state
                end else if (req_valid_doe && ((treg_req_doe.opcode == 4'h1) || (treg_req_doe.opcode == 4'h5)) && ((treg_req_doe.addr.mem == DOE_RD_MBOX) || (treg_req_doe.addr.cfg == DOE_RD_MBOX))) begin
                    doe_fsm <= 6'b100000; set_doe_err <= 1'b0;
                end else begin
                    doe_fsm <= 6'b011111; set_doe_err <= 1'b0;
                end

            6'b100000:                                  // dsemts_3     //wlm: If   Abort, goto Idle
                if (doe_abort == 1'b1) begin                            //wlm: Else If wr to DOE Read Data Mailbox (mem or cfg) (assumed preceeded by 4th 4B rd of DSEMTS data from DOE Read Data Mailbox), goto idle
                    doe_fsm <= 6'b000000; set_doe_err <= 1'b0;            //wlm:      Else stay in current state
                end else if (req_valid_doe && ((treg_req_doe.opcode == 4'h1) || (treg_req_doe.opcode == 4'h5)) && ((treg_req_doe.addr.mem == DOE_RD_MBOX) || (treg_req_doe.addr.cfg == DOE_RD_MBOX))) begin
                    doe_fsm <= 6'b100001; set_doe_err <= 1'b0;
                end else begin
                    doe_fsm <= 6'b100000; set_doe_err <= 1'b0;
                end

            6'b100001:                                  // dsemts_4     //wlm: If   Abort, goto Idle
                if (doe_abort == 1'b1) begin                            //wlm: Else If wr to DOE Read Data Mailbox (mem or cfg) (assumed preceeded by 5th 4B rd of DSEMTS data from DOE Read Data Mailbox), goto idle
                    doe_fsm <= 6'b000000; set_doe_err <= 1'b0;            //wlm:      Else stay in current state
                end else if (req_valid_doe && ((treg_req_doe.opcode == 4'h1) || (treg_req_doe.opcode == 4'h5)) && ((treg_req_doe.addr.mem == DOE_RD_MBOX) || (treg_req_doe.addr.cfg == DOE_RD_MBOX))) begin
                    doe_fsm <= 6'b100010; set_doe_err <= 1'b0;  //finished with data, back to Idle
                end else begin
                    doe_fsm <= 6'b100001; set_doe_err <= 1'b0;
                end

            6'b100010:                                  // dsemts_5     //wlm: If   Abort, goto Idle
                if (doe_abort == 1'b1) begin                            //wlm: Else If wr to DOE Read Data Mailbox (mem or cfg) (assumed preceeded by 6th 4B rd of DSEMTS data from DOE Read Data Mailbox), goto idle
                    doe_fsm <= 6'b000000; set_doe_err <= 1'b0;            //wlm:      Else stay in current state
                end else if (req_valid_doe && ((treg_req_doe.opcode == 4'h1) || (treg_req_doe.opcode == 4'h5)) && ((treg_req_doe.addr.mem == DOE_RD_MBOX) || (treg_req_doe.addr.cfg == DOE_RD_MBOX))) begin
                    doe_fsm <= 6'b000000; set_doe_err <= 1'b0;  //finished with data, back to Idle
                end else begin
                    doe_fsm <= 6'b100010; set_doe_err <= 1'b0;
                end

            default: begin
                doe_fsm <= 6'b000000;     set_doe_err <= 1'b0;
            end
        endcase
    end
end

// DOE Header Management
always_ff @(posedge clk) begin
    if (rst) begin
        wr_mbox_0 <= '0;
        wr_mbox_1 <= '0;
        wr_mbox_2 <= '0;
        curr_entry_handle <= '0;
    end else if (req_valid_doe && ((treg_req_doe.opcode == 4'h1) || (treg_req_doe.opcode == 4'h5)) && ((treg_req_doe.addr.mem == DOE_WR_MBOX) || (treg_req_doe.addr.cfg == DOE_WR_MBOX))) begin
        case (doe_fsm) inside
            6'b000000: begin                            // Idle, save first Write MBox  //wlm: capture 1st 4B of DOE Read Entry Request being written to DOE Write Data Mailbox
                wr_mbox_0 <= treg_req_doe.data[31:0];
                wr_mbox_1 <= '0;
                wr_mbox_2 <= '0;
                curr_entry_handle <= '0;
                end

            6'b000001: begin                            // Write 0, save 2nd Write MBox //wlm: capture 2nd 4B of DOE Read Entry Request being written to DOE Write Data Mailbox
                wr_mbox_0 <= wr_mbox_0;
                wr_mbox_1 <= treg_req_doe.data[31:0];
                wr_mbox_2 <= '0;
                curr_entry_handle <= '0;
                end

            6'b000010: begin                            // Write 1, save 3rd Write MBox but replace EntryHandle with Next to use
                wr_mbox_0 <= wr_mbox_0;
                                                                                // replace length field in MB header with header_length+payload_length - THK
                if (wr_mbox_0[15:0] != 16'h0001)                                // Table Access protocol for non-PCIe discovery
                begin
                    if (treg_req_doe.data[31:16] == 16'h0000)                   // CDAT Header
                        wr_mbox_1 <= {wr_mbox_1[31:18], 18'h0007};              // {Reserved, header_length + payload_length}
                    else if (treg_req_doe.data[31:16] == 16'h0001)              // DSMAS
                        wr_mbox_1 <= {wr_mbox_1[31:18], 18'h0009};              // {Reserved, header_length + payload_length}
                    else if (treg_req_doe.data[31:16] == 16'h0002)              // DSLBIS
                        wr_mbox_1 <= {wr_mbox_1[31:18], 18'h0009};              // {Reserved, header_length + payload_length}
                    else if (treg_req_doe.data[31:16] == 16'h0004)              // DSIS
                        wr_mbox_1 <= {wr_mbox_1[31:18], 18'h0005};              // {Reserved, header_length + payload_length}
                    else if (treg_req_doe.data[31:16] == 16'h0005)              // DSEMTS
                        wr_mbox_1 <= {wr_mbox_1[31:18], 18'h0009};              // {Reserved, header_length + payload_length}
                    else
                        wr_mbox_1 <= wr_mbox_1;
                end
                else 
                    wr_mbox_1 <= wr_mbox_1;                                     // Always set to 3DWORDs

                curr_entry_handle <= treg_req_doe.data;                         // Capture current entry handle of the requested CDAT structure. - THK

                                                                                // replace the wr_mbox2 with next EntryHandle in the CDAT structure - THK
                if (wr_mbox_0[15:0] != 16'h0001) begin                          //Table Access protocol (Request HDR1 VendorID != 1)
                                                                                //wlm: capture 3rd 4B of DOE Read Entry Request being written to DOE Write Data Mailbox,
                                                                                //wlm: BUT store next EntryHandle instead of current EntryHandle
                                                                                //wlm: EntryHandle is in upper 2B of wr_mbox_2

                    if ( cxl_dev_type == TYPE_1_DEV )                           // Type 1 device valid structures

                        if (treg_req_doe.data[31:16] == 16'h0000)               // curr_EntryHandle = CDAT HEADER
                            wr_mbox_2 <= {16'h0002, treg_req_doe.data[15:0]};   // next_EntryHandle = DSLBIS
                        else if (treg_req_doe.data[31:16] == 16'h0002)          // curr_EntryHandle = DSLBIS
                            wr_mbox_2 <= {16'h0004, treg_req_doe.data[15:0]};   // next_EntryHandle = DSIS
                        else if (treg_req_doe.data[31:16] == 16'h0004)          // curr_EntryHandle = DSIS
                            wr_mbox_2 <= {16'hFFFF, treg_req_doe.data[15:0]};   // next_EntryHandle = 'hFFFF (EOT)
                        else                                                    // curr_EntryHandle = UNKNOWN
                            wr_mbox_2 <= {16'hFFFF, treg_req_doe.data[15:0]};   // next_EntryHandle = 'hFFFF (EOT)

                    else if ( cxl_dev_type == TYPE_2_DEV )                      // Type 2 device valid structures

                        if (treg_req_doe.data[31:16] == 16'h0000)               // curr_EntryHandle = CDAT HEADER
                            wr_mbox_2 <= {16'h0001, treg_req_doe.data[15:0]};   // next_EntryHandle = DSMAS
                        else if (treg_req_doe.data[31:16] == 16'h0001)          // curr_EntryHandle = DSMAS
                            wr_mbox_2 <= {16'h0002, treg_req_doe.data[15:0]};   // next_EntryHandle = DSLBIS
                        else if (treg_req_doe.data[31:16] == 16'h0002)          // curr_EntryHandle = DSLBIS
                            wr_mbox_2 <= {16'h0004, treg_req_doe.data[15:0]};   // next_EntryHandle = DSIS
                        else if (treg_req_doe.data[31:16] == 16'h0004)          // curr_EntryHandle = DSIS
                            wr_mbox_2 <= {16'h0005, treg_req_doe.data[15:0]};   // next_EntryHandle = DSEMTS
                        else if (treg_req_doe.data[31:16] == 16'h0005)          // curr_EntryHandle = DSEMTS
                            wr_mbox_2 <= {16'hFFFF, treg_req_doe.data[15:0]};   // next_EntryHandle = 'hFFFF (EOT)
                        else                                                    // curr_EntryHandle = UNKNOWN
                            wr_mbox_2 <= {16'hFFFF, treg_req_doe.data[15:0]};   // next_EntryHandle = 'hFFFF (EOT)
                            
                    else if ( cxl_dev_type == TYPE_3_DEV )                      // Type 3 device valid structures

                        if (treg_req_doe.data[31:16] == 16'h0000)               // curr_EntryHandle = CDAT HEADER
                            wr_mbox_2 <= {16'h0001, treg_req_doe.data[15:0]};   // next_EntryHandle = DSMAS
                        else if (treg_req_doe.data[31:16] == 16'h0001)          // curr_EntryHandle = DSMAS
                            wr_mbox_2 <= {16'h0002, treg_req_doe.data[15:0]};   // next_EntryHandle = DSLBIS
                        else if (treg_req_doe.data[31:16] == 16'h0002)          // curr_EntryHandle = DSLBIS
                            wr_mbox_2 <= {16'h0005, treg_req_doe.data[15:0]};   // next_EntryHandle = DSEMTS
                        else if (treg_req_doe.data[31:16] == 16'h0005)          // curr_EntryHandle = DSEMTS
                            wr_mbox_2 <= {16'hFFFF, treg_req_doe.data[15:0]};   // next_EntryHandle = 'hFFFF (EOT)
                        else                                                    // curr_EntryHandle = UNKNOWN
                            wr_mbox_2 <= {16'hFFFF, treg_req_doe.data[15:0]};   // next_EntryHandle = 'hFFFF (EOT)
                            
                    else                                                        // Unknown device type config
                        wr_mbox_2 <= {16'hFFFF, treg_req_doe.data[15:0]};       // next_EntryHandle = 'hFFFF (EOT)

                end else begin                         //DOE Discovery protocol (Request HDR1 VendorID == 1)
                                                                        //wlm: based on Index value in 3rd 4B of Discovery Request written to DOE Write Data Mailbox,   
                                                                        //wlm: create DW0 of Discovery Resonse                                                     
                 if      (treg_req_doe.data[7:0] == 8'h00)                   
                       wr_mbox_2 <= {8'h01,8'h00,16'h0001};  //Request Index==0             //Response DW0: NextIndex==1,                ProtocolType,VendorID==DOE Discovery                                            
                 else // (treg_req_doe.data[7:0] == 8'h01)
                       wr_mbox_2 <= {8'h00,8'h02,16'h1E98};  //Request Index==X(assumed 1)  //Response DW0: NextIndex==0(last protocol), ProtocolType,VendorID==Table Access                                            
                   
                end
                end


           [6'b000011:6'b100010]: begin              // Others, keep current value
                wr_mbox_0 <= wr_mbox_0;
                wr_mbox_1 <= wr_mbox_1;
                wr_mbox_2 <= wr_mbox_2;
                curr_entry_handle <= curr_entry_handle;
                end

            default: begin
                wr_mbox_0 <= wr_mbox_0;
                wr_mbox_1 <= wr_mbox_1;
                wr_mbox_2 <= wr_mbox_2;
                curr_entry_handle <= curr_entry_handle;
                end
        endcase
    end else begin
        wr_mbox_0               <= wr_mbox_0;
        wr_mbox_1               <= wr_mbox_1;
        wr_mbox_2               <= wr_mbox_2;
        curr_entry_handle       <= curr_entry_handle;
    end
end

// Set READY on GO, turn off when ABORT or back at Idle
always_ff @(posedge clk) begin                                 //wlm: If   Abort OR Idle, next Ready=0   (Abort is a pulse)                                                                            
    if (rst) begin                                             //wlm: Else If Go,         next Ready=1   (Go is a pulse)                                                                  
        doe_ready <= 1'b0;
    end else begin
        if (doe_abort || (doe_fsm == 6'b000000))
          doe_ready <= 1'b0;
        else if (doe_go)
          doe_ready <= 1'b1;
    end
end

// Set BUSY on GO, turn off when back at Idle                  
always_ff @(posedge clk) begin                                 //wlm: If   Idle,  next Busy=0                                                                               
    if (rst) begin                                             //wlm: Else If Go, next Busy=1            (Go is a pulse)
        doe_busy <= 1'b0;
    end else begin
        if (doe_fsm == 6'b000000)
          doe_busy <= 1'b0;
        else if (doe_go)
          doe_busy <= 1'b1;
    end
end

always_ff @(posedge clk) begin                                 //wlm: doe_error is cleared only by doe_abort                                                                     
    if (rst) begin                                            
        doe_error <= 1'b0;
    end else begin
        if (doe_abort == 1'b1)
          doe_error <= 1'b0;
        else if ((set_doe_err==1'b1) || (doe_error==1'b1) || (doe_poisoned_wr_err==1'b1))
          doe_error <= 1'b1;
        else
          doe_error <= 1'b0;     
    end
end


// Read Data value : Always 0 for reads of the Write_MBox, reads of the Read_MBox depend on state
always_comb begin

  if (req_valid_doe && ((treg_req_doe.opcode == 4'h0) || (treg_req_doe.opcode == 4'h4)) && ((treg_req_doe.addr.mem == DOE_WR_MBOX) || (treg_req_doe.addr.cfg == DOE_WR_MBOX)))
    treg_ack_doe.data = '0;
  else
    case (doe_fsm) inside       //wlm: read data assignment          //wlm: state(s) selected
       [6'b000000:6'b000011]:   treg_ack_doe.data = '0        ;      //wlm: idle, write_0, write_1, write_2
        6'b001000:              treg_ack_doe.data = wr_mbox_0 ;      //wlm: read_0
        6'b001001:              treg_ack_doe.data = wr_mbox_1 ;      //wlm: read_1
        6'b001010:              treg_ack_doe.data = wr_mbox_2 ;      //wlm: read_2
        6'b001011:              treg_ack_doe.data = cdat_0    ;      //wlm: cdat_0
        6'b001100:              treg_ack_doe.data = cdat_1    ;      //wlm: cdat_1
        6'b001101:              treg_ack_doe.data = cdat_2    ;      //wlm: cdat_2
        6'b001110:              treg_ack_doe.data = cdat_3    ;      //wlm: cdat_3
        6'b001111:              treg_ack_doe.data = dsmas_0   ;      //wlm: dsmas_0
        6'b010000:              treg_ack_doe.data = dsmas_1   ;      //wlm: dsmas_1
        6'b010001:              treg_ack_doe.data = dsmas_2   ;      //wlm: dsmas_2
        6'b010010:              treg_ack_doe.data = dsmas_3   ;      //wlm: dsmas_3
        6'b010011:              treg_ack_doe.data = dsmas_4   ;      //wlm: dsmas_4
        6'b010100:              treg_ack_doe.data = dsmas_5   ;      //wlm: dsmas_5
        6'b010101:              treg_ack_doe.data = dsis_0    ;      //wlm: dsis_0
        6'b010110:              treg_ack_doe.data = dsis_1    ;      //wlm: dsis_1
        6'b010111:              treg_ack_doe.data = dslbis_0  ;      //wlm: dslbis_0
        6'b011000:              treg_ack_doe.data = dslbis_1  ;      //wlm: dslbis_1
        6'b011001:              treg_ack_doe.data = dslbis_2  ;      //wlm: dslbis_2
        6'b011010:              treg_ack_doe.data = dslbis_3  ;      //wlm: dslbis_3
        6'b011011:              treg_ack_doe.data = dslbis_4  ;      //wlm: dslbis_4
        6'b011100:              treg_ack_doe.data = dslbis_5  ;      //wlm: dslbis_5
        6'b011101:              treg_ack_doe.data = dsemts_0  ;      //THK: dsemts_0
        6'b011110:              treg_ack_doe.data = dsemts_1  ;      //THK: dsemts_1
        6'b011111:              treg_ack_doe.data = dsemts_2  ;      //THK: dsemts_2
        6'b100000:              treg_ack_doe.data = dsemts_3  ;      //THK: dsemts_3
        6'b100001:              treg_ack_doe.data = dsemts_4  ;      //THK: dsemts_4
        6'b100010:              treg_ack_doe.data = dsemts_5  ;      //THK: dsemts_5
        default  :              treg_ack_doe.data = '0        ;
    endcase
end

  assign treg_ack_doe.read_valid      = ((req_valid_doe == 1'b1) && ((treg_req_doe.opcode == 4'h0) || (treg_req_doe.opcode == 4'h4)));
  assign treg_ack_doe.read_miss       = '0;
  assign treg_ack_doe.write_valid     = ((req_valid_doe == 1'b1) && ((treg_req_doe.opcode == 4'h1) || (treg_req_doe.opcode == 4'h5)));
  assign treg_ack_doe.write_miss      = '0;
  assign treg_ack_doe.sai_successfull = 1'b1;

endmodule;

