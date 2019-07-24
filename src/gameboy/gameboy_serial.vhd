library IEEE;
use IEEE.std_logic_1164.all;  
use IEEE.numeric_std.all;     

use work.pProc_bus_gb.all;
use work.pReg_gb_serial.all;
use work.pReg_gb_mixed.all;

entity gameboy_serial is
   port 
   (
      clk100  : in    std_logic;  
      gb_bus  : inout proc_bus_gb_type := ((others => 'Z'), (others => 'Z'), (others => 'Z'), 'Z', 'Z', 'Z')
   );
end entity;

architecture arch of gameboy_serial is

   signal Gameboy_Infrared : std_logic_vector(Reg_Gameboy_Infrared.upper downto Reg_Gameboy_Infrared.lower) := (others => '0');
   
   signal Gameboy_SerialData          : std_logic_vector(Reg_Gameboy_SerialData         .upper downto Reg_Gameboy_SerialData         .lower) := (others => '0');
   signal Gameboy_SerialControl_Start : std_logic_vector(Reg_Gameboy_SerialControl_Start.upper downto Reg_Gameboy_SerialControl_Start.lower) := (others => '0');
   signal Gameboy_SerialControl_Speed : std_logic_vector(Reg_Gameboy_SerialControl_Speed.upper downto Reg_Gameboy_SerialControl_Speed.lower) := (others => '0');
   signal Gameboy_SerialControl_Clock : std_logic_vector(Reg_Gameboy_SerialControl_Clock.upper downto Reg_Gameboy_SerialControl_Clock.lower) := (others => '0');


begin 

   iReg_Gameboy_Infrared : entity work.eProcReg generic map (Reg_Gameboy_Infrared) port map  (clk100, gb_bus, Gameboy_Infrared, Gameboy_Infrared);  
   
   iReg_Gameboy_SerialData          : entity work.eProcReg generic map (Reg_Gameboy_SerialData         ) port map  (clk100, gb_bus, Gameboy_SerialData         , Gameboy_SerialData         );  
   iReg_Gameboy_SerialControl_Start : entity work.eProcReg generic map (Reg_Gameboy_SerialControl_Start) port map  (clk100, gb_bus, Gameboy_SerialControl_Start, Gameboy_SerialControl_Start);  
   iReg_Gameboy_SerialControl_Speed : entity work.eProcReg generic map (Reg_Gameboy_SerialControl_Speed) port map  (clk100, gb_bus, Gameboy_SerialControl_Speed, Gameboy_SerialControl_Speed);  
   iReg_Gameboy_SerialControl_Clock : entity work.eProcReg generic map (Reg_Gameboy_SerialControl_Clock) port map  (clk100, gb_bus, Gameboy_SerialControl_Clock, Gameboy_SerialControl_Clock);  
    

end architecture;





