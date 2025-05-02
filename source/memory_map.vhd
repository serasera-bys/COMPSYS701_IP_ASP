-- memory_map.vhd
library ieee; 
use ieee.std_logic_1164.all; 
use ieee.numeric_std.all;
use work.memory_map_pkg.all;
use work.recop_types.all;

entity memory_map is
  port(
    uaddress : in  bit_16;
    wren     : in  std_logic;
    din      : in  bit_16;
    dout     : out bit_16;
    xaddress : out bit_16;
    xwren    : out std_logic;
    xdin     : out bit_16;
    xdout    : in  bit_16
  );
end entity;

architecture rtl of memory_map is
begin
  process(uaddress, wren, din, xdout)
  begin
    if unsigned(uaddress) >= unsigned(dm_addr_start) and
       unsigned(uaddress) <= unsigned(dm_addr_end) then
      dout      <= din;        -- on-chip RAM
      xwren     <= '0';
    else
      dout      <= xdout;      -- external I/O
      xwren     <= wren;
    end if;
    xaddress <= uaddress;
    xdin     <= din;
  end process;
end architecture;
