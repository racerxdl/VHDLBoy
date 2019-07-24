
vcom -93 -quiet -work  sim/mem ^
src/mem/SyncRamDual.vhd 

vcom -quiet -work sim/gameboy ^
src/gameboy/proc_bus_gb.vhd ^
src/gameboy/reg_gb_timer.vhd ^
src/gameboy/reg_gb_joypad.vhd ^
src/gameboy/reg_gb_serial.vhd ^
src/gameboy/reg_gb_reserved.vhd ^
src/gameboy/reg_gb_mixed.vhd ^
src/gameboy/reg_gb_sound.vhd ^
src/gameboy/reg_gb_display.vhd ^
src/gameboy/reg_gb_memory.vhd ^
src/gameboy/gameboy_reservedregs.vhd ^
src/gameboy/gameboy_sound_ch1.vhd ^
src/gameboy/gameboy_sound_ch3.vhd ^
src/gameboy/gameboy_sound_ch4.vhd ^
src/gameboy/gameboy_sound.vhd ^
src/gameboy/gameboy_joypad.vhd ^
src/gameboy/gameboy_serial.vhd ^
src/gameboy/gameboy_memorymux.vhd ^
src/gameboy/gameboy_timer.vhd ^
src/gameboy/gameboy_gpu_timing.vhd ^
src/gameboy/gameboy_gpu_drawer.vhd ^
src/gameboy/gameboy_gpu.vhd

vcom -2008 -quiet -work sim/gameboy ^
src/gameboy/gameboy_cpu.vhd ^
src/gameboy/gameboy.vhd
