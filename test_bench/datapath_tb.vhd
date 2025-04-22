library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.various_constants.all;
use work.opcodes.all;
use work.recop_types.all;

entity datapath_tb is
end entity datapath_tb;

architecture tb of datapath_tb is
    constant clk_period : time := 10 ns;

    signal clk: bit_1 := '0';
    signal reset: bit_1;

    signal pm_out: bit_32;
    signal pm_addr, dm_out, dm_in, dm_addr: bit_16;

    signal pc_sel: bit_2;
    signal pc_write, ir_write, sop_write, dpcr_write, rf_write: bit_1;
	 signal sip, sop: bit_16;
	 signal dpcr: bit_32;
    signal dm_addr_sel, dm_in_sel: bit_2;
    signal rf_input_sel: bit_3;
    signal alu_operation: bit_3; 
    signal alu_op1_sel: bit_2;
    signal alu_op2_sel: bit_1;
    signal dpcr_sel: bit_1;
    signal clr_z_flag: bit_1;
    
    signal z_flag: bit_1;
    signal addressing_mode: bit_2;
    signal opcode: bit_6;
begin
    dut : entity work.datapath
    port map (
            clk => clk,
            reset => reset,

            -- Program memory
            pm_out => pm_out,
            pm_addr => pm_addr,

            -- Data memory
            dm_out => dm_out,
            dm_in => dm_in,
            dm_addr => dm_addr,
				
				-- External interface
				sip => sip,
				sop => sop,
				dpcr => dpcr,
            
            -- Signals from control unit
            pc_sel => pc_sel,
            rf_write => rf_write,
            dpcr_write => dpcr_write,
            sop_write => sop_write,
            pc_write => pc_write,
            ir_write => ir_write,
            dm_addr_sel  => dm_addr_sel,
            dm_in_sel => dm_in_sel,
            rf_input_sel => rf_input_sel,
            alu_operation => alu_operation,
            alu_op1_sel => alu_op1_sel,
            alu_op2_sel => alu_op2_sel,
            dpcr_sel => dpcr_sel,
            clr_z_flag => clr_z_flag,

            -- Signals to control unit
            z_flag => z_flag,
            addressing_mode => addressing_mode,
            opcode => opcode
    );

    -- Clock signal generator;
    clk <= not clk after clk_period/2;

    stimuli: process begin
        
        --reset
        pc_sel <= (others => '0');
        rf_write <= '0';
        dpcr_write <= '0';
        sop_write <= '0';
        pc_write <= '0';
        ir_write <= '0';
        dm_addr_sel  <= (others => '0');
        dm_in_sel <= (others => '0');
        rf_input_sel <= (others => '0');
        alu_operation <= (others => '0');
        alu_op1_sel <= (others => '0');
        alu_op2_sel <= '0';
        dpcr_sel <= '0';
        clr_z_flag <= '0';

        reset <= '1';
        wait for clk_period;
        reset <= '0';
        wait for clk_period;

        --testing pc 
        
        assert to_integer(unsigned(pm_addr)) = 0 report "pc should be 0 after reseta" severity error;
        pc_sel <= pc_sel_next;
        pc_write <= '1';
        wait for clk_period;
        assert to_integer(unsigned(pm_addr)) = 1 report "pc did not increment" severity error;

        wait for clk_period;
        pc_write <= '0';

        --testing ir
        pm_out <= x"deadbeef";
        ir_write <= '1';
        wait for clk_period;
        assert addressing_mode = pm_out(31 downto 30) report "addressing mode is not what was provided by program memory" severity error;
        assert opcode = pm_out(29 downto 24) report "opcode is not what was provided by program memory" severity error;
        

        -- testing alu

        -- instruction format
        -- ---------------------------------------------
        -- |AM(2)|OP(6)|Rz(4)|Rx(4)|ADDR/VAL/OTHERs(16)|
        -- ---------------------------------------------
        
        pm_out <= am_immediate & ldr & x"0" & x"0" & x"1234"; --AM and OP does not matter as we dont have a control unit
        rf_write <= '1';
        rf_input_sel <= "000"; -- ir_operand
        wait for 2*clk_period;
        pm_out <= am_immediate & ldr & x"1" & x"0" & x"abcd";
        wait for 2*clk_period;
        pm_out <= am_immediate & andr & x"2" & x"0" & x"5678";
        rf_input_sel <= "011"; -- alu_out
        alu_operation <= alu_and;
        alu_op1_sel <= "01"; -- ir_operand
        alu_op2_sel <= '0'; -- rx
        wait for 2*clk_period;
        pm_out <= am_immediate & str & x"0" & x"2" & x"a7a7";
        rf_write <= '0';
        dm_addr_sel <= dm_addr_sel_operand;
        dm_in_sel <= dm_in_sel_rx;
        wait for 2*clk_period;
        assert dm_in = x"1230"  report "and operation failed" severity error; -- 1234 AND 5678 = 1230

        assert false report "testbench finished" severity failure;
    end process stimuli;
end tb;
