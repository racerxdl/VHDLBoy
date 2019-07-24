library IEEE;
use IEEE.std_logic_1164.all;  
use IEEE.numeric_std.all;     

use work.pRegmap.all;
use work.pProc_bus_gb.all;
use work.pReg_gb_sound.all;

entity gameboy_sound_ch4 is
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

architecture arch of gameboy_sound_ch4 is
   
   signal Gameboy_Channel4_Length          : std_logic_vector(Reg_Gameboy_Channel4_Length         .upper downto Reg_Gameboy_Channel4_Length         .lower) := (others => '0');
   signal Gameboy_Channel4_VolEnvelope     : std_logic_vector(Reg_Gameboy_Channel4_VolEnvelope    .upper downto Reg_Gameboy_Channel4_VolEnvelope    .lower) := (others => '0');
   signal Gameboy_Channel4_PolyCounter     : std_logic_vector(Reg_Gameboy_Channel4_PolyCounter    .upper downto Reg_Gameboy_Channel4_PolyCounter    .lower) := (others => '0');
   signal Gameboy_Channel4_CounterInit     : std_logic_vector(Reg_Gameboy_Channel4_CounterInit    .upper downto Reg_Gameboy_Channel4_CounterInit    .lower) := (others => '0');    
          
   signal Channel4_Length_written      : std_logic;
   signal Channel4_VolEnvelope_written : std_logic;
   signal Channel4_PolyCounter_written : std_logic;
   signal Channel4_CounterInit_written : std_logic;                                                                                                                                                      
          
   signal length_left   : unsigned(6 downto 0) := (others => '0');
                        
   signal envelope_cnt  : unsigned(5 downto 0) := (others => '0');
   signal envelope_add  : unsigned(5 downto 0) := (others => '0');
                        
   signal volume        : integer range 0 to 15 := 0;
   signal wave_on       : std_logic := '0';      
                        
   signal divider_raw   : unsigned(23 downto 0) := (others => '0');
   signal freq_divider  : unsigned(23 downto 0) := (others => '0');
   signal length_on     : std_logic := '0';
   signal ch_on         : std_logic := '0';
   
   signal lfsr7bit      : std_logic := '0';
   signal lfsr          : std_logic_vector(14 downto 0) := (others => '0');
   
   signal soundcycles_freq     : unsigned(23 downto 0)  := (others => '0');
   signal soundcycles_envelope : unsigned(17 downto 0) := (others => '0');
   signal soundcycles_length   : unsigned(16 downto 0) := (others => '0');
   
begin 

   iReg_Gameboy_Channel4_Length      : entity work.eProcReg generic map ( Reg_Gameboy_Channel4_Length     ) port map  (clk100, gb_bus, Gameboy_Channel4_Length     , Gameboy_Channel4_Length     , Channel4_Length_written     );  
   iReg_Gameboy_Channel4_VolEnvelope : entity work.eProcReg generic map ( Reg_Gameboy_Channel4_VolEnvelope) port map  (clk100, gb_bus, Gameboy_Channel4_VolEnvelope, Gameboy_Channel4_VolEnvelope, Channel4_VolEnvelope_written);  
   iReg_Gameboy_Channel4_PolyCounter : entity work.eProcReg generic map ( Reg_Gameboy_Channel4_PolyCounter) port map  (clk100, gb_bus, Gameboy_Channel4_PolyCounter, Gameboy_Channel4_PolyCounter, Channel4_PolyCounter_written);  
   iReg_Gameboy_Channel4_CounterInit : entity work.eProcReg generic map ( Reg_Gameboy_Channel4_CounterInit) port map  (clk100, gb_bus, Gameboy_Channel4_CounterInit, Gameboy_Channel4_CounterInit, Channel4_CounterInit_written);  
           
           
   process (clk100)
   begin
      if rising_edge(clk100) then
      
         -- register write triggers
         if (Channel4_Length_written = '1') then
            length_left <= to_unsigned(64, 7) - unsigned(Gameboy_Channel4_Length(5 downto 0));
         end if;
         
         if (Channel4_VolEnvelope_written = '1') then
            envelope_cnt <= (others => '0');
            envelope_add <= (others => '0');
            volume       <= to_integer(unsigned(Gameboy_Channel4_VolEnvelope(7 downto 4)));
         end if;
         
         if (Channel4_PolyCounter_written = '1') then
            case to_integer(unsigned(Gameboy_Channel4_PolyCounter(2 downto 0))) is
               when 0 => divider_raw <= to_unsigned(  8, divider_raw'length);
               when 1 => divider_raw <= to_unsigned( 16, divider_raw'length);
               when 2 => divider_raw <= to_unsigned( 32, divider_raw'length);
               when 3 => divider_raw <= to_unsigned( 48, divider_raw'length);
               when 4 => divider_raw <= to_unsigned( 64, divider_raw'length);
               when 5 => divider_raw <= to_unsigned( 80, divider_raw'length);
               when 6 => divider_raw <= to_unsigned( 96, divider_raw'length);
               when 7 => divider_raw <= to_unsigned(112, divider_raw'length);
               when others => null;
            end case;
            
            lfsr7bit <= Gameboy_Channel4_PolyCounter(3);
            
         end if;
         freq_divider <= divider_raw sll to_integer(unsigned(Gameboy_Channel4_PolyCounter(7 downto 4)));
         
         if (Channel4_CounterInit_written = '1') then
            length_on <= Gameboy_Channel4_CounterInit(6);
            if (Gameboy_Channel4_CounterInit(7) = '1') then
               envelope_cnt <= (others => '0');
               envelope_add <= (others => '0');
               ch_on        <= '1';
               lfsr         <= (others => '1');
            end if;
         end if;
         
         -- cpu cycle trigger
         if (new_cycles_valid = '1') then
            soundcycles_freq     <= soundcycles_freq     + new_cycles;
            soundcycles_envelope <= soundcycles_envelope + new_cycles;
            soundcycles_length   <= soundcycles_length   + new_cycles;
         end if;
         
         -- freq / wavetable
         if (soundcycles_freq >= freq_divider) then
            soundcycles_freq <= soundcycles_freq - freq_divider;
            wave_on <= not lfsr(0);
            lfsr <= (lfsr(1) xor lfsr(0)) & lfsr(14 downto 1);
            if (lfsr7bit = '1') then
               lfsr(6) <= lfsr(1) xor lfsr(0);
            end if;
         end if;
         
         -- envelope
         if (soundcycles_envelope >= 65536) then -- 64 Hz
            soundcycles_envelope <= soundcycles_envelope - 65536;
            if (Gameboy_Channel4_VolEnvelope(2 downto 0) /= "000") then
               envelope_cnt <= envelope_cnt + 1;
            end if;
         end if;
         
         if (Gameboy_Channel4_VolEnvelope(2 downto 0) /= "000") then
            if (envelope_cnt >= unsigned(Gameboy_Channel4_VolEnvelope(2 downto 0))) then
               envelope_cnt <= (others => '0');
               if (envelope_add < 15) then
                  envelope_add <= envelope_add + 1;
               end if;
            end if;
            
            if (Gameboy_Channel4_VolEnvelope(3) = '0') then -- decrease
               if (unsigned(Gameboy_Channel4_VolEnvelope(7 downto 4)) >= envelope_add) then
                  volume <= to_integer(unsigned(Gameboy_Channel4_VolEnvelope(7 downto 4))) - to_integer(envelope_add);
               else
                  volume <= 0;
               end if;
            else
               if (unsigned(Gameboy_Channel4_VolEnvelope(7 downto 4)) + envelope_add <= 15) then
                  volume <= to_integer(unsigned(Gameboy_Channel4_VolEnvelope(7 downto 4))) + to_integer(envelope_add);
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





