library ieee; 
use ieee.std_logic_1164.all;

-- lfsr with 64 bit poly
entity lfsr_64 is 
	generic(
	  G_M             : integer           := 64 ;
	  G_POLY          : std_logic_vector  := "1000000000000000000000000000000000000000000000000000000000011011") ;  -- x^64+x^4+x^3+x^1+1 
	port (
	  i_clk           : in  std_logic;
	  i_rstb          : in  std_logic;
	  i_sync_reset    : in  std_logic;
	  i_seed          : in  std_logic_vector (G_M-1 downto 0);
	  i_en            : in  std_logic;
	  o_lsfr          : out std_logic_vector (G_M-1 downto 0);
	  o_bcdnumber	  : out std_logic_vector (3 downto 0)			-- 4 bits output random number --
	);	
end lfsr_64;
architecture rtl of lfsr_64 is	
		signal r_lfsr           : std_logic_vector (G_M downto 1);
		signal w_mask           : std_logic_vector (G_M downto 1);
		signal w_poly           : std_logic_vector (G_M downto 1);

		begin	
		o_lsfr  <= r_lfsr(64 downto 1);

		w_poly  <= G_POLY;
		g_mask : for k in G_M downto 1 generate
		  w_mask(k)  <= w_poly(k) and r_lfsr(1);
		end generate g_mask;

		p_lfsr : process (i_clk,i_rstb) begin 
		  if (i_rstb = '0') then 
			r_lfsr   <= (others=>'1');
		  elsif rising_edge(i_clk) then 
			if(i_sync_reset='1') then
			  r_lfsr   <= i_seed;
			elsif (i_en = '1') then 
			  r_lfsr   <= '0'&r_lfsr(G_M downto 2) xor w_mask;
			end if; 
		  end if; 
		end process p_lfsr; 
		
		o_bcdnumber <= o_lsfr(63 DOWNTO 60);
		
end architecture rtl;

library ieee; 
use ieee.std_logic_1164.all;
--use ieee.numeric_std.all; --

entity randomGenerator is
	port (
		nReset		: in std_logic;							-- reset, active low
		Clk			: in std_logic;							-- system clock

		seed		: in std_logic_vector(63 downto 0);		-- initial seed value for the LFSR
		
		GetNumber	: in std_logic;							-- When 1, the BCD number is consumed and another should be generated
				
		BCD			: out std_logic_vector(3 downto 0);		-- Valid 0-9 random number
		Ready		: out std_logic;						-- 1 when BCD contains a valid number
		
		load		: in std_logic							--Load Seed
	);
end randomGenerator;
architecture toplevel of randomGenerator is			-- include lfsr_64 module and a state machine <=TOP MODULE --
		signal bcdNumber  		: std_logic_vector(3 downto 0);
		signal readyOrNot 		: std_logic;
		signal numberStored		: std_logic_vector(3 downto 0);
		
		begin
		
		-- lfsr_64 entity instatiation --
		m_lfsr_64: entity lfsr_64 port map (
			i_clk			=>	Clk,	
			i_rstb			=> 	nReset,
			i_sync_reset 	=>	load,
			i_seed 			=>	seed,
			i_en			=> 	'1',				--Dejamos i_en a 1 porque enunciado nos dice que no modifiquemos el modulo lfsr_64--
			o_bcdnumber		=> 	bcdNumber
		);
		-- *****************************--
		p_randomgenerator : process (nReset,Clk) begin 
			if (nReset = '0') then 
				numberStored <= "1111";
				readyOrNot <= '0';
			elsif rising_edge(Clk) then 
				if (readyOrNot = '0') then			--if not ready get new random number--
					-- check if number from lfsr_64 module is not greater than 9 --
					if (bcdNumber > "0111") then 	--Now Max Slot of machine is 7 !!
						readyOrNot <= '0';
					else
						numberStored <= bcdNumber;
						readyOrNot <= '1';
					end if;
				end if;
				if (GetNumber = '1') then
					readyOrNot <= '0';				--get another random number between 0 and 9--
				end if;
			end if;
		end process p_randomgenerator; 
		
		Ready 	<= 	readyOrNot;
		BCD 	<=	numberStored;
		
end architecture toplevel;

library ieee; 
use ieee.std_logic_1164.all;
--Arithmetic module for prize calculation
entity prizeCalculator is
	port (
		nReset		: in std_logic;							-- reset, active low
		Clk			: in std_logic;							-- system clock
		Calcule		: in std_logic;							-- calculate order (active  high)
		prizeReaded : in std_logic;
		slotOne		: in std_logic_vector(3 downto 0);
		slotTwo		: in std_logic_vector(3 downto 0);
		slotThree	: in std_logic_vector(3 downto 0);
		CalcDone	: out std_logic;
		PrizeFinal	: out std_logic_vector(9 downto 0)		-- prize calculated
	);
end prizeCalculator;
architecture rtlprize of prizeCalculator is
		signal calcdoneOrNot : std_logic;
		signal prizecalc : std_logic_vector(9 downto 0);
		signal slot1 : std_logic_vector(3 downto 0);
		signal slot2 : std_logic_vector(3 downto 0);
		signal slot3 : std_logic_vector(3 downto 0);
		
		begin
		
		p_prizecalculator : process (nReset,Clk, prizeReaded) begin 
			if (nReset = '0') then 
				prizecalc <= "0000000000";
				calcdoneOrNot <= '0';
			elsif (prizeReaded = '1') then 
				calcdoneOrNot <= '0';
				prizecalc <= "0000000000";
			elsif rising_edge(Clk) then 
				if (calcdoneOrNot = '0') then
					if (Calcule = '1') then
						-- Do calculation of prize related to slots, considering credit is 1:
						if (slot1 = "0000") or (slot2 = "0000") or (slot3 = "0000") then			--BANK--> PRIZE = 0
							prizecalc <= "0000000000";
							calcdoneOrNot <= '1';
						elsif (slot1 = "0111") and (slot2 = "0111") and (slot3 = "0111") then       --MAX--> PRIZE = 225
							prizecalc <= "0011100001";
							calcdoneOrNot <= '1';						
						elsif (slot1 = "0001") and (slot2 = "0001") and (slot3 = "0001") then       --HI--> PRIZE = 25
							prizecalc <= "0000011001";
							calcdoneOrNot <= '1';					
						elsif (slot1 = "0010") and (slot2 = "0010") and (slot3 = "0010") then       --HI--> PRIZE = 25
							prizecalc <= "0000011001";
							calcdoneOrNot <= '1';						
						elsif (slot1 = "0011") and (slot2 = "0011") and (slot3 = "0011") then       --HI--> PRIZE = 25
							prizecalc <= "0000011001";
							calcdoneOrNot <= '1';						
						elsif (slot1 = "0101") and (slot2 = "0101") and (slot3 = "0101") then       --HI--> PRIZE = 25
							prizecalc <= "0000011001";
							calcdoneOrNot <= '1';
						elsif (slot2 = "0111") and (slot3 = "0111") then       						--NEAR--> PRIZE = 10
							prizecalc <= "0000001010";
							calcdoneOrNot <= '1';
						elsif (slot1 = "0111") and (slot2 = "0111") then       						--NEAR--> PRIZE = 10
							prizecalc <= "0000001010";
							calcdoneOrNot <= '1';
						elsif (slot3 = "0001") then       											--LO--> PRIZE = 1
							prizecalc <= "0000000001";
							calcdoneOrNot <= '1';
						elsif (slot3 = "0011") then       											--LO--> PRIZE = 1
							prizecalc <= "0000000001";
							calcdoneOrNot <= '1';
						elsif (slot3 = "0101") then       											--LO--> PRIZE = 1
							prizecalc <= "0000000001";
							calcdoneOrNot <= '1';
						elsif (slot3 = "0111") then       											--NEAR-LO--> PRIZE = 1
							prizecalc <= "0000000001";
							calcdoneOrNot <= '1';
						--elsif (slot1 = "0011") and (slot2 = "0011") and (slot3 = "0100") then    --DEBUG EXCEPTION
							--prizecalc <= "0000010000";
							--calcdoneOrNot <= '1';
						else
							prizecalc <= "0000000000";
							calcdoneOrNot <= '1';
						end if;
					end if;
				end if;	
			end if;
		end process p_prizecalculator; 
		
		slot1 <= slotOne;
		slot2 <= slotTwo;
		slot3 <= slotThree;
		CalcDone 	<= 	calcdoneOrNot;
		PrizeFinal 	<=	prizecalc;
		
end architecture rtlprize;

library ieee; 
use ieee.std_logic_1164.all;

entity slotMachine is 
port (
	nReset			: in std_logic;								-- reset, active low
	clock			: in std_logic;								-- system clock
  
	newCredit		: in std_logic;								-- Adds 1 credit per positive pule
	play			: in std_logic;								-- Plays, if credit is available
 
	credit			: out std_logic_vector(9 downto 0);			-- Accumulated credit/prize
  
	pay				: in std_logic;								-- Return the credit or pay the prize (when high)
	
	slot_L			: out std_logic_vector(3 downto 0);			-- Left slot
	slot_M			: out std_logic_vector(3 downto 0);			-- Mid slot
	slot_R			: out std_logic_vector(3 downto 0);			-- Right slot
	
	endPlay			: out std_logic;							-- 1 when the slots stop moving and prize (if any) is ready 
	
	prize			: out std_logic_vector(9 downto 0);			-- Current prize earned (from the last play)
		
	--showPrizes		: in std_logic;								-- 1 to enter in show prizes mode
	
	ejectCredit		: out std_logic;							-- When paying a prize, send 1 pulse of 3 clock cicles (at high) per credit
																-- with a separation of 10 clock cicles (at low) between them
																	
	endPay			: out std_logic;							-- 1 when the prize/credit is fully payed
			
	--State			: out std_logic_vector(2 downto 0);		--Debug State

			
	configLevel		: out std_logic_vector(15 downto 0));		-- show the currently implemented options in the module
	
end slotMachine;

architecture rtltop of slotMachine is	
		signal 	Seed			: 	std_logic_vector (63 downto 0);
		signal 	Get_number		:	std_logic;	
		signal 	NumberGenerated	:	std_logic_vector(3 downto 0);
		signal	ReadyorNot		:	std_logic;
		signal	Load			:	std_logic;	
		signal	CurrentPrize	:	std_logic_vector(9 downto 0);
		signal	slot1			:	std_logic_vector(3 downto 0);
		signal	slot2			:	std_logic_vector(3 downto 0);
		signal	slot3			:	std_logic_vector(3 downto 0);
		signal	slot1ready		:	std_logic;	
		signal	slot2ready		:	std_logic;	
		signal	slot3ready		:	std_logic;	
		
		--Prize calculator:
		signal calculePrize		:	std_logic;	
		signal prizeRead		:	std_logic;
		signal PrizeCalcDone	:	std_logic;
		
		signal currentState		:	std_logic_vector(2 downto 0);		--State Machine for slotMachine: 000 Idle. Loading Seed.  001 Waiting credit.  010 Credit. Ready to play.  011 Playing. Get random slots.   100 Calculate prize.   101 Prize calculated.    110 Prize. Waiting to pay.
		
		begin	
		
		-- prizeCalculator entity instatiation --
		m_prizecalculator: entity prizeCalculator port map (
			nReset				=>	nReset,	
			Clk					=> 	clock,
			Calcule 			=>	calculePrize,
			prizeReaded 		=>	prizeRead,
			slotOne				=>	slot1,
			slotTwo				=>	slot2,
			slotThree			=>	slot3,
			CalcDone			=>	PrizeCalcDone,
			PrizeFinal			=>	CurrentPrize
		);
		-- *****************************--
		-- randomGenerator entity instatiation --
		m_randomgenerator: entity randomGenerator port map (
			nReset				=>	nReset,	
			Clk					=> 	clock,
			seed 				=>	Seed,
			GetNumber 			=>	Get_number,
			BCD					=> 	NumberGenerated,
			Ready				=> 	ReadyorNot,
			load				=>	Load
		);
		-- *****************************--

		p_slotMachine : process (nReset,clock) begin 
			if (nReset = '0') then 						-- nReset active low					
				Get_number	<= '0';
				slot1 <= "0000";
				slot2 <= "0000";
				slot3 <= "0000";
				slot_L <= slot1;
				slot_M <= slot2;
				slot_R <= slot3;
				slot1ready <= '0';
				slot2ready <= '0';
				slot3ready <= '0';
				currentState <= "000";
				endPlay <= '0';
				Load <= '0';
				calculePrize <= '0';
				prizeRead <= '0';
			elsif rising_edge(clock) then 
				if (currentState = "000") then			--Loading seed (needs 2 clock cycles)				
					if (Load = '0') then
						seed <= "0011011101011100010100100110111010101010011110011000001000111001";
						Load <= '1';
					else
						Load <= '0';
						currentState <= "001";			--seed loaded. Go to waiting credit.
					end if;
				elsif (currentState = "001") then		--Machine Ready. Waiting credit.
					if (newCredit = '1') then	
						endPay <= '0';
						endPlay <= '0';		
						prizeRead <= '1';						
						currentState <= "010";			--Credit. Go to ready to play.
					end if;
				elsif (currentState = "010") then		--Machine waiting to play.
					if (play = '1') then
						endPay <= '0';
						endPlay <= '0';		
						prizeRead <= '1';						
						currentState <= "011";			--Go to playing
					end if;
				elsif (currentState = "011") then		--Machine playing
					if (slot1ready = '1') and (slot2ready = '1') and (slot3ready = '1') then	 --end play						
						currentState <= "100";			--Go to calculate prize
						slot1ready <= '0';
						slot2ready <= '0';
						slot3ready <= '0';
						slot_L <= slot1;
						slot_M <= slot2;
						slot_R <= slot3;
						prizeRead <= '0';
					elsif (Get_number = '1') then
						Get_number <= '0';
					elsif (slot1ready = '0') then
						if (ReadyorNot = '1') then
							slot1 <= NumberGenerated;
							slot1ready <= '1';
							Get_number <= '1';
						end if;
					elsif (slot2ready = '0') then
						if (ReadyorNot = '1') then
							slot2 <= NumberGenerated;
							slot2ready <= '1';
							Get_number <= '1';
						end if;
					elsif (slot3ready = '0') then
						if (ReadyorNot = '1') then
							slot3 <= NumberGenerated;
							slot3ready <= '1';
							Get_number <= '1';
						end if;
					end if;
				elsif (currentState = "100") then				--Calculating prize
					if (PrizeCalcDone = '0') then
						calculePrize <= '1';
					else 
						calculePrize <= '0';
						endPlay <= '1';							--  -> Play end. Slots and prize calculated. Pay or not.
						currentState <= "101";					--Go to prize calculated
					end if;
				elsif (currentState = "101") then				--Prize calculated
					if (CurrentPrize = "0000000000") then    	--NO Prize. Go to Machine ready.						
						currentState <= "001";
					elsif (CurrentPrize = "0000000001") then	--Refund. Play again without new credit.
						currentState <= "010";
						endPay <= '1';
					else
						currentState <= "110";					--Prize! Go to wait Pay.
					end if;
				elsif (currentState = "110") then	
					if (pay = '1') then
						currentState <= "001";                  --Go to machine ready.
						prizeRead <= '1';
						endPay <= '1';
					end if;
				end if;
			end if;
		end process p_slotMachine; 
		
		--slot_L <= slot1;   No estados intermedios
		--slot_M <= slot2;
		--slot_R <= slot3;
		prize <= CurrentPrize;
		configLevel <= "1111110000000001";
		--State <= currentState;               --Debug State
		--Not used:
		credit <= "0000000000";
		ejectCredit <= '0';
		
end architecture rtltop;