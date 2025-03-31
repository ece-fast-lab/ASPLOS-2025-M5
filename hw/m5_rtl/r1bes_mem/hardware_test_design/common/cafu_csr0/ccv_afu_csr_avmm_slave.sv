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
import rtlgen_pkg_v12::*;

module ccv_afu_csr_avmm_slave(
 
// AVMM Slave Interface
input                 clk, //125MHz AVMM
input                 reset_n, //125MHz AVMM 
input                 rtl_clk, //IP CLK
input                 rtl_rstn,//IP RST 
input         [63:0]  writedata,
input                 poison,
input                 read,
input                 write,
input         [7:0]   byteenable,
output  logic [63:0]  readdata,
output  logic         readdatavalid,
input         [21:0]  address,
output  logic         waitrequest,

output  logic         doe_poisoned_wr_err, 
//Target Register Access Interface
output         rtlgen_pkg_v12::cfg_req_64bit_t treg_req,
input          rtlgen_pkg_v12::cfg_ack_64bit_t treg_ack

);
enum int unsigned { IDLE = 0, REQ = 2, ACK = 4 } state, next_state;

localparam DOE_CFG_REG_START_ADDR = 22'h20_0F40;
localparam DOE_CFG_REG_END_ADDR   = 22'h20_0F54;

logic [3:0]  treg_opcode;
logic [47:0] treg_address;
logic [7:0]  treg_be;
logic [63:0] treg_data;
logic        data_valid;
logic        data_wait  ;
logic        unaligned_addr;


//DOE POISONED Write , Write data dropped and Setting the DOE ERROR Bit 
logic doe_poisoned_wr_err_i ;
logic doe_poisoned_wr_err_d ;
logic doe_poisoned_wr_err_sync_d ;
logic doe_poisoned_wr_err_sync ;
assign doe_poisoned_wr_err_i = waitrequest && write && ((address >= DOE_CFG_REG_START_ADDR) && (address <= DOE_CFG_REG_END_ADDR)) && poison;

always @(posedge clk) begin
  if(~reset_n) begin
    doe_poisoned_wr_err_d <= 1'b0;
  end
  else begin
    doe_poisoned_wr_err_d  <= doe_poisoned_wr_err_i;
  end 
end

altera_std_synchronizer_nocut #(.rst_value(0)
                               )      
doe_poisoned_wr_err_sync_inst (                        
            .clk (rtl_clk),         
            .reset_n (rtl_rstn),    
            .din (doe_poisoned_wr_err_d),
            .dout(doe_poisoned_wr_err_sync)       
        ); 

always @(posedge rtl_clk) begin
  if(~rtl_rstn) begin
    doe_poisoned_wr_err_sync_d <= 1'b0;
  end
  else begin
    doe_poisoned_wr_err_sync_d  <= doe_poisoned_wr_err_sync;
  end 
end

assign doe_poisoned_wr_err = doe_poisoned_wr_err_sync & ~doe_poisoned_wr_err_sync_d;

always_comb begin : next_state_logic
   next_state = IDLE;
      case(state)
      IDLE    : begin 
                   if( write | read) begin
                     if(poison) begin 
                       next_state = ACK;
                     end
                     else begin
                       next_state = REQ;
                     end 
                   end
                   else begin
                       next_state = IDLE;
                   end 
                end
      REQ     : begin
                   if (treg_ack.read_valid | treg_ack.write_valid) begin
                      next_state = ACK;
                   end
                   else begin
                      next_state = REQ;
                   end 
                end 
      ACK     : begin
                   next_state = IDLE;
                end
      default : next_state = IDLE;
   endcase
end




always_comb begin
   case(state)
   IDLE    : begin
               data_valid  = 1'b0;
               data_wait   = 1'b1;
               
             end
   REQ     : begin 
               data_valid  = 1'b1;
               data_wait   = 1'b1; 
             end
   ACK     : begin 
               data_valid  = 1'b0;
               data_wait   = 1'b0; 
             end
   default : begin 
                data_valid = 1'b0;
                data_wait  = 1'b1;
             end
   endcase
end

always_ff@(posedge clk) begin
   if(~reset_n)
      state <= IDLE;
   else
      state <= next_state;
end

always_ff@(posedge clk) begin
   if(~reset_n) begin
      treg_opcode    <= 4'h0;
      treg_address   <= 32'h0;
      treg_be        <= 8'h0;
      treg_data      <= 64'h0;
      readdata       <= 64'h0;
      readdatavalid  <= 1'b0;
   end
   else begin
      treg_opcode    <= {1'b0,address[21],1'b0,write};
      //treg_address   <= {27'd0,address[20:0]};
      //treg_be        <=  byteenable[7:0];
      //treg_data      <=  writedata;
      //readdata       <= treg_ack.data;
      readdatavalid  <= treg_ack.read_valid;
      if(unaligned_addr) begin
         treg_address   <= ({27'd0,address[20:0]} + 48'h4);
         treg_be        <= {4'h0,byteenable[7:4]};
         treg_data      <= {32'h0,writedata[63:32]};
         readdata       <= {treg_ack.data[31:0],32'h0};
      end
      else begin
         treg_address   <= {27'd0,address[20:0]};
         treg_be        <= byteenable[7:0];
         treg_data      <= writedata;
         readdata       <= treg_ack.data;
      end
   end
end

assign unaligned_addr   = (|byteenable[7:4]) && (byteenable[3:0]== 4'h0); 
assign treg_req.valid   = data_valid;
assign treg_req.addr    = treg_address;
assign treg_req.be      = treg_be;
assign treg_req.bar     = 3'd0;
assign treg_req.fid     = 8'd0;
assign treg_req.opcode  = rtlgen_pkg_v12::cfg_opcode_t'(treg_opcode);

assign treg_req.sai     = 8'h3f;
assign treg_req.data    = treg_data;
assign waitrequest = data_wait;

endmodule
