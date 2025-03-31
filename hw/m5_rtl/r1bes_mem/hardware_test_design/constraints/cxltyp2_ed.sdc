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



#-----------------------------------------------
# Create Input Clocks
#-----------------------------------------------

#create_clock -period "30.303 ns" -name {altera_reserved_tck} {altera_reserved_tck}


#-----------------------------------------------
# Create generated clocks
#-----------------------------------------------


#-------------------------------------------------
# Jtag 
#-------------------------------------------------
#-------------------------------------------------
# Jtag 
#-------------------------------------------------

set_time_format -unit ns -decimal_places 3

proc set_jtag_timing_constraints { } {

   set use_fitter_specific_constraint 1
   set_jtag_timing_spec_for_timing_analysis

   #if { $use_fitter_specific_constraint && [string equal quartus_fit $::TimeQuestInfo(nameofexecutable)] } {

   #   set_default_quartus_fit_timing_directive
   #}  else {

   #   set_jtag_timing_spec_for_timing_analysis
   #}
}

proc set_default_quartus_fit_timing_directive { } {
   set jtag_33Mhz_t_period 30

   create_clock -name {altera_reserved_tck} -period $jtag_33Mhz_t_period [get_ports {altera_reserved_tck}]
   set_clock_groups -asynchronous -group {altera_reserved_tck}


   set_max_delay -to [get_ports { altera_reserved_tdo } ] 0
}

proc set_jtag_timing_spec_for_timing_analysis { } {
   derive_clock_uncertainty


   set_tck_timing_spec
   set_tms_timing_spec

   set tdi_is_driven_by_blaster 1

   if { $tdi_is_driven_by_blaster } {
      set_tdi_timing_spec_when_driven_by_blaster
   } else {
      set_tdi_timing_spec_when_driven_by_device
   }

   set tdo_drive_blaster 1

   if { $tdo_drive_blaster } {
      set_tdo_timing_spec_when_drive_blaster
   } else {
      set_tdo_timing_spec_when_drive_device
   }

   set_optional_ntrst_timing_spec

   set_false_path -from [get_ports {altera_reserved_tdi}] -to [get_ports {altera_reserved_tdo}]
   if { [get_collection_size [get_registers -nowarn *~jtag_reg]] > 0 } {
      set_false_path -from [get_registers *~jtag_reg] -to [get_ports {altera_reserved_tdo}]
   }
}

proc set_tck_timing_spec { } {
   set ub1_t_period 166.666
   set ub2_default_t_period 41.666
   set ub2_safe_t_period 62.5

   set tck_t_period $ub2_safe_t_period

   create_clock -name {altera_reserved_tck} -period $tck_t_period  [get_ports {altera_reserved_tck}]
   set_clock_groups -asynchronous -group {altera_reserved_tck}
}

proc get_tck_delay_max { } {
   set tck_blaster_tco_max 14.603
   set tck_cable_max 11.627

   set tck_header_trace_max 0.5

   return [expr $tck_blaster_tco_max + $tck_cable_max + $tck_header_trace_max]
}

proc get_tck_delay_min { } {
   set tck_blaster_tco_min 14.603
   set tck_cable_min 10.00

   set tck_header_trace_min 0.1

   return [expr $tck_blaster_tco_min + $tck_cable_min + $tck_header_trace_min]
}

proc set_tms_timing_spec { } {
   set tms_blaster_tco_max 9.468
   set tms_blaster_tco_min 9.468

   set tms_cable_max 11.627
   set tms_cable_min 10.0

   set tms_header_trace_max 0.5
   set tms_header_trace_min 0.1

   set tms_in_max [expr $tms_cable_max + $tms_header_trace_max + $tms_blaster_tco_max - [get_tck_delay_min]]
   set tms_in_min [expr $tms_cable_min + $tms_header_trace_min + $tms_blaster_tco_min - [get_tck_delay_max]]

   set_input_delay -add_delay -clock_fall -clock altera_reserved_tck -max $tms_in_max [get_ports {altera_reserved_tms}]
   set_input_delay -add_delay -clock_fall -clock altera_reserved_tck -min $tms_in_min [get_ports {altera_reserved_tms}]
}

proc set_tdi_timing_spec_when_driven_by_blaster { } {
   set tdi_blaster_tco_max 8.551
   set tdi_blaster_tco_min 8.551

   set tdi_cable_max 11.627
   set tdi_cable_min 10.0

   set tdi_header_trace_max 0.5
   set tdi_header_trace_min 0.1

   set tdi_in_max [expr $tdi_cable_max + $tdi_header_trace_max + $tdi_blaster_tco_max - [get_tck_delay_min]]
   set tdi_in_min [expr $tdi_cable_min + $tdi_header_trace_min + $tdi_blaster_tco_min - [get_tck_delay_max]]

   set_input_delay -add_delay -clock_fall -clock altera_reserved_tck -max $tdi_in_max [get_ports {altera_reserved_tdi}]
   set_input_delay -add_delay -clock_fall -clock altera_reserved_tck -min $tdi_in_min [get_ports {altera_reserved_tdi}]
}

proc set_tdi_timing_spec_when_driven_by_device { } {
   set previous_device_tdo_tco_max 10.0
   set previous_device_tdo_tco_min 10.0

   set tdi_trace_max 0.5
   set tdi_trace_min 0.1

   set tdi_in_max [expr $previous_device_tdo_tco_max + $tdi_trace_max - [get_tck_delay_min]]
   set tdi_in_min [expr $previous_device_tdo_tco_min + $tdi_trace_min - [get_tck_delay_max]]

   set_input_delay -add_delay -clock_fall -clock altera_reserved_tck -max $tdi_in_max [get_ports {altera_reserved_tdi}]
   set_input_delay -add_delay -clock_fall -clock altera_reserved_tck -min $tdi_in_min [get_ports {altera_reserved_tdi}]
}

proc set_tdo_timing_spec_when_drive_blaster { } {
   set tdo_blaster_tsu 5.831
   set tdo_blaster_th -1.651

   set tdo_cable_max 11.627
   set tdo_cable_min 10.0

   set tdo_header_trace_max 0.5
   set tdo_header_trace_min 0.1

   set tdo_out_max [expr $tdo_cable_max + $tdo_header_trace_max + $tdo_blaster_tsu + [get_tck_delay_max]]
   set tdo_out_min [expr $tdo_cable_min + $tdo_header_trace_min - $tdo_blaster_th + [get_tck_delay_min]]

   set_output_delay -add_delay -clock_fall -clock altera_reserved_tck -max $tdo_out_max [get_ports {altera_reserved_tdo}]
   set_output_delay -add_delay -clock_fall -clock altera_reserved_tck -min $tdo_out_min [get_ports {altera_reserved_tdo}]
}

proc set_tdo_timing_spec_when_drive_device { } {
   set next_device_tdi_tco_max 10.0
   set next_device_tdi_tco_min 10.0

   set tdo_trace_max 0.5
   set tdo_trace_min 0.1

   set tdo_out_max [expr $next_device_tdi_tco_max + $tdo_trace_max + [get_tck_delay_max]]
   set tdo_out_min [expr $next_device_tdi_tco_min + $tdo_trace_min + [get_tck_delay_min]]

   set_output_delay -add_delay -clock altera_reserved_tck -max $tdo_out_max [get_ports {altera_reserved_tdo}]
   set_output_delay -add_delay -clock altera_reserved_tck -min $tdo_out_min [get_ports {altera_reserved_tdo}]
}

proc set_optional_ntrst_timing_spec { } {
   if { [get_collection_size [get_ports -nowarn {altera_reserved_ntrst}]] > 0 } {
      set_false_path -from [get_ports {altera_reserved_ntrst}]
   }
}

if { [get_collection_size [get_ports -nowarn {altera_reserved_tck}]] > 0 } {
   set_jtag_timing_constraints
   if {[string equal quartus_sta $::TimeQuestInfo(nameofexecutable)]} {
      post_message -type warning "The CXL IP Example Design is using default JTAG timing constraints from jtag_example.sdc. For correct hardware behavior, you must review the timing constraints and ensure that they accurately reflect your JTAG topology and clock speed."
   }
}

# Automatically derived from IP constraint file

set pld_clk      [get_clocks *|cxl_ip|rtile_cxl_ip.coreclkout_hip]
set side_hip_clk [get_clocks *|cxl_ip|rtile_cxl_ip.pld_clkout_slow]
set cam_clk      [get_clocks *|cxl_t2ip_sip_top|gen_clkrst|cxl_memexp_sip_clkgen|rnr_ial_sip_clkgen_pll_cam_clk]
set sbr_clk      [get_clocks *|cxl_t2ip_sip_top|gen_clkrst|cxl_memexp_sip_clkgen|rnr_ial_sip_clkgen_pll_sbr_clk]
set emif_usr_clk_0 [get_clocks ed_top_wrapper_typ2_inst|MC_CHANNEL_INST[0].mc_top|GEN_CHAN_COUNT_EMIF[0].emif_inst|emif_core_usr_clk]
set emif_usr_clk_1 [get_clocks ed_top_wrapper_typ2_inst|MC_CHANNEL_INST[0].mc_top|GEN_CHAN_COUNT_EMIF[1].emif_inst|emif_core_usr_clk]
set tck [get_clocks altera_reserved_tck]

# yerjin
set_false_path -from [get_keepers -no_duplicates {ed_top_wrapper_typ2_inst|ip2hdm_reset_n_f}] -to [all_registers]
set_false_path -from [get_keepers -no_duplicates {ed_top_wrapper_typ2_inst|ip2hdm_reset_n_ff}] -to [all_registers]

#-----------------------------------------------
# synchroniser 
#-----------------------------------------------
proc apply_sdc_synchronizer_nocut__to_node {to_node_list} {
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
      apply_sdc_synchronizer_nocut__to_node $to_node_list
      }
   }

apply_sdc_pre_synchronizer_nocut_data__din_s1 *synchronizer_nocut

#-----------------------------------------------
# Set Clock uncertainity
#-----------------------------------------------
derive_clock_uncertainty

#-----------------------------------------------
# Set Clock groups
#-----------------------------------------------

set_clock_groups -asynchronous -group $pld_clk -group $cam_clk -group $sbr_clk -group $tck -group $emif_usr_clk_0 -group $emif_usr_clk_1 -group $side_hip_clk 


#-----------------------------------------------
# Set Exceptions
#-----------------------------------------------

#-----------------------------------------------
# Overconstraint specific paths during Placement & Routing
#-----------------------------------------------

if {![is_post_route]} {
   # fitter; 15% 
   set_clock_uncertainty -setup -add -from $pld_clk 0.2ns

}

#-----------------------------------------------
# IPDCFIFO Constriants
#-----------------------------------------------
# constraints for DCFIFO sdc
#
# top-level sdc
# convention for module sdc apply_sdc_<module_name>
#
proc apply_sdc_dcfifo {hier_path} {
# gray_rdptr
apply_sdc_dcfifo_rdptr $hier_path
# gray_wrptr
apply_sdc_dcfifo_wrptr $hier_path
}
#
# common constraint setting proc
#
proc apply_sdc_dcfifo_for_ptrs {from_node_list to_node_list} {
# control skew for bits
set_max_skew -from $from_node_list -to $to_node_list -get_skew_value_from_clock_period src_clock_period -skew_value_multiplier 0.8
# path delay (exception for net delay)
if { ![string equal "quartus_syn" $::TimeQuestInfo(nameofexecutable)] } {
set_net_delay -from $from_node_list -to $to_node_list -max -get_value_from_clock_period dst_clock_period -value_multiplier 0.8
}
#relax setup and hold calculation
set_max_delay -from $from_node_list -to $to_node_list 100
set_min_delay -from $from_node_list -to $to_node_list -100
}
#
# mstable propgation delay
#
proc apply_sdc_dcfifo_mstable_delay {from_node_list to_node_list} {
# mstable delay
if { ![string equal "quartus_syn" $::TimeQuestInfo(nameofexecutable)] } {
set_net_delay -from $from_node_list -to $to_node_list -max -get_value_from_clock_period dst_clock_period -value_multiplier 0.8
}
}
#
# rdptr constraints
#
proc apply_sdc_dcfifo_rdptr {hier_path} {
# get from and to list
set from_node_list [get_keepers $hier_path|dcfifo_component|auto_generated|*rdptr_g*]
set to_node_list [get_keepers $hier_path|dcfifo_component|auto_generated|ws_dgrp|dffpipe*|dffe*]
apply_sdc_dcfifo_for_ptrs $from_node_list $to_node_list
# mstable
set from_node_mstable_list [get_keepers $hier_path|dcfifo_component|auto_generated|ws_dgrp|dffpipe*|dffe*]
set to_node_mstable_list [get_keepers $hier_path|dcfifo_component|auto_generated|ws_dgrp|dffpipe*|dffe*]
apply_sdc_dcfifo_mstable_delay $from_node_mstable_list $to_node_mstable_list
}
#
# wrptr constraints
#
proc apply_sdc_dcfifo_wrptr {hier_path} {
# control skew for bits
set from_node_list [get_keepers $hier_path|dcfifo_component|auto_generated|delayed_wrptr_g*]
set to_node_list [get_keepers $hier_path|dcfifo_component|auto_generated|rs_dgwp|dffpipe*|dffe*]
apply_sdc_dcfifo_for_ptrs $from_node_list $to_node_list
# mstable
set from_node_mstable_list [get_keepers $hier_path|dcfifo_component|auto_generated|rs_dgwp|dffpipe*|dffe*]
set to_node_mstable_list [get_keepers $hier_path|dcfifo_component|auto_generated|rs_dgwp|dffpipe*|dffe*]
apply_sdc_dcfifo_mstable_delay $from_node_mstable_list $to_node_mstable_list
}

proc apply_sdc_pre_dcfifo {entity_name} {

set inst_list [get_entity_instances $entity_name]

foreach each_inst $inst_list {

        apply_sdc_dcfifo ${each_inst} 

    }
}
#apply_sdc_pre_dcfifo ccv_afu_cdc_fifo_vcd*


