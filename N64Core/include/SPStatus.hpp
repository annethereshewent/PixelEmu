#include <cstdint>

typedef union SPStatus {
    struct {
        unsigned int halted: 1;
        unsigned int broke: 1;
        unsigned int dmaBusy: 1;
        unsigned int dmaFull: 1;
        unsigned int ioBusy: 1;
        unsigned int singleStep: 1;
        unsigned int intBreak: 1;
        unsigned int flag0: 1;
        unsigned int flag1: 1;
        unsigned int flag2: 1;
        unsigned int flag3: 1;
        unsigned int flag4: 1;
        unsigned int flag5: 1;
        unsigned int flag6: 1;
        unsigned int flag7: 1;
    };

    uint32_t value = 0;
} spbitset;
