//
//  EmuBridge.cpp
//  PixelEmu
//
//  Created by Anne Castrillon on 3/31/25.
//
#include "EmuBridge.hpp"
#include "../N64Core/include/CPU.hpp"
#include <cstdint>
#include <SDL3/SDL.h>
#include <SDL3/SDL_main.h>

static CPU* cpu = nullptr;

void initEmulator(uint8_t* romBytes, uint32_t romSize) {
    cpu = new CPU();
    cpu->bus.loadRomBytes(romBytes, romSize);
    cpu->bus.setCic();

    SDL_SetMainReady();

    if (!SDL_Init(SDL_INIT_AUDIO | SDL_INIT_VIDEO)) {
        std::println("{}", SDL_GetError());
        throw std::runtime_error("Could not initialize SDL");
    }

    SDL_Window* window = SDL_CreateWindow("PixelEmu - N64", 640, 480, SDL_WINDOW_VULKAN);

    if(window == NULL || window == nullptr) {
        std::println("window creation Error: {}", SDL_GetError());
        throw std::runtime_error("Could not initialize SDL");
    }

    cpu->bus.initRdp(window);
}

void stepFrame() {
    while (!cpu->bus.rdp.frameFinished) {
        cpu->step();
        if (!cpu->visited.contains(cpu->debugPc)) {
            std::println("[CPU] [PC: 0x{:x}] [PhysPC: 0x{:x}]", cpu->previousPc, cpu->debugPc);

            cpu->visited.insert(cpu->debugPc);
        }

    }

    cpu->limitFps();

    cpu->bus.rdp.frameFinished = false;
}


