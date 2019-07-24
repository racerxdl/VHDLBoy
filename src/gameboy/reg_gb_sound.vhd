library IEEE;
use IEEE.std_logic_1164.all;  
use IEEE.numeric_std.all;     

use work.pProc_bus_gb.all;
use work.pRegmap.all;

package pReg_gb_sound is

   -- range FF10 .. FF3F
   --   (                                                           adr      upper    lower    size  default   accesstype)                                     
   constant Reg_Gameboy_Channel1_Sweep           : regmap_type := (16#FF10#,   7,      0,        1,       0,   readwrite);   
   constant Reg_Gameboy_Channel1_DutyPattern     : regmap_type := (16#FF11#,   7,      0,        1,       0,   readwrite);   
   constant Reg_Gameboy_Channel1_VolEnvelope     : regmap_type := (16#FF12#,   7,      0,        1,       0,   readwrite);   
   constant Reg_Gameboy_Channel1_FreqLow         : regmap_type := (16#FF13#,   7,      0,        1,       0,   readwrite);   
   constant Reg_Gameboy_Channel1_FreqHigh        : regmap_type := (16#FF14#,   7,      0,        1,       0,   readwrite);   
   
   constant Reg_Gameboy_Channel2_DutyPattern     : regmap_type := (16#FF16#,   7,      0,        1,       0,   readwrite);   
   constant Reg_Gameboy_Channel2_VolEnvelope     : regmap_type := (16#FF17#,   7,      0,        1,       0,   readwrite);   
   constant Reg_Gameboy_Channel2_FreqLow         : regmap_type := (16#FF18#,   7,      0,        1,       0,   readwrite);   
   constant Reg_Gameboy_Channel2_FreqHigh        : regmap_type := (16#FF19#,   7,      0,        1,       0,   readwrite);   
   
   constant Reg_Gameboy_Channel3_OnOFF           : regmap_type := (16#FF1A#,   7,      0,        1,       0,   readwrite);   
   constant Reg_Gameboy_Channel3_Length          : regmap_type := (16#FF1B#,   7,      0,        1,       0,   readwrite);   
   constant Reg_Gameboy_Channel3_OutputLevel     : regmap_type := (16#FF1C#,   7,      0,        1,       0,   readwrite);   
   constant Reg_Gameboy_Channel3_FreqLow         : regmap_type := (16#FF1D#,   7,      0,        1,       0,   readwrite);   
   constant Reg_Gameboy_Channel3_FreqHigh        : regmap_type := (16#FF1E#,   7,      0,        1,       0,   readwrite);   
   
   constant Reg_Gameboy_Channel4_Length          : regmap_type := (16#FF20#,   7,      0,        1,       0,   readwrite);   
   constant Reg_Gameboy_Channel4_VolEnvelope     : regmap_type := (16#FF21#,   7,      0,        1,       0,   readwrite);   
   constant Reg_Gameboy_Channel4_PolyCounter     : regmap_type := (16#FF22#,   7,      0,        1,       0,   readwrite);   
   constant Reg_Gameboy_Channel4_CounterInit     : regmap_type := (16#FF23#,   7,      0,        1,       0,   readwrite);   
   
   constant Reg_Gameboy_SoundCtrl_ChannelCtrl    : regmap_type := (16#FF24#,   7,      0,        1,       0,   readwrite);   
   constant Reg_Gameboy_SoundCtrl_OutputTerminal : regmap_type := (16#FF25#,   7,      0,        1,       0,   readwrite);   
   constant Reg_Gameboy_SoundCtrl_SoundOnOff     : regmap_type := (16#FF26#,   7,      0,        1,       0,   readwrite);   
   
   constant Reg_Gameboy_SoundCtrl_WaveRam        : regmap_type := (16#FF30#,   7,      0,       16,       0,   readwrite);   
   
end package;
