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

import ctrl_signal_types::MONITOR_REGION_WIDTH;

module csr_top #(
    parameter REGFILE_SIZE = 32,
    parameter UPDATE_SIZE  = 8
)(
    input  logic        csr_avmm_clk,
    input  logic        csr_avmm_rstn,  
    output logic        csr_avmm_waitrequest,  
    output logic [63:0] csr_avmm_readdata,
    output logic        csr_avmm_readdatavalid,
    input  logic [63:0] csr_avmm_writedata,
    input  logic [21:0] csr_avmm_address,
    input  logic        csr_avmm_write,
    input  logic        csr_avmm_read, 
    input  logic [7:0]  csr_avmm_byteenable,

    // for monitor
    input  logic        afu_clk,
    input  logic        afu_reset_n,
    input logic cxlip2iafu_read_eclk,
    input logic cxlip2iafu_write_eclk,

    // for tracker
    output logic [31:0] page_query_rate,
    output logic [31:0] cache_query_rate,
    output logic [63:0] cxl_start_pa, // byte level address, start_pfn << 12
    output logic [63:0] cxl_addr_offset,
    input logic page_mig_addr_en,
    input logic [27:0]  page_mig_addr,
    input logic cache_mig_addr_en,
    input logic [27:0]  cache_mig_addr,

    // old eac signals 
    input  logic        is_writing_back,
    output logic        csr_zero_out,
    output logic        csr_write_back,
    output logic [63:0] write_back_addr,
    output logic [31:0] csr_write_back_cnt,
    output logic [MONITOR_REGION_WIDTH-1:0]  csr_monitor_region,
    output logic [63:0] csr_ofw_buf_tail_max,

    output	logic [5:0]  csr_awuser,
    output	logic [63:0] csr_ofw_buf_head,
    input	logic [63:0] csr_ofw_buf_vld_cnt
);


//CSR block

   custom_csr_top #(REGFILE_SIZE, UPDATE_SIZE) custom_csr_top_inst(
       .avmm_clk          (csr_avmm_clk),
       .reset_n      (csr_avmm_rstn),
       .writedata    (csr_avmm_writedata),
       .read         (csr_avmm_read),
       .write        (csr_avmm_write),
       .byteenable   (csr_avmm_byteenable),
       .readdata     (csr_avmm_readdata),
       .readdatavalid(csr_avmm_readdatavalid),
       .address      (csr_avmm_address),
       .waitrequest  (csr_avmm_waitrequest),

       .afu_clk      (afu_clk),
       .afu_reset_n (afu_reset_n),
       .cxlip2iafu_read_eclk(cxlip2iafu_read_eclk),
       .cxlip2iafu_write_eclk(cxlip2iafu_write_eclk),

       .page_query_rate (page_query_rate),
       .cache_query_rate (cache_query_rate),
       .page_mig_addr_en  (page_mig_addr_en),
       .page_mig_addr   (page_mig_addr),
       .cache_mig_addr_en(cache_mig_addr_en),
       .cache_mig_addr (cache_mig_addr),

       .is_writing_back (is_writing_back),
       .csr_zero_out    ( csr_zero_out ),
       .csr_write_back  ( csr_write_back ),
       .write_back_addr ( write_back_addr ),
       .csr_write_back_cnt ( csr_write_back_cnt ),
       .csr_monitor_region ( csr_monitor_region ),
       .csr_ofw_buf_tail_max ( csr_ofw_buf_tail_max ),

       .csr_awuser           (csr_awuser),
	   .csr_ofw_buf_head     (csr_ofw_buf_head),
       .csr_ofw_buf_vld_cnt  (csr_ofw_buf_vld_cnt)
   );

//USER LOGIC Implementation 
//
//


endmodule
