# DISTIRBUTED
#create_pblock pblock_1
#add_cells_to_pblock [get_pblocks pblock_1] [get_cells -quiet [list {trng_inst/entropy_cell_gen[0].neoTRNG_cell_inst}]]
#resize_pblock [get_pblocks pblock_1] -add {SLICE_X0Y85:SLICE_X9Y99}
#resize_pblock [get_pblocks pblock_1] -add {RAMB18_X0Y34:RAMB18_X0Y39}
#resize_pblock [get_pblocks pblock_1] -add {RAMB36_X0Y17:RAMB36_X0Y19}
#create_pblock pblock_2
#add_cells_to_pblock [get_pblocks pblock_2] [get_cells -quiet [list {trng_inst/entropy_cell_gen[1].neoTRNG_cell_inst}]]
#resize_pblock [get_pblocks pblock_2] -add {SLICE_X34Y85:SLICE_X43Y99}
#resize_pblock [get_pblocks pblock_2] -add {RAMB18_X2Y34:RAMB18_X2Y39}
#resize_pblock [get_pblocks pblock_2] -add {RAMB36_X2Y17:RAMB36_X2Y19}
#create_pblock pblock_3
#add_cells_to_pblock [get_pblocks pblock_3] [get_cells -quiet [list {trng_inst/entropy_cell_gen[2].neoTRNG_cell_inst}]]
#resize_pblock [get_pblocks pblock_3] -add {SLICE_X34Y0:SLICE_X43Y14}
#resize_pblock [get_pblocks pblock_3] -add {RAMB18_X2Y0:RAMB18_X2Y5}
#resize_pblock [get_pblocks pblock_3] -add {RAMB36_X2Y0:RAMB36_X2Y2}

# LOCALIZED
create_pblock pblock_1
add_cells_to_pblock [get_pblocks pblock_1] [get_cells -quiet [list {trng_inst/entropy_cell_gen[0].neoTRNG_cell_inst}]]
resize_pblock [get_pblocks pblock_1] -add {SLICE_X14Y51:SLICE_X21Y60}
create_pblock pblock_2
add_cells_to_pblock [get_pblocks pblock_2] [get_cells -quiet [list {trng_inst/entropy_cell_gen[1].neoTRNG_cell_inst}]]
resize_pblock [get_pblocks pblock_2] -add {SLICE_X22Y40:SLICE_X27Y49}
resize_pblock [get_pblocks pblock_2] -add {RAMB18_X1Y16:RAMB18_X1Y19}
resize_pblock [get_pblocks pblock_2] -add {RAMB36_X1Y8:RAMB36_X1Y9}
create_pblock pblock_3
add_cells_to_pblock [get_pblocks pblock_3] [get_cells -quiet [list {trng_inst/entropy_cell_gen[2].neoTRNG_cell_inst}]]
resize_pblock [get_pblocks pblock_3] -add {SLICE_X14Y40:SLICE_X21Y49}
