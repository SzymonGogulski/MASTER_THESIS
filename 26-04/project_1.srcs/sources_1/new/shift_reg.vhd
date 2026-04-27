library ieee;
use ieee.std_logic_1164.all;

entity shift_reg is
    generic (
        STAGES : integer := 4  -- Number of clock cycles to delay
    );
    port (
        clk_i  : in  std_logic;
        rstn_i : in  std_logic;
        en_i   : in  std_logic;
        en_o   : out std_logic
    );
end entity shift_reg;

architecture rtl of shift_reg is
    signal sreg : std_logic_vector(STAGES-1 downto 0);
begin

    en_shift_reg: process(rstn_i, clk_i)
    begin
        if (rstn_i = '0') then
            sreg <= (others => '0');
        elsif rising_edge(clk_i) then
            -- Shift left and concatenate the new input bit at the LSB
            sreg <= sreg(sreg'left-1 downto 0) & en_i;
        end if;
    end process en_shift_reg;

    -- Output the MSB (the bit that has traveled through all stages)
    en_o <= sreg(sreg'left);

end architecture rtl;