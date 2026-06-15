library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity simple_uart_tx is
    generic (
        BAUD_DIV : integer := 135 -- Default value (e.g., 125,000,000 / 921,600 ≈ 135.6)
    );
    port (
        clk      : in  std_logic;
        tx_start : in  std_logic;
        tx_data  : in  std_logic_vector(7 downto 0);
        tx_busy  : out std_logic;
        tx_done  : out std_logic;
        tx_out   : out std_logic
    );
end simple_uart_tx;

architecture Behavioral of simple_uart_tx is

    type state_type is (ST_IDLE, ST_START, ST_DATA, ST_STOP, ST_DONE);
    signal state : state_type := ST_IDLE;

    signal baud_cnt : integer range 0 to BAUD_DIV - 1 := 0;
    signal bit_cnt  : integer range 0 to 7 := 0;
    signal tx_reg   : std_logic_vector(7 downto 0) := (others => '0');

begin

    process(clk)
    begin
        if rising_edge(clk) then
            -- Default assignments
            tx_done <= '0';
            tx_busy <= '1'; -- Default to busy unless explicitly IDLE

            case state is

                when ST_IDLE =>
                    tx_out  <= '1'; -- UART line idles high
                    tx_busy <= '0';
                    baud_cnt <= 0;
                    bit_cnt  <= 0;
                    
                    if tx_start = '1' then
                        tx_reg  <= tx_data; -- Latch input data buffer
                        tx_busy <= '1';
                        state   <= ST_START;
                    end if;

                when ST_START =>
                    tx_out <= '0'; -- Start bit (pull low)
                    
                    if baud_cnt = BAUD_DIV - 1 then
                        baud_cnt <= 0;
                        state    <= ST_DATA;
                    else
                        baud_cnt <= baud_cnt + 1;
                    end if;

                when ST_DATA =>
                    tx_out <= tx_reg(bit_cnt); -- Send data LSB-first
                    
                    if baud_cnt = BAUD_DIV - 1 then
                        baud_cnt <= 0;
                        if bit_cnt = 7 then
                            state <= ST_STOP;
                        else
                            bit_cnt <= bit_cnt + 1;
                        end if;
                    else
                        baud_cnt <= baud_cnt + 1;
                    end if;

                when ST_STOP =>
                    tx_out <= '1'; -- Stop bit (pull high)
                    
                    if baud_cnt = BAUD_DIV - 1 then
                        baud_cnt <= 0;
                        state    <= ST_DONE;
                    else
                        baud_cnt <= baud_cnt + 1;
                    end if;

                when ST_DONE =>
                    tx_out  <= '1';
                    tx_done <= '1'; -- Strobe done signal for exactly one clock cycle
                    state   <= ST_IDLE;

                when others =>
                    state <= ST_IDLE;

            end case;
        end if;
    end process;

end Behavioral;