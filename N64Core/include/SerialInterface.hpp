#pragma once

#include <cstdint>
#include "DmaDirection.hpp"

class Bus;

enum SIStatusBits {
    SiDmaBusy = 0,
    SiIoBusy = 1,
    SiReadPending = 2,
    SiDmaError = 3,
    SiInterrupt = 12
};

class SerialInterface {
public:
    uint32_t status = 0;
    uint32_t dramAddress = 0;
    DmaDirection dir = DmaDirection::None;

    void handleDma(Bus& bus);
    uint64_t processRam(Bus& bus);
    uint64_t processChannel(int channel, Bus& bus);
};
