proc resolve_project_dir {} {
    set candidates {}
    set parent [get_property parent.project_path [current_project] -quiet]
    if {$parent ne ""} {
        lappend candidates [file dirname $parent]
    }

    set project_dir [get_property DIRECTORY [current_project] -quiet]
    if {$project_dir ne ""} {
        set probe [file normalize $project_dir]
        for {set i 0} {$i < 6} {incr i} {
            lappend candidates $probe
            set next_probe [file dirname $probe]
            if {$next_probe eq $probe} {
                break
            }
            set probe $next_probe
        }
    }

    foreach candidate $candidates {
        set candidate [file normalize $candidate]
        if {[file exists [file join $candidate "ip_patch" "run.tcl"]] && [llength [glob -nocomplain [file join $candidate "*.xpr"]]] > 0} {
            return $candidate
        }
    }

    error "Unable to resolve Vivado project directory from current project context"
}

proc ensure_xilinx_local_user_data {} {
    set current ""
    if {[info exists ::env(XILINX_LOCAL_USER_DATA)]} {
        set current $::env(XILINX_LOCAL_USER_DATA)
    }

    if {$current ne "" && [string first " " $current] < 0} {
        if {[catch {file mkdir $current} mkdir_msg]} {
            puts "WARNING: unable to create XILINX_LOCAL_USER_DATA '$current': $mkdir_msg"
        } else {
            puts "Using XILINX_LOCAL_USER_DATA=$current"
            return
        }
    }

    set candidates {}
    if {[info exists ::env(SystemDrive)] && $::env(SystemDrive) ne ""} {
        set system_drive [string trimright $::env(SystemDrive) "\\/"]
        lappend candidates "${system_drive}/XilinxLocalUserData"
    }
    foreach volume [file volumes] {
        lappend candidates [file join $volume XilinxLocalUserData]
    }

    foreach candidate $candidates {
        set candidate [file normalize $candidate]
        if {[string first " " $candidate] >= 0} {
            continue
        }
        if {[catch {file mkdir $candidate} mkdir_msg]} {
            puts "WARNING: unable to create XILINX_LOCAL_USER_DATA '$candidate': $mkdir_msg"
            continue
        }
        set ::env(XILINX_LOCAL_USER_DATA) [file nativename $candidate]
        puts "Set XILINX_LOCAL_USER_DATA=$::env(XILINX_LOCAL_USER_DATA)"
        return
    }

    puts "WARNING: XILINX_LOCAL_USER_DATA was not set; Vivado OOC runs may emit Common 17-1257."
}

ensure_xilinx_local_user_data

set current_prj_path [resolve_project_dir]
set current_prj_path [file normalize $current_prj_path]
set ::env(JFM_PATH) $current_prj_path
set run_tcl_path [file join $::env(JFM_PATH) "ip_patch" "run.tcl"]
source $run_tcl_path

proc ensure_mig_dcp {project_dir} {
    set ip_name "mig_7series_0"
    set src_dcp [file join $project_dir "LPVX30_0040.srcs" "sources_1" "ip" $ip_name "${ip_name}.dcp"]
    set run_dcp [file join $project_dir "LPVX30_0040.runs" "${ip_name}_synth_1" "${ip_name}.dcp"]
    set mig_rtl [file join $project_dir "LPVX30_0040.srcs" "sources_1" "ip" $ip_name $ip_name "user_design" "rtl" "${ip_name}.v"]
    set mig_axi_rtl [file join $project_dir "LPVX30_0040.srcs" "sources_1" "ip" $ip_name $ip_name "user_design" "rtl" "axi" "mig_7series_v4_2_axi_ctrl_addr_decode.v"]

    if {[file exists $src_dcp] && [file exists $mig_rtl] && [file exists $mig_axi_rtl]} {
        return
    }

    if {![file exists $run_dcp] || ![file exists $mig_rtl] || ![file exists $mig_axi_rtl]} {
        set ip_obj [get_ips -quiet $ip_name]
        if {[llength $ip_obj] == 0} {
            error "Required IP '$ip_name' was not found while preparing $src_dcp"
        }

        puts "MIG checkpoint is missing. Regenerating output products for $ip_name."
        catch {reset_target all $ip_obj} reset_msg
        if {$reset_msg ne ""} {
            puts "reset_target all $ip_name: $reset_msg"
        }
        if {[catch {generate_target all $ip_obj} gen_msg]} {
            error "Failed to generate output products for $ip_name: $gen_msg"
        }
        if {$gen_msg ne ""} {
            puts "generate_target all $ip_name: $gen_msg"
        }

        if {![file exists $mig_rtl] || ![file exists $mig_axi_rtl]} {
            error "MIG output products are still missing after regeneration. Missing example files: $mig_rtl or $mig_axi_rtl"
        }

        if {[file exists $src_dcp]} {
            return
        }

        if {[llength [get_runs -quiet ${ip_name}_synth_1]] == 0} {
            catch {create_ip_run $ip_obj} create_msg
            if {$create_msg ne ""} {
                puts "create_ip_run $ip_name: $create_msg"
            }
        }

        set ip_run [get_runs -quiet ${ip_name}_synth_1]
        if {[llength $ip_run] == 0} {
            error "Unable to create Vivado OOC run ${ip_name}_synth_1"
        }

        set run_status [get_property STATUS $ip_run]
        if {![string match "*Complete*" $run_status]} {
            catch {reset_run ${ip_name}_synth_1}
            puts "Launching ${ip_name}_synth_1 to generate MIG checkpoint."
            launch_runs ${ip_name}_synth_1 -jobs 8
            wait_on_run ${ip_name}_synth_1
            set run_status [get_property STATUS [get_runs ${ip_name}_synth_1]]
        }

        if {![string match "*Complete*" $run_status]} {
            error "${ip_name}_synth_1 did not complete successfully: $run_status"
        }
    }

    if {![file exists $run_dcp]} {
        error "Unable to locate generated MIG checkpoint: $run_dcp"
    }

    file mkdir [file dirname $src_dcp]
    file copy -force $run_dcp $src_dcp
    puts "Prepared MIG checkpoint: $src_dcp"
}

proc ensure_ip_dcp {project_dir ip_name dst_dcp} {
    set run_name "${ip_name}_synth_1"
    set run_dcp [file join $project_dir "LPVX30_0040.runs" $run_name "${ip_name}.dcp"]

    if {[file exists $dst_dcp]} {
        return
    }

    set ip_obj [get_ips -quiet $ip_name]
    if {[llength $ip_obj] == 0} {
        error "Required IP '$ip_name' was not found while preparing $dst_dcp"
    }

    puts "$ip_name checkpoint is missing. Regenerating output products."
    catch {reset_target all $ip_obj} reset_msg
    if {$reset_msg ne ""} {
        puts "reset_target all $ip_name: $reset_msg"
    }
    if {[catch {generate_target all $ip_obj} gen_msg]} {
        error "Failed to generate output products for $ip_name: $gen_msg"
    }
    if {$gen_msg ne ""} {
        puts "generate_target all $ip_name: $gen_msg"
    }

    if {[file exists $dst_dcp]} {
        return
    }

    if {[llength [get_runs -quiet $run_name]] == 0} {
        catch {create_ip_run $ip_obj} create_msg
        if {$create_msg ne ""} {
            puts "create_ip_run $ip_name: $create_msg"
        }
    }

    set ip_run [get_runs -quiet $run_name]
    if {[llength $ip_run] == 0} {
        error "Unable to create Vivado OOC run $run_name"
    }

    set run_status [get_property STATUS $ip_run]
    if {![string match "*Complete*" $run_status] || ![file exists $run_dcp]} {
        catch {reset_run $run_name}
        puts "Launching $run_name to generate $ip_name checkpoint."
        launch_runs $run_name -jobs 8
        wait_on_run $run_name
        set run_status [get_property STATUS [get_runs $run_name]]
    }

    if {![string match "*Complete*" $run_status]} {
        error "$run_name did not complete successfully: $run_status"
    }
    if {![file exists $run_dcp]} {
        error "Unable to locate generated checkpoint for $ip_name: $run_dcp"
    }

    file mkdir [file dirname $dst_dcp]
    file copy -force $run_dcp $dst_dcp
    puts "Prepared $ip_name checkpoint: $dst_dcp"
}

proc ensure_patch_ip_dcps {project_dir} {
    set repo_dir [file dirname $project_dir]
    ensure_ip_dcp $project_dir "pcie3_8x8g_0" [file join $repo_dir "HDL" "IP" "xc7vx690tffg19272i" "pcie3_ep_wrap" "pcie3_8x8g_0" "pcie3_8x8g_0.dcp"]
    ensure_ip_dcp $project_dir "srio_gen2_5g_2x_8b" [file join $repo_dir "HDL" "IP" "xc7vx690tffg19272i" "srio_support" "srio_support_5g_2x_8b" "srio_gen2_5g_2x_8b" "srio_gen2_5g_2x_8b.dcp"]
}

set prj_candidates [glob -nocomplain [file join $current_prj_path "*.xpr"]]
if {[llength $prj_candidates] > 0} {
    set prj_path [lindex $prj_candidates 0]
} else {
    set prj_path [get_prj_path]
}
if {[catch {open_project $prj_path} open_msg]} {
    if {[string first "already open" $open_msg] < 0} {
        error $open_msg
    }
    puts "Project is already open: $prj_path"
}
ensure_mig_dcp $current_prj_path
ensure_patch_ip_dcps $current_prj_path
puts "step 1:pre_patch_check"
pre_patch_check
puts "step 2:pre_synthesis_patch"
pre_synthesis_patch 
puts "step 3:runEco0"
close_project
