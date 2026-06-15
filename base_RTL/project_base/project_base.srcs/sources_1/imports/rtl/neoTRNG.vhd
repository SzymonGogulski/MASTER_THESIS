library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

entity neoTRNG is
  generic (
    NUM_CELLS           : natural range 1 to 255;
    NUM_INV_START       : natural range 3 to 4095;
    NUM_RAW_BITS        : natural range 1 to 4096;
    SIM_MODE            : boolean;
    ENABLE_VON_NEUMANN  : boolean := true;
    ENABLE_CRC          : boolean := true
  );
  port (
    clk_i    : in  std_ulogic;
    rstn_i   : in  std_ulogic;
    enable_i : in  std_ulogic;
    valid_o  : out std_ulogic;
    data_o   : out std_ulogic_vector(7 downto 0)
  );
end entity;

architecture neoTRNG_rtl of neoTRNG is

  function clog2_f(x : natural) return natural is
  begin
    for i in 0 to natural'high loop
      if (2 ** i >= x) then
        return i;
      end if;
    end loop;
    return 0;
  end function;

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

  signal cell_en_in  : std_ulogic_vector(NUM_CELLS - 1 downto 0); 
  signal cell_en_out : std_ulogic_vector(NUM_CELLS - 1 downto 0); 
  signal cell_rnd    : std_ulogic_vector(NUM_CELLS - 1 downto 0); 
  signal cell_sum    : std_ulogic;                                

  signal debias_sreg  : std_ulogic_vector(1 downto 0); 
  signal debias_state : std_ulogic;                    
  signal debias_valid : std_ulogic;                    
  signal debias_data  : std_ulogic;                    

  -- raw bitstream / bypass von neumann --
  signal raw_valid  : std_ulogic;
  signal raw_data   : std_ulogic;

  -- selected stream after optional debiasing
  signal selected_valid    : std_ulogic;
  signal selected_data     : std_ulogic;

  signal sample_en   : std_ulogic;                                        
  signal sample_sreg : std_ulogic_vector(7 downto 0);                     
  signal sample_cnt  : std_ulogic_vector(clog2_f(NUM_RAW_BITS) downto 0);

  constant poly_c : std_ulogic_vector(7 downto 0) := "00000111";

begin

  assert false
    report "[neoTRNG] The neoTRNG (v3.4) - A Tiny and Platform-Independent True Random Number Generator, " & "github.com/stnolting/neoTRNG"
    severity note;

  assert (NUM_INV_START mod 2) /= 0
    report "[neoTRNG] Number of inverters in first cell [NUM_INV_START] has to be odd!"
    severity error;

  assert 2 ** clog2_f(NUM_RAW_BITS) = NUM_RAW_BITS
    report "[neoTRNG] Number of pre-processed raw bits [NUM_RAW_BITS] has to be a power of 2!"
    severity error;

  assert not SIM_MODE
    report "[neoTRNG] Simulation-mode enabled (NO TRUE/PHYSICAL RANDOM)!"
    severity warning;

  entropy_cell_gen: for i in 0 to NUM_CELLS - 1 generate
    neoTRNG_cell_inst: neoTRNG_cell
      generic map (
        NUM_INV  => NUM_INV_START + (2 * i), 
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

  cell_en_in <= cell_en_out(NUM_CELLS - 2 downto 0) & sample_en;

  combine: process (cell_rnd)
    variable tmp_v : std_ulogic;
  begin
    tmp_v := '0';
    for i in 0 to NUM_CELLS - 1 loop
      tmp_v := tmp_v xor cell_rnd(i);
    end loop;
    cell_sum <= tmp_v;
  end process;

  -- John von Neumann Randomness Extractor (De-Biasing) -------------------------------------
  -- -------------------------------------------------------------------------------------------
  debiasing: process (rstn_i, clk_i)
  begin
    if (rstn_i = '0') then
      debias_sreg <= (others => '0');
      debias_state <= '0';
    elsif rising_edge(clk_i) then

      if ENABLE_VON_NEUMANN then
        debias_sreg <= debias_sreg(0) & cell_sum;
        -- start operation when last cell is enabled and process in every second cycle --
        debias_state <= (not debias_state) and cell_en_out(cell_en_out'left);
      else 
        -- VON NEUMANN DISABLED, ignore debias_state --
        debias_state <= '0';
      end if;

    end if;
  end process;

  debias_valid <= debias_state and (debias_sreg(1) xor debias_sreg(0));
  debias_data  <= debias_sreg(0);

  -- bypassed signals --
  raw_valid <= cell_en_out(cell_en_out'left);
  raw_data <= cell_sum;

  selected_valid <= debias_valid when ENABLE_VON_NEUMANN else raw_valid;
  selected_data  <= debias_data  when ENABLE_VON_NEUMANN else raw_data;

  -- Sampling Control -----------------------------------------------------------------------
  -- -------------------------------------------------------------------------------------------
  sampling_control: process (rstn_i, clk_i)
  begin
    if (rstn_i = '0') then
      sample_en <= '0';
      sample_cnt <= (others => '0');
      sample_sreg <= (others => '0');


    elsif rising_edge(clk_i) then
      sample_en <= enable_i;

      if ENABLE_CRC then 

        -- CRC ENABLED --
        if (sample_en = '0') or (sample_cnt(sample_cnt'left) = '1') then -- start new iteration
          sample_cnt <= (others => '0');
          sample_sreg <= (others => '0');
        elsif (selected_valid = '1') then -- valid raw random bit
          sample_cnt <= std_ulogic_vector(unsigned(sample_cnt) + 1);
          -- CRC-style sampling shift-register to mix random stream --
          if ((sample_sreg(sample_sreg'left) xor selected_data) = '1') then -- feedback bit
            sample_sreg <= (sample_sreg(sample_sreg'left - 1 downto 0) & '0') xor poly_c;
          else
            sample_sreg <= (sample_sreg(sample_sreg'left - 1 downto 0) & '0');
          end if;
        end if;

      else 
        -- CRC DISABLED --
        -- no counter usage at all
        sample_cnt <= (others => '0');

        if (sample_en = '1') and (selected_valid = '1') then
          sample_sreg <= sample_sreg(sample_sreg'left-1 downto 0) & selected_data;
        end if;

      end if;
    end if;
  end process;

  data_o  <= sample_sreg;
  valid_o <= sample_cnt(sample_cnt'left) when ENABLE_CRC else selected_valid;

end architecture;

library ieee;
  use ieee.std_logic_1164.all;

entity neoTRNG_cell is
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
end entity;

architecture neoTRNG_cell_rtl of neoTRNG_cell is

  signal sreg    : std_ulogic_vector(NUM_INV - 1 downto 0); 
  signal latch   : std_ulogic_vector(NUM_INV - 1 downto 0); 
  signal inv_in  : std_ulogic_vector(NUM_INV - 1 downto 0); 
  signal inv_out : std_ulogic_vector(NUM_INV - 1 downto 0); 
  signal sync    : std_ulogic_vector(1 downto 0);           

  attribute dont_touch : string;
  attribute keep : string;

  -- Apply to the oscillator signals to prevent optimization
  attribute dont_touch of latch   : signal is "true";
  attribute keep       of latch   : signal is "true";
  
  attribute dont_touch of inv_in  : signal is "true";
  attribute keep       of inv_in  : signal is "true";
  
  attribute dont_touch of inv_out : signal is "true";
  attribute keep       of inv_out : signal is "true";

begin

  en_shift_reg: process (rstn_i, clk_i)
  begin
    if (rstn_i = '0') then
      sreg <= (others => '0');
    elsif rising_edge(clk_i) then
      sreg <= sreg(sreg'left - 1 downto 0) & en_i;
    end if;
  end process;

  en_o <= sreg(sreg'left);

  ring_osc_gen: for i in 0 to NUM_INV - 1 generate

    latch(i) <= '0'           when (en_i = '0')     else
                latch(i)      when (sreg(i) = '0')  else
                inv_out(i);

    inverter_phy: if not SIM_MODE generate
      inv_out(i) <= not inv_in(i);
    end generate;

    inverter_sim: if SIM_MODE generate 
      inverter_sim_ff: process (rstn_i, clk_i) 
      begin
        if (rstn_i = '0') then
          inv_out(i) <= '0';
        elsif rising_edge(clk_i) then
          inv_out(i) <= not inv_in(i);
        end if;
      end process;
    end generate;

  end generate;

  inv_in <= latch(NUM_INV - 2 downto 0) & latch(NUM_INV - 1);

  synchronizer: process (rstn_i, clk_i)
  begin
    if (rstn_i = '0') then
      sync <= (others => '0');
    elsif rising_edge(clk_i) then
      sync <= sync(0) & latch(latch'left);
    end if;
  end process;

  rnd_o <= sync(1);

end architecture;
