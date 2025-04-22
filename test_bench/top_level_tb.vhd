library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.recop_types.all;

entity top_level_tb is 
end entity top_level_tb;

architecture tb of top_level_tb is
    constant clk_period : time := 10 ns;

    signal clk: bit_1 := '0';
    signal reset : bit_1; 

    signal switch, leds: bit_10;
    signal buttons: bit_4;
begin
    
    clk <= not clk after clk_period/2;

    recop: entity work.top_level
    port map(
        CLOCK_50 => clk,
        KEY => buttons,
        SW => switch,
        LEDR => leds
    );

    buttons(0) <= not reset;
    buttons(3 downto 1) <= (others => '0');
    
    stimuli: process begin
        switch <= "0000000000";
        reset <= '1';
        wait for clk_period;
        reset <= '0';

        wait for 30*clk_period;
        switch <= "1111100000";
        wait for 20*clk_period;
        switch <= "0000011111";
        wait for 20*clk_period;
        switch <= "1010101010";
        wait for 20*clk_period;
        switch <= "0101010101";
        wait;

    end process stimuli;
end tb;
