----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 06/06/2015 05:54:06 PM
-- Design Name: 
-- Module Name: errorgen - Behavioral
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
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity errorgen is
    Port ( clk : in std_logic;
           I_error_start : in std_logic;
           I_tx_done_tick : in std_logic;
           Q_tx_start : out std_logic;
           Q_tx_data : out std_logic_vector (7 downto 0));
end errorgen;

architecture Behavioral of errorgen is

	type string_type is array(0 to 5) of std_logic_vector(7 downto 0);
	signal L_string : string_type;

	type state_type is (sIDLE, sSTART, sWAIT, sCOUNT);
	signal current_state, next_state : state_type := sIDLE;
	
	--Counter signals
	signal L_count			: integer range 0 to 5;
	signal L_counter_inc	: std_logic := '0';
	signal L_counter_clr	: std_logic := '0';
	signal L_counter_full	: std_logic := '0';

begin

--String Declarations
L_string(0) <= x"45";
L_string(1) <= x"52";
L_string(2) <= x"52";
L_string(3) <= x"4f";
L_string(4) <= x"52";
L_string(5) <= x"0d";

--Output Assignment
Q_tx_data <= L_string(L_count);

Counter: process(clk)
begin
	if rising_edge(clk) then
		if (L_counter_clr = '1') then
			L_count <= 0;
		elsif (L_counter_inc = '1') then
			L_count <= L_count + 1;
		end if;
	end if;
end process;
L_counter_full <= '1' when (L_count = 5) else '0';


StateUpdate: process(clk)
begin
	if rising_edge(clk) then
		current_state <= next_state;
	end if;
end process;

StateMachine: process(current_state, I_error_start, I_tx_done_tick, L_counter_full)
begin

	next_state <= current_state;
	Q_tx_start <= '0';
	L_counter_inc <= '0';
	L_counter_clr <= '0';
	
	case current_state is
		
		when sIDLE =>
			L_counter_clr <= '1';
			if I_error_start = '1' then
				next_state <= sSTART;
			end if;
		
		when sSTART =>
			Q_tx_start <= '1';
			next_state <= sWAIT;
			
		when sWAIT =>
			if (I_tx_done_tick = '1') then
				if (L_counter_full = '1') then
					next_state <= sIDLE;
				else	
					next_state <= sCOUNT;
				end if;
			end if;
			
		when sCOUNT =>
			L_counter_inc <= '1';
			next_state <= sSTART;
		
		when others =>
			next_state <= sIDLE;
		
	end case;
end process;


end Behavioral;
