library ieee;
use ieee.std_logic_1164.all;

entity shift_reg_tb is
end entity shift_reg_tb;

architecture sim of shift_reg_tb is
    -- Component Signals
    constant STAGES_C : integer := 4;
    signal clk_s      : std_logic := '0';
    signal rstn_s     : std_logic := '0';
    signal en_i_s     : std_logic := '0';
    signal en_o_s     : std_logic;

    -- Clock Period definition
    constant CLK_PERIOD : time := 10 ns;

begin

    -- Instantiate the Unit Under Test (UUT)
    uut: entity work.shift_reg
        generic map (
            STAGES => STAGES_C
        )
        port map (
            clk_i  => clk_s,
            rstn_i => rstn_s,
            en_i   => en_i_s,
            en_o   => en_o_s
        );

    -- Clock Generation
    clk_process : process
    begin
        clk_s <= '0';
        wait for CLK_PERIOD/2;
        clk_s <= '1';
        wait for CLK_PERIOD/2;
    end process;

    -- Stimulus Process
    stim_proc: process
    begin		
        -- Initial Reset
        rstn_s <= '0';
        wait for 25 ns;	
        rstn_s <= '1';
        wait for CLK_PERIOD;

        -- Input a single pulse
        en_i_s <= '1';
        wait for CLK_PERIOD;
        en_i_s <= '0';

        -- Wait to see it propagate through the stages
        wait for CLK_PERIOD * (STAGES_C + 2);

        -- End Simulation
        assert false report "Simulation Finished" severity failure;
        wait;
    end process;

end architecture sim;