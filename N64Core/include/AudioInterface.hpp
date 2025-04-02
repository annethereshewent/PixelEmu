#pragma once

#include <cstdint>
#include <array>

typedef union AIStatus {
    struct {
        unsigned int dmaFull1: 1;
        unsigned int count: 15;
        unsigned int bc: 1;
        unsigned int unused0: 1;
        unsigned int unused1: 1;
        unsigned int wc: 1;
        unsigned int unused2: 1;
        unsigned int unused3: 1;
        unsigned int unused4: 1;
        unsigned int unused5: 1;
        unsigned int unused6: 1;
        unsigned int enabled: 1;
        unsigned int unused7: 1;
        unsigned int unused8: 1;
        unsigned int unused9: 1;
        unsigned int unused10: 1;
        unsigned int unused11: 1;
        unsigned int dmaBusy: 1;
        unsigned int dmaFull2: 1;
    };

    uint32_t value = 0;
} aistatusbitset;

class Bus;

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

    AIStatus status;

    std::array<AudioDma, 2> fifo = {};

    void pushDma();
    void popDma();
    void handleDma();
    uint64_t getDuration();
};
