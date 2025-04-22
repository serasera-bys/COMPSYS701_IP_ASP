
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.recop_types.all;
use work.memory_map.all;
use work.various_constants.all;
use work.opcodes.all;

entity recop is
    port (
        clk   : in bit_1;
        reset : in bit_1;

        dpcr: out bit_32;
        sop: out bit_16;
        sip: in bit_16;

        xmem_addr: out bit_16;
        xmem_out: in bit_16;
        xmem_in: out bit_16;
        xmem_write: out bit_1;
		  
		  ADC_DATA  : in std_logic_vector(31 downto 0);
		  ADC_VALID : in std_logic

    );
end recop;

architecture structural of recop is

    -- Sinyal penghubung antar modul
    signal mem_in, mem_out, dm_out, mem_addr, pm_addr : bit_16;
    signal pm_out : bit_32;
    signal pc_sel, dm_addr_sel, dm_in_sel : bit_2;
    signal rf_input_sel : bit_3;
    signal alu_op1_sel, alu_op2_sel : bit_1;
    signal alu_operation : bit_3;
    signal dpcr_sel : bit_1;
    signal pc_write, ir_write, sop_write, rf_write, mem_write, dm_write, dpcr_write, clr_z_flag : bit_1;
    signal z_flag : bit_1;
    signal rz_zero : bit_1;
    signal addressing_mode : bit_2;
    signal opcode : bit_6;

begin
	
    datapath : entity work.datapath
    port map (
        clk => clk,
        reset => reset,
		  
        pm_out => pm_out,
        pm_addr => pm_addr,
		  
        dm_out => mem_out,
        dm_in => mem_in,
        dm_addr => mem_addr,
		  
		  sip => sip,
		  sop => sop,
		  dpcr => dpcr,
		  
        pc_sel => pc_sel,
        pc_write => pc_write,
        ir_write => ir_write,
        sop_write => sop_write,
        dpcr_write => dpcr_write,
        rf_write => rf_write,
        rf_input_sel => rf_input_sel,
        dm_in_sel => dm_in_sel,
        dm_addr_sel => dm_addr_sel,
        alu_op1_sel => alu_op1_sel,
        alu_op2_sel => alu_op2_sel,
        alu_operation => alu_operation,
        clr_z_flag => clr_z_flag,
        z_flag => z_flag,
        rz_zero => rz_zero,
        addressing_mode => addressing_mode,
        opcode => opcode,
        dpcr_sel => dpcr_sel,
		  ADC_DATA => ADC_DATA,
		  ADC_VALID => ADC_VALID
    );


    controlunit : entity work.control_unit
    port map (
        clk => clk,
        reset => reset,
        z_flag => z_flag,
        rz_zero => rz_zero,
        opcode => opcode,
        addressing_mode => addressing_mode,
        pc_sel => pc_sel,
        pc_write => pc_write,
        ir_write => ir_write,
        sop_write => sop_write,
        rf_write => rf_write,
        dm_write => mem_write,
        dpcr_write => dpcr_write,
        dpcr_sel => dpcr_sel,
        clr_z_flag => clr_z_flag,
        alu_op1_sel => alu_op1_sel,
        alu_op2_sel => alu_op2_sel,
        rf_input_sel => rf_input_sel,
        dm_addr_sel => dm_addr_sel,
        dm_in_sel => dm_in_sel,
        alu_operation => alu_operation
    );
	 
         --xmem/dm interface
         xmem_addr <= mem_addr;
         xmem_in <= mem_in;
         mem_process: process (mem_addr, mem_write, dm_out, xmem_out) begin
            case to_integer(unsigned(mem_addr)) is
                when to_integer(unsigned(dm_addr_start)) to to_integer(unsigned(dm_addr_end)) =>
                    mem_out <= dm_out;
                    dm_write <= mem_write;
                    xmem_write <= '0';
                when others =>
                    mem_out <= xmem_out;
                    xmem_write <= mem_write;
                    dm_write <= '0';
            end case;
        end process mem_process;
        
	 data_memory: entity work.data_mem
	 port map (
		clock => clk,
		address => mem_addr(11 downto 0),
		data	=> mem_in,
		wren => dm_write,
		q => dm_out
	);
	
	program_memory: entity work.prog_mem
	port map (
		clock => clk,
                clken => pc_write,
		address => pm_addr(14 downto 0),
		q => pm_out
	);
	
end structural;
