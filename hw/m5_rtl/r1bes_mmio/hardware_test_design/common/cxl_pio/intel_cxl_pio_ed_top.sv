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
//  Module Name :  intel_cxl_pio_ed_top                                 
//  Author      :  ochittur                                   
//  Date        :  Aug 22, 2022                                 
//  Description :  Top file for PIO 
//-----------------------------------------------------------------------------

//`include "intel_cxl_pio_parameters.svh"
import intel_cxl_pio_parameters :: *;
//`default_nettype none
module intel_cxl_pio_ed_top (
     		input              	 Clk_i		     ,
     		input              	 Rstn_i		     ,
		input  logic [2:0]       pio_rx_bar          ,
		input  logic             pio_rx_eop          ,
		input  logic [127:0]     pio_rx_header       ,
		input  logic [511:0]     pio_rx_payload      ,
		input  logic             pio_rx_sop          ,
		input  logic             pio_rx_valid        ,
		output logic             pio_rx_ready        ,
		output logic             pio_txc_eop         ,
		output logic [127:0]     pio_txc_header      ,
		output logic [255:0]     pio_txc_payload     ,
		output logic             pio_txc_sop         ,
		output logic             pio_txc_valid       ,
     		output logic           	  pio_to_send_cpl    , //pio about to send output
		input  logic         	 pio_txc_ready	     ,
     		input 	     [7:0]	 ed_rx_bus_number    ,
     		input 	     [4:0]	 ed_rx_device_number 

);

// declarations

logic 		rst_controller_reset_out_reset;
logic [PFNUM_WIDTH-1:0] pio_rx_pfnum;
logic         	pio_rx_vfactive;
logic [VFNUM_WIDTH-1:0] pio_rx_vfnum;

logic [9:0]  	for_rxcrdt_tlp_len;
logic        	for_rxcrdt_hdr_valid;
logic        	for_rxcrdt_hdr_is_rd;
logic        	for_rxcrdt_hdr_is_wr;

logic [7:0]     default_config_rx_bus_number;
logic [4:0]     default_config_rx_device_number;
logic [2:0]     default_config_rx_function_number;
logic [7:0]     pio_rx_bus_number;
logic [4:0]     pio_rx_device_number;
logic [2:0]     pio_rx_function_number;


logic           tx_hdr_fifo_rreq ;
logic           tx_hdr_fifo_empty ;
logic  [96:0]   tx_hdr_fifo_rdata ;
logic  [8:0]    cplram_rd_addr ;
logic  [BAM_DATAWIDTH+1:0]  cplram_rd_data ;
logic           cpl_cmd_fifo_rdreq ;
logic  [80:0]   cpl_cmd_fifo_rddata ;
logic           cpl_cmd_fifo_empty ;
logic           cpl_ram_rdreq ; 
logic           avmm_read_data_valid ;
logic  [BAM_DATAWIDTH:0]    cplram_read_data ;



// mm_interconnect <--> mem0
logic           mm_interconnect_0_mem0_s1_chipselect;        // mm_interconnect_0:MEM0_s1_chipselect -> MEM0:chipselect
logic  [1023:0] mm_interconnect_0_mem0_s1_readdata;          // MEM0:readdata -> mm_interconnect_0:MEM0_s1_readdata
logic     [7:0] mm_interconnect_0_mem0_s1_address;           // mm_interconnect_0:MEM0_s1_address -> MEM0:address
logic   [127:0] mm_interconnect_0_mem0_s1_byteenable;        // mm_interconnect_0:MEM0_s1_byteenable -> MEM0:byteenable
logic           mm_interconnect_0_mem0_s1_write;             // mm_interconnect_0:MEM0_s1_write -> MEM0:write
logic  [1023:0] mm_interconnect_0_mem0_s1_writedata;         // mm_interconnect_0:MEM0_s1_writedata -> MEM0:writedata
logic           mm_interconnect_0_mem0_s1_clken;             // mm_interconnect_0:MEM0_s1_clken -> MEM0:clken

//pio <--> mm_interconnect
logic  [1023:0] pio0_pio_master_readdata;                    // mm_interconnect_0:pio0_pio_master_readdata -> pio0:pio_readdata_i
logic           pio0_pio_master_waitrequest;                 // mm_interconnect_0:pio0_pio_master_waitrequest -> pio0:pio_waitrequest_i
logic    [63:0] pio0_pio_master_address;                     // pio0:pio_address_o -> mm_interconnect_0:pio0_pio_master_address
logic           pio0_pio_master_read;                        // pio0:pio_read_o -> mm_interconnect_0:pio0_pio_master_read
logic   [127:0] pio0_pio_master_byteenable;                  // pio0:pio_byteenable_o -> mm_interconnect_0:pio0_pio_master_byteenable
logic           pio0_pio_master_readdatavalid;               // mm_interconnect_0:pio0_pio_master_readdatavalid -> pio0:pio_readdatavalid_i
logic     [1:0] pio0_pio_master_response;                    // mm_interconnect_0:pio0_pio_master_response -> pio0:pio_response_i
logic           pio0_pio_master_write;                       // pio0:pio_write_o -> mm_interconnect_0:pio0_pio_master_write
logic  [1023:0] pio0_pio_master_writedata;                   // pio0:pio_writedata_o -> mm_interconnect_0:pio0_pio_master_writedata
logic     [3:0] pio0_pio_master_burstcount;                  // pio0:pio_burstcount_o -> mm_interconnect_0:pio0_pio_master_burstcount

logic pio_rst_n;
logic pio_clk;

    assign pio_clk = Clk_i;

always_ff@(posedge pio_clk)
begin
	pio_rst_n <= Rstn_i;
end



assign pio_rx_pfnum 	= 2'h1;//2'b0;
assign pio_rx_vfactive  = 1'b0;
assign pio_rx_vfnum     = {VFNUM_WIDTH{1'b0}};

assign  pio_rx_bus_number       =  ed_rx_bus_number;                                                                                       
assign  pio_rx_device_number    =  ed_rx_device_number;                                                                                    
assign  pio_rx_function_number  =  pio_rx_pfnum;//ed_rx_st_pfnum_i  ;  //|  ed_rx_st1_pfnum_i  |  ed_rx_st2_pfnum_i  |  ed_rx_st3_pfnum_i  ;




//--tx


generate if(ENABLE_ONLY_PIO || ENABLE_BOTH_DEFAULT_CONFIG_PIO)
begin: PIO_AVST


// pio top module
//
intel_cxl_pio pio(

		.clk                       (             pio_clk                        ),
		.rst_n                     (             pio_rst_n                      ),
		//--avst signals                                      
		.bam_rx_bar_i              (             pio_rx_bar[2:0]                ),
		.bam_rx_eop_i              (             pio_rx_eop                     ),
		.bam_rx_header_i           (             pio_rx_header[127:0]           ),
		.bam_rx_payload_i          (             pio_rx_payload                 ),
		.bam_rx_pfnum_i            (             pio_rx_pfnum                   ),
		.bam_rx_sop_i              (             pio_rx_sop                     ),
		.bam_rx_valid_i            (             pio_rx_valid                   ),
		.bam_rx_vfactive_i         (             pio_rx_vfactive                ),
		.bam_rx_vfnum_i            (             pio_rx_vfnum                   ),
		.bam_rx_ready_o            (             pio_rx_ready                   ),
		.bam_txc_eop_o             (             pio_txc_eop                    ),
		.bam_txc_header_o          (             pio_txc_header[127:0]          ),
		.bam_txc_payload_o         (             pio_txc_payload                ),
		.bam_txc_sop_o             (             pio_txc_sop                    ),
		.bam_txc_valid_o           (             pio_txc_valid                  ),
		.dev_mps                   (             3'b0                           ),
    		.pio_to_send_cpl	   (		 pio_to_send_cpl		),
		//==mem interconnect                                 
		.bam_address_o             (             pio0_pio_master_address        ),
		.bam_read_o                (             pio0_pio_master_read           ),
		.bam_readdata_i            (             pio0_pio_master_readdata       ),
		.bam_readdatavalid_i       (             pio0_pio_master_readdatavalid  ),
		.bam_write_o               (             pio0_pio_master_write          ),
		.bam_writedata_o           (             pio0_pio_master_writedata      ),
		.bam_waitrequest_i         (             pio0_pio_master_waitrequest    ),
		.bam_byteenable_o          (             pio0_pio_master_byteenable     ),
		.bam_response_i            (             pio0_pio_master_response       ),
		.bam_burstcount_o          (             pio0_pio_master_burstcount     ),
		//==crdt intf signals                        
		.for_rxcrdt_tlp_len_o      (             for_rxcrdt_tlp_len             ),
		.for_rxcrdt_hdr_valid_o    (             for_rxcrdt_hdr_valid           ),
		.for_rxcrdt_hdr_is_rd_o    (             for_rxcrdt_hdr_is_rd           ),
		.for_rxcrdt_hdr_is_wr_o    (             for_rxcrdt_hdr_is_wr           ),
		.bam_txc_ready_i           (             pio_txc_ready	    			),
		.bam_writeresponsevalid_i  (             1'b0                           ),
		.tx_hdr_fifo_rreq_o        (             tx_hdr_fifo_rreq               ),
		.tx_hdr_fifo_empty_i       (             tx_hdr_fifo_empty              ),
		.tx_hdr_fifo_rdata_i       (             tx_hdr_fifo_rdata              ),
		.cplram_rd_addr_o          (             cplram_rd_addr                 ),
		.cplram_rd_data_i          (             cplram_rd_data                 ),
		.cpl_cmd_fifo_rdreq_i      (             cpl_cmd_fifo_rdreq             ),
		.cpl_cmd_fifo_rddata_o     (             cpl_cmd_fifo_rddata            ),
		.cpl_cmd_fifo_empty_o      (             cpl_cmd_fifo_empty             ),
		.cpl_ram_rdreq_i           (             cpl_ram_rdreq                  ),
		.avmm_read_data_valid_o    (             avmm_read_data_valid           ),
		.cplram_read_data_o        (             cplram_read_data               )

);
 

intel_pcie_bam_v2_cpl 
#(
    .BAM_DATAWIDTH(BAM_DATAWIDTH)

) bam_cpl (
		.clk                     (  pio_clk                 ),
		.rst_n                   (  pio_rst_n               ),
		.cplcmd_fifo_rdreq_o     (  cpl_cmd_fifo_rdreq      ),
		.cplcmd_fifo_data_i      (  cpl_cmd_fifo_rddata     ),
		.cplcmd_fifo_empty_i     (  cpl_cmd_fifo_empty      ),
		.cpl_buf_rdreq_o         (  cpl_ram_rdreq           ),
		.cpl_buf_data_i          (  cplram_read_data        ),
		.cpl_buff_wrreq_i        (  avmm_read_data_valid    ),
		.pio_rx_bus_number       (  pio_rx_bus_number       ),
		.pio_rx_device_number    (  pio_rx_device_number    ),
		.pio_rx_function_number  (  pio_rx_function_number  ),
		.tx_data_buff_rd_addr_i  (  cplram_rd_addr          ),
		.tx_data_buff_o          (  cplram_rd_data          ),
		.tx_hdr_fifo_rreq_i      (  tx_hdr_fifo_rreq        ),
		.tx_hdr_fifo_rdata_o     (  tx_hdr_fifo_rdata       ),
		.tx_hdr_fifo_empty_o     (  tx_hdr_fifo_empty       ),
		.busdev_num_i            (  13'b0                   )
 );


pcie_ed_altera_mm_interconnect_1920_sx2feoa mm_interconnect_0 (
		.pio0_pio_master_address                                      (pio0_pio_master_address),
		.pio0_pio_master_waitrequest                                  (pio0_pio_master_waitrequest),
		.pio0_pio_master_burstcount                                   (pio0_pio_master_burstcount),
		.pio0_pio_master_byteenable                                   (pio0_pio_master_byteenable),
		.pio0_pio_master_read                                         (pio0_pio_master_read),
		.pio0_pio_master_readdata                                     (pio0_pio_master_readdata),
		.pio0_pio_master_readdatavalid                                (pio0_pio_master_readdatavalid),
		.pio0_pio_master_write                                        (pio0_pio_master_write),
		.pio0_pio_master_writedata                                    (pio0_pio_master_writedata),
		.pio0_pio_master_response                                     (pio0_pio_master_response),
		.MEM0_s1_address                                              (mm_interconnect_0_mem0_s1_address),
		.MEM0_s1_write                                                (mm_interconnect_0_mem0_s1_write),
		.MEM0_s1_readdata                                             (mm_interconnect_0_mem0_s1_readdata),
		.MEM0_s1_writedata                                            (mm_interconnect_0_mem0_s1_writedata),
		.MEM0_s1_byteenable                                           (mm_interconnect_0_mem0_s1_byteenable),
		.MEM0_s1_chipselect                                           (mm_interconnect_0_mem0_s1_chipselect),
		.MEM0_s1_clken                                                (mm_interconnect_0_mem0_s1_clken),
		.MEM0_reset1_reset_bridge_in_reset_reset                      (~pio_rst_n ),
		.pio0_pio_master_translator_reset_reset_bridge_in_reset_reset (~pio_rst_n ),
		.pio0_pio_master_clk_clk                                      (pio_clk )                  
	);

	pcie_ed_MEM0 mem0 (
		.clk        (pio_clk ),
		.address    (mm_interconnect_0_mem0_s1_address),
		.clken      (mm_interconnect_0_mem0_s1_clken),
		.chipselect (mm_interconnect_0_mem0_s1_chipselect),
		.write      (mm_interconnect_0_mem0_s1_write),
		.readdata   (mm_interconnect_0_mem0_s1_readdata),
		.writedata  (mm_interconnect_0_mem0_s1_writedata),
		.byteenable (mm_interconnect_0_mem0_s1_byteenable),
		.reset      (~pio_rst_n )          
	);

end
endgenerate




endmodule //intel_cxl_pio_ed_top

