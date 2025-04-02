#pragma once

#include "Bus.hpp"
#include <vector>
#include "CPUInstruction.hpp"
#include "COP0.hpp"
#include "COP1.hpp"
#include <unordered_set>
#include <unordered_map>
#include "Scheduler.hpp"

const uint64_t FPS_INTERVAL = 1000 / 60;

class CPU {
public:
    std::array<uint64_t, 32> r = {};

    std::unordered_map<uint64_t, uint64_t> branches = {};

    uint32_t clock = 93750000;
    bool llbit = false;

    uint64_t hi = 0;
    uint64_t lo = 0;

    uint64_t previousPc;
    uint64_t pc;
    uint64_t nextPc;

    uint64_t debugPc;
    bool debugFinished = false;

    uint64_t instructionCount = 0;

    Scheduler scheduler;

    Bus bus;

    COP0 cop0;
    COP1 cop1;

    uint64_t timestamp = 0;

    bool discarded = false;

    bool debugOn = false;

    bool inDelaySlot = false;

    CPU();

    std::array<CPUInstruction, 64> instructions;
    std::array<CPUInstruction, 64> secondary;
    std::array<CPUInstruction, 32> registerInstructions;

    std::unordered_set<uint64_t> visited;

    void set(int i, uint64_t val);

    void step();

    void checkIrqs(bool usePreviousPc = true);
    void enterException(bool usePreviousPc = false, uint64_t offset = 0x180);

    void fastForwardRelativeLoop(int16_t amount);
    void fastForwardAbsoluteLoop(uint64_t target);

    void limitFps();

    // instructions
    static void reserved(CPU* cpu, uint32_t instruction);
    static void j(CPU* cpu, uint32_t instruction);
    static void jal(CPU* cpu, uint32_t instruction);
    static void beq(CPU* cpu, uint32_t instruction);
    static void bne(CPU* cpu, uint32_t instruction);
    static void blez(CPU* cpu, uint32_t instruction);
    static void bgtz(CPU* cpu, uint32_t instruction);
    static void addi(CPU* cpu, uint32_t instruction);
    static void addiu(CPU* cpu, uint32_t instruction);
    static void slti(CPU* cpu, uint32_t instruction);
    static void sltiu(CPU* cpu, uint32_t instruction);
    static void andi(CPU* cpu, uint32_t instruction);
    static void ori(CPU* cpu, uint32_t instruction);
    static void xori(CPU* cpu, uint32_t instruction);
    static void lui(CPU* cpu, uint32_t instruction);
    static void beql(CPU* cpu, uint32_t instruction);
    static void bnel(CPU* cpu, uint32_t instruction);
    static void blezl(CPU* cpu, uint32_t instruction);
    static void bgtzl(CPU* cpu, uint32_t instruction);
    static void daddi(CPU* cpu, uint32_t instruction);
    static void daddiu(CPU* cpu, uint32_t instruction);
    static void ldl(CPU* cpu, uint32_t instruction);
    static void ldr(CPU* cpu, uint32_t instruction);
    static void lb(CPU* cpu, uint32_t instruction);
    static void lh(CPU* cpu, uint32_t instruction);
    static void lwl(CPU* cpu, uint32_t instruction);
    static void lw(CPU* cpu, uint32_t instruction);
    static void lbu(CPU* cpu, uint32_t instruction);
    static void lhu(CPU* cpu, uint32_t instruction);
    static void lwr(CPU* cpu, uint32_t instruction);
    static void lwu(CPU* cpu, uint32_t instruction);
    static void sb(CPU* cpu, uint32_t instruction);
    static void sh(CPU* cpu, uint32_t instruction);
    static void swl(CPU* cpu, uint32_t instruction);
    static void sw(CPU* cpu, uint32_t instruction);
    static void sdl(CPU* cpu, uint32_t instruction);
    static void sdr(CPU* cpu, uint32_t instruction);
    static void swr(CPU* cpu, uint32_t instruction);
    static void cache(CPU* cpu, uint32_t instruction);
    static void ll(CPU* cpu, uint32_t instruction);
    static void lld(CPU* cpu, uint32_t instruction);
    static void ld(CPU* cpu, uint32_t instruction);
    static void sc(CPU* cpu, uint32_t instruction);
    static void scd(CPU* cpu, uint32_t instruction);
    static void sd(CPU* cpu, uint32_t instruction);
    static void sll(CPU* cpu, uint32_t instruction);
    static void srl(CPU* cpu, uint32_t instruction);
    static void sra(CPU* cpu, uint32_t instruction);
    static void sllv(CPU* cpu, uint32_t instruction);
    static void srlv(CPU* cpu, uint32_t instruction);
    static void srav(CPU* cpu, uint32_t instruction);
    static void jr(CPU* cpu, uint32_t instruction);
    static void jalr(CPU* cpu, uint32_t instruction);
    static void sync(CPU* cpu, uint32_t instruction);
    static void mfhi(CPU* cpu, uint32_t instruction);
    static void mthi(CPU* cpu, uint32_t instruction);
    static void mflo(CPU* cpu, uint32_t instruction);
    static void mtlo(CPU* cpu, uint32_t instruction);
    static void dsllv(CPU* cpu, uint32_t instruction);
    static void dsrlv(CPU* cpu, uint32_t instruction);
    static void dsrav(CPU* cpu, uint32_t instruction);
    static void mult(CPU* cpu, uint32_t instruction);
    static void multu(CPU* cpu, uint32_t instruction);
    static void div(CPU* cpu, uint32_t instruction);
    static void divu(CPU* cpu, uint32_t instruction);
    static void dmult(CPU* cpu, uint32_t instruction);
    static void dmultu(CPU* cpu, uint32_t instruction);
    static void ddiv(CPU* cpu, uint32_t instruction);
    static void ddivu(CPU* cpu, uint32_t instruction);
    static void add(CPU* cpu, uint32_t instruction);
    static void addu(CPU* cpu, uint32_t instruction);
    static void sub(CPU* cpu, uint32_t instruction);
    static void subu(CPU* cpu, uint32_t instruction);
    static void and_(CPU* cpu, uint32_t instruction);
    static void or_(CPU* cpu, uint32_t instruction);
    static void xor_(CPU* cpu, uint32_t instruction);
    static void nor(CPU* cpu, uint32_t instruction);
    static void slt(CPU* cpu, uint32_t instruction);
    static void sltu(CPU* cpu, uint32_t instruction);
    static void dadd(CPU* cpu, uint32_t instruction);
    static void daddu(CPU* cpu, uint32_t instruction);
    static void dsub(CPU* cpu, uint32_t instruction);
    static void dsubu(CPU* cpu, uint32_t instruction);
    static void tge(CPU* cpu, uint32_t instruction);
    static void tgeu(CPU* cpu, uint32_t instruction);
    static void tlt(CPU* cpu, uint32_t instruction);
    static void tltu(CPU* cpu, uint32_t instruction);
    static void teq(CPU* cpu, uint32_t instruction);
    static void tne(CPU* cpu, uint32_t instruction);
    static void dsll(CPU* cpu, uint32_t instruction);
    static void dsrl(CPU* cpu, uint32_t instruction);
    static void dsra(CPU* cpu, uint32_t instruction);
    static void dsll32(CPU* cpu, uint32_t instruction);
    static void dsrl32(CPU* cpu, uint32_t instruction);
    static void dsra32(CPU* cpu, uint32_t instruction);

    static void bltz(CPU* cpu, uint32_t instruction);
    static void bgez(CPU* cpu, uint32_t instruction);
    static void bltzl(CPU* cpu, uint32_t instruction);
    static void bgezl(CPU* cpu, uint32_t instruction);

    static void tgei(CPU* cpu, uint32_t instruction);
    static void tgeiu(CPU* cpu, uint32_t instruction);
    static void tlti(CPU* cpu, uint32_t instruction);
    static void tltiu(CPU* cpu, uint32_t instruction);
    static void teqi(CPU* cpu, uint32_t instruction);

    static void tnei(CPU* cpu, uint32_t instruction);

    static void bltzal(CPU* cpu, uint32_t instruction);
    static void bgezal(CPU* cpu, uint32_t instruction);
    static void bltzall(CPU* cpu, uint32_t instruction);
    static void bgezall(CPU* cpu, uint32_t instruction);

    static uint32_t getRt(uint32_t instruction);
    static uint32_t getRs(uint32_t instruction);
    static uint32_t getImmediate(uint32_t instruction);
    static uint64_t getSignedImmediate(uint32_t instruction);
    static uint32_t getRd(uint32_t instruction);
    static uint32_t shiftAmount(uint32_t instruction);
    static uint32_t getFd(uint32_t instruction);
};
