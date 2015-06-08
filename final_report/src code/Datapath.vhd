----------------------------------------------------------------------------------
-- Class: 			ENGS 128 15S
-- Engineer: 		Brett Nicholas and Matt Metzler
-- 
-- Create Date: 	05/27/2015 03:43:05 PM
-- Design Name: 	Final Project
-- Module Name: 	Datapath - Behavioral
-- Project Name: 	MyRISC
-- Target Devices: 	Xilinx Arctix7 FPGA on Digilent BASYS3 project board
-- Tool Versions: 	Xilinx Vivado
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
Port ( clk 					: in std_logic;
	   I_RF_M_data 			: in std_logic_vector (15 downto 0);	-- data from BRAM into datapath
	   I_RF_IR_data 		: in std_logic_vector (7 downto 0);		-- Bottom 8 bits from the instruction register (for load constant)
	   I_RF_Wreg_addr 		: in std_logic_vector (3 downto 0);		-- Address of register to be written to (Wreg)
	   I_RF_Wreg_wr 		: in std_logic;							-- write enable for write register (Wreg)
	   I_RF_Wreg_sel 		: in std_logic_vector (1 downto 0);		-- Mux select for inputs to register file
	   I_RF_Preg_addr 		: in std_logic_vector (3 downto 0);		-- Address of primary read register (Preg)
	   I_RF_Preg_rd 		: in std_logic;							-- read enable for Preg
	   I_RF_Qreg_addr 		: in std_logic_vector (3 downto 0); 	-- Address of secondary read register (Qreg - only used for arithmetic functions)
	   I_RF_Qreg_rd 		: in std_logic; 						-- read enable for Qreg
	   I_ALU_sel 			: in std_logic_vector (1 downto 0); 	-- ALU MUX: 00=>Preg pass through, 01=>Preg+Qreg, 10=>Preg-Qreg
	   I_reg_sel			: in std_logic_vector (3 downto 0);		-- Select which register to display
	   Q_M_data				: out std_logic_vector (15 downto 0);	-- data from datapath into BRAM 
	   Q_RF_Preg_isZero 	: out std_logic;						-- flag indicating Preg is zero (used for jump if zero)
	   Q_M_addr				: out std_logic_vector (7 downto 0); 	-- Memory address for inderect access
	   Q_reg_out			: out std_logic_vector (15 downto 0)	-- register output for displaying
	   );
end Datapath;

architecture Behavioral of Datapath is

	-- Structure for register file
	type Register_File is array(0 to 15) of std_logic_vector(15 downto 0);
		signal L_RF_Register	: Register_File := (others => (others => '0'));
	
	
	signal L_RF_Preg_data	: unsigned(15 downto 0) := x"0000";
	signal L_RF_Qreg_data	: unsigned(15 downto 0) := x"0000";
	signal L_ALU_data		: unsigned(15 downto 0) := x"0000";
	signal L_RF_Wreg_data	: std_logic_vector(15 downto 0) := x"0000";
	
begin

--Select register to display
Q_reg_out <= L_RF_Register(to_integer(unsigned(I_reg_sel)));

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
Q_M_addr <= std_logic_vector(L_RF_Qreg_data(7 downto 0));

end Behavioral;
