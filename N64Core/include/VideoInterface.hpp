#pragma once

#include <cstdint>

const uint32_t SERRATE_BIT = 6;

class Scheduler;

class VideoInterface {
public:
    uint32_t countPerScanline = 0;
    uint32_t vInterrupt = 0;
    uint32_t hVideo = 0;
    uint32_t field = 0;
    uint32_t vcurrent = 0;
    uint32_t ctrl = 0;
    uint32_t origin = 0;
    uint32_t width = 0;
    uint32_t viBurst = 0;
    uint32_t vTotal = 0;
    uint32_t hTotal = 0;
    uint32_t hTotalLeap = 0;
    uint32_t vVideo = 0;
    uint32_t vBurst = 0;
    uint32_t xScale = 0;
    uint32_t yScale = 0;

    uint32_t clock = 48681812;

    bool interruptStarted = false;
    uint32_t delay = 0;

    void updateVCurrent(Scheduler& scheduler, uint64_t currentCount);
};
