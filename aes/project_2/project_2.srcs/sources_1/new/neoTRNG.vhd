library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity neoTRNG is
	generic (
		NUM_CELLS : natural range 1 to 255; -- number of ring-oscillator cells, min 1
		NUM_INV_START : natural range 3 to 4095; -- number of inverters in first ring-oscillator cell, has to be odd
		SIM_MODE : boolean -- enable simulation mode (no physical random if enabled!)
	);
	port (
		clk_i : in std_ulogic; -- module clock
		rstn_i : in std_ulogic; -- module reset, low-active, async, optional
		enable_i : in std_ulogic; -- module enable (high-active)
		valid_o : out std_ulogic; -- data_o is valid when set (high for one cycle)
		data_o : out std_ulogic_vector(223 downto 0) -- block of random data
	);
end neoTRNG;

architecture neoTRNG_rtl of neoTRNG is

	-- entropy source cell --
	component neoTRNG_cell
		generic (
			NUM_INV : natural; -- number of inverters, has to be odd, min 3
			SIM_MODE : boolean -- enable simulation mode (no physical random if enabled!)
		);
		port (
			clk_i : in std_ulogic; -- clock
			rstn_i : in std_ulogic; -- reset, low-active, async, optional
			en_i : in std_ulogic; -- enable-chain input
			en_o : out std_ulogic; -- enable-chain output
			rnd_o : out std_ulogic -- random data (sync)
		);
	end component;

	-- entropy cell interconnect --
	signal cell_en_in : std_ulogic_vector(NUM_CELLS - 1 downto 0); -- enable-sreg input
	signal cell_en_out : std_ulogic_vector(NUM_CELLS - 1 downto 0); -- enable-sreg output
	signal cell_rnd : std_ulogic_vector(NUM_CELLS - 1 downto 0); -- cell random output
	signal cell_sum : std_ulogic; -- combined random data

	-- sampling control --
	signal sample_en : std_ulogic; -- global enable
	signal sample_sreg : std_ulogic_vector(223 downto 0); -- shift-register / de-serializer
	signal sample_cnt : integer range 0 to 224;
	signal valid_reg : std_ulogic;
	signal data_reg : std_ulogic_vector(223 downto 0);

begin

	-- Entropy Source -------------------------------------------------------------------------
	-- -------------------------------------------------------------------------------------------
	entropy_cell_gen :
	for i in 0 to NUM_CELLS - 1 generate
		neoTRNG_cell_inst : neoTRNG_cell
		generic map(
			NUM_INV => NUM_INV_START + (2 * i), -- increasing (odd) ring-oscillator length
			SIM_MODE => SIM_MODE
		)
		port map(
			clk_i => clk_i,
			rstn_i => rstn_i,
			en_i => cell_en_in(i),
			en_o => cell_en_out(i),
			rnd_o => cell_rnd(i)
		);
	end generate;

	-- enable-shift-register chain --
	cell_en_in <= cell_en_out(NUM_CELLS - 2 downto 0) & sample_en;

	-- combine cell outputs --
	combine : process (cell_rnd)
		variable tmp_v : std_ulogic;
	begin
		tmp_v := '0';
		for i in 0 to NUM_CELLS - 1 loop
			tmp_v := tmp_v xor cell_rnd(i);
		end loop;
		cell_sum <= tmp_v;
	end process combine;

	-- TRNG output stream --
	sampling : process (rstn_i, clk_i)
  	begin
		if (rstn_i = '0') then
			sample_en   <= '0';
			sample_cnt  <= 0;
			sample_sreg <= (others => '0');
			data_reg    <= (others => '0');
			valid_reg   <= '0';
		elsif rising_edge(clk_i) then

			-- Default assignment: valid pulse lasts only for a single clock cycle
            valid_reg <= '0'; 

            -- Enable the overall entropy harvesting chain based on module enable
            sample_en <= enable_i;

            if (enable_i = '0') then
                -- if enable_i goes low discard sample_sreg, reset sample_cnt, pull valid_o low
                sample_cnt  <= 0;
                sample_sreg <= (others => '0');
            else
                -- collect data when cell_en_out(cell_en_out'left) goes high
                if (cell_en_out(cell_en_out'left) = '1') then

                    sample_sreg <= sample_sreg(222 downto 0) & cell_sum;
                    
                    if (sample_cnt = 223) then
                        valid_reg  <= '1';
						data_reg   <= sample_sreg(222 downto 0) & cell_sum;
                        sample_cnt <= 0;
                    else
                        sample_cnt <= sample_cnt + 1;
                    end if;
                end if;
            end if;
		end if;
  	end process sampling;

	data_o <= data_reg;
	valid_o <= valid_reg;

end neoTRNG_rtl;










-- ================================================================================================ --
-- neoTRNG entropy source cell, based on a simple ring-oscillator constructed from an odd number    --
-- of inverters. The inverters are decoupled using individually-enabled latches to prevent          --
-- synthesis from "optimizing" (=removing) parts of the oscillator chain.                           --
-- ================================================================================================ --

library ieee;
use ieee.std_logic_1164.all;

entity neoTRNG_cell is
	generic (
		NUM_INV : natural; -- number of inverters, has to be odd, min 3
		SIM_MODE : boolean -- enable simulation mode (no physical random if enabled!)
	);
	port (
		clk_i : in std_ulogic; -- clock
		rstn_i : in std_ulogic; -- reset, low-active, async, optional
		en_i : in std_ulogic; -- enable-chain input
		en_o : out std_ulogic; -- enable-chain output
		rnd_o : out std_ulogic -- random data (sync)
	);
end neoTRNG_cell;

architecture neoTRNG_cell_rtl of neoTRNG_cell is

	signal sreg : std_ulogic_vector(NUM_INV - 1 downto 0); -- enable-shift-register
	signal latch : std_ulogic_vector(NUM_INV - 1 downto 0); -- ring oscillator: latches
	signal inv_in : std_ulogic_vector(NUM_INV - 1 downto 0); -- ring oscillator: inverter inputs
	signal inv_out : std_ulogic_vector(NUM_INV - 1 downto 0); -- ring oscillator: inverter outputs
	signal sync : std_ulogic_vector(1 downto 0); -- output synchronizer

begin

	-- Enable Shift-Register ------------------------------------------------------------------
	-- -------------------------------------------------------------------------------------------
	-- Using individual enable signals from a shift register for each inverter in order to prevent
	-- the synthesis tool from removing all but one inverter (since they implement "logical
	-- identical functions"). This makes the TRNG platform independent as we do not require tool-/
	-- technology-specific primitives, attributes or other options.

	en_shift_reg : process (rstn_i, clk_i)
	begin
		if (rstn_i = '0') then
			sreg <= (others => '0');
		elsif rising_edge(clk_i) then
			sreg <= sreg(sreg'left - 1 downto 0) & en_i;
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

	ring_osc_gen :
	for i in 0 to NUM_INV - 1 generate

		-- latch with global reset and individual enable --
		latch(i) <= '0' when (en_i = '0') else
		latch(i) when (sreg(i) = '0') else
		inv_out(i);

		-- inverter for actual synthesis --
		inverter_phy :
		if not SIM_MODE generate
			inv_out(i) <= not inv_in(i); -- this is one part of the ring oscillator's physical propagation delay
		end generate;

		-- inverter with "propagation delay" (implemented as a simple FF) --
		inverter_sim :
		if SIM_MODE generate -- for SIMULATION ONLY!
			inverter_sim_ff : process (rstn_i, clk_i) -- this will NOT generate true random numbers
			begin
				if (rstn_i = '0') then
					inv_out(i) <= '0';
				elsif rising_edge(clk_i) then
					inv_out(i) <= not inv_in(i);
				end if;
			end process inverter_sim_ff;
		end generate;

	end generate;

	-- chaining --
	inv_in <= latch(NUM_INV - 2 downto 0) & latch(NUM_INV - 1);
	-- Output Synchronizer --------------------------------------------------------------------
	-- -------------------------------------------------------------------------------------------
	-- Sample the actual entropy source (= phase noise) and move it to the system's clock domain.

	synchronizer : process (rstn_i, clk_i)
	begin
		if (rstn_i = '0') then
			sync <= (others => '0');
		elsif rising_edge(clk_i) then
			sync <= sync(0) & latch(latch'left);
		end if;
	end process synchronizer;

	-- cell output --
	rnd_o <= sync(1);

end neoTRNG_cell_rtl;