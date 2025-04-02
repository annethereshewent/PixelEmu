#include <cstdint>

typedef union VVideo {
    struct {
        unsigned int vEnd: 10;
        unsigned int unused: 6;
        unsigned int vStart: 10;
    };

    uint32_t value = 0;
} vvideobitset;
