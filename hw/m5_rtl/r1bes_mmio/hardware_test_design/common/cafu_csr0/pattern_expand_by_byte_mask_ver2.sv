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

/*  Page 602 of CXL 2.0 Spec
*/

module pattern_expand_by_byte_mask_ver2
#(
    parameter CACHELINE_WIDTH =  (64*8)
)
(
   input logic [63:0]          byte_mask_reg_in,
   input logic [2:0]           pattern_size_reg_in,
   input logic [31:0]          pattern32_in,
   input logic [15:0]          pattern16_in,
   input logic [7:0]           pattern8_in,

   output logic [CACHELINE_WIDTH-1:0]   pattern_out
);

localparam NUMBER_REPETITIONS_32 = CACHELINE_WIDTH / 32;
localparam NUMBER_REPETITIONS_16 = CACHELINE_WIDTH / 16;
localparam NUMBER_REPETITIONS_8  = CACHELINE_WIDTH / 8;

logic [CACHELINE_WIDTH-1:0] expanded_pattern_to_use;
    

always_comb
begin
  case( pattern_size_reg_in )
    3'd4 :      expanded_pattern_to_use = {NUMBER_REPETITIONS_32{pattern32_in}};
    3'd2 :      expanded_pattern_to_use = {NUMBER_REPETITIONS_16{pattern16_in}};
    3'd1 :      expanded_pattern_to_use = {NUMBER_REPETITIONS_8{pattern8_in}};
    default :   expanded_pattern_to_use = 'd0;
  endcase
end




generate
genvar gi;
    for(gi = 0; gi < 64; gi = gi + 1 )
    begin : gen_pattern_out
      assign pattern_out[((8*gi)+7):(8*gi)] = (byte_mask_reg_in[gi] == 1'b1) ? expanded_pattern_to_use[((8*gi)+7):(8*gi)] : 8'd0;
    end
endgenerate




endmodule


