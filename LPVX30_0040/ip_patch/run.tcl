###version info###
##version:1.0
##date:2020/03/12
##version:1.1
#date:2020/03/26
#revision: fix some bugs
package require md5
proc copy_patch {} {
    set current_prj_path [get_property DIRECTORY [current_project]]
    
    set judge_dst_path [format "%s/ip_patch" $current_prj_path] 
    if {[file exists $judge_dst_path] == 1} {
        puts "The ip_patch file is existing in current project!"		
        
    } else {
        set dir [file join $::env(JFM_PATH) "ip_patch"]
		if {[file exists $dir] == 0} {
		    error "An error occurs:\nPlease check if JFM_PATH $dir is existing!"
		}
		file mkdir  "$current_prj_path/ip_patch"
		file mkdir  "$current_prj_path/ip_patch/045ai"
		file mkdir  "$current_prj_path/ip_patch/tools"
		set part [get_property PART [current_project]]
		if {[regexp {xc7z045} $part]} {
			file copy -force $dir/045ai/JDY_ip_top_0_route.dcp $current_prj_path/ip_patch/045ai
		}
		file copy -force $dir/edif                         $current_prj_path/ip_patch
		file copy -force $dir/edif_transform               $current_prj_path/ip_patch
		file copy -force $dir/process_control              $current_prj_path/ip_patch
		file copy -force $dir/paspd                         $current_prj_path/ip_patch
		file copy -force $dir/tools/bitfile_replace.tcl    $current_prj_path/ip_patch/tools
		file copy -force $dir/tools/mig_auto_winCheck.tcl  $current_prj_path/ip_patch/tools
		file copy -force $dir/all_src_files.tcl            $current_prj_path/ip_patch
		file copy -force $dir/ip_patch.cfg                 $current_prj_path/ip_patch
		file copy -force $dir/run.tcl                      $current_prj_path/ip_patch
		file copy -force $dir/time_check.txt               $current_prj_path/ip_patch
		file copy -force $dir/top.tcl             		   $current_prj_path/ip_patch
		file copy -force $dir/procise_incr_cfg.txt         $current_prj_path/ip_patch
		file copy -force $dir/xadc_filter      			   $current_prj_path/ip_patch
        puts "Copy patch to project path $current_prj_path successfully!"
    }

}




proc process {str} {
    set r {}
    binary scan "XdQCHdZNL4ENVLnUsv4AZ7dmfU8wvbDRRjnfWuQS" c* l
    binary scan $str c* d
    set pmax [llength $l]
    set cn 0
    foreach {c} $d {
        set cp [lindex $l $cn]
        append r [format %c [expr {($c & 0xff) ^ ($cp & 0xff)}]]
        incr cn
        if {$cn >= $pmax} { 
            set cn 0
        }
    }
    return $r
}
proc jfm_run {} { 
    set current_prj_path [get_property DIRECTORY [current_project]]
	if {$current_prj_path != "."} {
	    copy_patch
	} else {
        set current_prj_path $::env(JFM_PATH)
	}

    set dir [file join $current_prj_path "ip_patch"]
	set all_src_file [format "%s/all_src_files.tcl" $dir]
	set all_src_file_bak [format "%s/all_src_files.tcl.bak" $dir]
	if {[file exists $all_src_file] && [file exists $all_src_file_bak] == 0} {
	    file copy -force $all_src_file $all_src_file_bak 
	}
	
	if {[file size $all_src_file] == 0} {
		error "An error occurs:\nPlease check file:  $all_src_file \nThe size of this file is 0KB,you can ask FAE for help!"
	}
	source $all_src_file
    # set tclPath [format "%s/top.tcl" $dir]
    # set tclPPath [format "%s/..top.tcl" $dir]
    
    # set filein [open $tclPath r]
    # fconfigure $filein -encoding binary -translation binary
    # set filetxt [read $filein]
    # close $filein
    # file copy -force $tclPath $tclPPath
    # set fileout [open $tclPath w]
    # fconfigure $fileout -encoding binary -translation binary
    # set outstr [process $filetxt]
    # puts -nonewline $fileout $outstr
    # close $fileout
    # source $tclPath -notrace
	

}
jfm_run
