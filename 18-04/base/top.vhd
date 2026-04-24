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
    constant CLK_FREQ        : integer := 125_000_000;
    constant BAUD_DIV        : integer := CLK_FREQ / BAUD_RATE;
    constant WAIT_COUNT      : integer := CLK_FREQ / 10; -- 0.1s interval

    -- Component Declaration
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

    -- Internal Signals
    signal timer_cnt    : integer range 0 to WAIT_COUNT := 0;
    signal trng_en      : std_ulogic := '0';
    signal trng_valid   : std_ulogic;
    signal trng_data    : std_ulogic_vector(7 downto 0);
    
    -- UART Logic
    signal tx_reg       : std_logic := '1';
    signal uart_cnt     : integer range 0 to BAUD_DIV := 0;
    signal bit_idx      : integer range 0 to 9 := 0;
    signal tx_buffer    : std_ulogic_vector(7 downto 0) := (others => '0');
    
    -- State Machine
    type state_t is (IDLE, WAIT_TRNG, SEND_UART);
    signal state : state_t := IDLE;

begin

    tx <= tx_reg;

    -- Instantiate TRNG
    trng_inst : neoTRNG
        generic map (
            NUM_CELLS     => 3,
            NUM_INV_START => 5,
            NUM_RAW_BITS  => 64, -- Increased for better entropy quality
            SIM_MODE      => false
        )
        port map (
            clk_i    => clk,
            rstn_i   => '1', -- Tie high if no hardware reset button
            enable_i => trng_en,
            valid_o  => trng_valid,
            data_o   => trng_data
        );

    process(clk)
    begin
        if rising_edge(clk) then
            case state is

                -- Wait for the 0.1s timer to trigger
                when IDLE =>
                    tx_reg <= '1';
                    if timer_cnt < WAIT_COUNT - 1 then
                        timer_cnt <= timer_cnt + 1;
                    else
                        timer_cnt <= 0;
                        trng_en   <= '1'; -- Start the entropy gathering
                        state     <= WAIT_TRNG;
                    end if;

                -- Wait for TRNG to finish post-processing (De-biasing + CRC)
                when WAIT_TRNG =>
                    if trng_valid = '1' then
                        tx_buffer <= trng_data;
                        trng_en   <= '0'; -- Stop TRNG to save power/reduce noise
                        uart_cnt  <= 0;
                        bit_idx   <= 0;
                        state     <= SEND_UART;
                    end if;

                -- Standard UART Transmission
                when SEND_UART =>
                    if uart_cnt < BAUD_DIV - 1 then
                        uart_cnt <= uart_cnt + 1;
                    else
                        uart_cnt <= 0;
                        case bit_idx is
                            when 0 => tx_reg <= '0'; -- Start
                            when 1 to 8 => tx_reg <= std_logic(tx_buffer(bit_idx-1));
                            when 9 => tx_reg <= '1'; -- Stop
                            when others => null;
                        end case;

                        if bit_idx < 9 then
                            bit_idx <= bit_idx + 1;
                        else
                            state <= IDLE; -- Go back to timer
                        end if;
                    end if;

                when others => state <= IDLE;
            end case;
        end if;
    end process;

end Behavioral;