#include <cstdint>

class RDInterface {
public:
    uint32_t select = 0;
    uint32_t config = 0;
    uint32_t mode = 0;

    bool init = false;

    uint32_t currentLoad = 0;
};
