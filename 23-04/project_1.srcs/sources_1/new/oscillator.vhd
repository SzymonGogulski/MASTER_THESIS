library ieee; 
use ieee.std_logic_1164.all; 

entity oscillator is 
    port ( 
        ro_out : out std_ulogic
    ); 
end entity oscillator; 

architecture rtl of oscillator is 
    signal s1, s2, s3 : std_ulogic := '0';
begin
    s1 <= not s3;
    s2 <= not s1;
    s3 <= not s2;

    ro_out <= s3;
end architecture rtl;