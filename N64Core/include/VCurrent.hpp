#include <cstdint>

typedef union VCurrent {
    struct {
        unsigned int vField: 1;
        unsigned int vCurrent: 9;
    };

    uint32_t value = 0;
} vcurrentbitset;
