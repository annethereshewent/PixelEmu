//
//  EmuBridge.hpp
//  PixelEmu
//
//  Created by Anne Castrillon on 3/31/25.
//
#pragma once

#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

// Start the emulator with a given ROM path
void initEmulator(uint8_t* romBytes, uint32_t romSize, void* metalLayer);

// Run one frame of emulation
void stepFrame();

int* getSaveTypes();
uint64_t getSaveTypesSize();

#ifdef __cplusplus
}
#endif
