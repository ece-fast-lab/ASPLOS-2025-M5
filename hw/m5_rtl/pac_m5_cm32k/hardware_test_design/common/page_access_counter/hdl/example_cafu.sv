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


// Copyright 2022 Intel Corporation.
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
///////////////////////////////////////////////////////////////////////
/*                COHERENCE-COMPLIANCE VALIDATION AFU

  Description   : FPGA CXL Compliance Engine Initiator AFU
                  Speaks to the AXI-to-CCIP+ translator.
                  This afu is the initiatior
                  The axi-to-ccip+ is the responder

  initial -> 07/12/2022 -> Antony Mathew
*/


module cust_afu_wrapper
(
      // Clocks
  input logic  axi4_mm_clk, 

    // Resets
  input logic  axi4_mm_rst_n,
  
  // [harry] AVMM interface - imported from ex_default_csr_top
  input  logic        csr_avmm_clk,
  input  logic        csr_avmm_rstn,  
  output logic        csr_avmm_waitrequest,  
  output logic [63:0] csr_avmm_readdata,
  output logic        csr_avmm_readdatavalid,
  input  logic [63:0] csr_avmm_writedata,
  input  logic [21:0] csr_avmm_address,
  input  logic        csr_avmm_write,
  input  logic        csr_avmm_read, 
  input  logic [7:0]  csr_avmm_byteenable,

  /*
    AXI-MM interface - write address channel
  */
  output logic [11:0]               awid,   //not sure
  output logic [63:0]               awaddr, 
  output logic [9:0]                awlen,  //must tie to 10'd0
  output logic [2:0]                awsize, //must tie to 3'b110 (64B/T)
  output logic [1:0]                awburst,//must tie to 2'b00
  output logic [2:0]                awprot, //must tie to 3'b000
  output logic [3:0]                awqos,  //must tie to 4'b0000
  output logic [5:0]                awuser, //v1.2
  output logic                      awvalid,
  output logic [3:0]                awcache,//must tie to 4'b0000
  output logic [1:0]                awlock, //must tie to 2'b00
  output logic [3:0]                awregion, //must tie to 4'b0000
   input                            awready,
  
  /*
    AXI-MM interface - write data channel
  */
  output logic [511:0]              wdata,
  output logic [(512/8)-1:0]        wstrb,
  output logic                      wlast,
  output logic                      wuser,  //not sure
  output logic                      wvalid,
 // output logic [7:0]                wid,
   input                            wready,
  
  /*
    AXI-MM interface - write response channel
  */ 
   input [11:0]                     bid,  //not sure
   input [1:0]                      bresp,  //2'b00: OKAY, 2'b01: EXOKAY, 2'b10: SLVERR
   input [3:0]                      buser,  //must tie to 4'b0000
   input                            bvalid,
  output logic                      bready,
  
  /*
    AXI-MM interface - read address channel
  */
  output logic [11:0]               arid, //not sure
  output logic [63:0]               araddr,
  output logic [9:0]                arlen,  //must tie to 10'd0
  output logic [2:0]                arsize, //must tie to 3'b110
  output logic [1:0]                arburst,  //must tie to 2'b00
  output logic [2:0]                arprot, //must tie to 3'b000
  output logic [3:0]                arqos,  //must tie to 4'b0000
  output logic [5:0]                aruser, //4'b0000": non-cacheable, 4'b0001: cacheable shared, 4'b0010: cachebale owned
  output logic                      arvalid,
  output logic [3:0]                arcache,  //must tie to 4'b0000
  output logic [1:0]                arlock, //must tie to 2'b00
  output logic [3:0]                arregion, //must tie to 4'b0000
   input                            arready,

  /*
    AXI-MM interface - read response channel
  */ 
   input [11:0]                     rid,  //not sure
   input [511:0]                    rdata,  
   input [1:0]                      rresp,  //2'b00: OKAY, 2'b01: EXOKAY, 2'b10: SLVERR
   input                            rlast,  
   input                            ruser,  //not sure
   input                            rvalid,
   output logic                     rready
  

   
);


// Tied to Zero for all inputs. USER Can Modify

//assign awready = 1'b0;
//assign wready  = 1'b0;
//assign arready = 1'b0;
//assign bid     = 16'h0;
//assign bresp   = 4'h0;  
//assign buser   = 4'h0;
//assign bvalid  = 1'b0;
//
//assign rid     = 16'h0; 
//assign rdata   = 512'h0;
//assign rresp   = 4'h0;
//assign rlast   = 1'b0;
//assign ruser   = 4'h0;
//assign rvalid  = 1'b0;


  assign  awid         = '0   ; //not sure
  //assign  awaddr       = '0   ; 
  assign  awlen        = '0   ;
  assign  awsize       = 3'b110   ; //must tie to 3'b110
  assign  awburst      = '0   ;
  assign  awprot       = '0   ;
  assign  awqos        = '0   ;
//  assign  awuser       = '0   ; //v1.2
  //assign  awvalid      = '0   ;
  assign  awcache      = '0   ;
  assign  awlock       = '0   ;
  assign  awregion     = '0   ;
  assign  wdata        = '1;    //all is 1
//  assign  wstrb        = '1   ; //v1.1 
//  assign  wlast        = '1   ; //v1.1
  assign  wuser        = '0   ; //set to not poison in v1.2
//  assign  wvalid       = '1   ; //v1.1
  assign  wid          = '0   ; //not sure
//  assign  bready       = '0   ;//v1.1
  assign  arid         = '0   ;
 //assign  araddr       = '0   ;
  assign  arlen        = '0   ;
  assign  arsize       = 3'b110   ;//must tie to 3'b110
  assign  arburst      = '0   ;
  assign  arprot       = '0   ;
  assign  arqos        = '0   ;
//  assign  aruser       = '0   ; //v1.2
  //assign  arvalid      = 1'b1   ; 
  assign  arcache      = '0   ;
  assign  arlock       = '0   ;
  assign  arregion     = '0   ;
  assign  rready       = 1'b1   ;//always high for some reason?

logic [63:0] func_type_out;   // function type selector
logic [63:0] page_addr_0_out; // base address for page 0
logic [63:0] delay_out; // store the delay result
logic [63:0] delay_out1; // store the delay result
logic [63:0] resp_out; //record the response of read/write
logic [63:0] test_case; 
/*
testcase: 
0: do nothing; 
1: read 64 times, non-cacheable; 
2: read same address, cacheable shared; 
3: write 64 times, non-cacheable; 
4: write same address, cache owned;
5: read HDM, host-biased, non-cacheable;
6: read HDM, device-biased, non-cacheable;
7: write HDM, host-biased, non-cacheable;
8: write HDM, device-biased, non-cacheable;
9: read host, non-cacheable;
10: write host, non-cacheable;
*/
logic [63:0] addr_offset;
logic [63:0] pre_test_case;

logic start_proc;
//CSR block
cust_afu_csr_avmm_slave cust_afu_csr_avmm_slave_inst(
    .clk          (csr_avmm_clk),
    .reset_n      (csr_avmm_rstn),
    .writedata    (csr_avmm_writedata),
    .read         (csr_avmm_read),
    .write        (csr_avmm_write),
    .byteenable   (csr_avmm_byteenable),
    .readdata     (csr_avmm_readdata),
    .readdatavalid(csr_avmm_readdatavalid),
    .address      (csr_avmm_address),
    .waitrequest  (csr_avmm_waitrequest),

    .o_start_proc  (start_proc),
    .func_type_out (func_type_out),   // not used in this module
    .page_addr_0_out(page_addr_0_out),
    .delay_out(delay_out),
    .delay_out1(delay_out1),
    .resp_out(resp_out),
    .test_case_out(test_case) //0: do nothing; 1: read 64 times; 2: read same address; 3: write 64 times; 4:write same addresss;
);

always_ff @(posedge axi4_mm_clk) begin
  pre_test_case <= test_case;
end

psedu_read_write psedu_read_write_inst(
    .axi4_mm_clk(axi4_mm_clk),
    .axi4_mm_rst_n(axi4_mm_rst_n),
    .test_case(test_case),
    .pre_test_case(pre_test_case),
    .start_proc(start_proc),
    .rvalid(rvalid),
    .rlast(rlast),
    .rresp(rresp),
    .arready(arready),
    .wready(wready),
    .awready(awready),
    .bvalid(bvalid),
    .bresp(bresp),
    .arvalid(arvalid),
    .aruser(aruser),
    .awvalid(awvalid),
    .awuser(awuser),
    .wvalid(wvalid),
    .wlast(wlast),
    .wstrb(wstrb),
    .bready(bready),
    .addr_offset(addr_offset),
    .resp_out(resp_out)
);

cal_delay cal_delay_inst(
  .clk(axi4_mm_clk),
  .reset_n(axi4_mm_rst_n),
  .m_axi_arvalid(arvalid), 
  .m_axi_rvalid(rvalid),
  .m_axi_awvalid(awvalid),
  .m_axi_wready(wready),
  .m_axi_bvalid(bvalid),
  .result(delay_out),
  .result1(delay_out1),
  .test_case(test_case),
  .pre_test_case(pre_test_case)
);

//addr = page + offset
always_comb begin
  araddr = page_addr_0_out + addr_offset;
  awaddr = page_addr_0_out + addr_offset;
end

endmodule


module prefetch_read_write (

    input logic axi4_mm_clk,
    input logic axi4_mm_rst_n,

    //control logic 
    //set PA of target cache line to page_addr_0
    input logic [63:0] page_addr_0,
    input logic start_proc,
    output logic end_proc,

    //ar channel
    input logic arready,
    output logic arvalid,
    output logic [63:0] araddr,
    output logic [11:0] arid,
    output logic [5:0] aruser,
    //rd channel
    output logic rready,
    input logic rvalid,
    input logic rlast,
    input logic [511:0] rdata,
    input logic [1:0] rresp,

    //aw channel
    input logic awready,
    output logic awvalid,
    output logic [63:0] awaddr,
    output logic [11:0] awid,
    output logic [5:0] awuser,
    //wr channel
    input logic wready,
    output logic wvalid,
    output logic [511:0] wdata,
    output logic wlast, 
    output logic [(512/8)-1:0] wstrb, 
    //b channel
    input logic bvalid,
    input logic [1:0] bresp,
    output logic bready
);

logic [511:0] rdata_reg;
logic [63:0] wr_counter;
logic [63:0] resp_counter;
logic [11:0] awid_reg; 
logic w_handshake;
logic aw_handshake;

enum logic [4:0] {
    STATE_RESET,
    STATE_RD_ADDR,
    STATE_RD_DATA,
    STATE_WR_SUB,
    STATE_WR_SUB_RESP
} state, next_state;

/*---------------------------------
functions
-----------------------------------*/
function void set_default();
    awvalid = 1'b0;
    wvalid = 1'b0;
    bready = 1'b0;
    arvalid = 1'b0;
    rready = 1'b0;
endfunction

always_ff @(posedge axi4_mm_clk) begin
    if (!axi4_mm_rst_n) begin
        state <= STATE_RESET;
        rdata_reg <= 64'b0;
    end
    else begin
        state <= next_state;
        unique case(state) 
            STATE_RD_DATA: begin
                if (rready & rvalid) begin
                    rdata_reg <= rdata;

                    aw_handshake <= 1'b0;
                    w_handshake <= 1'b0;

                    awid_reg <= 12'd10;
                    wr_counter <= 64'b0;
                    resp_counter <= 64'b0;
                end
            end

            STATE_WR_SUB: begin
                if (awvalid & awready) begin
                    aw_handshake <= 1'b1;
                end
                if (wvalid & wready) begin  // nc-p-write can start, otherwise wait 
                    w_handshake <= 1'b1;
                end
            end

            STATE_WR_SUB_RESP: begin
                if (bvalid & bready) begin  // nc-p-write done
                    aw_handshake <= 1'b0;
                    w_handshake <= 1'b0;
                    end_proc <= 1'b1;
                end
            end

            default: begin
                end_proc <= 1'b0;
            end
        endcase
    end
end




/*---------------------------------
FSM
-----------------------------------*/

always_comb begin
    unique case(state)
        STATE_RESET: begin
            if (start_proc) begin
                next_state = STATE_RD_ADDR;
            end
            else begin
                next_state = STATE_RESET;
            end
        end

        STATE_RD_ADDR: begin
            if (arready & arvalid) begin
                next_state = STATE_RD_DATA;
            end
            else begin
                next_state = STATE_RD_ADDR;
            end
        end

        STATE_RD_DATA: begin
            if (rready & rvalid) begin
                next_state = STATE_WR_SUB;
            end
            else begin
                next_state = STATE_RD_DATA;
            end
        end

        STATE_WR_SUB: begin
            if (awready & wready) begin
                next_state = STATE_WR_SUB_RESP;
            end
            else if (wvalid == 1'b0) begin
                if (awready) begin
                    next_state = STATE_WR_SUB_RESP;
                end
                else begin
                    next_state = STATE_WR_SUB;
                end
            end
            else if (awvalid == 1'b0) begin
                if (wready) begin
                    next_state = STATE_WR_SUB_RESP;
                end
                else begin
                    next_state = STATE_WR_SUB;
                end
            end
            else begin
                next_state = STATE_WR_SUB;
            end
        end

        STATE_WR_SUB_RESP: begin
            if (bvalid & bready) begin
                next_state = STATE_RESET; 
            end
            else begin
                next_state = STATE_WR_SUB_RESP;
            end
        end

        default: begin
            next_state = STATE_RESET;
        end
    endcase
end

always_comb begin
    set_default();
    unique case(state)
        STATE_RD_ADDR: begin
            arvalid = 1'b1;
            arid = 12'd2; // id can be any value within 2^12 as you want
            aruser = 6'b110000; //non-cacheable, device bias
            // aruser = 6'b100000; // may need to change to host bias 
            araddr = page_addr_0;
        end

        STATE_RD_DATA: begin
            rready = 1'b1;
        end

        STATE_WR_SUB: begin
            if (aw_handshake == 1'b0) begin
                awvalid = 1'b1;
            end
            else begin
                awvalid = 1'b0;
            end
            awid = 12'd2;
            awuser <= 6'b110010; //non-cacheable push, d2d, device bias
            awaddr = page_addr_0;

            if (w_handshake == 1'b0) begin
                wvalid = 1'b1;
            end
            else begin
                wvalid = 1'b0;
            end
            wdata = rdata_reg;  //finish one queue
            wlast = 1'b1;
            wstrb = 64'hffffffffffffffff;
        end

        STATE_WR_SUB_RESP: begin
            bready = 1'b1;
        end

        default: begin

        end
    endcase
end
    

endmodule