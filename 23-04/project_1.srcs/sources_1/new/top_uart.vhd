library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity top_uart is
    Port (
        clk : in  STD_LOGIC;  -- 125 MHz clock
        tx  : out STD_LOGIC   -- UART TX output
    );
end top_uart;

architecture Behavioral of top_uart is

    -- UART parameters
    constant BAUD_RATE : integer := 921600;
    constant CLK_FREQ  : integer := 125_000_000;
    constant BAUD_DIV  : integer := CLK_FREQ / BAUD_RATE;

    -- TRNG component
    component neoTRNG
        generic (
            NUM_CELLS     : natural range 1 to 99   := 3;
            NUM_INV_START : natural range 3 to 99   := 5;
            NUM_RAW_BITS  : natural range 1 to 4096 := 64;
            SIM_MODE      : boolean                 := false
        );
        port (
            clk_i    : in  std_ulogic;
            rstn_i   : in  std_ulogic;
            enable_i : in  std_ulogic;
            valid_o  : out std_ulogic;
            data_o   : out std_ulogic_vector(7 downto 0)
        );
    end component;

    -- TRNG signals
    signal trng_valid : std_ulogic;
    signal trng_data  : std_ulogic_vector(7 downto 0);

    -- UART signals
    signal tx_reg    : std_logic := '1';
    signal uart_cnt  : integer range 0 to BAUD_DIV := 0;
    signal bit_idx   : integer range 0 to 9 := 0;
    signal tx_buffer : std_ulogic_vector(7 downto 0) := (others => '0');
    signal busy      : std_logic := '0';

begin

    tx <= tx_reg;

    -- TRNG always ON (no throttling!)
    trng_inst : neoTRNG
        generic map (
            NUM_CELLS     => 3,
            NUM_INV_START => 5,
            NUM_RAW_BITS  => 64,
            SIM_MODE      => false
        )
        port map (
            clk_i    => clk,
            rstn_i   => '1',
            enable_i => '1',   -- ALWAYS ENABLED
            valid_o  => trng_valid,
            data_o   => trng_data
        );

    -- UART transmitter (continuous streaming)
    process(clk)
    begin
        if rising_edge(clk) then

            -- If UART idle and TRNG has data → start transmission immediately
            if (busy = '0') and (trng_valid = '1') then
                tx_buffer <= trng_data;
                busy      <= '1';
                uart_cnt  <= 0;
                bit_idx   <= 0;
            end if;

            -- UART transmission in progress
            if busy = '1' then
                if uart_cnt < BAUD_DIV - 1 then
                    uart_cnt <= uart_cnt + 1;
                else
                    uart_cnt <= 0;

                    case bit_idx is
                        when 0 =>
                            tx_reg <= '0'; -- start bit
                        when 1 to 8 =>
                            tx_reg <= std_logic(tx_buffer(bit_idx - 1));
                        when 9 =>
                            tx_reg <= '1'; -- stop bit
                        when others =>
                            tx_reg <= '1';
                    end case;

                    if bit_idx < 9 then
                        bit_idx <= bit_idx + 1;
                    else
                        busy <= '0'; -- immediately ready for next byte
                    end if;
                end if;
            end if;

        end if;
    end process;

end Behavioral;
