#pragma once

#include <cstdint>


typedef union Cop0Status {
    struct {
        unsigned int interruptEnable: 1;
        unsigned int exl: 1;
        unsigned int erl: 1;
        unsigned int unused0: 19;
        unsigned int bev: 1;
        unsigned int unused1: 3;
        unsigned int fr: 1;
        unsigned int unused2: 2;
        unsigned int cu1: 1;
        unsigned int cu2: 1;
    };

    uint32_t value = 0;
} cop0statusbitset;
