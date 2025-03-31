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

module verify_sc_index_byte_offset
(
    input                 clk,
    input                 reset_n,
    input [63:0]          compare_mask_in,
    input                 enable,          //error_found_in,
    output logic [5:0]    byte_offset_out
);

always_ff @( posedge clk )
begin
       if( reset_n == 1'b0 )                     byte_offset_out <= 'd0;
//  else if( error_found_in == 1'b0 )              byte_offset_out <= 'd0;
  else if( enable == 1'b0 )                      byte_offset_out <= byte_offset_out;
  else begin
         if( compare_mask_in[0] == 1'b1 )        byte_offset_out = 'd0;
    else if( compare_mask_in[1] == 1'b1 )        byte_offset_out = 'd1;
    else if( compare_mask_in[2] == 1'b1 )        byte_offset_out = 'd2;
    else if( compare_mask_in[3] == 1'b1 )        byte_offset_out = 'd3;
    else if( compare_mask_in[4] == 1'b1 )        byte_offset_out = 'd4;
    else if( compare_mask_in[5] == 1'b1 )        byte_offset_out = 'd5;
    else if( compare_mask_in[6] == 1'b1 )        byte_offset_out = 'd6;
    else if( compare_mask_in[7] == 1'b1 )        byte_offset_out = 'd7;
    else if( compare_mask_in[8] == 1'b1 )        byte_offset_out = 'd8;
    else if( compare_mask_in[9] == 1'b1 )        byte_offset_out = 'd9;
    else if( compare_mask_in[10] == 1'b1 )       byte_offset_out = 'd10;
    else if( compare_mask_in[11] == 1'b1 )       byte_offset_out = 'd11;
    else if( compare_mask_in[12] == 1'b1 )       byte_offset_out = 'd12;
    else if( compare_mask_in[13] == 1'b1 )       byte_offset_out = 'd13;
    else if( compare_mask_in[14] == 1'b1 )       byte_offset_out = 'd14;
    else if( compare_mask_in[15] == 1'b1 )       byte_offset_out = 'd15;
    else if( compare_mask_in[16] == 1'b1 )       byte_offset_out = 'd16;
    else if( compare_mask_in[17] == 1'b1 )       byte_offset_out = 'd17;
    else if( compare_mask_in[18] == 1'b1 )       byte_offset_out = 'd18;
    else if( compare_mask_in[19] == 1'b1 )       byte_offset_out = 'd19;
    else if( compare_mask_in[20] == 1'b1 )       byte_offset_out = 'd20;
    else if( compare_mask_in[21] == 1'b1 )       byte_offset_out = 'd21;
    else if( compare_mask_in[22] == 1'b1 )       byte_offset_out = 'd22;
    else if( compare_mask_in[23] == 1'b1 )       byte_offset_out = 'd23;
    else if( compare_mask_in[24] == 1'b1 )       byte_offset_out = 'd24;
    else if( compare_mask_in[25] == 1'b1 )       byte_offset_out = 'd25;
    else if( compare_mask_in[26] == 1'b1 )       byte_offset_out = 'd26;
    else if( compare_mask_in[27] == 1'b1 )       byte_offset_out = 'd27;
    else if( compare_mask_in[28] == 1'b1 )       byte_offset_out = 'd28;
    else if( compare_mask_in[29] == 1'b1 )       byte_offset_out = 'd29;
    else if( compare_mask_in[30] == 1'b1 )       byte_offset_out = 'd30;
    else if( compare_mask_in[31] == 1'b1 )       byte_offset_out = 'd31;
    else if( compare_mask_in[32] == 1'b1 )       byte_offset_out = 'd32;
    else if( compare_mask_in[33] == 1'b1 )       byte_offset_out = 'd33;
    else if( compare_mask_in[34] == 1'b1 )       byte_offset_out = 'd34;
    else if( compare_mask_in[35] == 1'b1 )       byte_offset_out = 'd35;
    else if( compare_mask_in[36] == 1'b1 )       byte_offset_out = 'd36;
    else if( compare_mask_in[37] == 1'b1 )       byte_offset_out = 'd37;
    else if( compare_mask_in[38] == 1'b1 )       byte_offset_out = 'd38;
    else if( compare_mask_in[39] == 1'b1 )       byte_offset_out = 'd39;
    else if( compare_mask_in[40] == 1'b1 )       byte_offset_out = 'd40;
    else if( compare_mask_in[41] == 1'b1 )       byte_offset_out = 'd41;
    else if( compare_mask_in[42] == 1'b1 )       byte_offset_out = 'd42;
    else if( compare_mask_in[43] == 1'b1 )       byte_offset_out = 'd43;
    else if( compare_mask_in[44] == 1'b1 )       byte_offset_out = 'd44;
    else if( compare_mask_in[45] == 1'b1 )       byte_offset_out = 'd45;
    else if( compare_mask_in[46] == 1'b1 )       byte_offset_out = 'd46;
    else if( compare_mask_in[47] == 1'b1 )       byte_offset_out = 'd47;
    else if( compare_mask_in[48] == 1'b1 )       byte_offset_out = 'd48;
    else if( compare_mask_in[49] == 1'b1 )       byte_offset_out = 'd49;
    else if( compare_mask_in[50] == 1'b1 )       byte_offset_out = 'd50;
    else if( compare_mask_in[51] == 1'b1 )       byte_offset_out = 'd51;
    else if( compare_mask_in[52] == 1'b1 )       byte_offset_out = 'd52;
    else if( compare_mask_in[53] == 1'b1 )       byte_offset_out = 'd53;
    else if( compare_mask_in[54] == 1'b1 )       byte_offset_out = 'd54;
    else if( compare_mask_in[55] == 1'b1 )       byte_offset_out = 'd55;
    else if( compare_mask_in[56] == 1'b1 )       byte_offset_out = 'd56;
    else if( compare_mask_in[57] == 1'b1 )       byte_offset_out = 'd57;
    else if( compare_mask_in[58] == 1'b1 )       byte_offset_out = 'd58;
    else if( compare_mask_in[59] == 1'b1 )       byte_offset_out = 'd59;
    else if( compare_mask_in[60] == 1'b1 )       byte_offset_out = 'd60;
    else if( compare_mask_in[61] == 1'b1 )       byte_offset_out = 'd61;
    else if( compare_mask_in[62] == 1'b1 )       byte_offset_out = 'd62;
    else if( compare_mask_in[63] == 1'b1 )       byte_offset_out = 'd63;
    else                                         byte_offset_out = 'd0;
  end
end
    
    
endmodule

