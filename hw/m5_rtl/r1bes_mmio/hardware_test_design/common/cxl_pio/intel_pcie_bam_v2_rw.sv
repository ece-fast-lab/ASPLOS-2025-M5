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
//  Project Name:  avmm_bridge_1024_ed                                  
//  Module Name :  intel_pcie_bam_v2_rw.sv                                  
//  Author      :  klai4                                   
//  Date        :  Mon Jan 14, 2021                                 
//  Description :  This module interfaces with the input fifo on the scheduler interface and analyze the packet 
//                 (align the data on write, split the read request etc), 
//                 the request will be stored into the fifo first before sending to the AVMM interface to achieve the best performance on the AVMM side
//-----------------------------------------------------------------------------  


// synopsys translate_off
`timescale 1 ps / 1 ps
// synopsys translate_on

module intel_pcie_bam_v2_rw
  #(
    parameter PFNUM_WIDTH = 2,
    parameter VFNUM_WIDTH = 11,
    parameter BAM_DATAWIDTH = 1024
    )
  (
   input logic           clk,
   input logic           rst_n,

   
   output  logic        preproc_cmd_fifo_read_o,
   input logic [430:0]  preproc_cmd_fifo_data_i,
   input logic          preproc_cmd_fifo_empty_i,
   
   output logic          rx_data_fifo_rdreq_o, 
   input logic [BAM_DATAWIDTH-1:0]   rx_data_fifo_rdata_i,
   
   /*----- Completion CMD FIFO */
   input  logic          cpl_cmd_fifo_rdreq_i,
   output logic [80:0]   cpl_cmd_fifo_rddata_o,
   output logic          cpl_cmd_fifo_empty_o,

   /*----- AVMM Command FIFO interface ------------*/
   input logic           avmm_cmd_fifo_rdreq_i,
   output logic [214 :0] avmm_cmd_fifo_rddata_o,
   output  logic          avmm_cmd_fifo_empty_o,

   /*----- AVMM Data FIFO interface ----------*/
   input logic           avmm_writedata_rdreq_i, 
   output logic [BAM_DATAWIDTH+127 :0] avmm_writedata_o, 
   input  logic          rx_valid_eop_i,  
   
   input  logic [2:0]    max_payload_size_i,
   output logic [6:0]    bam_np_hdr_credit_o,
   
   output logic          write_done_o    
  );

  localparam [1:0]                      WR_IDLE       = 2'b00;
  localparam [1:0]                      WR_DATA       = 2'b01;
  localparam [1:0]                      WR_DATA_XTRA  = 2'b10;
  localparam [1:0]                      WR_CMD_XTRA   = 2'b11;
	
	  logic  [2:0] mps_reg1;       
	  logic  [2:0] mps_reg2;       
	  logic  srst_reg;       
    logic  mps_256_reg1;
    logic  mps_128_reg1;
	  logic  [1:0] wr_state;           
	  logic  [1:0] wr_nxt_state;  
    logic  wr_pop_cmd;          
    logic  xfr_state;      
    logic  xtra_state;     
    logic  xtra_wrcmd_state;
    logic  wr_idle_state;  
    logic  wr_data_state;  
    logic  buffer_data_rd_reg;  
    logic  wr_pop_cmd_reg; 
    logic  wr_pop_cmd_reg1;
    logic  wr_pop_cmd_reg2;
    logic  wr_pop_cmd_reg3;
    logic  wr_pop_cmd_reg4;  
    logic  xtra_wrcmd_reg; 
    logic  xtra_wrcmd_reg1;
    logic  xtra_wrcmd_reg2;
    logic  xtra_wrcmd_reg3;
    logic  xtra_wrcmd_reg4;
    
    
    logic  [63:0] avmm_address;     
    logic [127:0] avmm_fbe;         
    logic [127:0]  avmm_lbe;        
    logic [6:0] avmm_burst_cnt;  
    logic [2:0]  avmm_bar;         
    logic  avmm_write_trans;   
    logic  avmm_read_trans;    
    logic [11:0]   avmm_vfnum;       
    logic [1:0]  avmm_pfnum;      
    logic  avmm_vfactive;          
    logic [3:0] pcie_lines;        
    logic [9:0] tlp_rd_tag;        
    logic [15:0] tlp_rd_reqid;     
    logic [7:0] tlp_lower_addr;    
    logic [9:0] tlp_len;           
    logic [2:0] tlp_attr;          
    logic [2:0]  tlp_tc;           
    logic  rd_type1_exist;         
    logic [7:0]  rd_type1_size;    
    logic  rd_type2_exist;         
    logic [4:0]  rd_type2_num;     
    logic [6:0] rd_last_type2_size;
    logic [3:0] tlp_fbe;           
    logic [3:0] tlp_lbe;           
    logic [63:0] avmm_address_reg; 
    logic [127:0] avmm_fbe_reg;     
    logic [127:0] avmm_lbe_reg;    
    logic [3:0] avmm_burst_cnt_reg;
    logic [2:0] avmm_bar_reg;      
    logic  avmm_write_trans_reg;   
    logic [11:0] avmm_vfnum_reg;   
    logic [1:0] avmm_pfnum_reg;    
    logic  avmm_vfactive_reg;      
    logic [3:0] pcie_lines_reg;    
    logic  avmm_gt_pcie_reg;       
    logic [3:0]  avmm_burst_counter;
    logic [3:0]  avmm_burst_count_reg;         
    logic [3:0]  pcie_line_counter;
    logic [BAM_DATAWIDTH-1:0] data_reg1;  
    logic [BAM_DATAWIDTH-1:0]  holding_data_reg; 
    logic [31:0] data_reg1_dw0;
    logic [31:0] data_reg1_dw1;
    logic [31:0] data_reg1_dw2;
    logic [31:0] data_reg1_dw3;
    logic [31:0] data_reg1_dw4;
    logic [31:0] data_reg1_dw5;
    logic [31:0] data_reg1_dw6;
    logic [31:0] data_reg1_dw7;
    logic [31:0] data_reg1_dw8;
    logic [31:0] data_reg1_dw9;
    logic [31:0] data_reg1_dw10;
    logic [31:0] data_reg1_dw11;
    logic [31:0] data_reg1_dw12;
    logic [31:0] data_reg1_dw13;
    logic [31:0] data_reg1_dw14;
    logic [31:0] data_reg1_dw15;
    logic [31:0] data_reg1_dw16;
    logic [31:0] data_reg1_dw17;
    logic [31:0] data_reg1_dw18;
    logic [31:0] data_reg1_dw19;
    logic [31:0] data_reg1_dw20;
    logic [31:0] data_reg1_dw21;
    logic [31:0] data_reg1_dw22;
    logic [31:0] data_reg1_dw23;
    logic [31:0] data_reg1_dw24;
    logic [31:0] data_reg1_dw25;
    logic [31:0] data_reg1_dw26;
    logic [31:0] data_reg1_dw27;
    logic [31:0] data_reg1_dw28;
    logic [31:0] data_reg1_dw29;
    logic [31:0] data_reg1_dw30;
    logic [31:0] data_reg1_dw31;

    logic [31:0] hold_reg_dw0; 
    logic [31:0] hold_reg_dw1; 
    logic [31:0] hold_reg_dw2; 
    logic [31:0] hold_reg_dw3; 
    logic [31:0] hold_reg_dw4; 
    logic [31:0] hold_reg_dw5; 
    logic [31:0] hold_reg_dw6; 
    logic [31:0] hold_reg_dw7; 
    logic [31:0] hold_reg_dw8; 
    logic [31:0] hold_reg_dw9; 
    logic [31:0] hold_reg_dw10;
    logic [31:0] hold_reg_dw11;
    logic [31:0] hold_reg_dw12;
    logic [31:0] hold_reg_dw13;
    logic [31:0] hold_reg_dw14;
    logic [31:0] hold_reg_dw15;
    logic [31:0] hold_reg_dw16;
    logic [31:0] hold_reg_dw17;
    logic [31:0] hold_reg_dw18;
    logic [31:0] hold_reg_dw19;
    logic [31:0] hold_reg_dw20;
    logic [31:0] hold_reg_dw21;
    logic [31:0] hold_reg_dw22;
    logic [31:0] hold_reg_dw23;
    logic [31:0] hold_reg_dw24;
    logic [31:0] hold_reg_dw25;
    logic [31:0] hold_reg_dw26;
    logic [31:0] hold_reg_dw27;
    logic [31:0] hold_reg_dw28;
    logic [31:0] hold_reg_dw29;
    logic [31:0] hold_reg_dw30;
    logic [31:0] hold_reg_dw31;
    logic [31:0] data_mux_out0; 
    logic [31:0] data_mux_out1;  
    logic [31:0] data_mux_out2;  
    logic [31:0] data_mux_out3;  
    logic [31:0] data_mux_out4;  
    logic [31:0] data_mux_out5;  
    logic [31:0] data_mux_out6;  
    logic [31:0] data_mux_out7;  
    logic [31:0] data_mux_out8;  
    logic [31:0] data_mux_out9;  
    logic [31:0] data_mux_out10; 
    logic [31:0] data_mux_out11; 
    logic [31:0] data_mux_out12; 
    logic [31:0] data_mux_out13; 
    logic [31:0] data_mux_out14; 
    logic [31:0] data_mux_out15;
    logic [31:0] data_mux_out16;
    logic [31:0] data_mux_out17;
    logic [31:0] data_mux_out18;
    logic [31:0] data_mux_out19;
    logic [31:0] data_mux_out20;
    logic [31:0] data_mux_out21;
    logic [31:0] data_mux_out22;
    logic [31:0] data_mux_out23;
    logic [31:0] data_mux_out24;
    logic [31:0] data_mux_out25;
    logic [31:0] data_mux_out26;
    logic [31:0] data_mux_out27;
    logic [31:0] data_mux_out28;
    logic [31:0] data_mux_out29;
    logic [31:0] data_mux_out30;
    logic [31:0] data_mux_out31; 
    logic [31:0] data_mux_dw0_reg1; 	
    logic [31:0] data_mux_dw1_reg1; 	
    logic [31:0] data_mux_dw2_reg1; 	
    logic [31:0] data_mux_dw3_reg1; 	
    logic [31:0] data_mux_dw4_reg1; 	
    logic [31:0] data_mux_dw5_reg1; 	
    logic [31:0] data_mux_dw6_reg1; 	
    logic [31:0] data_mux_dw7_reg1; 	
    logic [31:0] data_mux_dw8_reg1; 	
    logic [31:0] data_mux_dw9_reg1; 	
    logic [31:0] data_mux_dw10_reg1;	
    logic [31:0] data_mux_dw11_reg1;	
    logic [31:0] data_mux_dw12_reg1;	
    logic [31:0] data_mux_dw13_reg1;	
    logic [31:0] data_mux_dw14_reg1;	
    logic [31:0] data_mux_dw15_reg1;
    logic [31:0] data_mux_dw16_reg1;
    logic [31:0] data_mux_dw17_reg1;
    logic [31:0] data_mux_dw18_reg1;
    logic [31:0] data_mux_dw19_reg1;
    logic [31:0] data_mux_dw20_reg1;
    logic [31:0] data_mux_dw21_reg1;
    logic [31:0] data_mux_dw22_reg1;
    logic [31:0] data_mux_dw23_reg1;
    logic [31:0] data_mux_dw24_reg1;
    logic [31:0] data_mux_dw25_reg1;
    logic [31:0] data_mux_dw26_reg1;
    logic [31:0] data_mux_dw27_reg1;
    logic [31:0] data_mux_dw28_reg1;
    logic [31:0] data_mux_dw29_reg1;
    logic [31:0] data_mux_dw30_reg1;
    logic [31:0] data_mux_dw31_reg1;	
    logic [31:0] data_mux_dw0_reg2; 	
    logic [31:0] data_mux_dw1_reg2; 	
    logic [31:0] data_mux_dw2_reg2; 	
    logic [31:0] data_mux_dw3_reg2; 	
    logic [31:0] data_mux_dw4_reg2; 	
    logic [31:0] data_mux_dw5_reg2; 	
    logic [31:0] data_mux_dw6_reg2; 	
    logic [31:0] data_mux_dw7_reg2; 	
    logic [31:0] data_mux_dw8_reg2; 	
    logic [31:0] data_mux_dw9_reg2; 	
    logic [31:0] data_mux_dw10_reg2;	
    logic [31:0] data_mux_dw11_reg2;	
    logic [31:0] data_mux_dw12_reg2;	
    logic [31:0] data_mux_dw13_reg2;	
    logic [31:0] data_mux_dw14_reg2;	
    logic [31:0] data_mux_dw15_reg2;	
    logic [31:0] data_mux_dw16_reg2;
    logic [31:0] data_mux_dw17_reg2;
    logic [31:0] data_mux_dw18_reg2;
    logic [31:0] data_mux_dw19_reg2;
    logic [31:0] data_mux_dw20_reg2;
    logic [31:0] data_mux_dw21_reg2;
    logic [31:0] data_mux_dw22_reg2;
    logic [31:0] data_mux_dw23_reg2;
    logic [31:0] data_mux_dw24_reg2;
    logic [31:0] data_mux_dw25_reg2;
    logic [31:0] data_mux_dw26_reg2;
    logic [31:0] data_mux_dw27_reg2;
    logic [31:0] data_mux_dw28_reg2;
    logic [31:0] data_mux_dw29_reg2;
    logic [31:0] data_mux_dw30_reg2;
    logic [31:0] data_mux_dw31_reg2;
    logic        wr_data_state_reg;
    logic        avmm_wren_reg1; 
    logic        avmm_wren_reg2; 
    logic        avmm_wren_reg3; 
    logic        avmm_wren_reg4; 
    logic [63:0] avmm_address_reg1; 
    logic [63:0] avmm_address_reg2; 
    logic [63:0] avmm_address_reg3; 
    logic [63:0] avmm_address_reg4; 
    logic [3:0]  avmm_burst_cnt_reg1; 
    logic [3:0]  avmm_burst_cnt_reg2; 
    logic [3:0]  avmm_burst_cnt_reg3; 
    logic [3:0]  avmm_burst_cnt_reg4; 
    logic [2:0] avmm_bar_reg1;    
    logic [2:0] avmm_bar_reg2;    
    logic [2:0] avmm_bar_reg3;    
    logic [2:0] avmm_bar_reg4;    
    logic [11:0] avmm_vfnum_reg1; 
    logic [11:0] avmm_vfnum_reg2; 
    logic [11:0] avmm_vfnum_reg3; 
    logic [11:0] avmm_vfnum_reg4; 
    logic [1:0] avmm_pfnum_reg1;  
    logic [1:0] avmm_pfnum_reg2;  
    logic [1:0] avmm_pfnum_reg3;  
    logic [1:0] avmm_pfnum_reg4;  
    logic  avmm_vfactive_reg1;    
    logic  avmm_vfactive_reg2;    
    logic  avmm_vfactive_reg3;    
    logic  avmm_vfactive_reg4;    
    logic  avmm_write_state_rise; 
    logic  first_wren_reg; 
    logic  last_wren_reg;  
    logic [(BAM_DATAWIDTH/8-1):0] first_avmm_mask_reg1; 
    logic [(BAM_DATAWIDTH/8-1):0] last_avmm_mask_reg1; 
    logic [(BAM_DATAWIDTH/8-1):0] avmm_be_reg2; 
    logic [(BAM_DATAWIDTH/8-1):0] avmm_be_reg3; 
    logic [(BAM_DATAWIDTH/8-1):0] avmm_be_reg4; 
    logic   [6:0]      bam_np_hdr_credit; 
    logic   [1:0]      lower_addr_offset_reg2; 

   localparam [2:0]    RD_IDLE           = 3'b000;   
   localparam [2:0]    RD_DECODE         = 3'b001;
   localparam [2:0]    RD_TYPE_1         = 3'b010;
	 localparam [2:0]    RD_TYPE_2_0       = 3'b011;                 
   localparam [2:0]    RD_TYPE_2_1       = 3'b100;
   localparam [2:0]    RD_TYPE_2_2       = 3'b101;                                                 
   localparam [2:0]    RD_TYPE_2_1_PIPE  = 3'b111;                                                 

   logic [2:0]  rd_state;             
   logic [2:0]  rd_nxt_state;      
   logic        rd_pop_cmd;    
   logic        decode_state_reg1;                 
   logic        type_1_state_reg1;                 
   logic        type_2_1_state_reg1;               
   logic        type_2_2_state_reg1;               
   logic        type_1_state_reg2; 
   logic        type_2_1_state_reg2; 
   logic        type_1_state_reg3; 
   logic        type_1_state_reg4; 
   logic        type_1_state_reg5; 
   logic        rd_exist_type_1_reg1;             
   logic        rd_exist_type_2_reg1;             
   logic [63:0] rd_avmm_address_reg1;             
   logic [7:0]  tlp_dw_size_type_1_reg1;    
   logic [6:0]  last_type_2_size_reg1;       
   logic [9:0]  tlp_dw_size_reg1;            
   logic [15:0] cpl_req_id_reg1;            
   logic [9:0]  rdreq_tag_reg1;              
   logic [11:0] cpl_vfnum_reg1;             
   logic [1:0]  cpl_pfnum_reg1;              
   logic        cpl_vfactive_reg1;                
   logic [9:0]  cpl_tag_reg1;               
   logic [2:0]  cpl_attr_reg1;              
   logic [2:0]  cpl_tc_reg1;                 
   logic [7:0]  cpl_lower_addr_reg1;         
   logic [3:0]  tlp_fbe_reg1;                
   logic [3:0]  tlp_lbe_reg1;  
   logic        tlp_lbe_zero_reg1;             
   logic [127:0] avmm_rd_fbe_reg1;           
   logic [127:0] avmm_rd_lbe_reg1;           
   logic [2:0]  avmm_rd_bar_reg1;            
   logic [4:0]  type_2_cntr; 
   logic        cpl_buff_ok_reg2;               
   logic        count_type_2_eq_one_reg1;       
   logic        count_type_2_eq_one_reg2;       
   logic        count_type_2_eq_one_reg3;       
   logic  [6:0]  last_type_2_size_reg2;          
   logic        rd_exist_type_1_reg2;           
   logic [5:0]  rd_avmm_address_reg2;      
   logic [5:0]  type_2_index_reg;
   logic 	      rd_type_1_cmd_valid_reg2; 
   logic 	      rd_type_1_cmd_valid_reg3; 
   logic 	      rd_type_1_cmd_valid_reg4; 
   logic 	      rd_type_2_cmd_valid_reg2; 
   logic 	      rd_type_2_cmd_valid_reg3; 
   logic 	      rd_type_2_cmd_valid_reg4; 
   logic 	      rd_cmd_valid_reg5;        
   logic [63:0] tlp_start_addr_arg0_reg2; 
   logic [8:0]  tlp_start_addr_arg1_reg2;
   logic [63:0] tlp_start_addr_reg3;  
   logic [63:0] tlp_start_addr_reg4; 
   logic [63:0] tlp_start_addr_reg5;  
   logic [7:0]  tlp_dw_size_type_1_reg2;   
   logic [7:0]  tlp_dw_size_type_1_reg3;        
   logic [7:0]  tlp_dw_size_type_1_reg4;        
   logic [7:0]  tlp_dw_size_type_1_reg5;        
   logic [7:0]  last_type_2_size_max_reg2;     
   logic [7:0]  tlp_dw_size_type_2_reg3;    
   logic [7:0]  tlp_dw_size_type_2_reg4;          
   logic [3:0]  avmm_read_lines_type_2_plus_reg4; 
   logic [7:0]  tlp_dw_size_type_reg5; 
   logic [7:0]  avmm_type_1_read_dw_reg3; 
   logic [3:0]  avmm_type_1_read_bcnt_reg4;
   logic [3:0]  avmm_type_2_read_bcnt_reg4;
   logic [3:0]  avmm_read_bcnt_reg5;
   logic [127:0] avmm_rd_be_reg2; 
   logic [127:0] avmm_rd_be_reg3; 
   logic [127:0] avmm_rd_be_reg4; 
   logic [127:0] avmm_rd_be_reg5; 
   logic [9:0]  cpl_tag_reg2; 
   logic [9:0]  cpl_tag_reg3; 
   logic [9:0]  cpl_tag_reg4; 
   logic [9:0]  cpl_tag_reg5; 
   logic        cpl_vfactive_reg2;   
   logic        cpl_vfactive_reg3; 
   logic        cpl_vfactive_reg4; 
   logic        cpl_vfactive_reg5; 
   logic [11:0] cpl_vfnum_reg2;
   logic [11:0] cpl_vfnum_reg3; 
   logic [11:0] cpl_vfnum_reg4; 
   logic [11:0] cpl_vfnum_reg5; 
   logic [1:0]  cpl_pfnum_reg2;    
   logic [1:0]  cpl_pfnum_reg3;    
   logic [1:0]  cpl_pfnum_reg4;    
   logic [1:0]  cpl_pfnum_reg5;    
   logic [15:0] cpl_req_id_reg2; 
   logic [15:0] cpl_req_id_reg3; 
   logic [15:0] cpl_req_id_reg4; 
   logic [15:0] cpl_req_id_reg5; 
   logic [2:0]  cpl_attr_reg2;    
   logic [2:0]  cpl_attr_reg3;    
   logic [2:0]  cpl_attr_reg4;    
   logic [2:0]  cpl_attr_reg5;    
   logic [2:0]  cpl_tc_reg2;   
   logic [2:0]  cpl_tc_reg3;   
   logic [2:0]  cpl_tc_reg4;   
   logic [2:0]  cpl_tc_reg5;   
   logic        rd_pop_cmd_reg1;    
   logic        rd_pop_cmd_reg2;    
   logic        rd_pop_cmd_reg3;    
   logic        rd_pop_cmd_reg4;    
   logic [2:0]  avmm_rd_bar_reg2;   
   logic [2:0]  avmm_rd_bar_reg3;   
   logic [2:0]  avmm_rd_bar_reg4;   
   logic [2:0]  avmm_rd_bar_reg5;   
   logic [1:0]  first_invalid_bytes_reg2; 
   logic [1:0]  last_invalid_bytes_reg2;
   logic [1:0]  last_invalid_bytes_reg3;
   logic [7:0]  cpl_lower_addr_reg3; 
   logic [7:0]  cpl_lower_addr_reg2; 
   logic [7:0]  cpl_lower_addr_reg4; 
   logic [7:0]  cpl_lower_addr_reg5; 
   logic [11:0] total_rd_bytes_reg3;
   logic [11:0] total_rd_bytes_reg4;
   logic [9:0]  tlp_bytes_size_type_1_reg3; 
   logic [9:0]  tlp_bytes_size_type_1_reg4; 
   logic [11:0] remain_bytes_reg5; 
   logic        avmm_rd; 
   logic [63:0] avmm_rd_address;  
   logic [3:0]  avmm_rd_burst_cnt; 
   logic [127:0] avmm_rd_be;
   logic [11:0] avmm_rd_vfnum;           
   logic [1:0]  avmm_rd_pfnum;
   logic        avmm_rd_vfactive;            
   logic [2:0]  avmm_rd_bar;   
   logic        avmm_wr; 
   logic [63:0] avmm_wr_address;
   logic [3:0]  avmm_wr_burst_cnt; 
   logic [127:0] avmm_wr_be;
   logic [11:0] avmm_wr_vfnum;   
   logic [1:0]  avmm_wr_pfnum;   
   logic        avmm_wr_vfactive;      
   logic [2:0]  avmm_wr_bar;     
   logic        cmd_is_write_reg;   
   logic [63:0] cmd_addr_reg; 
   logic [3:0]  cmd_bcnt_reg; 
   logic [127:0] cmd_be_reg;  
   logic [11:0] cmd_vfnum;    
   logic [1:0]  cmd_pfnum;     
   logic        cmd_vfactive;       
   logic        cmd_wrreq_reg;      
   logic [7:0]  cpl_cmd_dwlen;    
   logic [2:0]  cpl_attr;         
   logic [2:0]  cpl_tc;           
   logic [11:0] cpl_bytes_count;
   logic [7:0]  cpl_lower_address;
   logic [9:0]  cpl_tag;          
   logic [15:0] cpl_reqster;  
   logic        wrcmd_avail_reg;  
   logic        rdcmd_avail_reg;
   logic        cpl_buff_ok_reg1;
   logic        type_2_state_reg1;    
   logic        mps_128_reg2;
   logic        mps_256_reg2;       
   logic [63:0] avmm_fbe_reg1;
	 logic [63:0] avmm_lbe_reg1; 
	 logic [9:0]  tlp_dw_size_reg2;             
	 logic        rd_type_1_cmd_valid_reg5;
	 logic        rd_type_2_cmd_valid_reg5;                
	 logic [2:0]  cmd_bar;
	 logic [BAM_DATAWIDTH-1:0] avmm_writedata;
	 logic [(BAM_DATAWIDTH/8-1):0] avmm_be;
	 logic        avmm_writedata_wrreq;
   logic	       avmm_cmd_fifo_wrreq;      
   logic [214:0] avmm_cmd_fifo_data; 
   logic         cpl_cmd_almost_full;
   logic         avmm_cmd_almost_full;
   logic [80:0]  cpl_cmd;  
   logic         cpl_cmd_wrreq;                  
   logic [3:0]   avmm_lines_cnt;
	 logic [6:0]   avmm_rdburst_cnt_reg2; 
	 logic [6:0]  avmm_rdburst_cnt_reg1;
   logic [6:0]  avmm_rdburst_cnt_reg3 ;
   logic [6:0]  avmm_rdburst_cnt_reg4 ;
   logic [6:0]  avmm_rdburst_cnt_reg5 ;
   logic        flush_be;
   logic        flush_be_reg1; 
   logic        flush_be_reg2; 
   logic        flush_be_reg3; 
   logic        flush_be_reg4; 
   logic        flush_be_reg5;   
   logic [7:0]  eop_cntr;
   logic [15:0] cpl_vfpf;
   logic        cpl_vf_active;
   logic [63:0]  avmmwr_address_plus_8_reg1;
   logic [63:0]  avmmwr_address_plus_8_reg2;
   logic [63:0]  avmmwr_address_plus_8_reg3;
   logic         rd_first_type_2_cmd_valid_reg2;
   logic         rd_first_type_2_cmd_valid_reg3;
   logic         rd_first_type_2_cmd_valid_reg4;
   logic         rd_first_type_2_cmd_valid_reg5; 
   logic         first_type_2_sreg;     
	  
always_ff @(posedge clk) 
  begin
    mps_reg1[2:0]        <= max_payload_size_i[2:0];
    mps_reg2[2:0]        <= mps_reg1;
    srst_reg        <= ~rst_n;
  end 

assign mps_256_reg1 = (mps_reg2 == 3'b001);
assign mps_128_reg1 = (mps_reg2 == 3'b000);

always_ff @(posedge clk) 
  begin
    mps_128_reg2        <= mps_128_reg1;
    mps_256_reg2        <= mps_256_reg1;
  end 
always_ff @(posedge clk)
  if(srst_reg)
    eop_cntr[7:0] <= 8'h0;
  else if(rx_valid_eop_i & ~wr_pop_cmd)
    eop_cntr[7:0] <= eop_cntr[7:0] + 1'b1;
  else if(~rx_valid_eop_i & wr_pop_cmd)
    eop_cntr[7:0] <= eop_cntr[7:0] - 1'b1;

//// RX Write state Machine
 always_ff @(posedge clk)  
   begin
      wrcmd_avail_reg <= avmm_write_trans & ~preproc_cmd_fifo_empty_i & ~avmm_cmd_almost_full & eop_cntr[7:0] != 8'h0 & rd_state == RD_IDLE;
      rdcmd_avail_reg <= avmm_read_trans & ~preproc_cmd_fifo_empty_i & ~avmm_cmd_almost_full;
   end
   
 always_ff @(posedge clk) 
    if (srst_reg) 
      wr_state                   <= WR_IDLE;
   else 
      wr_state                   <= wr_nxt_state; 


  always_comb begin
    case(wr_state) 
      WR_IDLE     :  
        if(wrcmd_avail_reg & rd_state == RD_IDLE)
          wr_nxt_state = WR_DATA;
        else 
          wr_nxt_state = WR_IDLE;
          
      WR_DATA   : 
           if(avmm_gt_pcie_reg & pcie_line_counter == 4'b1)    
             wr_nxt_state = WR_DATA_XTRA;
           else if(pcie_line_counter == 4'b1)
             wr_nxt_state = WR_IDLE;
           else
             wr_nxt_state = WR_DATA;
      
       WR_DATA_XTRA: /// one more data cycle on AVMM bus
         if(avmm_burst_count_reg[3:0] <= 8)
           wr_nxt_state = WR_IDLE;
         else
           wr_nxt_state = WR_CMD_XTRA;
       
       WR_CMD_XTRA:   /// burst count 9
         wr_nxt_state = WR_IDLE;
         
       default:
         wr_nxt_state = WR_IDLE;
         
    endcase
end 
 assign wr_pop_cmd      = wr_idle_state & wrcmd_avail_reg & rd_state == RD_IDLE;     
 assign xfr_state       =  (wr_state == WR_DATA);
 assign xtra_state      =  (wr_state == WR_DATA_XTRA);
 assign xtra_wrcmd_state = (wr_state == WR_CMD_XTRA);
 assign wr_idle_state   =  (wr_state == WR_IDLE);
 assign wr_data_state   = xfr_state | xtra_state;
 
  always_ff @(posedge clk) 
     buffer_data_rd_reg  <= xfr_state;
     
  always_ff @(posedge clk)   
    begin
      xtra_wrcmd_reg <= xtra_wrcmd_state;  
      xtra_wrcmd_reg1 <= xtra_wrcmd_reg;
      xtra_wrcmd_reg2 <= xtra_wrcmd_reg1;
      xtra_wrcmd_reg3 <= xtra_wrcmd_reg2;
      xtra_wrcmd_reg4 <= xtra_wrcmd_reg3;
      
      wr_pop_cmd_reg <= wr_pop_cmd;
      wr_pop_cmd_reg1 <= wr_pop_cmd_reg;
      wr_pop_cmd_reg2 <= wr_pop_cmd_reg1;
      wr_pop_cmd_reg3 <= wr_pop_cmd_reg2;
      wr_pop_cmd_reg4 <= wr_pop_cmd_reg3;
      
    end
  
if(BAM_DATAWIDTH == 1024) begin
  assign avmm_address[63:0]       = preproc_cmd_fifo_data_i[63:0];
  assign avmm_fbe[127:0]           = preproc_cmd_fifo_data_i[191:64];
  assign avmm_lbe[127:0]           = preproc_cmd_fifo_data_i[319:192];
  assign avmm_burst_cnt[6:0]      = preproc_cmd_fifo_data_i[326:320];
  assign avmm_bar[2:0]            = preproc_cmd_fifo_data_i[329:327];
  assign avmm_write_trans         = preproc_cmd_fifo_data_i[330];
  assign avmm_read_trans          = preproc_cmd_fifo_data_i[430];
  assign avmm_vfnum[11:0]         = preproc_cmd_fifo_data_i[342:331];
  assign avmm_pfnum[1:0]          = preproc_cmd_fifo_data_i[344:343];
  assign avmm_vfactive            = preproc_cmd_fifo_data_i[345];
  assign pcie_lines[3:0]          = preproc_cmd_fifo_data_i[349:346];
  assign tlp_rd_tag[9:0]          = preproc_cmd_fifo_data_i[359:350];
  assign tlp_rd_reqid[15:0]       = preproc_cmd_fifo_data_i[375:360];
  assign tlp_lower_addr[7:0]      = avmm_address[7:0]; // [254:248]
  assign tlp_len[9:0]             = preproc_cmd_fifo_data_i[392:383];
  assign tlp_attr[2:0]            = preproc_cmd_fifo_data_i[395:393];
  assign tlp_tc[2:0]              = preproc_cmd_fifo_data_i[398:396];
  assign rd_type1_exist           = preproc_cmd_fifo_data_i[399];
  assign rd_type1_size[7:0]       = preproc_cmd_fifo_data_i[407:400];
  assign rd_type2_exist           = preproc_cmd_fifo_data_i[408];
  assign rd_type2_num[4:0]        = preproc_cmd_fifo_data_i[413:409];
  assign rd_last_type2_size[6:0]  = preproc_cmd_fifo_data_i[420:414];
  assign tlp_fbe[3:0]             = preproc_cmd_fifo_data_i[424:421];
  assign tlp_lbe[3:0]             = preproc_cmd_fifo_data_i[428:425];
  assign flush_be                 = preproc_cmd_fifo_data_i[429];
end else if(BAM_DATAWIDTH == 512) begin
  assign avmm_address[63:0]       = preproc_cmd_fifo_data_i[63:0];
  assign avmm_fbe[63:0]           = preproc_cmd_fifo_data_i[127:64];
  assign avmm_lbe[63:0]           = preproc_cmd_fifo_data_i[191:128];
  assign avmm_burst_cnt[6:0]      = preproc_cmd_fifo_data_i[198:192];
  assign avmm_bar[2:0]            = preproc_cmd_fifo_data_i[201:199];
  assign avmm_write_trans         = preproc_cmd_fifo_data_i[202];
  assign avmm_read_trans          = preproc_cmd_fifo_data_i[302];
  assign avmm_vfnum[11:0]         = preproc_cmd_fifo_data_i[214:203];
  assign avmm_pfnum[1:0]          = preproc_cmd_fifo_data_i[216:215];
  assign avmm_vfactive            = preproc_cmd_fifo_data_i[217];
  assign pcie_lines[3:0]          = preproc_cmd_fifo_data_i[221:218];
  assign tlp_rd_tag[9:0]          = preproc_cmd_fifo_data_i[231:222];
  assign tlp_rd_reqid[15:0]       = preproc_cmd_fifo_data_i[247:232];
  assign tlp_lower_addr[7:0]      = avmm_address[7:0]; // [254:248]
  assign tlp_len[9:0]             = preproc_cmd_fifo_data_i[264:255];
  assign tlp_attr[2:0]            = preproc_cmd_fifo_data_i[267:265];
  assign tlp_tc[2:0]              = preproc_cmd_fifo_data_i[270:268];
  assign rd_type1_exist           = preproc_cmd_fifo_data_i[271];
  assign rd_type1_size[7:0]       = preproc_cmd_fifo_data_i[279:272];
  assign rd_type2_exist           = preproc_cmd_fifo_data_i[280];
  assign rd_type2_num[4:0]        = preproc_cmd_fifo_data_i[285:281];
  assign rd_last_type2_size[6:0]  = preproc_cmd_fifo_data_i[292:286];
  assign tlp_fbe[3:0]             = preproc_cmd_fifo_data_i[296:293];
  assign tlp_lbe[3:0]             = preproc_cmd_fifo_data_i[300:297];
  assign flush_be                 = preproc_cmd_fifo_data_i[301];
end else if(BAM_DATAWIDTH == 256) begin
  assign avmm_address[63:0]       = preproc_cmd_fifo_data_i[63:0];
  assign avmm_fbe[31:0]           = preproc_cmd_fifo_data_i[95:64];
  assign avmm_lbe[31:0]           = preproc_cmd_fifo_data_i[127:96];
  assign avmm_burst_cnt[6:0]      = preproc_cmd_fifo_data_i[134:128];
  assign avmm_bar[2:0]            = preproc_cmd_fifo_data_i[137:135];
  assign avmm_write_trans         = preproc_cmd_fifo_data_i[138];
  assign avmm_read_trans          = preproc_cmd_fifo_data_i[238];
  assign avmm_vfnum[11:0]         = preproc_cmd_fifo_data_i[150:139];
  assign avmm_pfnum[1:0]          = preproc_cmd_fifo_data_i[152:151];
  assign avmm_vfactive            = preproc_cmd_fifo_data_i[153];
  assign pcie_lines[3:0]          = preproc_cmd_fifo_data_i[157:154];
  assign tlp_rd_tag[9:0]          = preproc_cmd_fifo_data_i[167:158];
  assign tlp_rd_reqid[15:0]       = preproc_cmd_fifo_data_i[183:168];
  assign tlp_lower_addr[7:0]      = avmm_address[7:0]; // [254:248]
  assign tlp_len[9:0]             = preproc_cmd_fifo_data_i[200:191];
  assign tlp_attr[2:0]            = preproc_cmd_fifo_data_i[203:201];
  assign tlp_tc[2:0]              = preproc_cmd_fifo_data_i[206:204];
  assign rd_type1_exist           = preproc_cmd_fifo_data_i[207];
  assign rd_type1_size[7:0]       = preproc_cmd_fifo_data_i[215:208];
  assign rd_type2_exist           = preproc_cmd_fifo_data_i[216];
  assign rd_type2_num[4:0]        = preproc_cmd_fifo_data_i[221:217];
  assign rd_last_type2_size[6:0]  = preproc_cmd_fifo_data_i[228:222];
  assign tlp_fbe[3:0]             = preproc_cmd_fifo_data_i[232:229];
  assign tlp_lbe[3:0]             = preproc_cmd_fifo_data_i[236:233];
  assign flush_be                 = preproc_cmd_fifo_data_i[237];
end

// Latch cmd fifo info
 always_ff @ (posedge clk)
  if(wr_pop_cmd) /// latching the command out of idle
   begin
        avmm_address_reg[63:0]       <=      avmm_address[63:0];    
	if(BAM_DATAWIDTH == 1024) begin
          avmm_fbe_reg[127:0]           <=      flush_be? 128'h0 : avmm_fbe[127:0];
          avmm_lbe_reg[127:0]           <=      avmm_lbe[127:0];
	end else if(BAM_DATAWIDTH == 512) begin
	  avmm_fbe_reg[63:0]           <=      flush_be? 64'h0 : avmm_fbe[63:0];
          avmm_lbe_reg[63:0]           <=      avmm_lbe[63:0];
	end else if(BAM_DATAWIDTH == 256) begin
          avmm_fbe_reg[31:0]           <=      flush_be? 32'h0 : avmm_fbe[31:0];
          avmm_lbe_reg[31:0]           <=      avmm_lbe[31:0];
	end 
        avmm_bar_reg[2:0]            <=      avmm_bar[2:0];          
        avmm_write_trans_reg         <=      avmm_write_trans;           
        avmm_vfnum_reg[11:0]         <=      avmm_vfnum[11:0];       
        avmm_pfnum_reg[1:0]          <=      avmm_pfnum[1:0];        
        avmm_vfactive_reg            <=      avmm_vfactive;          
        pcie_lines_reg[3:0]          <=      pcie_lines[3:0];        
        avmm_gt_pcie_reg             <=      avmm_burst_cnt[3:0] > pcie_lines[3:0];
 end      
 
  always_ff @ (posedge clk)                                       
   if(wr_pop_cmd)                                              
     avmm_burst_counter[3:0] <= avmm_burst_cnt[3:0];             
   else if(wr_data_state)                                     
     avmm_burst_counter[3:0] <= avmm_burst_counter[3:0] - 1'b1;  
     
always_ff @ (posedge clk)                                       
   if(wr_pop_cmd)  
      avmm_burst_count_reg[3:0] <= avmm_burst_cnt[3:0];
  

assign fifo_rd = xfr_state;
 always_ff @ (posedge clk)
   if(wr_pop_cmd)
     pcie_line_counter[3:0] <= pcie_lines[3:0];
   else if(fifo_rd)
     pcie_line_counter[3:0] <= pcie_line_counter[3:0] - 1'b1;

//// Payload Data

  always_ff @ (posedge clk)  ///holding st data reg
     begin
     	 data_reg1[BAM_DATAWIDTH-1:0]        <=  rx_data_fifo_rdata_i[BAM_DATAWIDTH-1:0];  
       holding_data_reg[BAM_DATAWIDTH-1:0] <= data_reg1[BAM_DATAWIDTH-1:0];  
     end
     
  
	assign data_reg1_dw0 =  data_reg1[31:0];
    	assign data_reg1_dw1 =  data_reg1[63:32];
    	assign data_reg1_dw2 =  data_reg1[95:64];
    	assign data_reg1_dw3 =  data_reg1[127:96];
    	assign data_reg1_dw4 =  data_reg1[159:128];
    	assign data_reg1_dw5 =  data_reg1[191:160];
    	assign data_reg1_dw6 =  data_reg1[223:192];
    	assign data_reg1_dw7 =  data_reg1[255:224];
	assign hold_reg_dw0  = holding_data_reg[31:0];
    	assign hold_reg_dw1  = holding_data_reg[63:32];
    	assign hold_reg_dw2  = holding_data_reg[95:64];
    	assign hold_reg_dw3  = holding_data_reg[127:96];
    	assign hold_reg_dw4  = holding_data_reg[159:128];
    	assign hold_reg_dw5  = holding_data_reg[191:160];
    	assign hold_reg_dw6  = holding_data_reg[223:192];
    	assign hold_reg_dw7  = holding_data_reg[255:224];
  
    	if((BAM_DATAWIDTH == 512)||(BAM_DATAWIDTH == 1024)) begin
    		assign data_reg1_dw8 =  data_reg1[287:256];
	    	assign data_reg1_dw9 =  data_reg1[319:288];
    		assign data_reg1_dw10 = data_reg1[351:320];
    		assign data_reg1_dw11 = data_reg1[383:352];
    		assign data_reg1_dw12 = data_reg1[415:384];
    		assign data_reg1_dw13 = data_reg1[447:416];
   		assign data_reg1_dw14 = data_reg1[479:448];
    		assign data_reg1_dw15 = data_reg1[511:480];
		assign hold_reg_dw8  = holding_data_reg[287:256];
    		assign hold_reg_dw9  = holding_data_reg[319:288];
    		assign hold_reg_dw10 = holding_data_reg[351:320];
    		assign hold_reg_dw11 = holding_data_reg[383:352];
    		assign hold_reg_dw12 = holding_data_reg[415:384];
    		assign hold_reg_dw13 = holding_data_reg[447:416];
    		assign hold_reg_dw14 = holding_data_reg[479:448];
    		assign hold_reg_dw15 = holding_data_reg[511:480];
	end 
	if(BAM_DATAWIDTH == 1024) begin
                assign data_reg1_dw16 = data_reg1[543:512];
                assign data_reg1_dw17 = data_reg1[575:544];
                assign data_reg1_dw18 = data_reg1[607:576];
                assign data_reg1_dw19 = data_reg1[639:608];
                assign data_reg1_dw20 = data_reg1[671:640];
                assign data_reg1_dw21 = data_reg1[703:672];
                assign data_reg1_dw22 = data_reg1[735:704];
                assign data_reg1_dw23 = data_reg1[767:736];
		assign data_reg1_dw24 = data_reg1[799:768];
                assign data_reg1_dw25 = data_reg1[831:800];
                assign data_reg1_dw26 = data_reg1[863:832];
                assign data_reg1_dw27 = data_reg1[895:864];
                assign data_reg1_dw28 = data_reg1[927:896];
                assign data_reg1_dw29 = data_reg1[959:928];
                assign data_reg1_dw30 = data_reg1[991:960];
                assign data_reg1_dw31 = data_reg1[1023:992];
		assign hold_reg_dw16 = holding_data_reg[543:512];
                assign hold_reg_dw17 = holding_data_reg[575:544];
                assign hold_reg_dw18 = holding_data_reg[607:576];
                assign hold_reg_dw19 = holding_data_reg[639:608];
                assign hold_reg_dw20 = holding_data_reg[671:640];
                assign hold_reg_dw21 = holding_data_reg[703:672];
                assign hold_reg_dw22 = holding_data_reg[735:704];
                assign hold_reg_dw23 = holding_data_reg[767:736];
                assign hold_reg_dw24 = holding_data_reg[799:768];
                assign hold_reg_dw25 = holding_data_reg[831:800];
                assign hold_reg_dw26 = holding_data_reg[863:832];
                assign hold_reg_dw27 = holding_data_reg[895:864];
                assign hold_reg_dw28 = holding_data_reg[927:896];
                assign hold_reg_dw29 = holding_data_reg[959:928];
                assign hold_reg_dw30 = holding_data_reg[991:960];
                assign hold_reg_dw31 = holding_data_reg[1023:992];
        end
    	
    
     // Data Mux          
  if(BAM_DATAWIDTH == 256) begin
   always_comb
    case(avmm_address_reg2[4:2])
       3'b001:
         begin
	  data_mux_out0 =  hold_reg_dw7;
          data_mux_out1  = data_reg1_dw0;
          data_mux_out2  = data_reg1_dw1;
          data_mux_out3  = data_reg1_dw2;
          data_mux_out4  = data_reg1_dw3;
          data_mux_out5  = data_reg1_dw4;
          data_mux_out6  = data_reg1_dw5;
          data_mux_out7  = data_reg1_dw6;
	 end
     
       3'b010:
         begin
          data_mux_out0 =  hold_reg_dw6;
          data_mux_out1  = hold_reg_dw7;
          data_mux_out2  = data_reg1_dw0;
          data_mux_out3  = data_reg1_dw1;
          data_mux_out4  = data_reg1_dw2;
          data_mux_out5  = data_reg1_dw3;
          data_mux_out6  = data_reg1_dw4;
          data_mux_out7  = data_reg1_dw5;
         end

       3'b011:
         begin
          data_mux_out0 =  hold_reg_dw5;
          data_mux_out1  = hold_reg_dw6;
          data_mux_out2  = hold_reg_dw7;
          data_mux_out3  = data_reg1_dw0;
          data_mux_out4  = data_reg1_dw1;
          data_mux_out5  = data_reg1_dw2;
          data_mux_out6  = data_reg1_dw3;
          data_mux_out7  = data_reg1_dw4;
         end

       3'b100:
         begin
          data_mux_out0 =  hold_reg_dw4;
          data_mux_out1  = hold_reg_dw5;
          data_mux_out2  = hold_reg_dw6;
          data_mux_out3  = hold_reg_dw7;
          data_mux_out4  = data_reg1_dw0;
          data_mux_out5  = data_reg1_dw1;
          data_mux_out6  = data_reg1_dw2;
          data_mux_out7  = data_reg1_dw3;
         end

       3'b101:
         begin
          data_mux_out0 =  hold_reg_dw3;
          data_mux_out1  = hold_reg_dw4;
          data_mux_out2  = hold_reg_dw5;
          data_mux_out3  = hold_reg_dw6;
          data_mux_out4  = hold_reg_dw7;
          data_mux_out5  = data_reg1_dw0;
          data_mux_out6  = data_reg1_dw1;
          data_mux_out7  = data_reg1_dw2;
         end

       3'b110:
         begin
          data_mux_out0 =  hold_reg_dw2;
          data_mux_out1  = hold_reg_dw3;
          data_mux_out2  = hold_reg_dw4;
          data_mux_out3  = hold_reg_dw5;
          data_mux_out4  = hold_reg_dw6;
          data_mux_out5  = hold_reg_dw7;
          data_mux_out6  = data_reg1_dw0;
          data_mux_out7  = data_reg1_dw1;
         end

       3'b111:
         begin
          data_mux_out0 =  hold_reg_dw1;
          data_mux_out1  = hold_reg_dw2;
          data_mux_out2  = hold_reg_dw3;
          data_mux_out3  = hold_reg_dw4;
          data_mux_out4  = hold_reg_dw5;
          data_mux_out5  = hold_reg_dw6;
          data_mux_out6  = hold_reg_dw7;
          data_mux_out7  = data_reg1_dw0;
         end

       default:
         begin
          data_mux_out0 =  data_reg1_dw0;
          data_mux_out1  = data_reg1_dw1;
          data_mux_out2  = data_reg1_dw2;
          data_mux_out3  = data_reg1_dw3;
          data_mux_out4  = data_reg1_dw4;
          data_mux_out5  = data_reg1_dw5;
          data_mux_out6  = data_reg1_dw6;
          data_mux_out7  = data_reg1_dw7;
         end      
endcase

   always_ff @ (posedge clk)
    begin
     data_mux_dw0_reg1  <= data_mux_out0;
     data_mux_dw1_reg1  <= data_mux_out1;
     data_mux_dw2_reg1  <= data_mux_out2;
     data_mux_dw3_reg1  <= data_mux_out3;
     data_mux_dw4_reg1  <= data_mux_out4;
     data_mux_dw5_reg1  <= data_mux_out5;
     data_mux_dw6_reg1  <= data_mux_out6;
     data_mux_dw7_reg1  <= data_mux_out7;
    end

   always_ff @ (posedge clk)
    begin
     data_mux_dw0_reg2  <= data_mux_dw0_reg1;
     data_mux_dw1_reg2  <= data_mux_dw1_reg1;
     data_mux_dw2_reg2  <= data_mux_dw2_reg1;
     data_mux_dw3_reg2  <= data_mux_dw3_reg1;
     data_mux_dw4_reg2  <= data_mux_dw4_reg1;
     data_mux_dw5_reg2  <= data_mux_dw5_reg1;
     data_mux_dw6_reg2  <= data_mux_dw6_reg1;
     data_mux_dw7_reg2  <= data_mux_dw7_reg1;
    end

end



else if(BAM_DATAWIDTH == 512) begin 
   always_comb
    case(avmm_address_reg2[5:2])
       4'h1:
         begin 
          data_mux_out0 =  hold_reg_dw15;
          data_mux_out1  = data_reg1_dw0;  
          data_mux_out2  = data_reg1_dw1;  
          data_mux_out3  = data_reg1_dw2;  
          data_mux_out4  = data_reg1_dw3;  
          data_mux_out5  = data_reg1_dw4;  
          data_mux_out6  = data_reg1_dw5;  
          data_mux_out7  = data_reg1_dw6;  
          data_mux_out8  = data_reg1_dw7;  
          data_mux_out9  = data_reg1_dw8;  
          data_mux_out10 = data_reg1_dw9;  
          data_mux_out11 = data_reg1_dw10; 
          data_mux_out12 = data_reg1_dw11; 
          data_mux_out13 = data_reg1_dw12; 
          data_mux_out14 = data_reg1_dw13; 
          data_mux_out15 = data_reg1_dw14;            
        end
        
        
       4'h2:
         begin 
          data_mux_out0 =  hold_reg_dw14;
          data_mux_out1  = hold_reg_dw15;  
          data_mux_out2  = data_reg1_dw0; 
          data_mux_out3  = data_reg1_dw1; 
          data_mux_out4  = data_reg1_dw2; 
          data_mux_out5  = data_reg1_dw3; 
          data_mux_out6  = data_reg1_dw4; 
          data_mux_out7  = data_reg1_dw5; 
          data_mux_out8  = data_reg1_dw6; 
          data_mux_out9  = data_reg1_dw7; 
          data_mux_out10 = data_reg1_dw8; 
          data_mux_out11 = data_reg1_dw9; 
          data_mux_out12 = data_reg1_dw10;
          data_mux_out13 = data_reg1_dw11;
          data_mux_out14 = data_reg1_dw12;
          data_mux_out15 = data_reg1_dw13;           
        end      
           
      4'h3:
         begin 
          data_mux_out0 =  hold_reg_dw13;
          data_mux_out1  = hold_reg_dw14;  
          data_mux_out2  = hold_reg_dw15; 
          data_mux_out3  = data_reg1_dw0; 
          data_mux_out4  = data_reg1_dw1; 
          data_mux_out5  = data_reg1_dw2; 
          data_mux_out6  = data_reg1_dw3; 
          data_mux_out7  = data_reg1_dw4; 
          data_mux_out8  = data_reg1_dw5; 
          data_mux_out9  = data_reg1_dw6; 
          data_mux_out10 = data_reg1_dw7; 
          data_mux_out11 = data_reg1_dw8; 
          data_mux_out12 = data_reg1_dw9; 
          data_mux_out13 = data_reg1_dw10;
          data_mux_out14 = data_reg1_dw11;
          data_mux_out15 = data_reg1_dw12;          
        end              
           
       4'h4:
         begin 
          data_mux_out0 =  hold_reg_dw12;
          data_mux_out1  = hold_reg_dw13;  
          data_mux_out2  = hold_reg_dw14; 
          data_mux_out3  = hold_reg_dw15;
          data_mux_out4  = data_reg1_dw0; 
          data_mux_out5  = data_reg1_dw1; 
          data_mux_out6  = data_reg1_dw2; 
          data_mux_out7  = data_reg1_dw3; 
          data_mux_out8  = data_reg1_dw4; 
          data_mux_out9  = data_reg1_dw5; 
          data_mux_out10 = data_reg1_dw6; 
          data_mux_out11 = data_reg1_dw7; 
          data_mux_out12 = data_reg1_dw8; 
          data_mux_out13 = data_reg1_dw9; 
          data_mux_out14 = data_reg1_dw10;
          data_mux_out15 = data_reg1_dw11;          
        end                 
 
       4'h5:
         begin 
          data_mux_out0 =  hold_reg_dw11;
          data_mux_out1  = hold_reg_dw12;  
          data_mux_out2  = hold_reg_dw13; 
          data_mux_out3  = hold_reg_dw14;
          data_mux_out4  = hold_reg_dw15; 
          data_mux_out5  = data_reg1_dw0; 
          data_mux_out6  = data_reg1_dw1; 
          data_mux_out7  = data_reg1_dw2; 
          data_mux_out8  = data_reg1_dw3; 
          data_mux_out9  = data_reg1_dw4; 
          data_mux_out10 = data_reg1_dw5; 
          data_mux_out11 = data_reg1_dw6; 
          data_mux_out12 = data_reg1_dw7; 
          data_mux_out13 = data_reg1_dw8; 
          data_mux_out14 = data_reg1_dw9; 
          data_mux_out15 = data_reg1_dw10;          
        end              

       4'h6:
         begin 
          data_mux_out0 =  hold_reg_dw10; 
          data_mux_out1  = hold_reg_dw11; 
          data_mux_out2  = hold_reg_dw12; 
          data_mux_out3  = hold_reg_dw13; 
          data_mux_out4  = hold_reg_dw14; 
          data_mux_out5  = hold_reg_dw15; 
          data_mux_out6  = data_reg1_dw0; 
          data_mux_out7  = data_reg1_dw1; 
          data_mux_out8  = data_reg1_dw2; 
          data_mux_out9  = data_reg1_dw3; 
          data_mux_out10 = data_reg1_dw4; 
          data_mux_out11 = data_reg1_dw5; 
          data_mux_out12 = data_reg1_dw6; 
          data_mux_out13 = data_reg1_dw7; 
          data_mux_out14 = data_reg1_dw8; 
          data_mux_out15 = data_reg1_dw9;           
        end                
 
       4'h7:
         begin 
          data_mux_out0 =   hold_reg_dw9;
          data_mux_out1  =  hold_reg_dw10;
          data_mux_out2  =  hold_reg_dw11;
          data_mux_out3  =  hold_reg_dw12;
          data_mux_out4  =  hold_reg_dw13;
          data_mux_out5  =  hold_reg_dw14;
          data_mux_out6  =  hold_reg_dw15;
          data_mux_out7  =  data_reg1_dw0;     
          data_mux_out8  =  data_reg1_dw1;     
          data_mux_out9  =  data_reg1_dw2;     
          data_mux_out10 =  data_reg1_dw3;     
          data_mux_out11 =  data_reg1_dw4;     
          data_mux_out12 =  data_reg1_dw5;     
          data_mux_out13 =  data_reg1_dw6;     
          data_mux_out14 =  data_reg1_dw7;     
          data_mux_out15 =  data_reg1_dw8;          
        end                     
 
       4'h8:
         begin 
          data_mux_out0 =   hold_reg_dw8; 
          data_mux_out1  =  hold_reg_dw9;    
          data_mux_out2  =  hold_reg_dw10;  
          data_mux_out3  =  hold_reg_dw11;  
          data_mux_out4  =  hold_reg_dw12;  
          data_mux_out5  =  hold_reg_dw13;  
          data_mux_out6  =  hold_reg_dw14;  
          data_mux_out7  =  hold_reg_dw15;  
          data_mux_out8  =  data_reg1_dw0;       
          data_mux_out9  =  data_reg1_dw1;       
          data_mux_out10 =  data_reg1_dw2;       
          data_mux_out11 =  data_reg1_dw3;       
          data_mux_out12 =  data_reg1_dw4;       
          data_mux_out13 =  data_reg1_dw5;       
          data_mux_out14 =  data_reg1_dw6;       
          data_mux_out15 =  data_reg1_dw7;          
        end                    

       4'h9:
         begin 
          data_mux_out0  =  hold_reg_dw7;
          data_mux_out1  =  hold_reg_dw8;      
          data_mux_out2  =  hold_reg_dw9;      
          data_mux_out3  =  hold_reg_dw10;     
          data_mux_out4  =  hold_reg_dw11;     
          data_mux_out5  =  hold_reg_dw12;     
          data_mux_out6  =  hold_reg_dw13;     
          data_mux_out7  =  hold_reg_dw14;     
          data_mux_out8  =  hold_reg_dw15;     
          data_mux_out9  =  data_reg1_dw0;          
          data_mux_out10 =  data_reg1_dw1;          
          data_mux_out11 =  data_reg1_dw2;          
          data_mux_out12 =  data_reg1_dw3;          
          data_mux_out13 =  data_reg1_dw4;          
          data_mux_out14 =  data_reg1_dw5;          
          data_mux_out15 =  data_reg1_dw6;          
        end                         

       4'hA:
         begin 
          data_mux_out0  =  hold_reg_dw6;
          data_mux_out1  =  hold_reg_dw7;      
          data_mux_out2  =  hold_reg_dw8;      
          data_mux_out3  =  hold_reg_dw9;      
          data_mux_out4  =  hold_reg_dw10;     
          data_mux_out5  =  hold_reg_dw11;     
          data_mux_out6  =  hold_reg_dw12;     
          data_mux_out7  =  hold_reg_dw13;     
          data_mux_out8  =  hold_reg_dw14;     
          data_mux_out9  =  hold_reg_dw15;     
          data_mux_out10 =  data_reg1_dw0;          
          data_mux_out11 =  data_reg1_dw1;          
          data_mux_out12 =  data_reg1_dw2;          
          data_mux_out13 =  data_reg1_dw3;          
          data_mux_out14 =  data_reg1_dw4;          
          data_mux_out15 =  data_reg1_dw5;          
        end                        

       4'hB:
         begin 
          data_mux_out0  =  hold_reg_dw5;
          data_mux_out1  =  hold_reg_dw6;       
          data_mux_out2  =  hold_reg_dw7;       
          data_mux_out3  =  hold_reg_dw8;       
          data_mux_out4  =  hold_reg_dw9;       
          data_mux_out5  =  hold_reg_dw10;      
          data_mux_out6  =  hold_reg_dw11;      
          data_mux_out7  =  hold_reg_dw12;      
          data_mux_out8  =  hold_reg_dw13;      
          data_mux_out9  =  hold_reg_dw14;      
          data_mux_out10 =  hold_reg_dw15;      
          data_mux_out11 =  data_reg1_dw0;           
          data_mux_out12 =  data_reg1_dw1;           
          data_mux_out13 =  data_reg1_dw2;           
          data_mux_out14 =  data_reg1_dw3;           
          data_mux_out15 =  data_reg1_dw4;           
        end                          
 
       4'hC:
         begin 
          data_mux_out0  =  hold_reg_dw4;
          data_mux_out1  =  hold_reg_dw5;       
          data_mux_out2  =  hold_reg_dw6;       
          data_mux_out3  =  hold_reg_dw7;       
          data_mux_out4  =  hold_reg_dw8;       
          data_mux_out5  =  hold_reg_dw9;       
          data_mux_out6  =  hold_reg_dw10;      
          data_mux_out7  =  hold_reg_dw11;      
          data_mux_out8  =  hold_reg_dw12;      
          data_mux_out9  =  hold_reg_dw13;      
          data_mux_out10 =  hold_reg_dw14;      
          data_mux_out11 =  hold_reg_dw15;      
          data_mux_out12 =  data_reg1_dw0;           
          data_mux_out13 =  data_reg1_dw1;           
          data_mux_out14 =  data_reg1_dw2;           
          data_mux_out15 =  data_reg1_dw3;           
        end                       
                                                 
       4'hD:
         begin 
          data_mux_out0  =  hold_reg_dw3;
          data_mux_out1  =  hold_reg_dw4;       
          data_mux_out2  =  hold_reg_dw5;       
          data_mux_out3  =  hold_reg_dw6;       
          data_mux_out4  =  hold_reg_dw7;       
          data_mux_out5  =  hold_reg_dw8;       
          data_mux_out6  =  hold_reg_dw9;       
          data_mux_out7  =  hold_reg_dw10;      
          data_mux_out8  =  hold_reg_dw11;      
          data_mux_out9  =  hold_reg_dw12;      
          data_mux_out10 =  hold_reg_dw13;      
          data_mux_out11 =  hold_reg_dw14;      
          data_mux_out12 =  hold_reg_dw15;      
          data_mux_out13 =  data_reg1_dw0;           
          data_mux_out14 =  data_reg1_dw1;           
          data_mux_out15 =  data_reg1_dw2;           
        end                         
        
       4'hE:
         begin 
          data_mux_out0  =   hold_reg_dw2;
          data_mux_out1  =   hold_reg_dw3;      
          data_mux_out2  =   hold_reg_dw4;      
          data_mux_out3  =   hold_reg_dw5;      
          data_mux_out4  =   hold_reg_dw6;      
          data_mux_out5  =   hold_reg_dw7;      
          data_mux_out6  =   hold_reg_dw8;      
          data_mux_out7  =   hold_reg_dw9;      
          data_mux_out8  =   hold_reg_dw10;     
          data_mux_out9  =   hold_reg_dw11;     
          data_mux_out10 =   hold_reg_dw12;     
          data_mux_out11 =   hold_reg_dw13;     
          data_mux_out12 =   hold_reg_dw14;     
          data_mux_out13 =   hold_reg_dw15;     
          data_mux_out14 =   data_reg1_dw0;          
          data_mux_out15 =   data_reg1_dw1;          
        end                             
                
    
       4'hF:                                   
         begin                                 
          data_mux_out0  =  hold_reg_dw1; 
          data_mux_out1  =  hold_reg_dw2;        
          data_mux_out2  =  hold_reg_dw3;        
          data_mux_out3  =  hold_reg_dw4;        
          data_mux_out4  =  hold_reg_dw5;        
          data_mux_out5  =  hold_reg_dw6;        
          data_mux_out6  =  hold_reg_dw7;        
          data_mux_out7  =  hold_reg_dw8;        
          data_mux_out8  =  hold_reg_dw9;        
          data_mux_out9  =  hold_reg_dw10;       
          data_mux_out10 =  hold_reg_dw11;       
          data_mux_out11 =  hold_reg_dw12;       
          data_mux_out12 =  hold_reg_dw13;       
          data_mux_out13 =  hold_reg_dw14;       
          data_mux_out14 =  hold_reg_dw15;       
          data_mux_out15 =  data_reg1_dw0;            
        end                                     
                  
       default:
         begin
          data_mux_out0  =  data_reg1_dw0;    
          data_mux_out1  =  data_reg1_dw1;
          data_mux_out2  =  data_reg1_dw2;
          data_mux_out3  =  data_reg1_dw3;
          data_mux_out4  =  data_reg1_dw4;
          data_mux_out5  =  data_reg1_dw5;
          data_mux_out6  =  data_reg1_dw6;
          data_mux_out7  =  data_reg1_dw7;
          data_mux_out8  =  data_reg1_dw8;
          data_mux_out9  =  data_reg1_dw9;
          data_mux_out10 =  data_reg1_dw10;
          data_mux_out11 =  data_reg1_dw11;
          data_mux_out12 =  data_reg1_dw12;
          data_mux_out13 =  data_reg1_dw13;
          data_mux_out14 =  data_reg1_dw14;
          data_mux_out15 =  data_reg1_dw15;
         end
   endcase

    always_ff @ (posedge clk)
    begin
     data_mux_dw0_reg1  <= data_mux_out0;
     data_mux_dw1_reg1  <= data_mux_out1;
     data_mux_dw2_reg1  <= data_mux_out2;
     data_mux_dw3_reg1  <= data_mux_out3;
     data_mux_dw4_reg1  <= data_mux_out4;
     data_mux_dw5_reg1  <= data_mux_out5;
     data_mux_dw6_reg1  <= data_mux_out6;
     data_mux_dw7_reg1  <= data_mux_out7;
     data_mux_dw8_reg1  <= data_mux_out8;
     data_mux_dw9_reg1  <= data_mux_out9;
     data_mux_dw10_reg1 <= data_mux_out10;
     data_mux_dw11_reg1 <= data_mux_out11;
     data_mux_dw12_reg1 <= data_mux_out12;
     data_mux_dw13_reg1 <= data_mux_out13;
     data_mux_dw14_reg1 <= data_mux_out14;
     data_mux_dw15_reg1 <= data_mux_out15;
    end

    always_ff @ (posedge clk)
    begin
     data_mux_dw0_reg2  <= data_mux_dw0_reg1;
     data_mux_dw1_reg2  <= data_mux_dw1_reg1;
     data_mux_dw2_reg2  <= data_mux_dw2_reg1;
     data_mux_dw3_reg2  <= data_mux_dw3_reg1;
     data_mux_dw4_reg2  <= data_mux_dw4_reg1;
     data_mux_dw5_reg2  <= data_mux_dw5_reg1;
     data_mux_dw6_reg2  <= data_mux_dw6_reg1;
     data_mux_dw7_reg2  <= data_mux_dw7_reg1;
     data_mux_dw8_reg2  <= data_mux_dw8_reg1;
     data_mux_dw9_reg2  <= data_mux_dw9_reg1;
     data_mux_dw10_reg2 <= data_mux_dw10_reg1;
     data_mux_dw11_reg2 <= data_mux_dw11_reg1;
     data_mux_dw12_reg2 <= data_mux_dw12_reg1;
     data_mux_dw13_reg2 <= data_mux_dw13_reg1;
     data_mux_dw14_reg2 <= data_mux_dw14_reg1;
     data_mux_dw15_reg2 <= data_mux_dw15_reg1;
    end

  end

else if(BAM_DATAWIDTH == 1024) begin
   always_comb
    case(avmm_address_reg2[6:2])
       5'h1:
         begin
          data_mux_out0 =  hold_reg_dw31;
          data_mux_out1  = data_reg1_dw0;
          data_mux_out2  = data_reg1_dw1;
          data_mux_out3  = data_reg1_dw2;
          data_mux_out4  = data_reg1_dw3;
          data_mux_out5  = data_reg1_dw4;
          data_mux_out6  = data_reg1_dw5;
          data_mux_out7  = data_reg1_dw6;
          data_mux_out8  = data_reg1_dw7;
          data_mux_out9  = data_reg1_dw8;
          data_mux_out10 = data_reg1_dw9;
          data_mux_out11 = data_reg1_dw10;
          data_mux_out12 = data_reg1_dw11;
          data_mux_out13 = data_reg1_dw12;
          data_mux_out14 = data_reg1_dw13;
          data_mux_out15 = data_reg1_dw14;
          data_mux_out16 = data_reg1_dw15;
          data_mux_out17 = data_reg1_dw16;
          data_mux_out18 = data_reg1_dw17;
          data_mux_out19 = data_reg1_dw18;
          data_mux_out20 = data_reg1_dw19;
          data_mux_out21 = data_reg1_dw20;
          data_mux_out22 = data_reg1_dw21;
          data_mux_out23 = data_reg1_dw22;
          data_mux_out24 = data_reg1_dw23;
          data_mux_out25 = data_reg1_dw24;
          data_mux_out26 = data_reg1_dw25;
          data_mux_out27 = data_reg1_dw26;
          data_mux_out28 = data_reg1_dw27;
          data_mux_out29 = data_reg1_dw28;
          data_mux_out30 = data_reg1_dw29;
          data_mux_out31 = data_reg1_dw30;
        end

       5'h2:
         begin
          data_mux_out0 =  hold_reg_dw30;
          data_mux_out1  = hold_reg_dw31;
          data_mux_out2  = data_reg1_dw0;
          data_mux_out3  = data_reg1_dw1;
          data_mux_out4  = data_reg1_dw2;
          data_mux_out5  = data_reg1_dw3;
          data_mux_out6  = data_reg1_dw4;
          data_mux_out7  = data_reg1_dw5;
          data_mux_out8  = data_reg1_dw6;
          data_mux_out9  = data_reg1_dw7;
          data_mux_out10 = data_reg1_dw8;
          data_mux_out11 = data_reg1_dw9;
          data_mux_out12 = data_reg1_dw10;
          data_mux_out13 = data_reg1_dw11;
          data_mux_out14 = data_reg1_dw12;
          data_mux_out15 = data_reg1_dw13;
          data_mux_out16 = data_reg1_dw14;
          data_mux_out17 = data_reg1_dw15;
          data_mux_out18 = data_reg1_dw16;
          data_mux_out19 = data_reg1_dw17;
          data_mux_out20 = data_reg1_dw18;
          data_mux_out21 = data_reg1_dw19;
          data_mux_out22 = data_reg1_dw20;
          data_mux_out23 = data_reg1_dw21;
          data_mux_out24 = data_reg1_dw22;
          data_mux_out25 = data_reg1_dw23;
          data_mux_out26 = data_reg1_dw24;
          data_mux_out27 = data_reg1_dw25;
          data_mux_out28 = data_reg1_dw26;
          data_mux_out29 = data_reg1_dw27;
          data_mux_out30 = data_reg1_dw28;
          data_mux_out31 = data_reg1_dw29;
        end

       5'h3:
         begin
          data_mux_out0 =  hold_reg_dw29;
          data_mux_out1  = hold_reg_dw30;
          data_mux_out2  = hold_reg_dw31;
          data_mux_out3  = data_reg1_dw0;
          data_mux_out4  = data_reg1_dw1;
          data_mux_out5  = data_reg1_dw2;
          data_mux_out6  = data_reg1_dw3;
          data_mux_out7  = data_reg1_dw4;
          data_mux_out8  = data_reg1_dw5;
          data_mux_out9  = data_reg1_dw6;
          data_mux_out10 = data_reg1_dw7;
          data_mux_out11 = data_reg1_dw8;
          data_mux_out12 = data_reg1_dw9;
          data_mux_out13 = data_reg1_dw10;
          data_mux_out14 = data_reg1_dw11;
          data_mux_out15 = data_reg1_dw12;
          data_mux_out16 = data_reg1_dw13;
          data_mux_out17 = data_reg1_dw14;
          data_mux_out18 = data_reg1_dw15;
          data_mux_out19 = data_reg1_dw16;
          data_mux_out20 = data_reg1_dw17;
          data_mux_out21 = data_reg1_dw18;
          data_mux_out22 = data_reg1_dw19;
          data_mux_out23 = data_reg1_dw20;
          data_mux_out24 = data_reg1_dw21;
          data_mux_out25 = data_reg1_dw22;
          data_mux_out26 = data_reg1_dw23;
          data_mux_out27 = data_reg1_dw24;
          data_mux_out28 = data_reg1_dw25;
          data_mux_out29 = data_reg1_dw26;
          data_mux_out30 = data_reg1_dw27;
          data_mux_out31 = data_reg1_dw28;
        end

       5'h4:
         begin
          data_mux_out0 =  hold_reg_dw28;
          data_mux_out1  = hold_reg_dw29;
          data_mux_out2  = hold_reg_dw30;
          data_mux_out3  = hold_reg_dw31;
          data_mux_out4  = data_reg1_dw0;
          data_mux_out5  = data_reg1_dw1;
          data_mux_out6  = data_reg1_dw2;
          data_mux_out7  = data_reg1_dw3;
          data_mux_out8  = data_reg1_dw4;
          data_mux_out9  = data_reg1_dw5;
          data_mux_out10 = data_reg1_dw6;
          data_mux_out11 = data_reg1_dw7;
          data_mux_out12 = data_reg1_dw8;
          data_mux_out13 = data_reg1_dw9;
          data_mux_out14 = data_reg1_dw10;
          data_mux_out15 = data_reg1_dw11;
          data_mux_out16 = data_reg1_dw12;
          data_mux_out17 = data_reg1_dw13;
          data_mux_out18 = data_reg1_dw14;
          data_mux_out19 = data_reg1_dw15;
          data_mux_out20 = data_reg1_dw16;
          data_mux_out21 = data_reg1_dw17;
          data_mux_out22 = data_reg1_dw18;
          data_mux_out23 = data_reg1_dw19;
          data_mux_out24 = data_reg1_dw20;
          data_mux_out25 = data_reg1_dw21;
          data_mux_out26 = data_reg1_dw22;
          data_mux_out27 = data_reg1_dw23;
          data_mux_out28 = data_reg1_dw24;
          data_mux_out29 = data_reg1_dw25;
          data_mux_out30 = data_reg1_dw26;
          data_mux_out31 = data_reg1_dw27;
        end

       5'h5:
         begin
          data_mux_out0 =  hold_reg_dw27;
          data_mux_out1  = hold_reg_dw28;
          data_mux_out2  = hold_reg_dw29;
          data_mux_out3  = hold_reg_dw30;
          data_mux_out4  = hold_reg_dw31;
          data_mux_out5  = data_reg1_dw0;
          data_mux_out6  = data_reg1_dw1;
          data_mux_out7  = data_reg1_dw2;
          data_mux_out8  = data_reg1_dw3;
          data_mux_out9  = data_reg1_dw4;
          data_mux_out10 = data_reg1_dw5;
          data_mux_out11 = data_reg1_dw6;
          data_mux_out12 = data_reg1_dw7;
          data_mux_out13 = data_reg1_dw8;
          data_mux_out14 = data_reg1_dw9;
          data_mux_out15 = data_reg1_dw10;
          data_mux_out16 = data_reg1_dw11;
          data_mux_out17 = data_reg1_dw12;
          data_mux_out18 = data_reg1_dw13;
          data_mux_out19 = data_reg1_dw14;
          data_mux_out20 = data_reg1_dw15;
          data_mux_out21 = data_reg1_dw16;
          data_mux_out22 = data_reg1_dw17;
          data_mux_out23 = data_reg1_dw18;
          data_mux_out24 = data_reg1_dw19;
          data_mux_out25 = data_reg1_dw20;
          data_mux_out26 = data_reg1_dw21;
          data_mux_out27 = data_reg1_dw22;
          data_mux_out28 = data_reg1_dw23;
          data_mux_out29 = data_reg1_dw24;
          data_mux_out30 = data_reg1_dw25;
          data_mux_out31 = data_reg1_dw26;
        end

       5'h6:
         begin
          data_mux_out0 =  hold_reg_dw26;
          data_mux_out1  = hold_reg_dw27;
          data_mux_out2  = hold_reg_dw28;
          data_mux_out3  = hold_reg_dw29;
          data_mux_out4  = hold_reg_dw30;
          data_mux_out5  = hold_reg_dw31;
          data_mux_out6  = data_reg1_dw0;
          data_mux_out7  = data_reg1_dw1;
          data_mux_out8  = data_reg1_dw2;
          data_mux_out9  = data_reg1_dw3;
          data_mux_out10 = data_reg1_dw4;
          data_mux_out11 = data_reg1_dw5;
          data_mux_out12 = data_reg1_dw6;
          data_mux_out13 = data_reg1_dw7;
          data_mux_out14 = data_reg1_dw8;
          data_mux_out15 = data_reg1_dw9;
          data_mux_out16 = data_reg1_dw10;
          data_mux_out17 = data_reg1_dw11;
          data_mux_out18 = data_reg1_dw12;
          data_mux_out19 = data_reg1_dw13;
          data_mux_out20 = data_reg1_dw14;
          data_mux_out21 = data_reg1_dw15;
          data_mux_out22 = data_reg1_dw16;
          data_mux_out23 = data_reg1_dw17;
          data_mux_out24 = data_reg1_dw18;
          data_mux_out25 = data_reg1_dw19;
          data_mux_out26 = data_reg1_dw20;
          data_mux_out27 = data_reg1_dw21;
          data_mux_out28 = data_reg1_dw22;
          data_mux_out29 = data_reg1_dw23;
          data_mux_out30 = data_reg1_dw24;
          data_mux_out31 = data_reg1_dw25;
        end

       5'h7:
         begin
          data_mux_out0 =  hold_reg_dw25;
          data_mux_out1  = hold_reg_dw26;
          data_mux_out2  = hold_reg_dw27;
          data_mux_out3  = hold_reg_dw28;
          data_mux_out4  = hold_reg_dw29;
          data_mux_out5  = hold_reg_dw30;
          data_mux_out6  = hold_reg_dw31;
          data_mux_out7  = data_reg1_dw0;
          data_mux_out8  = data_reg1_dw1;
          data_mux_out9  = data_reg1_dw2;
          data_mux_out10 = data_reg1_dw3;
          data_mux_out11 = data_reg1_dw4;
          data_mux_out12 = data_reg1_dw5;
          data_mux_out13 = data_reg1_dw6;
          data_mux_out14 = data_reg1_dw7;
          data_mux_out15 = data_reg1_dw8;
          data_mux_out16 = data_reg1_dw9;
          data_mux_out17 = data_reg1_dw10;
          data_mux_out18 = data_reg1_dw11;
          data_mux_out19 = data_reg1_dw12;
          data_mux_out20 = data_reg1_dw13;
          data_mux_out21 = data_reg1_dw14;
          data_mux_out22 = data_reg1_dw15;
          data_mux_out23 = data_reg1_dw16;
          data_mux_out24 = data_reg1_dw17;
          data_mux_out25 = data_reg1_dw18;
          data_mux_out26 = data_reg1_dw19;
          data_mux_out27 = data_reg1_dw20;
          data_mux_out28 = data_reg1_dw21;
          data_mux_out29 = data_reg1_dw22;
          data_mux_out30 = data_reg1_dw23;
          data_mux_out31 = data_reg1_dw24;
        end

       5'h8:
         begin
          data_mux_out0 =  hold_reg_dw24;
          data_mux_out1  = hold_reg_dw25;
          data_mux_out2  = hold_reg_dw26;
          data_mux_out3  = hold_reg_dw27;
          data_mux_out4  = hold_reg_dw28;
          data_mux_out5  = hold_reg_dw29;
          data_mux_out6  = hold_reg_dw30;
          data_mux_out7  = hold_reg_dw31;
          data_mux_out8  = data_reg1_dw0;
          data_mux_out9  = data_reg1_dw1;
          data_mux_out10 = data_reg1_dw2;
          data_mux_out11 = data_reg1_dw3;
          data_mux_out12 = data_reg1_dw4;
          data_mux_out13 = data_reg1_dw5;
          data_mux_out14 = data_reg1_dw6;
          data_mux_out15 = data_reg1_dw7;
          data_mux_out16 = data_reg1_dw8;
          data_mux_out17 = data_reg1_dw9;
          data_mux_out18 = data_reg1_dw10;
          data_mux_out19 = data_reg1_dw11;
          data_mux_out20 = data_reg1_dw12;
          data_mux_out21 = data_reg1_dw13;
          data_mux_out22 = data_reg1_dw14;
          data_mux_out23 = data_reg1_dw15;
          data_mux_out24 = data_reg1_dw16;
          data_mux_out25 = data_reg1_dw17;
          data_mux_out26 = data_reg1_dw18;
          data_mux_out27 = data_reg1_dw19;
          data_mux_out28 = data_reg1_dw20;
          data_mux_out29 = data_reg1_dw21;
          data_mux_out30 = data_reg1_dw22;
          data_mux_out31 = data_reg1_dw23;
        end

       5'h9:
         begin
          data_mux_out0 =  hold_reg_dw23;
          data_mux_out1  = hold_reg_dw24;
          data_mux_out2  = hold_reg_dw25;
          data_mux_out3  = hold_reg_dw26;
          data_mux_out4  = hold_reg_dw27;
          data_mux_out5  = hold_reg_dw28;
          data_mux_out6  = hold_reg_dw29;
          data_mux_out7  = hold_reg_dw30;
          data_mux_out8  = hold_reg_dw31;
          data_mux_out9  = data_reg1_dw0;
          data_mux_out10 = data_reg1_dw1;
          data_mux_out11 = data_reg1_dw2;
          data_mux_out12 = data_reg1_dw3;
          data_mux_out13 = data_reg1_dw4;
          data_mux_out14 = data_reg1_dw5;
          data_mux_out15 = data_reg1_dw6;
          data_mux_out16 = data_reg1_dw7;
          data_mux_out17 = data_reg1_dw8;
          data_mux_out18 = data_reg1_dw9;
          data_mux_out19 = data_reg1_dw10;
          data_mux_out20 = data_reg1_dw11;
          data_mux_out21 = data_reg1_dw12;
          data_mux_out22 = data_reg1_dw13;
          data_mux_out23 = data_reg1_dw14;
          data_mux_out24 = data_reg1_dw15;
          data_mux_out25 = data_reg1_dw16;
          data_mux_out26 = data_reg1_dw17;
          data_mux_out27 = data_reg1_dw18;
          data_mux_out28 = data_reg1_dw19;
          data_mux_out29 = data_reg1_dw20;
          data_mux_out30 = data_reg1_dw21;
          data_mux_out31 = data_reg1_dw22;
        end

       5'hA:
         begin
          data_mux_out0 =  hold_reg_dw22;
          data_mux_out1  = hold_reg_dw23;
          data_mux_out2  = hold_reg_dw24;
          data_mux_out3  = hold_reg_dw25;
          data_mux_out4  = hold_reg_dw26;
          data_mux_out5  = hold_reg_dw27;
          data_mux_out6  = hold_reg_dw28;
          data_mux_out7  = hold_reg_dw29;
          data_mux_out8  = hold_reg_dw30;
          data_mux_out9  = hold_reg_dw31;
          data_mux_out10 = data_reg1_dw0;
          data_mux_out11 = data_reg1_dw1;
          data_mux_out12 = data_reg1_dw2;
          data_mux_out13 = data_reg1_dw3;
          data_mux_out14 = data_reg1_dw4;
          data_mux_out15 = data_reg1_dw5;
          data_mux_out16 = data_reg1_dw6;
          data_mux_out17 = data_reg1_dw7;
          data_mux_out18 = data_reg1_dw8;
          data_mux_out19 = data_reg1_dw9;
          data_mux_out20 = data_reg1_dw10;
          data_mux_out21 = data_reg1_dw11;
          data_mux_out22 = data_reg1_dw12;
          data_mux_out23 = data_reg1_dw13;
          data_mux_out24 = data_reg1_dw14;
          data_mux_out25 = data_reg1_dw15;
          data_mux_out26 = data_reg1_dw16;
          data_mux_out27 = data_reg1_dw17;
          data_mux_out28 = data_reg1_dw18;
          data_mux_out29 = data_reg1_dw19;
          data_mux_out30 = data_reg1_dw20;
          data_mux_out31 = data_reg1_dw21;
        end

       5'hB:
         begin
          data_mux_out0 =  hold_reg_dw21;
          data_mux_out1  = hold_reg_dw22;
          data_mux_out2  = hold_reg_dw23;
          data_mux_out3  = hold_reg_dw24;
          data_mux_out4  = hold_reg_dw25;
          data_mux_out5  = hold_reg_dw26;
          data_mux_out6  = hold_reg_dw27;
          data_mux_out7  = hold_reg_dw28;
          data_mux_out8  = hold_reg_dw29;
          data_mux_out9  = hold_reg_dw30;
          data_mux_out10 = hold_reg_dw31;
          data_mux_out11 = data_reg1_dw0;
          data_mux_out12 = data_reg1_dw1;
          data_mux_out13 = data_reg1_dw2;
          data_mux_out14 = data_reg1_dw3;
          data_mux_out15 = data_reg1_dw4;
          data_mux_out16 = data_reg1_dw5;
          data_mux_out17 = data_reg1_dw6;
          data_mux_out18 = data_reg1_dw7;
          data_mux_out19 = data_reg1_dw8;
          data_mux_out20 = data_reg1_dw9;
          data_mux_out21 = data_reg1_dw10;
          data_mux_out22 = data_reg1_dw11;
          data_mux_out23 = data_reg1_dw12;
          data_mux_out24 = data_reg1_dw13;
          data_mux_out25 = data_reg1_dw14;
          data_mux_out26 = data_reg1_dw15;
          data_mux_out27 = data_reg1_dw16;
          data_mux_out28 = data_reg1_dw17;
          data_mux_out29 = data_reg1_dw18;
          data_mux_out30 = data_reg1_dw19;
          data_mux_out31 = data_reg1_dw20;
        end

       5'hC:
         begin
          data_mux_out0 =  hold_reg_dw20;
          data_mux_out1  = hold_reg_dw21;
          data_mux_out2  = hold_reg_dw22;
          data_mux_out3  = hold_reg_dw23;
          data_mux_out4  = hold_reg_dw24;
          data_mux_out5  = hold_reg_dw25;
          data_mux_out6  = hold_reg_dw26;
          data_mux_out7  = hold_reg_dw27;
          data_mux_out8  = hold_reg_dw28;
          data_mux_out9  = hold_reg_dw29;
          data_mux_out10 = hold_reg_dw30;
          data_mux_out11 = hold_reg_dw31;
          data_mux_out12 = data_reg1_dw0;
          data_mux_out13 = data_reg1_dw1;
          data_mux_out14 = data_reg1_dw2;
          data_mux_out15 = data_reg1_dw3;
          data_mux_out16 = data_reg1_dw4;
          data_mux_out17 = data_reg1_dw5;
          data_mux_out18 = data_reg1_dw6;
          data_mux_out19 = data_reg1_dw7;
          data_mux_out20 = data_reg1_dw8;
          data_mux_out21 = data_reg1_dw9;
          data_mux_out22 = data_reg1_dw10;
          data_mux_out23 = data_reg1_dw11;
          data_mux_out24 = data_reg1_dw12;
          data_mux_out25 = data_reg1_dw13;
          data_mux_out26 = data_reg1_dw14;
          data_mux_out27 = data_reg1_dw15;
          data_mux_out28 = data_reg1_dw16;
          data_mux_out29 = data_reg1_dw17;
          data_mux_out30 = data_reg1_dw18;
          data_mux_out31 = data_reg1_dw19;
        end

       5'hD:
         begin
          data_mux_out0 =  hold_reg_dw19;
          data_mux_out1  = hold_reg_dw20;
          data_mux_out2  = hold_reg_dw21;
          data_mux_out3  = hold_reg_dw22;
          data_mux_out4  = hold_reg_dw23;
          data_mux_out5  = hold_reg_dw24;
          data_mux_out6  = hold_reg_dw25;
          data_mux_out7  = hold_reg_dw26;
          data_mux_out8  = hold_reg_dw27;
          data_mux_out9  = hold_reg_dw28;
          data_mux_out10 = hold_reg_dw29;
          data_mux_out11 = hold_reg_dw30;
          data_mux_out12 = hold_reg_dw31;
          data_mux_out13 = data_reg1_dw0;
          data_mux_out14 = data_reg1_dw1;
          data_mux_out15 = data_reg1_dw2;
          data_mux_out16 = data_reg1_dw3;
          data_mux_out17 = data_reg1_dw4;
          data_mux_out18 = data_reg1_dw5;
          data_mux_out19 = data_reg1_dw6;
          data_mux_out20 = data_reg1_dw7;
          data_mux_out21 = data_reg1_dw8;
          data_mux_out22 = data_reg1_dw9;
          data_mux_out23 = data_reg1_dw10;
          data_mux_out24 = data_reg1_dw11;
          data_mux_out25 = data_reg1_dw12;
          data_mux_out26 = data_reg1_dw13;
          data_mux_out27 = data_reg1_dw14;
          data_mux_out28 = data_reg1_dw15;
          data_mux_out29 = data_reg1_dw16;
          data_mux_out30 = data_reg1_dw17;
          data_mux_out31 = data_reg1_dw18;
        end

       5'hE:
         begin
          data_mux_out0 =  hold_reg_dw18;
          data_mux_out1  = hold_reg_dw19;
          data_mux_out2  = hold_reg_dw20;
          data_mux_out3  = hold_reg_dw21;
          data_mux_out4  = hold_reg_dw22;
          data_mux_out5  = hold_reg_dw23;
          data_mux_out6  = hold_reg_dw24;
          data_mux_out7  = hold_reg_dw25;
          data_mux_out8  = hold_reg_dw26;
          data_mux_out9  = hold_reg_dw27;
          data_mux_out10 = hold_reg_dw28;
          data_mux_out11 = hold_reg_dw29;
          data_mux_out12 = hold_reg_dw30;
          data_mux_out13 = hold_reg_dw31;
          data_mux_out14 = data_reg1_dw0;
          data_mux_out15 = data_reg1_dw1;
          data_mux_out16 = data_reg1_dw2;
          data_mux_out17 = data_reg1_dw3;
          data_mux_out18 = data_reg1_dw4;
          data_mux_out19 = data_reg1_dw5;
          data_mux_out20 = data_reg1_dw6;
          data_mux_out21 = data_reg1_dw7;
          data_mux_out22 = data_reg1_dw8;
          data_mux_out23 = data_reg1_dw9;
          data_mux_out24 = data_reg1_dw10;
          data_mux_out25 = data_reg1_dw11;
          data_mux_out26 = data_reg1_dw12;
          data_mux_out27 = data_reg1_dw13;
          data_mux_out28 = data_reg1_dw14;
          data_mux_out29 = data_reg1_dw15;
          data_mux_out30 = data_reg1_dw16;
          data_mux_out31 = data_reg1_dw17;
        end

       5'hF:
         begin
          data_mux_out0 =  hold_reg_dw17;
          data_mux_out1  = hold_reg_dw18;
          data_mux_out2  = hold_reg_dw19;
          data_mux_out3  = hold_reg_dw20;
          data_mux_out4  = hold_reg_dw21;
          data_mux_out5  = hold_reg_dw22;
          data_mux_out6  = hold_reg_dw23;
          data_mux_out7  = hold_reg_dw24;
          data_mux_out8  = hold_reg_dw25;
          data_mux_out9  = hold_reg_dw26;
          data_mux_out10 = hold_reg_dw27;
          data_mux_out11 = hold_reg_dw28;
          data_mux_out12 = hold_reg_dw29;
          data_mux_out13 = hold_reg_dw30;
          data_mux_out14 = hold_reg_dw31;
          data_mux_out15 = data_reg1_dw0;
          data_mux_out16 = data_reg1_dw1;
          data_mux_out17 = data_reg1_dw2;
          data_mux_out18 = data_reg1_dw3;
          data_mux_out19 = data_reg1_dw4;
          data_mux_out20 = data_reg1_dw5;
          data_mux_out21 = data_reg1_dw6;
          data_mux_out22 = data_reg1_dw7;
          data_mux_out23 = data_reg1_dw8;
          data_mux_out24 = data_reg1_dw9;
          data_mux_out25 = data_reg1_dw10;
          data_mux_out26 = data_reg1_dw11;
          data_mux_out27 = data_reg1_dw12;
          data_mux_out28 = data_reg1_dw13;
          data_mux_out29 = data_reg1_dw14;
          data_mux_out30 = data_reg1_dw15;
          data_mux_out31 = data_reg1_dw16;
        end

       5'h10:
         begin
          data_mux_out0 =  hold_reg_dw16;
          data_mux_out1  = hold_reg_dw17;
          data_mux_out2  = hold_reg_dw18;
          data_mux_out3  = hold_reg_dw19;
          data_mux_out4  = hold_reg_dw20;
          data_mux_out5  = hold_reg_dw21;
          data_mux_out6  = hold_reg_dw22;
          data_mux_out7  = hold_reg_dw23;
          data_mux_out8  = hold_reg_dw24;
          data_mux_out9  = hold_reg_dw25;
          data_mux_out10 = hold_reg_dw26;
          data_mux_out11 = hold_reg_dw27;
          data_mux_out12 = hold_reg_dw28;
          data_mux_out13 = hold_reg_dw29;
          data_mux_out14 = hold_reg_dw30;
          data_mux_out15 = hold_reg_dw31;
          data_mux_out16 = data_reg1_dw0;
          data_mux_out17 = data_reg1_dw1;
          data_mux_out18 = data_reg1_dw2;
          data_mux_out19 = data_reg1_dw3;
          data_mux_out20 = data_reg1_dw4;
          data_mux_out21 = data_reg1_dw5;
          data_mux_out22 = data_reg1_dw6;
          data_mux_out23 = data_reg1_dw7;
          data_mux_out24 = data_reg1_dw8;
          data_mux_out25 = data_reg1_dw9;
          data_mux_out26 = data_reg1_dw10;
          data_mux_out27 = data_reg1_dw11;
          data_mux_out28 = data_reg1_dw12;
          data_mux_out29 = data_reg1_dw13;
          data_mux_out30 = data_reg1_dw14;
          data_mux_out31 = data_reg1_dw15;
        end

       5'h11:
         begin
          data_mux_out0 =  hold_reg_dw15;
          data_mux_out1  = hold_reg_dw16;
          data_mux_out2  = hold_reg_dw17;
          data_mux_out3  = hold_reg_dw18;
          data_mux_out4  = hold_reg_dw19;
          data_mux_out5  = hold_reg_dw20;
          data_mux_out6  = hold_reg_dw21;
          data_mux_out7  = hold_reg_dw22;
          data_mux_out8  = hold_reg_dw23;
          data_mux_out9  = hold_reg_dw24;
          data_mux_out10 = hold_reg_dw25;
          data_mux_out11 = hold_reg_dw26;
          data_mux_out12 = hold_reg_dw27;
          data_mux_out13 = hold_reg_dw28;
          data_mux_out14 = hold_reg_dw29;
          data_mux_out15 = hold_reg_dw30;
          data_mux_out16 = hold_reg_dw31;
          data_mux_out17 = data_reg1_dw0;
          data_mux_out18 = data_reg1_dw1;
          data_mux_out19 = data_reg1_dw2;
          data_mux_out20 = data_reg1_dw3;
          data_mux_out21 = data_reg1_dw4;
          data_mux_out22 = data_reg1_dw5;
          data_mux_out23 = data_reg1_dw6;
          data_mux_out24 = data_reg1_dw7;
          data_mux_out25 = data_reg1_dw8;
          data_mux_out26 = data_reg1_dw9;
          data_mux_out27 = data_reg1_dw10;
          data_mux_out28 = data_reg1_dw11;
          data_mux_out29 = data_reg1_dw12;
          data_mux_out30 = data_reg1_dw13;
          data_mux_out31 = data_reg1_dw14;
        end

       5'h12:
         begin
          data_mux_out0 =  hold_reg_dw14;
          data_mux_out1  = hold_reg_dw15;
          data_mux_out2  = hold_reg_dw16;
          data_mux_out3  = hold_reg_dw17;
          data_mux_out4  = hold_reg_dw18;
          data_mux_out5  = hold_reg_dw19;
          data_mux_out6  = hold_reg_dw20;
          data_mux_out7  = hold_reg_dw21;
          data_mux_out8  = hold_reg_dw22;
          data_mux_out9  = hold_reg_dw23;
          data_mux_out10 = hold_reg_dw24;
          data_mux_out11 = hold_reg_dw25;
          data_mux_out12 = hold_reg_dw26;
          data_mux_out13 = hold_reg_dw27;
          data_mux_out14 = hold_reg_dw28;
          data_mux_out15 = hold_reg_dw29;
          data_mux_out16 = hold_reg_dw30;
          data_mux_out17 = hold_reg_dw31;
          data_mux_out18 = data_reg1_dw0;
          data_mux_out19 = data_reg1_dw1;
          data_mux_out20 = data_reg1_dw2;
          data_mux_out21 = data_reg1_dw3;
          data_mux_out22 = data_reg1_dw4;
          data_mux_out23 = data_reg1_dw5;
          data_mux_out24 = data_reg1_dw6;
          data_mux_out25 = data_reg1_dw7;
          data_mux_out26 = data_reg1_dw8;
          data_mux_out27 = data_reg1_dw9;
          data_mux_out28 = data_reg1_dw10;
          data_mux_out29 = data_reg1_dw11;
          data_mux_out30 = data_reg1_dw12;
          data_mux_out31 = data_reg1_dw13;
        end

       5'h13:
         begin
          data_mux_out0 =  hold_reg_dw13;
          data_mux_out1  = hold_reg_dw14;
          data_mux_out2  = hold_reg_dw15;
          data_mux_out3  = hold_reg_dw16;
          data_mux_out4  = hold_reg_dw17;
          data_mux_out5  = hold_reg_dw18;
          data_mux_out6  = hold_reg_dw19;
          data_mux_out7  = hold_reg_dw20;
          data_mux_out8  = hold_reg_dw21;
          data_mux_out9  = hold_reg_dw22;
          data_mux_out10 = hold_reg_dw23;
          data_mux_out11 = hold_reg_dw24;
          data_mux_out12 = hold_reg_dw25;
          data_mux_out13 = hold_reg_dw26;
          data_mux_out14 = hold_reg_dw27;
          data_mux_out15 = hold_reg_dw28;
          data_mux_out16 = hold_reg_dw29;
          data_mux_out17 = hold_reg_dw30;
          data_mux_out18 = hold_reg_dw31;
          data_mux_out19 = data_reg1_dw0;
          data_mux_out20 = data_reg1_dw1;
          data_mux_out21 = data_reg1_dw2;
          data_mux_out22 = data_reg1_dw3;
          data_mux_out23 = data_reg1_dw4;
          data_mux_out24 = data_reg1_dw5;
          data_mux_out25 = data_reg1_dw6;
          data_mux_out26 = data_reg1_dw7;
          data_mux_out27 = data_reg1_dw8;
          data_mux_out28 = data_reg1_dw9;
          data_mux_out29 = data_reg1_dw10;
          data_mux_out30 = data_reg1_dw11;
          data_mux_out31 = data_reg1_dw12;
        end

       5'h14:
         begin
          data_mux_out0 =  hold_reg_dw12;
          data_mux_out1  = hold_reg_dw13;
          data_mux_out2  = hold_reg_dw14;
          data_mux_out3  = hold_reg_dw15;
          data_mux_out4  = hold_reg_dw16;
          data_mux_out5  = hold_reg_dw17;
          data_mux_out6  = hold_reg_dw18;
          data_mux_out7  = hold_reg_dw19;
          data_mux_out8  = hold_reg_dw20;
          data_mux_out9  = hold_reg_dw21;
          data_mux_out10 = hold_reg_dw22;
          data_mux_out11 = hold_reg_dw23;
          data_mux_out12 = hold_reg_dw24;
          data_mux_out13 = hold_reg_dw25;
          data_mux_out14 = hold_reg_dw26;
          data_mux_out15 = hold_reg_dw27;
          data_mux_out16 = hold_reg_dw28;
          data_mux_out17 = hold_reg_dw29;
          data_mux_out18 = hold_reg_dw30;
          data_mux_out19 = hold_reg_dw31;
          data_mux_out20 = data_reg1_dw0;
          data_mux_out21 = data_reg1_dw1;
          data_mux_out22 = data_reg1_dw2;
          data_mux_out23 = data_reg1_dw3;
          data_mux_out24 = data_reg1_dw4;
          data_mux_out25 = data_reg1_dw5;
          data_mux_out26 = data_reg1_dw6;
          data_mux_out27 = data_reg1_dw7;
          data_mux_out28 = data_reg1_dw8;
          data_mux_out29 = data_reg1_dw9;
          data_mux_out30 = data_reg1_dw10;
          data_mux_out31 = data_reg1_dw11;
        end

       5'h15:
         begin
          data_mux_out0 =  hold_reg_dw11;
          data_mux_out1  = hold_reg_dw12;
          data_mux_out2  = hold_reg_dw13;
          data_mux_out3  = hold_reg_dw14;
          data_mux_out4  = hold_reg_dw15;
          data_mux_out5  = hold_reg_dw16;
          data_mux_out6  = hold_reg_dw17;
          data_mux_out7  = hold_reg_dw18;
          data_mux_out8  = hold_reg_dw19;
          data_mux_out9  = hold_reg_dw20;
          data_mux_out10 = hold_reg_dw21;
          data_mux_out11 = hold_reg_dw22;
          data_mux_out12 = hold_reg_dw23;
          data_mux_out13 = hold_reg_dw24;
          data_mux_out14 = hold_reg_dw25;
          data_mux_out15 = hold_reg_dw26 ;
          data_mux_out16 = hold_reg_dw27;
          data_mux_out17 = hold_reg_dw28;
          data_mux_out18 = hold_reg_dw29;
          data_mux_out19 = hold_reg_dw30;
          data_mux_out20 = hold_reg_dw31;
          data_mux_out21 = data_reg1_dw0;
          data_mux_out22 = data_reg1_dw1;
          data_mux_out23 = data_reg1_dw2;
          data_mux_out24 = data_reg1_dw3;
          data_mux_out25 = data_reg1_dw4;
          data_mux_out26 = data_reg1_dw5;
          data_mux_out27 = data_reg1_dw6;
          data_mux_out28 = data_reg1_dw7;
          data_mux_out29 = data_reg1_dw8;
          data_mux_out30 = data_reg1_dw9;
          data_mux_out31 = data_reg1_dw10;
        end

       5'h16:
         begin
          data_mux_out0 =  hold_reg_dw10;
          data_mux_out1  = hold_reg_dw11;
          data_mux_out2  = hold_reg_dw12;
          data_mux_out3  = hold_reg_dw13;
          data_mux_out4  = hold_reg_dw14;
          data_mux_out5  = hold_reg_dw15;
          data_mux_out6  = hold_reg_dw16;
          data_mux_out7  = hold_reg_dw17;
          data_mux_out8  = hold_reg_dw18;
          data_mux_out9  = hold_reg_dw19;
          data_mux_out10 = hold_reg_dw20;
          data_mux_out11 = hold_reg_dw21;
          data_mux_out12 = hold_reg_dw22;
          data_mux_out13 = hold_reg_dw23;
          data_mux_out14 = hold_reg_dw24;
          data_mux_out15 = hold_reg_dw25;
          data_mux_out16 = hold_reg_dw26;
          data_mux_out17 = hold_reg_dw27;
          data_mux_out18 = hold_reg_dw28;
          data_mux_out19 = hold_reg_dw29;
          data_mux_out20 = hold_reg_dw30;
          data_mux_out21 = hold_reg_dw31;
          data_mux_out22 = data_reg1_dw0;
          data_mux_out23 = data_reg1_dw1;
          data_mux_out24 = data_reg1_dw2;
          data_mux_out25 = data_reg1_dw3;
          data_mux_out26 = data_reg1_dw4;
          data_mux_out27 = data_reg1_dw5;
          data_mux_out28 = data_reg1_dw6;
          data_mux_out29 = data_reg1_dw7;
          data_mux_out30 = data_reg1_dw8;
          data_mux_out31 = data_reg1_dw9;
        end

       5'h17:
         begin
          data_mux_out0 =  hold_reg_dw9;
          data_mux_out1  = hold_reg_dw10;
          data_mux_out2  = hold_reg_dw11;
          data_mux_out3  = hold_reg_dw12;
          data_mux_out4  = hold_reg_dw13;
          data_mux_out5  = hold_reg_dw14;
          data_mux_out6  = hold_reg_dw15;
          data_mux_out7  = hold_reg_dw16;
          data_mux_out8  = hold_reg_dw17;
          data_mux_out9  = hold_reg_dw18;
          data_mux_out10 = hold_reg_dw19;
          data_mux_out11 = hold_reg_dw20;
          data_mux_out12 = hold_reg_dw21;
          data_mux_out13 = hold_reg_dw22;
          data_mux_out14 = hold_reg_dw23;
          data_mux_out15 = hold_reg_dw24;
          data_mux_out16 = hold_reg_dw25;
          data_mux_out17 = hold_reg_dw26;
          data_mux_out18 = hold_reg_dw27;
          data_mux_out19 = hold_reg_dw28;
          data_mux_out20 = hold_reg_dw29;
          data_mux_out21 = hold_reg_dw30;
          data_mux_out22 = hold_reg_dw31;
          data_mux_out23 = data_reg1_dw0;
          data_mux_out24 = data_reg1_dw1;
          data_mux_out25 = data_reg1_dw2;
          data_mux_out26 = data_reg1_dw3;
          data_mux_out27 = data_reg1_dw4;
          data_mux_out28 = data_reg1_dw5;
          data_mux_out29 = data_reg1_dw6;
          data_mux_out30 = data_reg1_dw7;
          data_mux_out31 = data_reg1_dw8;
        end

       5'h18:
         begin
          data_mux_out0 =  hold_reg_dw8;
          data_mux_out1  = hold_reg_dw9;
          data_mux_out2  = hold_reg_dw10;
          data_mux_out3  = hold_reg_dw11;
          data_mux_out4  = hold_reg_dw12;
          data_mux_out5  = hold_reg_dw13;
          data_mux_out6  = hold_reg_dw14;
          data_mux_out7  = hold_reg_dw15;
          data_mux_out8  = hold_reg_dw16;
          data_mux_out9  = hold_reg_dw17;
          data_mux_out10 = hold_reg_dw18;
          data_mux_out11 = hold_reg_dw19;
          data_mux_out12 = hold_reg_dw20;
          data_mux_out13 = hold_reg_dw21;
          data_mux_out14 = hold_reg_dw22;
          data_mux_out15 = hold_reg_dw23;
          data_mux_out16 = hold_reg_dw24;
          data_mux_out17 = hold_reg_dw25;
          data_mux_out18 = hold_reg_dw26;
          data_mux_out19 = hold_reg_dw27;
          data_mux_out20 = hold_reg_dw28;
          data_mux_out21 = hold_reg_dw29;
          data_mux_out22 = hold_reg_dw30;
          data_mux_out23 = hold_reg_dw31;
          data_mux_out24 = data_reg1_dw0;
          data_mux_out25 = data_reg1_dw1;
          data_mux_out26 = data_reg1_dw2;
          data_mux_out27 = data_reg1_dw3;
          data_mux_out28 = data_reg1_dw4;
          data_mux_out29 = data_reg1_dw5;
          data_mux_out30 = data_reg1_dw6;
          data_mux_out31 = data_reg1_dw7;
        end

       5'h19:
         begin
          data_mux_out0 =  hold_reg_dw7;
          data_mux_out1  = hold_reg_dw8;
          data_mux_out2  = hold_reg_dw9;
          data_mux_out3  = hold_reg_dw10;
          data_mux_out4  = hold_reg_dw11;
          data_mux_out5  = hold_reg_dw12;
          data_mux_out6  = hold_reg_dw13;
          data_mux_out7  = hold_reg_dw14;
          data_mux_out8  = hold_reg_dw15;
          data_mux_out9  = hold_reg_dw16;
          data_mux_out10 = hold_reg_dw17;
          data_mux_out11 = hold_reg_dw18;
          data_mux_out12 = hold_reg_dw19;
          data_mux_out13 = hold_reg_dw20;
          data_mux_out14 = hold_reg_dw21;
          data_mux_out15 = hold_reg_dw22;
          data_mux_out16 = hold_reg_dw23;
          data_mux_out17 = hold_reg_dw24;
          data_mux_out18 = hold_reg_dw25;
          data_mux_out19 = hold_reg_dw26;
          data_mux_out20 = hold_reg_dw27;
          data_mux_out21 = hold_reg_dw28;
          data_mux_out22 = hold_reg_dw29;
          data_mux_out23 = hold_reg_dw30;
          data_mux_out24 = hold_reg_dw31;
          data_mux_out25 = data_reg1_dw0;
          data_mux_out26 = data_reg1_dw1;
          data_mux_out27 = data_reg1_dw2;
          data_mux_out28 = data_reg1_dw3;
          data_mux_out29 = data_reg1_dw4;
          data_mux_out30 = data_reg1_dw5;
          data_mux_out31 = data_reg1_dw6;
        end

       5'h1A:
         begin
          data_mux_out0 =  hold_reg_dw6;
          data_mux_out1  = hold_reg_dw7;
          data_mux_out2  = hold_reg_dw8;
          data_mux_out3  = hold_reg_dw9;
          data_mux_out4  = hold_reg_dw10;
          data_mux_out5  = hold_reg_dw11;
          data_mux_out6  = hold_reg_dw12;
          data_mux_out7  = hold_reg_dw13;
          data_mux_out8  = hold_reg_dw14;
          data_mux_out9  = hold_reg_dw15;
          data_mux_out10 = hold_reg_dw16;
          data_mux_out11 = hold_reg_dw17;
          data_mux_out12 = hold_reg_dw18;
          data_mux_out13 = hold_reg_dw19;
          data_mux_out14 = hold_reg_dw20;
          data_mux_out15 = hold_reg_dw21;
          data_mux_out16 = hold_reg_dw22;
          data_mux_out17 = hold_reg_dw23;
          data_mux_out18 = hold_reg_dw24;
          data_mux_out19 = hold_reg_dw25;
          data_mux_out20 = hold_reg_dw26;
          data_mux_out21 = hold_reg_dw27;
          data_mux_out22 = hold_reg_dw28;
          data_mux_out23 = hold_reg_dw29;
          data_mux_out24 = hold_reg_dw30;
          data_mux_out25 = hold_reg_dw31;
          data_mux_out26 = data_reg1_dw0;
          data_mux_out27 = data_reg1_dw1;
          data_mux_out28 = data_reg1_dw2;
          data_mux_out29 = data_reg1_dw3;
          data_mux_out30 = data_reg1_dw4;
          data_mux_out31 = data_reg1_dw5;
        end

       5'h1B:
         begin
          data_mux_out0 =  hold_reg_dw5;
          data_mux_out1  = hold_reg_dw6;
          data_mux_out2  = hold_reg_dw7;
          data_mux_out3  = hold_reg_dw8;
          data_mux_out4  = hold_reg_dw9;
          data_mux_out5  = hold_reg_dw10;
          data_mux_out6  = hold_reg_dw11;
          data_mux_out7  = hold_reg_dw12;
          data_mux_out8  = hold_reg_dw13;
          data_mux_out9  = hold_reg_dw14;
          data_mux_out10 = hold_reg_dw15;
          data_mux_out11 = hold_reg_dw16;
          data_mux_out12 = hold_reg_dw17;
          data_mux_out13 = hold_reg_dw18;
          data_mux_out14 = hold_reg_dw19;
          data_mux_out15 = hold_reg_dw20;
          data_mux_out16 = hold_reg_dw21;
          data_mux_out17 = hold_reg_dw22;
          data_mux_out18 = hold_reg_dw23;
          data_mux_out19 = hold_reg_dw24;
          data_mux_out20 = hold_reg_dw25;
          data_mux_out21 = hold_reg_dw26;
          data_mux_out22 = hold_reg_dw27;
          data_mux_out23 = hold_reg_dw28;
          data_mux_out24 = hold_reg_dw29;
          data_mux_out25 = hold_reg_dw30;
          data_mux_out26 = hold_reg_dw31;
          data_mux_out27 = data_reg1_dw0;
          data_mux_out28 = data_reg1_dw1;
          data_mux_out29 = data_reg1_dw2;
          data_mux_out30 = data_reg1_dw3;
          data_mux_out31 = data_reg1_dw4;
        end

       5'h1C:
         begin
          data_mux_out0 =  hold_reg_dw4;
          data_mux_out1  = hold_reg_dw5;
          data_mux_out2  = hold_reg_dw6;
          data_mux_out3  = hold_reg_dw7;
          data_mux_out4  = hold_reg_dw8;
          data_mux_out5  = hold_reg_dw9;
          data_mux_out6  = hold_reg_dw10;
          data_mux_out7  = hold_reg_dw11;
          data_mux_out8  = hold_reg_dw12;
          data_mux_out9  = hold_reg_dw13;
          data_mux_out10 = hold_reg_dw14;
          data_mux_out11 = hold_reg_dw15;
          data_mux_out12 = hold_reg_dw16;
          data_mux_out13 = hold_reg_dw17;
          data_mux_out14 = hold_reg_dw18;
          data_mux_out15 = hold_reg_dw19;
          data_mux_out16 = hold_reg_dw20;
          data_mux_out17 = hold_reg_dw21;
          data_mux_out18 = hold_reg_dw22;
          data_mux_out19 = hold_reg_dw23;
          data_mux_out20 = hold_reg_dw24;
          data_mux_out21 = hold_reg_dw25;
          data_mux_out22 = hold_reg_dw26;
          data_mux_out23 = hold_reg_dw27;
          data_mux_out24 = hold_reg_dw28;
          data_mux_out25 = hold_reg_dw29;
          data_mux_out26 = hold_reg_dw30;
          data_mux_out27 = hold_reg_dw31;
          data_mux_out28 = data_reg1_dw0;
          data_mux_out29 = data_reg1_dw1;
          data_mux_out30 = data_reg1_dw2;
          data_mux_out31 = data_reg1_dw3;
        end

       5'h1D:
         begin
          data_mux_out0 =  hold_reg_dw3;
          data_mux_out1  = hold_reg_dw4;
          data_mux_out2  = hold_reg_dw5;
          data_mux_out3  = hold_reg_dw6;
          data_mux_out4  = hold_reg_dw7;
          data_mux_out5  = hold_reg_dw8;
          data_mux_out6  = hold_reg_dw9;
          data_mux_out7  = hold_reg_dw10;
          data_mux_out8  = hold_reg_dw11;
          data_mux_out9  = hold_reg_dw12;
          data_mux_out10 = hold_reg_dw13;
          data_mux_out11 = hold_reg_dw14;
          data_mux_out12 = hold_reg_dw15;
          data_mux_out13 = hold_reg_dw16;
          data_mux_out14 = hold_reg_dw17;
          data_mux_out15 = hold_reg_dw18;
          data_mux_out16 = hold_reg_dw19;
          data_mux_out17 = hold_reg_dw20;
          data_mux_out18 = hold_reg_dw21;
          data_mux_out19 = hold_reg_dw22;
          data_mux_out20 = hold_reg_dw23;
          data_mux_out21 = hold_reg_dw24;
          data_mux_out22 = hold_reg_dw25;
          data_mux_out23 = hold_reg_dw26;
          data_mux_out24 = hold_reg_dw27;
          data_mux_out25 = hold_reg_dw28;
          data_mux_out26 = hold_reg_dw29;
          data_mux_out27 = hold_reg_dw30;
          data_mux_out28 = hold_reg_dw31;
          data_mux_out29 = data_reg1_dw0;
          data_mux_out30 = data_reg1_dw1;
          data_mux_out31 = data_reg1_dw2;
        end

       5'h1E:
         begin
          data_mux_out0 =  hold_reg_dw2;
          data_mux_out1  = hold_reg_dw3;
          data_mux_out2  = hold_reg_dw4;
          data_mux_out3  = hold_reg_dw5;
          data_mux_out4  = hold_reg_dw6;
          data_mux_out5  = hold_reg_dw7;
          data_mux_out6  = hold_reg_dw8;
          data_mux_out7  = hold_reg_dw9;
          data_mux_out8  = hold_reg_dw10;
          data_mux_out9  = hold_reg_dw11;
          data_mux_out10 = hold_reg_dw12;
          data_mux_out11 = hold_reg_dw13;
          data_mux_out12 = hold_reg_dw14;
          data_mux_out13 = hold_reg_dw15;
          data_mux_out14 = hold_reg_dw16;
          data_mux_out15 = hold_reg_dw17;
          data_mux_out16 = hold_reg_dw18;
          data_mux_out17 = hold_reg_dw19;
          data_mux_out18 = hold_reg_dw20;
          data_mux_out19 = hold_reg_dw21;
          data_mux_out20 = hold_reg_dw22;
          data_mux_out21 = hold_reg_dw23;
          data_mux_out22 = hold_reg_dw24;
          data_mux_out23 = hold_reg_dw25;
          data_mux_out24 = hold_reg_dw26;
          data_mux_out25 = hold_reg_dw27;
          data_mux_out26 = hold_reg_dw28;
          data_mux_out27 = hold_reg_dw29;
          data_mux_out28 = hold_reg_dw30;
          data_mux_out29 = hold_reg_dw31;
          data_mux_out30 = data_reg1_dw0;
          data_mux_out31 = data_reg1_dw1;
        end

       5'h1F:
         begin
          data_mux_out0 =  hold_reg_dw1;
          data_mux_out1  = hold_reg_dw2;
          data_mux_out2  = hold_reg_dw3;
          data_mux_out3  = hold_reg_dw4;
          data_mux_out4  = hold_reg_dw5;
          data_mux_out5  = hold_reg_dw6;
          data_mux_out6  = hold_reg_dw7;
          data_mux_out7  = hold_reg_dw8;
          data_mux_out8  = hold_reg_dw9;
          data_mux_out9  = hold_reg_dw10;
          data_mux_out10 = hold_reg_dw11;
          data_mux_out11 = hold_reg_dw12;
          data_mux_out12 = hold_reg_dw13;
          data_mux_out13 = hold_reg_dw14;
          data_mux_out14 = hold_reg_dw15;
          data_mux_out15 = hold_reg_dw16;
          data_mux_out16 = hold_reg_dw17;
          data_mux_out17 = hold_reg_dw18;
          data_mux_out18 = hold_reg_dw19;
          data_mux_out19 = hold_reg_dw20;
          data_mux_out20 = hold_reg_dw21;
          data_mux_out21 = hold_reg_dw22;
          data_mux_out22 = hold_reg_dw23;
          data_mux_out23 = hold_reg_dw24;
          data_mux_out24 = hold_reg_dw25;
          data_mux_out25 = hold_reg_dw26;
          data_mux_out26 = hold_reg_dw27;
          data_mux_out27 = hold_reg_dw28;
          data_mux_out28 = hold_reg_dw29;
          data_mux_out29 = hold_reg_dw30;
          data_mux_out30 = hold_reg_dw31;
          data_mux_out31 = data_reg1_dw0;
        end

       default:
         begin
          data_mux_out0 =  data_reg1_dw0;
          data_mux_out1  = data_reg1_dw1;
          data_mux_out2  = data_reg1_dw2;
          data_mux_out3  = data_reg1_dw3;
          data_mux_out4  = data_reg1_dw4;
          data_mux_out5  = data_reg1_dw5;
          data_mux_out6  = data_reg1_dw6;
          data_mux_out7  = data_reg1_dw7;
          data_mux_out8  = data_reg1_dw8;
          data_mux_out9  = data_reg1_dw9;
          data_mux_out10 = data_reg1_dw10;
          data_mux_out11 = data_reg1_dw11;
          data_mux_out12 = data_reg1_dw12;
          data_mux_out13 = data_reg1_dw13;
          data_mux_out14 = data_reg1_dw14;
          data_mux_out15 = data_reg1_dw15;
          data_mux_out16 = data_reg1_dw16;
          data_mux_out17 = data_reg1_dw17;
          data_mux_out18 = data_reg1_dw18;
          data_mux_out19 = data_reg1_dw19;
          data_mux_out20 = data_reg1_dw20;
          data_mux_out21 = data_reg1_dw21;
          data_mux_out22 = data_reg1_dw22;
          data_mux_out23 = data_reg1_dw23;
          data_mux_out24 = data_reg1_dw24;
          data_mux_out25 = data_reg1_dw25;
          data_mux_out26 = data_reg1_dw26;
          data_mux_out27 = data_reg1_dw27;
          data_mux_out28 = data_reg1_dw28;
          data_mux_out29 = data_reg1_dw29;
          data_mux_out30 = data_reg1_dw30;
          data_mux_out31 = data_reg1_dw31;
        end
    endcase

   always_ff @ (posedge clk)
    begin
     data_mux_dw0_reg1  <= data_mux_out0;
     data_mux_dw1_reg1  <= data_mux_out1;
     data_mux_dw2_reg1  <= data_mux_out2;
     data_mux_dw3_reg1  <= data_mux_out3;
     data_mux_dw4_reg1  <= data_mux_out4;
     data_mux_dw5_reg1  <= data_mux_out5;
     data_mux_dw6_reg1  <= data_mux_out6;
     data_mux_dw7_reg1  <= data_mux_out7;
     data_mux_dw8_reg1  <= data_mux_out8;
     data_mux_dw9_reg1  <= data_mux_out9;
     data_mux_dw10_reg1 <= data_mux_out10;
     data_mux_dw11_reg1 <= data_mux_out11;
     data_mux_dw12_reg1 <= data_mux_out12;
     data_mux_dw13_reg1 <= data_mux_out13;
     data_mux_dw14_reg1 <= data_mux_out14;
     data_mux_dw15_reg1 <= data_mux_out15;
     data_mux_dw16_reg1 <= data_mux_out16;
     data_mux_dw17_reg1 <= data_mux_out17;
     data_mux_dw18_reg1 <= data_mux_out18;
     data_mux_dw19_reg1 <= data_mux_out19;
     data_mux_dw20_reg1 <= data_mux_out20;
     data_mux_dw21_reg1 <= data_mux_out21;
     data_mux_dw22_reg1 <= data_mux_out22;
     data_mux_dw23_reg1 <= data_mux_out23;
     data_mux_dw24_reg1 <= data_mux_out24;
     data_mux_dw25_reg1 <= data_mux_out25;
     data_mux_dw26_reg1 <= data_mux_out26;
     data_mux_dw27_reg1 <= data_mux_out27;
     data_mux_dw28_reg1 <= data_mux_out28;
     data_mux_dw29_reg1 <= data_mux_out29;
     data_mux_dw30_reg1 <= data_mux_out30;
     data_mux_dw31_reg1 <= data_mux_out31;
    end

   always_ff @ (posedge clk)
    begin
     data_mux_dw0_reg2  <= data_mux_dw0_reg1;
     data_mux_dw1_reg2  <= data_mux_dw1_reg1;
     data_mux_dw2_reg2  <= data_mux_dw2_reg1;
     data_mux_dw3_reg2  <= data_mux_dw3_reg1;
     data_mux_dw4_reg2  <= data_mux_dw4_reg1;
     data_mux_dw5_reg2  <= data_mux_dw5_reg1;
     data_mux_dw6_reg2  <= data_mux_dw6_reg1;
     data_mux_dw7_reg2  <= data_mux_dw7_reg1;
     data_mux_dw8_reg2  <= data_mux_dw8_reg1;
     data_mux_dw9_reg2  <= data_mux_dw9_reg1;
     data_mux_dw10_reg2 <= data_mux_dw10_reg1;
     data_mux_dw11_reg2 <= data_mux_dw11_reg1;
     data_mux_dw12_reg2 <= data_mux_dw12_reg1;
     data_mux_dw13_reg2 <= data_mux_dw13_reg1;
     data_mux_dw14_reg2 <= data_mux_dw14_reg1;
     data_mux_dw15_reg2 <= data_mux_dw15_reg1;
     data_mux_dw16_reg2 <= data_mux_dw16_reg1;
     data_mux_dw17_reg2 <= data_mux_dw17_reg1;
     data_mux_dw18_reg2 <= data_mux_dw18_reg1;
     data_mux_dw19_reg2 <= data_mux_dw19_reg1;
     data_mux_dw20_reg2 <= data_mux_dw20_reg1;
     data_mux_dw21_reg2 <= data_mux_dw21_reg1;
     data_mux_dw22_reg2 <= data_mux_dw22_reg1;
     data_mux_dw23_reg2 <= data_mux_dw23_reg1;
     data_mux_dw24_reg2 <= data_mux_dw24_reg1;
     data_mux_dw25_reg2 <= data_mux_dw25_reg1;
     data_mux_dw26_reg2 <= data_mux_dw26_reg1;
     data_mux_dw27_reg2 <= data_mux_dw27_reg1;
     data_mux_dw28_reg2 <= data_mux_dw28_reg1;
     data_mux_dw29_reg2 <= data_mux_dw29_reg1;
     data_mux_dw30_reg2 <= data_mux_dw30_reg1;
     data_mux_dw31_reg2 <= data_mux_dw31_reg1;
    end

  end
   
  always_ff @ (posedge clk)
    begin            
    	wr_data_state_reg <= wr_data_state;
      avmm_wren_reg1 <= wr_data_state;
      avmm_wren_reg2 <= avmm_wren_reg1;
      avmm_wren_reg3 <= avmm_wren_reg2;
      avmm_wren_reg4 <= avmm_wren_reg3;
      avmm_address_reg1 <= avmm_address_reg;
      avmm_address_reg2 <= avmm_address_reg1;   
      avmm_address_reg3 <= avmm_address_reg2; 
      avmm_burst_cnt_reg1 <= avmm_burst_cnt_reg;
      avmm_burst_cnt_reg2 <= avmm_burst_cnt_reg1; 
      avmm_burst_cnt_reg3 <= avmm_burst_cnt_reg2;
      avmm_burst_cnt_reg4 <= avmm_burst_cnt_reg3;     
      avmm_bar_reg1[2:0]    <=  avmm_bar_reg[2:0];   
      avmm_bar_reg2[2:0]    <=  avmm_bar_reg1[2:0];  
      avmm_bar_reg3[2:0]    <=  avmm_bar_reg2[2:0];  
      avmm_bar_reg4[2:0]    <=  avmm_bar_reg3[2:0];   
      avmm_vfnum_reg1[11:0] <=  avmm_vfnum_reg[11:0]; 
      avmm_vfnum_reg2[11:0] <=  avmm_vfnum_reg1[11:0]; 
      avmm_vfnum_reg3[11:0] <=  avmm_vfnum_reg2[11:0]; 
      avmm_vfnum_reg4[11:0] <=  avmm_vfnum_reg3[11:0]; 
      avmm_pfnum_reg1[1:0]  <=  avmm_pfnum_reg[1:0];   
      avmm_pfnum_reg2[1:0]  <=  avmm_pfnum_reg1[1:0]; 
      avmm_pfnum_reg3[1:0]  <=  avmm_pfnum_reg2[1:0]; 
      avmm_pfnum_reg4[1:0]  <=  avmm_pfnum_reg3[1:0]; 
      avmm_vfactive_reg1    <=  avmm_vfactive_reg;     
      avmm_vfactive_reg2    <=  avmm_vfactive_reg1;  
      avmm_vfactive_reg3    <=  avmm_vfactive_reg2;  
      avmm_vfactive_reg4    <=  avmm_vfactive_reg3;  
    end                         

/// Write address for extra write 
always_ff @ (posedge clk)
  begin
  	avmmwr_address_plus_8_reg1[5:0]  <= 6'h0;
  	avmmwr_address_plus_8_reg1[63:6] <= avmm_address_reg[63:6] + 4'h8;
  	avmmwr_address_plus_8_reg2[63:0] <= avmmwr_address_plus_8_reg1;
  	avmmwr_address_plus_8_reg3[63:0] <= avmmwr_address_plus_8_reg2;
  	
  end




 always_ff @ (posedge clk)        
   	   if(wr_pop_cmd & avmm_burst_cnt[3:0] <= 4'h8)         
         avmm_burst_cnt_reg <= avmm_burst_cnt[3:0]; 
 else if(wr_pop_cmd)
         avmm_burst_cnt_reg <= 4'h8;
       else
         avmm_burst_cnt_reg <= 4'h1; 
       


/// Write BE   
 assign avmm_write_state_rise = ~wr_data_state_reg & wr_data_state; 
 assign first_wren_reg = avmm_write_state_rise;       
 assign last_wren_reg  = wr_data_state & avmm_burst_counter[3:0] == 4'h1;
 // AVMM BE Mask
 always_ff @ (posedge clk)
   begin
     if(BAM_DATAWIDTH == 1024) begin
       first_avmm_mask_reg1[127:0] <= first_wren_reg? avmm_fbe_reg : 128'hFFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF;
       last_avmm_mask_reg1[127:0]  <= last_wren_reg ? avmm_lbe_reg : 128'hFFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF;
     end else if(BAM_DATAWIDTH == 512) begin
       first_avmm_mask_reg1[63:0] <= first_wren_reg? avmm_fbe_reg[63:0] : 64'hFFFF_FFFF_FFFF_FFFF;
       last_avmm_mask_reg1[63:0]  <= last_wren_reg ? avmm_lbe_reg[63:0] : 64'hFFFF_FFFF_FFFF_FFFF;
     end else if(BAM_DATAWIDTH == 256) begin
       first_avmm_mask_reg1[31:0] <= first_wren_reg? avmm_fbe_reg[31:0] : 32'hFFFF_FFFF;
       last_avmm_mask_reg1[31:0]  <= last_wren_reg ? avmm_lbe_reg[31:0] : 32'hFFFF_FFFF;
     end
   end

always_ff @ (posedge clk)
   begin
     if(BAM_DATAWIDTH == 1024) begin
       avmm_be_reg2[127:0] <= first_avmm_mask_reg1[127:0] & last_avmm_mask_reg1[127:0];
       avmm_be_reg3[127:0] <= avmm_be_reg2;
       avmm_be_reg4[127:0] <= avmm_be_reg3;
     end else if(BAM_DATAWIDTH == 512) begin
       avmm_be_reg2[63:0] <= first_avmm_mask_reg1[63:0] & last_avmm_mask_reg1[63:0];
       avmm_be_reg3[63:0] <= avmm_be_reg2;
       avmm_be_reg4[63:0] <= avmm_be_reg3;
     end else if(BAM_DATAWIDTH == 256) begin
       avmm_be_reg2[31:0] <= first_avmm_mask_reg1[31:0] & last_avmm_mask_reg1[31:0];
       avmm_be_reg3[31:0] <= avmm_be_reg2;
       avmm_be_reg4[31:0] <= avmm_be_reg3;
     end
   end

if(BAM_DATAWIDTH == 256) begin
assign avmm_writedata = {    data_mux_dw7_reg2,data_mux_dw6_reg2,data_mux_dw5_reg2,data_mux_dw4_reg2,
                               data_mux_dw3_reg2,data_mux_dw2_reg2,data_mux_dw1_reg2,data_mux_dw0_reg2};  
   end
else if(BAM_DATAWIDTH == 512) begin
assign avmm_writedata = {    data_mux_dw15_reg2,data_mux_dw14_reg2,data_mux_dw13_reg2,data_mux_dw12_reg2,
                               data_mux_dw11_reg2,data_mux_dw10_reg2,data_mux_dw9_reg2,data_mux_dw8_reg2,
                               data_mux_dw7_reg2,data_mux_dw6_reg2,data_mux_dw5_reg2,data_mux_dw4_reg2,
                               data_mux_dw3_reg2,data_mux_dw2_reg2,data_mux_dw1_reg2,data_mux_dw0_reg2};
   end
else if(BAM_DATAWIDTH == 1024) begin
assign avmm_writedata = {    data_mux_dw31_reg2,data_mux_dw30_reg2,data_mux_dw29_reg2,data_mux_dw28_reg2,
                               data_mux_dw27_reg2,data_mux_dw26_reg2,data_mux_dw25_reg2,data_mux_dw24_reg2,
                               data_mux_dw23_reg2,data_mux_dw22_reg2,data_mux_dw21_reg2,data_mux_dw20_reg2,
                               data_mux_dw19_reg2,data_mux_dw18_reg2,data_mux_dw17_reg2,data_mux_dw16_reg2,
			       data_mux_dw15_reg2,data_mux_dw14_reg2,data_mux_dw13_reg2,data_mux_dw12_reg2,
                               data_mux_dw11_reg2,data_mux_dw10_reg2,data_mux_dw9_reg2,data_mux_dw8_reg2,
                               data_mux_dw7_reg2,data_mux_dw6_reg2,data_mux_dw5_reg2,data_mux_dw4_reg2,
                               data_mux_dw3_reg2,data_mux_dw2_reg2,data_mux_dw1_reg2,data_mux_dw0_reg2};
   end

                            
assign avmm_writedata_wrreq          = avmm_wren_reg4;
generate
 if(BAM_DATAWIDTH == 1024) begin
   assign avmm_be[127:0]                 = avmm_be_reg4;
   scfifo  avmm_data_fifo (
      .clock                            (clk),
      .data                             ({avmm_be[127:0],avmm_writedata}),
      .rdreq                            (avmm_writedata_rdreq_i),
      .wrreq                            (avmm_writedata_wrreq),
      .almost_full                      (),
      .full                             (),
      .q                                (avmm_writedata_o[BAM_DATAWIDTH+127 :0]),
      .aclr                             (1'b0),
      .almost_empty                     (),
      .eccstatus                        (),
      .empty                            (),
      .sclr                             (srst_reg),
      .usedw                            ());
  defparam
      avmm_data_fifo.add_ram_output_register  = "ON",
      avmm_data_fifo.almost_full_value  = 8,
      avmm_data_fifo.enable_ecc  = "FALSE",
      avmm_data_fifo.intended_device_family  = "Agilex 7",
      avmm_data_fifo.lpm_hint  = "AUTO",
      avmm_data_fifo.lpm_numwords  = 256,
      avmm_data_fifo.lpm_showahead  = "ON",
      avmm_data_fifo.lpm_type  = "scfifo",
      avmm_data_fifo.lpm_width  = BAM_DATAWIDTH+128,
      avmm_data_fifo.lpm_widthu  = 8,
      avmm_data_fifo.overflow_checking  = "OFF",
      avmm_data_fifo.underflow_checking  = "OFF",
      avmm_data_fifo.use_eab  = "ON";

   
 end else if(BAM_DATAWIDTH == 512) begin
   assign avmm_be[63:0]                 = avmm_be_reg4;
   scfifo  avmm_data_fifo (
      .clock                            (clk),
      .data                             ({avmm_be[63:0],avmm_writedata}),
      .rdreq                            (avmm_writedata_rdreq_i),
      .wrreq                            (avmm_writedata_wrreq),
      .almost_full                      (),
      .full                             (),
      .q                                (avmm_writedata_o[BAM_DATAWIDTH+63 :0]),
      .aclr                             (1'b0),
      .almost_empty                     (),
      .eccstatus                        (),
      .empty                            (),
      .sclr                             (srst_reg),
      .usedw                            ());
  defparam
      avmm_data_fifo.add_ram_output_register  = "ON",
      avmm_data_fifo.almost_full_value  = 8,
      avmm_data_fifo.enable_ecc  = "FALSE",
      avmm_data_fifo.intended_device_family  = "Agilex 7",
      avmm_data_fifo.lpm_hint  = "AUTO",
      avmm_data_fifo.lpm_numwords  = 256,
      avmm_data_fifo.lpm_showahead  = "ON",
      avmm_data_fifo.lpm_type  = "scfifo",
      avmm_data_fifo.lpm_width  = BAM_DATAWIDTH+64,
      avmm_data_fifo.lpm_widthu  = 8,
      avmm_data_fifo.overflow_checking  = "OFF",
      avmm_data_fifo.underflow_checking  = "OFF",
      avmm_data_fifo.use_eab  = "ON";

assign avmm_writedata_o[639:576] = 64'h0;

 end else if(BAM_DATAWIDTH == 256) begin
   assign avmm_be[31:0]                 = avmm_be_reg4;
   scfifo  avmm_data_fifo (
      .clock                            (clk),
      .data                             ({avmm_be[31:0],avmm_writedata}),
      .rdreq                            (avmm_writedata_rdreq_i),
      .wrreq                            (avmm_writedata_wrreq),
      .almost_full                      (),
      .full                             (),
      .q                                (avmm_writedata_o[BAM_DATAWIDTH+31 :0]),
      .aclr                             (1'b0),
      .almost_empty                     (),
      .eccstatus                        (),
      .empty                            (),
      .sclr                             (srst_reg),
      .usedw                            ());
  defparam
      avmm_data_fifo.add_ram_output_register  = "ON",
      avmm_data_fifo.almost_full_value  = 8,
      avmm_data_fifo.enable_ecc  = "FALSE",
      avmm_data_fifo.intended_device_family  = "Agilex 7",
      avmm_data_fifo.lpm_hint  = "AUTO",
      avmm_data_fifo.lpm_numwords  = 256,
      avmm_data_fifo.lpm_showahead  = "ON",
      avmm_data_fifo.lpm_type  = "scfifo",
      avmm_data_fifo.lpm_width  = BAM_DATAWIDTH+32,
      avmm_data_fifo.lpm_widthu  = 8,
      avmm_data_fifo.overflow_checking  = "OFF",
      avmm_data_fifo.underflow_checking  = "OFF",
      avmm_data_fifo.use_eab  = "ON";

 end
endgenerate

//// READ processing
always_ff @(posedge clk) 
    if (srst_reg) 
      rd_state                   <= RD_IDLE;
   else 
      rd_state                   <= rd_nxt_state; 


  always_comb begin
    case(rd_state) 
      RD_IDLE     : 
        if(rdcmd_avail_reg & wr_idle_state)
          rd_nxt_state = RD_DECODE;
        else 
          rd_nxt_state = RD_IDLE;
      RD_DECODE   : 
          if(rd_exist_type_1_reg1)         
            rd_nxt_state = RD_TYPE_1;
          else                                 
            rd_nxt_state = RD_TYPE_2_1_PIPE;    /// pipe 13-bit comparator

      RD_TYPE_1   : 
        if (cpl_buff_ok_reg1)  /// CPL RAM and tx cmd fifo ok
           if (rd_exist_type_2_reg1)       
             rd_nxt_state = RD_TYPE_2_0;
            else                               
               rd_nxt_state = RD_IDLE;
        else                                 
          rd_nxt_state = RD_TYPE_1;
          
	    RD_TYPE_2_0  :      // prepare for the first 2 type                         
	      rd_nxt_state = RD_TYPE_2_1;
	      
      RD_TYPE_2_1  :    
         if (cpl_buff_ok_reg1)
             if (count_type_2_eq_one_reg2)
                rd_nxt_state = RD_IDLE;
             else     
                rd_nxt_state = RD_TYPE_2_2;
         else  
           rd_nxt_state = RD_TYPE_2_1;
                
      RD_TYPE_2_2  :                                            /// prepare for the 2nd+ Type C                    
        rd_nxt_state = RD_TYPE_2_1_PIPE;
      
      RD_TYPE_2_1_PIPE  :                                            /// pipe 13-bit comparator                   
        rd_nxt_state = RD_TYPE_2_1;
      
      default:
        rd_nxt_state = RD_IDLE;
    endcase
  end

/// state decode

 assign rd_pop_cmd     = (rd_state == RD_IDLE & rdcmd_avail_reg & wr_idle_state); 
 
  always_ff @(posedge clk)
    begin
       decode_state_reg1                  <= ((rd_nxt_state == RD_DECODE )  & ~srst_reg);   /// decode the next state (D)
       type_1_state_reg1                  <= ((rd_nxt_state == RD_TYPE_1 )  & ~srst_reg);
       type_2_1_state_reg1                <= ((rd_nxt_state == RD_TYPE_2_1) & ~srst_reg);
       type_2_2_state_reg1                <= ((rd_nxt_state == RD_TYPE_2_2) & ~srst_reg);
    end
 
 always_ff @(posedge clk)
    begin
     type_1_state_reg2 <= type_1_state_reg1;
     type_2_1_state_reg2 <= type_2_1_state_reg1;
     type_1_state_reg3 <= type_1_state_reg2;
     type_1_state_reg4 <= type_1_state_reg3;
     type_1_state_reg5 <= type_1_state_reg4;  
    end

  always_ff @(posedge clk) 
      if(rd_pop_cmd)
          begin
        	 rd_exist_type_1_reg1               <=    rd_type1_exist;     
        	 rd_exist_type_2_reg1               <=    rd_type2_exist;
        	 rd_avmm_address_reg1[63:0]         <=    avmm_address;
        	 tlp_dw_size_type_1_reg1[7:0]       <=    rd_type1_size[7:0];
        	 last_type_2_size_reg1[6:0]         <=    rd_last_type2_size[6:0];
        	 tlp_dw_size_reg1[9:0]              <=    tlp_len[9:0];   
        	 cpl_req_id_reg1[15:0]              <=    tlp_rd_reqid;
        	 rdreq_tag_reg1[9:0]                <=    tlp_rd_tag;
           cpl_vfnum_reg1[11:0]               <=    avmm_vfnum[11:0];       
           cpl_pfnum_reg1[1:0]                <=    avmm_pfnum[1:0];        
           cpl_vfactive_reg1                  <=    avmm_vfactive;  
           cpl_tag_reg1[9:0]                  <=    tlp_rd_tag;   
           cpl_attr_reg1[2:0]                 <=    tlp_attr;  
           flush_be_reg1                      <=    flush_be; 
           cpl_tc_reg1[2:0]                   <=    tlp_tc;      
           cpl_lower_addr_reg1[7:0]           <=    tlp_lower_addr[7:0];
           tlp_fbe_reg1[3:0]                  <=    tlp_fbe;
           tlp_lbe_reg1[3:0]                  <=    tlp_lbe;  
           tlp_lbe_zero_reg1                  <=    tlp_lbe == 4'h0;
           if(BAM_DATAWIDTH == 1024) begin
             avmm_rd_fbe_reg1[127:0]             <=    avmm_fbe[127:0];
             avmm_rd_lbe_reg1[127:0]             <=    avmm_lbe[127:0];
           end else if(BAM_DATAWIDTH == 512) begin
             avmm_rd_fbe_reg1[63:0]             <=    avmm_fbe[63:0];
             avmm_rd_lbe_reg1[63:0]             <=    avmm_lbe[63:0];
           end else if(BAM_DATAWIDTH == 256) begin
             avmm_rd_fbe_reg1[31:0]             <=    avmm_fbe[31:0];
             avmm_rd_lbe_reg1[31:0]             <=    avmm_lbe[31:0];
           end

           avmm_rd_bar_reg1[2:0]              <=    avmm_bar; 
           avmm_rdburst_cnt_reg1[6:0]         <=  avmm_burst_cnt[6:0];
           
           
          end

 always_ff @(posedge clk)
    cpl_buff_ok_reg1 <= ~cpl_cmd_almost_full & ~avmm_cmd_almost_full;
  
  /// outstanding type 2 read counter
 always_ff @(posedge clk)
    if (srst_reg) 
       type_2_cntr[4:0]  <= 13'h0;
    else if (rd_pop_cmd)  
       type_2_cntr[4:0]  <= rd_type2_num;
    else if (type_2_1_state_reg1 & cpl_buff_ok_reg1) /// decrement after each type C sent
       type_2_cntr[4:0]  <= type_2_cntr[4:0] - 1'b1;
 
 always_ff @(posedge clk)
     begin       
       cpl_buff_ok_reg2                 <= cpl_buff_ok_reg1;
       count_type_2_eq_one_reg1         <= (type_2_cntr[4: 0] == 5'h1);
       count_type_2_eq_one_reg2         <= count_type_2_eq_one_reg1;  
       count_type_2_eq_one_reg3         <= count_type_2_eq_one_reg2; 
       last_type_2_size_reg2            <= last_type_2_size_reg1;   
       rd_exist_type_1_reg2             <= rd_exist_type_1_reg1;
       rd_avmm_address_reg2[5:0]        <= rd_avmm_address_reg1[5:0];
     end 
     
  always_ff @(posedge clk) begin /// Indexing the number of MPS boundary to compute the address for type 2 AVMM read
    if (srst_reg) 
       type_2_index_reg <= 6'h0;
    else begin
      if (decode_state_reg1)
        type_2_index_reg  <= {5'h0, (rd_exist_type_1_reg1)};
      else if (type_2_2_state_reg1)  /// increment right before entering 2_1 state
        type_2_index_reg  <= type_2_index_reg + 1'b1;
        end
  end 

//// Read Command Valid
     
 always_ff @(posedge clk)  
   begin
   	rd_type_1_cmd_valid_reg2 <= cpl_buff_ok_reg1 & type_1_state_reg1;
   	rd_type_1_cmd_valid_reg3 <= rd_type_1_cmd_valid_reg2;
   	rd_type_1_cmd_valid_reg4 <= rd_type_1_cmd_valid_reg3;
   	rd_type_2_cmd_valid_reg2 <= cpl_buff_ok_reg1 & type_2_1_state_reg1;
   	rd_type_2_cmd_valid_reg3 <= rd_type_2_cmd_valid_reg2;
   	rd_type_2_cmd_valid_reg4 <= rd_type_2_cmd_valid_reg3;
   	rd_cmd_valid_reg5        <= rd_type_2_cmd_valid_reg4 | rd_type_1_cmd_valid_reg4;     
   	rd_type_1_cmd_valid_reg5 <= rd_type_1_cmd_valid_reg4;
   	rd_type_2_cmd_valid_reg5 <= rd_type_2_cmd_valid_reg4;  
   end


/// first type 2 flag (To fix a bug with first type 2 with FBE != 4hF)
 always_ff @(posedge clk) 
   if(rd_pop_cmd)
     first_type_2_sreg <= 1'b1;
   else if(rd_type_2_cmd_valid_reg2 | rd_type_1_cmd_valid_reg2)
     first_type_2_sreg <= 1'b0;      
 
 always_ff @(posedge clk)  
   begin
     rd_first_type_2_cmd_valid_reg2 <= cpl_buff_ok_reg1 & type_2_1_state_reg1 & tlp_fbe_reg1 != 4'hF & first_type_2_sreg; /// spectial case with BE !=F for first type 2
     rd_first_type_2_cmd_valid_reg3 <= rd_first_type_2_cmd_valid_reg2;
     rd_first_type_2_cmd_valid_reg4 <= rd_first_type_2_cmd_valid_reg3;
     rd_first_type_2_cmd_valid_reg5 <= rd_first_type_2_cmd_valid_reg4;
   end
 
/// Calculate the AVMM Read address
 always_ff @(posedge clk) 
  begin
    if (type_2_1_state_reg1) /// TYPE 2, address start at MPS boundary
      if (mps_128_reg1)     
         tlp_start_addr_arg0_reg2 <= {rd_avmm_address_reg1[63:7], 7'h0};
      else if (mps_256_reg1)
         tlp_start_addr_arg0_reg2 <= {rd_avmm_address_reg1[63:8], 8'h0};
      else                           
         tlp_start_addr_arg0_reg2 <= {rd_avmm_address_reg1[63:9], 9'h0};
    else                 // type 1 uses the original address from descriptor                              
     tlp_start_addr_arg0_reg2 <= rd_avmm_address_reg1[63:0];
  end    


 always_ff @(posedge clk) 
  begin     
    if (type_2_1_state_reg1)         
       if (mps_128_reg1)     
         tlp_start_addr_arg1_reg2[8:0] <= {2'h0, type_2_index_reg, 1'h0};
       else if (mps_256_reg1) 
         tlp_start_addr_arg1_reg2 <= {1'h0, type_2_index_reg, 2'h0};
       else                          
         tlp_start_addr_arg1_reg2 <= {      type_2_index_reg, 3'h0};
    else                               
      tlp_start_addr_arg1_reg2 <= 9'h0;
  end
  
 always_ff @(posedge clk) 
  begin     
  	 tlp_start_addr_reg3[5:0]     <= tlp_start_addr_arg0_reg2[5:0] ;
     tlp_start_addr_reg3[63:6]    <= (tlp_start_addr_arg0_reg2[63:6] + tlp_start_addr_arg1_reg2[8:0]);
     tlp_start_addr_reg4[63:0]    <= tlp_start_addr_reg3[63:0];
     tlp_start_addr_reg5[63:0]    <= tlp_start_addr_reg4[63:0];
  end

 
 /// Calculate TLP DW size

   // Type 1 size
 always_ff @(posedge clk) 
   begin
      tlp_dw_size_type_1_reg2[7:0]   <= tlp_dw_size_type_1_reg1[7:0];
      tlp_dw_size_type_1_reg3        <= tlp_dw_size_type_1_reg2;
      tlp_dw_size_type_1_reg4        <= tlp_dw_size_type_1_reg3;
      tlp_dw_size_type_1_reg5        <= tlp_dw_size_type_1_reg4;
   end  
 

      /// Type 2 DW size
 always_ff @(posedge clk)
  begin
   last_type_2_size_max_reg2      <= (last_type_2_size_reg1[6:0] == 7'h0); /// last type 2 full MPS
  
   if (~last_type_2_size_max_reg2 & count_type_2_eq_one_reg2) 
      tlp_dw_size_type_2_reg3            <= {1'b0,last_type_2_size_reg2[6:0]};
    else if (mps_128_reg2) 
      tlp_dw_size_type_2_reg3            <= 8'h20; // MPS req size = 128B
    else if (mps_256_reg2)
      tlp_dw_size_type_2_reg3            <= 8'h40; // MPS req size = 256B
    else
      tlp_dw_size_type_2_reg3            <= 8'h80; // MPS req size = 512B
      
    tlp_dw_size_type_2_reg4           <= tlp_dw_size_type_2_reg3;
    avmm_read_lines_type_2_plus_reg4[3:0]  <= |tlp_dw_size_type_2_reg3[3:0]? (tlp_dw_size_type_2_reg3[7:4] + 1'b1) : tlp_dw_size_type_2_reg3[7:4];
  end
  
  
  always_ff @(posedge clk)  
    tlp_dw_size_type_reg5 <= type_1_state_reg4 ? tlp_dw_size_type_1_reg4 : tlp_dw_size_type_2_reg4;




 /// calculate AVMM Read burst count
  always_ff @(posedge clk) 
    begin
      if(BAM_DATAWIDTH == 1024) begin
        avmm_type_1_read_dw_reg3[7:0]   <= tlp_dw_size_type_1_reg2[7:0] +  cpl_lower_addr_reg2[6:2];
        avmm_type_1_read_bcnt_reg4[3:0] <= (|avmm_type_1_read_dw_reg3[4:0])?   avmm_type_1_read_dw_reg3[7:5] + 1'b1 : avmm_type_1_read_dw_reg3[7:5]; 
      end else if(BAM_DATAWIDTH == 512) begin
        avmm_type_1_read_dw_reg3[7:0]   <= tlp_dw_size_type_1_reg2[7:0] +  cpl_lower_addr_reg2[5:2];
        avmm_type_1_read_bcnt_reg4[3:0] <= (|avmm_type_1_read_dw_reg3[3:0])?   avmm_type_1_read_dw_reg3[7:4] + 1'b1 : avmm_type_1_read_dw_reg3[7:4];
      end else if(BAM_DATAWIDTH == 256) begin
        avmm_type_1_read_dw_reg3[7:0]   <= tlp_dw_size_type_1_reg2[7:0] +  cpl_lower_addr_reg2[4:2];
        avmm_type_1_read_bcnt_reg4[3:0] <= (|avmm_type_1_read_dw_reg3[2:0])?   avmm_type_1_read_dw_reg3[7:3] + 1'b1 : avmm_type_1_read_dw_reg3[7:3];
      end
    end

  always_ff @(posedge clk) 
      if(BAM_DATAWIDTH == 1024) begin
        avmm_type_2_read_bcnt_reg4[3:0] <=  (|tlp_dw_size_type_2_reg3[4:0])?  tlp_dw_size_type_2_reg3[7:4] + 1'b1 : tlp_dw_size_type_2_reg3[7:4];    
      end else if(BAM_DATAWIDTH == 512) begin
        avmm_type_2_read_bcnt_reg4[3:0] <=  (|tlp_dw_size_type_2_reg3[3:0])?  tlp_dw_size_type_2_reg3[7:4] + 1'b1 : tlp_dw_size_type_2_reg3[7:4];
      end else if(BAM_DATAWIDTH == 256) begin
        avmm_type_2_read_bcnt_reg4[3:0] <=  (|tlp_dw_size_type_2_reg3[3:0])?  tlp_dw_size_type_2_reg3[7:4] + 1'b1 : tlp_dw_size_type_2_reg3[7:4];
      end
 
   always_ff @(posedge clk) 
      avmm_read_bcnt_reg5[3:0] <= rd_type_1_cmd_valid_reg4? avmm_type_1_read_bcnt_reg4 : avmm_type_2_read_bcnt_reg4;


/// Read BE
   always_ff @(posedge clk) 
     begin
       if(BAM_DATAWIDTH == 1024) begin
         avmm_rd_be_reg2[127:0] <= avmm_rd_fbe_reg1[127:0] & avmm_rd_lbe_reg1[127:0];
         avmm_rd_be_reg3[127:0] <= avmm_rd_be_reg2[127:0];
         avmm_rd_be_reg4[127:0] <= avmm_rd_be_reg3[127:0];
         avmm_rd_be_reg5[127:0] <= (avmm_rdburst_cnt_reg4 == 7'h1)? avmm_rd_be_reg4[127:0] : 128'hFFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF;
       end else if(BAM_DATAWIDTH == 512) begin
         avmm_rd_be_reg2[63:0] <= avmm_rd_fbe_reg1[63:0] & avmm_rd_lbe_reg1[63:0];
         avmm_rd_be_reg3[63:0] <= avmm_rd_be_reg2[63:0];
         avmm_rd_be_reg4[63:0] <= avmm_rd_be_reg3[63:0];
         avmm_rd_be_reg5[63:0] <= (avmm_rdburst_cnt_reg4 == 7'h1)? avmm_rd_be_reg4[63:0] : 64'hFFFF_FFFF_FFFF_FFFF;
       end else if(BAM_DATAWIDTH == 256) begin
         avmm_rd_be_reg2[31:0] <= avmm_rd_fbe_reg1[31:0] & avmm_rd_lbe_reg1[31:0];
         avmm_rd_be_reg3[31:0] <= avmm_rd_be_reg2[31:0];
         avmm_rd_be_reg4[31:0] <= avmm_rd_be_reg3[31:0];
         avmm_rd_be_reg5[31:0] <= (avmm_rdburst_cnt_reg4 == 7'h1)? avmm_rd_be_reg4[31:0] : 32'hFFFF_FFFF;
       end
     end

 always_ff @(posedge clk)  
   begin
     cpl_tag_reg2[9:0]  <= cpl_tag_reg1;
     cpl_tag_reg3[9:0]  <= cpl_tag_reg2;
     cpl_tag_reg4[9:0]  <= cpl_tag_reg3;
     cpl_tag_reg5[9:0]  <= cpl_tag_reg4;   
     
     cpl_vfactive_reg2  <= cpl_vfactive_reg1;   
     cpl_vfactive_reg3  <= cpl_vfactive_reg2;
     cpl_vfactive_reg4  <= cpl_vfactive_reg3;
     cpl_vfactive_reg5  <= cpl_vfactive_reg4;
     cpl_vfnum_reg2[11:0] <= cpl_vfnum_reg1;
     cpl_vfnum_reg3[11:0] <= cpl_vfnum_reg2;
     cpl_vfnum_reg4[11:0] <= cpl_vfnum_reg3;
     cpl_vfnum_reg5[11:0] <= cpl_vfnum_reg4;
     
     cpl_pfnum_reg2[1:0] <= cpl_pfnum_reg1;     
     cpl_pfnum_reg3[1:0] <= cpl_pfnum_reg2;     
     cpl_pfnum_reg4[1:0] <= cpl_pfnum_reg3;     
     cpl_pfnum_reg5[1:0] <= cpl_pfnum_reg4;     
     
     cpl_req_id_reg2[15:0] <= cpl_req_id_reg1[15:0];
     cpl_req_id_reg3[15:0] <= cpl_req_id_reg2[15:0];
     cpl_req_id_reg4[15:0] <= cpl_req_id_reg3[15:0];
     cpl_req_id_reg5[15:0] <= cpl_req_id_reg4[15:0];
     
     cpl_attr_reg2[2:0]    <=    cpl_attr_reg1;       
     cpl_attr_reg3[2:0]    <=    cpl_attr_reg2;  
     cpl_attr_reg4[2:0]    <=    cpl_attr_reg3;  
     cpl_attr_reg5[2:0]    <=    cpl_attr_reg4;      
     
     flush_be_reg2     <= flush_be_reg1;   
     flush_be_reg3     <= flush_be_reg2;   
     flush_be_reg4     <= flush_be_reg3;   
     flush_be_reg5     <= flush_be_reg4;   


     cpl_tc_reg2[2:0]    <=    cpl_tc_reg1; 
     cpl_tc_reg3[2:0]    <=    cpl_tc_reg2; 
     cpl_tc_reg4[2:0]    <=    cpl_tc_reg3;      
     cpl_tc_reg5[2:0]    <=    cpl_tc_reg4;      
     
     rd_pop_cmd_reg1     <= rd_pop_cmd;
     rd_pop_cmd_reg2     <= rd_pop_cmd_reg1;
     rd_pop_cmd_reg3     <= rd_pop_cmd_reg2;
     rd_pop_cmd_reg4     <= rd_pop_cmd_reg3;         
     
     avmm_rd_bar_reg2[2:0]    <= avmm_rd_bar_reg1;  
     avmm_rd_bar_reg3[2:0]    <= avmm_rd_bar_reg2;
     avmm_rd_bar_reg4[2:0]    <= avmm_rd_bar_reg3;
     avmm_rd_bar_reg5[2:0]    <= avmm_rd_bar_reg4;  
     
     avmm_rdburst_cnt_reg2[6:0] <= avmm_rdburst_cnt_reg1[6:0];
     avmm_rdburst_cnt_reg3[6:0] <= avmm_rdburst_cnt_reg2[6:0];
     avmm_rdburst_cnt_reg4[6:0] <= avmm_rdburst_cnt_reg3[6:0];
     avmm_rdburst_cnt_reg5[6:0] <= avmm_rdburst_cnt_reg4[6:0];
     
     tlp_dw_size_reg2[9:0]    <=  tlp_dw_size_reg1; 
      
   end

/// CPL Lower Address

 always_ff @(posedge clk) 
   case({tlp_lbe_zero_reg1,tlp_fbe_reg1[3:0]})
      {1'b1,4'b0001} : first_invalid_bytes_reg2[1:0] <= 2'h3;
      {1'b1,4'b0010} : first_invalid_bytes_reg2[1:0] <= 2'h3;
      {1'b1,4'b0011} : first_invalid_bytes_reg2[1:0] <= 2'h2;
      {1'b1,4'b0100} : first_invalid_bytes_reg2[1:0] <= 2'h3;
      {1'b1,4'b0101} : first_invalid_bytes_reg2[1:0] <= 2'h1;
      {1'b1,4'b0110} : first_invalid_bytes_reg2[1:0] <= 2'h2;
      {1'b1,4'b0111} : first_invalid_bytes_reg2[1:0] <= 2'h1;
      {1'b1,4'b1000} : first_invalid_bytes_reg2[1:0] <= 2'h3;
      {1'b1,4'b1010} : first_invalid_bytes_reg2[1:0] <= 2'h1;
      {1'b1,4'b1100} : first_invalid_bytes_reg2[1:0] <= 2'h2;
      {1'b1,4'b1110} : first_invalid_bytes_reg2[1:0] <= 2'h1;
      {1'b0,4'b0010} : first_invalid_bytes_reg2[1:0] <= 2'h1;  
      {1'b0,4'b0100} : first_invalid_bytes_reg2[1:0] <= 2'h2;  
      {1'b0,4'b0110} : first_invalid_bytes_reg2[1:0] <= 2'h1;  
      {1'b0,4'b1000} : first_invalid_bytes_reg2[1:0] <= 2'h3;  
      {1'b0,4'b1010} : first_invalid_bytes_reg2[1:0] <= 2'h1;  
      {1'b0,4'b1100} : first_invalid_bytes_reg2[1:0] <= 2'h2;  
      {1'b0,4'b1110} : first_invalid_bytes_reg2[1:0] <= 2'h1;  
      default:  first_invalid_bytes_reg2[1:0] <= 2'h0;
    endcase


  always_ff @(posedge clk) 
   case(tlp_fbe_reg1[3:0])
      4'b0010 : lower_addr_offset_reg2[1:0] <= 2'b01;
      4'b0100 : lower_addr_offset_reg2[1:0] <= 2'b10;
      4'b1000 : lower_addr_offset_reg2[1:0] <= 2'b11;
      4'b0110 : lower_addr_offset_reg2[1:0] <= 2'b01;
      4'b1100 : lower_addr_offset_reg2[1:0] <= 2'b10;
      4'b1110 : lower_addr_offset_reg2[1:0] <= 2'b01;
      default:  lower_addr_offset_reg2[1:0] <= 2'b00;
    endcase
   

always_ff @(posedge clk) 
   casex(tlp_lbe_reg1[3:0])
    4'b01xx : last_invalid_bytes_reg2[1:0] <= 2'h1;
    4'b001x : last_invalid_bytes_reg2[1:0] <= 2'h2;
    4'b0001 : last_invalid_bytes_reg2[1:0] <= 2'h3;
    default:  last_invalid_bytes_reg2[1:0] <= 2'h0;     
   endcase


always_ff @(posedge clk)     
    last_invalid_bytes_reg3[1:0] <= last_invalid_bytes_reg2[1:0];

 always_ff @(posedge clk)  
     if(rd_pop_cmd_reg2) begin
          if(BAM_DATAWIDTH == 1024) begin //modified to cater 1024 and 256bit
            cpl_lower_addr_reg3[7:0] <= {cpl_lower_addr_reg2[7:2], lower_addr_offset_reg2[1:0]};
          end else if(BAM_DATAWIDTH == 512) begin
            cpl_lower_addr_reg3[7:0] <= {cpl_lower_addr_reg2[6:2], lower_addr_offset_reg2[1:0]};
          end else if(BAM_DATAWIDTH == 256) begin
            cpl_lower_addr_reg3[7:0] <= {cpl_lower_addr_reg2[5:2], lower_addr_offset_reg2[1:0]};
          end
    end else if(rd_type_1_cmd_valid_reg3 | rd_type_2_cmd_valid_reg3) begin /// discard after used
     cpl_lower_addr_reg3[7:0] <= 8'h0;
    end

 always_ff @(posedge clk)  
   begin
   	 cpl_lower_addr_reg2[7:0] <= cpl_lower_addr_reg1[7:0];
     cpl_lower_addr_reg4[7:0] <= cpl_lower_addr_reg3[7:0];
     cpl_lower_addr_reg5[7:0] <= cpl_lower_addr_reg4[7:0];   
   end     

/// remain bytes [11:0]
 always_ff @(posedge clk) 
   begin
	    total_rd_bytes_reg3[11:0] <= {tlp_dw_size_reg2[9:0],2'b00} - first_invalid_bytes_reg2;
      total_rd_bytes_reg4[11:0] <= flush_be_reg3? 12'h1: (total_rd_bytes_reg3[11:0] - last_invalid_bytes_reg3);
   end

 always_ff @(posedge clk) 
  begin
    tlp_bytes_size_type_1_reg3[9:0] <= {tlp_dw_size_type_1_reg2[7:0], 2'b00}- first_invalid_bytes_reg2;
    tlp_bytes_size_type_1_reg4[9:0] <= tlp_bytes_size_type_1_reg3;
  end

always_ff @(posedge clk)
  if(rd_pop_cmd_reg4)
    remain_bytes_reg5[11:0] <= total_rd_bytes_reg4[11:0]; 
  else if(rd_type_1_cmd_valid_reg5 | rd_first_type_2_cmd_valid_reg5)  /// use reg5 due to the fact "used and discard"
    remain_bytes_reg5[11:0] <= remain_bytes_reg5[11:0] - tlp_bytes_size_type_1_reg4[9:0];
  else if(rd_type_2_cmd_valid_reg5) /// use reg5 due to the fact "used and discard"
     remain_bytes_reg5[11:0] <= remain_bytes_reg5[11:0] - {tlp_dw_size_type_2_reg4[7:0],2'b00};


 //// AVMM Read Commands
 assign avmm_rd = rd_cmd_valid_reg5;
 assign avmm_rd_address[63:0] =  tlp_start_addr_reg5;
 assign avmm_rd_burst_cnt[3:0] = avmm_read_bcnt_reg5;
  if(BAM_DATAWIDTH == 1024) begin
    assign avmm_rd_be[127:0] =  avmm_rd_be_reg5[127:0];
  end else if(BAM_DATAWIDTH == 512) begin
    assign avmm_rd_be[63:0] =  avmm_rd_be_reg5[63:0];
  end else if(BAM_DATAWIDTH == 256) begin
    assign avmm_rd_be[31:0] =  avmm_rd_be_reg5[31:0];
  end

 assign avmm_rd_vfnum[11:0] =  cpl_vfnum_reg5;               
 assign avmm_rd_pfnum[1:0]  =  cpl_pfnum_reg5;   
 assign avmm_rd_vfactive = cpl_vfactive_reg5;              
 assign avmm_rd_bar[2:0]    =  avmm_rd_bar_reg5;  
 
 always_ff @(posedge clk) 
     avmm_address_reg4 <= wr_pop_cmd_reg3? avmm_address_reg3 : avmmwr_address_plus_8_reg3;
                
 assign avmm_wr = wr_pop_cmd_reg4 | xtra_wrcmd_reg4;
 assign avmm_wr_address = avmm_address_reg4;
 assign avmm_wr_burst_cnt[3:0] = avmm_burst_cnt_reg4;
 if(BAM_DATAWIDTH == 1024) begin
  assign avmm_wr_be[127:0] = 128'hFFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF;  /// not used
  end else if(BAM_DATAWIDTH == 512) begin
  assign avmm_wr_be[63:0] = 64'hFFFF_FFFF_FFFF_FFFF;  /// not used
  end else if(BAM_DATAWIDTH == 256) begin
  assign avmm_wr_be[31:0] = 32'hFFFF_FFFF;  /// not used
  end

 assign avmm_wr_vfnum[11:0]    = avmm_vfnum_reg4[11:0];   
 assign avmm_wr_pfnum[1:0]     = avmm_pfnum_reg4[1:0];
 assign avmm_wr_vfactive       = avmm_vfactive_reg4; 
 assign avmm_wr_bar[2:0]       = avmm_bar_reg4[2:0];
 
 
always_ff @(posedge clk)        
  begin
  	cmd_is_write_reg   <= avmm_wr;                                          // 1
  	cmd_addr_reg[63:0] <= avmm_wr?  avmm_wr_address :  avmm_rd_address;     // 64
  	cmd_bcnt_reg[3:0]  <= avmm_wr?  avmm_wr_burst_cnt : avmm_rd_burst_cnt;  // 4
        if(BAM_DATAWIDTH == 1024) begin
        cmd_be_reg[127:0]   <= avmm_wr?  avmm_wr_be[127:0] : avmm_rd_be[127:0];                // 64
        end else if(BAM_DATAWIDTH == 512) begin
        cmd_be_reg[63:0]   <= avmm_wr?  avmm_wr_be[63:0] : avmm_rd_be[63:0];                // 64
        end else if(BAM_DATAWIDTH == 256) begin
        cmd_be_reg[31:0]   <= avmm_wr?  avmm_wr_be[31:0] : avmm_rd_be[31:0];                // 64
        end

  	cmd_vfnum[11:0]    <= avmm_wr?  avmm_wr_vfnum : avmm_rd_vfnum;          // 12
  	cmd_pfnum[1:0]     <= avmm_wr?  avmm_wr_pfnum : avmm_rd_pfnum;          // 3
  	cmd_vfactive       <= avmm_wr?  avmm_wr_vfactive : avmm_rd_vfactive;     // 1   
  	cmd_bar[2:0]       <= avmm_wr?  avmm_wr_bar : avmm_rd_bar;
  	cmd_wrreq_reg      <= avmm_wr | avmm_rd;
  end
 
 assign avmm_cmd_fifo_wrreq        =   cmd_wrreq_reg;
 generate
   if(BAM_DATAWIDTH == 1024) begin
      assign avmm_cmd_fifo_data[214:0]  =   {cmd_is_write_reg,cmd_bar, cmd_vfactive, cmd_pfnum, cmd_vfnum, cmd_bcnt_reg, cmd_be_reg[127:0], cmd_addr_reg };


scfifo  avmm_cmd_fifo (
      .clock                            (clk),
      .data                             (avmm_cmd_fifo_data[214:0]),
      .rdreq                            (avmm_cmd_fifo_rdreq_i),
      .wrreq                            (avmm_cmd_fifo_wrreq),
      .almost_full                      (avmm_cmd_almost_full),
      .full                             (),
      .q                                (avmm_cmd_fifo_rddata_o[214:0]),
      .aclr                             (1'b0),
      .almost_empty                     (),
      .eccstatus                        (),
      .empty                            (avmm_cmd_fifo_empty_o),
      .sclr                             (srst_reg),
      .usedw                            ());
  defparam
      avmm_cmd_fifo.add_ram_output_register  = "ON",
      avmm_cmd_fifo.almost_full_value  = 16,
      avmm_cmd_fifo.enable_ecc  = "FALSE",
      avmm_cmd_fifo.intended_device_family  = "Agilex 7",
      avmm_cmd_fifo.lpm_hint  = "AUTO",
      avmm_cmd_fifo.lpm_numwords  = 32,
      avmm_cmd_fifo.lpm_showahead  = "ON",
      avmm_cmd_fifo.lpm_type  = "scfifo",
      avmm_cmd_fifo.lpm_width  = (215),
      avmm_cmd_fifo.lpm_widthu  = 5,
      avmm_cmd_fifo.overflow_checking  = "OFF",
      avmm_cmd_fifo.underflow_checking  = "OFF",
      avmm_cmd_fifo.use_eab  = "ON";

   end else if(BAM_DATAWIDTH == 512) begin
 assign avmm_cmd_fifo_data[150:0]  =   {cmd_is_write_reg,cmd_bar, cmd_vfactive, cmd_pfnum, cmd_vfnum, cmd_bcnt_reg, cmd_be_reg[63:0], cmd_addr_reg };


scfifo  avmm_cmd_fifo (
      .clock                            (clk),
      .data                             (avmm_cmd_fifo_data[150:0]),
      .rdreq                            (avmm_cmd_fifo_rdreq_i),
      .wrreq                            (avmm_cmd_fifo_wrreq),
      .almost_full                      (avmm_cmd_almost_full),
      .full                             (),
      .q                                (avmm_cmd_fifo_rddata_o[150:0]),
      .aclr                             (1'b0),
      .almost_empty                     (),
      .eccstatus                        (),
      .empty                            (avmm_cmd_fifo_empty_o),
      .sclr                             (srst_reg),
      .usedw                            ());
  defparam
      avmm_cmd_fifo.add_ram_output_register  = "ON",
      avmm_cmd_fifo.almost_full_value  = 16,
      avmm_cmd_fifo.enable_ecc  = "FALSE",
      avmm_cmd_fifo.intended_device_family  = "Agilex 7",
      avmm_cmd_fifo.lpm_hint  = "AUTO",
      avmm_cmd_fifo.lpm_numwords  = 32,
      avmm_cmd_fifo.lpm_showahead  = "ON",
      avmm_cmd_fifo.lpm_type  = "scfifo",
      avmm_cmd_fifo.lpm_width  = (151),
      avmm_cmd_fifo.lpm_widthu  = 5,
      avmm_cmd_fifo.overflow_checking  = "OFF",
      avmm_cmd_fifo.underflow_checking  = "OFF",
      avmm_cmd_fifo.use_eab  = "ON";

assign avmm_cmd_fifo_rddata_o[214:151] = 64'h0;

   end else if(BAM_DATAWIDTH == 256) begin
 assign avmm_cmd_fifo_data[118:0]  =   {cmd_is_write_reg,cmd_bar, cmd_vfactive, cmd_pfnum, cmd_vfnum, cmd_bcnt_reg, cmd_be_reg[31:0], cmd_addr_reg };


scfifo  avmm_cmd_fifo (
      .clock                            (clk),
      .data                             (avmm_cmd_fifo_data[118:0]),
      .rdreq                            (avmm_cmd_fifo_rdreq_i),
      .wrreq                            (avmm_cmd_fifo_wrreq),
      .almost_full                      (avmm_cmd_almost_full),
      .full                             (),
      .q                                (avmm_cmd_fifo_rddata_o[118:0]),
      .aclr                             (1'b0),
      .almost_empty                     (),
      .eccstatus                        (),
      .empty                            (avmm_cmd_fifo_empty_o),
      .sclr                             (srst_reg),
      .usedw                            ());
  defparam
      avmm_cmd_fifo.add_ram_output_register  = "ON",
      avmm_cmd_fifo.almost_full_value  = 16,
      avmm_cmd_fifo.enable_ecc  = "FALSE",
      avmm_cmd_fifo.intended_device_family  = "Agilex 7",
      avmm_cmd_fifo.lpm_hint  = "AUTO",
      avmm_cmd_fifo.lpm_numwords  = 32,
      avmm_cmd_fifo.lpm_showahead  = "ON",
      avmm_cmd_fifo.lpm_type  = "scfifo",
      avmm_cmd_fifo.lpm_width  = (119),
      avmm_cmd_fifo.lpm_widthu  = 5,
      avmm_cmd_fifo.overflow_checking  = "OFF",
      avmm_cmd_fifo.underflow_checking  = "OFF",
      avmm_cmd_fifo.use_eab  = "ON";

assign avmm_cmd_fifo_rddata_o[214:119] = 96'h0;

   end
 endgenerate
 
 /// Pending completion cmd FIFO
 assign cpl_cmd_dwlen[7:0]    = tlp_dw_size_type_reg5;   // 8    
 assign cpl_attr[2:0]         = cpl_attr_reg5;           // 3
 assign cpl_tc[2:0]           = cpl_tc_reg5;             // 3
 assign cpl_bytes_count[11:0] = remain_bytes_reg5;       // 12
 assign cpl_lower_address[7:0]= cpl_lower_addr_reg5;     // 7
 assign cpl_tag[9:0]          = cpl_tag_reg5;            // 10
 assign cpl_reqster[15:0]     = cpl_req_id_reg5;         // 16
 
 assign avmm_lines_cnt[3:0]   = avmm_read_bcnt_reg5[3:0];
 assign cpl_vfpf[15:0] = {cpl_vfnum_reg5[11:0], 2'b00, cpl_pfnum_reg5[1:0]};
 assign cpl_vf_active  = cpl_vfactive_reg5;
 assign cpl_cmd[80:0]  = {cpl_vf_active,cpl_vfpf[15:0],avmm_lines_cnt[3:0],cpl_reqster[15:0], cpl_tag[9:0], cpl_lower_address[7:0], cpl_bytes_count[11:0], cpl_tc[2:0], cpl_attr[2:0], cpl_cmd_dwlen[7:0]};
 assign cpl_cmd_wrreq  = rd_cmd_valid_reg5;
 
 scfifo  cpl_cmd_fifo (
      .clock                            (clk),
      .data                             (cpl_cmd),
      .rdreq                            (cpl_cmd_fifo_rdreq_i), 
      .wrreq                            (cpl_cmd_wrreq),
      .almost_full                      (cpl_cmd_almost_full),
      .full                             (),
      .q                                (cpl_cmd_fifo_rddata_o),
      .aclr                             (1'b0),
      .almost_empty                     (),   
      .eccstatus                        (),
      .empty                            (cpl_cmd_fifo_empty_o),
      .sclr                             (srst_reg),
      .usedw                            ());
  defparam
      cpl_cmd_fifo.add_ram_output_register  = "ON",
      cpl_cmd_fifo.almost_full_value  = 16,
      cpl_cmd_fifo.enable_ecc  = "FALSE",
      cpl_cmd_fifo.intended_device_family  = "Agilex 7",
      cpl_cmd_fifo.lpm_hint  = "AUTO",
      cpl_cmd_fifo.lpm_numwords  = 32,
      cpl_cmd_fifo.lpm_showahead  = "ON",
      cpl_cmd_fifo.lpm_type  = "scfifo",
      cpl_cmd_fifo.lpm_width  = (81),
      cpl_cmd_fifo.lpm_widthu  = 5,
      cpl_cmd_fifo.overflow_checking  = "OFF",
      cpl_cmd_fifo.underflow_checking  = "OFF",
      cpl_cmd_fifo.use_eab  = "ON";
 
 
 
 assign preproc_cmd_fifo_read_o = wr_pop_cmd | rd_pop_cmd;     
 assign rx_data_fifo_rdreq_o = buffer_data_rd_reg;

 always_ff @ (posedge clk)
      if (srst_reg)
        bam_np_hdr_credit <= 7'h20; //default to support 32 tags with 32 read requests
      else if(rd_pop_cmd)
        bam_np_hdr_credit <= bam_np_hdr_credit + 1'b1;
 
assign bam_np_hdr_credit_o =  bam_np_hdr_credit;    
assign write_done_o = wr_pop_cmd;



endmodule

 
