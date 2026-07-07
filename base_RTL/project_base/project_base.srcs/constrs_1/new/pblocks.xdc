# LOCALIZED 2
#create_pblock pblock_1
#add_cells_to_pblock [get_pblocks pblock_1] [get_cells -quiet [list {trng_inst/entropy_cell_gen[0].neoTRNG_cell_inst}]]
#resize_pblock [get_pblocks pblock_1] -add {SLICE_X26Y47:SLICE_X31Y49}
#create_pblock pblock_2
#add_cells_to_pblock [get_pblocks pblock_2] [get_cells -quiet [list {trng_inst/entropy_cell_gen[1].neoTRNG_cell_inst}]]
#resize_pblock [get_pblocks pblock_2] -add {SLICE_X26Y44:SLICE_X31Y46}

#DISTIRBUTED 2
create_pblock pblock_1
add_cells_to_pblock [get_pblocks pblock_1] [get_cells -quiet [list {trng_inst/entropy_cell_gen[0].neoTRNG_cell_inst}]]
resize_pblock [get_pblocks pblock_1] -add {SLICE_X22Y96:SLICE_X25Y99}
create_pblock pblock_2
add_cells_to_pblock [get_pblocks pblock_2] [get_cells -quiet [list {trng_inst/entropy_cell_gen[1].neoTRNG_cell_inst}]]
resize_pblock [get_pblocks pblock_2] -add {SLICE_X24Y5:SLICE_X25Y9}
resize_pblock [get_pblocks pblock_2] -add {RAMB18_X1Y2:RAMB18_X1Y3}
resize_pblock [get_pblocks pblock_2] -add {RAMB36_X1Y1:RAMB36_X1Y1}

# DISTIRBUTED 3
#create_pblock pblock_1
#add_cells_to_pblock [get_pblocks pblock_1] [get_cells -quiet [list {trng_inst/entropy_cell_gen[0].neoTRNG_cell_inst}]]
#resize_pblock [get_pblocks pblock_1] -add {SLICE_X0Y97:SLICE_X5Y99}
#create_pblock pblock_2
#add_cells_to_pblock [get_pblocks pblock_2] [get_cells -quiet [list {trng_inst/entropy_cell_gen[1].neoTRNG_cell_inst}]]
#resize_pblock [get_pblocks pblock_2] -add {SLICE_X38Y96:SLICE_X43Y99}
#create_pblock pblock_3
#add_cells_to_pblock [get_pblocks pblock_3] [get_cells -quiet [list {trng_inst/entropy_cell_gen[2].neoTRNG_cell_inst}]]
#resize_pblock [get_pblocks pblock_3] -add {SLICE_X38Y0:SLICE_X43Y3}

# LOCALIZED 3
#create_pblock pblock_1
#add_cells_to_pblock [get_pblocks pblock_1] [get_cells -quiet [list {trng_inst/entropy_cell_gen[0].neoTRNG_cell_inst}]]
#resize_pblock [get_pblocks pblock_1] -add {SLICE_X22Y59:SLICE_X25Y61}
#create_pblock pblock_2
#add_cells_to_pblock [get_pblocks pblock_2] [get_cells -quiet [list {trng_inst/entropy_cell_gen[1].neoTRNG_cell_inst}]]
#resize_pblock [get_pblocks pblock_2] -add {SLICE_X22Y56:SLICE_X25Y58}
#create_pblock pblock_3
#add_cells_to_pblock [get_pblocks pblock_3] [get_cells -quiet [list {trng_inst/entropy_cell_gen[2].neoTRNG_cell_inst}]]
#resize_pblock [get_pblocks pblock_3] -add {SLICE_X22Y53:SLICE_X25Y55}

# DISTRIBUTED 6
#create_pblock pblock_1
#add_cells_to_pblock [get_pblocks pblock_1] [get_cells -quiet [list {trng_inst/entropy_cell_gen[0].neoTRNG_cell_inst}]]
#resize_pblock [get_pblocks pblock_1] -add {SLICE_X14Y95:SLICE_X21Y99}
#create_pblock pblock_2
#add_cells_to_pblock [get_pblocks pblock_2] [get_cells -quiet [list {trng_inst/entropy_cell_gen[1].neoTRNG_cell_inst}]]
#resize_pblock [get_pblocks pblock_2] -add {SLICE_X0Y78:SLICE_X5Y82}
#create_pblock pblock_3
#add_cells_to_pblock [get_pblocks pblock_3] [get_cells -quiet [list {trng_inst/entropy_cell_gen[2].neoTRNG_cell_inst}]]
#resize_pblock [get_pblocks pblock_3] -add {SLICE_X0Y22:SLICE_X5Y26}
#create_pblock pblock_4
#add_cells_to_pblock [get_pblocks pblock_4] [get_cells -quiet [list {trng_inst/entropy_cell_gen[3].neoTRNG_cell_inst}]]
#resize_pblock [get_pblocks pblock_4] -add {SLICE_X22Y2:SLICE_X25Y6}
#create_pblock pblock_5
#add_cells_to_pblock [get_pblocks pblock_5] [get_cells -quiet [list {trng_inst/entropy_cell_gen[4].neoTRNG_cell_inst}]]
#resize_pblock [get_pblocks pblock_5] -add {SLICE_X40Y82:SLICE_X43Y86}
#create_pblock pblock_6
#add_cells_to_pblock [get_pblocks pblock_6] [get_cells -quiet [list {trng_inst/entropy_cell_gen[5].neoTRNG_cell_inst}]]
#resize_pblock [get_pblocks pblock_6] -add {SLICE_X40Y25:SLICE_X43Y29}

# LOCALIZED 6
#create_pblock pblock_1
#add_cells_to_pblock [get_pblocks pblock_1] [get_cells -quiet [list {trng_inst/entropy_cell_gen[0].neoTRNG_cell_inst}]]
#resize_pblock [get_pblocks pblock_1] -add {SLICE_X26Y47:SLICE_X31Y49}
#create_pblock pblock_2
#add_cells_to_pblock [get_pblocks pblock_2] [get_cells -quiet [list {trng_inst/entropy_cell_gen[1].neoTRNG_cell_inst}]]
#resize_pblock [get_pblocks pblock_2] -add {SLICE_X26Y44:SLICE_X31Y46}
#create_pblock pblock_3
#add_cells_to_pblock [get_pblocks pblock_3] [get_cells -quiet [list {trng_inst/entropy_cell_gen[2].neoTRNG_cell_inst}]]
#resize_pblock [get_pblocks pblock_3] -add {SLICE_X26Y41:SLICE_X31Y43}
#create_pblock pblock_4
#add_cells_to_pblock [get_pblocks pblock_4] [get_cells -quiet [list {trng_inst/entropy_cell_gen[3].neoTRNG_cell_inst}]]
#resize_pblock [get_pblocks pblock_4] -add {SLICE_X26Y38:SLICE_X31Y40}
#create_pblock pblock_5
#add_cells_to_pblock [get_pblocks pblock_5] [get_cells -quiet [list {trng_inst/entropy_cell_gen[4].neoTRNG_cell_inst}]]
#resize_pblock [get_pblocks pblock_5] -add {SLICE_X26Y35:SLICE_X31Y37}
#create_pblock pblock_6
#add_cells_to_pblock [get_pblocks pblock_6] [get_cells -quiet [list {trng_inst/entropy_cell_gen[5].neoTRNG_cell_inst}]]
#resize_pblock [get_pblocks pblock_6] -add {SLICE_X26Y32:SLICE_X31Y34}



#create_pblock pblock_3
#add_cells_to_pblock [get_pblocks pblock_3] [get_cells -quiet [list {uart_cnt_reg[4]}]]
#resize_pblock [get_pblocks pblock_3] -add {SLICE_X26Y75:SLICE_X33Y89}
#resize_pblock [get_pblocks pblock_3] -add {DSP48_X1Y30:DSP48_X1Y35}
