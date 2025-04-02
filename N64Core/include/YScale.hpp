#include <cstdint>

typedef union YScale {
    struct {
        unsigned int xScale: 12;
        unsigned int unused: 4;
        unsigned int xOffset: 10;
    };

    uint32_t value = 0;
} yscalebitset;
