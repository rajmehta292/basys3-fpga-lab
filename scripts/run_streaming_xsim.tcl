# Run the default self-checking streaming pipeline test in Vivado XSIM.

set script_dir [file dirname [file normalize [info script]]]
set root_dir   [file normalize [file join $script_dir ..]]
set project_dir [file join $root_dir build basys3_streaming]

if {![file exists $project_dir basys3_streaming.xpr]} {
    source [file join $script_dir create_streaming_project.tcl]
}
else {
    open_project [file join $project_dir basys3_streaming.xpr]
}

set_property top tb_stream_pipeline [get_filesets sim_1]
launch_simulation -mode behavioral
run all
