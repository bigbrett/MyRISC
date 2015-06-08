----------------------------------------------------------------------------------
-- Company: 			Engs 31 14X
-- Engineer: 			E.W. Hansen
-- 
-- Create Date:    	12:55:02 07/19/2008 
-- Design Name: 		Lab 5
-- Module Name:    	SerialTx - Behavioral 
-- Project Name: 		RS232
-- Target Devices: 	Spartan 6 / Nexys 3
-- Tool versions: 	Foundation ISE 14.4
-- Description: 		Serial asynchronous transmitter for Pmod RS-232 port
--
-- Revision: 
-- Revision 0.01 - File Created
-- 	Rev (EWH) 7.17.2014, no external baud rate generator
-- Additional Comments: 
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity SerialTx is
    Port ( clk : in  STD_LOGIC;
           tx_data : in  STD_LOGIC_VECTOR (7 downto 0);
           tx_start : in  STD_LOGIC;
           tx : out  STD_LOGIC;					-- to Nexys 2 RS-232 port
           tx_done_tick : out  STD_LOGIC);
end SerialTx;

architecture Behavioral of SerialTx is
	constant CLOCK_FREQUENCY : integer := 100000000;		
	constant BAUD_RATE : integer := 115200;
	constant BAUD_COUNT : integer := CLOCK_FREQUENCY / BAUD_RATE;
	constant TICK_CTR_WIDTH : integer := integer(CEIL(LOG2(real(BAUD_COUNT))));
	
	signal br_cnt:		unsigned(TICK_CTR_WIDTH-1 downto 0) := (others=>'0');	-- baud rate counter
																		-- 12 bits can handle 4800 baud at 10 MHz clock
	signal br_tick:    std_logic;
	signal tx_reg:     std_logic_vector(9 downto 0) := "1111111111";   -- 1 start bit, 8 data bits, 1 stop bit, no parity
	signal tx_ctr:     unsigned(3 downto 0);				-- count the bits that have been sent
	signal tx_load, tx_shift : std_logic;					-- register control bits
	signal tx_empty:   std_logic;						    -- register status bit
	type state_type is (sidle, ssync, sload, sshift, sdone, swait);	-- state machine
	signal curr_state, next_state: state_type;
begin

BaudRateClock:
process(Clk)
begin
	if rising_edge(Clk) then
		if br_cnt = BAUD_COUNT-1 then
			br_cnt <= (others=>'0');
			br_tick <= '1';
		else
			br_cnt <= br_cnt+1;
			br_tick <= '0';
		end if;
	end if;
end process BaudRateClock;

DataRegister:
process( Clk )
begin
	if rising_edge( Clk ) then
		if (tx_load = '1') then
			tx_reg <= '1' & tx_data & '0';				-- load with stop & data & start
		elsif br_tick = '1' then							-- the register is always shifting
			tx_reg <= '1' & tx_reg(9 downto 1);			-- shift right														
		end if;														
	end if;
end process DataRegister;
tx <= tx_reg(0);												-- serial output port <= lsb

ShiftCounter:
process ( Clk )
begin
	if rising_edge( Clk ) then
		if (tx_load = '1') then					-- load counter with 10 when register is loaded
			tx_ctr <= x"A";		
		elsif br_tick = '1' then				-- count shifts (br_ticks) down to 0
			if (tx_shift = '1') then
				if tx_ctr > 0 then
					tx_ctr <= tx_ctr - 1;
				end if;
			end if;
		end if;
	end if;
end process ShiftCounter;
tx_empty <= '1' when tx_ctr = x"0" else '0';

TxControllerComb:
process ( tx_start, tx_empty, br_tick, curr_state )
begin
	-- defaults
	next_state <= curr_state;
	tx_load <= '0';  tx_shift <= '0'; tx_done_tick <= '0';
	-- next state and output logic
	case curr_state is
		when sidle => 
			if tx_start = '1' 						-- wait for start signal
				then next_state <= ssync;
			end if;
		when ssync =>									-- sync up with baud rate
			if br_tick = '1'
				then next_state <= sload;
			end if;
		when sload =>	tx_load <= '1';			-- load the data register
			next_state <= sshift;
		when sshift => tx_shift <= '1';			-- shift the bits out
			if tx_empty = '1' 						-- wait for shift counter
				then next_state <= sdone;
			end if;
		when sdone => tx_done_tick <= '1';		-- raise the done flag
			next_state <= swait;
		when swait => 									-- wait for start signal to drop
			if tx_start = '0' 
				then next_state <= sidle;
			end if;
		when others => next_state <= sidle;
	end case;
end process TxControllerComb;

TxControllerReg:
process ( Clk )
begin
	if rising_edge(Clk) then
			curr_state <= next_state;
	end if;
end process TxControllerReg;
		
end Behavioral;

