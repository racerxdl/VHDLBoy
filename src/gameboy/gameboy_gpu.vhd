library IEEE;
use IEEE.std_logic_1164.all;  
use IEEE.numeric_std.all;     

library MEM;

use work.pProc_bus_gb.all;
use work.pReg_gb_display.all;

entity gameboy_gpu is
   generic
   (
      scale_mult          : in  integer
   );
   port 
   (
      clk100              : in    std_logic;  
      gb_on               : in    std_logic;
      cgb                 : in    std_logic;
      gb_bus              : inout proc_bus_gb_type := ((others => 'Z'), (others => 'Z'), (others => 'Z'), 'Z', 'Z', 'Z');
                  
      clkvga              : in  std_logic;
      oCoord_X            : in  integer range -1023 to 2047;
      oCoord_Y            : in  integer range -1023 to 2047;
      gameboy_graphic     : out std_logic_vector(14 downto 0);
      gpu_out_active      : out std_logic := '0';
                          
      new_cycles          : in    unsigned(7 downto 0);
      new_cycles_valid    : in    std_logic;
                                  
      IRP_VBlank          : out   std_logic := '0';
      IRP_LCDStat         : out   std_logic := '0';
      hblank              : out   std_logic;
                          
      VRAM_PROC_addr      : in    natural range 0 to 16383;
      VRAM_PROC_datain    : in    std_logic_vector(7 downto 0);
      VRAM_PROC_dataout   : out   std_logic_vector(7 downto 0);
      VRAM_PROC_we        : in    std_logic;      
      
      OAMRAM_PROC_addr    : in    natural range 0 to 255;
      OAMRAM_PROC_datain  : in    std_logic_vector(7 downto 0);
      OAMRAM_PROC_dataout : out   std_logic_vector(7 downto 0);
      OAMRAM_PROC_we      : in    std_logic;
      
      Linetimerdebug      : out unsigned(8 downto 0);
      LineCountdebug      : out unsigned(7 downto 0)
   );
end entity;

architecture arch of gameboy_gpu is
   
   signal Gameboy_LCDControl                    : std_logic_vector(Reg_Gameboy_LCDControl                   .upper downto Reg_Gameboy_LCDControl                   .lower) := (others => '0');
   signal Gameboy_LCDControl_LCDEnable          : std_logic_vector(Reg_Gameboy_LCDControl_LCDEnable         .upper downto Reg_Gameboy_LCDControl_LCDEnable         .lower) := (others => '0');
   signal Gameboy_LCDControl_WindowMapSelect    : std_logic_vector(Reg_Gameboy_LCDControl_WindowMapSelect   .upper downto Reg_Gameboy_LCDControl_WindowMapSelect   .lower) := (others => '0');
   signal Gameboy_LCDControl_WindowEnable       : std_logic_vector(Reg_Gameboy_LCDControl_WindowEnable      .upper downto Reg_Gameboy_LCDControl_WindowEnable      .lower) := (others => '0');
   signal Gameboy_LCDControl_BGWindowTileSelect : std_logic_vector(Reg_Gameboy_LCDControl_BGWindowTileSelect.upper downto Reg_Gameboy_LCDControl_BGWindowTileSelect.lower) := (others => '0');
   signal Gameboy_LCDControl_BGMapSelect        : std_logic_vector(Reg_Gameboy_LCDControl_BGMapSelect       .upper downto Reg_Gameboy_LCDControl_BGMapSelect       .lower) := (others => '0');
   signal Gameboy_LCDControl_OBJSize            : std_logic_vector(Reg_Gameboy_LCDControl_OBJSize           .upper downto Reg_Gameboy_LCDControl_OBJSize           .lower) := (others => '0');
   signal Gameboy_LCDControl_ObjEnable          : std_logic_vector(Reg_Gameboy_LCDControl_ObjEnable         .upper downto Reg_Gameboy_LCDControl_ObjEnable         .lower) := (others => '0');
   signal Gameboy_LCDControl_BGEnable           : std_logic_vector(Reg_Gameboy_LCDControl_BGEnable          .upper downto Reg_Gameboy_LCDControl_BGEnable          .lower) := (others => '0');
          
   signal Gameboy_LCDStatus                     : std_logic_vector(Reg_Gameboy_LCDStatus                    .upper downto Reg_Gameboy_LCDStatus                    .lower) := (others => '0');
   signal Gameboy_LCDStatus_readback            : std_logic_vector(Reg_Gameboy_LCDStatus                    .upper downto Reg_Gameboy_LCDStatus                    .lower) := (others => '0');
          
   signal Gameboy_LCDSCrollY                    : std_logic_vector(Reg_Gameboy_LCDSCrollY                   .upper downto Reg_Gameboy_LCDSCrollY                   .lower) := (others => '0');
   signal Gameboy_LCDSCrollX                    : std_logic_vector(Reg_Gameboy_LCDSCrollX                   .upper downto Reg_Gameboy_LCDSCrollX                   .lower) := (others => '0');
          
   signal Gameboy_LCDLineY                      : std_logic_vector(Reg_Gameboy_LCDLineY                     .upper downto Reg_Gameboy_LCDLineY                     .lower) := (others => '0');
   signal Gameboy_LCDLineY_readback             : std_logic_vector(Reg_Gameboy_LCDLineY                     .upper downto Reg_Gameboy_LCDLineY                     .lower) := (others => '0');
   signal Gameboy_LCDLineY_written              : std_logic;
   signal Gameboy_LCDLineYCompare               : std_logic_vector(Reg_Gameboy_LCDLineYCompare              .upper downto Reg_Gameboy_LCDLineYCompare              .lower) := (others => '0');
          
   signal Gameboy_OAMDMA                        : std_logic_vector(Reg_Gameboy_OAMDMA                       .upper downto Reg_Gameboy_OAMDMA                       .lower) := (others => '0');
          
   signal Gameboy_BGPalette                     : std_logic_vector(Reg_Gameboy_BGPalette                    .upper downto Reg_Gameboy_BGPalette                    .lower) := (others => '0');
   signal Gameboy_OBP0Palette                   : std_logic_vector(Reg_Gameboy_OBP0Palette                  .upper downto Reg_Gameboy_OBP0Palette                  .lower) := (others => '0');
   signal Gameboy_OBP1Palette                   : std_logic_vector(Reg_Gameboy_OBP1Palette                  .upper downto Reg_Gameboy_OBP1Palette                  .lower) := (others => '0');
          
   signal Gameboy_WindowY                       : std_logic_vector(Reg_Gameboy_WindowY                      .upper downto Reg_Gameboy_WindowY                      .lower) := (others => '0');
   signal Gameboy_WindowX                       : std_logic_vector(Reg_Gameboy_WindowX                      .upper downto Reg_Gameboy_WindowX                      .lower) := (others => '0');
                   
   signal Gameboy_CGB_BGPalette                 : std_logic_vector(Reg_Gameboy_CGB_BGPalette                .upper downto Reg_Gameboy_CGB_BGPalette                .lower) := (others => '0');
   signal Gameboy_CGB_BGPalette_written         : std_logic;
   signal Gameboy_CGB_BGPaletteData             : std_logic_vector(Reg_Gameboy_CGB_BGPaletteData            .upper downto Reg_Gameboy_CGB_BGPaletteData            .lower) := (others => '0');
   signal Gameboy_CGB_BGPaletteData_readback    : std_logic_vector(Reg_Gameboy_CGB_BGPaletteData            .upper downto Reg_Gameboy_CGB_BGPaletteData            .lower) := (others => '0');
   signal Gameboy_CGB_BGPaletteData_written     : std_logic;
          
   signal Gameboy_CGB_ObjPalette                : std_logic_vector(Reg_Gameboy_CGB_ObjPalette               .upper downto Reg_Gameboy_CGB_ObjPalette               .lower) := (others => '0');
   signal Gameboy_CGB_ObjPalette_written        : std_logic;
   signal Gameboy_CGB_ObjPaletteData            : std_logic_vector(Reg_Gameboy_CGB_ObjPaletteData           .upper downto Reg_Gameboy_CGB_ObjPaletteData           .lower) := (others => '0');
   signal Gameboy_CGB_ObjPaletteData_readback   : std_logic_vector(Reg_Gameboy_CGB_ObjPaletteData           .upper downto Reg_Gameboy_CGB_ObjPaletteData           .lower) := (others => '0');
   signal Gameboy_CGB_ObjPaletteData_written    : std_logic;
   
   -- wiring
   
   signal search_oam           : std_logic;
   signal drawline             : std_logic;
   signal Reset_WindowY        : std_logic;
   signal linecounter_drawer   : unsigned(7 downto 0);
                               
   signal AddrVRAM             : natural range 0 to 16383; 
   signal DataVRAM             : std_logic_vector(7 downto 0);                              
   signal AddrOAM              : natural range 0 to 255; 
   signal DataOAM              : std_logic_vector(7 downto 0);  
   
   signal lcdstatus_mode            : std_logic_vector(1 downto 0);
   signal lcdstatus_LineCoincidence : std_logic;

   -- palette access
   signal PALETTE_PROC_addr    : natural range 0 to 63 := 0;
   signal PALETTE_PROC_datain  : std_logic_vector(15 downto 0) := (others => '0');
   signal PALETTE_PROC_dataout : std_logic_vector(15 downto 0);
   signal PALETTE_PROC_we      : std_logic := '0';  
   signal AddrPALETTE          : natural range 0 to 63; 
   signal DataPALETTE          : std_logic_vector(15 downto 0); 
   
   type tpaletteaccess is
   (
      IDLE,
      
      READBACKGROUND,
      WAITREADBACKGROUND,
      WRITEBACKGROUND,
      
      READSPRITE,
      WAITREADSPRITE,
      WRITESPRITE
   );
   signal palettestate : tpaletteaccess := IDLE;
   
   signal memory_slow        : std_logic := '0';
   signal background_pointer : unsigned(5 downto 0) := (others => '0');
   signal sprite_pointer     : unsigned(5 downto 0) := (others => '0');
   signal increasenext       : std_logic := '0';
   signal background_save    : std_logic_vector(15 downto 0) := (others => '0');
   signal sprite_save        : std_logic_vector(15 downto 0) := (others => '0');
   
   
begin 

   iReg_Gameboy_LCDControl                    : entity work.eProcReg generic map (Reg_Gameboy_LCDControl                   ) port map  (clk100, gb_bus, Gameboy_LCDControl                   , Gameboy_LCDControl                   ); 
   iReg_Gameboy_LCDControl_LCDEnable          : entity work.eProcReg generic map (Reg_Gameboy_LCDControl_LCDEnable         ) port map  (clk100, gb_bus, Gameboy_LCDControl_LCDEnable         , Gameboy_LCDControl_LCDEnable         ); 
   iReg_Gameboy_LCDControl_WindowMapSelect    : entity work.eProcReg generic map (Reg_Gameboy_LCDControl_WindowMapSelect   ) port map  (clk100, gb_bus, Gameboy_LCDControl_WindowMapSelect   , Gameboy_LCDControl_WindowMapSelect   ); 
   iReg_Gameboy_LCDControl_WindowEnable       : entity work.eProcReg generic map (Reg_Gameboy_LCDControl_WindowEnable      ) port map  (clk100, gb_bus, Gameboy_LCDControl_WindowEnable      , Gameboy_LCDControl_WindowEnable      ); 
   iReg_Gameboy_LCDControl_BGWindowTileSelect : entity work.eProcReg generic map (Reg_Gameboy_LCDControl_BGWindowTileSelect) port map  (clk100, gb_bus, Gameboy_LCDControl_BGWindowTileSelect, Gameboy_LCDControl_BGWindowTileSelect); 
   iReg_Gameboy_LCDControl_BGMapSelect        : entity work.eProcReg generic map (Reg_Gameboy_LCDControl_BGMapSelect       ) port map  (clk100, gb_bus, Gameboy_LCDControl_BGMapSelect       , Gameboy_LCDControl_BGMapSelect       ); 
   iReg_Gameboy_LCDControl_OBJSize            : entity work.eProcReg generic map (Reg_Gameboy_LCDControl_OBJSize           ) port map  (clk100, gb_bus, Gameboy_LCDControl_OBJSize           , Gameboy_LCDControl_OBJSize           ); 
   iReg_Gameboy_LCDControl_ObjEnable          : entity work.eProcReg generic map (Reg_Gameboy_LCDControl_ObjEnable         ) port map  (clk100, gb_bus, Gameboy_LCDControl_ObjEnable         , Gameboy_LCDControl_ObjEnable         ); 
   iReg_Gameboy_LCDControl_BGEnable           : entity work.eProcReg generic map (Reg_Gameboy_LCDControl_BGEnable          ) port map  (clk100, gb_bus, Gameboy_LCDControl_BGEnable          , Gameboy_LCDControl_BGEnable          ); 
                                                                                                                                                                                               
   iReg_Gameboy_LCDStatus                     : entity work.eProcReg generic map (Reg_Gameboy_LCDStatus                    ) port map  (clk100, gb_bus, Gameboy_LCDStatus_readback           , Gameboy_LCDStatus                    ); 
                                                                                                                                                                                               
   iReg_Gameboy_LCDSCrollY                    : entity work.eProcReg generic map (Reg_Gameboy_LCDSCrollY                   ) port map  (clk100, gb_bus, Gameboy_LCDSCrollY                   , Gameboy_LCDSCrollY                   ); 
   iReg_Gameboy_LCDSCrollX                    : entity work.eProcReg generic map (Reg_Gameboy_LCDSCrollX                   ) port map  (clk100, gb_bus, Gameboy_LCDSCrollX                   , Gameboy_LCDSCrollX                   ); 
                                                                                                                                                                                               
   iReg_Gameboy_LCDLineY                      : entity work.eProcReg generic map (Reg_Gameboy_LCDLineY                     ) port map  (clk100, gb_bus, Gameboy_LCDLineY_readback            , Gameboy_LCDLineY                    , Gameboy_LCDLineY_written); 
   iReg_Gameboy_LCDLineYCompare               : entity work.eProcReg generic map (Reg_Gameboy_LCDLineYCompare              ) port map  (clk100, gb_bus, Gameboy_LCDLineYCompare              , Gameboy_LCDLineYCompare              ); 
                                                                                                                                                                                                                                                                                                                                                                                              
   iReg_Gameboy_BGPalette                     : entity work.eProcReg generic map (Reg_Gameboy_BGPalette                    ) port map  (clk100, gb_bus, Gameboy_BGPalette                    , Gameboy_BGPalette                    ); 
   iReg_Gameboy_OBP0Palette                   : entity work.eProcReg generic map (Reg_Gameboy_OBP0Palette                  ) port map  (clk100, gb_bus, Gameboy_OBP0Palette                  , Gameboy_OBP0Palette                  ); 
   iReg_Gameboy_OBP1Palette                   : entity work.eProcReg generic map (Reg_Gameboy_OBP1Palette                  ) port map  (clk100, gb_bus, Gameboy_OBP1Palette                  , Gameboy_OBP1Palette                  ); 
                                                                                                                                                                                               
   iReg_Gameboy_WindowY                       : entity work.eProcReg generic map (Reg_Gameboy_WindowY                      ) port map  (clk100, gb_bus, Gameboy_WindowY                      , Gameboy_WindowY                      ); 
   iReg_Gameboy_WindowX                       : entity work.eProcReg generic map (Reg_Gameboy_WindowX                      ) port map  (clk100, gb_bus, Gameboy_WindowX                      , Gameboy_WindowX                      ); 
                                                                                                                                                                                                                                                                                                                                                                                  
   iReg_Gameboy_CGB_BGPalette                 : entity work.eProcReg generic map (Reg_Gameboy_CGB_BGPalette                ) port map  (clk100, gb_bus, Gameboy_CGB_BGPalette                , Gameboy_CGB_BGPalette                , Gameboy_CGB_BGPalette_written); 
   iReg_Gameboy_CGB_BGPaletteData             : entity work.eProcReg generic map (Reg_Gameboy_CGB_BGPaletteData            ) port map  (clk100, gb_bus, Gameboy_CGB_BGPaletteData_readback   , Gameboy_CGB_BGPaletteData            , Gameboy_CGB_BGPaletteData_written); 
                                                                                                                                                                                               
   iReg_Gameboy_CGB_ObjPalette                : entity work.eProcReg generic map (Reg_Gameboy_CGB_ObjPalette               ) port map  (clk100, gb_bus, Gameboy_CGB_ObjPalette               , Gameboy_CGB_ObjPalette               , Gameboy_CGB_ObjPalette_written); 
   iReg_Gameboy_CGB_ObjPaletteData            : entity work.eProcReg generic map (Reg_Gameboy_CGB_ObjPaletteData           ) port map  (clk100, gb_bus, Gameboy_CGB_ObjPaletteData_readback  , Gameboy_CGB_ObjPaletteData           , Gameboy_CGB_ObjPaletteData_written); 

   iVRAM: entity MEM.SyncRamDual
   generic map
   (
      DATA_WIDTH => 8,
      ADDR_WIDTH => 14
   )
   port map
   (
      clk        => clk100, 
      addr_a     => VRAM_PROC_addr,   
      datain_a   => VRAM_PROC_datain, 
      dataout_a  => VRAM_PROC_dataout,
      we_a       => VRAM_PROC_we,     
      addr_b     => AddrVRAM,
      datain_b   => x"00",
      dataout_b  => DataVRAM,
      we_b       => '0'
   );
   
   iOAMRAM: entity MEM.SyncRamDual
   generic map
   (
      DATA_WIDTH => 8,
      ADDR_WIDTH => 8
   )
   port map
   (
      clk        => clk100, 
      addr_a     => OAMRAM_PROC_addr,   
      datain_a   => OAMRAM_PROC_datain, 
      dataout_a  => OAMRAM_PROC_dataout,
      we_a       => OAMRAM_PROC_we,     
      addr_b     => AddrOAM,
      datain_b   => x"00",
      dataout_b  => DataOAM,
      we_b       => '0'
   );
   
   iPALETTERAM: entity MEM.SyncRamDual
   generic map
   (
      DATA_WIDTH => 16,
      ADDR_WIDTH => 6
   )
   port map
   (
      clk        => clk100, 
      addr_a     => PALETTE_PROC_addr,   
      datain_a   => PALETTE_PROC_datain, 
      dataout_a  => PALETTE_PROC_dataout,
      we_a       => PALETTE_PROC_we,     
      addr_b     => AddrPALETTE,
      datain_b   => x"0000",
      dataout_b  => DataPALETTE,
      we_b       => '0'
   );

   process (clk100)
   begin
      if (rising_edge(clk100)) then
      
         memory_slow     <= not memory_slow;
         PALETTE_PROC_we <= '0';
      
         case palettestate is
         
            when IDLE =>
               if (Gameboy_CGB_BGPalette_written = '1') then
                  background_pointer <= unsigned(Gameboy_CGB_BGPalette(5 downto 0));
                  palettestate <= READBACKGROUND;

               elsif (Gameboy_CGB_ObjPalette_written = '1') then
                  sprite_pointer     <= unsigned(Gameboy_CGB_ObjPalette(5 downto 0));
                  palettestate <= READSPRITE;
                  
               elsif (Gameboy_CGB_BGPaletteData_written = '1') then
                  PALETTE_PROC_addr   <= to_integer(unsigned(background_pointer(5 downto 1)));
                  if (background_pointer(0) = '0') then
                     PALETTE_PROC_datain <= background_save(15 downto 8) & Gameboy_CGB_BGPaletteData;
                  else
                     PALETTE_PROC_datain <= Gameboy_CGB_BGPaletteData & background_save(7 downto 0);
                  end if;
                  PALETTE_PROC_we <= '1';
                  increasenext       <= Gameboy_CGB_BGPalette(7);
                  palettestate       <= WRITEBACKGROUND;
                  
               elsif (Gameboy_CGB_ObjPaletteData_written = '1') then
                  PALETTE_PROC_addr <= 32 + to_integer(unsigned(sprite_pointer(5 downto 1)));
                  if (sprite_pointer(0) = '0') then
                     PALETTE_PROC_datain <= sprite_save(15 downto 8) & Gameboy_CGB_ObjPaletteData;
                  else
                     PALETTE_PROC_datain <= Gameboy_CGB_ObjPaletteData & sprite_save(7 downto 0);
                  end if;
                  PALETTE_PROC_we <= '1';
                  increasenext       <= Gameboy_CGB_ObjPalette(7);
                  palettestate       <= WRITESPRITE;
                  
               end if;
                  
            when READBACKGROUND =>
               PALETTE_PROC_addr <= to_integer(unsigned(background_pointer(5 downto 1)));
               palettestate      <= WAITREADBACKGROUND;
               memory_slow       <= '0';
                  
            when WAITREADBACKGROUND =>
               if (memory_slow = '1') then
                  background_save <= PALETTE_PROC_dataout; 
                  if (background_pointer(0) = '0') then
                     Gameboy_CGB_BGPaletteData_readback <= PALETTE_PROC_dataout(7 downto 0);
                  else
                     Gameboy_CGB_BGPaletteData_readback <= PALETTE_PROC_dataout(15 downto 8);
                  end if;
                  palettestate <= IDLE;
               end if;
                  
            when WRITEBACKGROUND =>
               if (increasenext = '1') then
                  background_pointer <= background_pointer + 1;
               end if;
               palettestate       <= READBACKGROUND;
             
            when READSPRITE =>
               PALETTE_PROC_addr  <= 32 + to_integer(unsigned(sprite_pointer(5 downto 1)));
               palettestate       <= WAITREADSPRITE;
               memory_slow        <= '0';    
            
            when WAITREADSPRITE => 
               if (memory_slow = '1') then
                  sprite_save <= PALETTE_PROC_dataout; 
                  if (sprite_pointer(0) = '0') then
                     Gameboy_CGB_ObjPaletteData_readback <= PALETTE_PROC_dataout(7 downto 0);
                  else
                     Gameboy_CGB_ObjPaletteData_readback <= PALETTE_PROC_dataout(15 downto 8);
                  end if;
                  palettestate <= IDLE;
               end if;
               
            when WRITESPRITE =>
               if (increasenext = '1') then
                  sprite_pointer <= sprite_pointer + 1;
               end if;
               palettestate   <= READSPRITE;

         end case;

      end if;
   end process;
   
   
   igameboy_gpu_timing : entity work.gameboy_gpu_timing
   port map
   (
      clk100                       => clk100,
                                    
      new_cycles                   => new_cycles,      
      new_cycles_valid             => new_cycles_valid,
                                   
      IRP_VBlank                   => IRP_VBlank, 
      IRP_LCDStat                  => IRP_LCDStat,
                                   
      search_oam                   => search_oam,
      drawline                     => drawline,   
      Reset_WindowY                => Reset_WindowY,
      linecounter_drawer           => linecounter_drawer,
      hblank                       => hblank,
                                   
      LCDControl_LCDEnable         => Gameboy_LCDControl_LCDEnable(Gameboy_LCDControl_LCDEnable'left),        
      LCDStatus_LineCoincidenceIRP => Gameboy_LCDStatus(6),
      LCDStatus_Mode2OAMIRP        => Gameboy_LCDStatus(5),       
      LCDStatus_Mode1VBlankIRP     => Gameboy_LCDStatus(4),    
      LCDStatus_Mode0HBlankIRP     => Gameboy_LCDStatus(3),    
                                   
      Gameboy_LCDLineY_reset       => Gameboy_LCDLineY_written,                          
      LCDLineYCompare              => Gameboy_LCDLineYCompare,
                                   
      state_out                    => lcdstatus_mode,
      LineY_out                    => Gameboy_LCDLineY_readback,
      LineCoincidence              => lcdstatus_LineCoincidence,
      
      Linetimerdebug               => Linetimerdebug,
      LineCountdebug               => LineCountdebug
   );
   
   -- masking out LYC=LY Coincidence Interrupt for compare compatability -> doesn't affect any game afaik
   Gameboy_LCDStatus_readback <= Gameboy_LCDStatus(7) & '0' & Gameboy_LCDStatus(5 downto 3) & lcdstatus_LineCoincidence & lcdstatus_mode;
   
   igameboy_gpu_drawer : entity work.gameboy_gpu_drawer
   generic map
   (
      scale_mult => scale_mult
   )
   port map
   (
      clk100                        => clk100,
      gb_on                         => gb_on,
      
      clkvga                        => clkvga,        
      oCoord_X                      => oCoord_X,       
      oCoord_Y                      => oCoord_Y,       
      gameboy_graphic               => gameboy_graphic,
      gpu_out_active                => gpu_out_active,
                                    
      AddrVRAM                      => AddrVRAM,
      DataVRAM                      => DataVRAM,
                                    
      AddrOAM                       => AddrOAM,
      DataOAM                       => DataOAM, 
      
      AddrPALETTE                   => AddrPALETTE, 
      DataPALETTE                   => DataPALETTE,
                                    
      linecounter                   => linecounter_drawer,  
      search_oam                    => search_oam,   
      drawline                      => drawline,     
      Reset_WindowY                 => Reset_WindowY,
      
      cgb                           => cgb,
      
      Gameboy_BGPalette             => Gameboy_BGPalette,  
      Gameboy_OBP0Palette           => Gameboy_OBP0Palette,
      Gameboy_OBP1Palette           => Gameboy_OBP1Palette,
                                    
      LCDSCrollY                    => Gameboy_LCDSCrollY,                  
      LCDSCrollX                    => Gameboy_LCDSCrollX,                           
      LCDControl_OBJSize            => Gameboy_LCDControl_OBJSize(Gameboy_LCDControl_OBJSize'left),           
      LCDControl_BGMapSelect        => Gameboy_LCDControl_BGMapSelect(Gameboy_LCDControl_BGMapSelect'left),       
      LCDControl_BGWindowTileSelect => Gameboy_LCDControl_BGWindowTileSelect(Gameboy_LCDControl_BGWindowTileSelect'left),
      LCDControl_ObjEnable          => Gameboy_LCDControl_ObjEnable(Gameboy_LCDControl_ObjEnable'left),
      LCDControl_BGEnable           => Gameboy_LCDControl_BGEnable(Gameboy_LCDControl_BGEnable'left),
      
      Gameboy_WindowY               => Gameboy_WindowY,
      Gameboy_WindowX               => Gameboy_WindowX,
      LCDControl_WindowMapSelect    => Gameboy_LCDControl_WindowMapSelect(Gameboy_LCDControl_WindowMapSelect'left),
      LCDControl_WindowEnable       => Gameboy_LCDControl_WindowEnable(Gameboy_LCDControl_WindowEnable'left)
   );         
   

end architecture;





