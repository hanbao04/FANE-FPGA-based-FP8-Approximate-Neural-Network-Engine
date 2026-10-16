# Y=1 core synthesis + implementation for netlist simulation.
# Usage: vivado -mode batch -source build_postsim.tcl -tclargs mvm|conv OUT_DIR IMG_W IMG_D PERIOD_NS CARRY_REMAP
# Writes the netlists and SDFs the simulations need and prints WNS/WHS at PERIOD_NS.
# Ports remain internal core interfaces; no board pin assignment/bitstream.
if {$argc != 6} { error "Expected: mvm|conv output_dir image_width image_height period_ns carry_remap" }
lassign $argv target output_dir image_width image_height period_ns carry_remap
set output_dir [file normalize $output_dir]
set sim_dir [file dirname [file normalize [info script]]]
set repo_dir [file normalize [file join $sim_dir ../../..]]
set part xck26-sfvc784-2LV-c
set_param general.maxThreads 8
create_project -in_memory -part $part
if {$target eq "mvm"} {
    set rtl_dir [file join $repo_dir hw/fane_opt/mm/v_opt]
    set top dsp_mm_chip
    set sources {mm_chip.sv mm_top.v mm.v fpmac_mm.v addmul.v fpadder.v bram_adder.v}
} elseif {$target eq "conv"} {
    set rtl_dir [file join $repo_dir hw/fane_opt/conv/v_opt]
    set top dsp_conv_chip
    set sources {conv_chip.sv conv_top.v addr_gen.v conv.v fpmac_conv.v fp8_addmul.v fp8_adder.v carry8_adder.v md_in.v md_out.v mux_add_exp.v mux_add_mant.v}
} else { error "Unknown target $target" }
foreach source $sources { read_verilog -sv [file join $rtl_dir $source] }
read_xdc [file join $rtl_dir constraints.xdc]
synth_design -top $top -part $part -mode out_of_context \
    -generic Y=1 -generic IMG_W=$image_width -generic IMG_D=$image_height
write_verilog -force -mode funcsim -rename_top ${top}_netlist [file join $output_dir post_synth_func.v]
if {$carry_remap > 0} {
    set carries [get_cells -hier -filter {REF_NAME == CARRY8}]
    # Release only the carry chains' ancestor boundaries for the official
    # equivalent LUT mapping. RAM primitive preservation remains intact.
    foreach carry $carries {
        set_property DONT_TOUCH false $carry
        set parent [file dirname [get_property NAME $carry]]
        while {$parent ne "." && $parent ne "/"} {
            set objects [get_cells -hier -filter "NAME == \"$parent\""]
            if {[llength $objects]} {set_property DONT_TOUCH false $objects}
            set parent [file dirname $parent]
        }
    }
    set_property CARRY_REMAP $carry_remap $carries
    opt_design -carry_remap
} else {
    opt_design
}
place_design -directive Explore
phys_opt_design
route_design -directive Explore
write_verilog -force -mode funcsim -rename_top ${top}_netlist [file join $output_dir post_route_func.v]
write_verilog -force -mode timesim -sdf_anno false -rename_top ${top}_netlist [file join $output_dir post_route_time.v]
write_sdf -force -process_corner slow -rename_top ${top}_netlist [file join $output_dir post_route.sdf]
write_sdf -force -process_corner fast -rename_top ${top}_netlist [file join $output_dir post_route_fast.sdf]
# Timing at the simulation clock (the XDC clock was used for implementation).
create_clock -period $period_ns -name clk -waveform [list 0.0 [expr {$period_ns / 2.0}]] [get_ports clk]
set setup_slack [get_property SLACK [get_timing_paths -delay_type max -max_paths 1]]
set hold_slack [get_property SLACK [get_timing_paths -delay_type min -max_paths 1]]
puts "POSTSIM_STA period_ns=$period_ns WNS=$setup_slack WHS=$hold_slack"
exit
