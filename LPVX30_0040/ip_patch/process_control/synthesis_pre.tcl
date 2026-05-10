set parent [get_property parent.project_path [current_project] -quiet]
set current_prj_path [file dirname $parent]
set ::env(JFM_PATH) $current_prj_path
set run_tcl_path [file join $::env(JFM_PATH) "ip_patch" "run.tcl"]
source $run_tcl_path

proc ensure_mig_dcp {project_dir} {
    set ip_name "mig_7series_0"
    set src_dcp [file join $project_dir "LPVX30_0040.srcs" "sources_1" "ip" $ip_name "${ip_name}.dcp"]
    set run_dcp [file join $project_dir "LPVX30_0040.runs" "${ip_name}_synth_1" "${ip_name}.dcp"]

    if {[file exists $src_dcp]} {
        return
    }

    if {![file exists $run_dcp]} {
        set ip_obj [get_ips -quiet $ip_name]
        if {[llength $ip_obj] == 0} {
            error "Required IP '$ip_name' was not found while preparing $src_dcp"
        }

        puts "MIG checkpoint is missing. Launching ${ip_name}_synth_1 to generate it."
        catch {generate_target synthesis $ip_obj} gen_msg
        if {$gen_msg ne ""} {
            puts "generate_target synthesis $ip_name: $gen_msg"
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
            if {[string match "*Error*" $run_status] || [string match "*Out-of-date*" $run_status]} {
                catch {reset_run ${ip_name}_synth_1}
            }
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

set prj_path [get_prj_path]
open_project $prj_path
ensure_mig_dcp $current_prj_path
puts "step 1:pre_patch_check"
pre_patch_check
puts "step 2:pre_synthesis_patch"
pre_synthesis_patch 
puts "step 3:runEco0"
close_project
