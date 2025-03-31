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
//  Module Name :  intel_pcie_bam_v2_sch_intf.v                                  
//  Author      :  klai4                                   
//  Date        :  Thu Jan 7, 2021                                 
//  Description :  This module converts the request incoming from HIP side and send
//                 out to avmm side
//-----------------------------------------------------------------------------  


// synopsys translate_off
`timescale 1 ps / 1 ps
// synopsys translate_on

module intel_pcie_bam_v2_sch_intf
  # (
      parameter PFNUM_WIDTH = 2,
      parameter VFNUM_WIDTH = 12,
      parameter BAM_DATAWIDTH = 1024,
      parameter pf0_bar0_address_width_hwtcl     = 0,//20,
      parameter pf0_bar1_address_width_hwtcl     = 0,
      parameter pf0_bar2_address_width_hwtcl     = 0,
      parameter pf0_bar3_address_width_hwtcl     = 0,
      parameter pf0_bar4_address_width_hwtcl     = 0,
      parameter pf0_bar5_address_width_hwtcl     = 0,

      parameter pf1_bar0_address_width_hwtcl     = 20,//0,
      parameter pf1_bar1_address_width_hwtcl     = 0,
      parameter pf1_bar2_address_width_hwtcl     = 0,
      parameter pf1_bar3_address_width_hwtcl     = 0,
      parameter pf1_bar4_address_width_hwtcl     = 0,
      parameter pf1_bar5_address_width_hwtcl     = 0,

      parameter pf2_bar0_address_width_hwtcl     = 0,
      parameter pf2_bar1_address_width_hwtcl     = 0,
      parameter pf2_bar2_address_width_hwtcl     = 0,
      parameter pf2_bar3_address_width_hwtcl     = 0,
      parameter pf2_bar4_address_width_hwtcl     = 0,
      parameter pf2_bar5_address_width_hwtcl     = 0,

      parameter pf3_bar0_address_width_hwtcl     = 0,
      parameter pf3_bar1_address_width_hwtcl     = 0,
      parameter pf3_bar2_address_width_hwtcl     = 0,
      parameter pf3_bar3_address_width_hwtcl     = 0,
      parameter pf3_bar4_address_width_hwtcl     = 0,
      parameter pf3_bar5_address_width_hwtcl     = 0
     )
  (
   input logic                    clk,
   input logic                    rst_n,

   // Rx Scheduler Interface
   output logic                   bam_rx_ready_o,
   input logic [BAM_DATAWIDTH-1:0]            bam_rx_payload_i,
   input logic [127:0]            bam_rx_header_i, 
   input logic [2:0]              bam_rx_bar_i, 
   input logic                    bam_rx_sop_i,
   input logic                    bam_rx_valid_i,
   input logic                    bam_rx_eop_i,
   input logic                    bam_rx_vfactive_i,
   input logic [PFNUM_WIDTH-1:0]  bam_rx_pfnum_i,
   input logic [VFNUM_WIDTH-1:0]  bam_rx_vfnum_i,
   

  
   output logic                   preproc_cmd_fifo_empty_o, 
   input  logic                   preproc_cmd_fifo_rdreq_i,
   output logic [430:0]           preproc_cmd_fifo_rddata_o, 
   
   

   output logic [BAM_DATAWIDTH-1:0]           rx_data_fifo_rddata_o, 
   input  logic                   rx_data_fifo_rdreq_i,
  
     //Tx FIFO read interface
   output logic                   tx_hdr_fifo_rreq_o,
   input logic                    tx_hdr_fifo_empty_i,
   input logic [96:0]             tx_hdr_fifo_rdata_i,

   output logic [8:0]             cplram_rd_addr_o,
   input logic [BAM_DATAWIDTH+1:0]            cplram_rd_data_i,

     //Tx Scheduler Interface
   input logic                    bam_txc_ready_i,
   output logic [BAM_DATAWIDTH-1 :0]          bam_txc_payload_o,
   output logic                   bam_txc_eop_o, 
   output logic                   bam_txc_valid_o,
   output logic [127:0]            bam_txc_header_o,
   output logic                   bam_txc_sop_o,
   output logic                   bam_txc_vfactive_o,
   output logic [PFNUM_WIDTH-1:0] bam_txc_pfnum_o,
   output logic [VFNUM_WIDTH-1:0] bam_txc_vfnum_o,
   
   output logic                   valid_eop_o,
   output logic           	  pio_to_send_cpl,
   
   input logic [2:0]              max_payload_size_i,
   
   //For rx credit interface
   output logic [9:0]    for_rxcrdt_tlp_len_o,
   output logic          for_rxcrdt_hdr_valid_o,
   output logic          for_rxcrdt_hdr_is_rd_o,
   output logic          for_rxcrdt_hdr_is_wr_o

  );

  localparam [1:0]    TX_IDLE       = 2'b00;
  localparam [1:0]    TX_SEND       = 2'b01;
  localparam [1:0]    TX_PAUSE      = 2'b10;          

    logic                   bam_hdr_vld_reg;
    logic [127:0]           bam_hdr_reg;
    logic                   bam_data_vld_reg;
    logic [BAM_DATAWIDTH-1 :0]          bam_data_reg;
    logic [2:0]             bam_bar_reg;
    logic                   bam_eop_reg;
    logic                   bam_vfactive_reg;
    logic [PFNUM_WIDTH-1:0] bam_pfnum_reg;
    logic [VFNUM_WIDTH-1:0] bam_vfnum_reg;
    logic [4:0]             preproc_cmd_fifo_cnt;
    logic [7:0]             rx_data_fifo_count;
    logic                   rx_data_fifo_lt16_reg;   
    logic                   preproc_cmd_fifo_lt16_reg;
    logic   [96:0]          hdr_reg;
    logic                   hdr_avail_reg;
    logic                   tx_ready_reg;
    logic   [3:0]           pcie_lines_cntr;
    logic   [1:0]           tx_state;      
    logic   [1:0]           tx_nxt_state;   
    logic                   idle_state; 
    logic                   send_state;  
    logic                   pause_state; 
    logic                   pop_hdr_fifo; 
    logic   [8:0]           cplram_rd_addr;
    logic   [BAM_DATAWIDTH-1:0]  	      tx_data_reg1;     
    logic   [BAM_DATAWIDTH-1:0]  	      tx_data_reg2;     
    logic   [BAM_DATAWIDTH-1:0]  	      tx_data_reg3;     
    logic    	              tx_sop_reg1;            
    logic    	              tx_sop_reg2;            
    logic    	              tx_sop_reg3;            
    logic    	              tx_eop_reg1;            
    logic    	              tx_eop_reg2;            
    logic    	              tx_eop_reg3;            
    logic    	              tx_valid_reg1;          
    logic    	              tx_valid_reg2;          
    logic    	              tx_valid_reg3;          
    logic   [96:0]          tx_header_reg1; 
    logic   [96:0]          tx_header_reg2; 
    logic   [96:0]          tx_header_reg3; 
    logic                   srst_reg;
    logic                   is_rd_eop;
    logic                   sop_reg;    
    logic                   eop_reg; 
    logic                   valid_reg; 
    logic [127:0]           header_reg;
   
  /// valid eop for TLP store and forward to avoid underflow         
 always_ff @(posedge clk) 
   begin
     valid_reg  <= bam_rx_valid_i;
   end
   
  always_ff @(posedge clk)
   if(bam_rx_valid_i)
   begin
     sop_reg    <= bam_rx_sop_i;
     eop_reg    <= bam_rx_eop_i;
   end
 
 always_ff @(posedge clk) 
   if(bam_rx_valid_i & bam_rx_sop_i)
     header_reg <= bam_rx_header_i;
 
 assign is_rd_eop = eop_reg & valid_reg & ~header_reg[30];
                                                            
 always_ff @(posedge clk)                                          
   valid_eop_o <= eop_reg & valid_reg & ~is_rd_eop;                  
   
   always_ff @(posedge clk) 
    srst_reg        <= ~rst_n;
        
    //Input signals flopped first, pipeline flops, no reset needed    
    
    always_ff @(posedge clk)
      if(bam_rx_sop_i & bam_rx_valid_i)
        bam_hdr_reg      <= bam_rx_header_i;
        
    always_ff @(posedge clk) 
      begin
          bam_hdr_vld_reg  <= bam_rx_sop_i & bam_rx_valid_i;
         
          
          bam_data_vld_reg <= bam_rx_valid_i;
          bam_data_reg     <= bam_rx_payload_i;
          
          bam_bar_reg      <= bam_rx_bar_i;
          bam_eop_reg      <= bam_rx_eop_i;
          bam_vfactive_reg <= bam_rx_vfactive_i;
          bam_pfnum_reg    <= bam_rx_pfnum_i;
          bam_vfnum_reg    <= bam_rx_vfnum_i;
          
      end // always_ff @

   always_ff @ (posedge clk)
     begin
       rx_data_fifo_lt16_reg     <= rx_data_fifo_count[7:0] < 8'd16;
       preproc_cmd_fifo_lt16_reg <= preproc_cmd_fifo_cnt[4:0] < 5'd16;
   end	  
	  
/// Ready Signal
   always_ff @ (posedge clk)
       if (srst_reg) 
         bam_rx_ready_o	<= 1'b0;
       else
         bam_rx_ready_o <=  preproc_cmd_fifo_lt16_reg & rx_data_fifo_lt16_reg;
         
assign rx_data_fifo_wrreq = bam_data_vld_reg & bam_hdr_reg[30] & (bam_hdr_reg[28:24]==5'b00000);



// Data payload FIFO
scfifo writedata_fifo
      (
       .clock            (clk                 ),
       .data             (bam_data_reg ),
       .rdreq            (rx_data_fifo_rdreq_i  ),
       .wrreq            (rx_data_fifo_wrreq), // only "with-data" type
       .q                (rx_data_fifo_rddata_o ),
       .empty            ( ),
       .sclr             (srst_reg              ),
       .usedw            (rx_data_fifo_count[7:0]   ),
       .aclr             (1'b0                ),
       .full             (  ),
       .almost_full      (),
       .almost_empty     (),
       .eccstatus       ());
    defparam
      writedata_fifo.add_ram_output_register  = "ON",
      writedata_fifo.enable_ecc  = "FALSE",
      writedata_fifo.intended_device_family  = "Agilex 7",
      writedata_fifo.lpm_hint  = "AUTO",
      writedata_fifo.lpm_numwords  = 256,
      writedata_fifo.lpm_showahead  = "ON",
      writedata_fifo.lpm_type  = "scfifo",
      writedata_fifo.lpm_width  = BAM_DATAWIDTH,
      writedata_fifo.lpm_widthu  = 8,
      writedata_fifo.overflow_checking  = "OFF",
      writedata_fifo.underflow_checking  = "OFF",
      writedata_fifo.use_eab  = "ON";
     
	  
   /// Pre-processing incomming header to pre-calcalulate AVMM transaction parameters                  
   intel_pcie_bam_v2_cmd_preproc 
   # (
  //.PFNUM_WIDTH(PFNUM_WIDTH),
  //.VFNUM_WIDTH(VFNUM_WIDTH),
  .BAM_DATAWIDTH(BAM_DATAWIDTH),
  .pf0_bar0_address_width_hwtcl(pf0_bar0_address_width_hwtcl),
  .pf0_bar1_address_width_hwtcl(pf0_bar1_address_width_hwtcl),
  .pf0_bar2_address_width_hwtcl(pf0_bar2_address_width_hwtcl),
  .pf0_bar3_address_width_hwtcl(pf0_bar3_address_width_hwtcl),
  .pf0_bar4_address_width_hwtcl(pf0_bar4_address_width_hwtcl),
  .pf0_bar5_address_width_hwtcl(pf0_bar5_address_width_hwtcl),
  .pf1_bar0_address_width_hwtcl(pf1_bar0_address_width_hwtcl),
  .pf1_bar1_address_width_hwtcl(pf1_bar1_address_width_hwtcl),
  .pf1_bar2_address_width_hwtcl(pf1_bar2_address_width_hwtcl),
  .pf1_bar3_address_width_hwtcl(pf1_bar3_address_width_hwtcl),
  .pf1_bar4_address_width_hwtcl(pf1_bar4_address_width_hwtcl),
  .pf1_bar5_address_width_hwtcl(pf1_bar5_address_width_hwtcl),
  .pf2_bar0_address_width_hwtcl(pf2_bar0_address_width_hwtcl),
  .pf2_bar1_address_width_hwtcl(pf2_bar1_address_width_hwtcl),
  .pf2_bar2_address_width_hwtcl(pf2_bar2_address_width_hwtcl),
  .pf2_bar3_address_width_hwtcl(pf2_bar3_address_width_hwtcl),
  .pf2_bar4_address_width_hwtcl(pf2_bar4_address_width_hwtcl),
  .pf2_bar5_address_width_hwtcl(pf2_bar5_address_width_hwtcl),
  .pf3_bar0_address_width_hwtcl(pf3_bar0_address_width_hwtcl),
  .pf3_bar1_address_width_hwtcl(pf3_bar1_address_width_hwtcl),
  .pf3_bar2_address_width_hwtcl(pf3_bar2_address_width_hwtcl),
  .pf3_bar3_address_width_hwtcl(pf3_bar3_address_width_hwtcl),
  .pf3_bar4_address_width_hwtcl(pf3_bar4_address_width_hwtcl),
  .pf3_bar5_address_width_hwtcl(pf3_bar5_address_width_hwtcl)
   )
   
   hdr_preproc                                                              
   (                                                                                                   
       .clk(clk),                                                                                      
       .rst_n(~srst_reg),                    
       .rx_hdr_valid_i(bam_hdr_vld_reg),           
       .rx_hdr_i({bam_vfnum_reg, bam_pfnum_reg, bam_vfactive_reg, bam_bar_reg, bam_hdr_reg}),                 
       .preproc_cmd_fifo_read_i(preproc_cmd_fifo_rdreq_i), 
       .preproc_cmd_fifo_data_o(preproc_cmd_fifo_rddata_o), 
       .preproc_cmd_fifo_count_o(preproc_cmd_fifo_cnt),
       .preproc_cmd_fifo_empty_o(preproc_cmd_fifo_empty_o),
       .max_payload_size_i(max_payload_size_i),
       .for_rxcrdt_tlp_len_o(for_rxcrdt_tlp_len_o),
       .for_rxcrdt_hdr_valid_o(for_rxcrdt_hdr_valid_o),
       .for_rxcrdt_hdr_is_rd_o(for_rxcrdt_hdr_is_rd_o),
       .for_rxcrdt_hdr_is_wr_o(for_rxcrdt_hdr_is_wr_o)

   );

      
    //TX Interface
   
always_ff @(posedge clk) 
  begin
    hdr_reg[96:0] <= tx_hdr_fifo_rdata_i[96:0];
    hdr_avail_reg <= ~tx_hdr_fifo_empty_i;
    tx_ready_reg <= bam_txc_ready_i;
  end

always_ff @(posedge clk) 
  if(pop_hdr_fifo)
    if(BAM_DATAWIDTH == 1024) begin //modified to cater 1024 and 256bit
       pcie_lines_cntr[3:0] <= (|hdr_reg[4:0])? hdr_reg[7:5] + 1'b1 : hdr_reg[7:5];
     end else if(BAM_DATAWIDTH == 512) begin
       pcie_lines_cntr[3:0] <= (|hdr_reg[3:0])? hdr_reg[7:4] + 1'b1 : hdr_reg[7:4];
     end else if(BAM_DATAWIDTH == 256) begin
       pcie_lines_cntr[3:0] <= (|hdr_reg[2:0])? hdr_reg[7:3] + 1'b1 : hdr_reg[7:3];
     end
  else if(send_state)
    pcie_lines_cntr[3:0] <= pcie_lines_cntr[3:0] - 1'b1;

always_ff @(posedge clk) 
    if (srst_reg) 
      tx_state[1:0]       <= TX_IDLE;
   else 
      tx_state[1:0]       <= tx_nxt_state;  

always_comb 
    case(tx_state) 
      TX_IDLE: 
        if(hdr_avail_reg & tx_ready_reg)   // pop hdr fifo here
          tx_nxt_state = TX_SEND; 
        else 
          tx_nxt_state = TX_IDLE;
      
      TX_SEND:
        if(pcie_lines_cntr[3:0] == 4'h1)
          tx_nxt_state = TX_IDLE;
        else
          tx_nxt_state = TX_SEND;
      
      default:
         tx_nxt_state = TX_IDLE;
   endcase
 
 
 assign idle_state  = (tx_state == TX_IDLE);
 assign send_state  = (tx_state == TX_SEND); 
 assign pause_state = (tx_state == TX_PAUSE);
 
 assign pop_hdr_fifo = idle_state & hdr_avail_reg & tx_ready_reg;
 assign tx_hdr_fifo_rreq_o = pop_hdr_fifo;
 
 /// CPL Ram read address
always_ff @(posedge clk) 
    if (srst_reg) 
      cplram_rd_addr[8:0]  <= 9'h0; 
    else if(send_state)
      cplram_rd_addr[8:0]  <= cplram_rd_addr[8:0] + 1'b1; 

assign cplram_rd_addr_o = cplram_rd_addr;

/// data pipe
always_ff @(posedge clk) 
  begin
  	tx_data_reg1[BAM_DATAWIDTH-1:0] <= cplram_rd_data_i[BAM_DATAWIDTH-1:0];                                              
  	tx_data_reg2[BAM_DATAWIDTH-1:0] <= tx_data_reg1;
  	tx_data_reg3[BAM_DATAWIDTH-1:0] <= tx_data_reg2;
  	tx_sop_reg1         <= cplram_rd_data_i[BAM_DATAWIDTH];
  	tx_sop_reg2         <= tx_sop_reg1;
  	tx_sop_reg3         <= tx_sop_reg2;
  	tx_eop_reg1         <= cplram_rd_data_i[BAM_DATAWIDTH+1];
  	tx_eop_reg2         <= tx_eop_reg1;
  	tx_eop_reg3         <= tx_eop_reg2;
  	tx_valid_reg1       <= send_state;
  	tx_valid_reg2       <= tx_valid_reg1;
  	tx_valid_reg3       <= tx_valid_reg2;
  	tx_header_reg2[96:0] <= tx_header_reg1[96:0];
    tx_header_reg3[96:0] <= tx_header_reg2[96:0];
  end


always_ff @(posedge clk) 
  if(pop_hdr_fifo)
      tx_header_reg1[96:0] <= tx_hdr_fifo_rdata_i[96:0];

/// assigning the output ports
assign pio_to_send_cpl	 = tx_valid_reg1 | tx_valid_reg2 | tx_valid_reg3;
assign bam_txc_valid_o   = tx_valid_reg3;
assign bam_txc_payload_o = tx_data_reg2;
assign bam_txc_sop_o     = tx_sop_reg2;
assign bam_txc_eop_o     = tx_eop_reg2;
assign bam_txc_header_o  = {32'h0,tx_header_reg3[95:0]};
assign bam_txc_vfactive_o = tx_header_reg3[96];
assign bam_txc_vfnum_o[VFNUM_WIDTH-1:0] = tx_header_reg3[50+VFNUM_WIDTH-1:50];
assign bam_txc_pfnum_o[PFNUM_WIDTH-1:0] = tx_header_reg3[48+PFNUM_WIDTH-1:48];


endmodule

module intel_pcie_bam_v2_cmd_preproc
  #(
    parameter PFNUM_WIDTH = 2,
    parameter VFNUM_WIDTH = 12,
    parameter BAM_DATAWIDTH = 256,
    parameter pf0_bar0_address_width_hwtcl     = 20,
  parameter pf0_bar1_address_width_hwtcl     = 0,
  parameter pf0_bar2_address_width_hwtcl     = 0,
  parameter pf0_bar3_address_width_hwtcl     = 0,
  parameter pf0_bar4_address_width_hwtcl     = 0,
  parameter pf0_bar5_address_width_hwtcl     = 0,

  parameter pf1_bar0_address_width_hwtcl     = 0,
  parameter pf1_bar1_address_width_hwtcl     = 0,
  parameter pf1_bar2_address_width_hwtcl     = 0,
  parameter pf1_bar3_address_width_hwtcl     = 0,
  parameter pf1_bar4_address_width_hwtcl     = 0,
  parameter pf1_bar5_address_width_hwtcl     = 0,

  parameter pf2_bar0_address_width_hwtcl     = 0,
  parameter pf2_bar1_address_width_hwtcl     = 0,
  parameter pf2_bar2_address_width_hwtcl     = 0,
  parameter pf2_bar3_address_width_hwtcl     = 0,
  parameter pf2_bar4_address_width_hwtcl     = 0,
  parameter pf2_bar5_address_width_hwtcl     = 0,

  parameter pf3_bar0_address_width_hwtcl     = 0,
  parameter pf3_bar1_address_width_hwtcl     = 0,
  parameter pf3_bar2_address_width_hwtcl     = 0,
  parameter pf3_bar3_address_width_hwtcl     = 0,
  parameter pf3_bar4_address_width_hwtcl     = 0,
  parameter pf3_bar5_address_width_hwtcl     = 0
    )
  (
   input logic           clk,
   input logic           rst_n,

   input logic           rx_hdr_valid_i,
   input logic [145:0]   rx_hdr_i,
   
   input  logic          preproc_cmd_fifo_read_i,
   output logic [430:0]  preproc_cmd_fifo_data_o,
   output logic [4:0]    preproc_cmd_fifo_count_o,
   output logic          preproc_cmd_fifo_empty_o,
   
   input  logic   [2:0]  max_payload_size_i,
   output logic [9:0]    for_rxcrdt_tlp_len_o,
   output logic          for_rxcrdt_hdr_valid_o,
   output logic          for_rxcrdt_hdr_is_rd_o,
   output logic          for_rxcrdt_hdr_is_wr_o

   );
logic   [63:0]     pf0_bar0_address_mask     =  { {(64-pf0_bar0_address_width_hwtcl){1'b0}},   {(pf0_bar0_address_width_hwtcl){1'b1}} };
logic   [63:0]     pf0_bar1_address_mask     =  { {(64-pf0_bar1_address_width_hwtcl){1'b0}},   {(pf0_bar1_address_width_hwtcl){1'b1}} };
logic   [63:0]     pf0_bar2_address_mask     =  { {(64-pf0_bar2_address_width_hwtcl){1'b0}},   {(pf0_bar2_address_width_hwtcl){1'b1}} };
logic   [63:0]     pf0_bar3_address_mask     =  { {(64-pf0_bar3_address_width_hwtcl){1'b0}},   {(pf0_bar3_address_width_hwtcl){1'b1}} };
logic   [63:0]     pf0_bar4_address_mask     =  { {(64-pf0_bar4_address_width_hwtcl){1'b0}},   {(pf0_bar4_address_width_hwtcl){1'b1}} };
logic   [63:0]     pf0_bar5_address_mask     =  { {(64-pf0_bar5_address_width_hwtcl){1'b0}},   {(pf0_bar5_address_width_hwtcl){1'b1}} };

logic   [63:0]     pf1_bar0_address_mask     =  { {(64-pf1_bar0_address_width_hwtcl){1'b0}},   {(pf1_bar0_address_width_hwtcl){1'b1}} };
logic   [63:0]     pf1_bar1_address_mask     =  { {(64-pf1_bar1_address_width_hwtcl){1'b0}},   {(pf1_bar1_address_width_hwtcl){1'b1}} };
logic   [63:0]     pf1_bar2_address_mask     =  { {(64-pf1_bar2_address_width_hwtcl){1'b0}},   {(pf1_bar2_address_width_hwtcl){1'b1}} };
logic   [63:0]     pf1_bar3_address_mask     =  { {(64-pf1_bar3_address_width_hwtcl){1'b0}},   {(pf1_bar3_address_width_hwtcl){1'b1}} };
logic   [63:0]     pf1_bar4_address_mask     =  { {(64-pf1_bar4_address_width_hwtcl){1'b0}},   {(pf1_bar4_address_width_hwtcl){1'b1}} };
logic   [63:0]     pf1_bar5_address_mask     =  { {(64-pf1_bar5_address_width_hwtcl){1'b0}},   {(pf1_bar5_address_width_hwtcl){1'b1}} };

logic   [63:0]     pf2_bar0_address_mask     =  { {(64-pf2_bar0_address_width_hwtcl){1'b0}},   {(pf2_bar0_address_width_hwtcl){1'b1}} };
logic   [63:0]     pf2_bar1_address_mask     =  { {(64-pf2_bar1_address_width_hwtcl){1'b0}},   {(pf2_bar1_address_width_hwtcl){1'b1}} };
logic   [63:0]     pf2_bar2_address_mask     =  { {(64-pf2_bar2_address_width_hwtcl){1'b0}},   {(pf2_bar2_address_width_hwtcl){1'b1}} };
logic   [63:0]     pf2_bar3_address_mask     =  { {(64-pf2_bar3_address_width_hwtcl){1'b0}},   {(pf2_bar3_address_width_hwtcl){1'b1}} };
logic   [63:0]     pf2_bar4_address_mask     =  { {(64-pf2_bar4_address_width_hwtcl){1'b0}},   {(pf2_bar4_address_width_hwtcl){1'b1}} };
logic   [63:0]     pf2_bar5_address_mask     =  { {(64-pf2_bar5_address_width_hwtcl){1'b0}},   {(pf2_bar5_address_width_hwtcl){1'b1}} };

logic   [63:0]     pf3_bar0_address_mask     =  { {(64-pf3_bar0_address_width_hwtcl){1'b0}},   {(pf3_bar0_address_width_hwtcl){1'b1}} };
logic   [63:0]     pf3_bar1_address_mask     =  { {(64-pf3_bar1_address_width_hwtcl){1'b0}},   {(pf3_bar1_address_width_hwtcl){1'b1}} };
logic   [63:0]     pf3_bar2_address_mask     =  { {(64-pf3_bar2_address_width_hwtcl){1'b0}},   {(pf3_bar2_address_width_hwtcl){1'b1}} };
logic   [63:0]     pf3_bar3_address_mask     =  { {(64-pf3_bar3_address_width_hwtcl){1'b0}},   {(pf3_bar3_address_width_hwtcl){1'b1}} };
logic   [63:0]     pf3_bar4_address_mask     =  { {(64-pf3_bar4_address_width_hwtcl){1'b0}},   {(pf3_bar4_address_width_hwtcl){1'b1}} };
logic   [63:0]     pf3_bar5_address_mask     =  { {(64-pf3_bar5_address_width_hwtcl){1'b0}},   {(pf3_bar5_address_width_hwtcl){1'b1}} };
    

  
   // *---------- Internal Signal Definition -------------*
    // All register signals are started with p*_*, numbers indicate the stage of pipeline
    //--------------------------------------------
    // 1st stage of pipeline signals

    logic [145:0]        rx_hdr_fifo_rdata_reg1;
        
    // header decode, done at the 1st stage of pipeline

    logic [9:0]          tlp_len_reg1;  
    logic                tlp_is_wr_reg1;
    logic                tlp_hdr_4dw_reg1;
    logic [63:0]         tlp_addr_reg1;
    logic [9:0]          tlp_tag_reg1;     
    logic [9:0]          tlp_tag_reg2;
    logic [9:0]          tlp_tag_reg3;
    logic [9:0]          tlp_tag_reg4;
    logic [9:0]          tlp_tag_reg5;
    logic [9:0]          tlp_tag_reg6;
    logic [9:0]          tlp_tag_reg7;
    logic [2:0]          tlp_attr_reg1;
    logic [2:0]          tlp_attr_reg2;
    logic [2:0]          tlp_attr_reg3;
    logic [2:0]          tlp_attr_reg4;
    logic [2:0]          tlp_attr_reg5;
    logic [2:0]          tlp_attr_reg6;
    logic [2:0]          tlp_attr_reg7;    
    
    
    logic [2:0]          tlp_tc_reg1;
    logic [2:0]          tlp_tc_reg2;
    logic [2:0]          tlp_tc_reg3;
    logic [2:0]          tlp_tc_reg4;
    logic [2:0]          tlp_tc_reg5;
    logic [2:0]          tlp_tc_reg6;
    logic [2:0]          tlp_tc_reg7;
    logic [15:0]         tlp_reqid_reg1;
    logic [15:0]         tlp_reqid_reg2;
    logic [15:0]         tlp_reqid_reg3;
    logic [15:0]         tlp_reqid_reg4;
    logic [15:0]         tlp_reqid_reg5;
    logic [15:0]         tlp_reqid_reg6;
    logic [15:0]         tlp_reqid_reg7;

    logic [2:0]          tlp_bar_reg1;
    logic [2:0]          tlp_bar_reg2;
    logic [2:0]          tlp_bar_reg3;    
    logic [2:0]          tlp_bar_reg4;
    logic [2:0]          tlp_bar_reg5;    
    logic [2:0]          tlp_bar_reg6;
    logic [2:0]          tlp_bar_reg7;
    logic [3:0]          tlp_fbe_reg1;
    logic [3:0]          tlp_fbe_reg2;
    logic [3:0]          tlp_fbe_reg3;
    logic [3:0]          tlp_fbe_reg4;
    logic [3:0]          tlp_fbe_reg5;
    logic [3:0]          tlp_fbe_reg6;
    logic [3:0]          tlp_fbe_reg7;     
    logic                flush_be_reg1; 
    logic                flush_be_reg2; 
    logic                flush_be_reg3; 
    logic                flush_be_reg4; 
    logic                flush_be_reg5; 
    logic                flush_be_reg6; 
    logic                flush_be_reg7; 
    
    logic [3:0]          tlp_lbe_reg1;
    logic [3:0]          tlp_lbe_reg2;
    logic [3:0]          tlp_lbe_reg3;
    logic [3:0]          tlp_lbe_reg4;
    logic [3:0]          tlp_lbe_reg5;
    logic [3:0]          tlp_lbe_reg6;
    logic [3:0]          tlp_lbe_reg7;
    logic [3:0]          tlp_lbe_orig_reg2;

    logic                tlp_vfactive_reg1;
    logic                tlp_vfactive_reg2;
    logic                tlp_vfactive_reg3;
    logic                tlp_vfactive_reg4;
    logic                tlp_vfactive_reg5;
    logic                tlp_vfactive_reg6;
    logic                tlp_vfactive_reg7;

    logic [PFNUM_WIDTH-1:0] tlp_pfnum_reg1;
    logic [PFNUM_WIDTH-1:0] tlp_pfnum_reg2;
    logic [PFNUM_WIDTH-1:0] tlp_pfnum_reg3;
    logic [PFNUM_WIDTH-1:0] tlp_pfnum_reg4;
    logic [PFNUM_WIDTH-1:0] tlp_pfnum_reg5;
    logic [PFNUM_WIDTH-1:0] tlp_pfnum_reg6;
    logic [PFNUM_WIDTH-1:0] tlp_pfnum_reg7;


    logic [VFNUM_WIDTH-1:0] tlp_vfnum_reg1; 
    logic [VFNUM_WIDTH-1:0] tlp_vfnum_reg2; 
    logic [VFNUM_WIDTH-1:0] tlp_vfnum_reg3; 
    logic [VFNUM_WIDTH-1:0] tlp_vfnum_reg4; 
    logic [VFNUM_WIDTH-1:0] tlp_vfnum_reg5; 
    logic [VFNUM_WIDTH-1:0] tlp_vfnum_reg6; 
    logic [VFNUM_WIDTH-1:0] tlp_vfnum_reg7; 




    logic                   hdr_valid_reg1;
    logic                   hdr_valid_reg2;
    logic                   hdr_valid_reg3;
    logic                   hdr_valid_reg4;
    logic                   hdr_valid_reg5;
    logic                   hdr_valid_reg6;
    logic                   hdr_valid_reg7;
    logic   [63:0]          tlp_addr_reg2;     
    logic   [63:0]          tlp_addr_reg3;     
    logic   [63:0]          tlp_addr_reg4;     
    logic   [63:0]          tlp_addr_reg5;     
    logic   [63:0]          tlp_addr_reg6;     
    logic   [63:0]          tlp_addr_reg7; 
    logic   [10:0]           avmm_dw_cnt_reg2; 
    logic   [6:0]           avmm_burstcnt_reg3; 
    logic   [6:0]           avmm_burstcnt_reg4; 
    logic   [6:0]           avmm_burstcnt_reg5; 
    logic   [6:0]           avmm_burstcnt_reg6; 
    logic   [6:0]           avmm_burstcnt_reg7; 
    logic   [127:0]          avmm_fbe_reg2;
    logic   [127:0]          avmm_fbe_reg3;
    logic   [127:0]          avmm_fbe_reg4;
    logic   [127:0]          avmm_fbe_reg5;
    logic   [127:0]          avmm_fbe_reg6;   
    logic   [127:0]          avmm_fbe_reg7;      
    logic   [127:0]          avmm_lbe_reg3;
    logic   [127:0]          avmm_lbe_reg4;
    logic   [127:0]          avmm_lbe_reg5;
    logic   [127:0]          avmm_lbe_reg6;
    logic   [127:0]          avmm_lbe_reg7;
    logic                   tlp_is_wr_reg2; 
    logic                   tlp_is_wr_reg3;
    logic                   tlp_is_wr_reg4; 
    logic                   tlp_is_wr_reg5; 
    logic                   tlp_is_wr_reg6;  
    logic                   tlp_is_wr_reg7;     
    logic                   tlp_is_rd_reg2; 
    logic                   tlp_is_rd_reg3;
    logic                   tlp_is_rd_reg4; 
    logic                   tlp_is_rd_reg5; 
    logic                   tlp_is_rd_reg6;  
    logic                   tlp_is_rd_reg7;  
    logic                   addr_512_unaligned_reg2; 
    logic                   addr_256_unaligned_reg2; 
    logic                   addr_128_unaligned_reg2; 
    logic   [7:0]           dw_to_512_reg2;     
    logic   [7:0]           dw_to_256_reg2;  
    logic   [7:0]           dw_to_128_reg2; 
    logic   [7:0]           dw_to_mps_zero_reg4;
    logic    [3:0]          pcie_lines_reg2;
    logic    [3:0]          pcie_lines_reg3;
    logic    [3:0]          pcie_lines_reg4;
    logic    [3:0]          pcie_lines_reg5;
    logic    [3:0]          pcie_lines_reg6;
    logic    [3:0]          pcie_lines_reg7;   
    logic    [7:0]          dw_to_mps_reg3; 
    logic    [7:0]          dw_to_mps_reg4;
    logic                   len_lt_dw2_mps_reg4;
    logic                   type_1_exist_reg5;
    logic                   type_1_exist_reg6;    
    logic                   type_1_exist_reg7;    
    
    logic   [7:0]           type_1_size_reg5;
    logic   [7:0]           type_1_size_reg6;    
    logic   [7:0]           type_1_size_reg7;    
    logic                   type_2_exist_reg4;
    logic                   type_2_exist_reg5;
    logic                   type_2_exist_reg6;
    logic                   type_2_exist_reg7;  
    logic                   addr_mps_unaligned_reg3;
    logic                   addr_mps_unaligned_reg4;    
    logic   [4:0]           num_aligned_type_2_reg6;
    logic                   type_2_remainder_reg6;
    logic   [4:0]           num_type_2_reg7;
    logic   [4:0]           num_type_2_comb6;
    logic   [2:0]           mps_reg1;
    logic                   mps_128_reg2; 
    logic                   mps_256_reg2; 
    logic                   mps_128_reg3; 
    logic                   mps_256_reg3; 
    logic                   mps_128_reg4; 
    logic                   mps_256_reg4; 
    logic                   mps_128_reg5; 
    logic                   mps_256_reg5;            
    logic   [6:0]           avmm_address_plus_dw_size_reg2;
    logic   [6:0]           lower_addr_reg2;
    logic   [6:0]           lower_addr_reg3;    
    logic   [6:0]           lower_addr_reg4;    
    logic   [6:0]           lower_addr_reg5;
    logic   [6:0]           lower_addr_reg6;
    logic   [6:0]           lower_addr_reg7;

    logic   [9:0]           tlp_len_reg2;
    logic   [9:0]           tlp_len_reg3;
    logic   [9:0]           tlp_len_reg4;
    logic   [9:0]           tlp_len_reg5;
    logic   [9:0]           tlp_len_reg6;
    logic   [9:0]           tlp_len_reg7;
    logic   [9:0]           dw_size_less_mps_reg5;
    logic   [6:0]           last_type_2_dwsize_reg6;
    logic   [6:0]           last_type_2_dwsize_reg7;    
    logic   [430:0]         preproc_cmd_fifo_data;  
    logic                   srst_reg;
    logic   [63:0] pf0_addr_mask_reg2;
    logic   [63:0] pf1_addr_mask_reg2;
    logic   [63:0] pf2_addr_mask_reg2;
    logic   [63:0] pf3_addr_mask_reg2;
    logic   [63:0] pf0_addr_mask_reg3;
    logic   [63:0] pf1_addr_mask_reg3;
    logic   [63:0] pf2_addr_mask_reg3;
    logic   [63:0] pf3_addr_mask_reg3;
    logic   [63:0] bam_addr_mask_reg3;
    logic   [63:0] bam_addr_mask_reg4; 



/// address mask

always_comb
  case(tlp_bar_reg2)
      3'b001 : pf0_addr_mask_reg2 = pf0_bar1_address_mask;
      3'b010 : pf0_addr_mask_reg2 = pf0_bar2_address_mask;
      3'b011 : pf0_addr_mask_reg2 = pf0_bar3_address_mask;
      3'b100 : pf0_addr_mask_reg2 = pf0_bar4_address_mask;
      3'b101 : pf0_addr_mask_reg2 = pf0_bar5_address_mask;
      default: pf0_addr_mask_reg2 = pf0_bar0_address_mask;
  endcase


always_comb
  case(tlp_bar_reg2)
      3'b001 : pf1_addr_mask_reg2 = pf1_bar1_address_mask;
      3'b010 : pf1_addr_mask_reg2 = pf1_bar2_address_mask;
      3'b011 : pf1_addr_mask_reg2 = pf1_bar3_address_mask;
      3'b100 : pf1_addr_mask_reg2 = pf1_bar4_address_mask;
      3'b101 : pf1_addr_mask_reg2 = pf1_bar5_address_mask;
      default: pf1_addr_mask_reg2 = pf1_bar0_address_mask;
  endcase

  always_comb
  case(tlp_bar_reg2)
      3'b001 : pf2_addr_mask_reg2 = pf2_bar1_address_mask;
      3'b010 : pf2_addr_mask_reg2 = pf2_bar2_address_mask;
      3'b011 : pf2_addr_mask_reg2 = pf2_bar3_address_mask;
      3'b100 : pf2_addr_mask_reg2 = pf2_bar4_address_mask;
      3'b101 : pf2_addr_mask_reg2 = pf2_bar5_address_mask;
      default: pf2_addr_mask_reg2 = pf2_bar0_address_mask;
  endcase

  always_comb
  case(tlp_bar_reg2)
      3'b001 : pf3_addr_mask_reg2 = pf3_bar1_address_mask;
      3'b010 : pf3_addr_mask_reg2 = pf3_bar2_address_mask;
      3'b011 : pf3_addr_mask_reg2 = pf3_bar3_address_mask;
      3'b100 : pf3_addr_mask_reg2 = pf3_bar4_address_mask;
      3'b101 : pf3_addr_mask_reg2 = pf3_bar5_address_mask;
      default: pf3_addr_mask_reg2 = pf3_bar0_address_mask;
  endcase


always_ff @(posedge clk) 
     begin
      pf0_addr_mask_reg3[63:0] <= pf0_addr_mask_reg2[63:0]; 
      pf1_addr_mask_reg3[63:0] <= pf1_addr_mask_reg2[63:0]; 
      pf2_addr_mask_reg3[63:0] <= pf2_addr_mask_reg2[63:0]; 
      pf3_addr_mask_reg3[63:0] <= pf3_addr_mask_reg2[63:0]; 
     end


always_comb
  case(tlp_pfnum_reg3)
      2'b01 : bam_addr_mask_reg3 = pf1_addr_mask_reg3;
      2'b10 : bam_addr_mask_reg3 = pf2_addr_mask_reg3;
      2'b11 : bam_addr_mask_reg3 = pf3_addr_mask_reg3;
      default: bam_addr_mask_reg3 = pf0_addr_mask_reg3;
  endcase

 always_ff @(posedge clk) 
     begin
      bam_addr_mask_reg4[63:0] <= bam_addr_mask_reg3[63:0]; 
     end

 always_ff @(posedge clk)        
  srst_reg        <= ~rst_n;   
    
always_ff @(posedge clk) 
  begin
    mps_reg1        <=  max_payload_size_i[2:0];
    mps_128_reg2    <= (mps_reg1 == 3'b000);
    mps_256_reg2    <= (mps_reg1 == 3'b001);
    mps_128_reg3    <= mps_128_reg2;
    mps_256_reg3    <= mps_256_reg2;
    mps_128_reg4    <= mps_128_reg3;
    mps_256_reg4    <= mps_256_reg3;
    mps_128_reg5    <= mps_128_reg4;
    mps_256_reg5    <= mps_256_reg4;
  end 


    
    always_ff @ (posedge clk)
        rx_hdr_fifo_rdata_reg1    <= rx_hdr_i;

   always_ff @ (posedge clk)
     begin
     	hdr_valid_reg1 <= rx_hdr_valid_i;
     	hdr_valid_reg2 <= hdr_valid_reg1;
     	hdr_valid_reg3 <= hdr_valid_reg2;
     	hdr_valid_reg4 <= hdr_valid_reg3;
     	hdr_valid_reg5 <= hdr_valid_reg4;
     	hdr_valid_reg6 <= hdr_valid_reg5;
     	hdr_valid_reg7 <= hdr_valid_reg6;
     end
    
    //----------------------------------------------------------------
    // TLP header decoding
  
    assign tlp_len_reg1     = rx_hdr_fifo_rdata_reg1[9:0];
    assign tlp_hdr_4dw_reg1 = rx_hdr_fifo_rdata_reg1[29];
    assign tlp_addr_reg1    = tlp_hdr_4dw_reg1 ? {rx_hdr_fifo_rdata_reg1[95:64], rx_hdr_fifo_rdata_reg1[127:96]}: {32'h0, rx_hdr_fifo_rdata_reg1[95:64]};
    assign tlp_bar_reg1     = rx_hdr_fifo_rdata_reg1[130:128];
    assign tlp_vfactive_reg1= rx_hdr_fifo_rdata_reg1[131];
    assign tlp_pfnum_reg1   = rx_hdr_fifo_rdata_reg1[133:132];
    assign tlp_vfnum_reg1   = rx_hdr_fifo_rdata_reg1[145:135];
        
    //read request info
    assign tlp_tag_reg1     = (rx_hdr_fifo_rdata_reg1[23] || rx_hdr_fifo_rdata_reg1[19]) ? {rx_hdr_fifo_rdata_reg1[23], rx_hdr_fifo_rdata_reg1[19], rx_hdr_fifo_rdata_reg1[47:40]} : {2'b0, rx_hdr_fifo_rdata_reg1[47:40]};
    assign tlp_attr_reg1    = {rx_hdr_fifo_rdata_reg1[18], rx_hdr_fifo_rdata_reg1[13:12]};
    assign tlp_tc_reg1      = rx_hdr_fifo_rdata_reg1[22:20];
    assign tlp_reqid_reg1   = rx_hdr_fifo_rdata_reg1[63:48];
    assign flush_be_reg1    =  {rx_hdr_fifo_rdata_reg1[39:36],rx_hdr_fifo_rdata_reg1[35:32]} == 8'h0;
    assign tlp_fbe_reg1     = (flush_be_reg1)? 4'hF : rx_hdr_fifo_rdata_reg1[35:32];
    assign tlp_lbe_reg1     = rx_hdr_fifo_rdata_reg1[39:36];

    assign tlp_is_wr_reg1   =  rx_hdr_fifo_rdata_reg1[30] & (rx_hdr_fifo_rdata_reg1[28:24]==5'b00000);
    assign tlp_is_rd_reg1   = ~rx_hdr_fifo_rdata_reg1[30] & (rx_hdr_fifo_rdata_reg1[28:26]== 3'b000);  
 

 // avmm address
 always_ff @(posedge clk) 
     begin
      tlp_addr_reg2[63:0] <= tlp_addr_reg1[63:0]; 
      tlp_addr_reg3[63:0] <= tlp_addr_reg2[63:0]; 
      tlp_addr_reg4[63:0] <= tlp_addr_reg3[63:0]; 
       tlp_addr_reg5[63:0] <= tlp_addr_reg4[63:0] & bam_addr_mask_reg4[63:0]; 
       //tlp_addr_reg5[63:0] <= tlp_addr_reg4[63:0] ; 
      tlp_addr_reg6[63:0] <= tlp_addr_reg5[63:0]; 
      tlp_addr_reg7[63:0] <= tlp_addr_reg6[63:0]; 
     end

 /// fbe/lbe
 
 always_ff @(posedge clk) 
     begin
      tlp_fbe_reg2[3:0] <= tlp_fbe_reg1[3:0]; 
      tlp_fbe_reg3[3:0] <= tlp_fbe_reg2[3:0]; 
      tlp_fbe_reg4[3:0] <= tlp_fbe_reg3[3:0]; 
      tlp_fbe_reg5[3:0] <= tlp_fbe_reg4[3:0]; 
      tlp_fbe_reg6[3:0] <= tlp_fbe_reg5[3:0]; 
      tlp_fbe_reg7[3:0] <= tlp_fbe_reg6[3:0];
      
      tlp_lbe_reg3[3:0] <= tlp_lbe_orig_reg2[3:0];
      tlp_lbe_reg4[3:0] <= tlp_lbe_reg3[3:0];
      tlp_lbe_reg5[3:0] <= tlp_lbe_reg4[3:0];
      tlp_lbe_reg6[3:0] <= tlp_lbe_reg5[3:0];
      tlp_lbe_reg7[3:0] <= tlp_lbe_reg6[3:0];
      
      flush_be_reg2     <= flush_be_reg1;
      flush_be_reg3     <= flush_be_reg2;
      flush_be_reg4     <= flush_be_reg3;
      flush_be_reg5     <= flush_be_reg4;
      flush_be_reg6     <= flush_be_reg5;
      flush_be_reg7     <= flush_be_reg6;
     end 
 
   
    /// Calculate the avmm total burst count
    ///avmm_dw_cnt_reg2 is calculating how many dw is needed to do transfer
  always_ff @ (posedge clk)   
    begin
     if(BAM_DATAWIDTH == 1024) begin //modified to cater 1024 and 256bit
        avmm_dw_cnt_reg2[10:0] <= tlp_len_reg1[9:0] + tlp_addr_reg1[6:2];
        avmm_burstcnt_reg3[6:0] <= (avmm_dw_cnt_reg2[4:0] == 5'h0)? {1'b0,avmm_dw_cnt_reg2[10:5]} : avmm_dw_cnt_reg2[10:5] + 1'b1;
     end else if(BAM_DATAWIDTH == 512) begin
        avmm_dw_cnt_reg2[10:0] <= tlp_len_reg1[9:0] + tlp_addr_reg1[5:2];
        avmm_burstcnt_reg3[6:0] <= (avmm_dw_cnt_reg2[3:0] == 4'h0)? {avmm_dw_cnt_reg2[10:4]} : avmm_dw_cnt_reg2[10:4] + 1'b1;
     end else if(BAM_DATAWIDTH == 256) begin
        avmm_dw_cnt_reg2[10:0] <= tlp_len_reg1[9:0] + tlp_addr_reg1[4:2];
        avmm_burstcnt_reg3[6:0] <= (avmm_dw_cnt_reg2[2:0] == 3'h0)? {avmm_dw_cnt_reg2[10:3]} : avmm_dw_cnt_reg2[10:3] + 1'b1;
     end
     avmm_burstcnt_reg4[6:0] <= avmm_burstcnt_reg3;
     avmm_burstcnt_reg5[6:0] <= avmm_burstcnt_reg4;
     avmm_burstcnt_reg6[6:0] <= avmm_burstcnt_reg5;
     avmm_burstcnt_reg7[6:0] <= avmm_burstcnt_reg6;
    end
    
   /// Calculate the avmm_fbe[63:0]
 always_ff @(posedge clk)  
   begin
     if(BAM_DATAWIDTH == 1024) begin //modified to cater 1024 and 256bit
       avmm_fbe_reg2[127:0] <= {124'hFFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFF, tlp_fbe_reg1} << {tlp_addr_reg1[6:2], 2'h0};
       avmm_fbe_reg3[127:0] <= avmm_fbe_reg2[127:0];
       avmm_fbe_reg4[127:0] <= avmm_fbe_reg3[127:0];
       avmm_fbe_reg5[127:0] <= avmm_fbe_reg4[127:0];
       avmm_fbe_reg6[127:0] <= avmm_fbe_reg5[127:0];
       avmm_fbe_reg7[127:0] <= avmm_fbe_reg6[127:0];
     end else if(BAM_DATAWIDTH == 512) begin
       avmm_fbe_reg2[63:0] <= {60'hFFFF_FFFF_FFFF_FFF, tlp_fbe_reg1} << {tlp_addr_reg1[5:2], 2'h0};
       avmm_fbe_reg3[63:0] <= avmm_fbe_reg2[63:0];
       avmm_fbe_reg4[63:0] <= avmm_fbe_reg3[63:0];
       avmm_fbe_reg5[63:0] <= avmm_fbe_reg4[63:0];
       avmm_fbe_reg6[63:0] <= avmm_fbe_reg5[63:0];
       avmm_fbe_reg7[63:0] <= avmm_fbe_reg6[63:0];
     end else if(BAM_DATAWIDTH == 256) begin
       avmm_fbe_reg2[31:0] <= {28'hFFFF_FFF, tlp_fbe_reg1} << {tlp_addr_reg1[4:2], 2'h0};
       avmm_fbe_reg3[31:0] <= avmm_fbe_reg2[31:0];
       avmm_fbe_reg4[31:0] <= avmm_fbe_reg3[31:0];
       avmm_fbe_reg5[31:0] <= avmm_fbe_reg4[31:0];
       avmm_fbe_reg6[31:0] <= avmm_fbe_reg5[31:0];
       avmm_fbe_reg7[31:0] <= avmm_fbe_reg6[31:0];
     end
     tlp_lbe_reg2[3:0]   <= (tlp_lbe_reg1[3:0] == 4'h0)? 4'hF : tlp_lbe_reg1[3:0]; /// if DW=1, this used as masked instead of real BE
     tlp_lbe_orig_reg2[3:0]     <= tlp_lbe_reg1[3:0];
     
    end
 

/// PCIe Lines
///QHIP max support is 4096bit which is 128byte per transfer. TLP length at 8bit only.
 always_ff @ (posedge clk)   
   begin
    if(BAM_DATAWIDTH == 1024) begin //modified to cater 1024 and 256bit
     pcie_lines_reg2[3:0] <= (tlp_len_reg1[4:0] == 5'h0)? tlp_len_reg1[7:5] : tlp_len_reg1[7:5] + 1'b1;   
     end else if(BAM_DATAWIDTH == 512) begin
     pcie_lines_reg2[3:0] <= (tlp_len_reg1[3:0] == 4'h0)? tlp_len_reg1[7:4] : tlp_len_reg1[7:4] + 1'b1;
     end else if(BAM_DATAWIDTH == 256) begin
     pcie_lines_reg2[3:0] <= (tlp_len_reg1[2:0] == 3'h0)? tlp_len_reg1[7:3] : tlp_len_reg1[7:3] + 1'b1;
     end
    pcie_lines_reg3[3:0] <= pcie_lines_reg2[3:0];
    pcie_lines_reg4[3:0] <= pcie_lines_reg3[3:0];
    pcie_lines_reg5[3:0] <= pcie_lines_reg4[3:0];
    pcie_lines_reg6[3:0] <= pcie_lines_reg5[3:0];
    pcie_lines_reg7[3:0] <= pcie_lines_reg6[3:0];
   end
         
    /// Calculate the avmm_lbe[63:0]
       
    always_ff @(posedge clk) 
      begin
        if(BAM_DATAWIDTH == 1024) begin 
           avmm_address_plus_dw_size_reg2[6:0] <= tlp_addr_reg1[6:0] + {tlp_len_reg1[4:0], 2'b00};  
        end else if(BAM_DATAWIDTH == 512) begin
           avmm_address_plus_dw_size_reg2[6:0] <= tlp_addr_reg1[5:0] + {tlp_len_reg1[3:0], 2'b00};   
        end else if(BAM_DATAWIDTH == 256) begin
           avmm_address_plus_dw_size_reg2[6:0] <= tlp_addr_reg1[4:0] + {tlp_len_reg1[2:0], 2'b00};
        end
      end
   
     always_ff @(posedge clk)  ///  last Tail BE
       begin
          if(BAM_DATAWIDTH == 1024) begin
           case(avmm_address_plus_dw_size_reg2[6:2])
             5'h1: avmm_lbe_reg3[127:0]       <= {124'h0, tlp_lbe_reg2[3:0]       };
             5'h2: avmm_lbe_reg3[127:0]       <= {120'h0, tlp_lbe_reg2[3:0], 4'hF};
             5'h3: avmm_lbe_reg3[127:0]       <= {116'h0, tlp_lbe_reg2[3:0], 8'hFF};
             5'h4: avmm_lbe_reg3[127:0]       <= {112'h0, tlp_lbe_reg2[3:0],12'hFFF};
             5'h5: avmm_lbe_reg3[127:0]       <= {108'h0, tlp_lbe_reg2[3:0],16'hFFFF};
             5'h6: avmm_lbe_reg3[127:0]       <= {104'h0, tlp_lbe_reg2[3:0],20'hFFFFF};
             5'h7: avmm_lbe_reg3[127:0]       <= {100'h0, tlp_lbe_reg2[3:0],24'hFFFFFF};
             5'h8: avmm_lbe_reg3[127:0]       <= {96'h0, tlp_lbe_reg2[3:0], 28'hFFFFFFF};
             5'h9: avmm_lbe_reg3[127:0]       <= {92'h0, tlp_lbe_reg2[3:0], 32'hFFFFFFFF};
             5'hA: avmm_lbe_reg3[127:0]       <= {88'h0, tlp_lbe_reg2[3:0], 36'hFFFFFFFFF};
             5'hB: avmm_lbe_reg3[127:0]       <= {84'h0, tlp_lbe_reg2[3:0], 40'hFFFFFFFFFF};
             5'hC: avmm_lbe_reg3[127:0]       <= {80'h0, tlp_lbe_reg2[3:0], 44'hFFFFFFFFFFF};
             5'hD: avmm_lbe_reg3[127:0]       <= {76'h0, tlp_lbe_reg2[3:0], 48'hFFFFFFFFFFFF};
             5'hE: avmm_lbe_reg3[127:0]       <= {72'h0, tlp_lbe_reg2[3:0], 52'hFFFFFFFFFFFFF};
             5'hF: avmm_lbe_reg3[127:0]       <= {68'h0, tlp_lbe_reg2[3:0], 56'hFFFFFFFFFFFFFF};
             5'h10: avmm_lbe_reg3[127:0]      <= {64'h0, tlp_lbe_reg2[3:0], 60'hFFFFFFFFFFFFFFF};
             5'h11: avmm_lbe_reg3[127:0]      <= {60'h0, tlp_lbe_reg2[3:0], 64'hFFFFFFFFFFFFFFFF};
             5'h12: avmm_lbe_reg3[127:0]      <= {56'h0, tlp_lbe_reg2[3:0], 68'hFFFFFFFFFFFFFFFFF};
             5'h13: avmm_lbe_reg3[127:0]      <= {52'h0, tlp_lbe_reg2[3:0], 72'hFFFFFFFFFFFFFFFFFF};
             5'h14: avmm_lbe_reg3[127:0]      <= {48'h0, tlp_lbe_reg2[3:0], 76'hFFFFFFFFFFFFFFFFFFF};
             5'h15: avmm_lbe_reg3[127:0]      <= {44'h0, tlp_lbe_reg2[3:0], 80'hFFFFFFFFFFFFFFFFFFFF};
             5'h16: avmm_lbe_reg3[127:0]      <= {40'h0, tlp_lbe_reg2[3:0], 84'hFFFFFFFFFFFFFFFFFFFFF};
             5'h17: avmm_lbe_reg3[127:0]      <= {36'h0, tlp_lbe_reg2[3:0], 88'hFFFFFFFFFFFFFFFFFFFFFF};
             5'h18: avmm_lbe_reg3[127:0]      <= {32'h0, tlp_lbe_reg2[3:0], 92'hFFFFFFFFFFFFFFFFFFFFFFF};
             5'h19: avmm_lbe_reg3[127:0]      <= {28'h0, tlp_lbe_reg2[3:0], 96'hFFFFFFFFFFFFFFFFFFFFFFFF};
             5'h1A: avmm_lbe_reg3[127:0]      <= {24'h0, tlp_lbe_reg2[3:0],100'hFFFFFFFFFFFFFFFFFFFFFFFFF};
             5'h1B: avmm_lbe_reg3[127:0]      <= {20'h0, tlp_lbe_reg2[3:0],104'hFFFFFFFFFFFFFFFFFFFFFFFFFF};
             5'h1C: avmm_lbe_reg3[127:0]      <= {16'h0, tlp_lbe_reg2[3:0],108'hFFFFFFFFFFFFFFFFFFFFFFFFFFF};
             5'h1D: avmm_lbe_reg3[127:0]      <= {12'h0, tlp_lbe_reg2[3:0],112'hFFFFFFFFFFFFFFFFFFFFFFFFFFFF};
             5'h1E: avmm_lbe_reg3[127:0]      <= { 8'h0, tlp_lbe_reg2[3:0],116'hFFFFFFFFFFFFFFFFFFFFFFFFFFFFF};
             5'h1F: avmm_lbe_reg3[127:0]      <= { 4'h0, tlp_lbe_reg2[3:0],120'hFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF};
             default:avmm_lbe_reg3[127:0]    <= {       tlp_lbe_reg2[3:0], 124'hFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF};
           endcase
          end else if(BAM_DATAWIDTH == 512) begin
           case(avmm_address_plus_dw_size_reg2[5:2])
             4'h1: avmm_lbe_reg3[63:0]      <= {60'h0, tlp_lbe_reg2[3:0]       };
             4'h2: avmm_lbe_reg3[63:0]      <= {56'h0, tlp_lbe_reg2[3:0], 4'hF };
             4'h3: avmm_lbe_reg3[63:0]      <= {52'h0, tlp_lbe_reg2[3:0], 8'hFF }; 
             4'h4: avmm_lbe_reg3[63:0]      <= {48'h0, tlp_lbe_reg2[3:0], 12'hFFF};
             4'h5: avmm_lbe_reg3[63:0]      <= {44'h0, tlp_lbe_reg2[3:0], 16'hFFFF};
             4'h6: avmm_lbe_reg3[63:0]      <= {40'h0, tlp_lbe_reg2[3:0], 20'hFFFFF};
             4'h7: avmm_lbe_reg3[63:0]      <= {36'h0, tlp_lbe_reg2[3:0], 24'hFFFFFF};
             4'h8: avmm_lbe_reg3[63:0]      <= {32'h0, tlp_lbe_reg2[3:0],  28'hFFFFFFF};
             4'h9: avmm_lbe_reg3[63:0]      <= {28'h0, tlp_lbe_reg2[3:0],  32'hFFFFFFFF};
             4'hA: avmm_lbe_reg3[63:0]      <= {24'h0, tlp_lbe_reg2[3:0],  36'hFFFFFFFFF};
             4'hB: avmm_lbe_reg3[63:0]      <= {20'h0, tlp_lbe_reg2[3:0],  40'hFFFFFFFFFF};
             4'hC: avmm_lbe_reg3[63:0]      <= {16'h0, tlp_lbe_reg2[3:0],  44'hFFFFFFFFFFF};
             4'hD: avmm_lbe_reg3[63:0]      <= {12'h0, tlp_lbe_reg2[3:0],  48'hFFFFFFFFFFFF};
             4'hE: avmm_lbe_reg3[63:0]      <= {8'h0, tlp_lbe_reg2[3:0],  52'hFFFFFFFFFFFFF};
             4'hF: avmm_lbe_reg3[63:0]      <= {4'h0, tlp_lbe_reg2[3:0],  56'hFFFFFFFFFFFFFF};
             default:avmm_lbe_reg3[63:0]    <= {       tlp_lbe_reg2[3:0],  60'hFFFFFFFFFFFFFFF};
           endcase
          end else if(BAM_DATAWIDTH == 256) begin
           case(avmm_address_plus_dw_size_reg2[4:2])
             4'h1: avmm_lbe_reg3[31:0]        <= {28'h0,   tlp_lbe_reg2[3:0]       };
             4'h2: avmm_lbe_reg3[31:0]        <= {24'h0,   tlp_lbe_reg2[3:0], 4'hF };
             4'h3: avmm_lbe_reg3[31:0]        <= {20'h0,   tlp_lbe_reg2[3:0], 8'hFF };
             4'h4: avmm_lbe_reg3[31:0]        <= {16'h0,   tlp_lbe_reg2[3:0], 12'hFFF};
             4'h5: avmm_lbe_reg3[31:0]        <= {12'h0,   tlp_lbe_reg2[3:0], 16'hFFFF};
             4'h6: avmm_lbe_reg3[31:0]        <= {8'h0,    tlp_lbe_reg2[3:0], 20'hFFFFF};
             4'h7: avmm_lbe_reg3[31:0]        <= {4'h0,    tlp_lbe_reg2[3:0], 24'hFFFFFF};
             default:avmm_lbe_reg3[31:0]      <= {           tlp_lbe_reg2[3:0], 28'hFFFFFFF};
           endcase
          end
       end         
    
  always_ff @(posedge clk) 
    begin
      if(BAM_DATAWIDTH == 1024) begin
        avmm_lbe_reg4[127:0] <= avmm_lbe_reg3[127:0]; 
        avmm_lbe_reg5[127:0] <= avmm_lbe_reg4[127:0];
        avmm_lbe_reg6[127:0] <= avmm_lbe_reg5[127:0];
        avmm_lbe_reg7[127:0] <= avmm_lbe_reg6[127:0];
      end else if(BAM_DATAWIDTH == 512) begin
        avmm_lbe_reg4[63:0] <= avmm_lbe_reg3[63:0];
        avmm_lbe_reg5[63:0] <= avmm_lbe_reg4[63:0];
        avmm_lbe_reg6[63:0] <= avmm_lbe_reg5[63:0];
        avmm_lbe_reg7[63:0] <= avmm_lbe_reg6[63:0];
      end else if(BAM_DATAWIDTH == 256) begin
        avmm_lbe_reg4[31:0] <= avmm_lbe_reg3[31:0];
        avmm_lbe_reg5[31:0] <= avmm_lbe_reg4[31:0];
        avmm_lbe_reg6[31:0] <= avmm_lbe_reg5[31:0];
        avmm_lbe_reg7[31:0] <= avmm_lbe_reg6[31:0];
      end
    end
    
 /// Write Flag
   always_ff @(posedge clk) 
     begin
       tlp_is_wr_reg2 <=   tlp_is_wr_reg1;
       tlp_is_wr_reg3 <=   tlp_is_wr_reg2;
       tlp_is_wr_reg4 <=   tlp_is_wr_reg3;
       tlp_is_wr_reg5 <=   tlp_is_wr_reg4;
       tlp_is_wr_reg6 <=   tlp_is_wr_reg5;
       tlp_is_wr_reg7 <=   tlp_is_wr_reg6;
     end
 
 /// Read Flag
     always_ff @(posedge clk) 
     begin
       tlp_is_rd_reg2 <=   tlp_is_rd_reg1;
       tlp_is_rd_reg3 <=   tlp_is_rd_reg2;
       tlp_is_rd_reg4 <=   tlp_is_rd_reg3;
       tlp_is_rd_reg5 <=   tlp_is_rd_reg4;
       tlp_is_rd_reg6 <=   tlp_is_rd_reg5;
       tlp_is_rd_reg7 <=   tlp_is_rd_reg6;
     end       

 /// Bar Hit
   always_ff @(posedge clk) 
     begin
       tlp_bar_reg2  <=   tlp_bar_reg1;
       tlp_bar_reg3  <=   tlp_bar_reg2;
       tlp_bar_reg4  <=   tlp_bar_reg3;
       tlp_bar_reg5  <=   tlp_bar_reg4;
       tlp_bar_reg6  <=   tlp_bar_reg5;
       tlp_bar_reg7  <=   tlp_bar_reg6;
     end
    
/// Virtual Channel

 always_ff @(posedge clk) 
     begin
       tlp_vfactive_reg2  <=   tlp_vfactive_reg1;
       tlp_vfactive_reg3  <=   tlp_vfactive_reg2;
       tlp_vfactive_reg4  <=   tlp_vfactive_reg3;
       tlp_vfactive_reg5  <=   tlp_vfactive_reg4;
       tlp_vfactive_reg6  <=   tlp_vfactive_reg5;
       tlp_vfactive_reg7  <=   tlp_vfactive_reg6;
       
       tlp_pfnum_reg2  <=   tlp_pfnum_reg1;
       tlp_pfnum_reg3  <=   tlp_pfnum_reg2;
       tlp_pfnum_reg4  <=   tlp_pfnum_reg3;
       tlp_pfnum_reg5  <=   tlp_pfnum_reg4;
       tlp_pfnum_reg6  <=   tlp_pfnum_reg5;
       tlp_pfnum_reg7  <=   tlp_pfnum_reg6;
       
       tlp_vfnum_reg2  <=   tlp_vfnum_reg1;
       tlp_vfnum_reg3  <=   tlp_vfnum_reg2;
       tlp_vfnum_reg4  <=   tlp_vfnum_reg3;
       tlp_vfnum_reg5  <=   tlp_vfnum_reg4;
       tlp_vfnum_reg6  <=   tlp_vfnum_reg5;
       tlp_vfnum_reg7  <=   tlp_vfnum_reg6;
       
     end




/// read tag
 always_ff @(posedge clk) 
     begin
       tlp_tag_reg2  <=   tlp_tag_reg1;
       tlp_tag_reg3  <=   tlp_tag_reg2;
       tlp_tag_reg4  <=   tlp_tag_reg3;    
       tlp_tag_reg5  <=   tlp_tag_reg4; 
       tlp_tag_reg6  <=   tlp_tag_reg5; 
       tlp_tag_reg7  <=   tlp_tag_reg6;
     end

/// Read Req ID
 always_ff @(posedge clk) 
     begin
       tlp_reqid_reg2  <=   tlp_reqid_reg1;
       tlp_reqid_reg3  <=   tlp_reqid_reg2;
       tlp_reqid_reg4  <=   tlp_reqid_reg3;
       tlp_reqid_reg5  <=   tlp_reqid_reg4;
       tlp_reqid_reg6  <=   tlp_reqid_reg5;
       tlp_reqid_reg7  <=   tlp_reqid_reg6;
     end

/// read lower address 

 always_ff @(posedge clk) 
     begin
       lower_addr_reg2[6:0]  <=    tlp_addr_reg1[6:0] ;
       lower_addr_reg3[6:0]  <=    lower_addr_reg2[6:0] ;
       lower_addr_reg4[6:0]  <=    lower_addr_reg3[6:0] ;
       lower_addr_reg5[6:0]  <=    lower_addr_reg4[6:0] ;
       lower_addr_reg6[6:0]  <=    lower_addr_reg5[6:0] ;
       lower_addr_reg7[6:0]  <=    lower_addr_reg6[6:0] ;
     end
    
 /// read length
 always_ff @(posedge clk) 
     begin
       tlp_len_reg2[9:0]  <=    tlp_len_reg1[9:0];
       tlp_len_reg3[9:0]  <=    tlp_len_reg2[9:0];
       tlp_len_reg4[9:0]  <=    tlp_len_reg3[9:0];
       tlp_len_reg5[9:0]  <=    tlp_len_reg4[9:0];
       tlp_len_reg6[9:0]  <=    tlp_len_reg5[9:0];
       tlp_len_reg7[9:0]  <=    tlp_len_reg6[9:0];
     end
 
/// Attribute/TC

always_ff @(posedge clk) 
     begin
       tlp_attr_reg2[2:0]  <=    tlp_attr_reg1[2:0];
       tlp_attr_reg3[2:0]  <=    tlp_attr_reg2[2:0];
       tlp_attr_reg4[2:0]  <=    tlp_attr_reg3[2:0];
       tlp_attr_reg5[2:0]  <=    tlp_attr_reg4[2:0];
       tlp_attr_reg6[2:0]  <=    tlp_attr_reg5[2:0];
       tlp_attr_reg7[2:0]  <=    tlp_attr_reg6[2:0];
       tlp_tc_reg2[2:0]    <=    tlp_tc_reg1[2:0];
       tlp_tc_reg3[2:0]    <=    tlp_tc_reg2[2:0];
       tlp_tc_reg4[2:0]    <=    tlp_tc_reg3[2:0];
       tlp_tc_reg5[2:0]    <=    tlp_tc_reg4[2:0];
       tlp_tc_reg6[2:0]    <=    tlp_tc_reg5[2:0];
       tlp_tc_reg7[2:0]    <=    tlp_tc_reg6[2:0];
     end

/// For read TLP partition:
// 1. Send AVMM read upto the MPS boundary (Type 1)
// 2. send AVMM read MPS size (0 or more reads as needed) Type 2
// 3. send AVMM read the remaining (Last Type 2)

/// Type 1 less than MPS (DW size upto MPS address boundary which is also multiple of RCB)

always_ff @(posedge clk) 
  begin
  	 addr_128_unaligned_reg2 <=  tlp_addr_reg1[6:2] != 5'h0;  
     dw_to_128_reg2[7:0]     <= {2'b00,(7'h20 - tlp_addr_reg1[6:2])};
  end


always_ff @(posedge clk) 
  begin
  	 addr_256_unaligned_reg2 <=  tlp_addr_reg1[7:2] != 6'h0;  
     dw_to_256_reg2[7:0]     <= {1'b0,(7'h40 - tlp_addr_reg1[7:2])};
  end

always_ff @(posedge clk) 
  begin
  	 addr_512_unaligned_reg2 <=  tlp_addr_reg1[8:2] != 7'h0;  
     dw_to_512_reg2[7:0]     <= (8'h80 - tlp_addr_reg1[8:2]);
  end

always_ff @(posedge clk) 
     case({mps_128_reg2, mps_256_reg2})
       2'b01:   addr_mps_unaligned_reg3 <= addr_256_unaligned_reg2;
       2'b10:   addr_mps_unaligned_reg3 <= addr_128_unaligned_reg2;
       default: addr_mps_unaligned_reg3 <= addr_512_unaligned_reg2;
     endcase
     
always_ff @(posedge clk) 
     case({mps_128_reg2, mps_256_reg2})
       2'b01:   dw_to_mps_reg3[7:0] <= dw_to_256_reg2[7:0];
       2'b10:   dw_to_mps_reg3[7:0] <= dw_to_128_reg2[7:0];
       default: dw_to_mps_reg3[7:0] <= dw_to_512_reg2[7:0];
     endcase

always_ff @(posedge clk) 
  begin
    addr_mps_unaligned_reg4 <= addr_mps_unaligned_reg3;
    dw_to_mps_reg4[7:0]     <= dw_to_mps_reg3[7:0];
  end


     
always_ff @(posedge clk) 
  begin
   len_lt_dw2_mps_reg4 <= tlp_len_reg3[9:0] <=  {2'b00,dw_to_mps_reg3[7:0]}; 
   type_1_exist_reg5     <=  (addr_mps_unaligned_reg4 | ~addr_mps_unaligned_reg4 & len_lt_dw2_mps_reg4);
   type_1_exist_reg6     <=  type_1_exist_reg5;
   type_1_exist_reg7     <=  type_1_exist_reg6;
  end   
  
  
  
 // Type 1 size
  always_ff @(posedge clk) 
    begin
      type_1_size_reg5[7:0] <=  len_lt_dw2_mps_reg4? tlp_len_reg4[7:0] : dw_to_mps_reg4[7:0];   
      type_1_size_reg6[7:0] <=  type_1_size_reg5;     
      type_1_size_reg7[7:0] <=  type_1_size_reg6;  
    end    
    
 
 /// Type 2 Conpletion of upto MPS 
  always_ff @(posedge clk)
   begin
     type_2_exist_reg4 <= tlp_len_reg3[9:0] > {2'b00,dw_to_mps_reg3[7:0]};  ///?????? should it be >= or >
     type_2_exist_reg5 <= type_2_exist_reg4; 
     type_2_exist_reg6 <= type_2_exist_reg5;
     type_2_exist_reg7 <= type_2_exist_reg6;
   end
    
   
  /// Number of type 2 Completions
 always_ff @(posedge clk) // set to 0 when aligned tp MPS  
     dw_to_mps_zero_reg4[7:0] <= ~addr_mps_unaligned_reg3? 8'h0: dw_to_mps_reg3;
       
  always_ff @(posedge clk) 
      dw_size_less_mps_reg5[9:0] <= tlp_len_reg4[9:0] - dw_to_mps_zero_reg4[7:0];  /// evaluate zero at boundary
  
  assign num_type_2_comb6 = type_2_exist_reg6? (num_aligned_type_2_reg6[4:0] + type_2_remainder_reg6) : (~type_1_exist_reg6 & ~type_2_exist_reg6)? 5'h1 : 5'h0;
  always_ff @(posedge clk)
  begin
     num_aligned_type_2_reg6[4:0]  <= mps_128_reg5? dw_size_less_mps_reg5[9:5] : mps_256_reg5? {1'b0,dw_size_less_mps_reg5[9:6]} : {2'b00,dw_size_less_mps_reg5[9:7]}; 
     type_2_remainder_reg6         <= mps_128_reg5? |dw_size_less_mps_reg5[4:0] : mps_256_reg5? |dw_size_less_mps_reg5[5:0] : |dw_size_less_mps_reg5[6:0]; 
     num_type_2_reg7[4:0]          <= num_type_2_comb6;
  end
  
  
 /// Last Type 2 size
always_ff @(posedge clk)
   begin
     last_type_2_dwsize_reg6[6:0] <=  mps_128_reg5? {2'b00,dw_size_less_mps_reg5[4:0]} : mps_256_reg5? {1'b0,dw_size_less_mps_reg5[5:0]} : dw_size_less_mps_reg5[6:0]; 
     last_type_2_dwsize_reg7[6:0] <=  last_type_2_dwsize_reg6[6:0];
   end    
  
 
 
 //// preproc command FIFO

assign preproc_cmd_fifo_wrreq = hdr_valid_reg7 & (tlp_is_rd_reg7 | tlp_is_wr_reg7) ;

// Added in for the support of credit interface
assign for_rxcrdt_tlp_len_o = tlp_len_reg7;
assign for_rxcrdt_hdr_valid_o = hdr_valid_reg7;
assign for_rxcrdt_hdr_is_rd_o = tlp_is_rd_reg7;
assign for_rxcrdt_hdr_is_wr_o = tlp_is_wr_reg7;

generate

if(BAM_DATAWIDTH == 1024) begin
  assign preproc_cmd_fifo_data[430:0] = {   
                                  tlp_is_rd_reg7,   // 1  
                                  flush_be_reg7,   // 1
                                  tlp_lbe_reg7,    // 4
                                  tlp_fbe_reg7,                 //4
                                  last_type_2_dwsize_reg7, // 7
                                  num_type_2_reg7,   // 5
                                  type_2_exist_reg7,  // 1
                                  type_1_size_reg7,  //8
                                  type_1_exist_reg7, // 1
                                  tlp_tc_reg7,       // 3
                                  tlp_attr_reg7,     // 3
                                  tlp_len_reg7,      // 10
                                  lower_addr_reg7,   // 7
                                  tlp_reqid_reg7,    // 16
                                  tlp_tag_reg7,      //10
                                  pcie_lines_reg7,   // 4
                                  tlp_vfactive_reg7,   //1
                                  tlp_pfnum_reg7,      // 2
                                  tlp_vfnum_reg7,       // 12
                                  tlp_is_wr_reg7,      // 1
                                  tlp_bar_reg7,       // 3
                                  avmm_burstcnt_reg7, //7
                                  avmm_lbe_reg7[127:0],    //127
                                  avmm_fbe_reg7[127:0],   //127
                                  tlp_addr_reg7   // 64
                               };
scfifo  preproc_fifo (
      .clock                            (clk),
      .data                             (preproc_cmd_fifo_data[430:0]),
      .rdreq                            (preproc_cmd_fifo_read_i),
      .wrreq                            (preproc_cmd_fifo_wrreq),
      .almost_full                      (),
      .full                             (),
      .q                                (preproc_cmd_fifo_data_o[430:0]),
      .aclr                             (1'b0),
      .almost_empty                     (),
      .eccstatus                        (),
      .empty                            (preproc_cmd_fifo_empty_o),
      .sclr                             (srst_reg),
      .usedw                            (preproc_cmd_fifo_count_o));
  defparam
      preproc_fifo.add_ram_output_register  = "ON",
      preproc_fifo.almost_full_value  = 8,
      preproc_fifo.enable_ecc  = "FALSE",
      preproc_fifo.intended_device_family  = "Agilex 7",
      preproc_fifo.lpm_hint  = "AUTO",
      preproc_fifo.lpm_numwords  = 32,
      preproc_fifo.lpm_showahead  = "ON",
      preproc_fifo.lpm_type  = "scfifo",
      preproc_fifo.lpm_width  = (431),
      preproc_fifo.lpm_widthu  = 5,
      preproc_fifo.overflow_checking  = "OFF",
      preproc_fifo.underflow_checking  = "OFF",
      preproc_fifo.use_eab  = "ON";

end else if(BAM_DATAWIDTH == 512) begin                  
  assign preproc_cmd_fifo_data[430:0] = { 128'h0,
                                  tlp_is_rd_reg7,   // 1
                                  flush_be_reg7,   // 1
                                  tlp_lbe_reg7,    // 4
                                  tlp_fbe_reg7,                 //4
                                  last_type_2_dwsize_reg7, // 7
                                  num_type_2_reg7,   // 5
                                  type_2_exist_reg7,  // 1
                                  type_1_size_reg7,  //8
                                  type_1_exist_reg7, // 1
                                  tlp_tc_reg7,       // 3
                                  tlp_attr_reg7,     // 3
                                  tlp_len_reg7,      // 10
                                  lower_addr_reg7,   // 7
                                  tlp_reqid_reg7,    // 16
                                  tlp_tag_reg7,      //10
                                  pcie_lines_reg7,   // 4
                                  tlp_vfactive_reg7,   //1
                                  tlp_pfnum_reg7,      // 2
                                  tlp_vfnum_reg7,       // 12
                                  tlp_is_wr_reg7,      // 1
                                  tlp_bar_reg7,       // 3
                                  avmm_burstcnt_reg7, //7
                                  avmm_lbe_reg7[63:0],    //64
                                  avmm_fbe_reg7[63:0],   //64
                                  tlp_addr_reg7   // 64
				};
				

scfifo  preproc_fifo (
      .clock                            (clk),
      .data                             (preproc_cmd_fifo_data[302:0]),
      .rdreq                            (preproc_cmd_fifo_read_i),
      .wrreq                            (preproc_cmd_fifo_wrreq),
      .almost_full                      (),
      .full                             (),
      .q                                (preproc_cmd_fifo_data_o[302:0]),
      .aclr                             (1'b0),
      .almost_empty                     (),
      .eccstatus                        (),
      .empty                            (preproc_cmd_fifo_empty_o),
      .sclr                             (srst_reg),
      .usedw                            (preproc_cmd_fifo_count_o));
  defparam
      preproc_fifo.add_ram_output_register  = "ON",
      preproc_fifo.almost_full_value  = 8,
      preproc_fifo.enable_ecc  = "FALSE",
      preproc_fifo.intended_device_family  = "Agilex 7",
      preproc_fifo.lpm_hint  = "AUTO",
      preproc_fifo.lpm_numwords  = 32,
      preproc_fifo.lpm_showahead  = "ON",
      preproc_fifo.lpm_type  = "scfifo",
      preproc_fifo.lpm_width  = (303),
      preproc_fifo.lpm_widthu  = 5,
      preproc_fifo.overflow_checking  = "OFF",
      preproc_fifo.underflow_checking  = "OFF",
      preproc_fifo.use_eab  = "ON";

assign preproc_cmd_fifo_data_o[430:303] = 128'h0; 

end else if(BAM_DATAWIDTH == 256) begin
  assign preproc_cmd_fifo_data[430:0] = { 192'h0,
                                  tlp_is_rd_reg7,   // 1
                                  flush_be_reg7,   // 1
                                  tlp_lbe_reg7,    // 4
                                  tlp_fbe_reg7,                 //4
                                  last_type_2_dwsize_reg7, // 7
                                  num_type_2_reg7,   // 5
                                  type_2_exist_reg7,  // 1
                                  type_1_size_reg7,  //8
                                  type_1_exist_reg7, // 1
                                  tlp_tc_reg7,       // 3
                                  tlp_attr_reg7,     // 3
                                  tlp_len_reg7,      // 10
                                  lower_addr_reg7,   // 7
                                  tlp_reqid_reg7,    // 16
                                  tlp_tag_reg7,      //10
                                  pcie_lines_reg7,   // 4
                                  tlp_vfactive_reg7,   //1
                                  tlp_pfnum_reg7,      // 2
                                  tlp_vfnum_reg7,       // 12
                                  tlp_is_wr_reg7,      // 1
                                  tlp_bar_reg7,       // 3
                                  avmm_burstcnt_reg7, //7
                                  avmm_lbe_reg7[31:0],    //32
                                  avmm_fbe_reg7[31:0],   //32
                                  tlp_addr_reg7   // 32
				};
				

scfifo  preproc_fifo (
      .clock                            (clk),
      .data                             (preproc_cmd_fifo_data[238:0]),
      .rdreq                            (preproc_cmd_fifo_read_i),
      .wrreq                            (preproc_cmd_fifo_wrreq),
      .almost_full                      (),
      .full                             (),
      .q                                (preproc_cmd_fifo_data_o[238:0]),
      .aclr                             (1'b0),
      .almost_empty                     (),
      .eccstatus                        (),
      .empty                            (preproc_cmd_fifo_empty_o),
      .sclr                             (srst_reg),
      .usedw                            (preproc_cmd_fifo_count_o));
  defparam
      preproc_fifo.add_ram_output_register  = "ON",
      preproc_fifo.almost_full_value  = 8,
      preproc_fifo.enable_ecc  = "FALSE",
      preproc_fifo.intended_device_family  = "Agilex 7",
      preproc_fifo.lpm_hint  = "AUTO",
      preproc_fifo.lpm_numwords  = 32,
      preproc_fifo.lpm_showahead  = "ON",
      preproc_fifo.lpm_type  = "scfifo",
      preproc_fifo.lpm_width  = (239),
      preproc_fifo.lpm_widthu  = 5,
      preproc_fifo.overflow_checking  = "OFF",
      preproc_fifo.underflow_checking  = "OFF",
      preproc_fifo.use_eab  = "ON";

assign preproc_cmd_fifo_data_o[430:239] = 192'h0;

end 

endgenerate


endmodule
