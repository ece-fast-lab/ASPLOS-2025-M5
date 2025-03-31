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
//  Module Name :  intel_pcie_bam_avst_intf.v
//  Description :  This module interfacing with RNR avst with WHR avst format
//                 
//-----------------------------------------------------------------------------


// synopsys translate_off
`timescale 1 ns / 1 ps
// synopsys translate_on

module intel_pcie_bam_v2_avst_intf
 # (
  parameter  BAM_DATAWIDTH = 1024
)
(
     input			     clk,
     input                           reset_n,
     input [2:0]                     pio_rx_st0_bar_i,      //
     input [2:0]                     pio_rx_st1_bar_i,      //
     input [2:0]                     pio_rx_st2_bar_i,      //
     input [2:0]                     pio_rx_st3_bar_i,      //
     input                           pio_rx_st0_eop_i,     //
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
     input                           pio_rx_st0_sop_i,      //
     input                           pio_rx_st1_sop_i,      //
     input                           pio_rx_st2_sop_i,      //
     input                           pio_rx_st3_sop_i,      //
     input                           pio_rx_st0_hvalid_i,    //
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
     input [2:0]                     pio_rx_st0_empty_i,    //
     input [2:0]                     pio_rx_st1_empty_i,    //
     input [2:0]                     pio_rx_st2_empty_i,    //
     input [2:0]                     pio_rx_st3_empty_i,    //

     output reg [2:0]                    pio_rx_bar,
     output reg                         pio_rx_sop,
     output reg                         pio_rx_eop,
     output reg [127:0]                  pio_rx_header,
     output reg [BAM_DATAWIDTH-1:0]                 pio_rx_payload,
     output reg                         pio_rx_valid,
     
//     input [(DATA_WIDTH==512)?1:0:0] pio_rx_tlp_abort_i,//
     input [31:0]                    pio_rx_st0_tlp_prfx_i, //
     input [31:0]                    pio_rx_st1_tlp_prfx_i, //
     input [31:0]                    pio_rx_st2_tlp_prfx_i, //
     input [31:0]                    pio_rx_st3_tlp_prfx_i, //
     output reg                   pio_tx_st0_eop_o,  //
     output reg                    pio_tx_st1_eop_o,  //
     output reg                   pio_tx_st2_eop_o,  //
     output reg                   pio_tx_st3_eop_o,  //
     output reg [127:0]            pio_tx_st0_header_o,      //
     output reg [127:0]            pio_tx_st1_header_o,      //
     output reg [127:0]            pio_tx_st2_header_o,      //
     output reg [127:0]            pio_tx_st3_header_o,      //

     output [31:0]             pio_tx_st0_prefix_o,      //
     output [31:0]             pio_tx_st1_prefix_o,      //
     output [31:0]             pio_tx_st2_prefix_o,      //
     output [31:0]             pio_tx_st3_prefix_o,      //

     output reg [255:0]   pio_tx_st0_payload_o,     //
     output reg [255:0]   pio_tx_st1_payload_o,     //
     output reg [255:0]   pio_tx_st2_payload_o,     //
     output reg [255:0]   pio_tx_st3_payload_o,     //

     //output [PFNUM_WIDTH-1:0]  pio_txc_pfnum_o,       //
     output reg                pio_tx_st0_sop_o,  //
     output reg                pio_tx_st1_sop_o,  //
     output reg                pio_tx_st2_sop_o,  //
     output reg                pio_tx_st3_sop_o,  //


     output reg                pio_tx_st0_dvalid_o,//
     output reg                pio_tx_st1_dvalid_o,//
     output reg                pio_tx_st2_dvalid_o,//
     output reg                pio_tx_st3_dvalid_o,//
     output reg                pio_tx_st0_hvalid_o,//
     output reg                pio_tx_st1_hvalid_o,//
     output reg                pio_tx_st2_hvalid_o,//
     output reg                pio_tx_st3_hvalid_o,//
     output reg                pio_tx_st0_pvalid_o,//
     output reg                pio_tx_st1_pvalid_o,//
     output reg                pio_tx_st2_pvalid_o,//
     output reg                pio_tx_st3_pvalid_o,//
     input                     pio_txc_eop,
     input [127:0]             pio_txc_header,
     input [BAM_DATAWIDTH-1:0]            pio_txc_payload,
     input                     pio_txc_sop,
     input                     pio_txc_valid
     
);


logic        srst_reg;
logic        srst_reg2;


logic        hold_sop_reg;
logic        hold_eop_reg;
logic        hold_eop_reg_set_nxt_cyc; 
logic [127:0] hold_header_reg;
logic [2:0]  hold_bar_reg;
logic [255:0] hold_payload_slot0_0;
logic [255:0] hold_payload_slot0_1;
logic [255:0] hold_payload_slot0_2;
logic [255:0] hold_payload_slot0_3;
logic [255:0] hold_payload_slot1_0;
logic [255:0] hold_payload_slot1_1;
logic [255:0] hold_payload_slot1_2;
logic [255:0] hold_payload_slot1_3;
logic [255:0] intermediate_payload_slot0_0;
logic [255:0] intermediate_payload_slot0_1;
logic [255:0] intermediate_payload_slot0_2;
logic [255:0] intermediate_payload_slot0_3;
logic [255:0] intermediate_payload_slot1_0;
logic [255:0] intermediate_payload_slot1_1;
logic [255:0] intermediate_payload_slot1_2;
logic [255:0] intermediate_payload_slot1_3;
logic [255:0] reserved_payload_slot0_0;
logic [255:0] reserved_payload_slot0_1;
logic [255:0] reserved_payload_slot0_2;
logic [255:0] reserved_payload_slot0_3;
logic [255:0] to_reserved_payload_slot0_0;
logic [255:0] to_reserved_payload_slot0_1;
logic [255:0] to_reserved_payload_slot0_2;
logic [255:0] to_reserved_payload_slot0_3;
logic [2:0]  intermediate_payload_slotcount;
logic [1:0]  last_data_packet_received;
logic        eop_slot0;
logic        eop_slot1;
logic        sent_slot0;
logic        sent_slot1;
logic        carry_slot0_to_slot1;
logic [3:0]  combine_dvalid;
logic [4:0]  combine_sumdvalid_reservedsta;
logic [2:0]  sum_dvalid;
logic [2:0]  sum_dvalid_rec;

logic [1:0]  reserved_status_slot;
logic [1:0]  reserved_status_slot_reg;
logic        buffer_full_slot;
logic        buffer_full_slot_reg;
     logic [2:0]                     pio_rx_st0_bar_reg;      //
     logic [2:0]                     pio_rx_st1_bar_reg;      //
     logic [2:0]                     pio_rx_st2_bar_reg;      //
     logic [2:0]                     pio_rx_st3_bar_reg;      //
     logic                           pio_rx_st0_eop_reg;      //
     logic                           pio_rx_st1_eop_reg;      //
     logic                           pio_rx_st2_eop_reg;      //
     logic                           pio_rx_st3_eop_reg;      //
     logic                           pio_rx_st0_sop_reg;      //
     logic                           pio_rx_st1_sop_reg;      //
     logic                           pio_rx_st2_sop_reg;      //
     logic                           pio_rx_st3_sop_reg;      //
     logic [1:0]                     pio_rx_sop_location;     //
     logic [1:0]                     pio_rx_eop_location;     //
     logic [127:0]                   pio_rx_st0_header_reg;   //
     logic [127:0]                   pio_rx_st1_header_reg;   //
     logic [127:0]                   pio_rx_st2_header_reg;   //
     logic [127:0]                   pio_rx_st3_header_reg;   //
     logic [255:0]          pio_rx_st0_payload_reg;  //
     logic [255:0]          pio_rx_st1_payload_reg;  //
     logic [255:0]          pio_rx_st2_payload_reg;  //
     logic [255:0]          pio_rx_st3_payload_reg;  //
     logic [255:0]          pio_rx_st0_payload_reg2;  //
     logic [255:0]          pio_rx_st1_payload_reg2;  //
     logic [255:0]          pio_rx_st2_payload_reg2;  //
     logic [255:0]          pio_rx_st3_payload_reg2;  //


     //logic [PFNUM_WIDTH-1:0]         pio_rx_pfnum_reg;    //
     logic 			     headeronly;
     logic			     headeronly_reg;
     logic                           pio_rx_st0_hvalid_reg;    //
     logic                           pio_rx_st1_hvalid_reg;    //
     logic                           pio_rx_st2_hvalid_reg;    //
     logic                           pio_rx_st3_hvalid_reg;    //
     logic                           pio_rx_st0_dvalid_reg;    //
     logic                           pio_rx_st1_dvalid_reg;    //
     logic                           pio_rx_st2_dvalid_reg;    //
     logic                           pio_rx_st3_dvalid_reg;    //
     logic                           pio_rx_st0_pvalid_reg;    //
     logic                           pio_rx_st1_pvalid_reg;    //
     logic                           pio_rx_st2_pvalid_reg;    //
     logic                           pio_rx_st3_pvalid_reg;    //
     logic                           pio_txc_eop_reg;
     logic                           pio_txc_eop_reg2;
     logic [127:0]                   pio_txc_header_reg;
     logic [127:0]                   pio_txc_header_reg2;
     logic [127:0]                   pio_txc_header_reg3;
     logic [255:0]                   pio_txc_st0_payload_reg;
     logic [255:0]                   pio_txc_st1_payload_reg;
     logic [255:0]                   pio_txc_st2_payload_reg;
     logic [255:0]                   pio_txc_st3_payload_reg;
     logic [255:0]                   pio_txc_st0_payload_reg2;
     logic [255:0]                   pio_txc_st1_payload_reg2;
     logic [255:0]                   pio_txc_st2_payload_reg2;
     logic [255:0]                   pio_txc_st3_payload_reg2;
     logic [255:0]                   pio_txc_st0_payload_reg3;
     logic [255:0]                   pio_txc_st1_payload_reg3;
     logic [255:0]                   pio_txc_st2_payload_reg3;
     logic [255:0]                   pio_txc_st3_payload_reg3;
     logic                           pio_txc_sop_reg;
     logic 		             pio_txc_sop_reg2;
     logic                           pio_txc_sop_reg3;
     logic                           pio_txc_valid_reg;
     logic                           pio_txc_valid_reg2;
     logic                           pio_txc_valid_reg3;
     logic [1:0]                     comb_tx_sop_eop;
     logic                          pio_tx_st0_dvalid_reg;//
     logic                          pio_tx_st1_dvalid_reg;//
     logic                          pio_tx_st2_dvalid_reg;//
     logic                          pio_tx_st3_dvalid_reg;//
     logic                          pio_tx_st0_hvalid_reg;//
     logic                          pio_tx_st1_hvalid_reg;//
     logic                          pio_tx_st2_hvalid_reg;//
     logic                          pio_tx_st3_hvalid_reg;//
     logic 		            pio_tx_st0_eop_reg;  //
     logic                          pio_tx_st1_eop_reg;  //
     logic                          pio_tx_st2_eop_reg;  //
     logic                          pio_tx_st3_eop_reg;  //
     logic [1:0]		    calculate_bytecount;

     logic  [255:0]                   to_pio_txc_st0_payload_reg;
     logic  [255:0]                   to_pio_txc_st1_payload_reg;
     logic  [255:0]                   to_pio_txc_st2_payload_reg;
     logic  [255:0]                   to_pio_txc_st3_payload_reg;
     logic                          to_pio_tx_st0_dvalid_reg;//
     logic                          to_pio_tx_st1_dvalid_reg;//
     logic                          to_pio_tx_st2_dvalid_reg;//
     logic                          to_pio_tx_st3_dvalid_reg;//
     logic                          to_pio_tx_st0_hvalid_reg;//
     logic                          to_pio_tx_st1_hvalid_reg;//
     logic                          to_pio_tx_st2_hvalid_reg;//
     logic                          to_pio_tx_st3_hvalid_reg;//
     logic                          to_pio_tx_st0_eop_reg;
     logic                          to_pio_tx_st1_eop_reg;
     logic                          to_pio_tx_st2_eop_reg;
     logic                          to_pio_tx_st3_eop_reg;
     logic  [11:0]                   to_calculate_bytecount;
     logic  [11:0]                   to_calculate_bytecount_minus1;
     
     logic                          tx_sent;
     logic  [1:0]                   sum_of_eop_o;
     

    assign combine_dvalid                    = {pio_rx_st3_dvalid_i,pio_rx_st2_dvalid_i,pio_rx_st1_dvalid_i,pio_rx_st0_dvalid_i};
    assign sum_dvalid                       = pio_rx_st3_dvalid_reg + pio_rx_st2_dvalid_reg + pio_rx_st1_dvalid_reg + pio_rx_st0_dvalid_reg ;
    assign sum_dvalid_rec                       = pio_rx_st3_dvalid_i + pio_rx_st2_dvalid_i + pio_rx_st1_dvalid_i + pio_rx_st0_dvalid_i ;
    assign combine_sumdvalid_reservedsta = {sum_dvalid[2:0],reserved_status_slot_reg};
   
always_comb begin
  case(combine_dvalid[3:0])
       4'b0000:
         begin
           intermediate_payload_slot0_0 = 'h0;
           intermediate_payload_slot0_1 = 'h0;
           intermediate_payload_slot0_2 = 'h0;
           intermediate_payload_slot0_3 = 'h0;
         end
       4'b0001:
         begin
           intermediate_payload_slot0_0 = pio_rx_st0_payload_i;
           intermediate_payload_slot0_1 = 'h0;
           intermediate_payload_slot0_2 = 'h0;
           intermediate_payload_slot0_3 = 'h0;
         end
       4'b0010:
         begin
           intermediate_payload_slot0_0 = pio_rx_st1_payload_i;
           intermediate_payload_slot0_1 = 'h0;
           intermediate_payload_slot0_2 = 'h0;
           intermediate_payload_slot0_3 = 'h0;
         end
       4'b0011:
         begin
           intermediate_payload_slot0_0 = pio_rx_st0_payload_i;
           intermediate_payload_slot0_1 = pio_rx_st1_payload_i;
           intermediate_payload_slot0_2 = 'h0;
           intermediate_payload_slot0_3 = 'h0;
         end
       4'b0100:
         begin
           intermediate_payload_slot0_0 = pio_rx_st2_payload_i;
           intermediate_payload_slot0_1 = 'h0;
           intermediate_payload_slot0_2 = 'h0;
           intermediate_payload_slot0_3 = 'h0;
         end
       4'b0101:
         begin
           intermediate_payload_slot0_0 = pio_rx_st0_payload_i;
           intermediate_payload_slot0_1 = pio_rx_st2_payload_i;
           intermediate_payload_slot0_2 = 'h0;
           intermediate_payload_slot0_3 = 'h0;
         end
       4'b0110:
         begin
           intermediate_payload_slot0_0 = pio_rx_st1_payload_i;
           intermediate_payload_slot0_1 = pio_rx_st2_payload_i;
           intermediate_payload_slot0_2 = 'h0;
           intermediate_payload_slot0_3 = 'h0;
         end
       4'b0111:
         begin
           intermediate_payload_slot0_0 = pio_rx_st0_payload_i;
           intermediate_payload_slot0_1 = pio_rx_st1_payload_i;
           intermediate_payload_slot0_2 = pio_rx_st2_payload_i;
           intermediate_payload_slot0_3 = 'h0;
         end
       4'b1000:
         begin
           intermediate_payload_slot0_0 = pio_rx_st3_payload_i;
           intermediate_payload_slot0_1 = 'h0;
           intermediate_payload_slot0_2 = 'h0;
           intermediate_payload_slot0_3 = 'h0;
         end
       4'b1001:
         begin
           intermediate_payload_slot0_0 = pio_rx_st0_payload_i;
           intermediate_payload_slot0_1 = pio_rx_st3_payload_i;
           intermediate_payload_slot0_2 = 'h0;
           intermediate_payload_slot0_3 = 'h0;
         end
       4'b1010:
         begin
           intermediate_payload_slot0_0 = pio_rx_st1_payload_i;
           intermediate_payload_slot0_1 = pio_rx_st3_payload_i;
           intermediate_payload_slot0_2 = 'h0;
           intermediate_payload_slot0_3 = 'h0;
         end
       4'b1011:
         begin
           intermediate_payload_slot0_0 = pio_rx_st0_payload_i;
           intermediate_payload_slot0_1 = pio_rx_st1_payload_i;
           intermediate_payload_slot0_2 = pio_rx_st3_payload_i;
           intermediate_payload_slot0_3 = 'h0;
         end
       4'b1100:
         begin
           intermediate_payload_slot0_0 = pio_rx_st2_payload_i;
           intermediate_payload_slot0_1 = pio_rx_st3_payload_i;
           intermediate_payload_slot0_2 = 'h0;
           intermediate_payload_slot0_3 = 'h0;
         end
       4'b1101:
         begin
           intermediate_payload_slot0_0 = pio_rx_st0_payload_i;
           intermediate_payload_slot0_1 = pio_rx_st2_payload_i;
           intermediate_payload_slot0_2 = pio_rx_st3_payload_i;
           intermediate_payload_slot0_3 = 'h0;
         end
       4'b1110:
         begin
           intermediate_payload_slot0_0 = pio_rx_st1_payload_i;
           intermediate_payload_slot0_1 = pio_rx_st2_payload_i;
           intermediate_payload_slot0_2 = pio_rx_st3_payload_i;
           intermediate_payload_slot0_3 = 'h0;
         end
       4'b1111:
         begin
           intermediate_payload_slot0_0 = pio_rx_st0_payload_i;
           intermediate_payload_slot0_1 = pio_rx_st1_payload_i;
           intermediate_payload_slot0_2 = pio_rx_st2_payload_i;
           intermediate_payload_slot0_3 = pio_rx_st3_payload_i;
         end


       default:
         begin
           intermediate_payload_slot0_0 = 'h0;
           intermediate_payload_slot0_1 = 'h0;
           intermediate_payload_slot0_2 = 'h0;
           intermediate_payload_slot0_3 = 'h0;

         end
  endcase
end

generate
if(BAM_DATAWIDTH == 1024) begin
  always_comb begin
    case(combine_sumdvalid_reservedsta[4:0])
         5'b00000:
           begin
             intermediate_payload_slot1_0 = 'h0;
             intermediate_payload_slot1_1 = 'h0;
             intermediate_payload_slot1_2 = 'h0;
             intermediate_payload_slot1_3 = 'h0;
             to_reserved_payload_slot0_0 =  'h0;
             to_reserved_payload_slot0_1 = 'h0;
             to_reserved_payload_slot0_2 = 'h0;
             reserved_status_slot = 0;
             buffer_full_slot = 0;
           end
         5'b00001:
           begin
             intermediate_payload_slot1_0 = 'h0;
             intermediate_payload_slot1_1 = 'h0;
             intermediate_payload_slot1_2 = 'h0;
             intermediate_payload_slot1_3 = 'h0;
             to_reserved_payload_slot0_0 =  reserved_payload_slot0_0;
             to_reserved_payload_slot0_1 = 'h0;
             to_reserved_payload_slot0_2 = 'h0;
             reserved_status_slot = 1;
             buffer_full_slot = 0;
           end
         5'b00010:
           begin
             intermediate_payload_slot1_0 = 'h0;
             intermediate_payload_slot1_1 = 'h0;
             intermediate_payload_slot1_2 = 'h0;
             intermediate_payload_slot1_3 = 'h0;
             to_reserved_payload_slot0_0 =  reserved_payload_slot0_0;
             to_reserved_payload_slot0_1 = reserved_payload_slot0_1;
             to_reserved_payload_slot0_2 = 'h0;
             reserved_status_slot = 2;
             buffer_full_slot = 0;
           end
         5'b00011:
           begin
             intermediate_payload_slot1_0 = 'h0;
             intermediate_payload_slot1_1 = 'h0;
             intermediate_payload_slot1_2 = 'h0;
             intermediate_payload_slot1_3 = 'h0;
             to_reserved_payload_slot0_0 =  reserved_payload_slot0_0;
             to_reserved_payload_slot0_1 = reserved_payload_slot0_1;
             to_reserved_payload_slot0_2 = reserved_payload_slot0_2;
             reserved_status_slot = 3;
             buffer_full_slot = 0;
           end
         5'b00100:
           begin
             intermediate_payload_slot1_0 = 'h0;
             intermediate_payload_slot1_1 = 'h0;
             intermediate_payload_slot1_2 = 'h0;
             intermediate_payload_slot1_3 = 'h0;
             to_reserved_payload_slot0_0 =  pio_rx_st0_payload_reg;
             to_reserved_payload_slot0_1 = 'h0;
             to_reserved_payload_slot0_2 = 'h0;
             reserved_status_slot = 1;
             buffer_full_slot = 0;
           end
         5'b00101:
           begin
             intermediate_payload_slot1_0 = 'h0;
             intermediate_payload_slot1_1 = 'h0;
             intermediate_payload_slot1_2 = 'h0;
             intermediate_payload_slot1_3 = 'h0;
             to_reserved_payload_slot0_0 =  reserved_payload_slot0_0;
             to_reserved_payload_slot0_1 = pio_rx_st0_payload_reg;
             to_reserved_payload_slot0_2 = 'h0;
             reserved_status_slot = 2;
             buffer_full_slot = 0;
           end
         5'b00110:
           begin
             intermediate_payload_slot1_0 = 'h0;
             intermediate_payload_slot1_1 = 'h0;
             intermediate_payload_slot1_2 = 'h0;
             intermediate_payload_slot1_3 = 'h0;
             to_reserved_payload_slot0_0 =  reserved_payload_slot0_0;
             to_reserved_payload_slot0_1 = reserved_payload_slot0_1;
             to_reserved_payload_slot0_2 = pio_rx_st0_payload_reg;
             reserved_status_slot = 3;
             buffer_full_slot = 0;
           end
         5'b00111:
           begin
             intermediate_payload_slot1_0 = reserved_payload_slot0_0;
             intermediate_payload_slot1_1 = reserved_payload_slot0_1;
             intermediate_payload_slot1_2 = reserved_payload_slot0_2;
             intermediate_payload_slot1_3 = pio_rx_st0_payload_reg;
             to_reserved_payload_slot0_0 =  'h0;
             to_reserved_payload_slot0_1 = 'h0;
             to_reserved_payload_slot0_2 = 'h0;
             reserved_status_slot = 0;
             buffer_full_slot = 1;
           end
         5'b01000:
           begin
             intermediate_payload_slot1_0 = 'h0;
             intermediate_payload_slot1_1 = 'h0;
             intermediate_payload_slot1_2 = 'h0;
             intermediate_payload_slot1_3 = 'h0;
             to_reserved_payload_slot0_0 =  pio_rx_st0_payload_reg;
             to_reserved_payload_slot0_1 = pio_rx_st1_payload_reg;
             to_reserved_payload_slot0_2 = 'h0;
             reserved_status_slot = 2;
             buffer_full_slot = 0;
           end
        5'b01001:
           begin
             intermediate_payload_slot1_0 = 'h0;
             intermediate_payload_slot1_1 = 'h0;
             intermediate_payload_slot1_2 = 'h0;
             intermediate_payload_slot1_3 = 'h0;
             to_reserved_payload_slot0_0 =  reserved_payload_slot0_0;
             to_reserved_payload_slot0_1 = pio_rx_st0_payload_reg;
             to_reserved_payload_slot0_2 = pio_rx_st1_payload_reg;
             reserved_status_slot = 3;
             buffer_full_slot = 0;
           end
         5'b01010:
           begin
             intermediate_payload_slot1_0 = reserved_payload_slot0_0;
             intermediate_payload_slot1_1 = reserved_payload_slot0_1;
             intermediate_payload_slot1_2 = pio_rx_st0_payload_reg;
             intermediate_payload_slot1_3 = pio_rx_st1_payload_reg;
             to_reserved_payload_slot0_0 =  'h0;
             to_reserved_payload_slot0_1 = 'h0;
             to_reserved_payload_slot0_2 = 'h0;
             reserved_status_slot = 0;
             buffer_full_slot = 1;
           end
         5'b01011:
           begin
             intermediate_payload_slot1_0 = reserved_payload_slot0_0;
             intermediate_payload_slot1_1 = reserved_payload_slot0_1;
             intermediate_payload_slot1_2 = reserved_payload_slot0_2;
             intermediate_payload_slot1_3 = pio_rx_st0_payload_reg;
             to_reserved_payload_slot0_0 =  pio_rx_st1_payload_reg;
             to_reserved_payload_slot0_1 = 'h0;
             to_reserved_payload_slot0_2 = 'h0;
             reserved_status_slot = 1;
             buffer_full_slot = 1;
           end
         5'b01100:
           begin
             intermediate_payload_slot1_0 = 'h0;
             intermediate_payload_slot1_1 = 'h0;
             intermediate_payload_slot1_2 = 'h0;
             intermediate_payload_slot1_3 = 'h0;
             to_reserved_payload_slot0_0 = pio_rx_st0_payload_reg ;
             to_reserved_payload_slot0_1 = pio_rx_st1_payload_reg;
             to_reserved_payload_slot0_2 = pio_rx_st2_payload_reg;
             reserved_status_slot = 3;
             buffer_full_slot = 0;
           end
         5'b01101:
           begin
             intermediate_payload_slot1_0 = reserved_payload_slot0_0;
             intermediate_payload_slot1_1 = pio_rx_st0_payload_reg;
             intermediate_payload_slot1_2 = pio_rx_st1_payload_reg;
             intermediate_payload_slot1_3 = pio_rx_st2_payload_reg;
             to_reserved_payload_slot0_0 =  'h0;
             to_reserved_payload_slot0_1 = 'h0;
             to_reserved_payload_slot0_2 = 'h0;
             reserved_status_slot = 0;
             buffer_full_slot = 1;
           end
         5'b01110:
           begin
             intermediate_payload_slot1_0 = reserved_payload_slot0_0;
             intermediate_payload_slot1_1 = reserved_payload_slot0_1;
             intermediate_payload_slot1_2 = pio_rx_st0_payload_reg;
             intermediate_payload_slot1_3 = pio_rx_st1_payload_reg;
             to_reserved_payload_slot0_0 =  pio_rx_st2_payload_reg;
             to_reserved_payload_slot0_1 = 'h0;
             to_reserved_payload_slot0_2 = 'h0;
             reserved_status_slot = 1;
             buffer_full_slot = 1;
           end
         5'b01111:
           begin
             intermediate_payload_slot1_0 = reserved_payload_slot0_0;
             intermediate_payload_slot1_1 = reserved_payload_slot0_1;
             intermediate_payload_slot1_2 = reserved_payload_slot0_2;
             intermediate_payload_slot1_3 = pio_rx_st0_payload_reg;
             to_reserved_payload_slot0_0 =  pio_rx_st1_payload_reg;
             to_reserved_payload_slot0_1 = pio_rx_st2_payload_reg;
             to_reserved_payload_slot0_2 = 'h0;
             reserved_status_slot = 2;
             buffer_full_slot = 1;
           end
         5'b10000:
           begin
             intermediate_payload_slot1_0 = pio_rx_st0_payload_reg;
             intermediate_payload_slot1_1 = pio_rx_st1_payload_reg;
             intermediate_payload_slot1_2 = pio_rx_st2_payload_reg;
             intermediate_payload_slot1_3 = pio_rx_st3_payload_reg;
             to_reserved_payload_slot0_0 =  'h0;
             to_reserved_payload_slot0_1 = 'h0;
             to_reserved_payload_slot0_2 = 'h0;
             reserved_status_slot = 0;
             buffer_full_slot = 1;
           end
         5'b10001:
           begin
             intermediate_payload_slot1_0 = reserved_payload_slot0_0;
             intermediate_payload_slot1_1 = pio_rx_st0_payload_reg;
             intermediate_payload_slot1_2 = pio_rx_st1_payload_reg;
             intermediate_payload_slot1_3 = pio_rx_st2_payload_reg;
             to_reserved_payload_slot0_0 =  pio_rx_st3_payload_reg;
             to_reserved_payload_slot0_1 = 'h0;
             to_reserved_payload_slot0_2 = 'h0;
             reserved_status_slot = 1;
             buffer_full_slot = 1;
           end
         5'b10010:
           begin
             intermediate_payload_slot1_0 = reserved_payload_slot0_0;
             intermediate_payload_slot1_1 = reserved_payload_slot0_1;
             intermediate_payload_slot1_2 = pio_rx_st0_payload_reg;
             intermediate_payload_slot1_3 = pio_rx_st1_payload_reg;
             to_reserved_payload_slot0_0 =  pio_rx_st2_payload_reg;
             to_reserved_payload_slot0_1 = pio_rx_st3_payload_reg;
             to_reserved_payload_slot0_2 = 'h0;
             reserved_status_slot = 2;
             buffer_full_slot = 1;
           end
         5'b10011:
           begin
             intermediate_payload_slot1_0 = reserved_payload_slot0_0;
             intermediate_payload_slot1_1 = reserved_payload_slot0_1;
             intermediate_payload_slot1_2 = reserved_payload_slot0_2;
             intermediate_payload_slot1_3 = pio_rx_st0_payload_reg;
             to_reserved_payload_slot0_0 =  pio_rx_st1_payload_reg;
             to_reserved_payload_slot0_1 = pio_rx_st2_payload_reg;
             to_reserved_payload_slot0_2 = pio_rx_st3_payload_reg;
             reserved_status_slot = 3;
             buffer_full_slot = 1;
           end
         default:
           begin
             intermediate_payload_slot1_0 = 'h0;
             intermediate_payload_slot1_1 = 'h0;
             intermediate_payload_slot1_2 = 'h0;
             intermediate_payload_slot1_3 = 'h0;
             to_reserved_payload_slot0_0 =  'h0;
             to_reserved_payload_slot0_1 = 'h0;
             to_reserved_payload_slot0_2 = 'h0;
             reserved_status_slot = 0;
             buffer_full_slot = 0;
           end
    endcase
    if(hold_eop_reg) begin
      reserved_status_slot = 0;
    end
  end
end
else if(BAM_DATAWIDTH == 512) begin
  always_comb begin
    case(combine_sumdvalid_reservedsta[4:0])
         5'b00000:
           begin
             intermediate_payload_slot1_0 = 'h0;
             intermediate_payload_slot1_1 = 'h0;
             intermediate_payload_slot1_2 = 'h0;
             intermediate_payload_slot1_3 = 'h0;
             to_reserved_payload_slot0_0 =  'h0;
             to_reserved_payload_slot0_1 = 'h0;
             to_reserved_payload_slot0_2 = 'h0;
             reserved_status_slot = 0;
             buffer_full_slot = 0;
           end
         5'b00001:
           begin
             intermediate_payload_slot1_0 = 'h0;
             intermediate_payload_slot1_1 = 'h0;
             intermediate_payload_slot1_2 = 'h0;
             intermediate_payload_slot1_3 = 'h0;
             to_reserved_payload_slot0_0 =  reserved_payload_slot0_0;
             to_reserved_payload_slot0_1 = 'h0;
             to_reserved_payload_slot0_2 = 'h0;
             reserved_status_slot = 1;
             buffer_full_slot = 0;
           end
         5'b00100:
           begin
             intermediate_payload_slot1_0 = 'h0;
             intermediate_payload_slot1_1 = 'h0;
             intermediate_payload_slot1_2 = 'h0;
             intermediate_payload_slot1_3 = 'h0;
             to_reserved_payload_slot0_0 =  pio_rx_st0_payload_reg;
             to_reserved_payload_slot0_1 =  'h0;
             to_reserved_payload_slot0_2 = 'h0;
             reserved_status_slot = 1;
             buffer_full_slot = 0;
           end
         5'b00101:
           begin
             intermediate_payload_slot1_0 = reserved_payload_slot0_0;
             intermediate_payload_slot1_1 = pio_rx_st0_payload_reg;
             intermediate_payload_slot1_2 = 'h0;
             intermediate_payload_slot1_3 = 'h0;
             to_reserved_payload_slot0_0 =  'h0;
             to_reserved_payload_slot0_1 =  'h0;
             to_reserved_payload_slot0_2 = 'h0;
             reserved_status_slot = 0;
             buffer_full_slot = 1;
           end
         5'b01000:
           begin
             intermediate_payload_slot1_0 = pio_rx_st0_payload_reg;
             intermediate_payload_slot1_1 = pio_rx_st1_payload_reg;
             intermediate_payload_slot1_2 = 'h0;
             intermediate_payload_slot1_3 = 'h0;
             to_reserved_payload_slot0_0 =  'h0;
             to_reserved_payload_slot0_1 =  'h0;
             to_reserved_payload_slot0_2 = 'h0;
             reserved_status_slot = 0;
             buffer_full_slot = 1;
           end
         5'b01001:
           begin
             intermediate_payload_slot1_0 = reserved_payload_slot0_0;
             intermediate_payload_slot1_1 = pio_rx_st0_payload_reg;
             intermediate_payload_slot1_2 = 'h0;
             intermediate_payload_slot1_3 = 'h0;
             to_reserved_payload_slot0_0 =  pio_rx_st1_payload_reg;
             to_reserved_payload_slot0_1 =  'h0;
             to_reserved_payload_slot0_2 = 'h0;
             reserved_status_slot = 1;
             buffer_full_slot = 1;
           end


         default:
           begin
             intermediate_payload_slot1_0 = 'h0;
             intermediate_payload_slot1_1 = 'h0;
             intermediate_payload_slot1_2 = 'h0;
             intermediate_payload_slot1_3 = 'h0;
             to_reserved_payload_slot0_0 =  'h0;
             to_reserved_payload_slot0_1 = 'h0;
             to_reserved_payload_slot0_2 = 'h0;
             reserved_status_slot = 0;
             buffer_full_slot = 0;
           end
    endcase
    if(hold_eop_reg) begin
      reserved_status_slot = 0;
    end
  end
end
endgenerate

always_ff @ (posedge clk or posedge srst_reg ) begin
  if (srst_reg) begin
  reserved_status_slot_reg <= 0;
  end
  else begin
  pio_rx_st0_payload_reg2 <= intermediate_payload_slot1_0;
  pio_rx_st1_payload_reg2 <= intermediate_payload_slot1_1;
  pio_rx_st2_payload_reg2 <= intermediate_payload_slot1_2;
  pio_rx_st3_payload_reg2 <= intermediate_payload_slot1_3;
  pio_rx_st0_payload_reg <= intermediate_payload_slot0_0;
  pio_rx_st1_payload_reg <= intermediate_payload_slot0_1;
  pio_rx_st2_payload_reg <= intermediate_payload_slot0_2;
  pio_rx_st3_payload_reg <= intermediate_payload_slot0_3;
  reserved_payload_slot0_0 <= to_reserved_payload_slot0_0;
  reserved_payload_slot0_1 <= to_reserved_payload_slot0_1;
  reserved_payload_slot0_2 <= to_reserved_payload_slot0_2;
  reserved_payload_slot0_3 <= to_reserved_payload_slot0_3;
  reserved_status_slot_reg <= reserved_status_slot;
  pio_rx_st0_dvalid_reg <= pio_rx_st0_dvalid_i;    //
  pio_rx_st1_dvalid_reg <= pio_rx_st1_dvalid_i;    //
  pio_rx_st2_dvalid_reg <= pio_rx_st2_dvalid_i;    //
  pio_rx_st3_dvalid_reg <= pio_rx_st3_dvalid_i;
  pio_rx_st0_eop_reg <= pio_rx_st0_eop_i;      //
  pio_rx_st1_eop_reg <= pio_rx_st1_eop_i;      //
  pio_rx_st2_eop_reg <= pio_rx_st2_eop_i;      //
  pio_rx_st3_eop_reg <= pio_rx_st3_eop_i;
  pio_rx_st0_sop_reg <= pio_rx_st0_sop_i;      //
  pio_rx_st1_sop_reg <= pio_rx_st1_sop_i;      //
  pio_rx_st2_sop_reg <= pio_rx_st2_sop_i;      //
  pio_rx_st3_sop_reg <= pio_rx_st3_sop_i;
   if(pio_rx_st0_sop_i) begin
     pio_rx_sop_location <= 0;
   end
   else if(pio_rx_st1_sop_i) begin
     pio_rx_sop_location <= 1;
   end
   else if(pio_rx_st2_sop_i) begin
     pio_rx_sop_location <= 2;
   end
   else if(pio_rx_st3_sop_i) begin
     pio_rx_sop_location <= 3;
   end
   if(pio_rx_st0_eop_i) begin
     pio_rx_eop_location <= 0;
   end
   else if(pio_rx_st1_eop_i) begin
     pio_rx_eop_location <= 1;
   end
   else if(pio_rx_st2_eop_i) begin
     pio_rx_eop_location <= 2;
   end
   else if(pio_rx_st3_eop_i) begin
     pio_rx_eop_location <= 3;
   end


   buffer_full_slot_reg <= buffer_full_slot;
  end

end

always_ff @ (posedge clk ) begin
  srst_reg        <= ~reset_n;
  srst_reg2        <= ~reset_n;
end


always_ff @ (posedge clk or posedge srst_reg) begin
    if (srst_reg) begin
      last_data_packet_received <= 0;
      eop_slot0 <= 0;
      eop_slot1 <= 0;
      headeronly <= 0;
      headeronly_reg <= 0;
    end
    else begin
      if(pio_rx_st0_hvalid_i) begin   // for header
        if(sum_dvalid_rec == 0)
          headeronly <= 1;
        else
          headeronly <=0;
        hold_header_reg <= pio_rx_st0_header_i;
        hold_sop_reg <= pio_rx_st0_sop_i;
        hold_bar_reg <= pio_rx_st0_bar_i;
      end
      else if(pio_rx_st1_hvalid_i) begin
        if(sum_dvalid_rec == 0)
          headeronly <= 1;
        else
          headeronly <=0;
        hold_header_reg <= pio_rx_st1_header_i;
        hold_sop_reg <= pio_rx_st1_sop_i;
        hold_bar_reg <= pio_rx_st1_bar_i;
      end
      else if(pio_rx_st2_hvalid_i) begin
        if(sum_dvalid_rec == 0)
          headeronly <= 1;
        else
          headeronly <=0;
        hold_header_reg <= pio_rx_st2_header_i;
        hold_sop_reg <= pio_rx_st2_sop_i;
        hold_bar_reg <= pio_rx_st2_bar_i;
      end
      else if(pio_rx_st3_hvalid_i) begin
        if(sum_dvalid_rec == 0)
          headeronly <= 1;
        else
          headeronly <=0;
        hold_header_reg <= pio_rx_st3_header_i;
        hold_sop_reg <= pio_rx_st3_sop_i;
        hold_bar_reg <= pio_rx_st3_bar_i;
      end
      if(hold_eop_reg == 1) begin //handling eop
        hold_eop_reg <= 0;
      end
      else if(hold_eop_reg_set_nxt_cyc == 1) begin
        hold_eop_reg <= 1;
        hold_eop_reg_set_nxt_cyc <= 0;
      end
      else if((pio_rx_st0_eop_reg)||(pio_rx_st1_eop_reg)||(pio_rx_st2_eop_reg)||(pio_rx_st3_eop_reg)) begin
        // if sop and eop happens at the same cycle
        if((pio_rx_st0_sop_reg)||(pio_rx_st1_sop_reg)||(pio_rx_st2_sop_reg)||(pio_rx_st3_sop_reg)) begin
          hold_eop_reg <= 1;
        end
        // if sop and eop happens at different cycle. Need to check if eop location larger than sop location. If yes, hold_eop_reg set at the next cycle.
        else if(pio_rx_eop_location >= pio_rx_sop_location) begin
          hold_eop_reg_set_nxt_cyc <= 1;
        end
        else begin
          hold_eop_reg <= 1;
          hold_eop_reg_set_nxt_cyc <= 0;
        end
        
      end
      if(headeronly) begin
        headeronly <= 0;
      end

    headeronly_reg <= headeronly; 
    end
end


always_ff @ (posedge clk or posedge srst_reg) begin
  if (srst_reg) begin
      pio_rx_valid <= 1'b0;
      pio_rx_bar <= 3'b0;
      pio_rx_header <= 128'h0;
      pio_rx_payload <= 'h0;
      pio_rx_sop <= 1'b0;
      pio_rx_eop <= 1'b0;
      sent_slot0 <= 0;
      sent_slot1 <= 0;
  end
  else begin
    if(sent_slot1) begin   // pull down the signals
      pio_rx_bar <= 'b0;
      pio_rx_sop <= 1'b0;;
      pio_rx_header <= 'h0;
      sent_slot1 <= 0;
    end
    if(sent_slot0) begin
      if(pio_rx_eop) begin
        pio_rx_payload <= 'h0;
        pio_rx_eop <= 1'b0;
        sent_slot0 <= 1'b0;
        pio_rx_valid <= 1'b0;
      end
      else if(buffer_full_slot_reg) begin
        pio_rx_valid <= 1'b1;
        if(BAM_DATAWIDTH == 1024) begin 
          pio_rx_payload <= {pio_rx_st3_payload_reg2,pio_rx_st2_payload_reg2,pio_rx_st1_payload_reg2,pio_rx_st0_payload_reg2};
        end
        else if(BAM_DATAWIDTH == 512) begin
          pio_rx_payload <= {pio_rx_st1_payload_reg2,pio_rx_st0_payload_reg2};
        end
        if(hold_eop_reg) begin
          pio_rx_eop <= 1'b1;
        end
      end
      else if(hold_eop_reg) begin
        pio_rx_valid <= 1'b1;
        if(BAM_DATAWIDTH == 1024) begin
          pio_rx_payload <= {256'h0,reserved_payload_slot0_2,reserved_payload_slot0_1,reserved_payload_slot0_0};
        end
        else if(BAM_DATAWIDTH == 512) begin
          pio_rx_payload <= {256'h0,reserved_payload_slot0_0};
        end
        pio_rx_eop <= 1'b1;

      end
      else begin
        pio_rx_payload <= 'h0;
        pio_rx_valid <= 1'b0;
      end
    end
    else if((buffer_full_slot_reg)||(headeronly_reg)||(hold_eop_reg)) begin
      pio_rx_bar <= hold_bar_reg;
      pio_rx_sop <= hold_sop_reg;
      pio_rx_header <= hold_header_reg;

      pio_rx_valid <= 1'b1;
      sent_slot0 <= 1;
      sent_slot1 <= 1;
      if(hold_eop_reg) begin
        pio_rx_eop <= 1'b1;
        if(buffer_full_slot_reg) begin
          if(BAM_DATAWIDTH == 1024) begin
            pio_rx_payload <= {pio_rx_st3_payload_reg2,pio_rx_st2_payload_reg2,pio_rx_st1_payload_reg2,pio_rx_st0_payload_reg2};
          end
          else if(BAM_DATAWIDTH == 512) begin
            pio_rx_payload <= {pio_rx_st1_payload_reg2,pio_rx_st0_payload_reg2};
          end
        end
        else begin
          if(BAM_DATAWIDTH == 1024) begin
            pio_rx_payload <= {256'h0,reserved_payload_slot0_2,reserved_payload_slot0_1,reserved_payload_slot0_0};
          end
          else if(BAM_DATAWIDTH == 512) begin
            pio_rx_payload <= {256'h0,reserved_payload_slot0_0};
          end
        end
      end
      else begin
        if(BAM_DATAWIDTH == 1024) begin
          pio_rx_payload <= {pio_rx_st3_payload_reg2,pio_rx_st2_payload_reg2,pio_rx_st1_payload_reg2,pio_rx_st0_payload_reg2};
        end
        else if(BAM_DATAWIDTH == 512) begin
          pio_rx_payload <= {pio_rx_st1_payload_reg2,pio_rx_st0_payload_reg2};
        end
      end
    end
    else begin
      pio_rx_payload <= 'h0;
      pio_rx_valid <= 1'b0;
    end

  end
end

assign to_calculate_bytecount_minus1 = to_calculate_bytecount - 12'b1;

always_ff @ (posedge clk or posedge srst_reg) begin
  if (srst_reg) begin
  end
  else begin
    if(pio_txc_valid) begin
      pio_txc_st0_payload_reg[255:0] <= pio_txc_payload[255:0];
      pio_txc_st1_payload_reg[255:0] <= pio_txc_payload[511:256];
      if(BAM_DATAWIDTH == 1024) begin
        pio_txc_st2_payload_reg[255:0] <= pio_txc_payload[767:512];
        pio_txc_st3_payload_reg[255:0] <= pio_txc_payload[1023:768];
      end
      else begin
        pio_txc_st2_payload_reg[255:0] <= 256'h0;
        pio_txc_st3_payload_reg[255:0] <= 256'h0;
      end 
      pio_txc_sop_reg <= pio_txc_sop;
      pio_txc_eop_reg <= pio_txc_eop;
      pio_txc_header_reg <= pio_txc_header;
      to_calculate_bytecount <= pio_txc_header[43:32];
    end
    if(to_calculate_bytecount >= 12'h80) begin
      to_calculate_bytecount <= to_calculate_bytecount - 12'h80;
      calculate_bytecount[1:0] <= 2'b11; 
    end
    else begin
      calculate_bytecount[1:0] <= to_calculate_bytecount_minus1[6:5];
    end
    pio_tx_st0_dvalid_reg <= to_pio_tx_st0_dvalid_reg;
    pio_tx_st1_dvalid_reg <= to_pio_tx_st1_dvalid_reg;
    pio_tx_st2_dvalid_reg <= to_pio_tx_st2_dvalid_reg;
    pio_tx_st3_dvalid_reg <= to_pio_tx_st3_dvalid_reg;
    pio_tx_st0_eop_reg  <= to_pio_tx_st0_eop_reg;
    pio_tx_st1_eop_reg  <= to_pio_tx_st1_eop_reg;
    pio_tx_st2_eop_reg  <= to_pio_tx_st2_eop_reg;
    pio_tx_st3_eop_reg  <= to_pio_tx_st3_eop_reg;
    pio_txc_sop_reg2 <= pio_txc_sop_reg;
    pio_txc_eop_reg2 <= pio_txc_eop_reg; 
    pio_txc_sop_reg3 <= pio_txc_sop_reg2;
    pio_txc_header_reg2 <= pio_txc_header_reg; 
    pio_txc_header_reg3 <= pio_txc_header_reg2;
  end  
end

always_ff @ (posedge clk or posedge srst_reg2) begin
  if (srst_reg2) begin
    pio_tx_st0_eop_o <= 1'b0;
    pio_tx_st1_eop_o <= 1'b0;
    pio_tx_st2_eop_o <= 1'b0;
    pio_tx_st3_eop_o <= 1'b0;
    pio_tx_st0_sop_o <= 1'b0;
    pio_tx_st1_sop_o <= 1'b0;
    pio_tx_st2_sop_o <= 1'b0;
    pio_tx_st3_sop_o <= 1'b0;
    pio_tx_st0_header_o <= 'h0;
    pio_tx_st1_header_o <= 'h0;
    pio_tx_st2_header_o <= 'h0;
    pio_tx_st3_header_o <= 'h0;
    pio_tx_st0_payload_o <= 'h0;
    pio_tx_st1_payload_o <= 'h0;
    pio_tx_st2_payload_o <= 'h0;
    pio_tx_st3_payload_o <= 'h0;
    pio_tx_st0_dvalid_o <= 1'b0;
    pio_tx_st1_dvalid_o <= 1'b0;
    pio_tx_st2_dvalid_o <= 1'b0;
    pio_tx_st3_dvalid_o <= 1'b0;
    pio_tx_st0_hvalid_o <= 1'b0;
    pio_tx_st1_hvalid_o <= 1'b0;
    pio_tx_st2_hvalid_o <= 1'b0;
    pio_tx_st3_hvalid_o <= 1'b0;
    pio_tx_st0_pvalid_o <= 1'b0;
    pio_tx_st1_pvalid_o <= 1'b0;
    pio_tx_st2_pvalid_o <= 1'b0;
    pio_tx_st3_pvalid_o <= 1'b0;
    tx_sent <= 1'b0;

  end
  else begin
    if(tx_sent) begin //suppose at most it is 1
      pio_tx_st0_eop_o <= 1'b0;
      pio_tx_st1_eop_o <= 1'b0;
      pio_tx_st2_eop_o <= 1'b0;
      pio_tx_st3_eop_o <= 1'b0;
      pio_tx_st0_sop_o <= 1'b0;
      pio_tx_st0_header_o <= 'h0;
      pio_tx_st0_payload_o <= 'h0;
      pio_tx_st1_payload_o <= 'h0;
      pio_tx_st2_payload_o <= 'h0;
      pio_tx_st3_payload_o <= 'h0;
      pio_tx_st0_dvalid_o <= 1'b0;
      pio_tx_st1_dvalid_o <= 1'b0;
      pio_tx_st2_dvalid_o <= 1'b0;
      pio_tx_st3_dvalid_o <= 1'b0;
      pio_tx_st0_hvalid_o <= 1'b0;
      pio_tx_st1_hvalid_o <= 1'b0;
      pio_tx_st2_hvalid_o <= 1'b0;
      pio_tx_st3_hvalid_o <= 1'b0;
      tx_sent <= 1'b0;
    end
    else if (pio_txc_valid_reg3) begin
      pio_tx_st0_eop_o <= pio_tx_st0_eop_reg;
      pio_tx_st1_eop_o <= pio_tx_st1_eop_reg;
      pio_tx_st2_eop_o <= pio_tx_st2_eop_reg;
      pio_tx_st3_eop_o <= pio_tx_st3_eop_reg;
      pio_tx_st0_sop_o <= pio_txc_sop_reg3;
      pio_tx_st1_sop_o <= 1'b0;
      pio_tx_st2_sop_o <= 1'b0;
      pio_tx_st3_sop_o <= 1'b0;
      pio_tx_st0_header_o <= pio_txc_header_reg2;
      pio_tx_st1_header_o <= 'h0;
      pio_tx_st2_header_o <= 'h0;
      pio_tx_st3_header_o <= 'h0;
      pio_tx_st0_payload_o <= pio_txc_st0_payload_reg3;
      pio_tx_st1_payload_o <= pio_txc_st1_payload_reg3;
      pio_tx_st2_payload_o <= pio_txc_st2_payload_reg3;
      pio_tx_st3_payload_o <= pio_txc_st3_payload_reg3;
      pio_tx_st0_dvalid_o <= pio_tx_st0_dvalid_reg;
      pio_tx_st1_dvalid_o <= pio_tx_st1_dvalid_reg;
      pio_tx_st2_dvalid_o <= pio_tx_st2_dvalid_reg;
      pio_tx_st3_dvalid_o <= pio_tx_st3_dvalid_reg; 
      pio_tx_st0_hvalid_o <= 1'b1;
      pio_tx_st1_hvalid_o <= 1'b0;
      pio_tx_st2_hvalid_o <= 1'b0;
      pio_tx_st3_hvalid_o <= 1'b0;
      pio_tx_st0_pvalid_o <= 1'b0;
      pio_tx_st1_pvalid_o <= 1'b0;
      pio_tx_st2_pvalid_o <= 1'b0;
      pio_tx_st3_pvalid_o <= 1'b0;
      if(sum_of_eop_o >= 1) begin
        tx_sent <= 1'b1;
      end
    end
    pio_txc_valid_reg <= pio_txc_valid;
    pio_txc_valid_reg2 <= pio_txc_valid_reg;
    pio_txc_valid_reg3 <= pio_txc_valid_reg2;
    pio_txc_st0_payload_reg2 <= pio_txc_st0_payload_reg;
    pio_txc_st1_payload_reg2 <= pio_txc_st1_payload_reg;
    pio_txc_st2_payload_reg2 <= pio_txc_st2_payload_reg;
    pio_txc_st3_payload_reg2 <= pio_txc_st3_payload_reg;
    pio_txc_st0_payload_reg3 <= pio_txc_st0_payload_reg2;
    pio_txc_st1_payload_reg3 <= pio_txc_st1_payload_reg2;
    pio_txc_st2_payload_reg3 <= pio_txc_st2_payload_reg2;
    pio_txc_st3_payload_reg3 <= pio_txc_st3_payload_reg2;
 
  end
end

assign comb_tx_sop_eop = {pio_txc_sop_reg2,pio_txc_eop_reg2};
//formula ==> (header bytecount - 1)/32
// 32 byte = 256bit

assign sum_of_eop_o = pio_tx_st0_eop_reg + pio_tx_st1_eop_reg + pio_tx_st2_eop_reg + pio_tx_st3_eop_reg; 
//   eop follow the last dvalid on
//   if sop = 1, eop = 0,  all dvalid on
//   if sop = 0, eop = 0, all dvalid on
//   if sop =0, eop = 1, byte count to calculate the remaining data and decide last dvalid and eop on with st
//   if sop = 1, eop = 1, byte count to calculate the remaining data

always_comb begin
  case(comb_tx_sop_eop[1:0])
       2'b00:
         begin
           to_pio_tx_st0_dvalid_reg = 1'b1;
           to_pio_tx_st1_dvalid_reg = 1'b1;
           to_pio_tx_st2_dvalid_reg = 1'b1;
           to_pio_tx_st3_dvalid_reg = 1'b1;    
           to_pio_tx_st0_eop_reg = 1'b0;
           to_pio_tx_st1_eop_reg = 1'b0;
           to_pio_tx_st2_eop_reg = 1'b0;
           to_pio_tx_st3_eop_reg = 1'b0;  
         end
       2'b01:
         begin
           if(calculate_bytecount == 0) begin
             to_pio_tx_st0_dvalid_reg = 1'b1;
             to_pio_tx_st1_dvalid_reg = 1'b0;
             to_pio_tx_st2_dvalid_reg = 1'b0;
             to_pio_tx_st3_dvalid_reg = 1'b0;
             to_pio_tx_st0_eop_reg = 1'b1;
             to_pio_tx_st1_eop_reg = 1'b0;
             to_pio_tx_st2_eop_reg = 1'b0;
             to_pio_tx_st3_eop_reg = 1'b0;
           end
           else if (calculate_bytecount == 1) begin
             to_pio_tx_st0_dvalid_reg = 1'b1;
             to_pio_tx_st1_dvalid_reg = 1'b1;
             to_pio_tx_st2_dvalid_reg = 1'b0;
             to_pio_tx_st3_dvalid_reg = 1'b0;
             to_pio_tx_st0_eop_reg = 1'b0;
             to_pio_tx_st1_eop_reg = 1'b1;
             to_pio_tx_st2_eop_reg = 1'b0;
             to_pio_tx_st3_eop_reg = 1'b0;
           end
           else if (calculate_bytecount == 2) begin
             to_pio_tx_st0_dvalid_reg = 1'b1;
             to_pio_tx_st1_dvalid_reg = 1'b1;
             to_pio_tx_st2_dvalid_reg = 1'b1;
             to_pio_tx_st3_dvalid_reg = 1'b0;
             to_pio_tx_st0_eop_reg = 1'b0;
             to_pio_tx_st1_eop_reg = 1'b0;
             to_pio_tx_st2_eop_reg = 1'b1;
             to_pio_tx_st3_eop_reg = 1'b0;
           end
           else begin
             to_pio_tx_st0_dvalid_reg = 1'b1;
             to_pio_tx_st1_dvalid_reg = 1'b1;
             to_pio_tx_st2_dvalid_reg = 1'b1;
             to_pio_tx_st3_dvalid_reg = 1'b1;
             to_pio_tx_st0_eop_reg = 1'b0;
             to_pio_tx_st1_eop_reg = 1'b0;
             to_pio_tx_st2_eop_reg = 1'b0;
             to_pio_tx_st3_eop_reg = 1'b1;              
           end
         end
       2'b10:
         begin
           to_pio_tx_st0_dvalid_reg = 1'b1;
           to_pio_tx_st1_dvalid_reg = 1'b1;
           to_pio_tx_st2_dvalid_reg = 1'b1;
           to_pio_tx_st3_dvalid_reg = 1'b1;
           to_pio_tx_st0_eop_reg = 1'b0;
           to_pio_tx_st1_eop_reg = 1'b0;
           to_pio_tx_st2_eop_reg = 1'b0;
           to_pio_tx_st3_eop_reg = 1'b0;
         end
       2'b11:
         begin
           
           if(pio_txc_header[43:32] == 0) begin   //newly added need to verify throughly
             to_pio_tx_st0_dvalid_reg = 1'b0;
             to_pio_tx_st1_dvalid_reg = 1'b0;
             to_pio_tx_st2_dvalid_reg = 1'b0;
             to_pio_tx_st3_dvalid_reg = 1'b0;
             to_pio_tx_st0_eop_reg = 1'b1;
             to_pio_tx_st1_eop_reg = 1'b0;
             to_pio_tx_st2_eop_reg = 1'b0;
             to_pio_tx_st3_eop_reg = 1'b0;
           end
           else if(calculate_bytecount == 0) begin
             to_pio_tx_st0_dvalid_reg = 1'b1;
             to_pio_tx_st1_dvalid_reg = 1'b0;
             to_pio_tx_st2_dvalid_reg = 1'b0;
             to_pio_tx_st3_dvalid_reg = 1'b0;
             to_pio_tx_st0_eop_reg = 1'b1;
             to_pio_tx_st1_eop_reg = 1'b0;
             to_pio_tx_st2_eop_reg = 1'b0;
             to_pio_tx_st3_eop_reg = 1'b0;
           end
           else if (calculate_bytecount == 1) begin
             to_pio_tx_st0_dvalid_reg = 1'b1;
             to_pio_tx_st1_dvalid_reg = 1'b1;
             to_pio_tx_st2_dvalid_reg = 1'b0;
             to_pio_tx_st3_dvalid_reg = 1'b0;
             to_pio_tx_st0_eop_reg = 1'b0;
             to_pio_tx_st1_eop_reg = 1'b1;
             to_pio_tx_st2_eop_reg = 1'b0;
             to_pio_tx_st3_eop_reg = 1'b0;
           end
           else if (calculate_bytecount == 2) begin
             to_pio_tx_st0_dvalid_reg = 1'b1;
             to_pio_tx_st1_dvalid_reg = 1'b1;
             to_pio_tx_st2_dvalid_reg = 1'b1;
             to_pio_tx_st3_dvalid_reg = 1'b0;
             to_pio_tx_st0_eop_reg = 1'b0;
             to_pio_tx_st1_eop_reg = 1'b0;
             to_pio_tx_st2_eop_reg = 1'b1;
             to_pio_tx_st3_eop_reg = 1'b0;
           end
           else begin
             to_pio_tx_st0_dvalid_reg = 1'b1;
             to_pio_tx_st1_dvalid_reg = 1'b1;
             to_pio_tx_st2_dvalid_reg = 1'b1;
             to_pio_tx_st3_dvalid_reg = 1'b1;
             to_pio_tx_st0_eop_reg = 1'b0;
             to_pio_tx_st1_eop_reg = 1'b0;
             to_pio_tx_st2_eop_reg = 1'b0;
             to_pio_tx_st3_eop_reg = 1'b1;
           end
         end
       default:
         begin
           to_pio_tx_st0_dvalid_reg = 1'b1;
           to_pio_tx_st1_dvalid_reg = 1'b1;
           to_pio_tx_st2_dvalid_reg = 1'b1;
           to_pio_tx_st3_dvalid_reg = 1'b1;
           to_pio_tx_st0_eop_reg = 1'b0;
           to_pio_tx_st1_eop_reg = 1'b0;
           to_pio_tx_st2_eop_reg = 1'b0;
           to_pio_tx_st3_eop_reg = 1'b0;   
         end

      endcase
end


endmodule 
