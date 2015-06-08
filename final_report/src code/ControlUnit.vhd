----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 05/27/2015 04:02:53 PM
-- Design Name: 
-- Module Name: ControlUnit - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity ControlUnit is
Generic (STACK_TOP : integer := 100);  -- Address of the beginning of the stack
Port ( clk 					: in std_logic;
	   I_instROM_data 		: in std_logic_vector (15 downto 0);	-- instruction from ROM memory 
	   I_RF_Preg_isZero 	: in std_logic;							-- flag indicating Preg is zero (used for jump if zero)
	   I_program_en			: in std_logic; 						-- Enables programming mode (no program execution during this time)
	   I_button				: in std_logic;							-- button to step through commands 
	   I_PC_limit			: in std_logic_vector (7 downto 0);		-- Maximum step to execute
	   Q_instROM_addr 		: out std_logic_vector (15 downto 0);	-- ROM address from which to receive instructions
	   Q_instROM_rd 		: out std_logic;						-- ROM read enable signal to aquire instruction
	   Q_M_addr				: out std_logic_vector (7 downto 0);	-- BRAM address
	   Q_M_addr_sel			: out std_logic_vector (1 downto 0);	-- Select between direct and indirect memory access  
--	   Q_M_rd 				: out std_logic;						-- BRAM read enable
	   Q_M_wr 				: out std_logic;						-- BRAM write enable
	   Q_RF_IR_data 		: out std_logic_vector (7 downto 0);	-- Bottom 8 bits from the instruction register (for load constant)
	   Q_RF_Wreg_sel 		: out std_logic_vector (1 downto 0);	-- Mux select for inputs to register file
	   Q_RF_Wreg_addr 		: out std_logic_vector (3 downto 0);	-- Address of register to be written to (Wreg)
	   Q_RF_Wreg_wr 		: out std_logic;						-- write enable for write register (Wreg)
	   Q_RF_Preg_addr 		: out std_logic_vector (3 downto 0);	-- Address of primary read register (Preg)
	   Q_RF_Preg_rd 		: out std_logic;						-- read enable for Preg
	   Q_RF_Qreg_addr 		: out std_logic_vector (3 downto 0);	-- Address of secondary read register (Qreg - only used for arithmetic functions)
	   Q_RF_Qreg_rd 		: out std_logic;						-- read enable for Qreg
	   Q_ALU_sel 			: out std_logic_vector (1 downto 0);	-- ALU MUX: 00=>Preg pass through, 01=>Preg+Qreg, 10=>Preg-Qreg
	   Q_SP_addr			: out std_logic_vector (7 downto 0);	-- Stack Pointer address for memory
	   Q_PC_count			: out std_logic_vector (15 downto 0)	-- Push the program count out to display
	   );
end ControlUnit;

architecture Behavioral of ControlUnit is

	-- Signals for the Program Counter
	signal L_PC_count		: unsigned (15 downto 0) := x"0000";		-- Program Count
	signal L_PC_ld			: std_logic := '0';							-- PC load from IR offset
	signal L_PC_clr			: std_logic := '0';							-- clear the PC
	signal L_PC_inc			: std_logic := '0';							-- increment the PC
	signal L_PC_dir			: std_logic := '0';							-- PC jump to direct address
	signal L_PC_restore		: std_logic := '0';							-- PC restore from LR
	signal L_PC_offset		: unsigned (7 downto 0) := x"00";			-- PC offset value from IR
	signal L_PC_full		: std_logic := '0';							-- Flag when PC reaches the limit
	
	-- Signals for Instruction Register
	signal L_IR_data		: std_logic_vector (15 downto 0) := x"0000";-- Instruction held in the IR
	signal L_IR_ld			: std_logic := '0';							-- load enable for IR
	signal L_IR_Opcode		: std_logic_vector (3 downto 0);
	
	-- Signals for the Link Register
	signal L_LR_data		: unsigned (15 downto 0) := x"0000";		-- Link Register
	signal L_LR_ld			: std_logic := '0';							-- LR load from PC
	signal L_LR_clr			: std_logic := '0';							-- clear the LR
	
	-- Signals for the stack register
	signal L_SP_addr		: unsigned (7 downto 0) := to_unsigned(STACK_TOP, 8);	-- Stack pointer
	signal L_SP_inc			: std_logic := '0'; 									-- Stack pointer increment
	signal L_SP_dec			: std_logic := '0'; 									-- Stack pointer decrement
	signal L_SP_clr 		: std_logic := '0'; 									-- Stack pointer clear
	
	-- Signals for Push Counter
	signal L_PushCount		: unsigned (3 downto 0) := "0000";			-- Counter for Push/Pop operations (cycles through registers)
	signal L_PushCount_clr	: std_logic := '0';							-- Clear the Push Counter
	signal L_PushCount_inc	: std_logic := '0';							-- increment the Push Counter
	signal L_PushCount_full	: std_logic := '0';							-- Flag when Push Counter = 12
	signal L_PopCount		: unsigned (3 downto 0) := x"C";			-- Pop Count
	signal L_Push_ready		: std_logic := '0';							-- enable pushing!
	signal L_Pop_ready		: std_logic := '0';							-- enable popping!
	
	-- State Machine signals
	type state_type is (sIDLE, sWAIT_XROM, sWAIT_MRAM, sPC_INC, SPC_INC_pre, sPC_DIRECT, sPC_DIRECT_pre, sPC_JUMP, sPC_JUMP_pre, 
						sPC_RESTORE, sPC_RESTORE_pre, sFETCH, sDECODE, sLOAD_DIR, sSTORE_DIR, sMOVE, sCONST, sADD, sSUB, sBZ, 
						sBD, sBL, sLOAD_IND, sSTORE_IND, sNO_OP, sPUSH1, sPUSH2, sPOP1, sPOP2, sPOP3, sFINISHED, sFIRST);
		signal current_state, next_state : state_type := sIDLE;
	
begin

Q_instROM_rd <= '1';

L_IR_Opcode <= L_IR_data(15 downto 12);

-- Asynchronous Address Outputs	
Q_instROM_addr <= std_logic_vector(L_PC_count);				
Q_M_addr <= L_IR_data(7 downto 0);
Q_RF_Qreg_addr <= L_IR_data(3 downto 0);
Q_SP_addr <= std_logic_vector(L_SP_addr);


Q_RF_Wreg_addr <= std_logic_vector(L_PopCount) when (L_IR_Opcode = x"D") else L_IR_data(11 downto 8);

--Q_RF_Preg_addr <= L_IR_data(11 downto 8) when (L_IR_opcode = x"7") or (L_IR_opcode = x"2") else L_IR_data(7 downto 4);
with L_IR_opcode select
	Q_RF_Preg_addr <= 	L_IR_data(11 downto 8) when x"2",
						L_IR_data(11 downto 8) when x"7",
						std_logic_vector(L_PushCount) when x"C",
						L_IR_data(7 downto 4) when others;
						
with L_IR_opcode select
	Q_M_addr_sel <=	"01" when x"a",		-- Memory address gets Qreg
					"01" when x"b",		
					"10" when x"c",		-- Memory address gets stack pointer
					"10" when x"d",		
					"00" when others;
						
--------------------------------------------
 
ProgramCounter: process(clk)
begin
	if rising_edge(clk) then
		if ( L_PC_clr = '1' ) then
			L_PC_count <= x"0000";
		elsif ( L_PC_inc = '1' ) then
			L_PC_count <= L_PC_count + 1;
		elsif ( L_PC_dir = '1' ) then
			L_PC_count <= x"00" & L_PC_offset;
		elsif ( L_PC_ld = '1' ) then
			L_PC_count <= L_PC_count + 1 + L_PC_offset;
		elsif ( L_PC_restore = '1' ) then
			L_PC_count <= L_LR_data + 1;
		end if;
	end if;
end process;
Q_PC_count <= std_logic_vector(L_PC_count);
L_PC_full <= '1' when L_PC_count >= (unsigned(I_PC_limit) - 1) else '0';


LinkRegister: process(clk)
begin
	if rising_edge(clk) then
		if ( L_LR_clr = '1' ) then
			L_LR_data <= x"0000";
		elsif ( L_LR_ld = '1' ) then
			L_LR_data <= L_PC_count;
		end if;
	end if;
end process;


StackPointer: process(clk)
begin 
	if rising_edge(clk) then
		if (L_SP_clr = '1') then 
			L_SP_addr <= to_unsigned(STACK_TOP, L_SP_addr'Length); -- reset SP to STACK_TOP 
		elsif (L_SP_dec = '1') then 
			L_SP_addr <= L_SP_addr - 1; -- decrement SP 
		elsif (L_SP_inc = '1') then 
			L_SP_addr <= L_SP_addr + 1; -- increment SP 
		end if; 
	end if; 
end process; 

PushCounter: process(clk)
begin
	if rising_edge(clk) then
		if ( L_PushCount_clr = '1' ) then
			L_PushCount <= "0000";
		elsif ( L_PushCount_inc = '1' ) then
			if ( L_PushCount_full = '1' ) then
				L_PushCount <= "0000";
			else
				L_PushCount <= L_PushCount + 1;
			end if;
		end if;
	end if;
end process;
L_PushCount_full <= '1' when ( L_PushCount = x"B" ) else '0';		-- Push Count is full when 12
L_PopCount <= 11 - L_PushCount;
L_Push_ready <= '1' when ( L_IR_data(to_integer(L_PushCount)) = '1' ) else '0';
L_Pop_ready <= '1' when ( L_IR_data(to_integer(L_PopCount)) = '1' ) else '0';

InstructionRegister: process(clk)
begin
	if rising_edge(clk) then
		if ( L_IR_ld = '1' ) then
			L_IR_data <= I_instROM_data;
		end if;
	end if;
end process;
L_PC_offset <= unsigned(L_IR_data(7 downto 0));
Q_RF_IR_data <= L_IR_data(7 downto 0);

StateUpdate: process(clk)
begin
	if rising_edge(clk) then
		current_state <= next_state;
	end if;
end process;

StateMachine: process(current_state, L_IR_Opcode, I_RF_Preg_isZero, I_program_en, L_PushCount_full, L_Push_ready, L_Pop_ready, I_button, L_PC_full)
begin
	-- State Default
	next_state <= current_state;
	
	--Local signal defaults
	L_IR_ld <= '0';
	L_PC_clr <= '0';
	L_PC_inc <= '0';
	L_PC_ld <= '0';
	L_PC_dir <= '0';
	L_PC_restore <= '0';
	L_LR_ld <= '0';
	L_LR_clr <= '0';
	L_SP_clr <= '0';
	L_SP_inc <= '0';
	L_SP_dec <= '0';
	L_PushCount_clr <= '0';
	L_PushCount_inc <= '0';
	
	--Output defaults
	Q_RF_Preg_rd <= '0';
	Q_RF_Qreg_rd <= '0';
	Q_RF_Wreg_sel <= "00";
	Q_RF_Wreg_wr <= '0';
	Q_M_wr <= '0';
	Q_ALU_sel <= "00";
	
	case current_state is
	
		when sIDLE =>
			L_PC_clr <= '1';
			L_LR_clr <= '1';
			L_SP_clr <= '1';
			if ( I_program_en = '0' ) then
				next_state <= sWAIT_XROM;
			end if;
			
--		when sFIRST =>
--			if I_button = '1' then
--				next_state <= sWAIT_XROM;
--			end if;
			
		when sWAIT_XROM =>
			if I_button = '1' then
				next_state <= sFETCH;
			end if;
			
		when sFETCH =>
			L_IR_ld <= '1';
			next_state <= sDECODE;
		
		when sDECODE =>
			Q_RF_Preg_rd <= '1';
			Q_RF_Qreg_rd <= '1';
			next_state <= sWAIT_MRAM;
			
		when sWAIT_MRAM =>
			
			case L_IR_Opcode is
				when x"0" => next_state <= sNO_OP;
				when x"1" => next_state <= sLOAD_DIR;
				when x"2" => next_state <= sSTORE_DIR;
				when x"3" => next_state <= sMOVE;
				when x"4" => next_state <= sCONST;
				when x"5" => next_state <= sADD;
				when x"6" => next_state <= sSUB;
				when x"7" => next_state <= sBZ;
				when x"8" => next_state <= sBD;
				when x"9" => next_state <= sBL;
				when x"A" => next_state <= sLOAD_IND;
				when x"B" => next_state <= sSTORE_IND;
				when x"C" => next_state <= sPUSH1;
				when x"D" => next_state <= sPOP1;
				when others => next_state <= sPC_INC;
			end case;
		
		when sLOAD_DIR =>
			Q_RF_Wreg_wr <= '1';
			Q_RF_Wreg_sel <= "01";
			if L_PC_full = '1' then
				next_state <= sFINISHED;
			else next_state <= sPC_INC;
			end if;
			
		when sSTORE_DIR =>
			Q_M_wr <= '1';
			if L_PC_full = '1' then
				next_state <= sFINISHED;
			else next_state <= sPC_INC;
			end if;
			
		when sMOVE =>
			Q_RF_Wreg_wr <= '1';
			if L_PC_full = '1' then
				next_state <= sFINISHED;
			else next_state <= sPC_INC;
			end if;
		
		when sCONST =>
			Q_RF_Wreg_sel <= "10";
			Q_RF_Wreg_wr <= '1';
			if L_PC_full = '1' then
				next_state <= sFINISHED;
			else next_state <= sPC_INC;
			end if;
			
		when sADD =>
			Q_ALU_sel <= "01";
			Q_RF_Wreg_wr <= '1';
			if L_PC_full = '1' then
				next_state <= sFINISHED;
			else next_state <= sPC_INC;
			end if;
			
		when sSUB =>
			Q_ALU_sel <= "10";
			Q_RF_Wreg_wr <= '1';
			if L_PC_full = '1' then
				next_state <= sFINISHED;
			else next_state <= sPC_INC;
			end if;
			
		when sBZ =>
			if ( I_RF_Preg_isZero = '1' ) then
				next_state <= sPC_JUMP;
			else
				if L_PC_full = '1' then
					next_state <= sFINISHED;
				else next_state <= sPC_INC;
				end if;
			end if;
			
		when sBD =>
			next_state <= sPC_DIRECT;
			
		when sBL =>
			L_LR_ld <= '1';
			next_state <= sPC_DIRECT;
			
		when sLOAD_IND =>
			Q_RF_Wreg_wr <= '1';
			Q_RF_Wreg_sel <= "01";
			if L_PC_full = '1' then
				next_state <= sFINISHED;
			else next_state <= sPC_INC;
			end if;
			
		when sSTORE_IND =>
			Q_M_wr <= '1';
			if L_PC_full = '1' then
				next_state <= sFINISHED;
			else next_state <= sPC_INC;
			end if;
			
		when sNO_OP =>
			if L_PC_full = '1' then
				next_state <= sFINISHED;
			else next_state <= sPC_INC;
			end if;
			
		when sPC_INC =>
			L_PC_inc <= '1';
			next_state <= sWAIT_XROM;
			
		when sPC_JUMP =>
			L_PC_ld <= '1';
			next_state <= sWAIT_XROM;
			
		when sPC_DIRECT =>
			L_PC_dir <= '1';
			next_state <= sWAIT_XROM;
			
		when sPC_RESTORE =>
			L_PC_restore <= '1';
			next_state <= sWAIT_XROM;
			
		when sPUSH1 =>
			Q_RF_Preg_rd <= '1';
			next_state <= sPUSH2;
			
		when sPUSH2 =>
			L_PushCount_inc <= '1';
			if ( L_Push_ready = '1' ) then
				Q_M_wr <= '1';
				L_SP_inc <= '1';
			end if;
			
			if ( L_PushCount_full = '1' ) then
				next_state <= sPC_INC;
			else
				next_state <= sPUSH1;
			end if;
			
		when sPOP1 =>
			Q_RF_Wreg_sel <= "01";		-- Wreg gets data from Memory
			if ( L_Pop_ready = '1' ) then
				L_SP_dec <= '1';
				next_state <= sPOP2;
			else
				next_state <= sPOP3;
			end if;
			
		when sPOP2 =>
			Q_RF_Wreg_sel <= "01";
			next_state <= sPOP3;
			
		when sPOP3 =>
			Q_RF_Wreg_sel <= "01";
			L_PushCount_inc <= '1';
			if ( L_Pop_ready = '1' ) then
				Q_RF_Wreg_wr <= '1';
			end if;
			
			if (L_PushCount_full = '1') then
				next_state <= sPC_RESTORE;			-- *** CHECK HERE IF BROKEN ***
			else
				next_state <= sPOP1;
			end if;
			
--		when sPC_INC_pre =>
--			if L_PC_full = '1' then
--				next_state <= sFINISHED;
--			elsif I_button = '1' then
--				next_state <= sPC_INC;
--			end if;
		
--		when sPC_DIRECT_pre =>
--			if L_PC_full = '1' then
--				next_state <= sFINISHED;
--			elsif I_button = '1' then
--				next_state <= sPC_DIRECT;
--			end if;
			
--		when sPC_JUMP_pre =>
--			if L_PC_full = '1' then
--				next_state <= sFINISHED;
--			elsif I_button = '1' then
--				next_state <= sPC_JUMP;
--			end if;
			
--		when sPC_RESTORE_pre =>
--			if L_PC_full = '1' then
--				next_state <= sFINISHED;
--			elsif I_button = '1' then
--				next_state <= sPC_RESTORE;
--			end if;
			
		when sFINISHED =>
			
		when others =>
			next_state <= sPC_INC_pre;
	end case;
	
	if ( I_program_en = '1' ) then
		next_state <= sIDLE;
	end if;
	
end process;

end Behavioral;
