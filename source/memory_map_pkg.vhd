-- Zoran Salcic

library ieee;
use ieee.std_logic_1164.all;
use work.recop_types.all;

package memory_map_pkg is
    
    --4096 words of data memory
    constant dm_addr_start: bit_16 := x"0000";
    constant dm_addr_end: bit_16 := x"0FFF";

    constant hex_a_addr: bit_16 := x"4000";
    constant hex_b_addr: bit_16 := x"4001";
    constant led_addr: bit_16 := x"4100";

    constant switch_addr: bit_16 := x"4200";
    constant button_addr: bit_16 := x"4300";
	 
	 constant adc_base_addr : bit_16 := x"A000";


end memory_map_pkg;	
