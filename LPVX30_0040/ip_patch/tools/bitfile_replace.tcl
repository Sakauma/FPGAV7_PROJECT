proc bitfile_replace {} {
	set report_env [report_environment -return_string -quiet]
    set list [split $report_env "\n"]
    foreach line $list {
        if {[regexp {ISL_IOSTREAMS_RSA=(.*)/tps/isl} $line match path]} {    
        }
    }
	set vvd_bitfile_path     [format "%s/data/xicom/cfgmem/bitfile.zip" $path]
	set vvd_bitfile_bak_path [format "%s.bak" $vvd_bitfile_path]
	if {[file exists $vvd_bitfile_bak_path]} {
		return
	}
	file copy -force $vvd_bitfile_path $vvd_bitfile_bak_path
	set path [file join $::env(JFM_PATH)]
	set fmsh_bitfile_path [format  "%s/ip_patch/tools/bitfile.zip" $path]  
	file copy -force $fmsh_bitfile_path $vvd_bitfile_path
	puts "FMSH => $vvd_bitfile_path replaced successfully!"
}

proc bitfile_recover {} {
	set report_env [report_environment -return_string -quiet]
    set list [split $report_env "\n"]
    foreach line $list {
        if {[regexp {ISL_IOSTREAMS_RSA=(.*)/tps/isl} $line match path]} {    
        }
    }
	set vvd_bitfile_path     [format "%s/data/xicom/cfgmem/bitfile.zip" $path]
	set vvd_bitfile_bak_path [format "%s.bak" $vvd_bitfile_path]
	if {[file exists $vvd_bitfile_bak_path]} {
		file copy -force $vvd_bitfile_bak_path $vvd_bitfile_path
		file delete -force $vvd_bitfile_bak_path
	} else {
		return
	}
	puts "FMSH => $vvd_bitfile_path recovered successfully!"
}