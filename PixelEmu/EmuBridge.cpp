//
//  EmuBridge.cpp
//  PixelEmu
//
//  Created by Anne Castrillon on 3/31/25.
//
#include "EmuBridge.hpp"
#include "../N64Core/include/CPU.hpp"
#include <cstdint>

static CPU* cpu = nullptr;
static std::vector<int> saveTypes = {};

void initEmulator(uint8_t* romBytes, uint32_t romSize) {
    cpu = new CPU();
    cpu->bus.loadRomBytes(romBytes, romSize);
    cpu->bus.setCic();

    cpu->bus.initAudio();
}

void stepFrame() {
    while (!cpu->bus.rdp.frameFinished) {
        cpu->step();
    }

    cpu->limitFps();

    cpu->bus.rdp.frameFinished = false;
}

int* getSaveTypes() {
    for (SaveType type: cpu->bus.saveTypes) {
        saveTypes.push_back((int)type);
    }

    return &saveTypes[0];
}

uint64_t getSaveTypesSize() {
    return saveTypes.size();
}

