-- SPDX-License-Identifier: MIT
-- Copyright (c) 2025 Rok Zitko
--
-- Read row and column data from a file
-- Rok Zitko, March-April 2022 -> Translated to VHDL 2026

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity readrc is
    generic (
        BS : integer := 64;
        N  : integer := 256;
        L  : integer := 128
    );
    port (
        rrow0 : out std_logic_vector(N-1 downto 0); -- reversed order row
        col0  : out std_logic_vector(L-1 downto 0)  -- column data
    );
end entity readrc;

architecture beh of readrc is
    -- Constants holding the direct values from the .dat files
    -- c64-hex.dat values concatenated (2 lines * 64 bits = 128 bits)
    constant C_DATA  : std_logic_vector(127 downto 0) := x"023334605d2466c2de9725e270f0ee93";
    
    -- rr64-hex.dat values concatenated (4 lines * 64 bits = 256 bits)
    constant RR_DATA : std_logic_vector(255 downto 0) := x"8becd6a49362e043714d1a1ed7b645bd19426da74fefc14df1dcd03202614a38";
begin

    -- col0 assignment (Direct mapping of the 128-bit vector)
    col0 <= C_DATA(L-1 downto 0);

    -- rrow0 assignment
    -- Replicates SystemVerilog's: {>>{rr}} >> 1
    -- In VHDL, a logical right shift fills the MSB with '0'
    rrow0 <= std_logic_vector(unsigned(RR_DATA(N-1 downto 0)) srl 1);

end architecture beh;
