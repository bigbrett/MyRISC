----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 05/27/2015 04:02:53 PM
-- Design Name: 
-- Module Name: Datapath - Behavioral
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

entity Datapath is
Port ( clk 					: in STD_LOGIC;
	   I_RF_M_data 			: in STD_LOGIC_VECTOR (15 downto 0);	-- data from BRAM into datapath
	   I_RF_IR_data 		: in STD_LOGIC_VECTOR (7 downto 0);		-- Bottom 8 bits from the instruction register (for load constant)
	   I_RF_Wreg_addr 		: in STD_LOGIC_VECTOR (3 downto 0);		-- Address of register to be written to (Wreg)
	   I_RF_Wreg_wr 		: in STD_LOGIC;							-- write enable for write register (Wreg)
	   I_RF_Wreg_sel 		: in STD_LOGIC_VECTOR (1 downto 0);		-- Mux select for inputs to register file
	   I_RF_Preg_addr 		: in STD_LOGIC_VECTOR (3 downto 0);		-- Address of primary read register (Preg)
	   I_RF_Preg_rd 		: in STD_LOGIC;							-- read enable for Preg
	   I_RF_Qreg_addr 		: in STD_LOGIC_VECTOR (3 downto 0); 	-- Address of secondary read register (Qreg - only used for arithmetic functions)
	   I_RF_Qreg_rd 		: in STD_LOGIC; 						-- read enable for Qreg
	   I_ALU_sel 			: in STD_LOGIC_VECTOR (1 downto 0); 	-- ALU MUX: 00=>Preg pass through, 01=>Preg+Qreg, 10=>Preg-Qreg
	   Q_M_data				: out STD_LOGIC_VECTOR (15 downto 0);	-- data from datapath into BRAM 
	   Q_RF_Preg_isZero 	: out STD_LOGIC);						-- flag indicating Preg is zero (used for jump if zero) 
end Datapath;

architecture Behavioral of Datapath is

	-- Structure for register file
	type Register_File is array(0 to 15) of std_logic_vector(15 downto 0);
		signal L_RF_Register	: Register_File;
	
	
	signal L_RF_Preg_data	: unsigned(15 downto 0) := x"0000";
	signal L_RF_Qreg_data	: unsigned(15 downto 0) := x"0000";
	signal L_ALU_data		: unsigned(15 downto 0) := x"0000";
	signal L_RF_Wreg_data	: std_logic_vector(15 downto 0) := x"0000";
	
begin

WregDataMux: process(I_RF_IR_data, I_RF_M_data, L_ALU_data, I_RF_Wreg_sel)
begin
	case I_RF_Wreg_sel is
		when "00" =>
			L_RF_Wreg_data <= std_logic_vector(L_ALU_data);			
		when "01" =>
			L_RF_Wreg_data <= I_RF_M_data;			
		when "10" =>
			L_RF_Wreg_data <= x"00" & I_RF_IR_data;			
		when others =>
			L_RF_Wreg_data <= x"0000";
	end case;
end process;


RegisterWrite: process(clk)
begin
	if rising_edge(clk) then
		if ( I_RF_Wreg_wr = '1' ) then
			L_RF_Register(to_integer(unsigned(I_RF_Wreg_addr))) <= L_RF_Wreg_data;
		end if;
	end if;
end process;


PregQreg: process(clk)
begin
	if rising_edge(clk) then
		-- Register Preg from the array
		if ( I_RF_Preg_rd = '1' ) then
			L_RF_Preg_data <= unsigned(L_RF_Register(to_integer(unsigned(I_RF_Preg_addr))));
		end if;
		-- Register Qreg from the array
		if ( I_RF_Qreg_rd = '1' ) then
			L_RF_Qreg_data <= unsigned(L_RF_Register(to_integer(unsigned(I_RF_Qreg_addr))));
		end if;
	end if;
end process;


ArithmeticLogicUnit: process(L_RF_Preg_data, L_RF_Qreg_data, I_ALU_sel)
begin
	case I_ALU_sel is
		when "00" =>						-- Preg pass through
			L_ALU_data <= L_RF_Preg_data;		
		when "01" =>						-- Preg + Qreg
			L_ALU_data <= L_RF_Preg_data + L_RF_Qreg_data;			
		when "10" =>						-- Preg - Qreg
			L_ALU_data <= L_RF_Preg_data - L_RF_Qreg_data;		
		when others =>
			L_ALU_data <= x"0000";
	end case;
end process;

-- Asynchronous Preg Zero flag
Q_RF_Preg_isZero <= '1' when L_RF_Preg_data = x"0000" else '0';

-- Data written to memory always comes from Preg
Q_M_data <= std_logic_vector(L_RF_Preg_data);

end Behavioral;
