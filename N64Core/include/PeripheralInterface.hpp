#pragma once
#include "PIStatus.hpp"

class PeripheralInterface {
public:
    PIStatus piStatus;
    uint32_t dom1Latch = 0;
    uint32_t dom2Latch = 0;

    uint32_t dom1Pwd = 0;
    uint32_t dom2Pwd = 0;

    uint32_t dom1Pgs = 0;
    uint32_t dom2Pgs = 0;

    uint32_t dom1Rls = 0;
    uint32_t dom2Rls = 0;

    uint32_t dramAddress = 0;
    uint32_t cartAddress = 0;

    uint32_t wrLen = 0;
    uint32_t rdLen = 0;

    uint32_t calculateCycles(int32_t domain, uint32_t length);
};
