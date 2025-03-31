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



module intel_cxl_aer (
    input           clk,
    input           rst,

    //-- inputs from pf_checker
    input logic           rx_sop,
    input logic           rx_eop,
    input logic           rx_hvalid,
    input logic           rx_dvalid,
    input logic [127:0]   rx_header,
    input logic [255:0]   rx_data,
    input logic [31:0]    rx_prefix,
    input logic           rx_pvalid,

    //-- bus and device number from IP
    input logic [7:0]     rx_bus_number,
    input logic [4:0]     rx_device_number,

    //--indication that pio is about to send cpl
    input logic           pio_to_send_cpl,

    //-- outputs to pio
    output logic          no_err_rx_sop,
    output logic          no_err_rx_eop,
    output logic          no_err_rx_hvalid,
    output logic          no_err_rx_dvalid,
    output logic [127:0]  no_err_rx_header,
    output logic [255:0]  no_err_rx_data,

    //-- completer abort for NP request if deteted AER
    output logic          np_ca_rx_sop,
    output logic          np_ca_rx_eop,
    output logic          np_ca_rx_hvalid,
    output logic          np_ca_rx_dvalid,
    output logic [127:0]  np_ca_rx_header,
    output logic [255:0]  np_ca_rx_data,

    //-- aer signals to/from CXL-IP
    input  logic          app_err_ready,
    output logic          app_err_valid,
    output logic [31:0]   app_err_hdr,
    output logic [13:0]   app_err_info,
    output logic [2:0]    app_err_func_num  
);

// check if tlp is a MemWr and length is greater than 256bits and set AER
// if AER is set write (header + prefix) into fifo
// if app_err_ready is given by ip then send the stored data to IP which is
// forwarded towards Host

    logic           Mem_Wr_tlp;
    logic           Mem_Rd_tlp; 
    logic           AER_gen;
    logic           aer_fifo_wr_en;
    logic           aer_fifo_rd_en;
    logic           aer_fifo_rd_en_f;
    logic [2:0]     state;
    logic [139:0]   aer_fifo_din;
    logic [139:0]   aer_fifo_dout;
    logic [139:0]   aer_fifo_dout_f;
    logic           aer_fifo_empty;
    logic           aer_fifo_full;
    logic [2:0]     aer_fifo_count;
    logic [127:0]   rx_header_reorder;

    logic [31:0]    rx_b0_dw;          
    logic [31:0]    rx_b4_dw;          
    logic [31:0]    rx_b8_dw;          
    logic [31:0]    rx_b12_dw;          
    logic [31:0]    tx_b0_dw;          
    logic [31:0]    tx_b4_dw;          
    logic [31:0]    tx_b8_dw;          
    logic [31:0]    tx_b12_dw;          

    logic [7:0]     fmt_type;
    logic [9:0]     length;
    logic [15:0]    completer_id;
    logic [15:0]    requester_id;
    logic [2:0]     cpl_status;
    logic [11:0]    byte_count;
    logic [6:0]     lower_address;
    logic [9:0]     tag;
    logic [2:0]     attr;
    logic [2:0]     tc;

    logic           ca_fifo_wr_en;
    logic           ca_fifo_rd_en;
    logic           ca_fifo_rd_en_f;
    logic [127:0]   ca_fifo_din;
    logic [127:0]   ca_fifo_dout;
    logic [127:0]   ca_fifo_dout_f;
    logic           ca_fifo_empty;
    logic           ca_fifo_full;
    logic [2:0]     ca_fifo_count;

    logic           ca_sop;
    logic           ca_eop;
    logic           ca_hvalid;
    logic           ca_dvalid;
    logic [128:0]   ca_hdr;
    logic [255:0]   ca_data;

    logic [31:0]    rx_prefix_sel;

        

assign rx_prefix_sel = rx_pvalid ? rx_prefix : '0 ;
assign rx_header_reorder = {rx_header[31:0],rx_header[63:32],rx_header[95:64],rx_header[127:96]};
assign Mem_Wr_tlp = (rx_header_reorder[127:125]==3'b010 || rx_header_reorder[127:125]==3'b011) && (rx_header_reorder[124:120] == 5'h0);
assign Mem_Rd_tlp = (rx_header_reorder[127:125]==3'b000 || rx_header_reorder[127:125]==3'b001) && (rx_header_reorder[124:120] == 5'h0);
assign AER_gen = rx_header_reorder[105:96] > 'h8;
assign aer_fifo_wr_en = AER_gen & rx_hvalid ;
assign aer_fifo_din = {rx_prefix,rx_header_reorder};

//form CA tlp
assign rx_b0_dw  = rx_header_reorder[127:96]; 
assign rx_b4_dw  = rx_header_reorder[95:64]; 
assign rx_b8_dw  = rx_header_reorder[63:32]; 
assign rx_b12_dw = rx_header_reorder[31:0]; 

assign fmt_type = 8'hA;
assign length = 10'h0;
assign cpl_status = 3'b100;  //CA
assign tag = {rx_header_reorder[119],rx_header_reorder[115],rx_header_reorder[79:72]};
assign attr = {rx_header_reorder[114],rx_header_reorder[109:108]};
assign tc = rx_header_reorder[118:116];
assign completer_id = {rx_bus_number,rx_device_number,3'h0};   //--here we should write the {bus,device,func} numbers {8,5,3}
assign requester_id = rx_header_reorder[95:89];
assign byte_count = Mem_Rd_tlp ? ({2'h0,rx_header_reorder[105:96]} << 2) : 12'h4;  //if mem_rd, CA should send proper byte count
assign lower_address = (rx_header_reorder[127:120] == 8'h0)         ? {rx_header_reorder[39:35],2'h0}  :
                       (rx_header_reorder[127:120] == 8'b0010_0000) ? {rx_header_reorder[6:2],2'h0} :7'd0;

assign tx_b0_dw  = {fmt_type,tag[9],tc,tag[8],attr[2],4'h0,attr[1:0],2'h0,length};
assign tx_b4_dw  = {completer_id,cpl_status,1'b0,byte_count};
assign tx_b8_dw  = {requester_id,tag[7:0],1'b0,lower_address};
assign tx_b12_dw = 32'b0;
assign ca_sop    = rx_sop;
assign ca_eop    = rx_eop;
assign ca_hvalid = rx_hvalid;
assign ca_dvalid = 1'h0;
assign ca_hdr    = rx_hvalid ? {tx_b0_dw,tx_b4_dw,tx_b8_dw,tx_b12_dw}: '0;
assign ca_data   = 256'h0;
assign ca_fifo_rd_en = ~pio_to_send_cpl && ~ca_fifo_empty;
assign ca_fifo_wr_en = ca_hvalid & AER_gen & Mem_Rd_tlp;
assign ca_fifo_din = ca_hdr;

assign np_ca_rx_sop = ca_fifo_rd_en_f;
assign np_ca_rx_eop = ca_fifo_rd_en_f;
assign np_ca_rx_hvalid = ca_fifo_rd_en_f;
assign np_ca_rx_dvalid = '0;
assign np_ca_rx_header = ca_fifo_dout;
assign np_ca_rx_data = '0;


always_ff@(posedge clk) begin
    if(!rst) ca_fifo_rd_en_f    <= '0;
    else ca_fifo_rd_en_f        <= ca_fifo_rd_en;
end




// logic to send out AER    
//
// 0. wait for fifo output goto s1
// 1. wait for ready , if ready goto s2 else s1
// 2. send 1st 32bit goto s3
// 3. send 2nd 32bit goto s4
// 4. send 3rd 32bit goto s5
// 5. send 4th 32bit goto s6
// 6. send 5th 32bit goto default
// default: read from fifo if not empty and goto s0 else default


    always_ff@(posedge clk)
    begin
        if(!rst) begin
                app_err_valid       <= '0  ;
                app_err_hdr         <= '0  ;
                app_err_info        <= '0  ;
                app_err_func_num    <= '0  ;  
                aer_fifo_rd_en      <= '0  ;
                aer_fifo_dout_f     <= '0  ;
                state               <= 'h7 ;
        end
        else begin
            case(state)
            3'h0 :  begin
                        app_err_valid       <= '0  ;
                        app_err_hdr         <= '0  ;
                        app_err_info        <= '0  ;
                        app_err_func_num    <= '0  ;  
                        aer_fifo_rd_en      <= '0  ;
                        aer_fifo_dout_f     <= aer_fifo_dout  ;
                        state               <= 'h1 ;
                    end
            3'h1 :  begin
                        app_err_valid       <= '0  ;
                        app_err_hdr         <= '0  ;
                        app_err_info        <= '0  ;
                        app_err_func_num    <= '0  ;  
                        aer_fifo_rd_en      <= '0  ;
                        aer_fifo_dout_f     <= aer_fifo_dout_f ;
                        state               <= app_err_ready ? 3'h2 : 3'h1 ;
                    end
            3'h2 :  begin
                        app_err_valid       <= 3'h1 ;
                        app_err_hdr         <= aer_fifo_dout[127:96]  ;
                        app_err_info        <= 14'h1; //Malformed_tlp
                        app_err_func_num    <= 3'h1 ; //Funtion_1 
                        aer_fifo_rd_en      <= '0   ;
                        aer_fifo_dout_f     <= aer_fifo_dout ;
                        state               <= 3'h3 ;
                    end
            3'h3 :  begin
                        app_err_valid       <= 3'h0 ;
                        app_err_hdr         <= aer_fifo_dout[95:64]  ;
                        app_err_info        <= 14'h0; 
                        app_err_func_num    <= 3'h0 ;  
                        aer_fifo_rd_en      <= '0   ;
                        aer_fifo_dout_f     <= aer_fifo_dout_f ;
                        state               <= 3'h4 ;
                    end
            3'h4 :  begin
                        app_err_valid       <= 3'h0 ;
                        app_err_hdr         <= aer_fifo_dout[63:32]  ;
                        app_err_info        <= 14'h0; 
                        app_err_func_num    <= 3'h0 ;  
                        aer_fifo_rd_en      <= '0   ;
                        aer_fifo_dout_f     <= aer_fifo_dout_f ;
                        state               <= 3'h5 ;
                    end
            3'h5 :  begin
                        app_err_valid       <= 3'h0 ;
                        app_err_hdr         <= aer_fifo_dout[31:0]  ;
                        app_err_info        <= 14'h0; 
                        app_err_func_num    <= 3'h0 ;  
                        aer_fifo_rd_en      <= '0   ;
                        aer_fifo_dout_f     <= aer_fifo_dout_f ;
                        state               <= 3'h6 ;
                    end
            3'h6 :  begin
                        app_err_valid       <= 3'h0 ;
                        app_err_hdr         <= aer_fifo_dout[139:128]  ;
                        app_err_info        <= 14'h0; 
                        app_err_func_num    <= 3'h0 ;  
                        aer_fifo_rd_en      <= '0   ;
                        aer_fifo_dout_f     <= aer_fifo_dout_f ;
                        state               <= 3'h7 ; //goto defulat
                    end
            default:begin
                        app_err_valid       <= '0  ;
                        app_err_hdr         <= '0  ;
                        app_err_info        <= '0  ;
                        app_err_func_num    <= '0  ;  
                        aer_fifo_rd_en      <= aer_fifo_empty ? 1'h0 : 1'h1 ;
                        aer_fifo_dout_f     <= '0  ;
                        state               <= aer_fifo_empty ? 3'h7 : 3'h0 ;
                    end

            endcase
        end
    end //always_ff




    scfifo ca_fifo 
      (
            .clock         (clk             ),
            .data          (ca_fifo_din     ),
            .rdreq         (ca_fifo_rd_en   ),
            .wrreq         (ca_fifo_wr_en   ),
            .q             (ca_fifo_dout    ),
            .empty         (ca_fifo_empty   ),
            .sclr          (!rst            ),
            .usedw         (ca_fifo_count   ),
            .aclr          (1'b0            ),
            .full          (ca_fifo_full    ),
            .almost_full   (),              
            .almost_empty  (),              
            .eccstatus     ());             
    defparam
      ca_fifo.add_ram_output_register  = "ON",
      ca_fifo.enable_ecc  = "FALSE",
      ca_fifo.intended_device_family  = "Agilex 7",
      ca_fifo.lpm_hint  = "AUTO", 
      ca_fifo.lpm_numwords  = 8,
      ca_fifo.lpm_showahead  = "OFF",
      ca_fifo.lpm_type  = "scfifo",
      ca_fifo.lpm_width  = 128,
      ca_fifo.lpm_widthu  = 3,
      ca_fifo.overflow_checking  = "ON",
      ca_fifo.underflow_checking  = "ON",
      ca_fifo.use_eab  = "ON";


    scfifo aer_fifo 
      (
            .clock         (clk             ),
            .data          (aer_fifo_din    ),
            .rdreq         (aer_fifo_rd_en  ),
            .wrreq         (aer_fifo_wr_en  ),
            .q             (aer_fifo_dout   ),
            .empty         (aer_fifo_empty  ),
            .sclr          (!rst            ),
            .usedw         (aer_fifo_count  ),
            .aclr          (1'b0            ),
            .full          (aer_fifo_full   ),
            .almost_full   (),              
            .almost_empty  (),              
            .eccstatus     ());             
    defparam
      aer_fifo.add_ram_output_register  = "ON",
      aer_fifo.enable_ecc  = "FALSE",
      aer_fifo.intended_device_family  = "Agilex 7",
      aer_fifo.lpm_hint  = "AUTO", 
      aer_fifo.lpm_numwords  = 8,
      aer_fifo.lpm_showahead  = "OFF",
      aer_fifo.lpm_type  = "scfifo",
      aer_fifo.lpm_width  = 140,
      aer_fifo.lpm_widthu  = 3,
      aer_fifo.overflow_checking  = "ON",
      aer_fifo.underflow_checking  = "ON",
      aer_fifo.use_eab  = "ON";


//if no error is detected send outputs

    always_ff@(posedge clk)
    begin
        if(!rst) begin
                        no_err_rx_sop       <= '0;
                        no_err_rx_eop       <= '0;
                        no_err_rx_hvalid    <= '0;
                        no_err_rx_dvalid    <= '0;
                        no_err_rx_header    <= '0;
                        no_err_rx_data      <= '0;
        end
        else begin
                        no_err_rx_sop       <= AER_gen ? '0 : rx_sop    ;
                        no_err_rx_eop       <= AER_gen ? '0 : rx_eop    ;
                        no_err_rx_hvalid    <= AER_gen ? '0 : rx_hvalid ;
                        no_err_rx_dvalid    <= AER_gen ? '0 : rx_dvalid ;
                        no_err_rx_header    <= AER_gen ? '0 : rx_header ;
                        no_err_rx_data      <= AER_gen ? '0 : rx_data   ;
        end
    end //always_ff


endmodule
