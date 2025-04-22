library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

use work.recop_types.all;


entity xmem_decoder is 
    port (
        addr: in bit_16;
        xmem_write: in bit_1;

        hex_a_write: out bit_1;
        hex_b_en_write: out bit_1;
        led_write: out bit_1
    );
end xmem_decoder;

architecture beh of xmem_decoder is begin



end beh;
