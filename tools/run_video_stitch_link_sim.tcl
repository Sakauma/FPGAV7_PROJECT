set script_dir [file dirname [file normalize [info script]]]
set repo_dir [file normalize [file join $script_dir ..]]
set project_file [file join $repo_dir LPVX30_0040 LPVX30_0040.xpr]
set generated_backup_dir [file normalize [file join $repo_dir .. .. _generated_backup]]
set project_backup [file join $generated_backup_dir [format "LPVX30_0040.xpr.sim_backup_%s" [clock format [clock seconds] -format "%Y%m%d_%H%M%S"]]]
set dfx_runtime_file [file join $repo_dir dfx_runtime.txt]

file mkdir $generated_backup_dir
file copy -force $project_file $project_backup
set sim_status [catch {
  open_project $project_file
  set tb_file [file join $repo_dir HDL TB video_stitch_link_tb.v]
  if {[llength [get_files -quiet $tb_file]] == 0} {
    add_files -fileset sim_1 $tb_file
  }
  set_property top video_stitch_link_tb [get_filesets sim_1]
  # The project keeps an old convertb waveform config; clear it for this batch smoke test.
  catch {set_property XSimWcfgFile "" [get_filesets sim_1]}
  set_property -name {xsim.simulate.runtime} -value {3000us} -objects [get_filesets sim_1]
  update_compile_order -fileset sim_1
  launch_simulation -mode behavioral
  close_sim
  close_project
} sim_error sim_options]

if {[catch {close_sim}]} {}
if {[catch {close_project}]} {}
file copy -force $project_backup $project_file
if {[file exists $dfx_runtime_file]} {
  set dfx_backup_name [format "dfx_runtime_%s.txt" [clock format [clock seconds] -format "%Y%m%d_%H%M%S"]]
  file copy -force $dfx_runtime_file [file join $generated_backup_dir $dfx_backup_name]
  file delete -force $dfx_runtime_file
}

if {$sim_status != 0} {
  return -options $sim_options $sim_error
}
