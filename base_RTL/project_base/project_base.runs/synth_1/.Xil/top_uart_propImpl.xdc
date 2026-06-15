set_property SRC_FILE_INFO {cfile:/home/szymon/Desktop/magister/base_RTL/project_1.srcs/constrs_1/new/physical.xdc rfile:../../../project_1.srcs/constrs_1/new/physical.xdc id:1} [current_design]
set_property SRC_FILE_INFO {cfile:/home/szymon/Desktop/magister/base_RTL/project_1.srcs/constrs_1/new/pblocks.xdc rfile:../../../project_1.srcs/constrs_1/new/pblocks.xdc id:2} [current_design]
set_property src_info {type:XDC file:1 line:3 export:INPUT save:INPUT read:READ} [current_design]
set_property PACKAGE_PIN H16 [get_ports clk]
set_property src_info {type:XDC file:1 line:4 export:INPUT save:INPUT read:READ} [current_design]
set_property PACKAGE_PIN G15 [get_ports tx]
set_property src_info {type:XDC file:2 line:10 export:INPUT save:INPUT read:READ} [current_design]
create_pblock pblock_1
add_cells_to_pblock [get_pblocks pblock_1] [get_cells -quiet [list {trng_inst/entropy_cell_gen[0].neoTRNG_cell_inst}]]
resize_pblock [get_pblocks pblock_1] -add {SLICE_X22Y96:SLICE_X25Y99}
set_property src_info {type:XDC file:2 line:13 export:INPUT save:INPUT read:READ} [current_design]
create_pblock pblock_2
add_cells_to_pblock [get_pblocks pblock_2] [get_cells -quiet [list {trng_inst/entropy_cell_gen[1].neoTRNG_cell_inst}]]
resize_pblock [get_pblocks pblock_2] -add {SLICE_X24Y5:SLICE_X25Y9}
resize_pblock [get_pblocks pblock_2] -add {RAMB18_X1Y2:RAMB18_X1Y3}
resize_pblock [get_pblocks pblock_2] -add {RAMB36_X1Y1:RAMB36_X1Y1}
