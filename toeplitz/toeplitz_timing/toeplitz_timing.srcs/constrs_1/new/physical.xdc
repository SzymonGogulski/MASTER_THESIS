set_property IOSTANDARD LVCMOS33 [get_ports clk]
set_property IOSTANDARD LVCMOS33 [get_ports tx]
set_property PACKAGE_PIN H16 [get_ports clk]
set_property PACKAGE_PIN G15 [get_ports tx]
set_property ALLOW_COMBINATORIAL_LOOPS TRUE [get_nets trng_inst/entropy_cell_gen[0].neoTRNG_cell_inst/inv_out_2]
set_property ALLOW_COMBINATORIAL_LOOPS TRUE [get_nets trng_inst/entropy_cell_gen[1].neoTRNG_cell_inst/inv_out_4]
set_property ALLOW_COMBINATORIAL_LOOPS TRUE [get_nets trng_inst/entropy_cell_gen[2].neoTRNG_cell_inst/inv_out_6]

#set_property ALLOW_COMBINATIONAL_LOOPS TRUE [get_nets -hierarchical *ring_osc*]
#set_property DONT_TOUCH TRUE [get_cells -hierarchical *latch_reg*]

# set_property ALLOW_COMBINATORIAL_LOOPS true [get_nets -hierarchical *inv_in*]
# set_property ALLOW_COMBINATORIAL_LOOPS true [get_nets -hierarchical *inv_out*]
# set_property ALLOW_COMBINATORIAL_LOOPS true [get_nets -hierarchical *latch*]


