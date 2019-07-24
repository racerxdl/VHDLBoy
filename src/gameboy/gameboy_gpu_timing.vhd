library IEEE;
use IEEE.std_logic_1164.all;  
use IEEE.numeric_std.all;     

entity gameboy_gpu_timing is
   port 
   (
      clk100                       : in  std_logic;  
                                   
      new_cycles                   : in  unsigned(7 downto 0);
      new_cycles_valid             : in  std_logic;
                                   
      IRP_VBlank                   : out std_logic := '0';
      IRP_LCDStat                  : out std_logic := '0';
                                   
      search_oam                   : out std_logic := '0';
      drawline                     : out std_logic := '0';                       
      Reset_WindowY                : out std_logic := '0';
      linecounter_drawer           : out unsigned(7 downto 0);
      hblank                       : out std_logic := '0';
                               
      LCDControl_LCDEnable         : in  std_logic;
      LCDStatus_LineCoincidenceIRP : in  std_logic;
      LCDStatus_Mode2OAMIRP        : in  std_logic;
      LCDStatus_Mode1VBlankIRP     : in  std_logic;
      LCDStatus_Mode0HBlankIRP     : in  std_logic;
      
      Gameboy_LCDLineY_reset       : in  std_logic;
      LCDLineYCompare              : in  std_logic_vector(7 downto 0);
      
      state_out                    : out std_logic_vector(1 downto 0);
      LineY_out                    : out std_logic_vector(7 downto 0);
      LineCoincidence              : out std_logic := '0';
      
      Linetimerdebug               : out unsigned(8 downto 0);
      LineCountdebug               : out unsigned(7 downto 0)
   );
end entity;

architecture arch of gameboy_gpu_timing is
   
   signal lcd_on      : std_logic := '0';
   
   signal linecounter : unsigned(7 downto 0) := (others => '0');
   signal state       : unsigned(1 downto 0) := (others => '0');
   signal linetimer   : unsigned(8 downto 0) := (others => '0');
   
   signal linecount_mod   : unsigned(7 downto 0) := (others => '0');
   signal linecount_mod_1 : unsigned(7 downto 0) := (others => '0');
   
   
begin 

   state_out <= std_logic_vector(state);
   LineY_out <= std_logic_vector(linecount_mod);
   
   Linetimerdebug <= linetimer;
   LineCountdebug <= linecount_mod;
   
   linecounter_drawer <= linecounter;

   process (clk100)
   begin
      if rising_edge(clk100) then
      
         IRP_VBlank  <= '0';
         IRP_LCDStat <= '0';
         
         search_oam    <= '0';
         drawline      <= '0';
         Reset_WindowY <= '0';
         hblank        <= '0';
      
         LineCoincidence <= '0';
         if (linecount_mod = unsigned(LCDLineYCompare) and LCDControl_LCDEnable = '1') then
            LineCoincidence <= '1';
         end if;
      
         if (Gameboy_LCDLineY_reset = '1') then
            linecounter     <= (others => '0');
         end if;
      
         if (LCDControl_LCDEnable = '0') then
         
            lcd_on          <= '0';
            linecounter     <= (others => '0');
            state           <= (others => '0');
            linetimer       <= (others => '0');
            linecount_mod   <= (others => '0');
            linecount_mod_1 <= (others => '0');
         
         elsif (lcd_on = '0') then
         
            state  <= to_unsigned(2, state'length);
            lcd_on <= '1';
         
         elsif (new_cycles_valid = '1') then
         
            linetimer  <= linetimer + new_cycles;
            
         else
            
            if (state = 2 and linetimer >= 80) then -- search oam
               state <= to_unsigned(3, state'length);
               search_oam <= '1';

            elsif (state = 3 and linetimer >= 80 + 172) then -- draw
               state <= to_unsigned(0, state'length);
               drawline <= '1';
               --Memory.hblank_hdma(); -> should this be in state 0?

            elsif (state = 0 and linetimer >= 80 + 172 + 204) then -- hblank
               hblank <= '1';
               state  <= to_unsigned(2, state'length);
               if (LCDStatus_Mode2OAMIRP = '1') then
                   IRP_LCDStat <= '1';
               end if;
                
               -- next line
               linecounter <= linecounter + 1;
               linetimer <= linetimer - 456;
               if (LineCounter = 143) then -- will be 144 next cycle
                  Reset_WindowY <= '1';
                  state <= to_unsigned(1, state'length);
                  IRP_VBlank <= '1';
                  if (LCDStatus_Mode1VBlankIRP = '1') then
                     IRP_LCDStat <= '1';
                  end if;
               end if;
               if (LCDStatus_Mode0HBlankIRP = '1') then
                  IRP_LCDStat <= '1';
               end if;

            elsif (state = 1 and linetimer >= 456) then -- vblank
               linetimer <= linetimer - 456;
               linecounter <= linecounter + 1;
               if (LineCounter = 153) then
                  LineCounter <= (others => '0');
                  state <= to_unsigned(2, state'length);
               end if;
            end if;
            
            if (LineCounter = 153 and linetimer >= 8) then
               linecount_mod <= (others => '0');
            elsif (linetimer >= 452) then
               linecount_mod <= linecounter + 1;
            else
               linecount_mod <= LineCounter;
            end if;
            linecount_mod_1 <= linecount_mod;
            
            if (linecount_mod = unsigned(LCDLineYCompare) and linecount_mod /= linecount_mod_1) then
               if (LCDStatus_LineCoincidenceIRP = '1') then
                  IRP_LCDStat <= '1';
               end if;
            end if;
         
         
         end if;
      
      end if;
   end process;

end architecture;





