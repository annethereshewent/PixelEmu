#include <cstdint>

class TlbEntry {
public:
    TlbEntry() {
        mask = 0;
        vpn2 = 0;
        region = 0;
        g = 0;
        asid = 0;

        pfnEven = 0;

        cEven = 0;
        dEven = 0;
        vEven = 0;

        pfnOdd = 0;

        cOdd = 0;
        dOdd = 0;
        vOdd = 0;

        startEven = 0;
        endEven = 0;
        physEven = 0;

        startOdd = 0;
        endOdd = 0;
        physOdd = 0;
    };
    uint64_t mask;
    uint64_t vpn2;

    uint8_t region;
    uint8_t g;
    uint8_t asid;

    uint64_t pfnEven;

    uint8_t cEven;
    uint8_t dEven;
    uint8_t vEven;

    uint64_t pfnOdd;

    uint8_t cOdd;
    uint8_t dOdd;
    uint8_t vOdd;

    uint64_t startEven;
    uint64_t endEven;
    uint64_t physEven;

    uint64_t startOdd;
    uint64_t endOdd;
    uint64_t physOdd;
};

class TlbLut {
public:
    uint64_t address;
    bool cached;
};
