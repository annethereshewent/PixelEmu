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
static std::vector<uint32_t> flattened = {};
static std::vector<uint64_t> rowLengths = {};
static std::vector<std::vector<uint32_t>> enqueuedWords = {};

void initEmulator(uint8_t* romBytes, uint32_t romSize) {
    cpu = new CPU();
    cpu->bus.loadRomBytes(romBytes, romSize);
    cpu->bus.setCic();

    cpu->bus.initAudio();
}

void step() {
    cpu->step();
    if (cpu->bus.rdp.cmdsReady) {
        // process RDP commands
        enqueuedWords = cpu->bus.rdp.enqueuedWords;
        flattenCommands();
    }
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

void flattenCommands() {
    for (const auto& row : enqueuedWords) {
        rowLengths.push_back(row.size());
        flattened.insert(flattened.end(), row.begin(), row.end());
    }
}

uint64_t* getRowLengths() {
    return &rowLengths[0];
}

uint32_t* getFlattened() {
    return &flattened[0];
}

uint64_t getNumRows() {
    return rowLengths.size();
}


bool getFrameFinished() {
    return cpu->bus.rdp.frameFinished;
}

void clearFrameFinished() {
    cpu->bus.rdp.frameFinished = false;
}

bool getCmdsReady() {
    return cpu->bus.rdp.cmdsReady;
}

void clearCmdsReady() {
    cpu->bus.rdp.cmdsReady = false;
}

void limitFps() {
    cpu->limitFps();
}

void clearEnqueuedCommands() {
    flattened.clear();
    rowLengths.clear();
    cpu->bus.rdp.enqueuedWords.clear();
}

uint64_t getWordCount() {
    return flattened.size();
}
