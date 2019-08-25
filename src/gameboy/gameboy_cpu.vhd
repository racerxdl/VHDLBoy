library IEEE;
use IEEE.std_logic_1164.all;  
use IEEE.numeric_std.all;     
use STD.textio.all;

use work.pProc_bus_gb.all;
use work.pReg_gb_mixed.all;
use work.pReg_gb_display.all;

entity gameboy_cpu is
   generic
   (
      is_simu : std_logic
   );
   port 
   (
      clk100           : in    std_logic;  
      gb_on            : in    std_logic;
      cgb              : in    std_logic;
      gb_bus           : inout proc_bus_gb_type := ((others => '0'), (others => 'Z'), (others => '0'), '1', '0', 'Z');
                       
      do_step          : in    std_logic;
      done             : out   std_logic := '0';
      HALT_out         : out   std_logic;
      
      new_cycles_out   : out   unsigned(7 downto 0) := (others => '0');
      new_cycles_valid : out   std_logic := '0';
      doublespeed_out  : out   std_logic;
      
      IRP_VBlank       : in    std_logic;
      IRP_LCDStat      : in    std_logic;
      IRP_Timer        : in    std_logic;
      IRP_Serial       : in    std_logic;
      IRP_Joypad       : in    std_logic;
      
      hblank           : in    std_logic;
      
      Linetimerdebug   : in    unsigned(8 downto 0);
      LineCountdebug   : in    unsigned(7 downto 0);
      DivReg_debug     : in    std_logic_vector(7 downto 0);
      TimeCnt_debug    : in    std_logic_vector(7 downto 0);
      cycletimer_debug : in    unsigned(15 downto 0)
   );
end entity;

architecture arch of gameboy_cpu is                                                        

   -- gb regs
   signal Gameboy_IRPFlag         : std_logic_vector(Reg_Gameboy_IRPFlag  .upper downto Reg_Gameboy_IRPFlag  .lower) := (others => '0');
   signal Gameboy_IRPFlag_intern  : std_logic_vector(Reg_Gameboy_IRPFlag  .upper downto Reg_Gameboy_IRPFlag  .lower) := (others => '0');
   signal Gameboy_IRPFlag_written : std_logic;
   
   signal Gameboy_IRPEnable      : std_logic_vector(Reg_Gameboy_IRPEnable.upper downto Reg_Gameboy_IRPEnable.lower) := (others => '0');
   
   signal Gameboy_SpeedSwitch          : std_logic_vector(Reg_Gameboy_SpeedSwitch.upper downto Reg_Gameboy_SpeedSwitch.lower) := (others => '0');
   signal Gameboy_SpeedSwitch_readback : std_logic_vector(Reg_Gameboy_SpeedSwitch.upper downto Reg_Gameboy_SpeedSwitch.lower) := (others => '0');
   signal Gameboy_SpeedSwitch_written  : std_logic;

   signal Gameboy_OAMDMA         : std_logic_vector(Reg_Gameboy_OAMDMA.upper downto Reg_Gameboy_OAMDMA.lower) := (others => '0');
   signal Gameboy_OAMDMA_written : std_logic;
   
   signal HDMA1_SourceHigh : std_logic_vector(Reg_Gameboy_HDMA1_SourceHigh.upper downto Reg_Gameboy_HDMA1_SourceHigh.lower) := (others => '0');
   signal HDMA2_SourceLow  : std_logic_vector(Reg_Gameboy_HDMA2_SourceLow .upper downto Reg_Gameboy_HDMA2_SourceLow .lower) := (others => '0');
   signal HDMA3_DestHigh   : std_logic_vector(Reg_Gameboy_HDMA3_DestHigh  .upper downto Reg_Gameboy_HDMA3_DestHigh  .lower) := (others => '0');
   signal HDMA4_DestLow    : std_logic_vector(Reg_Gameboy_HDMA4_DestLow   .upper downto Reg_Gameboy_HDMA4_DestLow   .lower) := (others => '0');
   signal HDMA5            : std_logic_vector(Reg_Gameboy_HDMA5           .upper downto Reg_Gameboy_HDMA5           .lower) := (others => '0');
   signal HDMA5_readback   : std_logic_vector(Reg_Gameboy_HDMA5           .upper downto Reg_Gameboy_HDMA5           .lower) := (others => '0');
   signal HDMA5_written    : std_logic;
    
   
   signal A : std_logic_vector(7 downto 0) := (others => '0');
   signal B : std_logic_vector(7 downto 0) := (others => '0');
   signal C : std_logic_vector(7 downto 0) := (others => '0');
   signal D : std_logic_vector(7 downto 0) := (others => '0');
   signal E : std_logic_vector(7 downto 0) := (others => '0');
   signal H : std_logic_vector(7 downto 0) := (others => '0');
   signal L : std_logic_vector(7 downto 0) := (others => '0');

   signal SP      : std_logic_vector(15 downto 0) := (others => '0');
   signal PC      : std_logic_vector(15 downto 0) := (others => '0');
   signal PC_old  : std_logic_vector(15 downto 0) := (others => '0');

   signal Flag_Zero      : std_logic := '0';
   signal Flag_Substract : std_logic := '0';
   signal Flag_Halfcarry : std_logic := '0';
   signal Flag_Carry     : std_logic := '0';

   signal HALT        : std_logic := '0';
   signal STOP        : std_logic := '0';
   signal IRPENA      : std_logic := '0';
   signal IRP_delay   : std_logic := '0';
   signal rerun_irp   : std_logic := '0';
   
   signal doublespeed     : std_logic := '0';
   signal speedswitch_req : std_logic := '0';
   
   signal cycles      : unsigned(31 downto 0) := (others => '0');
   signal newcycles   : unsigned(7 downto 0) := (others => '0');
   
   signal oamdma_required : std_logic := '0';
   signal oamdma_addr     : unsigned(15 downto 0) := (others => '0');
   
   signal HDMA_src           : unsigned(15 downto 0) := (others => '0');
   signal HDMA_dst           : unsigned(15 downto 0) := (others => '0');
   signal HDMA_Work_Left     : unsigned(6 downto 0) := (others => '1');
   signal HDMA_required      : std_logic := '0';
   signal HDMA_HBLANK        : std_logic := '0';
   signal HDMA_HBLANK_buffer : std_logic := '0';
   signal hdma_copythistime  : integer range 0 to 16 * 128 := 0;
   
   type tState is
   (
      IDLE,
      HDMA,
      HDMA_READ,
      HDMA_WRITE,
      OAMDMA_READ,
      OAMDMA_WRITE,
      READBUS,
      WAITREAD,
      EVALREAD,
      READBUSDUAL,
      WAITREADDUAL1,
      WAITREADDUAL2,
      WRITEBUS,
      WAITWRITE,
      CHECKIRP,
      INSTRDECODE,
      INSTRDECODE_ext1,
      INSTRDECODE_ext2,
      LOADFROMADDRESS,
      WRITEBACK_DATA,
      WRITEBACK_ADDR,
      LOAD_A_FROM_HRAM,
      WRITE_A_TO_HRAM,
      LOADFROMADDRESSDUAL,
      ADD_SP_PLUS_IMMI,
      WRITEBACK_DUAL1,
      WRITEBACK_DUAL2,
      PUSH,
      ADD,
      ADDCARRY,
      SUB,
      SUBCARRY,
      CALC_AND,
      CALC_OR,
      CALC_XOR,
      CALC_CP,
      INC,
      DEC,
      ADD_TO_HL,
      DAA,
      ADD_PC_PLUS_IMMI,
      CALL1,
      CALL2,
      BITTEST,
      SETBIT,
      SWAP,
      RL_WITHOUT_CARRY,
      RL_THROUGH_CARRY,
      RR_WITHOUT_CARRY,
      RR_THROUGH_CARRY,
      SHIFTLEFT,
      SHIFTRIGHT_NOCLEAR,
      SHIFTRIGHT,
      IRP1,
      IRP2
   );
   signal state : tState := IDLE;
   
   type tTask is
   (
      NONE,
      INSTRFETCH,
      INSTRFETCH_ext1,
      INSTRFETCH_ext2,
      LOADFROMADDRESS,
      WRITEBACK_DATA,
      WRITEBACK_ADDR,
      LOAD_A_FROM_HRAM,
      WRITE_A_TO_HRAM,
      LOADFROMADDRESSDUAL,
      ADD_SP_PLUS_IMMI,
      WRITEBACK_DUAL,
      PUSH,
      ADD,
      ADDCARRY,
      SUB,
      SUBCARRY,
      CALC_AND,
      CALC_OR,
      CALC_XOR,
      CALC_CP,
      INC,
      DEC,
      ADD_PC_PLUS_IMMI,
      CALL,
      BITTEST,
      SETBIT,
      SWAP,
      RL_WITHOUT_CARRY,
      RL_THROUGH_CARRY,
      RR_WITHOUT_CARRY,
      RR_THROUGH_CARRY,
      SHIFTLEFT,
      SHIFTRIGHT_NOCLEAR,
      SHIFTRIGHT,
      IRP
   );
   signal task : tTask := NONE;
   
   type tTarget is
   (
      TARGET_A,
      TARGET_B,
      TARGET_C,
      TARGET_D,
      TARGET_E,
      TARGET_H,
      TARGET_L,
      TARGET_AF,
      TARGET_BC,
      TARGET_DE,
      TARGET_HL,
      TARGET_SP,
      TARGET_PC,
      TARGET_MEM
   );
   signal target : tTarget := TARGET_A;
   
   signal read_addr       : std_logic_vector(15 downto 0) := (others => '0');
   signal read_data       : std_logic_vector( 7 downto 0) := (others => '0');
   signal read_data_dual  : std_logic_vector(15 downto 0) := (others => '0');
   signal write_addr      : std_logic_vector(15 downto 0) := (others => '0');
   signal write_data      : std_logic_vector( 7 downto 0) := (others => '0'); 
   signal write_data_dual : std_logic_vector(15 downto 0) := (others => '0'); 
   
   signal eval_data       : std_logic_vector( 7 downto 0) := (others => '0');
   signal Hoffset         : std_logic_vector( 7 downto 0) := (others => '0');
   
   signal add_data        : std_logic_vector( 7 downto 0) := (others => '0');
   signal add_data16      : std_logic_vector(15 downto 0) := (others => '0');
   
   signal bit_data        : std_logic_vector( 7 downto 0) := (others => '0');
   signal bit_select      : integer range 0 to 7 := 0;
   signal bitval          : std_logic := '0';
   
   signal swap_data       : std_logic_vector( 7 downto 0) := (others => '0');
   signal rotate_data     : std_logic_vector( 7 downto 0) := (others => '0');
   signal shift_data      : std_logic_vector( 7 downto 0) := (others => '0');
   
   signal irp_addr        : std_logic_vector(15 downto 0) := (others => '0');
   
   
   
   
begin 

   -- gb regs
   iReg_Gameboy_IRPFlag   : entity work.eProcReg generic map (Reg_Gameboy_IRPFlag  ) port map  (clk100, gb_bus, Gameboy_IRPFlag_intern, Gameboy_IRPFlag, Gameboy_IRPFlag_written); 
   iReg_Gameboy_IRPEnable : entity work.eProcReg generic map (Reg_Gameboy_IRPEnable) port map  (clk100, gb_bus, Gameboy_IRPEnable, Gameboy_IRPEnable); 
   
   iReg_Gameboy_SpeedSwitch : entity work.eProcReg generic map (Reg_Gameboy_SpeedSwitch) port map  (clk100, gb_bus, Gameboy_SpeedSwitch_readback, Gameboy_SpeedSwitch, Gameboy_SpeedSwitch_written); 

   iReg_Gameboy_OAMDMA              : entity work.eProcReg generic map (Reg_Gameboy_OAMDMA   ) port map  (clk100, gb_bus, Gameboy_OAMDMA, Gameboy_OAMDMA, Gameboy_OAMDMA_written); 
   
   iReg_Gameboy_HDMA1_SourceHigh    : entity work.eProcReg generic map (Reg_Gameboy_HDMA1_SourceHigh) port map  (clk100, gb_bus, HDMA1_SourceHigh, HDMA1_SourceHigh); 
   iReg_Gameboy_HDMA2_SourceLow     : entity work.eProcReg generic map (Reg_Gameboy_HDMA2_SourceLow ) port map  (clk100, gb_bus, HDMA2_SourceLow , HDMA2_SourceLow ); 
   iReg_Gameboy_HDMA3_DestHigh      : entity work.eProcReg generic map (Reg_Gameboy_HDMA3_DestHigh  ) port map  (clk100, gb_bus, HDMA3_DestHigh  , HDMA3_DestHigh  ); 
   iReg_Gameboy_HDMA4_DestLow       : entity work.eProcReg generic map (Reg_Gameboy_HDMA4_DestLow   ) port map  (clk100, gb_bus, HDMA4_DestLow   , HDMA4_DestLow   ); 
   iReg_Gameboy_HDMA5               : entity work.eProcReg generic map (Reg_Gameboy_HDMA5           ) port map  (clk100, gb_bus, HDMA5_readback  , HDMA5           , HDMA5_written); 
               
   
   HALT_out <= HALT;
   
   HDMA5_readback <= not HDMA_required & std_logic_vector(HDMA_Work_Left);
   
   Gameboy_SpeedSwitch_readback <= doublespeed & "000000" & speedswitch_req;
   doublespeed_out              <= doublespeed;
   
   process (clk100)
      variable result17_signed : signed(16 downto 0);
      variable result17        : unsigned(16 downto 0);
      variable result8         : unsigned(7 downto 0);
      variable result8_std     : std_logic_vector(7 downto 0);
   begin
      if rising_edge(clk100) then
      
         done             <= '0';
         gb_bus.ena       <= '0';
         new_cycles_valid <= '0';
      
         if (gb_on = '0') then
            A                      <= (others => '0');
            B                      <= (others => '0');
            C                      <= (others => '0');
            D                      <= (others => '0');
            E                      <= (others => '0');
            H                      <= (others => '0');
            L                      <= (others => '0');
            SP                     <= (others => '0');
            PC                     <= (others => '0');
            PC_old                 <= (others => '0');
            Flag_Zero              <= '0';
            Flag_Substract         <= '0';
            Flag_Halfcarry         <= '0';
            Flag_Carry             <= '0';
            HALT                   <= '0';
            STOP                   <= '0';
            IRPENA                 <= '0';
            IRP_delay              <= '0';
            rerun_irp              <= '0'; 
            cycles                 <= (others => '0');
            Gameboy_IRPFlag_intern <= x"E0";
            state                  <= IDLE;
            oamdma_required        <= '0';
            oamdma_addr            <= (others => '0');
            HDMA_required          <= '0';
            HDMA_HBLANK_buffer     <= '0';
            HDMA_Work_Left         <= (others => '1');
            doublespeed            <= '0';
            speedswitch_req        <= '0';
         else
         
            if (Gameboy_OAMDMA_written = '1') then
               oamdma_required <= '1';
               oamdma_addr     <= unsigned(Gameboy_OAMDMA) & x"00";
            end if;
            
            if (HDMA5_written = '1') then
               if (HDMA5(7) = '0' and HDMA_required = '1') then -- stop current HDMA
                  HDMA_required  <= '0';
               else
                  HDMA_src       <= unsigned(HDMA1_SourceHigh) & unsigned(HDMA2_SourceLow(7 downto 4)) & "0000";
                  HDMA_dst       <= "100" & unsigned(HDMA3_DestHigh(4 downto 0)) & unsigned(HDMA4_DestLow(7 downto 4)) & "0000";
                  HDMA_Work_Left <= unsigned(HDMA5(6 downto 0));
                  HDMA_required  <= '1';
                  HDMA_HBLANK    <= HDMA5(7);
               end if;
            end if; 

            if (HDMA_required = '1' and HDMA_HBLANK = '1' and hblank = '1') then -- next hblank
               HDMA_HBLANK_buffer <= '1';
            end if;
            
            if (Gameboy_SpeedSwitch_written = '1') then
               speedswitch_req <= Gameboy_SpeedSwitch(0);
            end if;
            
            if (Gameboy_IRPFlag_written = '1') then
               Gameboy_IRPFlag_intern <= "111" & Gameboy_IRPFlag(4 downto 0);
            end if;
            if (IRP_VBlank  = '1') then Gameboy_IRPFlag_intern(0) <= Gameboy_IRPFlag_intern(0) or (not HALT or Gameboy_IRPEnable(0)); HALT <= '0'; end if;
            if (IRP_LCDStat = '1') then Gameboy_IRPFlag_intern(1) <= Gameboy_IRPFlag_intern(1) or (not HALT or Gameboy_IRPEnable(1)); HALT <= '0'; end if;
            if (IRP_Timer   = '1') then Gameboy_IRPFlag_intern(2) <= Gameboy_IRPFlag_intern(2) or (not HALT or Gameboy_IRPEnable(2)); HALT <= '0'; end if;
            if (IRP_Serial  = '1') then Gameboy_IRPFlag_intern(3) <= Gameboy_IRPFlag_intern(3) or (not HALT or Gameboy_IRPEnable(3)); HALT <= '0'; end if;
            if (IRP_Joypad  = '1') then Gameboy_IRPFlag_intern(4) <= Gameboy_IRPFlag_intern(4) or (not HALT or Gameboy_IRPEnable(4)); HALT <= '0'; end if;
               
            case state is
            
               when IDLE =>
                  newcycles <= (others => '0');
                  if (newcycles > 0) then
                     new_cycles_valid <= '1';
                  end if;
                  
                  if (doublespeed = '1') then
                     cycles <= cycles + newcycles / 2;
                     new_cycles_out <= newcycles / 2;
                  else
                     cycles <= cycles + newcycles;
                     new_cycles_out <= newcycles;
                  end if;

                  
                  if (HDMA_required = '1' and (HDMA_HBLANK = '0' or HDMA_HBLANK_buffer = '1')) then
                     HDMA_HBLANK_buffer <= '0';
                     state              <= HDMA;
                  elsif (oamdma_required = '1') then
                     state      <= OAMDMA_READ;
                     gb_bus.Adr <= std_logic_vector(oamdma_addr);
                     gb_bus.rnw <= '1';
                     gb_bus.ena <= '1';
                  elsif (do_step = '1' or rerun_irp = '1') then
                     rerun_irp <= '0';
                     if (HALT = '1') then
                        if (doublespeed = '1') then
                           newcycles <= x"02";
                        else
                           newcycles <= x"01";
                        end if;
                     else
                        read_addr <= PC;
                        PC        <= std_logic_vector(unsigned(PC) + 1);
                        task      <= INSTRFETCH;
                        state     <= READBUS;
                     end if;                   
                  else
                     done <= '1';
                  end if;                  
                  
               -- ######################### HDMA
                  
               when HDMA =>
                  if (doublespeed = '1') then
                     newcycles   <= newcycles + 16;
                  else
                     newcycles   <= newcycles + 8;
                  end if;
                  hdma_copythistime <= 16;
                  HDMA_Work_Left <= HDMA_Work_Left - 1;
                  if (HDMA_Work_Left = 0) then
                     HDMA_required  <= '0';
                  end if;
                  HDMA_src   <= HDMA_src + 1;
                  gb_bus.Adr <= std_logic_vector(HDMA_src);
                  gb_bus.rnw <= '1';
                  gb_bus.ena <= '1';
                  state <= HDMA_READ;  
               
               when HDMA_READ =>
                  if (gb_bus.done = '1') then
                     hdma_copythistime <= hdma_copythistime - 1;
                     HDMA_dst   <= HDMA_dst + 1;
                     gb_bus.Adr <= std_logic_vector(HDMA_dst);
                     gb_bus.Din <= gb_bus.Dout;
                     gb_bus.rnw <= '0';
                     gb_bus.ena <= '1';
                     state      <= HDMA_WRITE;
                  end if;

               when HDMA_WRITE =>
                  if (gb_bus.done = '1') then
                     if (hdma_copythistime > 0) then
                        HDMA_src   <= HDMA_src + 1;
                        gb_bus.Adr <= std_logic_vector(HDMA_src);
                        gb_bus.rnw <= '1';
                        gb_bus.ena <= '1';
                        state <= HDMA_READ;
                     else
                        state <= IDLE;
                     end if;
                  end if;
               
               -- ######################### OAMDMA
                  
               when OAMDMA_READ =>
                  if (gb_bus.done = '1') then
                     oamdma_addr <= oamdma_addr + 1;
                     gb_bus.Adr <= x"FE" & std_logic_vector(oamdma_addr(7 downto 0));
                     gb_bus.Din <= gb_bus.Dout;
                     gb_bus.rnw <= '0';
                     gb_bus.ena <= '1';
                     state      <= OAMDMA_WRITE;
                     if (oamdma_addr(7 downto 0) = x"9F") then
                        oamdma_required <= '0';
                     end if;
                  end if;

               when OAMDMA_WRITE =>
                  if (gb_bus.done = '1') then
                     if (oamdma_required = '1') then
                        gb_bus.Adr <= std_logic_vector(oamdma_addr);
                        gb_bus.rnw <= '1';
                        gb_bus.ena <= '1';
                        state <= OAMDMA_READ;
                     else
                        state <= IDLE;
                     end if;
                  end if;
                  
               -- ######################### normal cycle
                  
               when READBUS =>
                  newcycles   <= newcycles + 4;
                  gb_bus.Adr  <= read_addr;
                  gb_bus.rnw  <= '1';
                  gb_bus.ena  <= '1';
                  state <= WAITREAD;
                  
               when WAITREAD => -- this is required for fpga timing closure only -> 9% performance lost!
                  if (gb_bus.done = '1') then
                     read_data   <= gb_bus.Dout;
                     eval_data   <= gb_bus.Dout;
                     state       <= EVALREAD;
                  end if;
                  
               when EVALREAD =>
                  case task is 
                     when INSTRFETCH          => state <= CHECKIRP; 
                     when INSTRFETCH_ext1     => state <= INSTRDECODE_ext1; 
                     when INSTRFETCH_ext2     => state <= INSTRDECODE_ext2; 
                     when LOADFROMADDRESS     => state <= LOADFROMADDRESS; 
                     when WRITEBACK_DATA      => state <= WRITEBACK_DATA;
                     when LOAD_A_FROM_HRAM    => state <= LOAD_A_FROM_HRAM; Hoffset <= eval_data;
                     when WRITE_A_TO_HRAM     => state <= WRITE_A_TO_HRAM; Hoffset <= eval_data;
                     when ADD_SP_PLUS_IMMI    => state <= ADD_SP_PLUS_IMMI;
                     when ADD                 => state <= ADD; add_data <= eval_data;
                     when ADDCARRY            => state <= ADDCARRY; add_data <= eval_data;
                     when SUB                 => state <= SUB; add_data <= eval_data;
                     when SUBCARRY            => state <= SUBCARRY; add_data <= eval_data;
                     when CALC_AND            => state <= CALC_AND; add_data <= eval_data;
                     when CALC_OR             => state <= CALC_OR ; add_data <= eval_data;
                     when CALC_XOR            => state <= CALC_XOR; add_data <= eval_data;
                     when CALC_CP             => state <= CALC_CP ; add_data <= eval_data;
                     when INC                 => state <= INC ; add_data <= eval_data;
                     when DEC                 => state <= DEC ; add_data <= eval_data;
                     when ADD_PC_PLUS_IMMI    => state <= ADD_PC_PLUS_IMMI;
                     when BITTEST             => state <= BITTEST; bit_data <= eval_data;
                     when SETBIT              => state <= SETBIT; write_data <= eval_data;
                     when SWAP                => state <= SWAP; swap_data <= eval_data;
                     when RL_WITHOUT_CARRY    => state <= RL_WITHOUT_CARRY  ; rotate_data <= eval_data;
                     when RL_THROUGH_CARRY    => state <= RL_THROUGH_CARRY  ; rotate_data <= eval_data;
                     when RR_WITHOUT_CARRY    => state <= RR_WITHOUT_CARRY  ; rotate_data <= eval_data;
                     when RR_THROUGH_CARRY    => state <= RR_THROUGH_CARRY  ; rotate_data <= eval_data;
                     when SHIFTLEFT           => state <= SHIFTLEFT         ; shift_data <= eval_data;
                     when SHIFTRIGHT_NOCLEAR  => state <= SHIFTRIGHT_NOCLEAR; shift_data <= eval_data;
                     when SHIFTRIGHT          => state <= SHIFTRIGHT        ; shift_data <= eval_data;
                     when others => null;
                  end case;
                  
               when READBUSDUAL =>
                  newcycles   <= newcycles + 4;
                  gb_bus.Adr  <= read_addr;
                  read_addr   <= std_logic_vector(unsigned(read_addr) + 1);
                  gb_bus.rnw  <= '1';
                  gb_bus.ena  <= '1';
                  state <= WAITREADDUAL1;
                  
               when WAITREADDUAL1 =>
                  if (gb_bus.done = '1') then
                     newcycles   <= newcycles + 4;
                     read_data_dual(7 downto 0) <= gb_bus.Dout;
                     gb_bus.Adr  <= read_addr;
                     gb_bus.ena  <= '1';
                     state <= WAITREADDUAL2;
                  end if;
                  
               when WAITREADDUAL2 =>
                  if (gb_bus.done = '1') then
                     read_data_dual(15 downto 8) <= gb_bus.Dout;
                     case task is 
                        when LOADFROMADDRESS     => read_addr <= gb_bus.Dout & read_data_dual(7 downto 0); state <= READBUS;
                        when WRITEBACK_ADDR      => state     <= WRITEBACK_ADDR;
                        when LOADFROMADDRESSDUAL => state     <= LOADFROMADDRESSDUAL;
                        when WRITEBACK_DUAL      => state     <= WRITEBACK_DUAL1;
                        when CALL                => state     <= CALL1;
                        when others => null;
                     end case;
                  end if;
                  
               when WRITEBUS =>
                  newcycles   <= newcycles + 4;
                  gb_bus.Adr  <= write_addr;
                  gb_bus.Din  <= write_data;
                  gb_bus.rnw  <= '0';
                  gb_bus.ena  <= '1';
                  state <= WAITWRITE;
                  
               when WAITWRITE =>
                  if (gb_bus.done = '1') then
                     case task is 
                        when NONE           => state <= IDLE;
                        when WRITEBACK_DUAL => state <= WRITEBACK_DUAL2;
                        when PUSH           => state <= PUSH;
                        when CALL           => state <= CALL2;
                        when IRP            => state <= IRP2;
                        when others         => state <= IDLE;
                     end case;
                     
                  end if;
                  
               when CHECKIRP => -- do this here, so IRPs have time to get into cpu before really going for INSTRDECODE
                  if (IRPENA = '1' and Gameboy_IRPFlag_intern(0) = '1' and Gameboy_IRPEnable(0) = '1') then -- IRP_VBlank
                     Gameboy_IRPFlag_intern(0) <= '0';
                     irp_addr                  <= x"0040";
                     state                     <= IRP1;
                  elsif (IRPENA = '1' and Gameboy_IRPFlag_intern(1) = '1' and Gameboy_IRPEnable(1) = '1') then -- IRP_LCDStat
                     Gameboy_IRPFlag_intern(1) <= '0';
                     irp_addr                  <= x"0048";
                     state                     <= IRP1; 
                  elsif (IRPENA = '1' and Gameboy_IRPFlag_intern(2) = '1' and Gameboy_IRPEnable(2) = '1') then -- IRP_Timer
                     Gameboy_IRPFlag_intern(2) <= '0';
                     irp_addr                  <= x"0050";
                     state                     <= IRP1; 
                  elsif (IRPENA = '1' and Gameboy_IRPFlag_intern(3) = '1' and Gameboy_IRPEnable(3) = '1') then -- IRP_Serial
                     Gameboy_IRPFlag_intern(3) <= '0';
                     irp_addr                  <= x"0058";
                     state                     <= IRP1; 
                  elsif (IRPENA = '1' and Gameboy_IRPFlag_intern(4) = '1' and Gameboy_IRPEnable(4) = '1') then -- IRP_Joypad
                     Gameboy_IRPFlag_intern(4) <= '0';
                     irp_addr                  <= x"0060";
                     state                     <= IRP1; 
                  else
                     state <= INSTRDECODE;
                     if (IRP_delay = '1') then
                        IRP_delay <= '0';
                        IRPENA    <= '1';
                     end if;
                  end if;
                  
               
               when INSTRDECODE =>
                  case read_data is

                     when x"06" | x"0E" | x"16" | x"1E" | x"26" | x"2E" => -- X = Mem[PC]
                        case read_data is
                           when x"06" => target <= TARGET_B;
                           when x"0E" => target <= TARGET_C;
                           when x"16" => target <= TARGET_D;
                           when x"1E" => target <= TARGET_E;
                           when x"26" => target <= TARGET_H;
                           when x"2E" => target <= TARGET_L;
                           when others => null;
                        end case;
                        read_addr <= PC;
                        PC        <= std_logic_vector(unsigned(PC) + 1);
                        task      <= LOADFROMADDRESS;
                        state     <= READBUS;

                     -- x = Y
                     when X"7F" => A <= A; state <= IDLE;
                     when X"78" => A <= B; state <= IDLE;
                     when X"79" => A <= C; state <= IDLE;
                     when X"7A" => A <= D; state <= IDLE;
                     when X"7B" => A <= E; state <= IDLE;
                     when X"7C" => A <= H; state <= IDLE;
                     when X"7D" => A <= L; state <= IDLE;
                     
                     when X"47" => B <= A; state <= IDLE;
                     when X"40" => B <= B; state <= IDLE;
                     when X"41" => B <= C; state <= IDLE;
                     when X"42" => B <= D; state <= IDLE;
                     when X"43" => B <= E; state <= IDLE;
                     when X"44" => B <= H; state <= IDLE;
                     when X"45" => B <= L; state <= IDLE;

                     when X"4F" => C <= A; state <= IDLE;
                     when X"48" => C <= B; state <= IDLE;
                     when X"49" => C <= C; state <= IDLE;
                     when X"4A" => C <= D; state <= IDLE;
                     when X"4B" => C <= E; state <= IDLE;
                     when X"4C" => C <= H; state <= IDLE;
                     when X"4D" => C <= L; state <= IDLE;
                     
                     when X"57" => D <= A; state <= IDLE;
                     when X"50" => D <= B; state <= IDLE;
                     when X"51" => D <= C; state <= IDLE;
                     when X"52" => D <= D; state <= IDLE;
                     when X"53" => D <= E; state <= IDLE;
                     when X"54" => D <= H; state <= IDLE;
                     when X"55" => D <= L; state <= IDLE;

                     when X"5F" => E <= A; state <= IDLE;
                     when X"58" => E <= B; state <= IDLE;
                     when X"59" => E <= C; state <= IDLE;
                     when X"5A" => E <= D; state <= IDLE;
                     when X"5B" => E <= E; state <= IDLE;
                     when X"5C" => E <= H; state <= IDLE;
                     when X"5D" => E <= L; state <= IDLE;
                     
                     when X"67" => H <= A; state <= IDLE;
                     when X"60" => H <= B; state <= IDLE;
                     when X"61" => H <= C; state <= IDLE;
                     when X"62" => H <= D; state <= IDLE;
                     when X"63" => H <= E; state <= IDLE;
                     when X"64" => H <= H; state <= IDLE;
                     when X"65" => H <= L; state <= IDLE;

                     when X"6F" => L <= A; state <= IDLE;
                     when X"68" => L <= B; state <= IDLE;
                     when X"69" => L <= C; state <= IDLE;
                     when X"6A" => L <= D; state <= IDLE;
                     when X"6B" => L <= E; state <= IDLE;
                     when X"6C" => L <= H; state <= IDLE;
                     when X"6D" => L <= L; state <= IDLE;

                     when x"0A" | x"1A" | x"7E" =>   -- A = Mem[DUALREG]
                        case read_data is
                           when x"0A" => read_addr <= B & C;
                           when x"1A" => read_addr <= D & E;
                           when x"7E" => read_addr <= H & L;
                           when others => null;
                        end case;
                        target <= TARGET_A;
                        task   <= LOADFROMADDRESS;
                        state  <= READBUS;
                        
                     when x"FA" =>                   -- A = Mem[Mem[PC]]
                        target    <= TARGET_A;
                        read_addr <= PC;
                        PC        <= std_logic_vector(unsigned(PC) + 2);
                        task      <= LOADFROMADDRESS;
                        state     <= READBUSDUAL;
                     
                     when x"3E" =>                   -- A = Mem[PC]
                        read_addr <= PC;
                        PC        <= std_logic_vector(unsigned(PC) + 1);
                        target    <= TARGET_A;
                        task      <= LOADFROMADDRESS;
                        state     <= READBUS; 
                     
                     when x"46" | x"4E" | x"56" | x"5E" | x"66" | x"6E" =>  -- X = Mem[HL]
                        case read_data is
                           when x"46" => target <= TARGET_B;
                           when x"4E" => target <= TARGET_C;
                           when x"56" => target <= TARGET_D;
                           when x"5E" => target <= TARGET_E;
                           when x"66" => target <= TARGET_H;
                           when x"6E" => target <= TARGET_L;
                           when others => null;
                        end case;
                        read_addr <= H & L;
                        task      <= LOADFROMADDRESS;
                        state     <= READBUS;
                     
                     when x"70" | x"71" | x"72" | x"73" | x"74" | x"75" => -- Mem[HL] = X
                        case read_data is
                           when x"70" => write_data <= B;
                           when x"71" => write_data <= C;
                           when x"72" => write_data <= D;
                           when x"73" => write_data <= E;
                           when x"74" => write_data <= H;
                           when x"75" => write_data <= L;
                           when others => null;
                        end case;
                        write_addr <= H & L;
                        state      <= WRITEBUS;
                        
                     when x"36" => -- Mem[HL] = Mem[PC]
                        read_addr  <= PC;
                        PC         <= std_logic_vector(unsigned(PC) + 1);
                        write_addr <= H & L;
                        task       <= WRITEBACK_DATA;
                        state      <= READBUS; 
                        
                     when x"02" | x"12" | x"77" => -- Mem[x] = A
                        case read_data is
                           when x"02" => write_addr <= B & C;
                           when x"12" => write_addr <= D & E;
                           when x"77" => write_addr <= H & L;
                           when others => null;
                        end case;
                        write_data <= A;
                        state      <= WRITEBUS; 
                        
                     when x"EA" => -- Mem[Mem[PC]] = A
                        read_addr  <= PC;
                        PC         <= std_logic_vector(unsigned(PC) + 2);
                        write_data <= A;
                        task       <= WRITEBACK_ADDR;
                        state      <= READBUSDUAL;    
                     
                     when x"F2" => -- A = HRAM[C]
                        Hoffset   <= C; 
                        state     <= LOAD_A_FROM_HRAM;
                        
                     when x"F0" => -- A = HRAM[Mem[PC]]
                        read_addr <= PC;
                        PC        <= std_logic_vector(unsigned(PC) + 1);
                        task      <= LOAD_A_FROM_HRAM;
                        state     <= READBUS; 
                        
                     when x"E2" => -- HRAM[C] = A
                        Hoffset   <= C;
                        state     <= WRITE_A_TO_HRAM;
                        
                     when x"E0" => -- HRAM[Mem[PC]] = A
                        read_addr <= PC;
                        PC        <= std_logic_vector(unsigned(PC) + 1);
                        task      <= WRITE_A_TO_HRAM;
                        state     <= READBUS;

                     when x"01" | x"11" | x"21" | x"31" => -- x|y = Mem[PC]
                        case read_data is
                           when x"01" => target <= TARGET_BC;
                           when x"11" => target <= TARGET_DE;
                           when x"21" => target <= TARGET_HL;
                           when x"31" => target <= TARGET_SP;
                           when others => null;
                        end case;
                        read_addr <= PC;
                        PC        <= std_logic_vector(unsigned(PC) + 2);
                        task      <= LOADFROMADDRESSDUAL;
                        state     <= READBUSDUAL;
                          
                     when x"F9" => -- SP = HL
                        SP        <= H & L;
                        newcycles <= newcycles + 4;
                        state     <= IDLE;
                        
                     when x"F8" => -- HL = SP + Mem[PC]
                        read_addr <= PC;
                        PC        <= std_logic_vector(unsigned(PC) + 1);
                        target    <= TARGET_HL;
                        task      <= ADD_SP_PLUS_IMMI;
                        state     <= READBUS;
                        newcycles <= newcycles + 4;
                        
                     when x"3A" =>   -- A = Mem[HL]; HL--
                        read_addr <= H & L;
                        target <= TARGET_A;
                        task   <= LOADFROMADDRESS;
                        state  <= READBUS; 
                        if (L = x"00") then
                           H <= std_logic_vector(unsigned(H) - 1);
                        end if;
                        L <= std_logic_vector(unsigned(L) - 1);
                     
                     when x"2A" =>   -- A = Mem[HL]; HL++
                        read_addr <= H & L;
                        target <= TARGET_A;
                        task   <= LOADFROMADDRESS;
                        state  <= READBUS; 
                        if (L = x"FF") then
                           H <= std_logic_vector(unsigned(H) + 1);
                        end if;
                        L <= std_logic_vector(unsigned(L) + 1);
                     
                     when x"32" =>   -- Mem[HL] = A; HL--
                        write_addr <= H & L;
                        write_data <= A;
                        state      <= WRITEBUS; 
                        if (L = x"00") then
                           H <= std_logic_vector(unsigned(H) - 1);
                        end if;
                        L <= std_logic_vector(unsigned(L) - 1);
                      
                     when x"22" =>   -- Mem[HL] = A; HL++
                        write_addr <= H & L;
                        write_data <= A;
                        state      <= WRITEBUS; 
                        if (L = x"FF") then
                           H <= std_logic_vector(unsigned(H) + 1);
                        end if;
                        L <= std_logic_vector(unsigned(L) + 1);
                        
                     when x"08" => -- Mem[Mem[PC]] = SP
                        read_addr       <= PC;
                        PC              <= std_logic_vector(unsigned(PC) + 2);
                        write_data_dual <= SP;
                        task            <= WRITEBACK_DUAL;
                        state           <= READBUSDUAL;  
                        
                     -- ################## STACK ##################################
                     
                     when x"F5" | x"C5" | x"D5" | x"E5" => -- Mem[SP - 1] = XY; SP -= 2
                        case read_data is
                           when x"F5" => write_data <= A; write_data_dual(7 downto 0) <= Flag_Zero & Flag_Substract & Flag_Halfcarry & Flag_Carry & "0000";
                           when x"C5" => write_data <= B; write_data_dual(7 downto 0) <= C;
                           when x"D5" => write_data <= D; write_data_dual(7 downto 0) <= E;
                           when x"E5" => write_data <= H; write_data_dual(7 downto 0) <= L;
                           when others => null;
                        end case;
                        SP         <= std_logic_vector(unsigned(SP) - 1);
                        write_addr <= std_logic_vector(unsigned(SP) - 1); 
                        state      <= WRITEBUS; 
                        task       <= PUSH;
                        newcycles  <= newcycles + 4;
                        
                     when x"F1" | x"C1" | x"D1" | x"E1" => -- XY = Mem[SP]; SP += 2
                        case read_data is
                           when x"F1" => target <= TARGET_AF;
                           when x"C1" => target <= TARGET_BC;
                           when x"D1" => target <= TARGET_DE;
                           when x"E1" => target <= TARGET_HL;
                           when others => null;
                        end case;
                        read_addr <= SP;
                        SP        <= std_logic_vector(unsigned(SP) + 2);
                        task      <= LOADFROMADDRESSDUAL;
                        state     <= READBUSDUAL;
                          
                          
                     -- ################## ALU ##################################     
                          
                     -- add
                     when x"87" | x"80" | x"81" | x"82" | x"83" | x"84" | x"85" => -- A = A + X
                        case read_data is
                           when x"87" => add_data <= A;
                           when x"80" => add_data <= B;
                           when x"81" => add_data <= C;
                           when x"82" => add_data <= D;
                           when x"83" => add_data <= E;
                           when x"84" => add_data <= H;
                           when x"85" => add_data <= L;
                           when others => null;
                        end case;
                        state <= ADD;
                                                
                     when x"86" => -- A = A + Mem[HL] 
                        read_addr <= H & L;
                        task      <= ADD;
                        state     <= READBUS; 
                        
                     when x"C6" => -- A = A + Mem[PC] 
                        read_addr <= PC;
                        PC        <= std_logic_vector(unsigned(PC) + 1);
                        task      <= ADD;
                        state     <= READBUS; 
                        
                     when x"8F" | x"88" | x"89" | x"8A" | x"8B" | x"8C" | x"8D" => -- A = A + X + Carry
                        case read_data is
                           when x"8F" => add_data <= A;
                           when x"88" => add_data <= B;
                           when x"89" => add_data <= C;
                           when x"8A" => add_data <= D;
                           when x"8B" => add_data <= E;
                           when x"8C" => add_data <= H;
                           when x"8D" => add_data <= L;
                           when others => null;
                        end case;
                        if (Flag_Carry = '1') then
                           state <= ADDCARRY;
                        else
                           state <= ADD;
                        end if;
                        
                     when x"8E" => -- A = A + Mem[HL] + Carry
                        read_addr <= H & L;
                        if (Flag_Carry = '1') then
                           task <= ADDCARRY;
                        else
                           task <= ADD;
                        end if;
                        state     <= READBUS; 
                        
                     when x"CE" => -- A = A + Mem[PC] + Carry
                        read_addr <= PC;
                        PC        <= std_logic_vector(unsigned(PC) + 1);
                        if (Flag_Carry = '1') then
                           task <= ADDCARRY;
                        else
                           task <= ADD;
                        end if;
                        state     <= READBUS; 
                     
                     -- sub
                     when x"97" | x"90" | x"91" | x"92" | x"93" | x"94" | x"95" => -- A = A - X
                        case read_data is
                           when x"97" => add_data <= A;
                           when x"90" => add_data <= B;
                           when x"91" => add_data <= C;
                           when x"92" => add_data <= D;
                           when x"93" => add_data <= E;
                           when x"94" => add_data <= H;
                           when x"95" => add_data <= L;
                           when others => null;
                        end case;
                        state <= SUB;
                        
                     when x"96" => -- A = A - Mem[HL] 
                        read_addr <= H & L;
                        task      <= SUB;
                        state     <= READBUS; 
                        
                     when x"D6" => -- A = A - Mem[PC] 
                        read_addr <= PC;
                        PC        <= std_logic_vector(unsigned(PC) + 1);
                        task      <= SUB;
                        state     <= READBUS; 
                        
                     when x"9F" | x"98" | x"99" | x"9A" | x"9B" | x"9C" | x"9D" => -- A = A - X - Carry
                        case read_data is
                           when x"9F" => add_data <= A;
                           when x"98" => add_data <= B;
                           when x"99" => add_data <= C;
                           when x"9A" => add_data <= D;
                           when x"9B" => add_data <= E;
                           when x"9C" => add_data <= H;
                           when x"9D" => add_data <= L;
                           when others => null;
                        end case;
                        if (Flag_Carry = '1') then
                           state <= SUBCARRY;
                        else
                           state <= SUB;
                        end if;
                        
                     when x"9E" => -- A = A - Mem[HL] - Carry
                        read_addr <= H & L;
                        if (Flag_Carry = '1') then
                           task <= SUBCARRY;
                        else
                           task <= SUB;
                        end if;
                        state     <= READBUS; 
                        
                     when x"DE" => -- A = A - Mem[PC] - Carry
                        read_addr <= PC;
                        PC        <= std_logic_vector(unsigned(PC) + 1);
                        if (Flag_Carry = '1') then
                           task <= SUBCARRY;
                        else
                           task <= SUB;
                        end if;
                        state     <= READBUS;    

                     -- AND
                     when x"A7" | x"A0" | x"A1" | x"A2" | x"A3" | x"A4" | x"A5" => -- A = A AND X
                        case read_data is
                           when x"A7" => add_data <= A;
                           when x"A0" => add_data <= B;
                           when x"A1" => add_data <= C;
                           when x"A2" => add_data <= D;
                           when x"A3" => add_data <= E;
                           when x"A4" => add_data <= H;
                           when x"A5" => add_data <= L;
                           when others => null;
                        end case;
                        state <= CALC_AND;
                        
                     when x"A6" => -- A = A AND Mem[HL] 
                        read_addr <= H & L;
                        task      <= CALC_AND;
                        state     <= READBUS; 
                        
                     when x"E6" => -- A = A AND Mem[PC] 
                        read_addr <= PC;
                        PC        <= std_logic_vector(unsigned(PC) + 1);
                        task      <= CALC_AND;
                        state     <= READBUS;   

                     -- OR
                     when x"B7" | x"B0" | x"B1" | x"B2" | x"B3" | x"B4" | x"B5" => -- A = A OR X
                        case read_data is
                           when x"B7" => add_data <= A;
                           when x"B0" => add_data <= B;
                           when x"B1" => add_data <= C;
                           when x"B2" => add_data <= D;
                           when x"B3" => add_data <= E;
                           when x"B4" => add_data <= H;
                           when x"B5" => add_data <= L;
                           when others => null;
                        end case;
                        state <= CALC_OR;
                        
                     when x"B6" => -- A = A OR Mem[HL] 
                        read_addr <= H & L;
                        task      <= CALC_OR;
                        state     <= READBUS; 
                        
                     when x"F6" => -- A = A OR Mem[PC] 
                        read_addr <= PC;
                        PC        <= std_logic_vector(unsigned(PC) + 1);
                        task      <= CALC_OR;
                        state     <= READBUS;  

                     -- XOR
                     when x"AF" | x"A8" | x"A9" | x"AA" | x"AB" | x"AC" | x"AD" => -- A = A XOR X
                        case read_data is
                           when x"AF" => add_data <= A;
                           when x"A8" => add_data <= B;
                           when x"A9" => add_data <= C;
                           when x"AA" => add_data <= D;
                           when x"AB" => add_data <= E;
                           when x"AC" => add_data <= H;
                           when x"AD" => add_data <= L;
                           when others => null;
                        end case;
                        state <= CALC_XOR;
                        
                     when x"AE" => -- A = A XOR Mem[HL] 
                        read_addr <= H & L;
                        task      <= CALC_XOR;
                        state     <= READBUS; 
                        
                     when x"EE" => -- A = A XOR Mem[PC] 
                        read_addr <= PC;
                        PC        <= std_logic_vector(unsigned(PC) + 1);
                        task      <= CALC_XOR;
                        state     <= READBUS;     

                     -- CP
                     when x"BF" | x"B8" | x"B9" | x"BA" | x"BB" | x"BC" | x"BD" => -- A = A CP X
                        case read_data is
                           when x"BF" => add_data <= A;
                           when x"B8" => add_data <= B;
                           when x"B9" => add_data <= C;
                           when x"BA" => add_data <= D;
                           when x"BB" => add_data <= E;
                           when x"BC" => add_data <= H;
                           when x"BD" => add_data <= L;
                           when others => null;
                        end case;
                        state <= CALC_CP;
                        
                     when x"BE" => -- A = A CP Mem[HL] 
                        read_addr <= H & L;
                        task      <= CALC_CP;
                        state     <= READBUS; 
                        
                     when x"FE" => -- A = A CP Mem[PC] 
                        read_addr <= PC;
                        PC        <= std_logic_vector(unsigned(PC) + 1);
                        task      <= CALC_CP;
                        state     <= READBUS;        

                     -- inc
                     when x"3C" | x"04" | x"0C" | x"14" | x"1C" | x"24" | x"2C" => -- x++
                        case read_data is
                           when x"3C" => add_data <= A; target <= TARGET_A;
                           when x"04" => add_data <= B; target <= TARGET_B;
                           when x"0C" => add_data <= C; target <= TARGET_C;
                           when x"14" => add_data <= D; target <= TARGET_D;
                           when x"1C" => add_data <= E; target <= TARGET_E;
                           when x"24" => add_data <= H; target <= TARGET_H;
                           when x"2C" => add_data <= L; target <= TARGET_L;
                           when others => null;
                        end case;
                        task  <= NONE;
                        state <= INC;                        
                          
                     when x"34" => -- Mem[HL] ++
                        read_addr  <= H & L;
                        write_addr <= H & L;
                        task       <= INC;
                        target     <= TARGET_MEM;
                        state      <= READBUS; 
                        
                     -- dec
                     when x"3D" | x"05" | x"0D" | x"15" | x"1D" | x"25" | x"2D" => -- x--
                        case read_data is
                           when x"3D" => add_data <= A; target <= TARGET_A;
                           when x"05" => add_data <= B; target <= TARGET_B;
                           when x"0D" => add_data <= C; target <= TARGET_C;
                           when x"15" => add_data <= D; target <= TARGET_D;
                           when x"1D" => add_data <= E; target <= TARGET_E;
                           when x"25" => add_data <= H; target <= TARGET_H;
                           when x"2D" => add_data <= L; target <= TARGET_L;
                           when others => null;
                        end case;
                        state <= DEC;                        
                          
                     when x"35" => -- Mem[HL] --
                        read_addr  <= H & L;
                        write_addr <= H & L;
                        task       <= DEC;
                        target     <= TARGET_MEM;
                        state      <= READBUS;
                          
                     
                     -- ################## 16 BIT ALU ##################################  
                     
                     when x"09" | x"19" | x"29" | x"39" => -- HL = HL + XY
                        case read_data is
                           when x"09" => add_data16 <= B & C;
                           when x"19" => add_data16 <= D & E;
                           when x"29" => add_data16 <= H & L;
                           when x"39" => add_data16 <= SP;
                           when others => null;
                        end case;
                        newcycles <= newcycles + 4;
                        state <= ADD_TO_HL;  
                     
                     when x"E8" => -- SP = SP + Mem[SP]
                        read_addr <= PC;
                        PC        <= std_logic_vector(unsigned(PC) + 1);
                        target    <= TARGET_SP;
                        task      <= ADD_SP_PLUS_IMMI;
                        state     <= READBUS; 
                        newcycles <= newcycles + 8;
                          
                     when x"03" | x"13" | x"23" | x"33" => -- XY++
                        case read_data is
                           when x"03" => 
                              if (C = x"FF") then 
                                 B <= std_logic_vector(unsigned(B) + 1);
                              end if;
                              C <= std_logic_vector(unsigned(C) + 1);
                           when x"13" => 
                              if (E = x"FF") then 
                                 D <= std_logic_vector(unsigned(D) + 1);
                              end if;
                              E <= std_logic_vector(unsigned(E) + 1);
                           when x"23" => 
                              if (L = x"FF") then 
                                 H <= std_logic_vector(unsigned(H) + 1);
                              end if;
                              L <= std_logic_vector(unsigned(L) + 1);
                           when x"33" => SP <= std_logic_vector(unsigned(SP) + 1);
                           when others => null;
                        end case;
                        newcycles <= newcycles + 4;
                        state <= IDLE; 
                        
                     when x"0B" | x"1B" | x"2B" | x"3B" => -- XY--
                        case read_data is
                           when x"0B" => 
                              if (C = x"00") then 
                                 B <= std_logic_vector(unsigned(B) - 1);
                              end if;
                              C <= std_logic_vector(unsigned(C) - 1);
                           when x"1B" => 
                              if (E = x"00") then 
                                 D <= std_logic_vector(unsigned(D) - 1);
                              end if;
                              E <= std_logic_vector(unsigned(E) - 1);
                           when x"2B" => 
                              if (L = x"00") then 
                                 H <= std_logic_vector(unsigned(H) - 1);
                              end if;
                              L <= std_logic_vector(unsigned(L) - 1);
                           when x"3B" => SP <= std_logic_vector(unsigned(SP) - 1);
                           when others => null;
                        end case;
                        newcycles <= newcycles + 4;
                        state <= IDLE; 
                          
                     -- ################## MISC ##################################  
                          
                     when X"27" => -- A = DAA(A)
                        state <= DAA;
                        
                     when X"2F" => -- A = not A
                        A <= not A;
                        Flag_Substract <= '1';
                        Flag_Halfcarry <= '1';
                        state <= IDLE;
                        
                     when X"3F" => -- change flags
                        Flag_Carry <= not Flag_Carry;
                        Flag_Substract <= '0';
                        Flag_Halfcarry <= '0';
                        state <= IDLE;
                        
                     when X"37" => -- change flags
                        Flag_Carry <= '1';
                        Flag_Substract <= '0';
                        Flag_Halfcarry <= '0';
                        state <= IDLE;
                          
                     when X"00" => -- NOP
                        state <= IDLE;
                        
                     when X"76" => -- HALT
                        HALT  <= '1';
                        state <= IDLE;
                        
                     when X"F3" => -- IRPENA = 0
                        IRPENA <= '0';
                        state  <= IDLE;
                        
                     when X"FB" => -- IRPENA = 1 next cycle
                        IRP_delay <= '1';
                        state <= IDLE;
                        
                     -- ################## Rotates ################################## 
                     
                     when x"07" => -- A RL without Carry
                        A <= A(6 downto 0) & A(7);
                        Flag_Carry     <= A(7);
                        Flag_Zero      <= '0';
                        Flag_Halfcarry <= '0';
                        Flag_Substract <= '0';
                        state <= IDLE;
                        
                     when x"17" => -- A RL through Carry
                        A <= A(6 downto 0) & Flag_Carry;
                        Flag_Carry     <= A(7);
                        Flag_Zero      <= '0';
                        Flag_Halfcarry <= '0';
                        Flag_Substract <= '0';
                        state <= IDLE;
                        
                     when x"0F" => -- A RR without Carry
                        A <= A(0) & A(7 downto 1);
                        Flag_Carry     <= A(0);
                        Flag_Zero      <= '0';
                        Flag_Halfcarry <= '0';
                        Flag_Substract <= '0';
                        state <= IDLE;
                        
                     when x"1F" => -- A RR through Carry
                        A <= Flag_Carry & A(7 downto 1);
                        Flag_Carry     <= A(0);
                        Flag_Zero      <= '0';
                        Flag_Halfcarry <= '0';
                        Flag_Substract <= '0';
                        state <= IDLE;
                        
                     -- ################## JUMPS ##################################
                     
                     when x"C3" | x"C2" | x"CA" | x"D2" | x"DA" => -- JP , JNZ, JZ, JNC, JC
                        if (
                              (read_data = x"C3")                     or
                              (read_data = x"C2" and Flag_Zero = '0') or 
                              (read_data = x"CA" and Flag_Zero = '1') or 
                              (read_data = x"D2" and Flag_Carry = '0') or 
                              (read_data = x"DA" and Flag_Carry = '1')
                        ) then
                           target    <= TARGET_PC;
                           read_addr <= PC;
                           task      <= LOADFROMADDRESSDUAL;
                           newcycles <= newcycles + 4;
                           state     <= READBUSDUAL;
                        else
                           PC        <= std_logic_vector(unsigned(PC) + 2);
                           newcycles <= newcycles + 8;
                           state     <= IDLE;
                        end if;
                     
                     when x"E9" => -- PC = HL
                        PC        <= H & L;
                        state     <= IDLE;
                        
                     when x"18" | x"20" | x"28" | x"30" | x"38" => -- JP PRELOAD , JNZ, JZ, JNC, JC
                        if (
                              (read_data = x"18")                     or
                              (read_data = x"20" and Flag_Zero = '0') or 
                              (read_data = x"28" and Flag_Zero = '1') or 
                              (read_data = x"30" and Flag_Carry = '0') or 
                              (read_data = x"38" and Flag_Carry = '1')
                        ) then
                           read_addr <= PC;
                           task      <= ADD_PC_PLUS_IMMI;
                           state     <= READBUS;
                           newcycles <= newcycles + 4;
                        else
                           newcycles <= newcycles + 4;
                           state     <= IDLE;
                        end if;
                        PC        <= std_logic_vector(unsigned(PC) + 1);
                          
                     when x"CD" | x"C4" | x"CC" | x"D4" | x"DC" => -- Call , CNZ, CZ, CNC, CC
                        if (
                              (read_data = x"CD")                     or
                              (read_data = x"C4" and Flag_Zero = '0') or 
                              (read_data = x"CC" and Flag_Zero = '1') or 
                              (read_data = x"D4" and Flag_Carry = '0') or 
                              (read_data = x"DC" and Flag_Carry = '1')
                        ) then
                           target    <= TARGET_PC;
                           read_addr <= PC;
                           task      <= CALL;
                           newcycles <= newcycles + 4;
                           state     <= READBUSDUAL;
                        else
                           newcycles <= newcycles + 8;
                           state     <= IDLE;
                        end if;
                        PC        <= std_logic_vector(unsigned(PC) + 2); 
                        
                     when x"C7" | x"CF" | x"D7" | x"DF" | x"E7" | x"EF" | x"F7" | x"FF" => -- rst
                        case read_data is
                           when x"C7" => read_data_dual <= x"0000";
                           when x"CF" => read_data_dual <= x"0008";
                           when x"D7" => read_data_dual <= x"0010";
                           when x"DF" => read_data_dual <= x"0018";
                           when x"E7" => read_data_dual <= x"0020";
                           when x"EF" => read_data_dual <= x"0028";
                           when x"F7" => read_data_dual <= x"0030";
                           when x"FF" => read_data_dual <= x"0038";
                           when others => null;
                        end case;
                        newcycles <= newcycles + 4;
                        task  <= CALL;
                        state <= CALL1;
                        
                     when x"C9" | x"C0" | x"C8" | x"D0" | x"D8" | x"D9" => -- RET , RNZ, RZ, RNC, RC, I
                        if (
                              (read_data = x"C9" or read_data = x"D9") or
                              (read_data = x"C0" and Flag_Zero = '0')  or 
                              (read_data = x"C8" and Flag_Zero = '1')  or 
                              (read_data = x"D0" and Flag_Carry = '0') or 
                              (read_data = x"D8" and Flag_Carry = '1')
                        ) then
                           if (read_data = x"D9") then
                              IRPENA <= '1';
                           end if;
                           target    <= TARGET_PC;
                           read_addr <= SP;
                           SP        <= std_logic_vector(unsigned(SP) + 2);
                           task      <= LOADFROMADDRESSDUAL;
                           state     <= READBUSDUAL;
                           if (read_data = x"C9" or read_data = x"D9") then
                              newcycles <= newcycles + 4;
                           else
                              newcycles <= newcycles + 8;
                           end if;
                        else
                           newcycles <= newcycles + 4;
                           state     <= IDLE;
                        end if;
                          
                     -- extented
                     when x"CB" =>
                        read_addr <= PC;
                        PC        <= std_logic_vector(unsigned(PC) + 1);
                        task      <= INSTRFETCH_ext1;
                        state     <= READBUS;
                    
                     when x"10" =>
                        read_addr <= PC;
                        PC        <= std_logic_vector(unsigned(PC) + 1);
                        task      <= INSTRFETCH_ext2;
                        state     <= READBUS;
                        
                          
                     when others =>
                        state <= IDLE;
                  
                  end case;
                  
                  
               when INSTRDECODE_ext1 =>
               
                  -- common for all these OPs
                  if (read_data(2 downto 0) = "110") then
                     target     <= TARGET_MEM;
                     read_addr  <= H & L;
                     write_addr <= H & L;
                     state      <= READBUS;
                  else
                     case to_Integer(unsigned(read_data(2 downto 0))) is
                        when 0 => target <= TARGET_B; bit_data <= B; swap_data <= B; rotate_data <= B; shift_data <= B;
                        when 1 => target <= TARGET_C; bit_data <= C; swap_data <= C; rotate_data <= C; shift_data <= C;
                        when 2 => target <= TARGET_D; bit_data <= D; swap_data <= D; rotate_data <= D; shift_data <= D;
                        when 3 => target <= TARGET_E; bit_data <= E; swap_data <= E; rotate_data <= E; shift_data <= E;
                        when 4 => target <= TARGET_H; bit_data <= H; swap_data <= H; rotate_data <= H; shift_data <= H;
                        when 5 => target <= TARGET_L; bit_data <= L; swap_data <= L; rotate_data <= L; shift_data <= L;
                        when 7 => target <= TARGET_A; bit_data <= A; swap_data <= A; rotate_data <= A; shift_data <= A;
                        when others => null;     
                     end case;
                  end if;
        
               
                  if (unsigned(read_data) >= x"40" and unsigned(read_data) <= x"7F") then -- BITTEST
                     bit_select <= to_integer(unsigned(read_data(5 downto 3)));
                     if (read_data(2 downto 0) = "110") then
                        task      <= BITTEST;
                     else
                        state     <= BITTEST;
                     end if;
                     
                  elsif (unsigned(read_data) >= x"80") then -- (RE-)SETBIT
                     bit_select <= to_integer(unsigned(read_data(5 downto 3)));
                     if (unsigned(read_data) <= x"BF") then
                        bitval <= '0';
                     else
                        bitval <= '1';
                     end if;
                     if (read_data(2 downto 0) = "110") then
                        task      <= SETBIT;
                     else
                        state     <= SETBIT;
                     end if;
                     
                  elsif (unsigned(read_data) >= x"30" and unsigned(read_data) <= x"37") then -- SWAP
                     if (read_data(2 downto 0) = "110") then
                        task      <= SWAP;
                     else
                        state     <= SWAP;
                     end if;
                     
                  elsif (unsigned(read_data) >= x"00" and unsigned(read_data) <= x"07") then -- RL without Carry
                     if (read_data(2 downto 0) = "110") then
                        task      <= RL_WITHOUT_CARRY;
                     else
                        state     <= RL_WITHOUT_CARRY;
                     end if;
                     
                  elsif (unsigned(read_data) >= x"10" and unsigned(read_data) <= x"17") then -- RL through carry
                     if (read_data(2 downto 0) = "110") then
                        task      <= RL_THROUGH_CARRY;
                     else
                        state     <= RL_THROUGH_CARRY;
                     end if;
                     
                  elsif (unsigned(read_data) >= x"08" and unsigned(read_data) <= x"0F") then -- RR without Carry
                     if (read_data(2 downto 0) = "110") then
                        task      <= RR_WITHOUT_CARRY;
                     else
                        state     <= RR_WITHOUT_CARRY;
                     end if;
                     
                  elsif (unsigned(read_data) >= x"18" and unsigned(read_data) <= x"1F") then -- RR through carry
                     if (read_data(2 downto 0) = "110") then
                        task      <= RR_THROUGH_CARRY;
                     else
                        state     <= RR_THROUGH_CARRY;
                     end if;
                   
                  elsif (unsigned(read_data) >= x"20" and unsigned(read_data) <= x"27") then -- Shiftleft
                     if (read_data(2 downto 0) = "110") then
                        task      <= SHIFTLEFT;
                     else
                        state     <= SHIFTLEFT;
                     end if;   

                  elsif (unsigned(read_data) >= x"28" and unsigned(read_data) <= x"2F") then -- SHIFTRIGHT_NOCLEAR
                     if (read_data(2 downto 0) = "110") then
                        task      <= SHIFTRIGHT_NOCLEAR;
                     else
                        state     <= SHIFTRIGHT_NOCLEAR;
                     end if;                       
                  
                  elsif (unsigned(read_data) >= x"38" and unsigned(read_data) <= x"3F") then -- SHIFTRIGHT
                     if (read_data(2 downto 0) = "110") then
                        task      <= SHIFTRIGHT;
                     else
                        state     <= SHIFTRIGHT;
                     end if; 
                  
                           
                  else
                  
                     state <= IDLE;
                 
                  end if;
               
               when INSTRDECODE_ext2 =>
                  if (read_data = x"00") then
                     STOP <= '1';
                     if (cgb = '1' and speedswitch_req = '1') then
                        doublespeed <= not doublespeed;
                        speedswitch_req <= '0';
                     end if;
                  end if;
                  state <= IDLE;

                  
               -- #####################################################
               -- ############ Second Step Commands ###################
               -- #####################################################

               when LOADFROMADDRESS =>
                  case target is
                     when TARGET_A => A <= read_data;
                     when TARGET_B => B <= read_data;
                     when TARGET_C => C <= read_data;
                     when TARGET_D => D <= read_data;
                     when TARGET_E => E <= read_data;
                     when TARGET_H => H <= read_data;
                     when TARGET_L => L <= read_data;
                     when others => null;
                  end case;
                  state <= IDLE;
            
               when WRITEBACK_DATA => -- write_addr must be set before!
                  write_data <= read_data;
                  state      <= WRITEBUS;               
                  
               when WRITEBACK_ADDR => -- write_data must be set before!
                  write_addr <= read_data_dual;
                  state      <= WRITEBUS;
            
               when LOAD_A_FROM_HRAM =>
                   read_addr <= std_logic_vector(x"FF00" + unsigned(Hoffset));
                   target    <= TARGET_A;
                   task      <= LOADFROMADDRESS;
                   state     <= READBUS;
                   
               when WRITE_A_TO_HRAM =>
                  write_addr <= std_logic_vector(x"FF00" + unsigned(Hoffset));
                  write_data <= A;
                  state      <= WRITEBUS; 
            
               when LOADFROMADDRESSDUAL =>
                  case target is
                     when TARGET_AF => A <= read_data_dual(15 downto 8); 
                        Flag_Zero      <= read_data_dual(7);
                        Flag_Substract <= read_data_dual(6);
                        Flag_Halfcarry <= read_data_dual(5);
                        Flag_Carry     <= read_data_dual(4);
                     when TARGET_BC => B <= read_data_dual(15 downto 8); C <= read_data_dual(7 downto 0);
                     when TARGET_DE => D <= read_data_dual(15 downto 8); E <= read_data_dual(7 downto 0);
                     when TARGET_HL => H <= read_data_dual(15 downto 8); L <= read_data_dual(7 downto 0);
                     when TARGET_SP => SP <= read_data_dual;
                     when TARGET_PC => PC <= read_data_dual;
                     when others => null;
                  end case;
                  state <= IDLE;
            
               when ADD_SP_PLUS_IMMI =>
                  result17_signed := signed('0' & SP) + signed(read_data);
                  Flag_Zero      <= '0';
                  Flag_Substract <= '0';
                  Flag_Halfcarry <= SP(4) xor read_data(4) xor result17_signed(4);
                  -- usually should be bit 8 of readdata, which doesn't make sense and is only sign extension, so we use 7th here as it's also sign bit
                  Flag_Carry     <= SP(8) xor result17_signed(8) xor read_data(7);   
                  if (target = TARGET_SP) then
                     SP <= std_logic_vector(result17_signed(15 downto 0));
                  else
                     H <= std_logic_vector(result17_signed(15 downto 8));
                     L <= std_logic_vector(result17_signed(7 downto 0));
                  end if;
                  state <= IDLE; 
            
               when WRITEBACK_DUAL1 =>
                  write_addr <= read_data_dual;
                  write_data <= write_data_dual(7 downto 0);
                  state      <= WRITEBUS; 
                  
               when WRITEBACK_DUAL2 =>
                  write_addr <= std_logic_vector(unsigned(read_data_dual) + 1);
                  write_data <= write_data_dual(15 downto 8);
                  state      <= WRITEBUS; 
                  task       <= NONE;
            
               when PUSH =>
                  write_data <= write_data_dual(7 downto 0);
                  SP         <= std_logic_vector(unsigned(SP) - 1);
                  write_addr <= std_logic_vector(unsigned(SP) - 1); 
                  state      <= WRITEBUS; 
                  task       <= NONE;
            
               when ADD =>
                  Flag_Carry <= '0';
                  if (to_integer(unsigned(A)) + to_integer(unsigned(add_data)) > 255) then 
                     Flag_Carry <= '1'; 
                  end if;
                  Flag_Substract <= '0';
                  A <= std_logic_vector(unsigned(A) + unsigned(add_data));
                  Flag_Halfcarry <= '0';
                  if (to_integer(unsigned(A(3 downto 0))) + to_integer(unsigned(add_data(3 downto 0))) > 15) then 
                     Flag_Halfcarry <= '1'; 
                  end if;
                  Flag_Zero <= '0';
                  if (unsigned(A) + unsigned(add_data) = 0) then
                     Flag_Zero <= '1';
                  end if;        
                  state <= IDLE;                   
                  
               when ADDCARRY =>
                  Flag_Carry <= '0';
                  if (to_integer(unsigned(A)) + to_integer(unsigned(add_data)) + 1 > 255) then 
                     Flag_Carry <= '1'; 
                  end if;
                  Flag_Substract <= '0';
                  A <= std_logic_vector(unsigned(A) + unsigned(add_data) + 1);
                  Flag_Halfcarry <= '0';
                  if ((to_integer(unsigned(A(3 downto 0))) + to_integer(unsigned(add_data(3 downto 0))) + 1) > 15) then 
                     Flag_Halfcarry <= '1'; 
                  end if;
                  Flag_Zero <= '0';
                  if (unsigned(A) + unsigned(add_data) + 1 = 0) then
                     Flag_Zero <= '1';
                  end if;
                  state <= IDLE; 

               when SUB =>
                  Flag_Carry <= '0';
                  if (unsigned(A) < unsigned(add_data)) then 
                     Flag_Carry <= '1'; 
                  end if;
                  Flag_Substract <= '1';
                  A <= std_logic_vector(unsigned(A) - unsigned(add_data));
                  Flag_Halfcarry <= '0';
                  if (unsigned(A(3 downto 0)) < unsigned(add_data(3 downto 0))) then 
                     Flag_Halfcarry <= '1'; 
                  end if;
                  Flag_Zero <= '0';
                  if (unsigned(A) - unsigned(add_data) = 0) then
                     Flag_Zero <= '1';
                  end if;      
                  state <= IDLE;                   
                  
               when SUBCARRY =>
                  Flag_Carry <= '0';
                  if (to_integer(unsigned(A)) < (to_integer(unsigned(add_data)) + 1)) then 
                     Flag_Carry <= '1'; 
                  end if;
                  Flag_Substract <= '1';
                  A <= std_logic_vector(unsigned(A) - (unsigned(add_data) + 1));
                  Flag_Halfcarry <= '0';
                  if (to_integer(unsigned(A(3 downto 0))) < (to_integer(unsigned(add_data(3 downto 0))) + 1)) then 
                     Flag_Halfcarry <= '1'; 
                  end if;
                  Flag_Zero <= '0';
                  if (unsigned(A) - (unsigned(add_data) + 1) = 0) then
                     Flag_Zero <= '1';
                  end if;
                  state <= IDLE; 
                  
               when CALC_AND =>
                  A <= A and add_data;
                  Flag_Carry <= '0';
                  Flag_Substract <= '0';
                  Flag_Halfcarry <= '1';
                  Flag_Zero <= '0';
                  if ((A and add_data) = x"00") then
                     Flag_Zero <= '1';
                  end if; 
                  state <= IDLE;                  
                  
               when CALC_OR =>
                  A <= A or add_data;
                  Flag_Carry <= '0';
                  Flag_Substract <= '0';
                  Flag_Halfcarry <= '0';
                  Flag_Zero <= '0';
                  if ((A or add_data) = x"00") then
                     Flag_Zero <= '1';
                  end if; 
                  state <= IDLE;                  
                  
               when CALC_XOR =>
                  A <= A xor add_data;
                  Flag_Carry <= '0';
                  Flag_Substract <= '0';
                  Flag_Halfcarry <= '0';
                  Flag_Zero <= '0';
                  if ((A xor add_data) = x"00") then
                     Flag_Zero <= '1';
                  end if; 
                  state <= IDLE;

               when CALC_CP =>
                  Flag_Carry <= '0';
                  if (unsigned(A) < unsigned(add_data)) then 
                     Flag_Carry <= '1'; 
                  end if;
                  Flag_Substract <= '1';
                  Flag_Halfcarry <= '0';
                  if (unsigned(A(3 downto 0)) < unsigned(add_data(3 downto 0))) then 
                     Flag_Halfcarry <= '1'; 
                  end if;
                  Flag_Zero <= '0';
                  if (unsigned(A) - unsigned(add_data) = 0) then
                     Flag_Zero <= '1';
                  end if; 
                  state <= IDLE;

               when INC =>
                  case target is
                     when TARGET_A   => A <= std_logic_vector(unsigned(add_data) + 1);
                     when TARGET_B   => B <= std_logic_vector(unsigned(add_data) + 1);
                     when TARGET_C   => C <= std_logic_vector(unsigned(add_data) + 1);
                     when TARGET_D   => D <= std_logic_vector(unsigned(add_data) + 1);
                     when TARGET_E   => E <= std_logic_vector(unsigned(add_data) + 1);
                     when TARGET_H   => H <= std_logic_vector(unsigned(add_data) + 1);
                     when TARGET_L   => L <= std_logic_vector(unsigned(add_data) + 1);
                     when TARGET_MEM => write_data <= std_logic_vector(unsigned(add_data) + 1);
                     when others => null;
                  end case;
                   
                  Flag_Substract <= '0';
                  Flag_Halfcarry <= '0';
                  if (add_data(3 downto 0) = x"F") then
                     Flag_Halfcarry <= '1';
                  end if;
                  Flag_Zero <= '0';
                  if (add_data = x"FF") then
                     Flag_Zero <= '1';
                  end if;
                  
                  if (target = TARGET_MEM) then
                     state <= WRITEBUS;
                  else
                     state <= IDLE;
                  end if;
               
               when DEC =>
                  case target is
                     when TARGET_A   => A <= std_logic_vector(unsigned(add_data) - 1);
                     when TARGET_B   => B <= std_logic_vector(unsigned(add_data) - 1);
                     when TARGET_C   => C <= std_logic_vector(unsigned(add_data) - 1);
                     when TARGET_D   => D <= std_logic_vector(unsigned(add_data) - 1);
                     when TARGET_E   => E <= std_logic_vector(unsigned(add_data) - 1);
                     when TARGET_H   => H <= std_logic_vector(unsigned(add_data) - 1);
                     when TARGET_L   => L <= std_logic_vector(unsigned(add_data) - 1);
                     when TARGET_MEM => write_data <= std_logic_vector(unsigned(add_data) - 1);
                     when others => null;
                  end case;
                   
                  Flag_Substract <= '1';
                  Flag_Halfcarry <= '0';
                  if (add_data(3 downto 0) = x"0") then
                     Flag_Halfcarry <= '1';
                  end if;
                  Flag_Zero <= '0';
                  if (add_data = x"01") then
                     Flag_Zero <= '1';
                  end if;
                  
                  if (target = TARGET_MEM) then
                     state <= WRITEBUS;
                  else
                     state <= IDLE;
                  end if;
                  
               when ADD_TO_HL =>
                  result17 := unsigned('0' & (H & L)) + unsigned('0' & (add_data16));
                  Flag_Carry <= result17(16); 
                  Flag_Substract <= '0';
                  Flag_Halfcarry <= '0';
                  if (to_integer(unsigned(H(3 downto 0)) & unsigned(L)) + to_integer(unsigned(add_data16(11 downto 0))) > 4095) then 
                     Flag_Halfcarry <= '1'; 
                  end if;    
                  H <= std_logic_vector(result17(15 downto 8));
                  L <= std_logic_vector(result17(7 downto 0));
                  state <= IDLE; 

               when DAA =>
                  result8 := unsigned(A);
                  if (Flag_Substract = '1') then
                     if (Flag_Halfcarry = '1') then 
                        result8 := result8 - 6;
                     end if;
                     if (Flag_Carry = '1') then 
                        result8 := result8 - x"60";
                     end if;
                  else
                     if (Flag_Carry = '1' or result8 > x"99") then
                        if (Flag_Halfcarry = '1' or result8(3 downto 0) > 9) then
                           result8 := result8 + x"66";
                        else
                           result8 := result8 + x"60";
                        end if;
                        Flag_Carry <= '1';
                     elsif (Flag_Halfcarry = '1' or result8(3 downto 0) > 9) then
                        result8 := result8 + 6;
                     end if;
                  end if;
                  Flag_Zero <= '0';
                  if (result8 = 0) then
                     Flag_Zero <= '1';
                  end if;
                  Flag_Halfcarry <= '0';
                  A <= std_logic_vector(result8);
                  state <= IDLE;
                  
               when ADD_PC_PLUS_IMMI =>
                  result17_signed := signed('0' & PC) + signed(read_data);
                  PC <= std_logic_vector(result17_signed(15 downto 0));
                  state <= IDLE; 
                  
               when CALL1 =>
                  write_data                  <= PC (15 downto 8);
                  write_data_dual(7 downto 0) <= PC(7 downto 0);
                  SP         <= std_logic_vector(unsigned(SP) - 1);
                  write_addr <= std_logic_vector(unsigned(SP) - 1);
                  PC         <= read_data_dual;
                  state      <= WRITEBUS; 

               when CALL2 =>
                  write_data  <= write_data_dual(7 downto 0);
                  SP         <= std_logic_vector(unsigned(SP) - 1);
                  write_addr <= std_logic_vector(unsigned(SP) - 1);
                  state      <= WRITEBUS; 
                  task       <= NONE;
               
               when BITTEST =>
                  Flag_Substract <= '0';
                  Flag_Halfcarry <= '1';
                  Flag_Zero      <= not bit_data(bit_select);
                  state <= IDLE;

               when SETBIT =>
                  case target is
                     when TARGET_A   =>          A(bit_select) <= bitval;
                     when TARGET_B   =>          B(bit_select) <= bitval;
                     when TARGET_C   =>          C(bit_select) <= bitval;
                     when TARGET_D   =>          D(bit_select) <= bitval;
                     when TARGET_E   =>          E(bit_select) <= bitval;
                     when TARGET_H   =>          H(bit_select) <= bitval;
                     when TARGET_L   =>          L(bit_select) <= bitval;
                     when TARGET_MEM => write_data(bit_select) <= bitval;
                     when others => null;
                  end case;
                  if (target = TARGET_MEM) then
                     state <= WRITEBUS;
                  else
                     state <= IDLE;
                  end if;
                  
               when SWAP =>
                  result8_std := swap_data(3 downto 0) & swap_data(7 downto 4);
                  case target is
                     when TARGET_A   =>          A <= result8_std;
                     when TARGET_B   =>          B <= result8_std;
                     when TARGET_C   =>          C <= result8_std;
                     when TARGET_D   =>          D <= result8_std;
                     when TARGET_E   =>          E <= result8_std;
                     when TARGET_H   =>          H <= result8_std;
                     when TARGET_L   =>          L <= result8_std;
                     when TARGET_MEM => write_data <= result8_std;
                     when others => null;
                  end case;
                  Flag_Substract <= '0';
                  Flag_Carry     <= '0';
                  Flag_Halfcarry <= '0';
                  Flag_Zero      <= '0';
                  if (swap_data = x"00") then
                     Flag_Zero   <= '1';
                  end if;
                  if (target = TARGET_MEM) then
                     state <= WRITEBUS;
                  else
                     state <= IDLE;
                  end if;
               
               when RL_WITHOUT_CARRY =>
                  result8_std := rotate_data(6 downto 0) & rotate_data(7);
                  case target is
                     when TARGET_A   =>          A <= result8_std;
                     when TARGET_B   =>          B <= result8_std;
                     when TARGET_C   =>          C <= result8_std;
                     when TARGET_D   =>          D <= result8_std;
                     when TARGET_E   =>          E <= result8_std;
                     when TARGET_H   =>          H <= result8_std;
                     when TARGET_L   =>          L <= result8_std;
                     when TARGET_MEM => write_data <= result8_std;
                     when others => null;
                  end case;
                  Flag_Carry     <= rotate_data(7);
                  Flag_Substract <= '0';
                  Flag_Halfcarry <= '0';
                  Flag_Zero      <= '0';
                  if (result8_std = x"00") then
                     Flag_Zero   <= '1';
                  end if;
                  if (target = TARGET_MEM) then
                     state <= WRITEBUS;
                  else
                     state <= IDLE;
                  end if;
                  
               when RL_THROUGH_CARRY =>
                  result8_std := rotate_data(6 downto 0) & Flag_Carry;
                  case target is
                     when TARGET_A   =>          A <= result8_std;
                     when TARGET_B   =>          B <= result8_std;
                     when TARGET_C   =>          C <= result8_std;
                     when TARGET_D   =>          D <= result8_std;
                     when TARGET_E   =>          E <= result8_std;
                     when TARGET_H   =>          H <= result8_std;
                     when TARGET_L   =>          L <= result8_std;
                     when TARGET_MEM => write_data <= result8_std;
                     when others => null;
                  end case;
                  Flag_Carry     <= rotate_data(7);
                  Flag_Substract <= '0';
                  Flag_Halfcarry <= '0';
                  Flag_Zero      <= '0';
                  if (result8_std = x"00") then
                     Flag_Zero   <= '1';
                  end if;
                  if (target = TARGET_MEM) then
                     state <= WRITEBUS;
                  else
                     state <= IDLE;
                  end if;
               
               when RR_WITHOUT_CARRY =>
                  result8_std := rotate_data(0) & rotate_data(7 downto 1);
                  case target is
                     when TARGET_A   =>          A <= result8_std;
                     when TARGET_B   =>          B <= result8_std;
                     when TARGET_C   =>          C <= result8_std;
                     when TARGET_D   =>          D <= result8_std;
                     when TARGET_E   =>          E <= result8_std;
                     when TARGET_H   =>          H <= result8_std;
                     when TARGET_L   =>          L <= result8_std;
                     when TARGET_MEM => write_data <= result8_std;
                     when others => null;
                  end case;
                  Flag_Carry     <= rotate_data(0);
                  Flag_Substract <= '0';
                  Flag_Halfcarry <= '0';
                  Flag_Zero      <= '0';
                  if (result8_std = x"00") then
                     Flag_Zero   <= '1';
                  end if;
                  if (target = TARGET_MEM) then
                     state <= WRITEBUS;
                  else
                     state <= IDLE;
                  end if;
                  
               when RR_THROUGH_CARRY =>
                  result8_std := Flag_Carry & rotate_data(7 downto 1);
                  case target is
                     when TARGET_A   =>          A <= result8_std;
                     when TARGET_B   =>          B <= result8_std;
                     when TARGET_C   =>          C <= result8_std;
                     when TARGET_D   =>          D <= result8_std;
                     when TARGET_E   =>          E <= result8_std;
                     when TARGET_H   =>          H <= result8_std;
                     when TARGET_L   =>          L <= result8_std;
                     when TARGET_MEM => write_data <= result8_std;
                     when others => null;
                  end case;
                  Flag_Carry     <= rotate_data(0);
                  Flag_Substract <= '0';
                  Flag_Halfcarry <= '0';
                  Flag_Zero      <= '0';
                  if (result8_std = x"00") then
                     Flag_Zero   <= '1';
                  end if;
                  if (target = TARGET_MEM) then
                     state <= WRITEBUS;
                  else
                     state <= IDLE;
                  end if;
               
               
               when SHIFTLEFT =>
                  result8_std := shift_data(6 downto 0) & '0';
                  case target is
                     when TARGET_A   =>          A <= result8_std;
                     when TARGET_B   =>          B <= result8_std;
                     when TARGET_C   =>          C <= result8_std;
                     when TARGET_D   =>          D <= result8_std;
                     when TARGET_E   =>          E <= result8_std;
                     when TARGET_H   =>          H <= result8_std;
                     when TARGET_L   =>          L <= result8_std;
                     when TARGET_MEM => write_data <= result8_std;
                     when others => null;
                  end case;
                  Flag_Carry     <= shift_data(7);
                  Flag_Substract <= '0';
                  Flag_Halfcarry <= '0';
                  Flag_Zero      <= '0';
                  if (result8_std = x"00") then
                     Flag_Zero   <= '1';
                  end if;
                  if (target = TARGET_MEM) then
                     state <= WRITEBUS;
                  else
                     state <= IDLE;
                  end if;
                  
               when SHIFTRIGHT_NOCLEAR =>
                  result8_std := shift_data(7) & shift_data(7 downto 1);
                  case target is
                     when TARGET_A   =>          A <= result8_std;
                     when TARGET_B   =>          B <= result8_std;
                     when TARGET_C   =>          C <= result8_std;
                     when TARGET_D   =>          D <= result8_std;
                     when TARGET_E   =>          E <= result8_std;
                     when TARGET_H   =>          H <= result8_std;
                     when TARGET_L   =>          L <= result8_std;
                     when TARGET_MEM => write_data <= result8_std;
                     when others => null;
                  end case;
                  Flag_Carry     <= shift_data(0);
                  Flag_Substract <= '0';
                  Flag_Halfcarry <= '0';
                  Flag_Zero      <= '0';
                  if (result8_std = x"00") then
                     Flag_Zero   <= '1';
                  end if;
                  if (target = TARGET_MEM) then
                     state <= WRITEBUS;
                  else
                     state <= IDLE;
                  end if;
                  
               when SHIFTRIGHT =>
                  result8_std := '0' & shift_data(7 downto 1);
                  case target is
                     when TARGET_A   =>          A <= result8_std;
                     when TARGET_B   =>          B <= result8_std;
                     when TARGET_C   =>          C <= result8_std;
                     when TARGET_D   =>          D <= result8_std;
                     when TARGET_E   =>          E <= result8_std;
                     when TARGET_H   =>          H <= result8_std;
                     when TARGET_L   =>          L <= result8_std;
                     when TARGET_MEM => write_data <= result8_std;
                     when others => null;
                  end case;
                  Flag_Carry     <= shift_data(0);
                  Flag_Substract <= '0';
                  Flag_Halfcarry <= '0';
                  Flag_Zero      <= '0';
                  if (result8_std = x"00") then
                     Flag_Zero   <= '1';
                  end if;
                  if (target = TARGET_MEM) then
                     state <= WRITEBUS;
                  else
                     state <= IDLE;
                  end if;
               
               when IRP1 =>
                  HALT      <= '0';
                  IRPENA    <= '0';
                  rerun_irp <= '1';
                  result17(15 downto 0) := unsigned(PC) - 1; -- reduced by 1 because we read already increased 1 before going into irp                           
                  write_data                  <= std_logic_vector(result17(15 downto 8));
                  write_data_dual(7 downto 0) <= std_logic_vector(result17(7 downto 0));
                  SP         <= std_logic_vector(unsigned(SP) - 1);
                  write_addr <= std_logic_vector(unsigned(SP) - 1);
                  PC         <= irp_addr;
                  task       <= IRP;
                  state      <= WRITEBUS; 
                  newcycles  <= newcycles + 8; -- reduced by 4 because we read once too much before going into irp
                  
               when IRP2 =>
                  write_data  <= write_data_dual(7 downto 0);
                  SP         <= std_logic_vector(unsigned(SP) - 1);
                  write_addr <= std_logic_vector(unsigned(SP) - 1);
                  state      <= WRITEBUS; 
                  task       <= NONE;              
               
               
            end case;
         

         end if;
      end if;
   end process;
   
-- synthesis translate_off
	
   -- test output
   
   goutput : if is_simu = '1' generate
   begin
   
      process
      
         file outfile: text;
         variable f_status: FILE_OPEN_STATUS;
         variable line_out : line;
         variable flags : std_logic_vector(7 downto 0); 
         variable irps : std_logic_vector(7 downto 0); 
         variable recordcount : integer := 0;
         
      begin
   
         file_open(f_status, outfile, "debug_gbsim.txt", write_mode);
         file_close(outfile);
         
         file_open(f_status, outfile, "debug_gbsim.txt", append_mode);
         
         while (true) loop
            wait until rising_edge(clk100);
            
            if (state = INSTRDECODE) then

               flags := Flag_Zero & Flag_Substract & Flag_Halfcarry & Flag_Carry & "0000";
               irps := "000" & Gameboy_IRPFlag_intern(4 downto 0);
               
               write(line_out, to_hstring(unsigned(pc) - 1) & ": ");
               write(line_out, "Ox" & to_hstring(unsigned(read_data)) & " ");
               write(line_out, "Ax" & to_hstring(unsigned(A)) & " ");
               write(line_out, "Fx" & to_hstring(unsigned(flags)) & " ");
               write(line_out, "Bx" & to_hstring(unsigned(B)) & " ");
               write(line_out, "Cx" & to_hstring(unsigned(C)) & " ");
               write(line_out, "Dx" & to_hstring(unsigned(D)) & " ");
               write(line_out, "Ex" & to_hstring(unsigned(E)) & " ");
               write(line_out, "Hx" & to_hstring(unsigned(H)) & " ");
               write(line_out, "Lx" & to_hstring(unsigned(L)) & " ");
               write(line_out, "Sx" & to_hstring(unsigned(SP)) & " ");
               write(line_out, "Ix" & to_hstring(unsigned(irps)) & " ");
               write(line_out, "Tx" & to_hstring(unsigned(cycles)) & " ");
               write(line_out, "LT" & to_hstring(Linetimerdebug) & " ");
               write(line_out, "CC" & to_hstring(cycletimer_debug) & " ");
               write(line_out, "Mx" & to_hstring(LineCountdebug) & "|");
               write(line_out,        to_hstring(unsigned(DivReg_debug)) & "|");
               write(line_out,        to_hstring(unsigned(TimeCnt_debug)) & "|");
               writeline(outfile, line_out);
               
               recordcount := recordcount + 1;
               
               if (recordcount > 1000) then
                  file_close(outfile);
                  file_open(f_status, outfile, "debug_gbsim.txt", append_mode);
                  recordcount := 0;
               end if;
               
            end if;
            
         end loop;
         
      end process;
      
   end generate goutput;
   
-- synthesis translate_on

end architecture;





