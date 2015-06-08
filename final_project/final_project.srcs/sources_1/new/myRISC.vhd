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
Port (	clk 			: in std_logic;						-- clock in 
		I_RsRx 			: in std_logic;						-- serial data in 
		I_progmode_sel 	: in std_logic;    					-- select between program and execute modes
		I_button		: in std_logic;						-- button to step through commands
		I_display_sel	: in std_logic;						-- select wether to display PC or registers
		I_reg_sel		: in std_logic_vector(3 downto 0);	-- select which register to display
		Q_RsTx			: out std_logic;					-- serial data out
		Q_segments		: out std_logic_vector(0 to 6);		-- segments for display
		Q_anodes		: out std_logic_vector(3 downto 0)	-- anodes for display
		);
end myRISC;


architecture Behavioral of myRISC is 

-- Control Unit contains FSM controller for fetch,decode/load/execute/store operations
-- as well as the Program Counter (PC), Instruction Register (IR) and necessary switching logic
component ControlUnit is
Port ( clk 					: in std_logic;
	   I_instROM_data 		: in std_logic_vector (15 downto 0);	-- instruction from ROM memory 
	   I_RF_Preg_isZero 	: in std_logic;							-- flag indicating Preg is zero (used for jump if zero) 
	   I_program_en			: in std_logic; 						-- Enables programming mode (no program execution during this time)
	   I_button				: in std_logic;							-- button to step through commands 
	   I_PC_limit			: in std_logic_vector (7 downto 0);		-- Maximum step to execute
	   Q_instROM_addr 		: out std_logic_vector (15 downto 0);	-- ROM address from which to receive instructions
	   Q_instROM_rd 		: out std_logic;						-- ROM read enable signal to aquire instruction
	   Q_M_addr 			: out std_logic_vector (7 downto 0);	-- BRAM address  
	   Q_M_addr_sel			: out std_logic_vector (1 downto 0);	-- Select between direct and indirect memory access
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
end component;
	signal C_instROM_addr 	: std_logic_vector (15 downto 0);	-- ROM address from which to receive instructions
	signal C_instROM_rd 	: std_logic;						-- ROM read enable signal to aquire instruction
	signal C_M_addr 		: std_logic_vector (7 downto 0);	-- BRAM address  
	signal C_M_addr_sel		: std_logic_vector (1 downto 0);	-- Select between direct and indirect memory access
	signal C_M_wr 			: std_logic;						-- BRAM write enable
	signal C_RF_IR_data 	: std_logic_vector (7 downto 0);	-- Bottom 8 bits from the instruction register (for load constant)
	signal C_RF_Wreg_sel 	: std_logic_vector (1 downto 0);	-- Mux select for inputs to register file
	signal C_RF_Wreg_addr 	: std_logic_vector (3 downto 0);	-- Address of register to be written to (Wreg)
	signal C_RF_Wreg_wr 	: std_logic;						-- write enable for write register (Wreg)
	signal C_RF_Preg_addr 	: std_logic_vector (3 downto 0);	-- Address of primary read register (Preg)
	signal C_RF_Preg_rd 	: std_logic;						-- read enable for Preg
	signal C_RF_Qreg_addr 	: std_logic_vector (3 downto 0);	-- Address of secondary read register (Qreg - only used for arithmetic functions)
	signal C_RF_Qreg_rd 	: std_logic;						-- read enable for Qreg
	signal C_ALU_sel 		: std_logic_vector (1 downto 0);	-- ALU MUX: 00=>Preg pass through, 01=>Preg+Qreg, 10=>Preg-Qreg
	signal C_SP_addr		: std_logic_vector (7 downto 0);	-- Stack Pointer address for memory
	signal C_PC_count		: std_logic_vector (15 downto 0);	-- Push the program count out to display


-- Datapath contains data input MUX, MIPS, 16x1 Register File (RF), and ALU 
component Datapath is
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
	   Q_M_addr				: out std_logic_vector (7 downto 0);	-- Memory address for inderect access
	   Q_reg_out			: out std_logic_vector (15 downto 0)	-- register output for displaying
	   );
end component;
	signal D_RF_Preg_isZero : std_logic;						-- flag indicating Preg is zero (used for jump if zero)
	signal D_M_data			: std_logic_vector (15 downto 0); 	-- data from datapath into BRAM 
	signal D_M_addr			: std_logic_vector (7 downto 0);	-- Memory address for inderect access
	signal D_reg_out		: std_logic_vector (15 downto 0);	-- Register output for displaying



---- Single-port ROM holds hard-coded instructions 
--component instruction_ROM IS
--port (	clka 	: IN std_logic;
--		ena 	: IN std_logic;
--		addra 	: IN std_logic_vector(15 downto 0);
--		douta 	: OUT std_logic_vector(15 downto 0)	);
--end component;
	signal X_instROM_data 	: std_logic_vector (15 downto 0);	-- instruction from ROM memory 


-- Instruction RAM for programmable processor instructions	
-- Single-Port read/write BRAM, with read priority 
COMPONENT instruction_BRAM
  PORT (
    clka 	: IN std_logic;
    wea 	: IN std_logic_vector(0 downto 0);
    addra 	: IN std_logic_vector(7 downto 0);
    dina 	: IN std_logic_vector(15 downto 0);
    douta 	: OUT std_logic_vector(15 downto 0)
  );
END COMPONENT;


-- Multipuropose single-port read/write BRAM, with read priority  
-- Read/write operations have a 2 clock cycle latency
component BRAM
port (	clka 	: in std_logic;							-- master clock
    	ena 	: IN std_logic; 						-- clock enable
		wea 	: in std_logic_vector(0 downto 0);		-- write enable
		addra 	: in std_logic_vector(7 downto 0);		-- read/write address
		dina 	: in std_logic_vector(15 downto 0);		-- write data in
		douta 	: out std_logic_vector(15 downto 0) );	-- read data 
end component;
	signal M_RF_M_data		: std_logic_vector (15 downto 0); 	-- data from BRAM into datapath	
	
	
-- Serial Receiver to program XRAM over USART
component SerialRx
port (	clk 				: in std_logic;
		RsRx 				: in std_logic;         
		Q_rx_data 			: out std_logic_vector(7 downto 0);
		Q_rx_done_tick 		: out std_logic  );
end component;
	signal R_RX_data		: std_logic_vector (7 downto 0) := x"00";
	signal R_RX_done_tick 	: std_logic := '0';

-- Serial Transmitter	
component SerialTx is
Port ( 	clk 				: in  std_logic;
	   	tx_data 			: in  std_logic_vector (7 downto 0);
	   	tx_start 			: in  std_logic;
	   	tx 					: out  std_logic;					-- to Nexys 2 RS-232 port
	   	tx_done_tick 		: out  std_logic);
end component;
	signal T_tx_done_tick	: std_logic := '0';		-- Transmitter done tick
	

-- Instruction buffer : Buffers received characters until carriage return, then converts
-- the received word into a 16-bit instruction and stores the word in instruction memory  	
component InstructionBuffer is
Port (	clk 				: in std_logic;
		I_RX_done_tick		: in std_logic;							-- SPI conversion done tick 
		I_RX_data 			: in std_logic_vector (7 downto 0);		-- SPI parallel data
		I_program_en		: in std_logic; 						-- Enables programming mode (no program execution during this time)
		Q_instruction_word 	: out std_logic_vector (15 downto 0);	-- 16-bit instruction to be stored in XRAM 
		Q_X_addr 			: out std_logic_vector (7 downto 0);	-- XRAM write address
		Q_X_wr_en 			: out std_logic;						-- XRAM write enable
--		Q_X_busy 			: out std_logic;						-- Instruction programming in progress flag
		Q_error_start		: out std_logic							-- start the error sequence
		);
end component;	
	signal B_instruction_word 	: std_logic_vector (15 downto 0) := x"0000";	-- 16-bit instruction to be stored in XRAM 
	signal B_X_addr 			: std_logic_vector (7 downto 0) := x"00";		-- XRAM write address
	signal B_X_wr_en 			: std_logic := '0';								-- XRAM write enable
	signal B_X_busy 			: std_logic := '0';								-- Instruction programming in progress flag
	signal B_error_start		: std_logic := '0';	
	
component debounce IS
PORT(	clk     : IN  std_logic;  -- assumes 25Mhz clock (MIGHT NEED TO CHANGE)
	    button  : IN  std_logic;  -- input signal to be debounced
	    db_out  : OUT std_logic); -- debounced signal out
END component;
	signal L_button_db		: std_logic := '0';		-- debounced button
	
component Monopulse is
Port (	clk 		: in std_logic;
	    button 		: in std_logic;
	    mono_out 	: out std_logic
	    );
end component;
	signal L_button_mono	: std_logic := '0';		-- monopulsed and debounced button
	
component mux7seg is
Port ( clk 				: in  std_logic;
	   y0, y1, y2, y3 	: in  std_logic_vector (3 downto 0);	-- digits
	   seg 				: out  std_logic_vector(0 to 6);		-- segments (a...g)
	   an 				: out  std_logic_vector (3 downto 0) );	-- anodes
end component;
	signal L_display	: std_logic_vector (15 downto 0) := x"0000";	-- post-mux display vector
	
component errorgen is
Port ( clk 					: in std_logic;
	   I_error_start 		: in std_logic;
	   I_tx_done_tick 		: in std_logic;
	   Q_tx_start 			: out std_logic;
	   Q_tx_data 			: out std_logic_vector (7 downto 0)
	   );
end component;
	signal E_tx_start		: std_logic := '0';
	signal E_tx_data		: std_logic_vector(7 downto 0) := x"00";

-- ADDRESS MUXes
	signal L_M_addr			: std_logic_vector (7 downto 0) := x"00";	-- Memory address mux
	signal L_X_addr			: std_logic_vector (7 downto 0) := x"00";	-- Instruction Memory address mux
	
	
BEGIN  -------------------------------------------------------------------------------------------------------------------------------------


-- Memory address MUX
-- switches between direct address, indirect address (within register), 
-- and the address held in the stack pointer. 
with C_M_addr_sel select
	L_M_addr <=	C_M_addr when "00",
				D_M_addr when "01",
				C_SP_addr when "10",
				x"00" when others;


-- Instruction Memory address MUX
-- switches between address from controller (execute mode)
-- and address from buffer (programmable mode)
with I_progmode_sel select
	L_X_addr <=	C_instROM_addr(7 downto 0) when '0',	-- address from controller (PC: execute mode)
				B_X_addr when '1',  					-- address from buffer (programming mode)
				x"00" when others;
				
-- Display Mux Process
DisplayMux: process(I_display_sel, I_progmode_sel, B_X_addr, D_reg_out, C_PC_count)
begin
	if (I_progmode_sel = '1') then
		L_display <= x"00" & B_X_addr;
	elsif (I_display_sel = '1') then
		L_display <= D_reg_out;
	else
		L_display <= C_PC_count;
	end if;
end process;


ControlUnit_C: ControlUnit
Port map(	clk => clk,
			I_instROM_data => X_instROM_data,		-- instruction from ROM memory 
			I_RF_Preg_isZero => D_RF_Preg_isZero,	-- flag indicating Preg is zero (used for jump if zero)
			I_program_en => I_progmode_sel,			-- Enables programming mode (no program execution during this time)
			I_button => L_button_mono,				-- button for stepping through instructions
			I_PC_limit => B_X_addr,					-- Maximum step to execute
			Q_instROM_addr => C_instROM_addr,		-- ROM address from which to receive instructions
			Q_instROM_rd => C_instROM_rd,			-- ROM read enable signal to aquire instruction
			Q_M_addr => C_M_addr,					-- BRAM address  
			Q_M_addr_sel => C_M_addr_sel,			-- Select between direct and indirect memory access
			Q_M_wr => C_M_wr,						-- BRAM write enable
			Q_RF_IR_data => C_RF_IR_data,			-- Bottom 8 bits from the instruction register (for load constant)
			Q_RF_Wreg_sel => C_RF_Wreg_sel,			-- Mux select for inputs to register file
			Q_RF_Wreg_addr => C_RF_Wreg_addr,		-- Address of register to be written to (Wreg)
			Q_RF_Wreg_wr => C_RF_Wreg_wr,			-- write enable for write register (Wreg)
			Q_RF_Preg_addr => C_RF_Preg_addr,		-- Address of primary read register (Preg)
			Q_RF_Preg_rd => C_RF_Preg_rd,			-- read enable for Preg
			Q_RF_Qreg_addr => C_RF_Qreg_addr,		-- Address of secondary read register (Qreg - only used for arithmetic functions)
			Q_RF_Qreg_rd => C_RF_Qreg_rd,			-- read enable for Qreg
			Q_ALU_sel => C_ALU_sel,					-- ALU MUX: 00=>Preg pass through, 01=>Preg+Qreg, 10=>Preg-Qreg
			Q_SP_addr => C_SP_addr,					-- Stack Pointer address for memory
			Q_PC_count => C_PC_count				-- Push the program count out to display
			);


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
			I_reg_sel => I_reg_sel,					-- Select which register to display
			Q_M_data => D_M_data,					-- data from datapath into BRAM 
			Q_RF_Preg_isZero => D_RF_Preg_isZero,	-- flag indicating Preg is zero (used for jump if zero)
			Q_M_addr => D_M_addr,					-- Memory address for inderect access
			Q_reg_out => D_reg_out					-- register output for displaying
			);    


--instruction_ROM_X: instruction_ROM
--Port Map (	clka => clk,
--			ena => C_instROM_rd,
--			addra => C_instROM_addr,		-- ROM address from which to receive instructions
--			douta => open--X_instROM_data  		-- instruction from ROM memory into controller
--			);


Instruction_BRAM_X: instruction_BRAM
PORT MAP (	clka => clk,
			wea(0) => B_X_wr_en,
			addra => L_X_addr,
			dina => B_instruction_word,
			douta => X_instROM_data
			);


BRAM_M: BRAM
Port Map (	clka => clk,						-- Port A (write port) clock 
			ena => '1', 						-- clock enable
			wea(0) => C_M_wr,					-- write enable (read if low, write if high)
			addra => L_M_addr,					-- read/write address
			dina => D_M_data,					-- write data: data from datapath into BRAM 
			douta => M_RF_M_data  				-- read data: from BRAM to Datapath
			);


SerialRx_R: SerialRx 
Port Map (	clk => clk,
			RsRx => I_RsRx,
			Q_rx_data => R_RX_data,
			Q_rx_done_tick => R_RX_done_tick  
			);
			
SerialTx_T: SerialTx
Port Map (	clk => clk,
			tx_data => E_tx_data,
			tx_start => E_tx_start,
			tx => Q_RsTx,					-- to Nexys 2 RS-232 port
			tx_done_tick => T_tx_done_tick
			);

Error_Generator_E: errorgen
Port Map ( 	clk => clk,
			I_error_start => B_error_start,
			I_tx_done_tick => T_tx_done_tick,
			Q_tx_start => E_tx_start,
			Q_tx_data => E_tx_data
			);

InstructionBuffer_B: InstructionBuffer
Port Map (	clk => clk, 				
			I_RX_done_tick => R_RX_done_tick,			-- SPI conversion done tick 
			I_RX_data => R_rx_data,						-- SPI parallel data
			I_program_en => I_progmode_sel,				-- Enables programming mode (no program execution during this time)
			Q_instruction_word => B_instruction_word,	-- 16-bit instruction to be stored in XRAM 
			Q_X_addr => B_X_addr, 						-- XRAM write address (also PC limit)
			Q_X_wr_en => B_X_wr_en,						-- XRAM write enable
--			Q_X_busy => B_X_busy,  						-- Instruction programming in progress flag
			Q_error_start => B_error_start				-- start the error sequence
			);
			
Debouncer: debounce
Port Map (	clk => clk,
			button => I_button,
			db_out => L_button_db
			);
			
Monopulser: monopulse
Port Map (	clk => clk,
			button => L_button_db,
			mono_out => L_button_mono
			);
			
Display: mux7seg
Port Map (	clk => clk,
	   		y0 => L_display(3 downto 0), 
	   		y1 => L_display(7 downto 4),
	   		y2 => L_display(11 downto 8),
	   		y3 => L_display(15 downto 12),
	   		seg => Q_segments,
	   		an => Q_anodes
	   		);
			
end Behavioral;

