#pragma once

#include <cstdint>

typedef union MIPSInterrupt {
    struct {
        unsigned int spInterrupt: 1;
        unsigned int siInterrupt: 1;
        unsigned int aiInterrupt: 1;
        unsigned int viInterrupt: 1;
        unsigned int piInterrupt: 1;
        unsigned int dpInterrupt: 1;
    };

    uint32_t value;
} mipsinterruptbitset;

class MIPSInterface {
public:
    bool upperMode = false;
    // number of bytes (minus 1) to write in repeat mode
    uint8_t repeatCount = 0;
    bool repeatMode = false;
    bool ebus = false;

    uint32_t mipsVersion = 0x2020102;

    MIPSInterrupt mipsInterrupt;
    MIPSInterrupt mipsMask;

    void write(uint32_t value);
    void setMask(uint32_t value);
};
