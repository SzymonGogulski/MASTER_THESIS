-- SPDX-License-Identifier: MIT
-- Testbench for Toeplitz Extractor top-level module

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity toeplitz_tb is
-- Testbenches do not have ports
end entity toeplitz_tb;

architecture sim of toeplitz_tb is

    -- 1. Component Declaration for the UUT (Unit Under Test)
    component toeplitz is
        generic (
            BS : integer := 64;
            N  : integer := 256;
            L  : integer := 128
        );
        port (
            clk         : in  std_logic;
            reset       : in  std_logic;
            data        : in  std_logic;
            data_valid  : in std_logic;
            q           : out std_logic_vector(L-1 downto 0);
            qstrobe     : out std_logic
        );
    end component;

    -- 2. Testbench Constants
    constant CLK_PERIOD : time := 10 ns;
    constant BS_G       : integer := 64;
    constant N_G        : integer := 256;
    constant L_G        : integer := 128;

    -- 3. Signal Declarations to connect to UUT
    signal clk          : std_logic := '0';
    signal reset        : std_logic := '1';
    signal data         : std_logic := '0';
    signal data_valid   : std_logic := '1';
    signal q            : std_logic_vector(L_G-1 downto 0);
    signal qstrobe      : std_logic;

    -- Simulation control flag
    signal sim_done : boolean := false;

    -- Mock raw data pattern to feed into the extractor (256 bits)
    -- You can modify this string pattern to test different data inputs
    constant TEST_DATA_STREAM : std_logic_vector(N_G-1 downto 0) := 
        X"A5A5A5A5B1B2B3B4C1C2C3C4D1D2D3D4E1E2E3E4F1F2F3F40102030405060708";
        
    -- Expected output stream for verification (128 bits)
    constant EXPECTED_Q : std_logic_vector(L_G-1 downto 0) := 
        X"6743ABD32AF0540CCEAF400958CD8550";

begin

    -- 4. Instantiate the Unit Under Test (UUT)
    uut: toeplitz
        generic map (
            BS => BS_G,
            N  => N_G,
            L  => L_G
        )
        port map (
            clk         => clk,
            reset       => reset,
            data        => data,
            data_valid  => data_valid,
            q           => q,
            qstrobe     => qstrobe
        );

    -- 5. Clock Generation Process
    clk_process : process
    begin
        while not sim_done loop
            clk <= '0';
            wait for CLK_PERIOD / 2;
            clk <= '1';
            wait for CLK_PERIOD / 2;
        end loop;
        wait; -- Stop process when simulation is done
    end process clk_process;

    -- 6. Stimulus Process (Feeds data serially into the UUT)
    stim_process : process
    begin
        -- Hold reset active for 4 clock cycles
        reset <= '1';
        data  <= '0';
        data_valid <= '0';
        wait for CLK_PERIOD * 4;
        
        -- Release reset on a falling edge to avoid setup/hold violations
        wait until falling_edge(clk);
        reset <= '0';
        report "System Reset Released. Starting Data Transmission..." severity note;
        
        -- Loop to stream all N bits (MSB to LSB)
        for i in N_G-1 downto 0 loop
            data_valid <= '1';
            data <= TEST_DATA_STREAM(i);
            wait until falling_edge(clk); 
        end loop;

        -- Clear data line after transmission is finished
        data_valid <= '0';
        data <= '0';

        -- Wait a few more clock cycles to capture the output strobe and result
        wait for CLK_PERIOD * 5;

        -- Terminate simulation
        report "Simulation Completed Successfully." severity note;
        sim_done <= true;
        wait;
    end process stim_process;

    -- 7. Verification Process (Monitors and captures the output)
    monitor_process : process
    begin
        -- Wait until the module asserts qstrobe high indicating valid output
        wait until rising_edge(clk) and qstrobe = '1';
        
        -- Log the final output
        report "Output Ready (qstrobe high)!" severity note;
        -- Change line 119 to this:
        report "Extracted Value (q): 0x" & to_hstring(to_bitvector(q)) severity note;
        report "Expected Value:      0x" & to_hstring(to_bitvector(EXPECTED_Q)) severity note;
        
        -- Self-checking validation logic
        if q = EXPECTED_Q then
            report "VERIFICATION RESULT: PASS" severity note;
        else
            report "VERIFICATION RESULT: FAILURE (Mismatched Stream Data)" severity error;
        end if;
        
        wait for CLK_PERIOD * 100;
        wait;
    end process monitor_process;

end architecture sim;