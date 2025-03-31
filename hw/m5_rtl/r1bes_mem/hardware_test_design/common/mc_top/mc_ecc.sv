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

module mc_ecc 
#(
parameter  MC_ECC_EN             = 1, // 0 - OFF; 1 - ON
parameter  MC_ECC_ENC_LATENCY    = 0, // supported option 0 and 1; (latency in emif_usr_clk cycles)
parameter  MC_ECC_DEC_LATENCY    = 1, // supported option 1 and 2; (latency in emif_usr_clk cycles)
parameter  AVMM_ADDR_WIDTH       = 27,
parameter  AVMM_S_DATA_WIDTH     = 512,

// == localparam ==
// ==== ALTECC ====
localparam ALTECC_DATAWORD_WIDTH = 64,
localparam ALTECC_CODEWORD_WIDTH = 72,
localparam ALTECC_INST_NUMBER    = AVMM_S_DATA_WIDTH / ALTECC_DATAWORD_WIDTH,

localparam AVMM_M_DATA_WIDTH     = ALTECC_INST_NUMBER * ALTECC_CODEWORD_WIDTH,
localparam AVMM_SYMBOL_WIDTH     = 8,
localparam AVMM_S_BE_WIDTH       = AVMM_S_DATA_WIDTH / AVMM_SYMBOL_WIDTH,
localparam AVMM_M_BE_WIDTH       = AVMM_M_DATA_WIDTH / AVMM_SYMBOL_WIDTH
)
(
input  logic                          clk                     ,
input  logic                          reset_n                 ,

output logic                          avmm_s_ready            ,
input  logic                          avmm_s_read             ,
input  logic                          avmm_s_write            ,
input  logic                          avmm_s_write_poison     ,
input  logic                          avmm_s_write_ras_sbe    ,
input  logic                          avmm_s_write_ras_dbe    ,
input  logic [AVMM_ADDR_WIDTH-1:0]    avmm_s_address          ,
output logic [AVMM_S_DATA_WIDTH-1:0]  avmm_s_readdata         ,
input  logic [AVMM_S_DATA_WIDTH-1:0]  avmm_s_writedata        ,
input  logic [AVMM_S_BE_WIDTH-1:0]    avmm_s_byteenable       ,
output logic                          avmm_s_read_poison      ,
output logic                          avmm_s_readdatavalid    ,
// Error Correction Code (ECC)
// Note *ecc_err_* are valid when avmm_s_readdatavalid is active
//output logic [ALTECC_INST_NUMBER-1:0] avmm_s_ecc_err_corrected,
//output logic [ALTECC_INST_NUMBER-1:0] avmm_s_ecc_err_detected ,
//output logic [ALTECC_INST_NUMBER-1:0] avmm_s_ecc_err_fatal    ,
//output logic [ALTECC_INST_NUMBER-1:0] avmm_s_ecc_err_syn_e    ,

input logic [ALTECC_INST_NUMBER-1:0] avmm_s_ecc_err_fatal    ,

input  logic                          avmm_m_ready            ,
output logic                          avmm_m_read             ,
output logic                          avmm_m_write            ,
output logic [AVMM_ADDR_WIDTH-1:0]    avmm_m_address          ,
output logic [AVMM_M_DATA_WIDTH-1:0]  avmm_m_writedata        ,
output logic [AVMM_M_BE_WIDTH-1:0]    avmm_m_byteenable       ,
input  logic [AVMM_M_DATA_WIDTH-1:0]  avmm_m_readdata         ,
input  logic                          avmm_m_readdatavalid    ,

  input  logic [AVMM_M_DATA_WIDTH-1:0]  in_avmm_s_writedata_w_ecc ,
  input  logic [AVMM_S_DATA_WIDTH-1:0]  in_avmm_s_readdata 

);

logic [MC_ECC_DEC_LATENCY-1:0] shift_rg_avmm_m_readdatavalid;
logic [AVMM_M_DATA_WIDTH-1:0]  avmm_s_writedata_w_ecc;
logic [AVMM_M_DATA_WIDTH-1:0]  avmm_s_writedata_w_ecc_n_poison;


  assign avmm_s_writedata_w_ecc = in_avmm_s_writedata_w_ecc;
  assign avmm_s_readdata        = in_avmm_s_readdata;



generate
   for(genvar i=0; i < ALTECC_INST_NUMBER; i=i+1) 
   begin: ECC_ENC_INST

     // altecc_enc_latency0 altecc_enc_inst (
     //    .data (avmm_s_writedata[i*ALTECC_DATAWORD_WIDTH +: ALTECC_DATAWORD_WIDTH]), //   input,  width = 64, data.data
     //    .q    (avmm_s_writedata_w_ecc[i*ALTECC_CODEWORD_WIDTH +: ALTECC_CODEWORD_WIDTH])     //  output,  width = 72,    q.q
     // );

      // == invert/corrupt 2 ECC parity bits in case avmm_s_write_poison is set
      // This will lead to err_fatal being set on decoder side and hence to avmm_s_read_poison bit set.
      // Note cuorrupting ECC parity bits instead of data bits has benefit of keeping data as is.
      // Note that it is not recommended to invert/corrupt MSB ECC parity bit as it has longest logic depth
      // (depends on all data bits and all other ECC parity bits) ==
      always_comb begin
         avmm_s_writedata_w_ecc_n_poison[i*ALTECC_CODEWORD_WIDTH +: ALTECC_CODEWORD_WIDTH]
            = avmm_s_writedata_w_ecc[i*ALTECC_CODEWORD_WIDTH +: ALTECC_CODEWORD_WIDTH];
          
         if (avmm_s_write_poison) begin
            avmm_s_writedata_w_ecc_n_poison[(i+1)*ALTECC_CODEWORD_WIDTH-1 -1]
                  = !avmm_s_writedata_w_ecc[(i+1)*ALTECC_CODEWORD_WIDTH-1 -1];
            avmm_s_writedata_w_ecc_n_poison[(i+1)*ALTECC_CODEWORD_WIDTH-1 -2]
                  = !avmm_s_writedata_w_ecc[(i+1)*ALTECC_CODEWORD_WIDTH-1 -2];
         end
         
         //RAS injection, single error injection so always use data group0 for simplicity (e.g. i=0)
         else if (i==0) begin
             if (avmm_s_write_ras_dbe) begin
                 avmm_s_writedata_w_ecc_n_poison[(i+1)*ALTECC_CODEWORD_WIDTH-1 -1]
                       = !avmm_s_writedata_w_ecc[(i+1)*ALTECC_CODEWORD_WIDTH-1 -1];
                 avmm_s_writedata_w_ecc_n_poison[(i+1)*ALTECC_CODEWORD_WIDTH-1 -2]
                       = !avmm_s_writedata_w_ecc[(i+1)*ALTECC_CODEWORD_WIDTH-1 -2];                 
             end else if (avmm_s_write_ras_sbe) begin
                 avmm_s_writedata_w_ecc_n_poison[(i+1)*ALTECC_CODEWORD_WIDTH-1 -2]
                       = !avmm_s_writedata_w_ecc[(i+1)*ALTECC_CODEWORD_WIDTH-1 -2];                 
             end 
         end //data group0
         
      end

   end

   if (MC_ECC_ENC_LATENCY == 0) begin : ecc_enc_latency_0

      always_comb begin
         avmm_m_read      = avmm_s_read;
         avmm_m_write     = avmm_s_write;
         avmm_m_address   = avmm_s_address;
         avmm_m_writedata = avmm_s_writedata_w_ecc_n_poison;
      end

   end
   else if (MC_ECC_ENC_LATENCY == 1) begin : ecc_enc_latency_1

      always_ff @(posedge clk) begin
         if (avmm_m_ready | ~reset_n) begin
            avmm_m_read      <= avmm_s_read;
            avmm_m_write     <= avmm_s_write;
            avmm_m_address   <= avmm_s_address;
            avmm_m_writedata <= avmm_s_writedata_w_ecc_n_poison;
         end
      end

   end

   if (MC_ECC_DEC_LATENCY == 1) 
   begin : ecc_dec_latency_1
//
//      for(genvar i=0; i < ALTECC_INST_NUMBER; i=i+1) begin: ECC_DEC_INST
//         altecc_dec_latency1 altecc_dec_inst (
//            .data          (avmm_m_readdata[i*ALTECC_CODEWORD_WIDTH +: ALTECC_CODEWORD_WIDTH]),  //   input,  width = 72,  data.data
//            .q             (avmm_s_readdata[i*ALTECC_DATAWORD_WIDTH +: ALTECC_DATAWORD_WIDTH]),  //  output,  width = 64,   q.q
//            .err_corrected (avmm_s_ecc_err_corrected[i]), //  output,   width = 1, err_corrected.err_corrected
//            .err_detected  (avmm_s_ecc_err_detected[i] ), //  output,   width = 1,  err_detected.err_detected
//            .err_fatal     (avmm_s_ecc_err_fatal[i]    ), //  output,   width = 1,     err_fatal.err_fatal
//            .syn_e         (avmm_s_ecc_err_syn_e[i]    ), //  output,   width = 1,         syn_e.syn_e
//            .clock         (clk                        )  //   input,   width = 1,         clock.clock
//         );
//      end
//
      always_ff @(posedge clk) begin
         shift_rg_avmm_m_readdatavalid <= avmm_m_readdatavalid;
      end

   end
   else if (MC_ECC_DEC_LATENCY == 2) 
   begin : ecc_dec_latency_2
//
//      for(genvar i=0; i < ALTECC_INST_NUMBER; i=i+1) begin: ECC_DEC_INST
//         altecc_dec_latency2 altecc_dec_inst (
//            .data          (avmm_m_readdata[i*ALTECC_CODEWORD_WIDTH +: ALTECC_CODEWORD_WIDTH]), //   input,  width = 72,   data.data
//            .q             (avmm_s_readdata[i*ALTECC_DATAWORD_WIDTH +: ALTECC_DATAWORD_WIDTH]), //  output,  width = 64,       q.q
//            .err_corrected (avmm_s_ecc_err_corrected[i]), //  output,   width = 1, err_corrected.err_corrected
//            .err_detected  (avmm_s_ecc_err_detected[i] ), //  output,   width = 1,  err_detected.err_detected
//            .err_fatal     (avmm_s_ecc_err_fatal[i]    ), //  output,   width = 1,     err_fatal.err_fatal
//            .syn_e         (avmm_s_ecc_err_syn_e[i]    ), //  output,   width = 1,         syn_e.syn_e
//            .clock         (clk                        )  //   input,   width = 1,         clock.clock
//         );
//      end
//
      always_ff @(posedge clk) begin
         shift_rg_avmm_m_readdatavalid <= {shift_rg_avmm_m_readdatavalid[MC_ECC_DEC_LATENCY-2:0],avmm_m_readdatavalid};
      end

   end

endgenerate

always_comb begin
   avmm_m_byteenable       = '1;

   avmm_s_ready            = avmm_m_ready;
   // == releaded to read response ==
   avmm_s_read_poison      = (avmm_s_ecc_err_fatal != 0);
   avmm_s_readdatavalid    = shift_rg_avmm_m_readdatavalid[MC_ECC_DEC_LATENCY-1];
end

endmodule
