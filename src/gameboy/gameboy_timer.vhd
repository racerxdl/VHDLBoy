library IEEE;
use IEEE.std_logic_1164.all;  
use IEEE.numeric_std.all;     

use work.pProc_bus_gb.all;
use work.pReg_gb_timer.all;

entity gameboy_timer is
   port 
   (
      clk100           : in    std_logic;  
      gb_on            : in    std_logic;
      gb_bus           : inout proc_bus_gb_type := ((others => 'Z'), (others => 'Z'), (others => 'Z'), 'Z', 'Z', 'Z');
      new_cycles       : in    unsigned(7 downto 0);
      new_cycles_valid : in    std_logic;
      IRP_Timer        : out   std_logic := '0';
      
      DivReg_debug     : out   std_logic_vector(7 downto 0);
      TimeCnt_debug    : out   std_logic_vector(7 downto 0);
      cycletimer_debug : out   unsigned(15 downto 0)
   );
end entity;

architecture arch of gameboy_timer is
   
   signal Gameboy_DivReg      : std_logic_vector(Reg_Gameboy_DivReg .upper     downto Reg_Gameboy_DivReg     .lower) := (others => '0');
   signal Gameboy_TimeCnt     : std_logic_vector(Reg_Gameboy_TimeCnt.upper     downto Reg_Gameboy_TimeCnt    .lower) := (others => '0');
   signal Gameboy_TimeMod     : std_logic_vector(Reg_Gameboy_TimeMod.upper     downto Reg_Gameboy_TimeMod    .lower) := (others => '0');
   signal Gameboy_TimeControl : std_logic_vector(Reg_Gameboy_TimeControl.upper downto Reg_Gameboy_TimeControl.lower) := (others => '0');
   
   signal Gameboy_DivReg_intern     : std_logic_vector(Reg_Gameboy_DivReg           .upper downto Reg_Gameboy_DivReg           .lower) := (others => '0');
   signal Gameboy_DivReg_written    : std_logic;   
   
   signal Gameboy_TimeCnt_intern     : std_logic_vector(Reg_Gameboy_TimeCnt         .upper downto Reg_Gameboy_TimeCnt          .lower) := (others => '0');
   signal Gameboy_TimeCnt_written    : std_logic;
   signal Gameboy_TimeControl_written : std_logic;
   
   signal cyclecount_div   : unsigned(14 downto 0) := (others => '0');
   signal cyclecount_timer : unsigned(14 downto 0) := (others => '0');
   signal timercontrol_on  : std_logic := '0';
   
   signal TimeCnt          : unsigned(7 downto 0) := (others => '0');
   
begin 
    
   iReg_Gameboy_DivReg            : entity work.eProcReg generic map (Reg_Gameboy_DivReg     ) port map  (clk100, gb_bus, Gameboy_DivReg_intern , Gameboy_DivReg     , Gameboy_DivReg_written);  
   iReg_Gameboy_TimeCnt           : entity work.eProcReg generic map (Reg_Gameboy_TimeCnt    ) port map  (clk100, gb_bus, Gameboy_TimeCnt_intern, Gameboy_TimeCnt    , Gameboy_TimeCnt_written);  
   iReg_Gameboy_TimeMod           : entity work.eProcReg generic map (Reg_Gameboy_TimeMod    ) port map  (clk100, gb_bus, Gameboy_TimeMod       , Gameboy_TimeMod    );  
   iReg_Gameboy_TimeControl       : entity work.eProcReg generic map (Reg_Gameboy_TimeControl) port map  (clk100, gb_bus, Gameboy_TimeControl   , Gameboy_TimeControl, Gameboy_TimeControl_written);   
  
   Gameboy_TimeCnt_intern <= std_logic_vector(TimeCnt);
   
   DivReg_debug     <= Gameboy_DivReg_intern;
   TimeCnt_debug    <= Gameboy_TimeCnt_intern;
   cycletimer_debug <= '0' & cyclecount_timer;
  
   process (clk100)
   begin
      if rising_edge(clk100) then
      
         IRP_Timer <= '0';
      
         if (gb_on = '0') then
         
            cyclecount_div   <= (others => '0');
            cyclecount_timer <= (others => '0'); 
            TimeCnt          <= (others => '0');
            timercontrol_on  <= '0';
            
         elsif (new_cycles_valid = '1') then
               
            cyclecount_div   <= cyclecount_div   + new_cycles;
            cyclecount_timer <= cyclecount_timer + new_cycles;
               
         else 
         
            if (cyclecount_div >= 128) then -- why ? 256 should be correct
               Gameboy_DivReg_intern <= std_logic_vector(unsigned(Gameboy_DivReg_intern) + cyclecount_div(14 downto 7));
               cyclecount_div <= (14 downto 7 => '0') & cyclecount_div(6 downto 0);
            end if;
            
            case Gameboy_TimeControl(1 downto 0) is
               when "00" => -- 4194 hz
                  if (cyclecount_timer(14 downto 10) > 0) then
                     cyclecount_timer <= (14 downto 10 => '0') & cyclecount_timer(9 downto 0);
                     if (timercontrol_on = '1') then
                        TimeCnt <= TimeCnt - cyclecount_timer(14 downto 10); -- only working for maximum of 31 wraparounds -> should be enough in real life
                        if (cyclecount_timer(14 downto 10) >= TimeCnt and TimeCnt > 0) then
                           -- TimeCnt = TimeMod; ????
                           IRP_Timer <= '1';
                        end if;
                     end if;
                  end if;
                  
               when "01" => -- 268400 hz
                  if (cyclecount_timer(8 downto 4) > 0) then
                     cyclecount_timer <= (14 downto 4 => '0') & cyclecount_timer(3 downto 0);
                     if (timercontrol_on = '1') then
                        TimeCnt <= TimeCnt - cyclecount_timer(8 downto 4); -- only working for maximum of 31 wraparounds -> should be enough in real life
                        if (cyclecount_timer(8 downto 4) >= TimeCnt and TimeCnt > 0) then
                           -- TimeCnt = TimeMod; ????
                           IRP_Timer <= '1';
                        end if;
                     end if;
                  end if;
                  
               when "10" => -- 67110 hz
                  if (cyclecount_timer(10 downto 6) > 0) then
                     cyclecount_timer <= (14 downto 6 => '0') & cyclecount_timer(5 downto 0);
                     if (timercontrol_on = '1') then
                        TimeCnt <= TimeCnt - cyclecount_timer(10 downto 6); -- only working for maximum of 31 wraparounds -> should be enough in real life
                        if (cyclecount_timer(10 downto 6) >= TimeCnt and TimeCnt > 0) then
                           -- TimeCnt = TimeMod; ????
                           IRP_Timer <= '1';
                        end if;
                     end if;
                  end if;
                  
               when "11" => -- 16780 hz
                  if (cyclecount_timer(12 downto 8) > 0) then
                     cyclecount_timer <= (14 downto 8 => '0') & cyclecount_timer(7 downto 0);
                     if (timercontrol_on = '1') then
                        TimeCnt <= TimeCnt - cyclecount_timer(12 downto 8); -- only working for maximum of 31 wraparounds -> should be enough in real life
                        if (cyclecount_timer(12 downto 8) >= TimeCnt and TimeCnt > 0) then
                           -- TimeCnt = TimeMod; ????
                           IRP_Timer <= '1';
                        end if;
                     end if;
                  end if;
                  
               when others => null;
            end case;
            

            
            if (Gameboy_DivReg_written = '1') then
               cyclecount_timer      <= (others => '0');
               Gameboy_DivReg_intern <= (others => '0');
            end if;
            
            if (Gameboy_TimeCnt_written = '1') then
               TimeCnt <= unsigned(Gameboy_TimeCnt);
            end if;
            
            if (Gameboy_TimeControl_written = '1') then
               timercontrol_on <= Gameboy_TimeControl(2);
               if (Gameboy_TimeControl(2) = '1' and timercontrol_on = '0') then
                  TimeCnt <= (others => '0');
                  case Gameboy_TimeControl(1 downto 0) is
                     when "00"   => cyclecount_timer <= "0000"       & cyclecount_timer(10 downto 0); -- 4194 hz
                     when "01"   => cyclecount_timer <= "0000000000" & cyclecount_timer(4 downto 0); -- 268400 hz
                     when "10"   => cyclecount_timer <= "00000000"   & cyclecount_timer(6 downto 0); -- 67110 hz
                     when others => cyclecount_timer <= "000000"     & cyclecount_timer(8 downto 0); -- 16780 hz
                  end case;
               end if;
            end if;
         
         end if;
      
      end if;
   end process; 
    

end architecture;





