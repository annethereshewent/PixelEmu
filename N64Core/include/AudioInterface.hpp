#pragma once

#include <cstdint>
#include <array>

class Bus;

enum AIStatusBits {
    Full = 0,
    BC = 16,
    WC = 19,
    Enabled = 25,
    Busy = 30,
    Full2 = 31
};

class AudioDma {
public:
    uint64_t address = 0;
    uint64_t length = 0;
    uint64_t duration = 0;
};

class AudioInterface {
public:

    Bus& bus;

    bool dmaReady = false;
    bool delayedCarry = false;
    AudioInterface(Bus& bus) : bus(bus) {};

    uint32_t dramAddress = 0;
    uint32_t audioLength = 0;
    uint32_t dacRate = 0;
    uint32_t bitRate = 0;

    uint32_t frequency = 33600;

    bool dmaEnable = false;

    uint32_t status;

    std::array<AudioDma, 2> fifo = {};

    void pushDma();
    void popDma();
    void handleDma();
    uint64_t getDuration();
};
