//
//  EmuBridge.cpp
//  PixelEmu
//
//  Created by Anne Castrillon on 3/31/25.
//
#include "EmuBridge.hpp"
#include "n64-plus/cpu/CPU.hpp"
#include <cstdint>

static CPU* cpu = nullptr;

void loadRom(uint8_t* romBytes, uint32_t romSize) {
    cpu = new CPU();
    cpu->bus.loadRomBytes(romBytes, romSize);
}

void stepFrame() {
    while (!cpu->bus.rdp.frameFinished) {
        cpu->step();
    }

    cpu->limitFps();

    cpu->bus.rdp.frameFinished = false;
}


