## TOP constrains file

# Setting variables Digital 
set 	clk_name0	"clk"
#set	clk_name1	"eCCK"
set	    rst_name0	"reset"
set 	max_area	0			;# 0:as small as possible 
set 	clk_peri0 	8
#set 	clk_peri1	10
set 	clk_uncer0	[expr $clk_peri0*0.01]
#set 	clk_uncer1	[expr $clk_peri1*0.01]
set 	clk_tran	0.08 			;# 80p
set 	out_load	50.0			;# 50fF
set	    auto_wire	1			;# 1:#default, 0:named model
#set	wire_name	"TSMC512K_Lowk_Conservative"
#set 	wire_group	"WireAreaLowkCon"
set	    wire_mode	"top"

# Setting variables Analog PHY
# Assuming that my block is drived by 1x inverter, 
# we can choose driving cell,
# or when we know specific transition time, 
# we can specify transition time of input ports.
set	    tran		0	;# 0:Using driving cell, 1:transition time unit:ps 
set 	driving_cell	INV_X4M_A9TR

# Constraints
set_max_area 		$max_area

create_clock	      -period	$clk_peri0	[get_ports  $clk_name0] 
set_clock_uncertainty -setup 	$clk_uncer0 	[get_clocks $clk_name0]
#set_clock_uncertainty -hold 	$clk_uncer0 	[get_clocks $clk_name0]
set_clock_transition 		$clk_tran	[get_clocks $clk_name0]

#create_clock	      -period	$clk_peri1 	[get_ports  $clk_name1]
#set_clock_uncertainty -setup 	$clk_uncer1 	[get_clocks $clk_name1]
#set_clock_uncertainty -hold 	$clk_uncer1 	[get_clocks $clk_name1]
#set_clock_transition 		$clk_tran	[get_clocks $clk_name1]

######################################### 
# Setting in/output delay 60%
# clk path

set_input_delay -max [expr $clk_peri0*0.6] -clock $clk_name0 \
[remove_from_collection [all_inputs] [get_ports {clock reset}]]
set_input_delay -min [expr $clk_peri0*0.2] -clock $clk_name0 \
[remove_from_collection [all_inputs] [get_ports {clock reset}]]

set_output_delay -max [expr $clk_peri0*0.2] -clock $clk_name0 \
[all_outputs]
set_output_delay -min [expr $clk_peri0*0.05] -clock $clk_name0 \
[all_outputs]

set_false_path -from $rst_name0 -to $clk_name0
#set_false_path -from $rst_name0 -to $clk_name1
#set_false_path -from $clk_name0 -to $clk_name1
#set_false_path -from $clk_name1 -to $clk_name0


# Additional Constraints
set_load 	[expr $out_load/1000]	[all_outputs] ;#unit:1pF, 50fF=50.0/1000
if {$tran==0} {
set_driving_cell -lib_cell 	$driving_cell [all_inputs];
} else {
set_input_transition 	[expr $tran]	[all_inputs]; 
}

# Wire load model
if {$auto_wire==1} {
set auto_wire_load_selection true 	;#default setting
set_wire_load_mode 			$wire_mode
#set_wire_load_selection_group  	$wire_group
} else {
set auto_wire_load_selection false
#set_wire_load_model -name 	$wire_name
set_wire_load_mode 		$wire_mode
}

set_app_var report_default_significant_digits 11

#propagated clock
#set_propagated_clock [all_clocks]

#remove_input_delay	[all_clocks]
