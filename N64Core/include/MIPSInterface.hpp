#pragma once

#include <cstdint>

enum MIPSInterruptBit {
    SP = 0,
    SI = 1,
    AI = 2,
    VI = 3,
    PI = 4,
    DP = 5
};


class MIPSInterface {
public:
    bool upperMode = false;
    // number of bytes (minus 1) to write in repeat mode
    uint8_t repeatCount = 0;
    bool repeatMode = false;
    bool ebus = false;

    uint32_t mipsVersion = 0x2020102;

    uint32_t mipsInterrupt = 0;
    uint32_t mipsMask = 0;

    void write(uint32_t value);
    void setMask(uint32_t value);
};
