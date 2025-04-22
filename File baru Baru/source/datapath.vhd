library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.recop_types.all;
use work.various_constants.all;

entity datapath is
	port (
		clk: in bit_1;
		reset: in bit_1;

                -- Program memory
                pm_out: in bit_32;
                pm_addr: out bit_16;

                -- Data memory
                dm_out: in bit_16;
                dm_in: out bit_16;
                dm_addr: out bit_16;
					 
					 --External interface:
					 sip: in bit_16;
					 sop: out bit_16;
					 dpcr: out bit_32;
		
                -- Signals from control unit
                pc_sel: in bit_2;
                pc_write, ir_write, sop_write, dpcr_write, rf_write: in bit_1;
                dm_addr_sel, dm_in_sel: in bit_2;
                rf_input_sel: in bit_3;
                alu_operation: in bit_3;
                alu_op1_sel: in bit_1;
                alu_op2_sel: in bit_1;
                dpcr_sel: in bit_1;
                clr_z_flag: in bit_1;

                -- Signals to control unit
                z_flag: out bit_1;
                rz_zero: out bit_1;
                addressing_mode: out bit_2;
                opcode: out bit_6;
					 
					 -- NoC input from ADC
					 ADC_DATA  : in std_logic_vector(31 downto 0);
					 ADC_VALID : in std_logic

		);
end datapath;

architecture combined of datapath is
	signal ir: bit_32;
        signal rz_select: bit_4;
        signal rx_select: bit_4;
        signal ir_operand: bit_16;

        signal pc, pc_next: bit_16;

        signal rx, rz, r7: bit_16;
        signal alu_out: bit_16;
		  signal reg_adc : std_logic_vector(31 downto 0);

        
begin
        
        --Program Counter
        --the actual program counter is the address input register of the program memory.
        --this design contains a separate pc to mirror the contents of the program memory address register.

        pc_next <= std_logic_vector(unsigned(pc) + 1) when pc_sel = pc_sel_next else
                    rx when pc_sel = pc_sel_rx else
                    ir_operand when pc_sel = pc_sel_operand else
                    (others => '0'); --including pc_sel_reset

        pc_process: process (clk, reset) begin
            if(reset = '1') then 
                pc <= (others => '0');
            elsif(rising_edge(clk) and pc_write = '1') then 
                pc <= pc_next;
            end if;
        end process pc_process;

        pm_addr <= pc_next;

        --Instruction Register
        ir_process: process (clk, reset) begin
            if(reset = '1') then 
                ir <= (others => '0');
            elsif(rising_edge(clk) and ir_write = '1') then
                ir <= pm_out;
            end if;
        end process ir_process;

        addressing_mode <= ir(31 downto 30);
        opcode <= ir(29 downto 24);
        rz_select <= ir(23 downto 20);
        rx_select <= ir(19 downto 16);
        ir_operand <= ir(15 downto 0); 

        
        -- Register File
        regfile : entity work.regfile
        port map(
            
		clk => clk,
		init => reset,
		ld_r => rf_write,
		sel_z => to_integer(unsigned(rz_select)),
		sel_x => to_integer(unsigned(rx_select)),
		rx => rx,
		rz => rz,
		rf_input_sel => rf_input_sel,
		ir_operand => ir_operand,
		dm_out => dm_out,
		aluout => alu_out,
		rz_max => (others => '0'),
		sip_hold => sip,
		er_temp => '0',
		r7 => r7,
		dprr_res => '0',
		dprr_res_reg => '0',
		dprr_wren => '0'
        );

	-- ALU
	ALU : entity work.alu
	port map (
		clk => clk,
		z_flag => z_flag,
		alu_operation => alu_operation,
		alu_op1_sel => alu_op1_sel,
		alu_op2_sel => alu_op2_sel,
		alu_carry => '1',
		alu_result => alu_out,
		rx => rx,
		rz => rz,
		ir_operand => ir_operand,
		clr_z_flag => clr_z_flag,
		reset => reset
	);


        -- Data memory input multiplexers
        dm_addr <= rx when dm_addr_sel = dm_addr_sel_rx else
                   rz when dm_addr_sel = dm_addr_sel_rz else
                   ir_operand when dm_addr_sel = dm_addr_sel_operand else
                   (others => '0');

        dm_in <= rx when dm_in_sel = dm_in_sel_rx else
                 ir_operand when dm_in_sel = dm_in_sel_operand else
                 pc when dm_in_sel = dm_in_sel_pc else
                 (others => '0');
                 
        -- SOP
        sop_process: process (clk, reset) begin
            if (reset = '1') then 
                sop <= (others => '0');
            elsif (rising_edge(clk) and sop_write = '1') then
                sop <= rx;
            end if;
        end process sop_process;

        
        -- DPCR
        dpcr_process: process (clk, reset) begin
            if (reset = '1') then 
                dpcr <= (others => '0');
            elsif (rising_edge(clk) and dpcr_write = '1') then
                if (dpcr_sel = dpcr_sel_r7) then
                    dpcr(15 downto 0) <= r7;
                else
                    dpcr(15 downto 0) <= ir_operand;
                end if;
                dpcr(31 downto 16) <= rx;
            end if;
        end process dpcr_process;


        --Rz zero signal
        rz_zero <= '1' when rz = x"0000" else '0';

		  --NOC
        process(clk)
		  begin
			if rising_edge(clk) then
			if ADC_VALID = '1' then
				reg_adc <= ADC_DATA;
				  end if;
				 end if;
		  end process;


end combined;

