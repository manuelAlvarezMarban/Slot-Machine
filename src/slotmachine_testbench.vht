library ieee; 
use ieee.std_logic_1164.all;

ENTITY slotmachine_vhd_tst IS
END slotmachine_vhd_tst;

ARCHITECTURE tb OF slotmachine_vhd_tst IS
	--constants (include here vhd generics)
	constant PERIOD		: time 		:= 20 ns;
	constant g_m		: integer	:= 64 ;
	--signals (i_seed could be anything except all 0s)
    signal nReset			: std_logic;								
	signal clock			: std_logic := '0';								
	signal newCredit		: std_logic;								
	signal play				: std_logic;								
	signal credit			: std_logic_vector(9 downto 0);			
	signal pay				: std_logic;								
	signal slot_L			: std_logic_vector(3 downto 0);			
	signal slot_M			: std_logic_vector(3 downto 0);			
	signal slot_R			: std_logic_vector(3 downto 0);			
	signal endPlay			: std_logic;							
	signal prize			: std_logic_vector(9 downto 0);				
	--signal showPrizes		: in std_logic;							
	signal ejectCredit		: std_logic;																							
	signal endPay			: std_logic;																						
	signal configLevel		: std_logic_vector(15 downto 0);	
	--signal State			: std_logic_vector(2 downto 0);	  --Debug STATE

	COMPONENT slotMachine
        port (
			nReset			: in std_logic;
			clock			: in std_logic;								
			newCredit		: in std_logic;								
			play			: in std_logic;								
			credit			: out std_logic_vector(9 downto 0);			
			pay				: in std_logic;								
			slot_L			: out std_logic_vector(3 downto 0);			
			slot_M			: out std_logic_vector(3 downto 0);		
			slot_R			: out std_logic_vector(3 downto 0);			
			endPlay			: out std_logic;						
			prize			: out std_logic_vector(9 downto 0);			
			--showPrizes		: in std_logic;								
			ejectCredit		: out std_logic;							
			endPay			: out std_logic;	
			--State			: out std_logic_vector(2 downto 0);		 --Debug STATE
			configLevel		: out std_logic_vector(15 downto 0)		
		);
    END COMPONENT;
	
BEGIN

	dut : slotMachine
	PORT MAP (  --list connections between master ports and signals--
				nReset      => nReset,
				clock       => clock,
				newCredit 	=> newCredit,
				play   		=> play,
				pay         => pay,
				slot_L      => slot_L,
				slot_M      => slot_M,
				slot_R      => slot_R,
				endPlay     => endPlay,
				prize      	=> prize,
				--showPrizes => --showPrizes,
				ejectCredit => ejectCredit,
				endPay      => endPay,
				--State		=> State,					--Debug STATE
				configLevel => configLevel
			);
		
	init : PROCESS
	BEGIN
		-- start TestBench, reset SlotMachine --
		nReset <= '0';   
		play <=  '0';
		newCredit <=  '0';		
		wait for PERIOD;
		nReset <= '1'; 
		report "INITIAL SLOTS: " & to_string(slot_L) & "  " & to_string(slot_M) & "  " & to_string(slot_R);
		report "INITIAL PRIZE: " & to_string(prize);		
		wait for PERIOD;
		report "Reset and init Machine, loading initial Seed...";		
		wait for PERIOD;
		report "SlotMachine Ready!! We will play 20 times.";
		
		for i in 0 to 20 loop -- play 20 times --
		
			newCredit <=  '1';			
			wait for PERIOD;
			--report "STATE: " & to_string(State);
			report "Lets Play...";
			play <=  '1';
			
			wait until endPlay = '1';
			report "SLOTS: " & to_string(slot_L) & "  " & to_string(slot_M) & "  " & to_string(slot_R);
			--report "PRIZE: " & to_string(prize);
			if (prize="0000000000") then
				report "No Prize..";
				report "Credit inserted...";
			elsif (prize="0000000001") then
				report "Refund Prize.";	
			else 
				report "Prize!: " & to_string(prize);
				pay <= '1';
				report "Pay !";
			end if;
			
			wait for PERIOD;
			
		end loop;	
		
		report "Dont play more ...";
		
		WAIT;
	END PROCESS init;
	
	always : PROCESS (clock)
	BEGIN
		clock <= NOT clock after PERIOD/2;
	END PROCESS always;
	
END tb;
