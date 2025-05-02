library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.recop_types.all;

entity tb_noctop is
end entity;

architecture sim of tb_noctop is
  signal clk         : std_logic := '0';
  signal reset       : std_logic := '1';
  signal sip_valid   : std_logic := '0';
  signal sip_data    : std_logic_vector(31 downto 0) := (others => '0');
  signal sip_write   : std_logic;
  signal dpcr_out    : std_logic_vector(31 downto 0);
  signal dpcr_valid  : std_logic;
  signal ADC_DATA    : std_logic_vector(31 downto 0) := x"00000010";
  signal ADC_VALID   : std_logic := '0';
  signal xmem_addr   : bit_16;
  signal xmem_in     : bit_16;
  signal xmem_out    : bit_16 := (others=>'0');
  signal xmem_write  : bit_1;

  -- stimulus
  function avg_8(v: integer) return std_logic_vector is
    variable s: integer := 0;
  begin
    for i in 0 to 7 loop s := s + v; end loop;
    return std_logic_vector(to_unsigned(s/8,32));
  end function;

  constant W : integer := 16;
  signal expected : std_logic_vector(31 downto 0);
begin
  -- DUT instantiation
  DUT: entity work.recop
    port map(
      clk        => clk,
      reset      => reset,
      sip_valid  => sip_valid,
      sip_data   => sip_data,
      sip_write  => sip_write,
      dpcr_out   => dpcr_out,
      dpcr_valid => dpcr_valid,
      ADC_DATA   => ADC_DATA,
      ADC_VALID  => ADC_VALID,
      xmem_addr  => xmem_addr,
      xmem_in    => xmem_in,
      xmem_out   => xmem_out,
      xmem_write => xmem_write
    );

  -- clock
  clk_proc: process
  begin
    wait for 5 ns; clk <= not clk;
  end process;

  -- stimulus
  stim: process
  begin
    -- reset
    reset <= '1'; wait for 20 ns;
    reset <= '0'; wait for 20 ns;

    -- kirim window = 8
    sip_data  <= x"00000008";
    sip_valid <= '1'; wait for 10 ns;
    sip_valid <= '0';

    expected <= avg_8(W);

    -- ADC sampling
    for i in 0 to 7 loop
      ADC_DATA  <= std_logic_vector(to_unsigned(W,32));
      ADC_VALID <= '1'; wait for 10 ns;
      ADC_VALID <= '0'; wait for 10 ns;
    end loop;

    -- tunggu hasil average
	assert dpcr_out = expected
	  report "AVERAGE MISMATCH: got " &
				integer'image(to_integer(unsigned(dpcr_out)))
      severity failure;
    report "AVERAGE OK: " &
       integer'image(to_integer(unsigned(dpcr_out)))
	severity note;

    wait;
  end process;

end architecture;
