#include <cstdint>

typedef union RDSelect {
    struct {
        unsigned int rsel: 4;
        unsigned int tsel: 4;
    };

    uint32_t value = 0;
} rdselbitset;

typedef union Config {
    struct {
        unsigned int cc: 6;
        unsigned int autoCC: 1;
    };

    uint32_t value = 0;
} configbitset;

typedef union Mode {
    struct {
        unsigned int opMode: 2;
        unsigned int stopT: 1;
        unsigned int stopR: 1;
    };

    uint32_t value = 0;
} modebitset;

class RDInterface {
public:
    RDSelect select;
    Config config;
    Mode mode;

    bool init = false;

    uint32_t currentLoad = 0;
};
