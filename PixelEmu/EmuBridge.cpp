//
//  EmuBridge.cpp
//  PixelEmu
//
//  Created by Anne Castrillon on 3/31/25.
//
#include "EmuBridge.hpp"
#include "../N64Core/include/CPU.hpp"
#include <cstdint>
#define SDL_MAIN_HANDLED
#include <SDL3/SDL.h>

static CPU* cpu = nullptr;

void initEmulator(uint8_t* romBytes, uint32_t romSize) {
    cpu = new CPU();
    cpu->bus.loadRomBytes(romBytes, romSize);
    cpu->bus.setCic();

    if (!SDL_Init(SDL_INIT_AUDIO | SDL_INIT_VIDEO)) {
        std::println("{}", SDL_GetError());
        throw std::runtime_error("Could not initialize SDL");
    }

    SDL_Window* window = SDL_CreateWindow("PixelEmu - N64", 640, 480, SDL_WINDOW_VULKAN);

    if(window == NULL || window == nullptr) {
        std::println("window creation Error: %s\n", SDL_GetError());
        throw std::runtime_error("Could not initialize SDL");
    }

    cpu->bus.initRdp(window);
}

void stepFrame() {
    while (!cpu->bus.rdp.frameFinished) {
        cpu->step();
    }

    cpu->limitFps();

    cpu->bus.rdp.frameFinished = false;
}


