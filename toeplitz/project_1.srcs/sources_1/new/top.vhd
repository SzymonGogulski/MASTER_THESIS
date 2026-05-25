library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity top is
    Port (
        clk : in  STD_LOGIC;  -- 125 MHz clock
        tx  : out STD_LOGIC   -- UART TX output
    );
end top;

architecture Behavioral of top is

    -- UART parameters
    constant BAUD_RATE : integer := 921600;
    constant CLK_FREQ  : integer := 125_000_000;
    constant BAUD_DIV  : integer := CLK_FREQ / BAUD_RATE;

    -- TRNG signals (Updated for 128-bit Toeplitz blocks)
    signal trng_valid : std_ulogic;
    signal trng_data  : std_ulogic_vector(127 downto 0);

    -- UART signals
    signal tx_reg     : std_logic := '1';
    signal uart_cnt   : integer range 0 to BAUD_DIV := 0;
    signal bit_idx    : integer range 0 to 9 := 0;
    signal byte_idx   : integer range 0 to 15 := 0; -- Tracks the 16 bytes within the 128-bit block
    signal tx_buffer  : std_ulogic_vector(127 downto 0) := (others => '0');
    signal busy       : std_logic := '0';

begin

    tx <= tx_reg;

    -- TRNG Core instantiation (Generics updated for Toeplitz integration)
    trng_inst : entity work.neoTRNG
        generic map (
            NUM_CELLS     => 3,
            NUM_INV_START => 5,
            SIM_MODE      => false
        )
        port map (
            clk_i    => clk,
            rstn_i   => '0',
            enable_i => '1',   -- ALWAYS ENABLED
            valid_o  => trng_valid,
            data_o   => trng_data
        );

    -- UART transmitter (Serializes a 128-bit block into 16 sequential bytes)
    process(clk)
    begin
        if rising_edge(clk) then
            if busy = '0' then
                -- IDLE: Monitor for a completely ready 128-bit random block
                if trng_valid = '1' then
                    tx_buffer <= trng_data;
                    busy      <= '1';
                    uart_cnt  <= 0;
                    bit_idx   <= 0;
                    byte_idx  <= 0;
                    tx_reg    <= '1'; -- Line idle high
                end if;
            else
                -- BUSY: Processing the current 128-bit data block
                if uart_cnt < BAUD_DIV - 1 then
                    uart_cnt <= uart_cnt + 1;
                else
                    uart_cnt <= 0;

                    -- Traditional UART Bit-Slicing Frame (Start + 8 Data + Stop)
                    case bit_idx is
                        when 0 =>
                            tx_reg <= '0'; -- Start bit
                        when 1 to 8 =>
                            -- Always transmit the LSB byte currently at the bottom of the buffer
                            tx_reg <= std_logic(tx_buffer(bit_idx - 1));
                        when 9 =>
                            tx_reg <= '1'; -- Stop bit
                        when others =>
                            tx_reg <= '1';
                    end case;

                    -- Shift Machine Step Logic
                    if bit_idx < 9 then
                        bit_idx <= bit_idx + 1;
                    else
                        -- Byte frame complete! Ready next byte or clear block state
                        bit_idx <= 0;
                        
                        if byte_idx < 15 then
                            byte_idx  <= byte_idx + 1;
                            -- Shift out the consumed byte (8 bits down) to expose the next byte
                            tx_buffer <= x"00" & tx_buffer(127 downto 8);
                        else
                            -- All 16 bytes from the block successfully serialized
                            busy <= '0'; 
                        end if;
                    end if;
                end if;
            end if;
        end if;
    end process;

end Behavioral;