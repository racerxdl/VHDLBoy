library IEEE;
use IEEE.std_logic_1164.all;  
use IEEE.numeric_std.all;     

use work.pProc_bus_gb.all;
use work.pRegmap.all;

package pReg_gb_joypad is

   -- range FF00 .. FF00
   --   (                                                   adr      upper    lower    size  default   accesstype)                                     
   constant Reg_Gameboy_Joypad           : regmap_type := (16#FF00#,   7,      0,        1,       0,   readwrite);   
   constant Reg_Gameboy_Joypad_reserved  : regmap_type := (16#FF00#,   7,      6,        1,       3,   readonly);   
   constant Reg_Gameboy_Joypad_P15       : regmap_type := (16#FF00#,   5,      5,        1,       0,   readwrite);   
   constant Reg_Gameboy_Joypad_P14       : regmap_type := (16#FF00#,   4,      4,        1,       0,   readwrite);   
   constant Reg_Gameboy_Joypad_DownStart : regmap_type := (16#FF00#,   3,      3,        1,       0,   readonly);   
   constant Reg_Gameboy_Joypad_UpSelect  : regmap_type := (16#FF00#,   2,      2,        1,       0,   readonly);   
   constant Reg_Gameboy_Joypad_LeftA     : regmap_type := (16#FF00#,   1,      1,        1,       0,   readonly);   
   constant Reg_Gameboy_Joypad_RightB    : regmap_type := (16#FF00#,   0,      0,        1,       0,   readonly);   
   
end package;
