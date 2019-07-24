-- BEWARE: the external memory bus has been exchanged to a more generic format, after testing the core
-- There may be minor bugs. 
-- Still, you should be able to easily bring it to work when
-- connecting your memory and test the core in simulation together with e.g. the bootrom

-- memory structure:
-- 22bit address with 32Bit Data each (16 Mbyte) divided into:

-- MEMORY NAME    START ADDR     MSB    LSB   COUNT
-----------------------------------------------------------------
-- GB_Gamerom              0,     31,    0,  2097152
-- GB_Gameram        2097152,      7,    0,   131072
-- GB_WRam           2228224,      7,    0,    32768
-- GB_BootRom        2260992,     31,    0,     4096
-- GB_HRAM           2265088,      7,    0,      128

-- as you may noticed, this core is using a 32bit bus, while the gb only has 8 Bit.
-- This is done because most memory these days have a 16 bit or 32 bit interface at least.
-- An advantage for the core, as a 32bit access can be used as a minicache with 4 cells size


library IEEE;
use IEEE.std_logic_1164.all;  
use IEEE.numeric_std.all;     

use work.pProc_bus_gb.all;
use work.pReg_gb_memory.all;
use work.pReg_gb_mixed.all;

entity gameboy_memorymux is
   port 
   (
      clk100              : in    std_logic; 
      gb_on               : in    std_logic;
      
      mem_addr            : out   std_logic_vector(21 downto 0) := (others => '0');
      mem_dataout         : out   std_logic_vector(31 downto 0) := (others => '0');
      mem_rnw             : out   std_logic := '0';
      mem_request         : out   std_logic := '0';
      mem_datain          : in    std_logic_vector(31 downto 0);
      mem_valid           : in    std_logic;

      gb_bus              : inout proc_bus_gb_type := ((others => 'Z'), (others => 'Z'), (others => 'Z'), 'Z', 'Z', 'Z');
      
      Gameboy_MBC         : in    std_logic_vector(2 downto 0);
      Gameboy_Rombanks    : in    std_logic_vector(7 downto 0);
      Gameboy_Rambanks    : in    std_logic_vector(4 downto 0);
      
      new_cycles          : in    unsigned(7 downto 0);
      new_cycles_valid    : in    std_logic;
                          
      VRAM_PROC_addr      : out   integer range 0 to 16383;
      VRAM_PROC_datain    : out   std_logic_vector(7 downto 0);
      VRAM_PROC_dataout   : in    std_logic_vector(7 downto 0);
      VRAM_PROC_we        : out   std_logic;
      
      OAMRAM_PROC_addr    : out   integer range 0 to 255;
      OAMRAM_PROC_datain  : out   std_logic_vector(7 downto 0);
      OAMRAM_PROC_dataout : in    std_logic_vector(7 downto 0);
      OAMRAM_PROC_we      : out   std_logic
   );
end entity;

architecture arch of gameboy_memorymux is
   
   constant busadr_bits : integer := 22;
   
   constant GB_Gamerom_start : integer :=       0;
   constant GB_Gameram_start : integer := 2097152;
   constant GB_WRam_start    : integer := 2228224;
   constant GB_BootRom_start : integer := 2260992;
   constant GB_HRAM_start    : integer := 2265088;

   type tState is
   (
      IDLE,
      READROM,
      WAITROM,
      READEXTERN,
      WAITREAD,
      WRITEEXTERN,
      WAITWRITE,
      VRAMREADWAIT,
      VRAMREAD,
      OAMRAMREADWAIT,
      OAMRAMREAD
   );
   signal state : tState := IDLE;
   
   signal rom_addr       : std_logic_vector(busadr_bits+1 downto 0) := (others => '0');
   signal rom_addr_last  : std_logic_vector(busadr_bits-1 downto 0) := (others => '0');
   signal rom_data_last  : std_logic_vector(31 downto 0)            := (others => '0');
   signal rom_last_valid : std_logic := '0';
   
   signal read_addr  : std_logic_vector(busadr_bits-1 downto 0) := (others => '0');
   signal write_addr : std_logic_vector(busadr_bits-1 downto 0) := (others => '0');
   signal write_data : std_logic_vector(7 downto 0) := (others => '0');
   
   signal cartram_active  : std_logic := '0';
   signal bankingmode_rom : std_logic := '0';
   
   signal rtc_active      : std_logic := '0';
   signal rtc_index       : integer range 0 to 4 := 0;
   
   signal second_cnt      : unsigned(20 downto 0) := (others => '0'); -- upper bit = clock freq = 1 second
   signal rtc_seconds     : unsigned(7 downto 0) := (others => '0');
   signal rtc_minutes     : unsigned(7 downto 0) := (others => '0');
   signal rtc_hours       : std_logic_vector(7 downto 0) := (others => '0');
   signal rtc_days1       : std_logic_vector(7 downto 0) := (others => '0');
   signal rtc_days2       : std_logic_vector(7 downto 0) := (others => '0');
   
   signal rombank         : unsigned(8 downto 0);
   signal rambank         : unsigned(3 downto 0);
   
   signal wrambank          : std_logic_vector(2 downto 0);
   signal wrambank_readback : std_logic_vector(2 downto 0) := "001";
   signal wrambank_written  : std_logic;
   signal vrambank          : std_logic_vector(0 downto 0) := "0";
   signal vrambank_readback : std_logic_vector(0 downto 0) := "0";
   signal vrambank_written  : std_logic;
   
   signal rombank_offset  : unsigned(22 downto 0);
   signal rambank_offset  : unsigned(17 downto 0);
   signal wrambank_offset : unsigned(14 downto 0);
   
   signal gbrom_active         : std_logic_vector(0 downto 0);
   signal gbrom_active_written : std_logic;
   signal gbrom_off            : std_logic := '0';

   signal bus_done        : std_logic := '0';
   signal bus_out         : std_logic_vector(7 downto 0) := (others => '0');
   signal bus_active      : std_logic;
   
begin 

   bus_active <= '1' when ((unsigned(gb_bus.Adr) < x"FF00") or
                          ((unsigned(gb_bus.Adr) >= x"FF80") and (unsigned(gb_bus.Adr) < x"FFFF")))
                     else '0';

   gb_bus.done <= bus_done when bus_active = '1' else 'Z';
   gb_bus.Dout <= bus_out  when bus_active = '1' else (others => 'Z');

   -- gb registers
   iReg_Gameboy_BootRomSwitch : entity work.eProcReg generic map ( Reg_Gameboy_BootRomSwitch) port map  (clk100, gb_bus, gbrom_active, gbrom_active, gbrom_active_written);  
   
   iReg_Gameboy_VRamBank : entity work.eProcReg generic map ( Reg_Gameboy_VRamBank) port map  (clk100, gb_bus, vrambank_readback, vrambank, vrambank_written);  
   iReg_Gameboy_WRamBank : entity work.eProcReg generic map ( Reg_Gameboy_WRamBank) port map  (clk100, gb_bus, wrambank_readback, wrambank, wrambank_written);  

   process (clk100)
      variable gbbus_adr       : unsigned(15 downto 0);
      variable gbbus_adr_wram  : unsigned(15 downto 0);
   begin
      if rising_edge(clk100) then
      
         mem_request      <= '0';
         bus_done         <= '0';
         
         VRAM_PROC_we   <= '0';
         OAMRAM_PROC_we <= '0';
         
         if (new_cycles_valid = '1') then
            second_cnt <= second_cnt + new_cycles;            
         end if;
         if (second_cnt(20) = '1') then
            second_cnt(20) <= '0';
            if (rtc_seconds < 59) then
               rtc_seconds <= rtc_seconds + 1;
            else
               rtc_seconds <= (others => '0');
               if (rtc_minutes < 59) then
                  rtc_minutes <= rtc_minutes + 1;
               else
                  rtc_minutes <= (others => '0');
               end if;
            end if;
         end if;
      
         if (gb_on = '0') then
            state             <= IDLE;
            cartram_active    <= '0';
            rtc_active        <= '0';
            bankingmode_rom   <= '0';
            rombank           <= to_unsigned(1, rombank'length); 
            rambank           <= to_unsigned(0, rambank'length); 
            rtc_index         <= 0;
            rom_last_valid    <= '0';
            gbrom_off         <= '0';
            vrambank_readback <= "0";
            wrambank_readback <= std_logic_vector(to_unsigned(1, wrambank'length));
         else
         
            if (gbrom_active_written = '1' and gbrom_active = "1") then
               gbrom_off <= '1';
            end if;
         
            gbbus_adr := unsigned(gb_bus.Adr);
            if (unsigned(gb_bus.Adr) >= Reg_Gameboy_WRamBank0_Echo.adr and unsigned(gb_bus.Adr) < Reg_Gameboy_OAMRam.adr) then
               gbbus_adr_wram      := unsigned(gb_bus.Adr) - x"2000";
            else
               gbbus_adr_wram      := unsigned(gb_bus.Adr);
            end if;
            
            if (bankingmode_rom = '1' and (unsigned(Gameboy_Rombanks) / 32) > unsigned(rambank(1 downto 0))) then
               rombank_offset <= ((rambank(1 downto 0) & (4 downto 0 => '0')) + rombank) & (13 downto 0 => '0');
            else
               rombank_offset <= rombank & (13 downto 0 => '0');
            end if;
            
            if (unsigned(Gameboy_Rambanks) > 0) then
               rambank_offset <= (rambank mod unsigned(Gameboy_Rambanks)) & (12 downto 0 => '0');
            else
               rambank_offset <= (others => '0');
            end if;

            if (vrambank_written = '1') then
               vrambank_readback <= vrambank;
            end if;
            
            if (wrambank_written = '1') then
               if (wrambank = "000") then
                  wrambank_readback <= std_logic_vector(to_unsigned(1, wrambank'length));
               else
                  wrambank_readback <= wrambank;
               end if;
            end if;
            wrambank_offset <= unsigned(wrambank_readback) & (11 downto 0 => '0');
      
            case state is
            
               when IDLE =>
                  if (gb_bus.ena = '1') then
                  
                     if (gb_bus.rnw = '1') then -- read
                  
                        if (gbbus_adr >= Reg_Gameboy_RomBank0.adr and gbbus_adr < Reg_Gameboy_RomBankN.adr) then 
                           if (gbrom_off = '0') then
                              if (unsigned(gbbus_adr) < x"100" or unsigned(gbbus_adr) >= x"200") then
                                 rom_addr <= std_logic_vector((to_unsigned(GB_BootRom_start, busadr_bits) & "00") + gbbus_adr(13 downto 0));
                                 state <= READROM;
                              else
                                 rom_addr <= std_logic_vector((to_unsigned(GB_Gamerom_start, busadr_bits) & "00") + gbbus_adr(13 downto 0));
                                 state <= READROM;
                              end if;
                           else
                              rom_addr <= std_logic_vector((to_unsigned(GB_Gamerom_start, busadr_bits) & "00") + gbbus_adr(13 downto 0));
                              state <= READROM;
                           end if;
                           
                        
                        elsif (gbbus_adr >= Reg_Gameboy_RomBankN.adr and gbbus_adr < Reg_Gameboy_VRam.adr) then 
                           rom_addr <= std_logic_vector((to_unsigned(GB_Gamerom_start, busadr_bits) & "00") + gbbus_adr(13 downto 0) + rombank_offset);
                           state    <= READROM;
                        
                        elsif (gbbus_adr >= Reg_Gameboy_VRam.adr and gbbus_adr < Reg_Gameboy_CartRam.adr) then 
                           if (vrambank_readback = "0") then
                              VRAM_PROC_addr <= to_integer(gbbus_adr - x"8000");
                           else
                              VRAM_PROC_addr <= to_integer(gbbus_adr - x"6000");
                           end if;
                           state <= VRAMREADWAIT;

                        elsif (gbbus_adr >= Reg_Gameboy_CartRam.adr and gbbus_adr < Reg_Gameboy_WRamBank0.adr) then   
                           if (cartram_active = '1' and rtc_active = '0') then
                              if (bankingmode_rom = '1') then
                                 read_addr <= std_logic_vector(to_unsigned(GB_Gameram_start, busadr_bits) + gbbus_adr(12 downto 0));
                              else
                                 read_addr <= std_logic_vector(to_unsigned(GB_Gameram_start, busadr_bits) + gbbus_adr(12 downto 0) + rambank_offset);
                              end if;
                              state <= READEXTERN;
                           elsif (rtc_active = '1') then   
                              case rtc_index is
                                 when 0 => bus_out <= std_logic_vector(rtc_seconds);
                                 when 1 => bus_out <= std_logic_vector(rtc_minutes);
                                 when 2 => bus_out <= rtc_hours;  
                                 when 3 => bus_out <= rtc_days1;  
                                 when 4 => bus_out <= rtc_days2;  
                              end case;
                              bus_done <= '1';
                           else
                              bus_out  <= x"FF";
                              bus_done <= '1';
                           end if;
                           
                        elsif (gbbus_adr_wram >= Reg_Gameboy_WRamBank0.adr and gbbus_adr_wram < Reg_Gameboy_WRamBankN.adr) then   
                           read_addr <= std_logic_vector(to_unsigned(GB_WRam_start, busadr_bits) + gbbus_adr_wram(11 downto 0));
                           state <= READEXTERN;
                        
                        elsif (gbbus_adr_wram >= Reg_Gameboy_WRamBankN.adr and gbbus_adr_wram < Reg_Gameboy_WRamBank0_Echo.adr) then   
                           read_addr <= std_logic_vector(to_unsigned(GB_WRam_start, busadr_bits) + gbbus_adr_wram(11 downto 0) + wrambank_offset);   
                           state <= READEXTERN;
                        
                        elsif (gbbus_adr >= Reg_Gameboy_OAMRam.adr and gbbus_adr < Reg_Gameboy_Unusable.adr) then 
                           OAMRAM_PROC_addr <= to_integer(gbbus_adr - x"FE00");
                           state <= OAMRAMREADWAIT;
                           
                        elsif (gbbus_adr >= Reg_Gameboy_Unusable.adr and gbbus_adr < x"FF00") then 
                           bus_out  <= x"00";
                           bus_done <= '1';
                           
                        elsif (gbbus_adr >= Reg_Gameboy_HRam.adr and gbbus_adr < x"FFFF") then 
                           read_addr <= std_logic_vector(to_unsigned(GB_HRAM_start, busadr_bits) + gbbus_adr(6 downto 0));   
                           state <= READEXTERN;
                        
                        end if;
                        
                     
                     else -- write
                     
                        if (gbbus_adr < Reg_Gameboy_VRam.adr) then 
                        
                           bus_done <= '1';
                     
                           if (unsigned(Gameboy_MBC) = 1) then
                           
                              if (gbbus_adr <= x"1FFF") then
                                 if (gb_bus.Din(3 downto 0) = x"A") then
                                    cartram_active <= '1';
                                 else
                                    cartram_active <= '0';
                                 end if;
                                 
                              elsif (gbbus_adr >= x"2000" and gbbus_adr <= x"3FFF") then
                                 if (unsigned(gb_bus.Din(4 downto 0)) = 0) then
                                    rombank <= to_unsigned(1, rombank'length);
                                 else
                                    rombank <= "0000" & unsigned(gb_bus.Din(4 downto 0));
                                 end if;
                                 
                              elsif (gbbus_adr >= x"4000" and gbbus_adr <= x"5FFF") then
                                 rambank <= "00" & unsigned(gb_bus.Din(1 downto 0));
                                 
                              elsif (gbbus_adr >= x"6000" and gbbus_adr <= x"7FFF") then
                                 if (gb_bus.Din = x"00") then
                                    bankingmode_rom <= '1';
                                 else
                                    bankingmode_rom <= '0';
                                 end if;
                              end if;
   
                           elsif (unsigned(Gameboy_MBC) = 2) then
                              if (gbbus_adr <= x"1FFF" and gbbus_adr(8) = '0') then
                                 if (gb_bus.Din(3 downto 0) = x"A") then
                                    cartram_active <= '1';
                                 else
                                    cartram_active <= '0';
                                 end if;
                                 
                              elsif (gbbus_adr >= x"2000" and gbbus_adr <= x"3FFF" and gbbus_adr(8) = '1') then
                                 if (gb_bus.Din(3 downto 0) = "0000") then
                                    rombank <= to_unsigned(1, rombank'length);
                                 else
                                    rombank <= "00000" & unsigned(gb_bus.Din(3 downto 0));
                                 end if;
                              end if;   
   
                           elsif (unsigned(Gameboy_MBC) = 3) then
                              if (gbbus_adr <= x"1FFF") then
                                 if (gb_bus.Din(3 downto 0) = x"A") then
                                    cartram_active <= '1';
                                 else
                                    cartram_active <= '0';
                                 end if;
                                 
                              elsif (gbbus_adr >= x"2000" and gbbus_adr <= x"3FFF") then
                                 if (gb_bus.Din(6 downto 0) = "0000000") then
                                    rombank <= to_unsigned(1, rombank'length);
                                 else
                                    rombank <= "00" & unsigned(gb_bus.Din(6 downto 0));
                                 end if;
   
                              elsif (gbbus_adr >= x"4000" and gbbus_adr <= x"5FFF") then
                                 if (unsigned(gb_bus.Din) < 4) then
                                    rambank <= "00" & unsigned(gb_bus.Din(1 downto 0));
                                    rtc_active <= '0';
                                 else
                                    rtc_active <= '1';
                                    rtc_index <= to_integer(unsigned(gb_bus.Din)) - 8;
                                 end if;
                                                      
                              end if;
                              
                           elsif (unsigned(Gameboy_MBC) = 5) then
                              if (gbbus_adr <= x"1FFF") then
                                 if (gb_bus.Din(3 downto 0) = x"A") then
                                    cartram_active <= '1';
                                 else
                                    cartram_active <= '0';
                                 end if;
                                 
                              elsif (gbbus_adr >= x"2000" and gbbus_adr <= x"2FFF") then
                                 rombank(7 downto 0) <= unsigned(gb_bus.Din);
                                 
                              elsif (gbbus_adr >= x"3000" and gbbus_adr <= x"3FFF") then
                                 rombank(8) <= gb_bus.Din(0);
   
                              elsif (gbbus_adr >= x"4000" and gbbus_adr <= x"5FFF") then
                                 rambank <= unsigned(gb_bus.Din(3 downto 0));
                              end if;
                              
                           end if;
                        
                        elsif (gbbus_adr >= Reg_Gameboy_VRam.adr and gbbus_adr < Reg_Gameboy_CartRam.adr) then 
                           if (vrambank_readback = "0") then
                              VRAM_PROC_addr <= to_integer(gbbus_adr - x"8000");
                           else
                              VRAM_PROC_addr <= to_integer(gbbus_adr - x"6000");
                           end if;
                           VRAM_PROC_datain  <= gb_bus.Din;
                           VRAM_PROC_we      <= '1';
                           bus_done          <= '1';

                        elsif (gbbus_adr >= Reg_Gameboy_CartRam.adr and gbbus_adr < Reg_Gameboy_WRamBank0.adr) then   
                           if (cartram_active = '1' and rtc_active = '0') then
                              if (bankingmode_rom = '1') then
                                 write_addr <= std_logic_vector(to_unsigned(GB_Gameram_start, busadr_bits) + gbbus_adr(12 downto 0));
                                 write_data <= gb_bus.Din;
                              else
                                 write_addr <= std_logic_vector(to_unsigned(GB_Gameram_start, busadr_bits) + gbbus_adr(12 downto 0) + rambank_offset);
                                 write_data <= gb_bus.Din;
                              end if;
                              state <= WRITEEXTERN;
                           elsif (rtc_active = '1') then   
                              case rtc_index is
                                 when 0 => null;
                                 when 1 => null;
                                 when 2 => rtc_hours <= gb_bus.Din;
                                 when 3 => rtc_days1 <= gb_bus.Din;
                                 when 4 => rtc_days2 <= gb_bus.Din;
                              end case;
                              bus_done <= '1';
                           else
                              bus_done <= '1';
                           end if;
                           
                        elsif (gbbus_adr >= Reg_Gameboy_WRamBank0.adr and gbbus_adr < Reg_Gameboy_WRamBankN.adr) then   
                           write_addr <= std_logic_vector(to_unsigned(GB_WRam_start, busadr_bits) + gbbus_adr(11 downto 0));
                           write_data <= gb_bus.Din;
                           state <= WRITEEXTERN;
                        
                        elsif (gbbus_adr >= Reg_Gameboy_WRamBankN.adr and gbbus_adr < Reg_Gameboy_WRamBank0_Echo.adr) then   
                           write_addr <= std_logic_vector(to_unsigned(GB_WRam_start, busadr_bits) + gbbus_adr(11 downto 0) + wrambank_offset);   
                           write_data <= gb_bus.Din;
                           state <= WRITEEXTERN;
                        
                        elsif (gbbus_adr >= Reg_Gameboy_OAMRam.adr and gbbus_adr < Reg_Gameboy_Unusable.adr) then 
                           OAMRAM_PROC_addr    <= to_integer(gbbus_adr - x"FE00");
                           OAMRAM_PROC_datain  <= gb_bus.Din;
                           OAMRAM_PROC_we      <= '1';
                           bus_done            <= '1';
                           
                        elsif (gbbus_adr >= Reg_Gameboy_Unusable.adr and gbbus_adr < x"FF00") then 
                           bus_done <= '1';
                           
                        elsif (gbbus_adr >= Reg_Gameboy_HRam.adr and gbbus_adr < x"FFFF") then 
                           write_addr <= std_logic_vector(to_unsigned(GB_HRAM_start, busadr_bits) + gbbus_adr(6 downto 0));   
                           write_data <= gb_bus.Din;
                           state <= WRITEEXTERN;
                        
                        end if;
                     
                     end if; -- read/write
                     
                  end if;
               
               when READROM =>
                  if (rom_last_valid = '1' and rom_addr_last = rom_addr(rom_addr'left downto 2)) then -- if the last access was in the same area, the minicache can be used
                     if (rom_addr(1 downto 0) = "00") then bus_out  <= rom_data_last(31 downto 24); end if;
                     if (rom_addr(1 downto 0) = "01") then bus_out  <= rom_data_last(23 downto 16); end if;
                     if (rom_addr(1 downto 0) = "10") then bus_out  <= rom_data_last(15 downto  8); end if;
                     if (rom_addr(1 downto 0) = "11") then bus_out  <= rom_data_last( 7 downto  0); end if;
                     bus_done <= '1';
                     state <= IDLE; 
                  else
                     mem_addr    <= rom_addr(rom_addr'left downto 2);
                     mem_rnw     <= '1';
                     mem_request <= '1';
                     state <= WAITROM;
                  end if;
                  
               when WAITROM =>
                  if (mem_valid = '1') then
                     rom_addr_last  <= rom_addr(rom_addr'left downto 2);
                     rom_data_last  <= mem_datain;
                     rom_last_valid <= '1';
                     if (rom_addr(1 downto 0) = "00") then bus_out  <= mem_datain(31 downto 24); end if;
                     if (rom_addr(1 downto 0) = "01") then bus_out  <= mem_datain(23 downto 16); end if;
                     if (rom_addr(1 downto 0) = "10") then bus_out  <= mem_datain(15 downto  8); end if;
                     if (rom_addr(1 downto 0) = "11") then bus_out  <= mem_datain( 7 downto  0); end if;
                     bus_done <= '1';
                     state <= IDLE; 
                  end if;
               
               when READEXTERN =>
                  mem_addr    <= read_addr;
                  mem_rnw     <= '1';
                  mem_request <= '1';
                  state <= WAITREAD;
                  
               when WAITREAD =>
                  if (mem_valid = '1') then
                     bus_out  <= mem_datain(7 downto 0);
                     bus_done <= '1';
                     state <= IDLE; 
                  end if;
                  
               when WRITEEXTERN =>
                  mem_addr    <= write_addr;
                  mem_dataout <= x"000000" & write_data;
                  mem_rnw     <= '0';
                  mem_request <= '1';
                  state <= WAITWRITE;
                  
               when WAITWRITE =>
                  if (mem_valid = '1') then
                     bus_done <= '1';
                     state <= IDLE; 
                  end if;
                  
               when VRAMREADWAIT =>
                  state <= VRAMREAD; 
                  
               when VRAMREAD =>
                  bus_out  <= VRAM_PROC_dataout;
                  bus_done <= '1';
                  state <= IDLE;                
                  
               when OAMRAMREADWAIT =>
                  state <= OAMRAMREAD; 
                  
               when OAMRAMREAD =>
                  bus_out  <= OAMRAM_PROC_dataout;
                  bus_done <= '1';
                  state <= IDLE; 
            
            end case;
            
         end if;
      
      
      end if;
   end process;

end architecture;





