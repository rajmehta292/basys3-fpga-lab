# XSDB hardware probe. This is deliberately read-only.
set url "tcp:localhost:3121"
if {$argc >= 1} {
    set url [lindex $argv 0]
}
connect -url $url
puts "Connected to $url"
puts "JTAG servers:"
catch {jtag servers} jtag_servers
puts $jtag_servers
puts "JTAG targets:"
catch {jtag targets} jtag_targets
puts $jtag_targets
puts "Debug targets:"
catch {targets} debug_targets
puts $debug_targets
disconnect
