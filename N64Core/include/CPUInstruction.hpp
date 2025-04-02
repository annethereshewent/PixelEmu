#pragma once

#include <cstdint>

class CPU;
typedef void (*CPUInstruction)(CPU* cpu, uint32_t instruction);
