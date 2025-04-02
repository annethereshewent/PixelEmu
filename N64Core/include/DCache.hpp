#pragma once

#include <cstdint>

class DCache {
public:
    bool valid = false;
    bool dirty = false;
    uint32_t tag = 0;
    uint16_t index = 0;
    std::array<uint32_t, 4> words;
};
