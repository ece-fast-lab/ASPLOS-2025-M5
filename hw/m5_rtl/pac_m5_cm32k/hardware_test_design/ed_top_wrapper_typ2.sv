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
//---------------------------------------------
//   ed_top_wrapper_typ2
//---------------------------------------------

import cxlip_top_pkg::*;
import afu_axi_if_pkg::*;
import cafu_csr0_cfg_pkg::*;
import tmp_cafu_csr0_cfg_pkg::*;
import intel_cxl_pio_parameters :: *;
import mc_ecc_pkg::*;
import mc_axi_if_pkg::*;
import ctrl_signal_types::MONITOR_REGION_WIDTH;
`include "avst4to1_pld_if.svh.iv"
`include "cxl_ed_defines.svh.iv"

module ed_top_wrapper_typ2 
#(

   localparam T1IP_ENABLE              = 1'b0 
)
(

    // Clocks
    input logic                ip2hdm_clk,             // SIP clk
    input   logic                     ip2cafu_avmm_clk,             //AVMM clock : 125MHz
    input   logic                     ip2csr_avmm_clk,              //AVMM clock : 125MHz
    // Resets
    input logic                ip2hdm_reset_n ,        // SIP RST 
    input   logic                     ip2cafu_avmm_rstn,            //cafu_AVMM_rst_n
    input   logic                     ip2csr_avmm_rstn,             //csr_AVMM_rst_n 

    //AVST_interface_Output_from_IP                                                                                                    
    input   logic                     ed_rx_st0_eop_i,              //AVST segment0 End of Packet
    input   logic                     ed_rx_st1_eop_i,              //AVST segment1 End of Packet 
    input   logic                     ed_rx_st2_eop_i,              //AVST segment2 End of Packet
    input   logic                     ed_rx_st3_eop_i,              //AVST segment3 End of Packet
    input   logic  [127:0]            ed_rx_st0_header_i,           //AVST segment0 Header 
    input   logic  [127:0]            ed_rx_st1_header_i,           //AVST segment1 Header 
    input   logic  [127:0]            ed_rx_st2_header_i,           //AVST segment2 Header 
    input   logic  [127:0]            ed_rx_st3_header_i,           //AVST segment3 Header 
    input   logic  [255:0]            ed_rx_st0_payload_i,          //AVST segment0 Data 
    input   logic  [255:0]            ed_rx_st1_payload_i,          //AVST segment1 Data 
    input   logic  [255:0]            ed_rx_st2_payload_i,          //AVST segment2 Data 
    input   logic  [255:0]            ed_rx_st3_payload_i,          //AVST segment3 Data 
    input   logic                     ed_rx_st0_sop_i,              //AVST segment0 Start of Packet 
    input   logic                     ed_rx_st1_sop_i,              //AVST segment1 Start of Packet 
    input   logic                     ed_rx_st2_sop_i,              //AVST segment2 Start of Packet 
    input   logic                     ed_rx_st3_sop_i,              //AVST segment3 Start of Packet 
    input   logic                     ed_rx_st0_hvalid_i,           //AVST segment0 Header Valid 
    input   logic                     ed_rx_st1_hvalid_i,           //AVST segment1 Header Valid 
    input   logic                     ed_rx_st2_hvalid_i,           //AVST segment2 Header Valid 
    input   logic                     ed_rx_st3_hvalid_i,           //AVST segment3 Header Valid 
    input   logic                     ed_rx_st0_dvalid_i,           //AVST segment0 Data Valid 
    input   logic                     ed_rx_st1_dvalid_i,           //AVST segment1 Data Valid 
    input   logic                     ed_rx_st2_dvalid_i,           //AVST segment2 Data Valid 
    input   logic                     ed_rx_st3_dvalid_i,           //AVST segment3 Data Valid 
    input   logic                     ed_rx_st0_pvalid_i,           //AVST segment0 Prefix Valid  
    input   logic                     ed_rx_st1_pvalid_i,           //AVST segment1 Prefix Valid  
    input   logic                     ed_rx_st2_pvalid_i,           //AVST segment2 Prefix Valid  
    input   logic                     ed_rx_st3_pvalid_i,           //AVST segment3 Prefix Valid  
    input   logic  [2:0]              ed_rx_st0_empty_i,            //AVST segment0 No.Of Dwords empty when corresponding EOP is asserted 
    input   logic  [2:0]              ed_rx_st1_empty_i,            //AVST segment1 No.Of Dwords empty when corresponding EOP is asserted 
    input   logic  [2:0]              ed_rx_st2_empty_i,            //AVST segment2 No.Of Dwords empty when corresponding EOP is asserted 
    input   logic  [2:0]              ed_rx_st3_empty_i,            //AVST segment3 No.Of Dwords empty when corresponding EOP is asserted 
    input   logic  [PFNUM_WIDTH-1:0]  ed_rx_st0_pfnum_i,            //AVST segment0 PF number of TLP 
    input   logic  [PFNUM_WIDTH-1:0]  ed_rx_st1_pfnum_i,            //AVST segment1 PF number of TLP 
    input   logic  [PFNUM_WIDTH-1:0]  ed_rx_st2_pfnum_i,            //AVST segment2 PF number of TLP 
    input   logic  [PFNUM_WIDTH-1:0]  ed_rx_st3_pfnum_i,            //AVST segment3 PF number of TLP 
    input   logic  [31:0]             ed_rx_st0_tlp_prfx_i,         //AVST segment0 PCIe TLP Prefix 
    input   logic  [31:0]             ed_rx_st1_tlp_prfx_i,         //AVST segment1 PCIe TLP Prefix 
    input   logic  [31:0]             ed_rx_st2_tlp_prfx_i,         //AVST segment2 PCIe TLP Prefix 
    input   logic  [31:0]             ed_rx_st3_tlp_prfx_i,         //AVST segment3 PCIe TLP Prefix 
    input   logic  [7:0]              ed_rx_st0_data_parity_i,      //AVST segment0 Parity for Data
    input   logic  [3:0]              ed_rx_st0_hdr_parity_i,       //AVST segment0 Parity for Header 
    input   logic                     ed_rx_st0_tlp_prfx_parity_i,  //AVST segment0 Parity for Prefix 
    input   logic                     ed_rx_st0_misc_parity_i,      //AVST segment0 
    input   logic  [7:0]              ed_rx_st1_data_parity_i,      //AVST segment1 Parity for Data    
    input   logic  [3:0]              ed_rx_st1_hdr_parity_i,       //AVST segment1 Parity for Header  
    input   logic                     ed_rx_st1_tlp_prfx_parity_i,  //AVST segment1 Parity for Prefix  
    input   logic                     ed_rx_st1_misc_parity_i,      //AVST segment1                    
    input   logic  [7:0]              ed_rx_st2_data_parity_i,      //AVST segment2 Parity for Data    
    input   logic  [3:0]              ed_rx_st2_hdr_parity_i,       //AVST segment2 Parity for Header  
    input   logic                     ed_rx_st2_tlp_prfx_parity_i,  //AVST segment2 Parity for Prefix  
    input   logic                     ed_rx_st2_misc_parity_i,      //AVST segment2                    
    input   logic  [7:0]              ed_rx_st3_data_parity_i,      //AVST segment3 Parity for Data    
    input   logic  [3:0]              ed_rx_st3_hdr_parity_i,       //AVST segment3 Parity for Header  
    input   logic                     ed_rx_st3_tlp_prfx_parity_i,  //AVST segment3 Parity for Prefix  
    input   logic                     ed_rx_st3_misc_parity_i,      //AVST segment3                    
    input   logic                     ed_rx_st0_passthrough_i,      //AVST segment0 indicates TLP is targetted to PF2 to PF7 
    input   logic                     ed_rx_st1_passthrough_i,      //AVST segment1 indicates TLP is targetted to PF2 to PF7  
    input   logic                     ed_rx_st2_passthrough_i,      //AVST segment2 indicates TLP is targetted to PF2 to PF7  
    input   logic                     ed_rx_st3_passthrough_i,      //AVST segment3 indicates TLP is targetted to PF2 to PF7  
    input   logic  [2:0]              ed_rx_st0_bar_i,              //AVST segment0 indicates BAR number 
    input   logic  [2:0]              ed_rx_st1_bar_i,              //AVST segment1 indicates BAR number 
    input   logic  [2:0]              ed_rx_st2_bar_i,              //AVST segment2 indicates BAR number 
    input   logic  [2:0]              ed_rx_st3_bar_i,              //AVST segment3 indicates BAR number 
    input   logic  [7:0]              ed_rx_bus_number,             //Bus number assigned by Host 
    input   logic  [4:0]              ed_rx_device_number,          //Device number assigned by Host  
    input   logic  [2:0]              ed_rx_function_number,        //Function Number assigned by Host  
    //--                                                                
    output  logic                     ed_rx_st_ready_o,             //AVST Ready 
    output  logic                     ed_clk,                       //  
    output  logic                     ed_rst_n,                     //  
    //                                                                  
    output  logic                     ed_tx_st0_eop_o,              //AVST segment0 End of Packet                                          
    output  logic                     ed_tx_st1_eop_o,              //AVST segment1 End of Packet                                          
    output  logic                     ed_tx_st2_eop_o,              //AVST segment2 End of Packet                                          
    output  logic                     ed_tx_st3_eop_o,              //AVST segment3 End of Packet                                          
    output  logic  [127:0]            ed_tx_st0_header_o,           //AVST segment0 Header                                                 
    output  logic  [127:0]            ed_tx_st1_header_o,           //AVST segment1 Header                                                 
    output  logic  [127:0]            ed_tx_st2_header_o,           //AVST segment2 Header                                                 
    output  logic  [127:0]            ed_tx_st3_header_o,           //AVST segment3 Header                                                 
    output  logic  [31:0]             ed_tx_st0_prefix_o,           //AVST segment0 Prefix  
    output  logic  [31:0]             ed_tx_st1_prefix_o,           //AVST segment1 Prefix    
    output  logic  [31:0]             ed_tx_st2_prefix_o,           //AVST segment2 Prefix    
    output  logic  [31:0]             ed_tx_st3_prefix_o,           //AVST segment3 Prefix    
    output  logic  [255:0]            ed_tx_st0_payload_o,          //AVST segment0 Data  
    output  logic  [255:0]            ed_tx_st1_payload_o,          //AVST segment1 Data   
    output  logic  [255:0]            ed_tx_st2_payload_o,          //AVST segment2 Data  
    output  logic  [255:0]            ed_tx_st3_payload_o,          //AVST segment3 Data  
    output  logic                     ed_tx_st0_sop_o,              //AVST segment0 Start of Packet  
    output  logic                     ed_tx_st1_sop_o,              //AVST segment1 Start of Packet  
    output  logic                     ed_tx_st2_sop_o,              //AVST segment2 Start of Packet  
    output  logic                     ed_tx_st3_sop_o,              //AVST segment3 Start of Packet  
    output  logic                     ed_tx_st0_dvalid_o,           //AVST segment0 Data Valid  
    output  logic                     ed_tx_st1_dvalid_o,           //AVST segment1 Data Valid  
    output  logic                     ed_tx_st2_dvalid_o,           //AVST segment2 Data Valid  
    output  logic                     ed_tx_st3_dvalid_o,           //AVST segment3 Data Valid  
    output  logic                     ed_tx_st0_pvalid_o,           //AVST segment0 Prefix Valid  
    output  logic                     ed_tx_st1_pvalid_o,           //AVST segment1 Prefix Valid  
    output  logic                     ed_tx_st2_pvalid_o,           //AVST segment2 Prefix Valid  
    output  logic                     ed_tx_st3_pvalid_o,           //AVST segment3 Prefix Valid  
    output  logic                     ed_tx_st0_hvalid_o,           //AVST segment0 Header Valid  
    output  logic                     ed_tx_st1_hvalid_o,           //AVST segment1 Header Valid  
    output  logic                     ed_tx_st2_hvalid_o,           //AVST segment2 Header Valid  
    output  logic                     ed_tx_st3_hvalid_o,           //AVST segment3 Header Valid  
    output  logic  [7:0]              ed_tx_st0_data_parity,        //AVST segment0 Data Parity  
    output  logic  [3:0]              ed_tx_st0_hdr_parity,         //AVST segment0 Header Parity  
    output  logic                     ed_tx_st0_prefix_parity,      //AVST segment0 Prefix Parity  
    output  logic  [2:0]              ed_tx_st0_empty,              //AVST segment0 Empty  
    output  logic                     ed_tx_st0_misc_parity,        //AVST segment0   
    output  logic  [7:0]              ed_tx_st1_data_parity,        //AVST segment1 Data Parity  
    output  logic  [3:0]              ed_tx_st1_hdr_parity,         //AVST segment1 Header Parity  
    output  logic                     ed_tx_st1_prefix_parity,      //AVST segment1 Prefix Parity  
    output  logic  [2:0]              ed_tx_st1_empty,              //AVST segment1 Empty  
    output  logic                     ed_tx_st1_misc_parity,        //AVST segment1   
    output  logic  [7:0]              ed_tx_st2_data_parity,        //AVST segment2 Data Parity      
    output  logic  [3:0]              ed_tx_st2_hdr_parity,         //AVST segment2 Header Parity    
    output  logic                     ed_tx_st2_prefix_parity,      //AVST segment2 Prefix Parity    
    output  logic  [2:0]              ed_tx_st2_empty,              //AVST segment2 Empty            
    output  logic                     ed_tx_st2_misc_parity,        //AVST segment2  
    output  logic  [7:0]              ed_tx_st3_data_parity,        //AVST segment3 Data Parity      
    output  logic  [3:0]              ed_tx_st3_hdr_parity,         //AVST segment3 Header Parity    
    output  logic                     ed_tx_st3_prefix_parity,      //AVST segment3 Prefix Parity    
    output  logic  [2:0]              ed_tx_st3_empty,              //AVST segment3 Empty            
    output  logic                     ed_tx_st3_misc_parity,        //AVST segment3   
    input   logic                     ed_tx_st_ready_i,             //AVST ready from IP   
    //                                                                
    output  logic  [2:0]              rx_st_hcrdt_update_o,         //Indicates Header credit is made available to Host. Bit[0] – PH, Bit[1] – NPH, Bit[2] – CPLH              //Rx_Header_credit_towards_HOST
    output  logic  [5:0]              rx_st_hcrdt_update_cnt_o,     //Indicate number of Header credits released to Host. Bit[1:0] – PH credits , Bit[3:2] – NPH credits, Bit[5:4] – CPLH credits 
    output  logic  [2:0]              rx_st_hcrdt_init_o,           //Credit Initialization indicator, remain high for entire initialization phase. 
    input   logic  [2:0]              rx_st_hcrdt_init_ack_i,       //Indicates host is ready for credit initialization phase  
    //                                                                  
    output  logic  [2:0]              rx_st_dcrdt_update_o,         //Indicates Data credit is made available. Bit[0] – PH, Bit[1] – NPH, Bit[2] – CPLH             // Rx_Data_credit_towards_HOST
    output  logic  [11:0]             rx_st_dcrdt_update_cnt_o,     //Indicate number of Header credits released. Bit[3:0] – PH credits , Bit[7:4] – NPH credits, Bit[11:8] – CPLH credits
    output  logic  [2:0]              rx_st_dcrdt_init_o,           //Credit Initialization indicator, remain high for entire initialization phase.
    input   logic  [2:0]              rx_st_dcrdt_init_ack_i,       //Indicates host is ready for credit initialization phase
    //                                                                     
    input   logic  [2:0]              tx_st_hcrdt_update_i,         //Indicates Header credit is made available by Host. Bit[0] – PH, Bit[1] – NPH, Bit[2] – CPLH  //Tx_Header_credit_from_HOST
    input   logic  [5:0]              tx_st_hcrdt_update_cnt_i,     //Indicate number of Header credits released to Host. Bit[1:0] – PH credits , Bit[3:2] – NPH credits, Bit[5:4] – CPLH credits  
    input   logic  [2:0]              tx_st_hcrdt_init_i,           //Credit Initialization indicator, remain high for entire initialization phase.  
    output  logic  [2:0]              tx_st_hcrdt_init_ack_o,       //Indicates Device (User Logic) is ready for credit initialization phase  
    //                                                                  
    input   logic  [2:0]              tx_st_dcrdt_update_i,         //Indicates Data credit is made available. Bit[0] – PH, Bit[1] – NPH, Bit[2] – CPLH  //Tx_Data_credit_from_HOST
    input   logic  [11:0]             tx_st_dcrdt_update_cnt_i,     //Indicate number of Header credits released. Bit[3:0] – PH credits , Bit[7:4] – NPH credits, Bit[11:8] – CPLH credits  
    input   logic  [2:0]              tx_st_dcrdt_init_i,           //Credit Initialization indicator, remain high for entire initialization phase.  
    output  logic  [2:0]              tx_st_dcrdt_init_ack_o,       //Indicates Device (User Logic) is ready for credit initialization phase  
    //                                                                                              
    input   logic  [31:0]             ccv_afu_conf_base_addr_high,  //bios_based_memory_base_address  
    input   logic                     ccv_afu_conf_base_addr_high_valid,                            
    input   logic  [27:0]             ccv_afu_conf_base_addr_low,                                   
    input   logic                     ccv_afu_conf_base_addr_low_valid,                             
    input   logic  [2:0]              pf0_max_payload_size,         //PF0 Max Payload Size                                
    input   logic  [2:0]              pf0_max_read_request_size,    //PF0 Max Read Request Size                                 
    input   logic                     pf0_bus_master_en,            //PF0 Bus master enable                                
    input   logic                     pf0_memory_access_en,         //PF0 Memory access enable                                
    input   logic  [2:0]              pf1_max_payload_size,         //PF1 Max Payload Size                                
    input   logic  [2:0]              pf1_max_read_request_size,    //PF0 Max Read Request Size                               
    input   logic                     pf1_bus_master_en,            //PF0 Bus master enable                                   
    input   logic                     pf1_memory_access_en,         //PF0 Memory access enable                                
    //From_User  Error Interface
    output   logic                    usr2ip_app_err_valid,   
    output   logic [31:0]             usr2ip_app_err_hdr,  
    output   logic [13:0]             usr2ip_app_err_info,
    output   logic [2:0]              usr2ip_app_err_func_num,
    //To_User  Error Interface
    input    logic                    ip2usr_app_err_ready,
    //FROM IP to USER
    input  logic                      ip2usr_aermsg_correctable_valid ,
    input  logic                      ip2usr_aermsg_uncorrectable_valid,
    input  logic                      ip2usr_aermsg_res ,  
    input  logic                      ip2usr_aermsg_bts ,  
    input  logic                      ip2usr_aermsg_bds ,  
    input  logic                      ip2usr_aermsg_rrs ,  
    input  logic                      ip2usr_aermsg_rtts,  
    input  logic                      ip2usr_aermsg_anes,  
    input  logic                      ip2usr_aermsg_cies,  
    input  logic                      ip2usr_aermsg_hlos,  
    input  logic [1:0]                ip2usr_aermsg_fmt ,  
    input  logic [4:0]                ip2usr_aermsg_type,  
    input  logic [2:0]                ip2usr_aermsg_tc  ,  
    input  logic                      ip2usr_aermsg_ido ,  
    input  logic                      ip2usr_aermsg_th  ,  
    input  logic                      ip2usr_aermsg_td  ,  
    input  logic                      ip2usr_aermsg_ep  ,  
    input  logic                      ip2usr_aermsg_ro  ,  
    input  logic                      ip2usr_aermsg_ns  ,  
    input  logic [1:0]                ip2usr_aermsg_at  ,  
    input  logic [9:0]                ip2usr_aermsg_length,
    input  logic [95:0]               ip2usr_aermsg_header,
    input  logic                      ip2usr_aermsg_und,   
    input  logic                      ip2usr_aermsg_anf,   
    input  logic                      ip2usr_aermsg_dlpes, 
    input  logic                      ip2usr_aermsg_sdes,  
    input  logic [4:0]                ip2usr_aermsg_fep,   
    input  logic                      ip2usr_aermsg_pts,   
    input  logic                      ip2usr_aermsg_fcpes, 
    input  logic                      ip2usr_aermsg_cts ,  
    input  logic                      ip2usr_aermsg_cas ,  
    input  logic                      ip2usr_aermsg_ucs ,  
    input  logic                      ip2usr_aermsg_ros ,  
    input  logic                      ip2usr_aermsg_mts ,  
    input  logic                      ip2usr_aermsg_uies,  
    input  logic                      ip2usr_aermsg_mbts,  
    input  logic                      ip2usr_aermsg_aebs,  
    input  logic                      ip2usr_aermsg_tpbes, 
    input  logic                      ip2usr_aermsg_ees,   
    input  logic                      ip2usr_aermsg_ures,  
    input  logic                      ip2usr_aermsg_avs ,     
    input  logic                      ip2usr_serr_out,
    //input    logic                    ip2usr_err_valid,
    //input    logic [127:0]            ip2usr_err_hdr,
    //input    logic [31:0]             ip2usr_err_tlp_prefix,
    //input    logic [13:0]             ip2usr_err_info,
    //Debug access
    input    logic                    ip2usr_debug_waitrequest,   
    input    logic [31:0]             ip2usr_debug_readdata,   
    input    logic                    ip2usr_debug_readdatavalid,   
    output   logic [31:0]             usr2ip_debug_writedata,   
    output   logic [31:0]             usr2ip_debug_address,   
    output   logic                    usr2ip_debug_write,   
    output   logic                    usr2ip_debug_read,   
    output   logic [3:0]              usr2ip_debug_byteenable,   
    //MSI-X_user_interface                                                                                              
    input   logic                     pf0_msix_enable,              //PF0 MSI-X enable                                 
    input   logic                     pf0_msix_fn_mask,             //PF0 MSI-X function mask                                
    input   logic                     pf1_msix_enable,              //PF1 MSI-X enable                                
    input   logic                     pf1_msix_fn_mask,             //PF1 MSI-X function mask                                
    output  logic  [63:0]             dev_serial_num,               //Device serial number for identification                                
    output  logic                     dev_serial_num_valid,         //Valid for Device serial number                                

    output  logic  [95:0]             cafu2ip_csr0_cfg_if,          //DVSEC values for IP
    input   logic  [5:0]              ip2cafu_csr0_cfg_if,          //
    //                                                                                              
    output  logic                     cafu2ip_avmm_waitrequest,     //CSR_Access_AVMM_Interface
    output  logic  [63:0]             cafu2ip_avmm_readdata,                                        
    output  logic                     cafu2ip_avmm_readdatavalid,                                   
    input   logic  [63:0]             ip2cafu_avmm_writedata,                                       
    input   logic                     ip2cafu_avmm_poison,                                           
    input   logic  [21:0]             ip2cafu_avmm_address,                                         
    input   logic                     ip2cafu_avmm_write,                                           
    input   logic                     ip2cafu_avmm_read,                                            
    input   logic  [7:0]              ip2cafu_avmm_byteenable,                                      

 
    output logic   [1:0]              u2ip_0_qos_devload,

    //cafu_csr - AXI interface
    //AXI-MM interface - write address channel
    output logic   [11:0]               axi0_awid,
    output logic   [63:0]               axi0_awaddr, 
    output logic   [9:0]                axi0_awlen,
    output logic   [2:0]                axi0_awsize,
    output logic   [1:0]                axi0_awburst,
    output logic   [2:0]                axi0_awprot,
    output logic   [3:0]                axi0_awqos,
    output logic   [5:0]                axi0_awuser,
    output logic                        axi0_awvalid,
    output logic   [3:0]                axi0_awcache,
    output logic   [1:0]                axi0_awlock,
    output logic   [3:0]                axi0_awregion,
    output logic   [5:0]                axi0_awatop,
    input                               axi0_awready,
  
    //AXI-MM interface - write data channel
    output logic   [511:0]              axi0_wdata,
    output logic   [(512/8)-1:0]        axi0_wstrb,
    output logic                        axi0_wlast,
    output logic                        axi0_wuser,
    output logic                        axi0_wvalid,
    input                               axi0_wready,
  
   //AXI-MM interface - write response channel
    input  logic   [11:0]               axi0_bid,
    input  logic   [1:0]                axi0_bresp,
    input  logic   [3:0]                axi0_buser,
    input  logic                        axi0_bvalid,
    output logic                        axi0_bready,
  
   //AXI-MM interface - read address channel
    output logic   [11:0]               axi0_arid,
    output logic   [63:0]               axi0_araddr,
    output logic   [9:0]                axi0_arlen,
    output logic   [2:0]                axi0_arsize,
    output logic   [1:0]                axi0_arburst,
    output logic   [2:0]                axi0_arprot,
    output logic   [3:0]                axi0_arqos,
    output logic   [5:0]                axi0_aruser,
    output logic                        axi0_arvalid,
    output logic   [3:0]                axi0_arcache,
    output logic   [1:0]                axi0_arlock,
    output logic   [3:0]                axi0_arregion,
    input  logic                        axi0_arready,

   //AXI-MM interface - read response channel
    input  logic   [11:0]               axi0_rid,
    input  logic   [511:0]              axi0_rdata,
    input  logic   [1:0]                axi0_rresp,
    input  logic                        axi0_rlast,
    input  logic                        axi0_ruser,
    input  logic                        axi0_rvalid,
    output logic                        axi0_rready,
  

  // CXL-IP <--> AFU quiesce interface
    input  logic                        ip2cafu_quiesce_req,
    output logic                        cafu2ip_quiesce_ack,
    //CXL RESET handshake signal to ED 
    output logic                                usr2ip_cxlreset_initiate, 
    input  logic                                ip2usr_cxlreset_req,  
    output logic                                usr2ip_cxlreset_ack,  
    input  logic                                ip2usr_cxlreset_error,
    input  logic                                ip2usr_cxlreset_complete, 
  // User AFU
  // AXI-MM interface - write address channel
    output logic [11:0]                 axi1_awid,
    output logic [63:0]                 axi1_awaddr, 
    output logic [9:0]                  axi1_awlen,
    output logic [2:0]                  axi1_awsize,
    output logic [1:0]                  axi1_awburst,
    output logic [2:0]                  axi1_awprot,
    output logic [3:0]                  axi1_awqos,
    output logic [5:0]                  axi1_awuser,
    output logic                        axi1_awvalid,
    output logic [3:0]                  axi1_awcache,
    output logic [1:0]                  axi1_awlock,
    output logic [3:0]                  axi1_awregion,
    output logic [5:0]                  axi1_awatop,
    input  logic                        axi1_awready,
  
  // AXI-MM interface - write data channel
    output logic [511:0]                axi1_wdata,
    output logic [(512/8)-1:0]          axi1_wstrb,
    output logic                        axi1_wlast,
    output logic                        axi1_wuser,
    output logic                        axi1_wvalid,
    input  logic                        axi1_wready,
  
// AXI-MM interface - write response channel
    input  logic [11:0]                 axi1_bid,
    input  logic [1:0]                  axi1_bresp,
    input  logic [3:0]                  axi1_buser,
    input  logic                        axi1_bvalid,
    output logic                        axi1_bready,
  
  
// AXI-MM interface - read address channel  
    output logic [11:0]                 axi1_arid,
    output logic [63:0]                 axi1_araddr,
    output logic [9:0]                  axi1_arlen,
    output logic [2:0]                  axi1_arsize,
    output logic [1:0]                  axi1_arburst,
    output logic [2:0]                  axi1_arprot,
    output logic [3:0]                  axi1_arqos,
    output logic [5:0]                  axi1_aruser,
    output logic                        axi1_arvalid,
    output logic [3:0]                  axi1_arcache,
    output logic [1:0]                  axi1_arlock,
    output logic [3:0]                  axi1_arregion,
    input                               axi1_arready,

// AXI-MM interface - read response channel
    input  logic [11:0]                 axi1_rid,
    input  logic [511:0]                axi1_rdata,
    input  logic [1:0]                  axi1_rresp,
    input  logic                        axi1_rlast,
    input  logic                        axi1_ruser,
    input  logic                        axi1_rvalid,
    output logic                        axi1_rready,

// DDRMC <--> CXL-IP 
    output  logic [63:0]              mc2ip_memsize,                //Not releavant for current implemntation


//Channel-0
    output  logic  [cxlip_top_pkg::MC_SR_STAT_WIDTH-1:0]     mc2ip_0_sr_status,               //HDM controller status
//Channel-0
     /* write address channel
      */
  input logic          ip2hdm_aximm0_awvalid    ,       
  input logic  [11:0]  ip2hdm_aximm0_awid       ,       
  input logic  [51:0]  ip2hdm_aximm0_awaddr     ,       
  input logic  [9:0]   ip2hdm_aximm0_awlen      ,       
  input logic  [3:0]   ip2hdm_aximm0_awregion   ,       
  input logic          ip2hdm_aximm0_awuser     ,       
  input logic  [2:0]   ip2hdm_aximm0_awsize     ,      
  input logic  [1:0]   ip2hdm_aximm0_awburst    ,      
  input logic  [2:0]   ip2hdm_aximm0_awprot     ,      
  input logic  [3:0]   ip2hdm_aximm0_awqos      ,      
  input logic  [3:0]   ip2hdm_aximm0_awcache    ,      
  input logic  [1:0]   ip2hdm_aximm0_awlock     ,      
  output  logic          hdm2ip_aximm0_awready    ,
     /* write data channel
      */
  input logic          ip2hdm_aximm0_wvalid     ,          
  input logic  [511:0] ip2hdm_aximm0_wdata      ,           
  input logic  [63:0]  ip2hdm_aximm0_wstrb      ,           
  input logic          ip2hdm_aximm0_wlast      ,           
  input logic          ip2hdm_aximm0_wuser      ,           
  output logic           hdm2ip_aximm0_wready  	 ,
     /* write response channel
      */
  output  logic          hdm2ip_aximm0_bvalid     ,
  output  logic [11:0]    hdm2ip_aximm0_bid        ,
  output  logic          hdm2ip_aximm0_buser      ,
  output  logic [1:0]    hdm2ip_aximm0_bresp      ,
  input logic          ip2hdm_aximm0_bready     ,               
     /* read address channel
      */
  input logic          ip2hdm_aximm0_arvalid    ,         
  input logic  [11:0]  ip2hdm_aximm0_arid       ,         
  input logic  [51:0]  ip2hdm_aximm0_araddr     ,         
  input logic  [9:0]   ip2hdm_aximm0_arlen      ,         
  input logic  [3:0]   ip2hdm_aximm0_arregion   ,         
  input logic          ip2hdm_aximm0_aruser     ,         
  input logic  [2:0]   ip2hdm_aximm0_arsize     ,         
  input logic  [1:0]   ip2hdm_aximm0_arburst    ,         
  input logic  [2:0]   ip2hdm_aximm0_arprot     ,         
  input logic  [3:0]   ip2hdm_aximm0_arqos      ,         
  input logic  [3:0]   ip2hdm_aximm0_arcache    ,         
  input logic  [1:0]   ip2hdm_aximm0_arlock     ,         
  output logic          hdm2ip_aximm0_arready    , 
     /* read response channel
      */
  output  logic          hdm2ip_aximm0_rvalid     , 
  output  logic          hdm2ip_aximm0_rlast     , 
  output  logic  [11:0]  hdm2ip_aximm0_rid        ,
  output  logic  [511:0] hdm2ip_aximm0_rdata      ,
  output  logic          hdm2ip_aximm0_ruser      ,
  output  logic  [1:0]   hdm2ip_aximm0_rresp      ,
  input logic          ip2hdm_aximm0_rready     ,     
	




 
   //CLST - AXI_ST interface for Slice-0
    input  logic                        ip2cafu_axistd0_tvalid,
    input  logic  [71:0]                ip2cafu_axistd0_tdata, 
    input  logic  [8:0]                 ip2cafu_axistd0_tstrb,
    input  logic  [2:0]                 ip2cafu_axistd0_tdest,
    input  logic  [8:0]                 ip2cafu_axistd0_tkeep,
    input  logic                        ip2cafu_axistd0_tlast,
    input  logic  [7:0]                 ip2cafu_axistd0_tid,
    input  logic  [7:0]                 ip2cafu_axistd0_tuser,  
    output logic                        cafu2ip_axistd0_tready, 
    input  logic                        ip2cafu_axisth0_tvalid,
    input  logic  [71:0]                ip2cafu_axisth0_tdata, 
    input  logic  [8:0]                 ip2cafu_axisth0_tstrb,
    input  logic  [2:0]                 ip2cafu_axisth0_tdest,
    input  logic  [8:0]                 ip2cafu_axisth0_tkeep,
    input  logic                        ip2cafu_axisth0_tlast,
    input  logic  [7:0]                 ip2cafu_axisth0_tid,
    input  logic  [7:0]                 ip2cafu_axisth0_tuser,  
    output logic                        cafu2ip_axisth0_tready, 



//AFU inline CSR avmm access
    output logic                        csr2ip_avmm_waitrequest,  
    output logic  [63:0]                csr2ip_avmm_readdata,     
    output logic                        csr2ip_avmm_readdatavalid,
    input  logic  [63:0]                ip2csr_avmm_writedata,
    input  logic                        ip2csr_avmm_poison,
    input  logic  [21:0]                ip2csr_avmm_address,
    input  logic                        ip2csr_avmm_write,
    input  logic                        ip2csr_avmm_read, 
    input  logic  [7:0]                 ip2csr_avmm_byteenable,


// DDR interface pins 
// DDR Memory Interface (1 Channel)

    input  [0:0]        mem_refclk     ,            // EMIF PLL reference clock
    output [0:0][0:0]   mem_ck         ,  // DDR4 interface signals
    output [0:0][0:0]   mem_ck_n       ,  //
    output [0:0][16:0]  mem_a          ,  //
    output [0:0]        mem_act_n      ,             //
    output [0:0][1:0]   mem_ba         ,  //
    output [0:0][1:0]   mem_bg         ,  //
`ifdef HDM_64G
    output [0:0][1:0]   mem_cke        ,  //
    output [0:0][1:0]   mem_cs_n       ,  //
    output [0:0][1:0]   mem_odt        ,  //
`else
    output [0:0][0:0]   mem_cke        ,  //
    output [0:0][0:0]   mem_cs_n       ,  //
    output [0:0][0:0]   mem_odt        ,  //
`endif
    output [0:0]        mem_reset_n    ,           //
    output [0:0]        mem_par        ,               //
    input  [0:0]        mem_oct_rzqin  ,         //
    input  [0:0]        mem_alert_n    , 
`ifdef ENABLE_DDR_DBI_PINS                //Micron DIMM
    inout  [0:0][8:0]   mem_dqs        ,  //
    inout  [0:0][8:0]   mem_dqs_n      ,  //
    inout  [0:0][8:0]   mem_dbi_n      ,  //
`else
    inout  [0:0][17:0]  mem_dqs        ,  //
    inout  [0:0][17:0]  mem_dqs_n      ,  //
`endif  
    inout  [0:0][71:0]  mem_dq            //

// DDR Memory Interface (4 Channel)



);

  //-------------------------------------------------------
  // Signals & Settings                                  --
  //-------------------------------------------------------


//User can implement the logic based on the queisce signal
    logic                                        ip2cafu_quiesce_req_f                ;                       
    logic                                        ip2cafu_quiesce_req_ff               ;                       

    logic                 [2:0]                  ed_rx_st0_chnum_i                    ; //Static signals
    logic                 [2:0]                  ed_rx_st1_chnum_i                    ;                                                    
    logic                 [2:0]                  ed_rx_st2_chnum_i                    ;                                                    
    logic                 [2:0]                  ed_rx_st3_chnum_i                    ;                                                    
    logic                 [10:0]                 ed_rx_st0_vfnum_i                    ;                                                    
    logic                 [10:0]                 ed_rx_st1_vfnum_i                    ;                                                    
    logic                 [10:0]                 ed_rx_st2_vfnum_i                    ;                                                    
    logic                 [10:0]                 ed_rx_st3_vfnum_i                    ;                                                    
    logic                                        ed_rx_st0_vfactive_i                 ;                                                    
    logic                                        ed_rx_st1_vfactive_i                 ;                                                    
    logic                                        ed_rx_st2_vfactive_i                 ;                                                    
    logic                                        ed_rx_st3_vfactive_i                 ;                                                    
    logic                                        ed_tx_st0_chnum                      ;                                                    
    logic                                        ed_tx_st1_chnum                      ;                                                    
    logic                                        ed_tx_st2_chnum                      ;                                                    
    logic                                        ed_tx_st3_chnum                      ;                                                    
    logic                 [2:0]                  ed_tx_st0_pfnum                      ;                                                    
    logic                 [2:0]                  ed_tx_st1_pfnum                      ;                                                    
    logic                 [2:0]                  ed_tx_st2_pfnum                      ;                                                    
    logic                 [2:0]                  ed_tx_st3_pfnum                      ;                                                    
    logic                 [10:0]                 ed_tx_st0_vfnum                      ;                                                    
    logic                 [10:0]                 ed_tx_st1_vfnum                      ;                                                    
    logic                 [10:0]                 ed_tx_st2_vfnum                      ;                                                    
    logic                 [10:0]                 ed_tx_st3_vfnum                      ;                                                    
    logic                                        ed_tx_st0_vfactive                   ;                                                    
    logic                                        ed_tx_st1_vfactive                   ;                                                    
    logic                                        ed_tx_st2_vfactive                   ;                                                    
    logic                                        ed_tx_st3_vfactive                   ;                                                    
    logic                                        ed_tx_st0_passthrough_o              ;                                                    
    logic                                        ed_tx_st1_passthrough_o              ;                                                    
    logic                                        ed_tx_st2_passthrough_o              ;                                                    
    logic                                        ed_tx_st3_passthrough_o              ;                                                    
    logic                 [35:0]                 hdm_size_256mb                       ; 

//CXLIP <---> iAFU
   
  // Error Correction Code (ECC)
  // Note *ecc_err_* are valid when mc2iafu_readdatavalid_eclk is active
  

  logic [cxlip_top_pkg::MC_CHANNEL-1:0]             mc2iafu_ready_eclk;
  logic [cxlip_top_pkg::MC_CHANNEL-1:0]             mc2iafu_read_poison_eclk;
  logic [cxlip_top_pkg::MC_CHANNEL-1:0]             mc2iafu_readdatavalid_eclk;
  // Error Correction Code (ECC)
  // Note *ecc_err_* are valid when mc2iafu_readdatavalid_eclk is active
  logic [cxlip_top_pkg::ALTECC_INST_NUMBER-1:0]     mc2iafu_ecc_err_corrected_eclk  [cxlip_top_pkg::MC_CHANNEL-1:0];
  logic [cxlip_top_pkg::ALTECC_INST_NUMBER-1:0]     mc2iafu_ecc_err_detected_eclk   [cxlip_top_pkg::MC_CHANNEL-1:0];
  logic [cxlip_top_pkg::ALTECC_INST_NUMBER-1:0]     mc2iafu_ecc_err_fatal_eclk      [cxlip_top_pkg::MC_CHANNEL-1:0];
  logic [cxlip_top_pkg::ALTECC_INST_NUMBER-1:0]     mc2iafu_ecc_err_syn_e_eclk      [cxlip_top_pkg::MC_CHANNEL-1:0];
  logic [cxlip_top_pkg::MC_CHANNEL-1:0]             mc2iafu_ecc_err_valid_eclk;
  logic [cxlip_top_pkg::MC_CHANNEL-1:0]             mc_rspfifo_full_eclk;
  logic [cxlip_top_pkg::MC_CHANNEL-1:0]             mc_rspfifo_empty_eclk;
  logic [cxlip_top_pkg::MC_CHANNEL-1:0]             mc2iafu_cxlmem_ready;
  logic [cxlip_top_pkg::MC_HA_DP_DATA_WIDTH-1:0]    mc2iafu_readdata_eclk           [cxlip_top_pkg::MC_CHANNEL-1:0];
  logic [cxlip_top_pkg::MC_MDATA_WIDTH-1:0]         mc2iafu_rsp_mdata_eclk          [cxlip_top_pkg::MC_CHANNEL-1:0];
  
  
  logic [cxlip_top_pkg::MC_HA_DP_DATA_WIDTH-1:0]    iafu2mc_writedata_eclk          [cxlip_top_pkg::MC_CHANNEL-1:0];
  logic [cxlip_top_pkg::MC_HA_DP_BE_WIDTH-1:0]      iafu2mc_byteenable_eclk         [cxlip_top_pkg::MC_CHANNEL-1:0];
  logic [cxlip_top_pkg::MC_CHANNEL-1:0]             iafu2mc_read_eclk;
  logic [cxlip_top_pkg::MC_CHANNEL-1:0]             iafu2mc_write_eclk;
  logic [cxlip_top_pkg::MC_CHANNEL-1:0]             iafu2mc_write_poison_eclk;
  logic [cxlip_top_pkg::MC_CHANNEL-1:0]             iafu2mc_write_ras_sbe_eclk;    
  logic [cxlip_top_pkg::MC_CHANNEL-1:0]             iafu2mc_write_ras_dbe_eclk;    
 // logic [cxlip_top_pkg::MC_HA_DP_ADDR_WIDTH-1:0]    iafu2mc_address_eclk            [cxlip_top_pkg::MC_CHANNEL-1:0];
  logic [(cxlip_top_pkg::CXLIP_FULL_ADDR_MSB):(cxlip_top_pkg::CXLIP_FULL_ADDR_LSB)]   iafu2mc_address_eclk            [cxlip_top_pkg::MC_CHANNEL-1:0];
  logic [cxlip_top_pkg::MC_MDATA_WIDTH-1:0]         iafu2mc_req_mdata_eclk          [cxlip_top_pkg::MC_CHANNEL-1:0];
  


  logic [cxlip_top_pkg::MC_SR_STAT_WIDTH-1:0]       mc_sr_status_eclk                   [cxlip_top_pkg::MC_CHANNEL-1:0];

  logic [cxlip_top_pkg::MC_CHANNEL-1:0]             iafu2cxlip_ready_eclk;
  logic [cxlip_top_pkg::MC_CHANNEL-1:0]             cxlip2iafu_read_eclk;
  logic [cxlip_top_pkg::MC_CHANNEL-1:0]             cxlip2iafu_write_eclk;
  logic [cxlip_top_pkg::MC_CHANNEL-1:0]             cxlip2iafu_write_poison_eclk;
  logic [cxlip_top_pkg::MC_CHANNEL-1:0]             cxlip2iafu_write_ras_sbe_eclk;    
  logic [cxlip_top_pkg::MC_CHANNEL-1:0]             cxlip2iafu_write_ras_dbe_eclk;    
  
  logic [(cxlip_top_pkg::CXLIP_FULL_ADDR_MSB):(cxlip_top_pkg::CXLIP_FULL_ADDR_LSB)]    cxlip2iafu_address_eclk            [cxlip_top_pkg::MC_CHANNEL-1:0];  //added from 22ww18a
  logic [cxlip_top_pkg::MC_MDATA_WIDTH-1:0]         cxlip2iafu_req_mdata_eclk           [cxlip_top_pkg::MC_CHANNEL-1:0];
  logic [cxlip_top_pkg::MC_HA_DP_DATA_WIDTH-1:0]    iafu2cxlip_readdata_eclk            [cxlip_top_pkg::MC_CHANNEL-1:0];
  logic [cxlip_top_pkg::MC_MDATA_WIDTH-1:0]         iafu2cxlip_rsp_mdata_eclk           [cxlip_top_pkg::MC_CHANNEL-1:0];
  logic [cxlip_top_pkg::MC_HA_DP_DATA_WIDTH-1:0]    cxlip2iafu_writedata_eclk           [cxlip_top_pkg::MC_CHANNEL-1:0];
  logic [cxlip_top_pkg::MC_HA_DP_BE_WIDTH-1:0]      cxlip2iafu_byteenable_eclk          [cxlip_top_pkg::MC_CHANNEL-1:0];

  logic [cxlip_top_pkg::MC_CHANNEL-1:0]             iafu2cxlip_read_poison_eclk;
  logic [cxlip_top_pkg::MC_CHANNEL-1:0]             iafu2cxlip_readdatavalid_eclk;
  // Error Correction Code (ECC)
  // Note *ecc_err_* are valid when iafu2cxlip_readdatavalid_eclk is active
  logic [cxlip_top_pkg::ALTECC_INST_NUMBER-1:0]     iafu2cxlip_ecc_err_corrected_eclk   [cxlip_top_pkg::MC_CHANNEL-1:0];
  logic [cxlip_top_pkg::ALTECC_INST_NUMBER-1:0]     iafu2cxlip_ecc_err_detected_eclk    [cxlip_top_pkg::MC_CHANNEL-1:0];
  logic [cxlip_top_pkg::ALTECC_INST_NUMBER-1:0]     iafu2cxlip_ecc_err_fatal_eclk       [cxlip_top_pkg::MC_CHANNEL-1:0];
  logic [cxlip_top_pkg::ALTECC_INST_NUMBER-1:0]     iafu2cxlip_ecc_err_syn_e_eclk       [cxlip_top_pkg::MC_CHANNEL-1:0];
  logic [cxlip_top_pkg::MC_CHANNEL-1:0]             iafu2cxlip_ecc_err_valid_eclk;
  
  logic [cxlip_top_pkg::RSPFIFO_DEPTH_WIDTH-1:0]    mc_rspfifo_fill_level_eclk  [cxlip_top_pkg::MC_CHANNEL-1:0];
    
  logic [cxlip_top_pkg::MC_CHANNEL-1:0]             mc_reqfifo_full_eclk;
  logic [cxlip_top_pkg::MC_CHANNEL-1:0]             mc_reqfifo_empty_eclk;
  logic [cxlip_top_pkg::REQFIFO_DEPTH_WIDTH-1:0]    mc_reqfifo_fill_level_eclk  [cxlip_top_pkg::MC_CHANNEL-1:0];
  
  logic [cxlip_top_pkg::MC_CHANNEL-1:0]             iafu2cxlip_cxlmem_ready;
  
  mc_ecc_pkg::mc_err_cnt_t  [cxlip_top_pkg::MC_CHANNEL-1:0]                mc_err_cnt ;


  logic [63:0]                                             mc2ip_memsize_s[cxlip_top_pkg::NUM_MC_TOP-1:0];
  logic [cxlip_top_pkg::MC_SR_STAT_WIDTH-1:0]              mc_sr_status_eclk_Q  [cxlip_top_pkg::MC_CHANNEL-1:0];
  logic                                                    mc_mem_active;
  tmp_cafu_csr0_cfg_pkg::tmp_MC_STATUS_t                   ddr_mc_status;
  tmp_cafu_csr0_cfg_pkg::tmp_new_CXL_MEM_DEV_STATUS_t      mem_dev_status ;



    logic                                        ip2hdm_reset_n_f                     ;
    logic                                        ip2hdm_reset_n_ff                    ;

    //--to/from afu                                                                                                              
    t_axi4_rd_addr_ch                            afu_axi_ar                           ;
    t_axi4_rd_addr_ready                         afu_axi_arready                      ;
    t_axi4_rd_resp_ch                            afu_axi_r                            ;
    t_axi4_rd_resp_ready                         afu_axi_rready                       ;
    t_axi4_wr_addr_ch                            afu_axi_aw                           ;
    t_axi4_wr_addr_ready                         afu_axi_awready                      ;
    t_axi4_wr_data_ch                            afu_axi_w                            ;
    t_axi4_wr_data_ready                         afu_axi_wready                       ;
    t_axi4_wr_resp_ch                            afu_axi_b                            ;
    t_axi4_wr_resp_ready                         afu_axi_bready                       ;
    //--to/from afu_cache                                                                                               
    t_axi4_rd_addr_ch                            afu_cache_axi_ar                     ;
    t_axi4_rd_addr_ready                         afu_cache_axi_arready                ;
    t_axi4_rd_resp_ch                            afu_cache_axi_r                      ;
    t_axi4_rd_resp_ready                         afu_cache_axi_rready                 ;
    t_axi4_wr_addr_ch                            afu_cache_axi_aw                     ;
    t_axi4_wr_addr_ready                         afu_cache_axi_awready                ;
    t_axi4_wr_data_ch                            afu_cache_axi_w                      ;
    t_axi4_wr_data_ready                         afu_cache_axi_wready                 ;
    t_axi4_wr_resp_ch                            afu_cache_axi_b                      ;
    t_axi4_wr_resp_ready                         afu_cache_axi_bready                 ;
    //--to/from afu_io                                                                                                  
    t_axi4_rd_addr_ch                            afu_io_axi_ar                        ;
    t_axi4_rd_addr_ready                         afu_io_axi_arready                   ;
    t_axi4_rd_resp_ch                            afu_io_axi_r                         ;
    t_axi4_rd_resp_ready                         afu_io_axi_rready                    ;
    t_axi4_wr_addr_ch                            afu_io_axi_aw                        ;
    t_axi4_wr_addr_ready                         afu_io_axi_awready                   ;
    t_axi4_wr_data_ch                            afu_io_axi_w                         ;
    t_axi4_wr_data_ready                         afu_io_axi_wready                    ;
    t_axi4_wr_resp_ch                            afu_io_axi_b                         ;
    t_axi4_wr_resp_ready                         afu_io_axi_bready                    ;
    logic                 [2:0]                  afu_axi_awsize                       ;  //AW* signals from AFU                                                  
    logic                 [1:0]                  afu_axi_awburst                      ;                                                    
    logic                 [2:0]                  afu_axi_awprot                       ;                                                    
    logic                 [3:0]                  afu_axi_awqos                        ;                                                    
    logic                 [3:0]                  afu_axi_awcache                      ;                                                    
    logic                 [1:0]                  afu_axi_awlock                       ;                                                    
    logic                 [2:0]                  afu_axi_arsize                       ;                                                    
    logic                 [1:0]                  afu_axi_arburst                      ;                                                    
    logic                 [2:0]                  afu_axi_arprot                       ;                                                    
    logic                 [3:0]                  afu_axi_arqos                        ;                                                    
    logic                 [3:0]                  afu_axi_arcache                      ;                                                    
    logic                 [1:0]                  afu_axi_arlock                       ;                                                    
    logic                                        cafu_user_enabled_cxl_io             ;  //Asserts 1 when user configured AFU to IO mode
    logic                 [2:0]                  ed_rx_bar                            ;  //AVST4to1 outputs                                                  
    logic                                        ed_rx_eop[1-1:0]                     ;                                                    
    logic                                        ed_rx_eop_i                          ;                                                    
    logic                 [127:0]                ed_rx_header[1-1:0]                  ;                                                    
    logic                 [511:0]                ed_rx_payload[1-1:0]                 ;                                                    
     logic [31:0]    ed_rx_prefix [0:0] ;
     logic	     ed_rx_prefix_valid[0:0] ;
    logic                                        ed_rx_sop[1-1:0]                     ;                                                    
    logic                                        ed_rx_sop_i                          ;                                                    
    logic                                        ed_rx_hvalid                         ;                                                    
    logic                                        ed_rx_valid                          ;                                                    
    logic                                        ed_rx_dvalid[1-1:0]                  ;                                                    
    logic                                        ed_rx_passthrough[1-1:0]             ;                                                    
    logic                                        ed_rx_ready                          ;                                                    
    logic                                        afu_pio_select                       ;  //if  afu_pio_select==1  then  select  afu  else  pio
    logic                                        afu_cache_io_select                  ;                                                    
    logic                 [2:0]                  pio_rx_bar                           ;  //PIO inputs                                                  
    logic                                        pio_rx_eop                           ;                                                    
    logic                                        pio_rx_valid                         ;                                                    
    logic                 [127:0]                pio_rx_header                        ;                                                    
    logic                 [255:0]                pio_rx_payload                       ;                                                    
    logic                                        pio_rx_sop                           ;                                                    
    logic                                        pio_to_send_cpl                      ;                                                    
    logic                                        pio_rx_hvalid                        ;                                                    
    logic                                        pio_rx_dvalid                        ;                                                    
     logic           pio_rx_pvalid	    ;   
     logic [31:0]    pio_rx_prefix ;
     logic [2:0]     aer_chk_rx_bar         ;      
     logic 	     aer_chk_rx_eop 	    ;      
     logic 	     aer_chk_rx_valid 	    ;      
     logic [127:0]   aer_chk_rx_header	    ;   
     logic [255:0]   aer_chk_rx_payload	    ;  
     logic  	     aer_chk_rx_sop	        ;      
     logic 	     aer_chk_rx_hvalid	    ;   
     logic           aer_chk_rx_dvalid	    ;   
     logic           aer_chk_rx_pvalid	    ;   
     logic [31:0]    aer_chk_rx_prefix ;
    logic                                        pio_rx_passthrough                   ;                                                    
    logic                                        pio_rx_ready                         ;                                                    
    logic                                        pio_txc_ready                        ;                                                    
    logic                                        pio_txc_eop                          ; //PIO outputs                                                   
    logic                                        pio_txc_sop                          ;                                                    
    logic                 [127:0]                pio_txc_header                       ;                                                    
    logic                 [255:0]                pio_txc_payload                      ;                                                    
    logic                                        pio_txc_valid                        ;                                                    
    logic                                        pio_tx_st_ready_i                    ;                                                    
    logic 	                                 np_ca_rx_sop                         ; //CA output from AER
    logic 	                                 np_ca_rx_eop                         ;
    logic 	                                 np_ca_rx_hvalid                      ;
    logic 	                                 np_ca_rx_dvalid                      ;
    logic 	          [127:0]                np_ca_rx_header                      ;
    logic 	          [255:0]                np_ca_rx_data                        ;
    logic                 [2:0]                  default_config_rx_bar                ; //Default config inputs                                                   
    logic                                        default_config_rx_eop                ;                                                    
    logic                 [127:0]                default_config_rx_header             ;                                                    
    logic                 [255:0]                default_config_rx_payload            ;                                                    
    logic                                        default_config_rx_sop                ;                                                    
    logic                                        default_config_rx_hvalid             ;                                                    
    logic                                        default_config_rx_valid              ;                                                    
    logic                                        default_config_rx_dvalid             ;                                                    
    logic                                        default_config_rx_passthrough        ;                                                    
    logic                                        default_config_rx_ready              ;                                                    
    logic                 [127:0]                default_config_tx_st_header_update   ; //Default config outputs                                                   
    logic                 [127:0]                default_config_txc_header            ;                                                    
    logic                                        default_config_txc_eop               ;                                                    
    logic                 [255:0]                default_config_txc_payload           ;                                                    
    logic                                        default_config_txc_sop               ;                                                    
    logic                                        default_config_txc_valid             ;                                                    
    logic                                        dc_bam_rx_signal_ready_o             ;                                                    
    logic                                        dc_tx_hdr_valid_o                    ;                                                    
    logic                                        dc_tx_hdr_valid                      ;                                                    
    logic                                        default_config_tx_st0_passthrough_i  ;                                                    
    logic                                        default_config_tx_st1_passthrough_i  ;                                                    
    logic                                        default_config_tx_st2_passthrough_i  ;                                                    
    logic                                        default_config_tx_st3_passthrough_i  ;                                                    
    logic                 [2:0]                  afu_rx_bar                           ; //Inputs to axi_avst bridge                                                   
    logic                                        afu_rx_eop                           ;                                                    
    logic                 [127:0]                afu_rx_hdr                           ;                                                    
    logic                 [511:0]                afu_rx_data                          ;                                                    
    logic                                        afu_rx_sop                           ;                                                    
    logic                                        afu_rx_hvalid                        ;                                                    
    logic                                        afu_rx_dvalid                        ;                                                    
    logic                                        afu_rx_passthrough                   ;                                                    
    logic                                        afu_rx_ready                         ;                                                    
    logic                                        afu_tx_st0_dvalid_o                  ; //Outputs from axi_avst bridge                                              
    logic                                        afu_tx_st0_sop_o                     ;                                                    
    logic                                        afu_tx_st0_eop_o                     ;                                                    
    logic                 [511:0]                afu_tx_st0_data_o                    ;                                                    
    logic                 [127:0]                afu_tx_st0_hdr_o                     ;                                                    
    logic                                        afu_tx_st0_hvalid_o                  ;                                                    
    logic                                        afu_tx_st1_dvalid_o                  ;                                                    
    logic                                        afu_tx_st1_sop_o                     ;                                                    
    logic                                        afu_tx_st1_eop_o                     ;                                                    
    logic                 [255:0]                afu_tx_st1_data_o                    ;                                                    
    logic                 [127:0]                afu_tx_st1_hdr_o                     ;                                                    
    logic                                        afu_tx_st1_hvalid_o                  ;                                                    
    logic                                        afu_tx_st2_dvalid_o                  ;                                                    
    logic                                        afu_tx_st2_sop_o                     ;                                                    
    logic                                        afu_tx_st2_eop_o                     ;                                                    
    logic                 [255:0]                afu_tx_st2_data_o                    ;                                                    
    logic                 [127:0]                afu_tx_st2_hdr_o                     ;                                                    
    logic                                        afu_tx_st2_hvalid_o                  ;                                                    
    logic                                        wr_last                              ;
    logic                 [15:0]                 tx_p_data_counter                    ; //Credit counters for Tx side                                               
    logic                 [15:0]                 tx_np_data_counter                   ; //Credit counters for Tx side                                           
    logic                 [15:0]                 tx_cpl_data_counter                  ; //Credit counters for Tx side                                       
    logic                 [12:0]                 tx_p_header_counter                  ; //Credit counters for Tx side                                       
    logic                 [12:0]                 tx_np_header_counter                 ; //Credit counters for Tx side                       
    logic                 [12:0]                 tx_cpl_header_counter                ; //Credit counters for Tx side   
    logic                                        wr_tlp_fifo_empty                    ;                                                    
    logic                 [9:0]                  p_tlp_sent_tag                       ; //For Bresp of AFU.io
    logic                                        p_tlp_sent_tag_valid                 ;
    logic                 [127:0]                ed_rx_st0_header_update              ; //Reorder header                                                   
    logic                 [127:0]                ed_rx_st1_header_update              ; //Reorder header                                                   
    logic                 [127:0]                ed_rx_st2_header_update              ; //Reorder header                                                   
    logic                 [127:0]                ed_rx_st3_header_update              ; //Reorder header                                                   
    logic                                        avst4to1_rx_data_avail[1-1:0]        ;                                                    
    logic                                        avst4to1_rx_hdr_avail[1-1:0]         ;                                                    
    logic                                        avst4to1_rx_nph_hdr_avail[1-1:0]     ;                                                    
    logic                                        avst4to1_np_hdr_crd_pop              ; //Return credit for NP                                                   
    logic                 [15:0]                 ed_rx_dw_valid[1-1:0]                ;                                                    
    logic                 [127:0]                ed_rx_header_update                  ; //Reorder header from AVST4to1                                                   
    logic                                        Mem_Wr_tlp                           ; //Detect if TLP is Mem_Wr                                                   
    logic                                        Msg_tlp                              ; //Detect if TLP is Msg                                                   
    logic                                        MsgD_tlp                             ; //Detect if TLP is Msg_D                                                    
    logic                                        Cpl_tlp                              ; //Detect if TLP is Cpl                                                    
    logic                                        CplD_tlp                             ; //Detect if TLP is CplD                                                    
    logic                                        p_or_cpl_tlp                         ; //Detect if TLP is posted or completion                                                    
    logic                 [9:0]                  tx_hdr                               ; //Length of header                                                   
    logic                                        tx_hdr_valid                         ; //Valid for header length                                                   
    logic                 [7:0]                  tx_hdr_type                          ; //Type of TLP                                                   
    logic                 [127:0]                pio_txc_header_update                ; //Reorder header from PIO                                                   
    logic                 [9:0]                  dc_hdr_len_o                         ; //Default Config output signals                                                    
    logic                                        dc_hdr_valid_o                       ;                                                    
    logic                                        dc_hdr_is_rd_o                       ;                                                    
    logic                                        dc_hdr_is_rd_with_data_o             ;                                                    
    logic                                        dc_hdr_is_wr_o                       ;                                                    
    avst4to1_if                                  p0_pld_if()                          ;                                                                                         

  mc_axi_if_pkg::t_to_mc_axi4   [cxlip_top_pkg::MC_CHANNEL-1:0] cxlip2iafu_to_mc_axi4; //cxlip2iafu_to_mc_axi4;
  mc_axi_if_pkg::t_to_mc_axi4   [cxlip_top_pkg::MC_CHANNEL-1:0] iafu2mc_to_mc_axi4; //cxlip2iafu_to_mc_axi4;
  mc_axi_if_pkg::t_from_mc_axi4 [cxlip_top_pkg::MC_CHANNEL-1:0] mc2iafu_from_mc_axi4; //iafu2cxlip_from_mc_axi4;
  mc_axi_if_pkg::t_from_mc_axi4 [cxlip_top_pkg::MC_CHANNEL-1:0] iafu2cxlip_from_mc_axi4; //iafu2cxlip_from_mc_axi4;

  logic csr_zero_out;
  logic csr_write_back;
  logic is_writing_back;
  logic [63:0] write_back_addr;
  logic [31:0] csr_write_back_cnt;
  logic [MONITOR_REGION_WIDTH-1:0] csr_monitor_region;
  logic [63:0] csr_ofw_buf_tail_max;

   // MODIFIED by Vinit
  logic [5:0]  csr_awuser;
	logic [63:0] csr_ofw_buf_head;
  logic [63:0] csr_ofw_buf_vld_cnt;


//-------------------------------------------------------
// Assignments                                  --
//-------------------------------------------------------
//=====================================================
 logic             cxl_reset ;
 logic             cxl_reset_n;
 logic             usr2ip_cxlreset_ack_d1;
 logic             cxl_or_conv_rst_n;


//Adding logic for cxl_reset and generate conventional_or_CXL reset
// This is logic detects the negedge event usr2ip_cxlreset_ack , and make it
// active low
 always @(posedge ip2hdm_clk) begin
  if(!ip2hdm_reset_n) begin
     usr2ip_cxlreset_ack_d1 <= 1'b0 ;
  end 
  else begin
     usr2ip_cxlreset_ack_d1 <= usr2ip_cxlreset_ack ;
  end      
end 

assign cxl_reset = usr2ip_cxlreset_ack_d1 && ~usr2ip_cxlreset_ack ;
assign cxl_reset_n = !cxl_reset ;
//cxl or conventional reset is generated by using 2 active low events and
//anding it 
assign cxl_or_conv_rst_n  = cxl_reset_n && ip2hdm_reset_n ; 
//=======================================================

//chip ID (device serial number) will be exported to Example design as an input and user can drive this signal based on avmm clk 
assign  dev_serial_num                           =  64'd0                                        ;
assign  dev_serial_num_valid                     =  1'b1                                         ;

assign  usr2ip_debug_writedata                   = '0                                            ;   
assign  usr2ip_debug_address                     = '0                                            ;   
assign  usr2ip_debug_write                       = '0                                            ;
assign  usr2ip_debug_read                        = '0                                            ;
assign  usr2ip_debug_byteenable                  = '0                                            ;

assign  afu_axi_aw.awsize                        =  t_axi4_burst_size_encoding'(afu_axi_awsize)  ;
assign  afu_axi_aw.awburst                       =  t_axi4_burst_encoding'(afu_axi_awburst)      ;
assign  afu_axi_aw.awprot                        =  t_axi4_prot_encoding'(afu_axi_awprot)        ;
assign  afu_axi_aw.awqos                         =  t_axi4_qos_encoding'(afu_axi_awqos)          ;
assign  afu_axi_aw.awcache                       =  t_axi4_awcache_encoding'(afu_axi_awcache)    ;
assign  afu_axi_aw.awlock                        =  t_axi4_lock_encoding'(afu_axi_awlock)        ;
assign  afu_axi_ar.arsize                        =  t_axi4_burst_size_encoding'(afu_axi_arsize)  ;
assign  afu_axi_ar.arburst                       =  t_axi4_burst_encoding'(afu_axi_arburst)      ;
assign  afu_axi_ar.arprot                        =  t_axi4_prot_encoding'(afu_axi_arprot)        ;
assign  afu_axi_ar.arqos                         =  t_axi4_qos_encoding'(afu_axi_arqos)          ;
assign  afu_axi_ar.arcache                       =  t_axi4_arcache_encoding'(afu_axi_arcache)    ;
assign  afu_axi_ar.arlock                        =  t_axi4_lock_encoding'(afu_axi_arlock)        ;

assign  cafu2ip_quiesce_ack                      =  ip2cafu_quiesce_req_ff                       ; 

assign  afu_cache_io_select                      =  cafu_user_enabled_cxl_io                     ;
assign  afu_pio_select                           =  afu_cache_io_select                          ;
     
assign  avst4to1_rx_data_avail[0]                =  1'b1                                         ;
assign  avst4to1_rx_hdr_avail[0]                 =  1'b1                                         ;
assign  avst4to1_rx_nph_hdr_avail[0]             =  1'b1                                         ;
assign  p0_pld_if.rx_st_sop_s0_o                 =  ed_rx_st0_sop_i                              ;
assign  p0_pld_if.rx_st_sop_s1_o                 =  ed_rx_st1_sop_i                              ;
assign  p0_pld_if.rx_st_sop_s2_o                 =  ed_rx_st2_sop_i                              ;
assign  p0_pld_if.rx_st_sop_s3_o                 =  ed_rx_st3_sop_i                              ;
assign  p0_pld_if.rx_st_eop_s0_o                 =  ed_rx_st0_eop_i                              ;
assign  p0_pld_if.rx_st_eop_s1_o                 =  ed_rx_st1_eop_i                              ;
assign  p0_pld_if.rx_st_eop_s2_o                 =  ed_rx_st2_eop_i                              ;
assign  p0_pld_if.rx_st_eop_s3_o                 =  ed_rx_st3_eop_i                              ;
assign  p0_pld_if.rx_st_empty_s0_o               =  ed_rx_st0_empty_i                            ;
assign  p0_pld_if.rx_st_empty_s1_o               =  ed_rx_st1_empty_i                            ;
assign  p0_pld_if.rx_st_empty_s2_o               =  ed_rx_st2_empty_i                            ;
assign  p0_pld_if.rx_st_empty_s3_o               =  ed_rx_st3_empty_i                            ;
assign  p0_pld_if.rx_st_data_s0_o                =  ed_rx_st0_payload_i                          ;
assign  p0_pld_if.rx_st_data_s1_o                =  ed_rx_st1_payload_i                          ;
assign  p0_pld_if.rx_st_data_s2_o                =  ed_rx_st2_payload_i                          ;
assign  p0_pld_if.rx_st_data_s3_o                =  ed_rx_st3_payload_i                          ;
assign  p0_pld_if.rx_st_data_par_s0_o            =  ed_rx_st0_data_parity_i                      ;
assign  p0_pld_if.rx_st_data_par_s1_o            =  ed_rx_st1_data_parity_i                      ;
assign  p0_pld_if.rx_st_data_par_s2_o            =  ed_rx_st2_data_parity_i                      ;
assign  p0_pld_if.rx_st_data_par_s3_o            =  ed_rx_st3_data_parity_i                      ;
assign  p0_pld_if.rx_st_dvalid_s0_o              =  ed_rx_st0_dvalid_i                           ;
assign  p0_pld_if.rx_st_dvalid_s1_o              =  ed_rx_st1_dvalid_i                           ;
assign  p0_pld_if.rx_st_dvalid_s2_o              =  ed_rx_st2_dvalid_i                           ;
assign  p0_pld_if.rx_st_dvalid_s3_o              =  ed_rx_st3_dvalid_i                           ;
assign  p0_pld_if.rx_st_hdr_s0_o                 =  ed_rx_st0_header_i                           ;
assign  p0_pld_if.rx_st_hdr_s1_o                 =  ed_rx_st1_header_i                           ;
assign  p0_pld_if.rx_st_hdr_s2_o                 =  ed_rx_st2_header_i                           ;
assign  p0_pld_if.rx_st_hdr_s3_o                 =  ed_rx_st3_header_i                           ;
assign  p0_pld_if.rx_st_hdr_par_s0_o             =  ed_rx_st0_hdr_parity_i                       ;
assign  p0_pld_if.rx_st_hdr_par_s1_o             =  ed_rx_st1_hdr_parity_i                       ;
assign  p0_pld_if.rx_st_hdr_par_s2_o             =  ed_rx_st2_hdr_parity_i                       ;
assign  p0_pld_if.rx_st_hdr_par_s3_o             =  ed_rx_st3_hdr_parity_i                       ;
assign  p0_pld_if.rx_st_hvalid_s0_o              =  ed_rx_st0_hvalid_i                           ;
assign  p0_pld_if.rx_st_hvalid_s1_o              =  ed_rx_st1_hvalid_i                           ;
assign  p0_pld_if.rx_st_hvalid_s2_o              =  ed_rx_st2_hvalid_i                           ;
assign  p0_pld_if.rx_st_hvalid_s3_o              =  ed_rx_st3_hvalid_i                           ;
assign  p0_pld_if.rx_st_tlp_prfx_s0_o            =  ed_rx_st0_tlp_prfx_i                         ;
assign  p0_pld_if.rx_st_tlp_prfx_s1_o            =  ed_rx_st1_tlp_prfx_i                         ;
assign  p0_pld_if.rx_st_tlp_prfx_s2_o            =  ed_rx_st2_tlp_prfx_i                         ;
assign  p0_pld_if.rx_st_tlp_prfx_s3_o            =  ed_rx_st3_tlp_prfx_i                         ;
assign  p0_pld_if.rx_st_tlp_prfx_par_s0_o        =  '0                                           ;
assign  p0_pld_if.rx_st_tlp_prfx_par_s1_o        =  '0                                           ;
assign  p0_pld_if.rx_st_tlp_prfx_par_s2_o        =  '0                                           ;
assign  p0_pld_if.rx_st_tlp_prfx_par_s3_o        =  '0                                           ;
assign  p0_pld_if.rx_st_pvalid_s0_o              =  ed_rx_st0_pvalid_i                           ;
assign  p0_pld_if.rx_st_pvalid_s1_o              =  ed_rx_st1_pvalid_i                           ;
assign  p0_pld_if.rx_st_pvalid_s2_o              =  ed_rx_st2_pvalid_i                           ;
assign  p0_pld_if.rx_st_pvalid_s3_o              =  ed_rx_st3_pvalid_i                           ;
assign  p0_pld_if.rx_st_bar_s0_o                 =  ed_rx_st0_bar_i                              ;
assign  p0_pld_if.rx_st_bar_s1_o                 =  ed_rx_st1_bar_i                              ;
assign  p0_pld_if.rx_st_bar_s2_o                 =  ed_rx_st2_bar_i                              ;
assign  p0_pld_if.rx_st_bar_s3_o                 =  ed_rx_st3_bar_i                              ;
assign  p0_pld_if.rx_st_passthrough_s0_o         =  ed_rx_st0_passthrough_i                      ;
assign  p0_pld_if.rx_st_passthrough_s1_o         =  ed_rx_st1_passthrough_i                      ;
assign  p0_pld_if.rx_st_passthrough_s2_o         =  ed_rx_st2_passthrough_i                      ;
assign  p0_pld_if.rx_st_passthrough_s3_o         =  ed_rx_st3_passthrough_i                      ;
assign  p0_pld_if.rx_st_tlp_RSSAI_prfx_s0_o      =  '0                                           ;
assign  p0_pld_if.rx_st_tlp_RSSAI_prfx_s1_o      =  '0                                           ;
assign  p0_pld_if.rx_st_tlp_RSSAI_prfx_s2_o      =  '0                                           ;
assign  p0_pld_if.rx_st_tlp_RSSAI_prfx_s3_o      =  '0                                           ;
assign  p0_pld_if.rx_st_tlp_RSSAI_prfx_par_s0_o  =  '0                                           ;
assign  p0_pld_if.rx_st_tlp_RSSAI_prfx_par_s1_o  =  '0                                           ;
assign  p0_pld_if.rx_st_tlp_RSSAI_prfx_par_s2_o  =  '0                                           ;
assign  p0_pld_if.rx_st_tlp_RSSAI_prfx_par_s3_o  =  '0                                           ;
assign  p0_pld_if.rx_st_vfactive_s0_o            =  '0                                           ;
assign  p0_pld_if.rx_st_vfactive_s1_o            =  '0                                           ;
assign  p0_pld_if.rx_st_vfactive_s2_o            =  '0                                           ;
assign  p0_pld_if.rx_st_vfactive_s3_o            =  '0                                           ;
assign  p0_pld_if.rx_st_vfnum_s0_o               =  '0                                           ;
assign  p0_pld_if.rx_st_vfnum_s1_o               =  '0                                           ;
assign  p0_pld_if.rx_st_vfnum_s2_o               =  '0                                           ;
assign  p0_pld_if.rx_st_vfnum_s3_o               =  '0                                           ;
assign  p0_pld_if.rx_st_pfnum_s0_o               =  '0                                           ;
assign  p0_pld_if.rx_st_pfnum_s1_o               =  '0                                           ;
assign  p0_pld_if.rx_st_pfnum_s2_o               =  '0                                           ;
assign  p0_pld_if.rx_st_pfnum_s3_o               =  '0                                           ;
assign  p0_pld_if.rx_Hcrdt_init_ack              =  rx_st_hcrdt_init_ack_i                       ;
assign  p0_pld_if.rx_Dcrdt_init_ack              =  rx_st_dcrdt_init_ack_i                       ;
assign  rx_st_hcrdt_update_cnt_o                 =  p0_pld_if.rx_Hcrdt_update_cnt                ;
assign  rx_st_hcrdt_update_o                     =  p0_pld_if.rx_Hcrdt_update                    ;
assign  rx_st_hcrdt_init_o                       =  p0_pld_if.rx_Hcrdt_init                      ;
assign  rx_st_dcrdt_update_cnt_o                 =  p0_pld_if.rx_Dcrdt_update_cnt                ;
assign  rx_st_dcrdt_update_o                     =  p0_pld_if.rx_Dcrdt_update                    ;
assign  rx_st_dcrdt_init_o                       =  p0_pld_if.rx_Dcrdt_init                      ;
    
// AXI-MM interface - write address channel
assign  axi0_awid                                =  afu_cache_axi_aw.awid                        ;
assign  axi0_awaddr                              =  afu_cache_axi_aw.awaddr                      ;
assign  axi0_awlen                               =  afu_cache_axi_aw.awlen                       ;
assign  axi0_awsize                              =  afu_cache_axi_aw.awsize                      ;
assign  axi0_awburst                             =  afu_cache_axi_aw.awburst                     ;
assign  axi0_awprot                              =  afu_cache_axi_aw.awprot                      ;
assign  axi0_awqos                               =  afu_cache_axi_aw.awqos                       ;
assign  axi0_awuser                              =  afu_cache_axi_aw.awuser                      ;
assign  axi0_awvalid                             =  afu_cache_axi_aw.awvalid                     ;
assign  axi0_awcache                             =  afu_cache_axi_aw.awcache                     ;
assign  axi0_awlock                              =  afu_cache_axi_aw.awlock                      ;
assign  axi0_awregion                            =  afu_cache_axi_aw.awregion                    ;
assign  axi0_awatop                              =  6'b000000                                    ;
assign  afu_cache_axi_awready                    =  axi0_awready                                 ;
  
//      AXI-MM_interface_write_data_channel                                                      
assign  axi0_wdata                               =  afu_cache_axi_w.wdata                        ;
assign  axi0_wstrb                               =  afu_cache_axi_w.wstrb                        ;
assign  axi0_wlast                               =  afu_cache_axi_w.wlast                        ;
assign  axi0_wuser                               =  afu_cache_axi_w.wuser                        ;
assign  axi0_wvalid                              =  afu_cache_axi_w.wvalid                       ;
assign  afu_cache_axi_wready                     =  axi0_wready                                  ;

//  AXI-MM interface - write response channel
assign  afu_cache_axi_b.bid                      =  axi0_bid                                     ;
assign  afu_cache_axi_b.bresp                    =  axi0_bresp == 'h0 ? eresp_OKAY : eresp_SLVERR;    
assign  afu_cache_axi_b.buser                    =  axi0_buser                                   ;
assign  afu_cache_axi_b.bvalid                   =  axi0_bvalid                                  ;
assign  axi0_bready                              =  afu_cache_axi_bready                         ;
  
//      AXI-MM_interface_read_address_channel                                                    
assign  axi0_arid                                =  afu_cache_axi_ar.arid                        ;
assign  axi0_araddr                              =  afu_cache_axi_ar.araddr                      ;
assign  axi0_arlen                               =  afu_cache_axi_ar.arlen                       ;
assign  axi0_arsize                              =  afu_cache_axi_ar.arsize                      ;
assign  axi0_arburst                             =  afu_cache_axi_ar.arburst                     ;
assign  axi0_arprot                              =  afu_cache_axi_ar.arprot                      ;
assign  axi0_arqos                               =  afu_cache_axi_ar.arqos                       ;
assign  axi0_aruser                              =  afu_cache_axi_ar.aruser                      ;
assign  axi0_arvalid                             =  afu_cache_axi_ar.arvalid                     ;
assign  axi0_arcache                             =  afu_cache_axi_ar.arcache                     ;
assign  axi0_arlock                              =  afu_cache_axi_ar.arlock                      ;
assign  axi0_arregion                            =  afu_cache_axi_ar.arregion                    ;
assign  afu_cache_axi_arready                    =  axi0_arready                                 ;

//      AXI-MM_interface_read_response_channel                                                   
assign  afu_cache_axi_r.rid                      =  axi0_rid                                     ;
assign  afu_cache_axi_r.rdata                    =  axi0_rdata                                   ;
assign  afu_cache_axi_r.rresp                    =  axi0_rresp == 'h0 ? eresp_OKAY : eresp_SLVERR;  
assign  afu_cache_axi_r.rlast                    =  axi0_rlast                                   ;
assign  afu_cache_axi_r.ruser                    =  axi0_ruser                                   ;
assign  afu_cache_axi_r.rvalid                   =  axi0_rvalid                                  ;
assign  axi0_rready                              =  afu_cache_axi_rready                         ;

assign  ed_rx_st0_chnum_i                        =  '0                                           ;
assign  ed_rx_st1_chnum_i                        =  '0                                           ;
assign  ed_rx_st2_chnum_i                        =  '0                                           ;
assign  ed_rx_st3_chnum_i                        =  '0                                           ;
assign  ed_rx_st0_vfnum_i                        =  '0                                           ;
assign  ed_rx_st1_vfnum_i                        =  '0                                           ;
assign  ed_rx_st2_vfnum_i                        =  '0                                           ;
assign  ed_rx_st3_vfnum_i                        =  '0                                           ;
assign  ed_rx_st0_vfactive_i                     =  '0                                           ;
assign  ed_rx_st1_vfactive_i                     =  '0                                           ;
assign  ed_rx_st2_vfactive_i                     =  '0                                           ;
assign  ed_rx_st3_vfactive_i                     =  '0                                           ;
assign  ed_rx_hvalid                             =  ed_rx_sop[0] & (|ed_rx_header[0])            ;                                                                
assign  ed_rx_sop_i                              =  ed_rx_sop[0]                                 ;
assign  ed_rx_eop_i                              =  ed_rx_eop[0]                                 ;
assign  pio_txc_header_update                    =  {pio_txc_header[31:0],pio_txc_header[63:32],pio_txc_header[95:64],pio_txc_header[127:96]} ;
assign  tx_hdr                                   =  ed_tx_st0_hvalid_o ? ed_tx_st0_header_o[105:96] : 10'h0                                   ;                          
assign  tx_hdr_valid                             =  ed_tx_st0_hvalid_o                                                                        ;
assign  tx_hdr_type                              =  ed_tx_st0_hvalid_o ? ed_tx_st0_header_o[127:120] : 8'h0                                   ;                          
assign  ed_rx_st0_header_update                  =  {ed_rx_st0_header_i[31:0],ed_rx_st0_header_i[63:32],ed_rx_st0_header_i[95:64],ed_rx_st0_header_i[127:96]}  ;
assign  ed_rx_st1_header_update                  =  {ed_rx_st1_header_i[31:0],ed_rx_st1_header_i[63:32],ed_rx_st1_header_i[95:64],ed_rx_st1_header_i[127:96]}  ;
assign  ed_rx_st2_header_update                  =  {ed_rx_st2_header_i[31:0],ed_rx_st2_header_i[63:32],ed_rx_st2_header_i[95:64],ed_rx_st2_header_i[127:96]}  ;
assign  ed_rx_st3_header_update                  =  {ed_rx_st3_header_i[31:0],ed_rx_st3_header_i[63:32],ed_rx_st3_header_i[95:64],ed_rx_st3_header_i[127:96]}  ;
assign  ed_rx_valid                              =  |ed_rx_dw_valid[0]                           ;
assign  Mem_Wr_tlp                               =  (ed_rx_header_update[31:29]==3'b010 || ed_rx_header_update[31:29]==3'b011) && (ed_rx_header_update[28:24]==5'h0);                 
assign  Msg_tlp                                  =  (ed_rx_header_update[31:29]==3'b001) && (ed_rx_header_update[28:27]==2'b10);                
assign  MsgD_tlp                                 =  (ed_rx_header_update[31:29]==3'b011) && (ed_rx_header_update[28:27]==2'b10);                
assign  CplD_tlp                                 =  (ed_rx_header_update[31:24]==8'h4A)          ;                                                                
assign  Cpl_tlp                                  =  (ed_rx_header_update[31:24]==8'hA)           ;                                                                
assign  p_or_cpl_tlp                             =  Mem_Wr_tlp || Msg_tlp || MsgD_tlp ||  CplD_tlp  ||  Cpl_tlp  ;
assign  {default_config_tx_st_header_update[31:0],default_config_tx_st_header_update[63:32],default_config_tx_st_header_update[95:64],default_config_tx_st_header_update[127:96]} =  default_config_txc_header ;                              	
assign  ed_rx_header_update                      = {ed_rx_header[0][103:96], ed_rx_header[0][111:104],ed_rx_header[0][119:112], ed_rx_header[0][127:120],  
                                                    ed_rx_header[0][71:64],  ed_rx_header[0][79:72],   ed_rx_header[0][87:80],   ed_rx_header[0][95:88],   
                                                    ed_rx_header[0][39:32],  ed_rx_header[0][47:40],   ed_rx_header[0][55:48],   ed_rx_header[0][63:56],   
                                                    ed_rx_header[0][7:0],    ed_rx_header[0][15:8],    ed_rx_header[0][23:16],   ed_rx_header[0][31:24] };   

  assign   u2ip_0_qos_devload = 2'b01;

  assign   cafu2ip_axistd0_tready = 1'b1;
  assign   cafu2ip_axisth0_tready = 1'b1;

//HDM SIZE
// Total amount of HDM expressed as a multiple of 256MB.
// This is a CXL-IP input and is used to advertise HDM size via CXL-IP DVSEC registers.
//
// HDM Size  hdm_size_256mb
// --------  --------------
//  256MB       36'h001
//  512MB       36'h002
//    1GB       36'h004
//    2GB       36'h008
//    4GB       36'h010
//    8GB       36'h020
//   16GB       36'h040
//   32GB       36'h080
//   64GB       36'h100
//  128GB       36'h200
//  256GB       36'h400
//  512GB       36'h800
//  (etc.)      (etc.)


`ifdef HDM_64G
      assign hdm_size_256mb = 36'h80; // HDM_32G
`else
      assign hdm_size_256mb = 36'h20; // HDM_8G
`endif


 assign   mc2ip_0_sr_status                    =  mc_sr_status_eclk[0]                   ;


//Channel-0
 assign cxlip2iafu_to_mc_axi4[0].awid     = ip2hdm_aximm0_awid ;
 assign cxlip2iafu_to_mc_axi4[0].awaddr   = ip2hdm_aximm0_awaddr ;
 assign cxlip2iafu_to_mc_axi4[0].awlen    = ip2hdm_aximm0_awlen ;
 assign cxlip2iafu_to_mc_axi4[0].awregion = ip2hdm_aximm0_awregion ;
 assign cxlip2iafu_to_mc_axi4[0].awuser   = ip2hdm_aximm0_awuser ;
 assign cxlip2iafu_to_mc_axi4[0].awsize   = afu_axi_if_pkg::t_axi4_burst_size_encoding'( ip2hdm_aximm0_awsize  );
 assign cxlip2iafu_to_mc_axi4[0].awburst  = afu_axi_if_pkg::t_axi4_burst_encoding'( ip2hdm_aximm0_awburst );
 assign cxlip2iafu_to_mc_axi4[0].awprot   = afu_axi_if_pkg::t_axi4_prot_encoding'( ip2hdm_aximm0_awprot  );
 assign cxlip2iafu_to_mc_axi4[0].awqos    = afu_axi_if_pkg::t_axi4_qos_encoding'( ip2hdm_aximm0_awqos   );
 assign cxlip2iafu_to_mc_axi4[0].awcache  = afu_axi_if_pkg::t_axi4_awcache_encoding'( ip2hdm_aximm0_awcache );
 assign cxlip2iafu_to_mc_axi4[0].awlock   = afu_axi_if_pkg::t_axi4_lock_encoding'( ip2hdm_aximm0_awlock  );
 assign cxlip2iafu_to_mc_axi4[0].awvalid  = ip2hdm_aximm0_awvalid;
 assign cxlip2iafu_to_mc_axi4[0].wdata    = ip2hdm_aximm0_wdata ;
 assign cxlip2iafu_to_mc_axi4[0].wstrb    = ip2hdm_aximm0_wstrb ;
 assign cxlip2iafu_to_mc_axi4[0].wlast    = ip2hdm_aximm0_wlast ;
 assign cxlip2iafu_to_mc_axi4[0].wuser    = ip2hdm_aximm0_wuser ;
 assign cxlip2iafu_to_mc_axi4[0].wvalid   = ip2hdm_aximm0_wvalid;
 assign cxlip2iafu_to_mc_axi4[0].bready   = ip2hdm_aximm0_bready ;
 assign cxlip2iafu_to_mc_axi4[0].arid     = ip2hdm_aximm0_arid ;
 assign cxlip2iafu_to_mc_axi4[0].araddr   = ip2hdm_aximm0_araddr ;
 assign cxlip2iafu_to_mc_axi4[0].arlen    = ip2hdm_aximm0_arlen ;
 assign cxlip2iafu_to_mc_axi4[0].arregion = ip2hdm_aximm0_arregion ;
 assign cxlip2iafu_to_mc_axi4[0].aruser   = ip2hdm_aximm0_aruser ;
 assign cxlip2iafu_to_mc_axi4[0].arsize   = afu_axi_if_pkg::t_axi4_burst_size_encoding'( ip2hdm_aximm0_arsize);
 assign cxlip2iafu_to_mc_axi4[0].arburst  = afu_axi_if_pkg::t_axi4_burst_encoding'( ip2hdm_aximm0_arburst );
 assign cxlip2iafu_to_mc_axi4[0].arprot   = afu_axi_if_pkg::t_axi4_prot_encoding'( ip2hdm_aximm0_arprot  );
 assign cxlip2iafu_to_mc_axi4[0].arqos    = afu_axi_if_pkg::t_axi4_qos_encoding'( ip2hdm_aximm0_arqos  );
 assign cxlip2iafu_to_mc_axi4[0].arcache  = afu_axi_if_pkg::t_axi4_arcache_encoding'( ip2hdm_aximm0_arcache );
 assign cxlip2iafu_to_mc_axi4[0].arlock   = afu_axi_if_pkg::t_axi4_lock_encoding'( ip2hdm_aximm0_arlock );
 assign cxlip2iafu_to_mc_axi4[0].arvalid  = ip2hdm_aximm0_arvalid;
 assign cxlip2iafu_to_mc_axi4[0].rready   = ip2hdm_aximm0_rready ;
 
 assign hdm2ip_aximm0_awready             =  iafu2cxlip_from_mc_axi4[0].awready ;
 assign hdm2ip_aximm0_wready              =  iafu2cxlip_from_mc_axi4[0].wready ;
 assign hdm2ip_aximm0_bvalid              =  iafu2cxlip_from_mc_axi4[0].bvalid ;
 assign hdm2ip_aximm0_bid                 =  iafu2cxlip_from_mc_axi4[0].bid ;
 assign hdm2ip_aximm0_buser               =  iafu2cxlip_from_mc_axi4[0].buser ;
 assign hdm2ip_aximm0_bresp               =  iafu2cxlip_from_mc_axi4[0].bresp ;
 assign hdm2ip_aximm0_arready             =  iafu2cxlip_from_mc_axi4[0].arready ;
 assign hdm2ip_aximm0_rvalid              =  iafu2cxlip_from_mc_axi4[0].rvalid ;
 assign hdm2ip_aximm0_rlast               =  iafu2cxlip_from_mc_axi4[0].rlast ;
 assign hdm2ip_aximm0_rid                 =  iafu2cxlip_from_mc_axi4[0].rid ;
 assign hdm2ip_aximm0_rdata               =  iafu2cxlip_from_mc_axi4[0].rdata ;
 assign hdm2ip_aximm0_ruser               =  iafu2cxlip_from_mc_axi4[0].ruser ;
 assign hdm2ip_aximm0_rresp               =  iafu2cxlip_from_mc_axi4[0].rresp ;


  always_ff @(posedge ip2hdm_clk) begin
    mc_sr_status_eclk_Q <= mc_sr_status_eclk;
  end

  generate
    if (cxlip_top_pkg::MC_CHANNEL == 2) begin : GenMc2
      assign ddr_mc_status.mc0_status = {11'b0,mc_sr_status_eclk_Q[0]};
      assign ddr_mc_status.mc1_status = {11'b0,mc_sr_status_eclk_Q[1]};
      assign mc_mem_active = mc_sr_status_eclk_Q[0][4] & mc_sr_status_eclk_Q[1][4];
    end
    else if (cxlip_top_pkg::MC_CHANNEL == 4) begin : GenMc4
      assign ddr_mc_status.mc0_status = {3'b000,mc_sr_status_eclk_Q[2],3'b000,mc_sr_status_eclk_Q[0]};
      assign ddr_mc_status.mc1_status = {3'b000,mc_sr_status_eclk_Q[3],3'b000,mc_sr_status_eclk_Q[1]};
      assign mc_mem_active = mc_sr_status_eclk_Q[0][4] & mc_sr_status_eclk_Q[1][4] & mc_sr_status_eclk_Q[2][4] & mc_sr_status_eclk_Q[3][4] ;
    end
    else begin : GenMc1
      assign ddr_mc_status.mc0_status = {11'b0,mc_sr_status_eclk_Q[0]};
      assign ddr_mc_status.mc1_status = '0;
      assign mc_mem_active = mc_sr_status_eclk_Q[0][4];
    end
  endgenerate

  assign mem_dev_status = {5'b00010, mc_mem_active, 2'b00};



  always_comb 
  begin
    mc2ip_memsize = 0;
    for (int i=0; i<NUM_MC_TOP; i=i+1)
    begin
      mc2ip_memsize = mc2ip_memsize + mc2ip_memsize_s[i];
    end
  end
always @(posedge ip2hdm_clk ) begin                 
    if(!ip2hdm_reset_n) begin                          
        ip2cafu_quiesce_req_f  <= 1'b0;                    
        ip2cafu_quiesce_req_ff <= 1'b0;                    
    end                                                
    else begin                                         
        ip2cafu_quiesce_req_f <= ip2cafu_quiesce_req;     
        ip2cafu_quiesce_req_ff <= ip2cafu_quiesce_req_f;  
    end                                                
end             

 //ED HANDSHAKE logic for CXL RESET, User can use this ip2usr_cxlreset_req to reset all the sticky registers in ED
 // ip2usr_cxlreset_req: This signal allows user logic to quiesce any logic related to CXL Reset.
 //                      This signal is asserted when CXL IP initiates CXL reset.This signal is 
 //                      deasserted once CXL reset sequence is complete.     
 //usr2ip_cxlreset_ack : When set,this signal indicates user logic has completed the CXL Reset quiescing.
 //                      User need to de assert this signal once the  ‘usr2ip_cxlreset_req´is deasserted.
 //                      CXL IP waits for de-assertion of this signal before setting ‘ip2usr_cxlreset_complete’ or ‘ip2usr_cxlreset_error ‘
  always @(posedge ip2hdm_clk) begin
  if(!ip2hdm_reset_n) begin           
    usr2ip_cxlreset_ack   <= 1'b0 ;
  end                           
  else begin                    
    usr2ip_cxlreset_ack   <= ip2usr_cxlreset_req;
  end                            
 end 
                                                                                                                                                                                                                 
always_ff@(posedge ip2hdm_clk) ip2hdm_reset_n_f <= ip2hdm_reset_n ;
always_ff@(posedge ip2hdm_clk) ip2hdm_reset_n_ff <= ip2hdm_reset_n_f ;

  //-------------------------------------------------------
  // Example design Modules instatances                  
  //-------------------------------------------------------



cafu_csr0_avmm_wrapper
#(
  .T1IP_ENABLE            (T1IP_ENABLE        )
)
cafu_csr0_avmm_wrapper_inst
(
        // Clocks                                                                          
        .csr_avmm_clk                       (        ip2cafu_avmm_clk                   ),    // AVMM clock : 125MHz
        .rtl_clk                            (        ip2hdm_clk                         ),    // IP clk         
        .axi4_mm_clk                        (        ip2hdm_clk                         ),                                  
        // Resets                                                                          
        .csr_avmm_rstn                      (        ip2cafu_avmm_rstn                  ),                                  
        .rst_n                              (        ip2hdm_reset_n                     ),                                  
        .axi4_mm_rst_n                      (        ip2hdm_reset_n                     ),                                  
        .cxl_or_conv_rst_n                  (        cxl_or_conv_rst_n                  ),	
        // Misc
        .cafu_user_enabled_cxl_io           (        cafu_user_enabled_cxl_io           ),                                  
        .hdm_size_256mb                     (        hdm_size_256mb                     ),                                  
        .ddr_mc_status                      (        ddr_mc_status                      ),
        .mc_mem_active                      (        mc_mem_active                      ),
        .mem_dev_status                     (        mem_dev_status                     ),
        .mc_err_cnt                         (        mc_err_cnt                         ),                                  
        .ccv_afu_conf_base_addr_high        (        ccv_afu_conf_base_addr_high        ),                                  
        .ccv_afu_conf_base_addr_high_valid  (        ccv_afu_conf_base_addr_high_valid  ),                                  
        .ccv_afu_conf_base_addr_low         (        ccv_afu_conf_base_addr_low         ),                                  
        .ccv_afu_conf_base_addr_low_valid   (        ccv_afu_conf_base_addr_low_valid   ),                                  
        // AXI-MM interface - write address channel     
        .awid                               (        afu_axi_aw.awid                    ),                                  
        .awaddr                             (        afu_axi_aw.awaddr                  ),                                  
        .awlen                              (        afu_axi_aw.awlen                   ),                                  
        .awsize                             (        afu_axi_awsize                     ),                                  
        .awburst                            (        afu_axi_awburst                    ),                                  
        .awprot                             (        afu_axi_awprot                     ),                                  
        .awqos                              (        afu_axi_awqos                      ),                                  
        .awuser                             (        afu_axi_aw.awuser                  ),                                  
        .awvalid                            (        afu_axi_aw.awvalid                 ),                                  
        .awcache                            (        afu_axi_awcache                    ),                                  
        .awlock                             (        afu_axi_awlock                     ),                                  
        .awregion                           (        afu_axi_aw.awregion                ),                                  
        .awready                            (        afu_axi_awready                    ),                                  
        // AXI-MM interface - write data channel     
        .wdata                              (        afu_axi_w.wdata                    ),                                  
        .wstrb                              (        afu_axi_w.wstrb                    ),                                  
        .wlast                              (        afu_axi_w.wlast                    ),                                  
        .wuser                              (        afu_axi_w.wuser                    ),                                  
        .wvalid                             (        afu_axi_w.wvalid                   ),                                  
        .wready                             (        afu_axi_wready                     ),                                  
        // AXI-MM interface - write response channel     
        .bid                                (        afu_axi_b.bid                      ),                                  
        .bresp                              (        afu_axi_b.bresp                    ),                                  
        .buser                              (        afu_axi_b.buser                    ),                                  
        .bvalid                             (        afu_axi_b.bvalid                   ),                                  
        .bready                             (        afu_axi_bready                     ),                                  
        // AXI-MM interface - read address channel     
        .arid                               (        afu_axi_ar.arid                    ),                                  
        .araddr                             (        afu_axi_ar.araddr                  ),                                  
        .arlen                              (        afu_axi_ar.arlen                   ),                                  
        .arsize                             (        afu_axi_arsize                     ),                                  
        .arburst                            (        afu_axi_arburst                    ),                                  
        .arprot                             (        afu_axi_arprot                     ),                                  
        .arqos                              (        afu_axi_arqos                      ),                                  
        .aruser                             (        afu_axi_ar.aruser                  ),                                  
        .arvalid                            (        afu_axi_ar.arvalid                 ),                                  
        .arcache                            (        afu_axi_arcache                    ),                                  
        .arlock                             (        afu_axi_arlock                     ),                                  
        .arregion                           (        afu_axi_ar.arregion                ),                                  
        .arready                            (        afu_axi_arready                    ),                                  
        // AXI-MM interface - read response channel     
        .rid                                (        afu_axi_r.rid                      ),                                  
        .rdata                              (        afu_axi_r.rdata                    ),                                  
        .rresp                              (        afu_axi_r.rresp                    ),                                  
        .rlast                              (        afu_axi_r.rlast                    ),                                  
        .ruser                              (        afu_axi_r.ruser                    ),                                  
        .rvalid                             (        afu_axi_r.rvalid                   ),                                  
        .rready                             (        afu_axi_rready                     ),                                  
        // cfg signals
	.cafu2ip_csr0_cfg_if                (        cafu2ip_csr0_cfg_if                ),                                  
        .ip2cafu_csr0_cfg_if                (        ip2cafu_csr0_cfg_if                ), 
        .usr2ip_cxlreset_initiate           (usr2ip_cxlreset_initiate                   ), 
        .ip2usr_cxlreset_error              (ip2usr_cxlreset_error                      ),
        .ip2usr_cxlreset_complete           (ip2usr_cxlreset_complete                   ),                                  
        // Between AFU and CXL_IP CSR Access  AVMM  Bus                           
        .csr_avmm_waitrequest               (        cafu2ip_avmm_waitrequest           ),                                  
        .csr_avmm_readdata                  (        cafu2ip_avmm_readdata              ),                                  
        .csr_avmm_readdatavalid             (        cafu2ip_avmm_readdatavalid         ),                                  
        .csr_avmm_writedata                 (        ip2cafu_avmm_writedata             ),                                  
        .csr_avmm_address                   (        ip2cafu_avmm_address               ),                                  
        .csr_avmm_write                     (        ip2cafu_avmm_write                 ),                                  
        .csr_avmm_read                      (        ip2cafu_avmm_read                  ),                                  
        .csr_avmm_poison                    (        ip2cafu_avmm_poison                ),                                  
        .csr_avmm_byteenable                (        ip2cafu_avmm_byteenable            )                                   
);

logic cache_query_en;
logic cache_query_ready;
logic cache_mig_addr_en_eclk;
logic cache_mig_addr_en_aclk;
logic [27:0]  cache_mig_addr_eclk;
logic [27:0]  cache_mig_addr_aclk;
logic cache_mig_addr_ready;

// hot cache tracker interface
logic page_query_en;
logic page_query_ready;
logic page_mig_addr_en_aclk;
logic page_mig_addr_en_stretch;
logic page_mig_addr_en_eclk;
logic [27:0]  page_mig_addr;
logic [27:0]  page_mig_addr_aclk;
logic [27:0]  page_mig_addr_stretch;
logic [27:0]  page_mig_addr_eclk;
logic page_mig_addr_ready;

logic [31:0] page_query_rate_aclk;
logic [31:0] page_query_rate_eclk;
logic [31:0] cache_query_rate_aclk;
logic [31:0] cache_query_rate_eclk;
logic page_cdc_fifo_rdempty;
logic cache_cdc_fifo_rdempty;
logic mem_chan_rd_en;

logic [32:0]  csr_addr_ub;
logic [32:0]  csr_addr_lb;


logic [63:0] csr_prefetch_page_addr;
logic csr_start_prefetch_aclk;
logic csr_start_prefetch_eclk;
logic [511:0] csr_prefetch_page_data;
logic prefetch_end;
logic [63:0] cxl_start_pa;
logic [63:0] cxl_addr_offset;

// cust_afu_wrapper cust_afu_wrapper_inst
// (
//  // Clocks
//   .axi4_mm_clk                           (ip2hdm_clk), 
//  // Resets
//   .axi4_mm_rst_n                         (ip2hdm_reset_n),

// // AXI-MM interface - write address channel
//   .awid                                  (axi1_awid),
//   .awaddr                                (axi1_awaddr), 
//   .awlen                                 (axi1_awlen),
//   .awsize                                (axi1_awsize),
//   .awburst                               (axi1_awburst),
//   .awprot                                (axi1_awprot),
//   .awqos                                 (axi1_awqos),
//   .awuser                                (axi1_awuser),
//   .awvalid                               (axi1_awvalid),
//   .awcache                               (axi1_awcache),
//   .awlock                                (axi1_awlock),
//   .awregion                              (axi1_awregion),
//   .awatop                                (axi1_awatop),
//   .awready                               (axi1_awready),
  
// // AXI-MM interface - write data channel
//   .wdata                                 (axi1_wdata),
//   .wstrb                                 (axi1_wstrb),
//   .wlast                                 (axi1_wlast),
//   .wuser                                 (axi1_wuser),
//   .wvalid                                (axi1_wvalid),
//   .wready                                (axi1_wready),
  
// //  AXI-MM interface - write response channel
//    .bid                                  (axi1_bid),
//    .bresp                                (axi1_bresp),
//    .buser                                (axi1_buser),
//    .bvalid                               (axi1_bvalid),
//    .bready                               (axi1_bready),
  
// // AXI-MM interface - read address channel
//   .arid                                  (axi1_arid),
//   .araddr                                (axi1_araddr),
//   .arlen                                 (axi1_arlen),
//   .arsize                                (axi1_arsize),
//   .arburst                               (axi1_arburst),
//   .arprot                                (axi1_arprot),
//   .arqos                                 (axi1_arqos),
//   .aruser                                (axi1_aruser),
//   .arvalid                               (axi1_arvalid),
//   .arcache                               (axi1_arcache),
//   .arlock                                (axi1_arlock),
//   .arregion                              (axi1_arregion),
//   .arready                               (axi1_arready),

// // AXI-MM interface - read response channel
//   .rid                                   (axi1_rid),
//   .rdata                                 (axi1_rdata),
//   .rresp                                 (axi1_rresp),
//   .rlast                                 (axi1_rlast),
//   .ruser                                 (axi1_ruser),
//   .rvalid                                (axi1_rvalid),
//   .rready                                (axi1_rready)
  
  
// );


  //-------------------------------------------------------
  // AVST4TO1 - CONVERGE 4 AVST TO 1 AVST SEGMENT                                  
  //-------------------------------------------------------

cxl_ed_avst_4to1_rx_side #(
        .APP_CORES             (  1   ),
        .P_HDR_CRDT            (  8   ),
        .NP_HDR_CRDT           (  8   ),
        .CPL_HDR_CRDT          (  8   ),
        .P_DATA_CRDT           (  32  ),
        .NP_DATA_CRDT          (  32  ),
        .CPL_DATA_CRDT         (  32  ),
        .DATA_FIFO_ADDR_WIDTH  (  5   )
) rx_side_inst (
        .pld_clk                         (  ip2hdm_clk                 ),
        .pld_rst_n                       (  ip2hdm_reset_n_f           ),
        .pld_init_done_rst_n             (  ip2hdm_reset_n_f           ),
        .pld_rx                          (  p0_pld_if.rx               ),
        .pld_rx_crd                      (  p0_pld_if.rx_crd           ),
        .crd_prim_rst_n                  (  ip2hdm_reset_n_f           ),
        .avst4to1_prim_clk               (  ip2hdm_clk                 ),
        .avst4to1_prim_rst_n             (  ip2hdm_reset_n_f           ),
        .avst4to1_core_max_payload       (  2'b00                      ),
        .tx_init                         (  tx_st_hcrdt_init_i         ),
        .avst4to1_rx_sop                 (  ed_rx_sop                  ),
        .avst4to1_rx_eop                 (  ed_rx_eop                  ),
        .avst4to1_rx_hdr                 (  ed_rx_header               ),
        .avst4to1_rx_passthrough         (  ed_rx_passthrough          ),
        .avst4to1_rx_data                (  ed_rx_payload              ),
        .avst4to1_rx_data_dw_valid       (  ed_rx_dw_valid             ),
        .avst4to1_rx_prefix              (  ed_rx_prefix               ),                         
        .avst4to1_rx_prefix_valid        (  ed_rx_prefix_valid         ),                         
        .avst4to1_rx_RSSAI_prefix        (                             ),                         
        .avst4to1_rx_RSSAI_prefix_valid  (                             ),                         
        .avst4to1_vf_active              (                             ),                         
        .avst4to1_vf_num                 (                             ),                         
        .avst4to1_pf_num                 (                             ),                         
        .avst4to1_bar_range              (                             ),                         
        .avst4to1_rx_tlp_abort           (                             ),                         
        .avst4to1_np_hdr_crd_pop         (  avst4to1_np_hdr_crd_pop    ),
        .avst4to1_rx_data_avail          (  avst4to1_rx_data_avail     ),
        .avst4to1_rx_hdr_avail           (  avst4to1_rx_hdr_avail      ),
        .avst4to1_rx_nph_hdr_avail       (  avst4to1_rx_nph_hdr_avail  )
);
//--------------------------------------------------
// intel_cxl_pf_checker
//--------------------------------------------------
intel_cxl_pf_checker  inst_cxl_pf_checker  (                                                                             
		.clk                                         (    ip2hdm_clk                     ),                                             
		//--ed                                                                                                                          
		.ed_rx_st_bar_i                              (    '0                             ),                                             
		.ed_rx_st_eop_i                              (    ed_rx_eop_i                    ),                                             
		.ed_rx_st_header_i                           (    ed_rx_header_update            ),                                              
		.ed_rx_st_payload_i                          (    ed_rx_payload[0]               ),                                             
		.ed_rx_st_sop_i                              (    ed_rx_sop_i                    ),                                              
		.ed_rx_st_hvalid_i                           (    ed_rx_hvalid                   ),                  
		.ed_rx_st_dvalid_i                           (    ed_rx_valid                    ),                         
		.ed_rx_st_pvalid_i                           (    ed_rx_prefix_valid[0]            ),                                             
		.ed_rx_st_empty_i                            (    '0                            ),                                             
		.ed_rx_st_pfnum_i                            (    '0                            ),                                             
		.ed_rx_st_tlp_prfx_i                         (    ed_rx_prefix[0]                  ),                                             
		.ed_rx_st_data_parity_i                      (    '0                             ),                                             
		.ed_rx_st_hdr_parity_i                       (    '0                             ),                                             
		.ed_rx_st_tlp_prfx_parity_i                  (    '0                             ),                                             
		.ed_rx_st_rssai_prefix_i                     (    '0                             ),                                             
		.ed_rx_st_rssai_prefix_parity_i              (    '0                             ),                                             
		.ed_rx_st_vfactive_i                         (    '0                             ),                                             
		.ed_rx_st_vfnum_i                            (    '0                             ),                                             
		.ed_rx_st_chnum_i                            (    '0                             ),                                             
		.ed_rx_st_misc_parity_i                      (    '0                             ),                                             
		.ed_rx_st_passthrough_i                      (    ed_rx_passthrough[0]           ),                                             
		.ed_rx_st_ready_o                            (    ed_rx_ready                    ),                                             
                .pf0_memory_access_en                        (    pf0_memory_access_en           ),
                .pf1_memory_access_en                        (    pf1_memory_access_en           ),
		//--default config                                                                             
		.default_config_rx_st_bar_o                  (    default_config_rx_bar          ),                                             
		.default_config_rx_st_eop_o                  (    default_config_rx_eop          ),                                             
		.default_config_rx_st_header_o               (    default_config_rx_header       ),                                             
		.default_config_rx_st_payload_o              (    default_config_rx_payload      ),                                             
		.default_config_rx_st_sop_o                  (    default_config_rx_sop          ),                                             
		.default_config_rx_st_hvalid_o               (    default_config_rx_hvalid       ),                                             
		.default_config_rx_st_dvalid_o               (    default_config_rx_dvalid       ),                                             
		.default_config_rx_st_pvalid_o               (                                   ),                                             
		.default_config_rx_st_empty_o                (                                   ),                                             
		.default_config_rx_st_pfnum_o                (                                   ),                                             
		.default_config_rx_st_tlp_prfx_o             (                                   ),                                             
		.default_config_rx_st_data_parity_o          (                                   ),                                             
		.default_config_rx_st_hdr_parity_o           (                                   ),                                             
		.default_config_rx_st_tlp_prfx_parity_o      (                                   ),                                             
		.default_config_rx_st_rssai_prefix_o         (                                   ),                                             
		.default_config_rx_st_rssai_prefix_parity_o  (                                   ),                                             
		.default_config_rx_st_vfactive_o             (                                   ),                                             
		.default_config_rx_st_vfnum_o                (                                   ),                                             
		.default_config_rx_st_chnum_o                (                                   ),                                             
		.default_config_rx_st_misc_parity_o          (                                   ),                                             
		.default_config_rx_st_passthrough_o          (    default_config_rx_passthrough  ),                                             
		.default_config_rx_st_ready_i                (    default_config_rx_ready        ),                                             
		//--pio                                                                                                                         
		.pio_rx_st_bar_o                             (     pio_rx_bar                    ),                                             
		.pio_rx_st_eop_o                             (     aer_chk_rx_eop                    ),                                             
		.pio_rx_st_header_o                          (     aer_chk_rx_header                 ),                                             
		.pio_rx_st_payload_o                         (     aer_chk_rx_payload                ),                                             
		.pio_rx_st_sop_o                             (     aer_chk_rx_sop                    ),                                             
		.pio_rx_st_hvalid_o                          (     aer_chk_rx_hvalid                 ),                                             
		.pio_rx_st_dvalid_o                          (     aer_chk_rx_dvalid                 ),                                             
		.pio_rx_st_pvalid_o                          (     aer_chk_rx_pvalid                 ),                                             
		.pio_rx_st_empty_o                           (                                   ),                                             
		.pio_rx_st_pfnum_o                           (                                   ),                                             
		.pio_rx_st_tlp_prfx_o                        (     aer_chk_rx_prefix                 ),                                             
		.pio_rx_st_data_parity_o                     (                                   ),                                             
		.pio_rx_st_hdr_parity_o                      (                                   ),                                             
		.pio_rx_st_tlp_prfx_parity_o                 (                                   ),                                             
		.pio_rx_st_rssai_prefix_o                    (                                   ),                                             
		.pio_rx_st_rssai_prefix_parity_o             (                                   ),                                             
		.pio_rx_st_vfactive_o                        (                                   ),                                             
		.pio_rx_st_vfnum_o                           (                                   ),                                             
		.pio_rx_st_chnum_o                           (                                   ),                                             
		.pio_rx_st_misc_parity_o                     (                                   ),                                             
		.pio_rx_st_passthrough_o                     (    pio_rx_passthrough             ),                                             
		.pio_rx_st_ready_i                           (    pio_rx_ready                   ),                                             
		//--afu                                                                                                                         
		.afu_rx_st_bar_o                             (     afu_rx_bar                    ),                                             
		.afu_rx_st_eop_o                             (     afu_rx_eop                    ),                                             
		.afu_rx_st_header_o                          (     afu_rx_hdr                    ),                                             
		.afu_rx_st_payload_o                         (     afu_rx_data                   ),                                             
		.afu_rx_st_sop_o                             (     afu_rx_sop                    ),                                             
		.afu_rx_st_hvalid_o                          (     afu_rx_hvalid                 ),                                             
		.afu_rx_st_dvalid_o                          (     afu_rx_dvalid                 ),                                             
		.afu_rx_st_pvalid_o                          (                                   ),                                             
		.afu_rx_st_empty_o                           (                                   ),                                             
		.afu_rx_st_pfnum_o                           (                                   ),                                             
		.afu_rx_st_tlp_prfx_o                        (                                   ),                                             
		.afu_rx_st_data_parity_o                     (                                   ),                                             
		.afu_rx_st_hdr_parity_o                      (                                   ),                                             
		.afu_rx_st_tlp_prfx_parity_o                 (                                   ),                                             
		.afu_rx_st_rssai_prefix_o                    (                                   ),                                             
		.afu_rx_st_rssai_prefix_parity_o             (                                   ),                                             
		.afu_rx_st_vfactive_o                        (                                   ),                                             
		.afu_rx_st_vfnum_o                           (                                   ),                                             
		.afu_rx_st_chnum_o                           (                                   ),                                             
		.afu_rx_st_misc_parity_o                     (                                   ),                                             
		.afu_rx_st_passthrough_o                     (    afu_rx_passthrough             ),                                             
		.afu_rx_st_ready_i                           (    afu_rx_ready                   ),                                             
		.afu_pio_select                              (    afu_pio_select                 ),  
		.rstn                                        (    ip2hdm_reset_n_f               )                                              
);                                                                                                                                              

//------------------------------------------
// default config block for sending UR
//-----------------------------------------



intel_cxl_default_config inst_cxl_default_config  (
	.clk                                (  ip2hdm_clk    			    ),              
	.rst_n                              (  ip2hdm_reset_n_f    		    ),
        .default_config_rx_bar              (  default_config_rx_bar                ),
        .default_config_rx_sop_i            (  default_config_rx_sop                ),
        .default_config_rx_eop_i            (  default_config_rx_eop                ),
        .default_config_rx_header_i         (  default_config_rx_header             ),
        .default_config_rx_payload_i        (  default_config_rx_payload            ),
        .default_config_rx_valid_i          (  default_config_rx_hvalid             ),
        .default_config_rx_st_ready_o       (  default_config_rx_ready              ),
        .default_config_tx_st_ready_i       (  pio_txc_ready                        ),
        .default_config_rx_bus_number       (  ed_rx_bus_number                     ),
        .default_config_rx_device_number    (  ed_rx_device_number                  ),
        .default_config_rx_function_number  (  ed_rx_function_number                ),
        .default_config_txc_eop             (  default_config_txc_eop               ),
        .default_config_txc_header          (  default_config_txc_header            ),
        .default_config_txc_payload         (  default_config_txc_payload           ),
        .default_config_txc_sop             (  default_config_txc_sop               ),
        .default_config_txc_valid           (  default_config_txc_valid             ),
        .ed_tx_st0_passthrough_o            (  default_config_tx_st0_passthrough_i  )
        );


intel_cxl_aer intel_cxl_aer_inst (
		.clk               (  ip2hdm_clk               ),
		.rst               (  ip2hdm_reset_n_f         ),
		.rx_sop            (  aer_chk_rx_sop           ),
		.rx_eop            (  aer_chk_rx_eop           ),
		.rx_hvalid         (  aer_chk_rx_hvalid        ),
		.rx_dvalid         (  aer_chk_rx_dvalid        ),
		.rx_header         (  aer_chk_rx_header        ),
		.rx_data           (  aer_chk_rx_payload       ),
		.rx_prefix         (  aer_chk_rx_prefix        ),
		.rx_pvalid         (  aer_chk_rx_pvalid        ),
		.rx_bus_number     (  ed_rx_bus_number         ),
		.rx_device_number  (  ed_rx_device_number      ),
		.pio_to_send_cpl   (  pio_to_send_cpl          ),
		.no_err_rx_sop     (  pio_rx_sop               ),
		.no_err_rx_eop     (  pio_rx_eop               ),
		.no_err_rx_hvalid  (  pio_rx_hvalid            ),
		.no_err_rx_dvalid  (  pio_rx_dvalid            ),
		.no_err_rx_header  (  pio_rx_header            ),
		.no_err_rx_data    (  pio_rx_payload           ),
		.np_ca_rx_sop      (  np_ca_rx_sop             ),
		.np_ca_rx_eop      (  np_ca_rx_eop             ),
		.np_ca_rx_hvalid   (  np_ca_rx_hvalid          ),
		.np_ca_rx_dvalid   (  np_ca_rx_dvalid          ),
		.np_ca_rx_header   (  np_ca_rx_header          ),
		.np_ca_rx_data     (  np_ca_rx_data            ),
		.app_err_ready     (  ip2usr_app_err_ready     ),
		.app_err_valid     (  usr2ip_app_err_valid     ),
		.app_err_hdr       (  usr2ip_app_err_hdr       ),
		.app_err_info      (  usr2ip_app_err_info      ),
		.app_err_func_num  (  usr2ip_app_err_func_num  )
		);


  //-------------------------------------------------------
  // CXL PIO                                  
  //-------------------------------------------------------

intel_cxl_pio_ed_top       intel_cxl_pio_ed_top_inst  (                             
		.Clk_i                     (     ip2hdm_clk                ),
		.Rstn_i                    (     ip2hdm_reset_n_f          ),  
		.pio_rx_bar                (     pio_rx_bar                ),  
		.pio_rx_eop                (     pio_rx_eop                ),  
		.pio_rx_header             (     pio_rx_header             ),  
		.pio_rx_payload            (     pio_rx_payload            ),  
		.pio_rx_sop                (     pio_rx_sop                ),  
		.pio_rx_valid              (     pio_rx_hvalid             ),  
		.pio_rx_ready              (     pio_rx_ready              ),  
		.pio_txc_ready             (     pio_txc_ready             ),  
		.pio_txc_eop               (     pio_txc_eop               ),  
		.pio_txc_header            (     pio_txc_header            ),  
		.pio_txc_payload           (     pio_txc_payload           ),  
		.pio_txc_sop               (     pio_txc_sop               ),  
		.pio_txc_valid             (     pio_txc_valid             ),  
    		.pio_to_send_cpl	   (	 pio_to_send_cpl	   ),
		.ed_rx_bus_number          (     ed_rx_bus_number          ),
		.ed_rx_device_number       (     ed_rx_device_number       )
		);                                                                                  


  //-------------------------------------------------------
  // CXL TX REDIT INTERFACE                                  
  //-------------------------------------------------------


intel_cxl_tx_crdt_intf inst_cxl_tx_crdt_intf (
        .clk                       (  ip2hdm_clk                ),                              
        .rst_n                     (  ip2hdm_reset_n_f          ),                              
        .tx_st_hcrdt_update_i      (  tx_st_hcrdt_update_i      ),                              
        .tx_st_hcrdt_update_cnt_i  (  tx_st_hcrdt_update_cnt_i  ),                              
        .tx_st_hcrdt_init_i        (  tx_st_hcrdt_init_i        ),                              
        .tx_st_hcrdt_init_ack_o    (  tx_st_hcrdt_init_ack_o    ),                              
        .tx_st_dcrdt_update_i      (  tx_st_dcrdt_update_i      ),                              
        .tx_st_dcrdt_update_cnt_i  (  tx_st_dcrdt_update_cnt_i  ),                              
        .tx_st_dcrdt_init_i        (  tx_st_dcrdt_init_i        ),                              
        .tx_st_dcrdt_init_ack_o    (  tx_st_dcrdt_init_ack_o    ),                              
        .pio_tx_st_ready_i         (  ed_tx_st_ready_i          ),                              
        .bam_tx_signal_ready_o     (  pio_txc_ready             ),                              
        .tx_hdr_i                  (  tx_hdr                    ),                              
        .tx_hdr_valid_i            (  tx_hdr_valid              ),                              
        .tx_hdr_type_i             (  tx_hdr_type               ),                              
        .dc_tx_hdr_valid_i         (  1'b0                      ),
        .tx_p_data_counter         (  tx_p_data_counter         ),                              
        .tx_np_data_counter        (  tx_np_data_counter        ),                              
        .tx_cpl_data_counter       (  tx_cpl_data_counter       ),                              
        .tx_p_header_counter       (  tx_p_header_counter       ),                              
        .tx_np_header_counter      (  tx_np_header_counter      ),                              
        .tx_cpl_header_counter     (  tx_cpl_header_counter     )                               
        );                                                                                      



  //-------------------------------------------------------
  // CXL AFU - CACHE/IO DEMUX                                  
  //-------------------------------------------------------



intel_cxl_afu_cache_io_demux  inst_intel_cxl_afu_cache_io_demux ( 
		.clk                    (  ip2hdm_clk             ),                                                     
		.rst                    (  ip2hdm_reset_n_f       ),                                                     
		.afu_cache_io_select    (  afu_cache_io_select    ),  //afu_cache_io_select  ==  1  ?  select  io  else  cache
		//--to/from afu                                                                              
		.afu_axi_ar             (  afu_axi_ar             ),                                                     
		.afu_axi_arready        (  afu_axi_arready        ),                                                     
		.afu_axi_r              (  afu_axi_r              ),                                                     
		.afu_axi_rready         (  afu_axi_rready         ),                                                     
		.afu_axi_aw             (  afu_axi_aw             ),                                                     
		.afu_axi_awready        (  afu_axi_awready        ),                                                     
		.afu_axi_w              (  afu_axi_w              ),                                                     
		.afu_axi_wready         (  afu_axi_wready         ),                                                     
		.afu_axi_b              (  afu_axi_b              ),                                                     
		.afu_axi_bready         (  afu_axi_bready         ),                                                     
		//--to/from  cache                                                                   
		.afu_cache_axi_ar       (  afu_cache_axi_ar       ),                                                     
		.afu_cache_axi_arready  (  afu_cache_axi_arready  ),                                                     
		.afu_cache_axi_r        (  afu_cache_axi_r        ),                                                     
		.afu_cache_axi_rready   (  afu_cache_axi_rready   ),                                                     
		.afu_cache_axi_aw       (  afu_cache_axi_aw       ),                                                     
		.afu_cache_axi_awready  (  afu_cache_axi_awready  ),                                                     
		.afu_cache_axi_w        (  afu_cache_axi_w        ),                                                     
		.afu_cache_axi_wready   (  afu_cache_axi_wready   ),                                                     
		.afu_cache_axi_b        (  afu_cache_axi_b        ),                                                     
		.afu_cache_axi_bready   (  afu_cache_axi_bready   ),                                                     
		//--to/from  io                                                                      
		.afu_io_axi_ar          (  afu_io_axi_ar          ),                                                     
		.afu_io_axi_arready     (  afu_io_axi_arready     ),                                                     
		.afu_io_axi_r           (  afu_io_axi_r           ),                                                     
		.afu_io_axi_rready      (  afu_io_axi_rready      ),                                                     
		.afu_io_axi_aw          (  afu_io_axi_aw          ),                                                     
		.afu_io_axi_awready     (  afu_io_axi_awready     ),                                                     
		.afu_io_axi_w           (  afu_io_axi_w           ),                                                     
		.afu_io_axi_wready      (  afu_io_axi_wready      ),                                                     
		.afu_io_axi_b           (  afu_io_axi_b           ),                                                     
		.afu_io_axi_bready      (  afu_io_axi_bready      )                                                      
		);                                                                                                             

  //-------------------------------------------------------
  // CXL AXI <--> AVST bridge                                  
  //-------------------------------------------------------
axi_to_avst_bridge      inst_axi_to_avst_bridge  (                                                      
		.clk                    (    ip2hdm_clk             ),                              
		.rst                    (    ip2hdm_reset_n_f       ),
		.axi_ar                 (    afu_io_axi_ar          ),                              
		.axi_arready            (    afu_io_axi_arready     ),                              
		.axi_r                  (    afu_io_axi_r           ),                              
		.axi_rready             (    afu_io_axi_rready      ),                              
		.axi_aw                 (    afu_io_axi_aw          ),                              
		.axi_awready            (    afu_io_axi_awready     ),                              
		.axi_w                  (    afu_io_axi_w           ),                              
		.axi_wready             (    afu_io_axi_wready      ),                              
		.axi_b                  (    afu_io_axi_b           ),                              
		.axi_bready             (    afu_io_axi_bready      ),                              
                .pf0_bus_master_en      (    pf0_bus_master_en      ),      
		.bus_number             (    ed_rx_bus_number       ),                              
		.device_number          (    ed_rx_device_number    ),                              
		.function_number        (    ed_rx_function_number  ),                              
                .wr_tlp_fifo_empty      (    wr_tlp_fifo_empty      ), 
                .wr_tlp_fifo_almost_full(    wr_tlp_fifo_almost_full),
                .rd_tlp_fifo_almost_full(    rd_tlp_fifo_almost_full),
                .p_tlp_sent_tag         (    p_tlp_sent_tag         ),
                .p_tlp_sent_tag_valid   (    p_tlp_sent_tag_valid   ), 
		.rx_st_dvalid           (    afu_rx_dvalid          ),                              
		.rx_st_sop              (    afu_rx_sop             ),  
		.rx_st_eop              (    afu_rx_eop             ),                              
		.rx_st_data             (    afu_rx_data            ),  
		.rx_st_hdr              (    afu_rx_hdr             ),                              
		.rx_st_hvalid           (    afu_rx_hvalid          ),                              
		.tx_st_ready            (			    ),                                                     
		.tx_st_dvalid           (    afu_tx_st0_dvalid_o    ),                              
		.tx_st_sop              (    afu_tx_st0_sop_o       ),                              
		.tx_st_eop              (    afu_tx_st0_eop_o       ),                              
		.tx_st_data             (    afu_tx_st0_data_o      ),                              
		.tx_st_hdr              (    afu_tx_st0_hdr_o       ),                              
                .wr_last                (    wr_last                ),
		.tx_st_hvalid           (    afu_tx_st0_hvalid_o    ),                              
		.tx_p_data_counter      (    tx_p_data_counter      ),                              
		.tx_np_data_counter     (    tx_np_data_counter     ),                              
		.tx_cpl_data_counter    (    tx_cpl_data_counter    ),                              
		.tx_p_header_counter    (    tx_p_header_counter    ),                              
		.tx_np_header_counter   (    tx_np_header_counter   ),                              
		.tx_cpl_header_counter  (    tx_cpl_header_counter  )                               
		);                                                                                                      

  //-------------------------------------------------------
  // TX_TLP_FIFO                                  
  //-------------------------------------------------------

intel_cxl_tx_tlp_fifos  inst_tlp_fifos  (                              
        .clk                         (  ip2hdm_clk                          ),
        .rst                         (  ip2hdm_reset_n_f                    ),
        .ip_tx_ready                 (  ed_tx_st_ready_i                    ),
        .afu_pio_select              (  afu_pio_select                      ),
        .afu_tx_st_dvalid            (  afu_tx_st0_dvalid_o                 ),
        .afu_tx_st_sop               (  afu_tx_st0_sop_o                    ),
        .afu_tx_st_eop               (  afu_tx_st0_eop_o                    ),
        .afu_tx_st_passthrough       (  afu_tx_st0_passthrough_o            ),
        .afu_tx_st_data              (  afu_tx_st0_data_o                   ),
        .afu_tx_st_hdr               (  afu_tx_st0_hdr_o                    ),
        .wr_last                     (  wr_last                             ),
        .afu_tx_st_hvalid            (  afu_tx_st0_hvalid_o                 ),
        .default_config_txc_eop      (  default_config_txc_eop              ),
        .default_config_txc_header   (  default_config_tx_st_header_update  ),
        .default_config_txc_payload  (  default_config_txc_payload          ),
        .default_config_txc_sop      (  default_config_txc_sop              ),
        .default_config_txc_valid    (  default_config_txc_valid            ),
        .pio_txc_eop                 (  pio_txc_eop                         ),
        .pio_txc_header              (  pio_txc_header_update               ),
        .pio_txc_payload             (  pio_txc_payload                     ),
        .pio_txc_sop                 (  pio_txc_sop                         ),
        .pio_txc_valid               (  pio_txc_valid                       ),
	.np_ca_rx_sop      	     (  np_ca_rx_sop             	    ),
	.np_ca_rx_eop      	     (  np_ca_rx_eop             	    ),
	.np_ca_rx_hvalid   	     (  np_ca_rx_hvalid          	    ),
	.np_ca_rx_dvalid   	     (  np_ca_rx_dvalid          	    ),
	.np_ca_rx_header   	     (  np_ca_rx_header          	    ),
	.np_ca_rx_data     	     (  np_ca_rx_data            	    ),
        .tx_p_data_counter           (  tx_p_data_counter                   ),
        .tx_np_data_counter          (  tx_np_data_counter                  ),
        .tx_cpl_data_counter         (  tx_cpl_data_counter                 ),
        .tx_p_header_counter         (  tx_p_header_counter                 ),
        .tx_np_header_counter        (  tx_np_header_counter                ),
        .tx_cpl_header_counter       (  tx_cpl_header_counter               ),
        .p_tlp_sent_tag              (  p_tlp_sent_tag                      ),
        .p_tlp_sent_tag_valid        (  p_tlp_sent_tag_valid                ), 
        .wr_tlp_fifo_empty           (  wr_tlp_fifo_empty                   ),
        .wr_tlp_fifo_almost_full     (  wr_tlp_fifo_almost_full             ),
        .rd_tlp_fifo_almost_full     (  rd_tlp_fifo_almost_full             ),
        .avst4to1_np_hdr_crd_pop     (  avst4to1_np_hdr_crd_pop             ),
        .tx_st0_dvalid               (  ed_tx_st0_dvalid_o                  ),
        .tx_st0_sop                  (  ed_tx_st0_sop_o                     ),
        .tx_st0_eop                  (  ed_tx_st0_eop_o                     ),
        .tx_st0_passthrough          (  ed_tx_st0_passthrough_o             ),
        .tx_st0_data                 (  ed_tx_st0_payload_o                 ),
        .tx_st0_data_parity          (  ed_tx_st0_data_parity               ),
        .tx_st0_hdr                  (  ed_tx_st0_header_o                  ),
        .tx_st0_hdr_parity           (  ed_tx_st0_hdr_parity                ),
        .tx_st0_hvalid               (  ed_tx_st0_hvalid_o                  ),
        .tx_st0_prefix               (  ed_tx_st0_prefix_o                  ),
        .tx_st0_prefix_parity        (  ed_tx_st0_prefix_parity             ),
        .tx_st0_RSSAI_prefix         (                                      ),
        .tx_st0_RSSAI_prefix_parity  (                                      ),
        .tx_st0_pvalid               (  ed_tx_st0_pvalid_o                  ),
        .tx_st0_vfactive             (  ed_tx_st0_vfactive                  ),
        .tx_st0_vfnum                (  ed_tx_st0_vfnum                     ),
        .tx_st0_pfnum                (  ed_tx_st0_pfnum                     ),
        .tx_st0_chnum                (  ed_tx_st0_chnum                     ),
        .tx_st0_empty                (  ed_tx_st0_empty                     ),
        .tx_st0_misc_parity          (  ed_tx_st0_misc_parity               ),
        .tx_st1_dvalid               (  ed_tx_st1_dvalid_o                  ),
        .tx_st1_sop                  (  ed_tx_st1_sop_o                     ),
        .tx_st1_eop                  (  ed_tx_st1_eop_o                     ),
        .tx_st1_passthrough          (  ed_tx_st1_passthrough_o             ),
        .tx_st1_data                 (  ed_tx_st1_payload_o                 ),
        .tx_st1_data_parity          (  ed_tx_st1_data_parity               ),
        .tx_st1_hdr                  (  ed_tx_st1_header_o                  ),
        .tx_st1_hdr_parity           (  ed_tx_st1_hdr_parity                ),
        .tx_st1_hvalid               (  ed_tx_st1_hvalid_o                  ),
        .tx_st1_prefix               (  ed_tx_st1_prefix_o                  ),
        .tx_st1_prefix_parity        (  ed_tx_st1_prefix_parity             ),
        .tx_st1_RSSAI_prefix         (                                      ),
        .tx_st1_RSSAI_prefix_parity  (                                      ),
        .tx_st1_pvalid               (  ed_tx_st1_pvalid_o                  ),
        .tx_st1_vfactive             (  ed_tx_st1_vfactive                  ),
        .tx_st1_vfnum                (  ed_tx_st1_vfnum                     ),
        .tx_st1_pfnum                (  ed_tx_st1_pfnum                     ),
        .tx_st1_chnum                (  ed_tx_st1_chnum                     ),
        .tx_st1_empty                (  ed_tx_st1_empty                     ),
        .tx_st1_misc_parity          (  ed_tx_st1_misc_parity               ),
        .tx_st2_dvalid               (  ed_tx_st2_dvalid_o                  ),
        .tx_st2_sop                  (  ed_tx_st2_sop_o                     ),
        .tx_st2_eop                  (  ed_tx_st2_eop_o                     ),
        .tx_st2_passthrough          (  ed_tx_st2_passthrough_o             ),
        .tx_st2_data                 (  ed_tx_st2_payload_o                 ),
        .tx_st2_data_parity          (  ed_tx_st2_data_parity               ),
        .tx_st2_hdr                  (  ed_tx_st2_header_o                  ),
        .tx_st2_hdr_parity           (  ed_tx_st2_hdr_parity                ),
        .tx_st2_hvalid               (  ed_tx_st2_hvalid_o                  ),
        .tx_st2_prefix               (  ed_tx_st2_prefix_o                  ),
        .tx_st2_prefix_parity        (  ed_tx_st2_prefix_parity             ),
        .tx_st2_RSSAI_prefix         (                                      ),
        .tx_st2_RSSAI_prefix_parity  (                                      ),
        .tx_st2_pvalid               (  ed_tx_st2_pvalid_o                  ),
        .tx_st2_vfactive             (  ed_tx_st2_vfactive_o                ),
        .tx_st2_vfnum                (  ed_tx_st2_vfnum                     ),
        .tx_st2_pfnum                (  ed_tx_st2_pfnum                     ),
        .tx_st2_chnum                (  ed_tx_st2_chnum                     ),
        .tx_st2_empty                (  ed_tx_st2_empty                     ),
        .tx_st2_misc_parity          (  ed_tx_st2_misc_parity               ),
        .tx_st3_dvalid               (  ed_tx_st3_dvalid_o                  ),
        .tx_st3_sop                  (  ed_tx_st3_sop_o                     ),
        .tx_st3_eop                  (  ed_tx_st3_eop_o                     ),
        .tx_st3_passthrough          (  ed_tx_st3_passthrough_o             ),
        .tx_st3_data                 (  ed_tx_st3_payload_o                 ),
        .tx_st3_data_parity          (  ed_tx_st3_data_parity               ),
        .tx_st3_hdr                  (  ed_tx_st3_header_o                  ),
        .tx_st3_hdr_parity           (  ed_tx_st3_hdr_parity                ),
        .tx_st3_hvalid               (  ed_tx_st3_hvalid_o                  ),
        .tx_st3_prefix               (  ed_tx_st3_prefix_o                  ),
        .tx_st3_prefix_parity        (  ed_tx_st3_prefix_parity             ),
        .tx_st3_RSSAI_prefix         (                                      ),
        .tx_st3_RSSAI_prefix_parity  (                                      ),
        .tx_st3_pvalid               (  ed_tx_st3_pvalid_o                  ),
        .tx_st3_vfactive             (  ed_tx_st3_vfactive                  ),
        .tx_st3_vfnum                (  ed_tx_st3_vfnum                     ),
        .tx_st3_pfnum                (  ed_tx_st3_pfnum                     ),
        .tx_st3_chnum                (  ed_tx_st3_chnum                     ),
        .tx_st3_empty                (  ed_tx_st3_empty                     ),
        .tx_st3_misc_parity          (  ed_tx_st3_misc_parity               )
        );                                                                  


//Passthrough User can implement the AFU logic here 
//


    // query rate CDC
    bus_synchronizer #(
      .SIGNAL_WIDTH(32)
    ) bus_synchronizer_page_query_rate_inst (
      .clk      (ip2hdm_clk),
      .data_in  (page_query_rate_aclk),
      .data_out (page_query_rate_eclk)
    );

    bus_synchronizer #(
      .SIGNAL_WIDTH(32)
    ) bus_synchronizer_cache_query_rate_inst (
      .clk      (ip2hdm_clk),
      .data_in  (cache_query_rate_aclk),
      .data_out (cache_query_rate_eclk)
    );
    
    // page_mig_addr CDC
    fifo_28w_16d afu_to_csr_cdc_fifo_inst (
      .data   (page_mig_addr_eclk),
      .wrreq  (page_mig_addr_en_eclk),
      .rdreq  (1'b1),
      .wrclk  (ip2hdm_clk),
      .rdclk  (ip2csr_avmm_clk),
      .q      (page_mig_addr_aclk),
      .rdempty(page_cdc_fifo_rdempty),
      .wrfull ()
    );

    // cache_mig_addr CDC
    // eclk = 400MHz
    // aclk = 125MHz
    fifo_28w_16d cache_mig_cdc_fifo_inst (
      .data   (cache_mig_addr_eclk),
      .wrreq  (cache_mig_addr_en_eclk),
      .rdreq  (1'b1),
      .wrclk  (ip2hdm_clk),
      .rdclk  (ip2csr_avmm_clk),
      .q      (cache_mig_addr_aclk),
      .rdempty(cache_cdc_fifo_rdempty),
      .wrfull ()
    );

    always_ff @( posedge ip2csr_avmm_clk ) begin 
      page_mig_addr_en_aclk <= ~page_cdc_fifo_rdempty;
      cache_mig_addr_en_aclk <= ~cache_cdc_fifo_rdempty;
    end

    // page_mig_addr_en CDC. First stretch, then go through a synchronizer.
    // stretcher #(
    //   .STRETCH_LENGTH(5),
    //   .SIGNAL_WIDTH(1)
    // ) stretcher_page_mig_en_inst (
    //   .clk        (ip2hdm_clk),
    //   .signal_in  (page_mig_addr_en_eclk),
    //   .signal_out (page_mig_addr_en_stretch)
    // );

    // altera_std_synchronizer_nocut #(
    //     .depth(3)
    // ) synchronizer_page_mig_en_inst (
    //     .clk            (ip2csr_avmm_clk),
    //     .reset_n        (1'b1),
    //     .din            (page_mig_addr_en_stretch),
    //     .dout           (page_mig_addr_en_aclk)
    // );
    

    // page_mig_addr CDC. First stretch, then go through a bus synchronizer
    // stretcher #(
    //   .STRETCH_LENGTH(5),
    //   .SIGNAL_WIDTH(28)
    // ) stretcher_page_mig_addr_inst (
    //   .clk        (ip2hdm_clk),
    //   .signal_in  (page_mig_addr_eclk),
    //   .signal_out (page_mig_addr_stretch)
    // );

    // bus_synchronizer #(
    //   .SIGNAL_WIDTH(28)
    // ) bus_synchronizer_page_mig_addr_inst (
    //   .clk      (ip2csr_avmm_clk),
    //   .data_in  (page_mig_addr_stretch),
    //   .data_out (page_mig_addr_aclk)
    // );

  //-------------------------------------------------------
  // PF1 BAR2 example CSR                                --
  //-------------------------------------------------------

csr_top csr_top_inst (
    .csr_avmm_clk                        ( ip2csr_avmm_clk                   ),
    .csr_avmm_rstn                       ( ip2csr_avmm_rstn                  ),
    .csr_avmm_waitrequest                ( csr2ip_avmm_waitrequest           ),
    .csr_avmm_readdata                   ( csr2ip_avmm_readdata              ),
    .csr_avmm_readdatavalid              ( csr2ip_avmm_readdatavalid         ),
    .csr_avmm_writedata                  ( ip2csr_avmm_writedata             ),
    .csr_avmm_address                    ( ip2csr_avmm_address               ),
    .csr_avmm_write                      ( ip2csr_avmm_write                 ),
    .csr_avmm_read                       ( ip2csr_avmm_read                  ),
    .csr_avmm_byteenable                 ( ip2csr_avmm_byteenable            ),

    .afu_clk                             ( ip2hdm_clk                         ),
    .afu_reset_n                         ( ip2hdm_reset_n_f ),
    .cxlip2iafu_read_eclk(ip2hdm_aximm0_arvalid & hdm2ip_aximm0_arready),
    .cxlip2iafu_write_eclk(ip2hdm_aximm0_wvalid & hdm2ip_aximm0_wready),

    .page_query_rate   (page_query_rate_aclk),
    .cache_query_rate  (cache_query_rate_aclk),
    .cxl_start_pa      (cxl_start_pa),
    .cxl_addr_offset   (cxl_addr_offset),
    .page_mig_addr_en  (page_mig_addr_en_aclk),
    .page_mig_addr     (page_mig_addr_aclk),
    .cache_mig_addr_en (cache_mig_addr_en_aclk),
    .cache_mig_addr     (cache_mig_addr_aclk),

    // specialized signals, 
    .is_writing_back                     ( is_writing_back ),
    .csr_zero_out                        ( csr_zero_out ),
    .csr_write_back                      ( csr_write_back ),
    .write_back_addr                     ( write_back_addr ),
    .csr_write_back_cnt                  ( csr_write_back_cnt ),
    .csr_monitor_region                  ( csr_monitor_region ),
    .csr_ofw_buf_tail_max                ( csr_ofw_buf_tail_max ),

    // MODIFIED by Vinit
    .csr_awuser           (csr_awuser),
    .csr_ofw_buf_head     (csr_ofw_buf_head),
    .csr_ofw_buf_vld_cnt  (csr_ofw_buf_vld_cnt)
);
//  ex_default_csr_top ex_default_csr_top_inst(
//     .csr_avmm_clk                        ( ip2csr_avmm_clk                   ),
//     .csr_avmm_rstn                       ( ip2csr_avmm_rstn                  ),
//     .csr_avmm_waitrequest                ( csr2ip_avmm_waitrequest           ),
//     .csr_avmm_readdata                   ( csr2ip_avmm_readdata              ),
//     .csr_avmm_readdatavalid              ( csr2ip_avmm_readdatavalid         ),
//     .csr_avmm_writedata                  ( ip2csr_avmm_writedata             ),
//     .csr_avmm_poison                     ( ip2csr_avmm_poison                ),
//     .csr_avmm_address                    ( ip2csr_avmm_address               ),
//     .csr_avmm_write                      ( ip2csr_avmm_write                 ),
//     .csr_avmm_read                       ( ip2csr_avmm_read                  ),
//     .csr_avmm_byteenable                 ( ip2csr_avmm_byteenable            )
//  );


m5_ctrl m5_ctrl_inst(
    .clk    ( ip2hdm_clk ),
    .rstn   ( ip2hdm_reset_n_f ), 

    .page_query_rate (page_query_rate_eclk),
    .cache_query_rate (cache_query_rate_eclk),
    .mem_chan_rd_en   (mem_chan_rd_en),

    // hot cache tracker interface
    .cache_query_en             (cache_query_en),
    .cache_query_ready          (cache_query_ready),
    .cache_mig_addr_en          (cache_mig_addr_en_eclk),
    .cache_mig_addr             (cache_mig_addr_eclk),
    .cache_mig_addr_ready       (cache_mig_addr_ready),

    // hot page tracker interface
    .page_query_en              (page_query_en),
    .page_query_ready           (page_query_ready),
    .page_mig_addr_en           (page_mig_addr_en_eclk),
    .page_mig_addr              (page_mig_addr_eclk),
    .page_mig_addr_ready        (page_mig_addr_ready)
);


 afu_top afu_top_inst(
    .afu_clk                             ( ip2hdm_clk                         ),
    .afu_rstn                            ( ip2hdm_reset_n_f                      ),

    // hot page tracker interface
    .cache_query_en             (cache_query_en),
    .cache_query_ready          (cache_query_ready),
    .cache_mig_addr_en          (cache_mig_addr_en_eclk),
    .cache_mig_addr             (cache_mig_addr_eclk),
    .cache_mig_addr_ready       (cache_mig_addr_ready),

    // hot cache tracker interface
    .page_query_en              (page_query_en),
    .page_query_ready           (page_query_ready),
    .page_mig_addr_en           (page_mig_addr_en_eclk),
    .page_mig_addr              (page_mig_addr_eclk),
    .page_mig_addr_ready        (page_mig_addr_ready),
    .mem_chan_rd_en             (mem_chan_rd_en),
    .csr_addr_ub                (csr_addr_ub),
    .csr_addr_lb                (csr_addr_lb),


//`ifdef OOORSP_MC_AXI2AVMM // April 2023 - Supporting out of order responses with AXI4
       .cxlip2iafu_to_mc_axi4            ( cxlip2iafu_to_mc_axi4    ), //( cxlip2iafu_to_mc_axi4[(2*chanCount+ONE_OR_ZERO):(2*chanCount)]    ), //cxlip2iafu_to_mc_axi4 
       .iafu2mc_to_mc_axi4               ( iafu2mc_to_mc_axi4       ), //( cxlip2iafu_to_mc_axi4[(2*chanCount+ONE_OR_ZERO):(2*chanCount)]    ), //cxlip2iafu_to_mc_axi4 
       .mc2iafu_from_mc_axi4             ( mc2iafu_from_mc_axi4     ), //( iafu2cxlip_from_mc_axi4[(2*chanCount+ONE_OR_ZERO):(2*chanCount)]  ), //iafu2cxlip_from_mc_axi4
       .iafu2cxlip_from_mc_axi4          ( iafu2cxlip_from_mc_axi4  )  //( iafu2cxlip_from_mc_axi4[(2*chanCount+ONE_OR_ZERO):(2*chanCount)]  ), //iafu2cxlip_from_mc_axi4
//`else
 );


//--------------------------------------------------------------------
// DDR Memory Controller Module
//--------------------------------------------------------------------

generate
for( genvar chanCount = 0; chanCount < cxlip_top_pkg::NUM_MC_TOP; chanCount=chanCount+1 )
begin : MC_CHANNEL_INST

localparam ONE_OR_ZERO     = 0;

`ifdef OOORSP_MC_NOCDCFIFOS
   mc_top_cfgCDCFifos
`else
   mc_top
`endif
#(
    .MC_CHANNEL               (cxlip_top_pkg::DDR_CHANNEL             ),
    .MC_HA_DDR4_ADDR_WIDTH    (cxlip_top_pkg::MC_HA_DDR4_ADDR_WIDTH   ),
    .MC_HA_DDR4_BA_WIDTH      (cxlip_top_pkg::MC_HA_DDR4_BA_WIDTH     ),
    .MC_HA_DDR4_BG_WIDTH      (cxlip_top_pkg::MC_HA_DDR4_BG_WIDTH     ),
    .MC_HA_DDR4_CK_WIDTH      (cxlip_top_pkg::MC_HA_DDR4_CK_WIDTH     ),
    .MC_HA_DDR4_CKE_WIDTH     (cxlip_top_pkg::MC_HA_DDR4_CKE_WIDTH    ),
    .MC_HA_DDR4_CS_WIDTH      (cxlip_top_pkg::MC_HA_DDR4_CS_WIDTH     ),
    .MC_HA_DDR4_ODT_WIDTH     (cxlip_top_pkg::MC_HA_DDR4_ODT_WIDTH    ),
    .MC_HA_DDR4_DQS_WIDTH     (cxlip_top_pkg::MC_HA_DDR4_DQS_WIDTH    ),
    .MC_HA_DDR4_DQ_WIDTH      (cxlip_top_pkg::MC_HA_DDR4_DQ_WIDTH     ),
    `ifdef ENABLE_DDR_DBI_PINS
    .MC_HA_DDR4_DBI_WIDTH     (cxlip_top_pkg::MC_HA_DDR4_DBI_WIDTH    ),
    `endif  
    .EMIF_AMM_ADDR_WIDTH      (cxlip_top_pkg::EMIF_AMM_ADDR_WIDTH     ),
    .EMIF_AMM_DATA_WIDTH      (cxlip_top_pkg::EMIF_AMM_DATA_WIDTH     ),
    .EMIF_AMM_BURST_WIDTH     (cxlip_top_pkg::EMIF_AMM_BURST_WIDTH    ),
    .EMIF_AMM_BE_WIDTH        (cxlip_top_pkg::EMIF_AMM_BE_WIDTH       ),
    .REG_ON_REQFIFO_INPUT_EN  (cxlip_top_pkg::REG_ON_REQFIFO_INPUT_EN ),
    .REG_ON_REQFIFO_OUTPUT_EN (cxlip_top_pkg::REG_ON_REQFIFO_OUTPUT_EN),
    .REG_ON_RSPFIFO_OUTPUT_EN (cxlip_top_pkg::REG_ON_RSPFIFO_OUTPUT_EN),
    .MC_HA_DP_ADDR_WIDTH      (cxlip_top_pkg::MC_HA_DP_ADDR_WIDTH     ),
    .MC_HA_DP_DATA_WIDTH      (cxlip_top_pkg::MC_HA_DP_DATA_WIDTH     ),
    .MC_ECC_EN                (cxlip_top_pkg::MC_ECC_EN               ),
    .MC_ECC_ENC_LATENCY       (cxlip_top_pkg::MC_ECC_ENC_LATENCY      ),
    .MC_ECC_DEC_LATENCY       (cxlip_top_pkg::MC_ECC_DEC_LATENCY      ),
    .MC_RAM_INIT_W_ZERO_EN    (cxlip_top_pkg::MC_RAM_INIT_W_ZERO_EN   ),
    .MEMSIZE_WIDTH            (cxlip_top_pkg::MEMSIZE_WIDTH           ),
    .FULL_ADDR_MSB            (cxlip_top_pkg::CXLIP_FULL_ADDR_MSB     ),
    .FULL_ADDR_LSB            (cxlip_top_pkg::CXLIP_FULL_ADDR_LSB     ),
    .CHAN_ADDR_MSB            (cxlip_top_pkg::CXLIP_CHAN_ADDR_MSB     ),
    .CHAN_ADDR_LSB            (cxlip_top_pkg::CXLIP_CHAN_ADDR_LSB     )
  )
  mc_top (
    .eclk                            (ip2hdm_clk),                        // input,  CXL-IP Slice clock
    .reset_n_eclk                    (ip2hdm_reset_n_ff),                    // input,  CXL-IP Slice reset_n

    .mc2ha_memsize                   (mc2ip_memsize_s[chanCount]),                        // output, Size (in bytes) of memory exposed to BIOS
    .mc_sr_status_eclk               (mc_sr_status_eclk[(2*chanCount+ONE_OR_ZERO):(2*chanCount)]          ),     // output, Memory Controller Status 
   
    `ifdef OOORSP_MC_NOCDCFIFOS
      .o_emif_usr_clk   ( emif_usr_clk[(2*chanCount+ONE_OR_ZERO):(2*chanCount)] ),
      .o_emif_usr_rst_n ( emif_usr_rst_n[(2*chanCount+ONE_OR_ZERO):(2*chanCount)] ),
    `endif
//`ifdef OOORSP_MC_AXI2AVMM // April 2023 - Supporting out of order responses with AXI4
       .iafu2mc_to_mc_axi4           ( iafu2mc_to_mc_axi4[(2*chanCount+ONE_OR_ZERO):(2*chanCount)]    ), //( cxlip2iafu_to_mc_axi4[(2*chanCount+ONE_OR_ZERO):(2*chanCount)]    ), //cxlip2iafu_to_mc_axi4 
       .mc2iafu_from_mc_axi4         ( mc2iafu_from_mc_axi4[(2*chanCount+ONE_OR_ZERO):(2*chanCount)]  ), //( iafu2cxlip_from_mc_axi4[(2*chanCount+ONE_OR_ZERO):(2*chanCount)]  ), //iafu2cxlip_from_mc_axi4
//`else
    
 //   .cxlmem_ready                    (mc2iafu_cxlmem_ready[(2*chanCount+ONE_OR_ZERO):(2*chanCount)]           ),
    .mc_err_cnt                      (mc_err_cnt[(2*chanCount+ONE_OR_ZERO):(2*chanCount)]     ), // output, SBE/DBE CNT

    // == DDR4 Interface ==
    .mem_refclk                      (mem_refclk[(2*chanCount+ONE_OR_ZERO):(2*chanCount)]                     ), // input,  EMIF PLL reference clock
    .mem_ck                          (mem_ck[(2*chanCount+ONE_OR_ZERO):(2*chanCount)]                         ), // output, DDR4 interface signals
    .mem_ck_n                        (mem_ck_n[(2*chanCount+ONE_OR_ZERO):(2*chanCount)]                       ), // output
    .mem_a                           (mem_a[(2*chanCount+ONE_OR_ZERO):(2*chanCount)]                          ), // output
    .mem_act_n                       (mem_act_n[(2*chanCount+ONE_OR_ZERO):(2*chanCount)]                      ), // output
    .mem_ba                          (mem_ba[(2*chanCount+ONE_OR_ZERO):(2*chanCount)]                         ), // output
    .mem_bg                          (mem_bg[(2*chanCount+ONE_OR_ZERO):(2*chanCount)]                         ), // output
    .mem_cke                         (mem_cke[(2*chanCount+ONE_OR_ZERO):(2*chanCount)]                        ), // output
    .mem_cs_n                        (mem_cs_n[(2*chanCount+ONE_OR_ZERO):(2*chanCount)]                       ), // output
    .mem_odt                         (mem_odt[(2*chanCount+ONE_OR_ZERO):(2*chanCount)]                        ), // output
    .mem_reset_n                     (mem_reset_n[(2*chanCount+ONE_OR_ZERO):(2*chanCount)]                    ), // output
    .mem_par                         (mem_par[(2*chanCount+ONE_OR_ZERO):(2*chanCount)]                        ), // output
    .mem_oct_rzqin                   (mem_oct_rzqin[(2*chanCount+ONE_OR_ZERO):(2*chanCount)]                  ), // input
    .mem_alert_n                     (mem_alert_n[(2*chanCount+ONE_OR_ZERO):(2*chanCount)]                    ), // input
    .mem_dqs                         (mem_dqs[(2*chanCount+ONE_OR_ZERO):(2*chanCount)]                        ), // inout
    .mem_dqs_n                       (mem_dqs_n[(2*chanCount+ONE_OR_ZERO):(2*chanCount)]                      ), // inout
    .mem_dq                          (mem_dq[(2*chanCount+ONE_OR_ZERO):(2*chanCount)]                         )  // inout
    `ifdef ENABLE_DDR_DBI_PINS
    ,.mem_dbi_n                      (mem_dbi_n[(2*chanCount+ONE_OR_ZERO):(2*chanCount)]                      )  // inout
    `endif

    ,.csr_zero_out        (csr_zero_out), // MODIFIED BY DOUGLAS
    .csr_write_back       (csr_write_back),
    .is_writing_back      (is_writing_back),
    .write_back_addr      (write_back_addr),
    .csr_write_back_cnt   (csr_write_back_cnt),
    .csr_monitor_region   (csr_monitor_region),
   // MODIFIED by Vinit
    .csr_awuser           (csr_awuser),
	  .csr_ofw_buf_head     (csr_ofw_buf_head),
    .csr_ofw_buf_vld_cnt  (csr_ofw_buf_vld_cnt),
    .csr_ofw_buf_tail_max (csr_ofw_buf_tail_max),

    // Clocks
    .axi4_mm_clk                           (ip2hdm_clk), 
    // Resets
    .axi4_mm_rst_n                         (ip2hdm_reset_n),

    // AXI-MM interface - write address channel
    .awid                                  (axi1_awid),
    .awaddr                                (axi1_awaddr), 
    .awlen                                 (axi1_awlen),
    .awsize                                (axi1_awsize),
    .awburst                               (axi1_awburst),
    .awprot                                (axi1_awprot),
    .awqos                                 (axi1_awqos),
    .awuser                                (axi1_awuser),
    .awvalid                               (axi1_awvalid),
    .awcache                               (axi1_awcache),
    .awlock                                (axi1_awlock),
    .awregion                              (axi1_awregion),
    .awatop                                (axi1_awatop),
    .awready                               (axi1_awready),
    
    // AXI-MM interface - write data channel
    .wdata                                 (axi1_wdata),
    .wstrb                                 (axi1_wstrb),
    .wlast                                 (axi1_wlast),
    .wuser                                 (axi1_wuser),
    .wvalid                                (axi1_wvalid),
    .wready                                (axi1_wready),
    
    //  AXI-MM interface - write response channel
    .bid                                  (axi1_bid),
    .bresp                                (axi1_bresp),
    .buser                                (axi1_buser),
    .bvalid                               (axi1_bvalid),
    .bready                               (axi1_bready),
    
    // AXI-MM interface - read address channel
    .arid                                  (axi1_arid),
    .araddr                                (axi1_araddr),
    .arlen                                 (axi1_arlen),
    .arsize                                (axi1_arsize),
    .arburst                               (axi1_arburst),
    .arprot                                (axi1_arprot),
    .arqos                                 (axi1_arqos),
    .aruser                                (axi1_aruser),
    .arvalid                               (axi1_arvalid),
    .arcache                               (axi1_arcache),
    .arlock                                (axi1_arlock),
    .arregion                              (axi1_arregion),
    .arready                               (axi1_arready),

    // AXI-MM interface - read response channel
    .rid                                   (axi1_rid),
    .rdata                                 (axi1_rdata),
    .rresp                                 (axi1_rresp),
    .rlast                                 (axi1_rlast),
    .ruser                                 (axi1_ruser),
    .rvalid                                (axi1_rvalid),
    .rready                                (axi1_rready)
  );  
end
endgenerate  


// MODIFIED BY DOUGLAS

//-------------------------------------------------------
// PF1 BAR2 example CSR                                --
//-------------------------------------------------------
csr_updater csr_updater_inst(
   .afu_clk                             ( ip2hdm_clk                        ),
   .afu_rstn                            ( ip2hdm_reset_n_f                  ),

   // mc side
   .mc2iafu_ready_eclk                  ( mc2iafu_ready_eclk                  ),
   .mc2iafu_read_poison_eclk            ( mc2iafu_read_poison_eclk            ),
   .mc2iafu_readdatavalid_eclk          ( mc2iafu_readdatavalid_eclk          ),
   .mc2iafu_ecc_err_corrected_eclk      ( mc2iafu_ecc_err_corrected_eclk      ),
   .mc2iafu_ecc_err_detected_eclk       ( mc2iafu_ecc_err_detected_eclk       ),
   .mc2iafu_ecc_err_fatal_eclk          ( mc2iafu_ecc_err_fatal_eclk          ),
   .mc2iafu_ecc_err_syn_e_eclk          ( mc2iafu_ecc_err_syn_e_eclk          ),
   .mc2iafu_ecc_err_valid_eclk          ( mc2iafu_ecc_err_valid_eclk          ),
   .mc2iafu_cxlmem_ready                ( mc2iafu_cxlmem_ready                ),
   .mc2iafu_readdata_eclk               ( mc2iafu_readdata_eclk               ),
   .mc2iafu_rsp_mdata_eclk              ( mc2iafu_rsp_mdata_eclk              ),

   // cxlip side
   .cxlip2iafu_writedata_eclk           ( cxlip2iafu_writedata_eclk           ), // TODO: These signals are outdated (should updated to AXI4)
   .cxlip2iafu_byteenable_eclk          ( cxlip2iafu_byteenable_eclk          ),
   .cxlip2iafu_read_eclk                ( ip2hdm_aximm0_arvalid                ),
   .cxlip2iafu_write_eclk               ( ip2hdm_aximm0_awvalid               ),
   .cxlip2iafu_write_poison_eclk        ( cxlip2iafu_write_poison_eclk        ),
   .cxlip2iafu_write_ras_sbe_eclk       ( cxlip2iafu_write_ras_sbe_eclk       ),    
   .cxlip2iafu_write_ras_dbe_eclk       ( cxlip2iafu_write_ras_dbe_eclk       ),    
   .cxlip2iafu_address_eclk             ( ip2hdm_aximm0_araddr                ),

   .cxlip2iafu_req_mdata_eclk           ( cxlip2iafu_req_mdata_eclk           ),

   .csr_avmm_write                      ( ip2csr_avmm_write                 ),
   .csr_avmm_read                       ( ip2csr_avmm_read                  ),
   .csr_avmm_address                    ( ip2csr_avmm_address               )
);

// the csr itself


endmodule
//------------------------------------------------------------------------------------
//
//
// End ed_top_wrapper_typ2.sv
//
//------------------------------------------------------------------------------------
//set foldmethod=marker
//set foldmarker=<<<,>>>

