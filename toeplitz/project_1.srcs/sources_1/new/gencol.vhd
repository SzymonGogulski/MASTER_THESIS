-- SPDX-License-Identifier: MIT
-- Copyright (c) 2025 Rok Zitko
--
-- Generate successive columns of the toeplitz matrix
-- Rok Zitko, March-April 2022 -> Translated to VHDL 2026
-- Modified to include data valid flow control.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity gencol is
  generic (
    bs     : integer := 64;
    n      : integer := 256;
    l      : integer := 128;
    stride : integer := 1;
    index  : integer := 0
  );
  port (
    clk        : in    std_logic;
    reset      : in    std_logic;
    data_valid : in    std_logic;                            -- high when input data is valid
    rrow0      : in    std_logic_vector(n-1 downto 0);
    col0       : in    std_logic_vector(l-1 downto 0);
    col        : inout std_logic_vector(l-1 downto 0)
  );
end entity gencol;

architecture rtl of gencol is

  signal rrow : std_logic_vector(n-1 downto 0);
  signal cnt  : integer range 0 to n;

begin

  process(clk)
    variable idx_shift : integer;
  begin
    if rising_edge(clk) then
      if reset = '1' then
        if index = 0 then
          col <= col0;
        else
          -- equivalent to verilog: { rrow0[(index>0 ? index-1 : index):0], col0[l-1:index] }
          idx_shift := index - 1;
          col <= rrow0(idx_shift downto 0) & col0(l-1 downto index);
        end if;
        -- equivalent to verilog: rrow <= rrow0 >> index (logical right shift)
        rrow <= std_logic_vector(shift_right(unsigned(rrow0), index));
        cnt  <= index;

      elsif data_valid = '1' then
        -- Process and shift only when data is valid
        if cnt = (n - stride + index) then
          if index = 0 then
            col <= col0;
          else
            idx_shift := index - 1;
            col <= rrow0(idx_shift downto 0) & col0(l-1 downto index);
          end if;
          rrow <= std_logic_vector(shift_right(unsigned(rrow0), index));
          cnt  <= index;
        else
          -- equivalent to verilog: col <= { rrow[stride-1:0], col[l-1:stride] }
          col  <= rrow(stride-1 downto 0) & col(l-1 downto stride);
          -- equivalent to verilog: rrow <= { {stride{1'b0}}, rrow[n-1:stride] }
          rrow <= (stride-1 downto 0 => '0') & rrow(n-1 downto stride);
          cnt  <= cnt + stride;
        end if;
      end if;
    end if;
  end process;

end architecture rtl;