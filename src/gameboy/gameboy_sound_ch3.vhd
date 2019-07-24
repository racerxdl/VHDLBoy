library IEEE;
use IEEE.std_logic_1164.all;  
use IEEE.numeric_std.all;     

use work.pRegmap.all;
use work.pProc_bus_gb.all;
use work.pReg_gb_sound.all;

entity gameboy_sound_ch3 is
   port 
   (
      clk100              : in    std_logic;  
      gb_bus              : inout proc_bus_gb_type := ((others => 'Z'), (others => 'Z'), (others => 'Z'), 'Z', 'Z', 'Z');
      
      new_cycles          : in    unsigned(7 downto 0);
      new_cycles_valid    : in    std_logic;
      
      sound_out           : out   signed(15 downto 0) := (others => '0');
      sound_on            : out   std_logic := '0'
   );
end entity;

architecture arch of gameboy_sound_ch3 is

   signal Gameboy_Channel3_OnOFF           : std_logic_vector(Reg_Gameboy_Channel3_OnOFF          .upper downto Reg_Gameboy_Channel3_OnOFF          .lower) := (others => '0');
   signal Gameboy_Channel3_Length          : std_logic_vector(Reg_Gameboy_Channel3_Length         .upper downto Reg_Gameboy_Channel3_Length         .lower) := (others => '0');
   signal Gameboy_Channel3_OutputLevel     : std_logic_vector(Reg_Gameboy_Channel3_OutputLevel    .upper downto Reg_Gameboy_Channel3_OutputLevel    .lower) := (others => '0');
   signal Gameboy_Channel3_FreqLow         : std_logic_vector(Reg_Gameboy_Channel3_FreqLow        .upper downto Reg_Gameboy_Channel3_FreqLow        .lower) := (others => '0');
   signal Gameboy_Channel3_FreqHigh        : std_logic_vector(Reg_Gameboy_Channel3_FreqHigh       .upper downto Reg_Gameboy_Channel3_FreqHigh       .lower) := (others => '0');

   signal Gameboy_Channel3_OnOFF_written       : std_logic;      
   signal Gameboy_Channel3_Length_written      : std_logic;     
   signal Gameboy_Channel3_OutputLevel_written : std_logic; 
   signal Gameboy_Channel3_FreqLow_written     : std_logic;     
   signal Gameboy_Channel3_FreqHigh_written    : std_logic;    

   type t_waveram is array(0 to 15) of std_logic_vector(7 downto 0);
   signal Gameboy_SoundCtrl_WaveRam        : t_waveram;
   
   signal choutput_on      : std_logic := '0';
                           
   signal wavetable_ptr    : unsigned(4 downto 0)  := (others => '0');
   signal wavetable        : std_logic_vector(0 to 7)  := (others => '0');
   signal wave_vol         : std_logic_vector(3 downto 0) := (others => '0');         
                           
   signal length_left      : unsigned(8 downto 0) := (others => '0');   
                        
   signal volume_shift     : integer range 0 to 3  := 0;
   signal wave_vol_shifted : integer range 0 to 15 := 0;
                        
   signal freq_divider     : unsigned(11 downto 0) := (others => '0');
   signal freq_check       : unsigned(11 downto 0) := (others => '0');
   signal length_on        : std_logic := '0';
   signal ch_on            : std_logic := '0';
   signal freq_cnt         : unsigned(11 downto 0) := (others => '0');
   
   signal soundcycles_freq     : unsigned(7 downto 0)  := (others => '0');
   signal soundcycles_length   : unsigned(16 downto 0) := (others => '0');
   
begin 

   iReg_Gameboy_Channel3_OnOFF       : entity work.eProcReg generic map ( Reg_Gameboy_Channel3_OnOFF      ) port map  (clk100, gb_bus, Gameboy_Channel3_OnOFF      , Gameboy_Channel3_OnOFF      ,Gameboy_Channel3_OnOFF_written      );  
   iReg_Gameboy_Channel3_Length      : entity work.eProcReg generic map ( Reg_Gameboy_Channel3_Length     ) port map  (clk100, gb_bus, Gameboy_Channel3_Length     , Gameboy_Channel3_Length     ,Gameboy_Channel3_Length_written     );  
   iReg_Gameboy_Channel3_OutputLevel : entity work.eProcReg generic map ( Reg_Gameboy_Channel3_OutputLevel) port map  (clk100, gb_bus, Gameboy_Channel3_OutputLevel, Gameboy_Channel3_OutputLevel,Gameboy_Channel3_OutputLevel_written);  
   iReg_Gameboy_Channel3_FreqLow     : entity work.eProcReg generic map ( Reg_Gameboy_Channel3_FreqLow    ) port map  (clk100, gb_bus, Gameboy_Channel3_FreqLow    , Gameboy_Channel3_FreqLow    ,Gameboy_Channel3_FreqLow_written    );  
   iReg_Gameboy_Channel3_FreqHigh    : entity work.eProcReg generic map ( Reg_Gameboy_Channel3_FreqHigh   ) port map  (clk100, gb_bus, Gameboy_Channel3_FreqHigh   , Gameboy_Channel3_FreqHigh   ,Gameboy_Channel3_FreqHigh_written   );  
                                                                                                                                          
   gWaveRam : for i in 0 to 15 generate
      iWaveRam: entity work.eProcReg generic map ( Reg_Gameboy_SoundCtrl_WaveRam, i ) 
         port map (clk100, gb_bus, Gameboy_SoundCtrl_WaveRam(i), Gameboy_SoundCtrl_WaveRam(i));
   end generate;
   
   
   process (clk100)
   begin
      if rising_edge(clk100) then
         
         if (Gameboy_Channel3_OnOFF_written = '1') then
            choutput_on <= Gameboy_Channel3_OnOFF(7);
         end if;
         
         if (Gameboy_Channel3_Length_written = '1') then
            length_left <= to_unsigned(256, 9) - unsigned(Gameboy_Channel3_Length(5 downto 0));
         end if;
         
         if (Gameboy_Channel3_OutputLevel_written = '1') then
            volume_shift  <= to_integer(unsigned(Gameboy_Channel3_OutputLevel(6 downto 5)));
         end if;
         
         if (Gameboy_Channel3_FreqLow_written = '1') then
            freq_divider <= '0' & unsigned(Gameboy_Channel3_FreqHigh(2 downto 0)) & unsigned(Gameboy_Channel3_FreqLow);
         end if;
         
         if (Gameboy_Channel3_FreqHigh_written = '1') then
            freq_divider <= '0' & unsigned(Gameboy_Channel3_FreqHigh(2 downto 0)) & unsigned(Gameboy_Channel3_FreqLow);
            length_on <= Gameboy_Channel3_FreqHigh(6);
            if (Gameboy_Channel3_FreqHigh(7) = '1') then
               ch_on        <= '1';
               freq_cnt     <= (others => '0');
            end if;
         end if;
         
         -- cpu cycle trigger
         if (new_cycles_valid = '1') then
            soundcycles_freq     <= soundcycles_freq     + new_cycles;
            soundcycles_length   <= soundcycles_length   + new_cycles;
         end if;
         
         -- freq / wavetable
         if (soundcycles_freq > 4) then
            freq_cnt <= freq_cnt + soundcycles_freq / 2;
            soundcycles_freq(soundcycles_freq'left downto 1) <= (others => '0');
         end if;
         
         freq_check <= 2048 - freq_divider;
         
         if (freq_cnt >= freq_check) then
            freq_cnt <= freq_cnt - freq_check;
            wavetable_ptr <= wavetable_ptr + 1;
         end if;

         -- length
         if (soundcycles_length >= 16384) then -- 256 Hz
            soundcycles_length <= soundcycles_length - 16384;
            if (length_left > 0 and length_on = '1') then
               length_left <= length_left - 1;
               if (length_left = 1) then
                  ch_on <= '0';
               end if;
            end if;
         end if;
         
         -- wavetable
         if (wavetable_ptr(0) = '0') then
            wave_vol <= Gameboy_SoundCtrl_WaveRam(to_integer(wavetable_ptr(4 downto 1)))(7 downto 4);
         else
            wave_vol <= Gameboy_SoundCtrl_WaveRam(to_integer(wavetable_ptr(4 downto 1)))(3 downto 0);
         end if;
         
         case volume_shift is
            when 0 => wave_vol_shifted <= 0;
            when 1 => wave_vol_shifted <= to_integer(unsigned(wave_vol));
            when 2 => wave_vol_shifted <= to_integer(unsigned(wave_vol)) / 2;
            when 3 => wave_vol_shifted <= to_integer(unsigned(wave_vol)) / 4;
            when others => null;
         end case;
         
         -- sound out
         if (ch_on = '1') and (choutput_on = '1') then
            sound_out <= to_signed(1024 * wave_vol_shifted, 16);
            sound_on  <= '1';
         else
            sound_out <= (others => '0');
            sound_on  <= '0';
         end if;
      
      end if;
   end process;
  

end architecture;





