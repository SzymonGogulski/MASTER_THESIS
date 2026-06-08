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
    
    -- CHANGED: Reseed after 65536 blocks to achieve exactly 1 MiB stream per seed
    constant N_OUTPUT  : integer := 65536;
    
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
    -- CHANGED: Updated TRNG data width to match 224-bit output
    signal trng_data    : std_ulogic_vector(223 downto 0);
    signal rstn_n_trng  : std_ulogic := '0';



    -- aes_enc signals
    signal aes_start      : std_logic := '0';
    signal aes_key        : std_logic_vector(127 downto 0) := (others => '0');
    signal aes_plaintext  : std_logic_vector(127 downto 0) := (others => '0');
    signal aes_ciphertext : std_logic_vector(127 downto 0);
    signal aes_done       : std_logic;



    -- Counter & Composition registers
    -- CHANGED: Segregated structure -> 96-bit fixed Nonce + 32-bit Counter
    signal nonce_reg      : std_logic_vector(95 downto 0) := (others => '0');
    signal ctr_reg        : unsigned(31 downto 0) := (others => '0');
    
    -- CHANGED: Increased range up to 65536 for 1 MiB blocks
    signal block_cnt      : integer range 0 to N_OUTPUT := 0;
    signal byte_cnt       : integer range 0 to 15 := 0;



    -- UART interface signals
    signal uart_tx_data  : std_logic_vector(7 downto 0) := (others => '0');
    signal uart_tx_start : std_logic := '0';
    signal uart_tx_busy  : std_logic;
    signal uart_tx_done  : std_logic;

    -- Buffer to hold active ciphertext block during transmission
    signal tx_buffer     : std_logic_vector(127 downto 0) := (others => '0');

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

    -- 1. neoTRNG Instance (224-bit Output Modified Version)
    trng_inst : entity work.neoTRNG
        generic map (
            NUM_CELLS     => 2,
            NUM_INV_START => 3,
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
            -- FIXED: Default assignment to '0' so ST_START_AES can successfully strobe it low
            aes_start     <= '0';
            uart_tx_start <= '0';

            case state is

                when ST_RESET =>
                    trng_enable <= '1'; -- Turn on TRNG to fetch initial seed key & nonce
                    block_cnt   <= 0;
                    ctr_reg     <= (others => '0');
                    state       <= ST_WAIT_TRNG;

                when ST_WAIT_TRNG =>
                    if trng_valid = '1' then
                        -- CHANGED: Key gets upper 128 bits (223 down to 96)
                        aes_key     <= std_logic_vector(trng_data(223 downto 96)); 
                        -- CHANGED: Nonce gets lower 96 bits (95 down to 0)
                        nonce_reg   <= std_logic_vector(trng_data(95 downto 0));
                        
                        trng_enable <= '0'; -- Turn off TRNG to conserve power
                        block_cnt   <= 0;   -- Reset block count tracking
                        ctr_reg     <= (others => '0'); -- Reset 32-bit stream offset block counter
                        state       <= ST_START_AES;
                    end if;

                when ST_START_AES =>
                    -- CHANGED: Plaintext layout = [ 96-bit Nonce ] & [ 32-bit Counter ]
                    aes_plaintext <= nonce_reg & std_logic_vector(ctr_reg);
                    aes_start     <= '0'; -- Strobe low for one clock cycle (default assignment handles returning high)
                    state         <= ST_WAIT_AES;

                when ST_WAIT_AES =>
                    -- Pull start high for remaining encryption execution cycles
                    aes_start <= '1';
                    if aes_done = '1' then
                        tx_buffer <= aes_ciphertext;                -- Snapshot ciphertext block
                        ctr_reg   <= ctr_reg + 1;                   -- Increment 32-bit keystream counter
                        byte_cnt  <= 0;                             -- Ready to transmit byte 0
                        state     <= ST_LOAD_UART;
                    end if;

                when ST_LOAD_UART =>
                    -- Serialize MSB-first out of the 128-bit text block
                    uart_tx_data  <= tx_buffer(127 - (byte_cnt * 8) downto 120 - (byte_cnt * 8));
                    uart_tx_start <= '1';
                    state         <= ST_WAIT_UART;

                when ST_WAIT_UART =>
                    -- Process handshake safely depending on UART IP finish flag
                    if uart_tx_done = '1' then
                        if byte_cnt = 15 then
                            -- Entire 128-bit block (16 bytes) transmitted
                            if block_cnt = (N_OUTPUT - 1) then
                                -- 65,536 blocks sent (1 MiB total data payload); reseed cycle triggered
                                trng_enable <= '1';
                                state       <= ST_WAIT_TRNG;
                            else
                                -- Process next sequential block under the same key/nonce context
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