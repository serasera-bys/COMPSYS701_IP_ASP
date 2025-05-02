library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.recop_types.all;       -- your bit_1, bit_2, etc.
use work.various_constants.all; -- your mux‐select constants
use work.opcodes.all;           -- your opcode enums

entity datapath is
  port(
    clk           : in  bit_1;
    reset         : in  bit_1;

    -- program memory interface
    pm_out        : in  bit_32;
    pm_addr       : out bit_16;

    -- data‐memory interface
    dm_out        : in  bit_16;
    dm_in         : out bit_16;
    dm_addr       : out bit_16;

    -- register file / ALU control
    pc_sel        : in  bit_2;
    pc_write      : in  bit_1;
    ir_write      : in  bit_1;
    rf_write      : in  bit_1;
    dm_addr_sel   : in  bit_2;
    dm_in_sel     : in  bit_2;
    rf_input_sel  : in  bit_3;
    alu_op1_sel   : in  bit_1;
    alu_op2_sel   : in  bit_1;
    alu_operation : in  bit_3;
    clr_z_flag    : in  bit_1;
    sop_write     : in  bit_1;

    -- DPCR/DPRR (NoC) interface
    dpcr_we       : in  bit_1;                            -- write‐enable DPCR
    dpcr_sel      : in  bit_1;                            -- choose R7 vs operand
    dprr_in       : in  std_logic_vector(31 downto 0);    -- NoC→DPRR data
    dprr_valid    : in  std_logic;                        -- NoC→DPRR valid

    -- status back to CU
    z_flag        : out bit_1;
    rz_zero       : out bit_1;
    addressing_mode : out bit_2;
    opcode        : out bit_6;

    -- DPCR output
    dpcr_out      : out std_logic_vector(31 downto 0);
    dpcr_valid    : out std_logic;

    -- SSOP (optional NoC send small)
    SOP           : out std_logic_vector(15 downto 0)
  );
end entity;

architecture combined of datapath is
  -- IR
  signal ir        : bit_32;
  signal rz_sel    : bit_4;
  signal rx_sel    : bit_4;
  signal ir_operand: bit_16;

  -- PC
  signal pc, pc_next : bit_16;

  -- RF/ALU
  signal rx, rz, r7   : bit_16;
  signal alu_out      : bit_16;

  -- DPRR staging
  signal dprr_data     : std_logic_vector(31 downto 0);
  signal dprr_valid_i  : std_logic;

  -- DPCR staging
  signal dpcr_data_i   : std_logic_vector(31 downto 0);
  signal dpcr_we_i     : std_logic;

begin
  ----------------------------------------------------------------
  -- Program Counter
  pc_next <= std_logic_vector(unsigned(pc) + 1)
               when pc_sel = pc_sel_next    else
             rx                              when pc_sel = pc_sel_rx  else
             ir_operand                     when pc_sel = pc_sel_operand else
             (others => '0');

  process(clk, reset)
  begin
    if reset = '1' then
      pc <= (others => '0');
    elsif rising_edge(clk) and pc_write = '1' then
      pc <= pc_next;
    end if;
  end process;
  pm_addr <= pc_next;

  ----------------------------------------------------------------
  -- Instruction Register
  process(clk, reset)
  begin
    if reset = '1' then
      ir <= (others => '0');
    elsif rising_edge(clk) and ir_write = '1' then
      ir <= pm_out;
    end if;
  end process;
  addressing_mode <= ir(31 downto 30);
  opcode          <= ir(29 downto 24);
  rz_sel          <= ir(23 downto 20);
  rx_sel          <= ir(19 downto 16);
  ir_operand      <= ir(15 downto 0);

  ----------------------------------------------------------------
  -- Register File
  regfile_inst: entity work.regfile
    port map(
      clk          => clk,
      init         => reset,
      ld_r         => rf_write,
      sel_z        => to_integer(unsigned(rz_sel)),
      sel_x        => to_integer(unsigned(rx_sel)),
      rx           => rx,
      rz           => rz,
		rz_max       => (others => '0'), 
      rf_input_sel => rf_input_sel,
      ir_operand   => ir_operand,
      dm_out       => dm_out,
      aluout       => alu_out,
      sip_hold     => dprr_data(31 downto 0),
      er_temp      => '0',
      r7           => r7,
      dprr_res     => '0',
      dprr_res_reg => '0',
      dprr_wren    => '0'
    );

  ----------------------------------------------------------------
  -- ALU
  alu_inst: entity work.alu
    port map(
      clk          => clk,
      reset        => reset,
      z_flag       => z_flag,
      alu_operation=> alu_operation,
      alu_op1_sel  => alu_op1_sel,
      alu_op2_sel  => alu_op2_sel,
      alu_carry    => '1',
      alu_result   => alu_out,
      rx           => rx,
      rz           => rz,
      ir_operand   => ir_operand,
      clr_z_flag   => clr_z_flag
    );

  ----------------------------------------------------------------
  -- Data‐Memory Mux
  dm_addr <= rx                when dm_addr_sel = dm_addr_sel_rx       else
            rz                when dm_addr_sel = dm_addr_sel_rz       else
            ir_operand        when dm_addr_sel = dm_addr_sel_operand else
            (others => '0');
  dm_in   <= rx                when dm_in_sel   = dm_in_sel_rx         else
            ir_operand        when dm_in_sel   = dm_in_sel_operand   else
            pc                when dm_in_sel   = dm_in_sel_pc        else
            (others => '0');

  ----------------------------------------------------------------
  -- SSOP (small send)
  process(clk, reset)
  begin
    if reset = '1' then
      SOP <= (others => '0');
    elsif rising_edge(clk) and sop_write = '1' then
      SOP <= rx;
    end if;
  end process;

  ----------------------------------------------------------------
  -- DPRR (NoC→DPRR)
	process(clk, reset)
	begin
	  if reset = '1' then
		 dprr_data  <= (others => '0');
		 dprr_valid_i <= '0';
	  elsif rising_edge(clk) then
		 if dprr_valid = '1' then
			dprr_data     <= dprr_in;
			dprr_valid_i  <= '1';
		 else
			dprr_valid_i  <= '0';
		 end if;
	  end if;
	end process;


  ----------------------------------------------------------------
  -- DPCR (DATACALL)
	process(clk, reset)
	begin
	  if reset = '1' then
		 dpcr_data_i <= (others => '0');
		 dpcr_we_i   <= '0';
	  elsif rising_edge(clk) then
		 if dpcr_we = '1' then
			-- bottom 16 bits from RZ or immediate
			if dpcr_sel = dpcr_sel_r7 then
			  dpcr_data_i(15 downto 0) <= rz;
			else
			  dpcr_data_i(15 downto 0) <= std_logic_vector(ir_operand);
			end if;
			-- top 16 bits from RX
			dpcr_data_i(31 downto 16) <= rx;
			dpcr_we_i                <= '1';
		 else
			dpcr_we_i <= '0';
		 end if;
	  end if;
	end process;

	dpcr_out   <= dpcr_data_i;
	dpcr_valid <= dpcr_we_i;
  ----------------------------------------------------------------
  -- Flags back to CU
  ----------------------------------------------------------------
  rz_zero <= '1' when rz = x"0000" else '0';
  -- z_flag is driven by ALU directly

end architecture combined;
