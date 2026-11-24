# Program a .bit file through Vivado Lab Edition Hardware Manager.
if {$argc < 1} {
    puts stderr "Usage: vivado_lab -mode batch -source program_vivado_lab.tcl -tclargs <bitstream> ?hw_server_url?"
    exit 2
}

set bitfile [file normalize [lindex $argv 0]]
set url "localhost:3121"
if {$argc >= 2} {
    set url [lindex $argv 1]
}
if {![file exists $bitfile]} {
    puts stderr "Bitstream does not exist: $bitfile"
    exit 2
}

open_hw_manager
connect_hw_server -url $url
open_hw_target
set devices [get_hw_devices]
if {[llength $devices] == 0} {
    error "No FPGA device found. Check JP1=JTAG, power, USB cable, and udev access."
}
set device [lindex $devices 0]
current_hw_device $device
refresh_hw_device $device
set_property PROGRAM.FILE $bitfile $device
program_hw_devices $device
refresh_hw_device $device
puts "Programming completed for $device"
close_hw_target
disconnect_hw_server
close_hw_manager
