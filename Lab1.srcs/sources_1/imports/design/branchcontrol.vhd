library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity branchcontrol is
    Port ( PL : in STD_LOGIC;
           BC : in STD_LOGIC_VECTOR(3 downto 0);
           PC : in STD_LOGIC_VECTOR (31 downto 0);
           AD : in STD_LOGIC_VECTOR (31 downto 0);
           Flags : in STD_LOGIC_VECTOR(3 downto 0);
           PCLoad : out STD_LOGIC; -- Mux que controla next PC 
           PCValue : out STD_LOGIC_VECTOR (31 downto 0));
end branchcontrol;

architecture Behavioral of branchcontrol is

signal Z,N,P,C,V: std_logic;

begin

Z <= Flags(3);        -- zero flag
N <= Flags(2);        -- negative flag
P <= not N and not Z; -- positive flag
C <= FLags(1);        -- carry flag
V <= Flags(0);        -- overflow flag

-- Definir a l�gica relativa ao calculo do sinal PCLoad, o qual dever� ter o n�vel l�gico '1' sempre que
-- ocorrer uma instru��o de salto (branch), mas apenas nos casos em que a condi��o de salto � verdadeira.
-- Em todos os outros casos (i.e., a instru��o n�o � de branch, ou a condi��o de salto � falsa) o valor 
-- dever� ser zero.
-- PCLoad <= '0';

with BC(2 downto 0) select
    PCLoad <= '0'        when "000",
              '1'        when "001", 
              Z          when "010",
              not Z      when "011",
              P          when "100",
              P or Z     when "101",
              not P      when "110",
              not P or Z when others; 

-- Calculo do novo valor de PC (caso a condicao de salto seja verdadeira)
PCValue<=PC;

end Behavioral;
