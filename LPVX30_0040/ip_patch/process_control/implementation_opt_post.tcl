set ::env(JFM_PATH) [file join [pwd] "../.."]
set run_tcl_path [file join $::env(JFM_PATH) "ip_patch" "run.tcl"]
source $run_tcl_path
set prj_path [get_prj_path]
open_project $prj_path
puts "step 4:post_opt_design_patch"
close_project
post_opt_design_patch 

set JDY_top_u0_cell [get_cells -hierarchical -regexp  -filter {REF_NAME=~JDY_ip_top_.* || ORIG_REF_NAME=~JDY_ip_top_.*}]
if { [get_cells $JDY_top_u0_cell] != ""} {
	set_property PROHIBIT true [get_sites -range {SLICE_X32Y75 SLICE_X79Y129}]
	set_property PROHIBIT true [get_sites -range {SLICE_X30Y20 SLICE_X81Y74}]
	set_property PROHIBIT true [get_sites -range {DSP48_X2Y8 DSP48_X3Y52}]
	set_property PROHIBIT true [get_sites -range {RAMB18_X2Y8 RAMB18_X3Y52}]
	set_property PROHIBIT true [get_sites -range {RAMB36_X2Y4 RAMB36_X3Y26}]
	
	set_property PROHIBIT true [get_sites -range {SLICE_X94Y0 SLICE_X97Y29}]
	set_property PROHIBIT true [get_sites -range {SLICE_X92Y24 SLICE_X93Y29}]
	set_property PROHIBIT true [get_sites -range {DSP48_X4Y0 DSP48_X4Y11}]
	set_property PROHIBIT true [get_sites -range {RAMB18_X4Y0 RAMB18_X4Y11}]
	set_property PROHIBIT true [get_sites -range {RAMB36_X4Y0 RAMB36_X4Y5}]
	set_property PROHIBIT true [get_sites -range {DSP48_X6Y0 DSP48_X6Y139}]
}
		
