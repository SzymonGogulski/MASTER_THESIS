library ieee;
use ieee.std_logic_1164.all;

entity top1 is
    port (
        ro_out : out std_ulogic
    );
end entity top1;

architecture rtl of top1 is
begin

    u_osc : entity work.oscillator
        port map (
            ro_out => ro_out
        );

end architecture rtl;