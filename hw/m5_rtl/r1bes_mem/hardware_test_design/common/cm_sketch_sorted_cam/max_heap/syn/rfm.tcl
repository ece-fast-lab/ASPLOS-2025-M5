
set NUM_ENTRY [getenv "NUM_ENTRY"]
set RFM_TH    [getenv "RFM_TH"]
set NUM_BIT    [getenv "NUM_BIT"]

#/* All verilog files, separated by spaces         */
set base_dir [getenv "BASE_DIR"]
set my_verilog_files [list $base_dir/src/rfm_unit_bank/rfm_unit_bank_${NUM_ENTRY}_${RFM_TH}_${NUM_BIT}.v \
                           $base_dir/src/addr_cam.v \
                           $base_dir/src/cnt_cam/cnt_cam_${NUM_ENTRY}_${RFM_TH}_${NUM_BIT}.v \
                           $base_dir/src/cam_components.v]


#/* Top-level Module                               */
set my_toplevel rfm_unit_bank_${NUM_ENTRY}_${RFM_TH}_${NUM_BIT}

#/* Target frequency in MHz for optimization       */
set my_clk_freq_MHz [getenv "SYN_FREQ"]
set clk_period [expr ((1000 / $my_clk_freq_MHz))]

#/* The name of the clock pin. If no clock-pin     */
#/* exists, pick anything                          */
set my_clock_pin clk
set my_reset_pin rstn

set clk_uncertainty  [expr $clk_period*0.01]

#/* Delay of input signals (Clock-to-Q, Package etc.)  */
set input_delay_max [expr $clk_period*0.6]
set input_delay_min [expr $clk_period*0.2]

#/* Reserved time for output signals (Holdtime etc.)   */
set output_delay_max [expr $clk_period*0.2]
set output_delay_min [expr $clk_period*0.05]



#/* Libraries   */
set TSMC_STD_CELL [getenv "TSMC_STD_CELL"]
set search_path [concat  $search_path $TSMC_STD_CELL]
set alib_library_analysis_path $TSMC_STD_CELL

set link_library [concat  [list sc9_cln40g_base_rvt_tt_typical_max_0p90v_25c.db] [list dw_foundation.sldb]]
set target_library [format "%s%s" [getenv "TSMC_TARGET_LIB"] ".db" ]


#/* Set Parameters   */

define_design_lib WORK -path ./WORK
remove_design -all
set verilogout_show_unconnected_pins "true"

analyze -format sverilog $my_verilog_files

elaborate $my_toplevel

current_design $my_toplevel


link
uniquify

set find_clock [ find port [list $my_clock_pin] ]
if {  $find_clock != [list] } {
   set clk_name $my_clock_pin
   create_clock -period $clk_period $clk_name
} else {
   set clk_name vclk
   create_clock -period $clk_period -name $clk_name
}

#set_option -pipe 2

#set_max_fanout 8 $my_toplevel

set_ideal_network $clk_name
set_clock_uncertainty -setup $clk_uncertainty [get_clocks $clk_name]
set_dont_touch_network $clk_name
set_dont_touch_network $my_reset_pin

set_driving_cell  -lib_cell INV_X4M_A9TR  [all_inputs]

set_input_delay -max $input_delay_max -clock $clk_name [remove_from_collection [all_inputs] $my_clock_pin]
set_input_delay -min $input_delay_min -clock $clk_name [remove_from_collection [all_inputs] $my_clock_pin]
set_output_delay -max $output_delay_max -clock $clk_name [all_outputs]
set_output_delay -min $output_delay_min -clock $clk_name [all_outputs]

set_false_path -from $my_reset_pin -to $clk_name

#set_max_area 0
#compile -ungroup_all -map_effort medium
#compile -incremental_mapping -map_effort medium
#compile_ultra -no_auto_ungroup
compile_ultra -retime

check_design
report_constraint -all_violators

set output_path $base_dir/syn/output/$my_toplevel/$my_clk_freq_MHz

exec mkdir -p $output_path

set filename [format "%s%s"  $my_toplevel "_syn.v"]
write -f verilog -output $output_path/$filename

set filename [format "%s%s"  $my_toplevel "_syn.sdc"]
write_sdc $output_path/$filename

set filename [format "%s%s"  $my_toplevel "_syn.sdf"]
write_sdf $output_path/$filename

redirect $output_path/area.rep {report_area -hier}
redirect $output_path/timing.rep { report_timing }
redirect $output_path/cell.rep { report_cell }
redirect $output_path/power.rep { report_power }

quit
