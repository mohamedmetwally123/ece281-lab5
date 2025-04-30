--+----------------------------------------------------------------------------
--|
--| NAMING CONVENSIONS :
--|
--|    xb_<port name>           = off-chip bidirectional port ( _pads file )
--|    xi_<port name>           = off-chip input port         ( _pads file )
--|    xo_<port name>           = off-chip output port        ( _pads file )
--|    b_<port name>            = on-chip bidirectional port
--|    i_<port name>            = on-chip input port
--|    o_<port name>            = on-chip output port
--|    c_<signal name>          = combinatorial signal
--|    f_<signal name>          = synchronous signal
--|    ff_<signal name>         = pipeline stage (ff_, fff_, etc.)
--|    <signal name>_n          = active low signal
--|    w_<signal name>          = top level wiring signal
--|    g_<generic name>         = generic
--|    k_<constant name>        = constant
--|    v_<variable name>        = variable
--|    sm_<state machine type>  = state machine type definition
--|    s_<signal name>          = state name
--|
--+----------------------------------------------------------------------------
library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;


entity top_basys3 is
    port(
        -- inputs
        clk     :   in std_logic; -- native 100MHz FPGA clock
        sw      :   in std_logic_vector(7 downto 0); -- operands and opcode
        btnU    :   in std_logic; -- reset
        btnC    :   in std_logic; -- fsm cycle
        
        -- outputs
        led :   out std_logic_vector(15 downto 0);
        -- 7-segment display segments (active-low cathodes)
        seg :   out std_logic_vector(6 downto 0);
        -- 7-segment display active-low enables (anodes)
        an  :   out std_logic_vector(3 downto 0)
    );
end top_basys3;

architecture top_basys3_arch of top_basys3 is 
  
	-- declare components and signals
	Signal w_btnU: std_logic;
	--registers
    signal w_A, w_B: std_logic_vector(7 downto 0):=x"00";

    --ALU
    signal w_result, w_bin: std_logic_vector(7 downto 0);
    signal w_op: std_logic_vector(2 downto 0):="000";
    --controller output
    signal w_cycle: std_logic_vector(3 downto 0);
    
    --twoscomplement
    signal w_hund, w_tens, w_ones, w_sign: std_logic_vector(3 downto 0);
    signal w_sign_bit: std_logic;
    signal w_hex: std_logic_vector(3 downto 0);
    
    --the clock
    signal w_clk: std_logic;
    signal w_sel: std_logic_vector(3 downto 0);
    
    --seven seg
    signal w_seg, w_seg_sign: std_logic_vector(6 downto 0);
    component controller_fsm is 
    port(
           i_reset : in STD_LOGIC;
           i_adv : in STD_LOGIC;
           o_cycle : out STD_LOGIC_VECTOR (3 downto 0)
    );
    end component controller_fsm;
    
    component ALU is 
    port(
           i_A : in STD_LOGIC_VECTOR (7 downto 0);
           i_B : in STD_LOGIC_VECTOR (7 downto 0);
           i_op : in STD_LOGIC_VECTOR (2 downto 0);
           o_result : out STD_LOGIC_VECTOR (7 downto 0);
           o_flags : out STD_LOGIC_VECTOR (3 downto 0)
    );
    end component ALU;
    
    component twos_comp is
    port (
        i_bin: in std_logic_vector(7 downto 0);
        o_sign: out std_logic;
        o_hund: out std_logic_vector(3 downto 0);
        o_tens: out std_logic_vector(3 downto 0);
        o_ones: out std_logic_vector(3 downto 0)
    );
    end component twos_comp;
    
    component clock_divider is
        generic ( constant k_DIV : natural := 2	);
        port ( 	i_clk    : in std_logic;		   -- basys3 clk
                i_reset  : in std_logic;		   -- asynchronous
                o_clk    : out std_logic		   -- divided (slow) clock
        );
   end component clock_divider;
    
    component TDM4 is
    generic ( constant k_WIDTH : natural  := 4); -- bits in input and output
    Port ( i_clk		: in  STD_LOGIC;
           i_reset		: in  STD_LOGIC; -- asynchronous
           i_D3 		: in  STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
		   i_D2 		: in  STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
		   i_D1 		: in  STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
		   i_D0 		: in  STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
		   o_data		: out STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
		   o_sel		: out STD_LOGIC_VECTOR (3 downto 0)	-- selected data line (one-cold)
	);
	end component TDM4;
    
    component sevenseg_decoder is 
     Port ( 
     i_Hex : in STD_LOGIC_VECTOR (3 downto 0);
     o_seg_n : out STD_LOGIC_VECTOR (6 downto 0)
     );
     end component sevenseg_decoder;

begin
	-- PORT MAPS ----------------------------------------

	w_btnu <= btnU;
	controller_inst: controller_fsm
	port map(
	   i_reset => w_btnU,
	   i_adv => btnC,
	   o_cycle => w_cycle	
	);

	
    registerA_proc: process(w_cycle(1))
    begin
        if rising_edge(w_cycle(1)) then
            w_A <= sw(7 downto 0);
        end if;
    end process registerA_proc;
    
    registerB_proc: process(w_cycle(2))
    begin
        if rising_edge(w_cycle(2)) then
            w_B <= sw(7 downto 0);
        end if;
    end process registerB_proc;
    
    ALU_inst: ALU
    port map(
        i_A => w_A,
        i_B => w_B,
        i_op => w_op,
        o_result => w_result,
        o_flags => led(15 downto 12)
    );
    
    --mux for selecting A, B, or the result to go through
    with w_cycle select
        w_bin <= w_A when "0010",
                 w_B when "0100",
                 w_result when "1000",
                 --need to change it but I still don't know what to change it to
                 -------
                 -------
                 "00000000" when others;
                 
    --This blanks the displayer in the first state
    with w_cycle select
        an <= "1111" when "0001",
              w_sel when others;
	twoscomplement: twos_comp
	port map(
	       i_bin => w_bin,
	       --just for now but I'll change it
	       o_sign => w_sign_bit,
	       o_hund => w_hund,
	       o_tens => w_tens,
	       o_ones => w_ones
	);

    --mux to display the sign
    with w_sign_bit select
        w_seg_sign <= "1111111" when '0',
                      "0111111" when others;
                      

    clock_inst: clock_divider 
	   generic map ( k_DIV => 100000 ) 
	   port map(
           i_clk => clk,
           --just for now
           i_reset => w_btnU,
           o_clk => w_clk
	 );
	 --extend tbhe sign bit
	-- w_sign <= (others => w_sign_bit);
	 w_sign <= "1111";
	 TDM4_inst: TDM4
	 port map(
	      i_clk => w_clk,
	      --just for now
	      i_reset => w_btnU,
	      --just for now
	      i_D3 => w_sign,
	      i_D2 => w_hund,
	      i_D1 => w_tens,
	      i_D0 => w_ones, 
	      o_data => w_Hex,
	      o_sel => w_sel
	 );
	 
	
	sevenseg: sevenseg_decoder
	port map(
	       i_hex => w_hex,
	       o_seg_n => w_seg
	);
	
	--process to select the operation
	op: process(w_cycle(4))
	   begin
	   if rising_edge(w_cycle(3)) then
	       w_op <= sw(2 downto 0);
	   end if;
	   end process op;
	
	--mux to select a number from seven seg decoder or to display the sign
	with w_sel select
	   seg <= w_seg_sign when "0111",
	          w_seg when others;
	--just for now
	led(3 downto 0) <= w_cycle;
	--led(4) <= btnC;
	led(11 downto 4) <= (others=> '0');
	-- CONCURRENT STATEMENTS ----------------------------
	
	
	
end top_basys3_arch;
