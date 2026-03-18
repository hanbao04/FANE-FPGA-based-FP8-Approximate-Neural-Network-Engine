create_clock -period 4.000 -name clk -waveform {0.000 2.000} [get_ports clk]

 create_pblock pblock_clustered_logic

 add_cells_to_pblock [get_pblocks pblock_clustered_logic] [get_cells -hierarchical -filter {NAME =~ "*name[0].dut"}]
 add_cells_to_pblock [get_pblocks pblock_clustered_logic] [get_cells -hierarchical -filter {NAME =~ "*name[1].dut"}]
 add_cells_to_pblock [get_pblocks pblock_clustered_logic] [get_cells -hierarchical -filter {NAME =~ "*name[2].dut"}]
 add_cells_to_pblock [get_pblocks pblock_clustered_logic] [get_cells -hierarchical -filter {NAME =~ "*name[3].dut"}]
# add_cells_to_pblock [get_pblocks pblock_clustered_logic] [get_cells -hierarchical -filter {NAME =~ "*name[4].dut"}]
# add_cells_to_pblock [get_pblocks pblock_clustered_logic] [get_cells -hierarchical -filter {NAME =~ "*name[5].dut"}]
# add_cells_to_pblock [get_pblocks pblock_clustered_logic] [get_cells -hierarchical -filter {NAME =~ "*name[6].dut"}]
# add_cells_to_pblock [get_pblocks pblock_clustered_logic] [get_cells -hierarchical -filter {NAME =~ "*name[7].dut"}]
# add_cells_to_pblock [get_pblocks pblock_clustered_logic] [get_cells -hierarchical -filter {NAME =~ "*name[8].dut"}]
# add_cells_to_pblock [get_pblocks pblock_clustered_logic] [get_cells -hierarchical -filter {NAME =~ "*name[9].dut"}]
# add_cells_to_pblock [get_pblocks pblock_clustered_logic] [get_cells -hierarchical -filter {NAME =~ "*name[10].dut"}]
# add_cells_to_pblock [get_pblocks pblock_clustered_logic] [get_cells -hierarchical -filter {NAME =~ "*name[11].dut"}]
# add_cells_to_pblock [get_pblocks pblock_clustered_logic] [get_cells -hierarchical -filter {NAME =~ "*name[12].dut"}]
# add_cells_to_pblock [get_pblocks pblock_clustered_logic] [get_cells -hierarchical -filter {NAME =~ "*name[13].dut"}]
# add_cells_to_pblock [get_pblocks pblock_clustered_logic] [get_cells -hierarchical -filter {NAME =~ "*name[14].dut"}]
# add_cells_to_pblock [get_pblocks pblock_clustered_logic] [get_cells -hierarchical -filter {NAME =~ "*name[15].dut"}]
# add_cells_to_pblock [get_pblocks pblock_clustered_logic] [get_cells -hierarchical -filter {NAME =~ "*name[16].dut"}]
# add_cells_to_pblock [get_pblocks pblock_clustered_logic] [get_cells -hierarchical -filter {NAME =~ "*name[17].dut"}]
# add_cells_to_pblock [get_pblocks pblock_clustered_logic] [get_cells -hierarchical -filter {NAME =~ "*name[18].dut"}]
# add_cells_to_pblock [get_pblocks pblock_clustered_logic] [get_cells -hierarchical -filter {NAME =~ "*name[19].dut"}]
# add_cells_to_pblock [get_pblocks pblock_clustered_logic] [get_cells -hierarchical -filter {NAME =~ "*name[20].dut"}]
# add_cells_to_pblock [get_pblocks pblock_clustered_logic] [get_cells -hierarchical -filter {NAME =~ "*name[21].dut"}]
# add_cells_to_pblock [get_pblocks pblock_clustered_logic] [get_cells -hierarchical -filter {NAME =~ "*name[22].dut"}]
# add_cells_to_pblock [get_pblocks pblock_clustered_logic] [get_cells -hierarchical -filter {NAME =~ "*name[23].dut"}]

resize_pblock [get_pblocks pblock_clustered_logic] -add CLOCKREGION_X1Y0
resize_pblock [get_pblocks pblock_clustered_logic] -add CLOCKREGION_X1Y1
resize_pblock [get_pblocks pblock_clustered_logic] -add CLOCKREGION_X2Y0
resize_pblock [get_pblocks pblock_clustered_logic] -add CLOCKREGION_X2Y1
# resize_pblock [get_pblocks pblock_clustered_logic] -add CLOCKREGION_X3Y1
# resize_pblock [get_pblocks pblock_clustered_logic] -add CLOCKREGION_X4Y2
# resize_pblock [get_pblocks pblock_clustered_logic] -add CLOCKREGION_X3Y2
# resize_pblock [get_pblocks pblock_clustered_logic] -add CLOCKREGION_X4Y3
# resize_pblock [get_pblocks pblock_clustered_logic] -add CLOCKREGION_X3Y3
# resize_pblock [get_pblocks pblock_clustered_logic] -add CLOCKREGION_X4Y4
# resize_pblock [get_pblocks pblock_clustered_logic] -add CLOCKREGION_X3Y4
# resize_pblock [get_pblocks pblock_clustered_logic] -add CLOCKREGION_X4Y5
# resize_pblock [get_pblocks pblock_clustered_logic] -add CLOCKREGION_X3Y5

 set_property IS_SOFT FALSE [get_pblocks pblock_clustered_logic]
 
 set_property HD.TREAT_INFERRED_CONSTANT_DRIVERS_AS_UNCONNECTED false [current_design]