#pragma once

typedef union DPCStatus {
    struct {
        unsigned int xbus: 1;
        unsigned int freeze: 1;
        unsigned int flush: 1;
        unsigned int gclk: 1;
        unsigned int tmemBusy: 1;
        unsigned int pipeBusy: 1;
        unsigned int cmdBusy: 1;
        unsigned int cbufReady: 1;
        unsigned int dmaBusy: 1;
        unsigned int endPending: 1;
        unsigned int startPending: 1;
    };

    uint32_t value = 0;
} dpcbitfield;

class Bus;

class RDPInterface {
public:
    DPCStatus status;

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
