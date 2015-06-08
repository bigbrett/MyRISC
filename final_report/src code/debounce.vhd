LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.std_logic_unsigned.all;

ENTITY debounce IS

  PORT(
    clk     : IN  STD_LOGIC;  -- assumes 25Mhz clock
    button  : IN  STD_LOGIC;  -- input signal to be debounced
    db_out  : OUT STD_LOGIC); -- debounced signal out
END debounce;

ARCHITECTURE logic OF debounce IS
  constant NBITS : integer := 18;	-- change this if too fast or too slow
  SIGNAL flipflops   : STD_LOGIC_VECTOR(1 DOWNTO 0); --input flip flops (synchronizer)
  SIGNAL counter_set : STD_LOGIC;                    --sync reset to zero
  SIGNAL counter_out : STD_LOGIC_VECTOR(NBITS DOWNTO 0) := (OTHERS => '0'); 
     --counter size (19 bits gives approx 10ms delay with 25MHz clock)
BEGIN

DFS:  process(clk, flipflops)						-- double flop synchronizer
begin
	IF rising_edge(clk) THEN
      flipflops <= button & flipflops(1); 
    end if;
  	counter_set <= flipflops(0) xor flipflops(1);   -- determine when to start/reset counter
end process DFS;

-- Wait until the input has been stable (synchronizer holds "00" or "11" for 
-- about 10 msec
DBtimer:  PROCESS(clk)
BEGIN
	IF rising_edge(clk) THEN
		If(counter_set = '1') THEN      -- reset counter because input is still bouncing
        	counter_out <= (OTHERS => '0');
--      	ELSIF(counter_out(1) = '0') THEN       -- use for simulation only
      ELSIF(counter_out(NBITS) = '0') THEN   -- use for implementation
        	counter_out <= counter_out + 1;
      	ELSE                                   --stable input time is met
        	db_out <= flipflops(1);
      	END IF;    
	END IF;
END PROCESS DBtimer;

END logic;
