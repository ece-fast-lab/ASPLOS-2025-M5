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


//----------------------------------------------------------------
//    Project Name:   avmm_bridge_1024_ed
//    Module Name :   intel_pcie_bam_v2.sv
//    Author      :   
//    Description :   Bursting Avalon Master Wrapper
//----------------------------------------------------------------

// synopsys translate_off
`timescale 1 ns / 1 ps
// synopsys translate_on

module intel_pcie_bam_v2_hwtcl # (
    parameter PFNUM_WIDTH               = 2,
    parameter VFNUM_WIDTH               = 12,
    parameter DATA_WIDTH                = 1024,
    parameter DEVICE_FAMILY             = "Agilex 7"
) 
(
     input [DATA_WIDTH-1:0]      pio_readdata_i,         // 
     input              pio_readdatavalid_i,    // 
     input [1:0]        pio_response_i,         // 

     input [2:0]                     pio_rx_st0_bar_i,      // 
     input [2:0]                     pio_rx_st1_bar_i,      //
     input [2:0]                     pio_rx_st2_bar_i,      //
     input [2:0]                     pio_rx_st3_bar_i,      //
     input 			     pio_rx_st0_eop_i,      // 
     input                           pio_rx_st1_eop_i,      //
     input                           pio_rx_st2_eop_i,      //
     input                           pio_rx_st3_eop_i,      //
     input [127:0]                   pio_rx_st0_header_i,   // 
     input [127:0]                   pio_rx_st1_header_i,   //
     input [127:0]                   pio_rx_st2_header_i,   //
     input [127:0]                   pio_rx_st3_header_i,   //
     input [255:0]          pio_rx_st0_payload_i,  // 
     input [255:0]          pio_rx_st1_payload_i,  //
     input [255:0]          pio_rx_st2_payload_i,  //
     input [255:0]          pio_rx_st3_payload_i,  //

     //input [PFNUM_WIDTH-1:0]         pio_rx_pfnum_i,    // 
     input  		             pio_rx_st0_sop_i,      // 
     input                           pio_rx_st1_sop_i,      //
     input                           pio_rx_st2_sop_i,      //
     input                           pio_rx_st3_sop_i,      //
     input 			     pio_rx_st0_hvalid_i,    //
     input                           pio_rx_st1_hvalid_i,    //
     input                           pio_rx_st2_hvalid_i,    //
     input                           pio_rx_st3_hvalid_i,    //
     input                           pio_rx_st0_dvalid_i,    //
     input                           pio_rx_st1_dvalid_i,    //
     input                           pio_rx_st2_dvalid_i,    //
     input                           pio_rx_st3_dvalid_i,    //
     input                           pio_rx_st0_pvalid_i,    //
     input                           pio_rx_st1_pvalid_i,    //
     input                           pio_rx_st2_pvalid_i,    //
     input                           pio_rx_st3_pvalid_i,    //

     input [2:0]	             pio_rx_st0_empty_i,    // 
     input [2:0]                     pio_rx_st1_empty_i,    //
     input [2:0]                     pio_rx_st2_empty_i,    //
     input [2:0]                     pio_rx_st3_empty_i,    //
     
//     input [(DATA_WIDTH==512)?1:0:0] pio_rx_tlp_abort_i,// 
     input [31:0]                    pio_rx_st0_tlp_prfx_i, // 
     input [31:0]                    pio_rx_st1_tlp_prfx_i, //
     input [31:0]                    pio_rx_st2_tlp_prfx_i, //
     input [31:0]                    pio_rx_st3_tlp_prfx_i, //
     //input                           pio_rx_vfactive_i, // 
     //input [VFNUM_WIDTH-1:0]         pio_rx_vfnum_i,    // 
     output                          pio_rx_st_ready_o,    // 

     input              pio_waitrequest_i,      // 
     //input [12:0]       busdev_num,             // 
     input              Clk_i,                    // 
     //input [2:0]        dev_mps,                // 
     input              Rstn_i,                 // 
	 output             pio_clk,                //
	 output             pio_rst_n,              //

     output [63:0]      pio_address_o,          // 
     //output [2:0]       pio_bar_o,              // 
     output [3:0]       pio_burstcount_o,       // 
     output [(DATA_WIDTH/8-1):0]      pio_byteenable_o,       // 
     //output [6:0]       pio_np_hdr_credit_o,    // 
     //output [PFNUM_WIDTH-1:0] pio_pfnum_o,      // 
     output             pio_read_o,             // 

     output                    pio_tx_st0_eop_o,  // 
     output                    pio_tx_st1_eop_o,  //
     output                    pio_tx_st2_eop_o,  //
     output                    pio_tx_st3_eop_o,  //
     output [127:0]            pio_tx_st0_header_o,      // 
     output [127:0]            pio_tx_st1_header_o,      //
     output [127:0]            pio_tx_st2_header_o,      //
     output [127:0]            pio_tx_st3_header_o,      //

     output [31:0]             pio_tx_st0_prefix_o,      // 
     output [31:0]             pio_tx_st1_prefix_o,      //
     output [31:0]             pio_tx_st2_prefix_o,      //
     output [31:0]             pio_tx_st3_prefix_o,      //    
     
     output [255:0]   pio_tx_st0_payload_o,     // 
     output [255:0]   pio_tx_st1_payload_o,     //
     output [255:0]   pio_tx_st2_payload_o,     //
     output [255:0]   pio_tx_st3_payload_o,     //

     //output [PFNUM_WIDTH-1:0]  pio_txc_pfnum_o,       // 
     output                    pio_tx_st0_sop_o,  // 
     output                    pio_tx_st1_sop_o,  //
     output                    pio_tx_st2_sop_o,  //
     output                    pio_tx_st3_sop_o,  //

     
     output                    pio_tx_st0_dvalid_o,// 
     output                    pio_tx_st1_dvalid_o,//
     output                    pio_tx_st2_dvalid_o,//
     output                    pio_tx_st3_dvalid_o,//
     output                    pio_tx_st0_pvalid_o,//
     output                    pio_tx_st1_pvalid_o,//
     output                    pio_tx_st2_pvalid_o,//
     output                    pio_tx_st3_pvalid_o,//
     output                    pio_tx_st0_hvalid_o,//
     output                    pio_tx_st1_hvalid_o,//
     output                    pio_tx_st2_hvalid_o,//
     output                    pio_tx_st3_hvalid_o,//

     
//     output                    pio_tx_st0_err_o,  // 

     //output                    pio_txc_vfactive_o,    // 
     //output [VFNUM_WIDTH-1:0]  pio_txc_vfnum_o,       // 
     input                     pio_tx_st_ready_i,       // 

     //output                   pio_vfactive_o,   // 
     //output [VFNUM_WIDTH-1:0] pio_vfnum_o,      // 
     output                   pio_write_o,      // 
     output [DATA_WIDTH-1:0]           pio_writedata_o,   // 

     //rx hcrdt
     output logic [2:0]           rx_st_hcrdt_update_o,
     output logic [5:0]           rx_st_hcrdt_update_cnt_o,
     output logic [2:0]           rx_st_hcrdt_init_o,
     input  logic [2:0]              rx_st_hcrdt_init_ack_i,

     //rx dcrdt
     output logic [2:0]             rx_st_dcrdt_update_o,
     output logic [11:0]             rx_st_dcrdt_update_cnt_o,
     output logic [2:0]             rx_st_dcrdt_init_o,
     input  logic [2:0]             rx_st_dcrdt_init_ack_i,

     //tx hcrdt
     input logic [2:0]             tx_st_hcrdt_update_i,
     input logic [5:0]             tx_st_hcrdt_update_cnt_i,
     input logic [2:0]             tx_st_hcrdt_init_i,
     output  logic [2:0]             tx_st_hcrdt_init_ack_o,

     //tx dcrdt
     input logic [2:0]             tx_st_dcrdt_update_i,
     input logic [11:0]             tx_st_dcrdt_update_cnt_i,
     input logic [2:0]             tx_st_dcrdt_init_i,
     output  logic [2:0]             tx_st_dcrdt_init_ack_o


      

);

localparam pld_tx_parity_ena  = "enable";  // enables AVST TX parity
localparam pld_rx_parity_ena  = "enable";  // enables AVST RX parity
localparam enable_sriov_hwtcl = 0;

logic srst_reg;
logic pio_Rstn;
logic pll_Rstn;
logic serdes_pll_locked;
logic pll_locked;

logic [2:0]   pio_rx_bar;
logic         pio_rx_eop;
logic [127:0] pio_rx_header;
logic [DATA_WIDTH-1:0] pio_rx_payload;
logic [PFNUM_WIDTH-1:0] pio_rx_pfnum;
logic         pio_rx_sop;
logic         pio_rx_valid;
logic         pio_rx_vfactive;
logic [VFNUM_WIDTH-1:0] pio_rx_vfnum;
logic         pio_rx_ready;

logic         pio_txc_ready;
logic         pio_txc_eop;
logic [127:0] pio_txc_header;
logic [DATA_WIDTH-1:0] pio_txc_payload;
logic         pio_txc_sop;
logic         pio_txc_valid;
logic         pio_txc_vfactive;

logic [9:0]  for_rxcrdt_tlp_len;
logic        for_rxcrdt_hdr_valid;
logic        for_rxcrdt_hdr_is_rd;
logic        for_rxcrdt_hdr_is_wr;

//Assuming no tlp prefix 
assign pio_tx_st0_prefix_o = 'h0;
assign pio_tx_st1_prefix_o = 'h0;
assign pio_tx_st2_prefix_o = 'h0;
assign pio_tx_st3_prefix_o = 'h0;

assign pio_txc_err_o = 0;
assign pio_rx_pfnum = 2'b0;

assign serdes_pll_locked = 1'b1;

//assign {pio_txc_header_wire[159:128],pio_txc_header_wire[191:160],pio_txc_header_wire[223:192],pio_txc_header_wire[255:224],
//        pio_txc_header_wire[31:0],pio_txc_header_wire[63:32],pio_txc_header_wire[95:64],pio_txc_header_wire[127:96]} = pio_txc_header_switch; 

    assign pio_rx_vfactive                  = 1'b0;//pio_rx_vfactive_i;
    assign pio_rx_vfnum                     = {VFNUM_WIDTH{1'b0}};//pio_rx_vfnum_i;
    assign pio_rx_st_ready_o                   = pio_rx_ready;

    assign pio_clk = Clk_i;
    assign pio_rst_n = Rstn_i;
 
  intel_pcie_bam_v2_avst_intf
 # (
   .BAM_DATAWIDTH(DATA_WIDTH) 
) avst_interface (
     .clk                               (pio_clk),
     .reset_n                           (pio_rst_n),
     .pio_rx_st0_bar_i (pio_rx_st0_bar_i),         
     .pio_rx_st1_bar_i (((DATA_WIDTH == 1024)||(DATA_WIDTH == 512))? pio_rx_st1_bar_i : 3'h0),         
     .pio_rx_st2_bar_i ((DATA_WIDTH == 1024)? pio_rx_st2_bar_i : 3'h0),         
     .pio_rx_st3_bar_i ((DATA_WIDTH == 1024)? pio_rx_st3_bar_i : 3'h0),         
     .pio_rx_st0_eop_i (pio_rx_st0_eop_i),         
     .pio_rx_st1_eop_i (((DATA_WIDTH == 1024)||(DATA_WIDTH == 512))? pio_rx_st1_eop_i : 1'b0),         
     .pio_rx_st2_eop_i ((DATA_WIDTH == 1024)? pio_rx_st2_eop_i : 1'b0),         
     .pio_rx_st3_eop_i ((DATA_WIDTH == 1024)? pio_rx_st3_eop_i : 1'b0),         
     .pio_rx_st0_header_i ({pio_rx_st0_header_i[31:0],pio_rx_st0_header_i[63:32],pio_rx_st0_header_i[95:64],pio_rx_st0_header_i[127:96]}),   
     .pio_rx_st1_header_i (((DATA_WIDTH == 1024)||(DATA_WIDTH == 512))? {pio_rx_st1_header_i[31:0],pio_rx_st1_header_i[63:32],pio_rx_st1_header_i[95:64],pio_rx_st1_header_i[127:96]} : 128'h0),   
     .pio_rx_st2_header_i ((DATA_WIDTH == 1024)? {pio_rx_st2_header_i[31:0],pio_rx_st2_header_i[63:32],pio_rx_st2_header_i[95:64],pio_rx_st2_header_i[127:96]} : 128'h0),
     .pio_rx_st3_header_i ((DATA_WIDTH == 1024)? {pio_rx_st3_header_i[31:0],pio_rx_st3_header_i[63:32],pio_rx_st3_header_i[95:64],pio_rx_st3_header_i[127:96]} : 128'h0),
     .pio_rx_st0_payload_i (pio_rx_st0_payload_i), 
     .pio_rx_st1_payload_i (((DATA_WIDTH == 1024)||(DATA_WIDTH == 512))? pio_rx_st1_payload_i : 256'h0), 
     .pio_rx_st2_payload_i ((DATA_WIDTH == 1024)? pio_rx_st2_payload_i : 256'h0), 
     .pio_rx_st3_payload_i ((DATA_WIDTH == 1024)? pio_rx_st3_payload_i : 256'h0), 
     .pio_rx_st0_sop_i (pio_rx_st0_sop_i),         
     .pio_rx_st1_sop_i (((DATA_WIDTH == 1024)||(DATA_WIDTH == 512))? pio_rx_st1_sop_i : 1'b0),         
     .pio_rx_st2_sop_i ((DATA_WIDTH == 1024)? pio_rx_st2_sop_i : 1'b0),         
     .pio_rx_st3_sop_i ((DATA_WIDTH == 1024)? pio_rx_st3_sop_i : 1'b0),         
     .pio_rx_st0_hvalid_i (pio_rx_st0_hvalid_i),   
     .pio_rx_st1_hvalid_i (((DATA_WIDTH == 1024)||(DATA_WIDTH == 512))? pio_rx_st1_hvalid_i : 1'b0),   
     .pio_rx_st2_hvalid_i ((DATA_WIDTH == 1024)? pio_rx_st2_hvalid_i : 1'b0),   
     .pio_rx_st3_hvalid_i ((DATA_WIDTH == 1024)? pio_rx_st3_hvalid_i : 1'b0),   
     .pio_rx_st0_dvalid_i (pio_rx_st0_dvalid_i),   
     .pio_rx_st1_dvalid_i (((DATA_WIDTH == 1024)||(DATA_WIDTH == 512))? pio_rx_st1_dvalid_i : 1'b0),   
     .pio_rx_st2_dvalid_i ((DATA_WIDTH == 1024)? pio_rx_st2_dvalid_i : 1'b0),   
     .pio_rx_st3_dvalid_i ((DATA_WIDTH == 1024)? pio_rx_st3_dvalid_i : 1'b0),   
     .pio_rx_st0_pvalid_i (pio_rx_st0_pvalid_i),   
     .pio_rx_st1_pvalid_i (((DATA_WIDTH == 1024)||(DATA_WIDTH == 512))? pio_rx_st1_pvalid_i : 1'b0),   
     .pio_rx_st2_pvalid_i ((DATA_WIDTH == 1024)? pio_rx_st2_pvalid_i : 1'b0),   
     .pio_rx_st3_pvalid_i ((DATA_WIDTH == 1024)? pio_rx_st3_pvalid_i : 1'b0),   
     .pio_rx_st0_empty_i (pio_rx_st0_empty_i),     
     .pio_rx_st1_empty_i (((DATA_WIDTH == 1024)||(DATA_WIDTH == 512))? pio_rx_st1_empty_i : 3'h0),     
     .pio_rx_st2_empty_i ((DATA_WIDTH == 1024)? pio_rx_st2_empty_i : 3'h0),     
     .pio_rx_st3_empty_i ((DATA_WIDTH == 1024)? pio_rx_st3_empty_i : 3'h0),
     .pio_rx_bar (pio_rx_bar),                     
     .pio_rx_sop (pio_rx_sop),                     
     .pio_rx_eop (pio_rx_eop),                     
     .pio_rx_header (pio_rx_header),               
     .pio_rx_payload (pio_rx_payload),             
     .pio_rx_valid (pio_rx_valid),                 
     .pio_rx_st0_tlp_prfx_i (pio_rx_st0_tlp_prfx_i),
     .pio_rx_st1_tlp_prfx_i (((DATA_WIDTH == 1024)||(DATA_WIDTH == 512))? pio_rx_st1_tlp_prfx_i : 32'h0),
     .pio_rx_st2_tlp_prfx_i ((DATA_WIDTH == 1024)? pio_rx_st2_tlp_prfx_i : 32'h0),
     .pio_rx_st3_tlp_prfx_i ((DATA_WIDTH == 1024)? pio_rx_st3_tlp_prfx_i : 32'h0),
     .pio_tx_st0_eop_o (pio_tx_st0_eop_o),          
     .pio_tx_st1_eop_o (pio_tx_st1_eop_o),          
     .pio_tx_st2_eop_o (pio_tx_st2_eop_o),          
     .pio_tx_st3_eop_o (pio_tx_st3_eop_o),          
     .pio_tx_st0_header_o ({pio_tx_st0_header_o[31:0],pio_tx_st0_header_o[63:32],pio_tx_st0_header_o[95:64],pio_tx_st0_header_o[127:96]}),    
     .pio_tx_st1_header_o ({pio_tx_st1_header_o[31:0],pio_tx_st1_header_o[63:32],pio_tx_st1_header_o[95:64],pio_tx_st1_header_o[127:96]}),
     .pio_tx_st2_header_o ({pio_tx_st2_header_o[31:0],pio_tx_st2_header_o[63:32],pio_tx_st2_header_o[95:64],pio_tx_st2_header_o[127:96]}),
     .pio_tx_st3_header_o ({pio_tx_st3_header_o[31:0],pio_tx_st3_header_o[63:32],pio_tx_st3_header_o[95:64],pio_tx_st3_header_o[127:96]}),
     .pio_tx_st0_prefix_o (),
     .pio_tx_st1_prefix_o (),
     .pio_tx_st2_prefix_o (),
     .pio_tx_st3_prefix_o (),
     .pio_tx_st0_payload_o (pio_tx_st0_payload_o),
     .pio_tx_st1_payload_o (pio_tx_st1_payload_o),
     .pio_tx_st2_payload_o (pio_tx_st2_payload_o),
     .pio_tx_st3_payload_o (pio_tx_st3_payload_o),
     .pio_tx_st0_sop_o (pio_tx_st0_sop_o),
     .pio_tx_st1_sop_o (pio_tx_st1_sop_o),
     .pio_tx_st2_sop_o (pio_tx_st2_sop_o),
     .pio_tx_st3_sop_o (pio_tx_st3_sop_o),
     .pio_tx_st0_dvalid_o (pio_tx_st0_dvalid_o),
     .pio_tx_st1_dvalid_o (pio_tx_st1_dvalid_o),
     .pio_tx_st2_dvalid_o (pio_tx_st2_dvalid_o),
     .pio_tx_st3_dvalid_o (pio_tx_st3_dvalid_o),
     .pio_tx_st0_hvalid_o (pio_tx_st0_hvalid_o),
     .pio_tx_st1_hvalid_o (pio_tx_st1_hvalid_o),
     .pio_tx_st2_hvalid_o (pio_tx_st2_hvalid_o),
     .pio_tx_st3_hvalid_o (pio_tx_st3_hvalid_o),
     .pio_tx_st0_pvalid_o (pio_tx_st0_pvalid_o),
     .pio_tx_st1_pvalid_o (pio_tx_st1_pvalid_o),
     .pio_tx_st2_pvalid_o (pio_tx_st2_pvalid_o),
     .pio_tx_st3_pvalid_o (pio_tx_st3_pvalid_o),
     .pio_txc_eop (pio_txc_eop),
     .pio_txc_header (pio_txc_header),  
     .pio_txc_payload (pio_txc_payload),
     .pio_txc_sop (pio_txc_sop),
     .pio_txc_valid (pio_txc_valid)
);



  intel_pcie_bam_v2
  # (
    .DEVICE_FAMILY   (DEVICE_FAMILY),
    .PFNUM_WIDTH     (PFNUM_WIDTH),
    .VFNUM_WIDTH     (VFNUM_WIDTH),
    .BAM_DATAWIDTH   (DATA_WIDTH)
  ) pio (
    .clk                                (pio_clk                   ), //
    .rst_n                              (pio_rst_n                 ), //
    .bam_readdata_i                     (pio_readdata_i            ), //
    .bam_readdatavalid_i                (pio_readdatavalid_i       ), //
    .bam_response_i                     (pio_response_i            ), //

    .bam_rx_bar_i                       (pio_rx_bar[2:0]         ), //
    .bam_rx_eop_i                       (pio_rx_eop              ), //
    .bam_rx_header_i                    (pio_rx_header[127:0]    ), //
    .bam_rx_payload_i                   (pio_rx_payload          ), //
    .bam_rx_pfnum_i                     (pio_rx_pfnum            ), //
    .bam_rx_sop_i                       (pio_rx_sop              ), //
    .bam_rx_valid_i                     (pio_rx_valid            ), //
    .bam_rx_vfactive_i                  (pio_rx_vfactive         ), //
    .bam_rx_vfnum_i                     (pio_rx_vfnum            ), //
    .bam_rx_ready_o                     (pio_rx_ready            ), //

    .bam_waitrequest_i                  (pio_waitrequest_i         ), //
    .bam_writeresponsevalid_i           (1'b0                      ), //
    .busdev_num                         (13'b0),//busdev_num                ), //
    .dev_mps                            (3'b0),//dev_mps                   ), //

    .bam_address_o                      (pio_address_o             ), //
    .bam_bar_o                          (),//pio_bar_o                 ), //
    .bam_burstcount_o                   (pio_burstcount_o          ), //
    .bam_byteenable_o                   (pio_byteenable_o          ), //
    .bam_np_hdr_credit_o                (),//pio_np_hdr_credit_o       ), //
    .bam_pfnum_o                        (),//pio_pfnum_o               ), //
    .bam_read_o                         (pio_read_o                ), //

    .bam_txc_ready_i                    (pio_txc_ready           ), //
    .bam_txc_eop_o                      (pio_txc_eop             ), //
    .bam_txc_header_o                   (pio_txc_header[127:0]   ), //
    .bam_txc_payload_o                  (pio_txc_payload         ), //
    .bam_txc_sop_o                      (pio_txc_sop             ), //
    .bam_txc_valid_o                    (pio_txc_valid         ),          //
    .bam_txc_vfactive_o                 (pio_txc_vfactive        ), //

    .bam_vfactive_o                     (),//pio_vfactive_o            ), //
    .bam_vfnum_o                        (),//pio_vfnum_o               ), //
    .bam_write_o                        (pio_write_o               ), //
    .bam_writedata_o                    (pio_writedata_o           ), //
    .bam_writeresponsevalid_o           (                          ),  //
    .for_rxcrdt_tlp_len_o               (for_rxcrdt_tlp_len),     // for credit interface
    .for_rxcrdt_hdr_valid_o             (for_rxcrdt_hdr_valid),
    .for_rxcrdt_hdr_is_rd_o             (for_rxcrdt_hdr_is_rd),
    .for_rxcrdt_hdr_is_wr_o             (for_rxcrdt_hdr_is_wr)
  );

intel_pcie_bam_v2_crdt_intf crdt_intf (
    .clk(pio_clk),
    .rst_n(pio_rst_n),
    .rx_st_hcrdt_update_o(rx_st_hcrdt_update_o),
    .rx_st_hcrdt_update_cnt_o(rx_st_hcrdt_update_cnt_o),
    .rx_st_hcrdt_init_o(rx_st_hcrdt_init_o),
    .rx_st_hcrdt_init_ack_i(rx_st_hcrdt_init_ack_i),
    .rx_st_dcrdt_update_o(rx_st_dcrdt_update_o),
    .rx_st_dcrdt_update_cnt_o(rx_st_dcrdt_update_cnt_o),
    .rx_st_dcrdt_init_o(rx_st_dcrdt_init_o),
    .rx_st_dcrdt_init_ack_i(rx_st_dcrdt_init_ack_i),
    .tx_st_hcrdt_update_i(tx_st_hcrdt_update_i),
    .tx_st_hcrdt_update_cnt_i(tx_st_hcrdt_update_cnt_i),
    .tx_st_hcrdt_init_i(tx_st_hcrdt_init_i),
    .tx_st_hcrdt_init_ack_o(tx_st_hcrdt_init_ack_o),
    .tx_st_dcrdt_update_i(tx_st_dcrdt_update_i),
    .tx_st_dcrdt_update_cnt_i(tx_st_dcrdt_update_cnt_i),
    .tx_st_dcrdt_init_i(tx_st_dcrdt_init_i),
    .tx_st_dcrdt_init_ack_o(tx_st_dcrdt_init_ack_o),
    .hdr_len_i(for_rxcrdt_tlp_len),
    .hdr_valid_i(for_rxcrdt_hdr_valid),
    .hdr_is_rd_i(for_rxcrdt_hdr_is_rd),
    .hdr_is_wr_i(for_rxcrdt_hdr_is_wr),
    .bam_rx_signal_ready_i(pio_rx_ready),
    .pio_tx_st_ready_i(pio_tx_st_ready_i),
    .bam_tx_signal_ready_o(pio_txc_ready),
    .tx_hdr_i(pio_txc_header[9:0]),
    .tx_hdr_valid_i(pio_txc_valid)
);

endmodule

