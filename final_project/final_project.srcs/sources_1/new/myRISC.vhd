----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 05/27/2015 03:43:05 PM
-- Design Name: 
-- Module Name: myRISC - Behavioral
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
library UNISIM;
	use UNISIM.VComponents.all;

entity myRISC is
    Port ( clk : in STD_LOGIC);
end myRISC;

architecture Behavioral of myRISC is

-- Control Unit contains FSM controller for fetch,decode/load/execute/store operations
-- as well as the Program Counter (PC), Instruction Register (IR) and necessary switching logic
component ControlUnit is
Port ( clk 					: in STD_LOGIC;
	   I_instROM_data 		: in STD_LOGIC_VECTOR (15 downto 0);	-- instruction from ROM memory 
	   I_RF_Preg_isZero 	: in STD_LOGIC;							-- flag indicating Preg is zero (used for jump if zero) 
	   Q_instROM_addr 		: out STD_LOGIC_VECTOR (15 downto 0);	-- ROM address from which to receive instructions
	   Q_instROM_rd 		: out STD_LOGIC;						-- ROM read enable signal to aquire instruction
	   Q_M_addr 			: out STD_LOGIC_VECTOR (7 downto 0);	-- BRAM address  
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
end component;
	-- signals driven by control unit (C)  
	signal C_instROM_addr 	: STD_LOGIC_VECTOR (15 downto 0);	-- ROM address from which to receive instructions
	signal C_instROM_rd 	: STD_LOGIC;						-- ROM read enable signal to aquire instruction
	signal C_M_addr 		: STD_LOGIC_VECTOR (7 downto 0);	-- BRAM address  
--	signal C_M_rd 			: STD_LOGIC;						-- BRAM read enable
	signal C_M_wr 			: STD_LOGIC;						-- BRAM write enable
	signal C_RF_IR_data 	: STD_LOGIC_VECTOR (7 downto 0);	-- Bottom 8 bits from the instruction register (for load constant)
	signal C_RF_Wreg_sel 	: STD_LOGIC_VECTOR (1 downto 0);	-- Mux select for inputs to register file
	signal C_RF_Wreg_addr 	: STD_LOGIC_VECTOR (3 downto 0);	-- Address of register to be written to (Wreg)
	signal C_RF_Wreg_wr 	: STD_LOGIC;						-- write enable for write register (Wreg)
	signal C_RF_Preg_addr 	: STD_LOGIC_VECTOR (3 downto 0);	-- Address of primary read register (Preg)
	signal C_RF_Preg_rd 	: STD_LOGIC;						-- read enable for Preg
	signal C_RF_Qreg_addr 	: STD_LOGIC_VECTOR (3 downto 0);	-- Address of secondary read register (Qreg - only used for arithmetic functions)
	signal C_RF_Qreg_rd 	: STD_LOGIC;						-- read enable for Qreg
	signal C_ALU_sel 		: STD_LOGIC_VECTOR (1 downto 0);	-- ALU MUX: 00=>Preg pass through, 01=>Preg+Qreg, 10=>Preg-Qreg


-- Datapath contains data input MUX, MIPS, 16x1 Register File (RF), and ALU 
component Datapath is
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
end component;
-- Signals driven by Datapath (D)
	signal D_RF_Preg_isZero : STD_LOGIC;						-- flag indicating Preg is zero (used for jump if zero)
	signal D_M_data			: STD_LOGIC_VECTOR (15 downto 0); 	-- data from datapath into BRAM 


-- Single-port ROM holds hard-coded instructions 
component instruction_ROM IS
  PORT (
    clka : IN STD_LOGIC;
    ena : IN STD_LOGIC;
    addra : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
    douta : OUT STD_LOGIC_VECTOR(15 DOWNTO 0)
  );
end component;
-- Signals driven by instruction ROM (X)
	signal X_instROM_data 	: STD_LOGIC_VECTOR (15 downto 0);	-- instruction from ROM memory 
	

-- Multipuropose single-port read/write BRAM, with read priority  
-- Read/write operations have a 2 clock cycle latency
component BRAM
port (	clka 	: in STD_LOGIC;							-- master clock
    	ena 	: IN STD_LOGIC; 						-- clock enable
		wea 	: in STD_LOGIC_VECTOR(0 downto 0);		-- write enable
		addra 	: in STD_LOGIC_VECTOR(7 downto 0);		-- read/write address
		dina 	: in STD_LOGIC_VECTOR(15 downto 0);		-- write data in
		douta 	: out STD_LOGIC_VECTOR(15 downto 0)
	);	-- read data 
end component;
-- Signals driven by BRAM 
	signal M_RF_M_data		: STD_LOGIC_VECTOR (15 downto 0); 	-- data from BRAM into datapath	
	
	
begin

ControlUnit_C: ControlUnit
Port map(	clk => clk,
			I_instROM_data => X_instROM_data,		-- instruction from ROM memory 
			I_RF_Preg_isZero => D_RF_Preg_isZero,	-- flag indicating Preg is zero (used for jump if zero) 
			Q_instROM_addr => C_instROM_addr,		-- ROM address from which to receive instructions
			Q_instROM_rd => C_instROM_rd,			-- ROM read enable signal to aquire instruction
			Q_M_addr => C_M_addr,					-- BRAM address  
--			Q_M_rd => C_M_rd,						-- BRAM read enable
			Q_M_wr => C_M_wr,						-- BRAM write enable
			Q_RF_IR_data => C_RF_IR_data,			-- Bottom 8 bits from the instruction register (for load constant)
			Q_RF_Wreg_sel => C_RF_Wreg_sel,			-- Mux select for inputs to register file
			Q_RF_Wreg_addr => C_RF_Wreg_addr,		-- Address of register to be written to (Wreg)
			Q_RF_Wreg_wr => C_RF_Wreg_wr,			-- write enable for write register (Wreg)
			Q_RF_Preg_addr => C_RF_Preg_addr,		-- Address of primary read register (Preg)
			Q_RF_Preg_rd => C_RF_Preg_rd,			-- read enable for Preg
			Q_RF_Qreg_addr => C_RF_Qreg_addr,		-- Address of secondary read register (Qreg - only used for arithmetic functions)
			Q_RF_Qreg_rd => C_RF_Qreg_rd,			-- read enable for Qreg
			Q_ALU_sel => C_ALU_sel  );				-- ALU MUX: 00=>Preg pass through, 01=>Preg+Qreg, 10=>Preg-Qreg


Datapath_D: Datapath 
Port Map(	clk => clk,
			I_RF_M_data => M_RF_M_data,				-- data from BRAM into datapath	
			I_RF_IR_data => C_RF_IR_data,			-- Bottom 8 bits from the instruction register (for load constant)
			I_RF_Wreg_addr => C_RF_Wreg_addr,		-- Address of register to be written to (Wreg)
			I_RF_Wreg_wr => C_RF_Wreg_wr,			-- write enable for write register (Wreg)
			I_RF_Wreg_sel => C_RF_Wreg_sel,			-- Mux select for inputs to register file
			I_RF_Preg_addr => C_RF_Preg_addr,		-- Address of primary read register (Preg)
			I_RF_Preg_rd => C_RF_Preg_rd,			-- read enable for Preg
			I_RF_Qreg_addr => C_RF_Qreg_addr,		-- Address of secondary read register (Qreg - only used for arithmetic functions)
			I_RF_Qreg_rd => C_RF_Qreg_rd,			-- read enable for Qreg
			I_ALU_sel => C_ALU_sel,					-- ALU MUX: 00=>Preg pass through, 01=>Preg+Qreg, 10=>Preg-Qreg
			Q_M_data => D_M_data,					-- data from datapath into BRAM 
			Q_RF_Preg_isZero => D_RF_Preg_isZero );	-- flag indicating Preg is zero (used for jump if zero)    


instruction_ROM_X: instruction_ROM
Port Map (	clka => clk,
			ena => C_instROM_rd,
			addra => C_instROM_addr,		-- ROM address from which to receive instructions
			douta => X_instROM_data   );	-- instruction from ROM memory into controller


BRAM_M: BRAM
Port Map (	clka => clk,						-- Port A (write port) clock 
			ena => '1', 						-- clock enable
			wea(0) => C_M_wr,					-- write enable (read if low, write if high)
			addra => C_M_addr,					-- read/write address
			dina => D_M_data,					-- write data: data from datapath into BRAM 
			douta => M_RF_M_data  );			-- read data: from BRAM to Datapath


end Behavioral;

