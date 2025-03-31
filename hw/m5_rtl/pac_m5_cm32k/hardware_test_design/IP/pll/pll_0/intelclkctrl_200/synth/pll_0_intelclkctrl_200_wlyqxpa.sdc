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


#__ACDS_USER_COMMENT__####################################################################
#__ACDS_USER_COMMENT__
#__ACDS_USER_COMMENT__ THIS IS AN AUTO-GENERATED FILE!
#__ACDS_USER_COMMENT__ -------------------------------
#__ACDS_USER_COMMENT__ Note: all changes to this file will be overwritten when the core is regenerated
#__ACDS_USER_COMMENT__
#__ACDS_USER_COMMENT__ FILE DESCRIPTION
#__ACDS_USER_COMMENT__ ----------------
#__ACDS_USER_COMMENT__ This file contains the timing constraints for the clock divider
#__ACDS_USER_COMMENT__

set script_dir [file dirname [info script]]

#__ACDS_USER_COMMENT__ Set global parameters
source "$script_dir/pll_0_intelclkctrl_200_wlyqxpa_parameters.tcl"

#__ACDS_USER_COMMENT__ Load the design package in order to retrieve a list of clock divider instances
load_package design

#__ACDS_USER_COMMENT__ Required for proper clock constraints
derive_clock_uncertainty

#__ACDS_USER_COMMENT__ Returns a map of clock targets to clock names for the design
proc get_target_to_clock_map { map } {

        upvar 1 $map target_to_clock_map

        #__ACDS_USER_COMMENT__ Obtain the clocks that have been created in the design
        set current_clocks [get_clocks]

        #__ACDS_USER_COMMENT__ Map the clocks in the design to their targets
        set target_to_clock_map [dict create]
        
        #__ACDS_USER_COMMENT__ Iterate over clocks in the design
        foreach_in_collection clk_id $current_clocks {

                #__ACDS_USER_COMMENT__ Query the targets for this clock
                set target_col [get_clock_info -targets $clk_id]

                #__ACDS_USER_COMMENT__ Virtual clocks have no target
                if { 0 == [get_collection_size $target_col] } {
                        continue
                }

                #__ACDS_USER_COMMENT__ Retrieve the clock name
                set clock_name [get_clock_info -name $clk_id]
                       
                #__ACDS_USER_COMMENT__ Iterate over the targets
                foreach_in_collection target_id $target_col {
                
                        #__ACDS_USER_COMMENT__ Retrieve target name and clock name
                        set target_name [get_node_info -name $target_id]
 
                        #__ACDS_USER_COMMENT__ Store mapping from target name to clock name
                        dict lappend target_to_clock_map $target_name $clock_name

                        #__ACDS_USER_COMMENT__ If a clock is created on a net, add a entry for 
                        #__ACDS_USER_COMMENT__ the pin as well.  This will ensure it is found 
                        #__ACDS_USER_COMMENT__ during the fanin traversals later
                        set target_type [get_node_info -type $target_id]
                        if { $target_type eq "net" } {
                                set pin_id [get_net_info -pin $target_id]
                                set pin_name [get_pin_info -name $pin_id]
                                dict lappend target_to_clock_map $pin_name $clock_name
                        }
                }
        }
}

#__ACDS_USER_COMMENT__ Make a graph to do topological sort of the clock divider instantiations
#__ACDS_USER_COMMENT__ Note that only instantiations of the current parameterization are processed by this file.
proc get_adjacency_list { instances } {

        set adjacency_list [dict create]

        #__ACDS_USER_COMMENT__ Iterate through all instances
        for {set curr_idx 0} {$curr_idx < [llength $instances]} {incr curr_idx} {
                set curr_inst [lindex $instances $curr_idx]
                
                #__ACDS_USER_COMMENT__ Iterate through all other instances to find 
                #__ACDS_USER_COMMENT__ the ones upstream of the current instance
                set upstream_instances [list]
                foreach other_inst $instances {
        
                        #__ACDS_USER_COMMENT__ Assume an instance is never a fanin of itself
                        if {$curr_inst eq $other_inst} {
                                continue
                        }

                        #__ACDS_USER_COMMENT__ See if other_inst is a fanin of curr_inst
                        set other_inst_nets [get_nets -nowarn "${other_inst}|*"]
                        set curr_inst_regs [get_registers -nowarn "${curr_inst}|clkdiv_inst*"]
                        if { 0 == [get_collection_size $other_inst_nets] || 0 == [get_collection_size $curr_inst_regs] } {
                                continue
                        }                        
                        
                        set fanin_col [get_fanins -through $other_inst_nets $curr_inst_regs]
                        if { [get_collection_size $fanin_col] > 0} {
                                lappend upstream_instances $other_inst
                                
                                #__ACDS_USER_COMMENT__ Add the upstream instances to the adjacency list
                                #__ACDS_USER_COMMENT__ Store the adjacency list in terms of indices
                                for {set fanin_idx 0} {$fanin_idx < [llength $instances]} {incr fanin_idx} {
                                        if { $other_inst eq [lindex $instances $fanin_idx] } {
                                                dict lappend adjacency_list $fanin_idx $curr_idx
                                                break
                                        }
                                }
                        }
                }
        }

        return $adjacency_list
}

#__ACDS_USER_COMMENT__ Depth-first search for topological sort
proc dfs_visit {edges n color_list result_list} {
        upvar 1 $color_list color
        upvar 1 $result_list result
        
        if {[lindex $color $n] == "black"} {
                return
        } elseif {[lindex $color $n] == "grey" } {
                error "Topological sort failed, cycle detected!"
        }
    
        set color [lreplace $color $n $n "grey"]
    
        if [dict exists $edges $n] {
                foreach m [dict get $edges $n] {
                        dfs_visit $edges $m color result
                }
        }
    
        set color [lreplace $color $n $n "black"]
        set result [linsert $result 0 $n]
}

#__ACDS_USER_COMMENT__ Depth-first search for topological sort
proc dfs { edges num_nodes } {

        set result [list]

        set color [list]
        for {set i 0} {$i < $num_nodes} {incr i} {
                lappend color "white"
        }

        set n [lsearch $color "white"]
        while { $n != -1 } {
                dfs_visit $edges $n color result
                set n [lsearch $color "white"]
        }
        return $result
}

#__ACDS_USER_COMMENT__ Sort the instances of the current parameterization
proc topological_sort { instances } {

        #__ACDS_USER_COMMENT__ Represent the connectivity graph between the instances 
        #__ACDS_USER_COMMENT__ as an adjaency list of indices
        set edges [get_adjacency_list $instances]

        #__ACDS_USER_COMMENT__ Depth-first search topological sort
        set order [dfs $edges [llength $instances] ]
    
        #__ACDS_USER_COMMENT__ Convert from indices back to instance names
        set result [list]
        foreach index $order {
                lappend result [lindex $instances $index ]
        }
        
        #__ACDS_USER_COMMENT__ Return the sorted instance names
        return $result
}

#__ACDS_USER_COMMENT__ Issue warning for instances that will be skipped
proc warn_skipped_instances { skipped_instances } {

        set target_to_clock_map [dict create]
        get_target_to_clock_map target_to_clock_map
        
        #__ACDS_USER_COMMENT__ Iterate over all clock divider instances passed in
        foreach clock_div_inst $skipped_instances {

                post_message -type warning "The intelclkctrl SDC script will not constrain clock divider\
                output clocks for ${clock_div_inst} because a cycle was detected. "
                
                #__ACDS_USER_COMMENT__ Iterate over all clock divider outputs
                for {set outclk 0} {$outclk < $::GLOBAL_pll_0_intelclkctrl_200_wlyqxpa_out_clocks} {incr outclk} {
                
                        set divisor [expr {2 ** $outclk}]
                        set msg "You must constrain ${clock_div_inst}|clkdiv_inst|clockdiv${divisor}."
                        set submsgs [list]
                
                        #__ACDS_USER_COMMENT__ Trace fanins to suggest possible clock sources
                        set clock_fanins [dict create]
                        set other_fanins [dict create]
                        set clkdiv_inclk "${clock_div_inst}|clkdiv_inst|inclk"
                        trace_fanins $clkdiv_inclk $target_to_clock_map clock_fanins other_fanins
        
                        if { [ dict size $clock_fanins ] > 0 } {
                                lappend submsgs "Possible clock sources:"
                                dict for { clock_fanin clock_name } $clock_fanins {
                                        lappend submsgs "${clock_fanin} (name ${clock_name})"
                                }
                        } else {
                                lappend submsgs "Possible sources that are not marked as clocks:"
                                dict for { other_fanin other_fanin_type } $other_fanins {
                                        lappend submsgs "${other_fanin} (type ${other_fanin_type})"
                                }
                        }
                        post_message -type warning $msg -submsg $submsgs
                }
        }
}

#__ACDS_USER_COMMENT__ Depth-first search to identify islands (connected components) in the graph
proc dfs_island { edges n curr_color visited_list} {
        upvar 1 $visited_list visited

        if {[lindex $visited $n] ne "unvisited"} {
                return
        }
    
        set visited [lreplace $visited $n $n $curr_color]
    
        if [dict exists $edges $n] {
                foreach m [dict get $edges $n] {
                        dfs_island $edges $m $curr_color visited
                }
        }
}


#__ACDS_USER_COMMENT__ Identify islands (connected components) in the graph
proc find_islands { instances visited_list } {
        upvar 1 $visited_list visited

        #__ACDS_USER_COMMENT__ Represent the connectivity graph between the instances 
        #__ACDS_USER_COMMENT__ as an adjaency list of indices
        set edges [get_adjacency_list $instances]
    
        #__ACDS_USER_COMMENT__ Create an undirected graph by adding all reverse edges
        set undirected_edges [dict create]
        dict for { src dsts } $edges {
                foreach dst $dsts {
                        if { ![dict exists $undirected_edges $src] } {
                                dict set undirected_edges $src [list]
                        }
                        if { $dst ni [dict get $undirected_edges $src] } {
                                dict lappend undirected_edges $src $dst
                        }
                        if { ![dict exists $undirected_edges $dst] } {
                                dict set undirected_edges $dst [list]
                        }
                        if { $src ni [dict get $undirected_edges $dst] } {
                                dict lappend undirected_edges $dst $src
                        }
                }
        }

        #__ACDS_USER_COMMENT__ Initialize all nodes as unvisited
        set num_nodes [llength $instances]
        for {set i 0} {$i < $num_nodes} {incr i} {
                lappend visited "unvisited"
        }    

        #__ACDS_USER_COMMENT__ Depth-first search to assign a color to nodes that are connected
        set curr_color 0
        set n [lsearch $visited "unvisited"]
        while { $n != -1 } {
                dfs_island $undirected_edges $n $curr_color visited
                set n [lsearch $visited "unvisited"]
                incr curr_color
        }    

        #__ACDS_USER_COMMENT__ Return number of colors (number of islands)
        return $curr_color
}


#__ACDS_USER_COMMENT__ Returns a list of clock divider instances
proc get_clock_divider_instances {} {

        set sorted_instances [list]

        #__ACDS_USER_COMMENT__ Retrieve a list of clock divider instances
        set core $::GLOBAL_pll_0_intelclkctrl_200_wlyqxpa_core
        set instances [design::get_instances -entity $core]
        
        #__ACDS_USER_COMMENT__ No clock divider instances were detected
        if {[ llength $instances ] == 0} {
                post_message -type warning "The intelclkctrl SDC script was unable to detect\
                any instances of core < ${core} >"
        }
        
        #__ACDS_USER_COMMENT__ Separate the instances into ialands (connected components)
        #__ACDS_USER_COMMENT__ The island_idex list is parallel to the instances list
        set island_idx [list]
        set num_islands [find_islands $instances island_idx]
        
        #__ACDS_USER_COMMENT__ Iterate over all islands
        for { set inum 0 } { $inum < $num_islands } { incr inum } {

                #__ACDS_USER_COMMENT__ Identify the instances within the current island
                set connected_instances [list]
                for {set i 0} {$i < [llength $instances]} {incr i} {
                        if {[lindex $island_idx $i] == $inum } {
                                lappend connected_instances [lindex $instances $i]
                        }
                }
                
                #__ACDS_USER_COMMENT__ Perform topological sort on in instances within the current island
                if  {[ catch  {set connected_instances [topological_sort $connected_instances]} errmsg]} {
                        #__ACDS_USER_COMMENT__ If sorting failed, skip these instances
                        post_message -type warning $errmsg
                        post_message -type warning "The intelclkctrl SDC script was unable to determine\
                        a topological ordering for the instances of < ${core} >."
                        warn_skipped_instances $connected_instances
                } else {
                        #__ACDS_USER_COMMENT__ Store the sorted instances
                        foreach inst $connected_instances {
                                lappend sorted_instances $inst
                        }
                }
        }

        #__ACDS_USER_COMMENT__ Append "|clkdiv_inst|" to each instance name
        for {set inst_i 0} {$inst_i < [llength $sorted_instances]} {incr inst_i} {
                lset sorted_instances $inst_i [lindex $sorted_instances $inst_i]|clkdiv_inst|
        }
        return $sorted_instances
}



#__ACDS_USER_COMMENT__ Check if any clocks have already been generated on the clock divider outputs
proc any_output_clocks_already_exist { inst target_to_clock_map } {

        set retval 0
        set previous_clocks 0
        set submsgs [list]
        set divisors [ list 1 2 4 ]

        #__ACDS_USER_COMMENT__ Go through the output pins of the clock divider
        for {set outclk 0} {$outclk < $::GLOBAL_pll_0_intelclkctrl_200_wlyqxpa_out_clocks} {incr outclk} {

                #__ACDS_USER_COMMENT__ Derive the name of the clock divider output
                set divisor [lindex $divisors $outclk]
                set target "${inst}clock_div${divisor}"

                #__ACDS_USER_COMMENT__ Check whether a clock has already been created
                if { [dict exists $target_to_clock_map $target] } {
                        lappend submsgs "Found a clock on ${target}."
                        incr previous_clocks
                } else {
                        lappend submsgs "Did not find a clock on ${target}."
                }
        }
        
        #__ACDS_USER_COMMENT__ If clocks have been previously defined, issue a warning
        if { $previous_clocks > 0} {
                set retval 1
                set clock_div_inst [string trim $inst "|"]
                set msg "The intelclkctrl SDC script will not constrain clock divider\
                output clocks for ${clock_div_inst} because one or more output clocks were previously defined. "
                post_message -type warning $msg -submsg $submsgs
        }
        
        return $retval
}



#__ACDS_USER_COMMENT__ Get the clock fanins and non-clock fanins of this clock divider
proc trace_fanins { clkdiv_inclk target_to_clock_map clock_dict other_dict } {

        upvar 1 $clock_dict clock_fanins
        upvar 1 $other_dict other_fanins

        #__ACDS_USER_COMMENT__ Trace the fanins of the clock divider
        set fanins [get_fanins -clock -stop_at_clock $clkdiv_inclk]
        foreach_in_collection fanin_id $fanins {
        
                #__ACDS_USER_COMMENT__ Retrieve the fanin name from the fanin node
                set fanin [get_object_info -name $fanin_id]

                #__ACDS_USER_COMMENT__ If the fanin is found in the map, it is a clock
                if { [dict exists $target_to_clock_map $fanin] } {
                
                        #__ACDS_USER_COMMENT__ Store clock fanin
                        set user_clock [dict get $target_to_clock_map $fanin]
                        dict lappend clock_fanins $fanin {*}$user_clock

                #__ACDS_USER_COMMENT__ Otherwise it is a non-clock fanin
                } else {
                
                        #__ACDS_USER_COMMENT__ Store non-clock fanin
                        set fanin_type [get_object_info -type $fanin_id]
                        dict lappend other_fanins $fanin $fanin_type
                }
        }
}        



#__ACDS_USER_COMMENT__ If there is a single non-clock fanin and it is a port, create a clock on it
#__ACDS_USER_COMMENT__ Returns 1 if a clock was created, 0 otherwise
proc add_clock_on_single_fanin_that_is_a_port { clock_dict other_dict target_to_clock_map } {

        upvar 1 $clock_dict clock_fanins
        upvar 1 $other_dict other_fanins

        set retval 0
        
        #__ACDS_USER_COMMENT__ If there is a single fanin that is not a clock
        if { (0 == [llength [dict keys $clock_fanins]]) && (1 == [llength [dict keys $other_fanins]]) } {
        
                #__ACDS_USER_COMMENT__ Get the fanin and its type
                set fanin_id [lindex [dict get $other_fanins] 0]
                set fanin_type [lindex [dict get $other_fanins] 1]
                        
                #__ACDS_USER_COMMENT__ If it is a port, create a clock
                if { $fanin_type eq "port" } {
                        
                        #__ACDS_USER_COMMENT__ The created clock will have the same name as the port
                        set clock_name [get_node_info -name $fanin_id]
                        
                        #__ACDS_USER_COMMENT__ The created clock will have a default period of 1ns
                        set period 1.000

                        #__ACDS_USER_COMMENT__ Create the clock on the port
                        post_message -type info "The intelclkctrl SDC script created clock\
                        ${clock_name} with default period ${period} ns."
                        create_clock -period $period $fanin_id
                                
                        #__ACDS_USER_COMMENT__ Add a new entry to clock_fanins
                        dict lappend clock_fanins $clock_name $clock_name
                        
                        #__ACDS_USER_COMMENT__ Add a new entry to target_to_clock_map
                        dict lappend target_to_clock_map $clock_name $clock_name

                        #__ACDS_USER_COMMENT__ Remove the entry from other_fanins
                        dict unset other_fanins $clock_name

                        set retval 1
                }
        }
        return $retval
}



#__ACDS_USER_COMMENT__ Issue warnings because there are no clock sources for this clock divider
#__ACDS_USER_COMMENT__ This should only be called if there are zero clock fanins
proc warn_no_clock_sources { clkdiv_inclk clock_fanins other_fanins } {

        #__ACDS_USER_COMMENT__ No fanins were detected
        if { 0 == [ dict size $other_fanins ] } {

                post_message -type warning "The intelclkctrl SDC script cannot constrain\
                clock divider output clocks because no fanins were found for ${clkdiv_inclk}."
                
        #__ACDS_USER_COMMENT__ At least one fanin was detected, but none of the fanins are clocks
        } elseif { [ dict size $other_fanins ] > 0 } {
        
                #__ACDS_USER_COMMENT__ Suggest the non-clock inputs detected as possible clocks
                set submsgs [list]
                dict for { other_fanin other_fanin_type } $other_fanins {
                        lappend submsgs "${other_fanin} (type ${other_fanin_type})"
                }

                set advice1 "If you have a SDC script that creates clocks on the above fanin(s),\
                please ensure that SDC script is listed before the clock control IP in the QSF file."
                set advice2 "If the SDC script from another IP creates clocks on the above fanin(s),\
                please ensure that IP is listed before the clock control IP in the QSF file."
                lappend submsgs $advice1
                lappend submsgs $advice2

                #__ACDS_USER_COMMENT__ Post warning message
                set msg "The intelclkctrl SDC script cannot constrain clock divider output\
                clocks because no clock fanins were found for $clkdiv_inclk.  You may need\
                to call create_clock on one or more of the following the fanin(s):"
                post_message -type warning $msg -submsg $submsgs
        }
}


#__ACDS_USER_COMMENT__ Issue warnings if there are fewer clock fanins than mux inputs
proc warn_missing_clock_sources { clkdiv_inclk num_mux_inputs clock_dict other_dict } {

        upvar 1 $clock_dict clock_fanins
        upvar 1 $other_dict other_fanins
        
        #__ACDS_USER_COMMENT__ Find the names of the clock fanins
        set clock_submsgs [list]
        dict for { clock_fanin clock_name } $clock_fanins {
                lappend clock_submsgs "${clock_fanin} (name ${clock_name})"
        }

        #__ACDS_USER_COMMENT__ Issue warnings if there are fewer clock fanins than mux inputs
        set num_clock_fanins [ dict size $clock_fanins ]
        if { $num_clock_fanins < $num_mux_inputs } {

                set msg "The intelclkctrl SDC script expected ${num_mux_inputs} clock inputs but\
                found only ${num_clock_fanins} clock fanin(s) for ${clkdiv_inclk}.  The following\
                clock fanins were found: "
                post_message -type warning $msg -submsg $clock_submsgs

                #__ACDS_USER_COMMENT__ Suggest the non-clock inputs detected as possible clocks
                if { [ dict size $other_fanins ] > 0 } {
                        set other_submsgs [list]
                        dict for { other_fanin other_fanin_type } $other_fanins {
                                lappend other_submsgs "${other_fanin} (type ${other_fanin_type})"
                        }
                        
                        #__ACDS_USER_COMMENT__ Post warning message
                        set msg "You may need create_clock on one or more of the following fanin(s): "
                        post_message -type warning $msg -submsg $other_submsgs
                }
        }
}


#__ACDS_USER_COMMENT__ Constrain clock divider outputs using generated clocks
proc add_generated_clocks { source divider_output divisor master_clock add_master } {

        #__ACDS_USER_COMMENT__ Return nothing if this clock divider output is not connected
        if { 0 == [get_collection_size [get_pins -nowarn $divider_output]] } {
                return ""
        }

        #__ACDS_USER_COMMENT__ Derive target
        set target [get_pins $divider_output]

        #__ACDS_USER_COMMENT__ Generate the constraint without master clock specified
        if { 0 == $add_master } {

                set name $divider_output
                post_message -type info "Constrained clock divider output clock\
                ${divider_output} to ${source}."
                create_generated_clock -add \
                        -name $name \
                        -source $source \
                        -divide_by $divisor \
                        $target

        #__ACDS_USER_COMMENT__ Generate the constraint with master clock specified
        } else {

                set name "${divider_output}_${master_clock}"
                post_message -type info "Constrained clock divider output clock\
                ${divider_output} to ${source} (master name ${master_clock})."
                create_generated_clock -add \
                        -name $name  \
                        -source $source \
                        -master_clock $master_clock \
                        -divide_by $divisor \
                        $target
        }
        return $name
}


#__ACDS_USER_COMMENT__####################################################################
#__ACDS_USER_COMMENT__
#__ACDS_USER_COMMENT__ Main flow to constraint clock divider outputs
#__ACDS_USER_COMMENT__
#__ACDS_USER_COMMENT__####################################################################


#__ACDS_USER_COMMENT__ Go through all clock divider instances
foreach inst [get_clock_divider_instances] {

        #__ACDS_USER_COMMENT__ Obtain a map of clock targets to clock names for the design
        set target_to_clock_map [dict create]
        get_target_to_clock_map target_to_clock_map

        #__ACDS_USER_COMMENT__ Skip if this clock divider's outputs already have constraints
        if { [ any_output_clocks_already_exist $inst $target_to_clock_map ] } {
                continue
        }

        #__ACDS_USER_COMMENT__ Get the clock and non-clock fanins of this clock divider
        set clock_fanins [dict create]
        set other_fanins [dict create]
        set clkdiv_inclk "${inst}inclk"
        trace_fanins $clkdiv_inclk $target_to_clock_map clock_fanins other_fanins
        
        #__ACDS_USER_COMMENT__ There may be no clock fanins found
        if { 0 == [ dict size $clock_fanins ] } {

               #__ACDS_USER_COMMENT__ Create a clock if appropriate, updating relevant data structures
               if { [add_clock_on_single_fanin_that_is_a_port clock_fanins other_fanins $target_to_clock_map] } {

                       #__ACDS_USER_COMMENT__ One entry has been moved from other_fanins to clock_fanins
                       
               #__ACDS_USER_COMMENT__ Otherwise, issue a warning as no constraints will be generated                       
               } else {
                       warn_no_clock_sources $clkdiv_inclk $clock_fanins $other_fanins
                       continue;
               }
        }
        
        #__ACDS_USER_COMMENT__ Issue warning if there are fewer clock fanins than expected
        set num_clock_fanins [ dict size $clock_fanins ]
        if { $num_clock_fanins < $::GLOBAL_pll_0_intelclkctrl_200_wlyqxpa_in_clocks } {
                warn_missing_clock_sources $clkdiv_inclk $::GLOBAL_pll_0_intelclkctrl_200_wlyqxpa_in_clocks clock_fanins other_fanins
        }        
        
        #__ACDS_USER_COMMENT__ Iterate over the clock fanins to this clock divider
        set clock_groups [list]
        dict for { clock_fanin clock_name_list } $clock_fanins {
        
                #__ACDS_USER_COMMENT__ If multiple clock inputs, or if multiple clock names on an input,
                #__ACDS_USER_COMMENT__ a master clock will be specified
                set add_master 0        
                if { ( $num_clock_fanins > 1 ) || ( [ llength $clock_name_list ] > 1 ) } {
                        set add_master 1
                }                                

                #__ACDS_USER_COMMENT__ Keep a list of the names of the newly generated clocks
                set new_clocks [list]
                foreach master_clock_name $clock_name_list {

                        #__ACDS_USER_COMMENT__ Constrain each of the clock divider output clocks
                        for {set outclk 0} {$outclk < $::GLOBAL_pll_0_intelclkctrl_200_wlyqxpa_out_clocks} {incr outclk} {

                                #__ACDS_USER_COMMENT__ Compute frequency ratio relative to the input clock
                                set divisor [expr {2 ** $outclk}]

                                #__ACDS_USER_COMMENT__ Derive output clock port
                                set target "${inst}clock_div${divisor}"
                                
                                #__ACDS_USER_COMMENT__ Write out statement to constraint output clock
                                set new_clock [add_generated_clocks $clock_fanin $target $divisor $master_clock_name $add_master]
                                if { $new_clock != "" } {
                                        lappend new_clocks $new_clock
                                }
                        }
                }
                lappend clock_groups "-group"
                lappend clock_groups $new_clocks
        }

        #__ACDS_USER_COMMENT__ Specify exclusive clock groups for newly created clocks
        #__ACDS_USER_COMMENT__ This is necessary if there is a clock mux feeding the clock divider
        if { $num_clock_fanins > 1 } {
                post_message -type info "set_clock_groups -exclusive ${clock_groups}"
                set_clock_groups -exclusive {*}$clock_groups
        }
}

