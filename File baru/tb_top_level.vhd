library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_top_level is
end entity;

architecture sim of tb_top_level is

    signal clk         : std_logic := '0';
    signal reset       : std_logic := '1';
    signal adc_data    : std_logic_vector(31 downto 0) := (others => '0');
    signal adc_valid   : std_logic := '0';
	 signal LEDR : std_logic_vector(9 downto 0);
	 signal HEX0, HEX1, HEX2, HEX3, HEX4, HEX5 : std_logic_vector(6 downto 0);
	 signal SW   : std_logic_vector(9 downto 0) := (others => '0');
	 signal KEY  : std_logic_vector(3 downto 0) := (others => '0');

    -- Add other signals if needed for observing results (e.g., LED output)

	component top_level
		 port (
       CLOCK_50  : in std_logic;
        reset     : in std_logic;
        adc_data  : in std_logic_vector(31 downto 0);
        adc_valid : in std_logic;
        LEDR      : out std_logic_vector(9 downto 0);
        HEX0      : out std_logic_vector(6 downto 0);
        HEX1      : out std_logic_vector(6 downto 0);
        HEX2      : out std_logic_vector(6 downto 0);
        HEX3      : out std_logic_vector(6 downto 0);
        HEX4      : out std_logic_vector(6 downto 0);
        HEX5      : out std_logic_vector(6 downto 0);
        KEY       : in std_logic_vector(3 downto 0);
        SW        : in std_logic_vector(9 downto 0)
		 );
	end component;


begin

    -- DUT instantiation
    uut: top_level
        port map (
            CLOCK_50      => clk,
            reset     => reset,
            adc_data  => adc_data,
            adc_valid => adc_valid,
				LEDR      => LEDR,
            HEX0      => HEX0,
            HEX1      => HEX1,
            HEX2      => HEX2,
            HEX3      => HEX3,
            HEX4      => HEX4,
            HEX5      => HEX5,
            KEY       => KEY,
            SW        => SW
        );

    -- Clock generation
    clk_process :process
    begin
        while true loop
            clk <= '0';
            wait for 10 ns;
            clk <= '1';
            wait for 10 ns;
        end loop;
    end process;

    -- Stimulus process
-- Stimulus process
stim_proc: process
begin
    -- Step 1: reset asserted
    reset <= '1';
    wait for 40 ns;

    -- Step 2: release reset
    reset <= '0';
    wait for 20 ns;

    -- Step 3: simulate 8 ADC samples
    for i in 0 to 7 loop
        adc_valid <= '1';
        adc_data <= std_logic_vector(to_unsigned(16#0010# * (i + 1), 32));
        wait for 20 ns;
    end loop;

    adc_valid <= '0';
    wait;
end process;


end architecture;