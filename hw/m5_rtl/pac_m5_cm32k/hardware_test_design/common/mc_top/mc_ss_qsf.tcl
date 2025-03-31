# (C) 2001-2023 Intel Corporation. All rights reserved.
# Your use of Intel Corporation's design tools, logic functions and other 
# software and tools, and its AMPP partner logic functions, and any output 
# files from any of the foregoing (including device programming or simulation 
# files), and any associated documentation or information are expressly subject 
# to the terms and conditions of the Intel Program License Subscription 
# Agreement, Intel FPGA IP License Agreement, or other applicable 
# license agreement, including, without limitation, that your use is for the 
# sole purpose of programming logic devices manufactured by Intel and sold by 
# Intel or its authorized distributors.  Please refer to the applicable 
# agreement for further details.


## Copyright 2022 Intel Corporation.
##
## THIS SOFTWARE MAY CONTAIN PREPRODUCTION CODE AND IS PROVIDED BY THE
## COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED
## WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
## MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
## DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
## LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
## CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
## SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR
## BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
## WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
## OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE,
## EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

set MC_SS_SRC_ROOT ../../rtl/
# == IP_FILE ==
set_global_assignment -name IP_FILE $MC_SS_SRC_ROOT/mc_ss/ip/reqfifo.ip
set_global_assignment -name IP_FILE $MC_SS_SRC_ROOT/mc_ss/ip/rspfifo.ip
set_global_assignment -name IP_FILE $MC_SS_SRC_ROOT/mc_ss/ip/emif_cal_one_ch.ip
set_global_assignment -name IP_FILE $MC_SS_SRC_ROOT/mc_ss/ip/emif_cal_two_ch.ip
set_global_assignment -name IP_FILE $MC_SS_SRC_ROOT/mc_ss/ip/emif.ip

set_global_assignment -name IP_FILE $MC_SS_SRC_ROOT/mc_ss/ip/altecc_enc_latency0.ip
set_global_assignment -name IP_FILE $MC_SS_SRC_ROOT/mc_ss/ip/altecc_dec_latency1.ip
set_global_assignment -name IP_FILE $MC_SS_SRC_ROOT/mc_ss/ip/altecc_dec_latency2.ip
# == RTL sources ==
set_global_assignment -name SYSTEMVERILOG_FILE $MC_SS_SRC_ROOT/mc_ss/mc_top.sv
set_global_assignment -name SYSTEMVERILOG_FILE $MC_SS_SRC_ROOT/mc_ss/mc_channel_adapter.sv
set_global_assignment -name SYSTEMVERILOG_FILE $MC_SS_SRC_ROOT/mc_ss/mc_rmw_shim.sv
set_global_assignment -name SYSTEMVERILOG_FILE $MC_SS_SRC_ROOT/mc_ss/mc_ecc.sv
set_global_assignment -name SYSTEMVERILOG_FILE $MC_SS_SRC_ROOT/mc_ss/mc_emif.sv
# == constraints ==
set_global_assignment -name SDC_FILE $MC_SS_SRC_ROOT/mc_ss/cdc.sdc
