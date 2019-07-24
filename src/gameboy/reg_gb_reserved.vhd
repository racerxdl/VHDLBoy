library IEEE;
use IEEE.std_logic_1164.all;  
use IEEE.numeric_std.all;     

use work.pProc_bus_gb.all;
use work.pRegmap.all;

package pReg_gb_reserved is

   -- range FF00 .. FF7F
   --   (                                                    adr      upper    lower    size  default   accesstype)                                     
   constant Reg_Gameboy_Rerserved_FF03    : regmap_type := (16#FF03#,   7,      0,        1,  16#FF#,   readonly);   
   
   constant Reg_Gameboy_Rerserved_FF08    : regmap_type := (16#FF08#,   7,      0,        1,  16#FF#,   readonly);   
   constant Reg_Gameboy_Rerserved_FF09    : regmap_type := (16#FF09#,   7,      0,        1,  16#FF#,   readonly);   
   constant Reg_Gameboy_Rerserved_FF0A    : regmap_type := (16#FF0A#,   7,      0,        1,  16#FF#,   readonly);   
   constant Reg_Gameboy_Rerserved_FF0B    : regmap_type := (16#FF0B#,   7,      0,        1,  16#FF#,   readonly);   
   constant Reg_Gameboy_Rerserved_FF0C    : regmap_type := (16#FF0C#,   7,      0,        1,  16#FF#,   readonly);   
   constant Reg_Gameboy_Rerserved_FF0D    : regmap_type := (16#FF0D#,   7,      0,        1,  16#FF#,   readonly);   
   constant Reg_Gameboy_Rerserved_FF0E    : regmap_type := (16#FF0E#,   7,      0,        1,  16#FF#,   readonly);   
   
   constant Reg_Gameboy_Rerserved_FF15    : regmap_type := (16#FF15#,   7,      0,        1,  16#FF#,   readonly);   
   constant Reg_Gameboy_Rerserved_FF1F    : regmap_type := (16#FF1F#,   7,      0,        1,  16#FF#,   readonly);   
   constant Reg_Gameboy_Rerserved_FF27    : regmap_type := (16#FF27#,   7,      0,        1,  16#FF#,   readonly);   
   constant Reg_Gameboy_Rerserved_FF28    : regmap_type := (16#FF28#,   7,      0,        1,  16#FF#,   readonly);   
   constant Reg_Gameboy_Rerserved_FF29    : regmap_type := (16#FF29#,   7,      0,        1,  16#FF#,   readonly);   
   constant Reg_Gameboy_Rerserved_FF2A    : regmap_type := (16#FF2A#,   7,      0,        1,  16#FF#,   readonly);   
   constant Reg_Gameboy_Rerserved_FF2B    : regmap_type := (16#FF2B#,   7,      0,        1,  16#FF#,   readonly);   
   constant Reg_Gameboy_Rerserved_FF2C    : regmap_type := (16#FF2C#,   7,      0,        1,  16#FF#,   readonly);   
   constant Reg_Gameboy_Rerserved_FF2D    : regmap_type := (16#FF2D#,   7,      0,        1,  16#FF#,   readonly);   
   constant Reg_Gameboy_Rerserved_FF2E    : regmap_type := (16#FF2E#,   7,      0,        1,  16#FF#,   readonly);   
   constant Reg_Gameboy_Rerserved_FF2F    : regmap_type := (16#FF2F#,   7,      0,        1,  16#FF#,   readonly);  
   
   constant Reg_Gameboy_Rerserved_FF4C    : regmap_type := (16#FF4C#,   7,      0,        1,  16#FF#,   readonly);   
   constant Reg_Gameboy_Rerserved_FF4E    : regmap_type := (16#FF4E#,   7,      0,        1,  16#FF#,   readonly);  
   
   constant Reg_Gameboy_Rerserved_FF57    : regmap_type := (16#FF57#,   7,      0,        1,  16#FF#,   readonly);   
   constant Reg_Gameboy_Rerserved_FF58    : regmap_type := (16#FF58#,   7,      0,        1,  16#FF#,   readonly);   
   constant Reg_Gameboy_Rerserved_FF59    : regmap_type := (16#FF59#,   7,      0,        1,  16#FF#,   readonly);   
   constant Reg_Gameboy_Rerserved_FF5A    : regmap_type := (16#FF5A#,   7,      0,        1,  16#FF#,   readonly);   
   constant Reg_Gameboy_Rerserved_FF5B    : regmap_type := (16#FF5B#,   7,      0,        1,  16#FF#,   readonly);   
   constant Reg_Gameboy_Rerserved_FF5C    : regmap_type := (16#FF5C#,   7,      0,        1,  16#FF#,   readonly);   
   constant Reg_Gameboy_Rerserved_FF5D    : regmap_type := (16#FF5D#,   7,      0,        1,  16#FF#,   readonly);   
   constant Reg_Gameboy_Rerserved_FF5E    : regmap_type := (16#FF5E#,   7,      0,        1,  16#FF#,   readonly);   
   constant Reg_Gameboy_Rerserved_FF5F    : regmap_type := (16#FF5F#,   7,      0,        1,  16#FF#,   readonly);   
   constant Reg_Gameboy_Rerserved_FF60    : regmap_type := (16#FF60#,   7,      0,        1,  16#FF#,   readonly);   
   constant Reg_Gameboy_Rerserved_FF61    : regmap_type := (16#FF61#,   7,      0,        1,  16#FF#,   readonly);   
   constant Reg_Gameboy_Rerserved_FF62    : regmap_type := (16#FF62#,   7,      0,        1,  16#FF#,   readonly);   
   constant Reg_Gameboy_Rerserved_FF63    : regmap_type := (16#FF63#,   7,      0,        1,  16#FF#,   readonly);   
   constant Reg_Gameboy_Rerserved_FF64    : regmap_type := (16#FF64#,   7,      0,        1,  16#FF#,   readonly);   
   constant Reg_Gameboy_Rerserved_FF65    : regmap_type := (16#FF65#,   7,      0,        1,  16#FF#,   readonly);   
   constant Reg_Gameboy_Rerserved_FF66    : regmap_type := (16#FF66#,   7,      0,        1,  16#FF#,   readonly);   
   constant Reg_Gameboy_Rerserved_FF67    : regmap_type := (16#FF67#,   7,      0,        1,  16#FF#,   readonly); 
   
   constant Reg_Gameboy_Rerserved_FF6D    : regmap_type := (16#FF6D#,   7,      0,        1,  16#FF#,   readonly);  
   constant Reg_Gameboy_Rerserved_FF6E    : regmap_type := (16#FF6E#,   7,      0,        1,  16#FF#,   readonly);  
   constant Reg_Gameboy_Rerserved_FF6F    : regmap_type := (16#FF6F#,   7,      0,        1,  16#FF#,   readonly); 
   
   constant Reg_Gameboy_Rerserved_FF71    : regmap_type := (16#FF71#,   7,      0,        1,  16#FF#,   readonly);
   
   constant Reg_Gameboy_Rerserved_FF78    : regmap_type := (16#FF78#,   7,      0,        1,  16#FF#,   readonly);  
   constant Reg_Gameboy_Rerserved_FF79    : regmap_type := (16#FF79#,   7,      0,        1,  16#FF#,   readonly);  
   constant Reg_Gameboy_Rerserved_FF7A    : regmap_type := (16#FF7A#,   7,      0,        1,  16#FF#,   readonly);  
   constant Reg_Gameboy_Rerserved_FF7B    : regmap_type := (16#FF7B#,   7,      0,        1,  16#FF#,   readonly);  
   constant Reg_Gameboy_Rerserved_FF7C    : regmap_type := (16#FF7C#,   7,      0,        1,  16#FF#,   readonly);  
   constant Reg_Gameboy_Rerserved_FF7D    : regmap_type := (16#FF7D#,   7,      0,        1,  16#FF#,   readonly);  
   constant Reg_Gameboy_Rerserved_FF7E    : regmap_type := (16#FF7E#,   7,      0,        1,  16#FF#,   readonly);  
   constant Reg_Gameboy_Rerserved_FF7F    : regmap_type := (16#FF7F#,   7,      0,        1,  16#FF#,   readonly);  
   
   constant Reg_Gameboy_Rerserved_FF6C    : regmap_type := (16#FF6C#,   7,      0,        1,  16#FF#,   readonly); -- Undocumented (FEh) - Bit 0 (Read/Write) - CGB Mode Only
   constant Reg_Gameboy_Rerserved_FF72    : regmap_type := (16#FF72#,   7,      0,        1,  16#FF#,   readonly); -- Undocumented (00h) - Bit 0-7 (Read/Write)
   constant Reg_Gameboy_Rerserved_FF73    : regmap_type := (16#FF73#,   7,      0,        1,  16#FF#,   readonly); -- Undocumented (00h) - Bit 0-7 (Read/Write)
   constant Reg_Gameboy_Rerserved_FF74    : regmap_type := (16#FF74#,   7,      0,        1,  16#FF#,   readonly); -- Undocumented (00h) - Bit 0-7 (Read/Write) - CGB Mode Only
   constant Reg_Gameboy_Rerserved_FF75    : regmap_type := (16#FF75#,   7,      0,        1,  16#FF#,   readonly); -- Undocumented (8Fh) - Bit 4-6 (Read/Write)
   constant Reg_Gameboy_Rerserved_FF76    : regmap_type := (16#FF76#,   7,      0,        1,  16#FF#,   readonly); -- Undocumented (00h) - Always 00h (Read Only)
   constant Reg_Gameboy_Rerserved_FF77    : regmap_type := (16#FF77#,   7,      0,        1,  16#FF#,   readonly); -- Undocumented (00h) - Always 00h (Read Only)
         
end package;
