# Create a Vivado project for the Basys 3 bring-up design.
set script_dir [file dirname [file normalize [info script]]]
set root      [file normalize [file join $script_dir ..]]
set project   [file join $root build basys3_demo]

file mkdir [file join $root build]
create_project -force basys3_demo $project -part xc7a35tcpg236-1
set_property target_language Verilog [current_project]
add_files -norecurse [file join $root src basys3_demo.sv]
add_files -fileset constrs_1 -norecurse [file join $root constraints basys3_demo.xdc]
set_property top basys3_demo [current_fileset]
update_compile_order -fileset sources_1
update_compile_order -fileset sim_1
puts "Created project: $project"
close_project
