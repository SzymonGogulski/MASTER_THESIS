-- SPDX-License-Identifier: MIT
-- Copyright (c) 2025 Rok Zitko
--
-- Toeplitz extractor, top level module
-- Rok Zitko, March-April 2022 -> Translated to VHDL 2026
-- Modified to include data valid flow control.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity toeplitz is
    generic (
        BS : integer := 64;
        N  : integer := 256;                                -- num of input bits
        L  : integer := 128                                 -- num of output bits
    );
    port (
        clk       : in  std_logic;
        reset     : in  std_logic;
        data      : in  std_logic;                            -- input raw data
        data_valid: in  std_logic;                            -- high when input data is valid
        q         : out std_logic_vector(L-1 downto 0);      -- output corrected data
        qstrobe   : out std_logic                            -- output valid signal
    );
end entity toeplitz;

architecture rtl of toeplitz is

    -- Constant parameters calculated from generics
    constant XSZ : integer := N / BS;
    constant YSZ : integer := L / BS;

    -- Internal signal declarations
    signal rrow0 : std_logic_vector(N-1 downto 0);
    signal col0  : std_logic_vector(L-1 downto 0);
    signal col   : std_logic_vector(L-1 downto 0);
    
    signal y     : std_logic_vector(L-1 downto 0);
    signal cnt   : integer;

begin

    -- Instantiate readrc
    readrc_inst : entity work.readrc
        generic map (
            BS => BS,
            N  => N,
            L  => L
        )
        port map (
            rrow0 => rrow0,
            col0  => col0
        );

    -- Instantiate gencol
    gencol_inst : entity work.gencol
        generic map (
            BS => BS,
            N  => N,
            L  => L
        )
        port map (
            clk         => clk,
            reset       => reset,
            data_valid  => data_valid,
            rrow0       => rrow0,
            col0        => col0,
            col         => col
        );

    -- Main synchronous process
    process(clk)
        -- Variable used to mimic blocking assignment behavior of 'ynew'
        variable ynew : std_logic_vector(L-1 downto 0);
    begin
        if rising_edge(clk) then
            if reset = '1' then
                q       <= (others => '0');
                qstrobe <= '0';
                y       <= (others => '0');
                cnt     <= 0;
            else
                -- Default assignment to prevent latching strobe behavior
                qstrobe <= '0';

                -- Only process data when the input bit is valid
                if data_valid = '1' then
                    -- Compute ynew combinationally based on current y and col
                    for i in 0 to L-1 loop
                        ynew(i) := y(i) xor (data and col(i));
                    end loop;

                    -- Counter and output logic
                    if cnt < (N - 1) then
                        cnt <= cnt + 1;
                        y   <= ynew;
                    else
                        cnt     <= 0;
                        qstrobe <= '1';
                        q       <= ynew;
                        y       <= (others => '0');
                    end if;
                end if;
            end if;
        end if;
    end process;

end architecture rtl;
