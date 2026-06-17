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

    -- 1-Second Timer Constant
    constant ONE_SECOND_LIMIT : integer := CLK_FREQ; 

    -- TRNG signals
    signal trng_valid : std_ulogic;
    signal trng_data  : std_ulogic_vector(7 downto 0);

    -- Measurement Signals
    signal one_sec_counter   : integer range 0 to ONE_SECOND_LIMIT := 0;
    signal byte_accumulator  : unsigned(31 downto 0) := (others => '0');
    signal latched_throughput: std_logic_vector(31 downto 0) := (others => '0');
    signal data_ready        : std_logic := '0';

    -- UART signals
    signal tx_reg      : std_logic := '1';
    signal uart_cnt    : integer range 0 to BAUD_DIV := 0;
    signal bit_idx     : integer range 0 to 9 := 0;
    signal tx_buffer   : std_logic_vector(7 downto 0) := (others => '0');
    signal busy        : std_logic := '0';
    
    -- Multi-byte tracking for transmission (5 bytes total: 1 sync + 4 data)
    signal byte_idx    : integer range 0 to 4 := 0;

begin

    tx <= tx_reg;

    -- TRNG Instance
    trng_inst : entity work.neoTRNG
        generic map (
            NUM_CELLS           => 2,
            NUM_INV_START       => 3,
            NUM_RAW_BITS        => 64,
            SIM_MODE            => false,
            ENABLE_VON_NEUMANN  => false,
            ENABLE_CRC          => false
        )
        port map (
            clk_i    => clk,
            rstn_i   => '1',
            enable_i => '1',
            valid_o  => trng_valid,
            data_o   => trng_data
        );

    ----------------------------------------------------------------
    -- 1. Throughput Accumulator & Timer Process
    ----------------------------------------------------------------
    process(clk)
    begin
        if rising_edge(clk) then
            data_ready <= '0'; 

            if trng_valid = '1' then
                byte_accumulator <= byte_accumulator + 1;
            end if;

            if one_sec_counter < ONE_SECOND_LIMIT - 1 then
                one_sec_counter <= one_sec_counter + 1;
            else
                one_sec_counter    <= 0;
                latched_throughput <= std_logic_vector(byte_accumulator);
                byte_accumulator   <= (others => '0'); 
                data_ready         <= '1';             
            end if;
        end if;
    end process;


    ----------------------------------------------------------------
    -- 2. Multi-Byte UART Transmitter Process (with 0x00 Prefix)
    ----------------------------------------------------------------
    process(clk)
    begin
        if rising_edge(clk) then
            if busy = '0' then
                -- IDLE: Wait for 1-second trigger
                if data_ready = '1' then
                    busy     <= '1';
                    uart_cnt <= 0;
                    bit_idx  <= 0;
                    byte_idx <= 0; -- Start at byte 0 (the sync byte)
                    
                    -- Load the preamble (Sync Byte: All Zeros)
                    tx_buffer <= (others => '0'); 
                    tx_reg    <= '1'; 
                end if;
            else
                -- BUSY: Processing bits and bytes
                if uart_cnt < BAUD_DIV - 1 then
                    uart_cnt <= uart_cnt + 1;
                else
                    uart_cnt <= 0;

                    -- UART Bit State Machine
                    case bit_idx is
                        when 0 =>
                            tx_reg <= '0'; -- Start bit
                        when 1 to 8 =>
                            tx_reg <= tx_buffer(bit_idx - 1); -- Data bits
                        when 9 =>
                            tx_reg <= '1'; -- Stop bit
                        when others =>
                            tx_reg <= '1';
                    end case;

                    -- Move to next bit / Next byte handling
                    if bit_idx < 9 then
                        bit_idx <= bit_idx + 1;
                    else
                        -- Finished transmitting current byte frame
                        if byte_idx < 4 then
                            -- Advance byte tracker and reset bit state machine
                            byte_idx <= byte_idx + 1;
                            bit_idx  <= 0; 
                            
                            -- Load buffer for the *next* transmission cycle
                            -- Note: byte_idx here represents what was just sent
                            case byte_idx is
                                when 0 => tx_buffer <= latched_throughput(31 downto 24); -- Byte 1 (MSB)
                                when 1 => tx_buffer <= latched_throughput(23 downto 16); -- Byte 2
                                when 2 => tx_buffer <= latched_throughput(15 downto 8);  -- Byte 3
                                when 3 => tx_buffer <= latched_throughput(7 downto 0);   -- Byte 4 (LSB)
                                when others => null;
                            end case;
                        else
                            -- All 5 bytes (1 sync + 4 data) have been transmitted
                            busy <= '0';
                        end if;
                    end if;
                end if;
            end if;
        end if;
    end process;

end Behavioral;