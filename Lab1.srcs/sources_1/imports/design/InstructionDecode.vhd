library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;

entity InstructionDecode is
    Port ( Instruction : in STD_LOGIC_VECTOR (31 downto 0);
            -- Instruction operands (OF => Operand Fetch)
           AA       : out STD_LOGIC_VECTOR ( 3 downto 0); -- A Address of the Register
           MA       : out STD_LOGIC; -- Multiplexer to select between REgisters and Immediate operand for input A
           BA       : out STD_LOGIC_VECTOR ( 3 downto 0); -- B Address of the Register
           MB       : out STD_LOGIC;  -- Multiplexer to select between REgisters and Immediate operand for input B
           KNS      : out STD_LOGIC_VECTOR (31 downto 0); -- Immediate constant
           -- execution control (EX => Execute)
           FS       : out STD_LOGIC_VECTOR ( 3 downto 0); -- selects operation on Execution fase (ALU)
           --FW       : out STD_LOGIC_VECTOR ( 3 downto 0);
           PL       : out STD_LOGIC; -- selectes between status and flags
           BC       : out STD_LOGIC_VECTOR ( 3 downto 0); -- selects which flag to analyse
           -- memory control (MEM => Memory)
           MMA      : out STD_LOGIC_VECTOR ( 1 downto 0); -- Origin of the content to save to memory to address
           MMB      : out STD_LOGIC_VECTOR ( 1 downto 0); -- Origin of the content to save to memory to data in
           MW       : out STD_LOGIC; -- Memory Write Enable
            -- Instruction Result (WB => Write-Back)
           MD       : out STD_LOGIC; -- Selects data for the registers between the ALU and the MEM
           DA       : out STD_LOGIC_VECTOR ( 3 downto 0) -- Destination Address, selects the register to store
          );
end InstructionDecode;

architecture Structural of InstructionDecode is
type storage_type is array (0 to 63) of std_logic_vector(30 downto 0);

--------------------------------------------------------------------------------------------------------------------------------  
-- SIGNAL PARTIAL DESCRIPTION  
--------------------------------------------------------------------------------------------------------------------------------  
-- when KNSSel is
--   "000" -> constant KNS(31:0) is zero-extended   0,...,0,I(17:0)
--   "001" -> constant KNS(31:0) is signed-extended I(17),...,I(17),I(17:0)
--   "010" -> constant KNS(31:0) is signed-extended I(25),...,I(25),I(25:22),I(13:0)
--   "011" -> constant KNS(31:0) is signed-extended I(13),...,I(13),I(13:0)
--   "100" -> constant KNS(31:0) is 0000h & I(15:0)
--   "101" -> constant KNS(31:0) is FFFFh & I(15:0)
--   "110" -> constant KNS(31:0) is I(15:0) & 0000h
--   "111" -> constant KNS(31:0) is I(15:0) & FFFFh

-- when MASel is
--   "00" -> AA=SA,                 OpA is R[AA] 
--   "10" -> AA=DECODE_MEMORY_AA,   OpA is R[AA]
--   "-1" -> AA=dont'care           OpA is KNS 

-- when MBSel is
--   "00" -> BA=SB,                 OpB is R[BA] 
--   "10" -> BA=DECODE_MEMORY_BA,   OpB is R[BA]
--   "-1" -> BA=dont'care           OpB is KNS 

-- when MdSel is
--   "00" -> DA=DR,                 Destination is R[DR] 
--   "10" -> DA=DECODE_MEMORY_DA,   Destination is R[DA]
--   "-1" -> DA=dont'care           Destination is KNS 

-- when MMA/MMB is
--   "00" -> Memory Address/DataIn is KNS 
--   "01" -> Memory Address/DataIn is R[AA]
--   "10" -> Memory Address/DataIn is R[BA]
--   "11" -> Memory Address/DataIn is Functional Unit Output

signal decode_memory: storage_type := (
-- UNCOMMENT THE LINES CORRESPONDING TO YOUR OPCODES
  --------------------------------------------------------------------------------------------------------------------------------  
  -- OPCODE =>  PL  &  dAA    & dBA     & dDA     &  FS     &  KNSSel &  MASel &  MBSel &  MMA   & MMB   &  MW  &  MDSel
  -- (decimal) (30) & (29-26) & (25-22) & (21-18) & (17-14) & (13-11) & (10-9) & (8-7)  & (6-5)  & (4-3) &  (2) & (1-0)  
  --------------------------------------------------------------------------------------------------------------------------------  
          0 =>  '?' &   x"?"  &  x"?"   &  x"?"   &  x"0000"   &  "???"  &  "00"  &  "00"  &  "00"  & "00"  &  '0' &  "00",  -- ADD    R[DR],R[SA],R[SB]
          1 =>  '?' &   x"?"  &  x"?"   &  x"?"   &  x"0000"   &  "001"  &  "00"  &  "11"  &  "00"  & "00"  &  '0' &  "00",  -- ADDI   R[DR],R[SA],SIMM18
          2 =>  '?' &   x"?"  &  x"?"   &  x"?"   &  x"0011"   &  "???"  &  "00"  &  "00"  &  "00"  & "00"  &  '0' &  "00",  -- SUB    R[DR],R[SA],R[SB]
          3 =>  '?' &   x"?"  &  x"?"   &  x"?"   &  x"0011"   &  "001"  &  "00"  &  "11"  &  "00"  & "00"  &  '0' &  "00",  -- SUBI   R[DR],R[SA],SIMM18
  --------------------------------------------------------------------------------------------------------------------------------  
  -- OPCODE =>  PL  &  dAA    & dBA     & dDA     &  FS     &  KNSSel &  MASel &  MBSel &  MMA   & MMB   &  MW  &  MDSel
  --------------------------------------------------------------------------------------------------------------------------------  
          4 =>  '?' &   x"?"  &  x"?"   &  x"?"   &  x"0100"   &  "???"  &  "00"  &  "00"  &  "00"  & "00"  &  '0' &  "00",  -- AND    R[DR],R[SA],R[SB]
          5 =>  '?' &   x"?"  &  x"?"   &  x"?"   &  x"0100"   &  "101"  &  "00"  &  "11"  &  "00"  & "00"  &  '0' &  "00",  -- ANDIL  R[DR],R[SA],IMM16
          6 =>  '?' &   x"?"  &  x"?"   &  x"?"   &  x"0100"   &  "111"  &  "00"  &  "11"  &  "00"  & "00"  &  '0' &  "00",  -- ANDIH  R[DR],R[SA],IMM16
          7 =>  '?' &   x"?"  &  x"?"   &  x"?"   &  x"0101"   &  "???"  &  "00"  &  "00"  &  "00"  & "00"  &  '0' &  "00",  -- NAND   R[DR],R[SA],R[SB]
          8 =>  '?' &   x"?"  &  x"?"   &  x"?"   &  x"0110"   &  "???"  &  "00"  &  "00"  &  "00"  & "00"  &  '0' &  "00",  -- OR     R[DR],R[SA],R[BA]
          9 =>  '?' &   x"?"  &  x"?"   &  x"?"   &  x"0110"   &  "100"  &  "00"  &  "11"  &  "00"  & "00"  &  '0' &  "00",  -- ORIL   R[DR],R[SA],IMM16
         10 =>  '?' &   x"?"  &  x"?"   &  x"?"   &  x"0110"   &  "110"  &  "00"  &  "11"  &  "00"  & "00"  &  '0' &  "00",  -- ORIH   R[DR],R[SA],IMM16
         11 =>  '?' &   x"?"  &  x"?"   &  x"?"   &  x"0111"   &  "???"  &  "00"  &  "00"  &  "00"  & "00"  &  '0' &  "00",  -- NOR    R[DR],R[SA],R[SB]
         12 =>  '?' &   x"?"  &  x"?"   &  x"?"   &  x"1000"   &  "???"  &  "00"  &  "00"  &  "00"  & "00"  &  '0' &  "00",  -- XOR    R[DR],R[SA],R[SB]
         13 =>  '?' &   x"?"  &  x"?"   &  x"?"   &  x"1001"   &  "???"  &  "00"  &  "00"  &  "00"  & "00"  &  '0' &  "00",  -- XNOR   R[DR],R[SA],R[SB]
  --------------------------------------------------------------------------------------------------------------------------------  
  -- OPCODE =>  PL  &  dAA    & dBA     & dDA     &  FS     &  KNSSel &  MASel &  MBSel &  MMA   & MMB   &  MW  &  MDSel
  --------------------------------------------------------------------------------------------------------------------------------  
         14 =>  '?' &   x"?"  &  x"?"   &  x"?"   &  x"1010"   &  "???"  &  "?1"  &  "?0"  &  "00"  & "00"  &  '0' &  "00",  -- LSL    R[DR],R[SB]
         15 =>  '?' &   x"?"  &  x"?"   &  x"?"   &  x"1011"   &  "???"  &  "?1"  &  "?0"  &  "00"  & "00"  &  '0' &  "00",  -- LSR    R[DR],R[SB]
         16 =>  '?' &   x"?"  &  x"?"   &  x"?"   &  x"1110"   &  "???"  &  "?1"  &  "?0"  &  "00"  & "00"  &  '0' &  "00",  -- ROL    R[DR],R[SB]
         17 =>  '?' &   x"?"  &  x"?"   &  x"?"   &  x"1111"   &  "???"  &  "?1"  &  "?0"  &  "00"  & "00"  &  '0' &  "00",  -- ROR    R[DR],R[SB]
         18 =>  '?' &   x"?"  &  x"?"   &  x"?"   &  x"1100"   &  "???"  &  "?1"  &  "?0"  &  "00"  & "00"  &  '0' &  "00",  -- ASL    R[DR],R[SB]
         19 =>  '?' &   x"?"  &  x"?"   &  x"?"   &  x"1101"   &  "???"  &  "?1"  &  "?0"  &  "00"  & "00"  &  '0' &  "00",  -- ASR    R[DR],R[SB]
  --------------------------------------------------------------------------------------------------------------------------------  
  -- OPCODE =>  PL  &  dAA    & dBA     & dDA     &  FS     &  KNSSel &  MASel &  MBSel &  MMA   & MMB   &  MW  &  MDSel
  --------------------------------------------------------------------------------------------------------------------------------  
         20 =>  '?' &   x"?"  &  x"?"   &  x"?"   &  x"0000"   &  "???"  &  "?0"  &  "?0"  &  "11"  & "00"  &  '0' &  "01",  -- LD     R[DA],(R[AA]+R[BA])
         21 =>  '?' &   x"?"  &  x"?"   &  x"?"   &  x"0000"   &  "001"  &  "?0"  &  "11"  &  "11"  & "00"  &  '0' &  "01",  -- LDI    R[DA],(R[AA]+SIMM18)
         22 =>  '?' &   x"?"  &  x"?"   &  x"?"   &  x"0000"   &  "???"  &  "?0"  &  "?0"  &  "11"  & "11"  &  '1' &  "?0",  -- ST     (R[AA]+SIMM18),R[SB]
  --------------------------------------------------------------------------------------------------------------------------------  
  -- OPCODE =>  PL  &  dAA    & dBA     & dDA     &  FS     &  KNSSel &  MASel &  MBSel &  MMA   & MMB   &  MW  &  MDSel
  --------------------------------------------------------------------------------------------------------------------------------  
         23 =>  '?' &   x"?"  &  x"?"   &  x"1111"   &  x"0011"   &  "???"  &  "??"  &  "??"  &  "00"  & "00"  &  '0' &  "?0",  -- B.cond  (R[SA] cond R[SB]),SIMM14
         24 =>  '?' &   x"?"  &  x"?"   &  x"1111"   &  x"0011"   &  "011"  &  "??"  &  "??"  &  "00"  & "00"  &  '0' &  "?0",  -- BI.cond (R[SA] cond SIMM14),R[SB]
   others =>    '0' &   x"0"  &  x"0"   &  x"0"   &  x"0"   &  "000"  &  "00"  &  "00"  &  "00"  & "00"  &  '0' &  "10"   -- NOP
   );

signal Opcode : std_logic_vector(5 downto 0);
signal mem_out : std_logic_vector(30 downto 0);

signal SA,dAA : std_logic_vector(3 downto 0);
signal SB,dBA : std_logic_vector(3 downto 0);
signal DR,dDA : std_logic_vector(3 downto 0);
signal MASel, MBSel, MDSel : std_logic_vector(1 downto 0);
signal KNSSel : std_logic_vector(2 downto 0);

begin

-- Retrieve Instruction Fields
Opcode <= Instruction(31 downto 26);
DR     <= Instruction(25 downto 22);
SA     <= Instruction(21 downto 18);
SB     <= Instruction(17 downto 14);
BC     <= Instruction(25 downto 22);

-- Constant value (KNS) is always extended to 32 bits, depending on KNSSel
with KNSSel select
    KNS  <= (31 downto 18=>'0') & Instruction(17 downto 0)             when "000",
            (31 downto 18=>Instruction(17)) & Instruction(17 downto 0) when "001",
            (31 downto 18=>Instruction(25)) & Instruction(25 downto 22) & Instruction(13 downto 0) when "010",
            (31 downto 14=>Instruction(13)) & Instruction(13 downto 0) when "011",
            (31 downto 16=>'0')             & Instruction(15 downto 0) when "100",
            (31 downto 16=>'1')             & Instruction(15 downto 0) when "101",
            Instruction(15 downto 0)        & (31 downto 16=>'0')      when "110",
            Instruction(15 downto 0)        & (31 downto 16=>'1')      when others;

-- Fetch decode bits from memory
mem_out <= decode_memory(to_integer(unsigned(Opcode)));

-- Assign memory outputs
PL    <= mem_out(30);
dDA   <= mem_out(21 downto 18);
dAA   <= mem_out(29 downto 26);
dBA   <= mem_out(25 downto 22);
MASel <= mem_out(10 downto 9);
MBSel <= mem_out( 8 downto 7);
FS    <= mem_out(17 downto 14);
KNSSel<= mem_out(13 downto 11);
MMA   <= mem_out( 6 downto 5);
MMB   <= mem_out( 4 downto 3);
MW    <= mem_out( 2);
MDSel <= mem_out( 1 downto 0);

-- select registers to read from the Register File ("Unidade de Armazenamento")
with MASel(1) select
    AA <= SA  when '0',
          dAA when others; 

with MBSel(1) select
    BA <= SB  when '0',
          dBA when others; 

with MDSel(1) select
    DA <= DR  when '0',
          dDA when others;
           
MA <= MASel(0);
MB <= MBSel(0);
MD <= MDSel(0);

end Structural;
