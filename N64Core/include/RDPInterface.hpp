#pragma once

#include <cstdint>

class Bus;

enum DPCStatusBits {
    Xbus = 0,
    Freeze = 1,
    Flush = 2,
    Gclk = 3,
    TmemBusy = 4,
    PipeBusy = 5,
    CmdBusy = 6,
    CbufReady = 7,
    DPCDmaBusy = 8,
    EndPending = 9,
    StartPending = 10
};

class RDPInterface {
public:
    uint32_t status = 0;

    uint32_t start = 0;
    uint32_t end = 0;
    uint32_t current = 0;

    uint32_t pipeBusy = 0xffffff;

    uint32_t clockCounter = 0;
    bool isFrozen = false;
    bool frameFinished = false;

    RDPInterface(Bus& bus): bus(bus) {};

    Bus& bus;

    uint32_t readRegisters(uint32_t offset);
    void writeRegisters(uint32_t offset, uint32_t value);
    void updateStatus(uint32_t value);
};
