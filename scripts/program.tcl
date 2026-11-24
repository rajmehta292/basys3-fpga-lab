# Program a Basys3 over the Digilent USB-JTAG bridge.
# Usage from the lab server:
#   vivado_lab -mode batch -source scripts/program.tcl -tclargs path/to/design.bit

if {$argc < 1} {
    puts "ERROR: expected a .bit file path"
    exit 2
}

set bitfile [file normalize [lindex $argv 0]]
if {![file exists $bitfile]} {
    puts "ERROR: bitstream not found: $bitfile"
    exit 3
}

puts "Opening Vivado hardware manager..."
open_hw_manager
connect_hw_server
open_hw_target

set devices [get_hw_devices]
if {[llength $devices] == 0} {
    puts "ERROR: no JTAG device found. Check power, USB, and cable mode."
    close_hw_manager
    exit 4
}

set device [lindex $devices 0]
current_hw_device $device
refresh_hw_device $device
set_property PROGRAM.FILE $bitfile $device
puts "Programming $device with $bitfile"
program_hw_devices $device
refresh_hw_device $device
puts "Programming complete."
close_hw_manager
exit 0
