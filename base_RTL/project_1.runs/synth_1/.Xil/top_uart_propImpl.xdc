set_property SRC_FILE_INFO {cfile:/home/szymon/Desktop/magister/base_RTL/project_1.srcs/constrs_1/new/physical.xdc rfile:../../../project_1.srcs/constrs_1/new/physical.xdc id:1} [current_design]
set_property SRC_FILE_INFO {cfile:/home/szymon/Desktop/magister/base_RTL/project_1.srcs/constrs_1/new/pblocks.xdc rfile:../../../project_1.srcs/constrs_1/new/pblocks.xdc id:2} [current_design]
set_property src_info {type:XDC file:1 line:3 export:INPUT save:INPUT read:READ} [current_design]
set_property PACKAGE_PIN H16 [get_ports clk]
set_property src_info {type:XDC file:1 line:4 export:INPUT save:INPUT read:READ} [current_design]
set_property PACKAGE_PIN G15 [get_ports tx]
set_property src_info {type:XDC file:2 line:19 export:INPUT save:INPUT read:READ} [current_design]
create_pblock pblock_1
add_cells_to_pblock [get_pblocks pblock_1] [get_cells -quiet [list {trng_inst/entropy_cell_gen[0].neoTRNG_cell_inst}]]
resize_pblock [get_pblocks pblock_1] -add {SLICE_X14Y51:SLICE_X21Y60}
set_property src_info {type:XDC file:2 line:22 export:INPUT save:INPUT read:READ} [current_design]
create_pblock pblock_2
add_cells_to_pblock [get_pblocks pblock_2] [get_cells -quiet [list {trng_inst/entropy_cell_gen[1].neoTRNG_cell_inst}]]
resize_pblock [get_pblocks pblock_2] -add {SLICE_X22Y40:SLICE_X27Y49}
resize_pblock [get_pblocks pblock_2] -add {RAMB18_X1Y16:RAMB18_X1Y19}
resize_pblock [get_pblocks pblock_2] -add {RAMB36_X1Y8:RAMB36_X1Y9}
set_property src_info {type:XDC file:2 line:27 export:INPUT save:INPUT read:READ} [current_design]
create_pblock pblock_3
add_cells_to_pblock [get_pblocks pblock_3] [get_cells -quiet [list {trng_inst/entropy_cell_gen[2].neoTRNG_cell_inst}]]
resize_pblock [get_pblocks pblock_3] -add {SLICE_X14Y40:SLICE_X21Y49}
