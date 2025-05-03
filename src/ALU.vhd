----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 04/18/2025 02:50:18 PM
-- Design Name: 
-- Module Name: ALU - Behavioral
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

entity ALU is
    Port ( i_A : in STD_LOGIC_VECTOR (7 downto 0);
           i_B : in STD_LOGIC_VECTOR (7 downto 0);
           i_op : in STD_LOGIC_VECTOR (2 downto 0);
           o_result : out STD_LOGIC_VECTOR (7 downto 0);
           o_flags : out STD_LOGIC_VECTOR (3 downto 0));
end ALU;

architecture Behavioral of ALU is

    component ripple_adder is
    Port ( A : in STD_LOGIC_VECTOR (7 downto 0);
           B : in STD_LOGIC_VECTOR (7 downto 0);
           Cin : in STD_LOGIC;
           S : out STD_LOGIC_VECTOR (7 downto 0);
           Cout : out STD_LOGIC
     );
     end component ripple_adder;
     
     --Signals for ripple adder inputs and outputs
     signal w_result, w_B_twoComplement, w_add_and_sub, w_and, w_or: std_logic_vector(7 downto 0);
     signal w_Cout: std_logic;
begin
    ripple_adder_inst: ripple_adder
    port map(
        A => i_A,
        B => w_B_twoComplement,
        Cin => i_op(0),
        S => w_add_and_sub,
        Cout => w_Cout
    );
    --mux for choosing between add or sub
    with i_op(0) select
        w_B_twoComplement <= i_B when '0',
                             not i_B when '1',
                             i_B when others;
                             
    --do the and and or op
    w_and <= i_A and i_B;
    w_or  <= i_A or i_B;
    
    --mux for choosing the output
    with i_op select
        w_result <= w_add_and_sub when "000",
                    w_add_and_sub when "001",
                    w_and when "010",
                    w_or when "011",
                    w_add_and_sub when others;
     --Negative flag
     o_flags(3) <= w_result(7);
     --output
     o_result <= w_result;
     
     --Carry flag
     o_flags(1) <= w_Cout and not i_op(1);
     
     --Overflow
     o_flags(0) <= not i_op(1) and (w_result(7) xor i_A(7)) and (((i_A(7) xnor i_B(7)) and not i_op(0)) or  ((i_A(7) xor i_B(7)) and i_op(0)));
     
     --zero flag
     o_flags(2) <= not w_result(0) and not w_result(1) and
                   not w_result(2) and not w_result(3) and
                   not w_result(4) and not w_result(5) and
                   not w_result(6) and not w_result(7);

     
     
     
 
end Behavioral;
