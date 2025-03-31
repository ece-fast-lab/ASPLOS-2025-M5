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

proc apply_sdc_cut_to_node {to_node_list} {
   set num_to_node_list [get_collection_size $to_node_list]
   if { $num_to_node_list > 0} {
      # relax setup and hold calculation
      set_max_delay -to $to_node_list 100
      set_min_delay -to $to_node_list -100
   }
}

proc apply_sdc_pre_synchronizer_nocut_data__din_s1 {entity_name} {
   foreach each_inst [get_entity_instances $entity_name] {
      set to_node_list [get_keepers -nowarn $each_inst|din_s1]
      apply_sdc_cut_to_node $to_node_list
      }
   }

apply_sdc_pre_synchronizer_nocut_data__din_s1 *synchronizer_nocut

proc apply_sdc_dcfifo_aclr {entity_name} {
   foreach each_inst [get_entity_instances $entity_name] {
      set to_node_list [get_pins -compatibility_mode -nocase -nowarn $each_inst|fifo_0|dcfifo_component|auto_generated|rdaclr|dffe*|aclr]
      apply_sdc_cut_to_node $to_node_list
      set to_node_list [get_pins -compatibility_mode -nocase -nowarn $each_inst|fifo_0|dcfifo_component|auto_generated|rdaclr|dffe*|clrn]
      apply_sdc_cut_to_node $to_node_list
      }
   }

apply_sdc_dcfifo_aclr reqfifo
apply_sdc_dcfifo_aclr rspfifo
