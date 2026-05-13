set script_dir [file dirname [file normalize [info script]]]
set project_dir [file join $script_dir video_gray10_axis_prj]

open_project $project_dir
set_top video_gray10_axis
open_solution solution1 -flow_target vivado
set_part {xc7vx690tffg1927-2}
create_clock -period 5 -name default
add_files [file join $script_dir src/video_gray10_axis.cpp]
add_files -tb [file join $script_dir src/video_gray10_axis.cpp] -cflags "-I[file join $script_dir src]"
add_files -tb [file join $script_dir tb/video_gray10_axis_tb.cpp] -cflags "-I[file join $script_dir src]"
csim_design
csynth_design
exit
