set_property SRC_FILE_INFO {cfile:/home/szymon/Desktop/magister/base_RTL/project_base/project_base.srcs/constrs_1/new/physical.xdc rfile:../../../project_base.srcs/constrs_1/new/physical.xdc id:1} [current_design]
set_property SRC_FILE_INFO {cfile:/home/szymon/Desktop/magister/base_RTL/project_base/project_base.srcs/constrs_1/new/pblocks.xdc rfile:../../../project_base.srcs/constrs_1/new/pblocks.xdc id:2} [current_design]
set_property src_info {type:XDC file:1 line:3 export:INPUT save:INPUT read:READ} [current_design]
set_property PACKAGE_PIN H16 [get_ports clk]
set_property src_info {type:XDC file:1 line:4 export:INPUT save:INPUT read:READ} [current_design]
set_property PACKAGE_PIN G15 [get_ports tx]
set_property src_info {type:XDC file:2 line:42 export:INPUT save:INPUT read:READ} [current_design]
create_pblock pblock_1
add_cells_to_pblock [get_pblocks pblock_1] [get_cells -quiet [list {trng_inst/entropy_cell_gen[0].neoTRNG_cell_inst}]]
resize_pblock [get_pblocks pblock_1] -add {SLICE_X14Y95:SLICE_X21Y99}
set_property src_info {type:XDC file:2 line:45 export:INPUT save:INPUT read:READ} [current_design]
create_pblock pblock_2
add_cells_to_pblock [get_pblocks pblock_2] [get_cells -quiet [list {trng_inst/entropy_cell_gen[1].neoTRNG_cell_inst}]]
resize_pblock [get_pblocks pblock_2] -add {SLICE_X0Y78:SLICE_X5Y82}
set_property src_info {type:XDC file:2 line:48 export:INPUT save:INPUT read:READ} [current_design]
create_pblock pblock_3
add_cells_to_pblock [get_pblocks pblock_3] [get_cells -quiet [list {trng_inst/entropy_cell_gen[2].neoTRNG_cell_inst}]]
resize_pblock [get_pblocks pblock_3] -add {SLICE_X0Y22:SLICE_X5Y26}
set_property src_info {type:XDC file:2 line:51 export:INPUT save:INPUT read:READ} [current_design]
create_pblock pblock_4
add_cells_to_pblock [get_pblocks pblock_4] [get_cells -quiet [list {trng_inst/entropy_cell_gen[3].neoTRNG_cell_inst}]]
resize_pblock [get_pblocks pblock_4] -add {SLICE_X22Y2:SLICE_X25Y6}
set_property src_info {type:XDC file:2 line:54 export:INPUT save:INPUT read:READ} [current_design]
create_pblock pblock_5
add_cells_to_pblock [get_pblocks pblock_5] [get_cells -quiet [list {trng_inst/entropy_cell_gen[4].neoTRNG_cell_inst}]]
resize_pblock [get_pblocks pblock_5] -add {SLICE_X40Y82:SLICE_X43Y86}
set_property src_info {type:XDC file:2 line:57 export:INPUT save:INPUT read:READ} [current_design]
create_pblock pblock_6
add_cells_to_pblock [get_pblocks pblock_6] [get_cells -quiet [list {trng_inst/entropy_cell_gen[5].neoTRNG_cell_inst}]]
resize_pblock [get_pblocks pblock_6] -add {SLICE_X40Y25:SLICE_X43Y29}
