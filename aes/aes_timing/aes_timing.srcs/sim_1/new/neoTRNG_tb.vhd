library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity neoTRNG_tb is
-- Testbenches do not have ports
end neoTRNG_tb;

architecture sim of neoTRNG_tb is

    -- Constant declarations matching generic bounds
    constant CLK_PERIOD    : time := 10 ns; -- 100 MHz clock
    constant NUM_CELLS     : natural := 4;  -- Small number for easy trace analysis
    constant NUM_INV_START : natural := 3;  -- Starting number of pseudo-inverters
    constant SIM_MODE      : boolean := true; -- Must be true for testbench simulation

    -- Component Declaration for the UUT (Unit Under Test)
    component neoTRNG is
        generic (
            NUM_CELLS : natural range 1 to 255;
            NUM_INV_START : natural range 3 to 4095;
            SIM_MODE : boolean
        );
        port (
            clk_i    : in  std_ulogic;
            rstn_i   : in  std_ulogic;
            enable_i : in  std_ulogic;
            valid_o  : out std_ulogic;
            data_o   : out std_ulogic_vector(127 downto 0)
        );
    end component;

    -- Testbench Signals
    signal clk_s    : std_ulogic := '0';
    signal rstn_s   : std_ulogic := '0';
    signal enable_s : std_ulogic := '0';
    signal valid_s  : std_ulogic;
    signal data_s   : std_ulogic_vector(127 downto 0);

    -- Simulation control flag
    signal sim_done : boolean := false;

begin

    -- 1. Instantiate the Unit Under Test (UUT)
    uut: neoTRNG
        generic map (
            NUM_CELLS     => NUM_CELLS,
            NUM_INV_START => NUM_INV_START,
            SIM_MODE      => SIM_MODE
        )
        port map (
            clk_i    => clk_s,
            rstn_i   => rstn_s,
            enable_i => enable_s,
            valid_o  => valid_s,
            data_o   => data_s
        );

    -- 2. Clock Generator Process
    clk_process : process
    begin
        while not sim_done loop
            clk_s <= '0';
            wait for CLK_PERIOD / 2;
            clk_s <= '1';
            wait for CLK_PERIOD / 2;
        end loop;
        wait;
    end process clk_process;

    -- 3. Stimulus Process
    stimulus_process : process
    begin
        -- Initial State
        enable_s <= '0';
        rstn_s   <= '0';
        wait for CLK_PERIOD * 5;

        -- Release Asynchronous Reset
        report "Releasing reset..." severity note;
        rstn_s <= '1';
        wait for CLK_PERIOD * 2;

        -- Enable the TRNG to begin harvesting pseudo-entropy
        report "Enabling neoTRNG..." severity note;
        enable_s <= '1';

        -- Monitor the output for blocks of data.
        -- In SIM_MODE, it takes time to propagate through the enable chains 
        -- and fill the 128-bit collector shift register.
        
        -- Wait for the 1st 128-bit random block
        wait until valid_s = '1';
        report "BLOCK 1 RECEIVED!" severity note;
        report "Data Out (Hex): " & to_hstring(to_bitvector(data_s)) severity note;
        wait for CLK_PERIOD; -- Step over the valid pulse

        -- Wait for the 2nd 128-bit random block
        wait until valid_s = '1';
        report "BLOCK 2 RECEIVED!" severity note;
        report "Data Out (Hex): " & to_hstring(to_bitvector(data_s)) severity note;
        wait for CLK_PERIOD;

        -- Test disabling behavior midway
        report "Disabling module to verify internal flush..." severity note;
        enable_s <= '0';
        wait for CLK_PERIOD * 20;

        -- Re-enable to see if it recovers safely
        report "Re-enabling module..." severity note;
        enable_s <= '1';
        
        -- Wait for a 3rd block to ensure clean recovery
        wait until valid_s = '1';
        report "BLOCK 3 RECEIVED (Post-flush)!" severity note;
        report "Data Out (Hex): " & to_hstring(to_bitvector(data_s)) severity note;
        wait for CLK_PERIOD;

        -- End the simulation gracefully
        report "Simulation completed successfully." severity note;
        sim_done <= true;
        wait;
    end process stimulus_process;

end sim;