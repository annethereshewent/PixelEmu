#include <cstdint>

typedef union VCtrl {
    struct {
        unsigned int type: 2;
        unsigned int gammaDitherEnable: 1;
        unsigned int gammaEnable: 1;
        unsigned int divotEnable: 1;
        unsigned int vbusClockEnable: 1;
        unsigned int serrate: 1;
        unsigned int testMode: 1;
        unsigned int aaMode: 2;
        unsigned int unused: 1;
        unsigned int killWe: 1;
        unsigned int pixelAdvance: 4;
        unsigned int deditherEnable: 1;
    };

    uint32_t value = 0;
} vctrlbitset;
