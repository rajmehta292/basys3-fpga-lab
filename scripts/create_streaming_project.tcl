# Create the managed Vivado project for the complete streaming top level.
# Run from any directory with:
#   vivado -mode batch -source scripts/create_streaming_project.tcl

set script_dir [file dirname [file normalize [info script]]]
set root_dir   [file normalize [file join $script_dir ..]]
set project_dir [file join $root_dir build basys3_streaming]

create_project basys3_streaming $project_dir -part xc7a35tcpg236-1 -force
set_property target_language Verilog [current_project]

set rtl_files [glob -nocomplain [file join $root_dir rtl *.v]]
if {[llength $rtl_files] == 0} {
    error "No RTL files found under $root_dir/rtl"
}
add_files -norecurse $rtl_files

set constraint_file [file join $root_dir constraints basys3_streaming.xdc]
add_files -fileset constrs_1 -norecurse $constraint_file

set sim_files [glob -nocomplain [file join $root_dir sim tb_*.v]]
if {[llength $sim_files] != 0} {
    add_files -fileset sim_1 -norecurse $sim_files
}

set_property top top_streaming [get_filesets sources_1]
set_property top tb_stream_pipeline [get_filesets sim_1]
set_property simulator_language Verilog [get_filesets sim_1]
update_compile_order -fileset sources_1
update_compile_order -fileset sim_1

puts "Created project: $project_dir"
puts "Design top: top_streaming"
puts "Default simulation top: tb_stream_pipeline"
puts "Part: xc7a35tcpg236-1"
