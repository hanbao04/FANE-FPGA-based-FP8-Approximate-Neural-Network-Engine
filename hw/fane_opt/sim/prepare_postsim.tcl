# Export both process corners and analyze the routed core at the sim clock.
# Usage: vivado -mode batch -source prepare_postsim.tcl -tclargs CONFIG_DIR PERIOD_NS
if {$argc != 2} { error "Expected: config_dir clock_period_ns" }
lassign $argv config_dir period_ns
set config_dir [file normalize $config_dir]
set_param general.maxThreads 8
open_checkpoint [file join $config_dir post_route.dcp]
create_clock -period $period_ns -name clk -waveform [list 0.0 [expr {$period_ns / 2.0}]] [get_ports clk]
set netlist_file [open [file join $config_dir post_route_time.v] r]
set netlist_source [read $netlist_file]
close $netlist_file
if {![regexp {module\s+(dsp_[a-z_]+_netlist)\s} $netlist_source -> netlist_top]} {
    error "Unable to identify the exported timing netlist top"
}
write_sdf -force -process_corner slow -rename_top $netlist_top [file join $config_dir post_route.sdf]
write_sdf -force -process_corner fast -rename_top $netlist_top [file join $config_dir post_route_fast.sdf]
report_timing_summary -delay_type min_max -report_unconstrained -max_paths 10 \
    -file [file join $config_dir timing_at_${period_ns}ns.rpt]
set setup_paths [get_timing_paths -delay_type max -max_paths 1]
set hold_paths [get_timing_paths -delay_type min -max_paths 1]
set setup_slack [get_property SLACK $setup_paths]
set hold_slack [get_property SLACK $hold_paths]
set fp [open [file join $config_dir sta_at_${period_ns}ns.txt] w]
puts $fp "period_ns=$period_ns WNS=$setup_slack WHS=$hold_slack"
close $fp
puts "POSTSIM_STA period_ns=$period_ns WNS=$setup_slack WHS=$hold_slack"
exit
