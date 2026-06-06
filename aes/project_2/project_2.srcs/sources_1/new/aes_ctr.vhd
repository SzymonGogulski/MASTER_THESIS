library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity aes_ctr is
    Port (
        clk : in  STD_LOGIC;  -- 125 MHz clock
        tx  : out STD_LOGIC   -- UART TX output
    );
end aes_ctr;

architecture Behavioral of aes_ctr is

    -- UART parameters
    constant BAUD_RATE : integer := 921600;
    constant CLK_FREQ  : integer := 125_000_000;
    constant BAUD_DIV  : integer := CLK_FREQ / BAUD_RATE;
    -- Reseed the aes_enc after every <N_OUTPUT> block transmitted via UART
    constant N_OUTPUT  : integer := 16;
    
    -- State Machine Definition
    type state_type is (
        ST_RESET, 
        ST_WAIT_TRNG, 
        ST_START_AES, 
        ST_WAIT_AES, 
        ST_LOAD_UART, 
        ST_WAIT_UART
    );
    signal state : state_type := ST_RESET;

    -- neoTRNG signals
    signal trng_enable  : std_ulogic := '0';
    signal trng_valid   : std_ulogic;
    signal trng_data    : std_ulogic_vector(127 downto 0);
    signal rstn_n_trng  : std_ulogic := '0';

    -- aes_enc signals
    signal aes_start      : std_logic := '0';
    signal aes_key        : std_logic_vector(127 downto 0) := (others => '0');
    signal aes_plaintext  : std_logic_vector(127 downto 0) := (others => '0');
    signal aes_ciphertext : std_logic_vector(127 downto 0);
    signal aes_done       : std_logic;

    -- Counter registers
    signal ctr_reg        : unsigned(127 downto 0) := (others => '0');
    signal block_cnt      : integer range 0 to N_OUTPUT := 0;
    signal byte_cnt       : integer range 0 to 15 := 0;

    -- UART interface signals
    signal uart_tx_data  : std_logic_vector(7 downto 0) := (others => '0');
    signal uart_tx_start : std_logic := '0';
    signal uart_tx_busy  : std_logic;
    signal uart_tx_done  : std_logic;

    -- Buffer to hold active ciphertext block during transmission
    signal tx_buffer     : std_logic_vector(127 downto 0) := (others => '0');

    -- Simple inline UART TX component description 
    -- (Assumes standard start bit, 8 data bits, 1 stop bit architecture)
    component simple_uart_tx is
        generic (
            BAUD_DIV : integer
        );
        port (
            clk      : in  std_logic;
            tx_start : in  std_logic;
            tx_data  : in  std_logic_vector(7 downto 0);
            tx_busy  : out std_logic;
            tx_done  : out std_logic;
            tx_out   : out std_logic
        );
    end component;

begin

    -- Release reset immediately 
    rstn_n_trng <= '1';

    -- 1. neoTRNG Instance
    trng_inst : entity work.neoTRNG
        generic map (
            NUM_CELLS     => 3,
            NUM_INV_START => 5,
            SIM_MODE      => false
        )
        port map (
            clk_i    => clk,
            rstn_i   => rstn_n_trng,
            enable_i => trng_enable,
            valid_o  => trng_valid,
            data_o   => trng_data
        );

    -- 2. AES Encryption Engine Instance
    aes_ctr_inst : entity work.aes_enc
        port map (
            clk        => clk,
            start      => aes_start,
            key        => aes_key,
            plaintext  => aes_plaintext,
            ciphertext => aes_ciphertext,
            done       => aes_done
        );

    -- 3. UART Transmitter Instantiation
    -- (Ensure you have a basic UART transmitter implementation in your design directory)
    uart_inst : simple_uart_tx
        generic map (
            BAUD_DIV => BAUD_DIV
        )
        port map (
            clk      => clk,
            tx_start => uart_tx_start,
            tx_data  => uart_tx_data,
            tx_busy  => uart_tx_busy,
            tx_done  => uart_tx_done,
            tx_out   => tx
        );

    -- 4. Central Controller State Machine
    process(clk)
    begin
        if rising_edge(clk) then
            -- Default assignments
            aes_start     <= '1';
            uart_tx_start <= '0';

            case state is

                when ST_RESET =>
                    trng_enable <= '1'; -- Turn on TRNG to fetch initial seed key
                    block_cnt   <= 0;
                    ctr_reg     <= (others => '0');
                    state       <= ST_WAIT_TRNG;

                when ST_WAIT_TRNG =>
                    if trng_valid = '1' then
                        aes_key     <= std_logic_vector(trng_data); -- Seed new key
                        trng_enable <= '0';                         -- Turn off TRNG to conserve power
                        block_cnt   <= 0;                           -- Reset block counter for the new key
                        state       <= ST_START_AES;
                    end if;

                when ST_START_AES =>
                    aes_plaintext <= std_logic_vector(ctr_reg);     -- Feed current counter value
                    aes_start     <= '0';                           -- Strobe start
                    state         <= ST_WAIT_AES;

                when ST_WAIT_AES =>
                    if aes_done = '1' then
                        tx_buffer <= aes_ciphertext;                -- Snapshot ciphertext block
                        ctr_reg   <= ctr_reg + 1;                   -- Safely increment the 128-bit counter
                        byte_cnt  <= 0;                             -- Ready to transmit byte 0
                        state     <= ST_LOAD_UART;
                    end if;

                when ST_LOAD_UART =>
                    -- Serialize MSB-first out of the 128-bit text block (Byte 15 down to 0)
                    -- To change to LSB-first, modify slice range to: (byte_cnt*8+7 downto byte_cnt*8)
                    uart_tx_data  <= tx_buffer(127 - (byte_cnt * 8) downto 120 - (byte_cnt * 8));
                    uart_tx_start <= '1';
                    state         <= ST_WAIT_UART;

                when ST_WAIT_UART =>
                    -- Wait for the UART engine to complete shifting out the current frame
                    if uart_tx_done = '1' or (uart_tx_busy = '0' and uart_tx_start = '0') then
                        if byte_cnt = 15 then
                            -- Entire 128-bit block (16 bytes) transmitted
                            if block_cnt = (N_OUTPUT - 1) then
                                -- We've sent N_OUTPUT blocks; trigger a reseed cycle
                                trng_enable <= '1';
                                state       <= ST_WAIT_TRNG;
                            else
                                -- Process next sequential block under the same key
                                block_cnt <= block_cnt + 1;
                                state     <= ST_START_AES;
                            end if;
                        else
                            -- Move to the next byte of the current block
                            byte_cnt <= byte_cnt + 1;
                            state    <= ST_LOAD_UART;
                        end if;
                    end if;

                when others =>
                    state <= ST_RESET;

            end case;
        end if;
    end process;

end Behavioral;