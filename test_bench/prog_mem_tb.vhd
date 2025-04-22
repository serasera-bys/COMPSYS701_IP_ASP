library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.recop_types.all;

entity prog_mem_tb is 
end entity prog_mem_tb;

architecture tb of prog_mem_tb is
    constant clk_period : time := 10 ns;

    signal clk: bit_1 := '0';
    signal addr: bit_15 := "000000000000000";
    signal q: bit_32;
begin
    
    clk <= not clk after clk_period/2;

    memory: entity work.prog_mem
    port map(
        clock => clk,
        address => addr,
        q => q
    );
    
    stimuli: process begin
        wait for 2*clk_period;
        addr <= std_logic_vector(unsigned(addr) + 1);
        wait for clk_period;
        addr <= std_logic_vector(unsigned(addr) + 1);

        if addr(3 downto 0) = x"F" then
            wait;
        end if;
    end process stimuli;

end tb;
