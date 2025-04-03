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
    uint32_t vcurrent;
    uint32_t ctrl;
    uint32_t origin = 0;
    uint32_t width = 0;
    uint32_t viBurst = 0;
    uint32_t vTotal = 0;
    uint32_t hTotal = 0;
    uint32_t hTotalLeap;
    uint32_t vVideo;
    uint32_t vBurst = 0;
    uint32_t xScale;
    uint32_t yScale;

    uint32_t clock = 48681812;

    bool interruptStarted;
    uint32_t delay;

    void updateVCurrent(Scheduler& scheduler, uint64_t currentCount);
};
