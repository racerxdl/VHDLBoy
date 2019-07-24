library IEEE;
use IEEE.std_logic_1164.all;  
use IEEE.numeric_std.all;     

use work.pRegmap.all;
use work.pProc_bus_gb.all;
use work.pReg_gb_sound.all;

entity gameboy_sound_ch1 is
   generic
   (
      has_sweep               : boolean;
      Reg_Channel_Sweep       : regmap_type;
      Reg_Channel_DutyPattern : regmap_type;
      Reg_Channel_VolEnvelope : regmap_type;
      Reg_Channel_FreqLow     : regmap_type;
      Reg_Channel_FreqHigh    : regmap_type
   );
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

architecture arch of gameboy_sound_ch1 is

   signal Channel_Sweep       : std_logic_vector(Reg_Channel_Sweep      .upper downto Reg_Channel_Sweep      .lower) := (others => '0');
   signal Channel_DutyPattern : std_logic_vector(Reg_Channel_DutyPattern.upper downto Reg_Channel_DutyPattern.lower) := (others => '0');
   signal Channel_VolEnvelope : std_logic_vector(Reg_Channel_VolEnvelope.upper downto Reg_Channel_VolEnvelope.lower) := (others => '0');
   signal Channel_FreqLow     : std_logic_vector(Reg_Channel_FreqLow    .upper downto Reg_Channel_FreqLow    .lower) := (others => '0');
   signal Channel_FreqHigh    : std_logic_vector(Reg_Channel_FreqHigh   .upper downto Reg_Channel_FreqHigh   .lower) := (others => '0');
   
   signal Channel_Sweep_written       : std_logic;
   signal Channel_DutyPattern_written : std_logic;
   signal Channel_VolEnvelope_written : std_logic;
   signal Channel_FreqLow_written     : std_logic;
   signal Channel_FreqHigh_written    : std_logic;                                                                                                                                                      

   signal wavetable_ptr : unsigned(2 downto 0)  := (others => '0');
   signal wavetable     : std_logic_vector(0 to 7)  := (others => '0');
   signal wave_on       : std_logic := '0';      
                        
   signal sweepcnt      : unsigned(7 downto 0) := (others => '0');
                        
   signal length_left   : unsigned(6 downto 0) := (others => '0');
                        
   signal envelope_cnt  : unsigned(5 downto 0) := (others => '0');
   signal envelope_add  : unsigned(5 downto 0) := (others => '0');
                        
   signal volume        : integer range 0 to 15 := 0;
                        
   signal freq_divider  : unsigned(11 downto 0) := (others => '0');
   signal freq_check    : unsigned(11 downto 0) := (others => '0');
   signal length_on     : std_logic := '0';
   signal ch_on         : std_logic := '0';
   signal freq_cnt      : unsigned(11 downto 0) := (others => '0');
   
   signal soundcycles_freq     : unsigned(7 downto 0)  := (others => '0');
   signal soundcycles_sweep    : unsigned(16 downto 0) := (others => '0');
   signal soundcycles_envelope : unsigned(17 downto 0) := (others => '0');
   signal soundcycles_length   : unsigned(16 downto 0) := (others => '0');
   
begin 

   gsweep : if has_sweep = true generate
   begin
      iReg_Channel_Sweep       : entity work.eProcReg generic map ( Reg_Channel_Sweep       ) port map  (clk100, gb_bus, Channel_Sweep      , Channel_Sweep      , Channel_Sweep_written      );  
   end generate;
   
   iReg_Channel_DutyPattern : entity work.eProcReg generic map ( Reg_Channel_DutyPattern ) port map  (clk100, gb_bus, Channel_DutyPattern, Channel_DutyPattern, Channel_DutyPattern_written);  
   iReg_Channel_VolEnvelope : entity work.eProcReg generic map ( Reg_Channel_VolEnvelope ) port map  (clk100, gb_bus, Channel_VolEnvelope, Channel_VolEnvelope, Channel_VolEnvelope_written);  
   iReg_Channel_FreqLow     : entity work.eProcReg generic map ( Reg_Channel_FreqLow     ) port map  (clk100, gb_bus, Channel_FreqLow    , Channel_FreqLow    , Channel_FreqLow_written    );  
   iReg_Channel_FreqHigh    : entity work.eProcReg generic map ( Reg_Channel_FreqHigh    ) port map  (clk100, gb_bus, Channel_FreqHigh   , Channel_FreqHigh   , Channel_FreqHigh_written   );  
  
   process (clk100)
   begin
      if rising_edge(clk100) then
      
         -- register write triggers
         if (Channel_Sweep_written = '1') then
            sweepcnt <= (others => '0');
         end if;
         
         if (Channel_DutyPattern_written = '1') then
            length_left <= to_unsigned(64, 7) - unsigned(Channel_DutyPattern(5 downto 0));
         end if;
         
         if (Channel_VolEnvelope_written = '1') then
            envelope_cnt <= (others => '0');
            envelope_add <= (others => '0');
            volume       <= to_integer(unsigned(Channel_VolEnvelope(7 downto 4)));
         end if;
         
         if (Channel_FreqLow_written = '1') then
            freq_divider <= '0' & unsigned(Channel_FreqHigh(2 downto 0)) & unsigned(Channel_FreqLow);
         end if;
         
         if (Channel_FreqHigh_written = '1') then
            freq_divider <= '0' & unsigned(Channel_FreqHigh(2 downto 0)) & unsigned(Channel_FreqLow);
            length_on <= Channel_FreqHigh(6);
            if (Channel_FreqHigh(7) = '1') then
               sweepcnt     <= (others => '0');
               envelope_cnt <= (others => '0');
               envelope_add <= (others => '0');
               ch_on        <= '1';
               freq_cnt     <= (others => '0');
            end if;
         end if;
         
         -- cpu cycle trigger
         if (new_cycles_valid = '1') then
            soundcycles_freq     <= soundcycles_freq     + new_cycles;
            soundcycles_sweep    <= soundcycles_sweep    + new_cycles;
            soundcycles_envelope <= soundcycles_envelope + new_cycles;
            soundcycles_length   <= soundcycles_length   + new_cycles;
         end if;
         
         -- freq / wavetable
         if (soundcycles_freq > 4) then
            freq_cnt <= freq_cnt + soundcycles_freq / 4;
            soundcycles_freq(soundcycles_freq'left downto 2) <= (others => '0');
         end if;
         
         freq_check <= 2048 - freq_divider;
         
         if (freq_cnt >= freq_check) then
            freq_cnt <= freq_cnt - freq_check;
            wavetable_ptr <= wavetable_ptr + 1;
         end if;
         
         -- sweep
         if (has_sweep = true) then
            if (soundcycles_sweep >= 32768) then -- 128 Hz
               soundcycles_sweep <= soundcycles_sweep - 32768;
               if (Channel_Sweep(6 downto 4) /= "000") then
                   sweepcnt <= sweepcnt + 1;
               end if;
            end if;
            
            if (Channel_Sweep(6 downto 4) /= "000") then
               if (sweepcnt >= unsigned(Channel_Sweep(6 downto 4))) then
                  sweepcnt <= (others => '0');
                  if (Channel_Sweep(3) = '0') then -- increase
                      freq_divider <= freq_divider + unsigned(Channel_Sweep(2 downto 0));
                  else
                      freq_divider <= freq_divider - unsigned(Channel_Sweep(2 downto 0));
                  end if;
                  
               end if;
            end if;
            
            if (freq_divider = 0) then
               freq_divider <= to_unsigned(1, freq_divider'length);
            end if;
            
         end if;
         
         
         -- envelope
         if (soundcycles_envelope >= 65536) then -- 64 Hz
            soundcycles_envelope <= soundcycles_envelope - 65536;
            if (Channel_VolEnvelope(2 downto 0) /= "000") then
               envelope_cnt <= envelope_cnt + 1;
            end if;
         end if;
         
         if (Channel_VolEnvelope(2 downto 0) /= "000") then
            if (envelope_cnt >= unsigned(Channel_VolEnvelope(2 downto 0))) then
               envelope_cnt <= (others => '0');
               if (envelope_add < 15) then
                  envelope_add <= envelope_add + 1;
               end if;
            end if;
            
            if (Channel_VolEnvelope(3) = '0') then -- decrease
               if (unsigned(Channel_VolEnvelope(7 downto 4)) >= envelope_add) then
                  volume <= to_integer(unsigned(Channel_VolEnvelope(7 downto 4))) - to_integer(envelope_add);
               else
                  volume <= 0;
               end if;
            else
               if (unsigned(Channel_VolEnvelope(7 downto 4)) + envelope_add <= 15) then
                  volume <= to_integer(unsigned(Channel_VolEnvelope(7 downto 4))) + to_integer(envelope_add);
               else
                  volume <= 15;
               end if;
            end if;
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
         
         -- duty
         case to_integer(unsigned(Channel_DutyPattern(7 downto 6))) is
            when 0 => wavetable <= "00000001";
            when 1 => wavetable <= "10000001";
            when 2 => wavetable <= "10000111";
            when 3 => wavetable <= "01111110";
            when others => null;
         end case;
         
         wave_on <= wavetable(to_integer(wavetable_ptr));
         
         -- sound out
         if (ch_on = '1') then
            if (wave_on = '1') then
               sound_out <= to_signed(512 * volume, 16);
            else
               sound_out <= to_signed(-512 * volume, 16);
            end if;
         else
            sound_out <= (others => '0');
         end if;
      
         sound_on <= ch_on;
      
      end if;
   end process;
  

end architecture;





