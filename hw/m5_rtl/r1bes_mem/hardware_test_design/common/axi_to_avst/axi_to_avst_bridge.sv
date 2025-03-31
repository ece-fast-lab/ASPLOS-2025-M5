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

import afu_axi_if_pkg::*;

module axi_to_avst_bridge (
    input					clk,
    input					rst,
    input   t_axi4_rd_addr_ch                   axi_ar,
    output  t_axi4_rd_addr_ready                axi_arready,    
    output  t_axi4_rd_resp_ch                   axi_r,
    input   t_axi4_rd_resp_ready                axi_rready, 
   
    input   t_axi4_wr_addr_ch                   axi_aw,
    output  t_axi4_wr_addr_ready                axi_awready,   
    input   t_axi4_wr_data_ch                   axi_w,
    output  t_axi4_wr_data_ready                axi_wready,    
    output  t_axi4_wr_resp_ch                   axi_b,
    input   t_axi4_wr_resp_ready                axi_bready,    

    input                                       pf0_bus_master_en,

    input  logic  [7:0] 			bus_number,
    input         [4:0] 			device_number,
    input         [2:0]				function_number,
    input                                       wr_tlp_fifo_empty ,
    input                                       wr_tlp_fifo_almost_full ,
    input                                       rd_tlp_fifo_almost_full ,

    input  logic                                rx_st_dvalid,
    input  logic                                rx_st_sop,
    input  logic                                rx_st_eop,
    input  logic  [511:0]                       rx_st_data, 
    input  logic  [127:0]                       rx_st_hdr,
    input  logic                                rx_st_hvalid,

    input                                       tx_st_ready,
    output logic                                tx_st_dvalid,
    output logic                                tx_st_sop,
    output logic                                tx_st_eop,
    output logic                                tx_st_passthrough,
    output logic  [511:0]                       tx_st_data,
    output logic  [127:0]                       tx_st_hdr,
    output logic                                tx_st_hvalid,
    output logic                                wr_last,

    input  logic  [9:0]                         p_tlp_sent_tag,
    input  logic                                p_tlp_sent_tag_valid,

    input  logic [15:0]            		tx_p_data_counter,
    input  logic [15:0]            		tx_np_data_counter,
    input  logic [15:0]            		tx_cpl_data_counter,
    input  logic [12:0]            		tx_p_header_counter,
    input  logic [12:0]            		tx_np_header_counter,
    input  logic [12:0]            		tx_cpl_header_counter

);

logic read_credits_available;
logic write_credits_available;
logic wr_rsp_buf_ren;
logic wr_rsp_buf_ren_f;
logic rd_rsp_buf_ren;
logic rd_rsp_buf_ren_f;
logic wr_rsp_buf_not_empty;
logic rd_rsp_buf_not_empty;
logic [31:0] read_tlp_hdr_1dw;
logic [31:0] read_tlp_hdr_2dw;
logic [31:0] read_tlp_hdr_3dw;
logic [31:0] read_tlp_hdr_4dw;
logic [31:0] write_tlp_hdr_1dw;
logic [31:0] write_tlp_hdr_2dw;
logic [31:0] write_tlp_hdr_3dw;
logic [31:0] write_tlp_hdr_4dw;

t_axi4_wr_addr_ready     awready;
t_axi4_wr_data_ready     wready;  
t_axi4_wr_resp_ch    axi_b_din, axi_b_dout;
t_axi4_rd_resp_ch    axi_r_din, axi_r_dout;

logic         read_tlp_header_valid;     
logic [63:0]  read_tlp_header_address;   
logic [63:0]  read_tlp_end_address;   
logic [9:0]   read_tlp_header_tag;       
logic [9:0]   read_tlp_header_length; 	 
logic         read_tlp_3DW;


logic         write_tlp_header_valid;     
logic [63:0]  write_tlp_header_address;   
logic	      write_tlp_address_valid;
logic [9:0]   write_tlp_header_tag;       
logic [9:0]   write_tlp_header_length; 	 
logic [511:0] write_tlp_data;
logic [63:0]  write_tlp_data_strobe;
logic	      write_tlp_data_valid;
logic         write_tlp_header_data_valid;

logic         write_tlp_header_valid_f;     
logic [63:0]  write_tlp_header_address_f;   
logic [9:0]   write_tlp_header_tag_f;       
logic [9:0]   write_tlp_header_length_f; 	 
logic [511:0] write_tlp_data_f;
logic [63:0]  write_tlp_data_strobe_f;
logic	      write_tlp_data_valid_f;

logic         write_tlp_header_valid_ff;     
logic [63:0]  write_tlp_header_address_ff;   
logic [63:0]  write_tlp_end_address;   //(tlp address + len > 32bit) send 4DW TLP HDR
logic [9:0]   write_tlp_header_tag_ff;       
logic [9:0]   write_tlp_header_length_ff; 	 
logic [511:0] write_tlp_data_ff;
logic [63:0]  write_tlp_data_strobe_ff;
logic	      write_tlp_data_valid_ff;
logic         write_tlp_3DW;

logic [525:0] avst_din;
logic [525:0] avst_dout;
logic         avst_wen;

logic 	      write_tlp_header_and_data_valid;

logic	      rd_rsp_buf_full;
logic	      wr_rsp_buf_full;
logic	      wr_rsp_buf_almost_full;
logic         rd_rsp_buf_empty;
logic         rd_rsp_buf_empty_f;

logic         wr_rsp_buf_empty;
logic         wr_rsp_buf_empty_f;
logic [127:0] write_tlp_header;
logic         wr_sop;               
logic         wr_eop;               
logic         wr_hvalid;            
logic         wr_dvalid;            
logic [127:0] wr_hdr;   
logic [511:0] wr_data;  
logic         rd_sop;               
logic         rd_eop;               
logic         rd_hvalid;            
logic         rd_dvalid;            
logic [127:0] rd_hdr;   
logic [511:0] rd_data;  


logic [9:0]   tlp_len_sel_p;
logic [9:0]   tlp_tag_sel_p;
logic [511:0] tlp_data_sel_p;
logic         tlp_sop_sel_p;
logic [3:0]   tlp_fbe_sel_p;
logic [3:0]   tlp_lbe_sel_p;
logic [63:0]  tlp_address_sel_p;  
logic         tlp_last_p;
logic [9:0]   tlp_len_sel_f;
logic [9:0]   tlp_tag_sel_f;
logic [511:0] tlp_data_sel_f;
logic         tlp_sop_sel_f;
logic [3:0]   tlp_fbe_sel_f;
logic [3:0]   tlp_lbe_sel_f;
logic [63:0]  tlp_address_sel_f;  
logic         tlp_last_f;
logic [63:0]  tlp1_address_fifo_out;  
logic [63:0]  tlp2_address_fifo_out;  
logic [63:0]  tlp3_address_fifo_out;  
logic [63:0]  tlp4_address_fifo_out;  
logic [63:0]  tlp5_address_fifo_out;  
logic [63:0]  tlp6_address_fifo_out;  
logic [63:0]  tlp7_address_fifo_out;  
logic [63:0]  tlp8_address_fifo_out;  
logic [63:0]  tlp1_address;  
logic [63:0]  tlp2_address;  
logic [63:0]  tlp3_address;  
logic [63:0]  tlp4_address;  
logic [63:0]  tlp5_address;  
logic [63:0]  tlp6_address;  
logic [63:0]  tlp7_address;  
logic [63:0]  tlp8_address;  
logic [63:0]  tlp_address_sel;  
logic [63:0]  tlp_address_fifo_out;  
logic [3:0]   tlp1_lbe_fifo_out;
logic [3:0]   tlp2_lbe_fifo_out;
logic [3:0]   tlp3_lbe_fifo_out;
logic [3:0]   tlp4_lbe_fifo_out;
logic [3:0]   tlp5_lbe_fifo_out;
logic [3:0]   tlp6_lbe_fifo_out;
logic [3:0]   tlp7_lbe_fifo_out;
logic [3:0]   tlp8_lbe_fifo_out;
logic [3:0]   tlp1_lbe;
logic [3:0]   tlp2_lbe;
logic [3:0]   tlp3_lbe;
logic [3:0]   tlp4_lbe;
logic [3:0]   tlp5_lbe;
logic [3:0]   tlp6_lbe;
logic [3:0]   tlp7_lbe;
logic [3:0]   tlp8_lbe;
logic [3:0]   tlp_lbe_sel;
logic [3:0]   tlp_lbe_fifo_out;
logic [3:0]   tlp1_fbe_fifo_out;
logic [3:0]   tlp2_fbe_fifo_out;
logic [3:0]   tlp3_fbe_fifo_out;
logic [3:0]   tlp4_fbe_fifo_out;
logic [3:0]   tlp5_fbe_fifo_out;
logic [3:0]   tlp6_fbe_fifo_out;
logic [3:0]   tlp7_fbe_fifo_out;
logic [3:0]   tlp8_fbe_fifo_out;
logic [3:0]   tlp1_fbe;
logic [3:0]   tlp2_fbe;
logic [3:0]   tlp3_fbe;
logic [3:0]   tlp4_fbe;
logic [3:0]   tlp5_fbe;
logic [3:0]   tlp6_fbe;
logic [3:0]   tlp7_fbe;
logic [3:0]   tlp8_fbe;
logic [3:0]   tlp_fbe_sel;
logic         tlp_sop_sel;
logic [3:0]   tlp_fbe_fifo_out;
logic [9:0]   tlp1_len_fifo_out;
logic [9:0]   tlp2_len_fifo_out;
logic [9:0]   tlp3_len_fifo_out;
logic [9:0]   tlp4_len_fifo_out;
logic [9:0]   tlp5_len_fifo_out;
logic [9:0]   tlp6_len_fifo_out;
logic [9:0]   tlp7_len_fifo_out;
logic [9:0]   tlp8_len_fifo_out;
logic [9:0]   tlp1_len;
logic [9:0]   tlp2_len;
logic [9:0]   tlp3_len;
logic [9:0]   tlp4_len;
logic [9:0]   tlp5_len;
logic [9:0]   tlp6_len;
logic [9:0]   tlp7_len;
logic [9:0]   tlp8_len;
logic         tlp1_valid_fifo_out;
logic         tlp2_valid_fifo_out;
logic         tlp3_valid_fifo_out;
logic         tlp4_valid_fifo_out;
logic         tlp5_valid_fifo_out;
logic         tlp6_valid_fifo_out;
logic         tlp7_valid_fifo_out;
logic         tlp8_valid_fifo_out;
logic         tlp1_valid;
logic         tlp2_valid;
logic         tlp3_valid;
logic         tlp4_valid;
logic         tlp5_valid;
logic         tlp6_valid;
logic         tlp7_valid;
logic         tlp8_valid;
logic [9:0]   tlp_len_sel;
logic [9:0]   tlp_len_fifo_out;
logic [9:0]   tlp_tag_sel;
logic [511:0] tlp_data_sel;
logic         tlp_last;
logic         tlp_sop;
logic         tlp_2to8_fifo_out;
logic         tlp_3to8_fifo_out;
logic         tlp_4to8_fifo_out;
logic         tlp_5to8_fifo_out;
logic         tlp_6to8_fifo_out;
logic         tlp_7to8_fifo_out;
logic         tlp_8_fifo_out;
logic         tlp_2to8;
logic         tlp_3to8;
logic         tlp_4to8;
logic         tlp_5to8;
logic         tlp_6to8;
logic         tlp_7to8;
logic         tlp_8;
logic [63:0]  tlp1_data;
logic [63:0]  tlp2_data;
logic [63:0]  tlp3_data;
logic [63:0]  tlp4_data;
logic [63:0]  tlp5_data;
logic [63:0]  tlp6_data;
logic [63:0]  tlp7_data;
logic [63:0]  tlp8_data;

logic [511:0] tlp_data_fifo_out;
logic [63:0]  tlp_data_strobe_fifo_out;
logic [9:0]   tlp_tag_fifo_out;
logic [6:0]   tlp_length_fifo_out;
logic [659:0] axi_wr_tlp_fifo_wr_data;
logic [659:0] axi_wr_tlp_fifo_rd_data;
logic [659:0] axi_wr_tlp_fifo_rd_data_f;
logic         axi_wr_tlp_fifo_empty;
logic         axi_wr_tlp_fifo_full;
logic         axi_wr_tlp_fifo_wrreq;
logic         axi_wr_tlp_fifo_rdreq;
logic         axi_wr_tlp_fifo_almost_full;
logic [3:0]   wr_tlp_state;
logic [3:0]   wr_tlp_next_state;

logic         axi_w_wvalid_f;
logic         axi_w_walid_posedge;
logic         axi_write_split_txn;
logic         axi_write_split_txn_f;
logic         axi_write_split_txn_ff;
logic         axi_write_split_txn_fff;
logic         p_credits_available;
logic         axi_write_zero_strobe_txn;
logic         axi_write_zero_strobe_txn_f;
logic         axi_write_zero_strobe_txn_ff;
logic         axi_write_zero_strobe_txn_fff;
assign axi_awready = awready;
assign axi_wready  = wready;

localparam MIN_HDR_CRDT_REQ = 'd3;
localparam MIN_DATA_CRDT_REQ = 'd12;

//wait till all writes are transmitted, AFU can give Rd TLPs while Wr TLPs are
// being sent
assign read_credits_available  = (tx_np_header_counter > MIN_HDR_CRDT_REQ) & (wr_tlp_fifo_empty) & (!rd_tlp_fifo_almost_full) & (!(axi_aw.awvalid | write_tlp_header_valid | write_tlp_header_valid_f | write_tlp_header_data_valid)) & (pf0_bus_master_en) & (axi_wr_tlp_fifo_empty) &(!(tlp_sop_sel | tlp_sop_sel_p | tlp_sop_sel_f)) ;   

//assign write_credits_available = (tx_p_header_counter > MIN_HDR_CRDT_REQ) & (tx_p_data_counter > MIN_DATA_CRDT_REQ) & (!wr_tlp_fifo_almost_full) & (axi_bready) & (pf0_bus_master_en) & (!axi_wr_tlp_fifo_almost_full); 
assign write_credits_available = (tx_p_header_counter > MIN_HDR_CRDT_REQ) & (tx_p_data_counter > MIN_DATA_CRDT_REQ) & (!wr_tlp_fifo_almost_full) & (!wr_rsp_buf_almost_full) & (pf0_bus_master_en) & (!axi_wr_tlp_fifo_almost_full); 
assign p_credits_available = (tx_p_header_counter > MIN_HDR_CRDT_REQ) & (tx_p_data_counter > MIN_DATA_CRDT_REQ) & (!wr_tlp_fifo_almost_full); 

assign wr_rsp_buf_ren = wr_rsp_buf_not_empty & (axi_bready | ~axi_b.bvalid); 
assign rd_rsp_buf_ren = rd_rsp_buf_not_empty & (axi_rready | ~axi_r.rvalid);
always_ff@(posedge clk) wr_rsp_buf_ren_f <= wr_rsp_buf_ren ;
always_ff@(posedge clk) rd_rsp_buf_ren_f <= rd_rsp_buf_ren ;



always_ff@(posedge clk)
begin
    if(!rst) begin
         avst_din <= 'h0;
         avst_wen <= 'h0;
    end
    else begin
         avst_din <= {rx_st_data,rx_st_hdr[23],rx_st_hdr[19],rx_st_hdr[79:72],rx_st_hdr[47:45],rx_st_hvalid};
         avst_wen <= rx_st_hvalid;  
    end
end

   assign rd_rsp_buf_not_empty = ~rd_rsp_buf_empty;

   always_ff@(posedge clk) rd_rsp_buf_empty_f <= rd_rsp_buf_empty;
    scfifo avst_buffer
      (
       .clock            (clk                 ),
       .data             (avst_din  ),
       .rdreq            (rd_rsp_buf_ren  ),
       .wrreq            (avst_wen  ),
       .q                (avst_dout  ),
       .empty            (rd_rsp_buf_empty  ),
       .sclr             (!rst            ),
       .usedw            (),
       .aclr             (1'b0              ),
       .full             (rd_rsp_buf_full  ),
       .almost_full      (),
       .almost_empty     (),
       .eccstatus       ());
    defparam
      avst_buffer.add_ram_output_register  = "ON",
      avst_buffer.enable_ecc  = "FALSE",
      avst_buffer.intended_device_family  = "Agilex",
      avst_buffer.lpm_hint  = "RAM_BLOCK_TYPE=M20K",
      avst_buffer.lpm_numwords  = 8,
      avst_buffer.lpm_showahead  = "OFF",
      avst_buffer.lpm_type  = "scfifo",
      avst_buffer.lpm_width  = 526,
      avst_buffer.lpm_widthu  = 3,
      avst_buffer.overflow_checking  = "ON",
      avst_buffer.underflow_checking  = "ON",
      avst_buffer.use_eab  = "ON";

//-- read response channel
   always_ff @(posedge clk) begin : RRESP_BUFFEROUT
       if (!rst) begin
           axi_r            <= '0;
       end else begin 
          if (rd_rsp_buf_ren_f) begin 
               axi_r.rvalid     <= avst_dout[0];
           end else if (rd_rsp_buf_not_empty == 0 && (axi_rready && axi_r.rvalid)) begin //effectively done - nothing more and master has accepted the current valid txn
               axi_r.rvalid     <= 0;
           end  
           if (rd_rsp_buf_ren_f) begin //its not free-wheeling because the FIFO dout is X's until the first wr/rd cycle
	       axi_r.rid        <= {2'd0,avst_dout[13:4]};  
               axi_r.rdata      <= avst_dout[525:14];
               axi_r.rresp      <= avst_dout[3:1] == 000 ? eresp_OKAY : eresp_SLVERR ;  //(if not SC then send SLVERR)
               axi_r.rlast      <= avst_dout[0];
               axi_r.ruser      <= 0;  
           end 
   end
   end //always_ff


//---------------------
   //axi_read_address_channel --
   always_ff@(posedge clk) begin : RD_ADDR
       if (!rst) begin
           axi_arready   <= 0;
           read_tlp_header_valid          <= 0;
           read_tlp_header_address        <= 0;
           read_tlp_header_tag            <= 0;
	   read_tlp_header_length         <= 0;
           read_tlp_end_address           <= 0;
       end else begin
           axi_arready                    <= read_credits_available ;  
           read_tlp_header_valid          <= axi_ar.arvalid & axi_arready;
           read_tlp_header_address        <= axi_ar.araddr; 
           read_tlp_header_tag            <= axi_ar.arid[9:0];           
	   read_tlp_header_length         <= tlp_len(axi_ar.arsize);   //--always 512bits will be sent/requested by AFU
           read_tlp_end_address           <= axi_ar.araddr + 'h40;
       end
   end




   /*
    * Write channel handling is more complicated than read channel.
    * Implementations has 3 stages:
    *  Stage 1: capture valid axi address or data & convert to avst.
    *  Stage 2: align separate axi address and data structs. Intent is to isolate the waiting on address for data or data for address.
    *  Stage 3: combine and drive IP. 
    */
   //Stage 1 Begin - handshake back to axi
   //axi_write_address_channel 
   always_ff @(posedge clk) begin : WR_ADDR_STAGE1
       if (!rst) begin
           awready <= 0; 
           write_tlp_header_valid <= 0;
       end else begin
           
           if (awready) begin
               write_tlp_header_address      <= axi_aw.awaddr;  
               write_tlp_header_tag          <= axi_aw.awid[9:0];
               write_tlp_header_length       <= tlp_len(axi_aw.awsize);
           end 
           
           if (awready) begin   //get the latest valid from AXI master
               write_tlp_header_valid <= axi_aw.awvalid;
           end else if (write_tlp_header_valid && write_tlp_data_valid) begin    //holding the valid and data has caught up so explicitly clear valid to avoid duplicate transmission.
               write_tlp_header_valid <= 0;
           end 

           if (!write_credits_available ) begin
               awready <= 0;
           end else if (awready && axi_aw.awvalid && ~write_tlp_header_valid && ~(wready && axi_w.wvalid)) begin  //we're clocking in an address but we got to wait for data, nothing previously nor arriving coincident
               awready <= 0;
           end else if (write_tlp_header_valid && ~(wready && axi_w.wvalid)) begin   //still waiting until data catches up
               awready <= 0;             
           end else begin
               awready <= 1;
           end  

       end
   end  

   //axi_write_data_channel
   always_ff @(posedge clk) begin  : WR_DATA_STAGE1
       if (!rst) begin
           wready <= 0; 
           write_tlp_data_valid <= 0;
       end else begin
           
           if (wready) begin
               write_tlp_data <= axi_w.wdata;   //--all bytes are valid no strobing
               write_tlp_data_strobe <= axi_w.wstrb;
           end 
           
           if (wready) begin   //get the latest valid from AXI master
               write_tlp_data_valid <= axi_w.wvalid;
           end else if (write_tlp_data_valid && write_tlp_header_valid) begin    //holding the valid and address has caught up so explicitly clear valid to avoid duplicate transmission.
               write_tlp_data_valid <= 0;
           end           

           if (!write_credits_available ) begin
               wready <= 0;
           end else if (wready && axi_w.wvalid && ~write_tlp_header_valid && ~(awready && axi_aw.awvalid)) begin   //we're clocking in data but we got to wait for address to catch up, nothing previously nor arriving coinciedent
               wready <= 0;
           end else if (write_tlp_data_valid && ~(awready && axi_aw.awvalid)) begin //still waiting until address catches up
               wready <= 0;
           end else begin
               wready <= 1;
           end
           
           // wready is 1 when detected posedge
           // wready toggles when detected posedge and split txn and 
       end
   end 

    //posedge detect of wvalid and check for strobes for split IO txn
    always_ff@(posedge clk) begin: POSEDGE_DET
        if(!rst) begin
            axi_w_wvalid_f <= 1'b0;
        end
        else begin
            axi_w_wvalid_f <= axi_w.wvalid;
        end
    end

    assign axi_w_walid_posedge = axi_w.wvalid & ~axi_w_wvalid_f;
    assign axi_write_split_txn = ~(&axi_w.wstrb[59:4]);
    assign axi_write_zero_strobe_txn = ~(|axi_w.wstrb);

    always_ff@(posedge clk) begin
        if(!rst) begin
            axi_write_split_txn_f   <= 1'b0;
            axi_write_split_txn_ff  <= 1'b0;
            axi_write_split_txn_fff <= 1'b0;
        end
        else begin
            axi_write_split_txn_f   <= axi_w_walid_posedge ? axi_write_split_txn : axi_write_split_txn_f;
            //axi_write_split_txn_f   <= axi_write_split_txn;
            axi_write_split_txn_ff  <= axi_write_split_txn_f;
            axi_write_split_txn_fff <= axi_write_split_txn_ff;
        end
    end

    always_ff@(posedge clk) begin
        if(!rst) begin
            axi_write_zero_strobe_txn_f   <= 1'b0;
            axi_write_zero_strobe_txn_ff  <= 1'b0;
            axi_write_zero_strobe_txn_fff <= 1'b0;
        end
        else begin
            axi_write_zero_strobe_txn_f   <= axi_w_walid_posedge ? axi_write_zero_strobe_txn : axi_write_zero_strobe_txn_f;
            axi_write_zero_strobe_txn_ff  <= axi_write_zero_strobe_txn_f;
            axi_write_zero_strobe_txn_fff <= axi_write_zero_strobe_txn_ff;
        end
    end



   //Stage1 End
   
   //Stage 2 - align address/data
   //axi_write_address_channel 
   always_ff @(posedge clk) begin : WR_ADDR_STAGE2
       if (!rst) begin 
           write_tlp_header_valid_f <= 0;
       end else begin 
           write_tlp_header_address_f <= write_tlp_header_address; 
           write_tlp_header_tag_f     <= write_tlp_header_tag;
           write_tlp_header_length_f  <= write_tlp_header_length;
           write_tlp_header_valid_f   <= write_tlp_header_valid & write_tlp_data_valid;     //use Q2 to alighn addr/data, both must be valid          
       end
   end  

   //axi_write_data_channel
   always_ff @(posedge clk) begin : WR_DATA_STAGE2
       if (!rst) begin 
           write_tlp_data_valid_f <= 0;
       end else begin
           write_tlp_data_f <= write_tlp_data;
           write_tlp_data_strobe_f <= write_tlp_data_strobe;
           write_tlp_data_valid_f <= write_tlp_header_valid & write_tlp_data_valid;     //use Q2 to alighn addr/data, both must be valid           
       end
   end 
   //Stage 2 End
   
   //Stage 3: combine axi 2 write channels (aw,w) into  avst channel
   always_ff @(posedge clk) begin : WR_STAGE3
       if (!rst) begin
           write_tlp_header_data_valid         <= 0;  
       end else begin
               write_tlp_header_data_valid         <= write_tlp_header_valid_f & write_tlp_data_valid_f;
           end 
           
           if (write_tlp_header_valid_f && write_tlp_data_valid_f) begin
               write_tlp_data_ff                <= write_tlp_data_f;
               write_tlp_data_strobe_ff         <= write_tlp_data_strobe_f;
               write_tlp_header_address_ff      <= write_tlp_header_address_f; 
               write_tlp_header_tag_ff          <= write_tlp_header_tag_f;   
               write_tlp_header_length_ff       <= write_tlp_header_length_f;
           end else begin
                write_tlp_data_ff               <= 'h0;
                write_tlp_data_strobe_ff        <= 'h0;
                write_tlp_header_address_ff     <= 'h0;
                write_tlp_header_tag_ff         <= 'h0;                
                write_tlp_header_tag_ff         <= 'h0;   
           end 
       end 

       always_ff@(posedge clk) begin
           if(!rst) axi_wr_tlp_fifo_rd_data_f <= 'd0;
           else axi_wr_tlp_fifo_rd_data_f <= axi_wr_tlp_fifo_rd_data;

       end

    assign axi_wr_tlp_fifo_wr_data   = {write_tlp_data_ff,write_tlp_data_strobe_ff,write_tlp_header_address_ff,write_tlp_header_tag_ff,write_tlp_header_length_ff}; //512+64+64+10+10
    assign axi_wr_tlp_fifo_wrreq     = write_tlp_header_data_valid;
    assign tlp_data_fifo_out         = axi_wr_tlp_fifo_rd_data_f[659:148];
    assign tlp_data_strobe_fifo_out  = axi_wr_tlp_fifo_rd_data_f[147:84];
    assign tlp_address_fifo_out      = axi_wr_tlp_fifo_rd_data_f[83:20];
    assign tlp_tag_fifo_out          = axi_wr_tlp_fifo_rd_data_f[19:10];
    assign tlp_length_fifo_out       = axi_wr_tlp_fifo_rd_data_f[9:0];
    assign tlp1_address_fifo_out     = tlp_address_fifo_out;  
    assign tlp2_address_fifo_out     = tlp_address_fifo_out + 6'd8;  
    assign tlp3_address_fifo_out     = tlp_address_fifo_out + 6'd16; 
    assign tlp4_address_fifo_out     = tlp_address_fifo_out + 6'd24;  
    assign tlp5_address_fifo_out     = tlp_address_fifo_out + 6'd32;  
    assign tlp6_address_fifo_out     = tlp_address_fifo_out + 6'd40;  
    assign tlp7_address_fifo_out     = tlp_address_fifo_out + 6'd48;  
    assign tlp8_address_fifo_out     = tlp_address_fifo_out + 6'd56;  
    assign tlp1_fbe_fifo_out         = tlp_data_strobe_fifo_out[3:0]; 
    assign tlp1_lbe_fifo_out         = tlp_data_strobe_fifo_out[7:4]; 
    assign tlp2_fbe_fifo_out         = tlp_data_strobe_fifo_out[11:8]; 
    assign tlp2_lbe_fifo_out         = tlp_data_strobe_fifo_out[15:12]; 
    assign tlp3_fbe_fifo_out         = tlp_data_strobe_fifo_out[19:16]; 
    assign tlp3_lbe_fifo_out         = tlp_data_strobe_fifo_out[23:20]; 
    assign tlp4_fbe_fifo_out         = tlp_data_strobe_fifo_out[27:24]; 
    assign tlp4_lbe_fifo_out         = tlp_data_strobe_fifo_out[31:28]; 
    assign tlp5_fbe_fifo_out         = tlp_data_strobe_fifo_out[35:32]; 
    assign tlp5_lbe_fifo_out         = tlp_data_strobe_fifo_out[39:36]; 
    assign tlp6_fbe_fifo_out         = tlp_data_strobe_fifo_out[43:40]; 
    assign tlp6_lbe_fifo_out         = tlp_data_strobe_fifo_out[47:44]; 
    assign tlp7_fbe_fifo_out         = tlp_data_strobe_fifo_out[51:48]; 
    assign tlp7_lbe_fifo_out         = tlp_data_strobe_fifo_out[55:52]; 
    assign tlp8_lbe_fifo_out         = tlp_data_strobe_fifo_out[63:60]; 
    assign tlp8_fbe_fifo_out         = tlp_data_strobe_fifo_out[59:56]; 
    assign tlp1_len_fifo_out         = |tlp1_lbe_fifo_out + |tlp1_fbe_fifo_out; 
    assign tlp2_len_fifo_out         = |tlp2_lbe_fifo_out + |tlp2_fbe_fifo_out; 
    assign tlp3_len_fifo_out         = |tlp3_lbe_fifo_out + |tlp3_fbe_fifo_out; 
    assign tlp4_len_fifo_out         = |tlp4_lbe_fifo_out + |tlp4_fbe_fifo_out; 
    assign tlp5_len_fifo_out         = |tlp5_lbe_fifo_out + |tlp5_fbe_fifo_out; 
    assign tlp6_len_fifo_out         = |tlp6_lbe_fifo_out + |tlp6_fbe_fifo_out; 
    assign tlp7_len_fifo_out         = |tlp7_lbe_fifo_out + |tlp7_fbe_fifo_out; 
    assign tlp8_len_fifo_out         = |tlp8_lbe_fifo_out + |tlp8_fbe_fifo_out; 
    assign tlp_2to8_fifo_out         = |tlp_data_strobe_fifo_out[63:8]; 
    assign tlp_3to8_fifo_out         = |tlp_data_strobe_fifo_out[63:16];
    assign tlp_4to8_fifo_out         = |tlp_data_strobe_fifo_out[63:24];
    assign tlp_5to8_fifo_out         = |tlp_data_strobe_fifo_out[63:32];
    assign tlp_6to8_fifo_out         = |tlp_data_strobe_fifo_out[63:40];
    assign tlp_7to8_fifo_out         = |tlp_data_strobe_fifo_out[63:48];
    assign tlp_8_fifo_out            = |tlp_data_strobe_fifo_out[63:56];
    assign tlp1_valid_fifo_out       = |tlp_data_strobe_fifo_out[7:0];  
    assign tlp2_valid_fifo_out       = |tlp_data_strobe_fifo_out[15:8]; 
    assign tlp3_valid_fifo_out       = |tlp_data_strobe_fifo_out[23:16];
    assign tlp4_valid_fifo_out       = |tlp_data_strobe_fifo_out[31:24];
    assign tlp5_valid_fifo_out       = |tlp_data_strobe_fifo_out[39:32];
    assign tlp6_valid_fifo_out       = |tlp_data_strobe_fifo_out[47:40];
    assign tlp7_valid_fifo_out       = |tlp_data_strobe_fifo_out[55:48];
    assign tlp8_valid_fifo_out       = |tlp_data_strobe_fifo_out[63:56];

    //checki f tlp is 1DW or 2DW tlp
    assign tlp1_fbe                            =  tlp1_len_fifo_out[1:0]==2'h1 ? tlp1_lbe_fifo_out | tlp1_fbe_fifo_out : tlp1_fbe_fifo_out;    
    assign tlp1_lbe                            =  tlp1_len_fifo_out[1:0]==2'h1 ? '0                                    : tlp1_lbe_fifo_out;   
    assign tlp2_fbe                            =  tlp2_len_fifo_out[1:0]==2'h1 ? tlp2_lbe_fifo_out | tlp2_fbe_fifo_out : tlp2_fbe_fifo_out;   
    assign tlp2_lbe                            =  tlp2_len_fifo_out[1:0]==2'h1 ? '0                                    : tlp2_lbe_fifo_out;   
    assign tlp3_fbe                            =  tlp3_len_fifo_out[1:0]==2'h1 ? tlp3_lbe_fifo_out | tlp3_fbe_fifo_out : tlp3_fbe_fifo_out;   
    assign tlp3_lbe                            =  tlp3_len_fifo_out[1:0]==2'h1 ? '0                                    : tlp3_lbe_fifo_out;   
    assign tlp4_fbe                            =  tlp4_len_fifo_out[1:0]==2'h1 ? tlp4_lbe_fifo_out | tlp4_fbe_fifo_out : tlp4_fbe_fifo_out;   
    assign tlp4_lbe                            =  tlp4_len_fifo_out[1:0]==2'h1 ? '0                                    : tlp4_lbe_fifo_out;   
    assign tlp5_fbe                            =  tlp5_len_fifo_out[1:0]==2'h1 ? tlp5_lbe_fifo_out | tlp5_fbe_fifo_out : tlp5_fbe_fifo_out;   
    assign tlp5_lbe                            =  tlp5_len_fifo_out[1:0]==2'h1 ? '0                                    : tlp5_lbe_fifo_out;    
    assign tlp6_fbe                            =  tlp6_len_fifo_out[1:0]==2'h1 ? tlp6_lbe_fifo_out | tlp6_fbe_fifo_out : tlp6_fbe_fifo_out;    
    assign tlp6_lbe                            =  tlp6_len_fifo_out[1:0]==2'h1 ? '0                                    : tlp6_lbe_fifo_out;    
    assign tlp7_fbe                            =  tlp7_len_fifo_out[1:0]==2'h1 ? tlp7_lbe_fifo_out | tlp7_fbe_fifo_out : tlp7_fbe_fifo_out;    
    assign tlp7_lbe                            =  tlp7_len_fifo_out[1:0]==2'h1 ? '0                                    : tlp7_lbe_fifo_out;    
    assign tlp8_fbe                            =  tlp8_len_fifo_out[1:0]==2'h1 ? tlp8_lbe_fifo_out | tlp8_fbe_fifo_out : tlp8_fbe_fifo_out;    
    assign tlp8_lbe                            =  tlp8_len_fifo_out[1:0]==2'h1 ? '0                                    : tlp8_lbe_fifo_out;    
    assign tlp1_len                            =  tlp1_len_fifo_out;       
    assign tlp2_len                            =  tlp2_len_fifo_out;     
    assign tlp3_len                            =  tlp3_len_fifo_out;     
    assign tlp4_len                            =  tlp4_len_fifo_out;     
    assign tlp5_len                            =  tlp5_len_fifo_out;     
    assign tlp6_len                            =  tlp6_len_fifo_out;     
    assign tlp7_len                            =  tlp7_len_fifo_out;     
    assign tlp8_len                            =  tlp8_len_fifo_out;     
    assign tlp1_address                        =  |tlp1_fbe_fifo_out ? tlp1_address_fifo_out : tlp1_address_fifo_out+4'h4;
    assign tlp2_address                        =  |tlp2_fbe_fifo_out ? tlp2_address_fifo_out : tlp2_address_fifo_out+4'h4;
    assign tlp3_address                        =  |tlp3_fbe_fifo_out ? tlp3_address_fifo_out : tlp3_address_fifo_out+4'h4;
    assign tlp4_address                        =  |tlp4_fbe_fifo_out ? tlp4_address_fifo_out : tlp4_address_fifo_out+4'h4;
    assign tlp5_address                        =  |tlp5_fbe_fifo_out ? tlp5_address_fifo_out : tlp5_address_fifo_out+4'h4;
    assign tlp6_address                        =  |tlp6_fbe_fifo_out ? tlp6_address_fifo_out : tlp6_address_fifo_out+4'h4;
    assign tlp7_address                        =  |tlp7_fbe_fifo_out ? tlp7_address_fifo_out : tlp7_address_fifo_out+4'h4;
    assign tlp8_address                        =  |tlp8_fbe_fifo_out ? tlp8_address_fifo_out : tlp8_address_fifo_out+4'h4;
    assign tlp1_data                           =  |tlp1_fbe_fifo_out ? tlp_data_fifo_out[63:0]    : {32'h0,tlp_data_fifo_out[63:32]};
    assign tlp2_data                           =  |tlp2_fbe_fifo_out ? tlp_data_fifo_out[127:64]  : {32'h0,tlp_data_fifo_out[127:96]};
    assign tlp3_data                           =  |tlp3_fbe_fifo_out ? tlp_data_fifo_out[191:128] : {32'h0,tlp_data_fifo_out[191:160]};
    assign tlp4_data                           =  |tlp4_fbe_fifo_out ? tlp_data_fifo_out[255:192] : {32'h0,tlp_data_fifo_out[255:224]};
    assign tlp5_data                           =  |tlp5_fbe_fifo_out ? tlp_data_fifo_out[319:256] : {32'h0,tlp_data_fifo_out[319:288]};
    assign tlp6_data                           =  |tlp6_fbe_fifo_out ? tlp_data_fifo_out[383:320] : {32'h0,tlp_data_fifo_out[383:352]};
    assign tlp7_data                           =  |tlp7_fbe_fifo_out ? tlp_data_fifo_out[447:384] : {32'h0,tlp_data_fifo_out[447:416]};
    assign tlp8_data                           =  |tlp8_fbe_fifo_out ? tlp_data_fifo_out[511:448] : {32'h0,tlp_data_fifo_out[511:480]};
    assign tlp_2to8                            =  tlp_2to8_fifo_out;    
    assign tlp_3to8                            =  tlp_3to8_fifo_out;    
    assign tlp_4to8                            =  tlp_4to8_fifo_out;    
    assign tlp_5to8                            =  tlp_5to8_fifo_out;    
    assign tlp_6to8                            =  tlp_6to8_fifo_out;    
    assign tlp_7to8                            =  tlp_7to8_fifo_out;    
    assign tlp_8                               =  tlp_8_fifo_out;       
    assign tlp1_valid                          =  tlp1_valid_fifo_out;  
    assign tlp2_valid                          =  tlp2_valid_fifo_out;  
    assign tlp3_valid                          =  tlp3_valid_fifo_out;  
    assign tlp4_valid                          =  tlp4_valid_fifo_out;  
    assign tlp5_valid                          =  tlp5_valid_fifo_out;  
    assign tlp6_valid                          =  tlp6_valid_fifo_out;  
    assign tlp7_valid                          =  tlp7_valid_fifo_out;  
    assign tlp8_valid                          =  tlp8_valid_fifo_out;  

    scfifo axi_wr_tlp 
      (
        .clock         (clk                          ),
        .data          (axi_wr_tlp_fifo_wr_data      ),
        .rdreq         (axi_wr_tlp_fifo_rdreq        ),
        .wrreq         (write_tlp_header_data_valid  ),
        .q             (axi_wr_tlp_fifo_rd_data      ),
        .empty         (axi_wr_tlp_fifo_empty        ),
        .sclr          (!rst                         ),
        .usedw         (                             ),
        .aclr          (1'b0                         ),
        .full          (axi_wr_tlp_fifo_full         ),
        .almost_full   (axi_wr_tlp_fifo_almost_full  ),
        .almost_empty  (                             ),
        .eccstatus     (                             ));
    defparam
      axi_wr_tlp.add_ram_output_register  = "ON",
      axi_wr_tlp.enable_ecc  = "FALSE",
      axi_wr_tlp.intended_device_family  = "Agilex",
      axi_wr_tlp.lpm_hint  = "RAM_BLOCK_TYPE=M20K",
      axi_wr_tlp.lpm_numwords  = 8,
      axi_wr_tlp.lpm_showahead  = "OFF",
      axi_wr_tlp.lpm_type  = "scfifo",
      axi_wr_tlp.lpm_width  = 660,
      axi_wr_tlp.lpm_widthu  = 3,
      axi_wr_tlp.overflow_checking  = "ON",
      axi_wr_tlp.underflow_checking  = "ON",
      axi_wr_tlp.almost_full_value = 4,
      axi_wr_tlp.use_eab  = "ON";

    //fsm for sending wr tlps
    always_ff@(posedge clk)
    begin
        if(!rst) wr_tlp_state <= 4'hF;
        else
        case(wr_tlp_state)
            0 : begin
                        wr_tlp_state     <= 4'hF; //goto default
                        axi_wr_tlp_fifo_rdreq <= 1'b0; 
            end
            1 : begin
                        wr_tlp_state          <= 4'h2;
                        axi_wr_tlp_fifo_rdreq <= 1'b0; 
            end
            2 : begin
                        wr_tlp_state     <= 4'h3;
            end
            3 : begin
                        wr_tlp_state     <= 4'h4;
            end
            4 : begin
                        wr_tlp_state     <= 4'h5;
            end
            5 : begin
                        wr_tlp_state     <= 4'h6;
            end
            6 : begin
                        wr_tlp_state     <= 4'h7;
            end
            7 : begin
                        wr_tlp_state     <= 4'h8;
            end
            8 : begin
                        wr_tlp_state     <= 4'hF;
            end
            9 : begin //zero strobe
                        wr_tlp_state     <= 4'hF; //goto default
                        axi_wr_tlp_fifo_rdreq <= 1'b0; 
            end
          'hA : begin
                        wr_tlp_state     <= 4'hB; 
                        axi_wr_tlp_fifo_rdreq  <= 1'h0; 
            end
          'hB : begin
                        axi_wr_tlp_fifo_rdreq  <= 1'h0; 
                        if (axi_write_zero_strobe_txn_ff && p_credits_available ) wr_tlp_state  <= 4'h9; //zero strobe
                        else if(axi_write_split_txn_ff &&  wr_tlp_fifo_empty) wr_tlp_state  <= 4'h1;     //split strobe
                        else if(!axi_write_split_txn_ff && p_credits_available ) wr_tlp_state  <= 4'h0;  //full strobe
                        else wr_tlp_state  <= 4'hB; //stay here
            end
            default : begin
                           if(p_credits_available && !axi_wr_tlp_fifo_empty) begin
                               axi_wr_tlp_fifo_rdreq  <= 1'h1; 
                               wr_tlp_state <= 4'hA;
                           end
                           else begin
                               axi_wr_tlp_fifo_rdreq  <= 1'h0;
                               wr_tlp_state <= 4'hF;
                           end
            end
        endcase
    end


    always_comb
    begin
        case(wr_tlp_state)
            0 : begin
                tlp_fbe_sel      = tlp1_fbe;
                tlp_lbe_sel      = tlp8_lbe;
                tlp_len_sel      = 10'h10;//tlp_len_fifo_out;
                tlp_address_sel  = tlp_address_fifo_out;
                tlp_tag_sel      = tlp_tag_fifo_out;
                tlp_data_sel     = tlp_data_fifo_out;
                tlp_last         = 1'b1;
                tlp_sop_sel      = 1'b1;
            end
            1 : begin
                    if(tlp1_valid) begin
                        tlp_fbe_sel      = tlp1_fbe;
                        tlp_lbe_sel      = tlp1_lbe;
                        tlp_len_sel      = tlp1_len;
                        tlp_address_sel  = tlp1_address;
                        tlp_tag_sel      = tlp_tag_fifo_out;
                        tlp_sop_sel      = 1'b1;
                        tlp_data_sel     = {448'h0,tlp1_data};
                    end
                    else begin
                        tlp_fbe_sel      = '0;
                        tlp_lbe_sel      = '0;
                        tlp_len_sel      = '0;
                        tlp_address_sel  = '0;
                        tlp_tag_sel      = '0;
                        tlp_sop_sel      = '0;
                        tlp_data_sel     = '0;
                    end
                    if(tlp_2to8) tlp_last    = 1'b0;
                    else         tlp_last    = 1'b1;
            end
            2 : begin
                    if(tlp2_valid) begin
                        tlp_fbe_sel      = tlp2_fbe;
                        tlp_lbe_sel      = tlp2_lbe;
                        tlp_len_sel      = tlp2_len;
                        tlp_address_sel  = tlp2_address;
                        tlp_tag_sel      = tlp_tag_fifo_out;
                        tlp_sop_sel      = 1'b1;
                        tlp_data_sel     = {448'h0,tlp2_data};
                    end
                    else begin
                        tlp_fbe_sel      = '0;
                        tlp_lbe_sel      = '0;
                        tlp_len_sel      = '0;
                        tlp_address_sel  = '0;
                        tlp_tag_sel      = '0;
                        tlp_sop_sel      = '0;
                        tlp_data_sel     = '0;
                    end
                    if(tlp_3to8) tlp_last    = 1'b0;
                    else         tlp_last    = 1'b1;
            end
            3 : begin
                    if(tlp3_valid) begin
                        tlp_fbe_sel      = tlp3_fbe;
                        tlp_lbe_sel      = tlp3_lbe;
                        tlp_len_sel      = tlp3_len;
                        tlp_address_sel  = tlp3_address;
                        tlp_tag_sel      = tlp_tag_fifo_out;
                        tlp_sop_sel      = 1'b1;
                        tlp_data_sel     = {448'h0,tlp3_data};
                    end
                    else begin
                        tlp_fbe_sel      = '0;
                        tlp_lbe_sel      = '0;
                        tlp_len_sel      = '0;
                        tlp_address_sel  = '0;
                        tlp_tag_sel      = '0;
                        tlp_sop_sel      = '0;
                        tlp_data_sel     = '0;
                    end
                    if(tlp_4to8) tlp_last    = 1'b0;
                    else         tlp_last    = 1'b1;
            end
            4 : begin
                    if(tlp4_valid) begin
                        tlp_fbe_sel      = tlp4_fbe;
                        tlp_lbe_sel      = tlp4_lbe;
                        tlp_len_sel      = tlp4_len;
                        tlp_address_sel  = tlp4_address;
                        tlp_tag_sel      = tlp_tag_fifo_out;
                        tlp_sop_sel      = 1'b1;
                        tlp_data_sel     = {448'h0,tlp4_data};
                    end
                    else begin
                        tlp_fbe_sel      = '0;
                        tlp_lbe_sel      = '0;
                        tlp_len_sel      = '0;
                        tlp_address_sel  = '0;
                        tlp_tag_sel      = '0;
                        tlp_sop_sel      = '0;
                        tlp_data_sel     = '0;
                    end
                    if(tlp_5to8) tlp_last    = 1'b0;
                    else         tlp_last    = 1'b1;
            end
            5 : begin
                    if(tlp5_valid) begin
                        tlp_fbe_sel      = tlp5_fbe;
                        tlp_lbe_sel      = tlp5_lbe;
                        tlp_len_sel      = tlp5_len;
                        tlp_address_sel  = tlp5_address;
                        tlp_tag_sel      = tlp_tag_fifo_out;
                        tlp_sop_sel      = 1'b1;
                        tlp_data_sel     = {448'h0,tlp5_data};
                    end
                    else begin
                        tlp_fbe_sel      = '0;
                        tlp_lbe_sel      = '0;
                        tlp_len_sel      = '0;
                        tlp_address_sel  = '0;
                        tlp_tag_sel      = '0;
                        tlp_sop_sel      = '0;
                        tlp_data_sel     = '0;
                    end
                    if(tlp_6to8) tlp_last    = 1'b0;
                    else         tlp_last    = 1'b1;
            end
            6 : begin
                    if(tlp6_valid) begin
                        tlp_fbe_sel      = tlp6_fbe;
                        tlp_lbe_sel      = tlp6_lbe;
                        tlp_len_sel      = tlp6_len;
                        tlp_address_sel  = tlp6_address;
                        tlp_tag_sel      = tlp_tag_fifo_out;
                        tlp_sop_sel      = 1'b1;
                        tlp_data_sel     = {448'h0,tlp6_data};
                    end
                    else begin
                        tlp_fbe_sel      = '0;
                        tlp_lbe_sel      = '0;
                        tlp_len_sel      = '0;
                        tlp_address_sel  = '0;
                        tlp_tag_sel      = '0;
                        tlp_sop_sel      = '0;
                        tlp_data_sel     = '0;
                    end
                    if(tlp_7to8) tlp_last    = 1'b0;
                    else         tlp_last    = 1'b1;
            end
            7 : begin
                    if(tlp7_valid) begin
                        tlp_fbe_sel      = tlp7_fbe;
                        tlp_lbe_sel      = tlp7_lbe;
                        tlp_len_sel      = tlp7_len;
                        tlp_address_sel  = tlp7_address;
                        tlp_tag_sel      = tlp_tag_fifo_out;
                        tlp_sop_sel      = 1'b1;
                        tlp_data_sel     = {448'h0,tlp7_data};
                    end
                    else begin
                        tlp_fbe_sel      = '0;
                        tlp_lbe_sel      = '0;
                        tlp_len_sel      = '0;
                        tlp_address_sel  = '0;
                        tlp_tag_sel      = '0;
                        tlp_sop_sel      = '0;
                        tlp_data_sel     = '0;
                    end
                    if(tlp_8) tlp_last    = 1'b0;
                    else      tlp_last    = 1'b1;
            end
            8 : begin
                    if(tlp8_valid) begin
                        tlp_fbe_sel      = tlp8_fbe;
                        tlp_lbe_sel      = tlp8_lbe;
                        tlp_len_sel      = tlp8_len;
                        tlp_address_sel  = tlp8_address;
                        tlp_tag_sel      = tlp_tag_fifo_out;
                        tlp_sop_sel      = 1'b1;
                        tlp_data_sel     = {448'h0,tlp8_data};
                    end
                    else begin
                        tlp_fbe_sel      = '0;
                        tlp_lbe_sel      = '0;
                        tlp_len_sel      = '0;
                        tlp_address_sel  = '0;
                        tlp_tag_sel      = '0;
                        tlp_sop_sel      = '0;
                        tlp_data_sel     = '0;
                    end
                    tlp_last    = 1'b1;
            end
            9 : begin
                tlp_fbe_sel      = '0;
                tlp_lbe_sel      = '0;
                tlp_len_sel      = 10'h1;//10'h10;//tlp_len_fifo_out;
                tlp_address_sel  = tlp_address_fifo_out;
                tlp_tag_sel      = tlp_tag_fifo_out;
                tlp_data_sel     = tlp_data_fifo_out;
                tlp_last         = 1'b1;
                tlp_sop_sel      = 1'b1;
            end
            default : begin
                        tlp_fbe_sel      = '0;
                        tlp_lbe_sel      = '0;
                        tlp_len_sel      = '0;
                        tlp_address_sel  = '0;
                        tlp_tag_sel      = '0;
                        tlp_sop_sel      = '0;
                        tlp_data_sel     = '0;
                        tlp_last         = '0;
            end
        endcase
    end

    always_ff@(posedge clk)
    begin
        if(!rst) begin
            tlp_len_sel_p      <=  '0;
            tlp_tag_sel_p      <=  '0;
            tlp_data_sel_p     <=  '0;
            tlp_sop_sel_p      <=  '0;
            tlp_fbe_sel_p      <=  '0;
            tlp_lbe_sel_p      <=  '0;
            tlp_address_sel_p  <=  '0;
            tlp_last_p         <=  '0;
            tlp_len_sel_f      <=  '0;
            tlp_tag_sel_f      <=  '0;
            tlp_data_sel_f     <=  '0;
            tlp_sop_sel_f      <=  '0;
            tlp_fbe_sel_f      <=  '0;
            tlp_lbe_sel_f      <=  '0;
            tlp_address_sel_f  <=  '0;
            tlp_last_f         <=  '0;
        end
        else begin
            tlp_len_sel_p      <=  tlp_len_sel;
            tlp_tag_sel_p      <=  tlp_tag_sel;
            tlp_data_sel_p     <=  tlp_data_sel;
            tlp_sop_sel_p      <=  tlp_sop_sel;
            tlp_fbe_sel_p      <=  tlp_fbe_sel;
            tlp_lbe_sel_p      <=  tlp_lbe_sel;
            tlp_address_sel_p  <=  tlp_address_sel;
            tlp_last_p         <=  tlp_last;
            tlp_len_sel_f      <=  tlp_len_sel_p;
            tlp_tag_sel_f      <=  tlp_tag_sel_p;
            tlp_data_sel_f     <=  tlp_data_sel_p;
            tlp_sop_sel_f      <=  tlp_sop_sel_p;
            tlp_fbe_sel_f      <=  tlp_fbe_sel_p;
            tlp_lbe_sel_f      <=  tlp_lbe_sel_p;
            tlp_address_sel_f  <=  tlp_address_sel_p;
            tlp_last_f         <=  tlp_last_p;
        end
    end

   //end 

   //axi_write_resp_channel
   always_ff @(posedge clk) begin : BRESP_FIFOIN  
       if (!rst) begin
           axi_b_din <= '0; 
       end else begin
           axi_b_din.bvalid        <= p_tlp_sent_tag_valid;//write_tlp_header_data_valid; 
           axi_b_din.bresp         <= eresp_OKAY;     //write tlp is posted so considering success                   
           axi_b_din.bid           <= p_tlp_sent_tag;//write_tlp_header_tag_ff;
       end
   end   
   
   assign wr_rsp_buf_not_empty = ~wr_rsp_buf_empty;
   always_ff@(posedge clk) wr_rsp_buf_empty_f <= wr_rsp_buf_empty;

    scfifo axi_wr_rsp_fifo 
      (
       .clock            (clk                 ),
       .data             (axi_b_din ),
       .rdreq            (wr_rsp_buf_ren ),
       .wrreq            (axi_b_din.bvalid  ),
       .q                (axi_b_dout  ),
       .empty            (wr_rsp_buf_empty  ),
       .sclr             (!rst            ),
       .usedw            (),
       .aclr             (1'b0              ),
       .full             (wr_rsp_buf_full  ),
       .almost_full      (wr_rsp_buf_almost_full),
       .almost_empty     (),
       .eccstatus       ());
    defparam
      axi_wr_rsp_fifo.add_ram_output_register  = "ON",
      axi_wr_rsp_fifo.enable_ecc  = "FALSE",
      axi_wr_rsp_fifo.intended_device_family  = "Agilex",
      axi_wr_rsp_fifo.lpm_hint  = "RAM_BLOCK_TYPE=M20K",
      axi_wr_rsp_fifo.lpm_numwords  = 8,
      axi_wr_rsp_fifo.lpm_showahead  = "OFF",
      axi_wr_rsp_fifo.lpm_type  = "scfifo",
      axi_wr_rsp_fifo.lpm_width  = $bits(t_axi4_wr_resp_ch),
      axi_wr_rsp_fifo.lpm_widthu  = 3,
      axi_wr_rsp_fifo.almost_full_value = 5,
      axi_wr_rsp_fifo.overflow_checking  = "ON",
      axi_wr_rsp_fifo.underflow_checking  = "ON",
      axi_wr_rsp_fifo.use_eab  = "ON";

   //drive axi_b write response our of buffer, up to master
   always_ff @(posedge clk) begin : BRESP_FIFOOUT
       if (!rst) begin
           axi_b            <= '0;           
       end else begin
           
           if (wr_rsp_buf_ren_f) begin    
               axi_b.bvalid <= axi_b_dout.bvalid;
           end else if (wr_rsp_buf_not_empty == 0 && (axi_bready && axi_b.bvalid)) begin //effectively done - nothing more and master has accepted the current txn
               axi_b.bvalid <= 0;
           end
           
           if (wr_rsp_buf_ren_f) begin
               axi_b.bid    <= axi_b_dout.bid; 
               axi_b.bresp  <= axi_b_dout.bresp;
               axi_b.buser  <= axi_b_dout.buser;
           end 
           
       end 
   end 
   
function [9:0] tlp_len (input t_axi4_burst_size_encoding axi_size);
begin
    case(axi_size) 
        esize_128          :  tlp_len = 10'b00_0000_0100 ;
        esize_256          :  tlp_len = 10'b00_0000_1000 ;
        esize_512          :  tlp_len = 10'b00_0001_0000 ;
        esize_1024         :  tlp_len = 10'b00_0010_0000 ;
        default            :  tlp_len = 10'b00_0000_0000 ;
    endcase
end
endfunction


//-- tlp formation - write request  
localparam Mem_Wr_tlp_4DW = 8'b0110_0000;
localparam Mem_Rd_tlp_4DW = 8'b0010_0000;
localparam Mem_Wr_tlp_3DW = 8'b0100_0000;
localparam Mem_Rd_tlp_3DW = 8'b0000_0000;
logic [15:0] requester_id;
assign requester_id = {bus_number,device_number,function_number} ;
assign write_tlp_end_address = tlp_address_sel_f + tlp_len_sel_f; //calculate end address of tlp
assign write_tlp_3DW = ~|(write_tlp_end_address[63:32]) ; // find all 0's in MSB

assign write_tlp_hdr_1dw = write_tlp_3DW ? {Mem_Wr_tlp_3DW,tlp_tag_sel_f[9],3'h0,tlp_tag_sel_f[8],9'h0,tlp_len_sel_f}  : {Mem_Wr_tlp_4DW,tlp_tag_sel_f[9],3'h0,tlp_tag_sel_f[8],9'h0,tlp_len_sel_f};
assign write_tlp_hdr_2dw = {requester_id,tlp_tag_sel_f[7:0],tlp_lbe_sel_f,tlp_fbe_sel_f}; 
assign write_tlp_hdr_3dw = write_tlp_3DW ? {tlp_address_sel_f[31:2],2'b00} : tlp_address_sel_f[63:32];  
assign write_tlp_hdr_4dw = write_tlp_3DW ? 32'b0 : {tlp_address_sel_f[31:2],2'b00};

assign  write_tlp_header = {write_tlp_hdr_1dw,write_tlp_hdr_2dw,write_tlp_hdr_3dw,write_tlp_hdr_4dw};

assign  wr_sop           =  tlp_sop_sel_f;
assign  wr_hvalid        =  tlp_sop_sel_f;
assign  wr_dvalid        =  axi_write_zero_strobe_txn_ff? 1'b0 : tlp_sop_sel_f;
assign  wr_data          =  tlp_data_sel_f;
assign  wr_hdr           =  {write_tlp_hdr_1dw,write_tlp_hdr_2dw,write_tlp_hdr_3dw,write_tlp_hdr_4dw};
assign  wr_eop           =  tlp_sop_sel_f;
assign  wr_last          =  tlp_last_f;
//--

//-- tlp formation - read request 
	     
assign read_tlp_3DW = ~|(read_tlp_end_address[63:32]);  // should request using 3DW type when address is less than 4GB
assign read_tlp_hdr_1dw = read_tlp_3DW ? {Mem_Rd_tlp_3DW,read_tlp_header_tag[9],3'h0,read_tlp_header_tag[8],9'h0,read_tlp_header_length}  : {Mem_Rd_tlp_4DW,read_tlp_header_tag[9],3'h0,read_tlp_header_tag[8],9'h0,read_tlp_header_length};
assign read_tlp_hdr_2dw = {requester_id,read_tlp_header_tag[7:0],8'hFF};
assign read_tlp_hdr_3dw = read_tlp_3DW ? {read_tlp_header_address[31:2],2'b00}  : read_tlp_header_address[63:32];
assign read_tlp_hdr_4dw = read_tlp_3DW ? 32'b0  : {read_tlp_header_address[31:2],2'b00};


assign  rd_sop        =  read_tlp_header_valid;                                                                              
assign  rd_hvalid     =  read_tlp_header_valid;                                                                              
assign  rd_dvalid     =  1'h0;                                                                                               
assign  rd_data       =  256'h0;                                                                                             
assign  rd_hdr        =  {read_tlp_hdr_1dw,read_tlp_hdr_2dw,read_tlp_hdr_3dw,read_tlp_hdr_4dw};                              
assign  rd_eop        =  read_tlp_header_valid;                                                                              

// read comes after write afu 
// simultaenouly write and read req will not come from AFU
assign  tx_st_sop     =  wr_sop  ?  wr_sop     :  rd_sop     ;
assign  tx_st_hvalid  =  wr_sop  ?  wr_hvalid  :  rd_hvalid  ;
assign  tx_st_dvalid  =  wr_sop  ?  wr_dvalid  :  rd_dvalid  ;
assign  tx_st_data    =  wr_sop  ?  wr_data    :  rd_data    ;
assign  tx_st_hdr     =  wr_sop  ?  wr_hdr     :  rd_hdr     ;
assign  tx_st_eop     =  wr_sop  ?  wr_eop     :  rd_eop     ;

endmodule 
