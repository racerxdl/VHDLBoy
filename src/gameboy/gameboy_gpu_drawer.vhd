library IEEE;
use IEEE.std_logic_1164.all;  
use IEEE.numeric_std.all;  
use STD.textio.all; 

entity gameboy_gpu_drawer is
   generic
   (
      scale_mult                    : in  integer
   );
   port 
   (
      clk100                        : in  std_logic; 
      gb_on                         : in  std_logic;

      clkvga                        : in  std_logic;
      oCoord_X                      : in  integer range -1023 to 2047;
      oCoord_Y                      : in  integer range -1023 to 2047;
      gameboy_graphic               : out std_logic_vector(14 downto 0);
      gpu_out_active                : out std_logic := '0';
                                    
      AddrVRAM                      : out natural range 0 to 16383 := 0; 
      DataVRAM                      : in  std_logic_vector(7 downto 0);
                                    
      AddrOAM                       : out natural range 0 to 255 := 0; 
      DataOAM                       : in  std_logic_vector(7 downto 0); 

      AddrPALETTE                   : out natural range 0 to 63; 
      DataPALETTE                   : in  std_logic_vector(15 downto 0);       
                                    
      linecounter                   : in  unsigned(7 downto 0);
      search_oam                    : in  std_logic;
      drawline                      : in  std_logic;   
      Reset_WindowY                 : in  std_logic;

      cgb                           : in  std_logic;
              
      Gameboy_BGPalette             : in  std_logic_vector(7 downto 0);
      Gameboy_OBP0Palette           : in  std_logic_vector(7 downto 0);
      Gameboy_OBP1Palette           : in  std_logic_vector(7 downto 0);    
              
      LCDSCrollY                    : in  std_logic_vector(7 downto 0);
      LCDSCrollX                    : in  std_logic_vector(7 downto 0);          
      LCDControl_OBJSize            : in  std_logic;
      LCDControl_BGMapSelect        : in  std_logic;
      LCDControl_BGWindowTileSelect : in  std_logic;
      LCDControl_ObjEnable          : in  std_logic;
      LCDControl_BGEnable           : in  std_logic;
      
      Gameboy_WindowY               : in  std_logic_vector(7 downto 0);
      Gameboy_WindowX               : in  std_logic_vector(7 downto 0);
      LCDControl_WindowMapSelect    : in  std_logic;
      LCDControl_WindowEnable       : in  std_logic
   );
end entity;

architecture arch of gameboy_gpu_drawer is
 
   type tPixelArray is array(0 to 23039) of std_logic_vector(15 downto 0);
   signal PixelArray : tPixelArray := (others => (others => '0'));
   
   type tlinedata is array(0 to 7) of std_logic_vector(1 downto 0);
   
   type sprite_type is record
      yline        : integer range 0 to 15;
      yline_flip   : integer range 0 to 15;
      xpos         : integer range -8 to 255;
      tileid       : integer range 0 to 255;
      bg_prio      : std_logic;
      flip_y       : std_logic;
      flip_x       : std_logic;
      second_map   : std_logic;
      palette_gb   : std_logic;
      palette_cgb  : unsigned(2 downto 0);
      data         : tlinedata;
      used         : std_logic;
      pxindex      : integer range 0 to 7;
      paletteindex : std_logic_vector(1 downto 0);
      palettegbmap : std_logic_vector(1 downto 0);
   end record;
   
   -- sprites
   type tSpriteArray is array(0 to 9) of sprite_type;
   signal SpriteArray : tSpriteArray;
   
   type tState is
   (
      IDLE,
      
      READOAM,
      SEARCHOAM,
      FETCHSPRITE1,
      FETCHSPRITE2,
      FETCHSPRITE3,
      FETCHSPRITE4,
      
      FETCHBGTILE1,
      FETCHBGTILE2,
      FETCHBGTILE3,
      FETCHBGLINE1,
      FETCHBGLINE2,
      
      FETCHWINDOWTILE1,
      FETCHWINDOWTILE2,
      FETCHWINDOWTILE3,
      FETCHWINDOWLINE1,
      FETCHWINDOWLINE2,
      
      CHECKDRAW
   );
   signal state : tstate;
   
   signal DataOAM_1     : std_logic_vector(7 downto 0) := (others => '0');
   
   signal mem_slow      : std_logic := '0';
   signal oam_pos       : integer range 0 to 159 := 0;
   signal sprite_count  : integer range 0 to 10 := 0;
   signal ysize         : integer range 0 to 16;
   
   -- background
   type bg_type is record
      tileid    : std_logic_vector(7 downto 0);
      palette   : unsigned(2 downto 0);
      secondmap : std_logic;
      mirror_h  : std_logic;
      mirror_v  : std_logic;
      bgprio    : std_logic;
      linedata : tlinedata;
   end record;
   
   signal bg_tile           : bg_type;
   signal bg_tile_x         : unsigned(4 downto 0) := (others => '0');
   signal bg_tile_y         : unsigned(4 downto 0) := (others => '0');
   signal addr_bg           : integer range 0 to 16383;
   signal bg_pixels_left    : integer range 0 to 8 := 0;
   signal bg_line           : unsigned (2 downto 0) := (others => '0');
   signal bg_line_flipped   : unsigned (2 downto 0) := (others => '0');
   signal bg_paletteindex   : std_logic_vector(1 downto 0);
   signal bg_paletteindex_1 : std_logic_vector(1 downto 0);
   
   -- window   
   signal window_tile           : bg_type;
   signal window_tile_x         : unsigned(4 downto 0) := (others => '0');
   signal window_tile_y         : unsigned(4 downto 0) := (others => '0');
   signal addr_window           : integer range 0 to 16383;
   signal window_pixels_left    : integer range 0 to 8 := 0;
   signal window_line           : unsigned (2 downto 0) := (others => '0');
   signal window_line_flipped   : unsigned (2 downto 0) := (others => '0');
   signal window_paletteindex   : std_logic_vector(1 downto 0);
   signal window_paletteindex_1 : std_logic_vector(1 downto 0);
   signal WindowYCnt            : integer range 0 to 144;
   signal window_xstart         : integer range 0 to 255;
   signal window_yoffset        : unsigned(7 downto 0);
   signal window_lineon         : std_logic := '0';
   signal window_lineon_save    : std_logic := '0';
   
   -- drawing
   signal draw_parts      : std_logic := '0';
   signal mix_parts       : std_logic := '0';
   signal palette_loading : std_logic := '0';
   signal palette_mapping : std_logic := '0';
   signal draw_pixel      : std_logic := '0';
   signal draw_pixel_1    : std_logic := '0';
   
   signal AddrPALETTE_bg       : natural range 0 to 63; 
   signal AddrPALETTE_window   : natural range 0 to 63; 
   signal AddrPALETTE_sprite   : natural range 0 to 63; 
   
   signal sprite_bgprio : std_logic := '0';
   signal sprite_on     : std_logic := '0';
   
   signal window_on    : std_logic := '0';
   signal window_on_1  : std_logic := '0';
   
   signal pixel        : std_logic_vector(15 downto 0) := (others => '0');
   signal pixel_1      : std_logic_vector(15 downto 0) := (others => '0');
   
   -- timing
   signal oam_req      : std_logic := '0';
   signal drawline_req : std_logic := '0';
   
   signal xpos   : integer range 0 to 159 := 0;
   signal xpos_1 : integer range 0 to 159 := 0;
   signal xpos_2 : integer range 0 to 159 := 0;
   signal xpos_3 : integer range 0 to 159 := 0;
   signal xpos_4 : integer range 0 to 159 := 0;
   signal xpos_5 : integer range 0 to 159 := 0;
   signal ypos   : integer range 0 to 143 := 0;
   
   signal write_addr : integer range 0 to 23039 := 0;
   
   signal AddrVRAM_buffer : natural range 0 to 16383 := 0; 
   
   -- vga readout
   signal oCoord_X_1     : integer range -1023 to 2047;
   signal oCoord_Y_1     : integer range -1023 to 2047;
   signal oCoord_active  : std_logic := '0';
   
   signal readout_addr        : integer range 0 to 23039 := 0; 
   signal readout_addr_ystart : integer range 0 to 23040 := 0; 
   signal readout_slow_x      : integer range 0 to 6     := 0; 
   signal readout_slow_y      : integer range 0 to 6     := 0; 
   signal readout_buffer      : std_logic_vector(14 downto 0) := (others => '0');
   
begin 

   process (clkvga)
   begin
      if rising_edge(clkvga) then
      
         oCoord_X_1 <= oCoord_X;
         oCoord_Y_1 <= oCoord_Y;
      
         if (oCoord_X >= 0 and oCoord_X < (160 * scale_mult) and oCoord_Y >= 0 and oCoord_Y < (144 * scale_mult)) then
            oCoord_active <= '1';
            if (readout_slow_x < 6) then
               readout_slow_x <= readout_slow_x + 1;
            else
               if (readout_addr < 23039) then
                  readout_addr <= readout_addr + 1;
               end if;
               readout_slow_x <= 0;
            end if;
         else
            oCoord_active <= '0';
            if (oCoord_X = (160 * scale_mult) and oCoord_Y >= 0 and oCoord_Y < (144 * scale_mult)) then
               if (readout_slow_y < 6) then
                  readout_slow_y <= readout_slow_y + 1;
                  readout_addr   <= readout_addr_ystart;
               else
                  readout_slow_y      <= 0;
                  readout_addr_ystart <= readout_addr_ystart + 160;
               end if;
            end if;
         end if;
         
         if (oCoord_X = 0 and oCoord_Y = -1) then
            readout_addr        <= 0;
            readout_addr_ystart <= 0;
            readout_slow_x      <= 0;
            readout_slow_y      <= 0;
         end if;
         
         readout_buffer  <= PixelArray(readout_addr)(14 downto 0);
         gameboy_graphic <= readout_buffer;

         gpu_out_active <= oCoord_active;
      
      end if;
   end process;

   ysize <= 16 when LCDControl_OBJSize = '1' else 8;
   
   addr_bg     <= 16#1C00# when LCDControl_BGMapSelect = '1' else 16#1800#; 
   addr_window <= 16#1C00# when LCDControl_WindowMapSelect = '1' else 16#1800#; 
   
   AddrVRAM <= AddrVRAM_buffer;

   process (clk100)
      variable sprite_ypos : integer range - 17 to 255;
      variable min_spritex : integer range - 17 to 255;
      variable addr_calc   : natural range 0 to 16383;
   begin
      if rising_edge(clk100) then
      
         mem_slow   <= not mem_slow;
         
         draw_parts      <= '0';
         mix_parts       <= '0';
         palette_loading <= '0';
         palette_mapping <= '0';
         draw_pixel      <= '0';
         
         xpos_1 <= xpos;
         xpos_2 <= xpos_1;
         xpos_3 <= xpos_2;
         xpos_4 <= xpos_3;
         xpos_5 <= xpos_4;
         pixel_1 <= pixel;
         write_addr <= xpos_5 + ypos * 160;
         draw_pixel_1 <= draw_pixel;
         if (draw_pixel_1 = '1') then
            PixelArray(write_addr) <= pixel_1;
         end if;

         if (LCDControl_ObjEnable = '1' and search_oam = '1') then -- if it isn't searched, it will not be drawn
            oam_req <= '1';
         end if;
         
         if (drawline = '1') then
            drawline_req <= '1';
         end if;
         
         window_on   <= '0';
         window_on_1 <= '0';
         if (Reset_WindowY = '1' or gb_on = '0') then
            WindowYCnt <= 0;
         end if;
         
         if (unsigned(Gameboy_WindowX) < 7) then
            window_xstart <= 0;
         else
            window_xstart <= (to_integer(unsigned(Gameboy_WindowX)) - 7);
         end if;
         
         if (to_unsigned(WindowYCnt, 8) >= unsigned(Gameboy_WindowY)) then
            window_yoffset <= to_unsigned(WindowYCnt, 8) - unsigned(Gameboy_WindowY);
            window_lineon  <= '1';
         else
            window_yoffset <= (others => '0');
            window_lineon  <= '0';
         end if;
         
         case state is
         
            when IDLE =>
               if (oam_req = '1') then
                  oam_req      <= '0';
                  ypos         <= to_integer(LineCounter);
                  state        <= READOAM;
                  AddrOAM      <= 0;
                  oam_pos      <= 0;
                  mem_slow     <= '0';
                  sprite_count <= 0;
               elsif (drawline_req = '1') then
                  drawline_req       <= '0';
                  state              <= FETCHWINDOWTILE1;
                  bg_pixels_left     <= 0;
                  window_pixels_left <= 0;
                  window_tile_x      <= (others => '0');
                  window_tile_y      <= window_yoffset(7 downto 3);       
                  window_line        <= window_yoffset(2 downto 0);
                  window_lineon_save <= window_lineon;                
                  xpos               <= 0;
                  ypos               <= to_integer(LineCounter);
                  if (LCDControl_WindowEnable = '1' and unsigned(Gameboy_WindowX) < 166) then
                     WindowYCnt      <= WindowYCnt + 1;
                  end if;
               end if;
               
            -- ################### Sprites ###########################
               
            when READOAM =>
               if (mem_slow = '1') then
                  DataOAM_1 <= DataOAM;
                  state <= SEARCHOAM;
               end if;
               
            when SEARCHOAM =>
               sprite_ypos := to_integer(unsigned(DataOAM_1) ) - 17 + ysize;
               if (sprite_ypos >= ypos and sprite_ypos < ypos + ysize) then
                  state         <= FETCHSPRITE1;
                  mem_slow      <= '0';
                  AddrOAM       <= oam_pos + 2; -- get id first
                  SpriteArray(sprite_count).yline_flip <= sprite_ypos - ypos;
               elsif (oam_pos = 156) then
                  state <= IDLE;
               else
                  SpriteArray(sprite_count).used  <= '0';
                  AddrOAM  <= oam_pos + 4;
                  oam_pos  <= oam_pos + 4;
                  state    <= READOAM;
                  mem_slow <= '0';
               end if;
               
            when FETCHSPRITE1 =>
               if (mem_slow = '1') then
                  SpriteArray(sprite_count).used       <= '1';
                  SpriteArray(sprite_count).tileid <= to_integer(unsigned(DataOAM));
                  SpriteArray(sprite_count).yline <= ysize - 1 - SpriteArray(sprite_count).yline_flip;
                  AddrOAM <= oam_pos + 3; -- get settings
                                    
                  state   <= FETCHSPRITE2;
               end if;
               
            when FETCHSPRITE2 =>
               if (mem_slow = '1') then
                  SpriteArray(sprite_count).bg_prio     <= DataOAM(7);
                  SpriteArray(sprite_count).flip_y      <= DataOAM(6);
                  SpriteArray(sprite_count).flip_x      <= DataOAM(5);
                  SpriteArray(sprite_count).palette_gb  <= DataOAM(4);
                  SpriteArray(sprite_count).second_map  <= DataOAM(3);
                  
                  if (cgb = '1') then
                     SpriteArray(sprite_count).palette_cgb <= unsigned(DataOAM(2 downto 0));                  
                  else
                     SpriteArray(sprite_count).palette_cgb <= "00" & unsigned(DataOAM(4 downto 4));
                  end if;
                     
                  AddrOAM <= oam_pos + 1; -- get xpos
                  
                  -- secondmap + index * 16 + line * 2
                  addr_calc := 0;
                  if (DataOAM(3) = '1' and cgb = '1') then -- secondmap
                     addr_calc := 16#2000#;
                  end if;
                  if (DataOAM(6) = '1') then -- flipy
                     addr_calc := addr_calc + SpriteArray(sprite_count).yline_flip * 2;
                  else
                     addr_calc := addr_calc + SpriteArray(sprite_count).yline * 2;
                  end if;
                  addr_calc := addr_calc + SpriteArray(sprite_count).tileid * 16;
                  AddrVRAM_buffer <= addr_calc;
                     
                  state   <= FETCHSPRITE3;
               end if;
               
            when FETCHSPRITE3 =>
               if (mem_slow = '1') then
                  SpriteArray(sprite_count).xpos <= to_integer(unsigned(DataOAM)) - 8;
                  
                  for i in 0 to 7 loop
                     if (SpriteArray(sprite_count).flip_x = '0') then
                        SpriteArray(sprite_count).data(i)(0) <= DataVRAM(7 - i);
                     else
                        SpriteArray(sprite_count).data(i)(0) <= DataVRAM(i);
                     end if;
                  end loop;
                  AddrVRAM_buffer <= AddrVRAM_buffer + 1;
                  
                  state   <= FETCHSPRITE4;
               end if;
               
            when FETCHSPRITE4 =>
               if (mem_slow = '1') then
                  if (SpriteArray(sprite_count).xpos = -8 or SpriteArray(sprite_count).xpos > 159) then
                     SpriteArray(sprite_count).used  <= '0';
                  elsif (SpriteArray(sprite_count).xpos < 0) then
                     SpriteArray(sprite_count).pxindex <= 0 - SpriteArray(sprite_count).xpos;
                  else
                     SpriteArray(sprite_count).pxindex <= 0;
                  end if;
               
                  for i in 0 to 7 loop
                     if (SpriteArray(sprite_count).flip_x = '0') then
                        SpriteArray(sprite_count).data(i)(1) <= DataVRAM(7 - i);
                     else
                        SpriteArray(sprite_count).data(i)(1) <= DataVRAM(i);
                     end if;
                  end loop;

                  if (sprite_count = 9 or oam_pos = 156) then
                     state <= IDLE;
                  else
                     sprite_count <= sprite_count + 1;
                     state        <= READOAM;
                     AddrOAM      <= oam_pos + 4;
                     oam_pos      <= oam_pos + 4;
                  end if;
               end if;
               
            -- ################### Background ###########################
            
            when FETCHBGTILE1 =>
               if (xpos = 0) then
                  bg_pixels_left <= 8 - to_integer(unsigned(LCDSCrollX(2 downto 0)));
               else
                  bg_pixels_left <= 8;
               end if;
               bg_line_flipped  <= 7 - bg_line;
               AddrVRAM_buffer  <= addr_bg + to_integer((bg_tile_y & "00000")) + to_integer(bg_tile_x); -- y * 32
               mem_slow  <= '0';
               state     <= FETCHBGTILE2;
               
            when FETCHBGTILE2 =>
               if (mem_slow = '1') then
                  bg_tile.tileid  <= DataVRAM;
                  AddrVRAM_buffer <= AddrVRAM_buffer + 16#2000#; -- fetch cgb stats
                  state <= FETCHBGTILE3;
               end if;   
                  
            when FETCHBGTILE3 =>
               if (mem_slow = '1') then
                  if (cgb = '1') then
                     bg_tile.palette   <= unsigned(DataVRAM(2 downto 0));
                     bg_tile.secondmap <= DataVRAM(3);
                     bg_tile.mirror_h  <= DataVRAM(5);
                     bg_tile.mirror_v  <= DataVRAM(6);
                     bg_tile.bgprio    <= DataVRAM(7);
                  else
                     bg_tile.palette   <= "000";
                     bg_tile.secondmap <= '0';
                     bg_tile.mirror_h  <= '0';
                     bg_tile.mirror_v  <= '0';
                     bg_tile.bgprio    <= '0';
                  end if;

                  addr_calc := 0;
                  if (DataVRAM(3) = '1' and cgb = '1') then -- secondmap
                     addr_calc := 16#2000#;
                  end if;
                  if (DataVRAM(6) = '1') then -- flipy
                     addr_calc := addr_calc + to_integer(bg_line_flipped & "0");
                  else
                     addr_calc := addr_calc + to_integer(bg_line & "0");
                  end if;
                  if (LCDControl_BGWindowTileSelect = '1') then
                     addr_calc := addr_calc + to_integer(unsigned(bg_tile.tileid)) * 16;
                  else
                     addr_calc := addr_calc + 16#1000# + to_integer(signed(bg_tile.tileid)) * 16;
                  end if;
                  AddrVRAM_buffer <= addr_calc;
                  
                  state   <= FETCHBGLINE1;

               end if;  
               
            when FETCHBGLINE1 =>
               if (mem_slow = '1') then
                  for i in 0 to 7 loop
                     if (bg_tile.mirror_h = '0') then
                        bg_tile.linedata(i)(0) <= DataVRAM(7 - i);
                     else
                        bg_tile.linedata(i)(0) <= DataVRAM(i);
                     end if;
                  end loop;
                  AddrVRAM_buffer <= AddrVRAM_buffer + 1;
                  state <= FETCHBGLINE2;
               end if;
              
            when FETCHBGLINE2 =>
               if (mem_slow = '1') then
                  for i in 0 to 7 loop
                     if (bg_tile.mirror_h = '0') then
                        bg_tile.linedata(i)(1) <= DataVRAM(7 - i);
                     else
                        bg_tile.linedata(i)(1) <= DataVRAM(i);
                     end if;
                  end loop;
                  state <= CHECKDRAW;
               end if;     

            -- ################### WINDOW ###########################
               
            when FETCHWINDOWTILE1 =>
               if (xpos = 0 and unsigned(Gameboy_WindowX) > 0 and unsigned(Gameboy_WindowX) < 7) then
                  window_pixels_left <= to_integer(unsigned(Gameboy_WindowX(2 downto 0)));
               else
                  window_pixels_left <= 8;
               end if;
               window_line_flipped  <= 7 - window_line;
               AddrVRAM_buffer  <= addr_WINDOW + to_integer((window_tile_y & "00000")) + to_integer(window_tile_x); -- y * 32
               window_tile_x <= window_tile_x + 1;
               mem_slow  <= '0';
               state     <= FETCHWINDOWTILE2;
               
            when FETCHWINDOWTILE2 =>
               if (mem_slow = '1') then
                  window_tile.tileid  <= DataVRAM;
                  AddrVRAM_buffer <= AddrVRAM_buffer + 16#2000#; -- fetch cgb stats
                  state <= FETCHWINDOWTILE3;
               end if;   
                  
            when FETCHWINDOWTILE3 =>
               if (mem_slow = '1') then
                  if (cgb = '1') then
                     window_tile.palette   <= unsigned(DataVRAM(2 downto 0));
                     window_tile.secondmap <= DataVRAM(3);
                     window_tile.mirror_h  <= DataVRAM(5);
                     window_tile.mirror_v  <= DataVRAM(6);
                     window_tile.bgprio    <= DataVRAM(7);
                  else
                     window_tile.palette   <= "000";
                     window_tile.secondmap <= '0';
                     window_tile.mirror_h  <= '0';
                     window_tile.mirror_v  <= '0';
                     window_tile.bgprio    <= '0';
                  end if;
                  
                  addr_calc := 0;
                  if (DataVRAM(3) = '1' and cgb = '1') then -- secondmap
                     addr_calc := 16#2000#;
                  end if;
                  if (DataVRAM(6) = '1') then -- flipy
                     addr_calc := addr_calc + to_integer(window_line_flipped & "0");
                  else
                     addr_calc := addr_calc + to_integer(window_line & "0");
                  end if;
                  if (LCDControl_BGWindowTileSelect = '1') then
                     addr_calc := addr_calc + to_integer(unsigned(window_tile.tileid)) * 16;
                  else
                     addr_calc := addr_calc + 16#1000# + to_integer(signed(window_tile.tileid)) * 16;
                  end if;
                  AddrVRAM_buffer <= addr_calc;
                  
                  state   <= FETCHWINDOWLINE1;

               end if;  
               
            when FETCHWINDOWLINE1 =>
               if (mem_slow = '1') then
                  for i in 0 to 7 loop
                     if (window_tile.mirror_h = '0') then
                        window_tile.linedata(i)(0) <= DataVRAM(7 - i);
                     else
                        window_tile.linedata(i)(0) <= DataVRAM(i);
                     end if;
                  end loop;
                  AddrVRAM_buffer <= AddrVRAM_buffer + 1;
                  state <= FETCHWINDOWLINE2;
               end if;
              
            when FETCHWINDOWLINE2 =>
               if (mem_slow = '1') then
                  for i in 0 to 7 loop
                     if (window_tile.mirror_h = '0') then
                        window_tile.linedata(i)(1) <= DataVRAM(7 - i);
                     else
                        window_tile.linedata(i)(1) <= DataVRAM(i);
                     end if;
                  end loop;
                  state <= CHECKDRAW;
               end if;  
            
            -- ################### Draw ###########################
            
            when CHECKDRAW =>
               if (bg_pixels_left = 0) then
                  bg_line   <= resize(unsigned(LCDSCrollY) + ypos, 3);
                  bg_tile_x <= resize((unsigned(LCDSCrollX) + xpos) / 8, 5);
                  bg_tile_y <= resize((unsigned(LCDSCrollY) + ypos) / 8, 5);
                  state <= FETCHBGTILE1;
               elsif (window_pixels_left = 0 and window_lineon_save = '1') then
                  state <= FETCHWINDOWTILE1;
               else
                  bg_paletteindex <= bg_tile.linedata(8 - bg_pixels_left);
                  bg_pixels_left <= bg_pixels_left - 1;
                  
                  if (LCDControl_WindowEnable = '1' and xpos >= window_xstart and window_lineon_save = '1') then
                     window_on <= '1';
                     window_paletteindex <= window_tile.linedata(8 - window_pixels_left);
                     window_pixels_left <= window_pixels_left - 1;
                  else
                     window_paletteindex <= "00";
                  end if;
                  
                  for i in 0 to 9 loop
                     SpriteArray(i).paletteindex <= "00";
                     if (SpriteArray(i).used = '1' and xpos >= SpriteArray(i).xpos) then
                        SpriteArray(i).paletteindex <= SpriteArray(i).data(SpriteArray(i).pxindex);
                        if (SpriteArray(i).pxindex < 7) then
                           SpriteArray(i).pxindex <= SpriteArray(i).pxindex + 1;
                        else
                           SpriteArray(i).used <= '0';
                        end if;
                     end if;
                     
                     if (SpriteArray(i).palette_gb = '0') then
                        case SpriteArray(i).data(SpriteArray(i).pxindex) is
                           when "00" => SpriteArray(i).palettegbmap <= Gameboy_OBP0Palette(1 downto 0);
                           when "01" => SpriteArray(i).palettegbmap <= Gameboy_OBP0Palette(3 downto 2);
                           when "10" => SpriteArray(i).palettegbmap <= Gameboy_OBP0Palette(5 downto 4);
                           when "11" => SpriteArray(i).palettegbmap <= Gameboy_OBP0Palette(7 downto 6);
                           when others => null;
                        end case;
                     else
                        case SpriteArray(i).data(SpriteArray(i).pxindex) is
                           when "00" => SpriteArray(i).palettegbmap <= Gameboy_OBP1Palette(1 downto 0);
                           when "01" => SpriteArray(i).palettegbmap <= Gameboy_OBP1Palette(3 downto 2);
                           when "10" => SpriteArray(i).palettegbmap <= Gameboy_OBP1Palette(5 downto 4);
                           when "11" => SpriteArray(i).palettegbmap <= Gameboy_OBP1Palette(7 downto 6);
                           when others => null;
                        end case;
                     end if;
                  end loop;
                  
                  draw_parts      <= '1';
                  if (xpos = 159) then
                     state <= IDLE;
                  else   
                     xpos <= xpos + 1;
                  end if;
               end if;
            
         end case;
         
         -- mainly used for sprite ordering
         if (draw_parts = '1') then
            if (cgb = '1') then
               AddrPALETTE_bg <= to_integer('0' & bg_tile.palette & unsigned(bg_paletteindex));
            else
               case bg_paletteindex is
                  when "00" => AddrPALETTE_bg <= to_integer('0' & bg_tile.palette & unsigned(Gameboy_BGPalette(1 downto 0)));
                  when "01" => AddrPALETTE_bg <= to_integer('0' & bg_tile.palette & unsigned(Gameboy_BGPalette(3 downto 2)));
                  when "10" => AddrPALETTE_bg <= to_integer('0' & bg_tile.palette & unsigned(Gameboy_BGPalette(5 downto 4)));
                  when "11" => AddrPALETTE_bg <= to_integer('0' & bg_tile.palette & unsigned(Gameboy_BGPalette(7 downto 6))); 
                  when others => null;
               end case;
            end if;
            bg_paletteindex_1 <= bg_paletteindex;
            
            if (cgb = '1') then
               AddrPALETTE_window <= to_integer('0' & window_tile.palette & unsigned(window_paletteindex));
            else
               case window_paletteindex is
                  when "00" => AddrPALETTE_window <= to_integer('0' & window_tile.palette & unsigned(Gameboy_BGPalette(1 downto 0)));
                  when "01" => AddrPALETTE_window <= to_integer('0' & window_tile.palette & unsigned(Gameboy_BGPalette(3 downto 2)));
                  when "10" => AddrPALETTE_window <= to_integer('0' & window_tile.palette & unsigned(Gameboy_BGPalette(5 downto 4)));
                  when "11" => AddrPALETTE_window <= to_integer('0' & window_tile.palette & unsigned(Gameboy_BGPalette(7 downto 6))); 
                  when others => null;
               end case;
            end if;
            
            window_paletteindex_1 <= window_paletteindex;
            window_on_1 <= window_on;
            
            min_spritex := 255;
            sprite_on <= '0';
            for i in 9 downto 0 loop 
               --if (SpriteArray(i).paletteindex /= "00" and SpriteArray(i).xpos <= min_spritex) then
               if (SpriteArray(i).paletteindex /= "00") then
                  if (cgb = '1') then
                     AddrPALETTE_sprite <= to_integer('1' & SpriteArray(i).palette_cgb & unsigned(SpriteArray(i).paletteindex));
                  else
                     AddrPALETTE_sprite <= to_integer('1' & SpriteArray(i).palette_cgb & unsigned(SpriteArray(i).palettegbmap));
                  end if;
                  min_spritex        := SpriteArray(i).xpos;
                  sprite_on          <= '1';
                  sprite_bgprio      <= SpriteArray(i).bg_prio;
               end if;
            end loop;
            
            mix_parts <= '1';
         end if;
         
         -- sprite/window/bg prio
         if (mix_parts = '1') then
            pixel <= (others => '1');
            if (sprite_on = '1' and (
                  (window_paletteindex_1 = "00" or window_on_1 = '0' or window_tile.bgprio = '0') and
                  (bg_paletteindex_1 = "00" or bg_tile.bgprio = '0') and
                  (sprite_bgprio = '0' or (window_paletteindex_1 = "00" and bg_paletteindex_1 = "00"))
               )) then
               AddrPALETTE <= AddrPALETTE_sprite;
            elsif (window_on_1 = '1') then
               AddrPALETTE <= AddrPALETTE_window;
            elsif (LCDControl_BGEnable = '1') then
               AddrPALETTE <= AddrPALETTE_bg;
            end if;
            palette_loading <= '1';
         end if;
         
         --palette loading
         if (palette_loading = '1') then
            palette_mapping <= '1';
         end if;
         
         --palette loaded
         if (palette_mapping = '1') then
            pixel      <= '0' & DataPALETTE(4 downto 0) & DataPALETTE(9 downto 5) & DataPALETTE(14 downto 10);
            draw_pixel <= '1';
         end if;
         
      
      end if;
   end process;
   
-- synthesis translate_off
   
  -- graphic test output
   
   goutput : if 1 = 0 generate
   begin
   
      process
      
         file outfile: text;
         variable f_status: FILE_OPEN_STATUS;
         variable line_out : line;
         variable color : unsigned(31 downto 0);
         
      begin
   
         file_open(f_status, outfile, "gra_gb_out.gra", write_mode);
         file_close(outfile);
         
         file_open(f_status, outfile, "gra_gb_out.gra", append_mode);
         write(line_out, string'("640#576")); 
         writeline(outfile, line_out);
         
         while (true) loop
            wait until xpos_1 = 159;
            wait for 1 us;
            
            for x in 0 to 159 loop
               color := x"0000" & unsigned(PixelArray(ypos * 160 + x));
               color := x"00" & unsigned(color(14 downto 10)) & "000" & unsigned(color(9 downto 5)) & "000" & unsigned(color(4 downto 0)) & "000";
            
               for doublex in 0 to 3 loop
                  for doubley in 0 to 3 loop
                     write(line_out, to_integer(color));
                     write(line_out, string'("#"));
                     write(line_out, x * 4 + doublex);
                     write(line_out, string'("#")); 
                     write(line_out, ypos * 4 + doubley);
                     writeline(outfile, line_out);
                  end loop;
               end loop;

            end loop;
            
            file_close(outfile);
            file_open(f_status, outfile, "gra_gb_out.gra", append_mode);
            
         end loop;
         
      end process;
   
   end generate goutput;
   
-- synthesis translate_on

end architecture;





