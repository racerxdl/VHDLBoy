library IEEE;
use IEEE.std_logic_1164.all;  
use IEEE.numeric_std.all;     

use work.pProc_bus_gb.all;
use work.pReg_gb_reserved.all;

entity gameboy_reservedregs is
   port 
   (
      clk100  : in    std_logic;  
      gb_bus  : inout proc_bus_gb_type := ((others => 'Z'), (others => 'Z'), (others => 'Z'), 'Z', 'Z', 'Z')
   );
end entity;

architecture arch of gameboy_reservedregs is

   signal Gameboy_Rerserved_FF03 : std_logic_vector(Reg_Gameboy_Rerserved_FF03.upper downto Reg_Gameboy_Rerserved_FF03.lower);
          
   signal Gameboy_Rerserved_FF08 : std_logic_vector(Reg_Gameboy_Rerserved_FF08.upper downto Reg_Gameboy_Rerserved_FF08.lower);
   signal Gameboy_Rerserved_FF09 : std_logic_vector(Reg_Gameboy_Rerserved_FF09.upper downto Reg_Gameboy_Rerserved_FF09.lower);
   signal Gameboy_Rerserved_FF0A : std_logic_vector(Reg_Gameboy_Rerserved_FF0A.upper downto Reg_Gameboy_Rerserved_FF0A.lower);
   signal Gameboy_Rerserved_FF0B : std_logic_vector(Reg_Gameboy_Rerserved_FF0B.upper downto Reg_Gameboy_Rerserved_FF0B.lower);
   signal Gameboy_Rerserved_FF0C : std_logic_vector(Reg_Gameboy_Rerserved_FF0C.upper downto Reg_Gameboy_Rerserved_FF0C.lower);
   signal Gameboy_Rerserved_FF0D : std_logic_vector(Reg_Gameboy_Rerserved_FF0D.upper downto Reg_Gameboy_Rerserved_FF0D.lower);
   signal Gameboy_Rerserved_FF0E : std_logic_vector(Reg_Gameboy_Rerserved_FF0E.upper downto Reg_Gameboy_Rerserved_FF0E.lower);
          
   signal Gameboy_Rerserved_FF15 : std_logic_vector(Reg_Gameboy_Rerserved_FF15.upper downto Reg_Gameboy_Rerserved_FF15.lower);
   signal Gameboy_Rerserved_FF1F : std_logic_vector(Reg_Gameboy_Rerserved_FF1F.upper downto Reg_Gameboy_Rerserved_FF1F.lower);
   signal Gameboy_Rerserved_FF27 : std_logic_vector(Reg_Gameboy_Rerserved_FF27.upper downto Reg_Gameboy_Rerserved_FF27.lower);
   signal Gameboy_Rerserved_FF28 : std_logic_vector(Reg_Gameboy_Rerserved_FF28.upper downto Reg_Gameboy_Rerserved_FF28.lower);
   signal Gameboy_Rerserved_FF29 : std_logic_vector(Reg_Gameboy_Rerserved_FF29.upper downto Reg_Gameboy_Rerserved_FF29.lower);
   signal Gameboy_Rerserved_FF2A : std_logic_vector(Reg_Gameboy_Rerserved_FF2A.upper downto Reg_Gameboy_Rerserved_FF2A.lower);
   signal Gameboy_Rerserved_FF2B : std_logic_vector(Reg_Gameboy_Rerserved_FF2B.upper downto Reg_Gameboy_Rerserved_FF2B.lower);
   signal Gameboy_Rerserved_FF2C : std_logic_vector(Reg_Gameboy_Rerserved_FF2C.upper downto Reg_Gameboy_Rerserved_FF2C.lower);
   signal Gameboy_Rerserved_FF2D : std_logic_vector(Reg_Gameboy_Rerserved_FF2D.upper downto Reg_Gameboy_Rerserved_FF2D.lower);
   signal Gameboy_Rerserved_FF2E : std_logic_vector(Reg_Gameboy_Rerserved_FF2E.upper downto Reg_Gameboy_Rerserved_FF2E.lower);
   signal Gameboy_Rerserved_FF2F : std_logic_vector(Reg_Gameboy_Rerserved_FF2F.upper downto Reg_Gameboy_Rerserved_FF2F.lower);
          
   signal Gameboy_Rerserved_FF4C : std_logic_vector(Reg_Gameboy_Rerserved_FF4C.upper downto Reg_Gameboy_Rerserved_FF4C.lower);
   signal Gameboy_Rerserved_FF4E : std_logic_vector(Reg_Gameboy_Rerserved_FF4E.upper downto Reg_Gameboy_Rerserved_FF4E.lower);
          
   signal Gameboy_Rerserved_FF57 : std_logic_vector(Reg_Gameboy_Rerserved_FF57.upper downto Reg_Gameboy_Rerserved_FF57.lower);
   signal Gameboy_Rerserved_FF58 : std_logic_vector(Reg_Gameboy_Rerserved_FF58.upper downto Reg_Gameboy_Rerserved_FF58.lower);
   signal Gameboy_Rerserved_FF59 : std_logic_vector(Reg_Gameboy_Rerserved_FF59.upper downto Reg_Gameboy_Rerserved_FF59.lower);
   signal Gameboy_Rerserved_FF5A : std_logic_vector(Reg_Gameboy_Rerserved_FF5A.upper downto Reg_Gameboy_Rerserved_FF5A.lower);
   signal Gameboy_Rerserved_FF5B : std_logic_vector(Reg_Gameboy_Rerserved_FF5B.upper downto Reg_Gameboy_Rerserved_FF5B.lower);
   signal Gameboy_Rerserved_FF5C : std_logic_vector(Reg_Gameboy_Rerserved_FF5C.upper downto Reg_Gameboy_Rerserved_FF5C.lower);
   signal Gameboy_Rerserved_FF5D : std_logic_vector(Reg_Gameboy_Rerserved_FF5D.upper downto Reg_Gameboy_Rerserved_FF5D.lower);
   signal Gameboy_Rerserved_FF5E : std_logic_vector(Reg_Gameboy_Rerserved_FF5E.upper downto Reg_Gameboy_Rerserved_FF5E.lower);
   signal Gameboy_Rerserved_FF5F : std_logic_vector(Reg_Gameboy_Rerserved_FF5F.upper downto Reg_Gameboy_Rerserved_FF5F.lower);
   signal Gameboy_Rerserved_FF60 : std_logic_vector(Reg_Gameboy_Rerserved_FF60.upper downto Reg_Gameboy_Rerserved_FF60.lower);
   signal Gameboy_Rerserved_FF61 : std_logic_vector(Reg_Gameboy_Rerserved_FF61.upper downto Reg_Gameboy_Rerserved_FF61.lower);
   signal Gameboy_Rerserved_FF62 : std_logic_vector(Reg_Gameboy_Rerserved_FF62.upper downto Reg_Gameboy_Rerserved_FF62.lower);
   signal Gameboy_Rerserved_FF63 : std_logic_vector(Reg_Gameboy_Rerserved_FF63.upper downto Reg_Gameboy_Rerserved_FF63.lower);
   signal Gameboy_Rerserved_FF64 : std_logic_vector(Reg_Gameboy_Rerserved_FF64.upper downto Reg_Gameboy_Rerserved_FF64.lower);
   signal Gameboy_Rerserved_FF65 : std_logic_vector(Reg_Gameboy_Rerserved_FF65.upper downto Reg_Gameboy_Rerserved_FF65.lower);
   signal Gameboy_Rerserved_FF66 : std_logic_vector(Reg_Gameboy_Rerserved_FF66.upper downto Reg_Gameboy_Rerserved_FF66.lower);
   signal Gameboy_Rerserved_FF67 : std_logic_vector(Reg_Gameboy_Rerserved_FF67.upper downto Reg_Gameboy_Rerserved_FF67.lower);
          
   signal Gameboy_Rerserved_FF6D : std_logic_vector(Reg_Gameboy_Rerserved_FF6D.upper downto Reg_Gameboy_Rerserved_FF6D.lower);
   signal Gameboy_Rerserved_FF6E : std_logic_vector(Reg_Gameboy_Rerserved_FF6E.upper downto Reg_Gameboy_Rerserved_FF6E.lower);
   signal Gameboy_Rerserved_FF6F : std_logic_vector(Reg_Gameboy_Rerserved_FF6F.upper downto Reg_Gameboy_Rerserved_FF6F.lower);
          
   signal Gameboy_Rerserved_FF71 : std_logic_vector(Reg_Gameboy_Rerserved_FF71.upper downto Reg_Gameboy_Rerserved_FF71.lower);
          
   signal Gameboy_Rerserved_FF78 : std_logic_vector(Reg_Gameboy_Rerserved_FF78.upper downto Reg_Gameboy_Rerserved_FF78.lower);
   signal Gameboy_Rerserved_FF79 : std_logic_vector(Reg_Gameboy_Rerserved_FF79.upper downto Reg_Gameboy_Rerserved_FF79.lower);
   signal Gameboy_Rerserved_FF7A : std_logic_vector(Reg_Gameboy_Rerserved_FF7A.upper downto Reg_Gameboy_Rerserved_FF7A.lower);
   signal Gameboy_Rerserved_FF7B : std_logic_vector(Reg_Gameboy_Rerserved_FF7B.upper downto Reg_Gameboy_Rerserved_FF7B.lower);
   signal Gameboy_Rerserved_FF7C : std_logic_vector(Reg_Gameboy_Rerserved_FF7C.upper downto Reg_Gameboy_Rerserved_FF7C.lower);
   signal Gameboy_Rerserved_FF7D : std_logic_vector(Reg_Gameboy_Rerserved_FF7D.upper downto Reg_Gameboy_Rerserved_FF7D.lower);
   signal Gameboy_Rerserved_FF7E : std_logic_vector(Reg_Gameboy_Rerserved_FF7E.upper downto Reg_Gameboy_Rerserved_FF7E.lower);
   signal Gameboy_Rerserved_FF7F : std_logic_vector(Reg_Gameboy_Rerserved_FF7F.upper downto Reg_Gameboy_Rerserved_FF7F.lower);
          
   signal Gameboy_Rerserved_FF6C : std_logic_vector(Reg_Gameboy_Rerserved_FF6C.upper downto Reg_Gameboy_Rerserved_FF6C.lower);
   signal Gameboy_Rerserved_FF72 : std_logic_vector(Reg_Gameboy_Rerserved_FF72.upper downto Reg_Gameboy_Rerserved_FF72.lower);
   signal Gameboy_Rerserved_FF73 : std_logic_vector(Reg_Gameboy_Rerserved_FF73.upper downto Reg_Gameboy_Rerserved_FF73.lower);
   signal Gameboy_Rerserved_FF74 : std_logic_vector(Reg_Gameboy_Rerserved_FF74.upper downto Reg_Gameboy_Rerserved_FF74.lower);
   signal Gameboy_Rerserved_FF75 : std_logic_vector(Reg_Gameboy_Rerserved_FF75.upper downto Reg_Gameboy_Rerserved_FF75.lower);
   signal Gameboy_Rerserved_FF76 : std_logic_vector(Reg_Gameboy_Rerserved_FF76.upper downto Reg_Gameboy_Rerserved_FF76.lower);
   signal Gameboy_Rerserved_FF77 : std_logic_vector(Reg_Gameboy_Rerserved_FF77.upper downto Reg_Gameboy_Rerserved_FF77.lower);

   
begin 

   iReg_Gameboy_Rerserved_FF03 : entity work.eProcReg generic map ( Reg_Gameboy_Rerserved_FF03 ) port map  (clk100, gb_bus, Gameboy_Rerserved_FF03);  
                                                                                                                            
   iReg_Gameboy_Rerserved_FF08 : entity work.eProcReg generic map ( Reg_Gameboy_Rerserved_FF08 ) port map  (clk100, gb_bus, Gameboy_Rerserved_FF08);  
   iReg_Gameboy_Rerserved_FF09 : entity work.eProcReg generic map ( Reg_Gameboy_Rerserved_FF09 ) port map  (clk100, gb_bus, Gameboy_Rerserved_FF09);  
   iReg_Gameboy_Rerserved_FF0A : entity work.eProcReg generic map ( Reg_Gameboy_Rerserved_FF0A ) port map  (clk100, gb_bus, Gameboy_Rerserved_FF0A);  
   iReg_Gameboy_Rerserved_FF0B : entity work.eProcReg generic map ( Reg_Gameboy_Rerserved_FF0B ) port map  (clk100, gb_bus, Gameboy_Rerserved_FF0B);  
   iReg_Gameboy_Rerserved_FF0C : entity work.eProcReg generic map ( Reg_Gameboy_Rerserved_FF0C ) port map  (clk100, gb_bus, Gameboy_Rerserved_FF0C);  
   iReg_Gameboy_Rerserved_FF0D : entity work.eProcReg generic map ( Reg_Gameboy_Rerserved_FF0D ) port map  (clk100, gb_bus, Gameboy_Rerserved_FF0D);  
   iReg_Gameboy_Rerserved_FF0E : entity work.eProcReg generic map ( Reg_Gameboy_Rerserved_FF0E ) port map  (clk100, gb_bus, Gameboy_Rerserved_FF0E);  
                                                                                                                            
   iReg_Gameboy_Rerserved_FF15 : entity work.eProcReg generic map ( Reg_Gameboy_Rerserved_FF15 ) port map  (clk100, gb_bus, Gameboy_Rerserved_FF15);  
   iReg_Gameboy_Rerserved_FF1F : entity work.eProcReg generic map ( Reg_Gameboy_Rerserved_FF1F ) port map  (clk100, gb_bus, Gameboy_Rerserved_FF1F);  
   iReg_Gameboy_Rerserved_FF27 : entity work.eProcReg generic map ( Reg_Gameboy_Rerserved_FF27 ) port map  (clk100, gb_bus, Gameboy_Rerserved_FF27);  
   iReg_Gameboy_Rerserved_FF28 : entity work.eProcReg generic map ( Reg_Gameboy_Rerserved_FF28 ) port map  (clk100, gb_bus, Gameboy_Rerserved_FF28);  
   iReg_Gameboy_Rerserved_FF29 : entity work.eProcReg generic map ( Reg_Gameboy_Rerserved_FF29 ) port map  (clk100, gb_bus, Gameboy_Rerserved_FF29);  
   iReg_Gameboy_Rerserved_FF2A : entity work.eProcReg generic map ( Reg_Gameboy_Rerserved_FF2A ) port map  (clk100, gb_bus, Gameboy_Rerserved_FF2A);  
   iReg_Gameboy_Rerserved_FF2B : entity work.eProcReg generic map ( Reg_Gameboy_Rerserved_FF2B ) port map  (clk100, gb_bus, Gameboy_Rerserved_FF2B);  
   iReg_Gameboy_Rerserved_FF2C : entity work.eProcReg generic map ( Reg_Gameboy_Rerserved_FF2C ) port map  (clk100, gb_bus, Gameboy_Rerserved_FF2C);  
   iReg_Gameboy_Rerserved_FF2D : entity work.eProcReg generic map ( Reg_Gameboy_Rerserved_FF2D ) port map  (clk100, gb_bus, Gameboy_Rerserved_FF2D);  
   iReg_Gameboy_Rerserved_FF2E : entity work.eProcReg generic map ( Reg_Gameboy_Rerserved_FF2E ) port map  (clk100, gb_bus, Gameboy_Rerserved_FF2E);  
   iReg_Gameboy_Rerserved_FF2F : entity work.eProcReg generic map ( Reg_Gameboy_Rerserved_FF2F ) port map  (clk100, gb_bus, Gameboy_Rerserved_FF2F);  
                                                                                                                            
   iReg_Gameboy_Rerserved_FF4C : entity work.eProcReg generic map ( Reg_Gameboy_Rerserved_FF4C ) port map  (clk100, gb_bus, Gameboy_Rerserved_FF4C);  
   iReg_Gameboy_Rerserved_FF4E : entity work.eProcReg generic map ( Reg_Gameboy_Rerserved_FF4E ) port map  (clk100, gb_bus, Gameboy_Rerserved_FF4E);  
                                                                                                                            
   iReg_Gameboy_Rerserved_FF57 : entity work.eProcReg generic map ( Reg_Gameboy_Rerserved_FF57 ) port map  (clk100, gb_bus, Gameboy_Rerserved_FF57);  
   iReg_Gameboy_Rerserved_FF58 : entity work.eProcReg generic map ( Reg_Gameboy_Rerserved_FF58 ) port map  (clk100, gb_bus, Gameboy_Rerserved_FF58);  
   iReg_Gameboy_Rerserved_FF59 : entity work.eProcReg generic map ( Reg_Gameboy_Rerserved_FF59 ) port map  (clk100, gb_bus, Gameboy_Rerserved_FF59);  
   iReg_Gameboy_Rerserved_FF5A : entity work.eProcReg generic map ( Reg_Gameboy_Rerserved_FF5A ) port map  (clk100, gb_bus, Gameboy_Rerserved_FF5A);  
   iReg_Gameboy_Rerserved_FF5B : entity work.eProcReg generic map ( Reg_Gameboy_Rerserved_FF5B ) port map  (clk100, gb_bus, Gameboy_Rerserved_FF5B);  
   iReg_Gameboy_Rerserved_FF5C : entity work.eProcReg generic map ( Reg_Gameboy_Rerserved_FF5C ) port map  (clk100, gb_bus, Gameboy_Rerserved_FF5C);  
   iReg_Gameboy_Rerserved_FF5D : entity work.eProcReg generic map ( Reg_Gameboy_Rerserved_FF5D ) port map  (clk100, gb_bus, Gameboy_Rerserved_FF5D);  
   iReg_Gameboy_Rerserved_FF5E : entity work.eProcReg generic map ( Reg_Gameboy_Rerserved_FF5E ) port map  (clk100, gb_bus, Gameboy_Rerserved_FF5E);  
   iReg_Gameboy_Rerserved_FF5F : entity work.eProcReg generic map ( Reg_Gameboy_Rerserved_FF5F ) port map  (clk100, gb_bus, Gameboy_Rerserved_FF5F);  
   iReg_Gameboy_Rerserved_FF60 : entity work.eProcReg generic map ( Reg_Gameboy_Rerserved_FF60 ) port map  (clk100, gb_bus, Gameboy_Rerserved_FF60);  
   iReg_Gameboy_Rerserved_FF61 : entity work.eProcReg generic map ( Reg_Gameboy_Rerserved_FF61 ) port map  (clk100, gb_bus, Gameboy_Rerserved_FF61);  
   iReg_Gameboy_Rerserved_FF62 : entity work.eProcReg generic map ( Reg_Gameboy_Rerserved_FF62 ) port map  (clk100, gb_bus, Gameboy_Rerserved_FF62);  
   iReg_Gameboy_Rerserved_FF63 : entity work.eProcReg generic map ( Reg_Gameboy_Rerserved_FF63 ) port map  (clk100, gb_bus, Gameboy_Rerserved_FF63);  
   iReg_Gameboy_Rerserved_FF64 : entity work.eProcReg generic map ( Reg_Gameboy_Rerserved_FF64 ) port map  (clk100, gb_bus, Gameboy_Rerserved_FF64);  
   iReg_Gameboy_Rerserved_FF65 : entity work.eProcReg generic map ( Reg_Gameboy_Rerserved_FF65 ) port map  (clk100, gb_bus, Gameboy_Rerserved_FF65);  
   iReg_Gameboy_Rerserved_FF66 : entity work.eProcReg generic map ( Reg_Gameboy_Rerserved_FF66 ) port map  (clk100, gb_bus, Gameboy_Rerserved_FF66);  
   iReg_Gameboy_Rerserved_FF67 : entity work.eProcReg generic map ( Reg_Gameboy_Rerserved_FF67 ) port map  (clk100, gb_bus, Gameboy_Rerserved_FF67);  
                                                                                                                            
   iReg_Gameboy_Rerserved_FF6D : entity work.eProcReg generic map ( Reg_Gameboy_Rerserved_FF6D ) port map  (clk100, gb_bus, Gameboy_Rerserved_FF6D);  
   iReg_Gameboy_Rerserved_FF6E : entity work.eProcReg generic map ( Reg_Gameboy_Rerserved_FF6E ) port map  (clk100, gb_bus, Gameboy_Rerserved_FF6E);  
   iReg_Gameboy_Rerserved_FF6F : entity work.eProcReg generic map ( Reg_Gameboy_Rerserved_FF6F ) port map  (clk100, gb_bus, Gameboy_Rerserved_FF6F);  
                                                                                                                            
   iReg_Gameboy_Rerserved_FF71 : entity work.eProcReg generic map ( Reg_Gameboy_Rerserved_FF71 ) port map  (clk100, gb_bus, Gameboy_Rerserved_FF71);  
                                                                                                                            
   iReg_Gameboy_Rerserved_FF78 : entity work.eProcReg generic map ( Reg_Gameboy_Rerserved_FF78 ) port map  (clk100, gb_bus, Gameboy_Rerserved_FF78);  
   iReg_Gameboy_Rerserved_FF79 : entity work.eProcReg generic map ( Reg_Gameboy_Rerserved_FF79 ) port map  (clk100, gb_bus, Gameboy_Rerserved_FF79);  
   iReg_Gameboy_Rerserved_FF7A : entity work.eProcReg generic map ( Reg_Gameboy_Rerserved_FF7A ) port map  (clk100, gb_bus, Gameboy_Rerserved_FF7A);  
   iReg_Gameboy_Rerserved_FF7B : entity work.eProcReg generic map ( Reg_Gameboy_Rerserved_FF7B ) port map  (clk100, gb_bus, Gameboy_Rerserved_FF7B);  
   iReg_Gameboy_Rerserved_FF7C : entity work.eProcReg generic map ( Reg_Gameboy_Rerserved_FF7C ) port map  (clk100, gb_bus, Gameboy_Rerserved_FF7C);  
   iReg_Gameboy_Rerserved_FF7D : entity work.eProcReg generic map ( Reg_Gameboy_Rerserved_FF7D ) port map  (clk100, gb_bus, Gameboy_Rerserved_FF7D);  
   iReg_Gameboy_Rerserved_FF7E : entity work.eProcReg generic map ( Reg_Gameboy_Rerserved_FF7E ) port map  (clk100, gb_bus, Gameboy_Rerserved_FF7E);  
   iReg_Gameboy_Rerserved_FF7F : entity work.eProcReg generic map ( Reg_Gameboy_Rerserved_FF7F ) port map  (clk100, gb_bus, Gameboy_Rerserved_FF7F);  
                                                                                                                            
   iReg_Gameboy_Rerserved_FF6C : entity work.eProcReg generic map ( Reg_Gameboy_Rerserved_FF6C ) port map  (clk100, gb_bus, Gameboy_Rerserved_FF6C);  
   iReg_Gameboy_Rerserved_FF72 : entity work.eProcReg generic map ( Reg_Gameboy_Rerserved_FF72 ) port map  (clk100, gb_bus, Gameboy_Rerserved_FF72);  
   iReg_Gameboy_Rerserved_FF73 : entity work.eProcReg generic map ( Reg_Gameboy_Rerserved_FF73 ) port map  (clk100, gb_bus, Gameboy_Rerserved_FF73);  
   iReg_Gameboy_Rerserved_FF74 : entity work.eProcReg generic map ( Reg_Gameboy_Rerserved_FF74 ) port map  (clk100, gb_bus, Gameboy_Rerserved_FF74);  
   iReg_Gameboy_Rerserved_FF75 : entity work.eProcReg generic map ( Reg_Gameboy_Rerserved_FF75 ) port map  (clk100, gb_bus, Gameboy_Rerserved_FF75);  
   iReg_Gameboy_Rerserved_FF76 : entity work.eProcReg generic map ( Reg_Gameboy_Rerserved_FF76 ) port map  (clk100, gb_bus, Gameboy_Rerserved_FF76);  
   iReg_Gameboy_Rerserved_FF77 : entity work.eProcReg generic map ( Reg_Gameboy_Rerserved_FF77 ) port map  (clk100, gb_bus, Gameboy_Rerserved_FF77);  

   

end architecture;





