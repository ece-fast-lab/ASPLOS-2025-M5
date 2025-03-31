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


//------------------------------------------------------------
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
//------------------------------------------------------------
module intel_cxl_afu_pio_mux (
	
    input				    clk,
    input				    rstn,
    input   logic  [0:0]    afu_pio_select,         //afu_pio_select==1  ?  select  afu  else  pio
    input   logic  [0:0]    pio_tx_st_eop,                                                     
    input   logic  [127:0]  pio_tx_st_header,                                                  
    input   logic  [255:0]  pio_tx_st_payload,                                                 
    input   logic  [0:0]    pio_tx_st_sop,                                                     
    input   logic  [0:0]    pio_tx_st_hvalid,                                                  
    input   logic  [0:0]    pio_tx_st_dvalid,                                                  
    input   logic  [0:0]    afu_tx_st_eop,                                                     
    input   logic  [127:0]  afu_tx_st_header,                                                  
    input   logic  [512:0]  afu_tx_st_payload,                                                 
    input   logic  [0:0]    afu_tx_st_sop,                                                     
    input   logic  [0:0]    afu_tx_st_hvalid,                                                  
    input   logic  [0:0]    afu_tx_st_dvalid,                                                  
    output  logic  [0:0]    avst_tx_st0_eop_o,                                                 
    output  logic  [127:0]  avst_tx_st0_header_o,                                              
    output  logic  [255:0]  avst_tx_st0_payload_o,                                             
    output  logic  [0:0]    avst_tx_st0_sop_o,                                                 
    output  logic  [0:0]    avst_tx_st0_hvalid_o,                                              
    output  logic  [0:0]    avst_tx_st0_dvalid_o,                                              
    output  logic  [0:0]    avst_tx_st0_ready_i,                                               
    output  logic  [0:0]    avst_tx_st1_eop_o,                                                 
    output  logic  [127:0]  avst_tx_st1_header_o,                                              
    output  logic  [255:0]  avst_tx_st1_payload_o,                                             
    output  logic  [0:0]    avst_tx_st1_sop_o,                                                 
    output  logic  [0:0]    avst_tx_st1_hvalid_o,                                              
    output  logic  [0:0]    avst_tx_st1_dvalid_o                                               
);


always_ff@(posedge clk) begin

	if(afu_pio_select) begin
		avst_tx_st0_eop_o   	<= 1'b0;
		avst_tx_st0_header_o	<= afu_tx_st_header;
		avst_tx_st0_payload_o	<= afu_tx_st_payload[255:0];
		avst_tx_st0_sop_o   	<= afu_tx_st_sop;
		avst_tx_st0_hvalid_o	<= afu_tx_st_hvalid;
		avst_tx_st0_dvalid_o	<= afu_tx_st_dvalid; 
		avst_tx_st1_eop_o   	<= afu_tx_st_eop; 
		avst_tx_st1_header_o	<= 128'h0; 
		avst_tx_st1_payload_o	<= afu_tx_st_payload[511:256]; 
		avst_tx_st1_sop_o   	<= 1'h0; 
		avst_tx_st1_hvalid_o	<= 1'h0; 
		avst_tx_st1_dvalid_o	<= afu_tx_st_dvalid; 
	end
	else begin
		avst_tx_st0_eop_o   	<= pio_tx_st_eop;
		avst_tx_st0_header_o	<= pio_tx_st_header;
		avst_tx_st0_payload_o	<= pio_tx_st_payload;
		avst_tx_st0_sop_o   	<= pio_tx_st_sop;
		avst_tx_st0_hvalid_o	<= pio_tx_st_hvalid;
		avst_tx_st0_dvalid_o	<= pio_tx_st_dvalid; 
		avst_tx_st1_eop_o   	<= 1'h0; 
		avst_tx_st1_header_o	<= 128'h0; 
		avst_tx_st1_payload_o	<= 256'h0; 
		avst_tx_st1_sop_o   	<= 1'h0; 
		avst_tx_st1_hvalid_o	<= 1'h0; 
		avst_tx_st1_dvalid_o	<= 1'h0; 
	end
end //always


endmodule
