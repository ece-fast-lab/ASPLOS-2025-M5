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
//  Module Name :  intel_cxl_default_config                                 
//  Author      :  ochittur                                   
//  Date        :  Aug 22, 2022                                 
//  Description :  Generation of UR for incoming TLP's
//-----------------------------------------------------------------------------

import intel_cxl_pio_parameters :: *;

module intel_cxl_default_config (
     input                                clk,
     input			          rst_n,
     input  logic [2:0]                   default_config_rx_bar,
     input  logic                         default_config_rx_sop_i,
     input  logic                         default_config_rx_eop_i,
     input  logic [127:0]                 default_config_rx_header_i,
     input  logic [BAM_DATAWIDTH-1:0]     default_config_rx_payload_i,
     input  logic                         default_config_rx_valid_i,
     input  logic [7:0]			  default_config_rx_bus_number,
     input  logic [4:0]			  default_config_rx_device_number,
     input  logic [2:0]			  default_config_rx_function_number,
     output logic			  default_config_rx_st_ready_o,
     input  logic			  default_config_tx_st_ready_i,
     output logic                         default_config_txc_eop,
     output logic [127:0]                 default_config_txc_header,
     output logic [BAM_DATAWIDTH-1:0]     default_config_txc_payload,
     output logic                         default_config_txc_sop,
     output logic                         default_config_txc_valid,
     output logic  		          ed_tx_st0_passthrough_o

);


logic          [9:0]                dc_hdr_len_o;                                  
logic                               dc_hdr_valid_o;                                
logic                               dc_hdr_is_rd_o;                                
logic                               dc_hdr_is_rd_with_data_o;                      
logic                               dc_hdr_is_wr_no_data_o;                        
logic                               dc_hdr_is_cpl_no_data_o;                       
logic                               dc_hdr_is_cpl_o;                               
logic                               dc_hdr_is_wr_o;                                
logic                               dc_bam_rx_signal_ready_o;                      
logic                               dc_tx_hdr_valid_o;                             
logic                               default_config_rx_sop;                         
logic                               default_config_rx_eop;                         
logic          [127:0]              default_config_rx_header;                      
logic          [BAM_DATAWIDTH-1:0]  default_config_rx_payload;                     
logic                               default_config_rx_valid;                       
//completions  should not be sent for  Mem_Wr,Msg,MsgD
//                                                                                 
logic                               Mem_Wr_tlp;                                    
logic                               Msg_tlp;                                       
logic                               MsgD_tlp;                                      
logic                               Mem_Rd_tlp;                                    
logic                               Mem_Rd_tlp_f;                                  
logic                               drop_tlp;                                      
//store in fifo and read          
logic          [133:0]              rx_tlp_fifo_indata;                  
logic          [133:0]              rx_tlp_fifo_outdata;                           
logic                               rx_tlp_fifo_wr_req;                            
logic                               rx_tlp_fifo_rd_req;                            
logic                               rx_tlp_fifo_almost_full;                       
logic                               rx_tlp_fifo_empty;                             
logic          [127:0]              UR_header;                  
logic                               reserved =    1'b0;         
logic          [6:0]                lower_address;                                 
logic          [15:0]               requester_id;                  
logic          [9:0]                tag;                  
logic          [2:0]                attr;                                          
logic          [2:0]                tc;                                            
logic          [2:0]                cpl_status =    3'b001;       
logic                               bcm        =    1'b0;         
logic          [11:0]               byte_count;                                    
logic          [15:0]               completer_id;                                  
logic          [31:0]               tx_first_dword;                                
logic          [31:0]               tx_second_dword;                               
logic          [31:0]               tx_third_dword;                                
logic          [31:0]               tx_fourth_dword;                               
logic          [2:0]                fmt        =    3'b0;         
logic          [4:0]                type_field =    5'hA;    //A  
logic          [9:0]                length     =    10'd0;        
logic          [13:0]               first_dword_misc;                              
logic          [31:0]               rx_first_dword;                                
logic          [31:0]               rx_second_dword;                               
logic          [31:0]               rx_third_dword;                                
logic          [31:0]               rx_fourth_dword;                               



assign  Mem_Wr_tlp      =  (default_config_rx_header_i[31:29]==3'b010  ||  default_config_rx_header_i[31:29]==3'b011)  &&  (default_config_rx_header_i[28:24]  ==  5'h0);
assign  Msg_tlp         =  (default_config_rx_header_i[31:29]          ==  3'b001)                                     &&  (default_config_rx_header_i[28:27]  ==  2'b10);
assign  MsgD_tlp        =  (default_config_rx_header_i[31:29]          ==  3'b011)                                     &&  (default_config_rx_header_i[28:27]  ==  2'b10);
assign  drop_tlp        =  Mem_Wr_tlp                                  ||  Msg_tlp                                     ||  MsgD_tlp;                               
assign  Mem_Rd_tlp      =  (default_config_rx_header_i[31:29]==3'b000  ||  default_config_rx_header_i[31:29]==3'b001)  &&  (default_config_rx_header_i[28:24]  ==  5'h0);
assign  dc_hdr_len_o    =  default_config_rx_header_i[9:0];                                                                                                        
assign  dc_hdr_valid_o  =  default_config_rx_valid_i;                                                                                                              
assign  dc_hdr_is_wr_o  =  (default_config_rx_header_i[30]             &   (default_config_rx_header_i[28:24]          ==  5'h0))                              ||  
       			    (default_config_rx_header_i[31:29]         ==  3'b011); 
assign  dc_hdr_is_wr_no_data_o   =  (default_config_rx_header_i[31:27]             ==  5'b00110                                            );
assign  dc_hdr_is_cpl_no_data_o  =  (default_config_rx_header_i[31:24]             ==  8'b0000_1010);                                      
assign  dc_hdr_is_cpl_o          =  (default_config_rx_header_i[31:27]==5'b01001)  ||  (default_config_rx_header_i[31:24]==8'b0000_1011);  


//--
assign  tx_first_dword              =  {fmt,type_field,tag[9],tc,tag[8],attr[2],4'h0,attr[1:0],2'h0,length};                                                                    
assign  tx_second_dword             =  {completer_id,cpl_status,bcm,byte_count};                                                                                                
assign  tx_third_dword              =  {requester_id,tag[7:0],reserved,lower_address};                                                                                          
assign  tx_fourth_dword             =  32'b0;                                                                                                                                   
assign  UR_header                   =  {tx_fourth_dword,tx_third_dword,tx_second_dword,tx_first_dword};                                                                         
assign  rx_tlp_fifo_indata          =  {default_config_rx_bar,default_config_rx_sop,default_config_rx_eop,UR_header,default_config_rx_valid};                                   
assign  rx_tlp_fifo_rd_req          =  default_config_tx_st_ready_i &  (!rx_tlp_fifo_empty);         
assign  rx_tlp_fifo_wr_req          =  default_config_rx_valid;                                                                                                                 
assign  default_config_txc_sop      =  rx_tlp_fifo_indata[130];                                                                                                                  
assign  default_config_txc_eop      =  rx_tlp_fifo_indata[129];                                                                                                                 
assign  default_config_txc_payload  =  1024'h0;//BAM_DATAWIDTH'b0;                                                                                                              
assign  default_config_txc_valid    =  rx_tlp_fifo_indata[0];                                                                                                                   
assign  default_config_txc_header   =  default_config_txc_valid ?  rx_tlp_fifo_indata[128:1]  :  128'h0;
assign  dc_bam_rx_signal_ready_o    =  default_config_rx_st_ready_o;                                                                                                            
assign  dc_tx_hdr_valid_o           =  default_config_rx_valid_i;                                                                                                               
assign  ed_tx_st0_passthrough_o     =  default_config_txc_valid ?  1'b1 :  1'b0;

//decode header
assign  rx_first_dword              =  default_config_rx_header[31:0];
assign  rx_second_dword             =  default_config_rx_header[63:32];
assign  rx_third_dword              =  default_config_rx_header[95:64];
assign  rx_fourth_dword             =  default_config_rx_header[127:96];

//send UR

assign  first_dword_misc            =  rx_first_dword[23:10];                                                                                           
assign  completer_id                =  {default_config_rx_bus_number,default_config_rx_device_number,3'h0};                                             
//if mem_rd, UR should send proper byte count
assign  byte_count                  =  Mem_Rd_tlp_f ?  ({2'h0,rx_first_dword[9:0]}  <<  2)  :  12'h4;
assign  requester_id                =  rx_second_dword[31:16];
assign  tag                         =  {rx_first_dword[23],rx_first_dword[19],rx_second_dword[15:8]};
assign  attr                        =  {rx_first_dword[18],rx_first_dword[13:12]};
assign  tc                          =  rx_first_dword[22:20];
assign  lower_address               = (default_config_rx_header[31:24] == 8'h0)         ? {rx_third_dword[6:2],2'h0}  :
                                        (default_config_rx_header[31:24] == 8'b0010_0000) ? {rx_fourth_dword[6:2],2'h0} :7'd0;


always_ff@(posedge clk or negedge rst_n)
begin
	if(!rst_n)
	begin
		default_config_rx_sop 	<= 1'b0; 
		default_config_rx_eop 	<= 1'b0;
		default_config_rx_header<= 128'h0;
		default_config_rx_valid <= 1'h0;
                Mem_Rd_tlp_f            <= 1'h0;
	end
	else
	begin
		default_config_rx_sop 	<=  drop_tlp ? 1'h0   : default_config_rx_sop_i ; 	
		default_config_rx_eop 	<=  drop_tlp ? 1'h0   : default_config_rx_eop_i ; 	
		default_config_rx_header<=  drop_tlp ? 128'h0 : default_config_rx_header_i ;
		default_config_rx_valid <=  drop_tlp ? 1'h0   : default_config_rx_valid_i ; 
                Mem_Rd_tlp_f  <= Mem_Rd_tlp;
	end
end



//--
//TLP_TYPE   [31:24]  TYPE  HEADER  DATA
//MRd        0000000  NP    y       y
//MRd        0100000  NP    y       y
//MRdLk      0000001  NP    y       y
//MRdLk      0100001  NP    y       y
//IORd       0000010  NP    y       y
//IOWr       1000010  NP    y       y
//CfgRd0     0000100  NP    y       y
//CfgWr0     1000100  NP    y       y
//CfgRd1     0000101  NP    y       y
//CfgWr1     1000101  NP    y       y
//MWr        1000000  P     y       y
//MWr        1100000  P     y       y
//Msg        0110xxx  p     y       n
//MsgD       1110xxx  p     y       Y
//--------          
//Cpl        0001010  C     y       n
//CplD       1001010  C     y       y
//CplLk      0001011  C     y       y
//CplDLk     1001011  C     y       y

always_comb
begin
	case(default_config_rx_header_i[31:24])
		8'b00000000: dc_hdr_is_rd_o 		= 1'b1;
		8'b00100000: dc_hdr_is_rd_o 		= 1'b1;
		8'b00000001: dc_hdr_is_rd_o 		= 1'b1;
		8'b00100001: dc_hdr_is_rd_o 		= 1'b1;
		8'b00000010: dc_hdr_is_rd_o 		= 1'b1;
		8'b00000100: dc_hdr_is_rd_o 		= 1'b1;
		8'b00000101: dc_hdr_is_rd_o 		= 1'b1;
		default   : dc_hdr_is_rd_o		= 1'b0;
	endcase
end

always_comb
begin
	case(default_config_rx_header_i[31:24])
		8'b01000010: dc_hdr_is_rd_with_data_o 	= 1'b1;
		8'b01000100: dc_hdr_is_rd_with_data_o	= 1'b1;
		8'b01000101: dc_hdr_is_rd_with_data_o	= 1'b1;
		default    : dc_hdr_is_rd_with_data_o   = 1'b0;
	endcase
end


always_ff@(posedge clk)
begin
	if(!rst_n) default_config_rx_st_ready_o <= 1'b0;
	else default_config_rx_st_ready_o <= 1'b1;
end //always_ff


	   
endmodule //intel_cxl_default_config
