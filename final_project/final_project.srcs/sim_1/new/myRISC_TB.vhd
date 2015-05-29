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
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity myRISC_TB is
--  Port ( );
end myRISC_TB;

architecture Behavioral of myRISC_TB is

component myRISC is
	PORT( clk: in STD_LOGIC );
end component;

signal clk: std_logic := '0';
constant clk_period  : time := 10ns;		-- 100 MHz

begin

uut: myRISC 
	Port Map (clk => clk);
	

-- Clock process definitions
clk_process: process
begin
	clk <= '0';
	wait for clk_period/2;
	clk <= '1';
	wait for clk_period/2;
end process;

end Behavioral;
