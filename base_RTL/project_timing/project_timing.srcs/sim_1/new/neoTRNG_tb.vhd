library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

entity neoTRNG_tb is
end entity;

architecture bhv of neoTRNG_tb is

  constant CLK_PERIOD     : time := 10 ns;
  constant NUM_CELLS      : natural := 3;
  constant NUM_INV_START  : natural := 3;
  constant NUM_RAW_BITS   : natural := 32; -- Kept small (power of 2) for easier cycle counting

  signal clk_i    : std_ulogic := '0';
  signal rstn_i   : std_ulogic := '0';
  signal enable_i : std_ulogic := '0';
  
  -- Outputs for each test instance
  signal valid_case1, valid_case2, valid_case3, valid_case4 : std_ulogic;
  signal data_case1,  data_case2,  data_case3,  data_case4  : std_ulogic_vector(7 downto 0);

  signal sim_done : boolean := false;

begin

  -- Clock Generation
  clk_process : process
  begin
    while not sim_done loop
      clk_i <= '0'; wait for CLK_PERIOD / 2;
      clk_i <= '1'; wait for CLK_PERIOD / 2;
    end loop;
    wait;
  end process;

  -- -------------------------------------------------------------------------
  -- Instantiating 4 Parallel DUTs to Legally Test Every Generic Combination
  -- -------------------------------------------------------------------------
  
  -- CASE 1: VON_NEUMANN = false, CRC = false (Expect valid after 8 raw bits / 8 clock cycles)
  DUT_CASE1 : entity work.neoTRNG
    generic map (
      NUM_CELLS => NUM_CELLS, NUM_INV_START => NUM_INV_START, NUM_RAW_BITS => NUM_RAW_BITS,
      SIM_MODE => true, ENABLE_VON_NEUMANN => false, ENABLE_CRC => false
    )
    port map ( clk_i => clk_i, rstn_i => rstn_i, enable_i => enable_i, valid_o => valid_case1, data_o => data_case1 );

  -- CASE 2: VON_NEUMANN = true, CRC = false (Expect valid after 8 Von Neumann bits / >8 clock cycles)
  DUT_CASE2 : entity work.neoTRNG
    generic map (
      NUM_CELLS => NUM_CELLS, NUM_INV_START => NUM_INV_START, NUM_RAW_BITS => NUM_RAW_BITS,
      SIM_MODE => true, ENABLE_VON_NEUMANN => true, ENABLE_CRC => false
    )
    port map ( clk_i => clk_i, rstn_i => rstn_i, enable_i => enable_i, valid_o => valid_case2, data_o => data_case2 );

  -- CASE 3: VON_NEUMANN = false, CRC = true (Expect valid after exactly NUM_RAW_BITS / 32 clock cycles)
  DUT_CASE3 : entity work.neoTRNG
    generic map (
      NUM_CELLS => NUM_CELLS, NUM_INV_START => NUM_INV_START, NUM_RAW_BITS => NUM_RAW_BITS,
      SIM_MODE => true, ENABLE_VON_NEUMANN => false, ENABLE_CRC => true
    )
    port map ( clk_i => clk_i, rstn_i => rstn_i, enable_i => enable_i, valid_o => valid_case3, data_o => data_case3 );

  -- CASE 4: VON_NEUMANN = true, CRC = true (Expect valid after NUM_RAW_BITS Von Neumann bits / >>32 clock cycles)
  DUT_CASE4 : entity work.neoTRNG
    generic map (
      NUM_CELLS => NUM_CELLS, NUM_INV_START => NUM_INV_START, NUM_RAW_BITS => NUM_RAW_BITS,
      SIM_MODE => true, ENABLE_VON_NEUMANN => true, ENABLE_CRC => true
    )
    port map ( clk_i => clk_i, rstn_i => rstn_i, enable_i => enable_i, valid_o => valid_case4, data_o => data_case4 );


  -- -------------------------------------------------------------------------
  -- Stimulus and Sequential Verification Process
  -- -------------------------------------------------------------------------
  stimulus_proc : process
    variable cycle_count : integer := 0;
  begin
    -- System Power-on Reset
    rstn_i   <= '0';
    enable_i <= '0';
    wait for CLK_PERIOD * 5;
    rstn_i   <= '1';
    wait for CLK_PERIOD * 2;

    -- =========================================================================
    -- WARM-UP PHASE: Wait for initial latching and first valid outputs
    -- =========================================================================
    report "Entering Warm-up Phase: Enabling module to latch entropy chains...";
    enable_i <= '1';
    
    -- Wait until every single test architecture variant has fired its first valid pulse
    -- this purges any startup garbage out of the cell pipeline filters.
    if (valid_case1 = '0') then wait until valid_case1 = '1'; end if;
    if (valid_case2 = '0') then wait until valid_case2 = '1'; end if;
    if (valid_case3 = '0') then wait until valid_case3 = '1'; end if;
    if (valid_case4 = '0') then wait until valid_case4 = '1'; end if;
    
    wait until rising_edge(clk_i);
    report "Warm-up complete! Resetting cores to establish synchronized clean slate...";
    
    -- De-assert enable and pulse a fast reset to flush sampling registers back to 0
    enable_i <= '0';
    rstn_i   <= '0';
    wait for CLK_PERIOD * 3;
    rstn_i   <= '1';
    wait for CLK_PERIOD * 5; -- Allow reset settling time

    -- =========================================================================
    -- VERIFY CASE 1: VON_NEUMANN = false, CRC = false
    -- In simulation mode with VN off, 1 valid raw bit is generated every single clock cycle.
    -- =========================================================================
    report "Testing Case 1: VON_NEUMANN=false, CRC=false...";
    enable_i    <= '1';
    cycle_count := 0;
    
    while valid_case1 = '0' loop
      wait until rising_edge(clk_i);
      cycle_count := cycle_count + 1;
      if cycle_count > 20 then
	        assert false report "Case 1 Failed: Timeout!" severity failure;
      end if;
    end loop;

    assert cycle_count = 8 
      report "Case 1 Failed! Expected exactly 8 cycles for 8 raw bits, but counted: " & integer'image(cycle_count)
      severity error;
      
    enable_i <= '0'; wait for CLK_PERIOD * 5;

    -- =========================================================================
    -- VERIFY CASE 3: VON_NEUMANN = false, CRC = true
    -- In simulation mode with VN off, should take exactly NUM_RAW_BITS cycles.
    -- =========================================================================
    report "Testing Case 3: VON_NEUMANN=false, CRC=true...";
    enable_i    <= '1';
    cycle_count := 0;
    
    while valid_case3 = '0' loop
      wait until rising_edge(clk_i);
      cycle_count := cycle_count + 1;
      if cycle_count > (NUM_RAW_BITS + 10) then
        assert false report "Case 3 Failed: Timeout!" severity failure;
      end if;
    end loop;

    assert cycle_count = NUM_RAW_BITS 
      report "Case 3 Failed! Expected exactly " & integer'image(NUM_RAW_BITS) & " cycles, but counted: " & integer'image(cycle_count)
      severity error;
      
    enable_i <= '0'; wait for CLK_PERIOD * 5;

    -- =========================================================================
    -- VERIFY CASE 2: VON_NEUMANN = true, CRC = false
    -- Von Neumann filtering drops bits, so it MUST take strictly longer than 8 cycles.
    -- =========================================================================
    report "Testing Case 2: VON_NEUMANN=true, CRC=false...";
    enable_i    <= '1';
    cycle_count := 0;
    
    while valid_case2 = '0' loop
      wait until rising_edge(clk_i);
      cycle_count := cycle_count + 1;
    end loop;

    assert cycle_count > 8 
      report "Case 2 Failed! Should take longer than 8 cycles due to Von Neumann filtering fallback."
      severity error;
    report "Case 2 passed. Cycles taken: " & integer'image(cycle_count);
      
    enable_i <= '0'; wait for CLK_PERIOD * 5;

    -- =========================================================================
    -- VERIFY CASE 4: VON_NEUMANN = true, CRC = true
    -- Must take strictly longer than NUM_RAW_BITS cycles.
    -- =========================================================================
    report "Testing Case 4: VON_NEUMANN=true, CRC=true...";
    enable_i    <= '1';
    cycle_count := 0;
    
    while valid_case4 = '0' loop
      wait until rising_edge(clk_i);
      cycle_count := cycle_count + 1;
    end loop;

    assert cycle_count > NUM_RAW_BITS 
      report "Case 4 Failed! Should take longer than NUM_RAW_BITS cycles due to Von Neumann filtering fallback."
      severity error;
    report "Case 4 passed. Cycles taken: " & integer'image(cycle_count);

    -- Wrap up simulation cleanly
    enable_i <= '0';
    wait for CLK_PERIOD * 5;
    report "ALL NEOTRNG ACCUMULATION TESTS COMPLETED SUCCESSFULLY!";
    sim_done <= true;
    wait;
  end process;

end architecture;