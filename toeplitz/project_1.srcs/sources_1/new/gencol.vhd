-- SPDX-License-Identifier: MIT
-- Copyright (c) 2025 Rok Zitko

-- Generate successive columns of the Toeplitz matrix
-- Rok Zitko, March-April 2022

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity gencol is
  generic (
    BS     : integer := 64;
    N      : integer := 256;
    L      : integer := 128;
    STRIDE : integer := 1;
    INDEX  : integer := 0
  );
  port (
    clk   : in  std_logic;
    reset : in  std_logic;
    rrow0 : in  std_logic_vector(N-1 downto 0);
    col0  : in  std_logic_vector(L-1 downto 0);
    col   : inout std_logic_vector(L-1 downto 0)
  );
end entity gencol;

architecture rtl of gencol is

  signal rrow : std_logic_vector(N-1 downto 0);
  signal cnt  : integer range 0 to N;

begin

  process(clk)
    variable idx_shift : integer;
  begin
    if rising_edge(clk) then
      if reset = '1' or cnt = (N - STRIDE + INDEX) then
        if INDEX = 0 then
          col <= col0;
        else
          -- Equivalent to Verilog: { rrow0[(INDEX>0 ? INDEX-1 : INDEX):0], col0[L-1:INDEX] }
          -- Since INDEX != 0 in this branch, INDEX-1 is used
          idx_shift := INDEX - 1;
          col <= rrow0(idx_shift downto 0) & col0(L-1 downto INDEX);
        end if;
        -- Equivalent to Verilog: rrow <= rrow0 >> INDEX (logical right shift)
        rrow <= std_logic_vector(shift_right(unsigned(rrow0), INDEX));
        cnt  <= INDEX;
      else
        -- Equivalent to Verilog: col <= { rrow[STRIDE-1:0], col[L-1:STRIDE] }
        col  <= rrow(STRIDE-1 downto 0) & col(L-1 downto STRIDE);
        -- Equivalent to Verilog: rrow <= { {STRIDE{1'b0}}, rrow[N-1:STRIDE] }
        rrow <= (STRIDE-1 downto 0 => '0') & rrow(N-1 downto STRIDE);
        cnt  <= cnt + STRIDE;
      end if;
    end if;
  end process;

end architecture rtl;



















