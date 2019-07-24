library IEEE;
use IEEE.std_logic_1164.all;  
use IEEE.numeric_std.all;     

use work.pProc_bus_gb.all;
use work.pRegmap.all;

package pReg_gb_display is

   -- range FF40 .. FF7F
   --   (                                                                adr      upper    lower    size  default   accesstype)                                     
   constant Reg_Gameboy_LCDControl                    : regmap_type := (16#FF40#,   7,      0,        1,       0,   readwrite);   
   constant Reg_Gameboy_LCDControl_LCDEnable          : regmap_type := (16#FF40#,   7,      7,        1,       0,   readwrite);   
   constant Reg_Gameboy_LCDControl_WindowMapSelect    : regmap_type := (16#FF40#,   6,      6,        1,       0,   readwrite);   
   constant Reg_Gameboy_LCDControl_WindowEnable       : regmap_type := (16#FF40#,   5,      5,        1,       0,   readwrite);   
   constant Reg_Gameboy_LCDControl_BGWindowTileSelect : regmap_type := (16#FF40#,   4,      4,        1,       0,   readwrite);   
   constant Reg_Gameboy_LCDControl_BGMapSelect        : regmap_type := (16#FF40#,   3,      3,        1,       0,   readwrite);   
   constant Reg_Gameboy_LCDControl_OBJSize            : regmap_type := (16#FF40#,   2,      2,        1,       0,   readwrite);   
   constant Reg_Gameboy_LCDControl_ObjEnable          : regmap_type := (16#FF40#,   1,      1,        1,       0,   readwrite);   
   constant Reg_Gameboy_LCDControl_BGEnable           : regmap_type := (16#FF40#,   0,      0,        1,       0,   readwrite);   
    
   constant Reg_Gameboy_LCDStatus                     : regmap_type := (16#FF41#,   7,      0,        1,       0,   readwrite);   
   constant Reg_Gameboy_LCDStatus_LineCoincidenceIRP  : regmap_type := (16#FF41#,   6,      6,        1,       0,   readwrite);   
   constant Reg_Gameboy_LCDStatus_Mode2OAMIRP         : regmap_type := (16#FF41#,   5,      5,        1,       0,   readwrite);   
   constant Reg_Gameboy_LCDStatus_Mode1VBlankIRP      : regmap_type := (16#FF41#,   4,      4,        1,       0,   readwrite);   
   constant Reg_Gameboy_LCDStatus_Mode0HBlankIRP      : regmap_type := (16#FF41#,   3,      3,        1,       0,   readwrite);   
   constant Reg_Gameboy_LCDStatus_LineCoincidence     : regmap_type := (16#FF41#,   2,      2,        1,       0,   readonly);   
   constant Reg_Gameboy_LCDStatus_Mode                : regmap_type := (16#FF41#,   1,      0,        1,       0,   readonly);   

   constant Reg_Gameboy_LCDSCrollY                    : regmap_type := (16#FF42#,   7,      0,        1,       0,   readwrite);
   constant Reg_Gameboy_LCDSCrollX                    : regmap_type := (16#FF43#,   7,      0,        1,       0,   readwrite);
   
   constant Reg_Gameboy_LCDLineY                      : regmap_type := (16#FF44#,   7,      0,        1,       0,   readwrite);
   constant Reg_Gameboy_LCDLineYCompare               : regmap_type := (16#FF45#,   7,      0,        1,       0,   readwrite);
   
   constant Reg_Gameboy_OAMDMA                        : regmap_type := (16#FF46#,   7,      0,        1,       0,   writeonly);
   
   constant Reg_Gameboy_BGPalette                     : regmap_type := (16#FF47#,   7,      0,        1,       0,   readwrite);
   constant Reg_Gameboy_OBP0Palette                   : regmap_type := (16#FF48#,   7,      0,        1,       0,   readwrite);
   constant Reg_Gameboy_OBP1Palette                   : regmap_type := (16#FF49#,   7,      0,        1,       0,   readwrite);
   
   constant Reg_Gameboy_WindowY                       : regmap_type := (16#FF4A#,   7,      0,        1,       0,   readwrite);
   constant Reg_Gameboy_WindowX                       : regmap_type := (16#FF4B#,   7,      0,        1,       0,   readwrite);
    
   constant Reg_Gameboy_HDMA1_SourceHigh              : regmap_type := (16#FF51#,   7,      0,        1,       0,   readwrite);
   constant Reg_Gameboy_HDMA2_SourceLow               : regmap_type := (16#FF52#,   7,      0,        1,       0,   readwrite);
   constant Reg_Gameboy_HDMA3_DestHigh                : regmap_type := (16#FF53#,   7,      0,        1,       0,   readwrite);
   constant Reg_Gameboy_HDMA4_DestLow                 : regmap_type := (16#FF54#,   7,      0,        1,       0,   readwrite);
   constant Reg_Gameboy_HDMA5                         : regmap_type := (16#FF55#,   7,      0,        1,       0,   readwrite);
   constant Reg_Gameboy_HDMA5_Mode                    : regmap_type := (16#FF55#,   7,      7,        1,       0,   readwrite);
   constant Reg_Gameboy_HDMA5_Length                  : regmap_type := (16#FF55#,   6,      0,        1,       0,   readwrite);
   
   constant Reg_Gameboy_CGB_BGPalette                 : regmap_type := (16#FF68#,   7,      0,        1,       0,   readwrite);
   constant Reg_Gameboy_CGB_BGPalette_AutoInc         : regmap_type := (16#FF68#,   7,      7,        1,       0,   readwrite);
   constant Reg_Gameboy_CGB_BGPalette_Index           : regmap_type := (16#FF68#,   5,      0,        1,       0,   readwrite);
   constant Reg_Gameboy_CGB_BGPaletteData             : regmap_type := (16#FF69#,   7,      0,        1,       0,   readwrite);
   
   constant Reg_Gameboy_CGB_ObjPalette                : regmap_type := (16#FF6A#,   7,      0,        1,       0,   readwrite);
   constant Reg_Gameboy_CGB_ObjPalette_AutoInc        : regmap_type := (16#FF6A#,   7,      7,        1,       0,   readwrite);
   constant Reg_Gameboy_CGB_ObjPalette_Index          : regmap_type := (16#FF6A#,   5,      0,        1,       0,   readwrite);
   constant Reg_Gameboy_CGB_ObjPaletteData            : regmap_type := (16#FF6B#,   7,      0,        1,       0,   readwrite);
    
    
end package;
