#include <cstdint>

typedef union XScale {
    struct {
        unsigned int xScale: 12;
        unsigned int unused: 4;
        unsigned int xOffset: 12;
    };

    uint32_t value = 0;
} xscalebitset;
