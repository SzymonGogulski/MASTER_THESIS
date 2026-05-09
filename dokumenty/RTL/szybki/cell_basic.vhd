library ieee;
use ieee.std_logic_1164.all;

entity neoTRNG_cell is
  port (
    clk_i  : in  std_ulogic; -- clock
    rstn_i : in  std_ulogic; -- reset, low-active, async, optional
    en_i   : in  std_ulogic; -- enable-chain input
    en_o   : out std_ulogic; -- enable-chain output
    rnd_o  : out std_ulogic  -- random data (sync)
  );
end neoTRNG_cell;

architecture neoTRNG_cell_rtl of neoTRNG_cell is

  constant NUM_INV : natural := 3;

  signal sreg    : std_ulogic_vector(NUM_INV-1 downto 0);
  signal latch   : std_ulogic_vector(NUM_INV-1 downto 0);
  signal inv_in  : std_ulogic_vector(NUM_INV-1 downto 0);
  signal inv_out : std_ulogic_vector(NUM_INV-1 downto 0);
  signal sync    : std_ulogic_vector(1 downto 0);

begin

  -- Enable Shift Register ---------------------------------------------------------------
  en_shift_reg: process(rstn_i, clk_i)
  begin
    if (rstn_i = '0') then
      sreg <= (others => '0');
    elsif rising_edge(clk_i) then
      sreg <= sreg(sreg'left-1 downto 0) & en_i;
    end if;
  end process;

  -- enable chain output
  en_o <= sreg(sreg'left);

  -- Ring Oscillator ----------------------------------------------------------------------
  ring_osc_gen:
  for i in 0 to NUM_INV-1 generate

    -- latch with reset and enable
    latch(i) <= '0' when (en_i = '0') else
                latch(i) when (sreg(i) = '0') else
                inv_out(i);

    -- physical inverter
    inv_out(i) <= not inv_in(i);

  end generate;

  -- chaining (ring)
  inv_in(0) <= latch(NUM_INV-1);
  inv_in(NUM_INV-1 downto 1) <= latch(NUM_INV-2 downto 0);

  -- Output Synchronizer ------------------------------------------------------------------
  synchronizer: process(rstn_i, clk_i)
  begin
    if (rstn_i = '0') then
      sync <= (others => '0');
    elsif rising_edge(clk_i) then
      sync <= sync(0) & latch(latch'left);
    end if;
  end process;

  -- output
  rnd_o <= sync(1);

end neoTRNG_cell_rtl;
