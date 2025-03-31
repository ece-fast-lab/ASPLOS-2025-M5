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

module verify_sc_extract_error_pattern
(
    input           clk,
    input           reset_n,
    input [511:0]   data_in,
    input [63:0]    compare_mask_in,
    input [2:0]     pattern_size_reg_in,
//    input           error_found_in,
   input            enable_in,
  
    output logic [31:0]   first_error_pattern_out
);
    
logic [63:0] temp_error_pattern;

always_ff @( posedge clk )
begin
       if( reset_n == 1'b0 )                     temp_error_pattern <= 'd0;
//  else if( error_found_in == 1'b0 )              temp_error_pattern <= 'd0;
  else if( enable_in == 1'b0 )                   temp_error_pattern <= temp_error_pattern;
  else begin
         if( compare_mask_in[0] == 1'b1 )        temp_error_pattern <= data_in[31:0];
    else if( compare_mask_in[1] == 1'b1 )        temp_error_pattern <= data_in[31:0];
    else if( compare_mask_in[2] == 1'b1 )        temp_error_pattern <= data_in[31:0];
    else if( compare_mask_in[3] == 1'b1 )        temp_error_pattern <= data_in[31:0];
    else if( compare_mask_in[4] == 1'b1 )        temp_error_pattern <= data_in[63:32];
    else if( compare_mask_in[5] == 1'b1 )        temp_error_pattern <= data_in[63:32];
    else if( compare_mask_in[6] == 1'b1 )        temp_error_pattern <= data_in[63:32];
    else if( compare_mask_in[7] == 1'b1 )        temp_error_pattern <= data_in[63:32];
    else if( compare_mask_in[8] == 1'b1 )        temp_error_pattern <= data_in[95:64];
    else if( compare_mask_in[9] == 1'b1 )        temp_error_pattern <= data_in[95:64];
    else if( compare_mask_in[10] == 1'b1 )       temp_error_pattern <= data_in[95:64];
    else if( compare_mask_in[11] == 1'b1 )       temp_error_pattern <= data_in[95:64];
    else if( compare_mask_in[12] == 1'b1 )       temp_error_pattern <= data_in[127:96];
    else if( compare_mask_in[13] == 1'b1 )       temp_error_pattern <= data_in[127:96];
    else if( compare_mask_in[14] == 1'b1 )       temp_error_pattern <= data_in[127:96];
    else if( compare_mask_in[15] == 1'b1 )       temp_error_pattern <= data_in[127:96];
    else if( compare_mask_in[16] == 1'b1 )       temp_error_pattern <= data_in[159:128];
    else if( compare_mask_in[17] == 1'b1 )       temp_error_pattern <= data_in[159:128];
    else if( compare_mask_in[18] == 1'b1 )       temp_error_pattern <= data_in[159:128];
    else if( compare_mask_in[19] == 1'b1 )       temp_error_pattern <= data_in[159:128];
    else if( compare_mask_in[20] == 1'b1 )       temp_error_pattern <= data_in[191:160];
    else if( compare_mask_in[21] == 1'b1 )       temp_error_pattern <= data_in[191:160];
    else if( compare_mask_in[22] == 1'b1 )       temp_error_pattern <= data_in[191:160];
    else if( compare_mask_in[23] == 1'b1 )       temp_error_pattern <= data_in[191:160];
    else if( compare_mask_in[24] == 1'b1 )       temp_error_pattern <= data_in[223:192];
    else if( compare_mask_in[25] == 1'b1 )       temp_error_pattern <= data_in[223:192];
    else if( compare_mask_in[26] == 1'b1 )       temp_error_pattern <= data_in[223:192];
    else if( compare_mask_in[27] == 1'b1 )       temp_error_pattern <= data_in[223:192];
    else if( compare_mask_in[28] == 1'b1 )       temp_error_pattern <= data_in[255:224];
    else if( compare_mask_in[29] == 1'b1 )       temp_error_pattern <= data_in[255:224];
    else if( compare_mask_in[30] == 1'b1 )       temp_error_pattern <= data_in[255:224];
    else if( compare_mask_in[31] == 1'b1 )       temp_error_pattern <= data_in[255:224];
    else if( compare_mask_in[32] == 1'b1 )       temp_error_pattern <= data_in[287:256];
    else if( compare_mask_in[33] == 1'b1 )       temp_error_pattern <= data_in[287:256];
    else if( compare_mask_in[34] == 1'b1 )       temp_error_pattern <= data_in[287:256];
    else if( compare_mask_in[35] == 1'b1 )       temp_error_pattern <= data_in[287:256];
    else if( compare_mask_in[36] == 1'b1 )       temp_error_pattern <= data_in[319:288];
    else if( compare_mask_in[37] == 1'b1 )       temp_error_pattern <= data_in[319:288];
    else if( compare_mask_in[38] == 1'b1 )       temp_error_pattern <= data_in[319:288];
    else if( compare_mask_in[39] == 1'b1 )       temp_error_pattern <= data_in[319:288];
    else if( compare_mask_in[40] == 1'b1 )       temp_error_pattern <= data_in[351:320];
    else if( compare_mask_in[41] == 1'b1 )       temp_error_pattern <= data_in[351:320];
    else if( compare_mask_in[42] == 1'b1 )       temp_error_pattern <= data_in[351:320];
    else if( compare_mask_in[43] == 1'b1 )       temp_error_pattern <= data_in[351:320];
    else if( compare_mask_in[44] == 1'b1 )       temp_error_pattern <= data_in[383:352];
    else if( compare_mask_in[45] == 1'b1 )       temp_error_pattern <= data_in[383:352];
    else if( compare_mask_in[46] == 1'b1 )       temp_error_pattern <= data_in[383:352];
    else if( compare_mask_in[47] == 1'b1 )       temp_error_pattern <= data_in[383:352];
    else if( compare_mask_in[48] == 1'b1 )       temp_error_pattern <= data_in[415:382];
    else if( compare_mask_in[49] == 1'b1 )       temp_error_pattern <= data_in[415:382];
    else if( compare_mask_in[50] == 1'b1 )       temp_error_pattern <= data_in[415:382];
    else if( compare_mask_in[51] == 1'b1 )       temp_error_pattern <= data_in[415:382];
    else if( compare_mask_in[52] == 1'b1 )       temp_error_pattern <= data_in[447:416];
    else if( compare_mask_in[53] == 1'b1 )       temp_error_pattern <= data_in[447:416];
    else if( compare_mask_in[54] == 1'b1 )       temp_error_pattern <= data_in[447:416];
    else if( compare_mask_in[55] == 1'b1 )       temp_error_pattern <= data_in[447:416];
    else if( compare_mask_in[56] == 1'b1 )       temp_error_pattern <= data_in[479:448];
    else if( compare_mask_in[57] == 1'b1 )       temp_error_pattern <= data_in[479:448];
    else if( compare_mask_in[58] == 1'b1 )       temp_error_pattern <= data_in[479:448];
    else if( compare_mask_in[59] == 1'b1 )       temp_error_pattern <= data_in[479:448];
    else if( compare_mask_in[60] == 1'b1 )       temp_error_pattern <= data_in[511:480];
    else if( compare_mask_in[61] == 1'b1 )       temp_error_pattern <= data_in[511:480];
    else if( compare_mask_in[62] == 1'b1 )       temp_error_pattern <= data_in[511:480];
    else if( compare_mask_in[63] == 1'b1 )       temp_error_pattern <= data_in[511:480];
    else                                         temp_error_pattern <= 'd0;
  end
end



assign first_error_pattern_out = temp_error_pattern;
  
/*  
  case( pattern_size_reg_in )
      3'd0 :        first_error_pattern_out = 'd0;
      3'd1 :        first_error_pattern_out = {24'd0, temp_error_pattern[7:0]};
      3'd2 :        first_error_pattern_out = {16'd0, temp_error_pattern[15:0]};
      3'd3 :        first_error_pattern_out = {8'd0,  temp_error_pattern[23:0]};
      default :     first_error_pattern_out = temp_error_pattern;
  endcase
end
    */
    
endmodule

