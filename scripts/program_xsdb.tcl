# Program a .bit file through a running hw_server using XSDB.
if {$argc < 1} {
    puts stderr "Usage: xsdb program_xsdb.tcl <bitstream> ?hw_server_url?"
    exit 2
}

set bitfile [file normalize [lindex $argv 0]]
set url "tcp:localhost:3121"
if {$argc >= 2} {
    set url [lindex $argv 1]
}
if {![file exists $bitfile]} {
    puts stderr "Bitstream does not exist: $bitfile"
    exit 2
}

connect -url $url
puts "JTAG targets:"
jtag targets
puts "Debug targets:"
targets
puts "Programming $bitfile"
fpga -f $bitfile
puts "Programming command completed."
disconnect
