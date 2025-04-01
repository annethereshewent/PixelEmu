//
//  EmuBridge.hpp
//  PixelEmu
//
//  Created by Anne Castrillon on 3/31/25.
//
#pragma once
#include <cstdint>

#ifdef __cplusplus
extern "C" {
#endif

// Start the emulator with a given ROM path
void loadRom(uint8_t* romBytes);

// Run one frame of emulation
void stepFrame();

#ifdef __cplusplus
}
#endif
