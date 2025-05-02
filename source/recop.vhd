library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.recop_types.all;       -- bit_1, bit_2, …
use work.various_constants.all; -- pc_sel_*, …
use work.opcodes.all;           -- instr enums
use work.memory_map_pkg.all;


entity recop is
  port (
    clk        : in  bit_1;
    reset      : in  bit_1;

    -- NoC/SIP command interface
    sip_valid  : in  std_logic;
    sip_data   : in  std_logic_vector(31 downto 0);
    sip_write  : out std_logic;

    -- NoC/DPCR response interface
    dpcr_out   : out std_logic_vector(31 downto 0);
    dpcr_valid : out std_logic;

    -- ADC stream
    ADC_DATA   : in  std_logic_vector(31 downto 0);
    ADC_VALID  : in  std_logic;

    -- external board I/O
    xmem_addr  : out bit_16;
    xmem_in    : out bit_16;
    xmem_out   : in  bit_16;
    xmem_write : out bit_1
  );
end entity;

architecture structural of recop is

  -- ASP FSM state & regs
  type asp_state is (IDLE,RUN,SEND);
  signal state       : asp_state := IDLE;
  signal limit_reg   : std_logic_vector(15 downto 0);
  signal average_reg : std_logic_vector(31 downto 0);
  signal reset_cpu   : std_logic := '0';

  -- Interconnect to prog_mem / datapath / memory_map / CU
  signal pm_addr       : bit_16;
  signal pm_out        : bit_32;
  signal mem_addr      : bit_16;
  signal mem_in,mem_out: bit_16;
  signal dm_write      : std_logic;

  signal pc_sel        : bit_2;
  signal pc_write      : bit_1;
  signal ir_write      : bit_1;
  signal sop_write     : bit_1;
  signal dpcr_we       : bit_1;
  signal dpcr_sel      : bit_1;
  signal rf_write      : bit_1;
  signal dm_addr_sel   : bit_2;
  signal dm_in_sel     : bit_2;
  signal rf_input_sel  : bit_3;
  signal alu_operation : bit_3;
  signal alu_op1_sel   : bit_1;
  signal alu_op2_sel   : bit_1;
  signal clr_z_flag    : bit_1;

  --signal dpcr_we : bit_1;
  --signal dm_write   : bit_1;
  
  signal z_flag        : bit_1;
  signal rz_zero       : bit_1;
  signal addressing_mode : bit_2;
  signal opcode         : bit_6;

  -- DPRR / DPCR staging
  signal dprr_data_i   : std_logic_vector(31 downto 0);
  signal dprr_valid_i  : std_logic;
  signal dpcr_out_i    : std_logic_vector(31 downto 0);
  signal dpcr_valid_i  : std_logic;

begin
  ----------------------------------------------------------------------------
  -- 1) Program Memory (Quartus QIP ROM)
  ----------------------------------------------------------------------------
  u_prog_mem : entity work.prog_mem
    port map(
      clock   => clk,
      clken   => pc_write, --1,            -- from CU
      address => pm_addr(14 downto 0),
      q       => pm_out
    );

  ----------------------------------------------------------------------------
  -- 2) Control Unit
  ----------------------------------------------------------------------------
  u_cu: entity work.control_unit
    port map(
      clk             => clk,
      reset           => reset or reset_cpu,
      z_flag          => z_flag,
      rz_zero         => rz_zero,
		
      addressing_mode => addressing_mode,
      opcode          => opcode,
      pc_sel          => pc_sel,
      pc_write        => pc_write,
      ir_write        => ir_write,
      sop_write       => sop_write,
		
      dpcr_we         => dpcr_we,
		
      dpcr_sel        => dpcr_sel,
		
      dm_write        => dm_write,
		
      rf_write        => rf_write,
      dm_addr_sel     => dm_addr_sel,
      dm_in_sel       => dm_in_sel,
      rf_input_sel    => rf_input_sel,
      alu_operation   => alu_operation,
      alu_op1_sel     => alu_op1_sel,
      alu_op2_sel     => alu_op2_sel,
      clr_z_flag      => clr_z_flag
    );

  ----------------------------------------------------------------------------
  -- 3) Datapath
  ----------------------------------------------------------------------------
  u_dp: entity work.datapath
    port map(
      clk            => clk,
      reset          => reset or reset_cpu,
      pm_out         => pm_out,
      pm_addr        => pm_addr,
      dm_out         => mem_out,
      dm_in          => mem_in,
      dm_addr        => mem_addr,
      pc_sel         => pc_sel,
      pc_write       => pc_write,
      ir_write       => ir_write,
      rf_write       => rf_write,
      dm_addr_sel    => dm_addr_sel,
      dm_in_sel      => dm_in_sel,
      rf_input_sel   => rf_input_sel,
      alu_operation  => alu_operation,
      alu_op1_sel    => alu_op1_sel,
      alu_op2_sel    => alu_op2_sel,
      clr_z_flag     => clr_z_flag,
		
      sop_write      => sop_write,
      dpcr_we        => dpcr_we,
      dpcr_sel       => dpcr_sel,
      dprr_in        => sip_data,
      dprr_valid     => sip_valid,
		
      z_flag         => z_flag,
      rz_zero        => rz_zero,
      addressing_mode=> addressing_mode,
      opcode         => opcode,
      dpcr_out       => open,
      dpcr_valid     => open,
      SOP            => open
    );

  ----------------------------------------------------------------------------
  -- 4) On-chip vs external memory
  ----------------------------------------------------------------------------
	u_memmap: entity work.memory_map
	  port map(
		 uaddress => mem_addr,
		 wren     => dm_write,
		 din      => mem_in,
		 dout     => mem_out,
		 xaddress => xmem_addr,
		 xwren    => xmem_write,
		 xdin     => xmem_in,
		 xdout    => xmem_out
	  );

  ----------------------------------------------------------------------------
  -- 5) Capture DPRR from NoC
  ----------------------------------------------------------------------------
  process(clk)
  begin
    if rising_edge(clk) then
      if sip_valid = '1' then
        dprr_data_i   <= sip_data;
        dprr_valid_i  <= '1';
        sip_write     <= '1';
      else
        dprr_valid_i  <= '0';
        sip_write     <= '0';
      end if;
    end if;
  end process;

  ----------------------------------------------------------------------------
  -- 6) ASP loop (average + send via DPCR)
  ----------------------------------------------------------------------------
  ASP_FSM: process(clk)
  begin
    if rising_edge(clk) then
      dpcr_out   <= (others=>'0');
      dpcr_valid <= '0';
      reset_cpu  <= '0';
      case state is
        when IDLE =>
          if dprr_valid_i = '1' then
            limit_reg <= dprr_data_i(15 downto 0);
            reset_cpu <= '1';
            state     <= RUN;
          end if;
        when RUN =>
          if dm_write = '1' and mem_addr = x"4000" then
            average_reg <= std_logic_vector(
                 to_unsigned(
                   to_integer(unsigned(mem_out)),
                   32
                 )
               );
            state       <= SEND;
          end if;
        when SEND =>
          dpcr_out   <= average_reg;
          dpcr_valid <= '1';
          state      <= IDLE;
      end case;
    end if;
  end process ASP_FSM;

end architecture;
