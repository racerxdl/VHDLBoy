library IEEE;
use IEEE.std_logic_1164.all;  
use IEEE.numeric_std.all;     

use work.pProc_bus_gb.all;
use work.pRegmap.all;

package pReg_gb_serial is

   -- range FF01 .. FF02
   --   (                                                       adr      upper    lower    size  default   accesstype)                                     
   constant Reg_Gameboy_SerialData            : regmap_type := (16#FF01#,   7,      0,        1,       0,   readwrite);   
   
   constant Reg_Gameboy_SerialControl         : regmap_type := (16#FF02#,   7,      0,        1,       0,   readwrite);   
   constant Reg_Gameboy_SerialControl_Start   : regmap_type := (16#FF02#,   7,      7,        1,       0,   readwrite);   
   constant Reg_Gameboy_SerialControl_Speed   : regmap_type := (16#FF02#,   1,      1,        1,       0,   readwrite);   
   constant Reg_Gameboy_SerialControl_Clock   : regmap_type := (16#FF02#,   0,      0,        1,       0,   readwrite);   
      
end package;
