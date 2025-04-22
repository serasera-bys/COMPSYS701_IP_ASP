library ieee;
use ieee.std_logic_1164.all;
use work.recop_types.all;
use work.opcodes.all;
use work.various_constants.all;  

entity control_unit is
    port (
        clk             : in  bit_1;
        reset           : in  bit_1;
        
        --from datapath
        z_flag          : in  bit_1;
        rz_zero         : in  bit_1;
        addressing_mode : in  bit_2;
        opcode          : in  bit_6;
        
        --to datapath
        pc_sel          : out bit_2;
        pc_write        : out bit_1;
        ir_write        : out bit_1;
        sop_write       : out bit_1;
        dpcr_write      : out bit_1;
        dpcr_sel        : out bit_1;
        dm_write        : out bit_1;
        rf_write        : out bit_1;
        dm_addr_sel     : out bit_2;
        dm_in_sel       : out bit_2;
        rf_input_sel    : out bit_3;
        alu_operation   : out bit_3;
        alu_op1_sel     : out bit_1;
        alu_op2_sel     : out bit_1;
        clr_z_flag      : out bit_1
    );
end control_unit;

architecture Behavioral of control_unit is
    type state_type is (INIT, FETCH, DECODE, EXECUTE);
    signal current_state, next_state : state_type;
begin
    --Transition
    process(clk, reset)
    begin
        if reset = '1' then
            current_state <= INIT;
        elsif rising_edge(clk) then
            current_state <= next_state;
        end if;
    end process;

    --Combinational Logic
    process(all) --current_state, opcode, z_flag, addressing_mode,reset
    begin
        pc_sel        <= pc_sel_next;
        pc_write      <= '0';
        ir_write      <= '0';
        sop_write     <= '0';
        dpcr_write    <= '0';
        dm_write      <= '0';
        rf_write      <= '0';
        dpcr_sel      <= dpcr_sel_r7;
        dm_addr_sel   <= dm_addr_sel_rx;
        dm_in_sel     <= dm_in_sel_rx;
        rf_input_sel  <= rf_input_sel_alu;
        alu_operation <= alu_idle;
        alu_op1_sel   <= alu_op1_sel_rx;
        alu_op2_sel   <= alu_op2_sel_rx;
        clr_z_flag    <= '0';

        case current_state is

            when INIT =>
                pc_sel <= pc_sel_reset;
                pc_write <= '1';
                next_state <= FETCH;

            when FETCH =>
                ir_write   <= '1';
                pc_write   <= '1';
                pc_sel     <= pc_sel_next;
                next_state <= DECODE;
                
            when DECODE =>
            
                --DECODE state is only needed for loading in the address to data memory during a LDR instruction as the output will arrive in the next cycle
                case addressing_mode is
                    when am_direct => dm_addr_sel <= dm_addr_sel_operand;
                    when others  => dm_addr_sel <= dm_addr_sel_rx;
                end case;
                next_state <= EXECUTE;

            when EXECUTE=>
                --Set operand multiplexers
                case addressing_mode is
                    when am_immediate =>
                        alu_op1_sel <= alu_op1_sel_operand;
                        alu_op2_sel <= alu_op2_sel_rx;
                        dm_addr_sel <= dm_addr_sel_rz;
                        pc_sel <= pc_sel_operand;
                        dpcr_sel <= dpcr_sel_operand;
                    when am_direct =>
                        dm_addr_sel <= dm_addr_sel_operand;
                    when am_register =>
                        alu_op1_sel <= alu_op1_sel_rx;
                        alu_op2_sel <= alu_op2_sel_rz;
                        pc_sel <= pc_sel_rx;
                        dpcr_sel <= dpcr_sel_r7;
                        if opcode = str then
                            dm_addr_sel <= dm_addr_sel_rz;
                        else
                            dm_addr_sel <= dm_addr_sel_rx;
                        end if;
                    when others => null;
                end case;

                
                -- Set write signals and multiplexers 
                case opcode is
                
                    when andr =>
                        alu_operation <= alu_and;
                        rf_input_sel <= rf_input_sel_alu;
                        rf_write <= '1';

                    when orr =>
                        alu_operation <= alu_or;
                        rf_input_sel <= rf_input_sel_alu;
                        rf_write <= '1';
                        
                    when addr =>
                        alu_operation <= alu_add;
                        rf_input_sel <= rf_input_sel_alu;
                        rf_write <= '1';

                    when subvr =>
                        alu_operation <= alu_sub;
                        rf_input_sel <= rf_input_sel_alu;
                        rf_write <= '1';

                    when subr =>
                        alu_operation <= alu_sub;
                        rf_input_sel <= rf_input_sel_alu;
                    
                    when ldr =>
                        if addressing_mode = am_immediate then
                            rf_input_sel <= rf_input_sel_operand;
                        else
                            rf_input_sel <= rf_input_sel_dm;
                        end if;
                        rf_write <= '1';

                    when str =>
                        --if addressing_mode = am_immediate then
                            --dm_in_sel <= dm_in_sel_operand;
                        --else
                            --dm_in_sel <= dm_in_sel_rx;
                        --end if;
								
								
                        --dm_write <= '1';
								
									 dm_write    <= '1';

									 case addressing_mode is
										  when am_immediate =>
												dm_in_sel   <= dm_in_sel_operand;
												dm_addr_sel <= dm_addr_sel_operand; 
										  when am_direct =>
												dm_in_sel   <= dm_in_sel_rx;
												dm_addr_sel <= dm_addr_sel_operand; 
										  when am_register =>
												dm_in_sel   <= dm_in_sel_rx;
												dm_addr_sel <= dm_addr_sel_rz;
										  when others =>
												null;
									 end case;

                    when jmp =>
                        --pc_write <= '1';
								if z_flag = '0' then
										pc_write <= '1';
								end if;

								

                    when present =>
                        if rz_zero = '1' then 
                            pc_write <= '1';
                        end if;

                    when sz =>
                        if z_flag = '1' then 
                            pc_write <= '1';
                        end if;

                    when datacall => 
                        dpcr_write <= '1';       

                    when clfz =>
                        clr_z_flag <= '1';

                    when lsip =>
                        rf_input_sel <= rf_input_sel_sip;
                        rf_write <= '1';

                    when ssop =>
                        sop_write <= '1';

                    when strpc =>
                        dm_in_sel <= dm_in_sel_pc;
                        dm_write <= '1';

                    when others => null; --including NOOP instruction;
               end case;

               next_state <= FETCH;

        end case;
    end process;
end Behavioral;
