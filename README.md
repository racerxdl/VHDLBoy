# VHDLBoy
VHDL Gameboy Color implementation

## Scope
- All internal Gameboy features for Singleplayer
  - CPU
  - Bussystem
  - Video (CGB colorization is mandatory!)
  - Timer
  - Sound
  - Joypad

- Gamemodule Memory Controller (MBC1,2,3,5)
- Speed multiplier system (Turbo Mode support)

### Out of Scope
- External Hardware
  - Printer
  - Camera
  - Link Cable
  - RTC (games that require RTC will still run and time is saved)
  ...

- Further FPGA Features
  - Graphics Output (e.g. VGA)
  - Memory connection (e.g. SDRam)
  - Controller (e.g. USB Gamepad, PS2 Keyboard, ...)

- Cycle accuracy(see Accuracy)

## Compatibility

### Gameboy Games

- All tested games start.
- Some have light graphical glitches.
- Game that use extensive window switching may produce Window flickering (e.g. WaveRace).
- As i did'n't play through a lot of games, i cannot give a final overview.

### Gameboy Color Games

- Most tested games start
- Know problems are:
  - very large games(4MB)
  - Game&Watch series, GTA2, Lufia

## How to Use

### Requirements:
- FPGA Board(e.g. Altera DE2-115)
  - with some MByte Ram, Small access time goes before MHz
  - with video output (VGA is easy)

- Some kind of housekeeping, e.g. Softcore or connected PC
  - Gameboy Core does NOT analyze the rom, so MBC/Romsize/Ramsize need to be set at port level
  - Save of gameram must be taken care off or savegames will be lost

- Skillset
  - You should be able to implement VGA/SDram Core in VHDl/Verilog
  - Being able to simulate VHDL with e.g. Modelsim will help a lot
  
- Gameboy Color Bootrom
   - Core doesn't implemented the original Gameboy black and White palettes
   - Bootrom MUST set the color palettes, otherwise screen will stay blank
   - Original bootrom does that, but using may not be legal
   - There are free bootroms available, but not tested yet

### What to do:
- Connect all the ports of the toplevel (gameboy.vhd) with your design. All Ports are described in the top level port list.

#### Some hints for not obvious parts:
- Getting MBC/ROM/Ramsize: read "Gameboy Pan Docs"
- Memory: provide an interface to 8 MByte of memory and write Gamerom and Bootrom to this memory at the correct position (see Memorymux.vhd) BEFORE switching on the core

### Implementation
- In Cyclone 4 FPGA: ~10000 LEs, ~500Kbit Memory
- All code was written from scratch
- No vendor specific modules used
- all internal memories (mainly for Video) are inferred
- Clk has a 100 MHz target
  - this will allow for up to 8x original Speed at 100 ns Memory latency.
  - if your timing closure is hard to reach for 100 Mhz you can go down easy, only sound sampling needs to be modified
- Sound is done for 48 Khz Sampling rate
  - if you need other sampling rate or lower the 100 Mhz clock, you need to modify gameboy_sound.vhd

## Accuracy

- All Blargg CPU Tests passed.
- Compatibility was designed to match PC emulator. (Same clock by clock behavior)

This core/emulator is not cycle accurate. This was never the target in the development and is probably hard to come by now as the core is done.

Why would you want cycle accuracy?
- A 100% cycle accurate system would behave exactly like the old Gameboy and all games would run the same way.

Why is this Core designed without that goal?
- Today(2019), there is no fully cycle accurate emulator at all and they have had plenty of manpower and years. So taking this approach would be very hard to get by.
- Most very good GB/GBC emulators are not very accurate but still very compatible.
- Development is very hard. You need testroms and fulfill those and hopefully games will run afterwards, while fixing bugs in games will just make the game run, enough for most users


