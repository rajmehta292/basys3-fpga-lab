# Non-project Vivado batch build.
set script_dir [file dirname [file normalize [info script]]]
set root      [file normalize [file join $script_dir ..]]
set out       [file join $root build]
file mkdir $out

read_verilog -sv [file join $root src basys3_demo.sv]
synth_design -top basys3_demo -part xc7a35tcpg236-1
read_xdc [file join $root constraints basys3_demo.xdc]
opt_design
place_design
phys_opt_design
route_design

report_utilization -file [file join $out utilization.rpt]
report_timing_summary -file [file join $out timing_summary.rpt] -warn_on_violation
write_bitstream -force [file join $out basys3_demo.bit]

puts "Bitstream: [file join $out basys3_demo.bit]"
