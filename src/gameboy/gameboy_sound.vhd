library IEEE;
use IEEE.std_logic_1164.all;  
use IEEE.numeric_std.all;     

use work.pProc_bus_gb.all;
use work.pReg_gb_sound.all;

entity gameboy_sound is
   port 
   (
      clk100              : in    std_logic;  
      gb_bus              : inout proc_bus_gb_type := ((others => 'Z'), (others => 'Z'), (others => 'Z'), 'Z', 'Z', 'Z');
      
      sound_out           : out   std_logic_vector(15 downto 0) := (others => '0')
   );
end entity;

architecture arch of gameboy_sound is
                                                                                                                                                                                                                                                                                                                        
   signal Gameboy_SoundCtrl_ChannelCtrl    : std_logic_vector(Reg_Gameboy_SoundCtrl_ChannelCtrl   .upper downto Reg_Gameboy_SoundCtrl_ChannelCtrl   .lower) := (others => '0');
   signal Gameboy_SoundCtrl_OutputTerminal : std_logic_vector(Reg_Gameboy_SoundCtrl_OutputTerminal.upper downto Reg_Gameboy_SoundCtrl_OutputTerminal.lower) := (others => '0');
   
   signal Gameboy_SoundCtrl_SoundOnOff     : std_logic_vector(Reg_Gameboy_SoundCtrl_SoundOnOff    .upper downto Reg_Gameboy_SoundCtrl_SoundOnOff    .lower) := (others => '0');
   signal Gameboy_SoundCtrl_SoundOnOff_rb  : std_logic_vector(Reg_Gameboy_SoundCtrl_SoundOnOff    .upper downto Reg_Gameboy_SoundCtrl_SoundOnOff    .lower) := (others => '0');
               

   signal new_cycles          : unsigned(7 downto 0) := (others => '0');
   signal new_cycles_slow     : unsigned(7 downto 0) := (others => '0');
   signal new_cycles_valid    : std_logic := '0';

   signal sound_out_ch1 : signed(15 downto 0);
   signal sound_out_ch2 : signed(15 downto 0);
   signal sound_out_ch3 : signed(15 downto 0);
   signal sound_out_ch4 : signed(15 downto 0);
   
   signal sound_on_ch1  : std_logic;
   signal sound_on_ch2  : std_logic;
   signal sound_on_ch3  : std_logic;
   signal sound_on_ch4  : std_logic;
   
   signal soundmix1 : signed(15 downto 0) := (others => '0'); 
   signal soundmix2 : signed(15 downto 0) := (others => '0'); 
   signal soundmix3 : signed(15 downto 0) := (others => '0'); 
   signal soundmix4 : signed(15 downto 0) := (others => '0'); 
   
           
begin 
                                                                                                                 
   iReg_Gameboy_SoundCtrl_ChannelCtrl    : entity work.eProcReg generic map ( Reg_Gameboy_SoundCtrl_ChannelCtrl    ) port map  (clk100, gb_bus, Gameboy_SoundCtrl_ChannelCtrl   , Gameboy_SoundCtrl_ChannelCtrl   );  
   iReg_Gameboy_SoundCtrl_OutputTerminal : entity work.eProcReg generic map ( Reg_Gameboy_SoundCtrl_OutputTerminal ) port map  (clk100, gb_bus, Gameboy_SoundCtrl_OutputTerminal, Gameboy_SoundCtrl_OutputTerminal);  
   iReg_Gameboy_SoundCtrl_SoundOnOff     : entity work.eProcReg generic map ( Reg_Gameboy_SoundCtrl_SoundOnOff     ) port map  (clk100, gb_bus, Gameboy_SoundCtrl_SoundOnOff_rb , Gameboy_SoundCtrl_SoundOnOff    );  

   Gameboy_SoundCtrl_SoundOnOff_rb <= Gameboy_SoundCtrl_SoundOnOff(7) & "000" & sound_on_ch4 & sound_on_ch3 & sound_on_ch2 & sound_on_ch1;
    
   igameboy_sound_ch1 : entity work.gameboy_sound_ch1
   generic map
   (
      has_sweep               => true,
      Reg_Channel_Sweep       => Reg_Gameboy_Channel1_Sweep,      
      Reg_Channel_DutyPattern => Reg_Gameboy_Channel1_DutyPattern,
      Reg_Channel_VolEnvelope => Reg_Gameboy_Channel1_VolEnvelope,
      Reg_Channel_FreqLow     => Reg_Gameboy_Channel1_FreqLow,    
      Reg_Channel_FreqHigh    => Reg_Gameboy_Channel1_FreqHigh  
   )
   port map
   (
      clk100           => clk100,          
      gb_bus           => gb_bus,          
      new_cycles       => new_cycles,      
      new_cycles_valid => new_cycles_valid,
      sound_out        => sound_out_ch1,
      sound_on         => sound_on_ch1 
   );
    
   igameboy_sound_ch2 : entity work.gameboy_sound_ch1
   generic map
   (
      has_sweep               => false,
      Reg_Channel_Sweep       => Reg_Gameboy_Channel1_Sweep,      -- unused
      Reg_Channel_DutyPattern => Reg_Gameboy_Channel2_DutyPattern,
      Reg_Channel_VolEnvelope => Reg_Gameboy_Channel2_VolEnvelope,
      Reg_Channel_FreqLow     => Reg_Gameboy_Channel2_FreqLow,    
      Reg_Channel_FreqHigh    => Reg_Gameboy_Channel2_FreqHigh  
   )
   port map
   (
      clk100           => clk100,          
      gb_bus           => gb_bus,          
      new_cycles       => new_cycles,      
      new_cycles_valid => new_cycles_valid,
      sound_out        => sound_out_ch2,
      sound_on         => sound_on_ch2 
   );
   
   igameboy_sound_ch3 : entity work.gameboy_sound_ch3
   port map
   (
      clk100           => clk100,          
      gb_bus           => gb_bus,          
      new_cycles       => new_cycles,      
      new_cycles_valid => new_cycles_valid,
      sound_out        => sound_out_ch3,
      sound_on         => sound_on_ch3 
   );
   
   igameboy_sound_ch4 : entity work.gameboy_sound_ch4
   port map
   (
      clk100           => clk100,          
      gb_bus           => gb_bus,          
      new_cycles       => new_cycles,      
      new_cycles_valid => new_cycles_valid,
      sound_out        => sound_out_ch4,
      sound_on         => sound_on_ch4 
   );
   
   new_cycles <= x"04";
   
   -- todo: stereo
   -- todo : volume_left/right
   process (clk100)
   begin
      if rising_edge(clk100) then
         
         -- generate exact timing, cannot use gameboy time
         new_cycles_valid <= '0';
                
         if (new_cycles_slow < 99) then
            new_cycles_slow <= new_cycles_slow + 1;
         else
            new_cycles_slow  <= (others => '0');
            new_cycles_valid <= '1';
         end if;
         
         -- sound channel mixing
         if (sound_on_ch1 = '1' and (Gameboy_SoundCtrl_OutputTerminal(0) = '1'or Gameboy_SoundCtrl_OutputTerminal(4) = '1')) then
            soundmix1 <= sound_out_ch1;
         else
            soundmix1 <= (others => '0');
         end if;
         
         if (sound_on_ch2 = '1' and (Gameboy_SoundCtrl_OutputTerminal(1) = '1'or Gameboy_SoundCtrl_OutputTerminal(5) = '1')) then
            soundmix2 <= soundmix1 + sound_out_ch2;
         else
            soundmix2 <= soundmix1;
         end if;
         
         if (sound_on_ch3 = '1' and (Gameboy_SoundCtrl_OutputTerminal(2) = '1'or Gameboy_SoundCtrl_OutputTerminal(6) = '1')) then
            soundmix3 <= soundmix2 + sound_out_ch3;
         else
            soundmix3 <= soundmix2;
         end if;
         
         if (sound_on_ch4 = '1' and (Gameboy_SoundCtrl_OutputTerminal(3) = '1'or Gameboy_SoundCtrl_OutputTerminal(7) = '1')) then
            soundmix4 <= soundmix3 + sound_out_ch4;
         else
            soundmix4 <= soundmix3;
         end if;
         
         sound_out <= std_logic_vector(soundmix4);
      
      end if;
   end process;
    
end architecture;





