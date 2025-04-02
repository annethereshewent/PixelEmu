#include <cstdint>

typedef union SPLength {
    struct {
        unsigned int length: 12;
        unsigned int count: 8;
        unsigned int skip: 12;
    };

    uint32_t value = 0;
} splengthbitset;
