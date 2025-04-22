library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

use work.recop_types.all;


entity seven_segment_decoder is 
    port (
        nibble: in bit_4;
        seven_segment: out bit_7
    );
end seven_segment_decoder;

architecture beh of seven_segment_decoder is begin

    seven_segment <=    "1000000" when nibble = "0000" else
                        "1111001" when nibble = "0001" else
                        "0100100" when nibble = "0010" else
                        "0110000" when nibble = "0011" else
                        "0011001" when nibble = "0100" else
                        "0010010" when nibble = "0101" else
                        "0000010" when nibble = "0110" else
                        "1111000" when nibble = "0111" else
                        "0000000" when nibble = "1000" else
                        "0010000" when nibble = "1001" else
                        "0001000" when nibble = "1010" else
                        "0000011" when nibble = "1011" else
                        "1000110" when nibble = "1100" else
                        "0100001" when nibble = "1101" else
                        "0000110" when nibble = "1110" else
                        "0001110" when nibble = "1111" else
                        "0111111";
end beh;
