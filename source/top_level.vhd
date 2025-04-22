-- Updated top_level.vhd with alu_op2_sel as bit_1 and all port mappings completed

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.recop_types.all;
use work.memory_map.all;

entity top_level is
    port (
        CLOCK_50   : in bit_1;
		  reset      : in bit_1;
		  
		  adc_data : in std_logic_vector(31 downto 0); -- data dari NoC
        adc_valid: in std_logic;                     -- validasi data dari NoC
		  
		  LEDR : out bit_10;
		  HEX0 : out bit_7;
		  HEX1 : out bit_7;
		  HEX2 : out bit_7;
		  HEX3 : out bit_7;
		  HEX4 : out bit_7;
		  HEX5 : out bit_7;
		  
		  KEY : in bit_4;
		  SW : in bit_10
    );
end top_level;

architecture structural of top_level is
    --signal clk, reset: bit_1;
	 signal clk_internal : bit_1;
	 signal reset_internal : bit_1;
    signal xmem_addr, xmem_out, xmem_in: bit_16;
    signal xmem_write: bit_1;

    signal hex_a, hex_b, led: bit_16;
    signal switch, button: bit_16;
begin

    clk_internal <= CLOCK_50;
	 reset_internal <= reset; --not KEY(0)

    recop: entity work.recop
    port map(
        clk => clk_internal,
        reset => reset_internal,

        sip => (others => '0'),

        xmem_addr => xmem_addr,
        xmem_out => xmem_out,
        xmem_in => xmem_in,
        xmem_write => xmem_write,
		  ADC_DATA   => adc_data,
		  ADC_VALID  => adc_valid
    );

    w_peripherals: process (clk_internal, reset_internal) begin
        if reset_internal = '1' then
            hex_a <= (others => '0');
            hex_b <= (others => '0');
            led  <= (others => '0');
        elsif rising_edge(clk_internal) and xmem_write = '1' then
            case xmem_addr is
                when hex_a_addr =>
                    hex_a <= xmem_in;
                when hex_b_addr =>
                    hex_b <= xmem_in;
                when led_addr =>
                    led <= xmem_in;
                when others => null;
            end case;
        end if;
    end process w_peripherals;

    --xmem output mux
    switch(9 downto 0) <= SW;
    switch(15 downto 10) <= (others => '0');
    button(3 downto 0) <= KEY;
    button(15 downto 4) <= (others => '0');
    
    xmem_out <= hex_a when xmem_addr = hex_a_addr else
                hex_b when xmem_addr = hex_b_addr else
                led when xmem_addr = led_addr else
                switch when xmem_addr = switch_addr else
                button when xmem_addr = button_addr else
                (others => '0');


    --hex seven segment decoders
    hex_a0_decoder : entity work.seven_segment_decoder
    port map(
        nibble => hex_a(3 downto 0),
        seven_segment => HEX0
    );
    hex_a1_decoder : entity work.seven_segment_decoder
    port map(
        nibble => hex_a(7 downto 4),
        seven_segment => HEX1
    );
    hex_a2_decoder : entity work.seven_segment_decoder
    port map(
        nibble => hex_a(11 downto 8),
        seven_segment => HEX2
    );
    hex_a3_decoder : entity work.seven_segment_decoder
    port map(
        nibble => hex_a(15 downto 12),
        seven_segment => HEX3
    );

    hex_b0_decoder : entity work.seven_segment_decoder
    port map(
        nibble => hex_b(3 downto 0),
        seven_segment => HEX4
    );
    hex_b1_decoder : entity work.seven_segment_decoder
    port map(
        nibble => hex_b(7 downto 4),
        seven_segment => HEX5
    );

    --LED
    LEDR <= led(9 downto 0);

end structural;
