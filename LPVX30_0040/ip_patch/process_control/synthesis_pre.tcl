set current_prj_path [get_property DIRECTORY [current_project] -quiet]
if {$current_prj_path eq ""} {
    set parent [get_property parent.project_path [current_project] -quiet]
    set current_prj_path [file dirname $parent]
}
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

    if {[file exists $src_dcp]} {
        return
    }

    if {![file exists $run_dcp]} {
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

set prj_candidates [glob -nocomplain [file join $current_prj_path "*.xpr"]]
if {[llength $prj_candidates] > 0} {
    set prj_path [lindex $prj_candidates 0]
} else {
    set prj_path [get_prj_path]
}
open_project $prj_path
ensure_mig_dcp $current_prj_path
puts "step 1:pre_patch_check"
pre_patch_check
puts "step 2:pre_synthesis_patch"
pre_synthesis_patch 
puts "step 3:runEco0"
close_project
