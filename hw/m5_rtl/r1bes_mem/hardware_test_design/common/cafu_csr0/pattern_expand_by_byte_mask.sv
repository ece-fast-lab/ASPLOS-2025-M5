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

module pattern_expand_by_byte_mask
#(
    parameter CACHELINE_WIDTH =  (64*8)
)
(
   input logic [63:0]          byte_mask_reg_in,
   input logic [31:0]          pattern_in,

   output logic [CACHELINE_WIDTH-1:0]   pattern_out
);

localparam NUMBER_REPETITIONS = CACHELINE_WIDTH / 32;


logic [CACHELINE_WIDTH-1:0] expanded_pattern_to_use;
    

always_comb
begin
  expanded_pattern_to_use = {NUMBER_REPETITIONS{pattern_in}};
end

/*  need to go byte by byte (7:0, 15:8, ....)
*/

/*            runSample sv unit test keeps saing gi is a constant ?!?!?!?!
genvar gi;

always_comb
begin
    for(gi = 0; gi < 64; gi = gi + 1 )
    begin
      pattern_out[((8*gi)+7):(8*gi)] = (byte_mask_reg_in[gi] == 1'b1) ? expanded_pattern_to_use[((8*gi)+7):(8*gi)] : 8'd0;
    end
end
*/

generate
genvar gi;
    for(gi = 0; gi < 64; gi = gi + 1 )
    begin : gen_pattern_out
      assign pattern_out[((8*gi)+7):(8*gi)] = (byte_mask_reg_in[gi] == 1'b1) ? expanded_pattern_to_use[((8*gi)+7):(8*gi)] : 8'd0;
    end
endgenerate



/*
always_comb
begin
  pattern_out[511:504] = (byte_mask_reg_in[63] == 1'b1) ? expanded_pattern_to_use[511:504] : 8'd0;
  pattern_out[503:496] = (byte_mask_reg_in[62] == 1'b1) ? expanded_pattern_to_use[503:496] : 8'd0;
  pattern_out[495:488] = (byte_mask_reg_in[61] == 1'b1) ? expanded_pattern_to_use[495:488] : 8'd0;
  pattern_out[487:480] = (byte_mask_reg_in[60] == 1'b1) ? expanded_pattern_to_use[487:480] : 8'd0;
  pattern_out[479:472] = (byte_mask_reg_in[59] == 1'b1) ? expanded_pattern_to_use[479:472] : 8'd0;
  pattern_out[471:464] = (byte_mask_reg_in[58] == 1'b1) ? expanded_pattern_to_use[471:464] : 8'd0;
  pattern_out[463:456] = (byte_mask_reg_in[57] == 1'b1) ? expanded_pattern_to_use[463:456] : 8'd0;
  pattern_out[455:448] = (byte_mask_reg_in[56] == 1'b1) ? expanded_pattern_to_use[455:448] : 8'd0;
  pattern_out[447:440] = (byte_mask_reg_in[55] == 1'b1) ? expanded_pattern_to_use[447:440] : 8'd0;
  pattern_out[439:432] = (byte_mask_reg_in[54] == 1'b1) ? expanded_pattern_to_use[439:432] : 8'd0;
  pattern_out[431:424] = (byte_mask_reg_in[53] == 1'b1) ? expanded_pattern_to_use[431:424] : 8'd0;
  pattern_out[423:416] = (byte_mask_reg_in[52] == 1'b1) ? expanded_pattern_to_use[423:416] : 8'd0;
  pattern_out[415:408] = (byte_mask_reg_in[51] == 1'b1) ? expanded_pattern_to_use[415:408] : 8'd0;
  pattern_out[407:400] = (byte_mask_reg_in[50] == 1'b1) ? expanded_pattern_to_use[407:400] : 8'd0;
  pattern_out[399:392] = (byte_mask_reg_in[49] == 1'b1) ? expanded_pattern_to_use[399:392] : 8'd0;
  pattern_out[391:384] = (byte_mask_reg_in[48] == 1'b1) ? expanded_pattern_to_use[391:384] : 8'd0;
  pattern_out[383:376] = (byte_mask_reg_in[47] == 1'b1) ? expanded_pattern_to_use[383:376] : 8'd0;
  pattern_out[375:368] = (byte_mask_reg_in[46] == 1'b1) ? expanded_pattern_to_use[375:368] : 8'd0;
  pattern_out[367:360] = (byte_mask_reg_in[45] == 1'b1) ? expanded_pattern_to_use[367:360] : 8'd0;
  pattern_out[359:352] = (byte_mask_reg_in[44] == 1'b1) ? expanded_pattern_to_use[359:352] : 8'd0;
  pattern_out[351:344] = (byte_mask_reg_in[43] == 1'b1) ? expanded_pattern_to_use[351:344] : 8'd0;
  pattern_out[343:336] = (byte_mask_reg_in[42] == 1'b1) ? expanded_pattern_to_use[343:336] : 8'd0;
  pattern_out[335:328] = (byte_mask_reg_in[41] == 1'b1) ? expanded_pattern_to_use[335:328] : 8'd0;
  pattern_out[327:320] = (byte_mask_reg_in[40] == 1'b1) ? expanded_pattern_to_use[327:320] : 8'd0;
  pattern_out[319:312] = (byte_mask_reg_in[39] == 1'b1) ? expanded_pattern_to_use[319:312] : 8'd0;
  pattern_out[311:304] = (byte_mask_reg_in[38] == 1'b1) ? expanded_pattern_to_use[311:304] : 8'd0;
  pattern_out[303:296] = (byte_mask_reg_in[37] == 1'b1) ? expanded_pattern_to_use[303:296] : 8'd0;
  pattern_out[295:288] = (byte_mask_reg_in[36] == 1'b1) ? expanded_pattern_to_use[295:288] : 8'd0;
  pattern_out[287:280] = (byte_mask_reg_in[35] == 1'b1) ? expanded_pattern_to_use[287:280] : 8'd0;
  pattern_out[279:272] = (byte_mask_reg_in[34] == 1'b1) ? expanded_pattern_to_use[279:272] : 8'd0;
  pattern_out[271:264] = (byte_mask_reg_in[33] == 1'b1) ? expanded_pattern_to_use[271:264] : 8'd0;
  pattern_out[263:256] = (byte_mask_reg_in[32] == 1'b1) ? expanded_pattern_to_use[263:256] : 8'd0;
  pattern_out[255:248] = (byte_mask_reg_in[31] == 1'b1) ? expanded_pattern_to_use[255:248] : 8'd0;
  pattern_out[247:240] = (byte_mask_reg_in[30] == 1'b1) ? expanded_pattern_to_use[247:240] : 8'd0;
  pattern_out[239:232] = (byte_mask_reg_in[29] == 1'b1) ? expanded_pattern_to_use[239:232] : 8'd0;
  pattern_out[231:224] = (byte_mask_reg_in[28] == 1'b1) ? expanded_pattern_to_use[231:224] : 8'd0;
  pattern_out[223:216] = (byte_mask_reg_in[27] == 1'b1) ? expanded_pattern_to_use[223:216] : 8'd0;
  pattern_out[215:208] = (byte_mask_reg_in[26] == 1'b1) ? expanded_pattern_to_use[215:208] : 8'd0;
  pattern_out[207:200] = (byte_mask_reg_in[25] == 1'b1) ? expanded_pattern_to_use[207:200] : 8'd0;
  pattern_out[199:192] = (byte_mask_reg_in[24] == 1'b1) ? expanded_pattern_to_use[199:192] : 8'd0;
  pattern_out[191:184] = (byte_mask_reg_in[23] == 1'b1) ? expanded_pattern_to_use[191:184] : 8'd0;
  pattern_out[183:176] = (byte_mask_reg_in[22] == 1'b1) ? expanded_pattern_to_use[183:176] : 8'd0;
  pattern_out[175:168] = (byte_mask_reg_in[21] == 1'b1) ? expanded_pattern_to_use[175:168] : 8'd0;
  pattern_out[167:160] = (byte_mask_reg_in[20] == 1'b1) ? expanded_pattern_to_use[167:160] : 8'd0;
  pattern_out[159:152] = (byte_mask_reg_in[19] == 1'b1) ? expanded_pattern_to_use[159:152] : 8'd0;
  pattern_out[151:144] = (byte_mask_reg_in[18] == 1'b1) ? expanded_pattern_to_use[151:144] : 8'd0;
  pattern_out[143:136] = (byte_mask_reg_in[17] == 1'b1) ? expanded_pattern_to_use[143:136] : 8'd0;
  pattern_out[135:128] = (byte_mask_reg_in[16] == 1'b1) ? expanded_pattern_to_use[135:128] : 8'd0;
  pattern_out[127:120] = (byte_mask_reg_in[15] == 1'b1) ? expanded_pattern_to_use[127:120] : 8'd0;
  pattern_out[119:112] = (byte_mask_reg_in[14] == 1'b1) ? expanded_pattern_to_use[119:112] : 8'd0;
  pattern_out[111:104] = (byte_mask_reg_in[13] == 1'b1) ? expanded_pattern_to_use[111:104] : 8'd0;
  pattern_out[103:96]  = (byte_mask_reg_in[12] == 1'b1) ? expanded_pattern_to_use[103:96]  : 8'd0;
  pattern_out[95:88]   = (byte_mask_reg_in[11] == 1'b1) ? expanded_pattern_to_use[95:88]   : 8'd0;
  pattern_out[87:80]   = (byte_mask_reg_in[10] == 1'b1) ? expanded_pattern_to_use[87:80]   : 8'd0;
  pattern_out[79:72]   = (byte_mask_reg_in[9]  == 1'b1) ? expanded_pattern_to_use[79:72]   : 8'd0;
  pattern_out[71:64]   = (byte_mask_reg_in[8]  == 1'b1) ? expanded_pattern_to_use[71:64]   : 8'd0;
  pattern_out[63:56]   = (byte_mask_reg_in[7]  == 1'b1) ? expanded_pattern_to_use[63:56]   : 8'd0;
  pattern_out[55:48]   = (byte_mask_reg_in[6]  == 1'b1) ? expanded_pattern_to_use[55:48]   : 8'd0;
  pattern_out[47:40]   = (byte_mask_reg_in[5]  == 1'b1) ? expanded_pattern_to_use[47:40]   : 8'd0;
  pattern_out[39:32]   = (byte_mask_reg_in[4]  == 1'b1) ? expanded_pattern_to_use[39:32]   : 8'd0;
  pattern_out[31:24]   = (byte_mask_reg_in[3]  == 1'b1) ? expanded_pattern_to_use[31:24]   : 8'd0;
  pattern_out[23:16]   = (byte_mask_reg_in[2]  == 1'b1) ? expanded_pattern_to_use[23:16]   : 8'd0;
  pattern_out[15:8]    = (byte_mask_reg_in[1]  == 1'b1) ? expanded_pattern_to_use[15:8]    : 8'd0;
  pattern_out[7:0]     = (byte_mask_reg_in[0]  == 1'b1) ? expanded_pattern_to_use[7:0]     : 8'd0;
end
*/




endmodule


