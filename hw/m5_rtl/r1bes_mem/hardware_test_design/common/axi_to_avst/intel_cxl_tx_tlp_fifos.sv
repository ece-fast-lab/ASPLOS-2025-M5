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

module  intel_cxl_tx_tlp_fifos  (                                     
input   clk,                                                          
input   rst,                                                          
input   logic                            ip_tx_ready,                 
input   logic                            afu_pio_select,              
input   logic                            afu_tx_st_dvalid,
input   logic                            afu_tx_st_sop,
input   logic                            afu_tx_st_eop,
input   logic                            afu_tx_st_passthrough,
input   logic                   [511:0]  afu_tx_st_data,
input   logic                   [127:0]  afu_tx_st_hdr,
input   logic                            afu_tx_st_hvalid,
input   logic                            wr_last,
input   logic                   [127:0]  default_config_txc_header,
input   logic                            default_config_txc_eop,
input   logic                   [255:0]  default_config_txc_payload,
input   logic                            default_config_txc_sop,
input   logic                            default_config_txc_valid,
input   logic                            pio_txc_eop,
input   logic                            pio_txc_sop,
input   logic                   [127:0]  pio_txc_header,
input   logic                   [255:0]  pio_txc_payload,
input   logic                            pio_txc_valid,
input   logic 			         np_ca_rx_sop,
input   logic 			         np_ca_rx_eop,
input   logic 			         np_ca_rx_hvalid,
input   logic 			         np_ca_rx_dvalid,
input   logic 			[127:0]  np_ca_rx_header,
input   logic 			[255:0]  np_ca_rx_data,
input   logic                   [15:0]   tx_p_data_counter,           
input   logic                   [15:0]   tx_np_data_counter,          
input   logic                   [15:0]   tx_cpl_data_counter,         
input   logic                   [12:0]   tx_p_header_counter,         
input   logic                   [12:0]   tx_np_header_counter,        
input   logic                   [12:0]   tx_cpl_header_counter,       
output  logic                   [9:0]    p_tlp_sent_tag,
output  logic                            p_tlp_sent_tag_valid,
output  logic                            wr_tlp_fifo_empty,
output  logic                            wr_tlp_fifo_almost_full,     
output  logic                            rd_tlp_fifo_almost_full,     
output  logic                            tx_st0_dvalid,               
output  logic                            tx_st0_sop,                  
output  logic                            tx_st0_eop,                  
output  logic                            tx_st0_passthrough,          
output  logic                   [255:0]  tx_st0_data,                 
output  logic                   [7:0]    tx_st0_data_parity,          
output  logic                   [127:0]  tx_st0_hdr,                  
output  logic                   [3:0]    tx_st0_hdr_parity,           
output  logic                            tx_st0_hvalid,               
output  logic                   [3:0]    tx_st0_prefix,               
output  logic                            tx_st0_prefix_parity,        
output  logic                   [11:0]   tx_st0_RSSAI_prefix,         
output  logic                            tx_st0_RSSAI_prefix_parity,  
output  logic                   [1:0]    tx_st0_pvalid,               
output  logic                            tx_st0_vfactive,             
output  logic                   [10:0]   tx_st0_vfnum,
output  logic                   [2:0]    tx_st0_pfnum,                
output  logic                   [2:0]    tx_st0_chnum,                
output  logic                   [2:0]    tx_st0_empty,                
output  logic                            tx_st0_misc_parity,          
output  logic                            tx_st1_dvalid,               
output  logic                            tx_st1_sop,                  
output  logic                            tx_st1_eop,                  
output  logic                            tx_st1_passthrough,          
output  logic                   [255:0]  tx_st1_data,                 
output  logic                   [7:0]    tx_st1_data_parity,          
output  logic                   [127:0]  tx_st1_hdr,                  
output  logic                   [3:0]    tx_st1_hdr_parity,           
output  logic                            tx_st1_hvalid,               
output  logic                   [3:0]    tx_st1_prefix,               
output  logic                            tx_st1_prefix_parity,        
output  logic                   [11:0]   tx_st1_RSSAI_prefix,         
output  logic                            tx_st1_RSSAI_prefix_parity,  
output  logic                   [1:0]    tx_st1_pvalid,               
output  logic                            tx_st1_vfactive,             
output  logic                   [10:0]   tx_st1_vfnum,
output  logic                   [2:0]    tx_st1_pfnum,                
output  logic                   [2:0]    tx_st1_chnum,                
output  logic                   [2:0]    tx_st1_empty,                
output  logic                            tx_st1_misc_parity,          
output  logic                            tx_st2_dvalid,               
output  logic                            tx_st2_sop,                  
output  logic                            tx_st2_eop,                  
output  logic                            tx_st2_passthrough,          
output  logic                   [255:0]  tx_st2_data,                 
output  logic                   [7:0]    tx_st2_data_parity,          
output  logic                   [127:0]  tx_st2_hdr,                  
output  logic                   [3:0]    tx_st2_hdr_parity,           
output  logic                            tx_st2_hvalid,               
output  logic                            tx_st2_prefix,               
output  logic                            tx_st2_prefix_parity,        
output  logic                   [11:0]   tx_st2_RSSAI_prefix,         
output  logic                            tx_st2_RSSAI_prefix_parity,  
output  logic                   [1:0]    tx_st2_pvalid,               
output  logic                            tx_st2_vfactive,             
output  logic                   [10:0]   tx_st2_vfnum,
output  logic                   [2:0]    tx_st2_pfnum,                
output  logic                   [2:0]    tx_st2_chnum,                
output  logic                   [2:0]    tx_st2_empty,                
output  logic                            tx_st2_misc_parity,          
output  logic                            tx_st3_dvalid,               
output  logic                            tx_st3_sop,                  
output  logic                            tx_st3_eop,                  
output  logic                            tx_st3_passthrough,          
output  logic                   [255:0]  tx_st3_data,                 
output  logic                   [7:0]    tx_st3_data_parity,          
output  logic                   [127:0]  tx_st3_hdr,                  
output  logic                   [3:0]    tx_st3_hdr_parity,           
output  logic                            tx_st3_hvalid,               
output  logic                   [3:0]    tx_st3_prefix,               
output  logic                            tx_st3_prefix_parity,        
output  logic                   [11:0]   tx_st3_RSSAI_prefix,         
output  logic                            tx_st3_RSSAI_prefix_parity,  
output  logic                   [1:0]    tx_st3_pvalid,               
output  logic                            tx_st3_vfactive,             
output  logic                   [10:0]   tx_st3_vfnum,
output  logic                   [2:0]    tx_st3_pfnum,                
output  logic                   [2:0]    tx_st3_chnum,                
output  logic                   [2:0]    tx_st3_empty,                
output  logic                            tx_st3_misc_parity,
output  logic                            avst4to1_np_hdr_crd_pop 
);                                                                    

logic                            tx_st0_dvalid_f;               
logic                            tx_st0_sop_f;               
logic                            tx_st0_eop_f;                  
logic                   [255:0]  tx_st0_data_f;                 
logic                   [127:0]  tx_st0_hdr_f;                 
logic                            tx_st0_hvalid_f;              
logic                            tx_st1_dvalid_f;               
logic                            tx_st1_sop_f;               
logic                            tx_st1_eop_f;                  
logic                   [255:0]  tx_st1_data_f;                 
logic                   [127:0]  tx_st1_hdr_f;                 
logic                            tx_st1_hvalid_f;              

// afu generate p, np
// dc generates cpl
// pio generates cpl

logic [641:0] p_tlp_fifo_din;
logic [641:0] p_tlp_fifo_dout;
logic p_tlp_fifo_rreq;
logic p_tlp_fifo_wreq;
logic p_tlp_fifo_empty;
logic [2:0] p_tlp_fifo_count;
logic p_tlp_fifo_full;
logic p_tlp_fifo_almost_full;

assign wr_tlp_fifo_empty = p_tlp_fifo_empty;
assign wr_tlp_fifo_almost_full = p_tlp_fifo_almost_full | p_tlp_fifo_full ;


assign p_tlp_fifo_wreq = (afu_tx_st_hvalid && ((afu_tx_st_hdr[127:120]==8'h60) || (afu_tx_st_hdr[127:120]==8'h40))) ? afu_tx_st_sop : 1'b0;
assign p_tlp_fifo_din = {wr_last,afu_tx_st_hvalid ,afu_tx_st_hdr,afu_tx_st_data};

    scfifo p_tlp
      (
        .clock         (clk                       ),
        .data          (p_tlp_fifo_din            ),
        .rdreq         (p_tlp_fifo_rreq           ),
        .wrreq         (p_tlp_fifo_wreq           ),
        .q             (p_tlp_fifo_dout           ),
        .empty         (p_tlp_fifo_empty          ),
        .sclr          (!rst                      ),
        .usedw         (p_tlp_fifo_count          ),
        .aclr          (1'b0                      ),
        .full          (p_tlp_fifo_full           ),
        .almost_full   (p_tlp_fifo_almost_full    ),  
        .almost_empty  (),                        
        .eccstatus     ());                       
    defparam
      p_tlp.add_ram_output_register  = "ON",
      p_tlp.enable_ecc  = "FALSE",
      p_tlp.intended_device_family  = "Agilex",
      p_tlp.lpm_hint  = "RAM_BLOCK_TYPE=M20K", //MLAB",
      p_tlp.lpm_numwords  = 8,
      p_tlp.lpm_showahead  = "OFF",
      p_tlp.lpm_type  = "scfifo",
      p_tlp.lpm_width  = 642,
      p_tlp.lpm_widthu  = 3,
      p_tlp.overflow_checking  = "ON",
      p_tlp.underflow_checking  = "ON",
      p_tlp.use_eab  = "ON",
      p_tlp.almost_full_value = 3;


//-- np
//
logic [128:0] np_tlp_fifo_din;
logic [128:0] np_tlp_fifo_dout;
logic np_tlp_fifo_rreq;
logic np_tlp_fifo_wreq;
logic np_tlp_fifo_empty;
logic [2:0] np_tlp_fifo_count;
logic np_tlp_fifo_full;
logic np_tlp_fifo_almost_full;

assign rd_tlp_fifo_almost_full = np_tlp_fifo_almost_full | np_tlp_fifo_full;
assign np_tlp_fifo_wreq = (afu_tx_st_hvalid && ((afu_tx_st_hdr[127:120]==8'h20) || (afu_tx_st_hdr[127:120]==8'h00))) ? afu_tx_st_sop : 1'b0;
assign np_tlp_fifo_din = {afu_tx_st_hvalid ,afu_tx_st_hdr};

    scfifo np_tlp
      (
        .clock         (clk                        ),
        .data          (np_tlp_fifo_din            ),
        .rdreq         (np_tlp_fifo_rreq           ),
        .wrreq         (np_tlp_fifo_wreq           ),
        .q             (np_tlp_fifo_dout           ),
        .empty         (np_tlp_fifo_empty          ),
        .sclr          (!rst                       ),
        .usedw         (np_tlp_fifo_count          ),
        .aclr          (1'b0                       ),
        .full          (np_tlp_fifo_full           ),
        .almost_full   (np_tlp_fifo_almost_full    ),  
        .almost_empty  (),                         
        .eccstatus     ());                        
    defparam
      np_tlp.add_ram_output_register  = "ON",
      np_tlp.enable_ecc  = "FALSE",
      np_tlp.intended_device_family  = "Agilex",
      np_tlp.lpm_hint  = "RAM_BLOCK_TYPE=M20K", //MLAB",
      np_tlp.lpm_numwords  = 8,
      np_tlp.lpm_showahead  = "OFF",
      np_tlp.lpm_type  = "scfifo",
      np_tlp.lpm_width  = 129,
      np_tlp.lpm_widthu  = 3,
      np_tlp.overflow_checking  = "ON",
      np_tlp.underflow_checking  = "ON",
      np_tlp.use_eab  = "ON",
      np_tlp.almost_full_value = 3;



//--cpl --dc
//
logic [383:0] cpl_tlp_fifo_din;
logic [383:0] cpl_tlp_fifo_dout;
logic cpl_tlp_fifo_rreq;
logic cpl_tlp_fifo_wreq;
logic cpl_tlp_fifo_empty;
logic [2:0] cpl_tlp_fifo_count;
logic cpl_tlp_fifo_full;

logic [128:0] dc_tlp_fifo_din;
logic [128:0] dc_tlp_fifo_dout;
logic dc_tlp_fifo_rreq;
logic dc_tlp_fifo_wreq;
logic dc_tlp_fifo_empty;
logic [2:0] dc_tlp_fifo_count;
logic dc_tlp_fifo_full;


assign dc_tlp_fifo_wreq = default_config_txc_valid;
assign dc_tlp_fifo_din = {default_config_txc_valid,default_config_txc_header};

    scfifo dc_tlp
      (
        .clock         (clk                ),
        .data          (dc_tlp_fifo_din    ),
        .rdreq         (dc_tlp_fifo_rreq   ),
        .wrreq         (dc_tlp_fifo_wreq   ),
        .q             (dc_tlp_fifo_dout   ),
        .empty         (dc_tlp_fifo_empty  ),
        .sclr          (!rst               ),
        .usedw         (dc_tlp_fifo_count  ),
        .aclr          (1'b0               ),
        .full          (dc_tlp_fifo_full   ),
        .almost_full   (),                 
        .almost_empty  (),                 
        .eccstatus     ());                
    defparam
      dc_tlp.add_ram_output_register  = "ON",
      dc_tlp.enable_ecc  = "FALSE",
      dc_tlp.intended_device_family  = "Agilex",
      dc_tlp.lpm_hint  = "RAM_BLOCK_TYPE=M20K", //MLAB",
      dc_tlp.lpm_numwords  = 8,
      dc_tlp.lpm_showahead  = "OFF",
      dc_tlp.lpm_type  = "scfifo",
      dc_tlp.lpm_width  = 129,
      dc_tlp.lpm_widthu  = 3,
      dc_tlp.overflow_checking  = "ON",
      dc_tlp.underflow_checking  = "ON",
      dc_tlp.use_eab  = "ON";

//-- cpl -pio




assign cpl_tlp_fifo_wreq = np_ca_rx_hvalid ? 1'b1 : pio_txc_valid;
assign cpl_tlp_fifo_din  = np_ca_rx_hvalid ? {np_ca_rx_hvalid,np_ca_rx_header,256'h0} : {pio_txc_valid,pio_txc_header,pio_txc_payload};

    scfifo cpl_tlp
      (
        .clock         (clk                 ),
        .data          (cpl_tlp_fifo_din    ),
        .rdreq         (cpl_tlp_fifo_rreq   ),
        .wrreq         (cpl_tlp_fifo_wreq   ),
        .q             (cpl_tlp_fifo_dout   ),
        .empty         (cpl_tlp_fifo_empty  ),
        .sclr          (!rst                ),
        .usedw         (cpl_tlp_fifo_count  ),
        .aclr          (1'b0                ),
        .full          (cpl_tlp_fifo_full   ),
        .almost_full   (),                  
        .almost_empty  (),                  
        .eccstatus     ());                 
    defparam
      cpl_tlp.add_ram_output_register  = "ON",
      cpl_tlp.enable_ecc  = "FALSE",
      cpl_tlp.intended_device_family  = "Agilex",
      cpl_tlp.lpm_hint  = "RAM_BLOCK_TYPE=M20K", //MLAB",
      cpl_tlp.lpm_numwords  = 8,
      cpl_tlp.lpm_showahead  = "OFF",
      cpl_tlp.lpm_type  = "scfifo",
      cpl_tlp.lpm_width  = 384,
      cpl_tlp.lpm_widthu  = 3,
      cpl_tlp.overflow_checking  = "ON",
      cpl_tlp.underflow_checking  = "ON",
      cpl_tlp.use_eab  = "ON";

 //-- read request arb
 
 always_comb begin
        case({afu_pio_select,ip_tx_ready})
            2'b00,2'b10 : begin
                p_tlp_fifo_rreq    =  1'b0;
                np_tlp_fifo_rreq   =  1'b0;
                cpl_tlp_fifo_rreq  =  1'b0;
                dc_tlp_fifo_rreq   =  1'b0;
            end

            2'b01: begin
                if(!dc_tlp_fifo_empty && (tx_cpl_header_counter > 'd3)) begin
                    p_tlp_fifo_rreq    =  1'b0;
                    np_tlp_fifo_rreq   =  1'b0;
                    cpl_tlp_fifo_rreq  =  1'b0;
                    dc_tlp_fifo_rreq   =  1'b1;
                end
                else if (!cpl_tlp_fifo_empty && (tx_cpl_header_counter > 'd4) & (tx_cpl_data_counter > 'd6)) begin
                    p_tlp_fifo_rreq    =  1'b0;
                    np_tlp_fifo_rreq   =  1'b0;
                    cpl_tlp_fifo_rreq  =  1'b1;
                    dc_tlp_fifo_rreq   =  1'b0;
                end
                else begin
                    p_tlp_fifo_rreq    =  1'b0;
                    np_tlp_fifo_rreq   =  1'b0;
                    cpl_tlp_fifo_rreq  =  1'b0;
                    dc_tlp_fifo_rreq   =  1'b0;
                end
            end // 2'b01

            2'b11: begin
                if(!dc_tlp_fifo_empty && (tx_cpl_header_counter > 'd3)) begin
                    p_tlp_fifo_rreq    =  1'b0;
                    np_tlp_fifo_rreq   =  1'b0;
                    cpl_tlp_fifo_rreq  =  1'b0;
                    dc_tlp_fifo_rreq   =  1'b1;
                end
                else if (!p_tlp_fifo_empty && (tx_p_header_counter > 'd3) && (tx_p_data_counter > 'd12)) begin
                    p_tlp_fifo_rreq    =  1'b1;
                    np_tlp_fifo_rreq   =  1'b0;
                    cpl_tlp_fifo_rreq  =  1'b0;
                    dc_tlp_fifo_rreq   =  1'b0;
                end
                else if (!np_tlp_fifo_empty && (tx_np_header_counter > 'd3)) begin
                    p_tlp_fifo_rreq    =  1'b0;
                    np_tlp_fifo_rreq   =  1'b1;
                    cpl_tlp_fifo_rreq  =  1'b0;
                    dc_tlp_fifo_rreq   =  1'b0;
                end
                else begin
                    p_tlp_fifo_rreq    =  1'b0;
                    np_tlp_fifo_rreq   =  1'b0;
                    cpl_tlp_fifo_rreq  =  1'b0;
                    dc_tlp_fifo_rreq   =  1'b0;
                end
            end // 2'b11
        endcase
end

// synthesis translate off
logic [1:0] rreq_add;
assign rreq_add = p_tlp_fifo_rreq + np_tlp_fifo_rreq + cpl_tlp_fifo_rreq + dc_tlp_fifo_rreq ;
always@(posedge clk) if(rreq_add > 1) $display("Error: intel_cxl_tx_tlp_fifos : multiple rreqs generated");

always@(posedge clk) 
    if(p_tlp_fifo_full && p_tlp_fifo_wreq ) $display("Error: intel_cxl_tx_tlp_fifos: p_tlp_fifo_overflow");
    else if(np_tlp_fifo_full && np_tlp_fifo_wreq) $display("Error: intel_cxl_tx_tlp_fifos: np_tlp_fifo_overflow");
    else if(cpl_tlp_fifo_full && cpl_tlp_fifo_wreq) $display("Error: intel_cxl_tx_tlp_fifos: cpl_tlp_fifo_overflow");
    else if(dc_tlp_fifo_full && dc_tlp_fifo_wreq) $display("Error: intel_cxl_tx_tlp_fifos: dc_tlp_fifo_overflow");

// synthesis translate on

//-- output assignments
//
logic  p_tlp_fifo_rreq_f ;            
logic  np_tlp_fifo_rreq_f ;          
logic  cpl_tlp_fifo_rreq_f ;         
logic  dc_tlp_fifo_rreq_f ;          
logic p_tlp_multiseg;

logic [6:0]  cpl_tlp_lower_address;
logic [11:0] cpl_tlp_byte_count;
logic        split_txn;
localparam   RCB_value = 'd128;

  assign cpl_tlp_lower_address = cpl_tlp_fifo_rreq_f ? cpl_tlp_fifo_dout[294:288] : '0 ;
  assign cpl_tlp_byte_count    = cpl_tlp_fifo_rreq_f ? cpl_tlp_fifo_dout[330:320] : '0 ;


  always_ff@(posedge clk)
      if (!rst) begin
           p_tlp_fifo_rreq_f       <= 1'b0;
           np_tlp_fifo_rreq_f      <= 1'b0;
           cpl_tlp_fifo_rreq_f     <= 1'b0;
           dc_tlp_fifo_rreq_f      <= 1'b0;
       end 
       else begin
           p_tlp_fifo_rreq_f       <= p_tlp_fifo_rreq;
           np_tlp_fifo_rreq_f      <= np_tlp_fifo_rreq;
           cpl_tlp_fifo_rreq_f     <= cpl_tlp_fifo_rreq;
           dc_tlp_fifo_rreq_f      <= dc_tlp_fifo_rreq;
       end


  always_ff@(posedge clk) begin
      if(!rst) begin
        split_txn <= '0;
        avst4to1_np_hdr_crd_pop <= '0;
      end
      else begin
          if(dc_tlp_fifo_rreq_f) begin
            split_txn <= 1'b0;
            avst4to1_np_hdr_crd_pop <= 1'b1;
          end
          else begin
            if (cpl_tlp_fifo_rreq_f) begin
                if((cpl_tlp_byte_count + cpl_tlp_lower_address) > RCB_value) begin
                    split_txn <= 1'b1;
                    avst4to1_np_hdr_crd_pop <= 1'b0;
                end
                else begin
                    split_txn <= 1'b0;
                    avst4to1_np_hdr_crd_pop <= 1'b1;
                end
            end
            else begin
            split_txn <= split_txn;
            avst4to1_np_hdr_crd_pop <= 1'b0;
            end
      end
  end
  end

  assign p_tlp_multiseg = p_tlp_fifo_dout[619:608] == 'h10 ;
  always_comb begin
      case({p_tlp_fifo_rreq_f,np_tlp_fifo_rreq_f,cpl_tlp_fifo_rreq_f,dc_tlp_fifo_rreq_f})
          4'b1000 : begin 
            tx_st0_dvalid_f   =  1'b1    ;
            tx_st0_sop_f      =  1'b1    ;
            tx_st0_eop_f      =  !p_tlp_multiseg; 
            tx_st0_data_f     =  p_tlp_fifo_dout[255:0]   ;
            tx_st0_hdr_f      =  p_tlp_fifo_dout[639:512] ;
            tx_st0_hvalid_f   =  1'b1    ;
            tx_st1_dvalid_f   =  p_tlp_multiseg;
            tx_st1_sop_f      =  1'b0    ;
            tx_st1_eop_f      =  p_tlp_multiseg;
            tx_st1_data_f     =  p_tlp_multiseg ? p_tlp_fifo_dout[511:256] : 256'h0  ;
            tx_st1_hdr_f      =  256'b0  ;
            tx_st1_hvalid_f   =  1'b0    ;
            p_tlp_sent_tag    =  {p_tlp_fifo_dout[631],p_tlp_fifo_dout[627],p_tlp_fifo_dout[591:584]};
            p_tlp_sent_tag_valid  = p_tlp_fifo_dout[641];  //taking wr_last
        end // 4'b1000
          4'b0100 : begin 
            tx_st0_dvalid_f   =  1'b0    ;
            tx_st0_sop_f      =  1'b1    ;
            tx_st0_eop_f      =  1'b1    ;
            tx_st0_data_f     =  256'b0  ;
            tx_st0_hdr_f      =  np_tlp_fifo_dout[127:0]  ;
            tx_st0_hvalid_f   =  1'b1    ;
            tx_st1_dvalid_f   =  1'b0    ;
            tx_st1_sop_f      =  1'b0    ;
            tx_st1_eop_f      =  1'b0    ;
            tx_st1_data_f     =  256'b0  ;
            tx_st1_hdr_f      =  128'b0  ;
            tx_st1_hvalid_f   =  1'b0    ;
            p_tlp_sent_tag    =  '0      ;
            p_tlp_sent_tag_valid  = '0   ;
        end // 4'b0100
          4'b0010 : begin 
            tx_st0_dvalid_f   =  cpl_tlp_fifo_dout[335:333]==3'b100 ? 1'b0 : 1'b1    ;
            tx_st0_sop_f      =  1'b1    ;
            tx_st0_eop_f      =  1'b1    ;
            tx_st0_data_f     =  cpl_tlp_fifo_dout[255:0]   ;
            tx_st0_hdr_f      =  cpl_tlp_fifo_dout[383:256] ;
            tx_st0_hvalid_f   =  1'b1    ;
            tx_st1_dvalid_f   =  1'b0    ;
            tx_st1_sop_f      =  1'b0    ;
            tx_st1_eop_f      =  1'b0    ;
            tx_st1_data_f     =  256'b0  ;
            tx_st1_hdr_f      =  128'b0  ;
            tx_st1_hvalid_f   =  1'b0    ;
            p_tlp_sent_tag    =  '0      ;
            p_tlp_sent_tag_valid  = '0   ;
        end // 4'b0010
          4'b0001 : begin 
            tx_st0_dvalid_f   =  1'b0    ;
            tx_st0_sop_f      =  1'b1    ;
            tx_st0_eop_f      =  1'b1    ;
            tx_st0_data_f     =  256'h0  ;
            tx_st0_hdr_f      =  dc_tlp_fifo_dout[127:0]  ;
            tx_st0_hvalid_f   =  1'b1    ;
            tx_st1_dvalid_f   =  1'b0    ;
            tx_st1_sop_f      =  1'b0    ;
            tx_st1_eop_f      =  1'b0    ;
            tx_st1_data_f     =  256'b0  ;
            tx_st1_hdr_f      =  128'b0  ;
            tx_st1_hvalid_f   =  1'b0    ;
            p_tlp_sent_tag    =  '0      ;
            p_tlp_sent_tag_valid  = '0   ;
        end // 4'b0001
        default : begin
            tx_st0_dvalid_f   =  1'b0    ;
            tx_st0_sop_f      =  1'b0    ;
            tx_st0_eop_f      =  1'b0    ;
            tx_st0_data_f     =  256'b0  ;
            tx_st0_hdr_f      =  128'b0  ;
            tx_st0_hvalid_f   =  1'b0    ;
            tx_st1_dvalid_f   =  1'b0    ;
            tx_st1_sop_f      =  1'b0    ;
            tx_st1_eop_f      =  1'b0    ;
            tx_st1_data_f     =  256'b0  ;
            tx_st1_hdr_f      =  128'b0  ;
            tx_st1_hvalid_f   =  1'b0    ;
            p_tlp_sent_tag    =  '0      ;
            p_tlp_sent_tag_valid  = '0   ;
        end // default
      endcase

  end

  always_ff@(posedge clk)
      if (!rst) begin
            tx_st0_dvalid  <=  1'b0    ;
            tx_st0_sop     <=  1'b0    ;
            tx_st0_eop     <=  1'b0    ;
            tx_st0_data    <=  256'b0  ;
            tx_st0_hdr     <=  128'b0  ;
            tx_st0_hvalid  <=  1'b0    ;
            tx_st1_dvalid  <=  1'h0    ;
            tx_st1_sop     <=  1'h0    ;
            tx_st1_eop     <=  1'h0    ;
            tx_st1_data    <=  256'h0  ;
            tx_st1_hdr     <=  128'h0  ;
            tx_st1_hvalid  <=  1'h0    ;
      end
      else begin
            tx_st0_dvalid  <= tx_st0_dvalid_f  ;
            tx_st0_sop     <= tx_st0_sop_f     ;
            tx_st0_eop     <= tx_st0_eop_f     ;
            tx_st0_data    <= tx_st0_data_f    ;
            tx_st0_hdr     <= tx_st0_hdr_f     ;
            tx_st0_hvalid  <= tx_st0_hvalid_f  ;
            tx_st1_dvalid  <= tx_st1_dvalid_f  ;
            tx_st1_sop     <= tx_st1_sop_f     ;
            tx_st1_eop     <= tx_st1_eop_f     ;
            tx_st1_data    <= tx_st1_data_f    ;
            tx_st1_hdr     <= tx_st1_hdr_f     ;
            tx_st1_hvalid  <= tx_st1_hvalid_f  ;
      end

assign  tx_st0_passthrough     =  1'b0                   ;
assign  tx_st0_hdr_parity[0]   =  ^tx_st0_hdr[31:0]      ;
assign  tx_st0_hdr_parity[1]   =  ^tx_st0_hdr[63:32]     ;
assign  tx_st0_hdr_parity[2]   =  ^tx_st0_hdr[95:64]     ;
assign  tx_st0_hdr_parity[3]   =  ^tx_st0_hdr[127:96]    ;
assign  tx_st0_data_parity[0]  =  ^tx_st0_data[31:0]     ;
assign  tx_st0_data_parity[1]  =  ^tx_st0_data[63:32]    ;
assign  tx_st0_data_parity[2]  =  ^tx_st0_data[95:64]    ;
assign  tx_st0_data_parity[3]  =  ^tx_st0_data[127:96]   ;
assign  tx_st0_data_parity[4]  =  ^tx_st0_data[159:128]  ;
assign  tx_st0_data_parity[5]  =  ^tx_st0_data[191:160]  ;
assign  tx_st0_data_parity[6]  =  ^tx_st0_data[223:192]  ;
assign  tx_st0_data_parity[7]  =  ^tx_st0_data[255:224]  ;

assign  tx_st0_prefix               =  4'h0   ;
assign  tx_st0_prefix_parity        =  ^tx_st0_prefix   ;
assign  tx_st0_RSSAI_prefix         =  12'h0  ;
assign  tx_st0_RSSAI_prefix_parity  =  ^tx_st0_RSSAI_prefix   ;
assign  tx_st0_pvalid               =  2'h0   ;
assign  tx_st0_vfactive             =  1'h0   ;
assign  tx_st0_vfnum                =  11'h0  ;
assign  tx_st0_pfnum                =  3'h0   ;
assign  tx_st0_chnum                =  3'h0   ;
assign  tx_st0_empty                =  3'h0   ;
assign  tx_st0_misc_parity          =  1'h0   ;

//--st1

assign  tx_st1_passthrough     =  1'h0  ;
assign  tx_st1_hdr_parity[0]   =  ^tx_st1_hdr[31:0]      ;
assign  tx_st1_hdr_parity[1]   =  ^tx_st1_hdr[63:32]     ;
assign  tx_st1_hdr_parity[2]   =  ^tx_st1_hdr[95:64]     ;
assign  tx_st1_hdr_parity[3]   =  ^tx_st1_hdr[127:96]    ;
assign  tx_st1_data_parity[0]  =  ^tx_st1_data[31:0]     ;
assign  tx_st1_data_parity[1]  =  ^tx_st1_data[63:32]    ;
assign  tx_st1_data_parity[2]  =  ^tx_st1_data[95:64]    ;
assign  tx_st1_data_parity[3]  =  ^tx_st1_data[127:96]   ;
assign  tx_st1_data_parity[4]  =  ^tx_st1_data[159:128]  ;
assign  tx_st1_data_parity[5]  =  ^tx_st1_data[191:160]  ;
assign  tx_st1_data_parity[6]  =  ^tx_st1_data[223:192]  ;
assign  tx_st1_data_parity[7]  =  ^tx_st1_data[255:224]  ;

assign  tx_st1_prefix               =  4'h0   ;
assign  tx_st1_prefix_parity        =  ^tx_st1_prefix   ;
assign  tx_st1_RSSAI_prefix         =  12'h0  ;
assign  tx_st1_RSSAI_prefix_parity  =  ^tx_st1_RSSAI_prefix   ;
assign  tx_st1_pvalid               =  2'h0   ;
assign  tx_st1_vfactive             =  1'h0   ;
assign  tx_st1_vfnum                =  11'h0  ;
assign  tx_st1_pfnum                =  3'h0   ;
assign  tx_st1_chnum                =  3'h0   ;
assign  tx_st1_empty                =  3'h0   ;
assign  tx_st1_misc_parity          =  1'h0   ;

//--st2,3
assign  tx_st2_dvalid          =  1'b0; 
assign  tx_st2_sop             =  1'b0; 
assign  tx_st2_eop             =  1'b0; 
assign  tx_st2_data            =  256'b0; 
assign  tx_st2_hdr             =  128'b0; 
assign  tx_st2_hvalid          =  1'b0; 
assign  tx_st2_passthrough     =  1'b0 ;
assign  tx_st2_hdr_parity[0]   =  ^tx_st2_hdr[31:0]      ;
assign  tx_st2_hdr_parity[1]   =  ^tx_st2_hdr[63:32]     ;
assign  tx_st2_hdr_parity[2]   =  ^tx_st2_hdr[95:64]     ;
assign  tx_st2_hdr_parity[3]   =  ^tx_st2_hdr[127:96]    ;
assign  tx_st2_data_parity[0]  =  ^tx_st2_data[31:0]     ;
assign  tx_st2_data_parity[1]  =  ^tx_st2_data[63:32]    ;
assign  tx_st2_data_parity[2]  =  ^tx_st2_data[95:64]    ;
assign  tx_st2_data_parity[3]  =  ^tx_st2_data[127:96]   ;
assign  tx_st2_data_parity[4]  =  ^tx_st2_data[159:128]  ;
assign  tx_st2_data_parity[5]  =  ^tx_st2_data[191:160]  ;
assign  tx_st2_data_parity[6]  =  ^tx_st2_data[223:192]  ;
assign  tx_st2_data_parity[7]  =  ^tx_st2_data[255:224]  ;

assign  tx_st2_prefix               =  4'h0   ;
assign  tx_st2_prefix_parity        =  ^tx_st2_prefix   ;
assign  tx_st2_RSSAI_prefix         =  12'h0  ;
assign  tx_st2_RSSAI_prefix_parity  =  ^tx_st2_RSSAI_prefix   ;
assign  tx_st2_pvalid               =  2'h0   ;
assign  tx_st2_vfactive             =  1'h0   ;
assign  tx_st2_vfnum                =  11'h0  ;
assign  tx_st2_pfnum                =  3'h0   ;
assign  tx_st2_chnum                =  3'h0   ;
assign  tx_st2_empty                =  3'h0   ;
assign  tx_st2_misc_parity          =  1'h0   ;


assign  tx_st3_dvalid          =  1'b0; 
assign  tx_st3_sop             =  1'b0;
assign  tx_st3_eop             =  1'b0; 
assign  tx_st3_passthrough     =  1'b0 ;
assign  tx_st3_data            =  256'b0; 
assign  tx_st3_hdr             =  128'h0 ;
assign  tx_st3_hvalid          =  1'h0 ;
assign  tx_st3_hdr_parity[0]   =  ^tx_st3_hdr[31:0]      ;
assign  tx_st3_hdr_parity[1]   =  ^tx_st3_hdr[63:32]     ;
assign  tx_st3_hdr_parity[2]   =  ^tx_st3_hdr[95:64]     ;
assign  tx_st3_hdr_parity[3]   =  ^tx_st3_hdr[127:96]    ;
assign  tx_st3_data_parity[0]  =  ^tx_st3_data[31:0]     ;
assign  tx_st3_data_parity[1]  =  ^tx_st3_data[63:32]    ;
assign  tx_st3_data_parity[2]  =  ^tx_st3_data[95:64]    ;
assign  tx_st3_data_parity[3]  =  ^tx_st3_data[127:96]   ;
assign  tx_st3_data_parity[4]  =  ^tx_st3_data[159:128]  ;
assign  tx_st3_data_parity[5]  =  ^tx_st3_data[191:160]  ;
assign  tx_st3_data_parity[6]  =  ^tx_st3_data[223:192]  ;
assign  tx_st3_data_parity[7]  =  ^tx_st3_data[255:224]  ;

assign  tx_st3_prefix               =  4'h0   ;
assign  tx_st3_prefix_parity        =  ^tx_st3_prefix ;
assign  tx_st3_RSSAI_prefix         =  12'h0  ;
assign  tx_st3_RSSAI_prefix_parity  =  ^tx_st3_RSSAI_prefix ;
assign  tx_st3_pvalid               =  2'h0   ;
assign  tx_st3_vfactive             =  1'h0   ;
assign  tx_st3_vfnum                =  11'h0  ;
assign  tx_st3_pfnum                =  3'h0   ;
assign  tx_st3_chnum                =  3'h0   ;
assign  tx_st3_empty                =  3'h0   ;
assign  tx_st3_misc_parity          =  1'h0   ;



endmodule
