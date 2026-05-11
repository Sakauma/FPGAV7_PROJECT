# Source this file in an already-open Vivado session before launching runs:
#   source tools/setup_vivado_user_data.tcl

proc ensure_xilinx_local_user_data {} {
    set current ""
    if {[info exists ::env(XILINX_LOCAL_USER_DATA)]} {
        set current $::env(XILINX_LOCAL_USER_DATA)
    }

    if {$current ne "" && [string first " " $current] < 0} {
        if {![catch {file mkdir $current} mkdir_msg]} {
            puts "Using XILINX_LOCAL_USER_DATA=$current"
            return
        }
        puts "WARNING: unable to create XILINX_LOCAL_USER_DATA '$current': $mkdir_msg"
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

    error "Unable to configure XILINX_LOCAL_USER_DATA. Set it manually to a no-space path, such as D:/XilinxLocalUserData."
}

ensure_xilinx_local_user_data
