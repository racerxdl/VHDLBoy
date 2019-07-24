library IEEE;
use IEEE.std_logic_1164.all;  
use IEEE.numeric_std.all;     

use work.pProc_bus_gb.all;
use work.pRegmap.all;

package pReg_gb_memory is

   -- range 0000 .. FFFE
   --   (                                                               adr      upper    lower    size  default   accesstype)                                     
   constant Reg_Gameboy_RomBank0                      : regmap_type := (16#0000#,   7,      0, 16#4000#,       0,   readwrite);  
   constant Reg_Gameboy_RomBankN                      : regmap_type := (16#4000#,   7,      0, 16#4000#,       0,   readwrite); 
   
   constant Reg_Gameboy_VRam                          : regmap_type := (16#8000#,   7,      0, 16#2000#,       0,   readwrite); 
   
   constant Reg_Gameboy_CartRam                       : regmap_type := (16#A000#,   7,      0, 16#2000#,       0,   readwrite);
   
   constant Reg_Gameboy_WRamBank0                     : regmap_type := (16#C000#,   7,      0, 16#1000#,       0,   readwrite);  
   constant Reg_Gameboy_WRamBankN                     : regmap_type := (16#D000#,   7,      0, 16#1000#,       0,   readwrite);  
   constant Reg_Gameboy_WRamBank0_Echo                : regmap_type := (16#E000#,   7,      0, 16#1000#,       0,   readwrite);  
   constant Reg_Gameboy_WRamBankN_Echo                : regmap_type := (16#F000#,   7,      0, 16#0E00#,       0,   readwrite); 
   
   constant Reg_Gameboy_OAMRam                        : regmap_type := (16#FE00#,   7,      0, 16#00A0#,       0,   readwrite); 
   
   constant Reg_Gameboy_Unusable                      : regmap_type := (16#FEA0#,   7,      0, 16#0060#,       0,   readonly); 
   
   constant Reg_Gameboy_HRam                          : regmap_type := (16#FF80#,   7,      0,      127,       0,   readwrite);  
     
   constant Reg_Gameboy_VRamBank                      : regmap_type := (16#FF4F#,   0,      0,        1,       0,   readwrite);  
   constant Reg_Gameboy_WRamBank                      : regmap_type := (16#FF70#,   2,      0,        1,       1,   readwrite);  
   

      
end package;
