library IEEE;
use IEEE.std_logic_1164.all;  
use IEEE.numeric_std.all;     

use work.pProc_bus_gb.all;

entity gameboy is
   generic
   (
      is_simu    : std_logic := '0';   -- setting to 1 will activate cpu debug output
      scale_mult : integer := 1        -- scale multiplier for image, 1 = 160x144, 2=320*288, ....
   );
   port 
   (
      clk100             : in    std_logic;  -- clk speed -> easily reducable if less turbo speed is required
      Gameboy_on         : in    std_logic;  -- switch gameboy on, setting to 0 will reset most parts
      Gameboy_Speedmult  : in    std_logic_vector(3 downto 0);  -- speed multiplier, 1 = normal speed, 2 = double, .... 
      
      -- game specific
      Gameboy_CGB        : in    std_logic;                     -- use gameboy color drawmode, switch this off after booting the cbg-bios when using games that don't support cgb, otherwise graphic glitches, extracted from rom address 0x143
      Gameboy_MBC        : in    std_logic_vector(2 downto 0);  -- MBC used, extracted from rom address 0x147, see PANDOCS for more info
      Gameboy_Rombanks   : in    std_logic_vector(7 downto 0);  -- How many rombanks game has, extracted from rom address 0x148, see PANDOCS for more info
      Gameboy_Rambanks   : in    std_logic_vector(4 downto 0);  -- How many rambanks game has, extracted from rom address 0x149, see PANDOCS for more info
      
      -- graphic
      clkvga             : in    std_logic;                     -- seperate clock for vga or hdmi
      oCoord_X           : in    integer range -1023 to 2047;   -- current screen coordinate incluiding offscreen
      oCoord_Y           : in    integer range -1023 to 2047;   -- current screen coordinate incluiding offscreen
      gameboy_graphic    : out   std_logic_vector(14 downto 0); -- 5/5/5 rgb output
      gameboy_active     : out   std_logic;                     -- inside gameboy pixel area 
          
      -- sound
      sound_out          : out   std_logic_vector(15 downto 0) := (others => '0'); -- 16 bit signed sound,output, mono only
      
      -- keys
      Gameboy_KeyUp     : in    std_logic;  
      Gameboy_KeyDown   : in    std_logic;
      Gameboy_KeyLeft   : in    std_logic;
      Gameboy_KeyRight  : in    std_logic;
      Gameboy_KeyA      : in    std_logic;
      Gameboy_KeyB      : in    std_logic;
      Gameboy_KeyStart  : in    std_logic;
      Gameboy_KeySelect : in    std_logic;
      
      -- memory ( gamerom, gameram, bootrom, HRAM, WRAM)
      mem_addr          : out   std_logic_vector(21 downto 0) := (others => '0');
      mem_dataout       : out   std_logic_vector(31 downto 0) := (others => '0');
      mem_rnw           : out   std_logic := '0';
      mem_request       : out   std_logic := '0';
      mem_datain        : in    std_logic_vector(31 downto 0);
      mem_valid         : in    std_logic
   );
end entity;

architecture arch of gameboy is

   signal gb_bus : proc_bus_gb_type;
   
   -- wiring                         
   signal VRAM_PROC_addr      : integer range 0 to 16383;
   signal VRAM_PROC_datain    : std_logic_vector(7 downto 0);
   signal VRAM_PROC_dataout   : std_logic_vector(7 downto 0);
   signal VRAM_PROC_we        : std_logic;
   
   signal OAMRAM_PROC_addr    : integer range 0 to 255;
   signal OAMRAM_PROC_datain  : std_logic_vector(7 downto 0);
   signal OAMRAM_PROC_dataout : std_logic_vector(7 downto 0);
   signal OAMRAM_PROC_we      : std_logic;
   
   signal gpu_out_active      : std_logic;
   
   signal Linetimerdebug : unsigned(8 downto 0);
   signal LineCountdebug : unsigned(7 downto 0);
   
   signal DivReg_debug     : std_logic_vector(7 downto 0);
   signal TimeCnt_debug    : std_logic_vector(7 downto 0);
   signal cycletimer_debug : unsigned(15 downto 0);
   
   signal cpu_step : std_logic := '0';
   signal cpu_done : std_logic;
   
   signal HALT_out : std_logic;
   signal HALT_cnt : integer range 0 to 3 := 0;
   
   signal new_cycles       : unsigned(7 downto 0);
   signal new_cycles_valid : std_logic;
   signal doublespeed      : std_logic;
   
   signal IRP_VBlank  : std_logic;
   signal IRP_LCDStat : std_logic;
   signal IRP_Timer   : std_logic;
   signal IRP_Serial  : std_logic;
   signal IRP_Joypad  : std_logic;
   
   signal hblank      : std_logic;
   
   type tState is
   (
      IDLE,
      CPU
   );
   signal state : tState := IDLE;
   
   -- timing/speedmult
   signal oCoord_Y_100_1 : integer range -1023 to 2047;
   signal oCoord_Y_100_2 : integer range -1023 to 2047;
   signal new_image_req  : unsigned(3 downto 0) := (others => '0');
   
   
begin 

   gameboy_active <= Gameboy_on and gpu_out_active;

   -- dummy modules
   igameboy_reservedregs : entity work.gameboy_reservedregs port map ( clk100, gb_bus);
   igameboy_serial       : entity work.gameboy_serial       port map ( clk100, gb_bus);
   
   -- real modules
   igameboy_joypad : entity work.gameboy_joypad
   port map
   (
      clk100            => clk100,
      gb_bus            => gb_bus,
      
      Gameboy_KeyUp     => Gameboy_KeyUp,    
      Gameboy_KeyDown   => Gameboy_KeyDown,  
      Gameboy_KeyLeft   => Gameboy_KeyLeft,  
      Gameboy_KeyRight  => Gameboy_KeyRight, 
      Gameboy_KeyA      => Gameboy_KeyA,     
      Gameboy_KeyB      => Gameboy_KeyB,     
      Gameboy_KeyStart  => Gameboy_KeyStart, 
      Gameboy_KeySelect => Gameboy_KeySelect
   );
   
   igameboy_memorymux : entity work.gameboy_memorymux
   port map
   (
      clk100               => clk100,
      gb_on                => Gameboy_on,
      
      mem_addr             => mem_addr,   
      mem_dataout          => mem_dataout,
      mem_rnw              => mem_rnw,    
      mem_request          => mem_request,
      mem_datain           => mem_datain, 
      mem_valid            => mem_valid,  
      
      gb_bus               => gb_bus,
      
      Gameboy_MBC          => Gameboy_MBC,     
      Gameboy_Rombanks     => Gameboy_Rombanks,
      Gameboy_Rambanks     => Gameboy_Rambanks,
      
      new_cycles           => new_cycles,      
      new_cycles_valid     => new_cycles_valid,
      
      VRAM_PROC_addr       => VRAM_PROC_addr,   
      VRAM_PROC_datain     => VRAM_PROC_datain, 
      VRAM_PROC_dataout    => VRAM_PROC_dataout,
      VRAM_PROC_we         => VRAM_PROC_we,     
                         
      OAMRAM_PROC_addr     => OAMRAM_PROC_addr,   
      OAMRAM_PROC_datain   => OAMRAM_PROC_datain, 
      OAMRAM_PROC_dataout  => OAMRAM_PROC_dataout,
      OAMRAM_PROC_we       => OAMRAM_PROC_we     
   );
   
   igameboy_sound : entity work.gameboy_sound        
   port map 
   ( 
      clk100               => clk100,
      gb_bus               => gb_bus,
      
      sound_out            => sound_out
   );
   
   igameboy_gpu : entity work.gameboy_gpu
   generic map
   (
      scale_mult => scale_mult
   )
   port map
   (
      clk100               => clk100,
      gb_on                => Gameboy_on,
      cgb                  => Gameboy_CGB,
      gb_bus               => gb_bus,
      
      clkvga               => clkvga,        
      oCoord_X             => oCoord_X,       
      oCoord_Y             => oCoord_Y,       
      gameboy_graphic      => gameboy_graphic,
      gpu_out_active       => gpu_out_active,
      
      new_cycles           => new_cycles,      
      new_cycles_valid     => new_cycles_valid,
                                        
      IRP_VBlank           => IRP_VBlank,      
      IRP_LCDStat          => IRP_LCDStat,     
      hblank               => hblank,     
                        
      VRAM_PROC_addr       => VRAM_PROC_addr,   
      VRAM_PROC_datain     => VRAM_PROC_datain, 
      VRAM_PROC_dataout    => VRAM_PROC_dataout,
      VRAM_PROC_we         => VRAM_PROC_we,     
                         
      OAMRAM_PROC_addr     => OAMRAM_PROC_addr,   
      OAMRAM_PROC_datain   => OAMRAM_PROC_datain, 
      OAMRAM_PROC_dataout  => OAMRAM_PROC_dataout,
      OAMRAM_PROC_we       => OAMRAM_PROC_we,   
   
      Linetimerdebug       => Linetimerdebug,    
      LineCountdebug       => LineCountdebug      
   );
   
   igameboy_timer : entity work.gameboy_timer
   port map
   (
      clk100           => clk100,
      gb_on            => Gameboy_on,
      gb_bus           => gb_bus,
      new_cycles       => new_cycles,      
      new_cycles_valid => new_cycles_valid,
      doublespeed      => doublespeed,
      IRP_Timer        => IRP_Timer,
      DivReg_debug     => DivReg_debug,
      TimeCnt_debug    => TimeCnt_debug,
      cycletimer_debug => cycletimer_debug
   );
   
   igameboy_cpu : entity work.gameboy_cpu
   generic map
   (
      is_simu => is_simu
   )
   port map
   (
      clk100           => clk100, 
      gb_on            => Gameboy_on,
      cgb              => Gameboy_CGB,
      gb_bus           => gb_bus,
      
      do_step          => cpu_step,
      done             => cpu_done,
      HALT_out         => HALT_out,
      
      new_cycles_out   => new_cycles,
      new_cycles_valid => new_cycles_valid,
      doublespeed_out  => doublespeed,
      
      IRP_VBlank       => IRP_VBlank,
      IRP_LCDStat      => IRP_LCDStat,
      IRP_Timer        => IRP_Timer,  
      IRP_Serial       => IRP_Serial, 
      IRP_Joypad       => IRP_Joypad,
      
      hblank           => hblank,
      
      Linetimerdebug   => Linetimerdebug,
      LineCountdebug   => LineCountdebug,
      DivReg_debug     => DivReg_debug, 
      TimeCnt_debug    => TimeCnt_debug,
      cycletimer_debug => cycletimer_debug
   );
   
   IRP_Serial <= '0';
   IRP_Joypad <= '0';

   -- this process controls the speed of the cpu
   -- for each speedmult(1 = normal speed), 1 frame will be tried to calculate between each "real" frame of e.g. vga
   process (clk100)
   begin
      if rising_edge(clk100) then
      
         oCoord_Y_100_1 <= oCoord_Y;
         oCoord_Y_100_2 <= oCoord_Y_100_1;
         
         if (oCoord_Y_100_2 = (144 * scale_mult) or unsigned(Gameboy_Speedmult) = 15) then  -- vga image show is done -> now start calculating next
            new_image_req <= unsigned(Gameboy_Speedmult);
         elsif (IRP_VBlank = '1' and new_image_req > 0) then -- frame calculation by gb done
            new_image_req <= new_image_req - 1;
         end if;
      
         if (cpu_step = '0' and cpu_done = '1' and Gameboy_on = '1' and HALT_cnt = 0 and new_image_req > 0) then -- using ff costs ~4% CPU performance 
            cpu_step <= '1';
         else
            cpu_step <= '0'; 
         end if;
         
         if (HALT_out = '1' and cpu_done = '0') then
            HALT_cnt <= 3;
         elsif (HALT_cnt > 0) then
            HALT_cnt <= HALT_cnt - 1;
         end if;

   
      end if;
   end process;
   

end architecture;





