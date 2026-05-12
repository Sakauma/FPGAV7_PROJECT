set script_dir [file dirname [file normalize [info script]]]
set repo_dir [file normalize [file join $script_dir ..]]
set project_file [file join $repo_dir LPVX30_0040 LPVX30_0040.xpr]
set report_dir [file join $repo_dir LPVX30_0040 reports]

set build_step "bitstream"
if {$argc > 0} {
  set build_step [lindex $argv 0]
}

if {$build_step ni {"synth" "impl" "bitstream"}} {
  error "Usage: vivado -mode batch -source tools/run_vivado_2025_build.tcl -tclargs synth|impl|bitstream"
}

file mkdir $report_dir
set_param general.maxThreads 8

open_project $project_file
update_compile_order -fileset sources_1

reset_run synth_1
launch_runs synth_1 -jobs 8
wait_on_run synth_1
set synth_status [get_property STATUS [get_runs synth_1]]
puts "SYNTH_STATUS=$synth_status"
if {[string first "Complete" $synth_status] < 0} {
  error "synth_1 did not complete: $synth_status"
}

open_run synth_1 -name synth_netlist
report_timing_summary -file [file join $report_dir synth_timing_summary.rpt] -warn_on_violation
report_utilization -file [file join $report_dir synth_utilization.rpt]
report_drc -file [file join $report_dir synth_drc.rpt]
close_design

if {$build_step eq "synth"} {
  close_project
  exit
}

reset_run impl_1
if {$build_step eq "bitstream"} {
  launch_runs impl_1 -to_step write_bitstream -jobs 8
} else {
  launch_runs impl_1 -jobs 8
}
wait_on_run impl_1
set impl_status [get_property STATUS [get_runs impl_1]]
puts "IMPL_STATUS=$impl_status"
if {[string first "Complete" $impl_status] < 0} {
  error "impl_1 did not complete: $impl_status"
}

open_run impl_1
report_timing_summary -file [file join $report_dir impl_timing_summary.rpt] -warn_on_violation
report_utilization -file [file join $report_dir impl_utilization.rpt]
report_drc -file [file join $report_dir impl_drc.rpt]
report_io -file [file join $report_dir impl_io.rpt]
close_project
