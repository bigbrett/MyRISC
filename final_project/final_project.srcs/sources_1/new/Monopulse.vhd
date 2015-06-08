----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 06/06/2015 01:09:39 PM
-- Design Name: 
-- Module Name: Monopulse - Behavioral
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

entity Monopulse is
    Port ( clk : in std_logic;
           button : in std_logic;
           mono_out : out std_logic);
end Monopulse;

architecture Behavioral of Monopulse is

	signal old_button	: std_logic := '0';
	signal new_button	: std_logic := '0';

begin

Registers: process(clk)
begin
	if rising_edge(clk) then
		old_button <= new_button;
		new_button <= button;
	end if;
end process;

mono_out <= '1' when (new_button = '1') and (old_button = '0') else '0';


end Behavioral;