set script_dir [file dirname [file normalize [info script]]]
set repo_dir [file normalize [file join $script_dir ..]]
set project_file [file join $repo_dir LPVX30_0040 LPVX30_0040.xpr]

open_project $project_file
set tb_file [file join $repo_dir HDL TB video_stitch_link_tb.v]
if {[llength [get_files -quiet $tb_file]] == 0} {
  add_files -fileset sim_1 $tb_file
}
set_property top video_stitch_link_tb [get_filesets sim_1]
set_property -name {xsim.simulate.runtime} -value {3000us} -objects [get_filesets sim_1]
update_compile_order -fileset sources_1
update_compile_order -fileset sim_1
launch_simulation -mode behavioral
run all
close_sim
close_project
