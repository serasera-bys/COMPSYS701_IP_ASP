library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.recop_types.all;

entity recop_tb is 
end entity recop_tb;

architecture tb of recop_tb is
    constant clk_period : time := 10 ns;

    signal clk: bit_1 := '0';
    signal reset : bit_1; 
begin
    
    clk <= not clk after clk_period/2;

    recop: entity work.recop
    port map(
        clk => clk,
        reset => reset,
        xmem_out => (others => '0'),
        sip => (others => '0')
    );
    
    stimuli: process begin
        reset <= '1';
        wait for clk_period;
        reset <= '0';
        wait;
    end process stimuli;
end tb;
