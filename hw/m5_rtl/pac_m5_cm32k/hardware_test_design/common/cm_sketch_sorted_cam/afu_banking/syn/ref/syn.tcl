########################################
# Multicore
set_host_options -max_cores 8

########################################
# Design library path
define_design_lib WORK 	-path ./work
remove_design -all
if [ file exist work ] {
    sh rm -rf work/*
	} else {
	    sh mkdir work
}
########################################
# Setup for TSMC 40nm CLN40G 1.2 RVt Standard Cell Library,
# TODO: Setup for other library
# Setting variable 
#set cornerF "bc_ccs"
set cornerT "tt_typical_max_0p90v_25c"
#set cornerTS "tc1d11d1_ccs"
#set cornerS "wc_ccs"
set corner  "$cornerT" 

set designname "Top"

set target_library "${libName}_${corner}.db" 
set link_library   "* ${libName}_${corner}.db dw_foundation.sldb" 

########################################
# Output file path 
set file_fanout		"output/$designname.fanout.rpt"
set file_report 	"output/$designname.rpt"
set file_check  	"output/$designname.check"
set file_verilog	"output/$designname.v"
set file_sdc    	"output/$designname.sdc"
set file_sdf    	"output/$designname.sdf"
set file_sta		"output/$designname.sta.rpt"
set file_elaborate  	"output/$designname.ela.rpt"
set file_cons		"output/$designname.cons.rpt"
set file_area		"output/$designname.area.rpt"
set file_vio		"output/$designname.vio.rpt"
set file_svf		"output/$designname.svf"
set file_cell		"output/$designname.pwr.cell.rpt"
set file_net		"output/$designname.pwr.net.rpt"
set file_total		"output/$designname.pwr.total.rpt"
set file_qor        "output/$designname.qor.rpt"
set check_read		"check/read.check"
set check_link		"check/link.check"
set check_cons		"check/cons.check"

# Make output directory 
if [ file exist output ] {
    sh rm -rf output/*
	} else {
	    sh mkdir output
}
if [ file exist check ] {
    sh rm -rf check/*
	} else {
	    sh mkdir check
}
set_svf	$file_svf
########################################
# Read RTL Design 
source code.list	>> $check_read
elaborate $designname	>> $file_elaborate
current_design 	   	   $designname
link 			>> $check_link
if {[link]} {
	} else {
	echo "\n\n\n\n\n\n\n\n\n\n\t\t\t!!Check Link Error\n\n\n\n\n\n\n\n\n\n"	
	exit					;# Exit DC if a check link error is encountered.
}
if {[check_design]} {
	} else {
	echo "\n\n\n\n\n\n\n\n\n\n\t\t\t!!Check Design Error\n\n\n\n\n\n\n\n\n\n"	
	exit					;# Exit DC if a check design error is encountered.
}

########################################
# Set Timing constraint
source ./cons/top.con 	>> 	$check_cons
#set_fix_hold 			$clk_name0
#set_fix_hold 			$clk_name1

########################################
# Compile & Save
# Compile
#compile_ultra -scan -timing;#-timing
# DFSNQ* cells are net changed to scannable DFF.
#set compile_disable_hierarchical_inverter_opt true
#set_fix_multiple_port_nets -all -buffer_constants

#set_dp_smartgen_options -cond_sum_adder true

#compile_ultra  -timing
#set_fix_hold 	$clk_name0
#set_ungroup 	[get_references serialInterface]
#set_ungroup 	[get_references i2c_regfile]
#set_fix_hold 	$clk_name1
#compile_ultra  -inc
#compile_ultra  -inc
compile_ultra 
#compile -area_effort high 
#compile -incremental
#compile_ultra -timing_high_effort_script -no_design_rule -retime
#compile_ultra -incremental -retime 
#compile_ultra -incremental 

#optimize_registers
set_fix_hold                    $clk_name0
#set_fix_hold                    $clk_name1

#compile_ultra -incremental -retime
#compile_ultra -incremental -retime
#compile_ultra -incremental -retime
#compile_ultra -incremental -retime
#compile_ultra -incremental -retime
#compile_ultra -incremental -retime

## Save design
report_net_fanout			>> $file_fanout
report_timing 				>> $file_report
report_timing_requirement 		>> $file_report
report_constraint -all_violators 	>> $file_vio
report_constraint -verbose 		>> $file_cons
report_area -hierarchy   		>> $file_area
report_power -verbose 			>> $file_total
report_power -cell -verbose 		>> $file_cell
report_power -net -verbose 		>> $file_net
report_qor                  >> $file_qor
check_design				>> $file_check
check_timing				>> $file_check

write -hier -f verilog -o 		$file_verilog
write_sdf -version 2.1 			$file_sdf
write_sdc 				$file_sdc

#start_gui
quit
