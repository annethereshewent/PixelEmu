//
//  EmuBridge.hpp
//  PixelEmu
//
//  Created by Anne Castrillon on 3/31/25.
//
#pragma once

#include <stdint.h>
#include <stdbool.h>

#ifdef __cplusplus
extern "C" {
#endif

// Start the emulator with a given ROM path
void initEmulator(uint8_t* romBytes, uint32_t romSize);

// Run one frame of emulation
void step();

int* getSaveTypes();

void flattenCommands();

uint32_t* getFlattened();
uint64_t* getRowLengths();
uint64_t getSaveTypesSize();
uint64_t getNumRows();
uint64_t getWordCount();

void limitFps();
void clearFrameFinished();
bool getFrameFinished();

void clearCmdsReady();
bool getCmdsReady();

void clearEnqueuedCommands();

#ifdef __cplusplus
}
#endif
