#include <cstdint>

typedef union HTotalLeap {
    struct {
        unsigned int leapB: 12;
        unsigned int unused: 4;
        unsigned int leapA: 12;
    };

    uint32_t value = 0;
} htotalleapbitset;
