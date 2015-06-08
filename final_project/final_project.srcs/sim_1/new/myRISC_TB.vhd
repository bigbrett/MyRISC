----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 05/29/2015 03:13:47 PM
-- Design Name: 
-- Module Name: myRISC_TB - Behavioral
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

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity myRISC_TB is
--  Port ( );
end myRISC_TB;

architecture Behavioral of myRISC_TB is

component myRISC is
Port (	clk 			: in STD_LOGIC;						-- clock in 
		I_RsRx 			: in STD_LOGIC;						-- serial data in 
		I_progmode_sel 	: in STD_LOGIC;    					-- select between program and execute modes
		I_button		: in STD_LOGIC;						-- button to step through commands
		I_display_sel	: in STD_LOGIC;						-- select wether to display PC or registers
		I_reg_sel		: in STD_LOGIC_VECTOR(3 downto 0);	-- select which register to display
		Q_RsTx			: out STD_LOGIC;					-- serial data out
		Q_segments		: out STD_LOGIC_VECTOR(0 to 6);		-- segments for display
		Q_anodes		: out STD_LOGIC_VECTOR(3 downto 0)	-- anodes for display
		);
end component;

signal clk: std_logic := '0';
constant clk_period  : time := 10ns;		-- 100 MHz

signal TB_button: std_logic := '0';
signal Prog_sel : std_logic := '1';
signal RsRx : std_logic := '1';
constant INSTRUCTION_DEPTH : integer := 17;

type Inst_type is array(0 to INSTRUCTION_DEPTH-1) of std_logic_vector(39 downto 0);
constant Instruction : Inst_type :=
	(	x"343030310d",	--4001	LDC r0, #1
		x"333130300d",	--3100	MOV r1, r0
		x"323130310d",	--2101	STR r1, 1
		x"313230310d",	--1201	LDR r2, 1
		x"353332310d",	--5321	ADD r3, r2, r1
		x"363333310d",	--6331	SUB r3, r3, r1
		x"3661343964",	-- ERROR -> too many characters
		x"373330310d",	--7301	BZZ r3, 1
		x"383030350d",	--8005	BDD 5
		x"623031340d",	--b014	SIN r1, @r4
		x"613330330d",	--a404	LIN r4, @r4
		x"393030630d",	--900c	BLL	c
		x"383030660d",	--800f	BDD f
		x"633030310d",	--c001	PSH r0
		x"343030370d",	--4007	LDC r0, #7
		x"643030310d",	--d001	POP r0
		x"303030300d");	--0000	NOP
-- Data definitions
	constant bit_time : time := 8.68us;		-- 115,200 baud


begin

uut: myRISC 
	Port Map (	clk => clk,
				I_RsRx => RsRx,
				I_Progmode_sel => Prog_sel,
				I_button => TB_button,
				I_display_sel => '0',
				I_reg_sel => (others => '0'),
				Q_RsTx => open,
				Q_segments => open,
				Q_anodes => open
				);
	

-- Clock process definitions
clk_process: process
begin
	clk <= '0';
	wait for clk_period/2;
	clk <= '1';
	wait for clk_period/2;
end process;

button: process
begin
	TB_button <= NOT(TB_button);
	wait for clk_period*5;
end process;


-- Stimulus process
stim_proc: process
   begin		
		wait for 100 us;
		wait for 10.25*clk_period;
		
		--Loop through the instructions
		for instcount in 0 to INSTRUCTION_DEPTH-1 loop		
	
			-- Send the character stream from left to right	
			-- but send the bits within each char from right to left	
			for charcount in (Instruction(instcount)'length / 8)-1 downto 0 loop
				RsRx <= '0';		-- Start bit
				wait for bit_time;
			
				for bitcount in 0 to 7 loop
					RsRx <= Instruction(instcount)(charcount*8 + bitcount);
					wait for bit_time;
				end loop;
			
				RsRx <= '1';		-- Stop bit
				wait for 200 us;  -- Intercharacter spacing
			end loop;
			
			-- Repeat every millisecond
			wait for 1 ms;
		 
		end loop;

		wait for 2 ms;
		Prog_sel <= '0';
		
end process;

end Behavioral;