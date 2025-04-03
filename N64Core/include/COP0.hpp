#pragma once

#include <cstdint>
#include <vector>
#include "CPUInstruction.hpp"
#include "Scheduler.hpp"

class CPU;

enum Cop0StatusBits {
   InterruptEnable = 0,
   Exl = 1,
   Erl = 2,
   Bev = 22,
   Fr = 26,
   Cu1 = 29,
   Cu2 = 30
};

class COP0 {
public:
    uint32_t index = 0;
    uint32_t random = 0;
    uint64_t entryLo0 = 0;
    uint64_t entryLo1 = 0;
    uint64_t context = 0;
    uint32_t pageMask = 0;
    uint32_t wired = 0;
    uint64_t badVAddress = 0;
    uint64_t count = 0;
    uint64_t entryHi = 0;
    uint32_t compare = 0;
    uint32_t status;
    uint32_t cause = 0 ;
    uint64_t epc = 0;
    uint32_t prid = 0;
    uint32_t config = 0;
    uint32_t llAddress = 0;
    uint32_t watchLo = 0;
    uint32_t watchHi = 0;
    uint64_t xContext = 0;
    uint32_t parityError = 0;
    uint32_t cacheError = 0;
    uint32_t tagLo = 0;
    uint32_t tagHi = 0;
    uint64_t errorEpc = 0;

    uint64_t latch = 0;

    CPU& cpu;

    bool pendingInterrupt = false;

    COP0(CPU& cpu);

    static void mfc0(CPU* cpu, uint32_t instruction);
    static void dmfc0(CPU* cpu, uint32_t instruction);
    static void mtc0(CPU* cpu, uint32_t instruction);
    static void dmtc0(CPU* cpu, uint32_t instruction);
    static void cp0(CPU* cpu, uint32_t instruction);
    static void syscall(CPU* cpu, uint32_t instruction);
    static void break_(CPU* cpu, uint32_t instruction);
    static void tlbr(CPU* cpu, uint32_t instruction);
    static void tlbwi(CPU* cpu, uint32_t instruction);
    static void tlbwr(CPU* cpu, uint32_t instruction);
    static void tlbp(CPU* cpu, uint32_t instruction);
    static void eret(CPU* cpu, uint32_t instruction);

    static void reserved(CPU* cpu, uint32_t instruction);

    void writeRegister(uint32_t index, uint64_t value, Scheduler* scheduler);

    void addCycles(uint32_t cycles);
    uint64_t readRegister(uint32_t index);

    std::array<CPUInstruction, 64> instructions;
    std::array<CPUInstruction, 32> cp0Instructions;
};
