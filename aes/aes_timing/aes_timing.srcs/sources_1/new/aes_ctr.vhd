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
    
    -- Reseed after 65536 blocks to achieve exactly 1 MiB stream per seed
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
    signal trng_data    : std_ulogic_vector(223 downto 0);
    signal rstn_n_trng  : std_ulogic := '0';

    -- aes_enc signals
    signal aes_start      : std_logic := '0';
    signal aes_key        : std_logic_vector(127 downto 0) := (others => '0');
    signal aes_plaintext  : std_logic_vector(127 downto 0) := (others => '0');
    signal aes_ciphertext : std_logic_vector(127 downto 0);
    signal aes_done       : std_logic;

    -- Counter & Composition registers
    signal nonce_reg      : std_logic_vector(95 downto 0) := (others => '0');
    signal ctr_reg        : unsigned(31 downto 0) := (others => '0');
    signal block_cnt      : integer range 0 to N_OUTPUT := 0;

    -- 1-Second Timer and Performance Metrics
    signal one_second_timer   : unsigned(26 downto 0) := (others => '0'); 
    signal block_rate_counter : unsigned(31 downto 0) := (others => '0'); 
    signal tx_count_data      : std_logic_vector(31 downto 0) := (others => '0'); 
    signal byte_cnt           : integer range 0 to 3 := 0;  
    
    -- FIXED: Clean handshake flags
    signal send_metrics_pending : std_logic := '0';
    signal clear_metrics_flag   : std_logic := '0';

    -- UART interface signals
    signal uart_tx_data  : std_logic_vector(7 downto 0) := (others => '0');
    signal uart_tx_start : std_logic := '0';
    signal uart_tx_busy  : std_logic;
    signal uart_tx_done  : std_logic;

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

    -- 4. FIXED: Isolated 1-Second Timer & Accumulator
    process(clk)
    begin
        if rising_edge(clk) then
            -- Continuously count completed blocks
            if aes_done = '1' then
                block_rate_counter <= block_rate_counter + 1;
            end if;

            -- Timer tracking
            if one_second_timer = (CLK_FREQ - 1) then
                one_second_timer     <= (others => '0');
                tx_count_data        <= std_logic_vector(block_rate_counter);
                block_rate_counter   <= (others => '0'); -- Reset count for next interval
                send_metrics_pending <= '1';            -- Flag state machine that data is ready
            else
                one_second_timer <= one_second_timer + 1;
                
                -- Clear flag only when State Machine acknowledges completion
                if clear_metrics_flag = '1' then
                    send_metrics_pending <= '0';
                end if;
            end if;
        end if;
    end process;


    -- 5. Central Controller State Machine
    process(clk)
    begin
        if rising_edge(clk) then
            aes_start          <= '0';
            uart_tx_start      <= '0';
            clear_metrics_flag <= '0'; -- Default to avoid latches

            case state is

                when ST_RESET =>
                    trng_enable <= '1'; 
                    block_cnt   <= 0;
                    ctr_reg     <= (others => '0');
                    state       <= ST_WAIT_TRNG;

                when ST_WAIT_TRNG =>
                    if trng_valid = '1' then
                        aes_key     <= std_logic_vector(trng_data(223 downto 96)); 
                        nonce_reg   <= std_logic_vector(trng_data(95 downto 0));
                        trng_enable <= '0'; 
                        block_cnt   <= 0;   
                        ctr_reg     <= (others => '0'); 
                        state       <= ST_START_AES;
                    end if;

                when ST_START_AES =>
                    aes_plaintext <= nonce_reg & std_logic_vector(ctr_reg);
                    aes_start     <= '0'; 
                    state         <= ST_WAIT_AES;

                when ST_WAIT_AES =>
                    aes_start <= '1';
                    if aes_done = '1' then
                        ctr_reg   <= ctr_reg + 1;

                        -- Check if 1 second has expired
                        if send_metrics_pending = '1' then
                            byte_cnt <= 0;
                            state    <= ST_LOAD_UART;
                        elsif block_cnt = (N_OUTPUT - 1) then
                            trng_enable <= '1';
                            state       <= ST_WAIT_TRNG;
                        else
                            block_cnt <= block_cnt + 1;
                            state     <= ST_START_AES;
                        end if;
                    end if;

                when ST_LOAD_UART =>
                    -- Slice 8 bits out of the 32-bit captured rate snapshot
                    uart_tx_data  <= tx_count_data(31 - (byte_cnt * 8) downto 24 - (byte_cnt * 8));
                    uart_tx_start <= '1';
                    state         <= ST_WAIT_UART;

                when ST_WAIT_UART =>
                    if uart_tx_done = '1' then
                        if byte_cnt = 3 then
                            -- Sent all 4 frames successfully
                            clear_metrics_flag <= '1'; -- Safely clear the pending request flag
                            
                            if block_cnt = (N_OUTPUT - 1) then
                                trng_enable <= '1';
                                state       <= ST_WAIT_TRNG;
                            else
                                state       <= ST_START_AES;
                            end if;
                        else
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