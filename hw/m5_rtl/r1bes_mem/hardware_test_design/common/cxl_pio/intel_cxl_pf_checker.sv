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


//----------------------------------------------------------------------------- 
//  Project Name:  intel_cxl 
//  Module Name :  intel_cxl_pf_checker                                 
//  Date        :  Aug 22, 2022                                 
//  Description :  Parses TLP's between PIO and Default Config
//-----------------------------------------------------------------------------
import intel_cxl_pio_parameters :: *;
module intel_cxl_pf_checker 
    #(parameter REQ_ID = 16'h0) (
input			          clk,
//--ed

input   logic  [2:0]              ed_rx_st_bar_i,
input   logic  [0:0]              ed_rx_st_eop_i,
input   logic  [127:0]            ed_rx_st_header_i,
input   logic  [511:0]            ed_rx_st_payload_i,
input   logic  [0:0]              ed_rx_st_sop_i,
input   logic  [0:0]              ed_rx_st_hvalid_i,
input   logic  [0:0]              ed_rx_st_dvalid_i,
input   logic  [0:0]              ed_rx_st_pvalid_i,
input   logic  [2:0]              ed_rx_st_empty_i,
input   logic  [PFNUM_WIDTH-1:0]  ed_rx_st_pfnum_i,
input   logic  [31:0]             ed_rx_st_tlp_prfx_i,
input   logic  [7:0]              ed_rx_st_data_parity_i,
input   logic  [3:0]              ed_rx_st_hdr_parity_i,
input   logic  [0:0]              ed_rx_st_tlp_prfx_parity_i,
input   logic  [11:0]             ed_rx_st_rssai_prefix_i,
input   logic  [0:0]              ed_rx_st_rssai_prefix_parity_i,
input   logic  [0:0]              ed_rx_st_vfactive_i,
input   logic  [10:0]             ed_rx_st_vfnum_i,
input   logic  [2:0]              ed_rx_st_chnum_i,
input   logic  [0:0]              ed_rx_st_misc_parity_i,
input   logic  [0:0]              ed_rx_st_passthrough_i,
output  logic  [0:0]              ed_rx_st_ready_o,
input   logic  [0:0]              pf0_memory_access_en,
input   logic  [0:0]              pf1_memory_access_en,


//--default config

output  logic  [2:0]              default_config_rx_st_bar_o,
output  logic  [0:0]              default_config_rx_st_eop_o,
output  logic  [127:0]            default_config_rx_st_header_o,
output  logic  [255:0]            default_config_rx_st_payload_o,
output  logic  [0:0]              default_config_rx_st_sop_o,
output  logic  [0:0]              default_config_rx_st_hvalid_o,
output  logic  [0:0]              default_config_rx_st_dvalid_o,
output  logic  [0:0]              default_config_rx_st_pvalid_o,
output  logic  [2:0]              default_config_rx_st_empty_o,
output  logic  [PFNUM_WIDTH-1:0]  default_config_rx_st_pfnum_o,
output  logic  [31:0]             default_config_rx_st_tlp_prfx_o,
output  logic  [7:0]              default_config_rx_st_data_parity_o,
output  logic  [3:0]              default_config_rx_st_hdr_parity_o,
output  logic  [0:0]              default_config_rx_st_tlp_prfx_parity_o,
output  logic  [11:0]             default_config_rx_st_rssai_prefix_o,
output  logic  [0:0]              default_config_rx_st_rssai_prefix_parity_o,
output  logic  [0:0]              default_config_rx_st_vfactive_o,
output  logic  [10:0]             default_config_rx_st_vfnum_o,
output  logic  [2:0]              default_config_rx_st_chnum_o,
output  logic  [0:0]              default_config_rx_st_misc_parity_o,
output  logic  [0:0]              default_config_rx_st_passthrough_o,
input   logic  [0:0]              default_config_rx_st_ready_i,



//--pio

output  logic  [2:0]              pio_rx_st_bar_o,
output  logic  [0:0]              pio_rx_st_eop_o,
output  logic  [127:0]            pio_rx_st_header_o,
output  logic  [255:0]            pio_rx_st_payload_o,
output  logic  [0:0]              pio_rx_st_sop_o,
output  logic  [0:0]              pio_rx_st_hvalid_o,
output  logic  [0:0]              pio_rx_st_dvalid_o,
output  logic  [0:0]              pio_rx_st_pvalid_o,
output  logic  [2:0]              pio_rx_st_empty_o,
output  logic  [PFNUM_WIDTH-1:0]  pio_rx_st_pfnum_o,
output  logic  [31:0]             pio_rx_st_tlp_prfx_o,
output  logic  [7:0]              pio_rx_st_data_parity_o,
output  logic  [3:0]              pio_rx_st_hdr_parity_o,
output  logic  [0:0]              pio_rx_st_tlp_prfx_parity_o,
output  logic  [11:0]             pio_rx_st_rssai_prefix_o,
output  logic  [0:0]              pio_rx_st_rssai_prefix_parity_o,
output  logic  [0:0]              pio_rx_st_vfactive_o,
output  logic  [10:0]             pio_rx_st_vfnum_o,
output  logic  [2:0]              pio_rx_st_chnum_o,
output  logic  [0:0]              pio_rx_st_misc_parity_o,
output  logic  [0:0]              pio_rx_st_passthrough_o,
input   logic  [0:0]              pio_rx_st_ready_i,

//--afu
//
output  logic  [2:0]              afu_rx_st_bar_o,
output  logic  [0:0]              afu_rx_st_eop_o,
output  logic  [127:0]            afu_rx_st_header_o,
output  logic  [511:0]            afu_rx_st_payload_o,
output  logic  [0:0]              afu_rx_st_sop_o,
output  logic  [0:0]              afu_rx_st_hvalid_o,
output  logic  [0:0]              afu_rx_st_dvalid_o,
output  logic  [0:0]              afu_rx_st_pvalid_o,
output  logic  [2:0]              afu_rx_st_empty_o,
output  logic  [PFNUM_WIDTH-1:0]  afu_rx_st_pfnum_o,
output  logic  [31:0]             afu_rx_st_tlp_prfx_o,
output  logic  [7:0]              afu_rx_st_data_parity_o,
output  logic  [3:0]              afu_rx_st_hdr_parity_o,
output  logic  [0:0]              afu_rx_st_tlp_prfx_parity_o,
output  logic  [11:0]             afu_rx_st_rssai_prefix_o,
output  logic  [0:0]              afu_rx_st_rssai_prefix_parity_o,
output  logic  [0:0]              afu_rx_st_vfactive_o,
output  logic  [10:0]             afu_rx_st_vfnum_o,
output  logic  [2:0]              afu_rx_st_chnum_o,
output  logic  [0:0]              afu_rx_st_misc_parity_o,
output  logic  [0:0]              afu_rx_st_passthrough_o,
input   logic  [0:0]              afu_rx_st_ready_i,
input   logic  [0:0]              afu_pio_select,  //afu_pio_select==1 ? select afu else pio

input   logic			  rstn
    
);


logic ed_rx_passthrough;
generate if(ENABLE_ONLY_DEFAULT_CONFIG || ENABLE_BOTH_DEFAULT_CONFIG_PIO)

assign ed_rx_passthrough =      ed_rx_st_passthrough_i   ;  
endgenerate


logic cpld_tlp;
logic cpl_tlp;
logic requester_id;
logic Mem_Wr_tlp;
logic Mem_Rd_tlp;

assign cpld_tlp = (ed_rx_st_header_i[31:24] == 8'h4A) ? 1'b1 : 1'b0;
assign cpl_tlp  = (ed_rx_st_header_i[31:24] == 8'hA)  ? 1'b1 : 1'b0;
assign Mem_Wr_tlp = (ed_rx_st_header_i[31:29]==3'b010 || ed_rx_st_header_i[31:29]==3'b011) && (ed_rx_st_header_i[28:24] == 5'h0);
assign Mem_Rd_tlp = (ed_rx_st_header_i[31:29]==3'b000 || ed_rx_st_header_i[31:29]==3'b001) && (ed_rx_st_header_i[28:24] == 5'h0);
assign requester_id = (ed_rx_st_header_i[95:80] == REQ_ID) ? 1'b1 : 1'b0;
			
generate if(ENABLE_BOTH_DEFAULT_CONFIG_PIO)
begin: BOTH_DEF_PIO
always_ff@(posedge clk)
begin
if(!ed_rx_st_passthrough_i && !afu_pio_select && pf1_memory_access_en)                    
begin
	pio_rx_st_bar_o                             <=  ed_rx_st_bar_i;
	pio_rx_st_eop_o                             <=  ed_rx_st_eop_i;
	pio_rx_st_header_o                          <=  ed_rx_st_header_i;
	pio_rx_st_payload_o                         <=  ed_rx_st_payload_i[255:0]; //TODO : can be 512 bits 
	pio_rx_st_sop_o                             <=  ed_rx_st_sop_i;
	pio_rx_st_hvalid_o                          <=  ed_rx_st_hvalid_i;
	pio_rx_st_dvalid_o                          <=  ed_rx_st_dvalid_i;
	pio_rx_st_pvalid_o                          <=  ed_rx_st_pvalid_i;
	pio_rx_st_empty_o                           <=  ed_rx_st_empty_i;
	pio_rx_st_pfnum_o                           <=  ed_rx_st_pfnum_i;
	pio_rx_st_tlp_prfx_o                        <=  ed_rx_st_tlp_prfx_i;
	pio_rx_st_data_parity_o                     <=  ed_rx_st_data_parity_i;
	pio_rx_st_hdr_parity_o                      <=  ed_rx_st_hdr_parity_i;
	pio_rx_st_tlp_prfx_parity_o                 <=  ed_rx_st_tlp_prfx_parity_i;
	pio_rx_st_rssai_prefix_o                    <=  ed_rx_st_rssai_prefix_i;
	pio_rx_st_rssai_prefix_parity_o             <=  ed_rx_st_rssai_prefix_parity_i;
	pio_rx_st_vfactive_o                        <=  ed_rx_st_vfactive_i;
	pio_rx_st_vfnum_o                           <=  ed_rx_st_vfnum_i;
	pio_rx_st_chnum_o                           <=  ed_rx_st_chnum_i;
	pio_rx_st_misc_parity_o                     <=  ed_rx_st_misc_parity_i;
	pio_rx_st_passthrough_o                     <=  ed_rx_st_passthrough_i;
end                                              
else                                             
begin                                            
	pio_rx_st_bar_o                             <=  '0;
	pio_rx_st_eop_o                             <=  '0;
	pio_rx_st_header_o                          <=  '0;
	pio_rx_st_payload_o                         <=  '0;
	pio_rx_st_sop_o                             <=  '0;
	pio_rx_st_hvalid_o                          <=  '0;
	pio_rx_st_dvalid_o                          <=  '0;
	pio_rx_st_pvalid_o                          <=  '0;
	pio_rx_st_empty_o                           <=  '0;
	pio_rx_st_pfnum_o                           <=  '0;
	pio_rx_st_tlp_prfx_o                        <=  '0;
	pio_rx_st_data_parity_o                     <=  '0;
	pio_rx_st_hdr_parity_o                      <=  '0;
	pio_rx_st_tlp_prfx_parity_o                 <=  '0;
	pio_rx_st_rssai_prefix_o                    <=  '0;
	pio_rx_st_rssai_prefix_parity_o             <=  '0;
	pio_rx_st_vfactive_o                        <=  '0;
	pio_rx_st_vfnum_o                           <=  '0;
	pio_rx_st_chnum_o                           <=  '0;
	pio_rx_st_misc_parity_o                     <=  '0;
	pio_rx_st_passthrough_o                     <=  '0;
end  //


if((cpl_tlp || cpld_tlp) && afu_pio_select && pf0_memory_access_en)
begin
	afu_rx_st_bar_o                             <=  ed_rx_st_bar_i;
	afu_rx_st_eop_o                             <=  ed_rx_st_eop_i;
	afu_rx_st_header_o                          <=  ed_rx_st_header_i;
	afu_rx_st_payload_o                         <=  ed_rx_st_payload_i;
	afu_rx_st_sop_o                             <=  ed_rx_st_sop_i;
	afu_rx_st_hvalid_o                          <=  ed_rx_st_hvalid_i;
	afu_rx_st_dvalid_o                          <=  ed_rx_st_dvalid_i;
	afu_rx_st_pvalid_o                          <=  ed_rx_st_pvalid_i;
	afu_rx_st_empty_o                           <=  ed_rx_st_empty_i;
	afu_rx_st_pfnum_o                           <=  ed_rx_st_pfnum_i;
	afu_rx_st_tlp_prfx_o                        <=  ed_rx_st_tlp_prfx_i;
	afu_rx_st_data_parity_o                     <=  ed_rx_st_data_parity_i;
	afu_rx_st_hdr_parity_o                      <=  ed_rx_st_hdr_parity_i;
	afu_rx_st_tlp_prfx_parity_o                 <=  ed_rx_st_tlp_prfx_parity_i;
	afu_rx_st_rssai_prefix_o                    <=  ed_rx_st_rssai_prefix_i;
	afu_rx_st_rssai_prefix_parity_o             <=  ed_rx_st_rssai_prefix_parity_i;
	afu_rx_st_vfactive_o                        <=  ed_rx_st_vfactive_i;
	afu_rx_st_vfnum_o                           <=  ed_rx_st_vfnum_i;
	afu_rx_st_chnum_o                           <=  ed_rx_st_chnum_i;
	afu_rx_st_misc_parity_o                     <=  ed_rx_st_misc_parity_i;
	afu_rx_st_passthrough_o                     <=  ed_rx_st_passthrough_i;
end                                              
else                                             
begin                                            
	afu_rx_st_bar_o                             <=  '0;
	afu_rx_st_eop_o                             <=  '0;
	afu_rx_st_header_o                          <=  '0;
	afu_rx_st_payload_o                         <=  '0;
	afu_rx_st_sop_o                             <=  '0;
	afu_rx_st_hvalid_o                          <=  '0;
	afu_rx_st_dvalid_o                          <=  '0;
	afu_rx_st_pvalid_o                          <=  '0;
	afu_rx_st_empty_o                           <=  '0;
	afu_rx_st_pfnum_o                           <=  '0;
	afu_rx_st_tlp_prfx_o                        <=  '0;
	afu_rx_st_data_parity_o                     <=  '0;
	afu_rx_st_hdr_parity_o                      <=  '0;
	afu_rx_st_tlp_prfx_parity_o                 <=  '0;
	afu_rx_st_rssai_prefix_o                    <=  '0;
	afu_rx_st_rssai_prefix_parity_o             <=  '0;
	afu_rx_st_vfactive_o                        <=  '0;
	afu_rx_st_vfnum_o                           <=  '0;
	afu_rx_st_chnum_o                           <=  '0;
	afu_rx_st_misc_parity_o                     <=  '0;
	afu_rx_st_passthrough_o                     <=  '0;
end  //--st0

if ((ed_rx_st_passthrough_i && (~((cpld_tlp || cpl_tlp) && afu_pio_select))) || (afu_pio_select && (Mem_Wr_tlp || Mem_Rd_tlp)))                    
begin
	default_config_rx_st_bar_o                  <=  ed_rx_st_bar_i;
	default_config_rx_st_eop_o                  <=  ed_rx_st_eop_i;
	default_config_rx_st_header_o               <=  ed_rx_st_header_i;
	default_config_rx_st_payload_o              <=  ed_rx_st_payload_i; 
	default_config_rx_st_sop_o                  <=  ed_rx_st_sop_i;
	default_config_rx_st_hvalid_o               <=  ed_rx_st_hvalid_i;
	default_config_rx_st_dvalid_o               <=  ed_rx_st_dvalid_i;
	default_config_rx_st_pvalid_o               <=  ed_rx_st_pvalid_i;
	default_config_rx_st_empty_o                <=  ed_rx_st_empty_i;
	default_config_rx_st_pfnum_o                <=  ed_rx_st_pfnum_i;
	default_config_rx_st_tlp_prfx_o             <=  ed_rx_st_tlp_prfx_i;
	default_config_rx_st_data_parity_o          <=  ed_rx_st_data_parity_i;
	default_config_rx_st_hdr_parity_o           <=  ed_rx_st_hdr_parity_i;
	default_config_rx_st_tlp_prfx_parity_o      <=  ed_rx_st_tlp_prfx_parity_i;
	default_config_rx_st_rssai_prefix_o         <=  ed_rx_st_rssai_prefix_i;
	default_config_rx_st_rssai_prefix_parity_o  <=  ed_rx_st_rssai_prefix_parity_i;
	default_config_rx_st_vfactive_o             <=  ed_rx_st_vfactive_i;
	default_config_rx_st_vfnum_o                <=  ed_rx_st_vfnum_i;
	default_config_rx_st_chnum_o                <=  ed_rx_st_chnum_i;
	default_config_rx_st_misc_parity_o          <=  ed_rx_st_misc_parity_i;
	default_config_rx_st_passthrough_o          <=  ed_rx_st_passthrough_i;
end
else if ((afu_pio_select && (~pf0_memory_access_en)) || (~afu_pio_select && (~pf1_memory_access_en)))                    
begin
	default_config_rx_st_bar_o                  <=  ed_rx_st_bar_i;
	default_config_rx_st_eop_o                  <=  ed_rx_st_eop_i;
	default_config_rx_st_header_o               <=  ed_rx_st_header_i;
	default_config_rx_st_payload_o              <=  ed_rx_st_payload_i; 
	default_config_rx_st_sop_o                  <=  ed_rx_st_sop_i;
	default_config_rx_st_hvalid_o               <=  ed_rx_st_hvalid_i;
	default_config_rx_st_dvalid_o               <=  ed_rx_st_dvalid_i;
	default_config_rx_st_pvalid_o               <=  ed_rx_st_pvalid_i;
	default_config_rx_st_empty_o                <=  ed_rx_st_empty_i;
	default_config_rx_st_pfnum_o                <=  ed_rx_st_pfnum_i;
	default_config_rx_st_tlp_prfx_o             <=  ed_rx_st_tlp_prfx_i;
	default_config_rx_st_data_parity_o          <=  ed_rx_st_data_parity_i;
	default_config_rx_st_hdr_parity_o           <=  ed_rx_st_hdr_parity_i;
	default_config_rx_st_tlp_prfx_parity_o      <=  ed_rx_st_tlp_prfx_parity_i;
	default_config_rx_st_rssai_prefix_o         <=  ed_rx_st_rssai_prefix_i;
	default_config_rx_st_rssai_prefix_parity_o  <=  ed_rx_st_rssai_prefix_parity_i;
	default_config_rx_st_vfactive_o             <=  ed_rx_st_vfactive_i;
	default_config_rx_st_vfnum_o                <=  ed_rx_st_vfnum_i;
	default_config_rx_st_chnum_o                <=  ed_rx_st_chnum_i;
	default_config_rx_st_misc_parity_o          <=  ed_rx_st_misc_parity_i;
	default_config_rx_st_passthrough_o          <=  ed_rx_st_passthrough_i;
end
else
begin
	default_config_rx_st_bar_o                  <=  '0;
	default_config_rx_st_eop_o                  <=  '0;
	default_config_rx_st_header_o               <=  '0;
	default_config_rx_st_payload_o              <=  '0;
	default_config_rx_st_sop_o                  <=  '0;
	default_config_rx_st_hvalid_o               <=  '0;
	default_config_rx_st_dvalid_o               <=  '0;
	default_config_rx_st_pvalid_o               <=  '0;
	default_config_rx_st_empty_o                <=  '0;
	default_config_rx_st_pfnum_o                <=  '0;
	default_config_rx_st_tlp_prfx_o             <=  '0;
	default_config_rx_st_data_parity_o          <=  '0;
	default_config_rx_st_hdr_parity_o           <=  '0;
	default_config_rx_st_tlp_prfx_parity_o      <=  '0;
	default_config_rx_st_rssai_prefix_o         <=  '0;
	default_config_rx_st_rssai_prefix_parity_o  <=  '0;
	default_config_rx_st_vfactive_o             <=  '0;
	default_config_rx_st_vfnum_o                <=  '0;
	default_config_rx_st_chnum_o                <=  '0;
	default_config_rx_st_misc_parity_o          <=  '0;
	default_config_rx_st_passthrough_o          <=  '0;
end

end //always

assign ed_rx_st_ready_o =  default_config_rx_st_ready_i &  pio_rx_st_ready_i;
end
endgenerate


//--default config
generate if(ENABLE_ONLY_DEFAULT_CONFIG)
begin: ONLY_DEF
always_ff@(posedge clk)
begin
	     default_config_rx_st_bar_o                 <=    ed_rx_st_bar_i;                          
	     default_config_rx_st_eop_o                 <=    ed_rx_st_eop_i;      
	     default_config_rx_st_header_o              <=    ed_rx_st_header_i;   
	     default_config_rx_st_payload_o             <=    ed_rx_st_payload_i;  
	     default_config_rx_st_sop_o                 <=    ed_rx_st_sop_i;      
	     default_config_rx_st_hvalid_o              <=    ed_rx_st_hvalid_i;   
	     default_config_rx_st_dvalid_o              <=    ed_rx_st_dvalid_i;   
	     default_config_rx_st_pvalid_o              <=    ed_rx_st_pvalid_i;   
	     default_config_rx_st_empty_o               <=    ed_rx_st_empty_i;    
	     default_config_rx_st_pfnum_o               <=    ed_rx_st_pfnum_i;         
	     default_config_rx_st_tlp_prfx_o            <=    ed_rx_st_tlp_prfx_i; 
	     default_config_rx_st_data_parity_o         <=    ed_rx_st_data_parity_i;
	     default_config_rx_st_hdr_parity_o          <=    ed_rx_st_hdr_parity_i;
	     default_config_rx_st_tlp_prfx_parity_o     <=    ed_rx_st_tlp_prfx_parity_i;
	     default_config_rx_st_rssai_prefix_o        <=    ed_rx_st_rssai_prefix_i;
	     default_config_rx_st_rssai_prefix_parity_o <=    ed_rx_st_rssai_prefix_parity_i;
	     default_config_rx_st_vfactive_o            <=    ed_rx_st_vfactive_i;
	     default_config_rx_st_vfnum_o               <=    ed_rx_st_vfnum_i;
	     default_config_rx_st_chnum_o               <=    ed_rx_st_chnum_i;
	     default_config_rx_st_misc_parity_o         <=    ed_rx_st_misc_parity_i;
	     default_config_rx_st_passthrough_o         <=    ed_rx_st_passthrough_i;
end //always

assign ed_rx_st_ready_o =  default_config_rx_st_ready_i ;
end
endgenerate



//--pio

generate if(ENABLE_ONLY_PIO)
begin: ONLY_PIO
always_ff@(posedge clk)
begin
     if(!afu_pio_select) begin
	     pio_rx_st_bar_o                 <=    ed_rx_st_bar_i;                          
	     pio_rx_st_eop_o                 <=    ed_rx_st_eop_i;      
	     pio_rx_st_header_o              <=    ed_rx_st_header_i;   
	     pio_rx_st_payload_o             <=    ed_rx_st_payload_i;  
	     pio_rx_st_sop_o                 <=    ed_rx_st_sop_i;      
	     pio_rx_st_hvalid_o              <=    ed_rx_st_hvalid_i;   
	     pio_rx_st_dvalid_o              <=    ed_rx_st_dvalid_i;   
	     pio_rx_st_pvalid_o              <=    ed_rx_st_pvalid_i;   
	     pio_rx_st_empty_o               <=    ed_rx_st_empty_i;    
	     pio_rx_st_pfnum_o               <=    ed_rx_st_pfnum_i;         
	     pio_rx_st_tlp_prfx_o            <=    ed_rx_st_tlp_prfx_i; 
	     pio_rx_st_data_parity_o         <=    ed_rx_st_data_parity_i;
	     pio_rx_st_hdr_parity_o          <=    ed_rx_st_hdr_parity_i;
	     pio_rx_st_tlp_prfx_parity_o     <=    ed_rx_st_tlp_prfx_parity_i;
	     pio_rx_st_rssai_prefix_o        <=    ed_rx_st_rssai_prefix_i;
	     pio_rx_st_rssai_prefix_parity_o <=    ed_rx_st_rssai_prefix_parity_i;
	     pio_rx_st_vfactive_o            <=    ed_rx_st_vfactive_i;
	     pio_rx_st_vfnum_o               <=    ed_rx_st_vfnum_i;
	     pio_rx_st_chnum_o               <=    ed_rx_st_chnum_i;
	     pio_rx_st_misc_parity_o         <=    ed_rx_st_misc_parity_i;
	     pio_rx_st_passthrough_o         <=    ed_rx_st_passthrough_i;
     end
     else begin
	     afu_rx_st_bar_o                 <=    ed_rx_st_bar_i;                          
	     afu_rx_st_eop_o                 <=    ed_rx_st_eop_i;      
	     afu_rx_st_header_o              <=    ed_rx_st_header_i;   
	     afu_rx_st_payload_o             <=    ed_rx_st_payload_i;  
	     afu_rx_st_sop_o                 <=    ed_rx_st_sop_i;      
	     afu_rx_st_hvalid_o              <=    ed_rx_st_hvalid_i;   
	     afu_rx_st_dvalid_o              <=    ed_rx_st_dvalid_i;   
	     afu_rx_st_pvalid_o              <=    ed_rx_st_pvalid_i;   
	     afu_rx_st_empty_o               <=    ed_rx_st_empty_i;    
	     afu_rx_st_pfnum_o               <=    ed_rx_st_pfnum_i;         
	     afu_rx_st_tlp_prfx_o            <=    ed_rx_st_tlp_prfx_i; 
	     afu_rx_st_data_parity_o         <=    ed_rx_st_data_parity_i;
	     afu_rx_st_hdr_parity_o          <=    ed_rx_st_hdr_parity_i;
	     afu_rx_st_tlp_prfx_parity_o     <=    ed_rx_st_tlp_prfx_parity_i;
	     afu_rx_st_rssai_prefix_o        <=    ed_rx_st_rssai_prefix_i;
	     afu_rx_st_rssai_prefix_parity_o <=    ed_rx_st_rssai_prefix_parity_i;
	     afu_rx_st_vfactive_o            <=    ed_rx_st_vfactive_i;
	     afu_rx_st_vfnum_o               <=    ed_rx_st_vfnum_i;
	     afu_rx_st_chnum_o               <=    ed_rx_st_chnum_i;
	     afu_rx_st_misc_parity_o         <=    ed_rx_st_misc_parity_i;
	     afu_rx_st_passthrough_o         <=    ed_rx_st_passthrough_i;
     end
end //always

assign ed_rx_st_ready_o =  pio_rx_st_ready_i ;
end
endgenerate

endmodule //intel_cxl_pf_checker
