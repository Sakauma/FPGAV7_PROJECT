#fmk230t fix_route
proc get_scaript_dir {} {
    set script_path [file normalize [info script]]
    set jfmScriptDir [file dirname $script_path]
    return $jfmScriptDir
}

proc readFiles {filePath} {
    if {[file exists $filePath]} {
        set fh [open $filePath "r"]
        set lines [split [read $fh] "\n"]
        set contents [list]
        foreach line $lines {
            if {[regexp {^\s*$} $line]} {
            } elseif {[regexp {^\s*#} $line]} {
            } else {
                lappend contents $line
            }
        }
        close $fh
        return $contents
    } else {
        error "error: no such file: $filePath"
    }
}

proc fix_route_230t_pre {} {
    puts "FMSH->Start fmk230t_fix_route_eco:"

    create_pblock pblock_1
    add_cells_to_pblock [get_pblocks pblock_1] [get_cells -hierarchical -filter {NAME != "*fmsh_fmk230t*"}]
    resize_pblock [get_pblocks pblock_1] -add {CLOCKREGION_X0Y0:CLOCKREGION_X1Y4}
    set_property CONTAIN_ROUTING 1 [get_pblocks pblock_1]

    set dir [get_scaript_dir]
    set fmk230_fix_route_path [file join $dir "fmk230_fix_route.info"]
    puts "$fmk230_fix_route_path"
    set nodes_list [readFiles $fmk230_fix_route_path]

    #create pblock row2~3
    create_pblock -quiet pblock_u_fix_route
    resize_pblock [get_pblocks pblock_u_fix_route] -add {CLOCKREGION_X0Y5:CLOCKREGION_X1Y6}
#    set_property CONTAIN_ROUTING 1 [get_pblocks pblock_u_fix_route]

    set cell [create_cell -reference VCC fmsh_fmk230t_vcc]
    set_property DONT_TOUCH 1 $cell
    add_cells_to_pblock [get_pblocks pblock_u_fix_route] [get_cells -quiet [list $cell]]

    set i 0
    set node_net [dict create]
    foreach node $nodes_list {
        if {$i<1} {
#        set cell  [create_cell -reference VCC  fmsh_fmk230t_vcc_$i]
            set cell1 [create_cell -reference LUT1 fmsh_fmk230t_mylut1_$i]
            add_cells_to_pblock [get_pblocks pblock_u_fix_route] [get_cells -quiet [list $cell1]]
            set_property INIT 2'h3 $cell1
            set_property DONT_TOUCH 1 $cell1
            set net [create_net fmk230t_vcc]
            set net1 [create_net fmk230t_fix_route_lut1_$i]
            connect_net -object "$cell/P"   -net [get_nets $net]
            connect_net -object "$cell1/I0" -net [get_nets $net]
            connect_net -object "$cell1/O"  -net [get_nets $net1]
            set_property DONT_TOUCH 1 [get_nets $net]
#            set_property DONT_TOUCH 1 [get_nets $net1]
            dict set node_net $net1 $node
        } else {
            set cell1 [create_cell -reference LUT1 fmsh_fmk230t_mylut1_$i]
            add_cells_to_pblock [get_pblocks pblock_u_fix_route] [get_cells -quiet [list $cell1]]
            set_property INIT 2'h3 $cell1
            set_property DONT_TOUCH 1 $cell1
            set net $net1
            set net1 [create_net fmk230t_fix_route_lut1_$i]
            connect_net -object "$cell1/I0" -net [get_nets $net]
            connect_net -object "$cell1/O"  -net [get_nets $net1]
            set_property DONT_TOUCH 1 [get_nets $net]
#            set_property DONT_TOUCH 1 [get_nets $net1]
            dict set node_net $net1 $node
        }
        incr i
    }

    set cell1 [create_cell -reference LUT1 fmsh_fmk230t_mylut1]
    add_cells_to_pblock [get_pblocks pblock_u_fix_route] [get_cells -quiet [list $cell1]]
    set_property INIT 2'h3 $cell1
    set_property DONT_TOUCH 1 $cell1
    set net $net1
    set net1 [create_net fmk230t_fix_route_lut1]
    connect_net -object "$cell1/I0" -net [get_nets $net]
    connect_net -object "$cell1/O"  -net [get_nets $net1]
    set_property DONT_TOUCH 1 [get_nets $net]

    #create OBUF
#    set cell_obuf [create_cell -reference OBUF fmsh_fmk230t_myobuf]
#    add_cells_to_pblock [get_pblocks pblock_u_fix_route] [get_cells -quiet [list $cell_obuf]]
#    connect_net -object [get_pins $cell_obuf/I] -net [get_nets $net1]
#    set_property DONT_TOUCH 1 [get_nets $net1]

#    set net_obuf [create_net fmk230t_obuf_net]
#    connect_net -object [get_pins $cell_obuf/O] -net [get_nets $net_obuf]
#    puts "get_pins=[get_pins $cell_obuf/O]"
    #create output port
#    create_port -direction OUT lut_outio
#    set_property PACKAGE_PIN A11 [get_ports "lut_outio"]
#    set_property IOSTANDARD LVCMOS15 [get_ports "lut_outio"]
#    connect_net -object [get_ports "lut_outio"] -net [get_nets $net_obuf]

    puts "FMSH->fmk230t_fix_route_eco excuted successfully!"
}
proc get_node_net_dict {} {
    set dir [get_scaript_dir]
    set fmk230_fix_route_path [file join $dir "fmk230_fix_route.info"]
    set nodes_list [readFiles $fmk230_fix_route_path]
    set i 0
    set node_net_dict [dict create]
    foreach node $nodes_list {
        set net1 fmk230t_fix_route_lut1_$i
        dict set node_net_dict $net1 $node
        incr i
    }
    return $node_net_dict
}

proc fix_route_230t_post {} {
    puts "FMSH->Start set_fixed_route:"
    set node_net_dict [get_node_net_dict]
    dict for {key val}  $node_net_dict {
    	set str "{GAP $val}"
    	set_property fixed_route $str [get_nets $key]
#        puts "$str $key"
    }
    puts "FMSH->set_fixed_route excuted successfully!"
}
# fix_route_230t_post

