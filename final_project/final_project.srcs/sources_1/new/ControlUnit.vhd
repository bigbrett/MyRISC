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
Port ( clk 					: in STD_LOGIC;
	   I_instROM_data 		: in STD_LOGIC_VECTOR (15 downto 0);	-- instruction from ROM memory 
	   I_RF_Preg_isZero 	: in STD_LOGIC;							-- flag indicating Preg is zero (used for jump if zero) 
	   Q_instROM_addr 		: out STD_LOGIC_VECTOR (15 downto 0);	-- ROM address from which to receive instructions
	   Q_instROM_rd 		: out STD_LOGIC;						-- ROM read enable signal to aquire instruction
	   Q_M_addr				: out STD_LOGIC_VECTOR (7 downto 0);	-- BRAM address  
--	   Q_M_rd 				: out STD_LOGIC;						-- BRAM read enable
	   Q_M_wr 				: out STD_LOGIC;						-- BRAM write enable
	   Q_RF_IR_data 		: out STD_LOGIC_VECTOR (7 downto 0);	-- Bottom 8 bits from the instruction register (for load constant)
	   Q_RF_Wreg_sel 		: out STD_LOGIC_VECTOR (1 downto 0);	-- Mux select for inputs to register file
	   Q_RF_Wreg_addr 		: out STD_LOGIC_VECTOR (3 downto 0);	-- Address of register to be written to (Wreg)
	   Q_RF_Wreg_wr 		: out STD_LOGIC;						-- write enable for write register (Wreg)
	   Q_RF_Preg_addr 		: out STD_LOGIC_VECTOR (3 downto 0);	-- Address of primary read register (Preg)
	   Q_RF_Preg_rd 		: out STD_LOGIC;						-- read enable for Preg
	   Q_RF_Qreg_addr 		: out STD_LOGIC_VECTOR (3 downto 0);	-- Address of secondary read register (Qreg - only used for arithmetic functions)
	   Q_RF_Qreg_rd 		: out STD_LOGIC;						-- read enable for Qreg
	   Q_ALU_sel 			: out STD_LOGIC_VECTOR (1 downto 0));	-- ALU MUX: 00=>Preg pass through, 01=>Preg+Qreg, 10=>Preg-Qreg
end ControlUnit;

architecture Behavioral of ControlUnit is

	-- Signals for the Program Counter
	signal L_PC_count		: unsigned (15 downto 0) := x"0000";		-- Program Count
	signal L_PC_ld			: std_logic := '0';							-- PC load from IR offset
	signal L_PC_clr			: std_logic := '0';							-- clear the PC
	signal L_PC_inc			: std_logic := '0';							-- increment the PC
	signal L_PC_offset		: unsigned (7 downto 0) := x"00";			-- PC offset value from IR
	
	-- Signals for Instruction Register
	signal L_IR_data		: std_logic_vector (15 downto 0) := x"0000";-- Instruction held in the IR
	signal L_IR_ld			: std_logic := '0';							-- load enable for IR
	signal L_IR_Opcode		: std_logic_vector (3 downto 0);
	
	-- State Machine signals
	type state_type is (sIDLE, sWAIT, sPC_INC, sPC_JUMP, sFETCH, sDECODE, sLOAD, sSTORE, sADD, sCONST, sSUB, sJZ);
	signal current_state, next_state : state_type := sIDLE;
	
begin

Q_instROM_rd <= '1';

L_IR_Opcode <= L_IR_data(15 downto 12);

-- Asynchronous Address Outputs	
Q_instROM_addr <= std_logic_vector(L_PC_count);				
Q_M_addr <= L_IR_data(7 downto 0);
Q_RF_Wreg_addr <= L_IR_data(11 downto 8);
Q_RF_Preg_addr <= L_IR_data(11 downto 8) when ( L_IR_opcode = ("0101" or "0001") ) else L_IR_data(7 downto 4);
Q_RF_Qreg_addr <= L_IR_data(3 downto 0);


ProgramCoutner: process(clk)
begin
	if rising_edge(clk) then
		if ( L_PC_clr = '1' ) then
			L_PC_count <= x"0000";
		elsif ( L_PC_ld = '1' ) then
			L_PC_count <= L_PC_count + L_PC_offset;
		elsif ( L_PC_inc = '1' ) then
			L_PC_count <= L_PC_count + 1;
		end if;
	end if;
end process;


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

StateMachine: process(current_state, L_IR_Opcode, I_RF_Preg_isZero)
begin
	next_state <= current_state;
	L_IR_ld <= '0';
	L_PC_inc <= '0';
	L_PC_ld <= '0';
	Q_RF_Preg_rd <= '0';
	Q_RF_Qreg_rd <= '0';
	Q_RF_Wreg_sel <= "00";
	Q_RF_Wreg_wr <= '0';
	Q_M_wr <= '0';
	Q_ALU_sel <= "00";
	
	case current_state is
		
		when sIDLE =>
			next_state <= sWAIT;
		when sWAIT =>
			next_state <= sFETCH;
			
		when sFETCH =>
			L_IR_ld <= '1';
			next_state <= sDECODE;
		
		when sDECODE =>
			Q_RF_Preg_rd <= '1';
			Q_RF_Qreg_rd <= '1';
			
			case L_IR_Opcode is
				when "0000" => next_state <= sLOAD;
				when "0001" => next_state <= sSTORE;
				when "0010" => next_state <= sADD;
				when "0011" => next_state <= sCONST;
				when "0100" => next_state <= sSUB;
				when "0101" => next_state <= sJZ;
				when others => next_state <= sPC_INC;
			end case;
		
		when sLOAD =>
			Q_RF_Wreg_wr <= '1';
			Q_RF_Wreg_sel <= "01";
			next_state <= sPC_INC;
			
		when sSTORE =>
			Q_M_wr <= '1';
			next_state <= sPC_INC;
			
		when sADD =>
			Q_ALU_sel <= "01";
			Q_RF_Wreg_sel <= "00";
			Q_RF_Wreg_wr <= '1';
			next_state <= sPC_INC;
		
		when sCONST =>
			Q_RF_Wreg_sel <= "10";
			Q_RF_Wreg_wr <= '1';
			next_state <= sPC_INC;
			
		when sSUB =>
			Q_ALU_sel <= "10";
			Q_RF_Wreg_sel <= "00";
			Q_RF_Wreg_wr <= '1';
			next_state <= sPC_INC;
			
		when sJZ =>
			if ( I_RF_Preg_isZero = '1' ) then
				next_state <= sPC_JUMP;
			else
				next_state <= sPC_INC;
			end if;
			
		when sPC_INC =>
			L_PC_inc <= '1';
			next_state <= sWAIT;
			
		when sPC_JUMP =>
			L_PC_ld <= '1';
			next_state <= sWAIT;
			
		
		when others =>
			next_state <= sPC_INC;
	end case;
end process;

end Behavioral;
