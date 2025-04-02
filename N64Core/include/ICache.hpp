#pragma once

#include <cstdint>
#include "CPUInstruction.hpp"

class ICache {
public:
    bool valid = false;
    uint32_t tag = 0;
    uint16_t index = 0;
    std::array<uint32_t, 8> words = {};
};
