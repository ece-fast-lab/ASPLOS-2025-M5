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
//  Project Name:  avmm_bridge_512                                   
//  Module Name :  intel_pcie_bam_fifos.sv                                  
//  Author      :  jjshou                                   
//  Date        :  Thu Aug 7, 2017                                 
//  Description :  This module holds all FIFO/RAM modules for hprxm
//-----------------------------------------------------------------------------  


// synopsys translate_off
`timescale 1 ps / 1 ps
// synopsys translate_on

module intel_pcie_bam_fifos
  #(
    parameter PFNUM_WIDTH = 3,
    parameter VFNUM_WIDTH = 11
    )
    (
     input                                  clk,
     input                                  rst_n,

    /*----- RX FIFO 0 interface signals ----------*/

     input                                  rx_hdr_fifo_rreq,
     input                                  rx_hdr_fifo_wreq,
     input [145:0]                          rx_hdr_fifo_wdata,
     output [145:0]                         rx_hdr_fifo_rdata,
     output                                 rx_hdr_fifo_empty,
     output                                 rx_hdr_fifo_full,
     output [3:0]                           rx_hdr_fifo_count,
     
     input                                  rx_data_fifo_rreq,
     input                                  rx_data_fifo_wreq,
     input [512:0]                          rx_data_fifo_wdata,
     output [512:0]                         rx_data_fifo_rdata,
     output                                 rx_data_fifo_full,
     output [3:0]                           rx_data_fifo_count,

     /*----- Read request scoreboard FIFO inteface ----*/
     input                                  rd_scbd_fifo_wreq,
     input                                  rd_scbd_fifo_rreq,
     input [44:0]                           rd_scbd_fifo_wdata,
     output [44:0]                          rd_scbd_fifo_rdata,
     output                                 rd_scbd_fifo_empty,

     /*----- AVMM Command FIFO interface ------------*/
     input                                  avmm_cmd_fifo_wreq,
     input                                  avmm_cmd_fifo_rreq,
     input [194+PFNUM_WIDTH+VFNUM_WIDTH :0] avmm_cmd_fifo_wdata,
     output [194+PFNUM_WIDTH+VFNUM_WIDTH :0] avmm_cmd_fifo_rdata,
     output                                 avmm_cmd_fifo_empty,
     output [3:0]                           avmm_cmd_fifo_count, 

     /*----- AVMM Data FIFO interface ----------*/
     input                                  avmm_data_fifo_wreq,
     input                                  avmm_data_fifo_rreq,
     input [511 :0]                         avmm_data_fifo_wdata,
     output [511 :0]                        avmm_data_fifo_rdata,
     output [5:0]                           avmm_data_fifo_count,

     /*------ Completion Data Buffer ----------*/
     input                                  cpl_buf_wreq,
     input [512:0]                          cpl_buf_wdata,
     input [ 8:0]                           cpl_buf_waddr,
     input [ 8:0]                           cpl_buf_raddr,
     output [512:0]                         cpl_buf_data_q,


     /*------ TX FIFO interface signals -------*/
     output logic                           tx_hdr_fifo_empty,
     output logic                           tx_hdr_fifo_full,
     input                                  tx_hdr_fifo_wreq,
     input [ 95:0]                          tx_hdr_fifo_wdata,
     input                                  tx_hdr_fifo_rreq,
     output [ 95:0]                         tx_hdr_fifo_rdata,

     output logic [4:0]                     tx_data_fifo_count,
     output logic                           tx_data_fifo_empty,
     output logic                           tx_data_fifo_full,
     input                                  tx_data_fifo_wreq,
     input [513:0]                          tx_data_fifo_wdata,
     input                                  tx_data_fifo_rreq,
     output [513:0]                         tx_data_fifo_rdata                 
     );

    wire                rd_scbd_fifo_full;
        
    /*------ Scheduler RX input FIFO Instantiation -----*/
    /// Rx FIFO 0
    scfifo rx_hdr_fifo
      (
       .clock            (clk                 ),
       .data             (rx_hdr_fifo_wdata ),
       .rdreq            (rx_hdr_fifo_rreq  ),
       .wrreq            (rx_hdr_fifo_wreq  ),
       .q                (rx_hdr_fifo_rdata ),
       .empty            (rx_hdr_fifo_empty ),
       .sclr             (!rst_n            ),
       .usedw            (rx_hdr_fifo_count ),
       .aclr             (1'b0              ),
       .full             (rx_hdr_fifo_full  ),
       .almost_full      (),
       .almost_empty     (),
       .eccstatus       ());
    defparam
      rx_hdr_fifo.add_ram_output_register  = "ON",
      rx_hdr_fifo.enable_ecc  = "FALSE",
      rx_hdr_fifo.intended_device_family  = "Agilex 7",
      rx_hdr_fifo.lpm_hint  = "RAM_BLOCK_TYPE=MLAB",
      rx_hdr_fifo.lpm_numwords  = 16,
      rx_hdr_fifo.lpm_showahead  = "ON",
      rx_hdr_fifo.lpm_type  = "scfifo",
      rx_hdr_fifo.lpm_width  = 146,
      rx_hdr_fifo.lpm_widthu  = 4,
      rx_hdr_fifo.overflow_checking  = "ON",
      rx_hdr_fifo.underflow_checking  = "ON",
      rx_hdr_fifo.use_eab  = "ON";

    scfifo rx_data_fifo
      (
       .clock            (clk                 ),
       .data             (rx_data_fifo_wdata ),
       .rdreq            (rx_data_fifo_rreq  ),
       .wrreq            (rx_data_fifo_wreq  ),
       .q                (rx_data_fifo_rdata ),
       .empty            (rx_data_fifo_empty ),
       .sclr             (!rst_n              ),
       .usedw            (rx_data_fifo_count ),
       .aclr             (1'b0                ),
       .full             (rx_data_fifo_full  ),
       .almost_full      (),
       .almost_empty     (),
       .eccstatus       ());
    defparam
      rx_data_fifo.add_ram_output_register  = "ON",
      rx_data_fifo.enable_ecc  = "FALSE",
      rx_data_fifo.intended_device_family  = "Agilex 7",
      rx_data_fifo.lpm_hint  = "RAM_BLOCK_TYPE=MLAB",
      rx_data_fifo.lpm_numwords  = 16,
      rx_data_fifo.lpm_showahead  = "ON",
      rx_data_fifo.lpm_type  = "scfifo",
      rx_data_fifo.lpm_width  = 513,
      rx_data_fifo.lpm_widthu  = 4,
      rx_data_fifo.overflow_checking  = "ON",
      rx_data_fifo.underflow_checking  = "ON",
      rx_data_fifo.use_eab  = "ON";
    
    /*------ AVMM Command FIFO Instantiation -----*/
    scfifo avmm_cmd_fifo 
      (
       .clock   (clk),
       .sclr    (!rst_n),
       .wrreq   (avmm_cmd_fifo_wreq), 
       .rdreq   (avmm_cmd_fifo_rreq),
       .data    (avmm_cmd_fifo_wdata),
       .q       (avmm_cmd_fifo_rdata),
       .empty   (avmm_cmd_fifo_empty),
       .full  (),
       .almost_full      (),
       .aclr             (1'b0),
       .almost_empty     (),
       .eccstatus        (),
       .usedw  (avmm_cmd_fifo_count)
       );
    defparam
      avmm_cmd_fifo.add_ram_output_register  = "ON",
      avmm_cmd_fifo.enable_ecc  = "FALSE",
      avmm_cmd_fifo.intended_device_family  = "Agilex 7",
      avmm_cmd_fifo.lpm_hint  = "RAM_BLOCK_TYPE=MLAB",
      avmm_cmd_fifo.lpm_numwords  = 16,
      avmm_cmd_fifo.lpm_showahead  = "ON",
      avmm_cmd_fifo.lpm_type  = "scfifo",
      avmm_cmd_fifo.lpm_width  = 195+PFNUM_WIDTH+VFNUM_WIDTH,
      avmm_cmd_fifo.lpm_widthu  = 4,
      avmm_cmd_fifo.overflow_checking  = "ON",
      avmm_cmd_fifo.underflow_checking  = "ON",
      avmm_cmd_fifo.use_eab  = "ON";

    /*------ AVMM Data FIFO Instantiation --------*/

    /// FIFO to store the AVMM write data and byte enable

    scfifo  avmm_data_fifo 
      (
       .rdreq  (avmm_data_fifo_rreq),
       .clock  (clk),
       .wrreq  (avmm_data_fifo_wreq),
       .data   (avmm_data_fifo_wdata),
       .usedw  (avmm_data_fifo_count),
       .empty (),
       .q     (avmm_data_fifo_rdata),
       .full  (),
       .almost_full      (),
       .sclr             (~rst_n),
       .aclr             (1'b0),
       .almost_empty     (),
       .eccstatus       ()
       );
    defparam
      avmm_data_fifo.add_ram_output_register  = "ON",
      avmm_data_fifo.enable_ecc  = "FALSE",
      avmm_data_fifo.intended_device_family  = "Agilex 7",
      avmm_data_fifo.lpm_hint  = "RAM_BLOCK_TYPE=M20K",
      avmm_data_fifo.lpm_numwords  = 64,
      avmm_data_fifo.lpm_showahead  = "ON",
      avmm_data_fifo.lpm_type  = "scfifo",
      avmm_data_fifo.lpm_width  = 512,
      avmm_data_fifo.lpm_widthu  = 6,
      avmm_data_fifo.overflow_checking  = "ON",
      avmm_data_fifo.underflow_checking  = "ON",
      avmm_data_fifo.use_eab  = "ON";

    /*----- Read Request Scoreboard FIFO -----------*/
    scfifo  rd_scbd_fifo 
      (
       .rdreq  (rd_scbd_fifo_rreq),
       .clock  (clk),
       .wrreq  (rd_scbd_fifo_wreq),
       .data   (rd_scbd_fifo_wdata),
       .usedw  (),
       .empty  (rd_scbd_fifo_empty),
       .q      (rd_scbd_fifo_rdata),
       .full  (rd_scbd_fifo_full),
       .sclr  (~rst_n),
       .almost_full      (),
       .aclr             (1'b0),
       .almost_empty     (),
       .eccstatus       ()
       );
    defparam
      rd_scbd_fifo.add_ram_output_register  = "ON",
      rd_scbd_fifo.enable_ecc  = "FALSE",
      rd_scbd_fifo.intended_device_family  = "Agilex 7",
      rd_scbd_fifo.lpm_hint  = "RAM_BLOCK_TYPE=MLAB",
      rd_scbd_fifo.lpm_numwords  = 32,
      rd_scbd_fifo.lpm_showahead  = "ON",
      rd_scbd_fifo.lpm_type  = "scfifo",
      rd_scbd_fifo.lpm_width  = 45,
      rd_scbd_fifo.lpm_widthu  = 5,
      rd_scbd_fifo.overflow_checking  = "ON",
      rd_scbd_fifo.underflow_checking  = "ON",
      rd_scbd_fifo.use_eab  = "ON";

    /*------ RAM (M20K) to store completion data ---------*/
    altsyncram   //dual-port RAM
      #(
        .intended_device_family("Agilex 7"),
        .operation_mode("DUAL_PORT"),
        .width_a(513),
        .widthad_a(8),
        .numwords_a(256),
        .width_b(513),
        .widthad_b(8),
        .numwords_b(256),
        .lpm_type("altsyncram"),
        .width_byteena_a(1),
        .outdata_reg_b("UNREGISTERED"),
        .indata_aclr_a("NONE"),
        .wrcontrol_aclr_a("NONE"),
        .address_aclr_a("NONE"),
        .address_reg_b("CLOCK0"),
        .address_aclr_b("NONE"),
        .outdata_aclr_b("NONE"),
        .power_up_uninitialized("FALSE"),
        .ram_block_type("AUTO"),
        .read_during_write_mode_mixed_ports("OLD_DATA")
        )
    tx_cpl_buff (
                 .wren_a         (cpl_buf_wreq),
                 .clocken1       (),
                 .clock0         (clk),
                 .clock1         (),
                 .address_a      (cpl_buf_waddr[7:0]),
                 .address_b      (cpl_buf_raddr[7:0]),
                 .data_a         (cpl_buf_wdata),
                 .q_b            (cpl_buf_data_q),
                 .aclr0          (),
                 .aclr1          (),
                 .addressstall_a (),
                 .addressstall_b (),
                 .byteena_a      (),
                 .byteena_b      (),
                 .clocken0       (),
                 .data_b         (),
                 .q_a            (),
                 .rden_b         (),
                 .wren_b         ()
                 );

    /*--------- TX output FIFO ----------------*/
     scfifo tx_hdr_fifo  
       (
        .clock       (clk                ),
        .data        (tx_hdr_fifo_wdata  ),
        .rdreq       (tx_hdr_fifo_rreq   ),
        .wrreq       (tx_hdr_fifo_wreq   ),
        .full        (tx_hdr_fifo_full   ),
        .q           (tx_hdr_fifo_rdata  ),
        .empty       (tx_hdr_fifo_empty  ),
        .sclr        (!rst_n             ),
        .usedw       (tx_hdr_fifo_count  ),
        .almost_full      (),
        .aclr             (1'b0),
        .almost_empty     (tx_hdr_fifo_almost_empty),
        .eccstatus       ());
    defparam
      tx_hdr_fifo.add_ram_output_register  = "ON",
      tx_hdr_fifo.enable_ecc  = "FALSE",
      tx_hdr_fifo.intended_device_family  = "Agilex 7",
      tx_hdr_fifo.lpm_hint  = "RAM_BLOCK_TYPE=MLAB",
      tx_hdr_fifo.lpm_numwords  = 32,
      tx_hdr_fifo.lpm_showahead  = "ON",
      tx_hdr_fifo.lpm_type  = "scfifo",
      tx_hdr_fifo.lpm_width  = 96,
      tx_hdr_fifo.lpm_widthu  = 5,
      tx_hdr_fifo.overflow_checking  = "ON",
      tx_hdr_fifo.underflow_checking  = "ON",
      tx_hdr_fifo.use_eab  = "ON"; 

 scfifo tx_data_fifo  
       (
        .clock       (clk                ),
        .data        (tx_data_fifo_wdata  ),
        .rdreq       (tx_data_fifo_rreq   ),
        .wrreq       (tx_data_fifo_wreq   ),
        .full        (tx_data_fifo_full   ),
        .q           (tx_data_fifo_rdata  ),
        .empty       (tx_data_fifo_empty  ),
        .sclr        (!rst_n             ),
        .usedw       (tx_data_fifo_count  ),
        .almost_full      (),
        .aclr             (1'b0),
        .almost_empty     (tx_data_fifo_almost_empty),
        .eccstatus       ());
    defparam
      tx_data_fifo.add_ram_output_register  = "ON",
      tx_data_fifo.enable_ecc  = "FALSE",
      tx_data_fifo.intended_device_family  = "Agilex 7",
      tx_data_fifo.lpm_hint  = "RAM_BLOCK_TYPE=MLAB",
      tx_data_fifo.lpm_numwords  = 32,
      tx_data_fifo.lpm_showahead  = "ON",
      tx_data_fifo.lpm_type  = "scfifo",
      tx_data_fifo.lpm_width  = 514,
      tx_data_fifo.lpm_widthu  = 5,
      tx_data_fifo.overflow_checking  = "ON",
      tx_data_fifo.underflow_checking  = "ON",
      tx_data_fifo.use_eab  = "ON";     

`ifdef ALTERA_PCIE_S10_ENABLE_ASSERTIONS
    rd_scbd_fifo_overflow_check : assert property (
    @( posedge clk) disable iff ( rst_n !== 1'b1 ) 
    !(rd_scbd_fifo_full  && rd_scbd_fifo_wreq))
      else $error ( "%m RTL_ASSERTION_ERROR: RD_SCBD_FIFO overflow" );

    tx_fifo_overflow_check : assert property (
    @( posedge clk) disable iff ( rst_n !== 1'b1 ) 
    !(tx_fifo_full  && tx_fifo_wreq))
    else $error ( "%m RTL_ASSERTION_ERROR: TX_FIFO overflow" );
`endif
    
endmodule
