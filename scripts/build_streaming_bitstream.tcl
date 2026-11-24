# Synthesize, implement, report, and write the streaming bitstream.
# This script requires the full Vivado installation and the Artix-7 device
# files. It intentionally fails if timing or implementation fails.

set script_dir [file dirname [file normalize [info script]]]
set root_dir   [file normalize [file join $script_dir ..]]
set project_dir [file join $root_dir build basys3_streaming]
set result_dir [file join $root_dir results]

if {![file exists $project_dir basys3_streaming.xpr]} {
    source [file join $script_dir create_streaming_project.tcl]
}
else {
    open_project [file join $project_dir basys3_streaming.xpr]
}

file mkdir [file join $result_dir synthesis]
file mkdir [file join $result_dir timing]
file mkdir [file join $result_dir hardware]

reset_run synth_1
reset_run impl_1
launch_runs synth_1 -jobs 4
wait_on_run synth_1
if {[get_property STATUS [get_runs synth_1]] ne "synth_design Complete!"} {
    error "Synthesis did not complete successfully"
}

open_run synth_1
report_utilization -file [file join $result_dir synthesis utilization.rpt]
close_design

launch_runs impl_1 -to_step write_bitstream -jobs 4
wait_on_run impl_1
if {[get_property STATUS [get_runs impl_1]] ne "write_bitstream Complete!"} {
    error "Implementation/bitstream did not complete successfully"
}

open_run impl_1
report_timing_summary -delay_type max -file [file join $result_dir timing timing_summary.rpt]
report_timing_summary -delay_type min -file [file join $result_dir timing timing_hold_summary.rpt]
report_utilization -file [file join $result_dir synthesis implementation_utilization.rpt]

set bitstream [get_property BITSTREAM.FILE [get_runs impl_1]]
file copy -force $bitstream [file join $result_dir hardware basys3_streaming.bit]
puts "Generated: [file join $result_dir hardware basys3_streaming.bit]"
puts "Timing reports: [file join $result_dir timing]"
