#pragma once

#include <cstdint>
#include "DmaDirection.hpp"

class Bus;

typedef union SIStatus {
    struct {
        unsigned int dmaBusy: 1;
        unsigned int ioBusy: 1;
        unsigned int readPending: 1;
        unsigned int dmaError: 1;
        unsigned int pchState: 4;
        unsigned int dmaState: 4;
        unsigned int interrupt: 1;
        unsigned int reserved: 19;
    };

    uint32_t value = 0;
} sibitset;

class SerialInterface {
public:
    SIStatus status;
    uint32_t dramAddress = 0;
    DmaDirection dir = DmaDirection::None;

    void handleDma(Bus& bus);
    uint64_t processRam(Bus& bus);
    uint64_t processChannel(int channel, Bus& bus);
};
