library IEEE;
use IEEE.std_logic_1164.all;  
use IEEE.numeric_std.all;     

use work.pProc_bus_gb.all;
use work.pRegmap.all;

package pReg_gb_mixed is

   -- range FF0F .. FFFF
   --   (                                                       adr      upper    lower    size  default   accesstype)                                     
   constant Reg_Gameboy_IRPFlag               : regmap_type := (16#FF0F#,   7,      0,        1,       0,   readwrite);   
   constant Reg_Gameboy_IRPFlag_VBlank        : regmap_type := (16#FF0F#,   0,      0,        1,       0,   readwrite);   
   constant Reg_Gameboy_IRPFlag_LCDStat       : regmap_type := (16#FF0F#,   1,      1,        1,       0,   readwrite);   
   constant Reg_Gameboy_IRPFlag_Timer         : regmap_type := (16#FF0F#,   2,      2,        1,       0,   readwrite);   
   constant Reg_Gameboy_IRPFlag_Serial        : regmap_type := (16#FF0F#,   3,      3,        1,       0,   readwrite);   
   constant Reg_Gameboy_IRPFlag_Joypad        : regmap_type := (16#FF0F#,   4,      4,        1,       0,   readwrite);   
   
   constant Reg_Gameboy_SpeedSwitch           : regmap_type := (16#FF4D#,   7,      0,        1,       0,   readwrite);   
   constant Reg_Gameboy_SpeedSwitch_Current   : regmap_type := (16#FF4D#,   7,      7,        1,       0,   readonly);   
   constant Reg_Gameboy_SpeedSwitch_Prepare   : regmap_type := (16#FF4D#,   0,      0,        1,       0,   readwrite);   
   
   constant Reg_Gameboy_BootRomSwitch         : regmap_type := (16#FF50#,   0,      0,        1,       1,   writeonly); 
   
   constant Reg_Gameboy_Infrared              : regmap_type := (16#FF56#,   7,      0,        1,  16#FF#,   readwrite);
   
   constant Reg_Gameboy_IRPEnable             : regmap_type := (16#FFFF#,   7,      0,        1,       0,   readwrite);   
   constant Reg_Gameboy_IRPEnable_VBlank      : regmap_type := (16#FFFF#,   0,      0,        1,       0,   readwrite);   
   constant Reg_Gameboy_IRPEnable_LCDStat     : regmap_type := (16#FFFF#,   1,      1,        1,       0,   readwrite);   
   constant Reg_Gameboy_IRPEnable_Timer       : regmap_type := (16#FFFF#,   2,      2,        1,       0,   readwrite);   
   constant Reg_Gameboy_IRPEnable_Serial      : regmap_type := (16#FFFF#,   3,      3,        1,       0,   readwrite);   
   constant Reg_Gameboy_IRPEnable_Joypad      : regmap_type := (16#FFFF#,   4,      4,        1,       0,   readwrite);  
   
end package;
