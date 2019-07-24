library IEEE;
use IEEE.std_logic_1164.all;  
use IEEE.numeric_std.all;     

use work.pProc_bus_gb.all;
use work.pRegmap.all;

package pReg_gb_timer is

   -- range FF04 .. FF07
   --   (                                                   adr      upper    lower    size  default   accesstype)
   constant Reg_Gameboy_DivReg            : regmap_type := (16#FF04#,   7,      0,        1,       0,   readwrite);
   constant Reg_Gameboy_TimeCnt           : regmap_type := (16#FF05#,   7,      0,        1,       0,   readwrite);
   constant Reg_Gameboy_TimeMod           : regmap_type := (16#FF06#,   7,      0,        1,       0,   readwrite);
                                         
   constant Reg_Gameboy_TimeControl       : regmap_type := (16#FF07#,   7,      0,        1,       0,   readwrite);   
   constant Reg_Gameboy_TimeControl_Start : regmap_type := (16#FF07#,   2,      2,        1,       0,   readwrite);   
   constant Reg_Gameboy_TimeControl_Clock : regmap_type := (16#FF07#,   1,      0,        1,       0,   readwrite);   
   
end package;
