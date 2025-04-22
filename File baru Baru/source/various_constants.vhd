-- Zoran Salcic

library ieee;
use ieee.std_logic_1164.all;
use work.recop_types.all;

package various_constants is
-- ALU operation selection alu_sel
    constant alu_add: bit_3 := "000";
    constant alu_sub: bit_3 := "001";
    constant alu_and: bit_3 := "010";
    constant alu_or: bit_3 := "011";
    constant alu_idle: bit_3 := "100";
    constant alu_max: bit_3 := "101";

    constant alu_op1_sel_rx: bit_1 := '0';
    constant alu_op1_sel_operand: bit_1 := '1';

    constant alu_op2_sel_rx: bit_1 := '0';
    constant alu_op2_sel_rz: bit_1 := '1';
	
-- Program counter select
   constant pc_sel_next: bit_2 := "00";
   constant pc_sel_rx: bit_2 := "01";
   constant pc_sel_operand: bit_2 := "10";
    constant pc_sel_reset: bit_2 := "11";

-- Data memory input select
   constant dm_in_sel_rx: bit_2 := "00";
   constant dm_in_sel_operand: bit_2 := "01";
   constant dm_in_sel_pc: bit_2 := "10";
	constant dm_in_sel_rz      : bit_2 := "11";
	
-- Data memory address select
   constant dm_addr_sel_rx: bit_2 := "00";
   constant dm_addr_sel_rz: bit_2 := "01";
   constant dm_addr_sel_operand: bit_2 := "10";

--rf input constant
    constant rf_input_sel_operand: bit_3 := "000";
    constant rf_input_sel_alu: bit_3 := "011";
    constant rf_input_sel_sip: bit_3 := "101";
    constant rf_input_sel_dm: bit_3 := "111";

    constant dpcr_sel_r7: bit_1 := '0';
    constant dpcr_sel_operand: bit_1 := '1';

	
end various_constants;	
