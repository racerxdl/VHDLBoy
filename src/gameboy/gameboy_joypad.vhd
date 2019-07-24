library IEEE;
use IEEE.std_logic_1164.all;  
use IEEE.numeric_std.all;     

use work.pProc_bus_gb.all;
use work.pReg_gb_joypad.all;

entity gameboy_joypad is
   port 
   (
      clk100            : in    std_logic;  
      gb_bus            : inout proc_bus_gb_type := ((others => 'Z'), (others => 'Z'), (others => 'Z'), 'Z', 'Z', 'Z');
      
      Gameboy_KeyUp     : in    std_logic;
      Gameboy_KeyDown   : in    std_logic;
      Gameboy_KeyLeft   : in    std_logic;
      Gameboy_KeyRight  : in    std_logic;
      Gameboy_KeyA      : in    std_logic;
      Gameboy_KeyB      : in    std_logic;
      Gameboy_KeyStart  : in    std_logic;
      Gameboy_KeySelect : in    std_logic
   );
end entity;

architecture arch of gameboy_joypad is

   signal Gameboy_Joypad_reserved  : std_logic_vector(Reg_Gameboy_Joypad_reserved .upper downto Reg_Gameboy_Joypad_reserved .lower) := (others => '0');
   signal Gameboy_Joypad_P15       : std_logic_vector(Reg_Gameboy_Joypad_P15      .upper downto Reg_Gameboy_Joypad_P15      .lower) := (others => '0');
   signal Gameboy_Joypad_P14       : std_logic_vector(Reg_Gameboy_Joypad_P14      .upper downto Reg_Gameboy_Joypad_P14      .lower) := (others => '0');
   signal Gameboy_Joypad_DownStart : std_logic_vector(Reg_Gameboy_Joypad_DownStart.upper downto Reg_Gameboy_Joypad_DownStart.lower) := (others => '0');
   signal Gameboy_Joypad_UpSelect  : std_logic_vector(Reg_Gameboy_Joypad_UpSelect .upper downto Reg_Gameboy_Joypad_UpSelect .lower) := (others => '0');
   signal Gameboy_Joypad_LeftA     : std_logic_vector(Reg_Gameboy_Joypad_LeftA    .upper downto Reg_Gameboy_Joypad_LeftA    .lower) := (others => '0');
   signal Gameboy_Joypad_RightB    : std_logic_vector(Reg_Gameboy_Joypad_RightB   .upper downto Reg_Gameboy_Joypad_RightB   .lower) := (others => '0');

begin 

   iReg_Gameboy_Joypad_reserved  : entity work.eProcReg generic map (Reg_Gameboy_Joypad_reserved ) port map  (clk100, gb_bus, Gameboy_Joypad_reserved);  
   iReg_Gameboy_Joypad_P15       : entity work.eProcReg generic map (Reg_Gameboy_Joypad_P15      ) port map  (clk100, gb_bus, Gameboy_Joypad_P15      , Gameboy_Joypad_P15);  
   iReg_Gameboy_Joypad_P14       : entity work.eProcReg generic map (Reg_Gameboy_Joypad_P14      ) port map  (clk100, gb_bus, Gameboy_Joypad_P14      , Gameboy_Joypad_P14);  
   iReg_Gameboy_Joypad_DownStart : entity work.eProcReg generic map (Reg_Gameboy_Joypad_DownStart) port map  (clk100, gb_bus, Gameboy_Joypad_DownStart);  
   iReg_Gameboy_Joypad_UpSelect  : entity work.eProcReg generic map (Reg_Gameboy_Joypad_UpSelect ) port map  (clk100, gb_bus, Gameboy_Joypad_UpSelect );  
   iReg_Gameboy_Joypad_LeftA     : entity work.eProcReg generic map (Reg_Gameboy_Joypad_LeftA    ) port map  (clk100, gb_bus, Gameboy_Joypad_LeftA    );  
   iReg_Gameboy_Joypad_RightB    : entity work.eProcReg generic map (Reg_Gameboy_Joypad_RightB   ) port map  (clk100, gb_bus, Gameboy_Joypad_RightB   );  
  
  
   process (clk100)
   begin
      if rising_edge(clk100) then
      
         if (Gameboy_Joypad_P14 = "0") then
            Gameboy_Joypad_DownStart(Gameboy_Joypad_DownStart'left) <= not Gameboy_KeyDown;
            Gameboy_Joypad_UpSelect(Gameboy_Joypad_UpSelect'left)   <= not Gameboy_KeyUp;
            Gameboy_Joypad_LeftA(Gameboy_Joypad_LeftA'left)         <= not Gameboy_KeyLeft;
            Gameboy_Joypad_RightB(Gameboy_Joypad_RightB'left)       <= not Gameboy_KeyRight;
         else
            Gameboy_Joypad_DownStart(Gameboy_Joypad_DownStart'left) <= not Gameboy_KeyStart;
            Gameboy_Joypad_UpSelect(Gameboy_Joypad_UpSelect'left)   <= not Gameboy_KeySelect;
            Gameboy_Joypad_LeftA(Gameboy_Joypad_LeftA'left)         <= not Gameboy_KeyA;
            Gameboy_Joypad_RightB(Gameboy_Joypad_RightB'left)       <= not Gameboy_KeyB;
         end if;
      
      end if;
   end process; 
    

end architecture;





