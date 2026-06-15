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

    -- 1-Second Timebase Parameters
    -- 125,000,000 cycles = 1 second
    constant ONE_SECOND_LIMIT : integer := CLK_FREQ;
    signal sec_timer          : integer range 0 to ONE_SECOND_LIMIT := 0;

    -- TRNG signals
    signal trng_valid : std_ulogic;
    signal trng_data  : std_ulogic_vector(127 downto 0); -- Still mapped, but unused except to satisfy ports

    -- Counter Registers
    signal block_counter    : unsigned(31 downto 0) := (others => '0');
    signal latch_tx_counter : std_logic_vector(31 downto 0) := (others => '0');
    signal start_tx_strobe  : std_logic := '0';

    -- UART signals (Modified for 32-bit / 4-byte operation)
    signal tx_reg     : std_logic := '1';
    signal uart_cnt   : integer range 0 to BAUD_DIV := 0;
    signal bit_idx    : integer range 0 to 9 := 0;
    signal byte_idx   : integer range 0 to 3 := 0; -- Tracks 4 bytes within the 32-bit counter
    signal tx_buffer  : std_logic_vector(31 downto 0) := (others => '0');
    signal busy       : std_logic := '0';

begin

    tx <= tx_reg;

    -- TRNG Core instantiation 
    trng_inst : entity work.neoTRNG
        generic map (
            NUM_CELLS     => 3,    
            NUM_INV_START => 3,
            SIM_MODE      => false
        )
        port map (
            clk_i    => clk,
            rstn_i   => '0',   -- NOTE: Consider changing to a proper reset if needed
            enable_i => '1',   
            valid_o  => trng_valid,
            data_o   => trng_data
        );

    -- -------------------------------------------------------------------------
    -- 1-Second Timebase & Block Accumulator Logic
    -- -------------------------------------------------------------------------
    process(clk)
    begin
        if rising_edge(clk) then
            start_tx_strobe <= '0'; -- Default single-cycle pulse

            -- Continuously count incoming TRNG valid blocks
            if trng_valid = '1' then
                block_counter <= block_counter + 1;
            end if;

            -- 1-Second Tick Generator
            if sec_timer < ONE_SECOND_LIMIT - 1 then
                sec_timer <= sec_timer + 1;
            else
                sec_timer        <= 0;
                latch_tx_counter <= std_logic_vector(block_counter);
                start_tx_strobe  <= '1'; -- Signal UART machine to transmit
                block_counter    <= (others => '0'); -- Reset counter for the next second
            end if;
        end if;
    end process;

    -- -------------------------------------------------------------------------
    -- UART Transmitter (Serializes 32-bit block count into 4 sequential bytes)
    -- -------------------------------------------------------------------------
    process(clk)
    begin
        if rising_edge(clk) then
            if busy = '0' then
                -- IDLE: Wait for the 1-second strobe to latch the data
                if start_tx_strobe = '1' then
                    tx_buffer <= latch_tx_counter;
                    busy      <= '1';
                    uart_cnt  <= 0;
                    bit_idx   <= 0;
                    byte_idx  <= 0;
                    tx_reg    <= '1'; -- Line idle high
                end if;
            else
                -- BUSY: Processing the 32-bit counter transmission
                if uart_cnt < BAUD_DIV - 1 then
                    uart_cnt <= uart_cnt + 1;
                else
                    uart_cnt <= 0;

                    -- UART Frame Slicing (Start + 8 Data + Stop)
                    case bit_idx is
                        when 0 =>
                            tx_reg <= '0'; -- Start bit
                        when 1 to 8 =>
                            -- Transmit LSB bit of the bottom byte currently in the buffer
                            tx_reg <= tx_buffer(bit_idx - 1);
                        when 9 =>
                            tx_reg <= '1'; -- Stop bit
                        when others =>
                            tx_reg <= '1';
                    end case;

                    -- Shift Machine Serialization Steps
                    if bit_idx < 9 then
                        bit_idx <= bit_idx + 1;
                    else
                        -- Byte frame complete!
                        bit_idx <= 0;
                        
                        if byte_idx < 3 then
                            byte_idx  <= byte_idx + 1;
                            -- Shift out the consumed byte (8 bits) to expose the next byte
                            tx_buffer <= x"00" & tx_buffer(31 downto 8);
                        else
                            -- All 4 bytes (32-bits) transmitted successfully
                            busy <= '0'; 
                        end if;
                    end if;
                end if;
            end if;
        end if;
    end process;

end Behavioral;