-- ============================================================================================= --
-- neoTRNG - A Tiny and Platform-Independent True Random Number Generator (Version 3.4)          --
-- https://github.com/stnolting/neoTRNG                                                          --
-- ============================================================================================= --
-- The neoTNG true-random number generator samples free-running ring-oscillators (combinatorial  --
-- loops) to obtain *phase noise* hat is used as entropy source. The individual ring-oscillators --
-- are based on plain inverter chains that are decoupled using individually-enabled latches in   --
-- order to prevent the synthesis tool from trimming parts of the logic.                         --
--                                                                                               --
-- Hence, the TRNG provides a platform- agnostic architecture that can be implemented for any    --
-- FPGA/ASIC without requiring primitive instantiation or technology-specific attributes or      --
-- platform-specific synthesis options.                                                          --
--                                                                                               --
-- The random output from each entropy cells is synchronized and XOR-ed with the other cell's    --
-- outputs before it is and fed into a simple 2-bit "John von Neumann randomness extractor"      --
-- (extracting edges). <NUM_RAW_BITS> de-biased bits are combined using an CRC-style shift       --
-- register (entropy compression) to generate one final random data byte.                        --
-- ============================================================================================= --
-- BSD 3-Clause License                                                                          --
--                                                                                               --
-- Copyright (c) 2026, Stephan Nolting. All rights reserved.                                     --
--                                                                                               --
-- Redistribution and use in source and binary forms, with or without modification, are          --
-- permitted provided that the following conditions are met:                                     --
--                                                                                               --
-- 1. Redistributions of source code must retain the above copyright notice, this list of        --
--    conditions and the following disclaimer.                                                   --
--                                                                                               --
-- 2. Redistributions in binary form must reproduce the above copyright notice, this list of     --
--    conditions and the following disclaimer in the documentation and/or other materials        --
--    provided with the distribution.                                                            --
--                                                                                               --
-- 3. Neither the name of the copyright holder nor the names of its contributors may be used to  --
--    endorse or promote products derived from this software without specific prior written      --
--    permission.                                                                                --
--                                                                                               --
-- THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS   --
-- OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF               --
-- MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE    --
-- COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,     --
-- EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE --
-- GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED    --
-- AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING     --
-- NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED  --
-- OF THE POSSIBILITY OF SUCH DAMAGE.                                                            --
-- ============================================================================================= --

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity neoTRNG is
  generic (
    NUM_CELLS     : natural range 1 to 255;  -- number of ring-oscillator cells, min 1
    NUM_INV_START : natural range 3 to 4095; -- number of inverters in first ring-oscillator cell, has to be odd
    SIM_MODE      : boolean                  -- enable simulation mode (no physical random if enabled!)
  );
  port (
    clk_i    : in  std_ulogic; -- module clock
    rstn_i   : in  std_ulogic; -- module reset, high-active, async
    enable_i : in  std_ulogic; -- module enable (high-active)
    valid_o  : out std_ulogic; -- data_o is valid when set (high for one cycle)
    data_o   : out std_ulogic_vector(127 downto 0) -- 128-bit random data block output
  );
end neoTRNG;

architecture neoTRNG_rtl of neoTRNG is

  -- entropy source cell --
  component neoTRNG_cell
    generic (
      NUM_INV  : natural;
      SIM_MODE : boolean
    );
    port (
      clk_i  : in  std_ulogic;
      rstn_i : in  std_ulogic;
      en_i   : in  std_ulogic;
      en_o   : out std_ulogic;
      rnd_o  : out std_ulogic
    );
  end component;

  -- entropy cell interconnect --
  signal cell_en_in  : std_ulogic_vector(NUM_CELLS-1 downto 0);
  signal cell_en_out : std_ulogic_vector(NUM_CELLS-1 downto 0);
  signal cell_rnd    : std_ulogic_vector(NUM_CELLS-1 downto 0);
  signal cell_sum    : std_ulogic;

  -- sampling control --
  signal sample_en   : std_ulogic;
  signal raw_valid   : std_ulogic;
  
  -- Toeplitz extractor interface signals --
  signal toeplitz_q      : std_logic_vector(127 downto 0);
  signal toeplitz_strobe : std_logic;

begin

  -- Configuration Checks -------------------------------------------------------------------
  assert false report
    "[neoTRNG] The neoTRNG (v3.4 modified) integrated with Toeplitz Extractor Post-Processing" severity note;

  assert (NUM_INV_START mod 2) /= 0 report
    "[neoTRNG] Number of inverters in first cell [NUM_INV_START] has to be odd!" severity error;

  assert not SIM_MODE report
    "[neoTRNG] Simulation-mode enabled (NO TRUE/PHYSICAL RANDOM)!" severity warning;


  -- Entropy Source -------------------------------------------------------------------------
  entropy_cell_gen:
  for i in 0 to NUM_CELLS-1 generate
    neoTRNG_cell_inst: neoTRNG_cell
    generic map (
      NUM_INV  => NUM_INV_START + (2*i),
      SIM_MODE => SIM_MODE
    )
    port map (
      clk_i  => clk_i,
      rstn_i => rstn_i,
      en_i   => cell_en_in(i),
      en_o   => cell_en_out(i),
      rnd_o  => cell_rnd(i)
    );
  end generate;

  -- enable-shift-register chain --
  cell_en_in <= cell_en_out(NUM_CELLS-2 downto 0) & sample_en;

  -- combine cell outputs --
  combine: process(cell_rnd)
    variable tmp_v : std_ulogic;
  begin
    tmp_v := '0';
    for i in 0 to NUM_CELLS-1 loop
      tmp_v := tmp_v xor cell_rnd(i);
    end loop;
    cell_sum <= tmp_v;
  end process combine;


  -- Sampling and Flow Control --------------------------------------------------------------
  flow_control: process(rstn_i, clk_i)
  begin
    if (rstn_i = '1') then
      sample_en <= '0';
      raw_valid <= '0';
    elsif rising_edge(clk_i) then
      sample_en <= enable_i;
      
      -- Pulse valid signal only when cell pipeline is filled up and module is enabled
      if (sample_en = '1') and (cell_en_out(cell_en_out'left) = '1') then
        raw_valid <= '1';
      else
        raw_valid <= '0';
      end if;
    end if;
  end process flow_control;


  -- Toeplitz Random Extractor Core --------------------------------------------------------
  toeplitz_inst : entity work.toeplitz
    generic map (
      BS => 64,  -- Block Size internal parameter
      N  => 256, -- Number of input bits consumed per block
      L  => 128  -- Number of output bits extracted per block
    )
    port map (
      clk        => clk_i,
      reset      => rstn_i,
      data       => std_logic(cell_sum),
      data_valid => std_logic(raw_valid),
      q          => toeplitz_q,
      qstrobe    => toeplitz_strobe
    );


  -- Output Registration --------------------------------------------------------------------
  output_mapping: process(rstn_i, clk_i)
  begin
    if (rstn_i = '1') then
      data_o  <= (others => '0');
      valid_o <= '0';
    elsif rising_edge(clk_i) then
      valid_o <= std_ulogic(toeplitz_strobe);
      
      if toeplitz_strobe = '1' then
        data_o <= std_ulogic_vector(toeplitz_q);
      end if;
    end if;
  end process output_mapping;

end architecture neoTRNG_rtl;


-- ================================================================================================ --
-- neoTRNG entropy source cell, based on a simple ring-oscillator constructed from an odd number    --
-- of inverters. The inverters are decoupled using individually-enabled latches to prevent          --
-- the synthesis tool from "optimizing" (=removing) parts of the oscillator chain.                  --
-- ================================================================================================ --

library ieee;
use ieee.std_logic_1164.all;

entity neoTRNG_cell is
  generic (
    NUM_INV  : natural; -- number of inverters, has to be odd, min 3
    SIM_MODE : boolean  -- enable simulation mode (no physical random if enabled!)
  );
  port (
    clk_i  : in  std_ulogic; -- clock
    rstn_i : in  std_ulogic; -- reset, low-active, async, optional
    en_i   : in  std_ulogic; -- enable-chain input
    en_o   : out std_ulogic; -- enable-chain output
    rnd_o  : out std_ulogic  -- random data (sync)
  );
end neoTRNG_cell;

architecture neoTRNG_cell_rtl of neoTRNG_cell is

  signal sreg    : std_ulogic_vector(NUM_INV-1 downto 0); -- enable-shift-register
  signal latch   : std_ulogic_vector(NUM_INV-1 downto 0); -- ring oscillator: latches
  signal inv_in  : std_ulogic_vector(NUM_INV-1 downto 0); -- ring oscillator: inverter inputs
  signal inv_out : std_ulogic_vector(NUM_INV-1 downto 0); -- ring oscillator: inverter outputs
  signal sync    : std_ulogic_vector(1 downto 0); -- output synchronizer

begin

  -- Enable Shift-Register ------------------------------------------------------------------
  -- -------------------------------------------------------------------------------------------
  -- Using individual enable signals from a shift register for each inverter in order to prevent
  -- the synthesis tool from removing all but one inverter (since they implement "logical
  -- identical functions"). This makes the TRNG platform independent as we do not require tool-/
  -- technology-specific primitives, attributes or other options.

  en_shift_reg: process(rstn_i, clk_i)
  begin
    if (rstn_i = '1') then
      sreg <= (others => '0');
    elsif rising_edge(clk_i) then
      sreg <= sreg(sreg'left-1 downto 0) & en_i;
    end if;
  end process en_shift_reg;

  -- output for global enable chain --
  en_o <= sreg(sreg'left);


  -- Physical Entropy Source: Ring Oscillator -----------------------------------------------
  -- -------------------------------------------------------------------------------------------
  -- Each cell is based on a simple ring oscillator with an odd number of inverters. Each
  -- inverter is followed by a latch that provides a reset (to start in a defined state) and
  -- a latch-enable to make the latch transparent. Switching to transparent mode is done one by
  -- one by the enable shift register.

  ring_osc_gen:
  for i in 0 to NUM_INV-1 generate

    -- latch with global reset and individual enable --
    latch(i) <= '0' when (en_i = '0') else latch(i) when (sreg(i) = '0') else inv_out(i);

    -- inverter for actual synthesis --
    inverter_phy:
    if not SIM_MODE generate
      inv_out(i) <= not inv_in(i); -- this is one part of the ring oscillator's physical propagation delay
    end generate;

    -- inverter with "propagation delay" (implemented as a simple FF) --
    inverter_sim:
    if SIM_MODE generate -- for SIMULATION ONLY!
      inverter_sim_ff: process(rstn_i, clk_i) -- this will NOT generate true random numbers
      begin
        if (rstn_i = '1') then
          inv_out(i) <= '0';
        elsif rising_edge(clk_i) then
          inv_out(i) <= not inv_in(i);
        end if;
      end process inverter_sim_ff;
    end generate;

  end generate;

  -- chaining --
  inv_in <= latch(NUM_INV-2 downto 0) & latch(NUM_INV-1);


  -- Output Synchronizer --------------------------------------------------------------------
  -- -------------------------------------------------------------------------------------------
  -- Sample the actual entropy source (= phase noise) and move it to the system's clock domain.

  synchronizer: process(rstn_i, clk_i)
  begin
    if (rstn_i = '1') then
      sync <= (others => '0');
    elsif rising_edge(clk_i) then
      sync <= sync(0) & latch(latch'left);
    end if;
  end process synchronizer;

  -- cell output --
  rnd_o <= sync(1);

end neoTRNG_cell_rtl;
