# DISTIRBUTED
create_pblock pblock_1
add_cells_to_pblock [get_pblocks pblock_1] [get_cells -quiet [list {trng_inst/entropy_cell_gen[0].neoTRNG_cell_inst}]]
resize_pblock [get_pblocks pblock_1] -add {SLICE_X0Y97:SLICE_X5Y99}
create_pblock pblock_2
add_cells_to_pblock [get_pblocks pblock_2] [get_cells -quiet [list {trng_inst/entropy_cell_gen[1].neoTRNG_cell_inst}]]
resize_pblock [get_pblocks pblock_2] -add {SLICE_X38Y96:SLICE_X43Y99}
create_pblock pblock_3
add_cells_to_pblock [get_pblocks pblock_3] [get_cells -quiet [list {trng_inst/entropy_cell_gen[2].neoTRNG_cell_inst}]]
resize_pblock [get_pblocks pblock_3] -add {SLICE_X38Y0:SLICE_X43Y3}

# LOCALIZED
#create_pblock pblock_1
#add_cells_to_pblock [get_pblocks pblock_1] [get_cells -quiet [list {trng_inst/entropy_cell_gen[0].neoTRNG_cell_inst}]]
#resize_pblock [get_pblocks pblock_1] -add {SLICE_X22Y59:SLICE_X25Y61}
#create_pblock pblock_2
#add_cells_to_pblock [get_pblocks pblock_2] [get_cells -quiet [list {trng_inst/entropy_cell_gen[1].neoTRNG_cell_inst}]]
#resize_pblock [get_pblocks pblock_2] -add {SLICE_X22Y56:SLICE_X25Y58}
#create_pblock pblock_3
#add_cells_to_pblock [get_pblocks pblock_3] [get_cells -quiet [list {trng_inst/entropy_cell_gen[2].neoTRNG_cell_inst}]]
#resize_pblock [get_pblocks pblock_3] -add {SLICE_X22Y53:SLICE_X25Y55}


