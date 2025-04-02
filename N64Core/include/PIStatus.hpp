#include <cstdint>

typedef union PIStatus {
    struct {
        unsigned int dmaBusy: 1;
        unsigned int ioBusy: 1;
        unsigned int dmaError: 1;
        unsigned int dmaCompleted: 1;
    };

    uint32_t value = 0;
} pibitset;
