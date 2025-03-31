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




module afu_csr_avmm_slave(
 
// AVMM Slave Interface
   input               clk,
   input               reset_n,
   input  logic [31:0] writedata,
   input  logic        read,
   input  logic        write,
   input  logic [3:0]  byteenable,
   output logic [31:0] readdata,
   output logic        readdatavalid,
   input  logic [31:0] address,
   output logic        waitrequest
);


 logic [31:0] csr_test_reg;
 logic [31:0] mask ;

 assign mask[7:0]   = byteenable[0]? 8'hFF:8'h0; 
 assign mask[15:8]  = byteenable[1]? 8'hFF:8'h0; 
 assign mask[23:16] = byteenable[2]? 8'hFF:8'h0; 
 assign mask[31:24] = byteenable[3]? 8'hFF:8'h0; 
 
//Write logic
always @(posedge clk) begin
    if (!reset_n) begin
        csr_test_reg  <= 32'h0;
        
    end
    else begin
        if (write && (address == 32'h0)) begin 
           csr_test_reg <= writedata & mask;
        end
        else begin
           csr_test_reg <= csr_test_reg;
        end        
    end    
end 

//Read logic
always @(posedge clk) begin
    if (!reset_n) begin
        readdata  <= 32'h0;
    end
    else begin
        if (read && (address == 32'h0)) begin 
           readdata <= csr_test_reg & mask;
        end
        else begin
           readdata  <= 32'h0;
        end        
    end    
end 



//Control Logic
enum int unsigned { IDLE = 0,WRITE = 2, READ = 4 } state, next_state;

always_comb begin : next_state_logic
   next_state = IDLE;
      case(state)
      IDLE    : begin 
                   if( write ) begin
                       next_state = WRITE;
                   end
                   else begin
                     if (read) begin  
                       next_state = READ;
                     end
                     else begin
                       next_state = IDLE;
                     end
                   end 
                end
      WRITE     : begin
                   next_state = IDLE;
                end
      READ      : begin
                   next_state = IDLE;
                end
      default : next_state = IDLE;
   endcase
end


always_comb begin
   case(state)
   IDLE    : begin
               waitrequest  = 1'b1;
               readdatavalid= 1'b0;
             end
   WRITE     : begin 
               waitrequest  = 1'b0;
               readdatavalid= 1'b0;
             end
   READ     : begin 
               waitrequest  = 1'b0;
               readdatavalid= 1'b1;
             end
   default : begin 
               waitrequest  = 1'b1;
               readdatavalid= 1'b0;
             end
   endcase
end

always_ff@(posedge clk) begin
   if(~reset_n)
      state <= IDLE;
   else
      state <= next_state;
end

endmodule
