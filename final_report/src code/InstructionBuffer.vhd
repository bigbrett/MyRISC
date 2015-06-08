----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 06/02/2015 12:28:48 PM
-- Design Name: 
-- Module Name: InstructionBuffer - Behavioral
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
library UNISIM;
use UNISIM.VComponents.all;

entity InstructionBuffer is
Port (	clk 				: in std_logic;
		I_RX_done_tick		: in std_logic;							-- SPI conversion done tick 
		I_RX_data 			: in std_logic_vector (7 downto 0);		-- SPI parallel data
		I_program_en		: in std_logic; 						-- Enables programming mode (no program execution during this time)
		Q_instruction_word 	: out std_logic_vector (15 downto 0);	-- 16-bit instruction to be stored in XRAM 
		Q_X_addr 			: out std_logic_vector (7 downto 0);	-- XRAM write address
		Q_X_wr_en 			: out std_logic;						-- XRAM write enable
--		Q_X_busy 			: out std_logic;						-- Instruction programming in progress flag
		Q_error_start		: out std_logic							-- Start the error sequence
		);
end InstructionBuffer;

architecture Behavioral of InstructionBuffer is
	
-- converts 8-bit ascii code for 0->f to hex representation
function ascii2hex (a: std_logic_vector(7 downto 0)) return std_logic_vector is
	variable tmp: std_logic_vector(3 downto 0) := x"0";
begin
	case a is 
		when x"30" => tmp := x"0"; -- 0
		when x"31" => tmp := x"1";	-- 1
		when x"32" => tmp := x"2";	-- 2
		when x"33" => tmp := x"3"; -- 3
		when x"34" => tmp := x"4";	-- 4
		when x"35" => tmp := x"5";	-- 5
		when x"36" => tmp := x"6";	-- 6
		when x"37" => tmp := x"7";	-- 7
		when x"38" => tmp := x"8";	-- 8
		when x"39" => tmp := x"9";	-- 9
		when x"61" => tmp := x"a"; -- a
		when x"62" => tmp := x"b"; -- b
		when x"63" => tmp := x"c"; -- c
		when x"64" => tmp := x"d"; -- d
		when x"65" => tmp := x"e"; -- e
		when x"66" => tmp := x"f"; -- f
		when others => tmp := x"0";
	end case;
	return tmp;
end	ascii2hex;
	
	-- ASCII character constants 
	constant NUL			: std_logic_vector (7 downto 0) := x"00";
    constant CR				: std_logic_vector (7 downto 0) := x"0d";
    constant BS				: std_logic_vector (7 downto 0) := x"08";

    
	-- character buffer shift register file 
	constant iCHARBUF_DEPTH		: integer := 4; 		-- max = 16 characters deep 
    constant iCHARBUF_WIDTH		: integer := 8;			-- character = 8 bits
    type regfile_type is array(iCHARBUF_DEPTH-1 downto 0) of std_logic_vector(iCHARBUF_WIDTH-1 downto 0);
	signal L_charBuf			: regfile_type := (others => NUL); -- character buffer shift register file
    signal L_charBuf_shift_en	: std_logic := '0'; 	-- shift enable signal 
    signal L_charBuf_clr		: std_logic := '0'; 	-- Clear character buffer 
    signal L_charBuf_isFull		: std_logic := '0';		-- Character buffer is full 

	-- character buffer shift counter
    signal L_charBuf_shift_ctr 		: integer range 0 to 4 := 0; -- shift counter
    
    -- XRAM 
    constant iXRAM_ADDR_WIDTH	: integer := 8;  -- width of instruction RAM address
    constant iXRAM_DEPTH		: integer := 200; -- depth of instruction RAM 
    signal L_XRAM_wr_addr		: unsigned(iXRAM_ADDR_WIDTH-1 downto 0) := (others=>'0'); -- 
    signal L_XRAM_wr_ctr_en		: std_logic := '0';
	signal L_XRAM_wr_ctr_clr	: std_logic := '0';

    -- input register
    signal L_rx_data_reg			: std_logic_vector (7 downto 0) := (others => '0'); 
--    signal L_rx_data_hex			: std_logic_vector (3 downto 0) := (others => '0');
    signal L_CR_detected			: std_logic := '0'; 	 	-- input character = carriage return
    signal L_BS_detected			: std_logic := '0';			-- input character = backspace
    signal L_rx_data_ready			: std_logic := '0'; 	 	-- input data is ready 
	
	signal L_inst_reg_en			: std_logic := '0';
	


    -- FSM state types 
    type state_type is (sIDLE, sWAIT, sSHIFT, sWRITE, sWRITE2, sERROR, sSETUP);
    signal current_state, next_state: state_type;
-------------------------------------------------------------------------------------------------------------------------
-- Command  |  Opcode  |  Definition  	 |  Operation				|   Expected String		|  		Parsing State   	| 
-- ---------|----------|-----------------|-------------------------------------------------------------------------------
--   NOP	|   0000   |  No operation	 |                          |  NOP	X X X    		|	sEXPECT_ARGS_X_X_X
--   LDR	|   0001   |  Load Direct    | Ra <= M[d]               |  LDR <Ra> <   d   >   |	sEXPECT_ARGS_RA_D
--   STR    |   0010   |  Store Direct   | M[d] <= Ra               |  STR <Ra> <   d   >   |	sEXPECT_ARGS_RA_D
--   MOV    |   0011   |  Move 			 | Ra <= Rb                 |  MOV <Ra> <Rb> X      | 	sEXPECT_ARGS_RA_RB_X
--   LDC    |   0100   |  Load Constant  | Ra <= d                  |  LDC <Ra> <   d   >   | 	sEXPECT_ARGS_RA_D
--   ADD    |   0101   |  Add 			 | Ra <= Rb + Rc            |  ADD <Ra> <Rb> <Rc>   | 	sEXPECT_ARGS_RA_RB_RC
--   SUB    |   0110   |  Subtract 		 | Ra <= Rb - Rc            |  SUB <Ra> <Rb> <Rc>   | 	sEXPECT_ARGS_RA_RB_RC
--   BZ     |   0111   |  Jump if Zero   | if(Ra=0) then Pc<=Pc+d+  |  BZ  X X <Ra>         |	sEXPECT_ARGS_X_X_RA
--   BD     |   1000   |  Jump Direct 	 | Pc <= d                  |  BD  X X <Ra>         |	sEXPECT_ARGS_X_X_RA
--	 BL 	|   1001   |  Branch w link  | LR <= PC and PC <= d     |  BL  X X <Ra>         |	sEXPECT_ARGS_X_X_RA
--	 LIN    |   1010   |  Load Indirect  | Ra <= M[Rc]              |  LIN <Ra> X <Rc>      |	sEXPECT_ARGS_RA_X_RC
--	 SIN	|   1011   |  Store Indirect | M[Rc] <= Rb              |  SIN <Ra> <Rb> <Rc>   |	sEXPECT_ARGS_RA_RB_RC
--   PSH    |   1100   |  Push Registers |                          |  PSH < 12-bits >      |	sEXPECT_ARGS_12CHAR
--   POP    |   1101   |  Pop Registers  |                          |  POP < 12-bits >      |	sEXPECT_ARGS_12CHAR
-------------------------------------------------------------------------------------------------------------------------
--  16-bit instruction format: x"XXXX"
-- 	<Opcode> <Ra> <Rb> <Rc>
-- 	<Opcode> <Ra> <   d   >
--	<Opcode> <  Registers  >    
-------------------------------------------------------------------
begin

-- Register input character on RX_done_tick 
input_reg: process(clk)
begin
	if rising_edge(clk) then 
		if (I_rx_done_tick = '1') then 
			L_rx_data_reg <= I_rx_data;
			L_rx_data_ready <= '1'; -- data ready flag
		else
			L_rx_data_ready <= '0'; -- data not ready
		end if; 
	end if;
end process; 
L_CR_detected <= '1' when L_rx_data_reg = CR else '0'; -- Async watchdog to detect CR
L_BS_detected <= '1' when L_rx_data_reg = BS else '0'; -- Async watchdog to detect CR 


-- Shifts characters into the char buffer on the enable signal. Also contains shift counter
shift_reg: process(clk, L_charBuf_shift_en, L_charBuf_clr)
begin
	if rising_edge(clk) then
        if (L_charBuf_clr = '1') then 
			L_charBuf <= (others => NUL); -- clear char buffer 
			L_charBuf_shift_ctr <= 0; 	  -- clear shift counter
		elsif (L_charBuf_shift_en = '1') then 
			L_charBuf(L_charBuf_shift_ctr) <= L_rx_data_reg; -- shift in character 
			L_charBuf_shift_ctr <= L_charBuf_shift_ctr + 1; -- Shift count ++ 
		end if; 
    end if;
end process;
L_charBuf_isFull <= '1' when L_charBuf_shift_ctr = 4 else '0'; -- ASYNC watchdog for full character buffer 


output_reg: process(clk, L_inst_reg_en)
begin
	if rising_edge(clk) then 
		if(L_inst_reg_en = '1') then 
			Q_instruction_word <= ascii2hex(L_charBuf(0)) & ascii2hex(L_charBuf(1)) & ascii2hex(L_charBuf(2)) & ascii2hex(L_charBuf(3));
		end if;
	end if; 
end process; 

-- Counter for XRAM write address 
write_counter: process(clk, L_XRAM_wr_ctr_clr, L_XRAM_wr_ctr_en)
begin
    if rising_edge(clk) then
        if (L_XRAM_wr_ctr_clr = '1') then
            L_XRAM_wr_addr <= to_unsigned(0, L_XRAM_wr_addr'length);
        elsif (L_XRAM_wr_ctr_en = '1') then
            L_XRAM_wr_addr <= L_XRAM_wr_addr + 1;
        end if;
    end if;
end process;
Q_X_addr <= std_logic_vector(L_XRAM_wr_addr);


-----------------------------------------------------------------
---------------------- FSM CONTROLLER ---------------------------
-----------------------------------------------------------------
StateUpdate: process(clk)
begin
	if rising_edge(clk) then
		current_state <= next_state;
	end if;
end process;


StateMachine: process(current_state, L_rx_data_ready, L_CR_detected, I_program_en, L_BS_detected, L_charBuf_isFull)
begin
    -- Defaults
    L_XRAM_wr_ctr_clr <= '0';
    L_XRAM_wr_ctr_en <= '0';
    L_charBuf_shift_en <= '0';
    L_charBuf_clr <= '0';
    L_inst_reg_en <= '0';
    Q_X_wr_en <= '0';
    Q_error_start <= '0';
	next_state <= current_state;

    case current_state is 
    	-- idle until set into programming mode
    	when sIDLE =>  
			L_charBuf_clr <= '1';
    		if (I_program_en = '1') then 
    			next_state <= sSETUP;
    		end if; 
    		
    	-- Clear the XRAM write address
    	when sSETUP =>
    		 L_XRAM_wr_ctr_clr <= '1';
    		 next_state <= sWAIT;
    		
    	-- wait for new character on rx_done_tick	
    	when sWAIT =>
    		if (I_program_en = '0') then -- go to idle b/c execute mode begins
    			next_state <= sIDLE; 
			elsif (L_rx_data_ready = '1') then
				if (L_BS_detected = '1') then
					next_state <= sERROR;
				elsif (L_CR_detected = '1') then
					if (L_charBuf_isFull = '1') then
						next_state <= sWRITE;
					else
						next_state <= sERROR;
					end if;
				elsif (L_charBuf_isFull = '1') then
					next_state <= sERROR;
				else 
					next_state <= sSHIFT;
				end if;
			end if; 
			 
		-- Shift received character into register file	 
    	when sSHIFT => 
			L_charBuf_shift_en <= '1';		
			next_state <= sWAIT;
			
		-- register instruction in output register	
		when sWRITE => 
			L_inst_reg_en <= '1'; -- register instruction 
			L_charBuf_clr <= '1'; -- clear character buffer now that command has been 
			next_state <= sWRITE2; 
		
		-- write contents of output register to XRAM
		when sWRITE2 => 
			Q_X_wr_en <= '1'; -- write output register to memory 
			L_XRAM_wr_ctr_en <= '1'; -- increment write counter
			next_state <= sWAIT; 
			
		when sERROR =>
			Q_error_start <= '1';
			L_charBuf_clr <= '1';
			next_state <= sWAIT;
			
		when others => 
			next_state <= sWAIT;
			
    end case; 
end process; 


end Behavioral;
