library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity top is
    Port (
        clk     : in  STD_LOGIC;  -- 125 MHz clock
        tx      : out STD_LOGIC   -- UART TX output
    );
end top;

architecture Behavioral of top is

    -- UART parameters
    constant BAUD_RATE       : integer := 115200;
    constant CLK_FREQ        : integer := 125_000_000; -- 125 MHz
    constant BAUD_DIV        : integer := CLK_FREQ / BAUD_RATE;

    -- One-second timer
    constant ONE_SEC_COUNT   : integer := CLK_FREQ / 10;

    -- UART signals
    signal tx_reg            : STD_LOGIC := '1';
    signal uart_clk_cnt      : integer range 0 to BAUD_DIV := 0;
    signal bit_cnt           : integer range 0 to 9 := 0; -- start + 8 data + stop
    signal tx_data           : std_ulogic_vector(7 downto 0) := (others => '0');
    signal sending           : std_logic := '0';

    -- 1-second counter
    signal sec_cnt           : integer range 0 to ONE_SEC_COUNT := 0;

    -- TRNG signals
    signal trng_enable       : std_logic := '0';
    signal trng_valid        : std_logic;
    signal trng_data         : std_ulogic_vector(7 downto 0);

begin

    tx <= tx_reg;

    -- Instantiate TRNG
    trng_inst : entity work.neoTRNG
        generic map (
            NUM_CELLS     => 3,
            NUM_INV_START => 5,
            NUM_RAW_BITS  => 64,
            SIM_MODE      => false
        )
        port map (
            clk_i    => clk,
            rstn_i   => '1',
            enable_i => trng_enable,
            valid_o  => trng_valid,
            data_o   => trng_data
        );

    process(clk)
    begin
        if rising_edge(clk) then

            -- 1-second timer
            if sec_cnt < ONE_SEC_COUNT - 1 then
                sec_cnt <= sec_cnt + 1;
            else
                sec_cnt <= 0;
                trng_enable <= '1';  -- enable TRNG
            end if;

            -- Read TRNG when valid
            if trng_valid = '1' and trng_enable = '1' then
                tx_data <= trng_data; -- latch random byte
                trng_enable <= '0';   -- disable TRNG
                sending <= '1';
                uart_clk_cnt <= 0;
                bit_cnt <= 0;
            end if;

            -- UART transmission
            if sending = '1' then
                if uart_clk_cnt < BAUD_DIV - 1 then
                    uart_clk_cnt <= uart_clk_cnt + 1;
                else
                    uart_clk_cnt <= 0;
                    case bit_cnt is
                        when 0 => tx_reg <= '0'; -- start bit
                        when 1 to 8 => tx_reg <= tx_data(bit_cnt-1); -- data bits
                        when 9 => tx_reg <= '1'; -- stop bit
                        when others => null;
                    end case;

                    if bit_cnt < 9 then
                        bit_cnt <= bit_cnt + 1;
                    else
                        bit_cnt <= 0;
                        sending <= '0';
                    end if;
                end if;
            else
                tx_reg <= '1'; -- idle high
            end if;

        end if;
    end process;

end Behavioral;
