create_clock -period 2.857 -name clk -waveform {0.000 1.428} [get_ports clk]

#  create_pblock pblock_clustered_logic

#  add_cells_to_pblock [get_pblocks pblock_clustered_logic] [get_cells -hierarchical -filter {NAME =~ "*name[0].dut"}]
#  add_cells_to_pblock [get_pblocks pblock_clustered_logic] [get_cells -hierarchical -filter {NAME =~ "*name[1].dut"}]
#  add_cells_to_pblock [get_pblocks pblock_clustered_logic] [get_cells -hierarchical -filter {NAME =~ "*name[2].dut"}]
#  add_cells_to_pblock [get_pblocks pblock_clustered_logic] [get_cells -hierarchical -filter {NAME =~ "*name[3].dut"}]
#  add_cells_to_pblock [get_pblocks pblock_clustered_logic] [get_cells -hierarchical -filter {NAME =~ "*name[4].dut"}]
#  add_cells_to_pblock [get_pblocks pblock_clustered_logic] [get_cells -hierarchical -filter {NAME =~ "*name[5].dut"}]


#  resize_pblock [get_pblocks pblock_clustered_logic] -add CLOCKREGION_X1Y5
#  resize_pblock [get_pblocks pblock_clustered_logic] -add CLOCKREGION_X1Y4
#  resize_pblock [get_pblocks pblock_clustered_logic] -add CLOCKREGION_X2Y5
#  resize_pblock [get_pblocks pblock_clustered_logic] -add CLOCKREGION_X2Y4


#  set_property IS_SOFT FALSE [get_pblocks pblock_clustered_logic]

#  set_property HD.TREAT_INFERRED_CONSTANT_DRIVERS_AS_UNCONNECTED false [current_design]